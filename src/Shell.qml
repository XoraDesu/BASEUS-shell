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

    // 5. ShellState — central shell state (depends on Logger, EventBus)
    Core.ShellState {
        id: _shellState
        logger: _logger
        eventBus: _eventBus
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
    }

    Core.MockHyprlandBridge {
        id: _mockBridge
        logger: _logger
        eventBus: _eventBus
        shellState: _shellState
    }

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
                activeMonitor: _shellState.activeMonitorIndex,
                activeWorkspace: _workspaceModel.getActiveWorkspace(_shellState.activeMonitorIndex),
                monitorCount: _monitorModel.getMonitorCount(),
                windowCount: _windowModel.windows.length,
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
                activeWorkspace: _workspaceModel.getActiveWorkspace(_shellState.activeMonitorIndex)
            })
        }
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

        if (_config.simulationEnabled) {
            _mockBridge.initialize()
        } else {
            _liveBridge.initialize()
        }
    }

    function _teardownSubsystems() {
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
