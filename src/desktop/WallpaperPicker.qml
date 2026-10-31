pragma ComponentBehavior: Bound

// BASEUS — Wallpaper Picker Floating Surface
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §27, DESIGN.md §27–29, and ANTI-SLOP.md:
//   - Transient centered floating surface mapped on WlrLayer.Overlay
//   - Solid Wabi-sabi body (Theme.colors.surfaceSolid + 1px borderSubtle)
//   - Zero blur, zero glassmorphism, zero drop shadows
//   - Categorization tabs: Library, Recent, Favorites
//   - Live preview, apply to active workspace (1..10), apply to all workspaces
//   - Strictly NO wallpaper slideshows or automatic interval rotations (MASTER.md §27)
//   - Layer-shell input region contracting to 0x0 at idle

import QtQuick
import "../theme" as ThemeModule

Item {
    id: pickerRoot

    // =========================================================
    // Dependencies & Configuration
    // =========================================================
    property var theme: null
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: pickerRoot.theme ? pickerRoot.theme : pickerRoot.defaultTheme

    property var wallpaperService: null
    property var paletteService: null
    property var workspaceModel: null
    property int monitorIndex: 0

    // =========================================================
    // State Properties
    // =========================================================
    property bool active: false
    property string currentTab: "library" // "library" | "recent" | "favorites"
    property int selectedIndex: 0

    // Built-in Wallpaper Catalog
    property var catalog: [
        {
            "id": "wp_default",
            "title": "Default Slate",
            "path": "/usr/share/backgrounds/baseus/default.png",
            "previewColor": "#1a1b26",
            "isLive": false,
            "isFavorite": true
        },
        {
            "id": "wp_indigo",
            "title": "Indigo Mist",
            "path": "/usr/share/backgrounds/baseus/indigo_mist.png",
            "previewColor": "#24283b",
            "isLive": false,
            "isFavorite": false
        },
        {
            "id": "wp_tokyo",
            "title": "Tokyo Slate",
            "path": "/usr/share/backgrounds/baseus/tokyo_neon.png",
            "previewColor": "#1f2335",
            "isLive": false,
            "isFavorite": true
        },
        {
            "id": "wp_desert",
            "title": "Desert Horizon",
            "path": "/usr/share/backgrounds/baseus/desert_horizon.png",
            "previewColor": "#292524",
            "isLive": false,
            "isFavorite": false
        },
        {
            "id": "wp_obsidian",
            "title": "Obsidian Peak",
            "path": "/usr/share/backgrounds/baseus/obsidian_peak.png",
            "previewColor": "#16161e",
            "isLive": false,
            "isFavorite": false
        },
        {
            "id": "wp_matrix",
            "title": "Cyber Matrix",
            "path": "/usr/share/backgrounds/baseus/cyber_matrix.mp4",
            "previewColor": "#121019",
            "isLive": true,
            "isFavorite": false
        }
    ]

    // Favorites & Recent Tracking
    property var favoritePaths: ({
        "/usr/share/backgrounds/baseus/default.png": true,
        "/usr/share/backgrounds/baseus/tokyo_neon.png": true
    })
    property var recentPaths: [
        "/usr/share/backgrounds/baseus/default.png",
        "/usr/share/backgrounds/baseus/tokyo_neon.png"
    ]

    // Filtered items based on active tab
    readonly property var currentItems: {
        var res = []
        if (pickerRoot.currentTab === "recent") {
            for (var r = 0; r < pickerRoot.recentPaths.length; r++) {
                var rp = pickerRoot.recentPaths[r]
                for (var c = 0; c < pickerRoot.catalog.length; c++) {
                    if (pickerRoot.catalog[c].path === rp) {
                        res.push(pickerRoot.catalog[c])
                        break
                    }
                }
            }
            return res
        }

        for (var i = 0; i < pickerRoot.catalog.length; i++) {
            var item = pickerRoot.catalog[i]
            if (pickerRoot.currentTab === "library") {
                res.push(item)
            } else if (pickerRoot.currentTab === "favorites") {
                if (pickerRoot.favoritePaths[item.path]) {
                    res.push(item)
                }
            }
        }
        return res
    }

    readonly property int itemCount: pickerRoot.currentItems.length

    signal dismissRequested()
    signal wallpaperApplied(string path, int workspace, bool isLive)

    // =========================================================
    // Active Workspace Tracking
    // =========================================================
    readonly property int currentWorkspace: {
        if (pickerRoot.workspaceModel && typeof pickerRoot.workspaceModel.getActiveWorkspace === "function") {
            return pickerRoot.workspaceModel.getActiveWorkspace(pickerRoot.monitorIndex)
        }
        return 1
    }

    readonly property string currentWallpaperPath: {
        if (pickerRoot.wallpaperService && typeof pickerRoot.wallpaperService.getWallpaperForMonitor === "function") {
            return pickerRoot.wallpaperService.getWallpaperForMonitor(pickerRoot.monitorIndex)
        }
        return ""
    }

    // =========================================================
    // Public API Methods
    // =========================================================

    function open() {
        pickerRoot.active = true
        pickerRoot.selectedIndex = 0
        focusItem.forceActiveFocus()
    }

    function close() {
        pickerRoot.active = false
    }

    function toggle() {
        if (pickerRoot.active) {
            close()
        } else {
            open()
        }
    }

    function setTab(tabName: string) {
        if (tabName === "library" || tabName === "recent" || tabName === "favorites") {
            pickerRoot.currentTab = tabName
            pickerRoot.selectedIndex = 0
        }
    }

    function toggleFavorite(path: string) {
        var updated = Object.assign({}, pickerRoot.favoritePaths)
        if (updated[path]) {
            delete updated[path]
        } else {
            updated[path] = true
        }
        pickerRoot.favoritePaths = updated
    }

    function _recordRecent(path: string) {
        var arr = pickerRoot.recentPaths.slice()
        var idx = arr.indexOf(path)
        if (idx >= 0) {
            arr.splice(idx, 1)
        }
        arr.unshift(path)
        if (arr.length > 8) {
            arr.pop()
        }
        pickerRoot.recentPaths = arr
    }

    function applySelected(allWorkspaces: bool): bool {
        var items = pickerRoot.currentItems
        if (pickerRoot.selectedIndex < 0 || pickerRoot.selectedIndex >= items.length) return false
        var sel = items[pickerRoot.selectedIndex]
        if (!sel || !pickerRoot.wallpaperService) return false

        _recordRecent(sel.path)

        if (sel.isLive) {
            pickerRoot.wallpaperService.setGlobalLiveWallpaper(sel.path)
            pickerRoot.wallpaperApplied(sel.path, 0, true)
        } else if (allWorkspaces) {
            for (var ws = 1; ws <= 10; ws++) {
                pickerRoot.wallpaperService.setWorkspaceWallpaper(ws, sel.path)
            }
            pickerRoot.wallpaperApplied(sel.path, 0, false)
        } else {
            var targetWs = pickerRoot.currentWorkspace
            pickerRoot.wallpaperService.setWorkspaceWallpaper(targetWs, sel.path)
            pickerRoot.wallpaperApplied(sel.path, targetWs, false)
        }

        pickerRoot.close()
        pickerRoot.dismissRequested()
        return true
    }

    function getSelectedWallpaper(): var {
        var items = pickerRoot.currentItems
        if (pickerRoot.selectedIndex >= 0 && pickerRoot.selectedIndex < items.length) {
            return items[pickerRoot.selectedIndex]
        }
        return null
    }

    function getSnapshot(): var {
        return {
            "active": pickerRoot.active,
            "currentTab": pickerRoot.currentTab,
            "selectedIndex": pickerRoot.selectedIndex,
            "selectedWallpaper": pickerRoot.getSelectedWallpaper(),
            "itemCount": pickerRoot.itemCount,
            "items": pickerRoot.currentItems,
            "favoritesCount": Object.keys(pickerRoot.favoritePaths).length,
            "recentCount": pickerRoot.recentPaths.length,
            "currentWorkspace": pickerRoot.currentWorkspace,
            "currentWallpaperPath": pickerRoot.currentWallpaperPath
        }
    }

    // =========================================================
    // UI Layout: Backdrop & Centered Floating Dialog
    // =========================================================

    // Solid Dimming Backdrop (Click-outside dismiss)
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: pickerRoot.currentTheme.colors.neutral
        opacity: pickerRoot.active ? pickerRoot.currentTheme.motion.recedeOpacity : 0.0
        visible: opacity > 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: pickerRoot.currentTheme.motion.durationNormal
                easing.type: Easing.InOutQuad
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                pickerRoot.close()
                pickerRoot.dismissRequested()
            }
        }
    }

    // Keyboard Focus Interceptor
    Item {
        id: focusItem
        anchors.fill: parent
        focus: pickerRoot.active

        Keys.onEscapePressed: {
            pickerRoot.close()
            pickerRoot.dismissRequested()
        }

        Keys.onReturnPressed: function(event) {
            var all = (event.modifiers & Qt.ShiftModifier) !== 0
            pickerRoot.applySelected(all)
        }

        Keys.onTabPressed: {
            if (pickerRoot.currentTab === "library") pickerRoot.setTab("recent")
            else if (pickerRoot.currentTab === "recent") pickerRoot.setTab("favorites")
            else pickerRoot.setTab("library")
        }

        Keys.onLeftPressed: {
            if (pickerRoot.selectedIndex > 0) {
                pickerRoot.selectedIndex--
            }
        }

        Keys.onRightPressed: {
            if (pickerRoot.selectedIndex < pickerRoot.itemCount - 1) {
                pickerRoot.selectedIndex++
            }
        }

        Keys.onUpPressed: {
            if (pickerRoot.selectedIndex - 3 >= 0) {
                pickerRoot.selectedIndex -= 3
            }
        }

        Keys.onDownPressed: {
            if (pickerRoot.selectedIndex + 3 < pickerRoot.itemCount) {
                pickerRoot.selectedIndex += 3
            }
        }
    }

    // Centered Floating Body (640x510px)
    Rectangle {
        id: dialogBody
        width: Math.min(660, parent.width - 48)
        height: Math.min(520, parent.height - 48)
        anchors.centerIn: parent

        color: pickerRoot.currentTheme.colors.surfaceSolid
        radius: pickerRoot.currentTheme.geometry.radiusLarge
        border.color: pickerRoot.currentTheme.colors.borderSubtle
        border.width: 1

        scale: pickerRoot.active ? 1.0 : 0.96
        opacity: pickerRoot.active ? 1.0 : 0.0
        visible: opacity > 0.0

        Behavior on scale {
            NumberAnimation {
                duration: pickerRoot.currentTheme.motion.durationFast
                easing.type: pickerRoot.currentTheme.motion.easingFocus
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: pickerRoot.currentTheme.motion.durationFast
                easing.type: Easing.InOutQuad
            }
        }

        // Prevent click-through to backdrop
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // -----------------------------------------------------
        // Header: Title & Tabs
        // -----------------------------------------------------
        Item {
            id: headerArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 56

            // Section Heading
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    width: 3
                    height: 14
                    radius: 1
                    color: pickerRoot.currentTheme.colors.dominant
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "WALLPAPERS"
                    font.family: pickerRoot.currentTheme.typography.fontFamilyMono
                    font.pixelSize: pickerRoot.currentTheme.typography.sizeTitle
                    font.weight: Font.DemiBold
                    font.capitalization: Font.AllUppercase
                    color: pickerRoot.currentTheme.colors.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Category Tab Switcher
            Row {
                anchors.centerIn: parent
                spacing: 6

                // Library Tab
                Rectangle {
                    width: 74
                    height: 28
                    radius: pickerRoot.currentTheme.geometry.radiusPill
                    color: pickerRoot.currentTab === "library"
                        ? pickerRoot.currentTheme.colors.surfaceHighlight
                        : "transparent"
                    border.color: pickerRoot.currentTab === "library"
                        ? pickerRoot.currentTheme.colors.dominant
                        : pickerRoot.currentTheme.colors.borderSubtle
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Library"
                        font.family: pickerRoot.currentTheme.typography.fontFamily
                        font.pixelSize: pickerRoot.currentTheme.typography.sizeCaption
                        font.weight: pickerRoot.currentTab === "library" ? Font.Medium : Font.Normal
                        color: pickerRoot.currentTab === "library"
                            ? pickerRoot.currentTheme.colors.textPrimary
                            : pickerRoot.currentTheme.colors.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pickerRoot.setTab("library")
                    }
                }

                // Recent Tab
                Rectangle {
                    width: 74
                    height: 28
                    radius: pickerRoot.currentTheme.geometry.radiusPill
                    color: pickerRoot.currentTab === "recent"
                        ? pickerRoot.currentTheme.colors.surfaceHighlight
                        : "transparent"
                    border.color: pickerRoot.currentTab === "recent"
                        ? pickerRoot.currentTheme.colors.dominant
                        : pickerRoot.currentTheme.colors.borderSubtle
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Recent"
                        font.family: pickerRoot.currentTheme.typography.fontFamily
                        font.pixelSize: pickerRoot.currentTheme.typography.sizeCaption
                        font.weight: pickerRoot.currentTab === "recent" ? Font.Medium : Font.Normal
                        color: pickerRoot.currentTab === "recent"
                            ? pickerRoot.currentTheme.colors.textPrimary
                            : pickerRoot.currentTheme.colors.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pickerRoot.setTab("recent")
                    }
                }

                // Favorites Tab
                Rectangle {
                    width: 74
                    height: 28
                    radius: pickerRoot.currentTheme.geometry.radiusPill
                    color: pickerRoot.currentTab === "favorites"
                        ? pickerRoot.currentTheme.colors.surfaceHighlight
                        : "transparent"
                    border.color: pickerRoot.currentTab === "favorites"
                        ? pickerRoot.currentTheme.colors.dominant
                        : pickerRoot.currentTheme.colors.borderSubtle
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Favorites"
                        font.family: pickerRoot.currentTheme.typography.fontFamily
                        font.pixelSize: pickerRoot.currentTheme.typography.sizeCaption
                        font.weight: pickerRoot.currentTab === "favorites" ? Font.Medium : Font.Normal
                        color: pickerRoot.currentTab === "favorites"
                            ? pickerRoot.currentTheme.colors.textPrimary
                            : pickerRoot.currentTheme.colors.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pickerRoot.setTab("favorites")
                    }
                }
            }

            // Close button (Esc)
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: 14
                color: closeHoverArea.containsMouse
                    ? pickerRoot.currentTheme.colors.surfaceHighlight
                    : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.pixelSize: 12
                    color: pickerRoot.currentTheme.colors.textSecondary
                }

                MouseArea {
                    id: closeHoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        pickerRoot.close()
                        pickerRoot.dismissRequested()
                    }
                }
            }

            // Hairline separator
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: pickerRoot.currentTheme.colors.borderSubtle
            }
        }

        // -----------------------------------------------------
        // Content Area: Grid of Wallpapers
        // -----------------------------------------------------
        Item {
            id: gridContainer
            anchors.top: headerArea.bottom
            anchors.bottom: footerArea.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16

            Grid {
                id: wallpaperGrid
                columns: 3
                spacing: 12
                anchors.centerIn: parent

                Repeater {
                    model: pickerRoot.currentItems

                    delegate: Rectangle {
                        id: cardItem
                        required property var modelData
                        required property int index

                        width: 196
                        height: 118
                        radius: pickerRoot.currentTheme.geometry.radiusMedium
                        color: pickerRoot.currentTheme.colors.surfaceRecessed
                        border.width: (pickerRoot.selectedIndex === index) ? 2 : 1
                        border.color: (pickerRoot.selectedIndex === index)
                            ? pickerRoot.currentTheme.colors.dominant
                            : (cardHover.containsMouse
                                ? pickerRoot.currentTheme.colors.surfaceHighlight
                                : pickerRoot.currentTheme.colors.borderSubtle)

                        scale: (pickerRoot.selectedIndex === index) ? 1.02 : (cardHover.containsMouse ? 1.01 : 1.0)

                        Behavior on scale {
                            NumberAnimation {
                                duration: pickerRoot.currentTheme.motion.durationFast
                                easing.type: Easing.OutQuad
                            }
                        }

                        // Preview background
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: pickerRoot.currentTheme.geometry.radiusMedium - 1
                            color: cardItem.modelData.previewColor || pickerRoot.currentTheme.colors.surfaceRecessed
                            clip: true

                            Image {
                                id: cardImg
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                source: cardItem.modelData.path ? ("file://" + cardItem.modelData.path) : ""
                                visible: status === Image.Ready
                            }

                            // Fallback geometric glyph
                            Text {
                                anchors.centerIn: parent
                                visible: !cardImg.visible
                                text: cardItem.modelData.isLive ? "▶ LIVE" : "❖"
                                font.family: pickerRoot.currentTheme.typography.fontFamilyMono
                                font.pixelSize: 14
                                color: pickerRoot.currentTheme.colors.textMuted
                            }

                            // Active indicator pill
                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.margins: 6
                                width: 52
                                height: 18
                                radius: 4
                                color: pickerRoot.currentTheme.colors.surfaceSolid
                                border.color: pickerRoot.currentTheme.colors.dominant
                                border.width: 1
                                visible: cardItem.modelData.path === pickerRoot.currentWallpaperPath

                                Text {
                                    anchors.centerIn: parent
                                    text: "ACTIVE"
                                    font.family: pickerRoot.currentTheme.typography.fontFamilyMono
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    color: pickerRoot.currentTheme.colors.dominant
                                }
                            }

                            // Favorite star button
                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 6
                                width: 22
                                height: 22
                                radius: 11
                                color: pickerRoot.favoritePaths[cardItem.modelData.path]
                                    ? pickerRoot.currentTheme.colors.dominant
                                    : (favHover.containsMouse ? pickerRoot.currentTheme.colors.surfaceHighlight : pickerRoot.currentTheme.colors.surfaceSolid)
                                border.color: pickerRoot.currentTheme.colors.borderSubtle
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "★"
                                    font.pixelSize: 10
                                    color: pickerRoot.favoritePaths[cardItem.modelData.path]
                                        ? pickerRoot.currentTheme.colors.textInverse
                                        : pickerRoot.currentTheme.colors.textSecondary
                                }

                                MouseArea {
                                    id: favHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: pickerRoot.toggleFavorite(cardItem.modelData.path)
                                }
                            }

                            // Bottom title strip
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 24
                                color: pickerRoot.currentTheme.colors.surfaceSolid

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: cardItem.modelData.title || "Wallpaper"
                                    font.family: pickerRoot.currentTheme.typography.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    color: (pickerRoot.selectedIndex === cardItem.index)
                                        ? pickerRoot.currentTheme.colors.dominant
                                        : pickerRoot.currentTheme.colors.textPrimary
                                }
                            }
                        }

                        MouseArea {
                            id: cardHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                pickerRoot.selectedIndex = cardItem.index
                            }
                            onDoubleClicked: {
                                pickerRoot.selectedIndex = cardItem.index
                                pickerRoot.applySelected(false)
                            }
                        }
                    }
                }
            }

            // Empty state placeholder
            Item {
                anchors.centerIn: parent
                visible: pickerRoot.itemCount === 0

                Text {
                    anchors.centerIn: parent
                    text: pickerRoot.currentTab === "favorites" ? "No favorites marked yet." : "No wallpapers found."
                    font.family: pickerRoot.currentTheme.typography.fontFamily
                    font.pixelSize: pickerRoot.currentTheme.typography.sizeBody
                    color: pickerRoot.currentTheme.colors.textMuted
                }
            }
        }

        // -----------------------------------------------------
        // Footer Area: Actions & Keyboard Hints
        // -----------------------------------------------------
        Item {
            id: footerArea
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 60

            // Top hairline separator
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: pickerRoot.currentTheme.colors.borderSubtle
            }

            // Left: Selected metadata summary
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    text: {
                        var sel = pickerRoot.getSelectedWallpaper()
                        return sel ? sel.title : "None selected"
                    }
                    font.family: pickerRoot.currentTheme.typography.fontFamily
                    font.pixelSize: pickerRoot.currentTheme.typography.sizeCaption
                    font.weight: Font.Medium
                    color: pickerRoot.currentTheme.colors.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "·  Workspace " + pickerRoot.currentWorkspace
                    font.family: pickerRoot.currentTheme.typography.fontFamilyMono
                    font.pixelSize: 10
                    color: pickerRoot.currentTheme.colors.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Right: Action buttons
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // Apply to Active Workspace Button
                Rectangle {
                    width: 108
                    height: 30
                    radius: pickerRoot.currentTheme.geometry.radiusPill
                    color: pickerRoot.currentTheme.colors.dominant

                    Text {
                        anchors.centerIn: parent
                        text: "Apply (WS " + pickerRoot.currentWorkspace + ")"
                        font.family: pickerRoot.currentTheme.typography.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: pickerRoot.currentTheme.colors.textInverse
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pickerRoot.applySelected(false)
                    }
                }

                // Apply to All Workspaces Button
                Rectangle {
                    width: 80
                    height: 30
                    radius: pickerRoot.currentTheme.geometry.radiusPill
                    color: pickerRoot.currentTheme.colors.surfaceHighlight
                    border.color: pickerRoot.currentTheme.colors.borderSubtle
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Apply All"
                        font.family: pickerRoot.currentTheme.typography.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: pickerRoot.currentTheme.colors.textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pickerRoot.applySelected(true)
                    }
                }
            }
        }
    }
}
