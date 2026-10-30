// BASEUS — Hyprland Integration Bridge
// Copyright (c) 2026 xoradesu — MIT License
//
// Isolates all Hyprland-specific IPC communication behind a clean boundary.
// The rest of BASEUS consumes normalized state/events through ShellState,
// domain models, and EventBus, not raw Hyprland details.
//
// Responsibilities:
//   - Hyprland IPC availability detection and honest diagnostics
//   - Direct UNIX domain socket (j/monitors, j/clients, [[BATCH]] dispatch over .socket.sock)
//     compatible with Hyprland 0.57+ without spawning child processes
//   - Fixed 1–10 per-monitor workspace state observation & navigation (DEC-010)
//   - Freeform floating window state, live geometry, focus history, and default float/center (DEC-008)
//   - Geometric maximize (preserving layout boundaries) vs native compositor fullscreen (DEC-023)
//   - Scratchpad-free minimize & centered restore onto target monitor (DEC-038)
//   - POP workspace & monitor movement hooks preserving focus semantics (MASTER.md §35)

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
    property var windowModel: null

    // =========================================================
    // Connection & Layout Configuration
    // =========================================================
    readonly property bool isMock: false
    property bool connected: false
    property string lastError: ""
    property int layoutGapOut: 16
    property int _minimizedParkCoord: -16000

    property int _focusedMonitorIndex: 0
    property var _cachedMonitors: []
    property var _seenWindowAddresses: ({})
    property var _savedGeometries: ({})
    property var _minimizedMeta: ({})

    readonly property string instanceSignature: String(Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "")
    readonly property string requestSocketPath: String(Hyprland.requestSocketPath || "")
    readonly property string eventSocketPath: String(Hyprland.eventSocketPath || "")
    readonly property bool runtimeAvailable: instanceSignature.length > 0 && eventSocketPath.length > 0
    readonly property bool usingLua: Boolean(Hyprland.usingLua)

    // =========================================================
    // 1. Direct .socket.sock Query Client: j/monitors
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
            if (Number(socketError) === 1) return
            hyprlandBridge._monitorsQueryInFlight = false
            hyprlandBridge._monitorsBuffer = ""
            if (hyprlandBridge.logger) {
                hyprlandBridge.logger.warn("HyprlandBridge",
                    "j/monitors socket query error (%1)".arg(socketError))
            }
            if (connected) connected = false
        }

        parser: SplitParser {
            splitMarker: ""
            onRead: function(chunk) {
                hyprlandBridge._monitorsBuffer += chunk
            }
        }
    }

    // =========================================================
    // 2. Direct .socket.sock Query Client: j/clients
    // =========================================================
    property bool _clientsQueryInFlight: false
    property bool _clientsQueryPending: false
    property string _clientsBuffer: ""

    property Socket _clientsSocket: Socket {
        onConnectionStateChanged: {
            if (connected) {
                hyprlandBridge._clientsBuffer = ""
                write("j/clients")
                flush()
            } else if (hyprlandBridge._clientsQueryInFlight) {
                hyprlandBridge._clientsQueryInFlight = false
                var payload = hyprlandBridge._clientsBuffer
                hyprlandBridge._clientsBuffer = ""
                if (payload.trim().length > 0) {
                    hyprlandBridge._handleClientsJson(payload)
                }
                if (hyprlandBridge._clientsQueryPending && hyprlandBridge.connected) {
                    hyprlandBridge._clientsQueryPending = false
                    hyprlandBridge._requestClients()
                }
            }
        }

        onError: function(socketError) {
            if (Number(socketError) === 1) return
            hyprlandBridge._clientsQueryInFlight = false
            hyprlandBridge._clientsBuffer = ""
            if (hyprlandBridge.logger) {
                hyprlandBridge.logger.warn("HyprlandBridge",
                    "j/clients socket query error (%1)".arg(socketError))
            }
            if (connected) connected = false
        }

        parser: SplitParser {
            splitMarker: ""
            onRead: function(chunk) {
                hyprlandBridge._clientsBuffer += chunk
            }
        }
    }

    // =========================================================
    // 3. Direct .socket.sock FIFO Batch Dispatcher
    // =========================================================
    property var _dispatchQueue: []
    property bool _dispatchInFlight: false
    property var _activeDispatchJob: null
    property string _dispatchBuffer: ""

    property Socket _dispatchSocket: Socket {
        onConnectionStateChanged: {
            if (connected) {
                hyprlandBridge._dispatchBuffer = ""
                if (hyprlandBridge._activeDispatchJob && hyprlandBridge._activeDispatchJob.wire) {
                    write(hyprlandBridge._activeDispatchJob.wire)
                    flush()
                } else {
                    connected = false
                }
            } else if (hyprlandBridge._dispatchInFlight) {
                var finishedJob = hyprlandBridge._activeDispatchJob
                var resp = hyprlandBridge._dispatchBuffer.trim()
                hyprlandBridge._dispatchBuffer = ""
                hyprlandBridge._activeDispatchJob = null
                hyprlandBridge._dispatchInFlight = false

                if (resp.length > 0 && hyprlandBridge.logger) {
                    var lines = resp.split("\n")
                    for (var i = 0; i < lines.length; i++) {
                        var t = lines[i].trim()
                        if (t.length > 0 && t !== "ok") {
                            hyprlandBridge.logger.warn("HyprlandBridge",
                                "Compositor dispatch diagnostic: %1".arg(t))
                        }
                    }
                }

                if (finishedJob && hyprlandBridge.connected) {
                    if (finishedJob.refreshMonitors) {
                        hyprlandBridge._requestMonitors()
                    }
                    if (finishedJob.refreshClients) {
                        hyprlandBridge._requestClients()
                    }
                }

                if (hyprlandBridge.connected && hyprlandBridge._dispatchQueue.length > 0) {
                    hyprlandBridge._pumpDispatchQueue()
                }
            }
        }

        onError: function(socketError) {
            if (Number(socketError) === 1) return
            hyprlandBridge._dispatchInFlight = false
            hyprlandBridge._activeDispatchJob = null
            hyprlandBridge._dispatchBuffer = ""
            if (hyprlandBridge.logger) {
                hyprlandBridge.logger.warn("HyprlandBridge",
                    "Dispatch socket error (%1)".arg(socketError))
            }
            if (connected) connected = false
            if (hyprlandBridge.connected && hyprlandBridge._dispatchQueue.length > 0) {
                hyprlandBridge._pumpDispatchQueue()
            }
        }

        parser: SplitParser {
            splitMarker: ""
            onRead: function(chunk) {
                hyprlandBridge._dispatchBuffer += chunk
            }
        }
    }

    function _dispatchBatch(commands, refreshClientsAfter, refreshMonitorsAfter) {
        if (!connected || requestSocketPath.length === 0 || !Array.isArray(commands)) return false
        var clean = []
        for (var i = 0; i < commands.length; i++) {
            var cmd = String(commands[i] || "").trim()
            if (cmd.length > 0) clean.push(cmd)
        }
        if (clean.length === 0) return false

        var wire = clean.length === 1
            ? ("dispatch " + clean[0])
            : ("[[BATCH]]dispatch " + clean.join(";dispatch "))

        var nextQ = _dispatchQueue.slice()
        nextQ.push({
            wire: wire,
            refreshClients: Boolean(refreshClientsAfter),
            refreshMonitors: Boolean(refreshMonitorsAfter)
        })
        _dispatchQueue = nextQ
        _pumpDispatchQueue()
        return true
    }

    function _pumpDispatchQueue() {
        if (!connected || _dispatchInFlight || _dispatchQueue.length === 0) return
        var nextQ = _dispatchQueue.slice()
        var job = nextQ.shift()
        _dispatchQueue = nextQ

        if (_dispatchSocket.connected) {
            _dispatchSocket.connected = false
        }
        _dispatchBuffer = ""
        _activeDispatchJob = job
        _dispatchInFlight = true
        _dispatchSocket.path = requestSocketPath
        _dispatchSocket.connected = true
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
            _requestClients()
        }
    }

    // =========================================================
    // Address, Geometry & Monitor Helpers
    // =========================================================

    function _normalizeAddress(address) {
        var raw = String(address || "").trim()
        if (raw.length === 0) return ""
        return "0x" + raw.replace(/^0x/i, "")
    }

    function _resolveTargetAddress(windowAddress) {
        var explicitAddr = _normalizeAddress(windowAddress)
        if (explicitAddr.length > 0) return explicitAddr
        if (windowModel && windowModel.focusedAddress.length > 0) return windowModel.focusedAddress
        if (Hyprland.activeToplevel && Hyprland.activeToplevel.address) {
            return _normalizeAddress(Hyprland.activeToplevel.address)
        }
        return ""
    }

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

    function _getMonitorGeometry(monitorIndex) {
        var target = (typeof monitorIndex === "number" && !isNaN(monitorIndex) && monitorIndex >= 0)
            ? Math.floor(monitorIndex)
            : _focusedMonitorIndex

        for (var c = 0; c < _cachedMonitors.length; c++) {
            if (_cachedMonitors[c] && _cachedMonitors[c].index === target) {
                return _cachedMonitors[c]
            }
        }

        if (monitorModel) {
            var found = monitorModel.getMonitor(target)
            if (found) return found
        }

        if (_cachedMonitors.length > 0) return _cachedMonitors[0]
        return { index: 0, name: "monitor-0", x: 0, y: 0, width: 1920, height: 1080, scale: 1.0 }
    }

    function _computeMonitorCenteredPosition(winWidth, winHeight, monitorIndex) {
        var mon = _getMonitorGeometry(monitorIndex)
        var scale = (typeof mon.scale === "number" && mon.scale > 0) ? mon.scale : 1.0
        var logicalW = Math.round(((typeof mon.width === "number" && mon.width > 0) ? mon.width : 1920) / scale)
        var logicalH = Math.round(((typeof mon.height === "number" && mon.height > 0) ? mon.height : 1080) / scale)
        var w = (typeof winWidth === "number" && !isNaN(winWidth) && winWidth > 0) ? Math.round(winWidth) : 800
        var h = (typeof winHeight === "number" && !isNaN(winHeight) && winHeight > 0) ? Math.round(winHeight) : 480
        var monX = (typeof mon.x === "number" && !isNaN(mon.x)) ? mon.x : 0
        var monY = (typeof mon.y === "number" && !isNaN(mon.y)) ? mon.y : 0

        return {
            x: Math.round(monX + (logicalW - w) / 2),
            y: Math.round(monY + (logicalH - h) / 2),
            width: w,
            height: h,
            monitor: mon.index
        }
    }

    function _computeMonitorMaximizedBox(monitorIndex) {
        var mon = _getMonitorGeometry(monitorIndex)
        var scale = (typeof mon.scale === "number" && mon.scale > 0) ? mon.scale : 1.0
        var logicalW = Math.round(((typeof mon.width === "number" && mon.width > 0) ? mon.width : 1920) / scale)
        var logicalH = Math.round(((typeof mon.height === "number" && mon.height > 0) ? mon.height : 1080) / scale)
        var gap = Math.max(0, Math.round(layoutGapOut))
        var monX = (typeof mon.x === "number" && !isNaN(mon.x)) ? mon.x : 0
        var monY = (typeof mon.y === "number" && !isNaN(mon.y)) ? mon.y : 0

        return {
            x: Math.round(monX + gap),
            y: Math.round(monY + gap),
            width: Math.max(160, Math.round(logicalW - 2 * gap)),
            height: Math.max(120, Math.round(logicalH - 2 * gap)),
            monitor: mon.index
        }
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
    // Dual Lua (0.57+) / Hyprlang (< 0.57) Command Builders
    // =========================================================

    function _cmdFocusMonitor(monName) {
        return usingLua
            ? ("hl.dsp.focus({ monitor = \"" + monName + "\" })")
            : ("focusmonitor " + monName)
    }

    function _cmdFocusWorkspace(workspaceId) {
        return usingLua
            ? ("hl.dsp.focus({ workspace = " + workspaceId.toString() + " })")
            : ("workspace " + workspaceId.toString())
    }

    function _cmdFocusWindow(addr) {
        return usingLua
            ? ("hl.dsp.focus({ window = \"address:" + addr + "\" })")
            : ("focuswindow address:" + addr)
    }

    function _cmdRaiseWindow(addr) {
        return usingLua
            ? ("hl.dsp.window.alter_zorder({ mode = \"top\", window = \"address:" + addr + "\" })")
            : ("alterzorder top,address:" + addr)
    }

    function _cmdCloseWindow(addr) {
        return usingLua
            ? ("hl.dsp.window.close({ window = \"address:" + addr + "\" })")
            : ("closewindow address:" + addr)
    }

    function _cmdSetFloating(addr, action) {
        if (usingLua) {
            var luaAction = (action === "set" || action === "on" || action === "enable")
                ? "on"
                : ((action === "unset" || action === "off" || action === "disable") ? "off" : "toggle")
            return "hl.dsp.window.float({ action = \"" + luaAction + "\", window = \"address:" + addr + "\" })"
        }
        if (action === "set" || action === "on" || action === "enable") return "setfloating address:" + addr
        if (action === "unset" || action === "off" || action === "disable") return "settiled address:" + addr
        return "togglefloating address:" + addr
    }

    function _cmdMoveWindowExact(addr, x, y) {
        var rx = Math.round(x).toString()
        var ry = Math.round(y).toString()
        return usingLua
            ? ("hl.dsp.window.move({ x = " + rx + ", y = " + ry + ", relative = false, window = \"address:" + addr + "\" })")
            : ("movewindowpixel exact " + rx + " " + ry + ",address:" + addr)
    }

    function _cmdResizeWindowExact(addr, w, h) {
        var rw = Math.max(1, Math.round(w)).toString()
        var rh = Math.max(1, Math.round(h)).toString()
        return usingLua
            ? ("hl.dsp.window.resize({ x = " + rw + ", y = " + rh + ", relative = false, window = \"address:" + addr + "\" })")
            : ("resizewindowpixel exact " + rw + " " + rh + ",address:" + addr)
    }

    function _cmdTagWindow(addr, tagExpr) {
        return usingLua
            ? ("hl.dsp.window.tag({ tag = \"" + tagExpr + "\", window = \"address:" + addr + "\" })")
            : ("tagwindow " + tagExpr + " address:" + addr)
    }

    function _cmdNativeFullscreen(action) {
        return usingLua
            ? ("hl.dsp.window.fullscreen({ mode = \"fullscreen\", action = \"" + action + "\" })")
            : "fullscreen 0"
    }

    function _cmdMoveWindowToWorkspace(addr, workspaceId, silent) {
        var wsStr = workspaceId.toString()
        if (usingLua) {
            return "hl.dsp.window.move({ workspace = " + wsStr + ", follow = " + (silent ? "false" : "true") + ", window = \"address:" + addr + "\" })"
        }
        return (silent ? "movetoworkspacesilent " : "movetoworkspace ") + wsStr + ",address:" + addr
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
        _seenWindowAddresses = ({})
        _savedGeometries = ({})
        _minimizedMeta = ({})
        _monitorsQueryInFlight = false
        _monitorsQueryPending = false
        _clientsQueryInFlight = false
        _clientsQueryPending = false
        _dispatchQueue = []
        _dispatchInFlight = false
        _activeDispatchJob = null
        connected = true
        if (logger) logger.info("HyprlandBridge",
            "Hyprland bridge connected (instance=%1).".arg(instanceSignature))

        Hyprland.refreshMonitors()
        Hyprland.refreshWorkspaces()
        Hyprland.refreshToplevels()
        _syncMonitors()
        _syncWorkspaces()
        _requestMonitors()
        _requestClients()
        return true
    }

    // =========================================================
    // Direct Socket Synchronization: j/monitors & j/clients
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

    function _requestClients() {
        if (!connected || requestSocketPath.length === 0) return
        if (_clientsQueryInFlight) {
            _clientsQueryPending = true
            return
        }
        if (_clientsSocket.connected) {
            _clientsSocket.connected = false
        }
        _clientsBuffer = ""
        _clientsQueryInFlight = true
        _clientsQueryPending = false
        _clientsSocket.path = requestSocketPath
        _clientsSocket.connected = true
    }

    function _handleClientsJson(rawJson) {
        if (!connected || !eventBus) return
        var trimmed = String(rawJson || "").trim()
        if (trimmed.length === 0) return

        var parsed = null
        try {
            parsed = JSON.parse(trimmed)
        } catch (e) {
            if (logger) logger.warn("HyprlandBridge",
                "Failed to parse j/clients JSON: %1".arg(e.message || String(e)))
            return
        }

        if (!Array.isArray(parsed)) return

        var list = []
        var bestFocusAddr = ""
        var bestFocusRank = 999999
        var enforcementCmds = []
        var nextSeen = {}

        for (var i = 0; i < parsed.length; i++) {
            var c = parsed[i]
            if (!c || c.mapped === false) continue

            var addr = _normalizeAddress(c.address)
            if (addr.length === 0) continue

            var rawWsId = (c.workspace && typeof c.workspace.id === "number") ? c.workspace.id : 1
            var wsId = _isValidWorkspaceId(rawWsId) ? rawWsId : 1
            var monIdx = (typeof c.monitor === "number" && c.monitor >= 0) ? c.monitor : _focusedMonitorIndex

            var atArr = Array.isArray(c.at) ? c.at : [0, 0]
            var sizeArr = Array.isArray(c.size) ? c.size : [800, 480]
            var xVal = (typeof atArr[0] === "number" && !isNaN(atArr[0])) ? Math.round(atArr[0]) : 0
            var yVal = (typeof atArr[1] === "number" && !isNaN(atArr[1])) ? Math.round(atArr[1]) : 0
            var wVal = (typeof sizeArr[0] === "number" && !isNaN(sizeArr[0]) && sizeArr[0] > 0) ? Math.round(sizeArr[0]) : 800
            var hVal = (typeof sizeArr[1] === "number" && !isNaN(sizeArr[1]) && sizeArr[1] > 0) ? Math.round(sizeArr[1]) : 480

            var tagsArr = Array.isArray(c.tags) ? c.tags : []
            var hasMinTag = tagsArr.indexOf("baseus_minimized") !== -1
            var hasMaxTag = tagsArr.indexOf("baseus_maximized") !== -1

            var fsMode = (typeof c.fullscreen === "number") ? c.fullscreen : (c.fullscreen ? 2 : 0)
            var isNativeFullscreen = (!hasMinTag && fsMode === 2)
            var isMaximized = (!hasMinTag && !isNativeFullscreen && (fsMode === 1 || hasMaxTag))
            var isFloating = Boolean(c.floating)
            var focusRank = (typeof c.focusHistoryID === "number" && c.focusHistoryID >= 0) ? c.focusHistoryID : (1000 + i)

            // DEC-008: Enforce default freeform floating & centering for newly mapped windows
            // (also correcting 0x0 headless virtual-output negative centering coordinates).
            var isNewlySeen = !_seenWindowAddresses[addr]
            nextSeen[addr] = true

            if (isNewlySeen && !hasMinTag && !isNativeFullscreen && !isMaximized) {
                var monGeom = _getMonitorGeometry(monIdx)
                var monX = (typeof monGeom.x === "number") ? monGeom.x : 0
                var monY = (typeof monGeom.y === "number") ? monGeom.y : 0
                var needsFloat = !isFloating
                var needsCenter = needsFloat || (xVal < monX) || (yVal < monY)

                if (needsFloat) {
                    enforcementCmds.push(_cmdSetFloating(addr, "set"))
                    isFloating = true
                }
                if (needsCenter) {
                    var centeredNew = _computeMonitorCenteredPosition(wVal, hVal, monIdx)
                    enforcementCmds.push(_cmdMoveWindowExact(addr, centeredNew.x, centeredNew.y))
                    xVal = centeredNew.x
                    yVal = centeredNew.y
                }
            }

            if (!hasMinTag && focusRank < bestFocusRank) {
                bestFocusRank = focusRank
                bestFocusAddr = addr
            }

            var savedMeta = _minimizedMeta[addr] || null
            var savedGeom = _savedGeometries[addr] || (savedMeta ? savedMeta.savedGeometry : undefined)
            var originWs = (hasMinTag && savedMeta && _isValidWorkspaceId(savedMeta.originWorkspace))
                ? savedMeta.originWorkspace
                : wsId

            var entry = {
                address: addr,
                title: String(c.title || ""),
                appClass: String(c["class"] || c.initialClass || ""),
                workspace: wsId,
                originWorkspace: originWs,
                monitor: monIdx,
                x: xVal,
                y: yVal,
                width: wVal,
                height: hVal,
                floating: isFloating,
                fullscreen: isNativeFullscreen,
                maximized: isMaximized,
                minimized: hasMinTag,
                focused: false,
                focusOrder: focusRank
            }
            if (savedGeom) {
                entry.savedGeometry = savedGeom
            }
            list.push(entry)
        }

        _seenWindowAddresses = nextSeen

        for (var k = 0; k < list.length; k++) {
            list[k].focused = (!list[k].minimized && bestFocusAddr.length > 0 && list[k].address === bestFocusAddr)
        }

        eventBus.emit("window", {
            source: "bridge",
            type: "synced",
            windows: list,
            focusedAddress: bestFocusAddr
        })

        if (enforcementCmds.length > 0) {
            _dispatchBatch(enforcementCmds, true, false)
        }
    }

    // =========================================================
    // Fallback Initial State Sync & Event Translation
    // =========================================================

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
            ? _normalizeAddress(Hyprland.activeToplevel.address)
            : ""
        if (addr.length > 0 && windowModel) {
            var existing = windowModel.getWindowByAddress(addr)
            if (existing && existing.minimized) return
        }
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
            var parts = event.parse(4)
            if (parts && parts.length >= 4) {
                var wsNum = parseInt(parts[1], 10)
                var centeredDefault = _computeMonitorCenteredPosition(800, 480, _focusedMonitorIndex)
                eventBus.emit("window", {
                    source: "bridge",
                    type: "created",
                    window: {
                        address: _normalizeAddress(parts[0]),
                        workspace: _isValidWorkspaceId(wsNum) ? wsNum : 1,
                        monitor: _focusedMonitorIndex,
                        x: centeredDefault.x,
                        y: centeredDefault.y,
                        width: 800,
                        height: 480,
                        appClass: String(parts[2] || ""),
                        title: String(parts[3] || ""),
                        floating: true,
                        fullscreen: false,
                        maximized: false,
                        minimized: false,
                        focused: true
                    }
                })
            }
            Hyprland.refreshToplevels()
            _requestClients()
        } else if (name === "closewindow") {
            var closedAddr = _normalizeAddress(data)
            delete _seenWindowAddresses[closedAddr]
            delete _savedGeometries[closedAddr]
            delete _minimizedMeta[closedAddr]
            eventBus.emit("window", {
                source: "bridge",
                type: "destroyed",
                address: closedAddr
            })
            Hyprland.refreshToplevels()
            _requestClients()
        } else if (name === "activewindowv2") {
            var trimmedAddr = data.trim()
            var nextFocusAddr = trimmedAddr.length > 0 ? _normalizeAddress(trimmedAddr) : ""
            if (nextFocusAddr.length > 0 && windowModel) {
                var maybeMin = windowModel.getWindowByAddress(nextFocusAddr)
                if (maybeMin && maybeMin.minimized) return
            }
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
                    var movedAddr = _normalizeAddress(moveParts[0])
                    var targetMon = workspaceModel ? workspaceModel.getMonitorForWorkspace(targetWs) : -1
                    eventBus.emit("window", {
                        source: "bridge",
                        type: "moved",
                        transition: "pop",
                        address: movedAddr,
                        workspace: targetWs,
                        monitor: targetMon >= 0 ? targetMon : _focusedMonitorIndex
                    })
                }
            }
            _requestClients()
        } else if (name === "fullscreen" || name === "changefloatingmode" || name === "windowtitlev2") {
            // Query authoritative j/clients so Hyprland FSMODE_MAXIMIZED (1) vs FSMODE_FULLSCREEN (2),
            // floating toggles, and live geometry are disambiguated per DEC-023.
            _requestClients()
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
            _requestClients()
        } else if (name === "monitoradded" || name === "monitorremoved" || name === "monitoraddedv2" || name === "monitorremovedv2") {
            Hyprland.refreshMonitors()
            Hyprland.refreshWorkspaces()
            _requestMonitors()
            _requestClients()
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

        return _dispatchBatch([_cmdFocusMonitor(monName)], false, false)
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

        var cmds = []
        if (typeof monitorIndex === "number" && !isNaN(monitorIndex) && monitorIndex !== _focusedMonitorIndex) {
            var monName = _resolveMonitorNameByIndex(monitorIndex)
            if (monName.length === 0) {
                if (logger) logger.warn("HyprlandBridge",
                    "Cannot switch workspace on unknown monitor %1.".arg(monitorIndex))
                return false
            }
            _focusedMonitorIndex = monitorIndex
            cmds.push(_cmdFocusMonitor(monName))
        }

        cmds.push(_cmdFocusWorkspace(workspaceId))

        if (logger) logger.info("HyprlandBridge",
            "Switching monitor %1 to workspace %2 (lua=%3)"
                .arg(_focusedMonitorIndex).arg(workspaceId).arg(usingLua))

        return _dispatchBatch(cmds, false, false)
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
    // Freeform Window Capability Commands (M1-T2)
    // =========================================================

    function focusWindow(windowAddress) {
        if (!connected) return false
        var addr = _resolveTargetAddress(windowAddress)
        if (addr.length === 0) return false

        var win = windowModel ? windowModel.getWindowByAddress(addr) : null
        if (win && win.minimized) {
            return restoreWindow(addr)
        }

        if (eventBus) {
            eventBus.emit("window", {
                source: "bridge",
                type: "focused",
                address: addr
            })
        }
        return _dispatchBatch([_cmdFocusWindow(addr), _cmdRaiseWindow(addr)], true, false)
    }

    function closeWindow(windowAddress) {
        if (!connected) return false
        var addr = _resolveTargetAddress(windowAddress)
        if (addr.length === 0) return false

        var win = windowModel ? windowModel.getWindowByAddress(addr) : null
        var cmds = []
        if (win && win.minimized) {
            cmds.push(_cmdTagWindow(addr, "-baseus_minimized"))
        }
        cmds.push(_cmdCloseWindow(addr))
        return _dispatchBatch(cmds, true, false)
    }

    function moveWindow(windowAddress, x, y) {
        if (!connected || typeof x !== "number" || typeof y !== "number" || isNaN(x) || isNaN(y)) return false
        var addr = _resolveTargetAddress(windowAddress)
        if (addr.length === 0) return false

        var win = windowModel ? windowModel.getWindowByAddress(addr) : null
        if (win && win.minimized) return false

        var cmds = []
        if (win && win.fullscreen) {
            cmds.push(_cmdFocusWindow(addr))
            cmds.push(_cmdNativeFullscreen("unset"))
            if (eventBus) {
                eventBus.emit("window", { source: "bridge", type: "fullscreen", address: addr, fullscreen: false })
            }
        }
        if (win && win.maximized) {
            delete _savedGeometries[addr]
            cmds.push(_cmdTagWindow(addr, "-baseus_maximized"))
            if (eventBus) {
                eventBus.emit("window", { source: "bridge", type: "maximized", address: addr, maximized: false })
            }
        }
        if (!win || !win.floating) {
            cmds.push(_cmdSetFloating(addr, "set"))
        }
        cmds.push(_cmdMoveWindowExact(addr, x, y))

        if (eventBus) {
            eventBus.emit("window", {
                source: "bridge",
                type: "geometry",
                address: addr,
                x: Math.round(x),
                y: Math.round(y)
            })
        }
        return _dispatchBatch(cmds, true, false)
    }

    function resizeWindow(windowAddress, width, height) {
        if (!connected || typeof width !== "number" || typeof height !== "number"
            || isNaN(width) || isNaN(height) || width <= 0 || height <= 0) {
            return false
        }
        var addr = _resolveTargetAddress(windowAddress)
        if (addr.length === 0) return false

        var win = windowModel ? windowModel.getWindowByAddress(addr) : null
        if (win && win.minimized) return false

        var cmds = []
        if (win && win.fullscreen) {
            cmds.push(_cmdFocusWindow(addr))
            cmds.push(_cmdNativeFullscreen("unset"))
            if (eventBus) {
                eventBus.emit("window", { source: "bridge", type: "fullscreen", address: addr, fullscreen: false })
            }
        }
        if (win && win.maximized) {
            delete _savedGeometries[addr]
            cmds.push(_cmdTagWindow(addr, "-baseus_maximized"))
            if (eventBus) {
                eventBus.emit("window", { source: "bridge", type: "maximized", address: addr, maximized: false })
            }
        }
        if (!win || !win.floating) {
            cmds.push(_cmdSetFloating(addr, "set"))
        }
        cmds.push(_cmdResizeWindowExact(addr, width, height))
        if (win) {
            // Hyprland resizes floating windows around their center; re-anchor top-left (x, y).
            cmds.push(_cmdMoveWindowExact(addr, win.x, win.y))
        }

        if (eventBus) {
            eventBus.emit("window", {
                source: "bridge",
                type: "geometry",
                address: addr,
                width: Math.round(width),
                height: Math.round(height)
            })
        }
        return _dispatchBatch(cmds, true, false)
    }

    function centerWindow(windowAddress, monitorIndex) {
        if (!connected) return false
        var addr = _resolveTargetAddress(windowAddress)
        if (addr.length === 0) return false

        var win = windowModel ? windowModel.getWindowByAddress(addr) : null
        if (win && win.minimized) {
            return restoreWindow(addr, undefined, monitorIndex)
        }

        var targetMon = (typeof monitorIndex === "number" && !isNaN(monitorIndex) && monitorIndex >= 0)
            ? Math.floor(monitorIndex)
            : (win ? win.monitor : _focusedMonitorIndex)

        var baseGeom = (win && win.maximized && (win.savedGeometry || _savedGeometries[addr]))
            ? (win.savedGeometry || _savedGeometries[addr])
            : { width: win ? win.width : 800, height: win ? win.height : 480 }

        var centered = _computeMonitorCenteredPosition(baseGeom.width, baseGeom.height, targetMon)
        var cmds = []

        if (win && win.fullscreen) {
            cmds.push(_cmdFocusWindow(addr))
            cmds.push(_cmdNativeFullscreen("unset"))
            if (eventBus) {
                eventBus.emit("window", { source: "bridge", type: "fullscreen", address: addr, fullscreen: false })
            }
        }
        if (win && win.maximized) {
            delete _savedGeometries[addr]
            cmds.push(_cmdTagWindow(addr, "-baseus_maximized"))
            cmds.push(_cmdResizeWindowExact(addr, centered.width, centered.height))
            if (eventBus) {
                eventBus.emit("window", { source: "bridge", type: "maximized", address: addr, maximized: false })
            }
        }
        if (!win || !win.floating) {
            cmds.push(_cmdSetFloating(addr, "set"))
        }
        cmds.push(_cmdMoveWindowExact(addr, centered.x, centered.y))

        if (eventBus) {
            eventBus.emit("window", {
                source: "bridge",
                type: "geometry",
                address: addr,
                monitor: centered.monitor,
                x: centered.x,
                y: centered.y,
                width: centered.width,
                height: centered.height
            })
        }
        return _dispatchBatch(cmds, true, false)
    }

    function setFloating(windowAddress, floating) {
        if (!connected) return false
        var addr = _resolveTargetAddress(windowAddress)
        if (addr.length === 0) return false

        var win = windowModel ? windowModel.getWindowByAddress(addr) : null
        if (win && win.minimized) return false

        var nextFloat = (floating === undefined) ? !(win ? win.floating : true) : Boolean(floating)
        if (win && win.floating === nextFloat) return true

        var cmds = []
        if (!nextFloat && win && win.maximized) {
            delete _savedGeometries[addr]
            cmds.push(_cmdTagWindow(addr, "-baseus_maximized"))
            if (eventBus) {
                eventBus.emit("window", { source: "bridge", type: "maximized", address: addr, maximized: false })
            }
        }

        cmds.push(_cmdSetFloating(addr, nextFloat ? "set" : "unset"))

        if (nextFloat && win) {
            var floatW = (win.width > 0) ? win.width : 800
            var floatH = (win.height > 0) ? win.height : 480
            var centered = _computeMonitorCenteredPosition(floatW, floatH, win.monitor)
            cmds.push(_cmdResizeWindowExact(addr, centered.width, centered.height))
            cmds.push(_cmdMoveWindowExact(addr, centered.x, centered.y))
            if (eventBus) {
                eventBus.emit("window", {
                    source: "bridge",
                    type: "floating",
                    address: addr,
                    floating: true
                })
                eventBus.emit("window", {
                    source: "bridge",
                    type: "geometry",
                    address: addr,
                    x: centered.x,
                    y: centered.y,
                    width: centered.width,
                    height: centered.height
                })
            }
            return _dispatchBatch(cmds, true, false)
        }

        if (eventBus) {
            eventBus.emit("window", {
                source: "bridge",
                type: "floating",
                address: addr,
                floating: nextFloat
            })
        }
        return _dispatchBatch(cmds, true, false)
    }

    function toggleFloating(windowAddress) {
        return setFloating(windowAddress, undefined)
    }

    // DEC-023: Geometric maximize preserving layout boundaries (distinct from native fullscreen).
    // Never toggles ShellState.mode into "fullscreen".
    function setMaximized(windowAddress, maximized) {
        if (!connected) return false
        var addr = _resolveTargetAddress(windowAddress)
        if (addr.length === 0) return false

        var win = windowModel ? windowModel.getWindowByAddress(addr) : null
        if (!win || win.minimized) return false

        var nextMax = (maximized === undefined) ? !win.maximized : Boolean(maximized)
        if (nextMax === win.maximized) return true

        var cmds = []
        if (nextMax) {
            var preGeom = (win.savedGeometry && win.savedGeometry.width > 0)
                ? win.savedGeometry
                : { x: win.x, y: win.y, width: win.width, height: win.height }
            _savedGeometries[addr] = preGeom

            if (win.fullscreen) {
                cmds.push(_cmdFocusWindow(addr))
                cmds.push(_cmdNativeFullscreen("unset"))
                if (eventBus) {
                    eventBus.emit("window", { source: "bridge", type: "fullscreen", address: addr, fullscreen: false })
                }
            }
            if (!win.floating) {
                cmds.push(_cmdSetFloating(addr, "set"))
            }

            var maxBox = _computeMonitorMaximizedBox(win.monitor)
            cmds.push(_cmdTagWindow(addr, "+baseus_maximized"))
            cmds.push(_cmdResizeWindowExact(addr, maxBox.width, maxBox.height))
            cmds.push(_cmdMoveWindowExact(addr, maxBox.x, maxBox.y))
            cmds.push(_cmdFocusWindow(addr))
            cmds.push(_cmdRaiseWindow(addr))

            if (eventBus) {
                eventBus.emit("window", {
                    source: "bridge",
                    type: "maximized",
                    address: addr,
                    maximized: true,
                    savedGeometry: preGeom,
                    x: maxBox.x,
                    y: maxBox.y,
                    width: maxBox.width,
                    height: maxBox.height
                })
            }
        } else {
            var restoreGeom = win.savedGeometry || _savedGeometries[addr]
                || _computeMonitorCenteredPosition(800, 480, win.monitor)
            delete _savedGeometries[addr]

            cmds.push(_cmdTagWindow(addr, "-baseus_maximized"))
            if (!win.floating) {
                cmds.push(_cmdSetFloating(addr, "set"))
            }
            cmds.push(_cmdResizeWindowExact(addr, restoreGeom.width, restoreGeom.height))
            cmds.push(_cmdMoveWindowExact(addr, restoreGeom.x, restoreGeom.y))

            if (eventBus) {
                eventBus.emit("window", {
                    source: "bridge",
                    type: "maximized",
                    address: addr,
                    maximized: false,
                    x: restoreGeom.x,
                    y: restoreGeom.y,
                    width: restoreGeom.width,
                    height: restoreGeom.height
                })
            }
        }

        return _dispatchBatch(cmds, true, false)
    }

    function toggleMaximize(windowAddress) {
        return setMaximized(windowAddress, undefined)
    }

    // DEC-023: Native compositor fullscreen — toggles ShellState.mode ("desktop" <-> "fullscreen").
    function setFullscreen(windowAddress, fullscreen) {
        if (!connected) return false
        var addr = _resolveTargetAddress(windowAddress)
        if (addr.length === 0) return false

        var win = windowModel ? windowModel.getWindowByAddress(addr) : null
        if (!win || win.minimized) return false

        var nextFs = (fullscreen === undefined) ? !win.fullscreen : Boolean(fullscreen)
        if (nextFs === win.fullscreen) return true

        var cmds = []
        if (nextFs && win.maximized) {
            var baseGeom = win.savedGeometry || _savedGeometries[addr]
            delete _savedGeometries[addr]
            cmds.push(_cmdTagWindow(addr, "-baseus_maximized"))
            if (baseGeom) {
                cmds.push(_cmdResizeWindowExact(addr, baseGeom.width, baseGeom.height))
                cmds.push(_cmdMoveWindowExact(addr, baseGeom.x, baseGeom.y))
            }
        }

        cmds.push(_cmdFocusWindow(addr))
        cmds.push(_cmdNativeFullscreen(nextFs ? "set" : "unset"))

        if (eventBus) {
            eventBus.emit("window", {
                source: "bridge",
                type: "fullscreen",
                address: addr,
                fullscreen: nextFs
            })
        }
        return _dispatchBatch(cmds, true, false)
    }

    function toggleFullscreen(windowAddress) {
        return setFullscreen(windowAddress, undefined)
    }

    // DEC-038: Scratchpad-free minimize (NEVER uses special:* workspaces).
    function minimizeWindow(windowAddress) {
        if (!connected) return false
        var addr = _resolveTargetAddress(windowAddress)
        if (addr.length === 0) return false

        var win = windowModel ? windowModel.getWindowByAddress(addr) : null
        if (!win || win.minimized) return false

        var originWs = win.workspace
        var originMon = win.monitor
        var savedGeom = (win.maximized && (win.savedGeometry || _savedGeometries[addr]))
            ? (win.savedGeometry || _savedGeometries[addr])
            : { x: win.x, y: win.y, width: win.width, height: win.height }

        _minimizedMeta[addr] = {
            originWorkspace: originWs,
            originMonitor: originMon,
            savedGeometry: savedGeom
        }
        delete _savedGeometries[addr]

        var nextFocus = windowModel
            ? windowModel.getNextFocusableWindow(addr, originWs, originMon)
            : null

        var cmds = []
        if (win.fullscreen) {
            cmds.push(_cmdFocusWindow(addr))
            cmds.push(_cmdNativeFullscreen("unset"))
        }
        if (win.maximized) {
            cmds.push(_cmdTagWindow(addr, "-baseus_maximized"))
        }
        if (!win.floating) {
            cmds.push(_cmdSetFloating(addr, "set"))
        }
        cmds.push(_cmdTagWindow(addr, "+baseus_minimized"))
        cmds.push(_cmdMoveWindowExact(addr, _minimizedParkCoord, _minimizedParkCoord))

        if (nextFocus) {
            cmds.push(_cmdFocusWindow(nextFocus.address))
            cmds.push(_cmdRaiseWindow(nextFocus.address))
        }

        if (logger) logger.info("HyprlandBridge",
            "Minimized window %1 on workspace %2 (scratchpad-free)".arg(addr).arg(originWs))

        if (eventBus) {
            eventBus.emit("window", {
                source: "bridge",
                type: "minimized",
                address: addr,
                originWorkspace: originWs,
                monitor: originMon,
                savedGeometry: savedGeom
            })
            if (nextFocus) {
                eventBus.emit("window", {
                    source: "bridge",
                    type: "focused",
                    address: nextFocus.address
                })
            }
        }

        return _dispatchBatch(cmds, true, false)
    }

    // DEC-038 & MASTER.md §36: Centered restore onto target monitor & workspace.
    function restoreWindow(windowAddress, targetWorkspaceId, targetMonitorIndex) {
        if (!connected) return false

        var win = null
        var explicitAddr = _normalizeAddress(windowAddress)
        if (explicitAddr.length > 0 && windowModel) {
            win = windowModel.getWindowByAddress(explicitAddr)
        } else if (windowModel) {
            var minList = windowModel.getMinimizedWindows()
            if (minList.length > 0) win = minList[0]
        }
        if (!win || !win.minimized) return false

        var addr = win.address
        var meta = _minimizedMeta[addr] || null
        var targetMon = (typeof targetMonitorIndex === "number" && !isNaN(targetMonitorIndex) && targetMonitorIndex >= 0)
            ? Math.floor(targetMonitorIndex)
            : (shellState ? shellState.activeMonitorIndex : _focusedMonitorIndex)

        var targetWs = _isValidWorkspaceId(targetWorkspaceId)
            ? targetWorkspaceId
            : getActiveWorkspaceId(targetMon)

        var baseGeom = (win.savedGeometry && win.savedGeometry.width > 0)
            ? win.savedGeometry
            : ((meta && meta.savedGeometry && meta.savedGeometry.width > 0)
                ? meta.savedGeometry
                : { width: win.width, height: win.height })

        var centered = _computeMonitorCenteredPosition(baseGeom.width, baseGeom.height, targetMon)
        delete _minimizedMeta[addr]

        var cmds = []
        cmds.push(_cmdTagWindow(addr, "-baseus_minimized"))
        if (!win.floating) {
            cmds.push(_cmdSetFloating(addr, "set"))
        }

        if (targetMon !== _focusedMonitorIndex) {
            var monName = _resolveMonitorNameByIndex(targetMon)
            if (monName.length > 0) {
                _focusedMonitorIndex = targetMon
                cmds.push(_cmdFocusMonitor(monName))
            }
        }

        if (win.workspace !== targetWs) {
            var visibleOwner = workspaceModel ? workspaceModel.getMonitorForWorkspace(targetWs) : -1
            var moveSilently = (visibleOwner >= 0 && visibleOwner === targetMon)
            cmds.push(_cmdMoveWindowToWorkspace(addr, targetWs, moveSilently))
        } else if (getActiveWorkspaceId(targetMon) !== targetWs) {
            cmds.push(_cmdFocusWorkspace(targetWs))
        }

        cmds.push(_cmdResizeWindowExact(addr, centered.width, centered.height))
        cmds.push(_cmdMoveWindowExact(addr, centered.x, centered.y))
        cmds.push(_cmdFocusWindow(addr))
        cmds.push(_cmdRaiseWindow(addr))

        if (logger) logger.info("HyprlandBridge",
            "Restored window %1 centered on monitor %2 workspace %3 (%4,%5 %6x%7)"
                .arg(addr).arg(centered.monitor).arg(targetWs)
                .arg(centered.x).arg(centered.y).arg(centered.width).arg(centered.height))

        if (eventBus) {
            eventBus.emit("window", {
                source: "bridge",
                type: "restored",
                address: addr,
                workspace: targetWs,
                monitor: centered.monitor,
                x: centered.x,
                y: centered.y,
                width: centered.width,
                height: centered.height,
                focused: true
            })
        }

        return _dispatchBatch(cmds, true, false)
    }

    // MASTER.md §35: POP workspace-move hook preserving focus semantics.
    function moveWindowToWorkspace(windowAddress, workspaceId, followFocus) {
        if (!_isValidWorkspaceId(workspaceId)) {
            if (logger) logger.warn("HyprlandBridge",
                "Invalid workspace ID in moveWindowToWorkspace: %1".arg(workspaceId))
            return false
        }
        if (!connected) return false

        var addr = _resolveTargetAddress(windowAddress)
        if (addr.length === 0) return false

        var shouldFollow = (followFocus === undefined) ? true : Boolean(followFocus)
        var win = windowModel ? windowModel.getWindowByAddress(addr) : null
        var prevWs = win ? win.workspace : getActiveWorkspaceId(_focusedMonitorIndex)
        var prevMon = win ? win.monitor : _focusedMonitorIndex
        var ownerMon = workspaceModel ? workspaceModel.getMonitorForWorkspace(workspaceId) : -1
        var targetMon = (ownerMon >= 0) ? ownerMon : prevMon

        var cmds = []
        if (shouldFollow && targetMon !== _focusedMonitorIndex) {
            var monName = _resolveMonitorNameByIndex(targetMon)
            if (monName.length > 0) {
                _focusedMonitorIndex = targetMon
                cmds.push(_cmdFocusMonitor(monName))
            }
        }

        cmds.push(_cmdMoveWindowToWorkspace(addr, workspaceId, !shouldFollow))

        var nextX = win ? win.x : undefined
        var nextY = win ? win.y : undefined

        if (targetMon !== prevMon && win && !win.minimized) {
            if (win.maximized) {
                var dstMax = _computeMonitorMaximizedBox(targetMon)
                cmds.push(_cmdResizeWindowExact(addr, dstMax.width, dstMax.height))
                cmds.push(_cmdMoveWindowExact(addr, dstMax.x, dstMax.y))
                nextX = dstMax.x
                nextY = dstMax.y
            } else {
                var dstCenter = _computeMonitorCenteredPosition(win.width, win.height, targetMon)
                cmds.push(_cmdResizeWindowExact(addr, dstCenter.width, dstCenter.height))
                cmds.push(_cmdMoveWindowExact(addr, dstCenter.x, dstCenter.y))
                nextX = dstCenter.x
                nextY = dstCenter.y
            }
        }

        if (shouldFollow) {
            if (!win || !win.minimized) {
                cmds.push(_cmdFocusWindow(addr))
                cmds.push(_cmdRaiseWindow(addr))
            }
        } else if (win && win.focused) {
            var nextOnOrigin = windowModel
                ? windowModel.getNextFocusableWindow(addr, prevWs, prevMon)
                : null
            if (nextOnOrigin) {
                cmds.push(_cmdFocusWindow(nextOnOrigin.address))
                cmds.push(_cmdRaiseWindow(nextOnOrigin.address))
            }
        }

        if (logger) logger.info("HyprlandBridge",
            "POP moving window %1: ws %2 (mon %3) → ws %4 (mon %5, followFocus=%6)"
                .arg(addr).arg(prevWs).arg(prevMon).arg(workspaceId).arg(targetMon).arg(shouldFollow))

        if (eventBus) {
            eventBus.emit("window", {
                source: "bridge",
                type: "moved",
                transition: "pop",
                address: addr,
                fromWorkspace: prevWs,
                workspace: workspaceId,
                fromMonitor: prevMon,
                monitor: targetMon,
                x: nextX,
                y: nextY,
                followFocus: shouldFollow
            })
        }

        return _dispatchBatch(cmds, true, targetMon !== prevMon)
    }

    function moveWindowToMonitor(windowAddress, monitorIndex, followFocus) {
        if (!connected || typeof monitorIndex !== "number" || isNaN(monitorIndex) || monitorIndex < 0) {
            return false
        }
        var targetMon = Math.floor(monitorIndex)
        var monName = _resolveMonitorNameByIndex(targetMon)
        if (monName.length === 0) {
            if (logger) logger.warn("HyprlandBridge",
                "Cannot move window to unknown monitor %1.".arg(targetMon))
            return false
        }

        var targetWs = getActiveWorkspaceId(targetMon)
        return moveWindowToWorkspace(windowAddress, targetWs, followFocus)
    }

    // =========================================================
    // Monitor Queries & Teardown
    // =========================================================

    function getMonitorCount() {
        if (!connected) return 0
        if (_cachedMonitors.length > 0) return _cachedMonitors.length
        if (!Hyprland.monitors || !Hyprland.monitors.values) return 0
        return Hyprland.monitors.values.length
    }

    function teardown() {
        var wasConnected = connected
        connected = false
        _monitorsQueryInFlight = false
        _monitorsQueryPending = false
        _monitorsBuffer = ""
        _monitorsSocket.connected = false

        _clientsQueryInFlight = false
        _clientsQueryPending = false
        _clientsBuffer = ""
        _clientsSocket.connected = false

        _dispatchQueue = []
        _dispatchInFlight = false
        _activeDispatchJob = null
        _dispatchBuffer = ""
        _dispatchSocket.connected = false

        _cachedMonitors = []
        _seenWindowAddresses = ({})
        _savedGeometries = ({})
        _minimizedMeta = ({})
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
