// BASEUS — Action Registry
// Copyright (c) 2026 xoradesu — MIT License
//
// Actions are primitives (DEC-028: Discover → Customize → Execute).
//   Discover  — enumerate/query registered actions (list, get, search, categories).
//   Customize — triggers (shortcuts, gestures) bind to action IDs; the registry keeps
//               action identity separate from trigger assignment and reports default
//               shortcut conflicts explicitly.
//   Execute   — execute(actionId, payload) runs exactly one registered callback.
//
// Integrity rules:
//   - IDs are unique and namespaced ("category.name"); duplicates are rejected, never replaced.
//   - Only the registering owner may unregister an action.
//   - Query APIs return plain copies without callbacks, so consumers cannot mutate
//     registry state or invoke callbacks outside execute().
//   - Default shortcut collisions are rejected at registration.
//   - Every outcome is a structured result and an "input" EventBus event.
//
// Events (EventBus category "input", source "registry"):
//   { type: "registered" | "unregistered" | "executed" | "rejected", id, ... }

import QtQuick

QtObject {
    id: actionRegistry

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var shellState: null
    property var workspaceModel: null
    property var windowModel: null
    property var navigationController: null

    // Active compositor bridge (live or mock). Provided by the composition root.
    property var bridge: null

    // =========================================================
    // Schema
    // =========================================================
    readonly property var categories: ["navigation", "workspace", "window", "system"]
    readonly property string coreOwner: "core"
    readonly property int maxExecutionDepth: 4

    // Internal storage: { id: { descriptor fields..., callback, isEnabled } } — never exposed.
    property var _actions: ({})
    property var _order: []
    property int _depth: 0
    property int actionCount: 0

    // Last execution outcome (diagnostics).
    property var lastResult: null

    // =========================================================
    // Helpers
    // =========================================================

    function _emit(type, payload) {
        if (!eventBus) return
        var ev = { source: "registry", type: type }
        for (var key in payload) ev[key] = payload[key]
        eventBus.emit("input", ev)
    }

    function _fail(type, id, error, extra) {
        var res = { ok: false, id: String(id === undefined ? "" : id), error: error }
        if (extra) {
            for (var key in extra) res[key] = extra[key]
        }
        if (logger) logger.warn("ActionRegistry",
            "%1 rejected for '%2': %3".arg(type).arg(res.id).arg(error))
        _emit("rejected", { id: res.id, operation: type, error: error })
        return res
    }

    // Canonical shortcut form for conflict comparison: modifiers in fixed order, then key.
    function normalizeShortcut(shortcut) {
        if (typeof shortcut !== "string") return ""
        var parts = shortcut.split("+")
        var mods = []
        var key = ""
        var order = ["super", "ctrl", "alt", "shift"]
        for (var i = 0; i < parts.length; i++) {
            var p = parts[i].trim().toLowerCase()
            if (p.length === 0) continue
            if (order.indexOf(p) >= 0) {
                if (mods.indexOf(p) < 0) mods.push(p)
            } else {
                key = p
            }
        }
        if (key.length === 0) return ""
        mods.sort(function(a, b) { return order.indexOf(a) - order.indexOf(b) })
        return mods.concat([key]).join("+")
    }

    function _isEnabled(entry) {
        var flag = entry.isEnabled
        if (typeof flag === "function") {
            try {
                return Boolean(flag())
            } catch (e) {
                if (logger) logger.error("ActionRegistry",
                    "isEnabled() for '%1' threw: %2".arg(entry.id).arg(e.message || e))
                return false
            }
        }
        return flag !== false
    }

    function _describe(entry) {
        return {
            id: entry.id,
            category: entry.category,
            title: entry.title,
            description: entry.description,
            defaultShortcut: entry.defaultShortcut,
            enabled: _isEnabled(entry),
            owner: entry.owner
        }
    }

    // =========================================================
    // Register / Unregister
    // =========================================================
    // spec: { id, category, title, description, defaultShortcut?, isEnabled?, callback }
    // owner: non-empty string identifying the registering subsystem.
    // Returns { ok: true, id } or { ok: false, id, error }.

    function register(spec, owner) {
        if (!spec || typeof spec !== "object") return _fail("register", "", "invalid-spec")
        var id = spec.id
        if (typeof owner !== "string" || owner.length === 0) return _fail("register", id, "invalid-owner")
        if (typeof id !== "string" || !/^[a-z][a-zA-Z0-9]*(\.[a-zA-Z0-9-]+)+$/.test(id)) {
            return _fail("register", id, "invalid-id")
        }
        if (categories.indexOf(spec.category) < 0) return _fail("register", id, "invalid-category")
        if (typeof spec.title !== "string" || spec.title.trim().length === 0) return _fail("register", id, "invalid-title")
        if (typeof spec.description !== "string") return _fail("register", id, "invalid-description")
        if (typeof spec.callback !== "function") return _fail("register", id, "invalid-callback")

        var shortcut = (spec.defaultShortcut === undefined) ? "" : spec.defaultShortcut
        if (typeof shortcut !== "string") return _fail("register", id, "invalid-shortcut")

        var enabledSpec = (spec.isEnabled === undefined) ? true : spec.isEnabled
        if (typeof enabledSpec !== "boolean" && typeof enabledSpec !== "function") {
            return _fail("register", id, "invalid-enabled")
        }

        if (_actions[id] !== undefined) {
            return _fail("register", id, "duplicate-id", { owner: _actions[id].owner })
        }

        var normalized = normalizeShortcut(shortcut)
        if (shortcut.length > 0 && normalized.length === 0) return _fail("register", id, "invalid-shortcut")
        if (normalized.length > 0) {
            for (var i = 0; i < _order.length; i++) {
                var other = _actions[_order[i]]
                if (other.shortcutKey === normalized) {
                    return _fail("register", id, "shortcut-conflict", { conflictsWith: other.id })
                }
            }
        }

        _actions[id] = {
            id: id,
            category: spec.category,
            title: spec.title,
            description: spec.description,
            defaultShortcut: shortcut,
            shortcutKey: normalized,
            isEnabled: enabledSpec,
            callback: spec.callback,
            owner: owner
        }
        _order.push(id)
        actionCount = _order.length

        if (logger) logger.debug("ActionRegistry", "Registered '%1' (%2, owner=%3)".arg(id).arg(spec.category).arg(owner))
        _emit("registered", { id: id, category: spec.category, owner: owner })
        return { ok: true, id: id }
    }

    // Only the registering owner may remove an action.
    function unregister(id, owner) {
        var entry = _actions[id]
        if (entry === undefined) return _fail("unregister", id, "unknown-action")
        if (entry.owner !== owner) return _fail("unregister", id, "not-owner", { owner: entry.owner })

        delete _actions[id]
        _order.splice(_order.indexOf(id), 1)
        actionCount = _order.length

        if (logger) logger.debug("ActionRegistry", "Unregistered '%1'".arg(id))
        _emit("unregistered", { id: id, owner: owner })
        return { ok: true, id: id }
    }

    // =========================================================
    // Discover
    // =========================================================

    function has(id) {
        return _actions[id] !== undefined
    }

    function get(id) {
        var entry = _actions[id]
        return entry === undefined ? null : _describe(entry)
    }

    // filter: { category?: string, enabledOnly?: bool, query?: string }
    function list(filter) {
        var f = filter || {}
        var query = (typeof f.query === "string") ? f.query.trim().toLowerCase() : ""
        var out = []
        for (var i = 0; i < _order.length; i++) {
            var entry = _actions[_order[i]]
            if (f.category && entry.category !== f.category) continue
            if (query.length > 0) {
                var hay = (entry.id + " " + entry.title + " " + entry.description).toLowerCase()
                if (hay.indexOf(query) < 0) continue
            }
            var desc = _describe(entry)
            if (f.enabledOnly === true && !desc.enabled) continue
            out.push(desc)
        }
        return out
    }

    function search(text) {
        return list({ query: text })
    }

    function getCategories() {
        var out = []
        for (var i = 0; i < categories.length; i++) {
            var cat = categories[i]
            var n = 0
            for (var j = 0; j < _order.length; j++) {
                if (_actions[_order[j]].category === cat) n++
            }
            out.push({ category: cat, count: n })
        }
        return out
    }

    // Default shortcut conflict helpers (DEC-028: conflict handling must be explicit).
    // Returns the IDs of actions whose default shortcut equals the given shortcut.
    function findShortcutOwners(shortcut) {
        var key = normalizeShortcut(shortcut)
        var out = []
        if (key.length === 0) return out
        for (var i = 0; i < _order.length; i++) {
            if (_actions[_order[i]].shortcutKey === key) out.push(_order[i])
        }
        return out
    }

    function getActionForShortcut(shortcut) {
        var owners = findShortcutOwners(shortcut)
        return owners.length > 0 ? get(owners[0]) : null
    }

    // =========================================================
    // Execute
    // =========================================================
    // Returns { ok, id, error?, result? } and records it in lastResult.
    // Callback contract: returning false, or an object with ok === false, is a failure.

    function execute(id, payload) {
        var entry = _actions[id]
        var res
        if (entry === undefined) {
            res = _fail("execute", id, "unknown-action")
            lastResult = res
            return res
        }
        if (!_isEnabled(entry)) {
            res = _fail("execute", id, "disabled")
            lastResult = res
            return res
        }
        if (_depth >= maxExecutionDepth) {
            res = _fail("execute", id, "reentrant-limit")
            lastResult = res
            return res
        }

        var value
        _depth++
        try {
            value = entry.callback(payload)
        } catch (e) {
            _depth--
            res = _fail("execute", id, "callback-error", { message: String(e.message || e) })
            lastResult = res
            return res
        }
        _depth--

        var failed = (value === false) || (value !== null && typeof value === "object" && value.ok === false)
        res = { ok: !failed, id: id }
        if (value !== undefined && typeof value === "object") res.result = value
        if (failed) res.error = (value && value.reason) ? String(value.reason) : "action-failed"

        if (logger) logger.debug("ActionRegistry", "Executed '%1' → ok=%2".arg(id).arg(res.ok))
        _emit("executed", { id: id, ok: res.ok, error: res.error || "", category: entry.category })
        lastResult = res
        return res
    }

    // =========================================================
    // Core actions (M1: navigation, workspace, window)
    // =========================================================
    // Default shortcuts below are descriptors that mirror binds shipped in
    // config/hypr/baseus-desktop.{lua,conf}; no shortcut is claimed that is not bound there.

    function _bridgeCall(name, args) {
        if (!bridge || bridge.connected !== true) return { ok: false, reason: "bridge-unavailable" }
        var ok = bridge[name].apply(bridge, args)
        return ok === false ? { ok: false, reason: "bridge-rejected" } : { ok: true }
    }

    function _targetWindow(payload) {
        var addr = (payload && typeof payload.address === "string") ? payload.address : ""
        return addr.length > 0 ? addr : (windowModel ? windowModel.focusedAddress : "")
    }

    function _registerCore() {
        var self = actionRegistry
        var nav = navigationController

        self.register({
            id: "navigation.back", category: "navigation",
            title: "Back", description: "Return to the previous context: close an overlay, return to the previous workspace, or refocus the previous window.",
            defaultShortcut: "Super+Escape",
            isEnabled: function() { return nav !== null },
            callback: function() { return nav.back() }
        }, coreOwner)

        self.register({
            id: "navigation.home", category: "navigation",
            title: "Home", description: "Return to the desktop on Workspace 1 of the active monitor.",
            defaultShortcut: "Super+D",
            isEnabled: function() { return nav !== null },
            callback: function() { return nav.home() }
        }, coreOwner)

        self.register({
            id: "navigation.overview", category: "navigation",
            title: "Overview", description: "Toggle the Helicopter View of the current desktop context.",
            defaultShortcut: "Super+Tab",
            isEnabled: function() { return nav !== null },
            callback: function() { return nav.overview() }
        }, coreOwner)

        self.register({
            id: "workspace.next", category: "workspace",
            title: "Next workspace", description: "Switch the active monitor to the next workspace (1–10, no wrap).",
            callback: function() {
                return _bridgeCall("nextWorkspace", [shellState.activeMonitorIndex])
            }
        }, coreOwner)

        self.register({
            id: "workspace.previous", category: "workspace",
            title: "Previous workspace", description: "Switch the active monitor to the preceding workspace (1–10, no wrap).",
            callback: function() {
                return _bridgeCall("previousWorkspace", [shellState.activeMonitorIndex])
            }
        }, coreOwner)

        for (var n = 1; n <= 10; n++) {
            (function(ws) {
                self.register({
                    id: "workspace.switch" + ws, category: "workspace",
                    title: "Workspace " + ws, description: "Switch the active monitor to workspace " + ws + ".",
                    defaultShortcut: "Super+" + (ws % 10),
                    callback: function() {
                        return _bridgeCall("switchWorkspace", [ws, shellState.activeMonitorIndex])
                    }
                }, coreOwner)
            })(n)
        }

        function windowAction(id, title, description, method) {
            self.register({
                id: id, category: "window", title: title, description: description,
                isEnabled: function() { return windowModel !== null && windowModel.focusedAddress.length > 0 },
                callback: function(payload) {
                    var addr = _targetWindow(payload)
                    if (addr.length === 0) return { ok: false, reason: "no-target-window" }
                    return _bridgeCall(method, [addr])
                }
            }, coreOwner)
        }

        windowAction("window.close", "Close window", "Close the focused window.", "closeWindow")
        windowAction("window.center", "Center window", "Center the focused window on its monitor.", "centerWindow")
        windowAction("window.toggleFloating", "Toggle floating", "Switch the focused window between floating and tiled.", "toggleFloating")
        windowAction("window.toggleMaximize", "Toggle maximize", "Maximize the focused window within layout margins, or restore it.", "toggleMaximize")
        windowAction("window.toggleFullscreen", "Toggle fullscreen", "Toggle native fullscreen for the focused window.", "toggleFullscreen")
        windowAction("window.minimize", "Minimize window", "Minimize the focused window without a scratchpad.", "minimizeWindow")

        self.register({
            id: "window.restore", category: "window",
            title: "Restore window", description: "Restore the most recently minimized window, centered on the active monitor.",
            isEnabled: function() { return windowModel !== null && windowModel.getMinimizedWindows().length > 0 },
            callback: function(payload) {
                var addr = (payload && typeof payload.address === "string") ? payload.address : ""
                return _bridgeCall("restoreWindow", [addr])
            }
        }, coreOwner)
    }

    // =========================================================
    // Lifecycle
    // =========================================================

    function initialize() {
        _actions = ({})
        _order = []
        _depth = 0
        actionCount = 0
        lastResult = null
        _registerCore()
        if (logger) logger.info("ActionRegistry",
            "Action registry initialized (%1 core actions).".arg(actionCount))
    }

    function teardown() {
        _actions = ({})
        _order = []
        _depth = 0
        actionCount = 0
        lastResult = null
    }
}

