pragma ComponentBehavior: Bound

// BASEUS — Design System Theme Root
// Copyright (c) 2026 xoradesu — MIT License
//
// The composition root for all BASEUS design tokens:
//   - Theme.colors
//   - Theme.typography
//   - Theme.spacing
//   - Theme.geometry
//   - Theme.motion
//
// Subscribes to the EventBus to apply live palette updates (Matugen pipeline)
// without interrupting shell lifecycle or behavior.

import QtQuick

QtObject {
    id: themeRoot

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null

    // =========================================================
    // Token Subsystems
    // =========================================================
    readonly property Colors colors: Colors { id: _colors }
    readonly property Typography typography: Typography { id: _typography }
    readonly property Spacing spacing: Spacing { id: _spacing }
    readonly property Geometry geometry: Geometry { id: _geometry }
    readonly property Motion motion: Motion { id: _motion }

    // =========================================================
    // Event Subscriptions
    // =========================================================

    function initialize() {
        if (eventBus) {
            eventBus.unsubscribeAll("Theme")
            eventBus.subscribe("Theme", "theme", function(eventData) {
                if (eventData && eventData.type === "palette_updated" && eventData.palette) {
                    if (logger) logger.info("Theme", "Applying new dynamic palette...")
                    _colors.applyPalette(eventData.palette)
                }
            })
            if (logger) logger.debug("Theme", "Subscribed to theme events.")
        }
    }

    function teardown() {
        if (eventBus) {
            eventBus.unsubscribeAll("Theme")
        }
    }
}
