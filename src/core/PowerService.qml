// BASEUS — Power & Session Management Service
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §32, DESIGN.md §31, DEC-027, and ROADMAP.md §12:
//   - Event-driven power backend supporting session and power actions:
//       * lock: secure session lock
//       * suspend: system sleep
//       * logout: compositor session termination
//       * reboot: system restart (destructive)
//       * poweroff: system shutdown (destructive)
//   - Destructive action identification for accidental trigger prevention
//   - Clean dispatch via systemctl / loginctl / Hyprland bridge
//   - Automated in-memory simulation parity for headless/WSL2 environments

pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io

Item {
    id: powerService

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var shellState: null
    property var bridge: null
    property var config: null
    property var authService: null

    // =========================================================
    // Service State
    // =========================================================
    property bool simulationMode: false
    property bool dryRun: false
    property string lastAction: ""
    property string lastActionStatus: "idle" // "idle" | "simulated" | "executed" | "failed"
    property string lastActionTimestamp: ""
    property int actionCount: 0

    readonly property var supportedActions: ["lock", "suspend", "logout", "reboot", "poweroff"]
    readonly property var destructiveActions: ["reboot", "poweroff"]

    // =========================================================
    // Action Executor Process
    // =========================================================
    Process {
        id: execProcess
        command: []

        onExited: function(exitCode, exitStatus) {
            if (powerService.logger) {
                powerService.logger.info("PowerService", "Command exited with code: " + exitCode)
            }
        }
    }

    // =========================================================
    // Helper Methods
    // =========================================================
    function isDestructive(action: string): bool {
        return action === "reboot" || action === "poweroff"
    }

    function isSupported(action: string): bool {
        return powerService.supportedActions.indexOf(action) !== -1
    }

    // =========================================================
    // Execution API
    // =========================================================
    function execute(action: string): var {
        if (!isSupported(action)) {
            if (powerService.logger) {
                powerService.logger.warn("PowerService", "Unsupported power action rejected: " + action)
            }
            return { ok: false, action: action, error: "unsupported-action" }
        }

        var isSim = powerService.simulationMode || powerService.dryRun

        powerService.lastAction = action
        powerService.lastActionTimestamp = new Date().toISOString()
        powerService.actionCount++

        if (powerService.logger) {
            powerService.logger.info("PowerService", "Executing power action: " + action + (isSim ? " (simulation)" : " (live)"))
        }

        var res = { ok: true, action: action, simulated: isSim, timestamp: powerService.lastActionTimestamp }

        if (action === "lock" && powerService.authService) {
            powerService.authService.lock()
        }

        if (isSim) {
            powerService.lastActionStatus = "simulated"
            _notifyEventBus(action, true)
            return res
        }

        // Live execution dispatch
        var ok = true
        var cmd = []

        switch (action) {
        case "lock":
            if (powerService.bridge && typeof powerService.bridge.dispatch === "function") {
                powerService.bridge.dispatch("exec loginctl lock-session")
            } else {
                cmd = ["loginctl", "lock-session"]
            }
            break
        case "suspend":
            cmd = ["systemctl", "suspend"]
            break
        case "logout":
            if (powerService.bridge && typeof powerService.bridge.dispatch === "function") {
                powerService.bridge.dispatch("exit")
            } else {
                cmd = ["loginctl", "terminate-user", ""]
            }
            break
        case "reboot":
            cmd = ["systemctl", "reboot"]
            break
        case "poweroff":
            cmd = ["systemctl", "poweroff"]
            break
        default:
            ok = false
            break
        }

        if (cmd.length > 0) {
            try {
                execProcess.command = cmd
                execProcess.running = true
                powerService.lastActionStatus = "executed"
            } catch (e) {
                ok = false
                powerService.lastActionStatus = "failed"
                if (powerService.logger) {
                    powerService.logger.error("PowerService", "Failed to launch process for action: " + action)
                }
            }
        } else {
            powerService.lastActionStatus = ok ? "executed" : "failed"
        }

        res.ok = ok
        _notifyEventBus(action, false)
        return res
    }

    function lock(): var {
        return execute("lock")
    }

    function suspend(): var {
        return execute("suspend")
    }

    function logout(): var {
        return execute("logout")
    }

    function reboot(): var {
        return execute("reboot")
    }

    function poweroff(): var {
        return execute("poweroff")
    }

    function _notifyEventBus(action: string, isSim: bool) {
        if (powerService.eventBus) {
            powerService.eventBus.emit("power", {
                type: "action_triggered",
                action: action,
                isDestructive: powerService.isDestructive(action),
                simulated: isSim,
                timestamp: powerService.lastActionTimestamp
            })
        }
    }

    function getSnapshot(): var {
        return {
            "lastAction": powerService.lastAction,
            "lastActionStatus": powerService.lastActionStatus,
            "lastActionTimestamp": powerService.lastActionTimestamp,
            "actionCount": powerService.actionCount,
            "simulationMode": powerService.simulationMode,
            "dryRun": powerService.dryRun,
            "supportedActions": powerService.supportedActions,
            "destructiveActions": powerService.destructiveActions
        }
    }

    // =========================================================
    // Lifecycle
    // =========================================================
    function initialize() {
        if (powerService.config && powerService.config.simulationEnabled) {
            powerService.simulationMode = true
        }
        if (powerService.logger) {
            powerService.logger.info("PowerService", "Initialized (simulationMode=" + powerService.simulationMode + ")")
        }
    }

    function teardown() {
        if (execProcess.running) {
            execProcess.running = false
        }
        powerService.lastAction = ""
        powerService.lastActionStatus = "idle"
        if (powerService.logger) {
            powerService.logger.info("PowerService", "Teardown complete")
        }
    }
}
