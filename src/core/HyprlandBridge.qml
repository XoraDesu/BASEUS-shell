// BASEUS — Hyprland Integration Bridge
// Copyright (c) 2026 xoradesu — MIT License
//
// Isolates all Hyprland-specific IPC communication behind a clean boundary.
// The rest of BASEUS consumes normalized state/events through ShellState,
// domain models, and EventBus, not raw Hyprland details.
//
// Responsibilities:
//   - Hyprland IPC availability detection and honest diagnostics
//   - Direct UNIX domain socket (j/monitors over .socket.sock) synchronization
//     compatible with Hyprland 0.57+ schema without spawning child processes
//   - Fixed 1–10 per-monitor workspace state observation & navigation (DEC-010)
//   - Freeform window state observation & workspace movement
//   - Multi-monitor focus & hotplug state observation
//   - Hyprland event → BASEUS event translation (dual Lua 0.57+ / Hyprlang < 0.57)
//
// Architecture (per DEC-005, DEC-007):
//   External Event → Integration Boundary → Normalized Event → Consumers

import Quickshell
import Quickshell.Io
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
    property var workspaceModel: null
    property var monitorModel: null

    // =========================================================
    // Connection State
    // =========================================================
    readonly property bool isMock: false
    property bool connected: false
    property string lastError: ""
    property int _focusedMonitorIndex: 0
    property var _cachedMonitors: []

    readonly property string instanceSignature: String(Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "")
    readonly property string requestSocketPath: String(Hyprland.requestSocketPath || "")
    readonly property string eventSocketPath: String(Hyprland.eventSocketPath || "")
    readonly property bool runtimeAvailable: instanceSignature.length > 0 && eventSocketPath.length > 0
    readonly property bool usingLua: Boolean(Hyprland.usingLua)

    // =========================================================
    // Direct .socket.sock Query Client (j/monitors — zero process spawn)
    // =========================================================
    property bool _monitorsQueryInFlight: false
    property bool _monitorsQueryPending: false
    property string _monitorsBuffer: ""

    property Socket _monitorsSocket: Socket {
        onConnectionStateChanged: {
            if (connected) {
                hyprlandBridge._monitorsBuffer = ""
                write("j/monitors")
                flush()
            } else if (hyprlandBridge._monitorsQueryInFlight) {
                hyprlandBridge._monitorsQueryInFlight = false
                var payload = hyprlandBridge._monitorsBuffer
                hyprlandBridge._monitorsBuffer = ""
                if (payload.trim().length > 0) {
                    hyprlandBridge._handleMonitorsJson(payload)
                }
                if (hyprlandBridge._monitorsQueryPending && hyprlandBridge.connected) {
                    hyprlandBridge._monitorsQueryPending = false
                    hyprlandBridge._requestMonitors()
                }
            }
        }

        onError: function(socketError) {
            // QLocalSocket::PeerClosedError (1) is normal EOF when Hyprland finishes
            // sending a .socket.sock response; onConnectionStateChanged (!connected)
            // immediately follows and parses _monitorsBuffer.
            if (Number(socketError) === 1) {
                return
            }
            hyprlandBridge._monitorsQueryInFlight = false
            hyprlandBridge._monitorsBuffer = ""
            if (hyprlandBridge.logger) {
                hyprlandBridge.logger.warn("HyprlandBridge",
                    "j/monitors socket query error (%1)".arg(socketError))
            }
            if (connected) {
                connected = false
            }
        }

        parser: SplitParser {
            splitMarker: ""
            onRead: function(chunk) {
                hyprlandBridge._monitorsBuffer += chunk
            }
        }
    }

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

    readonly property var observedToplevels: (connected && Hyprland.toplevels) ? Hyprland.toplevels.values : []

    onObservedToplevelsChanged: {
        if (connected) {
            _syncToplevels()
        }
    }

    // =========================================================
    // Helpers
    // =========================================================

    function _isValidWorkspaceId(workspaceId) {
        return typeof workspaceId === "number"
            && !isNaN(workspaceId)
            && Math.floor(workspaceId) === workspaceId
            && workspaceId >= 1
            && workspaceId <= 10
    }

    function _parseModeDimensions(availableModes) {
        if (!Array.isArray(availableModes) || availableModes.length === 0) {
            return { width: 1920, height: 1080 }
        }
        var first = String(availableModes[0] || "")
        var atParts = first.split("@")
        var resParts = String(atParts[0] || "").split("x")
        if (resParts.length === 2) {
            var w = parseInt(resParts[0], 10)
            var h = parseInt(resParts[1], 10)
            if (!isNaN(w) && w > 0 && !isNaN(h) && h > 0) {
                return { width: w, height: h }
            }
        }
        return { width: 1920, height: 1080 }
    }

    function _resolveMonitorIndexByName(monName) {
        var targetName = String(monName || "").trim()
        if (targetName.length === 0) return _focusedMonitorIndex

        for (var c = 0; c < _cachedMonitors.length; c++) {
            if (_cachedMonitors[c] && _cachedMonitors[c].name === targetName) {
                return _cachedMonitors[c].index
            }
        }

        if (monitorModel && Array.isArray(monitorModel.monitors)) {
            for (var j = 0; j < monitorModel.monitors.length; j++) {
                var entry = monitorModel.monitors[j]
                if (entry && String(entry.name || "") === targetName && typeof entry.index === "number") {
                    return entry.index
                }
            }
        }

        if (Hyprland.monitors && Hyprland.monitors.values) {
            var rawMons = Hyprland.monitors.values
            for (var i = 0; i < rawMons.length; i++) {
                if (rawMons[i] && String(rawMons[i].name || "") === targetName && typeof rawMons[i].id === "number" && rawMons[i].id >= 0) {
                    return rawMons[i].id
                }
            }
        }

        return _focusedMonitorIndex
    }

    function _resolveMonitorNameByIndex(monitorIndex) {
        if (typeof monitorIndex !== "number" || isNaN(monitorIndex)) return ""

        for (var c = 0; c < _cachedMonitors.length; c++) {
            if (_cachedMonitors[c] && _cachedMonitors[c].index === monitorIndex) {
                return String(_cachedMonitors[c].name || "")
            }
        }

        if (monitorModel) {
            var found = monitorModel.getMonitor(monitorIndex)
            if (found && found.name) return String(found.name)
        }

        if (Hyprland.monitors && Hyprland.monitors.values) {
            var rawMons = Hyprland.monitors.values
            for (var i = 0; i < rawMons.length; i++) {
                if (rawMons[i] && rawMons[i].id === monitorIndex) {
                    return String(rawMons[i].name || "")
                }
            }
        }

        return ""
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
        _focusedMonitorIndex = 0
        _cachedMonitors = []
        _monitorsQueryInFlight = false
        _monitorsQueryPending = false
        connected = true
        if (logger) logger.info("HyprlandBridge",
            "Hyprland bridge connected (instance=%1).".arg(instanceSignature))

        Hyprland.refreshMonitors()
        Hyprland.refreshWorkspaces()
        Hyprland.refreshToplevels()
        _syncAll()
        _requestMonitors()
        return true
    }

    // =========================================================
    // Direct Socket Synchronization (j/monitors)
    // =========================================================

    function _requestMonitors() {
        if (!connected || requestSocketPath.length === 0) return
        if (_monitorsQueryInFlight) {
            _monitorsQueryPending = true
            return
        }
        if (_monitorsSocket.connected) {
            _monitorsSocket.connected = false
        }
        _monitorsBuffer = ""
        _monitorsQueryInFlight = true
        _monitorsQueryPending = false
        _monitorsSocket.path = requestSocketPath
        _monitorsSocket.connected = true
    }

    function _handleMonitorsJson(rawJson) {
        if (!connected || !eventBus) return
        var trimmed = String(rawJson || "").trim()
        if (trimmed.length === 0) return

        var parsed = null
        try {
            parsed = JSON.parse(trimmed)
        } catch (e) {
            if (logger) logger.warn("HyprlandBridge",
                "Failed to parse j/monitors JSON: %1".arg(e.message || String(e)))
            return
        }

        if (!Array.isArray(parsed)) return

        var monitorList = []
        var activeWsMap = {}
        var focusedIdx = _focusedMonitorIndex
        var foundFocused = false

        for (var i = 0; i < parsed.length; i++) {
            var m = parsed[i]
            if (!m || m.disabled === true) continue
            var idx = typeof m.id === "number" ? m.id : i
            var fallbackDim = _parseModeDimensions(m.availableModes)
            var w = (typeof m.width === "number" && m.width > 0) ? m.width : fallbackDim.width
            var h = (typeof m.height === "number" && m.height > 0) ? m.height : fallbackDim.height

            if (m.focused === true) {
                focusedIdx = idx
                foundFocused = true
            }

            monitorList.push({
                index: idx,
                name: String(m.name || ("monitor-" + idx)),
                width: w,
                height: h,
                x: typeof m.x === "number" ? m.x : 0,
                y: typeof m.y === "number" ? m.y : 0,
                scale: (typeof m.scale === "number" && m.scale > 0) ? m.scale : 1.0,
                active: true
            })

            if (m.activeWorkspace && _isValidWorkspaceId(m.activeWorkspace.id)) {
                activeWsMap[idx] = m.activeWorkspace.id
            }
        }

        if (!foundFocused && monitorList.length > 0) {
            focusedIdx = monitorList[0].index
        }

        _cachedMonitors = monitorList
        if (monitorList.length > 0) {
            _focusedMonitorIndex = focusedIdx
            eventBus.emit("monitor", {
                source: "bridge",
                type: "synced",
                monitors: monitorList,
                focusedIndex: focusedIdx
            })
        }

        if (Object.keys(activeWsMap).length > 0) {
            eventBus.emit("workspace", {
                source: "bridge",
                type: "synced",
                activeWorkspaces: activeWsMap
            })
        }
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
        if (rawMonitors.length === 0) return

        var list = []
        var focusedIdx = _focusedMonitorIndex
        var foundFocused = false

        for (var i = 0; i < rawMonitors.length; i++) {
            var m = rawMonitors[i]
            if (!m) continue
            var idx = typeof m.id === "number" ? m.id : i
            if (m.focused) {
                focusedIdx = idx
                foundFocused = true
            }
            list.push({
                index: idx,
                name: String(m.name || ("monitor-" + idx)),
                width: (typeof m.width === "number" && m.width > 0) ? m.width : 1920,
                height: (typeof m.height === "number" && m.height > 0) ? m.height : 1080,
                x: typeof m.x === "number" ? m.x : 0,
                y: typeof m.y === "number" ? m.y : 0,
                scale: (typeof m.scale === "number" && m.scale > 0) ? m.scale : 1.0,
                active: true
            })
        }

        if (!foundFocused && list.length > 0) {
            focusedIdx = list[0].index
        }

        if (list.length > 0) {
            _cachedMonitors = list
            _focusedMonitorIndex = focusedIdx
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
            if (_isValidWorkspaceId(wsId)) {
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
            var monName = (t.monitor && t.monitor.name) ? String(t.monitor.name) : ""
            var monIdx = monName.length > 0
                ? _resolveMonitorIndexByName(monName)
                : ((t.monitor && typeof t.monitor.id === "number" && t.monitor.id >= 0) ? t.monitor.id : _focusedMonitorIndex)
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

        if (list.length > 0) {
            eventBus.emit("window", {
                source: "bridge",
                type: "synced",
                windows: list,
                focusedAddress: focusedAddr
            })
        }
    }

    function _emitFocusedMonitor() {
        if (!connected || !eventBus || !Hyprland.focusedMonitor) return
        var monName = String(Hyprland.focusedMonitor.name || "")
        var monIdx = monName.length > 0
            ? _resolveMonitorIndexByName(monName)
            : Hyprland.focusedMonitor.id
        if (typeof monIdx === "number" && monIdx >= 0) {
            _focusedMonitorIndex = monIdx
            eventBus.emit("monitor", {
                source: "bridge",
                type: "focused",
                index: monIdx
            })
        }
    }

    function _emitFocusedWorkspace() {
        if (!connected || !eventBus || !Hyprland.focusedWorkspace) return
        var ws = Hyprland.focusedWorkspace
        if (!_isValidWorkspaceId(ws.id)) return
        var monIdx = _focusedMonitorIndex
        if (ws.monitor && String(ws.monitor.name || "").length > 0) {
            monIdx = _resolveMonitorIndexByName(ws.monitor.name)
        } else if (workspaceModel) {
            var existingOwner = workspaceModel.getMonitorForWorkspace(ws.id)
            if (existingOwner >= 0) {
                monIdx = existingOwner
            }
        }
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
                        workspace: _isValidWorkspaceId(wsNum) ? wsNum : 1,
                        monitor: _focusedMonitorIndex,
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
                if (_isValidWorkspaceId(targetWs)) {
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
            if (_isValidWorkspaceId(activeWsId)) {
                var activeMonIdx = _focusedMonitorIndex
                if (workspaceModel) {
                    var existingOwner = workspaceModel.getMonitorForWorkspace(activeWsId)
                    if (existingOwner >= 0 && existingOwner !== _focusedMonitorIndex) {
                        activeMonIdx = existingOwner
                        _focusedMonitorIndex = existingOwner
                        eventBus.emit("monitor", {
                            source: "bridge",
                            type: "focused",
                            index: existingOwner
                        })
                    }
                }
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
                var resolvedMonIdx = _resolveMonitorIndexByName(monName)
                _focusedMonitorIndex = resolvedMonIdx
                eventBus.emit("monitor", {
                    source: "bridge",
                    type: "focused",
                    index: resolvedMonIdx
                })
                if (_isValidWorkspaceId(fmWsId)) {
                    eventBus.emit("workspace", {
                        source: "bridge",
                        type: "activated",
                        monitorIndex: resolvedMonIdx,
                        current: fmWsId
                    })
                }
            }
        } else if (name === "moveworkspacev2" || name === "moveworkspace") {
            var mwParts = name === "moveworkspacev2" ? event.parse(3) : event.parse(2)
            var movedWsRaw = mwParts[0] || ""
            var movedMonName = name === "moveworkspacev2" ? (mwParts[2] || "") : (mwParts[1] || "")
            var movedWsId = parseInt(String(movedWsRaw).trim(), 10)
            if (_isValidWorkspaceId(movedWsId) && String(movedMonName).trim().length > 0) {
                var dstMonIdx = _resolveMonitorIndexByName(movedMonName)
                eventBus.emit("workspace", {
                    source: "bridge",
                    type: "activated",
                    monitorIndex: dstMonIdx,
                    current: movedWsId
                })
            }
            _requestMonitors()
        } else if (name === "monitoradded" || name === "monitorremoved" || name === "monitoraddedv2" || name === "monitorremovedv2") {
            Hyprland.refreshMonitors()
            Hyprland.refreshWorkspaces()
            _requestMonitors()
        }
    }

    // =========================================================
    // Monitor & Workspace Commands
    // =========================================================

    function focusMonitor(monitorIndex) {
        if (!connected) {
            if (logger) logger.warn("HyprlandBridge",
                "Cannot focus monitor %1 — Hyprland bridge is not connected.".arg(monitorIndex))
            return false
        }

        var monName = _resolveMonitorNameByIndex(monitorIndex)
        if (monName.length === 0) {
            if (logger) logger.warn("HyprlandBridge",
                "Cannot focus monitor %1 — unknown monitor index.".arg(monitorIndex))
            return false
        }

        _focusedMonitorIndex = monitorIndex
        if (logger) logger.info("HyprlandBridge",
            "Focusing monitor %1 ('%2', lua=%3)".arg(monitorIndex).arg(monName).arg(usingLua))

        if (usingLua) {
            Hyprland.dispatch("hl.dsp.focus({ monitor = \"" + monName + "\" })")
        } else {
            Hyprland.dispatch("focusmonitor " + monName)
        }
        return true
    }

    function getActiveWorkspaceId(monitorIndex) {
        var targetMon = (typeof monitorIndex === "number" && !isNaN(monitorIndex))
            ? monitorIndex
            : _focusedMonitorIndex

        if (workspaceModel) {
            return workspaceModel.getActiveWorkspace(targetMon)
        }

        if (!connected || !Hyprland.monitors) return 1
        var rawMonitors = Hyprland.monitors.values || []
        for (var i = 0; i < rawMonitors.length; i++) {
            var m = rawMonitors[i]
            if (m && m.id === targetMon && m.activeWorkspace && _isValidWorkspaceId(m.activeWorkspace.id)) {
                return m.activeWorkspace.id
            }
        }
        return 1
    }

    function switchWorkspace(workspaceId, monitorIndex) {
        if (!_isValidWorkspaceId(workspaceId)) {
            if (logger) logger.warn("HyprlandBridge",
                "Invalid workspace ID: %1 (must be integer 1–10)".arg(workspaceId))
            return false
        }

        if (!connected) {
            if (logger) logger.warn("HyprlandBridge",
                "Cannot switch to workspace %1 — Hyprland bridge is not connected.".arg(workspaceId))
            return false
        }

        if (typeof monitorIndex === "number" && !isNaN(monitorIndex) && monitorIndex !== _focusedMonitorIndex) {
            if (!focusMonitor(monitorIndex)) {
                return false
            }
        }

        if (logger) logger.info("HyprlandBridge",
            "Switching monitor %1 to workspace %2 (lua=%3)"
                .arg(_focusedMonitorIndex).arg(workspaceId).arg(usingLua))

        if (usingLua) {
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + workspaceId.toString() + " })")
        } else {
            Hyprland.dispatch("workspace " + workspaceId.toString())
        }
        return true
    }

    function switchWorkspaceRelative(delta, monitorIndex) {
        if (!connected) {
            if (logger) logger.warn("HyprlandBridge",
                "Cannot step workspace by %1 — Hyprland bridge is not connected.".arg(delta))
            return false
        }

        var targetMon = (typeof monitorIndex === "number" && !isNaN(monitorIndex))
            ? Math.floor(monitorIndex)
            : _focusedMonitorIndex
        var step = (typeof delta === "number" && !isNaN(delta))
            ? (delta >= 0 ? Math.floor(delta) : Math.ceil(delta))
            : 0
        if (step === 0) return false

        var currentWs = getActiveWorkspaceId(targetMon)
        var targetWs = Math.max(1, Math.min(10, currentWs + step))
        if (targetWs === currentWs) {
            if (logger) logger.debug("HyprlandBridge",
                "Workspace boundary reached on monitor %1 (workspace=%2, delta=%3)"
                    .arg(targetMon).arg(currentWs).arg(step))
            return false
        }

        return switchWorkspace(targetWs, targetMon)
    }

    function nextWorkspace(monitorIndex) {
        return switchWorkspaceRelative(1, monitorIndex)
    }

    function previousWorkspace(monitorIndex) {
        return switchWorkspaceRelative(-1, monitorIndex)
    }

    // =========================================================
    // Window Commands
    // =========================================================

    function moveWindowToWorkspace(windowAddress, workspaceId) {
        if (!_isValidWorkspaceId(workspaceId) || !windowAddress) {
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
        if (!connected) return 0
        if (_cachedMonitors.length > 0) return _cachedMonitors.length
        if (!Hyprland.monitors || !Hyprland.monitors.values) return 0
        return Hyprland.monitors.values.length
    }

    // =========================================================
    // Teardown
    // =========================================================

    function teardown() {
        var wasConnected = connected
        connected = false
        _monitorsQueryInFlight = false
        _monitorsQueryPending = false
        _monitorsBuffer = ""
        _monitorsSocket.connected = false
        _cachedMonitors = []
        _focusedMonitorIndex = 0
        if (wasConnected && logger) {
            logger.info("HyprlandBridge", "Hyprland bridge disconnected.")
        }
    }

    Component.onCompleted: {
        if (logger) logger.debug("HyprlandBridge",
            "Hyprland bridge created. Call initialize() to connect.")
    }
}
