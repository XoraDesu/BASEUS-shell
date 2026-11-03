pragma ComponentBehavior: Bound

// BASEUS — Editorial Typographic Contextual Cue (M6-03)
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §31, DESIGN.md §26, and ANTI-SLOP.md §37:
//   - Editorial typographic telemetry for subtle system status:
//       * Hyprland active submap
//       * Low battery warning
//       * Volume / mute peak alerts
//       * Manual system cue invocations
//   - Monospaced JetBrains Mono typography with bold editorial tracking.
//   - Crisp slide-and-fade and text-swap transitions (duration <= 120ms). No lingering text.
//   - Auto-decay timer returning to quiet empty state after inactivity timeout.
//   - Fully non-interactive hitmask discipline (enabled: false, acceptedDevices: PointerDevice.None).

import QtQuick
import "../../src/theme" as ThemeModule
import "../../src/core" as CoreModule

Item {
    id: contextualCueRoot

    // =========================================================
    // Dependencies & Configuration
    // =========================================================
    property ThemeModule.Theme theme
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: contextualCueRoot.theme ? contextualCueRoot.theme : contextualCueRoot.defaultTheme

    property CoreModule.Config config
    property CoreModule.HyprlandBridge hyprlandBridge
    property CoreModule.StatusService statusService
    property CoreModule.AudioService audioService

    // =========================================================
    // Cue State & Telemetry Properties
    // =========================================================
    property string cueText: ""
    property string cueCategory: "normal" // "normal", "warning", "accent"

    readonly property bool hasActiveCue: contextualCueRoot.cueText.length > 0

    readonly property int timeoutMs: (contextualCueRoot.config && contextualCueRoot.config.personality && contextualCueRoot.config.personality.contextualCue)
        ? contextualCueRoot.config.personality.contextualCue.timeout
        : 2200

    readonly property int maxChars: (contextualCueRoot.config && contextualCueRoot.config.personality && contextualCueRoot.config.personality.contextualCue)
        ? contextualCueRoot.config.personality.contextualCue.maxCharacters
        : 32

    // Non-interactive pass-through input mask
    enabled: false
    TapHandler {
        acceptedDevices: PointerDevice.None
    }

    implicitWidth: contextualCueRoot.hasActiveCue ? (cuePill.width + 4) : 0
    implicitHeight: contextualCueRoot.hasActiveCue ? 18 : 0
    clip: true

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 110
            easing.type: Easing.OutCubic
        }
    }

    // =========================================================
    // Auto-Decay Inactivity Timer
    // Zero CPU consumption once decayed to empty state
    // =========================================================
    Timer {
        id: decayTimer
        interval: contextualCueRoot.timeoutMs
        repeat: false
        running: false
        onTriggered: {
            contextualCueRoot.cueText = ""
            contextualCueRoot.cueCategory = "normal"
        }
    }

    // =========================================================
    // IPC Listeners (Hyprland Submap, Battery, Audio)
    // =========================================================
    Connections {
        target: contextualCueRoot.hyprlandBridge ? contextualCueRoot.hyprlandBridge : null

        function onActiveSubmapChanged() {
            var sub = String(contextualCueRoot.hyprlandBridge.activeSubmap || "").trim()
            if (sub.length > 0) {
                contextualCueRoot.showCue("SUBMAP: " + sub, "accent")
            } else {
                decayTimer.restart()
            }
        }
    }

    Connections {
        target: contextualCueRoot.statusService ? contextualCueRoot.statusService : null

        function onIsLowBatteryChanged() {
            var s = contextualCueRoot.statusService
            if (s && s.isLowBattery) {
                let pct = Math.round(s.batteryPercent)
                contextualCueRoot.showCue("BATT: " + pct + "% LOW", "warning")
            }
        }
    }

    Connections {
        target: contextualCueRoot.audioService ? contextualCueRoot.audioService : null

        function onAudioChanged() {
            if (contextualCueRoot.audioService.muted) {
                contextualCueRoot.showCue("AUDIO: MUTED", "warning")
            }
        }
    }

    // =========================================================
    // Public Trigger API
    // =========================================================
    function showCue(text: string, category: string): void {
        if (!text || text.length === 0) {
            contextualCueRoot.cueText = ""
            contextualCueRoot.cueCategory = "normal"
            decayTimer.stop()
            return
        }
        var clean = text.substring(0, contextualCueRoot.maxChars).toUpperCase()
        contextualCueRoot.cueText = clean
        contextualCueRoot.cueCategory = (category && category.length > 0) ? category : "normal"
        decayTimer.restart()
    }

    function clearCue(): void {
        contextualCueRoot.cueText = ""
        contextualCueRoot.cueCategory = "normal"
        decayTimer.stop()
    }

    onVisibleChanged: {
        if (!contextualCueRoot.visible) {
            decayTimer.stop()
        }
    }

    Component.onDestruction: {
        decayTimer.stop()
    }

    // =========================================================
    // Editorial Typographic Presentation (Slide-and-Fade)
    // =========================================================
    Rectangle {
        id: cuePill
        anchors.verticalCenter: parent.verticalCenter
        height: 18
        width: cueLabel.implicitWidth + 12
        radius: 2
        color: contextualCueRoot.currentTheme.palette.surfaceVariant
        border.width: 1
        border.color: (contextualCueRoot.cueCategory === "warning")
            ? contextualCueRoot.currentTheme.colors.statusWarning
            : ((contextualCueRoot.cueCategory === "accent") ? contextualCueRoot.currentTheme.palette.primary : contextualCueRoot.currentTheme.palette.outline)

        opacity: contextualCueRoot.hasActiveCue ? 1.0 : 0.0
        y: contextualCueRoot.hasActiveCue ? 0.0 : -3.0

        Behavior on opacity {
            NumberAnimation {
                duration: 110
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: 110
                easing.type: Easing.OutCubic
            }
        }

        Text {
            id: cueLabel
            anchors.centerIn: parent
            text: contextualCueRoot.cueText
            font.family: contextualCueRoot.currentTheme.typography.fontFamilyMono
            font.pixelSize: contextualCueRoot.currentTheme.typography.sizeMicro
            font.weight: Font.Bold
            font.letterSpacing: 1.5
            color: (contextualCueRoot.cueCategory === "warning")
                ? contextualCueRoot.currentTheme.colors.statusWarning
                : ((contextualCueRoot.cueCategory === "accent") ? contextualCueRoot.currentTheme.palette.primary : contextualCueRoot.currentTheme.palette.onSurfaceVariant)
        }
    }

    // =========================================================
    // Diagnostic State
    // =========================================================
    function getDiagnosticSnapshot(): string {
        return "ContextualCue: text='" + contextualCueRoot.cueText +
               "' | cat=" + contextualCueRoot.cueCategory +
               " | active=" + contextualCueRoot.hasActiveCue +
               " | decay=" + decayTimer.running
    }
}

