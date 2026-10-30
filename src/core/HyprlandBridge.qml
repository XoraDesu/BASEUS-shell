// BASEUS — Hyprland Integration Bridge
// Copyright (c) 2026 xoradesu — MIT License
//
// Isolates all Hyprland-specific IPC communication behind a clean boundary.
// The rest of BASEUS consumes normalized state/events through ShellState,
// domain models, and EventBus, not raw Hyprland details.
//
// Responsibilities:
//   - Hyprland IPC availability detection and honest diagnostics
//   - Workspace state observation (fixed 1–10 BASEUS model)
//   - Window state observation
//   - Monitor state observation
//   - Hyprland event → BASEUS event translation
//   - Runtime assumption documentation
//
// Architecture (per TASKS.md §12, MASTER-PROMPT.md §17):
//   External Event → Integration Boundary → Normalized Event → Consumers
//
// Runtime assumptions:
//   - Hyprland is running and HYPRLAND_INSTANCE_SIGNATURE is set
//   - Hyprland request/event sockets are accessible via Quickshell.Hyprland

import Quickshell
import Quickshell.Hyprland
import QtQuick

QtObject {
    id: hyprlandBridge

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var shellState: null

    // =========================================================
    // Connection State
    // =========================================================
    readonly property bool isMock: false
    property bool connected: false
    property string lastError: ""

    readonly property string instanceSignature: String(Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "")
    readonly property bool runtimeAvailable: instanceSignature.length > 0 && String(Hyprland.eventSocketPath || "").length > 0
    readonly property bool usingLua: Boolean(Hyprland.usingLua)

    // =========================================================
    // Signal Subscriptions (active only when connected)
    // =========================================================
    property Connections _hyprConnections: Connections {
        target: Hyprland
        enabled: hyprlandBridge.connected

        function onFocusedMonitorChanged() {
            hyprlandBridge._emitFocusedMonitor()
        }

        function onFocusedWorkspaceChanged() {
            hyprlandBridge._emitFocusedWorkspace()
        }

        function onActiveToplevelChanged() {
            hyprlandBridge._emitActiveToplevel()
        }

        function onRawEvent(event) {
            hyprlandBridge._handleRawEvent(event)
        }
    }

    // =========================================================
    // Initialization
    // =========================================================

    function initialize() {
        if (logger) logger.info("HyprlandBridge", "Initializing Hyprland integration...")

        if (!runtimeAvailable) {
            connected = false
            lastError = instanceSignature.length === 0
                ? "Hyprland runtime unavailable (HYPRLAND_INSTANCE_SIGNATURE is not set)"
                : "Hyprland IPC event socket path unavailable"
            if (logger) logger.warn("HyprlandBridge", lastError + ". Live Hyprland IPC disabled.")
            return false
        }

        if (!eventBus) {
            connected = false
            lastError = "Cannot initialize HyprlandBridge — eventBus not available"
            if (logger) logger.error("HyprlandBridge", lastError)
            return false
        }

        lastError = ""
        connected = true
        if (logger) logger.info("HyprlandBridge",
            "Hyprland bridge connected (instance=%1).".arg(instanceSignature))

        Hyprland.refreshMonitors()
        Hyprland.refreshWorkspaces()
        Hyprland.refreshToplevels()
        _syncAll()
        return true
    }

    // =========================================================
    // State Synchronization & Event Translation
    // =========================================================

    function _syncAll() {
        if (!connected || !eventBus) return
        _syncMonitors()
        _syncWorkspaces()
        _syncToplevels()
    }

    function _syncMonitors() {
        if (!connected || !eventBus || !Hyprland.monitors) return
        var rawMonitors = Hyprland.monitors.values || []
        var list = []
        var focusedIdx = 0

        for (var i = 0; i < rawMonitors.length; i++) {
            var m = rawMonitors[i]
            if (!m) continue
            var idx = typeof m.id === "number" ? m.id : i
            if (m.focused) focusedIdx = idx
            list.push({
                index: idx,
                name: String(m.name || ("monitor-" + idx)),
                width: typeof m.width === "number" ? m.width : 1920,
                height: typeof m.height === "number" ? m.height : 1080,
                x: typeof m.x === "number" ? m.x : 0,
                y: typeof m.y === "number" ? m.y : 0,
                scale: typeof m.scale === "number" ? m.scale : 1.0,
                active: true
            })
        }

        if (list.length > 0) {
            eventBus.emit("monitor", {
                source: "bridge",
                type: "synced",
                monitors: list,
                focusedIndex: focusedIdx
            })
        }
    }

    function _syncWorkspaces() {
        if (!connected || !eventBus || !Hyprland.monitors) return
        var rawMonitors = Hyprland.monitors.values || []
        var activeMap = {}

        for (var i = 0; i < rawMonitors.length; i++) {
            var m = rawMonitors[i]
            if (!m || !m.activeWorkspace) continue
            var monIdx = typeof m.id === "number" ? m.id : i
            var wsId = m.activeWorkspace.id
            if (wsId >= 1 && wsId <= 10) {
                activeMap[monIdx] = wsId
            }
        }

        if (Object.keys(activeMap).length > 0) {
            eventBus.emit("workspace", {
                source: "bridge",
                type: "synced",
                activeWorkspaces: activeMap
            })
        }
    }

    function _syncToplevels() {
        if (!connected || !eventBus || !Hyprland.toplevels) return
        var rawToplevels = Hyprland.toplevels.values || []
        var list = []
        var focusedAddr = (Hyprland.activeToplevel && Hyprland.activeToplevel.address)
            ? ("0x" + String(Hyprland.activeToplevel.address).replace(/^0x/, ""))
            : ""

        for (var i = 0; i < rawToplevels.length; i++) {
            var t = rawToplevels[i]
            if (!t) continue
            var addr = "0x" + String(t.address || "").replace(/^0x/, "")
            var ipc = t.lastIpcObject || ({})
            var wsId = (t.workspace && typeof t.workspace.id === "number") ? t.workspace.id : 1
            var monIdx = (t.monitor && typeof t.monitor.id === "number") ? t.monitor.id : 0
            list.push({
                address: addr,
                title: String(t.title || ""),
                appClass: String(ipc["class"] || ""),
                workspace: wsId,
                monitor: monIdx,
                floating: ipc.floating !== undefined ? Boolean(ipc.floating) : true,
                fullscreen: Boolean(ipc.fullscreen),
                maximized: false,
                minimized: false,
                focused: Boolean(t.activated) || (addr === focusedAddr && focusedAddr.length > 0)
            })
        }

        eventBus.emit("window", {
            source: "bridge",
            type: "synced",
            windows: list,
            focusedAddress: focusedAddr
        })
    }

    function _emitFocusedMonitor() {
        if (!connected || !eventBus || !Hyprland.focusedMonitor) return
        eventBus.emit("monitor", {
            source: "bridge",
            type: "focused",
            index: Hyprland.focusedMonitor.id
        })
    }

    function _emitFocusedWorkspace() {
        if (!connected || !eventBus || !Hyprland.focusedWorkspace) return
        var ws = Hyprland.focusedWorkspace
        if (ws.id < 1 || ws.id > 10) return
        var monIdx = (ws.monitor && typeof ws.monitor.id === "number") ? ws.monitor.id : 0
        eventBus.emit("workspace", {
            source: "bridge",
            type: "activated",
            monitorIndex: monIdx,
            current: ws.id
        })
    }

    function _emitActiveToplevel() {
        if (!connected || !eventBus) return
        var addr = (Hyprland.activeToplevel && Hyprland.activeToplevel.address)
            ? ("0x" + String(Hyprland.activeToplevel.address).replace(/^0x/, ""))
            : ""
        eventBus.emit("window", {
            source: "bridge",
            type: "focused",
            address: addr
        })
    }

    function _handleRawEvent(event) {
        if (!connected || !eventBus || !event) return
        var name = String(event.name || "")
        var data = String(event.data || "")

        if (name === "openwindow") {
            // Format: WINDOWADDRESS,WORKSPACENAME,WINDOWCLASS,WINDOWTITLE
            var parts = event.parse(4)
            if (parts && parts.length >= 4) {
                var wsNum = parseInt(parts[1], 10)
                eventBus.emit("window", {
                    source: "bridge",
                    type: "created",
                    window: {
                        address: "0x" + String(parts[0]).replace(/^0x/, ""),
                        workspace: (!isNaN(wsNum) && wsNum >= 1 && wsNum <= 10) ? wsNum : 1,
                        appClass: String(parts[2] || ""),
                        title: String(parts[3] || ""),
                        floating: true,
                        fullscreen: false,
                        focused: true
                    }
                })
            }
            Hyprland.refreshToplevels()
        } else if (name === "closewindow") {
            eventBus.emit("window", {
                source: "bridge",
                type: "destroyed",
                address: "0x" + data.replace(/^0x/, "")
            })
            Hyprland.refreshToplevels()
        } else if (name === "activewindowv2") {
            var trimmedAddr = data.trim()
            var nextFocusAddr = trimmedAddr.length > 0
                ? ("0x" + trimmedAddr.replace(/^0x/, ""))
                : ""
            eventBus.emit("window", {
                source: "bridge",
                type: "focused",
                address: nextFocusAddr
            })
        } else if (name === "movewindowv2" || name === "movewindow") {
            var moveParts = event.parse(2)
            if (moveParts && moveParts.length >= 2) {
                var targetWs = parseInt(moveParts[1], 10)
                if (!isNaN(targetWs) && targetWs >= 1 && targetWs <= 10) {
                    eventBus.emit("window", {
                        source: "bridge",
                        type: "moved",
                        address: "0x" + String(moveParts[0]).replace(/^0x/, ""),
                        workspace: targetWs
                    })
                }
            }
        } else if (name === "fullscreen") {
            var isFs = (data.trim() === "1")
            var activeAddr = (Hyprland.activeToplevel && Hyprland.activeToplevel.address)
                ? ("0x" + String(Hyprland.activeToplevel.address).replace(/^0x/, ""))
                : ""
            eventBus.emit("window", {
                source: "bridge",
                type: "fullscreen",
                fullscreen: isFs,
                address: activeAddr
            })
        } else if (name === "workspacev2" || name === "workspace") {
            var wsRaw = name === "workspacev2" ? (event.parse(2)[0] || "") : data
            var activeWsId = parseInt(String(wsRaw).trim(), 10)
            if (!isNaN(activeWsId) && activeWsId >= 1 && activeWsId <= 10) {
                var activeMonIdx = (Hyprland.focusedMonitor && typeof Hyprland.focusedMonitor.id === "number")
                    ? Hyprland.focusedMonitor.id
                    : 0
                eventBus.emit("workspace", {
                    source: "bridge",
                    type: "activated",
                    monitorIndex: activeMonIdx,
                    current: activeWsId
                })
            }
            Hyprland.refreshWorkspaces()
        } else if (name === "focusedmonv2" || name === "focusedmon") {
            var fmParts = event.parse(2)
            if (fmParts && fmParts.length >= 2) {
                var monName = String(fmParts[0] || "")
                var fmWsId = parseInt(String(fmParts[1] || "").trim(), 10)
                var resolvedMonIdx = (Hyprland.focusedMonitor && typeof Hyprland.focusedMonitor.id === "number")
                    ? Hyprland.focusedMonitor.id
                    : 0
                if (Hyprland.monitors && Hyprland.monitors.values) {
                    var rawMons = Hyprland.monitors.values
                    for (var mi = 0; mi < rawMons.length; mi++) {
                        if (rawMons[mi] && String(rawMons[mi].name || "") === monName && typeof rawMons[mi].id === "number") {
                            resolvedMonIdx = rawMons[mi].id
                            break
                        }
                    }
                }
                eventBus.emit("monitor", {
                    source: "bridge",
                    type: "focused",
                    index: resolvedMonIdx
                })
                if (!isNaN(fmWsId) && fmWsId >= 1 && fmWsId <= 10) {
                    eventBus.emit("workspace", {
                        source: "bridge",
                        type: "activated",
                        monitorIndex: resolvedMonIdx,
                        current: fmWsId
                    })
                }
            }
        } else if (name === "monitoradded" || name === "monitorremoved" || name === "monitoraddedv2" || name === "monitorremovedv2") {
            Hyprland.refreshMonitors()
            _syncMonitors()
        }
    }

    // =========================================================
    // Workspace Queries & Commands
    // =========================================================

    function getActiveWorkspaceId(monitorIndex) {
        if (!connected || !Hyprland.monitors) return 1
        var rawMonitors = Hyprland.monitors.values || []
        for (var i = 0; i < rawMonitors.length; i++) {
            var m = rawMonitors[i]
            if (m && m.id === monitorIndex && m.activeWorkspace) {
                return m.activeWorkspace.id
            }
        }
        return 1
    }

    function switchWorkspace(workspaceId) {
        if (workspaceId < 1 || workspaceId > 10) {
            if (logger) logger.warn("HyprlandBridge",
                "Invalid workspace ID: %1 (must be 1–10)".arg(workspaceId))
            return false
        }

        if (!connected) {
            if (logger) logger.warn("HyprlandBridge",
                "Cannot switch to workspace %1 — Hyprland bridge is not connected.".arg(workspaceId))
            return false
        }

        if (logger) logger.info("HyprlandBridge",
            "Switching to workspace %1 (lua=%2)".arg(workspaceId).arg(usingLua))

        if (usingLua) {
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + workspaceId.toString() + " })")
        } else {
            Hyprland.dispatch("workspace " + workspaceId.toString())
        }
        return true
    }

    // =========================================================
    // Window Commands
    // =========================================================

    function moveWindowToWorkspace(windowAddress, workspaceId) {
        if (workspaceId < 1 || workspaceId > 10 || !windowAddress) {
            if (logger) logger.warn("HyprlandBridge",
                "Invalid moveWindowToWorkspace arguments: address='%1', workspace=%2"
                    .arg(windowAddress).arg(workspaceId))
            return false
        }

        if (!connected) {
            if (logger) logger.warn("HyprlandBridge",
                "Cannot move window %1 — Hyprland bridge is not connected.".arg(windowAddress))
            return false
        }

        var addr = "0x" + String(windowAddress).replace(/^0x/, "")
        if (logger) logger.info("HyprlandBridge",
            "Moving window %1 to workspace %2 (lua=%3)".arg(addr).arg(workspaceId).arg(usingLua))

        if (usingLua) {
            Hyprland.dispatch("hl.dsp.window.move({ workspace = " + workspaceId.toString() + ", window = \"address:" + addr + "\" })")
        } else {
            Hyprland.dispatch("movetoworkspace " + workspaceId.toString() + ",address:" + addr)
        }
        return true
    }

    // =========================================================
    // Monitor Queries
    // =========================================================

    function getMonitorCount() {
        if (!connected || !Hyprland.monitors || !Hyprland.monitors.values) return 0
        return Hyprland.monitors.values.length
    }

    // =========================================================
    // Teardown
    // =========================================================

    function teardown() {
        var wasConnected = connected
        connected = false
        if (wasConnected && logger) {
            logger.info("HyprlandBridge", "Hyprland bridge disconnected.")
        }
    }

    Component.onCompleted: {
        if (logger) logger.debug("HyprlandBridge",
            "Hyprland bridge created. Call initialize() to connect.")
    }
}
