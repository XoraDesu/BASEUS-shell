// BASEUS — Notification Domain Model
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §30, DESIGN.md §17, §18, DEC-020, and ANTI-SLOP.md §20:
//   - Central domain model managing transient notification state
//   - FreeDesktop DBus NotificationServer integration via Quickshell.Services.Notifications
//   - Fallback diagnostic / programmatic posting API for simulation and shell alerts
//   - Top-left floating placement coordination
//   - Configurable timeout (~3000ms default via Config.qml)
//   - Hover pause mechanic: hovering any notification pauses timeouts for all pending notifications
//   - Hold-to-silence mechanic: long hold silences/clears all notifications
//   - Strict Anti-Slop: zero cardification, zero permanent clutter, bounded active queue

pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Notifications

Item {
    id: notificationModel

    // =========================================================
    // Dependencies
    // =========================================================
    property var logger: null
    property var eventBus: null
    property var config: null

    // =========================================================
    // State
    // =========================================================
    property var notifications: []
    readonly property int count: notificationModel.notifications.length
    property bool paused: false
    property bool silenced: false

    readonly property int defaultTimeout: {
        if (notificationModel.config && typeof notificationModel.config.notificationTimeout === "number" && notificationModel.config.notificationTimeout > 0) {
            return notificationModel.config.notificationTimeout
        }
        return 3000
    }

    readonly property int maxVisible: 3
    property int _nextId: 1
    property var _notificationRefs: ({})

    // =========================================================
    // FreeDesktop DBus Service Integration
    // =========================================================
    NotificationServer {
        id: server
        onNotification: notification => {
            notificationModel.handleIncoming(notification)
        }
    }

    // =========================================================
    // Incoming Notification Ingestion
    // =========================================================
    function handleIncoming(n: var) {
        if (!n) return
        if (notificationModel.silenced) {
            if (typeof n.dismiss === "function") {
                n.dismiss()
            }
            return
        }

        var notifId = notificationModel._nextId++
        notificationModel._notificationRefs[notifId] = n

        var actionsList = []
        if (n.actions) {
            for (var i = 0; i < n.actions.length; i++) {
                var act = n.actions[i]
                if (act) {
                    actionsList.push({
                        id: String(act.id || ""),
                        text: String(act.text || "")
                    })
                }
            }
        }

        var urgencyStr = "normal"
        if (n.urgency === NotificationUrgency.Critical) {
            urgencyStr = "critical"
        } else if (n.urgency === NotificationUrgency.Low) {
            urgencyStr = "low"
        }

        var timeoutVal = (typeof n.expireTimeout === "number" && n.expireTimeout > 0)
            ? n.expireTimeout
            : notificationModel.defaultTimeout

        var item = {
            id: notifId,
            appName: String(n.appName || "Application"),
            appIcon: String(n.appIcon || ""),
            summary: String(n.summary || ""),
            body: String(n.body || ""),
            urgency: urgencyStr,
            actions: actionsList,
            timeout: timeoutVal,
            remaining: timeoutVal,
            timestamp: Date.now()
        }

        notificationModel._enqueue(item)
    }

    // =========================================================
    // Programmatic & Diagnostic Posting API
    // =========================================================
    function postNotification(appName: string, appIcon: string, summary: string, body: string, urgency: string, actions: var, timeoutMs: int): int {
        if (notificationModel.silenced) return -1

        var notifId = notificationModel._nextId++
        var timeoutVal = (typeof timeoutMs === "number" && timeoutMs > 0)
            ? timeoutMs
            : notificationModel.defaultTimeout

        var actionsList = []
        if (actions && Array.isArray(actions)) {
            for (var i = 0; i < actions.length; i++) {
                if (actions[i]) {
                    actionsList.push({
                        id: String(actions[i].id || ""),
                        text: String(actions[i].text || "")
                    })
                }
            }
        }

        var item = {
            id: notifId,
            appName: appName && appName.length > 0 ? appName : "System",
            appIcon: appIcon || "",
            summary: summary || "",
            body: body || "",
            urgency: urgency || "normal",
            actions: actionsList,
            timeout: timeoutVal,
            remaining: timeoutVal,
            timestamp: Date.now()
        }

        notificationModel._enqueue(item)
        return notifId
    }

    function _enqueue(item: var) {
        var next = []
        next.push(item)
        for (var i = 0; i < notificationModel.notifications.length; i++) {
            next.push(notificationModel.notifications[i])
        }
        notificationModel.notifications = next

        if (notificationModel.logger) {
            notificationModel.logger.info("NotificationModel",
                "Notification [%1] from '%2': '%3'"
                .arg(item.id)
                .arg(item.appName)
                .arg(item.summary))
        }

        if (notificationModel.eventBus) {
            notificationModel.eventBus.emit("notification", {
                source: "model",
                type: "added",
                notification: item
            })
        }
    }

    // =========================================================
    // Dismissal & Lifecycle Operations
    // =========================================================
    function dismiss(id: int) {
        var next = []
        var found = false
        for (var i = 0; i < notificationModel.notifications.length; i++) {
            if (notificationModel.notifications[i].id === id) {
                found = true
            } else {
                next.push(notificationModel.notifications[i])
            }
        }

        if (found) {
            notificationModel.notifications = next
            if (notificationModel._notificationRefs[id]) {
                try {
                    notificationModel._notificationRefs[id].dismiss()
                } catch (e) {}
                delete notificationModel._notificationRefs[id]
            }

            if (notificationModel.logger) {
                notificationModel.logger.debug("NotificationModel", "Dismissed notification %1".arg(id))
            }

            if (notificationModel.eventBus) {
                notificationModel.eventBus.emit("notification", {
                    source: "model",
                    type: "dismissed",
                    id: id
                })
            }
        }
    }

    function dismissAll() {
        var list = notificationModel.notifications
        for (var i = 0; i < list.length; i++) {
            var notifId = list[i].id
            if (notificationModel._notificationRefs[notifId]) {
                try {
                    notificationModel._notificationRefs[notifId].dismiss()
                } catch (e) {}
                delete notificationModel._notificationRefs[notifId]
            }
        }
        notificationModel.notifications = []

        if (notificationModel.eventBus) {
            notificationModel.eventBus.emit("notification", {
                source: "model",
                type: "dismissed_all"
            })
        }
    }

    function silenceAll() {
        notificationModel.silenced = true
        notificationModel.dismissAll()

        if (notificationModel.logger) {
            notificationModel.logger.info("NotificationModel", "All notifications silenced.")
        }

        if (notificationModel.eventBus) {
            notificationModel.eventBus.emit("notification", {
                source: "model",
                type: "silenced"
            })
        }
    }

    function resetSilence() {
        notificationModel.silenced = false
    }

    function setPaused(isPaused: bool) {
        notificationModel.paused = isPaused
    }

    function invokeAction(id: int, actionId: string) {
        if (notificationModel._notificationRefs[id]) {
            var ref = notificationModel._notificationRefs[id]
            if (ref.actions) {
                for (var i = 0; i < ref.actions.length; i++) {
                    if (ref.actions[i] && ref.actions[i].id === actionId) {
                        try {
                            ref.actions[i].invoke()
                        } catch (e) {}
                        break
                    }
                }
            }
        }
        notificationModel.dismiss(id)
    }

    // =========================================================
    // Countdown Timer (Hover Pausable)
    // =========================================================
    Timer {
        id: ticker
        interval: 100
        repeat: true
        running: notificationModel.notifications.length > 0 && !notificationModel.paused

        onTriggered: {
            var list = notificationModel.notifications
            var expiredIds = []

            for (var i = 0; i < list.length; i++) {
                list[i].remaining = Math.max(0, list[i].remaining - 100)
                if (list[i].remaining <= 0) {
                    expiredIds.push(list[i].id)
                }
            }

            for (var j = 0; j < expiredIds.length; j++) {
                notificationModel.dismiss(expiredIds[j])
            }
        }
    }

    // =========================================================
    // Introspection / Diagnostic Snapshot
    // =========================================================
    function getSnapshot(): var {
        return {
            count: notificationModel.notifications.length,
            paused: notificationModel.paused,
            silenced: notificationModel.silenced,
            notifications: notificationModel.notifications
        }
    }
}

