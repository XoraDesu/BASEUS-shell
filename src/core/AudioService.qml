// BASEUS — Audio & System Feedback Service
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §33, DESIGN.md §32–33, and DEC-021:
//   - Central service managing audio volume, mute state, and brightness feedback
//   - PipeWire / WirePlumber integration via Quickshell.Services.Pipewire
//   - Deterministic offline simulation / fallback for WSL2 & headless compositors
//   - Coordinates Top Island OSD feedback triggers
//   - Clean event emission via EventBus category "osd"

pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Pipewire

Item {
    id: audioService

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var config: null

    // =========================================================
    // State
    // =========================================================
    property real volume: 0.72
    property bool muted: false
    property real brightness: 0.60

    readonly property int volumePercent: Math.round(audioService.volume * 100)
    readonly property int brightnessPercent: Math.round(audioService.brightness * 100)

    readonly property bool pipewireAvailable: Pipewire.ready && Pipewire.defaultAudioSink !== null
    readonly property bool isSimulation: audioService.config ? audioService.config.simulationEnabled : false
    readonly property bool available: audioService.pipewireAvailable || audioService.isSimulation
    readonly property bool isAudioActive: !audioService.muted && audioService.volume > 0.0

    // Signals
    signal osdRequested(string type, real value, bool isMuted)
    signal audioChanged(real volume, bool muted)

    // =========================================================
    // Pipewire Synchronization
    // =========================================================
    Connections {
        target: (Pipewire.ready && Pipewire.defaultAudioSink) ? Pipewire.defaultAudioSink.audio : null

        function onVolumesChanged() {
            audioService._syncPipewire()
        }

        function onMutedChanged() {
            audioService._syncPipewire()
        }
    }

    function _syncPipewire(): void {
        var sink = Pipewire.defaultAudioSink
        if (!sink || !sink.audio) return
        var newVol = sink.audio.volume
        var newMuted = sink.audio.muted
        var changed = (newVol !== audioService.volume || newMuted !== audioService.muted)
        audioService.volume = Math.max(0.0, Math.min(1.0, newVol))
        audioService.muted = newMuted
        if (changed) {
            audioService.audioChanged(audioService.volume, audioService.muted)
            audioService.triggerOsd("volume", audioService.volume, audioService.muted)
        }
    }

    // =========================================================
    // Volume Control API
    // =========================================================

    function setVolume(v: real, notify: var): void {
        var doNotify = (typeof notify === "boolean") ? notify : true
        var clamped = Math.max(0.0, Math.min(1.0, v))
        audioService.volume = clamped
        if (clamped > 0.0 && audioService.muted) {
            audioService.muted = false
        }

        if (audioService.pipewireAvailable && Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
            Pipewire.defaultAudioSink.audio.volume = clamped
            if (clamped > 0.0 && Pipewire.defaultAudioSink.audio.muted) {
                Pipewire.defaultAudioSink.audio.muted = false
            }
        }

        audioService.audioChanged(audioService.volume, audioService.muted)
        if (doNotify) {
            audioService.triggerOsd("volume", audioService.volume, audioService.muted)
        }
    }

    function stepVolume(delta: real): void {
        audioService.setVolume(audioService.volume + delta, true)
    }

    function toggleMute(): void {
        audioService.muted = !audioService.muted
        if (audioService.pipewireAvailable && Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
            Pipewire.defaultAudioSink.audio.muted = audioService.muted
        }

        audioService.audioChanged(audioService.volume, audioService.muted)
        audioService.triggerOsd("volume", audioService.volume, audioService.muted)
    }

    // =========================================================
    // Brightness Control API
    // =========================================================

    function setBrightness(b: real, notify: var): void {
        var doNotify = (typeof notify === "boolean") ? notify : true
        var clamped = Math.max(0.0, Math.min(1.0, b))
        audioService.brightness = clamped
        if (doNotify) {
            audioService.triggerOsd("brightness", audioService.brightness, false)
        }
    }

    function stepBrightness(delta: real): void {
        audioService.setBrightness(audioService.brightness + delta, true)
    }

    // =========================================================
    // Unified OSD Trigger
    // =========================================================

    function triggerOsd(type: string, val: real, isMuted: bool): void {
        var t = (type && type.length > 0) ? type : "volume"
        var v = (typeof val === "number") ? Math.max(0.0, Math.min(1.0, val)) : (t === "brightness" ? audioService.brightness : audioService.volume)
        var m = (typeof isMuted === "boolean") ? isMuted : (t === "volume" ? audioService.muted : false)

        if (t === "brightness") {
            audioService.brightness = v
        } else {
            audioService.volume = v
            audioService.muted = m
        }

        audioService.osdRequested(t, v, m)

        if (audioService.eventBus) {
            audioService.eventBus.emit("osd", {
                source: "audio_service",
                type: t,
                value: v,
                percent: Math.round(v * 100),
                isMuted: m
            })
        }

        if (audioService.logger) {
            audioService.logger.debug("AudioService",
                "OSD triggered: %1=%2% (muted=%3)".arg(t).arg(Math.round(v * 100)).arg(m))
        }
    }

    // =========================================================
    // Diagnostic Snapshot
    // =========================================================

    function getSnapshot(): var {
        return {
            available: true,
            volume: audioService.volume,
            volumePercent: audioService.volumePercent,
            muted: audioService.muted,
            brightness: audioService.brightness,
            brightnessPercent: audioService.brightnessPercent,
            pipewireAvailable: audioService.pipewireAvailable,
            isSimulation: audioService.isSimulation
        }
    }
}
