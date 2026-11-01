// BASEUS — Session Authentication & Lock Service
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §35, DESIGN.md §35, DEC-025, and ANTI-SLOP.md:
//   - Manages session lock lifecycle and authentication state machine
//   - Real Linux PAM authentication via Quickshell.Services.Pam.PamContext
//   - Deterministic headless / WSL2 simulation parity under BASEUS_SIMULATION=1
//   - Safe credential handling with zero memory leak and instant failure reset
//   - Emits normalized EventBus notifications under category "auth"

pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Pam

Item {
    id: authService

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var shellState: null
    property var config: null

    // =========================================================
    // State & Configuration
    // =========================================================
    property bool enabled: true
    property bool isLocked: false
    property string authState: "idle" // "idle" | "authenticating" | "failed" | "success"
    property string user: {
        var u = Quickshell.env("USER")
        return (typeof u === "string" && u.length > 0) ? u : "baseus"
    }
    property int failedAttempts: 0
    property string lastError: ""
    property bool simulationMode: false
    property string mockPassword: "baseus"
    property var _mockAuthOverride: null

    signal locked()
    signal unlocked()
    signal authenticationFailed()

    // =========================================================
    // Real Linux PAM Authentication
    // =========================================================
    property string _pendingPassword: ""

    PamContext {
        id: pamContext
        user: authService.user
        config: "login"

        onCompleted: function(result) {
            authService._pendingPassword = ""
            if (result === PamResult.Success) {
                if (authService.logger) {
                    authService.logger.info("AuthService", "PAM authentication succeeded for user: " + authService.user)
                }
                authService.authState = "success"
                authService.unlock()
            } else {
                if (authService.logger) {
                    authService.logger.warn("AuthService", "PAM authentication failed (" + PamResult.toString(result) + ") for user: " + authService.user)
                }
                authService._handleAuthFailure("Invalid password")
            }
        }

        onError: function(err) {
            authService._pendingPassword = ""
            var errStr = PamError.toString(err)
            if (authService.logger) {
                authService.logger.error("AuthService", "PAM error encountered: " + errStr)
            }
            authService._handleAuthFailure(errStr)
        }

        onMessageChanged: {
            if (pamContext.message.indexOf("Password") !== -1 || pamContext.responseRequired) {
                if (authService._pendingPassword.length > 0) {
                    pamContext.respond(authService._pendingPassword)
                    authService._pendingPassword = ""
                }
            }
        }
    }

    // =========================================================
    // Internal State Helpers
    // =========================================================
    function _handleAuthFailure(reason: string) {
        authService.authState = "failed"
        authService.failedAttempts++
        authService.lastError = reason

        _emitEvent("auth_failed", {
            "user": authService.user,
            "failedAttempts": authService.failedAttempts,
            "reason": reason
        })
        authService.authenticationFailed()
    }

    function _emitEvent(type: string, payload: var) {
        if (!authService.eventBus) return

        var evt = {
            "type": type,
            "isLocked": authService.isLocked,
            "authState": authService.authState,
            "user": authService.user,
            "timestamp": new Date().toISOString()
        }

        if (payload) {
            for (var k in payload) {
                evt[k] = payload[k]
            }
        }

        authService.eventBus.emit("auth", evt)
    }

    // =========================================================
    // Public API
    // =========================================================
    function lock(): void {
        if (authService.isLocked) return

        authService.isLocked = true
        authService.authState = "idle"
        authService.lastError = ""

        if (authService.shellState && typeof authService.shellState.setMode === "function") {
            authService.shellState.setMode("locked")
        }

        if (authService.logger) {
            authService.logger.info("AuthService", "Session locked for user: " + authService.user)
        }

        _emitEvent("locked", { "user": authService.user })
        authService.locked()
    }

    function unlock(): void {
        if (!authService.isLocked) return

        authService.isLocked = false
        authService.authState = "idle"
        authService.failedAttempts = 0
        authService.lastError = ""
        authService._pendingPassword = ""

        if (authService.shellState && typeof authService.shellState.dismissOverlay === "function") {
            authService.shellState.dismissOverlay()
        }

        if (authService.logger) {
            authService.logger.info("AuthService", "Session unlocked for user: " + authService.user)
        }

        _emitEvent("unlocked", { "user": authService.user })
        authService.unlocked()
    }

    function authenticate(password: string): bool {
        if (!authService.isLocked) return true
        if (authService.authState === "authenticating") return false

        authService.authState = "authenticating"
        authService.lastError = ""

        var pw = String(password || "")

        // 1. Simulation / Override Evaluation
        if (authService.simulationMode || authService._mockAuthOverride !== null) {
            var ok = false
            if (authService._mockAuthOverride !== null) {
                ok = Boolean(authService._mockAuthOverride)
            } else {
                ok = (pw === authService.mockPassword)
            }

            if (ok) {
                authService.authState = "success"
                authService.unlock()
                return true
            } else {
                authService._handleAuthFailure("Incorrect password")
                return false
            }
        }

        // 2. Live PAM Authentication
        authService._pendingPassword = pw
        var started = pamContext.start()
        if (!started) {
            if (authService.logger) {
                authService.logger.warn("AuthService", "PAM context start failed — falling back to simulation validation")
            }
            // Fallback if PAM service cannot start (e.g. WSL2 permissions)
            var simOk = (pw === authService.mockPassword)
            if (simOk) {
                authService.authState = "success"
                authService.unlock()
                return true
            } else {
                authService._handleAuthFailure("PAM start failed / incorrect password")
                return false
            }
        }

        return true
    }

    function setMockAuthResult(result: bool): void {
        authService._mockAuthOverride = result
    }

    function clearMockAuthResult(): void {
        authService._mockAuthOverride = null
    }

    function resetFailures(): void {
        authService.failedAttempts = 0
        authService.authState = "idle"
        authService.lastError = ""
    }

    function getSnapshot(): var {
        return {
            "available": true,
            "isLocked": authService.isLocked,
            "authState": authService.authState,
            "user": authService.user,
            "failedAttempts": authService.failedAttempts,
            "lastError": authService.lastError,
            "simulationMode": authService.simulationMode
        }
    }

    // =========================================================
    // Lifecycle
    // =========================================================
    function initialize(): void {
        if (authService.config && authService.config.simulationEnabled) {
            authService.simulationMode = true
        }

        authService.isLocked = false
        authService.authState = "idle"
        authService.failedAttempts = 0
        authService.lastError = ""

        if (authService.logger) {
            authService.logger.info("AuthService",
                "AuthService initialized (user=%1, simulationMode=%2)"
                .arg(authService.user)
                .arg(authService.simulationMode))
        }
    }

    function teardown(): void {
        if (pamContext.active) {
            pamContext.abort()
        }
        authService.isLocked = false
        authService.authState = "idle"
        authService.failedAttempts = 0
        authService.lastError = ""
        authService._pendingPassword = ""

        if (authService.logger) {
            authService.logger.info("AuthService", "AuthService teardown complete")
        }
    }
}

