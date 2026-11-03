pragma ComponentBehavior: Bound

// BASEUS — Headquarter Settings Application
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by MASTER.md §18–22, DESIGN.md §24–25, DEC-019, and ANTI-SLOP.md:
//   - Literally fullscreen surface mapped per-monitor on WlrLayer.Overlay
//   - Persistent right sidebar (240px) with organic ICR fillets, never icon-only
//   - One-way configuration principle: "If something is configurable, it belongs in Headquarter"
//   - Contextual help bubbles to the right without shifting the main layout
//   - Live apply principle: settings mutate backend models immediately with sensible defaults
//   - Solid Wabi-sabi body (Theme.colors.surfaceBase + surfaceSolid), zero blur, zero glassmorphism
//   - Layer-shell input region contracting to 0x0 when closed

import QtQuick
import "../theme" as ThemeModule

Item {
    id: headquarterRoot

    // =========================================================
    // Dependencies & Configuration
    // =========================================================
    property var theme: null
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: headquarterRoot.theme ? headquarterRoot.theme : headquarterRoot.defaultTheme

    property var shellState: null
    property var config: null
    property var themeService: null
    property var paletteService: null
    property var wallpaperService: null
    property var workspaceModel: null
    property var monitorModel: null
    property var windowModel: null
    property var actionRegistry: null
    property var notificationModel: null
    property var audioService: null
    property var mediaService: null
    property var statusService: null
    property var bridge: null
    property var hostRef: null
    property int monitorIndex: 0

    // =========================================================
    // State Properties
    // =========================================================
    property bool active: false
    property string currentCategory: "home" // "home" | "appearance" | "workspaces" | "shortcuts" | "feedback" | "about"
    readonly property var categories: ["home", "appearance", "workspaces", "shortcuts", "feedback", "about"]
    property string searchQuery: ""

    // Contextual Help state (MASTER.md §21, DESIGN.md §25)
    property string activeHelpTitle: ""
    property string activeHelpText: ""
    property int activeHelpY: 100
    property bool activeHelpVisible: false

    // Action filter in Shortcuts category
    property string actionCategoryFilter: "all" // "all" | "navigation" | "workspace" | "window"

    signal dismissRequested()

    // =========================================================
    // Settings Catalog & Search Index (MASTER.md §20)
    // =========================================================
    readonly property var settingsIndex: [
        {
            "id": "theme_preset",
            "title": "Theme Presets",
            "category": "appearance",
            "breadcrumb": "Appearance > Theme Presets",
            "description": "Switch between pre-configured aesthetic palettes (Wabi-sabi Indigo, Tokyo Slate, Cyber Sand, Obsidian Ember).",
            "helpText": "Selects a unified design preset. Themes alter visual styling (colors, wallpaper, surface accents) without affecting shortcuts or interaction invariants (DEC-037).",
            "keywords": "theme preset tokyo slate indigo cyber sand obsidian appearance visual style colors"
        },
        {
            "id": "visual_transition",
            "title": "Visual Transitions",
            "category": "appearance",
            "breadcrumb": "Appearance > Visual Transitions",
            "description": "Select the visual mask wiping style used during theme transitions.",
            "helpText": "Determines the visual wipe animation when changing themes: circle_wipe, wavy_wipe, bubble_ripple, or standard fade crossfade.",
            "keywords": "transition wipe circle wavy bubble fade animation theme motion"
        },
        {
            "id": "four_color_palette",
            "title": "Four-Color Palette Architecture",
            "category": "appearance",
            "breadcrumb": "Appearance > Palette Roles (DEC-011)",
            "description": "Inspect the four primary color roles: Dominant, Secondary, Accent, and Neutral.",
            "helpText": "BASEUS enforces strictly four primary colors per theme. All tonal and surface colors are algorithmically derived, preserving WCAG AA contrast (DEC-011).",
            "keywords": "palette color dominant secondary accent neutral contrast wcag matugen 4-color"
        },
        {
            "id": "wallpaper_engine",
            "title": "Wallpaper Engine & Assignments",
            "category": "appearance",
            "breadcrumb": "Appearance > Wallpaper Engine (DEC-013)",
            "description": "Manage per-workspace static wallpapers and global live wallpapers.",
            "helpText": "Static wallpapers are mapped per workspace (1–10). Live wallpapers span globally across monitors without duplicate rendering overhead.",
            "keywords": "wallpaper static live background image video workspace monitor"
        },
        {
            "id": "workspace_labels",
            "title": "Workspace Labels & Tags",
            "category": "workspaces",
            "breadcrumb": "Workspaces & Monitors > Workspace Labels",
            "description": "Assign custom semantic names and tags to workspaces 1 through 10.",
            "helpText": "Customize the 10 fixed workspaces with user-defined names (e.g. HOME, DEV, CHAT). Changes mutate config and workspace model immediately.",
            "keywords": "workspace label name tag 1-10 configure rename"
        },
        {
            "id": "monitors_topology",
            "title": "Display Topology & Geometry",
            "category": "workspaces",
            "breadcrumb": "Workspaces & Monitors > Display Topology",
            "description": "View connected displays, refresh rates, resolutions, and scaling.",
            "helpText": "Displays the active Wayland outputs recognized by Hyprland. Workspaces and Layer-Shell surfaces are instantiated per monitor.",
            "keywords": "monitor display screen resolution geometry virtual output refresh rate"
        },
        {
            "id": "action_registry",
            "title": "Action Registry & Shortcuts",
            "category": "shortcuts",
            "breadcrumb": "Shortcuts & Gestures > Action Registry (DEC-028)",
            "description": "Browse all registered shell actions, default keybindings, and conflicts.",
            "helpText": "All BASEUS operations follow Discover → Customize → Execute. View core navigation, workspace, and window action bindings.",
            "keywords": "shortcut keybind key action registry navigation back home super overview"
        },
        {
            "id": "notification_timeout",
            "title": "Notification Display Duration",
            "category": "feedback",
            "breadcrumb": "System Feedback > Notifications (DEC-020)",
            "description": "Configure the auto-dismiss timeout for top-left desktop notifications.",
            "helpText": "Sets how many milliseconds a notification remains visible before auto-dismissal. Hovering pauses the countdown; long-press silences alerts.",
            "keywords": "notification timeout duration dismiss silence delay"
        },
        {
            "id": "hold_to_silence",
            "title": "Notification Hold-to-Silence",
            "category": "feedback",
            "breadcrumb": "System Feedback > Hold-to-Silence",
            "description": "Hold a notification for ~1200ms to silence all desktop notifications.",
            "helpText": "A gentle long-press (~1200ms) on any notification triggers an intentional hold progress fill that silences the desktop feedback system calmly.",
            "keywords": "notification hold silence mute dnd do not disturb gesture"
        },
        {
            "id": "osd_timeout",
            "title": "Top Island OSD Behavior",
            "category": "feedback",
            "breadcrumb": "System Feedback > Top Island OSD (DEC-021)",
            "description": "Configure the volume and display brightness bubble-drop feedback delay.",
            "helpText": "OSD bubbles emerge smoothly from the Top Island notch with in-place morphing and 100% click-through hitmasking so input is never blocked.",
            "keywords": "osd volume brightness top island bubble drop sound feedback"
        },
        {
            "id": "media_player",
            "title": "Media Player & Strict DEC-039",
            "category": "feedback",
            "breadcrumb": "System Feedback > MPRIS Media (DEC-026, DEC-039)",
            "description": "Centralized media player tracking with strict notification suppression.",
            "helpText": "Track and playback state changes are displayed calmly inside the Top Island and Media Widget; track change notifications are strictly suppressed.",
            "keywords": "media mpris player music song artist notification suppression dec-039"
        },
        {
            "id": "bongo_cat",
            "title": "Bongo Cat Companion",
            "category": "feedback",
            "breadcrumb": "System Feedback > Bongo Cat Companion (ANTI-SLOP §37)",
            "description": "Personality companion reacting contextually with zero CPU consumption at idle.",
            "helpText": "The vector-rendered companion synchronizes with playback rhythm during music playback, and completely halts its internal timer when paused.",
            "keywords": "bongo cat companion pet animation paw tempo rhythm cpu idle"
        },
        {
            "id": "about_baseus",
            "title": "System Identity & Health",
            "category": "about",
            "breadcrumb": "System / About > Subsystem Health",
            "description": "View BASEUS version, licensing, compositor bridge, and service health.",
            "helpText": "Overview of active subsystem connectivity: HyprlandBridge, PipeWire AudioService, MPRIS MediaService, and StatusService telemetry.",
            "keywords": "about system version license author architecture health bridge"
        }
    ]

    readonly property var searchResults: {
        var q = headquarterRoot.searchQuery.trim().toLowerCase()
        if (q.length === 0) return []
        var res = []
        for (var i = 0; i < headquarterRoot.settingsIndex.length; i++) {
            var item = headquarterRoot.settingsIndex[i]
            var haystack = (item.title + " " + item.description + " " + item.keywords + " " + item.breadcrumb).toLowerCase()
            if (haystack.indexOf(q) >= 0) {
                res.push(item)
            }
        }
        return res
    }

    // =========================================================
    // Public API Methods
    // =========================================================

    function open(category: string) {
        headquarterRoot.active = true
        if (category && (category === "home" || category === "appearance" || category === "workspaces" || category === "shortcuts" || category === "feedback" || category === "about")) {
            headquarterRoot.currentCategory = category
        } else {
            headquarterRoot.currentCategory = "home"
        }
        headquarterRoot.searchQuery = ""
        headquarterRoot.dismissHelp()
        focusItem.forceActiveFocus()
    }

    function close() {
        headquarterRoot.active = false
        headquarterRoot.searchQuery = ""
        headquarterRoot.dismissHelp()
        headquarterRoot.dismissRequested()
    }

    function toggle(category: string) {
        if (headquarterRoot.active) {
            close()
        } else {
            open(category)
        }
    }

    function setCategory(cat: string) {
        if (cat === "home" || cat === "appearance" || cat === "workspaces" || cat === "shortcuts" || cat === "feedback" || cat === "about") {
            headquarterRoot.currentCategory = cat
            headquarterRoot.searchQuery = ""
            headquarterRoot.dismissHelp()
        }
    }

    function setSearch(query: string) {
        headquarterRoot.searchQuery = query
        headquarterRoot.dismissHelp()
    }

    function triggerHelp(title: string, text: string, yPos: int) {
        if (headquarterRoot.activeHelpVisible && headquarterRoot.activeHelpTitle === title) {
            headquarterRoot.activeHelpVisible = false
        } else {
            headquarterRoot.activeHelpTitle = title
            headquarterRoot.activeHelpText = text
            headquarterRoot.activeHelpY = Math.max(80, yPos - 16)
            headquarterRoot.activeHelpVisible = true
        }
    }

    function dismissHelp() {
        headquarterRoot.activeHelpVisible = false
        headquarterRoot.activeHelpTitle = ""
        headquarterRoot.activeHelpText = ""
    }

    function getSnapshot(): var {
        return {
            "active": headquarterRoot.active,
            "currentCategory": headquarterRoot.currentCategory,
            "categories": headquarterRoot.categories,
            "searchQuery": headquarterRoot.searchQuery,
            "searchResultsCount": headquarterRoot.searchResults.length,
            "searchResults": headquarterRoot.searchResults,
            "activeHelpVisible": headquarterRoot.activeHelpVisible,
            "activeHelpTitle": headquarterRoot.activeHelpTitle,
            "monitorIndex": headquarterRoot.monitorIndex,
            "activeTheme": headquarterRoot.themeService ? headquarterRoot.themeService.activeThemeName : "wabi-sabi-indigo",
            "activeWorkspace": headquarterRoot.workspaceModel ? headquarterRoot.workspaceModel.getActiveWorkspace(headquarterRoot.monitorIndex) : 1
        }
    }

    function getPresetPreviewColor(themeId: string): color {
        if (headquarterRoot.themeService && headquarterRoot.themeService.builtinThemes) {
            var themeDef = headquarterRoot.themeService.builtinThemes[themeId]
            if (themeDef && themeDef.palette && themeDef.palette.surfaceBase) {
                return themeDef.palette.surfaceBase
            }
        }
        return headquarterRoot.currentTheme.colors.surfaceSolid
    }

    // =========================================================
    // Keyboard Focus & Dismissal
    // =========================================================
    Item {
        id: focusItem
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: function(event) {
            event.accepted = true
            if (headquarterRoot.activeHelpVisible) {
                headquarterRoot.dismissHelp()
            } else if (headquarterRoot.searchQuery.length > 0) {
                headquarterRoot.searchQuery = ""
            } else {
                headquarterRoot.close()
            }
        }
    }

    // =========================================================
    // UI Layout: Fullscreen Canvas & Curtain Reveal
    // =========================================================

    // Solid Background Canvas
    Rectangle {
        id: backgroundCanvas
        anchors.fill: parent
        color: headquarterRoot.currentTheme.colors.surfaceBase
        opacity: headquarterRoot.active ? 1.0 : 0.0
        visible: opacity > 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: headquarterRoot.currentTheme.motion.durationSlow
                easing.type: headquarterRoot.currentTheme.motion.easingStandard
            }
        }
    }

    // Main Interactive Container
    Item {
        id: container
        anchors.fill: parent
        visible: headquarterRoot.active

        // -----------------------------------------------------
        // Left & Center: Main Settings Content Area
        // -----------------------------------------------------
        Item {
            id: mainContentArea
            anchors.left: parent.left
            anchors.right: rightSidebar.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            // Top Navigation & Search Bar
            Item {
                id: topNavBar
                height: 72
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 48
                anchors.rightMargin: 48

                // Breadcrumb Path
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: "HEADQUARTER"
                        font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                        font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                        font.weight: Font.DemiBold
                        color: headquarterRoot.currentTheme.colors.textMuted
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "/"
                        font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                        font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                        color: headquarterRoot.currentTheme.colors.outlineVariant
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: headquarterRoot.currentCategory.toUpperCase()
                        font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                        font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                        font.weight: Font.DemiBold
                        color: headquarterRoot.currentTheme.colors.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Search Input Box (MASTER.md §20)
                Rectangle {
                    id: searchBox
                    width: 280
                    height: 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    radius: headquarterRoot.currentTheme.geometry.radiusMedium
                    color: headquarterRoot.currentTheme.colors.surfaceContainerLowest
                    border.color: searchInput.activeFocus
                        ? headquarterRoot.currentTheme.colors.accent
                        : headquarterRoot.currentTheme.colors.outlineVariant
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: "⌕"
                            font.pixelSize: 14
                            color: headquarterRoot.currentTheme.colors.textMuted
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextInput {
                            id: searchInput
                            width: parent.width - 48
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: headquarterRoot.currentTheme.typography.fontFamily
                            font.pixelSize: headquarterRoot.currentTheme.typography.sizeBody
                            color: headquarterRoot.currentTheme.colors.textPrimary
                            clip: true
                            text: headquarterRoot.searchQuery
                            onTextChanged: headquarterRoot.searchQuery = text

                            Text {
                                text: "Search settings..."
                                font.family: headquarterRoot.currentTheme.typography.fontFamily
                                font.pixelSize: headquarterRoot.currentTheme.typography.sizeBody
                                color: headquarterRoot.currentTheme.colors.textMuted
                                visible: searchInput.text.length === 0
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: "×"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: headquarterRoot.currentTheme.colors.textMuted
                            visible: headquarterRoot.searchQuery.length > 0
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = ""
                                    headquarterRoot.searchQuery = ""
                                }
                            }
                        }
                    }
                }

                // 1px Hairline Separator
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: headquarterRoot.currentTheme.colors.borderSubtle
                }
            }

            // Scrollable Content Region
            Flickable {
                id: mainFlickable
                anchors.top: topNavBar.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 48
                anchors.rightMargin: 48
                anchors.topMargin: 24
                anchors.bottomMargin: 24
                contentWidth: width
                contentHeight: contentColumn.implicitHeight + 48
                clip: true

                Column {
                    id: contentColumn
                    width: Math.min(760, parent.width - 280) // Leaves space on right for help bubble
                    spacing: 28

                    // =================================================
                    // Search Results View (when searchQuery active)
                    // =================================================
                    Column {
                        width: parent.width
                        spacing: 16
                        visible: headquarterRoot.searchQuery.trim().length > 0

                        Text {
                            text: "SEARCH RESULTS (" + headquarterRoot.searchResults.length + ")"
                            font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                            font.pixelSize: headquarterRoot.currentTheme.typography.sizeMicro
                            font.weight: Font.Bold
                            color: headquarterRoot.currentTheme.colors.textMuted
                        }

                        Repeater {
                            model: headquarterRoot.searchResults

                            delegate: Rectangle {
                                id: searchResultDelegate
                                required property var modelData
                                required property int index

                                width: contentColumn.width
                                height: 72
                                radius: headquarterRoot.currentTheme.geometry.radiusMedium
                                color: resultHover.containsMouse
                                    ? headquarterRoot.currentTheme.colors.surfaceHighlight
                                    : headquarterRoot.currentTheme.colors.surfaceSolid
                                border.color: headquarterRoot.currentTheme.colors.borderSubtle
                                border.width: 1

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4

                                    Row {
                                        spacing: 8
                                        Text {
                                            text: searchResultDelegate.modelData.title
                                            font.family: headquarterRoot.currentTheme.typography.fontFamily
                                            font.pixelSize: headquarterRoot.currentTheme.typography.sizeBody
                                            font.weight: Font.DemiBold
                                            color: headquarterRoot.currentTheme.colors.textPrimary
                                        }
                                        Text {
                                            text: "·  " + searchResultDelegate.modelData.breadcrumb
                                            font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                            font.pixelSize: 10
                                            color: headquarterRoot.currentTheme.colors.accent
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Text {
                                        text: searchResultDelegate.modelData.description
                                        width: parent.width
                                        elide: Text.ElideRight
                                        font.family: headquarterRoot.currentTheme.typography.fontFamily
                                        font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                                        color: headquarterRoot.currentTheme.colors.textSecondary
                                    }
                                }

                                MouseArea {
                                    id: resultHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        headquarterRoot.currentCategory = searchResultDelegate.modelData.category
                                        headquarterRoot.searchQuery = ""
                                        searchInput.text = ""
                                    }
                                }
                            }
                        }

                        Text {
                            visible: headquarterRoot.searchResults.length === 0
                            text: "No matching settings found for \"" + headquarterRoot.searchQuery + "\"."
                            font.family: headquarterRoot.currentTheme.typography.fontFamily
                            font.pixelSize: headquarterRoot.currentTheme.typography.sizeBody
                            color: headquarterRoot.currentTheme.colors.textMuted
                        }
                    }

                    // =================================================
                    // Category 1: HOME VIEW (MASTER.md §19)
                    // =================================================
                    Column {
                        width: parent.width
                        spacing: 24
                        visible: headquarterRoot.searchQuery.trim().length === 0 && headquarterRoot.currentCategory === "home"

                        // Archival Editorial Greeting
                        Column {
                            width: parent.width
                            spacing: 6

                            Text {
                                text: "SECTION 01  ·  CORE OPERATIONS"
                                font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                font.pixelSize: headquarterRoot.currentTheme.typography.sizeMicro
                                font.weight: Font.Bold
                                color: headquarterRoot.currentTheme.colors.accent
                            }

                            Text {
                                text: "BASEUS HEADQUARTER"
                                font.family: headquarterRoot.currentTheme.typography.fontFamily
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                color: headquarterRoot.currentTheme.colors.textPrimary
                            }

                            Text {
                                text: "Central Operational Environment. Wabi-sabi foundation with cybernetic velocity."
                                font.family: headquarterRoot.currentTheme.typography.fontFamily
                                font.pixelSize: headquarterRoot.currentTheme.typography.sizeBody
                                color: headquarterRoot.currentTheme.colors.textSecondary
                            }
                        }

                        // Quiet System State Grid (Strictly NO fake CPU/RAM KPI cockpit slop)
                        Grid {
                            columns: 2
                            columnSpacing: 16
                            rowSpacing: 16
                            width: parent.width

                            // Card 1: Active Theme & Daily Snapshot
                            Rectangle {
                                width: (parent.width - 16) / 2
                                height: 104
                                radius: headquarterRoot.currentTheme.geometry.radiusMedium
                                color: headquarterRoot.currentTheme.colors.surfaceSolid
                                border.color: headquarterRoot.currentTheme.colors.borderSubtle
                                border.width: 1

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 4

                                    Text {
                                        text: "01  ACTIVE THEME"
                                        font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                        font.pixelSize: headquarterRoot.currentTheme.typography.sizeMicro
                                        color: headquarterRoot.currentTheme.colors.textMuted
                                    }
                                    Text {
                                        text: headquarterRoot.themeService ? headquarterRoot.themeService.activeThemeName : "wabi-sabi-indigo"
                                        font.family: headquarterRoot.currentTheme.typography.fontFamily
                                        font.pixelSize: headquarterRoot.currentTheme.typography.sizeTitle
                                        font.weight: Font.DemiBold
                                        color: headquarterRoot.currentTheme.colors.textPrimary
                                    }
                                    Text {
                                        text: "Transition: " + (headquarterRoot.themeService ? headquarterRoot.themeService.activeTransition : "fade")
                                        font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                        font.pixelSize: 10
                                        color: headquarterRoot.currentTheme.colors.accent
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: headquarterRoot.setCategory("appearance")
                                }
                            }

                            // Card 2: Palette Roles (DEC-011)
                            Rectangle {
                                width: (parent.width - 16) / 2
                                height: 104
                                radius: headquarterRoot.currentTheme.geometry.radiusMedium
                                color: headquarterRoot.currentTheme.colors.surfaceSolid
                                border.color: headquarterRoot.currentTheme.colors.borderSubtle
                                border.width: 1

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 6

                                    Text {
                                        text: "02  PALETTE ARCHITECTURE (DEC-011)"
                                        font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                        font.pixelSize: headquarterRoot.currentTheme.typography.sizeMicro
                                        color: headquarterRoot.currentTheme.colors.textMuted
                                    }

                                    Row {
                                        spacing: 8
                                        Rectangle { width: 22; height: 22; radius: 4; color: headquarterRoot.currentTheme.colors.dominant }
                                        Rectangle { width: 22; height: 22; radius: 4; color: headquarterRoot.currentTheme.colors.secondary }
                                        Rectangle { width: 22; height: 22; radius: 4; color: headquarterRoot.currentTheme.colors.accent }
                                        Rectangle { width: 22; height: 22; radius: 4; color: headquarterRoot.currentTheme.colors.neutral }
                                    }

                                    Text {
                                        text: "Strictly 4 primary roles  ·  WCAG AA Compliant"
                                        font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                        font.pixelSize: 10
                                        color: headquarterRoot.currentTheme.colors.textMuted
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: headquarterRoot.setCategory("appearance")
                                }
                            }

                            // Card 3: Workspace Architecture (DEC-010)
                            Rectangle {
                                width: (parent.width - 16) / 2
                                height: 104
                                radius: headquarterRoot.currentTheme.geometry.radiusMedium
                                color: headquarterRoot.currentTheme.colors.surfaceSolid
                                border.color: headquarterRoot.currentTheme.colors.borderSubtle
                                border.width: 1

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 4

                                    Text {
                                        text: "03  WORKSPACES & TOPOLOGY"
                                        font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                        font.pixelSize: headquarterRoot.currentTheme.typography.sizeMicro
                                        color: headquarterRoot.currentTheme.colors.textMuted
                                    }
                                    Text {
                                        text: "Workspace " + (headquarterRoot.workspaceModel ? headquarterRoot.workspaceModel.getActiveWorkspace(headquarterRoot.monitorIndex) : 1) + " of 10"
                                        font.family: headquarterRoot.currentTheme.typography.fontFamily
                                        font.pixelSize: headquarterRoot.currentTheme.typography.sizeTitle
                                        font.weight: Font.DemiBold
                                        color: headquarterRoot.currentTheme.colors.textPrimary
                                    }
                                    Text {
                                        text: (headquarterRoot.monitorModel ? headquarterRoot.monitorModel.monitors.length : 1) + " active display(s)  ·  Per-monitor fixed 10 WS"
                                        font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                        font.pixelSize: 10
                                        color: headquarterRoot.currentTheme.colors.textSecondary
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: headquarterRoot.setCategory("workspaces")
                                }
                            }

                            // Card 4: Action Registry (DEC-028)
                            Rectangle {
                                width: (parent.width - 16) / 2
                                height: 104
                                radius: headquarterRoot.currentTheme.geometry.radiusMedium
                                color: headquarterRoot.currentTheme.colors.surfaceSolid
                                border.color: headquarterRoot.currentTheme.colors.borderSubtle
                                border.width: 1

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 4

                                    Text {
                                        text: "04  ACTION REGISTRY (DEC-028)"
                                        font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                        font.pixelSize: headquarterRoot.currentTheme.typography.sizeMicro
                                        color: headquarterRoot.currentTheme.colors.textMuted
                                    }
                                    Text {
                                        text: (headquarterRoot.actionRegistry ? headquarterRoot.actionRegistry.actionCount : 22) + " Registered Actions"
                                        font.family: headquarterRoot.currentTheme.typography.fontFamily
                                        font.pixelSize: headquarterRoot.currentTheme.typography.sizeTitle
                                        font.weight: Font.DemiBold
                                        color: headquarterRoot.currentTheme.colors.textPrimary
                                    }
                                    Text {
                                        text: "Discover  →  Customize  →  Execute"
                                        font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                        font.pixelSize: 10
                                        color: headquarterRoot.currentTheme.colors.accent
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: headquarterRoot.setCategory("shortcuts")
                                }
                            }
                        }

                        // Quick Navigation Jump Pills
                        Row {
                            spacing: 10

                            Rectangle {
                                height: 32
                                width: 140
                                radius: headquarterRoot.currentTheme.geometry.radiusPill
                                color: headquarterRoot.currentTheme.colors.surfaceHighlight
                                border.color: headquarterRoot.currentTheme.colors.borderSubtle
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "Appearance →"
                                    font.family: headquarterRoot.currentTheme.typography.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: headquarterRoot.currentTheme.colors.textPrimary
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: headquarterRoot.setCategory("appearance")
                                }
                            }

                            Rectangle {
                                height: 32
                                width: 160
                                radius: headquarterRoot.currentTheme.geometry.radiusPill
                                color: headquarterRoot.currentTheme.colors.surfaceHighlight
                                border.color: headquarterRoot.currentTheme.colors.borderSubtle
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "System Feedback →"
                                    font.family: headquarterRoot.currentTheme.typography.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: headquarterRoot.currentTheme.colors.textPrimary
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: headquarterRoot.setCategory("feedback")
                                }
                            }
                        }
                    }

                    // =================================================
                    // Category 2: APPEARANCE VIEW (MASTER.md §23–27)
                    // =================================================
                    Column {
                        width: parent.width
                        spacing: 24
                        visible: headquarterRoot.searchQuery.trim().length === 0 && headquarterRoot.currentCategory === "appearance"

                        // Section 1: Theme Presets
                        Column {
                            width: parent.width
                            spacing: 12

                            Row {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "THEME PRESETS"
                                    font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                    font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                                    font.weight: Font.Bold
                                    color: headquarterRoot.currentTheme.colors.textPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                // Help Trigger
                                Rectangle {
                                    width: 18; height: 18; radius: 9
                                    color: headquarterRoot.currentTheme.colors.surfaceHighlight
                                    border.color: headquarterRoot.currentTheme.colors.borderSubtle; border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: "?"; font.pixelSize: 10; color: headquarterRoot.currentTheme.colors.textMuted }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: headquarterRoot.triggerHelp("Theme Presets", "Select a predefined aesthetic theme. Themes mutate visual styling (palette, wallpaper, layout) while strictly preserving gestures and shortcuts (DEC-037).", parent.y)
                                    }
                                }
                            }

                            Row {
                                spacing: 12

                                Repeater {
                                    model: [
                                        { "id": "wabi-sabi-indigo", "name": "Wabi-Sabi Indigo" },
                                        { "id": "tokyo-slate", "name": "Tokyo Slate" },
                                        { "id": "cyber-sand", "name": "Cyber Sand" },
                                        { "id": "obsidian-ember", "name": "Obsidian Ember" }
                                    ]

                                    delegate: Rectangle {
                                        id: themePresetDelegate
                                        required property var modelData
                                        width: 160
                                        height: 80
                                        radius: headquarterRoot.currentTheme.geometry.radiusMedium
                                        color: headquarterRoot.currentTheme.colors.surfaceSolid
                                        border.color: (headquarterRoot.themeService && headquarterRoot.themeService.activeThemeName === themePresetDelegate.modelData.id)
                                            ? headquarterRoot.currentTheme.colors.accent
                                            : headquarterRoot.currentTheme.colors.borderSubtle
                                        border.width: (headquarterRoot.themeService && headquarterRoot.themeService.activeThemeName === themePresetDelegate.modelData.id) ? 2 : 1

                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 4

                                            Rectangle {
                                                width: parent.width
                                                height: 24
                                                radius: 4
                                                color: headquarterRoot.getPresetPreviewColor(themePresetDelegate.modelData.id)
                                            }

                                            Text {
                                                text: themePresetDelegate.modelData.name
                                                font.family: headquarterRoot.currentTheme.typography.fontFamily
                                                font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                                                font.weight: Font.DemiBold
                                                color: headquarterRoot.currentTheme.colors.textPrimary
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (headquarterRoot.themeService) {
                                                    headquarterRoot.themeService.applyTheme(themePresetDelegate.modelData.id)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Section 2: Visual Transitions
                        Column {
                            width: parent.width
                            spacing: 12

                            Row {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "VISUAL TRANSITION WIPES"
                                    font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                    font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                                    font.weight: Font.Bold
                                    color: headquarterRoot.currentTheme.colors.textPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 18; height: 18; radius: 9
                                    color: headquarterRoot.currentTheme.colors.surfaceHighlight
                                    border.color: headquarterRoot.currentTheme.colors.borderSubtle; border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: "?"; font.pixelSize: 10; color: headquarterRoot.currentTheme.colors.textMuted }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: headquarterRoot.triggerHelp("Visual Transition Wipes", "Determines the shader/mask transition animation when applying a new theme (circle_wipe, wavy_wipe, bubble_ripple, fade).", parent.y)
                                    }
                                }
                            }

                            Row {
                                spacing: 10
                                Repeater {
                                    model: ["fade", "circle_wipe", "wavy_wipe", "bubble_ripple"]
                                    delegate: Rectangle {
                                        id: transitionDelegate
                                        required property string modelData
                                        width: 110
                                        height: 32
                                        radius: headquarterRoot.currentTheme.geometry.radiusPill
                                        color: (headquarterRoot.themeService && headquarterRoot.themeService.activeTransition === transitionDelegate.modelData)
                                            ? headquarterRoot.currentTheme.colors.dominant
                                            : headquarterRoot.currentTheme.colors.surfaceHighlight
                                        border.color: headquarterRoot.currentTheme.colors.borderSubtle
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: transitionDelegate.modelData
                                            font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                            font.pixelSize: 10
                                            color: (headquarterRoot.themeService && headquarterRoot.themeService.activeTransition === transitionDelegate.modelData)
                                                ? headquarterRoot.currentTheme.colors.textInverse
                                                : headquarterRoot.currentTheme.colors.textPrimary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (headquarterRoot.themeService) {
                                                    headquarterRoot.themeService.activeTransition = transitionDelegate.modelData
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Section 3: Four-Color Palette Inspector (DEC-011)
                        Column {
                            width: parent.width
                            spacing: 12

                            Row {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "PALETTE ROLES (DEC-011)"
                                    font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                    font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                                    font.weight: Font.Bold
                                    color: headquarterRoot.currentTheme.colors.textPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 18; height: 18; radius: 9
                                    color: headquarterRoot.currentTheme.colors.surfaceHighlight
                                    border.color: headquarterRoot.currentTheme.colors.borderSubtle; border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: "?"; font.pixelSize: 10; color: headquarterRoot.currentTheme.colors.textMuted }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: headquarterRoot.triggerHelp("Palette Roles (DEC-011)", "Every BASEUS theme derives all surface colors strictly from four primary color roles: Dominant, Secondary, Accent, and Neutral.", parent.y)
                                    }
                                }
                            }

                            Row {
                                spacing: 14
                                Repeater {
                                    model: [
                                        { "role": "Dominant", "color": headquarterRoot.currentTheme.colors.dominant },
                                        { "role": "Secondary", "color": headquarterRoot.currentTheme.colors.secondary },
                                        { "role": "Accent", "color": headquarterRoot.currentTheme.colors.accent },
                                        { "role": "Neutral", "color": headquarterRoot.currentTheme.colors.neutral }
                                    ]

                                    delegate: Rectangle {
                                        id: paletteRoleDelegate
                                        required property var modelData
                                        width: 130
                                        height: 70
                                        radius: headquarterRoot.currentTheme.geometry.radiusMedium
                                        color: headquarterRoot.currentTheme.colors.surfaceSolid
                                        border.color: headquarterRoot.currentTheme.colors.borderSubtle
                                        border.width: 1

                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 4

                                            Row {
                                                spacing: 6
                                                Rectangle { width: 14; height: 14; radius: 3; color: paletteRoleDelegate.modelData.color }
                                                Text {
                                                    text: paletteRoleDelegate.modelData.role
                                                    font.family: headquarterRoot.currentTheme.typography.fontFamily
                                                    font.pixelSize: 11
                                                    font.weight: Font.DemiBold
                                                    color: headquarterRoot.currentTheme.colors.textPrimary
                                                }
                                            }

                                            Text {
                                                text: String(paletteRoleDelegate.modelData.color)
                                                font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                                font.pixelSize: 10
                                                color: headquarterRoot.currentTheme.colors.textMuted
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Section 4: Wallpaper Launcher
                        Column {
                            width: parent.width
                            spacing: 12

                            Row {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "WALLPAPER ASSIGNMENTS"
                                    font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                    font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                                    font.weight: Font.Bold
                                    color: headquarterRoot.currentTheme.colors.textPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 18; height: 18; radius: 9
                                    color: headquarterRoot.currentTheme.colors.surfaceHighlight
                                    border.color: headquarterRoot.currentTheme.colors.borderSubtle; border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: "?"; font.pixelSize: 10; color: headquarterRoot.currentTheme.colors.textMuted }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: headquarterRoot.triggerHelp("Wallpaper Assignments", "Static wallpapers map per workspace. Live wallpapers span globally across monitors without duplicate overhead (DEC-013).", parent.y)
                                    }
                                }
                            }

                            Row {
                                spacing: 14
                                Rectangle {
                                    width: 180
                                    height: 36
                                    radius: headquarterRoot.currentTheme.geometry.radiusPill
                                    color: headquarterRoot.currentTheme.colors.dominant

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Open Wallpaper Picker"
                                        font.family: headquarterRoot.currentTheme.typography.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: headquarterRoot.currentTheme.colors.textInverse
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (headquarterRoot.hostRef) {
                                                headquarterRoot.hostRef.openWallpaperPicker(headquarterRoot.monitorIndex)
                                            }
                                        }
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Active: " + (headquarterRoot.wallpaperService ? headquarterRoot.wallpaperService.getWallpaperForMonitor(headquarterRoot.monitorIndex) : "")
                                    font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                    font.pixelSize: 10
                                    color: headquarterRoot.currentTheme.colors.textSecondary
                                    elide: Text.ElideMiddle
                                    width: 320
                                }
                            }
                        }
                    }

                    // =================================================
                    // Category 3: WORKSPACES & MONITORS VIEW
                    // =================================================
                    Column {
                        width: parent.width
                        spacing: 24
                        visible: headquarterRoot.searchQuery.trim().length === 0 && headquarterRoot.currentCategory === "workspaces"

                        // Section 1: Workspaces 1..10
                        Column {
                            width: parent.width
                            spacing: 12

                            Row {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "10-WORKSPACE ARCHITECTURE (DEC-010)"
                                    font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                    font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                                    font.weight: Font.Bold
                                    color: headquarterRoot.currentTheme.colors.textPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 18; height: 18; radius: 9
                                    color: headquarterRoot.currentTheme.colors.surfaceHighlight
                                    border.color: headquarterRoot.currentTheme.colors.borderSubtle; border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: "?"; font.pixelSize: 10; color: headquarterRoot.currentTheme.colors.textMuted }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: headquarterRoot.triggerHelp("Workspaces 1–10", "BASEUS enforces exactly 10 workspaces per monitor (Super+1 through Super+0). Click a workspace to switch to it, or edit its custom label.", parent.y)
                                    }
                                }
                            }

                            Grid {
                                columns: 5
                                columnSpacing: 10
                                rowSpacing: 10
                                width: parent.width

                                Repeater {
                                    model: 10

                                    delegate: Rectangle {
                                        id: wsCardDelegate
                                        required property int index
                                        readonly property int wsNum: wsCardDelegate.index + 1
                                        readonly property bool isCurrentWs: headquarterRoot.workspaceModel && (headquarterRoot.workspaceModel.getActiveWorkspace(headquarterRoot.monitorIndex) === wsCardDelegate.wsNum)

                                        width: (contentColumn.width - 40) / 5
                                        height: 52
                                        radius: headquarterRoot.currentTheme.geometry.radiusMedium
                                        color: wsCardDelegate.isCurrentWs
                                            ? headquarterRoot.currentTheme.colors.dominant
                                            : headquarterRoot.currentTheme.colors.surfaceSolid
                                        border.color: wsCardDelegate.isCurrentWs
                                            ? headquarterRoot.currentTheme.colors.accent
                                            : headquarterRoot.currentTheme.colors.borderSubtle
                                        border.width: 1

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 2

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: "WS " + wsCardDelegate.wsNum
                                                font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                                color: wsCardDelegate.isCurrentWs
                                                    ? headquarterRoot.currentTheme.colors.textInverse
                                                    : headquarterRoot.currentTheme.colors.textPrimary
                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: (headquarterRoot.workspaceModel ? headquarterRoot.workspaceModel.getWorkspaceLabel(wsCardDelegate.wsNum) : "") || "Default"
                                                font.family: headquarterRoot.currentTheme.typography.fontFamily
                                                font.pixelSize: 10
                                                color: wsCardDelegate.isCurrentWs
                                                    ? headquarterRoot.currentTheme.colors.textInverse
                                                    : headquarterRoot.currentTheme.colors.textMuted
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (headquarterRoot.bridge) {
                                                    headquarterRoot.bridge.switchWorkspace(wsCardDelegate.wsNum, headquarterRoot.monitorIndex)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Section 2: Display Topology
                        Column {
                            width: parent.width
                            spacing: 12

                            Row {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "DISPLAY TOPOLOGY"
                                    font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                    font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                                    font.weight: Font.Bold
                                    color: headquarterRoot.currentTheme.colors.textPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 18; height: 18; radius: 9
                                    color: headquarterRoot.currentTheme.colors.surfaceHighlight
                                    border.color: headquarterRoot.currentTheme.colors.borderSubtle; border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: "?"; font.pixelSize: 10; color: headquarterRoot.currentTheme.colors.textMuted }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: headquarterRoot.triggerHelp("Display Topology", "Active monitors detected by the Wayland compositor. Workspaces and shell layers are instantiated per monitor.", parent.y)
                                    }
                                }
                            }

                            Repeater {
                                model: headquarterRoot.monitorModel ? headquarterRoot.monitorModel.monitors : []

                                delegate: Rectangle {
                                    id: monitorCardDelegate
                                    required property var modelData
                                    required property int index

                                    width: contentColumn.width
                                    height: 52
                                    radius: headquarterRoot.currentTheme.geometry.radiusMedium
                                    color: headquarterRoot.currentTheme.colors.surfaceSolid
                                    border.color: headquarterRoot.currentTheme.colors.borderSubtle
                                    border.width: 1

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        spacing: 16

                                        Text {
                                            text: monitorCardDelegate.modelData.name || ("Monitor " + monitorCardDelegate.index)
                                            font.family: headquarterRoot.currentTheme.typography.fontFamily
                                            font.pixelSize: headquarterRoot.currentTheme.typography.sizeBody
                                            font.weight: Font.DemiBold
                                            color: headquarterRoot.currentTheme.colors.textPrimary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: (monitorCardDelegate.modelData.width || 1920) + "x" + (monitorCardDelegate.modelData.height || 1080) + " @ " + Math.round(monitorCardDelegate.modelData.refreshRate || 60) + "Hz"
                                            font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                            font.pixelSize: 11
                                            color: headquarterRoot.currentTheme.colors.textSecondary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Item { width: 1; height: 1; Component.onCompleted: width = parent.width - 320 }

                                        Text {
                                            text: (headquarterRoot.monitorIndex === monitorCardDelegate.index) ? "ACTIVE TARGET" : ""
                                            font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                            font.pixelSize: 10
                                            font.weight: Font.Bold
                                            color: headquarterRoot.currentTheme.colors.accent
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // =================================================
                    // Category 4: SHORTCUTS & GESTURES VIEW (DEC-028)
                    // =================================================
                    Column {
                        width: parent.width
                        spacing: 24
                        visible: headquarterRoot.searchQuery.trim().length === 0 && headquarterRoot.currentCategory === "shortcuts"

                        // Header with Category Filter
                        Column {
                            width: parent.width
                            spacing: 12

                            Row {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "ACTION REGISTRY (DEC-028)"
                                    font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                    font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                                    font.weight: Font.Bold
                                    color: headquarterRoot.currentTheme.colors.textPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 18; height: 18; radius: 9
                                    color: headquarterRoot.currentTheme.colors.surfaceHighlight
                                    border.color: headquarterRoot.currentTheme.colors.borderSubtle; border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: "?"; font.pixelSize: 10; color: headquarterRoot.currentTheme.colors.textMuted }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: headquarterRoot.triggerHelp("Action Registry", "All actions follow Discover → Customize → Execute. View core navigation, workspace, and window action bindings.", parent.y)
                                    }
                                }
                            }

                            // Filter Chips
                            Row {
                                spacing: 8
                                Repeater {
                                    model: ["all", "navigation", "workspace", "window"]
                                    delegate: Rectangle {
                                        id: actionFilterDelegate
                                        required property string modelData
                                        width: 90
                                        height: 28
                                        radius: headquarterRoot.currentTheme.geometry.radiusPill
                                        color: (headquarterRoot.actionCategoryFilter === actionFilterDelegate.modelData)
                                            ? headquarterRoot.currentTheme.colors.dominant
                                            : headquarterRoot.currentTheme.colors.surfaceHighlight
                                        border.color: headquarterRoot.currentTheme.colors.borderSubtle
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: actionFilterDelegate.modelData.toUpperCase()
                                            font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                            font.pixelSize: 10
                                            color: (headquarterRoot.actionCategoryFilter === actionFilterDelegate.modelData)
                                                ? headquarterRoot.currentTheme.colors.textInverse
                                                : headquarterRoot.currentTheme.colors.textPrimary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: headquarterRoot.actionCategoryFilter = actionFilterDelegate.modelData
                                        }
                                    }
                                }
                            }
                        }

                        // Actions List
                        Column {
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: {
                                    if (!headquarterRoot.actionRegistry) return []
                                    var f = (headquarterRoot.actionCategoryFilter === "all") ? {} : { category: headquarterRoot.actionCategoryFilter }
                                    return headquarterRoot.actionRegistry.list(f)
                                }

                                delegate: Rectangle {
                                    id: actionItemDelegate
                                    required property var modelData
                                    width: contentColumn.width
                                    height: 48
                                    radius: headquarterRoot.currentTheme.geometry.radiusSmall
                                    color: headquarterRoot.currentTheme.colors.surfaceSolid
                                    border.color: headquarterRoot.currentTheme.colors.borderSubtle
                                    border.width: 1

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 14
                                        anchors.rightMargin: 14
                                        spacing: 12

                                        Text {
                                            text: actionItemDelegate.modelData.title
                                            font.family: headquarterRoot.currentTheme.typography.fontFamily
                                            font.pixelSize: headquarterRoot.currentTheme.typography.sizeBody
                                            font.weight: Font.DemiBold
                                            color: headquarterRoot.currentTheme.colors.textPrimary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: "·  " + actionItemDelegate.modelData.category
                                            font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                            font.pixelSize: 10
                                            color: headquarterRoot.currentTheme.colors.textMuted
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Item { width: 1; height: 1; Component.onCompleted: width = parent.width - 240 }

                                        // Default Shortcut Chip
                                        Rectangle {
                                            visible: (actionItemDelegate.modelData.defaultShortcut && actionItemDelegate.modelData.defaultShortcut.length > 0)
                                            height: 24
                                            width: shortcutLabel.implicitWidth + 14
                                            radius: 4
                                            color: headquarterRoot.currentTheme.colors.surfaceHighlight
                                            border.color: headquarterRoot.currentTheme.colors.borderSubtle
                                            border.width: 1
                                            anchors.verticalCenter: parent.verticalCenter

                                            Text {
                                                id: shortcutLabel
                                                anchors.centerIn: parent
                                                text: actionItemDelegate.modelData.defaultShortcut || ""
                                                font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                                font.pixelSize: 10
                                                color: headquarterRoot.currentTheme.colors.accent
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // =================================================
                    // Category 5: SYSTEM FEEDBACK VIEW (M3)
                    // =================================================
                    Column {
                        width: parent.width
                        spacing: 24
                        visible: headquarterRoot.searchQuery.trim().length === 0 && headquarterRoot.currentCategory === "feedback"

                        // Section 1: Notifications
                        Column {
                            width: parent.width
                            spacing: 12

                            Row {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "NOTIFICATIONS (DEC-020)"
                                    font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                    font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                                    font.weight: Font.Bold
                                    color: headquarterRoot.currentTheme.colors.textPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 18; height: 18; radius: 9
                                    color: headquarterRoot.currentTheme.colors.surfaceHighlight
                                    border.color: headquarterRoot.currentTheme.colors.borderSubtle; border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: "?"; font.pixelSize: 10; color: headquarterRoot.currentTheme.colors.textMuted }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: headquarterRoot.triggerHelp("Notifications", "Floating top-left placement with 70% icon backdrop, hover-pauseable timeout, and 0x0 click-through idle hitmask.", parent.y)
                                    }
                                }
                            }

                            Row {
                                spacing: 10
                                Repeater {
                                    model: [2000, 3000, 5000, 8000]
                                    delegate: Rectangle {
                                        id: timeoutOptionDelegate
                                        required property int modelData
                                        width: 90
                                        height: 32
                                        radius: headquarterRoot.currentTheme.geometry.radiusPill
                                        color: (headquarterRoot.notificationModel && headquarterRoot.notificationModel.defaultTimeout === timeoutOptionDelegate.modelData)
                                            ? headquarterRoot.currentTheme.colors.dominant
                                            : headquarterRoot.currentTheme.colors.surfaceHighlight
                                        border.color: headquarterRoot.currentTheme.colors.borderSubtle
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: timeoutOptionDelegate.modelData + "ms"
                                            font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                            font.pixelSize: 10
                                            color: (headquarterRoot.notificationModel && headquarterRoot.notificationModel.defaultTimeout === timeoutOptionDelegate.modelData)
                                                ? headquarterRoot.currentTheme.colors.textInverse
                                                : headquarterRoot.currentTheme.colors.textPrimary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (headquarterRoot.notificationModel) {
                                                    headquarterRoot.notificationModel.defaultTimeout = timeoutOptionDelegate.modelData
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Hold to Silence Toggle
                            Row {
                                spacing: 12
                                Rectangle {
                                    width: 150
                                    height: 32
                                    radius: headquarterRoot.currentTheme.geometry.radiusPill
                                    color: (headquarterRoot.notificationModel && headquarterRoot.notificationModel.silenced)
                                        ? headquarterRoot.currentTheme.colors.accent
                                        : headquarterRoot.currentTheme.colors.surfaceHighlight
                                    border.color: headquarterRoot.currentTheme.colors.borderSubtle
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: (headquarterRoot.notificationModel && headquarterRoot.notificationModel.silenced)
                                            ? "Notifications Silenced"
                                            : "Silence Notifications"
                                        font.family: headquarterRoot.currentTheme.typography.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: (headquarterRoot.notificationModel && headquarterRoot.notificationModel.silenced)
                                            ? headquarterRoot.currentTheme.colors.textInverse
                                            : headquarterRoot.currentTheme.colors.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (headquarterRoot.notificationModel) {
                                                if (headquarterRoot.notificationModel.silenced) {
                                                    headquarterRoot.notificationModel.unsilence()
                                                } else {
                                                    headquarterRoot.notificationModel.silence()
                                                }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "1200ms hold on any notification also activates silence"
                                    font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                    font.pixelSize: 10
                                    color: headquarterRoot.currentTheme.colors.textMuted
                                }
                            }
                        }

                        // Section 2: Audio & Brightness OSD (DEC-021)
                        Column {
                            width: parent.width
                            spacing: 12

                            Row {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "TOP ISLAND OSD (DEC-021)"
                                    font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                    font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                                    font.weight: Font.Bold
                                    color: headquarterRoot.currentTheme.colors.textPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 18; height: 18; radius: 9
                                    color: headquarterRoot.currentTheme.colors.surfaceHighlight
                                    border.color: headquarterRoot.currentTheme.colors.borderSubtle; border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: "?"; font.pixelSize: 10; color: headquarterRoot.currentTheme.colors.textMuted }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: headquarterRoot.triggerHelp("Top Island OSD", "Volume and brightness indicators drop smoothly from the Top Island notch with rapid in-place value morphing and 100% click-through hitmask.", parent.y)
                                    }
                                }
                            }

                            Text {
                                text: "1800ms auto-hide delay  ·  Bubble-drop origin anchored to Top Island notch  ·  Zero input blocking"
                                font.family: headquarterRoot.currentTheme.typography.fontFamily
                                font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                                color: headquarterRoot.currentTheme.colors.textSecondary
                            }
                        }

                        // Section 3: MPRIS Media Integration (DEC-026, DEC-039)
                        Column {
                            width: parent.width
                            spacing: 12

                            Row {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "MEDIA PLAYER & STRICT DEC-039"
                                    font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                    font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                                    font.weight: Font.Bold
                                    color: headquarterRoot.currentTheme.colors.textPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 18; height: 18; radius: 9
                                    color: headquarterRoot.currentTheme.colors.surfaceHighlight
                                    border.color: headquarterRoot.currentTheme.colors.borderSubtle; border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: "?"; font.pixelSize: 10; color: headquarterRoot.currentTheme.colors.textMuted }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: headquarterRoot.triggerHelp("Strict DEC-039", "Track changes and playback updates strictly NEVER generate desktop notifications. Controlled via Top Island and MediaWidget.", parent.y)
                                    }
                                }
                            }

                            Text {
                                text: "Active session: " + (headquarterRoot.mediaService ? headquarterRoot.mediaService.activePlayerName : "none") + " (" + (headquarterRoot.mediaService ? headquarterRoot.mediaService.playbackStatus : "Stopped") + ")"
                                font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                font.pixelSize: 11
                                color: headquarterRoot.currentTheme.colors.textSecondary
                            }
                        }
                    }

                    // =================================================
                    // Category 6: ABOUT BASEUS VIEW
                    // =================================================
                    Column {
                        width: parent.width
                        spacing: 24
                        visible: headquarterRoot.searchQuery.trim().length === 0 && headquarterRoot.currentCategory === "about"

                        Column {
                            width: parent.width
                            spacing: 6

                            Text {
                                text: "BASEUS 0.4.0 (MILESTONE M4)"
                                font.family: headquarterRoot.currentTheme.typography.fontFamily
                                font.pixelSize: 22
                                font.weight: Font.Bold
                                color: headquarterRoot.currentTheme.colors.textPrimary
                            }

                            Text {
                                text: "Freeform-first Wayland desktop environment for Linux.\nBuilt on Quickshell & Hyprland with Wabi-sabi restraint and cybernetic velocity."
                                font.family: headquarterRoot.currentTheme.typography.fontFamily
                                font.pixelSize: headquarterRoot.currentTheme.typography.sizeBody
                                color: headquarterRoot.currentTheme.colors.textSecondary
                            }

                            Text {
                                text: "Copyright (c) 2026 xoradesu · MIT License"
                                font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                font.pixelSize: 11
                                color: headquarterRoot.currentTheme.colors.textMuted
                            }
                        }

                        // Subsystem Health Status
                        Column {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "CORE SUBSYSTEM STATUS"
                                font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                font.pixelSize: headquarterRoot.currentTheme.typography.sizeMicro
                                font.weight: Font.Bold
                                color: headquarterRoot.currentTheme.colors.textMuted
                            }

                            Repeater {
                                model: [
                                    { "name": "Hyprland Compositor Bridge", "status": (headquarterRoot.bridge && headquarterRoot.bridge.connected) ? "Connected (Live)" : "Mock Simulation", "ok": true },
                                    { "name": "Audio Stack (PipeWire / WirePlumber)", "status": (headquarterRoot.audioService && headquarterRoot.audioService.pipewireAvailable) ? "PipeWire Active" : "Emulated Fallback", "ok": true },
                                    { "name": "Media Player Stack (MPRIS)", "status": (headquarterRoot.mediaService && headquarterRoot.mediaService.hasPlayer) ? "Session Active" : "Mock Ready", "ok": true },
                                    { "name": "Palette Pipeline (Matugen)", "status": "Cached / Contrast Validated", "ok": true },
                                    { "name": "Wallpaper Engine (DEC-013)", "status": "10-WS Static + Global Live", "ok": true }
                                ]

                                delegate: Rectangle {
                                    id: subsystemItemDelegate
                                    required property var modelData
                                    width: contentColumn.width
                                    height: 40
                                    radius: headquarterRoot.currentTheme.geometry.radiusSmall
                                    color: headquarterRoot.currentTheme.colors.surfaceSolid
                                    border.color: headquarterRoot.currentTheme.colors.borderSubtle
                                    border.width: 1

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 14
                                        anchors.rightMargin: 14
                                        spacing: 12

                                        Rectangle {
                                            width: 8; height: 8; radius: 4
                                            color: subsystemItemDelegate.modelData.ok ? headquarterRoot.currentTheme.colors.accent : headquarterRoot.currentTheme.colors.textMuted
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: subsystemItemDelegate.modelData.name
                                            font.family: headquarterRoot.currentTheme.typography.fontFamily
                                            font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                                            font.weight: Font.DemiBold
                                            color: headquarterRoot.currentTheme.colors.textPrimary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Item { width: 1; height: 1; Component.onCompleted: width = parent.width - 240 }

                                        Text {
                                            text: subsystemItemDelegate.modelData.status
                                            font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                            font.pixelSize: 10
                                            color: headquarterRoot.currentTheme.colors.textSecondary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =========================================================
            // Contextual Help Bubble (MASTER.md §21, DESIGN.md §25)
            // =========================================================
            // Positioned anchored to the right of main content without layout shift.
            Rectangle {
                id: helpBubble
                visible: headquarterRoot.activeHelpVisible
                width: 240
                height: helpContentCol.implicitHeight + 24
                x: mainContentArea.width - width - 24
                y: headquarterRoot.activeHelpY
                radius: headquarterRoot.currentTheme.geometry.radiusMedium
                color: headquarterRoot.currentTheme.colors.surfaceHighlight
                border.color: headquarterRoot.currentTheme.colors.borderSubtle
                border.width: 1
                z: 10

                Column {
                    id: helpContentCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    Row {
                        width: parent.width

                        Text {
                            text: "WHAT DOES THIS DO?"
                            font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                            font.pixelSize: headquarterRoot.currentTheme.typography.sizeMicro
                            font.weight: Font.Bold
                            color: headquarterRoot.currentTheme.colors.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item { width: 1; height: 1; Component.onCompleted: width = parent.width - 150 }

                        Text {
                            text: "×"
                            font.family: headquarterRoot.currentTheme.typography.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: headquarterRoot.currentTheme.colors.textMuted
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: headquarterRoot.dismissHelp()
                            }
                        }
                    }

                    Text {
                        text: headquarterRoot.activeHelpTitle
                        width: parent.width
                        wrapMode: Text.WordWrap
                        font.family: headquarterRoot.currentTheme.typography.fontFamily
                        font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                        font.weight: Font.DemiBold
                        color: headquarterRoot.currentTheme.colors.textPrimary
                    }

                    Text {
                        text: headquarterRoot.activeHelpText
                        width: parent.width
                        wrapMode: Text.WordWrap
                        font.family: headquarterRoot.currentTheme.typography.fontFamily
                        font.pixelSize: headquarterRoot.currentTheme.typography.sizeCaption
                        color: headquarterRoot.currentTheme.colors.textSecondary
                    }
                }
            }
        }

        // -----------------------------------------------------
        // Persistent Right Sidebar (DEC-019, DESIGN.md §24)
        // -----------------------------------------------------
        Rectangle {
            id: rightSidebar
            width: 240
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            color: headquarterRoot.currentTheme.colors.surfaceSolid
            border.color: headquarterRoot.currentTheme.colors.borderSubtle
            border.width: 1

            // Top-left ICR concave fillet (junction to screen top bezel)
            ThemeModule.InverseCorner {
                anchors.top: parent.top
                anchors.right: parent.left
                cornerRadius: headquarterRoot.currentTheme.geometry.inverseCornerRadius
                fillColor: headquarterRoot.currentTheme.colors.surfaceSolid
                position: "top-left"
            }

            // Bottom-left ICR concave fillet (junction to screen bottom bezel)
            ThemeModule.InverseCorner {
                anchors.bottom: parent.bottom
                anchors.right: parent.left
                cornerRadius: headquarterRoot.currentTheme.geometry.inverseCornerRadius
                fillColor: headquarterRoot.currentTheme.colors.surfaceSolid
                position: "bottom-left"
            }

            // Sidebar Header
            Item {
                id: sidebarHeader
                height: 72
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: "BASEUS"
                        font.family: headquarterRoot.currentTheme.typography.fontFamily
                        font.pixelSize: headquarterRoot.currentTheme.typography.sizeHeadline
                        font.weight: Font.Bold
                        color: headquarterRoot.currentTheme.colors.textPrimary
                    }

                    Text {
                        text: "HEADQUARTER"
                        font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                        font.pixelSize: headquarterRoot.currentTheme.typography.sizeMicro
                        font.weight: Font.Bold
                        color: headquarterRoot.currentTheme.colors.accent
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: headquarterRoot.currentTheme.colors.borderSubtle
                }
            }

            // Sidebar Category Items List
            Column {
                anchors.top: sidebarHeader.bottom
                anchors.bottom: sidebarFooter.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 16
                spacing: 4

                Repeater {
                    model: [
                        { "id": "home", "label": "Home", "num": "01" },
                        { "id": "appearance", "label": "Appearance", "num": "02" },
                        { "id": "workspaces", "label": "Workspaces & Displays", "num": "03" },
                        { "id": "shortcuts", "label": "Shortcuts & Gestures", "num": "04" },
                        { "id": "feedback", "label": "System Feedback", "num": "05" },
                        { "id": "about", "label": "About BASEUS", "num": "06" }
                    ]

                    delegate: Rectangle {
                        id: sidebarNavDelegate
                        required property var modelData
                        readonly property bool isSelected: headquarterRoot.currentCategory === sidebarNavDelegate.modelData.id && headquarterRoot.searchQuery.trim().length === 0

                        width: rightSidebar.width - 24
                        height: 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: headquarterRoot.currentTheme.geometry.radiusMedium
                        color: sidebarNavDelegate.isSelected
                            ? headquarterRoot.currentTheme.colors.stateSelected
                            : (sidebarItemHover.pressed
                                ? headquarterRoot.currentTheme.colors.statePressed
                                : (sidebarItemHover.containsMouse ? headquarterRoot.currentTheme.colors.stateHover : "transparent"))
                        border.color: sidebarNavDelegate.isSelected ? headquarterRoot.currentTheme.colors.outlineVariant : "transparent"
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: sidebarNavDelegate.modelData.num
                                font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                font.pixelSize: 10
                                color: sidebarNavDelegate.isSelected
                                    ? headquarterRoot.currentTheme.colors.accent
                                    : headquarterRoot.currentTheme.colors.textMuted
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: sidebarNavDelegate.modelData.label
                                font.family: headquarterRoot.currentTheme.typography.fontFamily
                                font.pixelSize: headquarterRoot.currentTheme.typography.sizeBody
                                font.weight: sidebarNavDelegate.isSelected ? Font.DemiBold : Font.Normal
                                color: sidebarNavDelegate.isSelected
                                    ? headquarterRoot.currentTheme.colors.textPrimary
                                    : headquarterRoot.currentTheme.colors.textSecondary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: sidebarItemHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                headquarterRoot.setCategory(sidebarNavDelegate.modelData.id)
                            }
                        }
                    }
                }
            }

            // Sidebar Footer: Dismiss Button
            Item {
                id: sidebarFooter
                height: 64
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: headquarterRoot.currentTheme.colors.outlineVariant
                }

                Rectangle {
                    width: parent.width - 32
                    height: 36
                    anchors.centerIn: parent
                    radius: headquarterRoot.currentTheme.geometry.radiusPill
                    color: footerCloseHover.pressed
                        ? headquarterRoot.currentTheme.colors.statePressed
                        : (footerCloseHover.containsMouse ? headquarterRoot.currentTheme.colors.stateHover : headquarterRoot.currentTheme.colors.surfaceContainerHighest)
                    border.color: headquarterRoot.currentTheme.colors.outlineVariant
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 28; height: 18; radius: 3
                            color: headquarterRoot.currentTheme.colors.surfaceContainerLowest
                            border.color: headquarterRoot.currentTheme.colors.outlineVariant
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.centerIn: parent
                                text: "ESC"
                                font.family: headquarterRoot.currentTheme.typography.fontFamilyMono
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                color: headquarterRoot.currentTheme.colors.textMuted
                            }
                        }

                        Text {
                            text: "Close Headquarter"
                            font.family: headquarterRoot.currentTheme.typography.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: headquarterRoot.currentTheme.colors.textPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: footerCloseHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: headquarterRoot.close()
                    }
                }
            }
        }
    }
}
