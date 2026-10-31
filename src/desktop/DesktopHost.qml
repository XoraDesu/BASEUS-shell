// BASEUS — Desktop Host
// Copyright (c) 2026 xoradesu — MIT License
//
// Multi-monitor Wayland Layer-Shell host scaffolding (M1-T4, M1-T5, DEC-045).
// Anchors foundational desktop overlay surfaces per monitor bounds
// while maintaining zero-cost click-through at idle and per-monitor
// native fullscreen recession (DEC-023, DESIGN.md §14).

pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: desktopHost

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var shellState: null
    property var monitorModel: null
    property var workspaceModel: null
    property var windowModel: null
    property var config: null
    property var bridge: null
    property var theme: null
    property var actionRegistry: null
    property var notificationModel: null
    property var audioService: null
    property var mediaService: null
    property var statusService: null
    property var wallpaperService: null
    property var paletteService: null
    property bool mediaWidgetEnabled: false

    // =========================================================
    // Host Configuration
    // =========================================================
    property bool enabled: true
    property int layer: WlrLayer.Top
    property string layerNamespace: "baseus-desktop"

    // =========================================================
    // Surface Tracking
    // =========================================================
    property var _surfaces: []
    readonly property int surfaceCount: _surfaces.length

    function resolveMonitorIndex(screenName: string): int {
        if (desktopHost.monitorModel && desktopHost.monitorModel.monitors) {
            var mons = desktopHost.monitorModel.monitors
            for (var i = 0; i < mons.length; i++) {
                var m = mons[i]
                if (m && m.name === screenName) {
                    return (typeof m.index === "number") ? m.index : i
                }
            }
        }
        return 0
    }

    function getSurfaceSnapshot(): var {
        var snapshot = []
        for (var i = 0; i < desktopHost._surfaces.length; i++) {
            var s = desktopHost._surfaces[i]
            if (!s) continue
            snapshot.push({
                monitorIndex: s.monitorIndex,
                screenName: s.screenName,
                width: s.width,
                height: s.height,
                visible: s.visible,
                isFullscreen: s.isFullscreen,
                layer: desktopHost.layer === WlrLayer.Top ? "top" : "overlay",
                topIsland: {
                    timeText: s.topIslandRef ? s.topIslandRef.timeText : "",
                    visible: s.topIslandRef ? s.topIslandRef.visible : false,
                    expanded: s.topIslandRef ? s.topIslandRef.expanded : false,
                    hitRegion: s.topIslandRef
                        ? { width: s.topIslandRef.anchorItem.width, height: s.topIslandRef.anchorItem.height }
                        : { width: 0, height: 0 }
                },
                summon: desktopHost._summonSnapshot(s.monitorIndex),
                workspaceIndicator: {
                    active: s.workspaceIndicatorRef ? s.workspaceIndicatorRef.active : false,
                    currentWorkspace: s.workspaceIndicatorRef ? s.workspaceIndicatorRef.currentWorkspace : 1,
                    previousWorkspace: s.workspaceIndicatorRef ? s.workspaceIndicatorRef.previousWorkspace : 1,
                    workspaceLabel: s.workspaceIndicatorRef ? s.workspaceIndicatorRef.workspaceLabel : ""
                },
                dock: {
                    revealed: s.dockRef ? s.dockRef.revealed : false,
                    visible: s.dockRef ? s.dockRef.visible : false,
                    itemCount: s.dockRef ? s.dockRef.itemCount : 0,
                    items: s.dockRef ? s.dockRef.getSnapshot() : []
                },
                commandCenter: {
                    active: desktopHost.commandCenterActive && (desktopHost.commandCenterMonitorIndex === s.monitorIndex)
                },
                appDrawer: {
                    active: desktopHost.appDrawerActive && (desktopHost.appDrawerMonitorIndex === s.monitorIndex)
                },
                notifications: s.notificationHostRef ? s.notificationHostRef.getSnapshot() : { available: false, count: 0 },
                osd: s.topIslandRef ? s.topIslandRef.getOsdState() : { available: false, active: false },
                mediaWidget: s.mediaWidgetRef ? s.mediaWidgetRef.getSnapshot() : { available: false, visible: false, expanded: false },
                wallpaper: {
                    path: desktopHost.wallpaperService ? desktopHost.wallpaperService.getWallpaperForMonitor(s.monitorIndex) : "",
                    mode: desktopHost.wallpaperService ? desktopHost.wallpaperService.mode : "static"
                },
                wallpaperPicker: {
                    active: desktopHost.wallpaperPickerActive && (desktopHost.wallpaperPickerMonitorIndex === s.monitorIndex)
                }
            })
        }
        return snapshot
    }

    // =========================================================
    // Top Island Access (M2-T3)
    // =========================================================
    // Fullscreen summon instances live in a dedicated Overlay surface per monitor.

    function _summonFor(monitorIndex: int): var {
        var list = summonVariants.instances
        for (var i = 0; i < list.length; i++) {
            if (list[i] && list[i].monitorIndex === monitorIndex) return list[i]
        }
        return null
    }

    function _summonSnapshot(monitorIndex: int): var {
        var w = desktopHost._summonFor(monitorIndex)
        if (!w) return { available: false, visible: false }
        var snap = w.islandRef.getSnapshot()
        snap.available = true
        snap.visible = w.visible
        snap.layer = "overlay"
        snap.surfaceWidth = w.width
        snap.surfaceHeight = w.height
        return snap
    }

    // The island that currently owns the top edge on this monitor:
    // the summon instance during native fullscreen, otherwise the main anchor.
    function _islandFor(monitorIndex: int): var {
        if (desktopHost.shellState && desktopHost.shellState.isMonitorFullscreen(monitorIndex)) {
            var w = desktopHost._summonFor(monitorIndex)
            if (w) return w.islandRef
        }
        for (var i = 0; i < desktopHost._surfaces.length; i++) {
            var s = desktopHost._surfaces[i]
            if (s && s.monitorIndex === monitorIndex) return s.topIslandRef
        }
        return null
    }

    function getTopIslandState(monitorIndex: int): var {
        var island = desktopHost._islandFor(monitorIndex)
        if (!island) return { available: false }
        var snap = island.getSnapshot()
        snap.available = true
        return snap
    }

    function setTopIslandHover(monitorIndex: int, hovered: bool): bool {
        var island = desktopHost._islandFor(monitorIndex)
        if (!island) return false
        island.simulateHover(hovered)
        return true
    }

    function tapTopIsland(monitorIndex: int): bool {
        var island = desktopHost._islandFor(monitorIndex)
        if (!island) return false
        island.applyTap()
        return true
    }

    function clickTopIslandTrigger(monitorIndex: int, actionId: string): bool {
        var island = desktopHost._islandFor(monitorIndex)
        return island ? island.activateTrigger(actionId) : false
    }

    function triggerOsd(type: string, value: real, isMuted: bool, monitorIndex: int): bool {
        var t = (typeof type === "string" && type.length > 0) ? type : "volume"
        var mon = (typeof monitorIndex === "number" && monitorIndex >= 0)
            ? monitorIndex
            : (desktopHost.shellState ? desktopHost.shellState.activeMonitorIndex : 0)
        var island = desktopHost._islandFor(mon)
        if (island) {
            island.showOsd(t, value, isMuted)
            return true
        }
        return false
    }

    function getOsdState(monitorIndex: int): var {
        var mon = (typeof monitorIndex === "number" && monitorIndex >= 0)
            ? monitorIndex
            : (desktopHost.shellState ? desktopHost.shellState.activeMonitorIndex : 0)
        var island = desktopHost._islandFor(mon)
        if (!island) return { available: false, active: false }
        var snap = island.getOsdState()
        snap.monitorIndex = mon
        return snap
    }

    function clickDockItem(monitorIndex: int, itemId: string): bool {
        for (var i = 0; i < desktopHost._surfaces.length; i++) {
            var s = desktopHost._surfaces[i]
            if (s && s.monitorIndex === monitorIndex && s.dockRef) {
                return s.dockRef.activateItemById(itemId)
            }
        }
        return false
    }

    function getDockItems(monitorIndex: int): var {
        for (var i = 0; i < desktopHost._surfaces.length; i++) {
            var s = desktopHost._surfaces[i]
            if (s && s.monitorIndex === monitorIndex && s.dockRef) {
                return s.dockRef.getSnapshot()
            }
        }
        return []
    }

    function revealDock(monitorIndex: int): bool {
        for (var i = 0; i < desktopHost._surfaces.length; i++) {
            var s = desktopHost._surfaces[i]
            if (s && s.monitorIndex === monitorIndex && s.dockRef) {
                s.dockRef.reveal()
                return true
            }
        }
        return false
    }

    function hideDock(monitorIndex: int): bool {
        for (var i = 0; i < desktopHost._surfaces.length; i++) {
            var s = desktopHost._surfaces[i]
            if (s && s.monitorIndex === monitorIndex && s.dockRef) {
                s.dockRef.hide()
                return true
            }
        }
        return false
    }

    function isDockRevealed(monitorIndex: int): bool {
        for (var i = 0; i < desktopHost._surfaces.length; i++) {
            var s = desktopHost._surfaces[i]
            if (s && s.monitorIndex === monitorIndex && s.dockRef) {
                return s.dockRef.revealed
            }
        }
        return false
    }

    function triggerWorkspaceIndicator(monitorIndex: int, prevWs: int, currWs: int, label: string): bool {
        for (var i = 0; i < desktopHost._surfaces.length; i++) {
            var s = desktopHost._surfaces[i]
            if (s && s.monitorIndex === monitorIndex && s.workspaceIndicatorRef) {
                s.workspaceIndicatorRef.showIndicator(prevWs, currWs, label)
                return true
            }
        }
        return false
    }

    // =========================================================
    // Command Center State & Control (M2-T4, DEC-017)
    // =========================================================
    property bool _commandCenterOpen: false
    property int _commandCenterMonitor: 0

    readonly property bool commandCenterActive: desktopHost._commandCenterOpen || (desktopHost.shellState && desktopHost.shellState.mode === "command-center")
    readonly property int commandCenterMonitorIndex: desktopHost._commandCenterMonitor

    function openCommandCenter(prefix: string, monitorIndex: int) {
        if (typeof monitorIndex === "number" && monitorIndex >= 0) {
            desktopHost._commandCenterMonitor = monitorIndex
        } else if (desktopHost.shellState) {
            desktopHost._commandCenterMonitor = desktopHost.shellState.activeMonitorIndex
        }
        desktopHost._commandCenterOpen = true
        if (desktopHost.shellState && desktopHost.shellState.mode !== "command-center") {
            desktopHost.shellState.setMode("command-center")
        }
        var cc = desktopHost._commandCenterFor(desktopHost._commandCenterMonitor)
        if (cc) {
            cc.openWithPrefix(prefix)
        }
    }

    function closeCommandCenter() {
        desktopHost._commandCenterOpen = false
        if (desktopHost.shellState && desktopHost.shellState.mode === "command-center") {
            desktopHost.shellState.dismissOverlay()
        }
        var cc = desktopHost._commandCenterFor(desktopHost._commandCenterMonitor)
        if (cc) {
            cc.close()
        }
    }

    function toggleCommandCenter(monitorIndex: int) {
        if (desktopHost.commandCenterActive) {
            desktopHost.closeCommandCenter()
        } else {
            desktopHost.openCommandCenter("", monitorIndex)
        }
    }

    function _commandCenterFor(monitorIndex: int): var {
        var list = commandCenterVariants.instances
        for (var i = 0; i < list.length; i++) {
            if (list[i] && list[i].monitorIndex === monitorIndex) {
                return list[i].commandCenterRef
            }
        }
        return null
    }

    function getCommandCenterState(monitorIndex: int): var {
        var mon = (typeof monitorIndex === "number" && monitorIndex >= 0)
            ? monitorIndex
            : desktopHost.commandCenterMonitorIndex
        var cc = desktopHost._commandCenterFor(mon)
        if (!cc) return { available: false, active: false }
        var snap = cc.getSnapshot()
        snap.available = true
        snap.monitorIndex = mon
        return snap
    }

    // =========================================================
    // App Drawer State & Control (M2-T5, DEC-018, DEC-022)
    // =========================================================
    property bool _appDrawerOpen: false
    property int _appDrawerMonitor: 0

    readonly property bool appDrawerActive: desktopHost._appDrawerOpen || (desktopHost.shellState && desktopHost.shellState.mode === "app-drawer")
    readonly property int appDrawerMonitorIndex: desktopHost._appDrawerMonitor

    function openAppDrawer(monitorIndex: int) {
        if (typeof monitorIndex === "number" && monitorIndex >= 0) {
            desktopHost._appDrawerMonitor = monitorIndex
        } else if (desktopHost.shellState) {
            desktopHost._appDrawerMonitor = desktopHost.shellState.activeMonitorIndex
        }
        desktopHost._appDrawerOpen = true
        if (desktopHost.shellState && desktopHost.shellState.mode !== "app-drawer") {
            desktopHost.shellState.setMode("app-drawer")
        }
        var ad = desktopHost._appDrawerFor(desktopHost._appDrawerMonitor)
        if (ad) {
            ad.open()
        }
    }

    function closeAppDrawer() {
        desktopHost._appDrawerOpen = false
        if (desktopHost.shellState && desktopHost.shellState.mode === "app-drawer") {
            desktopHost.shellState.dismissOverlay()
        }
        var ad = desktopHost._appDrawerFor(desktopHost._appDrawerMonitor)
        if (ad) {
            ad.close()
        }
    }

    function toggleAppDrawer(monitorIndex: int) {
        if (desktopHost.appDrawerActive) {
            desktopHost.closeAppDrawer()
        } else {
            desktopHost.openAppDrawer(monitorIndex)
        }
    }

    function _appDrawerFor(monitorIndex: int): var {
        var list = appDrawerVariants.instances
        for (var i = 0; i < list.length; i++) {
            if (list[i] && list[i].monitorIndex === monitorIndex) {
                return list[i].appDrawerRef
            }
        }
        return null
    }

    function getAppDrawerState(monitorIndex: int): var {
        var mon = (typeof monitorIndex === "number" && monitorIndex >= 0)
            ? monitorIndex
            : desktopHost.appDrawerMonitorIndex
        var ad = desktopHost._appDrawerFor(mon)
        if (!ad) return { available: false, active: false }
        var snap = ad.getSnapshot()
        snap.available = true
        snap.monitorIndex = mon
        return snap
    }

    function getNotificationState(monitorIndex: int): var {
        for (var i = 0; i < desktopHost._surfaces.length; i++) {
            var s = desktopHost._surfaces[i]
            if (s && s.monitorIndex === monitorIndex && s.notificationHostRef) {
                return s.notificationHostRef.getSnapshot()
            }
        }
        return { available: false, count: 0 }
    }

    // =========================================================
    // Wallpaper Picker State & Control (M4-T4, MASTER.md §27)
    // =========================================================
    property bool _wallpaperPickerOpen: false
    property int _wallpaperPickerMonitor: 0

    readonly property bool wallpaperPickerActive: desktopHost._wallpaperPickerOpen || (desktopHost.shellState && desktopHost.shellState.mode === "wallpaper-picker")
    readonly property int wallpaperPickerMonitorIndex: desktopHost._wallpaperPickerMonitor

    function openWallpaperPicker(monitorIndex: int) {
        if (typeof monitorIndex === "number" && monitorIndex >= 0) {
            desktopHost._wallpaperPickerMonitor = monitorIndex
        } else if (desktopHost.shellState) {
            desktopHost._wallpaperPickerMonitor = desktopHost.shellState.activeMonitorIndex
        }
        desktopHost._wallpaperPickerOpen = true
        if (desktopHost.shellState && desktopHost.shellState.mode !== "wallpaper-picker") {
            desktopHost.shellState.setMode("wallpaper-picker")
        }
        var wp = desktopHost._wallpaperPickerFor(desktopHost._wallpaperPickerMonitor)
        if (wp) {
            wp.open()
        }
    }

    function closeWallpaperPicker() {
        desktopHost._wallpaperPickerOpen = false
        if (desktopHost.shellState && desktopHost.shellState.mode === "wallpaper-picker") {
            desktopHost.shellState.dismissOverlay()
        }
        var wp = desktopHost._wallpaperPickerFor(desktopHost._wallpaperPickerMonitor)
        if (wp) {
            wp.close()
        }
    }

    function toggleWallpaperPicker(monitorIndex: int) {
        if (desktopHost.wallpaperPickerActive) {
            desktopHost.closeWallpaperPicker()
        } else {
            desktopHost.openWallpaperPicker(monitorIndex)
        }
    }

    function _wallpaperPickerFor(monitorIndex: int): var {
        var list = wallpaperPickerVariants.instances
        for (var i = 0; i < list.length; i++) {
            if (list[i] && list[i].monitorIndex === monitorIndex) {
                return list[i].wallpaperPickerRef
            }
        }
        return null
    }

    function getWallpaperPickerState(monitorIndex: int): var {
        var mon = (typeof monitorIndex === "number" && monitorIndex >= 0)
            ? monitorIndex
            : desktopHost.wallpaperPickerMonitorIndex
        var wp = desktopHost._wallpaperPickerFor(mon)
        if (!wp) return { available: false, active: false }
        var snap = wp.getSnapshot()
        snap.available = true
        snap.monitorIndex = mon
        return snap
    }

    Connections {
        target: desktopHost.shellState ? desktopHost.shellState : null
        function onModeChanged() {
            if (desktopHost.shellState) {
                if (desktopHost.shellState.mode === "command-center" && !desktopHost._commandCenterOpen) {
                    desktopHost.openCommandCenter("", desktopHost.shellState.activeMonitorIndex)
                } else if (desktopHost.shellState.mode !== "command-center" && desktopHost._commandCenterOpen) {
                    desktopHost._commandCenterOpen = false
                    var cc = desktopHost._commandCenterFor(desktopHost._commandCenterMonitor)
                    if (cc) cc.close()
                }

                if (desktopHost.shellState.mode === "app-drawer" && !desktopHost._appDrawerOpen) {
                    desktopHost.openAppDrawer(desktopHost.shellState.activeMonitorIndex)
                } else if (desktopHost.shellState.mode !== "app-drawer" && desktopHost._appDrawerOpen) {
                    desktopHost._appDrawerOpen = false
                    var ad = desktopHost._appDrawerFor(desktopHost._appDrawerMonitor)
                    if (ad) ad.close()
                }

                if (desktopHost.shellState.mode === "wallpaper-picker" && !desktopHost._wallpaperPickerOpen) {
                    desktopHost.openWallpaperPicker(desktopHost.shellState.activeMonitorIndex)
                } else if (desktopHost.shellState.mode !== "wallpaper-picker" && desktopHost._wallpaperPickerOpen) {
                    desktopHost._wallpaperPickerOpen = false
                    var wp = desktopHost._wallpaperPickerFor(desktopHost._wallpaperPickerMonitor)
                    if (wp) wp.close()
                }
            }
        }
    }

    Connections {
        target: desktopHost.audioService ? desktopHost.audioService : null
        function onOsdRequested(type, value, isMuted) {
            var mon = desktopHost.shellState ? desktopHost.shellState.activeMonitorIndex : 0
            desktopHost.triggerOsd(type, value, isMuted, mon)
        }
    }

    function _registerSurface(surface: var) {
        if (!surface) return
        var next = []
        for (var i = 0; i < desktopHost._surfaces.length; i++) {
            if (desktopHost._surfaces[i] !== surface) {
                next.push(desktopHost._surfaces[i])
            }
        }
        next.push(surface)
        desktopHost._surfaces = next

        if (desktopHost.logger) {
            desktopHost.logger.info("DesktopHost",
                "Desktop surface registered for monitor %1 (%2) [%3x%4]"
                .arg(surface.monitorIndex)
                .arg(surface.screenName)
                .arg(surface.width)
                .arg(surface.height))
        }

        if (desktopHost.eventBus) {
            desktopHost.eventBus.emit("desktop", {
                source: "host",
                type: "surface_registered",
                monitorIndex: surface.monitorIndex,
                screenName: surface.screenName,
                surfaceCount: desktopHost._surfaces.length
            })
        }
    }

    function _unregisterSurface(surface: var) {
        if (!surface) return
        var next = []
        for (var i = 0; i < desktopHost._surfaces.length; i++) {
            if (desktopHost._surfaces[i] !== surface) {
                next.push(desktopHost._surfaces[i])
            }
        }
        desktopHost._surfaces = next

        if (desktopHost.logger) {
            desktopHost.logger.debug("DesktopHost",
                "Desktop surface unregistered for monitor %1 (%2)"
                .arg(surface.monitorIndex)
                .arg(surface.screenName))
        }

        if (desktopHost.eventBus) {
            desktopHost.eventBus.emit("desktop", {
                source: "host",
                type: "surface_unregistered",
                monitorIndex: surface.monitorIndex,
                screenName: surface.screenName,
                surfaceCount: desktopHost._surfaces.length
            })
        }
    }

    // =========================================================
    // Desktop Media Widget Access (M3-T4, DEC-026)
    // =========================================================

    function getMediaWidgetSnapshot(monitorIndex: int): var {
        for (var i = 0; i < desktopHost._surfaces.length; i++) {
            var s = desktopHost._surfaces[i]
            if (s && s.monitorIndex === monitorIndex && s.mediaWidgetRef) {
                return s.mediaWidgetRef.getSnapshot()
            }
        }
        return { available: false, visible: false, expanded: false }
    }

    function toggleMediaWidget(monitorIndex: int): bool {
        desktopHost.mediaWidgetEnabled = !desktopHost.mediaWidgetEnabled
        return desktopHost.mediaWidgetEnabled
    }

    // =========================================================
    // Lifecycle Operations
    // =========================================================

    function initialize() {
        desktopHost.enabled = true
        if (desktopHost.logger) {
            desktopHost.logger.info("DesktopHost", "DesktopHost initialized.")
        }
    }

    function teardown() {
        desktopHost.enabled = false
        desktopHost._surfaces = []
        if (desktopHost.logger) {
            desktopHost.logger.info("DesktopHost", "DesktopHost torn down.")
        }
    }

    // =========================================================
    // Multi-Monitor Layer-Shell Variants
    // =========================================================

    Variants {
        id: variants
        model: desktopHost.enabled ? Quickshell.screens : []

        delegate: Component {
            WlrLayershell {
                id: layerWindow
                required property var modelData

                screen: modelData

                // Anchor to entire screen
                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                color: "transparent"

                layer: desktopHost.layer
                namespace: desktopHost.layerNamespace
                keyboardFocus: WlrKeyboardFocus.None
                exclusiveZone: 0

                // Constrain layer-shell input region strictly to the top island anchor body
                // and the dock trigger/hitbox, ensuring all other desktop space remains
                // completely click-through (DEC-029, DEC-015)
                mask: Region {
                    Region {
                        item: topIsland.anchorItem
                    }
                    Region {
                        item: dock.hitRegionItem
                    }
                    Region {
                        item: notificationHost.hitRegionItem
                    }
                    Region {
                        item: (desktopHost.mediaWidgetEnabled && mediaWidget.widgetVisible) ? mediaWidget : null
                    }
                }

                readonly property string screenName: modelData ? modelData.name : ""
                readonly property var _monitorsRef: desktopHost.monitorModel ? desktopHost.monitorModel.monitors : null
                readonly property int monitorIndex: {
                    var dummy = layerWindow._monitorsRef
                    return desktopHost.resolveMonitorIndex(layerWindow.screenName)
                }

                // DEC-023 & DESIGN.md §14: Cleanly recede when native fullscreen is active on this monitor
                readonly property bool isFullscreen: desktopHost.shellState ? desktopHost.shellState.isMonitorFullscreen(layerWindow.monitorIndex) : false
                visible: desktopHost.enabled && !layerWindow.isFullscreen

                readonly property var topIslandRef: topIsland
                readonly property var workspaceIndicatorRef: workspaceIndicator
                readonly property var dockRef: dock
                readonly property var notificationHostRef: notificationHost
                readonly property var mediaWidgetRef: mediaWidget

                // Foundational M1 Desktop Surfaces (DEC-045)
                TopIslandAnchor {
                    id: topIsland
                    theme: desktopHost.theme
                    isFullscreen: layerWindow.isFullscreen
                    actionRegistry: desktopHost.actionRegistry
                    workspaceModel: desktopHost.workspaceModel
                    windowModel: desktopHost.windowModel
                    mediaService: desktopHost.mediaService
                    statusService: desktopHost.statusService
                    monitorIndex: layerWindow.monitorIndex
                }

                WorkspaceIndicator {
                    id: workspaceIndicator
                    theme: desktopHost.theme
                    workspaceModel: desktopHost.workspaceModel
                    monitorIndex: layerWindow.monitorIndex
                }

                // Primary Interaction Surfaces (M2-T1, M2-T2, DEC-015)
                DockAnchor {
                    id: dock
                    theme: desktopHost.theme
                    config: desktopHost.config
                    windowModel: desktopHost.windowModel
                    workspaceModel: desktopHost.workspaceModel
                    bridge: desktopHost.bridge
                    monitorIndex: layerWindow.monitorIndex
                    isFullscreen: layerWindow.isFullscreen
                }

                // System Feedback Surfaces (M3-T1, DEC-020)
                NotificationHost {
                    id: notificationHost
                    theme: desktopHost.theme
                    notificationModel: desktopHost.notificationModel
                    isFullscreen: layerWindow.isFullscreen
                    monitorIndex: layerWindow.monitorIndex
                }

                // Dedicated Desktop Media Widget (M3-T4, DEC-026)
                MediaWidget {
                    id: mediaWidget
                    theme: desktopHost.theme
                    mediaService: desktopHost.mediaService
                    widgetVisible: desktopHost.mediaWidgetEnabled
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 24
                    anchors.bottomMargin: 24
                }

                Component.onCompleted: {
                    desktopHost._registerSurface(layerWindow)
                }

                Component.onDestruction: {
                    desktopHost._unregisterSurface(layerWindow)
                }
            }
        }
    }

    // =========================================================
    // Fullscreen Top Island Summon Surface (DESIGN.md §14, DEC-016)
    // =========================================================
    // The main surface above is unmapped during native fullscreen. This separate
    // surface exists (mapped) only while this monitor is fullscreen, on the Overlay
    // layer so it can sit above the fullscreen client. Its input region is a 2px
    // top-edge trigger until summoned, so the fullscreen app keeps all input.
    Variants {
        id: summonVariants
        model: desktopHost.enabled ? Quickshell.screens : []

        delegate: Component {
            WlrLayershell {
                id: summonWindow
                required property var modelData

                screen: modelData

                // Top-anchored only: compositor centers it horizontally
                anchors.top: true

                implicitWidth: summonIsland.expandedWidth + (summonIsland.currentTheme.geometry.islandIcr * 2)
                implicitHeight: summonIsland.expandedHeight

                color: "transparent"

                layer: WlrLayer.Overlay
                namespace: desktopHost.layerNamespace + "-summon"
                keyboardFocus: WlrKeyboardFocus.None
                exclusiveZone: 0

                mask: Region {
                    item: summonIsland.anchorItem
                }

                readonly property string screenName: modelData ? modelData.name : ""
                readonly property var _monitorsRef: desktopHost.monitorModel ? desktopHost.monitorModel.monitors : null
                readonly property int monitorIndex: {
                    var dummy = summonWindow._monitorsRef
                    return desktopHost.resolveMonitorIndex(summonWindow.screenName)
                }
                readonly property bool isFullscreen: desktopHost.shellState ? desktopHost.shellState.isMonitorFullscreen(summonWindow.monitorIndex) : false
                readonly property var islandRef: summonIsland

                visible: desktopHost.enabled && summonWindow.isFullscreen
                onVisibleChanged: {
                    if (!summonWindow.visible) summonIsland.collapse()
                }

                TopIslandAnchor {
                    id: summonIsland
                    theme: desktopHost.theme
                    fullscreenSummon: true
                    actionRegistry: desktopHost.actionRegistry
                    workspaceModel: desktopHost.workspaceModel
                    windowModel: desktopHost.windowModel
                    mediaService: desktopHost.mediaService
                    statusService: desktopHost.statusService
                    monitorIndex: summonWindow.monitorIndex
                }
            }
        }
    }

    // =========================================================
    // Command Center Surface Overlay (DEC-017, MASTER.md §13)
    // =========================================================
    Variants {
        id: commandCenterVariants
        model: desktopHost.enabled ? Quickshell.screens : []

        delegate: Component {
            WlrLayershell {
                id: ccWindow
                required property var modelData

                screen: modelData

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                color: "transparent"
                layer: WlrLayer.Overlay
                namespace: desktopHost.layerNamespace + "-command"
                keyboardFocus: (commandCenter.active && ccWindow.isTargetMonitor)
                    ? WlrKeyboardFocus.Exclusive
                    : WlrKeyboardFocus.None
                exclusiveZone: 0

                mask: Region {
                    item: (commandCenter.active && ccWindow.isTargetMonitor) ? commandCenter : null
                }

                readonly property string screenName: modelData ? modelData.name : ""
                readonly property var _monitorsRef: desktopHost.monitorModel ? desktopHost.monitorModel.monitors : null
                readonly property int monitorIndex: {
                    var dummy = ccWindow._monitorsRef
                    return desktopHost.resolveMonitorIndex(ccWindow.screenName)
                }
                readonly property bool isTargetMonitor: ccWindow.monitorIndex === desktopHost.commandCenterMonitorIndex
                readonly property var commandCenterRef: commandCenter

                visible: desktopHost.enabled && desktopHost.commandCenterActive && ccWindow.isTargetMonitor

                CommandCenter {
                    id: commandCenter
                    anchors.fill: parent
                    theme: desktopHost.theme
                    actionRegistry: desktopHost.actionRegistry
                    windowModel: desktopHost.windowModel
                    workspaceModel: desktopHost.workspaceModel
                    config: desktopHost.config
                    bridge: desktopHost.bridge
                    monitorIndex: ccWindow.monitorIndex
                    active: ccWindow.visible

                    onDismissRequested: desktopHost.closeCommandCenter()
                    onActionExecuted: function(actionId, ok) {
                        desktopHost.closeCommandCenter()
                    }
                }
            }
        }
    }

    // =========================================================
    // App Drawer Surface Overlay (DEC-018, DEC-022, MASTER.md §14)
    // =========================================================
    Variants {
        id: appDrawerVariants
        model: desktopHost.enabled ? Quickshell.screens : []

        delegate: Component {
            WlrLayershell {
                id: drawerWindow
                required property var modelData

                screen: modelData

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                color: "transparent"
                layer: WlrLayer.Overlay
                namespace: desktopHost.layerNamespace + "-drawer"
                keyboardFocus: (appDrawer.active && drawerWindow.isTargetMonitor)
                    ? WlrKeyboardFocus.Exclusive
                    : WlrKeyboardFocus.None
                exclusiveZone: 0

                mask: Region {
                    item: (appDrawer.active && drawerWindow.isTargetMonitor) ? appDrawer : null
                }

                readonly property string screenName: modelData ? modelData.name : ""
                readonly property var _monitorsRef: desktopHost.monitorModel ? desktopHost.monitorModel.monitors : null
                readonly property int monitorIndex: {
                    var dummy = drawerWindow._monitorsRef
                    return desktopHost.resolveMonitorIndex(drawerWindow.screenName)
                }
                readonly property bool isTargetMonitor: drawerWindow.monitorIndex === desktopHost.appDrawerMonitorIndex
                readonly property var appDrawerRef: appDrawer

                visible: desktopHost.enabled && desktopHost.appDrawerActive && drawerWindow.isTargetMonitor

                AppDrawer {
                    id: appDrawer
                    anchors.fill: parent
                    theme: desktopHost.theme
                    bridge: desktopHost.bridge
                    config: desktopHost.config
                    monitorIndex: drawerWindow.monitorIndex
                    active: drawerWindow.visible

                    onDismissRequested: desktopHost.closeAppDrawer()
                    onAppLaunched: function(item) {
                        desktopHost.closeAppDrawer()
                    }
                }
            }
        }
    }

    // =========================================================
    // Wallpaper Picker Surface Overlay (M4-T4, MASTER.md §27)
    // =========================================================
    Variants {
        id: wallpaperPickerVariants
        model: desktopHost.enabled ? Quickshell.screens : []

        delegate: Component {
            WlrLayershell {
                id: wpWindow
                required property var modelData

                screen: modelData

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                color: "transparent"
                layer: WlrLayer.Overlay
                namespace: desktopHost.layerNamespace + "-wallpaper-picker"
                keyboardFocus: (wallpaperPicker.active && wpWindow.isTargetMonitor)
                    ? WlrKeyboardFocus.Exclusive
                    : WlrKeyboardFocus.None
                exclusiveZone: 0

                mask: Region {
                    item: (wallpaperPicker.active && wpWindow.isTargetMonitor) ? wallpaperPicker : null
                }

                readonly property string screenName: modelData ? modelData.name : ""
                readonly property var _monitorsRef: desktopHost.monitorModel ? desktopHost.monitorModel.monitors : null
                readonly property int monitorIndex: {
                    var dummy = wpWindow._monitorsRef
                    return desktopHost.resolveMonitorIndex(wpWindow.screenName)
                }
                readonly property bool isTargetMonitor: wpWindow.monitorIndex === desktopHost.wallpaperPickerMonitorIndex
                readonly property var wallpaperPickerRef: wallpaperPicker

                visible: desktopHost.enabled && desktopHost.wallpaperPickerActive && wpWindow.isTargetMonitor

                WallpaperPicker {
                    id: wallpaperPicker
                    anchors.fill: parent
                    theme: desktopHost.theme
                    wallpaperService: desktopHost.wallpaperService
                    paletteService: desktopHost.paletteService
                    workspaceModel: desktopHost.workspaceModel
                    monitorIndex: wpWindow.monitorIndex
                    active: wpWindow.visible

                    onDismissRequested: desktopHost.closeWallpaperPicker()
                    onWallpaperApplied: function(path, ws, isLive) {
                        desktopHost.closeWallpaperPicker()
                    }
                }
            }
        }
    }

    // =========================================================
    // Multi-Monitor Wallpaper Surface (M4-T2, DEC-013)
    // =========================================================
    Variants {
        id: wallpaperVariants
        model: desktopHost.enabled ? Quickshell.screens : []

        delegate: Component {
            WlrLayershell {
                id: wallpaperWindow
                required property var modelData

                screen: modelData

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                color: desktopHost.theme ? desktopHost.theme.colors.surfaceBase : "#16161e"
                layer: WlrLayer.Background
                namespace: desktopHost.layerNamespace + "-wallpaper"
                keyboardFocus: WlrKeyboardFocus.None
                exclusiveZone: -1

                // 100% click-through, 0x0 hitmask
                mask: Region {}

                readonly property string screenName: modelData ? modelData.name : ""
                readonly property var _monitorsRef: desktopHost.monitorModel ? desktopHost.monitorModel.monitors : null
                readonly property int monitorIndex: {
                    var dummy = wallpaperWindow._monitorsRef
                    return desktopHost.resolveMonitorIndex(wallpaperWindow.screenName)
                }

                readonly property string currentWallpaperPath: {
                    if (desktopHost.wallpaperService && typeof desktopHost.wallpaperService.getWallpaperForMonitor === "function") {
                        return desktopHost.wallpaperService.getWallpaperForMonitor(wallpaperWindow.monitorIndex)
                    }
                    return ""
                }

                Item {
                    id: wallpaperContainer
                    anchors.fill: parent

                    Rectangle {
                        anchors.fill: parent
                        color: desktopHost.theme ? desktopHost.theme.colors.surfaceBase : "#16161e"
                    }

                    Image {
                        id: wallpaperImg
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        source: wallpaperWindow.currentWallpaperPath.length > 0 ? ("file://" + wallpaperWindow.currentWallpaperPath) : ""
                        visible: status === Image.Ready
                        opacity: status === Image.Ready ? 1.0 : 0.0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: desktopHost.theme ? desktopHost.theme.motion.durationTheme : 400
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }
            }
        }
    }
}
