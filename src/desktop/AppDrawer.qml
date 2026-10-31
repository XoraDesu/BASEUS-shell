pragma ComponentBehavior: Bound

// BASEUS — Fullscreen Application Drawer
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §14–17, DESIGN.md §20–23, DEC-018, and DEC-022:
//   - Literally fullscreen surface mapped per-monitor inside DesktopHost.qml
//   - Top corners rounded (radiusLarge = 12px), bottom corners flush with display edge
//   - Smooth curtain reveal from bottom to top driven by Theme.motion tokens
//   - Solid Wabi-sabi palette surface (colors.surfaceSolid + borderSubtle), zero blur, zero glassmorphism
//   - Persistent top search input field, auto-focused upon reveal
//   - Landing state: Recent/Suggested layer (max 3 columns, darker tonal surfaceHighlight)
//   - Search collapse transition: Recent layer collapses upward when typing in search
//   - Main catalog: Single continuous dynamic grid sorted strictly in fixed A–Z–0–9–# order
//   - Strictly NO separate cardified section headers (ANTI-SLOP.md §6.1)
//   - Strictly NO running indicators (DEC-018: running indicators belong exclusively to Dock)
//   - Alphabet Fast Scroller (A–Z–0–9–#): 1px idle rail on right edge, 3px active rail,
//     hierarchical scrubbing ("Focus grows. Context recedes."), grid jumping
//   - Application launch dispatch via bridge and clean dismissal via Escape/Back

