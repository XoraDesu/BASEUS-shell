// BASEUS — Idle & Inhibitor Service
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §34, DESIGN.md §34, DEC-025, and ROADMAP.md §12:
//   - Event-driven idle management backend:
//       * Tracks user activity via Wayland ext-idle-notify-v1
//       * Configurable multi-tier timeouts: dim warning, lock timeout, suspend timeout
//       * Idle inhibitor mechanism (Awake / Presentation Mode) halting idle timers
//       * Simulation parity for headless / WSL2 environments via internal stepper
//       * Automatic lock / suspend dispatch via PowerService

pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Wayland

Item {
    id: idleService

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var shellState: null
    property var powerService: null
    property var config: null

    // =========================================================
    // Service Configuration & State
    // =========================================================
    property bool enabled: true
    property bool simulationMode: false
    property bool inhibited: false
    property string currentState: "active" // "active" | "dim" | "lock" | "suspend"
    property int idleSeconds: 0

    // Configurable thresholds (in seconds)
    property int dimTimeout: 300           // 5 minutes
    property int lockTimeout: 600          // 10 minutes
    property int suspendTimeout: 900       // 15 minutes
    property bool autoLock: true
    property bool autoSuspend: false

    // =========================================================
    // Native Wayland Idle Monitors (ext-idle-notify-v1)
    // =========================================================
    IdleMonitor {
        id: dimMonitor
        enabled: idleService.enabled && !idleService.simulationMode && !idleService.inhibited
        timeout: idleService.dimTimeout
        respectInhibitors: true
        onIsIdleChanged: idleService._onWaylandIdleChanged()
    }

    IdleMonitor {
        id: lockMonitor
        enabled: idleService.enabled && !idleService.simulationMode && !idleService.inhibited
        timeout: idleService.lockTimeout
        respectInhibitors: true
        onIsIdleChanged: idleService._onWaylandIdleChanged()
    }

    IdleMonitor {
        id: suspendMonitor
        enabled: idleService.enabled && !idleService.simulationMode && !idleService.inhibited
        timeout: idleService.suspendTimeout
        respectInhibitors: true
        onIsIdleChanged: idleService._onWaylandIdleChanged()
    }

    // Native Wayland Idle Inhibitor
    IdleInhibitor {
        id: waylandInhibitor
        enabled: idleService.enabled && !idleService.simulationMode && idleService.inhibited
    }

    // =========================================================
    // Simulation Timer (for headless / WSL2 testing)
    // =========================================================
    Timer {
        id: simTimer
        interval: 1000
        repeat: true
        running: idleService.enabled && idleService.simulationMode && !idleService.inhibited
        onTriggered: idleService._tick(1)
    }

    // =========================================================
    // Internal Event Handlers & State Machine
    // =========================================================
    function _onWaylandIdleChanged() {
        if (!idleService.enabled || idleService.inhibited) return

        var newTier = "active"
        if (suspendMonitor.isIdle) {
            newTier = "suspend"
        } else if (lockMonitor.isIdle) {
            newTier = "lock"
        } else if (dimMonitor.isIdle) {
            newTier = "dim"
        }

        _applyTier(newTier)
    }

    function _tick(deltaSeconds: int) {
        if (!idleService.enabled || idleService.inhibited) return
        idleService.idleSeconds += deltaSeconds
        _evaluateSimulationTier()
    }

    function _evaluateSimulationTier() {
        if (idleService.inhibited) {
            _applyTier("active")
            return
        }

        var newTier = "active"
        if (idleService.idleSeconds >= idleService.suspendTimeout) {
            newTier = "suspend"
        } else if (idleService.idleSeconds >= idleService.lockTimeout) {
            newTier = "lock"
        } else if (idleService.idleSeconds >= idleService.dimTimeout) {
            newTier = "dim"
        }

        _applyTier(newTier)
    }

    function _applyTier(newTier: string) {
        if (newTier === idleService.currentState) return

        var oldTier = idleService.currentState
        idleService.currentState = newTier

        if (idleService.logger) {
            idleService.logger.info("IdleService",
                "Idle tier changed: %1 -> %2 (idleSeconds=%3, inhibited=%4)"
                .arg(oldTier)
                .arg(newTier)
                .arg(idleService.idleSeconds)
                .arg(idleService.inhibited))
        }

        _emitEvent("tier_reached", {
            "tier": newTier,
            "previousTier": oldTier,
            "idleSeconds": idleService.idleSeconds
        })

        // Auto-action dispatch
        if (newTier === "lock" && idleService.autoLock && idleService.powerService) {
            if (idleService.logger) {
                idleService.logger.info("IdleService", "Lock timeout reached — triggering powerService.lock()")
            }
            idleService.powerService.lock()
        } else if (newTier === "suspend" && idleService.autoSuspend && idleService.powerService) {
            if (idleService.logger) {
                idleService.logger.info("IdleService", "Suspend timeout reached — triggering powerService.suspend()")
            }
            idleService.powerService.suspend()
        }
    }

    function _emitEvent(type: string, payload: var) {
        if (!idleService.eventBus) return

        var evt = {
            "type": type,
            "inhibited": idleService.inhibited,
            "state": idleService.currentState,
            "idleSeconds": idleService.idleSeconds,
            "timestamp": new Date().toISOString()
        }

        if (payload) {
            for (var k in payload) {
                evt[k] = payload[k]
            }
        }

        idleService.eventBus.emit("idle", evt)
    }

    // =========================================================
    // Public API
    // =========================================================
    function toggleInhibitor(): bool {
        return setInhibitor(!idleService.inhibited)
    }

    function setInhibitor(val: bool): bool {
        if (idleService.inhibited === val) return idleService.inhibited

        idleService.inhibited = val

        if (idleService.inhibited) {
            // Inhibiting halts timers and resets idle state to active
            simulateActivity()
        }

        if (idleService.logger) {
            idleService.logger.info("IdleService",
                "Idle inhibitor toggled: %1".arg(idleService.inhibited ? "ACTIVE (Awake Mode)" : "OFF"))
        }

        _emitEvent("inhibitor_changed", { "inhibited": idleService.inhibited })
        return idleService.inhibited
    }

    function simulateActivity(): void {
        idleService.idleSeconds = 0

        if (idleService.currentState !== "active") {
            var oldState = idleService.currentState
            idleService.currentState = "active"

            if (idleService.logger) {
                idleService.logger.info("IdleService", "Activity detected — resetting idle state to active (was %1)".arg(oldState))
            }

            _emitEvent("activity_detected", { "previousState": oldState })
            _emitEvent("tier_reached", { "tier": "active", "previousTier": oldState, "idleSeconds": 0 })
        }
    }

    function setMockIdle(seconds: int): void {
        if (idleService.inhibited) {
            idleService.idleSeconds = 0
            return
        }

        idleService.idleSeconds = Math.max(0, seconds)
        _evaluateSimulationTier()
    }

    function getSnapshot(): var {
        return {
            "available": true,
            "enabled": idleService.enabled,
            "inhibited": idleService.inhibited,
            "state": idleService.currentState,
            "idleSeconds": idleService.idleSeconds,
            "dimTimeout": idleService.dimTimeout,
            "lockTimeout": idleService.lockTimeout,
            "suspendTimeout": idleService.suspendTimeout,
            "autoLock": idleService.autoLock,
            "autoSuspend": idleService.autoSuspend,
            "simulationMode": idleService.simulationMode
        }
    }

    // =========================================================
    // Lifecycle
    // =========================================================
    function initialize() {
        if (idleService.config) {
            if (typeof idleService.config.idleDimTimeout === "number") idleService.dimTimeout = idleService.config.idleDimTimeout
            if (typeof idleService.config.idleLockTimeout === "number") idleService.lockTimeout = idleService.config.idleLockTimeout
            if (typeof idleService.config.idleSuspendTimeout === "number") idleService.suspendTimeout = idleService.config.idleSuspendTimeout
            if (typeof idleService.config.idleAutoLock === "boolean") idleService.autoLock = idleService.config.idleAutoLock
            if (typeof idleService.config.idleAutoSuspend === "boolean") idleService.autoSuspend = idleService.config.idleAutoSuspend
            if (typeof idleService.config.idleInhibitByDefault === "boolean") idleService.inhibited = idleService.config.idleInhibitByDefault
            if (idleService.config.simulationEnabled) idleService.simulationMode = true
        }

        idleService.idleSeconds = 0
        idleService.currentState = "active"

        if (idleService.logger) {
            idleService.logger.info("IdleService",
                "IdleService initialized (simulationMode=%1, dim=%2s, lock=%3s, suspend=%4s, inhibited=%5)"
                .arg(idleService.simulationMode)
                .arg(idleService.dimTimeout)
                .arg(idleService.lockTimeout)
                .arg(idleService.suspendTimeout)
                .arg(idleService.inhibited))
        }
    }

    function teardown() {
        simTimer.stop()
        idleService.idleSeconds = 0
        idleService.currentState = "active"
        if (idleService.logger) {
            idleService.logger.info("IdleService", "Teardown complete")
        }
    }
}

