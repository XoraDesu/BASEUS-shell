// BASEUS — Dock Model
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §10; DESIGN.md §11; and DEC-015:
//   - Pinned applications are GLOBAL (always present across all workspaces)
//   - Active applications are WORKSPACE-SPECIFIC (appear only when active on current workspace)
//   - Tracks running state indicators and per-workspace window counts
//   - Provides MRU window cycling for multi-window applications
//   - Dispatches focus or launch on item activation

pragma ComponentBehavior: Bound
import QtQuick

QtObject {
    id: dockModel

    // =========================================================
    // Dependencies & Configuration
    // =========================================================
    property var config: null
    property var windowModel: null
    property var workspaceModel: null
    property var bridge: null
    property int monitorIndex: 0

    // Reactive active workspace for this monitor
    readonly property int activeWorkspace: {
        if (!dockModel.workspaceModel) return 1
        var _aw = dockModel.workspaceModel.activeWorkspaces
        return dockModel.workspaceModel.getActiveWorkspace(dockModel.monitorIndex)
    }

    // =========================================================
    // Reactive Consolidated Dock Items (DEC-015)
    // =========================================================
    // Re-evaluates automatically whenever pinned config, active workspace,
    // window list, or focused address changes.
    readonly property var items: {
        var _pinned = (dockModel.config && dockModel.config.dockPinnedApps) ? dockModel.config.dockPinnedApps : [
            { id: "terminal", title: "Terminal", appClass: "kitty", command: "kitty", icon: "utilities-terminal" },
            { id: "browser", title: "Browser", appClass: "firefox", command: "firefox", icon: "firefox" },
            { id: "editor", title: "Editor", appClass: "code", command: "code", icon: "text-editor" },
            { id: "files", title: "Files", appClass: "thunar", command: "thunar", icon: "system-file-manager" }
        ]
        var _wins = dockModel.windowModel ? dockModel.windowModel.windows : []
        var _focused = dockModel.windowModel ? dockModel.windowModel.focusedAddress : ""
        var _ws = dockModel.activeWorkspace
        var _mon = dockModel.monitorIndex

        return dockModel._buildItems(_pinned, _wins, _focused, _ws, _mon)
    }

    readonly property int itemCount: dockModel.items.length

    // =========================================================
    // Internal Item Construction
    // =========================================================

    function _matchesApp(appClass, win): bool {
        if (!win) return false
        var target = String(appClass || "").toLowerCase().trim()
        if (target.length === 0) return false
        var winClass = String(win.appClass || "").toLowerCase().trim()
        var winTitle = String(win.title || "").toLowerCase().trim()
        if (winClass.length > 0) {
            if (winClass === target || winClass.indexOf(target) !== -1 || target.indexOf(winClass) !== -1) {
                return true
            }
        }
        if (winTitle.length > 0) {
            if (winTitle === target || winTitle.indexOf(target) !== -1) {
                return true
            }
        }
        return false
    }

    function _orderAddressesByMRU(addresses, focusHistory): var {
        if (!addresses || addresses.length <= 1) return addresses ? addresses.slice() : []
        var hist = focusHistory || []
        var ordered = []
        var remaining = addresses.slice()
        for (var i = 0; i < hist.length; i++) {
            var addr = hist[i]
            var idx = remaining.indexOf(addr)
            if (idx !== -1) {
                ordered.push(addr)
                remaining.splice(idx, 1)
            }
        }
        for (var j = 0; j < remaining.length; j++) {
            ordered.push(remaining[j])
        }
        return ordered
    }

    function _isWindowClaimedByPins(win, pinnedList): bool {
        if (!win || !pinnedList) return false
        for (var i = 0; i < pinnedList.length; i++) {
            var p = pinnedList[i]
            if (p && dockModel._matchesApp(p.appClass, win)) {
                return true
            }
        }
        return false
    }

    function _buildItems(pinnedList, windowList, focusedAddress, currWorkspace, currMonitor): var {
        var result = []
        var wins = windowList || []
        var focusHist = dockModel.windowModel ? dockModel.windowModel.focusHistory : []

        // 1. Process Pinned Apps (GLOBAL per DEC-015)
        var pList = pinnedList || []
        for (var i = 0; i < pList.length; i++) {
            var pin = pList[i]
            if (!pin) continue

            var pinAppClass = pin.appClass || pin.id || ""
            var allMatching = []
            var wsMatching = []

            for (var w = 0; w < wins.length; w++) {
                var win = wins[w]
                if (dockModel._matchesApp(pinAppClass, win)) {
                    allMatching.push(win)
                    if (win.monitor === currMonitor && (win.workspace === currWorkspace || (win.minimized && win.originWorkspace === currWorkspace))) {
                        wsMatching.push(win)
                    }
                }
            }

            var wsAddrs = dockModel._orderAddressesByMRU(wsMatching.map(function(item) { return item.address }), focusHist)
            var allAddrs = dockModel._orderAddressesByMRU(allMatching.map(function(item) { return item.address }), focusHist)
            var isFocused = wsMatching.some(function(item) { return item.address === focusedAddress })

            result.push({
                id: "pin_" + (pin.id || pinAppClass),
                pinId: pin.id || "",
                title: pin.title || pin.id || "App",
                appClass: pinAppClass,
                command: pin.command || pinAppClass,
                icon: pin.icon || "",
                isPinned: true,
                isRunning: (allMatching.length > 0),
                isFocused: isFocused,
                windowCount: wsMatching.length,
                globalWindowCount: allMatching.length,
                windowAddresses: wsAddrs,
                globalWindowAddresses: allAddrs,
                hasWindowsOnWorkspace: (wsMatching.length > 0)
            })
        }

        // 2. Process Unpinned Running Apps (WORKSPACE-SPECIFIC per DEC-015)
        var unpinnedGroups = ({})
        var unpinnedOrder = []

        for (var j = 0; j < wins.length; j++) {
            var cand = wins[j]
            if (!cand) continue

            // Must belong to current monitor and current active workspace
            if (cand.monitor !== currMonitor) continue
            var onWs = (cand.workspace === currWorkspace || (cand.minimized && cand.originWorkspace === currWorkspace))
            if (!onWs) continue

            // Skip if claimed by a pinned app
            if (dockModel._isWindowClaimedByPins(cand, pList)) continue

            var rawClass = String(cand.appClass || "").trim()
            var groupKey = (rawClass.length > 0) ? rawClass.toLowerCase() : ("app_" + cand.address)

            if (!unpinnedGroups[groupKey]) {
                unpinnedGroups[groupKey] = {
                    title: cand.title && cand.title.length > 0 ? cand.title : (rawClass.length > 0 ? rawClass : "Window"),
                    appClass: rawClass,
                    windows: []
                }
                unpinnedOrder.push(groupKey)
            }
            unpinnedGroups[groupKey].windows.push(cand)
        }

        for (var k = 0; k < unpinnedOrder.length; k++) {
            var key = unpinnedOrder[k]
            var grp = unpinnedGroups[key]
            var grpAddrs = dockModel._orderAddressesByMRU(grp.windows.map(function(item) { return item.address }), focusHist)
            var grpFocused = grp.windows.some(function(item) { return item.address === focusedAddress })

            result.push({
                id: "running_" + (grp.appClass.length > 0 ? grp.appClass : key),
                pinId: "",
                title: grp.title,
                appClass: grp.appClass,
                command: grp.appClass,
                icon: grp.appClass,
                isPinned: false,
                isRunning: true,
                isFocused: grpFocused,
                windowCount: grp.windows.length,
                globalWindowCount: grp.windows.length,
                windowAddresses: grpAddrs,
                globalWindowAddresses: grpAddrs,
                hasWindowsOnWorkspace: true
            })
        }

        return result
    }

    // =========================================================
    // Item Activation API
    // =========================================================

    function activateItem(itemData): bool {
        if (!itemData) return false
        var addrs = itemData.windowAddresses || []

        if (addrs.length === 1) {
            // Single window on this workspace: focus it directly
            if (dockModel.bridge) {
                return dockModel.bridge.focusWindow(addrs[0])
            }
        } else if (addrs.length > 1) {
            // Multi-window: cycle through instances in MRU order
            var focused = dockModel.windowModel ? dockModel.windowModel.focusedAddress : ""
            var currIdx = addrs.indexOf(focused)
            var nextIdx = (currIdx + 1) % addrs.length
            if (dockModel.bridge) {
                return dockModel.bridge.focusWindow(addrs[nextIdx])
            }
        } else if (itemData.command && itemData.command.length > 0) {
            // Inactive pinned app: launch new instance
            if (dockModel.bridge && typeof dockModel.bridge.launchApp === "function") {
                return dockModel.bridge.launchApp(itemData.command)
            }
        }
        return false
    }

    function getSnapshot(): var {
        var snap = []
        for (var i = 0; i < dockModel.items.length; i++) {
            var it = dockModel.items[i]
            if (!it) continue
            snap.push({
                id: it.id,
                title: it.title,
                appClass: it.appClass,
                isPinned: it.isPinned,
                isRunning: it.isRunning,
                isFocused: it.isFocused,
                windowCount: it.windowCount,
                hasWindowsOnWorkspace: it.hasWindowsOnWorkspace,
                addresses: it.windowAddresses
            })
        }
        return snap
    }
}