import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: appDrawerRoot

    // =========================================================
    // Properties & Dependencies
    // =========================================================
    property Theme theme: null
    readonly property Theme currentTheme: theme !== null ? theme : Theme

    property var bridge: null
    property var config: null
    property int monitorIndex: 0
    property bool active: false

    property real revealProgress: 0.0
    property string searchQuery: ""
    property var customCatalog: null

    property var recentApps: []
    property var catalog: []
    property var filteredCatalog: []

    signal dismissRequested()
    signal appLaunched(var item)

    // =========================================================
    // Catalog Generation & A–Z–0–9–# Sorting (DEC-018, DEC-022)
    // =========================================================
    function _getSectionKey(title: string): string {
        var str = String(title || "").trim()
        if (str.length === 0) return "#"
        var first = str.charAt(0).toUpperCase()
        if (first >= "A" && first <= "Z") return first
        if (first >= "0" && first <= "9") return first
        return "#"
    }

    function _getSectionOrder(secKey: string): int {
        if (secKey >= "A" && secKey <= "Z") return secKey.charCodeAt(0) - 65
        if (secKey >= "0" && secKey <= "9") return 26 + (secKey.charCodeAt(0) - 48)
        return 36
    }

    function _buildDefaultCatalog(): var {
        return [
            { id: "archive", title: "Archive Manager", command: "file-roller", icon: "package-x-generic" },
            { id: "browser", title: "Browser", command: "firefox", icon: "firefox" },
            { id: "calculator", title: "Calculator", command: "gnome-calculator", icon: "accessories-calculator" },
            { id: "calendar", title: "Calendar", command: "gnome-calendar", icon: "office-calendar" },
            { id: "code", title: "Code Editor", command: "code", icon: "text-editor" },
            { id: "document", title: "Document Viewer", command: "evince", icon: "document-viewer" },
            { id: "files", title: "Files", command: "thunar", icon: "system-file-manager" },
            { id: "gallery", title: "Gallery", command: "eog", icon: "image-x-generic" },
            { id: "help", title: "Help", command: "yelp", icon: "help-browser" },
            { id: "image_editor", title: "Image Editor", command: "gimp", icon: "image-x-generic" },
            { id: "logs", title: "Logs", command: "gnome-logs", icon: "utilities-system-monitor" },
            { id: "music", title: "Music", command: "amberol", icon: "audio-x-generic" },
            { id: "notes", title: "Notes", command: "gnome-notes", icon: "text-editor" },
            { id: "office", title: "Office", command: "libreoffice", icon: "x-office-document" },
            { id: "passwords", title: "Passwords", command: "keepassxc", icon: "system-lock-screen" },
            { id: "settings", title: "Settings", command: "baseus-settings", icon: "preferences-system" },
            { id: "software", title: "Software", command: "gnome-software", icon: "system-software-install" },
            { id: "terminal", title: "Terminal", command: "kitty", icon: "utilities-terminal" },
            { id: "utilities", title: "Utilities", command: "gnome-tweaks", icon: "preferences-other" },
            { id: "video", title: "Video Player", command: "celluloid", icon: "video-x-generic" },
            { id: "weather", title: "Weather", command: "gnome-weather", icon: "weather-clear" },
            { id: "zero_ad", title: "0 A.D.", command: "0ad", icon: "applications-games" },
            { id: "one_password", title: "1Password", command: "1password", icon: "system-lock-screen" },
            { id: "seven_zip", title: "7-Zip", command: "7z", icon: "package-x-generic" },
            { id: "script_runner", title: "#! Script Runner", command: "bash", icon: "utilities-terminal" }
        ]
    }

    function _rebuildCatalog() {
        var baseList = []
        if (customCatalog && Array.isArray(customCatalog) && customCatalog.length > 0) {
            baseList = customCatalog.slice()
        } else {
            baseList = _buildDefaultCatalog()
        }

        // Merge pinned apps from config if present
        var pinned = (config && config.dock && config.dock.pinnedApps) ? config.dock.pinnedApps : []
        for (var p = 0; p < pinned.length; p++) {
            var pin = pinned[p]
            var found = false
            for (var b = 0; b < baseList.length; b++) {
                if (baseList[b].id === pin.id || baseList[b].command === pin.command) {
                    found = true
                    break
                }
            }
            if (!found) {
                baseList.push({
                    id: pin.id,
                    title: pin.title || pin.id,
                    command: pin.command,
                    icon: pin.icon || ""
                })
            }
        }

        // Assign section keys and sort in fixed A–Z–0–9–# order
        var enriched = []
        for (var i = 0; i < baseList.length; i++) {
            var item = baseList[i]
            var sec = _getSectionKey(item.title)
            enriched.push({
                id: String(item.id || ""),
                title: String(item.title || item.id || ""),
                command: String(item.command || ""),
                icon: String(item.icon || ""),
                section: sec
            })
        }

        enriched.sort(function(a, b) {
            var ordA = appDrawerRoot._getSectionOrder(a.section)
            var ordB = appDrawerRoot._getSectionOrder(b.section)
            if (ordA !== ordB) return ordA - ordB
            return a.title.localeCompare(b.title)
        })

        catalog = enriched

        // Default recent apps (up to 3 items)
        if (!recentApps || recentApps.length === 0) {
            var recents = []
            for (var r = 0; r < enriched.length && recents.length < 3; r++) {
                var cId = enriched[r].id
                if (cId === "terminal" || cId === "browser" || cId === "files") {
                    recents.push(enriched[r])
                }
            }
            if (recents.length === 0 && enriched.length > 0) {
                recents = enriched.slice(0, Math.min(3, enriched.length))
            }
            recentApps = recents
        }

        _applyFilter()
    }

    function _applyFilter() {
        var query = searchQuery.trim().toLowerCase()
        if (query.length === 0) {
            filteredCatalog = catalog
            return
        }

        var results = []
        for (var i = 0; i < catalog.length; i++) {
            var app = catalog[i]
            if (app.title.toLowerCase().indexOf(query) >= 0 ||
                app.command.toLowerCase().indexOf(query) >= 0 ||
                app.id.toLowerCase().indexOf(query) >= 0) {
                results.push(app)
            }
        }
        filteredCatalog = results
    }

    // =========================================================
    // Alphabet Fast Scroller Jumping (DEC-022)
    // =========================================================
    function scrubTo(letter: string) {
        if (!letter || filteredCatalog.length === 0) return false
        var targetUpper = String(letter).toUpperCase()
        var targetOrder = _getSectionOrder(targetUpper)

        var bestIdx = -1
        for (var i = 0; i < filteredCatalog.length; i++) {
            var itemSec = filteredCatalog[i].section
            var itemOrder = _getSectionOrder(itemSec)
            if (itemOrder >= targetOrder) {
                bestIdx = i
                break
            }
        }

        if (bestIdx >= 0) {
            catalogGrid.positionViewAtIndex(bestIdx, GridView.Beginning)
            return true
        }
        return false
    }

    // =========================================================
    // Launch & Interaction Operations
    // =========================================================
    function launchItem(itemData: var) {
        if (!itemData) return false
        var cmd = String(itemData.command || "").trim()

        // Push to recent apps (avoid duplicates, max 3 items)
        var nextRecents = [itemData]
        for (var i = 0; i < recentApps.length && nextRecents.length < 3; i++) {
            if (recentApps[i].id !== itemData.id) {
                nextRecents.push(recentApps[i])
            }
        }
        recentApps = nextRecents

        if (bridge && typeof bridge.launchApp === "function") {
            bridge.launchApp(cmd)
        }

        appDrawerRoot.appLaunched(itemData)
        appDrawerRoot.dismissRequested()
        return true
    }

    function launchIndex(index: int): bool {
        if (index >= 0 && index < filteredCatalog.length) {
            return launchItem(filteredCatalog[index])
        }
        return false
    }

    function launchId(appId: string): bool {
        var queryId = String(appId || "").trim().toLowerCase()
        for (var i = 0; i < catalog.length; i++) {
            if (catalog[i].id.toLowerCase() === queryId ||
                catalog[i].command.toLowerCase() === queryId) {
                return launchItem(catalog[i])
            }
        }
        return false
    }

    function setSearch(queryText: string) {
        searchQuery = String(queryText || "")
        searchInput.text = searchQuery
        _applyFilter()
    }

    function open() {
        _rebuildCatalog()
        searchQuery = ""
        searchInput.text = ""
        _applyFilter()
        revealAnimation.stop()
        if (currentTheme.motion.reducedMotion) {
            revealProgress = 1.0
        } else {
            revealAnimation.from = revealProgress
            revealAnimation.to = 1.0
            revealAnimation.start()
        }
        searchInput.forceActiveFocus()
    }

    function close() {
        revealAnimation.stop()
        if (currentTheme.motion.reducedMotion) {
            revealProgress = 0.0
        } else {
            revealAnimation.from = revealProgress
            revealAnimation.to = 0.0
            revealAnimation.start()
        }
        searchInput.focus = false
    }

    function getSnapshot(): var {
        return {
            active: appDrawerRoot.active,
            revealProgress: appDrawerRoot.revealProgress,
            searchQuery: appDrawerRoot.searchQuery,
            recentCount: appDrawerRoot.recentApps ? appDrawerRoot.recentApps.length : 0,
            catalogCount: appDrawerRoot.catalog ? appDrawerRoot.catalog.length : 0,
            filteredCount: appDrawerRoot.filteredCatalog ? appDrawerRoot.filteredCatalog.length : 0,
            firstItemTitle: (appDrawerRoot.filteredCatalog && appDrawerRoot.filteredCatalog.length > 0)
                ? appDrawerRoot.filteredCatalog[0].title
                : "",
            recentApps: appDrawerRoot.recentApps
        }
    }

    onActiveChanged: {
        if (active) {
            open()
        } else {
            close()
        }
    }

    Component.onCompleted: {
        _rebuildCatalog()
    }

    // =========================================================
    // Reveal Animation (Bottom-to-Top Curtain, DESIGN.md §20)
    // =========================================================
    NumberAnimation {
        id: revealAnimation
        target: appDrawerRoot
        property: "revealProgress"
        duration: appDrawerRoot.currentTheme.motion.durationSlow
        easing.type: appDrawerRoot.currentTheme.motion.easingFocus
    }

    // =========================================================
    // Fullscreen Surface (Rounded top, flush bottom, DEC-018)
    // =========================================================
    Rectangle {
        id: drawerSurface
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height
        y: Math.round((1.0 - appDrawerRoot.revealProgress) * parent.height)

        color: appDrawerRoot.currentTheme.colors.surfaceSolid
        border.color: appDrawerRoot.currentTheme.colors.borderSubtle
        border.width: 1

        topLeftRadius: appDrawerRoot.currentTheme.geometry.radiusLarge
        topRightRadius: appDrawerRoot.currentTheme.geometry.radiusLarge
        bottomLeftRadius: appDrawerRoot.currentTheme.geometry.radiusFlush
        bottomRightRadius: appDrawerRoot.currentTheme.geometry.radiusFlush

        // =====================================================
        // Top Bar & Persistent Search Input
        // =====================================================
        Item {
            id: topBar
            anchors.top: parent.top
            anchors.topMargin: appDrawerRoot.currentTheme.spacing.xl
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(680, parent.width - (appDrawerRoot.currentTheme.spacing.xl * 2))
            height: 44

            Rectangle {
                id: searchBox
                anchors.left: parent.left
                anchors.right: closeButton.left
                anchors.rightMargin: appDrawerRoot.currentTheme.spacing.md
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: appDrawerRoot.currentTheme.colors.surfaceRecessed
                border.color: searchInput.activeFocus
                    ? appDrawerRoot.currentTheme.colors.borderFocus
                    : appDrawerRoot.currentTheme.colors.borderSubtle
                border.width: 1
                radius: appDrawerRoot.currentTheme.geometry.radiusMedium

                Behavior on border.color {
                    ColorAnimation { duration: appDrawerRoot.currentTheme.motion.durationFast }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: appDrawerRoot.currentTheme.spacing.md
                    anchors.rightMargin: appDrawerRoot.currentTheme.spacing.md
                    spacing: appDrawerRoot.currentTheme.spacing.sm

                    Text {
                        text: ""
                        font.family: appDrawerRoot.currentTheme.typography.fontFamilyMono
                        font.pixelSize: appDrawerRoot.currentTheme.typography.sizeBody
                        color: searchInput.activeFocus
                            ? appDrawerRoot.currentTheme.colors.dominant
                            : appDrawerRoot.currentTheme.colors.textMuted
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: appDrawerRoot.currentTheme.typography.fontFamily
                            font.pixelSize: appDrawerRoot.currentTheme.typography.sizeBody
                            color: appDrawerRoot.currentTheme.colors.textPrimary
                            selectByMouse: true
                            clip: true

                            onTextChanged: {
                                appDrawerRoot.searchQuery = text
                                appDrawerRoot._applyFilter()
                            }

                            Keys.onEscapePressed: function(event) {
                                if (text.length > 0) {
                                    text = ""
                                } else {
                                    appDrawerRoot.dismissRequested()
                                }
                                event.accepted = true
                            }

                            Keys.onReturnPressed: function(event) {
                                if (appDrawerRoot.filteredCatalog.length > 0) {
                                    appDrawerRoot.launchItem(appDrawerRoot.filteredCatalog[0])
                                }
                                event.accepted = true
                            }

                            Keys.onDownPressed: function(event) {
                                catalogGrid.forceActiveFocus()
                                event.accepted = true
                            }
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Type to search applications..."
                            font.family: appDrawerRoot.currentTheme.typography.fontFamily
                            font.pixelSize: appDrawerRoot.currentTheme.typography.sizeBody
                            color: appDrawerRoot.currentTheme.colors.textMuted
                            visible: searchInput.text.length === 0
                        }
                    }

                    // Clear button
                    Item {
                        width: 24
                        height: 24
                        visible: searchInput.text.length > 0

                        Rectangle {
                            anchors.fill: parent
                            radius: appDrawerRoot.currentTheme.geometry.radiusSmall
                            color: clearMouse.containsMouse
                                ? appDrawerRoot.currentTheme.colors.surfaceHighlight
                                : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                font.family: appDrawerRoot.currentTheme.typography.fontFamilyMono
                                font.pixelSize: appDrawerRoot.currentTheme.typography.sizeTitle
                                color: appDrawerRoot.currentTheme.colors.textSecondary
                            }

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = ""
                                    searchInput.forceActiveFocus()
                                }
                            }
                        }
                    }
                }
            }

            // Close trigger button
            Rectangle {
                id: closeButton
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 44
                color: closeMouse.containsMouse
                    ? appDrawerRoot.currentTheme.colors.surfaceHighlight
                    : appDrawerRoot.currentTheme.colors.surfaceRecessed
                border.color: appDrawerRoot.currentTheme.colors.borderSubtle
                border.width: 1
                radius: appDrawerRoot.currentTheme.geometry.radiusMedium

                Text {
                    anchors.centerIn: parent
                    text: "ESC"
                    font.family: appDrawerRoot.currentTheme.typography.fontFamilyMono
                    font.pixelSize: appDrawerRoot.currentTheme.typography.sizeMicro
                    font.weight: Font.DemiBold
                    color: closeMouse.containsMouse
                        ? appDrawerRoot.currentTheme.colors.dominant
                        : appDrawerRoot.currentTheme.colors.textMuted
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: appDrawerRoot.dismissRequested()
                }
            }
        }

        // =====================================================
        // Landing Layer: Recent / Suggested Applications
        // Collapses smoothly upward when search becomes active (MASTER.md §15)
        // =====================================================
        Item {
            id: recentContainer
            anchors.top: topBar.bottom
            anchors.topMargin: appDrawerRoot.searchQuery.trim().length > 0 ? 0 : appDrawerRoot.currentTheme.spacing.md
            anchors.horizontalCenter: parent.horizontalCenter
            width: topBar.width
            clip: true

            readonly property bool isCollapsed: appDrawerRoot.searchQuery.trim().length > 0 ||
                !appDrawerRoot.recentApps || appDrawerRoot.recentApps.length === 0

            height: isCollapsed ? 0 : 106
            opacity: isCollapsed ? 0.0 : 1.0

            Behavior on height {
                NumberAnimation { duration: appDrawerRoot.currentTheme.motion.durationNormal }
            }
            Behavior on opacity {
                NumberAnimation { duration: appDrawerRoot.currentTheme.motion.durationNormal }
            }
            Behavior on anchors.topMargin {
                NumberAnimation { duration: appDrawerRoot.currentTheme.motion.durationNormal }
            }

            Rectangle {
                anchors.fill: parent
                color: appDrawerRoot.currentTheme.colors.surfaceHighlight
                border.color: appDrawerRoot.currentTheme.colors.borderSubtle
                border.width: 1
                radius: appDrawerRoot.currentTheme.geometry.radiusMedium

                Column {
                    anchors.fill: parent
                    anchors.margins: appDrawerRoot.currentTheme.spacing.sm
                    spacing: appDrawerRoot.currentTheme.spacing.xs

                    Text {
                        text: "RECENT / SUGGESTED"
                        font.family: appDrawerRoot.currentTheme.typography.fontFamilyMono
                        font.pixelSize: appDrawerRoot.currentTheme.typography.sizeMicro
                        font.weight: Font.DemiBold
                        color: appDrawerRoot.currentTheme.colors.textMuted
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: appDrawerRoot.currentTheme.spacing.sm

                        Repeater {
                            model: appDrawerRoot.recentApps

                            delegate: AppDrawerItem {
                                required property var modelData
                                width: Math.floor((recentContainer.width - 32) / Math.max(1, Math.min(3, appDrawerRoot.recentApps.length)))
                                height: 72
                                theme: appDrawerRoot.currentTheme
                                itemData: modelData
                                onClicked: appDrawerRoot.launchItem(modelData)
                            }
                        }
                    }
                }
            }
        }

        // =====================================================
        // Main Catalog Grid (Single continuous grid, DEC-018)
        // =====================================================
        Item {
            id: catalogArea
            anchors.top: recentContainer.bottom
            anchors.topMargin: appDrawerRoot.currentTheme.spacing.md
            anchors.bottom: parent.bottom
            anchors.bottomMargin: appDrawerRoot.currentTheme.spacing.md
            anchors.left: parent.left
            anchors.leftMargin: appDrawerRoot.currentTheme.spacing.lg
            anchors.right: fastScroller.left
            anchors.rightMargin: appDrawerRoot.currentTheme.spacing.sm

            GridView {
                id: catalogGrid
                anchors.fill: parent
                clip: true

                readonly property int colCount: Math.max(3, Math.min(6, Math.floor(width / 140)))
                cellWidth: Math.floor(width / colCount)
                cellHeight: 96

                model: appDrawerRoot.filteredCatalog

                delegate: AppDrawerItem {
                    id: gridDelegate
                    required property var modelData
                    required property int index

                    width: catalogGrid.cellWidth
                    height: catalogGrid.cellHeight
                    theme: appDrawerRoot.currentTheme
                    itemData: modelData

                    onClicked: appDrawerRoot.launchItem(modelData)
                }

                // Keyboard grid navigation
                Keys.onEscapePressed: function(event) {
                    searchInput.forceActiveFocus()
                    event.accepted = true
                }

                Keys.onReturnPressed: function(event) {
                    if (currentIndex >= 0 && currentIndex < appDrawerRoot.filteredCatalog.length) {
                        appDrawerRoot.launchItem(appDrawerRoot.filteredCatalog[currentIndex])
                    }
                    event.accepted = true
                }
            }

            // Empty state notice
            Item {
                anchors.centerIn: parent
                width: parent.width - 48
                height: 100
                visible: appDrawerRoot.filteredCatalog.length === 0

                Column {
                    anchors.centerIn: parent
                    spacing: appDrawerRoot.currentTheme.spacing.sm

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No applications found"
                        font.family: appDrawerRoot.currentTheme.typography.fontFamily
                        font.pixelSize: appDrawerRoot.currentTheme.typography.sizeHeadline
                        color: appDrawerRoot.currentTheme.colors.textPrimary
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No matches for '" + appDrawerRoot.searchQuery + "'"
                        font.family: appDrawerRoot.currentTheme.typography.fontFamily
                        font.pixelSize: appDrawerRoot.currentTheme.typography.sizeBody
                        color: appDrawerRoot.currentTheme.colors.textMuted
                    }
                }
            }

            // Scrubbing dimming overlay (MASTER.md §16: interface dims slightly during fast scroll)
            Rectangle {
                anchors.fill: parent
                color: appDrawerRoot.currentTheme.colors.surfaceSolid
                opacity: fastScroller.scrollerActive ? 0.35 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: appDrawerRoot.currentTheme.motion.durationFast }
                }
            }
        }

        // =====================================================
        // Alphabet Fast Scroller (A–Z–0–9–#, DEC-022)
        // =========================================================
        AlphabetScroller {
            id: fastScroller
            anchors.right: parent.right
            anchors.rightMargin: 1
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: appDrawerRoot.currentTheme.spacing.xl
            anchors.bottomMargin: appDrawerRoot.currentTheme.spacing.lg
            theme: appDrawerRoot.currentTheme

            onLetterSelected: function(letter) {
                appDrawerRoot.scrubTo(letter)
            }
        }
    }
}
