pragma ComponentBehavior: Bound

// BASEUS — Root Shell Component
// Copyright (c) 2026 xoradesu — MIT License
//
// The root shell component that initializes and orchestrates
// all BASEUS foundation systems. This is the single composition
// root for the shell lifecycle.

import Quickshell.Io
import QtQuick
import "core" as Core
import "theme" as ThemeModule
import "desktop" as DesktopModule

Item {
    id: shell

    // =========================================================
    // Foundation Singletons
    // =========================================================
    // Instantiated once at composition root and wired in dependency order.

    // 1. Logger — diagnostics (no dependencies)
    Core.Logger {
        id: _logger
    }

    // 2. EventBus — decoupled communication (depends on Logger)
    Core.EventBus {
        id: _eventBus
        logger: _logger
    }

    // 3. Configuration — static/user config & fallback (depends on Logger, EventBus)
    Core.Config {
        id: _config
        logger: _logger
        eventBus: _eventBus
    }

    // 4. Lifecycle — deterministic init/teardown/restart (depends on Logger, Config, EventBus)
    Core.Lifecycle {
        id: _lifecycle
        logger: _logger
        config: _config
        eventBus: _eventBus
        onInitializeSubsystems: function() { shell._initializeSubsystems() }
        onTeardownSubsystems: function() { shell._teardownSubsystems() }
    }

    // 5. ShellState — central shell state (depends on Logger, EventBus, WorkspaceModel, WindowModel)
    Core.ShellState {
        id: _shellState
        logger: _logger
        eventBus: _eventBus
        workspaceModel: _workspaceModel
        windowModel: _windowModel
    }

    // 6. Design System Theme & Tokens (depends on Logger, EventBus)
    ThemeModule.Theme {
        id: _theme
        logger: _logger
        eventBus: _eventBus
    }

    // 7. Domain Models (initialized before active bridge emits initial context)
    Core.MonitorModel {
        id: _monitorModel
        logger: _logger
        eventBus: _eventBus
    }

    Core.WorkspaceModel {
        id: _workspaceModel
        logger: _logger
        eventBus: _eventBus
        config: _config
        windowModel: _windowModel
    }

    Core.WindowModel {
        id: _windowModel
        logger: _logger
        eventBus: _eventBus
    }

    // 8. Hyprland Integration Boundary & Offline Simulation Bridge
    Core.HyprlandBridge {
        id: _liveBridge
        logger: _logger
        eventBus: _eventBus
        shellState: _shellState
        workspaceModel: _workspaceModel
        monitorModel: _monitorModel
        windowModel: _windowModel
    }

    Core.MockHyprlandBridge {
        id: _mockBridge
        logger: _logger
        eventBus: _eventBus
        shellState: _shellState
        workspaceModel: _workspaceModel
        monitorModel: _monitorModel
        windowModel: _windowModel
    }

    // 9. Navigation primitives (Back / Home / Overview — DEC-024)
    Core.NavigationController {
        id: _navigationController
        logger: _logger
        shellState: _shellState
        workspaceModel: _workspaceModel
        windowModel: _windowModel
        bridge: shell.activeBridge
    }

    // 10. Action registry (Discover → Customize → Execute — DEC-028)
    Core.ActionRegistry {
        id: _actionRegistry
        logger: _logger
        eventBus: _eventBus
        shellState: _shellState
        workspaceModel: _workspaceModel
        windowModel: _windowModel
        navigationController: _navigationController
        bridge: shell.activeBridge
    }

    // 11. Notification Domain Model (M3-T1, DEC-020)
    Core.NotificationModel {
        id: _notificationModel
        logger: _logger
        eventBus: _eventBus
        config: _config
    }

    // 12. Audio & System Feedback Service (M3-T2, DEC-021)
    Core.AudioService {
        id: _audioService
        logger: _logger
        eventBus: _eventBus
        config: _config
    }

    // 13. Media Player Service & MPRIS Bridge (M3-T3, DEC-026, DEC-039)
    Core.MediaService {
        id: _mediaService
        logger: _logger
        eventBus: _eventBus
        config: _config
    }

    // 14. System Status & Health Service (M3-T5, MASTER.md §9, ANTI-SLOP.md §6.7–6.8)
    Core.StatusService {
        id: _statusService
        logger: _logger
        eventBus: _eventBus
        config: _config
        notificationModel: _notificationModel
        bridge: shell.activeBridge
        audioService: _audioService
        mediaService: _mediaService
    }

    // 15. Palette & Matugen Pipeline Service (M4-T1, DEC-011)
    Core.PaletteService {
        id: _paletteService
        logger: _logger
        eventBus: _eventBus
        config: _config
        theme: _theme
    }

    // 16. Wallpaper Engine Service (M4-T2, DEC-013, DEC-014)
    Core.WallpaperService {
        id: _wallpaperService
        logger: _logger
        eventBus: _eventBus
        config: _config
        workspaceModel: _workspaceModel
        monitorModel: _monitorModel
        paletteService: _paletteService
    }

    // 17. Dynamic Theme & Visual State Service (M4-T3, DEC-012, DEC-037)
    Core.ThemeService {
        id: _themeService
        logger: _logger
        eventBus: _eventBus
        config: _config
        theme: _theme
        paletteService: _paletteService
        wallpaperService: _wallpaperService
        desktopHost: _desktopHost
    }

    // 18. Per-Monitor Layer-Shell Desktop Scaffolding (DEC-045, DEC-023)
    DesktopModule.DesktopHost {
        id: _desktopHost
        logger: _logger
        eventBus: _eventBus
        shellState: _shellState
        monitorModel: _monitorModel
        workspaceModel: _workspaceModel
        windowModel: _windowModel
        config: _config
        bridge: shell.activeBridge
        theme: _theme
        actionRegistry: _actionRegistry
        notificationModel: _notificationModel
        audioService: _audioService
        mediaService: _mediaService
        statusService: _statusService
        wallpaperService: _wallpaperService
        paletteService: _paletteService
        themeService: _themeService
        enabled: _lifecycle.initialized
    }

    // Diagnostic-only action counter (see registerDiagnosticAction IPC).
    property int _diagnosticActionRuns: 0

    // =========================================================
    // Public Subsystem References
    // =========================================================
    readonly property alias logger: _logger
    readonly property alias config: _config
    readonly property alias lifecycle: _lifecycle
    readonly property alias shellState: _shellState
    readonly property alias eventBus: _eventBus
    readonly property alias theme: _theme
    readonly property alias monitorModel: _monitorModel
    readonly property alias workspaceModel: _workspaceModel
    readonly property alias windowModel: _windowModel
    readonly property alias liveBridge: _liveBridge
    readonly property alias mockBridge: _mockBridge
    readonly property alias navigationController: _navigationController
    readonly property alias actionRegistry: _actionRegistry
    readonly property alias desktopHost: _desktopHost
    readonly property alias notificationModel: _notificationModel
    readonly property alias audioService: _audioService
    readonly property alias mediaService: _mediaService
    readonly property alias statusService: _statusService
    readonly property alias paletteService: _paletteService
    readonly property alias wallpaperService: _wallpaperService
    readonly property alias themeService: _themeService

    readonly property var activeBridge: _config.simulationEnabled ? _mockBridge : _liveBridge
    readonly property var hyprlandBridge: activeBridge

    // =========================================================
    // Foundation Diagnostic IPC (supports validation & future doctor)
    // =========================================================
    IpcHandler {
        target: "baseus"

        function status(): string {
            var bridge = shell.activeBridge
            return JSON.stringify({
                lifecycle: _lifecycle.state,
                restartCount: _lifecycle.restartCount,
                simulation: _config.simulationEnabled,
                configLoaded: _config.loaded,
                configFallback: _config.usedFallback,
                configLastError: _config.lastError,
                logLevel: _logger.level,
                bridgeType: bridge.isMock ? "mock" : "hyprland",
                bridgeConnected: bridge.connected,
                bridgeError: bridge.lastError,
                mode: _shellState.mode,
                overviewActive: _shellState.overviewActive,
                hasFullscreenApp: _shellState.hasFullscreenApp,
                fullscreenMonitors: _shellState.fullscreenMonitors,
                actionCount: _actionRegistry.actionCount,
                activeMonitor: _shellState.activeMonitorIndex,
                activeWorkspace: _workspaceModel.getActiveWorkspace(_shellState.activeMonitorIndex),
                previousWorkspace: _workspaceModel.getPreviousWorkspace(_shellState.activeMonitorIndex),
                activeWorkspaces: _workspaceModel.activeWorkspaces,
                previousWorkspaces: _workspaceModel.previousWorkspaces,
                monitorCount: _monitorModel.getMonitorCount(),
                windowCount: _windowModel.windows.length,
                minimizedWindowCount: _windowModel.getMinimizedWindows().length,
                focusedWindow: _windowModel.focusedAddress,
                desktopHost: {
                    enabled: _desktopHost.enabled,
                    surfaceCount: _desktopHost.surfaceCount,
                    surfaces: _desktopHost.getSurfaceSnapshot()
                },
                notifications: _notificationModel.getSnapshot(),
                audio: _audioService.getSnapshot(),
                media: _mediaService.getSnapshot(),
                status: _statusService.getSnapshot(),
                subscriptions: {
                    monitor: _eventBus.getSubscriptionCount("monitor"),
                    workspace: _eventBus.getSubscriptionCount("workspace"),
                    window: _eventBus.getSubscriptionCount("window"),
                    theme: _eventBus.getSubscriptionCount("theme")
                }
            })
        }

        function restart(): string {
            var ok = _lifecycle.restart()
            return JSON.stringify({
                restarted: ok,
                lifecycle: _lifecycle.state,
                restartCount: _lifecycle.restartCount,
                subscriptions: {
                    monitor: _eventBus.getSubscriptionCount("monitor"),
                    workspace: _eventBus.getSubscriptionCount("workspace"),
                    window: _eventBus.getSubscriptionCount("window"),
                    theme: _eventBus.getSubscriptionCount("theme")
                }
            })
        }

        function switchWorkspace(workspaceId: int): string {
            var ok = shell.activeBridge.switchWorkspace(workspaceId)
            return JSON.stringify({
                switched: ok,
                activeMonitor: _shellState.activeMonitorIndex,
                activeWorkspace: _workspaceModel.getActiveWorkspace(_shellState.activeMonitorIndex),
                previousWorkspace: _workspaceModel.getPreviousWorkspace(_shellState.activeMonitorIndex)
            })
        }

        function switchMonitorWorkspace(monitorIndex: int, workspaceId: int): string {
            var ok = shell.activeBridge.switchWorkspace(workspaceId, monitorIndex)
            return JSON.stringify({
                switched: ok,
                monitorIndex: monitorIndex,
                activeWorkspace: _workspaceModel.getActiveWorkspace(monitorIndex),
                previousWorkspace: _workspaceModel.getPreviousWorkspace(monitorIndex)
            })
        }

        function nextWorkspace(): string {
            var mon = _shellState.activeMonitorIndex
            var ok = shell.activeBridge.nextWorkspace(mon)
            return JSON.stringify({
                switched: ok,
                activeMonitor: mon,
                activeWorkspace: _workspaceModel.getActiveWorkspace(mon),
                previousWorkspace: _workspaceModel.getPreviousWorkspace(mon)
            })
        }

        function previousWorkspace(): string {
            var mon = _shellState.activeMonitorIndex
            var ok = shell.activeBridge.previousWorkspace(mon)
            return JSON.stringify({
                switched: ok,
                activeMonitor: mon,
                activeWorkspace: _workspaceModel.getActiveWorkspace(mon),
                previousWorkspace: _workspaceModel.getPreviousWorkspace(mon)
            })
        }

        function workspaces(): string {
            return JSON.stringify(_workspaceModel.getSnapshot(_shellState.activeMonitorIndex))
        }

        function windows(): string {
            return JSON.stringify(_windowModel.getSnapshot())
        }

        function focusWindow(address: string): string {
            var ok = shell.activeBridge.focusWindow(address)
            return JSON.stringify({
                focused: ok,
                focusedWindow: _windowModel.focusedAddress,
                window: _windowModel.getWindowByAddress(address || _windowModel.focusedAddress)
            })
        }

        function closeWindow(address: string): string {
            var ok = shell.activeBridge.closeWindow(address)
            return JSON.stringify({
                closed: ok,
                windowCount: _windowModel.windows.length,
                focusedWindow: _windowModel.focusedAddress
            })
        }

        function centerWindow(address: string, monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            var ok = shell.activeBridge.centerWindow(address, monArg)
            return JSON.stringify({
                centered: ok,
                window: _windowModel.getWindowByAddress(address || _windowModel.focusedAddress)
            })
        }

        function moveWindow(address: string, x: int, y: int): string {
            var ok = shell.activeBridge.moveWindow(address, x, y)
            return JSON.stringify({
                moved: ok,
                window: _windowModel.getWindowByAddress(address || _windowModel.focusedAddress)
            })
        }

        function resizeWindow(address: string, width: int, height: int): string {
            var ok = shell.activeBridge.resizeWindow(address, width, height)
            return JSON.stringify({
                resized: ok,
                window: _windowModel.getWindowByAddress(address || _windowModel.focusedAddress)
            })
        }

        function toggleFloating(address: string): string {
            var ok = shell.activeBridge.toggleFloating(address)
            return JSON.stringify({
                toggled: ok,
                window: _windowModel.getWindowByAddress(address || _windowModel.focusedAddress)
            })
        }

        function toggleMaximize(address: string): string {
            var ok = shell.activeBridge.toggleMaximize(address)
            return JSON.stringify({
                toggled: ok,
                mode: _shellState.mode,
                hasFullscreenApp: _shellState.hasFullscreenApp,
                window: _windowModel.getWindowByAddress(address || _windowModel.focusedAddress)
            })
        }

        function toggleFullscreen(address: string): string {
            var ok = shell.activeBridge.toggleFullscreen(address)
            return JSON.stringify({
                toggled: ok,
                mode: _shellState.mode,
                hasFullscreenApp: _shellState.hasFullscreenApp,
                fullscreenMonitors: _shellState.fullscreenMonitors,
                window: _windowModel.getWindowByAddress(address || _windowModel.focusedAddress)
            })
        }

        function minimizeWindow(address: string): string {
            var targetAddr = address || _windowModel.focusedAddress
            var ok = shell.activeBridge.minimizeWindow(targetAddr)
            return JSON.stringify({
                minimized: ok,
                mode: _shellState.mode,
                focusedWindow: _windowModel.focusedAddress,
                minimizedCount: _windowModel.getMinimizedWindows().length,
                window: _windowModel.getWindowByAddress(targetAddr)
            })
        }

        function restoreWindow(address: string, targetWorkspaceId: int, targetMonitorIndex: int): string {
            var wsArg = (targetWorkspaceId >= 1 && targetWorkspaceId <= 10) ? targetWorkspaceId : undefined
            var monArg = targetMonitorIndex >= 0 ? targetMonitorIndex : undefined
            var ok = shell.activeBridge.restoreWindow(address, wsArg, monArg)
            return JSON.stringify({
                restored: ok,
                activeMonitor: _shellState.activeMonitorIndex,
                activeWorkspace: _workspaceModel.getActiveWorkspace(_shellState.activeMonitorIndex),
                focusedWindow: _windowModel.focusedAddress,
                minimizedCount: _windowModel.getMinimizedWindows().length,
                window: _windowModel.getWindowByAddress(address || _windowModel.focusedAddress)
            })
        }

        function moveWindowToWorkspace(address: string, workspaceId: int, followFocus: bool): string {
            var targetAddr = address || _windowModel.focusedAddress
            var ok = shell.activeBridge.moveWindowToWorkspace(targetAddr, workspaceId, followFocus)
            return JSON.stringify({
                moved: ok,
                transition: "pop",
                activeMonitor: _shellState.activeMonitorIndex,
                activeWorkspace: _workspaceModel.getActiveWorkspace(_shellState.activeMonitorIndex),
                focusedWindow: _windowModel.focusedAddress,
                window: _windowModel.getWindowByAddress(targetAddr)
            })
        }

        function moveWindowToMonitor(address: string, monitorIndex: int, followFocus: bool): string {
            var targetAddr = address || _windowModel.focusedAddress
            var ok = shell.activeBridge.moveWindowToMonitor(targetAddr, monitorIndex, followFocus)
            return JSON.stringify({
                moved: ok,
                transition: "pop",
                activeMonitor: _shellState.activeMonitorIndex,
                activeWorkspace: _workspaceModel.getActiveWorkspace(_shellState.activeMonitorIndex),
                focusedWindow: _windowModel.focusedAddress,
                window: _windowModel.getWindowByAddress(targetAddr)
            })
        }

        function setMockMonitors(count: int): string {
            var ok = _config.simulationEnabled ? _mockBridge.setMockMonitorCount(count) : false
            return JSON.stringify({
                updated: ok,
                monitorCount: _monitorModel.getMonitorCount(),
                activeWorkspaces: _workspaceModel.activeWorkspaces
            })
        }

        function spawnMockWindow(title: string, appClass: string, workspaceId: int, width: int, height: int): string {
            var addr = _config.simulationEnabled
                ? _mockBridge.addMockWindow(title, appClass, workspaceId, width, height)
                : ""
            return JSON.stringify({
                spawned: addr.length > 0,
                address: addr,
                window: _windowModel.getWindowByAddress(addr)
            })
        }

        // -----------------------------------------------------
        // M1-T3: Action Registry & navigation primitives
        // -----------------------------------------------------

        function listActions(category: string, query: string): string {
            var actions = _actionRegistry.list({ category: category, query: query })
            return JSON.stringify({
                count: actions.length,
                categories: _actionRegistry.getCategories(),
                actions: actions
            })
        }

        function getAction(id: string): string {
            return JSON.stringify({ action: _actionRegistry.get(id) })
        }

        function shortcutOwners(shortcut: string): string {
            return JSON.stringify({
                shortcut: shortcut,
                normalized: _actionRegistry.normalizeShortcut(shortcut),
                owners: _actionRegistry.findShortcutOwners(shortcut)
            })
        }

        function executeAction(id: string): string {
            return JSON.stringify(shell._executeActionWithState(id, undefined))
        }

        // payload: JSON object string, e.g. {"address":"0x1a2b"}
        function executeActionWithPayload(id: string, payload: string): string {
            var parsed
            try {
                parsed = JSON.parse(payload)
            } catch (e) {
                return JSON.stringify({ ok: false, id: id, error: "invalid-payload" })
            }
            return JSON.stringify(shell._executeActionWithState(id, parsed))
        }

        // Registers a no-op action owned by "diagnostic" (exercises registry integrity rules).
        function registerDiagnosticAction(id: string, category: string, shortcut: string): string {
            var res = _actionRegistry.register({
                id: id,
                category: category,
                title: "Diagnostic " + id,
                description: "Diagnostic no-op action.",
                defaultShortcut: shortcut,
                callback: function() { shell._diagnosticActionRuns++; return { ran: shell._diagnosticActionRuns } }
            }, "diagnostic")
            res.actionCount = _actionRegistry.actionCount
            return JSON.stringify(res)
        }

        // Can only remove actions owned by "diagnostic"; core actions are protected.
        function unregisterAction(id: string): string {
            var res = _actionRegistry.unregister(id, "diagnostic")
            res.actionCount = _actionRegistry.actionCount
            return JSON.stringify(res)
        }

        // Returns current active Layer-Shell desktop surfaces (M1-T4, M1-T5)
        function desktopSurfaces(): string {
            return JSON.stringify({
                enabled: _desktopHost.enabled,
                surfaceCount: _desktopHost.surfaceCount,
                surfaces: _desktopHost.getSurfaceSnapshot()
            })
        }

        // Diagnostic trigger for workspace indicator (M1-T5)
        function triggerWorkspaceIndicator(monitorIndex: int, prevWs: int, currWs: int, label: string): string {
            var ok = _desktopHost.triggerWorkspaceIndicator(monitorIndex, prevWs, currWs, label)
            return JSON.stringify({
                ok: ok,
                monitorIndex: monitorIndex,
                current: currWs,
                previous: prevWs,
                label: label
            })
        }

        // Sets user-defined workspace label (MASTER.md §7)
        function setWorkspaceLabel(workspaceId: int, label: string): string {
            var ok = _workspaceModel.setLabel(workspaceId, label)
            return JSON.stringify({
                ok: ok,
                workspaceId: workspaceId,
                label: label
            })
        }

        // Reveals Dock on specified monitor (M2-T1)
        function revealDock(monitorIndex: int): string {
            var ok = _desktopHost.revealDock(monitorIndex)
            return JSON.stringify({
                ok: ok,
                monitorIndex: monitorIndex,
                revealed: _desktopHost.isDockRevealed(monitorIndex)
            })
        }

        // Hides/recedes Dock on specified monitor (M2-T1)
        function hideDock(monitorIndex: int): string {
            var ok = _desktopHost.hideDock(monitorIndex)
            return JSON.stringify({
                ok: ok,
                monitorIndex: monitorIndex,
                revealed: _desktopHost.isDockRevealed(monitorIndex)
            })
        }

        // Queries Dock revealed status on specified monitor (M2-T1)
        function dockRevealed(monitorIndex: int): string {
            return JSON.stringify({
                monitorIndex: monitorIndex,
                revealed: _desktopHost.isDockRevealed(monitorIndex)
            })
        }

        // Queries Dock items on specified monitor (M2-T2)
        function dockItems(monitorIndex: int): string {
            return JSON.stringify({
                monitorIndex: monitorIndex,
                items: _desktopHost.getDockItems(monitorIndex)
            })
        }

        // Activates/clicks Dock item by ID on specified monitor (M2-T2)
        function clickDockItem(monitorIndex: int, itemId: string): string {
            var ok = _desktopHost.clickDockItem(monitorIndex, itemId)
            return JSON.stringify({
                ok: ok,
                monitorIndex: monitorIndex,
                itemId: itemId
            })
        }

        // Top Island state on the monitor's current top-edge owner (M2-T3):
        // main anchor on desktop, summon surface during native fullscreen.
        function topIslandState(monitorIndex: int): string {
            return JSON.stringify(_desktopHost.getTopIslandState(monitorIndex))
        }

        // Diagnostic: drives the same code path as real pointer hover enter/leave.
        function setTopIslandHover(monitorIndex: int, hovered: bool): string {
            var ok = _desktopHost.setTopIslandHover(monitorIndex, hovered)
            return JSON.stringify({ ok: ok, monitorIndex: monitorIndex, hovered: hovered })
        }

        // Diagnostic: drives the same code path as a real tap on the island.
        function tapTopIsland(monitorIndex: int): string {
            var ok = _desktopHost.tapTopIsland(monitorIndex)
            return JSON.stringify({ ok: ok, monitorIndex: monitorIndex })
        }

        // Diagnostic: activates a header navigation trigger (executes via ActionRegistry).
        function clickTopIslandTrigger(monitorIndex: int, actionId: string): string {
            var ok = _desktopHost.clickTopIslandTrigger(monitorIndex, actionId)
            return JSON.stringify({ ok: ok, monitorIndex: monitorIndex, actionId: actionId })
        }

        // -----------------------------------------------------
        // M2-T4: Command Center Surface & Action Prefix Routing
        // -----------------------------------------------------

        function toggleCommandCenter(monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            _desktopHost.toggleCommandCenter(monArg)
            return JSON.stringify({
                active: _desktopHost.commandCenterActive,
                mode: _shellState.mode,
                monitorIndex: _desktopHost.commandCenterMonitorIndex
            })
        }

        function openCommandCenter(prefix: string, monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            _desktopHost.openCommandCenter(prefix, monArg)
            return JSON.stringify({
                active: _desktopHost.commandCenterActive,
                mode: _shellState.mode,
                prefix: prefix,
                monitorIndex: _desktopHost.commandCenterMonitorIndex
            })
        }

        function closeCommandCenter(): string {
            _desktopHost.closeCommandCenter()
            return JSON.stringify({
                active: _desktopHost.commandCenterActive,
                mode: _shellState.mode
            })
        }

        function commandCenterState(monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            return JSON.stringify(_desktopHost.getCommandCenterState(monArg))
        }

        function commandCenterInput(text: string, monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            var mon = (monArg !== undefined) ? monArg : _desktopHost.commandCenterMonitorIndex
            var cc = _desktopHost._commandCenterFor(mon)
            if (!cc) return JSON.stringify({ ok: false, reason: "not-available" })
            cc.setInput(text)
            return JSON.stringify({ ok: true, state: cc.getSnapshot() })
        }

        function commandCenterExecute(index: int, monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            var mon = (monArg !== undefined) ? monArg : _desktopHost.commandCenterMonitorIndex
            var cc = _desktopHost._commandCenterFor(mon)
            if (!cc) return JSON.stringify({ ok: false, reason: "not-available" })
            var ok = (index >= 0) ? cc.executeIndex(index) : cc.executeSelected()
            return JSON.stringify({ ok: ok, state: cc.getSnapshot() })
        }

        // -----------------------------------------------------
        // App Drawer Diagnostic Telemetry & Control (M2-T5)
        // -----------------------------------------------------

        function toggleAppDrawer(monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            _desktopHost.toggleAppDrawer(monArg)
            return JSON.stringify({
                active: _desktopHost.appDrawerActive,
                mode: _shellState.mode,
                monitorIndex: _desktopHost.appDrawerMonitorIndex
            })
        }

        function openAppDrawer(monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            _desktopHost.openAppDrawer(monArg)
            return JSON.stringify({
                active: _desktopHost.appDrawerActive,
                mode: _shellState.mode,
                monitorIndex: _desktopHost.appDrawerMonitorIndex
            })
        }

        function closeAppDrawer(): string {
            _desktopHost.closeAppDrawer()
            return JSON.stringify({
                active: _desktopHost.appDrawerActive,
                mode: _shellState.mode
            })
        }

        function appDrawerState(monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            return JSON.stringify(_desktopHost.getAppDrawerState(monArg))
        }

        function appDrawerSearch(query: string, monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            var mon = (monArg !== undefined) ? monArg : _desktopHost.appDrawerMonitorIndex
            var ad = _desktopHost._appDrawerFor(mon)
            if (!ad) return JSON.stringify({ ok: false, reason: "not-available" })
            ad.setSearch(query)
            return JSON.stringify({ ok: true, state: ad.getSnapshot() })
        }

        function appDrawerScrub(letter: string, monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            var mon = (monArg !== undefined) ? monArg : _desktopHost.appDrawerMonitorIndex
            var ad = _desktopHost._appDrawerFor(mon)
            if (!ad) return JSON.stringify({ ok: false, reason: "not-available" })
            var ok = ad.scrubTo(letter)
            return JSON.stringify({ ok: ok, letter: letter, state: ad.getSnapshot() })
        }

        function appDrawerLaunch(idOrIndex: string, monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            var mon = (monArg !== undefined) ? monArg : _desktopHost.appDrawerMonitorIndex
            var ad = _desktopHost._appDrawerFor(mon)
            if (!ad) return JSON.stringify({ ok: false, reason: "not-available" })
            var idx = parseInt(idOrIndex, 10)
            var ok = false
            if (!isNaN(idx) && String(idx) === String(idOrIndex).trim()) {
                ok = ad.launchIndex(idx)
            } else {
                ok = ad.launchId(idOrIndex)
            }
            return JSON.stringify({ ok: ok, state: ad.getSnapshot() })
        }

        // -----------------------------------------------------
        // M3-T1: Notifications Domain & IPC
        // -----------------------------------------------------

        function postNotification(appName: string, appIcon: string, summary: string, body: string, urgency: string): string {
            var id = _notificationModel.postNotification(appName, appIcon, summary, body, urgency, undefined, 0)
            return JSON.stringify({
                ok: id > 0,
                id: id,
                count: _notificationModel.count,
                state: _notificationModel.getSnapshot()
            })
        }

        function dismissNotification(id: int): string {
            _notificationModel.dismiss(id)
            return JSON.stringify({
                ok: true,
                id: id,
                count: _notificationModel.count,
                state: _notificationModel.getSnapshot()
            })
        }

        function silenceNotifications(): string {
            _notificationModel.silenceAll()
            return JSON.stringify({
                ok: true,
                silenced: _notificationModel.silenced,
                count: _notificationModel.count
            })
        }

        function resetSilence(): string {
            _notificationModel.resetSilence()
            return JSON.stringify({
                ok: true,
                silenced: _notificationModel.silenced
            })
        }

        function notificationState(): string {
            return JSON.stringify(_notificationModel.getSnapshot())
        }

        // =====================================================
        // System Feedback & OSD Operations (M3-T2, DEC-021)
        // =====================================================

        function triggerOsd(type: string, value: real, isMuted: bool): string {
            var t = (typeof type === "string" && type.length > 0) ? type : "volume"
            var v = (typeof value === "number") ? value : (t === "brightness" ? _audioService.brightness : _audioService.volume)
            var m = (typeof isMuted === "boolean") ? isMuted : (t === "volume" ? _audioService.muted : false)
            _audioService.triggerOsd(t, v, m)
            var mon = _shellState.activeMonitorIndex
            _desktopHost.triggerOsd(t, v, m, mon)
            return JSON.stringify({
                ok: true,
                type: t,
                value: v,
                percent: Math.round(v * 100),
                isMuted: m,
                activeMonitor: mon
            })
        }

        function osdState(monitorIndex: int): string {
            var mon = (typeof monitorIndex === "number" && monitorIndex >= 0)
                ? monitorIndex
                : _shellState.activeMonitorIndex
            return JSON.stringify(_desktopHost.getOsdState(mon))
        }

        function setVolume(val: real): string {
            _audioService.setVolume(val, true)
            return JSON.stringify(_audioService.getSnapshot())
        }

        function stepVolume(delta: real): string {
            _audioService.stepVolume(delta)
            return JSON.stringify(_audioService.getSnapshot())
        }

        function toggleMute(): string {
            _audioService.toggleMute()
            return JSON.stringify(_audioService.getSnapshot())
        }

        function setBrightness(val: real): string {
            _audioService.setBrightness(val, true)
            return JSON.stringify(_audioService.getSnapshot())
        }

        function stepBrightness(delta: real): string {
            _audioService.stepBrightness(delta)
            return JSON.stringify(_audioService.getSnapshot())
        }

        // =====================================================
        // Media Operations (M3-T3, DEC-026, DEC-039)
        // =====================================================

        function mediaStatus(): string {
            return JSON.stringify(_mediaService.getSnapshot())
        }

        function mediaPlay(): string {
            _mediaService.play()
            return JSON.stringify(_mediaService.getSnapshot())
        }

        function mediaPause(): string {
            _mediaService.pause()
            return JSON.stringify(_mediaService.getSnapshot())
        }

        function mediaToggle(): string {
            _mediaService.togglePlay()
            return JSON.stringify(_mediaService.getSnapshot())
        }

        function mediaNext(): string {
            _mediaService.next()
            return JSON.stringify(_mediaService.getSnapshot())
        }

        function mediaPrevious(): string {
            _mediaService.previous()
            return JSON.stringify(_mediaService.getSnapshot())
        }

        function mediaSeek(pos: real): string {
            _mediaService.seek(pos)
            return JSON.stringify(_mediaService.getSnapshot())
        }

        function mediaWidgetState(monitorIndex: int): string {
            return JSON.stringify(_desktopHost.getMediaWidgetSnapshot(typeof monitorIndex === "number" ? monitorIndex : 0))
        }

        function toggleMediaWidget(monitorIndex: int): string {
            var enabled = _desktopHost.toggleMediaWidget(typeof monitorIndex === "number" ? monitorIndex : 0)
            return JSON.stringify({
                enabled: enabled,
                mediaWidget: _desktopHost.getMediaWidgetSnapshot(typeof monitorIndex === "number" ? monitorIndex : 0)
            })
        }

        function bongoCatState(monitorIndex: int): string {
            var mw = _desktopHost.getMediaWidgetSnapshot(typeof monitorIndex === "number" ? monitorIndex : 0)
            return JSON.stringify(mw && mw.bongoCat ? mw.bongoCat : { isPlaying: false, resting: true })
        }

        // =====================================================
        // System Status & Health Operations (M3-T5, MASTER.md §9, ANTI-SLOP.md §6.7–6.8)
        // =====================================================

        function systemStatus(): string {
            return JSON.stringify(_statusService.getSnapshot())
        }

        function setMockBattery(percent: real, isCharging: bool): string {
            _statusService.setMockBattery(percent, isCharging)
            return JSON.stringify(_statusService.getSnapshot())
        }

        function setMockNetwork(connected: bool, type: string, name: string): string {
            _statusService.setMockNetwork(connected, type, name)
            return JSON.stringify(_statusService.getSnapshot())
        }

        // =====================================================
        // Palette Operations (M4-T1, DEC-011)
        // =====================================================

        function getPalette(): string {
            return JSON.stringify(_paletteService.getPalette())
        }

        function extractPalette(wallpaperPath: string): string {
            var pal = _paletteService.extractPalette(wallpaperPath)
            return JSON.stringify(pal)
        }

        function setPalette(dominant: string, secondary: string, accent: string, neutral: string): string {
            var pal = _paletteService.setPalette(dominant, secondary, accent, neutral)
            return JSON.stringify(pal)
        }

        // =====================================================
        // Wallpaper Operations (M4-T2, DEC-013, DEC-014)
        // =====================================================

        function setWorkspaceWallpaper(workspaceId: int, path: string): string {
            var ok = _wallpaperService.setWorkspaceWallpaper(workspaceId, path)
            return JSON.stringify({
                ok: ok,
                workspace: workspaceId,
                path: path,
                wallpaperState: _wallpaperService.getSnapshot(_shellState.activeMonitorIndex)
            })
        }

        function setGlobalLiveWallpaper(path: string): string {
            var ok = _wallpaperService.setGlobalLiveWallpaper(path)
            return JSON.stringify({
                ok: ok,
                path: path,
                wallpaperState: _wallpaperService.getSnapshot(_shellState.activeMonitorIndex)
            })
        }

        function wallpaperState(monitorIndex: int): string {
            var mon = (typeof monitorIndex === "number" && monitorIndex >= 0) ? monitorIndex : _shellState.activeMonitorIndex
            return JSON.stringify(_wallpaperService.getSnapshot(mon))
        }

        // =====================================================
        // Wallpaper Picker Diagnostic Telemetry & Control (M4-T4)
        // =====================================================

        function toggleWallpaperPicker(monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            _desktopHost.toggleWallpaperPicker(monArg)
            return JSON.stringify({
                active: _desktopHost.wallpaperPickerActive,
                mode: _shellState.mode,
                monitorIndex: _desktopHost.wallpaperPickerMonitorIndex
            })
        }

        function openWallpaperPicker(monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            _desktopHost.openWallpaperPicker(monArg)
            return JSON.stringify({
                active: _desktopHost.wallpaperPickerActive,
                mode: _shellState.mode,
                monitorIndex: _desktopHost.wallpaperPickerMonitorIndex
            })
        }

        function closeWallpaperPicker(): string {
            _desktopHost.closeWallpaperPicker()
            return JSON.stringify({
                active: _desktopHost.wallpaperPickerActive,
                mode: _shellState.mode
            })
        }

        function wallpaperPickerState(monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            return JSON.stringify(_desktopHost.getWallpaperPickerState(monArg))
        }

        function wallpaperPickerSetTab(tab: string, monitorIndex: int): string {
            var mon = monitorIndex >= 0 ? monitorIndex : _desktopHost.wallpaperPickerMonitorIndex
            var wp = _desktopHost._wallpaperPickerFor(mon)
            if (!wp) return JSON.stringify({ ok: false, reason: "not-available" })
            wp.setTab(tab)
            return JSON.stringify({ ok: true, state: wp.getSnapshot() })
        }

        function wallpaperPickerSelect(index: int, monitorIndex: int): string {
            var mon = monitorIndex >= 0 ? monitorIndex : _desktopHost.wallpaperPickerMonitorIndex
            var wp = _desktopHost._wallpaperPickerFor(mon)
            if (!wp) return JSON.stringify({ ok: false, reason: "not-available" })
            wp.selectedIndex = index
            return JSON.stringify({ ok: true, state: wp.getSnapshot() })
        }

        function wallpaperPickerApply(allWorkspaces: bool, monitorIndex: int): string {
            var mon = monitorIndex >= 0 ? monitorIndex : _desktopHost.wallpaperPickerMonitorIndex
            var wp = _desktopHost._wallpaperPickerFor(mon)
            if (!wp) return JSON.stringify({ ok: false, reason: "not-available" })
            var ok = wp.applySelected(allWorkspaces)
            return JSON.stringify({ ok: ok, state: wp.getSnapshot() })
        }

        // =====================================================
        // Theme Operations (M4-T3, DEC-012, DEC-037)
        // =====================================================

        function saveCurrentTheme(name: string): string {
            var t = _themeService.saveCurrentTheme(name)
            return JSON.stringify({
                ok: (t !== null),
                theme: t
            })
        }

        function applyTheme(name: string): string {
            var ok = _themeService.applyTheme(name)
            return JSON.stringify({
                ok: ok,
                name: name,
                activeTheme: _themeService.activeThemeName,
                activeTransition: _themeService.activeTransition
            })
        }

        function listThemes(): string {
            return JSON.stringify(_themeService.listThemes())
        }

        function dailySnapshotState(): string {
            return JSON.stringify(_themeService.dailySnapshotState())
        }

        // =====================================================
        // Headquarter Operations & Diagnostic Control (M4-T5, DEC-019)
        // =====================================================

        function openHeadquarter(category: string, monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            var cat = (typeof category === "string" && category.length > 0) ? category : "home"
            _desktopHost.openHeadquarter(cat, monArg)
            return JSON.stringify({
                active: _desktopHost.headquarterActive,
                mode: _shellState.mode,
                category: cat,
                monitorIndex: _desktopHost.headquarterMonitorIndex
            })
        }

        function closeHeadquarter(): string {
            _desktopHost.closeHeadquarter()
            return JSON.stringify({
                active: _desktopHost.headquarterActive,
                mode: _shellState.mode
            })
        }

        function toggleHeadquarter(monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            _desktopHost.toggleHeadquarter(monArg)
            return JSON.stringify({
                active: _desktopHost.headquarterActive,
                mode: _shellState.mode,
                monitorIndex: _desktopHost.headquarterMonitorIndex
            })
        }

        function headquarterState(monitorIndex: int): string {
            var monArg = monitorIndex >= 0 ? monitorIndex : undefined
            return JSON.stringify(_desktopHost.getHeadquarterState(monArg))
        }

        function headquarterSetCategory(category: string, monitorIndex: int): string {
            var mon = monitorIndex >= 0 ? monitorIndex : _desktopHost.headquarterMonitorIndex
            var hq = _desktopHost._headquarterFor(mon)
            if (!hq) return JSON.stringify({ ok: false, reason: "not-available" })
            hq.setCategory(category)
            return JSON.stringify({ ok: true, state: hq.getSnapshot() })
        }

        function headquarterSearch(query: string, monitorIndex: int): string {
            var mon = monitorIndex >= 0 ? monitorIndex : _desktopHost.headquarterMonitorIndex
            var hq = _desktopHost._headquarterFor(mon)
            if (!hq) return JSON.stringify({ ok: false, reason: "not-available" })
            hq.setSearch(query)
            return JSON.stringify({ ok: true, state: hq.getSnapshot() })
        }
    }

    function _executeActionWithState(id, payload) {
        var res = _actionRegistry.execute(id, payload)
        res.mode = _shellState.mode
        res.overviewActive = _shellState.overviewActive
        res.activeMonitor = _shellState.activeMonitorIndex
        res.activeWorkspace = _workspaceModel.getActiveWorkspace(_shellState.activeMonitorIndex)
        res.previousWorkspace = _workspaceModel.getPreviousWorkspace(_shellState.activeMonitorIndex)
        res.focusedWindow = _windowModel.focusedAddress
        return res
    }

    // =========================================================
    // Deterministic Subsystem Orchestration
    // =========================================================

    function _initializeSubsystems() {
        _theme.motion.reducedMotion = _config.reducedMotion
        _theme.initialize()
        _shellState.initialize()
        _monitorModel.initialize()
        _workspaceModel.initialize()
        _windowModel.initialize()
        _actionRegistry.initialize()

        if (_config.simulationEnabled) {
            _mockBridge.initialize()
        } else {
            _liveBridge.initialize()
        }

        _wallpaperService.initialize()
        _themeService.initialize()
        _desktopHost.initialize()
    }

    function _teardownSubsystems() {
        _notificationModel.dismissAll()
        _desktopHost.teardown()
        _themeService.teardown()
        _wallpaperService.teardown()
        _actionRegistry.teardown()
        _mockBridge.teardown()
        _liveBridge.teardown()
        _windowModel.teardown()
        _workspaceModel.teardown()
        _monitorModel.teardown()
        _shellState.teardown()
        _theme.teardown()
    }

    Component.onCompleted: {
        _logger.info("Shell", "BASEUS shell initializing...")
        _lifecycle.initialize()
        _logger.info("Shell", "BASEUS shell ready (simulation=%1, bridgeConnected=%2)."
            .arg(_config.simulationEnabled)
            .arg(shell.activeBridge.connected))
    }

    Component.onDestruction: {
        _logger.info("Shell", "BASEUS shell shutting down...")
        _lifecycle.teardown()
        _logger.info("Shell", "BASEUS shell terminated.")
    }
}
