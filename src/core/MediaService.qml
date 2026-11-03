// BASEUS — Media Service & MPRIS Bridge
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §31, DESIGN.md §31–33, DEC-026, and DEC-039:
//   - MPRIS session tracking via Quickshell.Services.Mpris
//   - Multi-session playback management
//   - Deterministic mock player playlist for simulation and headless environments
//   - Strict enforcement of DEC-039: track changes MUST NOT generate desktop notifications
//   - Standard control API: play, pause, togglePlay, next, previous, seek
//   - EventBus category "media" emission

pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Mpris

Item {
    id: mediaService

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var config: null

    // =========================================================
    // State
    // =========================================================
    property bool hasPlayer: false
    property string playbackStatus: "Paused" // "Playing", "Paused", "Stopped"
    readonly property bool isPlaying: mediaService.playbackStatus === "Playing"

    property string trackTitle: "Midnight City"
    property string trackArtist: "M83"
    property string trackAlbum: "Hurry Up, We're Dreaming"
    property string trackArtUrl: ""
    property real trackLength: 244.0 // seconds
    property real trackPosition: 42.0 // seconds
    readonly property real trackProgress: mediaService.trackLength > 0.0
        ? Math.max(0.0, Math.min(1.0, mediaService.trackPosition / mediaService.trackLength))
        : 0.0

    property string activePlayerIdentity: "mock-player"
    property var playerList: []
    property int activePlayerIndex: 0

    readonly property bool isSimulation: mediaService.config ? mediaService.config.simulationEnabled : false
    readonly property var _mpris: Mpris
    readonly property bool hasLivePlayers: (_mpris && _mpris.players && _mpris.players.values) ? (_mpris.players.values.length > 0) : false

    // Signals
    signal playbackChanged(string status)
    signal trackChanged(string title, string artist, string album)
    signal seekChanged(real position)

    // =========================================================
    // Deterministic Mock Playlist (Simulation & WSL2 Fallback)
    // =========================================================
    readonly property var mockPlaylist: [
        {
            title: "Midnight City",
            artist: "M83",
            album: "Hurry Up, We're Dreaming",
            artUrl: "",
            length: 244.0
        },
        {
            title: "Resonance",
            artist: "HOME",
            album: "Odyssey",
            artUrl: "",
            length: 212.0
        },
        {
            title: "Dayvan Cowboy",
            artist: "Boards of Canada",
            album: "The Campfire Headphase",
            artUrl: "",
            length: 300.0
        }
    ]
    property int _mockIndex: 0

    // Position progress tick in mock mode
    Timer {
        id: mockPositionTimer
        interval: 1000
        repeat: true
        running: !mediaService.hasLivePlayers && mediaService.isPlaying
        onTriggered: {
            if (mediaService.trackPosition < mediaService.trackLength) {
                mediaService.trackPosition += 1.0
                mediaService.seekChanged(mediaService.trackPosition)
            } else {
                mediaService.next()
            }
        }
    }

    // =========================================================
    // Live MPRIS Synchronization
    // =========================================================
    Connections {
        target: (mediaService._mpris && mediaService._mpris.players) ? mediaService._mpris.players : null

        function onValuesChanged() {
            mediaService._syncLivePlayers()
        }
    }

    function _syncLivePlayers(): void {
        if (!mediaService.hasLivePlayers || mediaService.isSimulation) {
            mediaService.hasPlayer = true
            mediaService.activePlayerIdentity = "mock-player"
            mediaService.playerList = ["mock-player"]
            return
        }

        var players = mediaService._mpris.players.values
        var names = []
        for (var i = 0; i < players.length; i++) {
            var p = players[i]
            if (p) {
                names.push(String(p.identity || ("player-" + i)))
            }
        }
        mediaService.playerList = names
        mediaService.hasPlayer = players.length > 0

        var idx = Math.min(mediaService.activePlayerIndex, players.length - 1)
        if (idx < 0) idx = 0
        var activeP = players[idx]
        if (activeP) {
            mediaService.activePlayerIdentity = String(activeP.identity || "mpris-player")
            mediaService.playbackStatus = String(activeP.playbackState || "Paused")
            mediaService.trackTitle = String(activeP.trackTitle || "Unknown Title")
            mediaService.trackArtist = String(activeP.trackArtist || "Unknown Artist")
            mediaService.trackAlbum = String(activeP.trackAlbum || "")
            mediaService.trackArtUrl = String(activeP.trackArtUrl || "")
            mediaService.trackLength = Number(activeP.length || 0.0)
            mediaService.trackPosition = Number(activeP.position || 0.0)
        }
    }

    // =========================================================
    // Control Operations
    // =========================================================

    function play(): void {
        mediaService.playbackStatus = "Playing"

        if (mediaService.hasLivePlayers && !mediaService.isSimulation) {
            var players = mediaService._mpris.players.values
            if (players.length > mediaService.activePlayerIndex && players[mediaService.activePlayerIndex]) {
                players[mediaService.activePlayerIndex].play()
            }
        }

        mediaService.playbackChanged(mediaService.playbackStatus)
        mediaService._emitMediaEvent("playback_changed")
    }

    function pause(): void {
        mediaService.playbackStatus = "Paused"

        if (mediaService.hasLivePlayers && !mediaService.isSimulation) {
            var players = mediaService._mpris.players.values
            if (players.length > mediaService.activePlayerIndex && players[mediaService.activePlayerIndex]) {
                players[mediaService.activePlayerIndex].pause()
            }
        }

        mediaService.playbackChanged(mediaService.playbackStatus)
        mediaService._emitMediaEvent("playback_changed")
    }

    function togglePlay(): void {
        if (mediaService.isPlaying) {
            mediaService.pause()
        } else {
            mediaService.play()
        }
    }

    function next(): void {
        if (mediaService.hasLivePlayers && !mediaService.isSimulation) {
            var players = mediaService._mpris.players.values
            if (players.length > mediaService.activePlayerIndex && players[mediaService.activePlayerIndex]) {
                players[mediaService.activePlayerIndex].next()
            }
        } else {
            // Advance mock playlist
            var nextIdx = (mediaService._mockIndex + 1) % mediaService.mockPlaylist.length
            mediaService._setMockTrack(nextIdx)
        }

        // Enforce DEC-039: track changes MUST NOT generate desktop notifications
        mediaService.trackChanged(mediaService.trackTitle, mediaService.trackArtist, mediaService.trackAlbum)
        mediaService._emitMediaEvent("track_changed")
    }

    function previous(): void {
        if (mediaService.hasLivePlayers && !mediaService.isSimulation) {
            var players = mediaService._mpris.players.values
            if (players.length > mediaService.activePlayerIndex && players[mediaService.activePlayerIndex]) {
                players[mediaService.activePlayerIndex].previous()
            }
        } else {
            // Previous mock playlist
            var prevIdx = (mediaService._mockIndex - 1 + mediaService.mockPlaylist.length) % mediaService.mockPlaylist.length
            mediaService._setMockTrack(prevIdx)
        }

        // Enforce DEC-039: track changes MUST NOT generate desktop notifications
        mediaService.trackChanged(mediaService.trackTitle, mediaService.trackArtist, mediaService.trackAlbum)
        mediaService._emitMediaEvent("track_changed")
    }

    function seek(pos: real): void {
        var clamped = Math.max(0.0, Math.min(mediaService.trackLength, pos))
        mediaService.trackPosition = clamped

        if (mediaService.hasLivePlayers && !mediaService.isSimulation) {
            var players = mediaService._mpris.players.values
            if (players.length > mediaService.activePlayerIndex && players[mediaService.activePlayerIndex]) {
                if (typeof players[mediaService.activePlayerIndex].setPosition === "function") {
                    players[mediaService.activePlayerIndex].setPosition(clamped)
                }
            }
        }

        mediaService.seekChanged(clamped)
        mediaService._emitMediaEvent("seek")
    }

    function selectPlayer(index: int): void {
        if (typeof index === "number" && index >= 0) {
            mediaService.activePlayerIndex = index
            mediaService._syncLivePlayers()
        }
    }

    function _setMockTrack(idx: int): void {
        mediaService._mockIndex = idx
        var t = mediaService.mockPlaylist[idx]
        if (t) {
            mediaService.trackTitle = t.title
            mediaService.trackArtist = t.artist
            mediaService.trackAlbum = t.album
            mediaService.trackArtUrl = t.artUrl
            mediaService.trackLength = t.length
            mediaService.trackPosition = 0.0
        }
    }

    function _emitMediaEvent(type: string): void {
        if (mediaService.eventBus) {
            mediaService.eventBus.emit("media", {
                source: "media_service",
                type: type,
                status: mediaService.playbackStatus,
                isPlaying: mediaService.isPlaying,
                title: mediaService.trackTitle,
                artist: mediaService.trackArtist,
                album: mediaService.trackAlbum,
                artUrl: mediaService.trackArtUrl,
                length: mediaService.trackLength,
                position: mediaService.trackPosition,
                progress: mediaService.trackProgress,
                player: mediaService.activePlayerIdentity
            })
        }

        if (mediaService.logger) {
            mediaService.logger.debug("MediaService",
                "Media event '%1': %2 — %3 (%4)"
                .arg(type)
                .arg(mediaService.trackArtist)
                .arg(mediaService.trackTitle)
                .arg(mediaService.playbackStatus))
        }
    }

    // =========================================================
    // Diagnostic Snapshot
    // =========================================================

    function getSnapshot(): var {
        return {
            available: true,
            hasPlayer: mediaService.hasPlayer,
            playbackStatus: mediaService.playbackStatus,
            isPlaying: mediaService.isPlaying,
            title: mediaService.trackTitle,
            artist: mediaService.trackArtist,
            album: mediaService.trackAlbum,
            artUrl: mediaService.trackArtUrl,
            length: mediaService.trackLength,
            position: mediaService.trackPosition,
            progress: mediaService.trackProgress,
            player: mediaService.activePlayerIdentity,
            players: mediaService.playerList,
            isSimulation: mediaService.isSimulation
        }
    }

    Component.onCompleted: {
        mediaService._setMockTrack(0)
        mediaService.hasPlayer = true
        mediaService.activePlayerIdentity = "mock-player"
        mediaService.playerList = ["mock-player"]
    }
}

