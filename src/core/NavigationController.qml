// BASEUS — Navigation Controller
// Copyright (c) 2026 xoradesu — MIT License
//
// Implements the Back / Home / Overview mental model (DEC-024, MASTER.md §8).
// These are navigation primitives only: they decide *what* a navigation request
// means against current shell, workspace, and window state. They own no state of
// their own — context history is derived from existing owners:
//   - overlay / fullscreen mode        → ShellState
//   - per-monitor previous workspace   → WorkspaceModel.previousWorkspaces
//   - window focus history (MRU)       → WindowModel.focusHistory
//
// Triggers (shortcuts, gestures, UI) never call this directly; they execute
// registered actions (ActionRegistry, DEC-028).
//
// Every method returns a plain result object:
//   { ok: bool, kind: string, reason: string, ... }
// so callers and diagnostics never have to guess why nothing happened.

import QtQuick

QtObject {
    id: navigationController

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var shellState: null
    property var workspaceModel: null
    property var windowModel: null

    // Active compositor bridge (live or mock). Provided by the composition root.
    property var bridge: null

    readonly property int homeWorkspaceId: 1

    // =========================================================
    // Internal helpers
    // =========================================================

    function _ready() {
        return shellState !== null && workspaceModel !== null && windowModel !== null
    }

    function _result(ok, kind, reason, extra) {
        var res = { ok: ok, kind: kind, reason: reason }
        if (extra) {
            for (var key in extra) res[key] = extra[key]
        }
        if (logger) logger.debug("NavigationController",
            "%1 → ok=%2 reason='%3'".arg(kind).arg(ok).arg(reason))
        return res
    }

    function _bridgeUsable() {
        return bridge !== null && bridge.connected === true
    }

    // Most recent window in focus history (other than the focused one) that is
    // still visible on the given monitor's active workspace.
    function _previousWindowOnWorkspace(monitorIndex, workspaceId) {
        var history = windowModel.focusHistory || []
        for (var i = 0; i < history.length; i++) {
            var addr = history[i]
            if (addr === windowModel.focusedAddress) continue
            var win = windowModel.getWindowByAddress(addr)
            if (!win || win.minimized) continue
            if (win.workspace !== workspaceId || win.monitor !== monitorIndex) continue
            return win
        }
        return null
    }

    // =========================================================
    // Back — previous context
    // =========================================================
    // Resolution order (first applicable wins):
    //   1. an active overlay (Overview, …)             → return to desktop
    //   2. the active monitor's previous workspace      → switch to it
    //   3. the previously focused window on this workspace → focus it
    //   4. nothing to go back to                        → ok=false, "nothing-to-go-back-to"

    function back() {
        if (!_ready()) return _result(false, "back", "not-ready")

        if (shellState.isOverlayMode()) {
            var leftMode = shellState.mode
            shellState.dismissOverlay()
            return _result(true, "back", "", { via: "overlay", from: leftMode, mode: shellState.mode })
        }

        var mon = shellState.activeMonitorIndex
        var current = workspaceModel.getActiveWorkspace(mon)
        var previous = workspaceModel.getPreviousWorkspace(mon)

        if (previous !== current) {
            if (!_bridgeUsable()) return _result(false, "back", "bridge-unavailable", { via: "workspace" })
            var switched = bridge.switchWorkspace(previous, mon)
            return _result(switched, "back", switched ? "" : "switch-failed",
                { via: "workspace", monitor: mon, from: current, to: previous })
        }

        var prevWin = _previousWindowOnWorkspace(mon, current)
        if (prevWin) {
            if (!_bridgeUsable()) return _result(false, "back", "bridge-unavailable", { via: "window" })
            var focused = bridge.focusWindow(prevWin.address)
            return _result(focused, "back", focused ? "" : "focus-failed",
                { via: "window", monitor: mon, workspace: current, address: prevWin.address })
        }

        return _result(false, "back", "nothing-to-go-back-to", { via: "none" })
    }

    // =========================================================
    // Home — the desktop
    // =========================================================
    // Dismisses any overlay, then brings the active monitor to Workspace 1.
    // Idempotent: already home is a successful no-op.

    function home() {
        if (!_ready()) return _result(false, "home", "not-ready")

        var dismissed = shellState.isOverlayMode()
        if (dismissed) shellState.dismissOverlay()

        var mon = shellState.activeMonitorIndex
        var current = workspaceModel.getActiveWorkspace(mon)
        if (current === homeWorkspaceId) {
            return _result(true, "home", dismissed ? "" : "already-home",
                { dismissedOverlay: dismissed, monitor: mon, workspace: current })
        }

        if (!_bridgeUsable()) {
            return _result(false, "home", "bridge-unavailable",
                { dismissedOverlay: dismissed, monitor: mon, workspace: current })
        }
        var switched = bridge.switchWorkspace(homeWorkspaceId, mon)
        return _result(switched, "home", switched ? "" : "switch-failed",
            { dismissedOverlay: dismissed, monitor: mon, from: current, to: homeWorkspaceId })
    }

    // =========================================================
    // Overview — Helicopter View (primitive mode toggle only; surface is M5)
    // =========================================================

    function overview() {
        if (!_ready()) return _result(false, "overview", "not-ready")

        if (shellState.overviewActive) {
            shellState.exitOverview()
            return _result(true, "overview", "", { active: false, mode: shellState.mode })
        }

        var entered = shellState.enterOverview()
        return _result(entered.ok, "overview", entered.reason,
            { active: shellState.overviewActive, mode: shellState.mode })
    }
}

