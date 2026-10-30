pragma ComponentBehavior: Bound

// BASEUS — Mock Hyprland Integration Bridge
// Copyright (c) 2026 xoradesu — MIT License
//
// Provides a complete offline simulation of Hyprland IPC events.
// Used when developing on Windows, WSL2 without a live Hyprland compositor,
// or outside an active Hyprland session, allowing state, event, window
// lifecycle, and design layers to be tested deterministically.
//
// Emits identical normalized events into EventBus as HyprlandBridge:
//   - "monitor": synced, focused
//   - "workspace": synced, activated
//   - "window": synced, created, destroyed, focused, geometry, floating,
//               maximized, fullscreen, minimized, restored, moved (POP)

import QtQuick

QtObject {
    id: mockBridge

    // =========================================================
    // Dependencies (injected by Shell.qml)
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var shellState: null
    property var workspaceModel: null
    property var monitorModel: null
    property var windowModel: null

    // =========================================================
    // Simulation State
    // =========================================================
    readonly property bool isMock: true
    property bool connected: false
    property string lastError: ""
    property int layoutGapOut: 16
    property int _nextMockId: 4

    property int focusedMonitorIndex: 0
    property int currentWorkspace: 1
    property var mockActiveWorkspaces: ({ 0: 1 })
    property var mockMonitors: []
    property string focusedWindowAddress: "0x1a2b"
    property var mockWindows: []

    function _normalizeAddress(address) {
        var raw = String(address || "").trim()
        if (raw.length === 0) return ""
        return "0x" + raw.replace(/^0x/i, "")
    }

    function _resolveTargetAddress(windowAddress) {
        var explicitAddr = _normalizeAddress(windowAddress)
        if (explicitAddr.length > 0) return explicitAddr
        if (windowModel && windowModel.focusedAddress.length > 0) return windowModel.focusedAddress
        return focusedWindowAddress
    }

    function _isValidWorkspaceId(workspaceId) {
        return typeof workspaceId === "number"
            && !isNaN(workspaceId)
            && Math.floor(workspaceId) === workspaceId
            && workspaceId >= 1
            && workspaceId <= 10
    }

    function _defaultMockMonitors(count) {
        var total = (typeof count === "number" && count >= 1) ? Math.floor(count) : 1
        var list = []
        for (var i = 0; i < total; i++) {
            list.push({
                index: i,
                name: "SIM-" + (i + 1),
                width: 1920,
                height: 1080,
                x: i * 1920,
                y: 0,
                scale: 1.0,
                active: true
            })
        }
        return list
    }

    function _getMonitorGeometry(monitorIndex) {
        var target = (typeof monitorIndex === "number" && !isNaN(monitorIndex) && monitorIndex >= 0)
            ? Math.floor(monitorIndex)
            : focusedMonitorIndex
        for (var i = 0; i < mockMonitors.length; i++) {
            if (mockMonitors[i].index === target) return mockMonitors[i]
        }
        if (mockMonitors.length > 0) return mockMonitors[0]
        return { index: 0, name: "SIM-1", x: 0, y: 0, width: 1920, height: 1080, scale: 1.0 }
    }

    function _computeCenteredPosition(winWidth, winHeight, monitorIndex) {
        var mon = _getMonitorGeometry(monitorIndex)
        var w = (typeof winWidth === "number" && !isNaN(winWidth) && winWidth > 0) ? Math.round(winWidth) : 800
        var h = (typeof winHeight === "number" && !isNaN(winHeight) && winHeight > 0) ? Math.round(winHeight) : 480
        return {
            x: Math.round(mon.x + (mon.width - w) / 2),
            y: Math.round(mon.y + (mon.height - h) / 2),
            width: w,
            height: h,
            monitor: mon.index
        }
    }

    function _computeMaximizedBox(monitorIndex) {
        var mon = _getMonitorGeometry(monitorIndex)
        var gap = Math.max(0, Math.round(layoutGapOut))
        return {
            x: Math.round(mon.x + gap),
            y: Math.round(mon.y + gap),
            width: Math.max(160, Math.round(mon.width - 2 * gap)),
            height: Math.max(120, Math.round(mon.height - 2 * gap)),
            monitor: mon.index
        }
    }

    function _defaultMockWindows() {
        return [
            {
                address: "0x1a2b",
                title: "terminal — zsh",
                appClass: "kitty",
                workspace: 1,
                originWorkspace: 1,
                monitor: 0,
                x: 560,
                y: 280,
                width: 800,
                height: 520,
                floating: true,
                fullscreen: false,
                maximized: false,
                minimized: false,
                focused: true,
                focusOrder: 0
            },
            {
                address: "0x3c4d",
                title: "Mozilla Firefox",
                appClass: "firefox",
                workspace: 1,
                originWorkspace: 1,
                monitor: 0,
                x: 400,
                y: 170,
                width: 1120,
                height: 740,
                floating: true,
                fullscreen: false,
                maximized: false,
                minimized: false,
                focused: false,
                focusOrder: 1
            },
            {
                address: "0x5e6f",
                title: "BASEUS — Neovim",
                appClass: "nvim",
                workspace: 2,
                originWorkspace: 2,
                monitor: 0,
                x: 480,
                y: 220,
                width: 960,
                height: 640,
                floating: true,
                fullscreen: false,
                maximized: false,
                minimized: false,
                focused: false,
                focusOrder: 2
            }
        ]
    }

    function _getMockWindow(address) {
        var addr = _normalizeAddress(address)
        for (var i = 0; i < mockWindows.length; i++) {
            if (mockWindows[i].address === addr) return mockWindows[i]
        }
        return null
    }

    function _updateMockWindow(address, mutator) {
        var addr = _normalizeAddress(address)
        var updated = null
        var next = []
        for (var i = 0; i < mockWindows.length; i++) {
            var copy = {}
            for (var k in mockWindows[i]) {
                copy[k] = mockWindows[i][k]
            }
            if (copy.address === addr) {
                mutator(copy)
                updated = copy
            }
            next.push(copy)
        }
        if (updated) {
            mockWindows = next
        }
        return updated
    }

    // =========================================================
    // Initialization
    // =========================================================

    function initialize() {
        if (logger) logger.info("MockBridge", "Starting offline Hyprland simulation...")

        focusedMonitorIndex = 0
        currentWorkspace = 1
        _nextMockId = 4
        mockMonitors = _defaultMockMonitors(1)
        mockActiveWorkspaces = ({ 0: 1 })
        focusedWindowAddress = "0x1a2b"
        mockWindows = _defaultMockWindows()

        if (eventBus) {
            eventBus.emit("monitor", {
                source: "bridge",
                type: "synced",
                focusedIndex: focusedMonitorIndex,
                monitors: mockMonitors
            })

            eventBus.emit("workspace", {
                source: "bridge",
                type: "synced",
                activeWorkspaces: mockActiveWorkspaces
            })

            eventBus.emit("window", {
                source: "bridge",
                type: "synced",
                windows: mockWindows,
                focusedAddress: focusedWindowAddress
            })
        }

        connected = true
        lastError = ""
        if (logger) logger.info("MockBridge",
            "Simulation active (10 workspaces, %1 monitor(s), %2 sample windows)."
                .arg(mockMonitors.length).arg(mockWindows.length))
        return true
    }

    // =========================================================
    // Multi-Monitor Simulation
    // =========================================================

    function setMockMonitorCount(count) {
        if (!connected || typeof count !== "number" || isNaN(count) || count < 1) return false
        var total = Math.floor(count)
        mockMonitors = _defaultMockMonitors(total)

        var nextMap = {}
        for (var i = 0; i < total; i++) {
            var existing = mockActiveWorkspaces[i]
            nextMap[i] = _isValidWorkspaceId(existing) ? existing : Math.min(10, i + 1)
        }
        mockActiveWorkspaces = nextMap
        if (focusedMonitorIndex >= total) {
            focusedMonitorIndex = 0
        }
        currentWorkspace = mockActiveWorkspaces[focusedMonitorIndex] || 1

        if (eventBus) {
            eventBus.emit("monitor", {
                source: "bridge",
                type: "synced",
                focusedIndex: focusedMonitorIndex,
                monitors: mockMonitors
            })
            eventBus.emit("workspace", {
                source: "bridge",
                type: "synced",
                activeWorkspaces: mockActiveWorkspaces
            })
        }
        return true
    }

    function focusMonitor(monitorIndex) {
        if (!connected || typeof monitorIndex !== "number" || isNaN(monitorIndex)) return false
        var target = Math.floor(monitorIndex)
        if (target < 0 || target >= mockMonitors.length) {
            if (logger) logger.warn("MockBridge",
                "Cannot focus monitor %1 — simulated monitor count is %2.".arg(target).arg(mockMonitors.length))
            return false
        }

        focusedMonitorIndex = target
        currentWorkspace = getActiveWorkspaceId(target)

        if (eventBus) {
            eventBus.emit("monitor", {
                source: "bridge",
                type: "focused",
                index: target
            })
        }
        return true
    }

    // =========================================================
    // Workspace Simulation (DEC-010: Exactly 10 workspaces)
    // =========================================================

    function getActiveWorkspaceId(monitorIndex) {
        var mon = (typeof monitorIndex === "number" && !isNaN(monitorIndex))
            ? Math.floor(monitorIndex)
            : focusedMonitorIndex
        if (workspaceModel) {
            return workspaceModel.getActiveWorkspace(mon)
        }
        var ws = mockActiveWorkspaces[mon]
        return _isValidWorkspaceId(ws) ? ws : 1
    }

    function switchWorkspace(workspaceId, monitorIndex) {
        if (!_isValidWorkspaceId(workspaceId)) {
            if (logger) logger.warn("MockBridge",
                "Invalid workspace ID: %1 (must be integer 1–10)".arg(workspaceId))
            return false
        }

        if (!connected) return false

        var targetMon = (typeof monitorIndex === "number" && !isNaN(monitorIndex))
            ? Math.floor(monitorIndex)
            : focusedMonitorIndex

        if (workspaceModel && monitorIndex === undefined) {
            var existingOwner = workspaceModel.getMonitorForWorkspace(workspaceId)
            if (existingOwner >= 0 && existingOwner < mockMonitors.length) {
                targetMon = existingOwner
            }
        }

        if (targetMon < 0 || targetMon >= mockMonitors.length) {
            if (logger) logger.warn("MockBridge",
                "Invalid monitor index %1 in switchWorkspace.".arg(targetMon))
            return false
        }

        if (targetMon !== focusedMonitorIndex) {
            focusMonitor(targetMon)
        }

        var previous = getActiveWorkspaceId(targetMon)
        var nextMap = {}
        for (var k in mockActiveWorkspaces) {
            nextMap[k] = mockActiveWorkspaces[k]
        }
        nextMap[targetMon] = workspaceId
        mockActiveWorkspaces = nextMap
        currentWorkspace = workspaceId

        if (logger) logger.info("MockBridge",
            "Simulating monitor %1 workspace switch: %2 → %3"
                .arg(targetMon).arg(previous).arg(workspaceId))

        if (eventBus) {
            eventBus.emit("workspace", {
                source: "bridge",
                type: "activated",
                monitorIndex: targetMon,
                previous: previous,
                current: workspaceId
            })
        }
        return true
    }

    function switchWorkspaceRelative(delta, monitorIndex) {
        if (!connected) return false
        var targetMon = (typeof monitorIndex === "number" && !isNaN(monitorIndex))
            ? Math.floor(monitorIndex)
            : focusedMonitorIndex
        var step = (typeof delta === "number" && !isNaN(delta))
            ? (delta >= 0 ? Math.floor(delta) : Math.ceil(delta))
            : 0
        if (step === 0) return false

        var currentWs = getActiveWorkspaceId(targetMon)
        var targetWs = Math.max(1, Math.min(10, currentWs + step))
        if (targetWs === currentWs) return false
        return switchWorkspace(targetWs, targetMon)
    }

    function nextWorkspace(monitorIndex) {
        return switchWorkspaceRelative(1, monitorIndex)
    }

    function previousWorkspace(monitorIndex) {
        return switchWorkspaceRelative(-1, monitorIndex)
    }

    // =========================================================
    // Freeform Window Simulation (M1-T2)
    // =========================================================

    function addMockWindow(title, appClass, workspaceId, width, height) {
        if (!connected) return ""
        var wsId = _isValidWorkspaceId(workspaceId) ? workspaceId : getActiveWorkspaceId(focusedMonitorIndex)
        var ownerMon = workspaceModel ? workspaceModel.getMonitorForWorkspace(wsId) : -1
        var monIdx = ownerMon >= 0 ? ownerMon : focusedMonitorIndex
        var centered = _computeCenteredPosition(width || 800, height || 480, monIdx)
        var addr = "0x" + (0x7000 + (_nextMockId++)).toString(16)

        var win = {
            address: addr,
            title: String(title || "New Window"),
            appClass: String(appClass || "app"),
            workspace: wsId,
            originWorkspace: wsId,
            monitor: centered.monitor,
            x: centered.x,
            y: centered.y,
            width: centered.width,
            height: centered.height,
            floating: true,
            fullscreen: false,
            maximized: false,
            minimized: false,
            focused: true,
            focusOrder: 0
        }

        var next = []
        for (var i = 0; i < mockWindows.length; i++) {
            var copy = {}
            for (var k in mockWindows[i]) copy[k] = mockWindows[i][k]
            copy.focused = false
            next.push(copy)
        }
        next.push(win)
        mockWindows = next
        focusedWindowAddress = addr

        if (eventBus) {
            eventBus.emit("window", { source: "bridge", type: "created", window: win })
        }
        return addr
    }

    function focusWindow(windowAddress) {
        if (!connected) return false
        var addr = _resolveTargetAddress(windowAddress)
        if (addr.length === 0) return false

        var existing = (windowModel && windowModel.getWindowByAddress(addr)) || _getMockWindow(addr)
        if (!existing) return false
        if (existing.minimized) {
            return restoreWindow(addr)
        }

        focusedWindowAddress = addr
        var next = []
        for (var i = 0; i < mockWindows.length; i++) {
            var copy = {}
            for (var k in mockWindows[i]) copy[k] = mockWindows[i][k]
            copy.focused = (copy.address === addr)
            next.push(copy)
        }
        mockWindows = next

        if (eventBus) {
            eventBus.emit("window", {
                source: "bridge",
                type: "focused",
                address: addr
            })
        }
        return true
    }

    function closeWindow(windowAddress) {
        if (!connected) return false
        var addr = _resolveTargetAddress(windowAddress)
        if (addr.length === 0) return false

        var existing = (windowModel && windowModel.getWindowByAddress(addr)) || _getMockWindow(addr)
        if (!existing) return false

        var next = mockWindows.filter(function(w) { return w.address !== addr })
        mockWindows = next

        var nextFocus = windowModel
            ? windowModel.getNextFocusableWindow(addr, existing.workspace, existing.monitor)
            : null
        focusedWindowAddress = nextFocus ? nextFocus.address : ""

        if (eventBus) {
            eventBus.emit("window", {
                source: "bridge",
                type: "destroyed",
                address: addr
            })
            eventBus.emit("window", {
                source: "bridge",
                type: "focused",
                address: focusedWindowAddress
            })
        }
        return true
    }

    function moveWindow(windowAddress, x, y) {
        if (!connected || typeof x !== "number" || typeof y !== "number" || isNaN(x) || isNaN(y)) return false
        var addr = _resolveTargetAddress(windowAddress)
        var win = (windowModel && windowModel.getWindowByAddress(addr)) || _getMockWindow(addr)
        if (!win || win.minimized) return false

        if (win.fullscreen) setFullscreen(addr, false)
        if (win.maximized) {
            _updateMockWindow(addr, function(w) {
                w.maximized = false
                w.savedGeometry = null
            })
            if (eventBus) {
                eventBus.emit("window", { source: "bridge", type: "maximized", address: addr, maximized: false })
            }
        }

        var rx = Math.round(x)
        var ry = Math.round(y)
        _updateMockWindow(addr, function(w) {
            w.floating = true
            w.x = rx
            w.y = ry
        })
        if (eventBus) {
            eventBus.emit("window", { source: "bridge", type: "geometry", address: addr, x: rx, y: ry })
        }
        return true
    }

    function resizeWindow(windowAddress, width, height) {
        if (!connected || typeof width !== "number" || typeof height !== "number"
            || isNaN(width) || isNaN(height) || width <= 0 || height <= 0) {
            return false
        }
        var addr = _resolveTargetAddress(windowAddress)
        var win = (windowModel && windowModel.getWindowByAddress(addr)) || _getMockWindow(addr)
        if (!win || win.minimized) return false

        if (win.fullscreen) setFullscreen(addr, false)
        if (win.maximized) {
            _updateMockWindow(addr, function(w) {
                w.maximized = false
                w.savedGeometry = null
            })
            if (eventBus) {
                eventBus.emit("window", { source: "bridge", type: "maximized", address: addr, maximized: false })
            }
        }

        var rw = Math.round(width)
        var rh = Math.round(height)
        _updateMockWindow(addr, function(w) {
            w.floating = true
            w.width = rw
            w.height = rh
        })
        if (eventBus) {
            eventBus.emit("window", { source: "bridge", type: "geometry", address: addr, width: rw, height: rh })
        }
        return true
    }

    function centerWindow(windowAddress, monitorIndex) {
        if (!connected) return false
        var addr = _resolveTargetAddress(windowAddress)
        var win = (windowModel && windowModel.getWindowByAddress(addr)) || _getMockWindow(addr)
        if (!win) return false
        if (win.minimized) {
            return restoreWindow(addr, undefined, monitorIndex)
        }

        var targetMon = (typeof monitorIndex === "number" && !isNaN(monitorIndex) && monitorIndex >= 0)
            ? Math.floor(monitorIndex)
            : win.monitor
        var baseGeom = (win.maximized && win.savedGeometry) ? win.savedGeometry : { width: win.width, height: win.height }
        var centered = _computeCenteredPosition(baseGeom.width, baseGeom.height, targetMon)

        if (win.fullscreen) setFullscreen(addr, false)
        if (win.maximized && eventBus) {
            eventBus.emit("window", { source: "bridge", type: "maximized", address: addr, maximized: false })
        }

        _updateMockWindow(addr, function(w) {
            w.floating = true
            w.maximized = false
            w.savedGeometry = null
            w.monitor = centered.monitor
            w.x = centered.x
            w.y = centered.y
            w.width = centered.width
            w.height = centered.height
        })

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
        return true
    }

    function setFloating(windowAddress, floating) {
        if (!connected) return false
        var addr = _resolveTargetAddress(windowAddress)
        var win = (windowModel && windowModel.getWindowByAddress(addr)) || _getMockWindow(addr)
        if (!win) return false

        var nextFloat = (floating === undefined) ? !win.floating : Boolean(floating)
        _updateMockWindow(addr, function(w) { w.floating = nextFloat })
        if (eventBus) {
            eventBus.emit("window", { source: "bridge", type: "floating", address: addr, floating: nextFloat })
        }
        return true
    }

    function toggleFloating(windowAddress) {
        return setFloating(windowAddress, undefined)
    }

    function setMaximized(windowAddress, maximized) {
        if (!connected) return false
        var addr = _resolveTargetAddress(windowAddress)
        var win = (windowModel && windowModel.getWindowByAddress(addr)) || _getMockWindow(addr)
        if (!win || win.minimized) return false

        var nextMax = (maximized === undefined) ? !win.maximized : Boolean(maximized)
        if (nextMax === win.maximized) return true

        if (nextMax) {
            var preGeom = (win.savedGeometry && win.savedGeometry.width > 0)
                ? win.savedGeometry
                : { x: win.x, y: win.y, width: win.width, height: win.height }
            if (win.fullscreen && eventBus) {
                eventBus.emit("window", { source: "bridge", type: "fullscreen", address: addr, fullscreen: false })
            }
            var maxBox = _computeMaximizedBox(win.monitor)
            _updateMockWindow(addr, function(w) {
                w.fullscreen = false
                w.maximized = true
                w.floating = true
                w.savedGeometry = preGeom
                w.x = maxBox.x
                w.y = maxBox.y
                w.width = maxBox.width
                w.height = maxBox.height
            })
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
            var restoreGeom = win.savedGeometry || _computeCenteredPosition(800, 480, win.monitor)
            _updateMockWindow(addr, function(w) {
                w.maximized = false
                w.savedGeometry = null
                w.x = restoreGeom.x
                w.y = restoreGeom.y
                w.width = restoreGeom.width
                w.height = restoreGeom.height
            })
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
        return true
    }

    function toggleMaximize(windowAddress) {
        return setMaximized(windowAddress, undefined)
    }

    function setFullscreen(windowAddress, fullscreen) {
        if (!connected) return false
        var addr = _resolveTargetAddress(windowAddress)
        var win = (windowModel && windowModel.getWindowByAddress(addr)) || _getMockWindow(addr)
        if (!win || win.minimized) return false

        var nextFs = (fullscreen === undefined) ? !win.fullscreen : Boolean(fullscreen)
        if (nextFs === win.fullscreen) return true

        _updateMockWindow(addr, function(w) {
            w.fullscreen = nextFs
            if (nextFs) w.maximized = false
        })

        if (eventBus) {
            eventBus.emit("window", {
                source: "bridge",
                type: "fullscreen",
                address: addr,
                fullscreen: nextFs
            })
        }
        return true
    }

    function toggleFullscreen(windowAddress) {
        return setFullscreen(windowAddress, undefined)
    }

    function minimizeWindow(windowAddress) {
        if (!connected) return false
        var addr = _resolveTargetAddress(windowAddress)
        var win = (windowModel && windowModel.getWindowByAddress(addr)) || _getMockWindow(addr)
        if (!win || win.minimized) return false

        var originWs = win.workspace
        var originMon = win.monitor
        var savedGeom = (win.maximized && win.savedGeometry)
            ? win.savedGeometry
            : { x: win.x, y: win.y, width: win.width, height: win.height }

        var nextFocus = windowModel
            ? windowModel.getNextFocusableWindow(addr, originWs, originMon)
            : null

        _updateMockWindow(addr, function(w) {
            w.minimized = true
            w.fullscreen = false
            w.maximized = false
            w.focused = false
            w.originWorkspace = originWs
            w.savedGeometry = savedGeom
        })

        focusedWindowAddress = nextFocus ? nextFocus.address : ""

        if (eventBus) {
            eventBus.emit("window", {
                source: "bridge",
                type: "minimized",
                address: addr,
                originWorkspace: originWs,
                monitor: originMon,
                savedGeometry: savedGeom
            })
            eventBus.emit("window", {
                source: "bridge",
                type: "focused",
                address: focusedWindowAddress
            })
        }
        return true
    }

    function restoreWindow(windowAddress, targetWorkspaceId, targetMonitorIndex) {
        if (!connected) return false

        var win = null
        var explicitAddr = _normalizeAddress(windowAddress)
        if (explicitAddr.length > 0) {
            win = (windowModel && windowModel.getWindowByAddress(explicitAddr)) || _getMockWindow(explicitAddr)
        } else if (windowModel) {
            var minList = windowModel.getMinimizedWindows()
            if (minList.length > 0) win = minList[0]
        }
        if (!win || !win.minimized) return false

        var addr = win.address
        var targetMon = (typeof targetMonitorIndex === "number" && !isNaN(targetMonitorIndex) && targetMonitorIndex >= 0)
            ? Math.floor(targetMonitorIndex)
            : focusedMonitorIndex
        if (targetMon >= mockMonitors.length) targetMon = 0

        var targetWs = _isValidWorkspaceId(targetWorkspaceId)
            ? targetWorkspaceId
            : getActiveWorkspaceId(targetMon)

        var baseGeom = (win.savedGeometry && win.savedGeometry.width > 0)
            ? win.savedGeometry
            : { width: win.width, height: win.height }
        var centered = _computeCenteredPosition(baseGeom.width, baseGeom.height, targetMon)

        if (targetMon !== focusedMonitorIndex) {
            focusMonitor(targetMon)
        }
        if (getActiveWorkspaceId(targetMon) !== targetWs) {
            switchWorkspace(targetWs, targetMon)
        }

        _updateMockWindow(addr, function(w) {
            w.minimized = false
            w.fullscreen = false
            w.maximized = false
            w.floating = true
            w.savedGeometry = null
            w.workspace = targetWs
            w.originWorkspace = targetWs
            w.monitor = centered.monitor
            w.x = centered.x
            w.y = centered.y
            w.width = centered.width
            w.height = centered.height
            w.focused = true
        })
        focusedWindowAddress = addr

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
        return true
    }

    function moveWindowToWorkspace(windowAddress, workspaceId, followFocus) {
        if (!connected || !_isValidWorkspaceId(workspaceId)) return false
        var addr = _resolveTargetAddress(windowAddress)
        var win = (windowModel && windowModel.getWindowByAddress(addr)) || _getMockWindow(addr)
        if (!win) return false

        var shouldFollow = (followFocus === undefined) ? true : Boolean(followFocus)
        var prevWs = win.workspace
        var prevMon = win.monitor
        var ownerMon = workspaceModel ? workspaceModel.getMonitorForWorkspace(workspaceId) : -1
        var targetMon = (ownerMon >= 0) ? ownerMon : prevMon

        var nextX = win.x
        var nextY = win.y
        if (targetMon !== prevMon && !win.minimized) {
            var dstBox = win.maximized
                ? _computeMaximizedBox(targetMon)
                : _computeCenteredPosition(win.width, win.height, targetMon)
            nextX = dstBox.x
            nextY = dstBox.y
        }

        _updateMockWindow(addr, function(w) {
            w.workspace = workspaceId
            if (!w.minimized) w.originWorkspace = workspaceId
            w.monitor = targetMon
            w.x = nextX
            w.y = nextY
            if (shouldFollow && !w.minimized) w.focused = true
        })

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

        if (shouldFollow) {
            if (targetMon !== focusedMonitorIndex) {
                focusMonitor(targetMon)
            }
            if (getActiveWorkspaceId(targetMon) !== workspaceId) {
                switchWorkspace(workspaceId, targetMon)
            }
            if (!win.minimized) {
                focusWindow(addr)
            }
        } else if (win.focused) {
            var nextOnOrigin = windowModel
                ? windowModel.getNextFocusableWindow(addr, prevWs, prevMon)
                : null
            focusedWindowAddress = nextOnOrigin ? nextOnOrigin.address : ""
            if (eventBus) {
                eventBus.emit("window", {
                    source: "bridge",
                    type: "focused",
                    address: focusedWindowAddress
                })
            }
        }
        return true
    }

    function moveWindowToMonitor(windowAddress, monitorIndex, followFocus) {
        if (!connected || typeof monitorIndex !== "number" || isNaN(monitorIndex)) return false
        var targetMon = Math.floor(monitorIndex)
        if (targetMon < 0 || targetMon >= mockMonitors.length) return false
        var targetWs = getActiveWorkspaceId(targetMon)
        return moveWindowToWorkspace(windowAddress, targetWs, followFocus)
    }

    function getMonitorCount() {
        return connected ? mockMonitors.length : 0
    }

    // =========================================================
    // Teardown
    // =========================================================

    function teardown() {
        var wasConnected = connected
        connected = false
        focusedMonitorIndex = 0
        if (wasConnected && logger) logger.info("MockBridge", "Mock simulation stopped.")
    }
}
