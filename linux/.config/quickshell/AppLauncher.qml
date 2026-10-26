import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

PanelWindow {
    id: root

    property bool shown: false
    property string queryText: ""
    property int selectedIndex: 0
    property var filteredApps: []
    property var usageByPrefix: ({})

    readonly property int launcherWidth: 760

    function normalized(text) {
        return (text || "").toLowerCase().trim()
    }

    function textScore(text, query, prefixWeight, containsWeight) {
        if (!text || query.length === 0) return -1

        const value = text.toLowerCase()
        if (value.startsWith(query)) {
            return prefixWeight - Math.min(value.length, 80) * 0.01
        }

        const at = value.indexOf(query)
        if (at >= 0) {
            return containsWeight - at * 0.08
        }

        return -1
    }

    function scoreEntry(entry, query) {
        if (!entry) return -1
        if (query.length === 0) return 1

        let best = -1
        best = Math.max(best, textScore(entry.name, query, 120, 85))
        best = Math.max(best, textScore(entry.genericName, query, 95, 65))
        best = Math.max(best, textScore(entry.id, query, 85, 55))
        best = Math.max(best, textScore(entry.comment, query, 65, 40))

        if (entry.keywords) {
            for (let i = 0; i < entry.keywords.length; i++) {
                best = Math.max(best, textScore(entry.keywords[i], query, 85, 50))
            }
        }

        return best
    }

    function usageFor(prefix, appId) {
        const bucket = usageByPrefix[prefix]
        if (!bucket) return 0
        return bucket[appId] || 0
    }

    function rebuildResults() {
        const query = normalized(queryText)
        const source = DesktopEntries.applications.values || []
        const scored = []

        for (let i = 0; i < source.length; i++) {
            const entry = source[i]
            const match = scoreEntry(entry, query)
            if (match < 0) continue

            const usage = usageFor(query, entry.id)
            const globalUsage = usageFor("", entry.id)
            const usageBonus = usage * 1000 + globalUsage * 30

            scored.push({
                entry: entry,
                score: match + usageBonus,
                usage: usage,
                globalUsage: globalUsage
            })
        }

        scored.sort((a, b) => {
            if (b.score !== a.score) return b.score - a.score
            if (b.usage !== a.usage) return b.usage - a.usage
            if (b.globalUsage !== a.globalUsage) return b.globalUsage - a.globalUsage
            return a.entry.name.localeCompare(b.entry.name)
        })

        filteredApps = scored

        if (filteredApps.length === 0) {
            selectedIndex = 0
        } else if (selectedIndex >= filteredApps.length) {
            selectedIndex = filteredApps.length - 1
        }
    }

    function moveSelection(delta) {
        if (filteredApps.length === 0) return
        let next = selectedIndex + delta
        if (next < 0) next = filteredApps.length - 1
        if (next >= filteredApps.length) next = 0
        selectedIndex = next
    }

    function rememberSelection(entry) {
        if (!entry) return

        const query = normalized(queryText)
        const updated = Object.assign({}, usageByPrefix)

        function bump(prefix) {
            const bucket = Object.assign({}, updated[prefix] || {})
            bucket[entry.id] = (bucket[entry.id] || 0) + 1
            updated[prefix] = bucket
        }

        bump("")
        for (let i = 1; i <= query.length; i++) {
            bump(query.slice(0, i))
        }

        usageByPrefix = updated
        usageData.usageByPrefix = updated
    }

    function launchIndex(index) {
        if (index < 0 || index >= filteredApps.length) return

        const item = filteredApps[index]
        rememberSelection(item.entry)
        item.entry.execute()
        closeLauncher()
    }

    function openLauncher() {
        if (shown) return
        shown = true
        queryText = ""
        selectedIndex = 0
        rebuildResults()
        focusTimer.restart()
    }

    function closeLauncher() {
        shown = false
    }

    function toggleLauncher() {
        if (shown) closeLauncher()
        else openLauncher()
    }

    function containsScreenPoint(x, y) {
        if (!root.screen) return false
        const winX = root.screen.x + root.margins.left
        const winY = root.screen.y + root.margins.top
        return x >= winX && x <= winX + root.width &&
               y >= winY && y <= winY + root.height
    }

    function checkClick() {
        if (!shown || !visible) return
        cursorProcess.running = true
    }

    anchors {
        top: true
        left: true
    }
    margins {
        left: root.screen ? Math.max(Math.floor((root.screen.width - root.launcherWidth) / 2), 0) : 0
        top: root.screen ? Math.max(Math.floor((root.screen.height - root.implicitHeight) / 2), 0) : 0
    }

    implicitWidth: launcherWidth
    implicitHeight: launcherPanel.implicitHeight
    exclusiveZone: 0
    color: "transparent"
    visible: shown

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    GlobalShortcut {
        name: "launcher"
        description: "Open quickshell launcher"
        onPressed: root.toggleLauncher()
    }

    IpcHandler {
        target: "launcher"
        function checkClick(): void {
            root.checkClick()
        }
        function open(): void {
            root.openLauncher()
        }
        function close(): void {
            root.closeLauncher()
        }
        function toggle(): void {
            root.toggleLauncher()
        }
    }

    Process {
        id: cursorProcess
        command: ["hyprctl", "cursorpos"]

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(",")
                if (parts.length !== 2) return

                const x = parseInt(parts[0].trim())
                const y = parseInt(parts[1].trim())
                if (!root.containsScreenPoint(x, y)) root.closeLauncher()
            }
        }
    }

    FileView {
        id: usageStore
        path: Qt.resolvedUrl("app-launcher-usage.json")
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: {
            root.usageByPrefix = usageData.usageByPrefix || ({})
            root.rebuildResults()
        }

        JsonAdapter {
            id: usageData
            property var usageByPrefix: ({})
        }
    }

    Connections {
        target: usageData
        function onUsageByPrefixChanged() {
            root.usageByPrefix = usageData.usageByPrefix || ({})
            root.rebuildResults()
        }
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.rebuildResults()
        }
    }

    Timer {
        id: focusTimer
        interval: 1
        repeat: false
        onTriggered: searchInput.forceActiveFocus()
    }

    Rectangle {
        id: launcherPanel
        width: root.launcherWidth
        implicitHeight: contentColumn.implicitHeight + 24
        radius: 18
        color: "#101010"
        border.width: 1
        border.color: "#2C2C2C"

        Column {
            id: contentColumn
            anchors {
                fill: parent
                margins: 12
            }
            spacing: 10

            Rectangle {
                width: parent.width
                height: 44
                radius: 12
                color: "#161616"
                border.width: 1
                border.color: searchInput.activeFocus ? "#CF577C" : "#2D2D2D" // was "#FD7C40"

                Behavior on border.color {
                    ColorAnimation {
                        duration: 140
                    }
                }

                TextInput {
                    id: searchInput
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }
                    color: "#D6D6D6"
                    selectionColor: "#6E2043" // was "#A23D0D"
                    selectedTextColor: "#F8F8F8"
                    font.pixelSize: 18
                    verticalAlignment: TextInput.AlignVCenter
                    focus: root.shown
                    text: root.queryText
                    clip: true

                    onTextChanged: {
                        root.queryText = text
                        root.selectedIndex = 0
                        root.rebuildResults()
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.closeLauncher()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Down) {
                            root.moveSelection(1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            root.moveSelection(-1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.launchIndex(root.selectedIndex)
                            event.accepted = true
                        }
                    }
                }

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    text: "Applications"
                    color: "#666666"
                    visible: searchInput.text.length === 0
                    font.pixelSize: 16
                }
            }

            ListView {
                id: resultsView
                width: parent.width
                height: Math.min(contentHeight, 4 * 56)
                model: root.filteredApps
                spacing: 4
                clip: true
                interactive: contentHeight > height

                delegate: Rectangle {
                    required property int index
                    required property var modelData

                    width: resultsView.width
                    height: 52
                    radius: 10
                    color: root.selectedIndex === index ? "#6E2043" : "transparent" // was "#A23D0D"

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 10

                        IconImage {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            source: modelData.entry.icon
                                ? Quickshell.iconPath(modelData.entry.icon, true)
                                : "image://icon/application-x-executable"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: modelData.entry.name
                                color: root.selectedIndex === index ? "#F8F8F8" : "#D0D0D0"
                                elide: Text.ElideRight
                                font.pixelSize: 18
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.entry.comment && modelData.entry.comment.length > 0
                                    ? modelData.entry.comment
                                    : modelData.entry.id
                                color: root.selectedIndex === index ? "#F0E0D8" : "#8E8E8E"
                                elide: Text.ElideRight
                                font.pixelSize: 13
                            }
                        }
                    }

                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered) root.selectedIndex = index
                        }
                    }

                    TapHandler {
                        onTapped: root.launchIndex(index)
                    }
                }
            }

            Text {
                visible: root.filteredApps.length === 0
                text: "No matching applications"
                color: "#7A7A7A"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
        }
    }

    onShownChanged: {
        if (shown) {
            focusTimer.restart()
            rebuildResults()
        }
    }

    Component.onCompleted: rebuildResults()
}
