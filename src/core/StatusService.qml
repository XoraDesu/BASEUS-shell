// BASEUS — System Status & Diagnostic Service
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §9, ROADMAP.md §10, and ANTI-SLOP.md §6.7–6.8:
//   - Event-driven system health and status model: Power/Battery, Network, Subsystems
//   - Strict Anti-Slop (ANTI-SLOP.md §6.7 & §6.8):
//       * NO permanent telemetry dashboards or cockpit syndrome
//       * NO fake CPU/RAM usage graphs, NO sci-fi dials or decorative percentages
//       * Idle desktop remains quiet and calm (MASTER.md §9)
//   - Contextual status delivery through TopIslandHeader
//   - Low-battery / critical alerts dispatched via NotificationModel
//   - Deterministic in-memory simulation parity for headless/WSL2 environments

pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: statusService

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var config: null
    property var notificationModel: null
    property var bridge: null
    property var audioService: null
    property var mediaService: null

    // =========================================================
    // Power & Battery State
    // =========================================================
    property bool hasBattery: true
    property real batteryPercent: 88.0 // 0.0 .. 100.0
    property bool isCharging: false
    property real lowBatteryThreshold: 20.0
    property real criticalBatteryThreshold: 10.0

    readonly property bool isLowBattery: statusService.hasBattery && !statusService.isCharging && (statusService.batteryPercent <= statusService.lowBatteryThreshold)
    readonly property bool isCriticalBattery: statusService.hasBattery && !statusService.isCharging && (statusService.batteryPercent <= statusService.criticalBatteryThreshold)

    readonly property string batteryGlyph: {
        if (!statusService.hasBattery) return "AC"
        if (statusService.isCharging) return "CHG"
        if (statusService.batteryPercent <= 15.0) return "LOW"
        return "BAT"
    }

    readonly property string batteryLabel: {
        if (!statusService.hasBattery) return "AC Power"
        const pct = Math.round(statusService.batteryPercent)
        if (statusService.isCharging) return pct + "% Charging"
        return pct + "%"
    }

    // Auto Low-Battery Alert State
    property bool _lowBatteryAlertSent: false

    onBatteryPercentChanged: statusService._checkBatteryAlert()
    onIsChargingChanged: {
        if (statusService.isCharging) {
            statusService._lowBatteryAlertSent = false
        }
        statusService._checkBatteryAlert()
    }

    function _checkBatteryAlert(): void {
        const isLow = statusService.hasBattery && !statusService.isCharging && (statusService.batteryPercent <= statusService.lowBatteryThreshold)
        const isCrit = statusService.hasBattery && !statusService.isCharging && (statusService.batteryPercent <= statusService.criticalBatteryThreshold)

        if (isLow && !statusService._lowBatteryAlertSent) {
            statusService._lowBatteryAlertSent = true
            if (statusService.notificationModel) {
                statusService.notificationModel.postNotification(
                    "Power",
                    "battery-caution",
                    "Low Battery (" + Math.round(statusService.batteryPercent) + "%)",
                    isCrit
                        ? "Battery is critical. Connect charger immediately."
                        : "Battery is low. Connect charger soon.",
                    isCrit ? "critical" : "normal",
                    [],
                    5000
                )
            }
            statusService._emitStatusEvent("battery_low")
        } else if (!isLow && statusService.batteryPercent > statusService.lowBatteryThreshold) {
            statusService._lowBatteryAlertSent = false
        }
    }

    // =========================================================
    // Network Connectivity State
    // =========================================================
    property bool networkConnected: true
    property string networkType: "wifi" // "wifi", "ethernet", "none"
    property string networkName: "Baseus-Net" // SSID or interface label
    property int networkSignalStrength: 85 // 0 .. 100

    readonly property string networkLabel: {
        if (!statusService.networkConnected) return "Offline"
        if (statusService.networkType === "ethernet") return "Ethernet"
        return statusService.networkName.length > 0 ? statusService.networkName : "Connected"
    }

    readonly property string networkGlyph: {
        if (!statusService.networkConnected) return "OFF"
        if (statusService.networkType === "ethernet") return "ETH"
        return "WLAN"
    }

    // =========================================================
    // Subsystem Health Tracking
    // =========================================================
    readonly property bool bridgeConnected: statusService.bridge ? statusService.bridge.connected : true
    readonly property bool audioAvailable: statusService.audioService ? Boolean(statusService.audioService.available) : true
    readonly property bool mediaAvailable: statusService.mediaService ? statusService.mediaService.hasPlayer : true
    readonly property bool systemHealthy: statusService.bridgeConnected && statusService.audioAvailable

    // =========================================================
    // Simulation & Diagnostic Mutation API
    // =========================================================
    function setMockBattery(percent: real, charging: bool): void {
        statusService.batteryPercent = Math.max(0.0, Math.min(100.0, percent))
        statusService.isCharging = charging
        statusService._checkBatteryAlert()
        statusService._emitStatusEvent("battery_changed")
    }

    function setMockNetwork(connected: bool, type: string, name: string): void {
        statusService.networkConnected = connected
        if (typeof type === "string" && type.length > 0) {
            statusService.networkType = type
        }
        if (typeof name === "string") {
            statusService.networkName = name
        }
        statusService._emitStatusEvent("network_changed")
    }

    // =========================================================
    // EventBus Category "status" Emission
    // =========================================================
    function _emitStatusEvent(type: string): void {
        if (statusService.eventBus) {
            statusService.eventBus.emit("status", {
                source: "status_service",
                type: type,
                battery: {
                    percent: statusService.batteryPercent,
                    isCharging: statusService.isCharging,
                    isLow: statusService.isLowBattery,
                    isCritical: statusService.isCriticalBattery
                },
                network: {
                    connected: statusService.networkConnected,
                    type: statusService.networkType,
                    name: statusService.networkName
                },
                subsystems: {
                    bridgeConnected: statusService.bridgeConnected,
                    audioAvailable: statusService.audioAvailable,
                    mediaAvailable: statusService.mediaAvailable,
                    healthy: statusService.systemHealthy
                }
            })
        }

        if (statusService.logger) {
            statusService.logger.debug("StatusService",
                "Status event '%1': Bat=%2% (Chg=%3), Net=%4 (%5)"
                .arg(type)
                .arg(Math.round(statusService.batteryPercent))
                .arg(statusService.isCharging)
                .arg(statusService.networkName)
                .arg(statusService.networkConnected))
        }
    }

    // =========================================================
    // Diagnostic Introspection Snapshot
    // =========================================================
    function getSnapshot(): var {
        return {
            battery: {
                hasBattery: statusService.hasBattery,
                percent: statusService.batteryPercent,
                isCharging: statusService.isCharging,
                isLowBattery: statusService.isLowBattery,
                isCriticalBattery: statusService.isCriticalBattery,
                glyph: statusService.batteryGlyph,
                label: statusService.batteryLabel
            },
            network: {
                connected: statusService.networkConnected,
                type: statusService.networkType,
                name: statusService.networkName,
                signalStrength: statusService.networkSignalStrength,
                glyph: statusService.networkGlyph,
                label: statusService.networkLabel
            },
            subsystems: {
                bridgeConnected: statusService.bridgeConnected,
                audioAvailable: statusService.audioAvailable,
                mediaAvailable: statusService.mediaAvailable,
                systemHealthy: statusService.systemHealthy
            }
        }
    }
}

