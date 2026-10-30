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
    }

    function _teardownSubsystems() {
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
