pragma ComponentBehavior: Bound

// BASEUS — Logger / Diagnostics
// Copyright (c) 2026 xoradesu — MIT License
//
// Structured logging for BASEUS shell diagnostics.
// Per TASKS.md §14:
//   - Useful log levels
//   - Enough context for lifecycle/state/event failures
//   - No noisy logging during normal idle
//   - Startup failure diagnosable
//   - Sensitive values not logged
//
// Log levels: DEBUG < INFO < WARN < ERROR
//
// Convention:
//   logger.info("Subsystem", "Message with %1 args".arg(value))

import QtQuick

QtObject {
    id: loggerRoot

    // =========================================================
    // Configuration
    // =========================================================

    // Minimum log level to output
    // Values: "debug", "info", "warn", "error"
    property string level: "info"

    // Whether to include timestamps
    property bool showTimestamp: true

    // =========================================================
    // Level Priorities
    // =========================================================

    readonly property var _levels: ({
        "debug": 0,
        "info": 1,
        "warn": 2,
        "error": 3
    })

    function _shouldLog(msgLevel) {
        var threshold = _levels[level] || 1
        var priority = _levels[msgLevel] || 0
        return priority >= threshold
    }

    // =========================================================
    // Formatting
    // =========================================================

    function _format(msgLevel, subsystem, message) {
        var parts = []

        if (showTimestamp) {
            parts.push(new Date().toISOString())
        }

        parts.push("[" + msgLevel.toUpperCase() + "]")
        parts.push("[" + subsystem + "]")
        parts.push(message)

        return parts.join(" ")
    }

    // =========================================================
    // Log Methods
    // =========================================================

    function debug(subsystem, message) {
        if (_shouldLog("debug")) {
            console.log(_format("debug", subsystem, message))
        }
    }

    function info(subsystem, message) {
        if (_shouldLog("info")) {
            console.info(_format("info", subsystem, message))
        }
    }

    function warn(subsystem, message) {
        if (_shouldLog("warn")) {
            console.warn(_format("warn", subsystem, message))
        }
    }

    function error(subsystem, message) {
        if (_shouldLog("error")) {
            console.error(_format("error", subsystem, message))
        }
    }

    // =========================================================
    // Startup Banner
    // =========================================================

    function logBanner() {
        info("Logger", "BASEUS diagnostics active (level=%1)".arg(level))
    }
}
