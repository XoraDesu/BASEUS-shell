// BASEUS — Window Model
// Copyright (c) 2026 xoradesu — MIT License
//
// Tracks freeform window state for the BASEUS shell.
// Per MASTER.md §6, §35, §36, §38 and DEC-008, DEC-023, DEC-038:
//   - Freeform floating windows by default
//   - Centered new-window placement and centered restore
//   - Live geometry (x, y, width, height) and MRU focusHistory tracking
//   - Explicit separation between geometric maximize and native fullscreen (DEC-023)
//   - Scratchpad-free minimize & restore preserving originWorkspace (DEC-038)
//   - Normalized POP workspace/monitor move hooks (MASTER.md §35)
//
// State ownership:
//   - WindowModel owns the BASEUS view of window state
//   - HyprlandBridge / MockHyprlandBridge provides normalized window events
//   - ShellState and UI surfaces consume window state from here

import QtQuick

QtObject {
    id: windowModel

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null

    // =========================================================
    // Window Registry & Focus History
    // =========================================================
    // Each entry:
    //   { address, title, appClass, workspace, originWorkspace, monitor,
    //     x, y, width, height, savedGeometry,
    //     floating, fullscreen, maximized, minimized, focused, focusOrder }
    property var windows: []

    // Currently focused visible window address ("" when none)
    property string focusedAddress: ""

    // Most-recently-focused window addresses first (index 0 = MRU)
    property var focusHistory: []

    // =========================================================
    // Internal Helpers
    // =========================================================

    function _normalizeAddress(address) {
        var raw = String(address || "").trim()
        if (raw.length === 0) return ""
        return "0x" + raw.replace(/^0x/i, "")
    }

    function _isValidWorkspaceId(workspaceId) {
        return typeof workspaceId === "number"
            && !isNaN(workspaceId)
            && Math.floor(workspaceId) === workspaceId
            && workspaceId >= 1
            && workspaceId <= 10
    }

    function _cloneGeometry(geom) {
        if (!geom || typeof geom !== "object") return null
        if (typeof geom.width !== "number" || typeof geom.height !== "number") return null
        if (isNaN(geom.width) || isNaN(geom.height) || geom.width <= 0 || geom.height <= 0) return null
        return {
            x: (typeof geom.x === "number" && !isNaN(geom.x)) ? Math.round(geom.x) : 0,
            y: (typeof geom.y === "number" && !isNaN(geom.y)) ? Math.round(geom.y) : 0,
            width: Math.round(geom.width),
            height: Math.round(geom.height)
        }
    }

    function _normalizeEntry(windowData, existingEntry) {
        var addr = _normalizeAddress(windowData ? windowData.address : "")
        var prev = existingEntry || null

        var ws = (windowData && _isValidWorkspaceId(windowData.workspace))
            ? windowData.workspace
            : (prev ? prev.workspace : 1)

        var originWs = (windowData && _isValidWorkspaceId(windowData.originWorkspace))
            ? windowData.originWorkspace
            : (prev && _isValidWorkspaceId(prev.originWorkspace) ? prev.originWorkspace : ws)

        var mon = (windowData && typeof windowData.monitor === "number" && !isNaN(windowData.monitor) && windowData.monitor >= 0)
            ? Math.floor(windowData.monitor)
            : (prev ? prev.monitor : 0)

        var isMin = (windowData && windowData.minimized !== undefined)
            ? Boolean(windowData.minimized)
            : (prev ? Boolean(prev.minimized) : false)

        var isFs = !isMin && Boolean(windowData && windowData.fullscreen !== undefined
            ? windowData.fullscreen
            : (prev ? prev.fullscreen : false))

        var isMax = !isMin && !isFs && Boolean(windowData && windowData.maximized !== undefined
            ? windowData.maximized
            : (prev ? prev.maximized : false))

        var isFloating = (windowData && windowData.floating !== undefined)
            ? Boolean(windowData.floating)
            : (prev ? Boolean(prev.floating) : true)

        var xVal = (windowData && typeof windowData.x === "number" && !isNaN(windowData.x))
            ? Math.round(windowData.x)
            : (prev ? prev.x : 0)
        var yVal = (windowData && typeof windowData.y === "number" && !isNaN(windowData.y))
            ? Math.round(windowData.y)
            : (prev ? prev.y : 0)
        var wVal = (windowData && typeof windowData.width === "number" && !isNaN(windowData.width) && windowData.width > 0)
            ? Math.round(windowData.width)
            : (prev && prev.width > 0 ? prev.width : 800)
        var hVal = (windowData && typeof windowData.height === "number" && !isNaN(windowData.height) && windowData.height > 0)
            ? Math.round(windowData.height)
            : (prev && prev.height > 0 ? prev.height : 480)

        var savedGeom = null
        if (windowData && windowData.savedGeometry !== undefined) {
            savedGeom = _cloneGeometry(windowData.savedGeometry)
        } else if (prev && prev.savedGeometry && (isMin || isMax || isFs)) {
            savedGeom = _cloneGeometry(prev.savedGeometry)
        }

        if (!isMin) {
            originWs = ws
        }

        var isFocused = !isMin && Boolean(windowData && windowData.focused !== undefined
            ? windowData.focused
            : (prev ? prev.focused : false))

        var orderVal = (windowData && typeof windowData.focusOrder === "number" && !isNaN(windowData.focusOrder) && windowData.focusOrder >= 0)
            ? Math.floor(windowData.focusOrder)
            : (prev ? prev.focusOrder : 0)

        return {
            address: addr,
            title: (windowData && windowData.title !== undefined) ? String(windowData.title || "") : (prev ? prev.title : ""),
            appClass: (windowData && (windowData.appClass !== undefined || windowData["class"] !== undefined))
                ? String(windowData.appClass || windowData["class"] || "")
                : (prev ? prev.appClass : ""),
            workspace: ws,
            originWorkspace: originWs,
            monitor: mon,
            x: xVal,
            y: yVal,
            width: wVal,
            height: hVal,
            savedGeometry: savedGeom,
            floating: isFloating,
            fullscreen: isFs,
            maximized: isMax,
            minimized: isMin,
            focused: isFocused,
            focusOrder: orderVal
        }
    }

    function _touchFocusHistory(address) {
        var addr = _normalizeAddress(address)
        if (addr.length === 0) return
        var next = [addr]
        for (var i = 0; i < focusHistory.length; i++) {
            if (focusHistory[i] !== addr) {
                next.push(focusHistory[i])
            }
        }
        focusHistory = next
    }

    function _appendToFocusHistoryIfMissing(address) {
        var addr = _normalizeAddress(address)
        if (addr.length === 0) return
        for (var i = 0; i < focusHistory.length; i++) {
            if (focusHistory[i] === addr) return
        }
        var next = focusHistory.slice()
        next.push(addr)
        focusHistory = next
    }

    function _removeFromFocusHistory(address) {
        var addr = _normalizeAddress(address)
        if (addr.length === 0) return
        var next = []
        for (var i = 0; i < focusHistory.length; i++) {
            if (focusHistory[i] !== addr) {
                next.push(focusHistory[i])
            }
        }
        focusHistory = next
    }

    function _recomputeFocusFlagsAndOrders(list, activeFocusAddr) {
        var historyIndex = {}
        for (var h = 0; h < focusHistory.length; h++) {
            historyIndex[focusHistory[h]] = h
        }

        var updated = []
        for (var i = 0; i < list.length; i++) {
            var copy = _normalizeEntry(list[i], list[i])
            copy.focused = (!copy.minimized && activeFocusAddr.length > 0 && copy.address === activeFocusAddr)
            copy.focusOrder = (historyIndex[copy.address] !== undefined)
                ? historyIndex[copy.address]
                : (focusHistory.length + i)
            updated.push(copy)
        }
        return updated
    }

    function _upsertWindow(windowData) {
        if (!windowData || !windowData.address) return null
        var addr = _normalizeAddress(windowData.address)
        if (addr.length === 0) return null

        var existing = getWindowByAddress(addr)
        var entry = _normalizeEntry(windowData, existing)

        if (entry.focused && !entry.minimized) {
            focusedAddress = entry.address
            _touchFocusHistory(entry.address)
        } else {
            _appendToFocusHistoryIfMissing(entry.address)
            if (entry.minimized && focusedAddress === entry.address) {
                focusedAddress = ""
            }
        }

        var next = windows.slice()
        var replaced = false
        for (var i = 0; i < next.length; i++) {
            if (next[i].address === entry.address) {
                next[i] = entry
                replaced = true
                break
            }
        }
        if (!replaced) {
            next.push(entry)
            if (logger) logger.debug("WindowModel",
                "Window tracked: '%1' (%2, ws=%3, floating=%4, pos=%5,%6, size=%7x%8)"
                    .arg(entry.title).arg(entry.address).arg(entry.workspace).arg(entry.floating)
                    .arg(entry.x).arg(entry.y).arg(entry.width).arg(entry.height))
        }

        windows = _recomputeFocusFlagsAndOrders(next, focusedAddress)
        return getWindowByAddress(entry.address)
    }

    function _deleteWindow(address) {
        var addr = _normalizeAddress(address)
        if (addr.length === 0) return null
        var next = windows.slice()
        for (var i = 0; i < next.length; i++) {
            if (next[i].address === addr) {
                var removed = next.splice(i, 1)[0]
                _removeFromFocusHistory(addr)
                if (focusedAddress === addr) {
                    focusedAddress = ""
                }
                windows = _recomputeFocusFlagsAndOrders(next, focusedAddress)
                if (logger) logger.debug("WindowModel",
                    "Window removed: '%1' (%2)".arg(removed.title).arg(addr))
                return removed
            }
        }
        return null
    }

    function _applyFocus(address) {
        var addr = _normalizeAddress(address)
        if (addr.length > 0) {
            var target = getWindowByAddress(addr)
            if (target && target.minimized) {
                return false
            }
        }
        if (focusedAddress === addr) return false
        var previous = focusedAddress
        focusedAddress = addr
        if (focusedAddress.length > 0) {
            _touchFocusHistory(focusedAddress)
        }
        windows = _recomputeFocusFlagsAndOrders(windows, focusedAddress)

        if (logger) logger.debug("WindowModel",
            "Focus: %1 → %2".arg(previous || "none").arg(focusedAddress || "none"))
        return true
    }

    function _emitModelUpdated(reason, address, extra) {
        if (!eventBus) return
        var payload = {
            source: "model",
            type: "updated",
            reason: String(reason || ""),
            address: _normalizeAddress(address),
            focusedAddress: focusedAddress
        }
        if (extra && typeof extra === "object") {
            for (var k in extra) {
                payload[k] = extra[k]
            }
        }
        eventBus.emit("window", payload)
    }

    // =========================================================
    // Public Window Operations
    // =========================================================

    function addWindow(windowData) {
        if (!windowData || !windowData.address) return null
        var addr = _normalizeAddress(windowData.address)
        if (getWindowByAddress(addr)) {
            if (logger) logger.warn("WindowModel", "Duplicate window: %1".arg(addr))
            return null
        }
        var entry = _upsertWindow(windowData)
        if (entry && eventBus) {
            eventBus.emit("window", { source: "model", type: "created", window: entry })
            _emitModelUpdated("created", entry.address)
        }
        return entry
    }

    function removeWindow(address) {
        var addr = _normalizeAddress(address)
        var removed = _deleteWindow(addr)
        if (removed && eventBus) {
            eventBus.emit("window", { source: "model", type: "destroyed", window: removed, address: addr })
            _emitModelUpdated("destroyed", addr)
        }
        return removed
    }

    function setFocused(address) {
        var previous = focusedAddress
        if (!_applyFocus(address)) return
        if (eventBus) {
            eventBus.emit("window", {
                source: "model",
                type: "focused",
                address: focusedAddress,
                previousAddress: previous
            })
            _emitModelUpdated("focused", focusedAddress)
        }
    }

    // =========================================================
    // Queries
    // =========================================================

    function getWindowsByWorkspace(workspaceId, includeMinimized) {
        var includeMin = (includeMinimized === undefined) ? true : Boolean(includeMinimized)
        return windows.filter(function(w) {
            return w.workspace === workspaceId && (includeMin || !w.minimized)
        })
    }

    function getVisibleWindowsByWorkspace(workspaceId) {
        return getWindowsByWorkspace(workspaceId, false)
    }

    function getWindowsByMonitor(monitorIndex, includeMinimized) {
        var includeMin = (includeMinimized === undefined) ? true : Boolean(includeMinimized)
        return windows.filter(function(w) {
            return w.monitor === monitorIndex && (includeMin || !w.minimized)
        })
    }

    function getMinimizedWindows(workspaceId) {
        var filterByWs = _isValidWorkspaceId(workspaceId)
        var minMap = {}
        var count = 0
        for (var i = 0; i < windows.length; i++) {
            var w = windows[i]
            if (!w.minimized) continue
            if (filterByWs && w.workspace !== workspaceId && w.originWorkspace !== workspaceId) continue
            minMap[w.address] = w
            count++
        }
        if (count === 0) return []

        var ordered = []
        var added = {}
        for (var h = 0; h < focusHistory.length; h++) {
            var hAddr = focusHistory[h]
            if (minMap[hAddr]) {
                ordered.push(minMap[hAddr])
                added[hAddr] = true
            }
        }
        for (var j = 0; j < windows.length; j++) {
            var rem = windows[j]
            if (minMap[rem.address] && !added[rem.address]) {
                ordered.push(rem)
            }
        }
        return ordered
    }

    function getWindowByAddress(address) {
        var addr = _normalizeAddress(address)
        if (addr.length === 0) return null
        for (var i = 0; i < windows.length; i++) {
            if (windows[i].address === addr) return windows[i]
        }
        return null
    }

    function getFocusedWindow() {
        return focusedAddress.length > 0 ? getWindowByAddress(focusedAddress) : null
    }

    function getNextFocusableWindow(excludeAddress, workspaceId, monitorIndex) {
        var excluded = _normalizeAddress(excludeAddress)
        var hasWs = _isValidWorkspaceId(workspaceId)
        var hasMon = (typeof monitorIndex === "number" && !isNaN(monitorIndex) && monitorIndex >= 0)

        for (var h = 0; h < focusHistory.length; h++) {
            var candidate = getWindowByAddress(focusHistory[h])
            if (!candidate || candidate.minimized || candidate.address === excluded) continue
            if (hasWs && candidate.workspace !== workspaceId) continue
            if (!hasWs && hasMon && candidate.monitor !== monitorIndex) continue
            return candidate
        }

        for (var i = 0; i < windows.length; i++) {
            var fallback = windows[i]
            if (!fallback || fallback.minimized || fallback.address === excluded) continue
            if (hasWs && fallback.workspace !== workspaceId) continue
            if (!hasWs && hasMon && fallback.monitor !== monitorIndex) continue
            return fallback
        }

        return null
    }

    // Per DEC-023: ONLY native compositor fullscreen returns true here (never maximized or minimized).
    function hasFullscreenWindow(monitorIndex, workspaceId) {
        var checkWs = _isValidWorkspaceId(workspaceId)
        return windows.some(function(w) {
            if (w.minimized || !w.fullscreen) return false
            if (checkWs) return w.workspace === workspaceId
            return w.monitor === monitorIndex
        })
    }

    function hasMaximizedWindow(monitorIndex, workspaceId) {
        var checkWs = _isValidWorkspaceId(workspaceId)
        return windows.some(function(w) {
            if (w.minimized || !w.maximized) return false
            if (checkWs) return w.workspace === workspaceId
            return w.monitor === monitorIndex
        })
    }

    function getSnapshot() {
        var visibleCount = 0
        var minimizedCount = 0
        for (var i = 0; i < windows.length; i++) {
            if (windows[i].minimized) {
                minimizedCount++
            } else {
                visibleCount++
            }
        }
        return {
            count: windows.length,
            visibleCount: visibleCount,
            minimizedCount: minimizedCount,
            focusedAddress: focusedAddress,
            focusHistory: focusHistory.slice(),
            windows: windows.slice()
        }
    }

    // =========================================================
    // Lifecycle & Event Subscriptions
    // =========================================================

    function initialize() {
        windows = []
        focusedAddress = ""
        focusHistory = []
        if (!eventBus) return

        eventBus.subscribe("WindowModel", "window", function(ev) {
            if (!ev || ev.source === "model") return

            if (ev.type === "synced" && Array.isArray(ev.windows)) {
                var existingByAddr = {}
                for (var e = 0; e < windows.length; e++) {
                    existingByAddr[windows[e].address] = windows[e]
                }

                var rawList = []
                var incomingSet = {}
                var focusAddr = _normalizeAddress(ev.focusedAddress || "")

                for (var i = 0; i < ev.windows.length; i++) {
                    var itemAddr = _normalizeAddress(ev.windows[i] ? ev.windows[i].address : "")
                    if (itemAddr.length === 0) continue
                    var item = _normalizeEntry(ev.windows[i], existingByAddr[itemAddr] || null)
                    if (item.minimized && focusAddr === item.address) {
                        focusAddr = ""
                    }
                    if (item.focused && !item.minimized && focusAddr.length === 0) {
                        focusAddr = item.address
                    }
                    incomingSet[item.address] = true
                    rawList.push(item)
                }

                // Build MRU history: focusedAddr first, then existing history still alive,
                // then remaining windows ordered by incoming focusOrder.
                var nextHistory = []
                var seenHist = {}
                if (focusAddr.length > 0 && incomingSet[focusAddr]) {
                    nextHistory.push(focusAddr)
                    seenHist[focusAddr] = true
                }
                for (var h = 0; h < focusHistory.length; h++) {
                    var oldAddr = focusHistory[h]
                    if (incomingSet[oldAddr] && !seenHist[oldAddr]) {
                        nextHistory.push(oldAddr)
                        seenHist[oldAddr] = true
                    }
                }
                var sortedIncoming = rawList.slice().sort(function(a, b) {
                    return a.focusOrder - b.focusOrder
                })
                for (var s = 0; s < sortedIncoming.length; s++) {
                    var sAddr = sortedIncoming[s].address
                    if (!seenHist[sAddr]) {
                        nextHistory.push(sAddr)
                        seenHist[sAddr] = true
                    }
                }

                focusHistory = nextHistory
                focusedAddress = (focusAddr.length > 0 && incomingSet[focusAddr]) ? focusAddr : ""
                windows = _recomputeFocusFlagsAndOrders(rawList, focusedAddress)
                _emitModelUpdated("synced", focusedAddress)
            } else if (ev.type === "created" && ev.window) {
                var created = _upsertWindow(ev.window)
                if (created) {
                    _emitModelUpdated("created", created.address)
                }
            } else if (ev.type === "destroyed" && ev.address) {
                var destroyed = _deleteWindow(ev.address)
                if (destroyed) {
                    _emitModelUpdated("destroyed", destroyed.address)
                }
            } else if (ev.type === "focused" && ev.address !== undefined) {
                if (_applyFocus(ev.address)) {
                    _emitModelUpdated("focused", focusedAddress)
                }
            } else if (ev.type === "geometry" && ev.address) {
                var geomTarget = getWindowByAddress(ev.address)
                if (geomTarget) {
                    var geomCopy = _normalizeEntry(geomTarget, geomTarget)
                    if (typeof ev.x === "number" && !isNaN(ev.x)) geomCopy.x = Math.round(ev.x)
                    if (typeof ev.y === "number" && !isNaN(ev.y)) geomCopy.y = Math.round(ev.y)
                    if (typeof ev.width === "number" && !isNaN(ev.width) && ev.width > 0) geomCopy.width = Math.round(ev.width)
                    if (typeof ev.height === "number" && !isNaN(ev.height) && ev.height > 0) geomCopy.height = Math.round(ev.height)
                    if (typeof ev.monitor === "number" && !isNaN(ev.monitor) && ev.monitor >= 0) geomCopy.monitor = Math.floor(ev.monitor)
                    _upsertWindow(geomCopy)
                    _emitModelUpdated("geometry", geomCopy.address)
                }
            } else if (ev.type === "floating" && ev.address) {
                var floatTarget = getWindowByAddress(ev.address)
                if (floatTarget) {
                    var floatCopy = _normalizeEntry(floatTarget, floatTarget)
                    floatCopy.floating = Boolean(ev.floating)
                    _upsertWindow(floatCopy)
                    _emitModelUpdated("floating", floatCopy.address)
                }
            } else if (ev.type === "maximized" && ev.address) {
                var maxTarget = getWindowByAddress(ev.address)
                if (maxTarget) {
                    var maxCopy = _normalizeEntry(maxTarget, maxTarget)
                    var nextMax = Boolean(ev.maximized)
                    if (nextMax && !maxTarget.maximized && !maxTarget.minimized) {
                        maxCopy.savedGeometry = ev.savedGeometry
                            ? _cloneGeometry(ev.savedGeometry)
                            : _cloneGeometry({ x: maxTarget.x, y: maxTarget.y, width: maxTarget.width, height: maxTarget.height })
                    } else if (!nextMax) {
                        maxCopy.savedGeometry = null
                    }
                    maxCopy.maximized = nextMax
                    if (nextMax) {
                        maxCopy.fullscreen = false
                        maxCopy.minimized = false
                    }
                    if (typeof ev.x === "number" && !isNaN(ev.x)) maxCopy.x = Math.round(ev.x)
                    if (typeof ev.y === "number" && !isNaN(ev.y)) maxCopy.y = Math.round(ev.y)
                    if (typeof ev.width === "number" && !isNaN(ev.width) && ev.width > 0) maxCopy.width = Math.round(ev.width)
                    if (typeof ev.height === "number" && !isNaN(ev.height) && ev.height > 0) maxCopy.height = Math.round(ev.height)
                    _upsertWindow(maxCopy)
                    _emitModelUpdated("maximized", maxCopy.address, { maximized: nextMax })
                }
            } else if (ev.type === "fullscreen" && ev.address) {
                var fsWin = getWindowByAddress(ev.address)
                if (fsWin) {
                    var fsCopy = _normalizeEntry(fsWin, fsWin)
                    var nextFs = Boolean(ev.fullscreen)
                    fsCopy.fullscreen = nextFs
                    if (nextFs) {
                        fsCopy.maximized = false
                        fsCopy.minimized = false
                    }
                    _upsertWindow(fsCopy)
                    _emitModelUpdated("fullscreen", fsCopy.address, { fullscreen: nextFs })
                }
            } else if (ev.type === "minimized" && ev.address) {
                var minTarget = getWindowByAddress(ev.address)
                if (minTarget) {
                    var minCopy = _normalizeEntry(minTarget, minTarget)
                    if (!minTarget.minimized) {
                        minCopy.originWorkspace = _isValidWorkspaceId(ev.originWorkspace)
                            ? ev.originWorkspace
                            : minTarget.workspace
                        if (!minCopy.savedGeometry) {
                            minCopy.savedGeometry = ev.savedGeometry
                                ? _cloneGeometry(ev.savedGeometry)
                                : _cloneGeometry({ x: minTarget.x, y: minTarget.y, width: minTarget.width, height: minTarget.height })
                        }
                    }
                    minCopy.minimized = true
                    minCopy.fullscreen = false
                    minCopy.maximized = false
                    minCopy.focused = false
                    _upsertWindow(minCopy)
                    _emitModelUpdated("minimized", minCopy.address)
                }
            } else if (ev.type === "restored" && ev.address) {
                var resTarget = getWindowByAddress(ev.address)
                if (resTarget) {
                    var resCopy = _normalizeEntry(resTarget, resTarget)
                    if (_isValidWorkspaceId(ev.workspace)) {
                        resCopy.workspace = ev.workspace
                        resCopy.originWorkspace = ev.workspace
                    }
                    if (typeof ev.monitor === "number" && !isNaN(ev.monitor) && ev.monitor >= 0) {
                        resCopy.monitor = Math.floor(ev.monitor)
                    }
                    if (typeof ev.x === "number" && !isNaN(ev.x)) resCopy.x = Math.round(ev.x)
                    if (typeof ev.y === "number" && !isNaN(ev.y)) resCopy.y = Math.round(ev.y)
                    if (typeof ev.width === "number" && !isNaN(ev.width) && ev.width > 0) resCopy.width = Math.round(ev.width)
                    if (typeof ev.height === "number" && !isNaN(ev.height) && ev.height > 0) resCopy.height = Math.round(ev.height)
                    resCopy.minimized = false
                    resCopy.fullscreen = false
                    resCopy.maximized = false
                    resCopy.floating = true
                    resCopy.savedGeometry = null
                    resCopy.focused = (ev.focused !== undefined) ? Boolean(ev.focused) : true
                    var restored = _upsertWindow(resCopy)
                    _emitModelUpdated("restored", restored ? restored.address : resCopy.address)
                }
            } else if (ev.type === "moved" && ev.address && _isValidWorkspaceId(ev.workspace)) {
                var moveTarget = getWindowByAddress(ev.address)
                if (moveTarget) {
                    var prevWs = moveTarget.workspace
                    var prevMon = moveTarget.monitor
                    var movedCopy = _normalizeEntry(moveTarget, moveTarget)
                    movedCopy.workspace = ev.workspace
                    if (!movedCopy.minimized) {
                        movedCopy.originWorkspace = ev.workspace
                    }
                    if (typeof ev.monitor === "number" && !isNaN(ev.monitor) && ev.monitor >= 0) {
                        movedCopy.monitor = Math.floor(ev.monitor)
                    }
                    if (typeof ev.x === "number" && !isNaN(ev.x)) movedCopy.x = Math.round(ev.x)
                    if (typeof ev.y === "number" && !isNaN(ev.y)) movedCopy.y = Math.round(ev.y)
                    if (ev.followFocus === true && !movedCopy.minimized) {
                        movedCopy.focused = true
                    }
                    var updatedMoved = _upsertWindow(movedCopy)
                    if (eventBus && updatedMoved) {
                        eventBus.emit("window", {
                            source: "model",
                            type: "moved",
                            transition: String(ev.transition || "pop"),
                            window: updatedMoved,
                            address: updatedMoved.address,
                            fromWorkspace: _isValidWorkspaceId(ev.fromWorkspace) ? ev.fromWorkspace : prevWs,
                            workspace: updatedMoved.workspace,
                            fromMonitor: (typeof ev.fromMonitor === "number") ? ev.fromMonitor : prevMon,
                            monitor: updatedMoved.monitor,
                            followFocus: Boolean(ev.followFocus)
                        })
                    }
                    _emitModelUpdated("moved", movedCopy.address)
                }
            }
        })

        if (logger) logger.info("WindowModel", "Window model initialized.")
    }

    function teardown() {
        if (eventBus) {
            eventBus.unsubscribeAll("WindowModel")
        }
    }

    function reset() {
        windows = []
        focusedAddress = ""
        focusHistory = []
        if (logger) logger.debug("WindowModel", "Window model reset.")
    }
}
