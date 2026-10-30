// BASEUS — Core Event Bus
// Copyright (c) 2026 xoradesu — MIT License
//
// Provides decoupled event communication between shell subsystems.
// Surfaces and services subscribe to events by category rather than
// directly coupling to low-level event sources.
//
// Event categories (architectural, per TASKS.md §11):
//   - lifecycle: shell start, stop, restart
//   - monitor: monitor added, removed, changed
//   - workspace: workspace switched, renamed
//   - window: window created, destroyed, moved, focused, fullscreen
//   - input: action triggered, shortcut pressed
//   - system: volume, brightness, network
//   - media: track change, play/pause, session switch
//   - theme: palette changed, wallpaper changed
//   - config: configuration reloaded
//
// Design principles:
//   - Explicit subscription/unsubscription
//   - No duplicate subscriptions (keyed by subscriber ID)
//   - Diagnosable event failures
//   - No hidden side effects

import QtQuick

QtObject {
    id: eventBus

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null

    // =========================================================
    // Internal subscription registry
    // =========================================================
    // Structure: { category: { subscriberId: callback } }
    property var _subscriptions: ({})

    // =========================================================
    // Subscribe
    // =========================================================
    // subscriberId: unique string identifying the subscriber
    // category: event category string
    // callback: function(eventData) to invoke
    //
    // Returns true if subscribed, false if duplicate

    function subscribe(subscriberId, category, callback) {
        if (!category || !subscriberId || !callback) {
            if (logger) logger.error("EventBus",
                "subscribe() called with invalid arguments: subscriber='%1', category='%2'"
                    .arg(subscriberId).arg(category))
            return false
        }

        // Initialize category bucket if needed
        if (!_subscriptions[category]) {
            _subscriptions[category] = {}
        }

        // Prevent duplicate subscriptions
        if (_subscriptions[category][subscriberId]) {
            if (logger) logger.warn("EventBus",
                "Duplicate subscription rejected: '%1' already subscribed to '%2'"
                    .arg(subscriberId).arg(category))
            return false
        }

        _subscriptions[category][subscriberId] = callback
        if (logger) logger.debug("EventBus",
            "Subscribed: '%1' → '%2'".arg(subscriberId).arg(category))
        return true
    }

    // =========================================================
    // Unsubscribe
    // =========================================================

    function unsubscribe(subscriberId, category) {
        if (!_subscriptions[category] || !_subscriptions[category][subscriberId]) {
            if (logger) logger.warn("EventBus",
                "Unsubscribe: '%1' not found in '%2'"
                    .arg(subscriberId).arg(category))
            return false
        }

        delete _subscriptions[category][subscriberId]
        if (logger) logger.debug("EventBus",
            "Unsubscribed: '%1' from '%2'".arg(subscriberId).arg(category))
        return true
    }

    // =========================================================
    // Unsubscribe All (for a specific subscriber)
    // =========================================================
    // Used during teardown to prevent stale subscriptions on restart

    function unsubscribeAll(subscriberId) {
        var count = 0
        for (var category in _subscriptions) {
            if (_subscriptions[category][subscriberId]) {
                delete _subscriptions[category][subscriberId]
                count++
            }
        }
        if (logger) logger.debug("EventBus",
            "Unsubscribed '%1' from %2 categories".arg(subscriberId).arg(count))
        return count
    }

    // =========================================================
    // Emit
    // =========================================================
    // category: event category string
    // eventData: object containing event payload

    function emit(category, eventData) {
        if (!_subscriptions[category]) {
            return // No subscribers — silent, not an error
        }

        var subscribers = _subscriptions[category]
        for (var subscriberId in subscribers) {
            try {
                subscribers[subscriberId](eventData || {})
            } catch (e) {
                if (logger) logger.error("EventBus",
                    "Handler error in '%1' subscriber '%2': %3"
                        .arg(category).arg(subscriberId).arg(e.message || e))
                // Continue delivering to other subscribers — one failure
                // should not block others
            }
        }
    }

    // =========================================================
    // Diagnostics
    // =========================================================

    function getSubscriptionCount(category) {
        if (!_subscriptions[category]) return 0
        return Object.keys(_subscriptions[category]).length
    }

    function getCategories() {
        return Object.keys(_subscriptions)
    }

    // =========================================================
    // Reset (for testing and restart)
    // =========================================================

    function reset() {
        _subscriptions = {}
        if (logger) logger.info("EventBus", "All subscriptions cleared.")
    }
}
