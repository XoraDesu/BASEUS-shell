// BASEUS — Desktop Host
// Copyright (c) 2026 xoradesu — MIT License
//
// Multi-monitor Wayland Layer-Shell host scaffolding (M1-T4, DEC-045).
// Anchors foundational desktop overlay surfaces per monitor bounds
// while maintaining zero-cost click-through at idle and per-monitor
// native fullscreen recession (DEC-023, DESIGN.md §14).

pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme" as ThemeModule

Scope {
    id: desktopHost

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var shellState: null
    property var monitorModel: null
    property var theme: null

    // =========================================================
    // Host Configuration
    // =========================================================
    property bool enabled: true
    property int layer: WlrLayer.Top
    property string layerNamespace: "baseus-desktop"

    // =========================================================
    // Surface Tracking
    // =========================================================
    property var _surfaces: []
    readonly property int surfaceCount: _surfaces.length

    function resolveMonitorIndex(screenName: string): int {
        if (desktopHost.monitorModel && desktopHost.monitorModel.monitors) {
            var mons = desktopHost.monitorModel.monitors
            for (var i = 0; i < mons.length; i++) {
                var m = mons[i]
                if (m && m.name === screenName) {
                    return (typeof m.index === "number") ? m.index : i
                }
            }
        }
        return 0
    }

    function getSurfaceSnapshot(): var {
        var snapshot = []
        for (var i = 0; i < desktopHost._surfaces.length; i++) {
            var s = desktopHost._surfaces[i]
            if (!s) continue
            snapshot.push({
                monitorIndex: s.monitorIndex,
                screenName: s.screenName,
                width: s.width,
                height: s.height,
                visible: s.visible,
                isFullscreen: s.isFullscreen,
                layer: desktopHost.layer === WlrLayer.Top ? "top" : "overlay"
            })
        }
        return snapshot
    }

    function _registerSurface(surface: var) {
        if (!surface) return
        var next = []
        for (var i = 0; i < desktopHost._surfaces.length; i++) {
            if (desktopHost._surfaces[i] !== surface) {
                next.push(desktopHost._surfaces[i])
            }
        }
        next.push(surface)
        desktopHost._surfaces = next

        if (desktopHost.logger) {
            desktopHost.logger.info("DesktopHost",
                "Desktop surface registered for monitor %1 (%2) [%3x%4]"
                .arg(surface.monitorIndex)
                .arg(surface.screenName)
                .arg(surface.width)
                .arg(surface.height))
        }

        if (desktopHost.eventBus) {
            desktopHost.eventBus.emit("desktop", {
                source: "host",
                type: "surface_registered",
                monitorIndex: surface.monitorIndex,
                screenName: surface.screenName,
                surfaceCount: desktopHost._surfaces.length
            })
        }
    }

    function _unregisterSurface(surface: var) {
        if (!surface) return
        var next = []
        for (var i = 0; i < desktopHost._surfaces.length; i++) {
            if (desktopHost._surfaces[i] !== surface) {
                next.push(desktopHost._surfaces[i])
            }
        }
        desktopHost._surfaces = next

        if (desktopHost.logger) {
            desktopHost.logger.debug("DesktopHost",
                "Desktop surface unregistered for monitor %1 (%2)"
                .arg(surface.monitorIndex)
                .arg(surface.screenName))
        }

        if (desktopHost.eventBus) {
            desktopHost.eventBus.emit("desktop", {
                source: "host",
                type: "surface_unregistered",
                monitorIndex: surface.monitorIndex,
                screenName: surface.screenName,
                surfaceCount: desktopHost._surfaces.length
            })
        }
    }

    // =========================================================
    // Lifecycle Operations
    // =========================================================

    function initialize() {
        desktopHost.enabled = true
        if (desktopHost.logger) {
            desktopHost.logger.info("DesktopHost", "DesktopHost initialized.")
        }
    }

    function teardown() {
        desktopHost.enabled = false
        desktopHost._surfaces = []
        if (desktopHost.logger) {
            desktopHost.logger.info("DesktopHost", "DesktopHost torn down.")
        }
    }

    // =========================================================
    // Multi-Monitor Layer-Shell Variants
    // =========================================================

    Variants {
        id: variants
        model: desktopHost.enabled ? Quickshell.screens : []

        delegate: Component {
            WlrLayershell {
                id: layerWindow
                required property var modelData

                screen: modelData

                // Anchor to entire screen
                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                color: "transparent"

                layer: desktopHost.layer
                namespace: desktopHost.layerNamespace
                keyboardFocus: WlrKeyboardFocus.None
                exclusiveZone: 0

                // Zero-cost click-through at idle: empty mask passes all input to windows below
                mask: Region {}

                readonly property string screenName: modelData ? modelData.name : ""
                readonly property var _monitorsRef: desktopHost.monitorModel ? desktopHost.monitorModel.monitors : null
                readonly property int monitorIndex: {
                    var dummy = layerWindow._monitorsRef
                    return desktopHost.resolveMonitorIndex(layerWindow.screenName)
                }

                // DEC-023 & DESIGN.md §14: Cleanly recede when native fullscreen is active on this monitor
                readonly property bool isFullscreen: desktopHost.shellState ? desktopHost.shellState.isMonitorFullscreen(layerWindow.monitorIndex) : false
                visible: desktopHost.enabled && !layerWindow.isFullscreen

                // Host container for upcoming M1-T5 surfaces (WorkspaceIndicator & TopIslandAnchor)
                Item {
                    id: desktopContainer
                    anchors.fill: parent
                    // Quiet and transparent at idle per ANTI-SLOP & DEC-029
                }

                Component.onCompleted: {
                    desktopHost._registerSurface(layerWindow)
                }

                Component.onDestruction: {
                    desktopHost._unregisterSurface(layerWindow)
                }
            }
        }
    }
}

