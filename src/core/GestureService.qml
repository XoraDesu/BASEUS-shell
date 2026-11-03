pragma ComponentBehavior: Bound

// BASEUS — Touchpad Gesture Dispatcher & Scaffolding
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §28–29, §34, DESIGN.md §28, DEC-028, and ANTI-SLOP.md:
//   - Dispatches multi-finger touchpad gestures directly to BASEUS actions
//   - 3-finger horizontal swipe: workspace stepping (previous/next)
//   - 4-finger swipe up: open Overview / window spread
//   - 4-finger swipe down: summon App Drawer
//   - Pinch gesture scaffolding: pinch-in (dismiss overview / exit overlay), pinch-out (enter overview)
//   - Threshold gating (minSwipeDelta >= 40px, cooldownLatch ~350ms)
//   - Emits normalized events to EventBus under category "gesture"
//   - Deterministic offline simulation parity under BASEUS_SIMULATION=1
//   - Strictly anti-slop: zero decorative trails, zero neon touch particles

import QtQuick

Item {
    id: gestureService

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var shellState: null
    property var workspaceModel: null
    property var navigationController: null
    property var desktopHost: null
    property var actionRegistry: null
    property var config: null

    // =========================================================
    // Configuration & Thresholds
    // =========================================================
    property bool enabled: true
    property real minSwipeDelta: 40.0
    property int gestureCooldownMs: 350
    property real pinchThreshold: 0.2

    // =========================================================
    // Internal State
    // =========================================================
    property bool _cooldownActive: false
    property var lastGesture: null
    property int gestureCount: 0

    // Cooldown timer to prevent accidental double-triggering or jitter
    Timer {
        id: cooldownTimer
        interval: gestureService.gestureCooldownMs
        repeat: false
        running: false
        onTriggered: {
            gestureService._cooldownActive = false
        }
    }

    // =========================================================
    // Event Emitter
    // =========================================================
    function _emit(type: string, payload: var): void {
        if (!gestureService.eventBus) return

        var evt = {
            source: "gesture_service",
            type: type,
            timestamp: new Date().toISOString()
        }

        if (payload) {
            for (var k in payload) {
                evt[k] = payload[k]
            }
        }

        gestureService.eventBus.emit("gesture", evt)
    }

    // =========================================================
    // Swipe Gesture Processor
    // =========================================================
    function processSwipe(direction: string, fingers: int, distance: var): var {
        if (!gestureService.enabled) {
            return { ok: false, reason: "disabled" }
        }

        var dir = (typeof direction === "string") ? direction.trim().toLowerCase() : ""
        var f = (typeof fingers === "number") ? fingers : 0

        if (typeof distance === "number" && !isNaN(distance)) {
            if (Math.abs(distance) < gestureService.minSwipeDelta) {
                return {
                    ok: false,
                    reason: "below-threshold",
                    distance: distance,
                    threshold: gestureService.minSwipeDelta
                }
            }
        }

        if (gestureService._cooldownActive) {
            return { ok: false, reason: "cooldown-active" }
        }

        var actionId = ""

        if (f === 3) {
            if (dir === "left") {
                actionId = "workspace.next"
            } else if (dir === "right") {
                actionId = "workspace.previous"
            } else {
                return { ok: false, reason: "unmapped-swipe-direction", direction: dir, fingers: f }
            }
        } else if (f === 4) {
            if (dir === "up") {
                actionId = "navigation.overview"
            } else if (dir === "down") {
                actionId = "surface.app_drawer"
            } else if (dir === "left") {
                actionId = "workspace.next"
            } else if (dir === "right") {
                actionId = "workspace.previous"
            } else {
                return { ok: false, reason: "unmapped-swipe-direction", direction: dir, fingers: f }
            }
        } else {
            return { ok: false, reason: "unsupported-finger-count", fingers: f }
        }

        var res = null
        if (gestureService.actionRegistry) {
            res = gestureService.actionRegistry.execute(actionId)
        }

        gestureService._cooldownActive = true
        cooldownTimer.restart()
        gestureService.gestureCount++

        var payload = {
            type: "swipe",
            direction: dir,
            fingers: f,
            action: actionId,
            distance: (typeof distance === "number") ? distance : gestureService.minSwipeDelta,
            result: res,
            timestamp: new Date().toISOString()
        }

        gestureService.lastGesture = payload
        gestureService._emit("swipe", payload)

        if (gestureService.logger) {
            gestureService.logger.debug("GestureService", "Dispatched swipe: " + dir + " (" + f + " fingers) -> " + actionId)
        }

        return {
            ok: true,
            type: "swipe",
            direction: dir,
            fingers: f,
            action: actionId,
            result: res
        }
    }

    // =========================================================
    // Pinch Gesture Processor
    // =========================================================
    function processPinch(type: string, scaleDelta: var): var {
        if (!gestureService.enabled) {
            return { ok: false, reason: "disabled" }
        }

        var t = (typeof type === "string") ? type.trim().toLowerCase() : ""

        if (typeof scaleDelta === "number" && !isNaN(scaleDelta)) {
            if (Math.abs(scaleDelta) < gestureService.pinchThreshold) {
                return {
                    ok: false,
                    reason: "below-threshold",
                    scaleDelta: scaleDelta,
                    threshold: gestureService.pinchThreshold
                }
            }
            if (t === "") {
                t = (scaleDelta < 0) ? "in" : "out"
            }
        }

        if (gestureService._cooldownActive) {
            return { ok: false, reason: "cooldown-active" }
        }

        var actionId = ""
        if (t === "in" || t === "pinch_in") {
            actionId = "navigation.back"
        } else if (t === "out" || t === "pinch_out") {
            actionId = "navigation.overview"
        } else {
            return { ok: false, reason: "unmapped-pinch-type", type: t }
        }

        var res = null
        if (gestureService.actionRegistry) {
            res = gestureService.actionRegistry.execute(actionId)
        }

        gestureService._cooldownActive = true
        cooldownTimer.restart()
        gestureService.gestureCount++

        var payload = {
            type: "pinch",
            pinchType: t,
            action: actionId,
            scaleDelta: (typeof scaleDelta === "number") ? scaleDelta : gestureService.pinchThreshold,
            result: res,
            timestamp: new Date().toISOString()
        }

        gestureService.lastGesture = payload
        gestureService._emit("pinch", payload)

        if (gestureService.logger) {
            gestureService.logger.debug("GestureService", "Dispatched pinch: " + t + " -> " + actionId)
        }

        return {
            ok: true,
            type: "pinch",
            pinchType: t,
            action: actionId,
            result: res
        }
    }

    // =========================================================
    // Mock / Diagnostic Dispatcher
    // =========================================================
    function dispatchMockGesture(direction: string, fingers: int, distance: var): var {
        var d = (typeof direction === "string") ? direction.trim().toLowerCase() : ""
        if (d === "pinch_in" || d === "in") {
            return gestureService.processPinch("in", (typeof distance === "number") ? distance : -0.3)
        }
        if (d === "pinch_out" || d === "out") {
            return gestureService.processPinch("out", (typeof distance === "number") ? distance : 0.3)
        }
        return gestureService.processSwipe(direction, fingers, distance)
    }

    // =========================================================
    // Diagnostics & Snapshot API
    // =========================================================
    function getSnapshot(): var {
        return {
            enabled: gestureService.enabled,
            cooldownActive: gestureService._cooldownActive,
            gestureCooldownMs: gestureService.gestureCooldownMs,
            minSwipeDelta: gestureService.minSwipeDelta,
            pinchThreshold: gestureService.pinchThreshold,
            gestureCount: gestureService.gestureCount,
            lastGesture: gestureService.lastGesture
        }
    }

    function resetCooldown(): void {
        cooldownTimer.stop()
        gestureService._cooldownActive = false
    }

    // =========================================================
    // Lifecycle
    // =========================================================
    function initialize(): void {
        gestureService.resetCooldown()
        gestureService.gestureCount = 0
        gestureService.lastGesture = null
        if (gestureService.logger) {
            gestureService.logger.info("GestureService", "GestureService initialized.")
        }
        gestureService._emit("initialized", {})
    }

    function teardown(): void {
        gestureService.resetCooldown()
        gestureService.gestureCount = 0
        gestureService.lastGesture = null
    }
}

