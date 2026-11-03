pragma ComponentBehavior: Bound

// BASEUS — Command Center Surface
// Copyright (c) 2026 xoradesu — MIT License
//
// Governed by:
//   - MASTER.md §13 (Command Center is universal action/search launcher)
//   - DESIGN.md §19 (Command Center Visual Design)
//   - DEC-017 (Universal action/search surface, slightly above center, fit-content)
//   - ANTI-SLOP.md §6.4, §6.5 (Solid Wabi-sabi surface, zero blur/glass/glow)
//
// Routing Engine:
//   - `>` prefix: Direct action execution routed to ActionRegistry (DEC-028)
//   - `?help`: Inline quick reference of supported prefixes and shortcuts
//   - plain text: Application search matching running windows and pinned apps

import QtQuick
import "../theme" as ThemeModule

Item {
    id: commandCenterRoot

    // =========================================================
    // Dependencies & Configuration
    // =========================================================
    property var theme: null
    readonly property ThemeModule.Theme defaultTheme: ThemeModule.Theme {}
    readonly property ThemeModule.Theme currentTheme: commandCenterRoot.theme ? commandCenterRoot.theme : commandCenterRoot.defaultTheme

    property var actionRegistry: null
    property var windowModel: null
    property var workspaceModel: null
    property var config: null
    property var bridge: null
    property int monitorIndex: 0

    // =========================================================
    // State & Visibility
    // =========================================================
    property bool active: false
    property string query: ""
    property int selectedIndex: 0
    property var items: []

    readonly property int itemCount: commandCenterRoot.items ? commandCenterRoot.items.length : 0
    readonly property string currentMode: {
        var t = commandCenterRoot.query.trim()
        if (t.startsWith(">")) return "action"
        if (t.startsWith("?") || t.toLowerCase() === "help") return "help"
        return "app"
    }

    signal dismissRequested()
    signal actionExecuted(string actionId, bool success)

    // =========================================================
    // Public Control API
    // =========================================================

    function openWithPrefix(prefix: string) {
        commandCenterRoot.active = true
        var initial = (typeof prefix === "string") ? prefix : ""
        commandCenterRoot.query = initial
        searchInput.text = initial
        searchInput.cursorPosition = initial.length
        commandCenterRoot.refreshResults()
        commandCenterRoot.selectedIndex = 0
        searchInput.forceActiveFocus()
    }

    function close() {
        commandCenterRoot.active = false
        commandCenterRoot.query = ""
        searchInput.text = ""
        commandCenterRoot.items = []
        commandCenterRoot.selectedIndex = 0
        searchInput.focus = false
    }

    function setInput(text: string) {
        var str = (typeof text === "string") ? text : ""
        commandCenterRoot.query = str
        searchInput.text = str
        searchInput.cursorPosition = str.length
        commandCenterRoot.refreshResults()
    }

    function selectNext() {
        if (commandCenterRoot.itemCount > 0) {
            commandCenterRoot.selectedIndex = (commandCenterRoot.selectedIndex + 1) % commandCenterRoot.itemCount
            resultsList.positionViewAtIndex(commandCenterRoot.selectedIndex, ListView.Contain)
        }
    }

    function selectPrevious() {
        if (commandCenterRoot.itemCount > 0) {
            commandCenterRoot.selectedIndex = (commandCenterRoot.selectedIndex - 1 + commandCenterRoot.itemCount) % commandCenterRoot.itemCount
            resultsList.positionViewAtIndex(commandCenterRoot.selectedIndex, ListView.Contain)
        }
    }

    function executeSelected(): bool {
        if (commandCenterRoot.selectedIndex >= 0 && commandCenterRoot.selectedIndex < commandCenterRoot.itemCount) {
            return commandCenterRoot.executeItem(commandCenterRoot.items[commandCenterRoot.selectedIndex])
        }
        return false
    }

    function executeIndex(index: int): bool {
        if (index >= 0 && index < commandCenterRoot.itemCount) {
            return commandCenterRoot.executeItem(commandCenterRoot.items[index])
        }
        return false
    }

    function executeItem(item: var): bool {
        if (!item) return false
        var ok = false

        if (item.type === "prefix_template") {
            if (item.template !== undefined) {
                commandCenterRoot.setInput(item.template)
                return true // Stays open, switched to that prefix mode
            }
            return false
        }

        // Dismiss Command Center overlay first so desktop context is restored
        // before executing target action or raising window
        commandCenterRoot.dismissRequested()

        if (item.type === "action") {
            if (commandCenterRoot.actionRegistry && item.actionId) {
                var res = commandCenterRoot.actionRegistry.execute(item.actionId)
                ok = res && Boolean(res.ok)
                commandCenterRoot.actionExecuted(item.actionId, ok)
            }
        } else if (item.type === "window") {
            if (commandCenterRoot.bridge && item.address) {
                if (commandCenterRoot.workspaceModel && typeof item.workspaceId === "number") {
                    commandCenterRoot.workspaceModel.switchTo(item.workspaceId, item.monitorIndex)
                }
                commandCenterRoot.bridge.focusWindow(item.address)
                ok = true
            }
        } else if (item.type === "app") {
            if (commandCenterRoot.bridge && item.command) {
                commandCenterRoot.bridge.launchApp(item.command)
                ok = true
            }
        }

        return ok
    }

    function getSnapshot(): var {
        var sel = (commandCenterRoot.selectedIndex >= 0 && commandCenterRoot.selectedIndex < commandCenterRoot.itemCount)
            ? commandCenterRoot.items[commandCenterRoot.selectedIndex]
            : null
        return {
            active: commandCenterRoot.active,
            query: commandCenterRoot.query,
            mode: commandCenterRoot.currentMode,
            itemCount: commandCenterRoot.itemCount,
            selectedIndex: commandCenterRoot.selectedIndex,
            selectedItem: sel,
            items: commandCenterRoot.items
        }
    }

    // =========================================================
    // Prefix Routing Engine
    // =========================================================

    function refreshResults() {
        var raw = searchInput.text
        commandCenterRoot.query = raw
        var trimmed = raw.trim()
        var nextItems = []

        if (trimmed.startsWith(">")) {
            // -------------------------------------------------
            // Mode A: Direct Action Execution via ActionRegistry
            // -------------------------------------------------
            var actQuery = trimmed.substring(1).trim().toLowerCase()
            var actList = commandCenterRoot.actionRegistry
                ? commandCenterRoot.actionRegistry.list({ query: actQuery })
                : []
            for (var i = 0; i < actList.length; i++) {
                var act = actList[i]
                nextItems.push({
                    id: act.id,
                    type: "action",
                    title: act.title,
                    description: act.description,
                    category: act.category ? act.category.toUpperCase() : "ACTION",
                    shortcut: act.defaultShortcut || "",
                    actionId: act.id,
                    enabled: act.enabled
                })
            }
        } else if (trimmed.startsWith("?") || trimmed.toLowerCase() === "help") {
            // -------------------------------------------------
            // Mode B: Inline Quick Reference & Prefix Help
            // -------------------------------------------------
            var helpQuery = trimmed.startsWith("?") ? trimmed.substring(1).trim().toLowerCase() : ""
            if (helpQuery === "help") helpQuery = ""
            var allHelp = [
                { id: "help_action", type: "prefix_template", title: "> <action>", description: "Execute system action or shortcut (e.g. >overview, >home)", category: "PREFIX", shortcut: "", template: ">" },
                { id: "help_app", type: "prefix_template", title: "<app name>", description: "Search, launch, or focus applications", category: "PREFIX", shortcut: "", template: "" },
                { id: "help_web", type: "prefix_template", title: "@web: <query>", description: "Web search query gateway (DEC-017)", category: "PREFIX", shortcut: "", template: "@web: " },
                { id: "help_settings", type: "prefix_template", title: "@settings: <topic>", description: "Desktop and system settings category (DEC-017)", category: "PREFIX", shortcut: "", template: "@settings: " },
                { id: "help_file", type: "prefix_template", title: "@file: <name>", description: "Local document and file search (DEC-017)", category: "PREFIX", shortcut: "", template: "@file: " },
                { id: "help_folder", type: "prefix_template", title: "@folder: <name>", description: "Local folder and directory search (DEC-017)", category: "PREFIX", shortcut: "", template: "@folder: " },
                { id: "help_home", type: "action", title: "Home", description: "Return to Workspace 1", category: "SHORTCUT", shortcut: "Super+D", actionId: "navigation.home" },
                { id: "help_overview", type: "action", title: "Overview", description: "Toggle Helicopter View", category: "SHORTCUT", shortcut: "Super+Tab", actionId: "navigation.overview" },
                { id: "help_back", type: "action", title: "Back", description: "Dismiss overlay or previous context", category: "SHORTCUT", shortcut: "Super+Escape", actionId: "navigation.back" },
                { id: "help_workspaces", type: "action", title: "Workspaces 1–10", description: "Direct per-monitor workspace navigation", category: "SHORTCUT", shortcut: "Super+1..0", actionId: "workspace.switch1" }
            ]
            for (var h = 0; h < allHelp.length; h++) {
                var hItem = allHelp[h]
                if (helpQuery.length === 0 ||
                    hItem.title.toLowerCase().indexOf(helpQuery) >= 0 ||
                    hItem.description.toLowerCase().indexOf(helpQuery) >= 0) {
                    nextItems.push(hItem)
                }
            }
        } else {
            // -------------------------------------------------
            // Mode C: Application Search (running windows & pins)
            // -------------------------------------------------
            var appQuery = trimmed.toLowerCase()

            // 1. Running client windows from WindowModel
            if (commandCenterRoot.windowModel && commandCenterRoot.windowModel.windows) {
                var wins = commandCenterRoot.windowModel.windows
                for (var w = 0; w < wins.length; w++) {
                    var win = wins[w]
                    if (!win || win.minimized) continue
                    var winTitle = win.title || win.appClass || ""
                    var winClass = win.appClass || ""
                    if (appQuery.length === 0 ||
                        winTitle.toLowerCase().indexOf(appQuery) >= 0 ||
                        winClass.toLowerCase().indexOf(appQuery) >= 0) {
                        nextItems.push({
                            id: "win_" + win.address,
                            type: "window",
                            title: winTitle,
                            description: "Active Window · Workspace " + win.workspace,
                            category: "WINDOW",
                            shortcut: "",
                            address: win.address,
                            workspaceId: win.workspace,
                            monitorIndex: win.monitor
                        })
                    }
                }
            }

            // 2. Pinned applications from Config
            var pinned = (commandCenterRoot.config && commandCenterRoot.config.dock && commandCenterRoot.config.dock.pinnedApps)
                ? commandCenterRoot.config.dock.pinnedApps
                : []
            for (var p = 0; p < pinned.length; p++) {
                var pin = pinned[p]
                var pTitle = pin.title || pin.id || ""
                var pCmd = pin.command || ""
                if (appQuery.length === 0 ||
                    pTitle.toLowerCase().indexOf(appQuery) >= 0 ||
                    pCmd.toLowerCase().indexOf(appQuery) >= 0) {
                    nextItems.push({
                        id: "pin_" + pin.id,
                        type: "app",
                        title: pTitle,
                        description: "Pinned Application · " + pCmd,
                        category: "APP",
                        shortcut: "",
                        command: pCmd
                    })
                }
            }
        }

        commandCenterRoot.items = nextItems
        if (commandCenterRoot.selectedIndex >= nextItems.length) {
            commandCenterRoot.selectedIndex = Math.max(0, nextItems.length - 1)
        }
    }

    onActiveChanged: {
        if (commandCenterRoot.active) {
            commandCenterRoot.refreshResults()
            commandCenterRoot.selectedIndex = 0
            searchInput.forceActiveFocus()
        }
    }

    // =========================================================
    // Backdrop Tap-to-Dismiss Handler
    // =========================================================
    Item {
        id: backdropArea
        anchors.fill: parent

        TapHandler {
            onTapped: commandCenterRoot.dismissRequested()
        }
    }

    // =========================================================
    // Center Modal Surface (DESIGN.md §19, DEC-017)
    // =========================================================
    Rectangle {
        id: surfaceBox
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(560, commandCenterRoot.width - (commandCenterRoot.currentTheme.spacing.edgeMargin * 2))

        readonly property int targetY: Math.round((commandCenterRoot.height - surfaceBox.height) * 0.38)
        readonly property int maxHeight: Math.min(480, commandCenterRoot.height - 80)

        // Dynamic fit-content height up to maximum threshold
        height: Math.min(surfaceBox.maxHeight, mainCol.implicitHeight)
        y: commandCenterRoot.active ? surfaceBox.targetY : (surfaceBox.targetY - 16)
        opacity: commandCenterRoot.active ? 1.0 : 0.0
        visible: opacity > 0.0
        clip: true

        // Solid Wabi-sabi aesthetics (surfaceContainerHigh floating overlay)
        color: commandCenterRoot.currentTheme.colors.surfaceContainerHigh
        border.width: commandCenterRoot.currentTheme.geometry.borderWidth
        border.color: commandCenterRoot.currentTheme.colors.outline
        radius: commandCenterRoot.currentTheme.geometry.floatingRadius

        // Top-to-bottom curtain reveal motion (asymmetric enter/exit)
        Behavior on opacity {
            NumberAnimation {
                duration: commandCenterRoot.active ? commandCenterRoot.currentTheme.motion.durationNormal : commandCenterRoot.currentTheme.motion.durationFast
                easing.type: commandCenterRoot.active ? commandCenterRoot.currentTheme.motion.easingEnter : commandCenterRoot.currentTheme.motion.easingExit
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: commandCenterRoot.active ? commandCenterRoot.currentTheme.motion.durationNormal : commandCenterRoot.currentTheme.motion.durationFast
                easing.type: commandCenterRoot.active ? commandCenterRoot.currentTheme.motion.easingEnter : commandCenterRoot.currentTheme.motion.easingExit
            }
        }

        // TapHandler to prevent backdrop dismissal when clicking inside the surface
        TapHandler {}

        Column {
            id: mainCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            // -------------------------------------------------
            // Row 1: Search / Action Input Field
            // -------------------------------------------------
            Item {
                id: searchBarRow
                width: mainCol.width
                height: 52

                // Prefix glyph badge
                Rectangle {
                    id: prefixBadge
                    anchors.left: parent.left
                    anchors.leftMargin: commandCenterRoot.currentTheme.spacing.md
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    radius: commandCenterRoot.currentTheme.geometry.radiusSmall
                    color: commandCenterRoot.currentTheme.colors.surfaceHighlight
                    border.width: 1
                    border.color: (commandCenterRoot.currentMode === "action" || commandCenterRoot.currentMode === "help")
                        ? commandCenterRoot.currentTheme.colors.dominant
                        : commandCenterRoot.currentTheme.colors.borderSubtle

                    Text {
                        anchors.centerIn: parent
                        text: commandCenterRoot.currentMode === "action" ? ">" : (commandCenterRoot.currentMode === "help" ? "?" : "⌕")
                        font.family: commandCenterRoot.currentTheme.typography.fontFamilyMono
                        font.pixelSize: commandCenterRoot.currentTheme.typography.sizeBody
                        font.weight: Font.Bold
                        color: (commandCenterRoot.currentMode === "action" || commandCenterRoot.currentMode === "help")
                            ? commandCenterRoot.currentTheme.colors.dominant
                            : commandCenterRoot.currentTheme.colors.textMuted
                    }
                }

                // Search input field
                TextInput {
                    id: searchInput
                    anchors.left: prefixBadge.right
                    anchors.leftMargin: commandCenterRoot.currentTheme.spacing.sm
                    anchors.right: escChip.left
                    anchors.rightMargin: commandCenterRoot.currentTheme.spacing.sm
                    anchors.verticalCenter: parent.verticalCenter

                    font.family: commandCenterRoot.currentTheme.typography.fontFamily
                    font.pixelSize: commandCenterRoot.currentTheme.typography.sizeBody
                    color: commandCenterRoot.currentTheme.colors.textPrimary
                    selectByMouse: true
                    selectionColor: commandCenterRoot.currentTheme.colors.surfaceHighlight
                    selectedTextColor: commandCenterRoot.currentTheme.colors.textPrimary
                    clip: true

                    onTextChanged: commandCenterRoot.refreshResults()

                    Keys.onDownPressed: function(event) {
                        event.accepted = true
                        commandCenterRoot.selectNext()
                    }
                    Keys.onUpPressed: function(event) {
                        event.accepted = true
                        commandCenterRoot.selectPrevious()
                    }
                    Keys.onReturnPressed: function(event) {
                        event.accepted = true
                        commandCenterRoot.executeSelected()
                    }
                    Keys.onEnterPressed: function(event) {
                        event.accepted = true
                        commandCenterRoot.executeSelected()
                    }
                    Keys.onEscapePressed: function(event) {
                        event.accepted = true
                        commandCenterRoot.dismissRequested()
                    }

                    Text {
                        anchors.fill: parent
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search apps, or type '>' for actions, '?help' for quick reference..."
                        font: searchInput.font
                        color: commandCenterRoot.currentTheme.colors.textMuted
                        visible: searchInput.text.length === 0
                        elide: Text.ElideRight
                    }
                }

                // ESC dismissal indicator badge
                Rectangle {
                    id: escChip
                    anchors.right: parent.right
                    anchors.rightMargin: commandCenterRoot.currentTheme.spacing.md
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 20
                    radius: commandCenterRoot.currentTheme.geometry.concentricRadius(commandCenterRoot.currentTheme.geometry.floatingRadius, 4)
                    color: commandCenterRoot.currentTheme.colors.surfaceContainerLowest
                    border.width: 1
                    border.color: commandCenterRoot.currentTheme.colors.outlineVariant

                    Text {
                        anchors.centerIn: parent
                        text: "ESC"
                        font.family: commandCenterRoot.currentTheme.typography.fontFamilyMono
                        font.pixelSize: commandCenterRoot.currentTheme.typography.sizeMicro
                        color: commandCenterRoot.currentTheme.colors.textMuted
                    }
                }
            }

            // -------------------------------------------------
            // Row 2: Hairline Divider
            // -------------------------------------------------
            Rectangle {
                id: dividerLine
                width: mainCol.width
                height: 1
                color: commandCenterRoot.currentTheme.colors.outlineVariant
                visible: commandCenterRoot.itemCount > 0 || (commandCenterRoot.query.length > 0 && commandCenterRoot.itemCount === 0)
            }

            // -------------------------------------------------
            // Row 3: Empty State (when query yields 0 results)
            // -------------------------------------------------
            Item {
                id: emptyStateRow
                width: mainCol.width
                height: 48
                visible: commandCenterRoot.query.length > 0 && commandCenterRoot.itemCount === 0

                Text {
                    anchors.centerIn: parent
                    text: "No matching actions or applications"
                    font.family: commandCenterRoot.currentTheme.typography.fontFamily
                    font.pixelSize: commandCenterRoot.currentTheme.typography.sizeBody
                    color: commandCenterRoot.currentTheme.colors.textMuted
                }
            }

            // -------------------------------------------------
            // Row 4: Results List (scrolls internally when capped)
            // -------------------------------------------------
            Item {
                id: resultsContainer
                width: mainCol.width
                height: Math.min(resultsList.contentHeight, surfaceBox.maxHeight - searchBarRow.height - (footerRow.visible ? footerRow.height : 0) - (dividerLine.visible ? 1 : 0) - (footerDivider.visible ? 1 : 0))
                clip: true
                visible: commandCenterRoot.itemCount > 0

                ListView {
                    id: resultsList
                    anchors.fill: parent
                    boundsBehavior: Flickable.StopAtBounds
                    model: commandCenterRoot.items
                    currentIndex: commandCenterRoot.selectedIndex

                    delegate: Rectangle {
                        id: resultItemDelegate
                        required property var modelData
                        required property int index

                        width: resultsList.width
                        height: 48
                        color: (commandCenterRoot.selectedIndex === index)
                            ? commandCenterRoot.currentTheme.colors.stateSelected
                            : (itemHoverHandler.hovered ? commandCenterRoot.currentTheme.colors.stateHover : "transparent")

                        border.width: (commandCenterRoot.selectedIndex === index) ? 1 : 0
                        border.color: commandCenterRoot.currentTheme.colors.borderFocus

                        HoverHandler {
                            id: itemHoverHandler
                            onHoveredChanged: {
                                if (hovered) commandCenterRoot.selectedIndex = resultItemDelegate.index
                            }
                        }

                        TapHandler {
                            onTapped: commandCenterRoot.executeIndex(resultItemDelegate.index)
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: commandCenterRoot.currentTheme.spacing.md
                            anchors.right: parent.right
                            anchors.rightMargin: commandCenterRoot.currentTheme.spacing.md
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: commandCenterRoot.currentTheme.spacing.sm

                            // Category badge
                            Rectangle {
                                width: Math.max(categoryLabel.implicitWidth + 8, 36)
                                height: 20
                                anchors.verticalCenter: parent.verticalCenter
                                radius: commandCenterRoot.currentTheme.geometry.concentricRadius(commandCenterRoot.currentTheme.geometry.floatingRadius, 4)
                                color: commandCenterRoot.currentTheme.colors.surfaceContainerLowest
                                border.width: 1
                                border.color: commandCenterRoot.currentTheme.colors.outlineVariant

                                Text {
                                    id: categoryLabel
                                    anchors.centerIn: parent
                                    text: resultItemDelegate.modelData.category || ""
                                    font.family: commandCenterRoot.currentTheme.typography.fontFamilyMono
                                    font.pixelSize: commandCenterRoot.currentTheme.typography.sizeMicro
                                    color: (resultItemDelegate.modelData.category === "ACTION")
                                        ? commandCenterRoot.currentTheme.colors.dominant
                                        : commandCenterRoot.currentTheme.colors.textMuted
                                }
                            }

                            // Title & Description
                            Column {
                                width: parent.width - 50 - (shortcutChip.visible ? (shortcutChip.width + 12) : 0)
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    width: parent.width
                                    text: resultItemDelegate.modelData.title || ""
                                    font.family: commandCenterRoot.currentTheme.typography.fontFamily
                                    font.pixelSize: commandCenterRoot.currentTheme.typography.sizeBody
                                    font.weight: Font.Medium
                                    color: commandCenterRoot.currentTheme.colors.textPrimary
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: resultItemDelegate.modelData.description || ""
                                    font.family: commandCenterRoot.currentTheme.typography.fontFamily
                                    font.pixelSize: commandCenterRoot.currentTheme.typography.sizeCaption
                                    color: commandCenterRoot.currentTheme.colors.textSecondary
                                    elide: Text.ElideRight
                                    visible: text.length > 0
                                }
                            }

                            // Shortcut chip (if action carries a default shortcut)
                            Rectangle {
                                id: shortcutChip
                                width: shortcutLabel.implicitWidth + 10
                                height: 20
                                anchors.verticalCenter: parent.verticalCenter
                                radius: commandCenterRoot.currentTheme.geometry.concentricRadius(commandCenterRoot.currentTheme.geometry.floatingRadius, 4)
                                color: commandCenterRoot.currentTheme.colors.surfaceContainerLowest
                                border.width: 1
                                border.color: commandCenterRoot.currentTheme.colors.outlineVariant
                                visible: resultItemDelegate.modelData.shortcut && resultItemDelegate.modelData.shortcut.length > 0

                                Text {
                                    id: shortcutLabel
                                    anchors.centerIn: parent
                                    text: resultItemDelegate.modelData.shortcut || ""
                                    font.family: commandCenterRoot.currentTheme.typography.fontFamilyMono
                                    font.pixelSize: commandCenterRoot.currentTheme.typography.sizeMicro
                                    color: commandCenterRoot.currentTheme.colors.textMuted
                                }
                            }
                        }
                    }
                }
            }

            // -------------------------------------------------
            // Row 5: Hairline Divider Before Footer
            // -------------------------------------------------
            Rectangle {
                id: footerDivider
                width: mainCol.width
                height: 1
                color: commandCenterRoot.currentTheme.colors.outlineVariant
                visible: commandCenterRoot.itemCount > 0
            }

            // -------------------------------------------------
            // Row 6: Calm Status Footer
            // -------------------------------------------------
            Item {
                id: footerRow
                width: mainCol.width
                height: 28
                visible: commandCenterRoot.itemCount > 0

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: commandCenterRoot.currentTheme.spacing.md
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↑↓ Navigate   ↵ Execute   ESC Close"
                    font.family: commandCenterRoot.currentTheme.typography.fontFamilyMono
                    font.pixelSize: commandCenterRoot.currentTheme.typography.sizeMicro
                    color: commandCenterRoot.currentTheme.colors.textMuted
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: commandCenterRoot.currentTheme.spacing.md
                    anchors.verticalCenter: parent.verticalCenter
                    text: commandCenterRoot.itemCount + (commandCenterRoot.itemCount === 1 ? " result" : " results")
                    font.family: commandCenterRoot.currentTheme.typography.fontFamilyMono
                    font.pixelSize: commandCenterRoot.currentTheme.typography.sizeMicro
                    color: commandCenterRoot.currentTheme.colors.textMuted
                }
            }
        }
    }
}
