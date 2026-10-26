import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// AI coding quota and local spend via the CodexBar CLI (https://github.com/steipete/CodexBar),
// laid out like CodexBar's macOS menu.
PopUp {
    id: root

    // Installed outside PATH so it doesn't shadow ~/.local/bin/codexbar.
    property string cliPath: Quickshell.env("HOME") + "/.local/lib/codexbar-cli/codexbar"
    property string provider: "both"   // claude + codex; any `codexbar --provider` value works
    property int refreshInterval: 5 * 60 * 1000

    property var providers: []
    property alias selectedTab: savedState.selectedTab
    property string fetchError: ""
    property string fetchStderr: ""
    property var lastUpdated: null
    property real now: Date.now()

    property var usageEntries: []
    property var costEntries: []

    readonly property var current: root.providers.find(p => p.id === root.selectedTab) ?? null
    readonly property bool refreshing: usageProcess.running || costProcess.running

    // Tints match CodexBar's provider descriptors.
    readonly property var providerInfo: ({
        claude: {
            name: "Claude",
            color: "#CC7C5E",
            dashboard: "https://claude.ai/settings/usage",
            status: "https://status.claude.com/"
        },
        codex: {
            name: "Codex",
            color: "#49A3B0",
            dashboard: "https://chatgpt.com/settings/usage?tab=overview",
            status: "https://status.openai.com/"
        }
    })

    panelTargetWidth: 320 + 24
    panelTargetHeight: column.implicitHeight + 24

    function refresh(): void {
        root.fetchStderr = ""
        if (!usageProcess.running) usageProcess.running = true
        if (!costProcess.running) costProcess.running = true
    }

    function levelColor(remaining) {
        if (remaining < 0)  return "#888"
        if (remaining < 10) return "#FF8C8C"
        if (remaining < 30) return "#FFD98C"
        return "#D9A1FF"
    }

    function formatDuration(ms) {
        const mins = Math.max(0, Math.round(ms / 60000))
        if (mins < 60) return mins + "m"
        const hours = Math.floor(mins / 60)
        if (hours < 24) return hours + "h " + (mins % 60) + "m"
        return Math.floor(hours / 24) + "d " + (hours % 24) + "h"
    }

    function formatCost(value) {
        return "$" + Number(value).toLocaleString(Qt.locale("en_US"), "f", 2)
    }

    function formatTokens(n) {
        if (n >= 1e9) return (n / 1e9).toFixed(1) + "B"
        if (n >= 1e6) return (n / 1e6).toFixed(1) + "M"
        if (n >= 1e3) return (n / 1e3).toFixed(1) + "K"
        return String(Math.round(n))
    }

    function formatInstant(ms) {
        return Qt.formatDateTime(new Date(ms), "MMM d 'at' HH:mm")
    }

    function updatedText() {
        if (root.refreshing) return "Refreshing…"
        return root.lastUpdated ? "Updated " + Qt.formatTime(root.lastUpdated, "HH:mm") : "Loading…"
    }

    function windowLabel(w) {
        if (w.windowMinutes === 300)   return "Session"
        if (w.windowMinutes === 1440)  return "Daily"
        if (w.windowMinutes === 10080) return "Weekly"
        return w.windowMinutes ? Math.round(w.windowMinutes / 60) + "h window" : "Limit"
    }

    function extraLabel(extra) {
        const title = extra.title || extra.id
        // The macOS menu calls Claude's "Fable only" weekly cap "Fable weekly".
        if (extra.window.windowMinutes === 10080 && title.endsWith(" only"))
            return title.slice(0, -5) + " weekly"
        return title
    }

    // "38% in reserve | Expected 44% used | Lasts until reset" -> "38% in reserve · Lasts until reset"
    function paceFromCli(pace) {
        if (!pace || typeof pace.expectedUsedPercent !== "number") return null
        return {
            text: (pace.summary || "").split(" | ").filter(s => s && !s.startsWith("Expected")).join(" · "),
            marker: 100 - pace.expectedUsedPercent,
            deficit: pace.deltaPercent > 0
        }
    }

    // The CLI only reports pace for some windows; the rest get the same linear estimate here.
    function paceFromWindow(w, used, resetsAt) {
        const total = (w.windowMinutes || 0) * 60000
        const elapsed = total - (resetsAt - Date.now())
        if (!total || isNaN(resetsAt) || used < 0 || elapsed <= 0 || elapsed > total) return null
        const expected = elapsed / total * 100
        if (expected < 3) return null
        const delta = Math.round(used - expected)
        const left = delta === 0 ? "On pace" : Math.abs(delta) + (delta > 0 ? "% in deficit" : "% in reserve")
        const right = used <= expected
            ? "Lasts until reset"
            : "Runs out in " + formatDuration((100 - used) * elapsed / used)
        return { text: left + " · " + right, marker: 100 - expected, deficit: delta > 0 }
    }

    function toWindow(label, w, pace, main) {
        const used = typeof w.usedPercent === "number" ? Math.max(0, Math.min(100, w.usedPercent)) : -1
        const resetsAt = w.resetsAt ? Date.parse(w.resetsAt) : NaN
        const p = paceFromCli(pace) ?? paceFromWindow(w, used, resetsAt)
        return {
            label: label,
            remaining: used < 0 ? -1 : Math.round(100 - used),
            resetsAt: resetsAt,
            windowMinutes: w.windowMinutes || 0,
            pace: p ? p.text : "",
            paceMarker: p ? p.marker : -1,
            paceDeficit: p ? p.deficit : false,
            main: main
        }
    }

    function resetCreditsText(credits) {
        if (!credits || !credits.availableCount) return ""
        const count = credits.availableCount
        const expiries = (credits.credits || [])
            .filter(c => c.status === "available" && c.expires_at)
            .map(c => Date.parse(c.expires_at))
            .sort((a, b) => a - b)
        const text = count + (count === 1 ? " free limit reset available" : " free limit resets available")
        return expiries.length ? text + " · next expires " + Qt.formatDateTime(new Date(expiries[0]), "MMM d") : text
    }

    // Spend from `codexbar cost`, which scans this PC's local Claude/Codex logs.
    function toCost(entry, weekly) {
        if (!entry || entry.error) return null
        const dayMs = 24 * 3600 * 1000
        const today = new Date()
        today.setHours(0, 0, 0, 0)
        const historyDays = entry.historyDays || 30

        const byDay = {}
        const models = {}
        for (const d of entry.daily || []) {
            const [y, m, day] = d.date.split("-").map(Number)
            const start = new Date(y, m - 1, day).getTime()
            byDay[start] = { start: start, end: start + dayMs, cost: d.totalCost || 0, tokens: d.totalTokens || 0 }
            for (const mb of d.modelBreakdowns || [])
                models[mb.modelName] = (models[mb.modelName] || 0) + (mb.cost || 0)
        }

        const days = []
        for (let i = historyDays - 1; i >= 0; i--) {
            const d = new Date(today)
            d.setDate(d.getDate() - i)
            days.push(byDay[d.getTime()] ?? { start: d.getTime(), end: d.getTime() + dayMs, cost: 0, tokens: 0 })
        }

        // Quota windows end at the weekly reset and stride back one window at a time. The CLI
        // only has daily totals, so each day is spread evenly across the hours it overlaps.
        const windows = []
        if (weekly && !isNaN(weekly.resetsAt) && weekly.windowMinutes) {
            const span = weekly.windowMinutes * 60000
            const labels = ["Current window", "Previous window", "2 windows ago", "3 windows ago"]
            for (let i = 0; i < labels.length; i++) {
                const end = weekly.resetsAt - i * span
                const start = end - span
                if (i > 0 && start < days[0].start) break
                let cost = 0
                let tokens = 0
                for (const d of days) {
                    const overlap = Math.min(d.end, end) - Math.max(d.start, start)
                    if (overlap <= 0) continue
                    cost += d.cost * overlap / (d.end - d.start)
                    tokens += d.tokens * overlap / (d.end - d.start)
                }
                if (i === 0 || cost > 0 || tokens > 0)
                    windows.push({ label: labels[i], start: start, end: end, cost: cost, tokens: tokens })
            }
        }

        return {
            today: entry.sessionCostUSD ?? 0,
            todayTokens: entry.sessionTokens ?? 0,
            history: entry.last30DaysCostUSD ?? 0,
            historyTokens: entry.last30DaysTokens ?? 0,
            historyLabel: historyDays + "d",
            days: days,
            maxDay: Math.max(0, ...days.map(d => d.cost)),
            windows: windows,
            topModel: Object.keys(models).sort((a, b) => models[b] - models[a])[0] ?? ""
        }
    }

    function rebuild() {
        const costs = {}
        for (const c of root.costEntries) costs[c.provider] = c

        root.providers = root.usageEntries.map(entry => {
            const id = entry.provider || "?"
            const info = root.providerInfo[id] ?? {}
            const usage = entry.usage || {}
            const labels = entry.rateWindowLabels || {}
            const pace = entry.pace || {}

            const windows = []
            for (const key of ["primary", "secondary", "tertiary"]) {
                const w = usage[key]
                if (w) windows.push(toWindow(labels[key] || windowLabel(w), w, pace[key], true))
            }
            // Per-model caps such as Claude's Fable weekly window: never drive the bar number.
            for (const extra of usage.extraRateWindows || []) {
                if (extra.window) windows.push(toWindow(extraLabel(extra), extra.window, null, false))
            }

            // The bar shows whichever general window is closest to running out.
            const known = windows.filter(w => w.main && w.remaining >= 0)
            const weekly = windows.find(w => w.main && w.windowMinutes === 10080) ?? null

            return {
                id: id,
                name: info.name ?? id.charAt(0).toUpperCase() + id.slice(1),
                color: info.color ?? "#A1BFFF",
                dashboard: info.dashboard ?? "",
                status: info.status ?? "",
                // Codex reports plans in lowercase ("plus").
                plan: (usage.loginMethod || "").replace(/^./, c => c.toUpperCase()),
                email: usage.accountEmail || (usage.identity && usage.identity.accountEmail) || "",
                error: entry.error ? (entry.error.message || "Fetch failed") : "",
                windows: windows,
                remaining: known.length ? Math.min(...known.map(w => w.remaining)) : -1,
                resetCredits: resetCreditsText(usage.codexResetCredits),
                cost: toCost(costs[id], weekly)
            }
        })
    }

    function parseEntries(text) {
        try {
            const entries = JSON.parse(text)
            return Array.isArray(entries) ? entries : null
        } catch (e) {
            return null
        }
    }

    Process {
        id: usageProcess
        // Through sh so a missing binary still closes stdout and reports an error.
        command: ["sh", "-c", 'exec "$1" usage --provider "$2" --format json', "sh", root.cliPath, root.provider]
        stdout: StdioCollector {
            onStreamFinished: {
                const entries = root.parseEntries(text)
                // Keep the last good data on failure; the footer reports the error.
                if (!entries) {
                    root.fetchError = text.trim() ? "Unexpected output from codexbar" : "codexbar returned nothing"
                    return
                }
                root.usageEntries = entries
                root.fetchError = ""
                root.lastUpdated = new Date()
                root.rebuild()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: root.fetchStderr = text.trim().split("\n").pop()
        }
    }

    Process {
        id: costProcess
        command: ["sh", "-c", 'exec "$1" cost --provider "$2" --format json', "sh", root.cliPath, root.provider]
        stdout: StdioCollector {
            onStreamFinished: {
                // Spend is optional: without it the quota sections still show.
                const entries = root.parseEntries(text)
                if (!entries) return
                root.costEntries = entries
                root.rebuild()
            }
        }
    }

    // Remembers the selected tab across restarts, as the macOS app does.
    FileView {
        path: Qt.resolvedUrl("ai-usage-state.json")
        printErrors: false
        blockLoading: true
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: savedState
            property string selectedTab: "overview"
        }
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 30 * 1000
        running: root.shown
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }

    onShownChanged: {
        if (shown && (!root.lastUpdated || Date.now() - root.lastUpdated.getTime() > 60 * 1000))
            root.refresh()
    }

    ColumnLayout {
        id: column
        anchors {
            top: parent.top
            topMargin: 12
            horizontalCenter: parent.horizontalCenter
        }
        width: 320
        spacing: 10

        // ── Provider tabs ────────────────────────────────────────────────────

        RowLayout {
            Layout.fillWidth: true
            visible: root.providers.length > 0
            spacing: 4

            Repeater {
                model: [{ id: "overview", name: "Overview", remaining: -1, color: "#fff" }].concat(root.providers)

                Item {
                    id: tab
                    readonly property bool selected: (root.current ? root.current.id : "overview") === modelData.id
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: 42

                    Rectangle {
                        anchors.fill: parent
                        radius: 7
                        color: tab.selected ? "#0A84FF" : (tabArea.containsMouse ? "#1a1a1a" : "transparent")
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 14
                            height: 14

                            ProviderLogo {
                                anchors.centerIn: parent
                                visible: modelData.id !== "overview"
                                provider: modelData.id === "overview" ? "" : modelData.id
                                size: 14
                            }

                            Grid {
                                anchors.centerIn: parent
                                visible: modelData.id === "overview"
                                columns: 2
                                spacing: 2

                                Repeater {
                                    model: 4
                                    Rectangle {
                                        width: 5
                                        height: 5
                                        radius: 1.5
                                        color: "transparent"
                                        border.width: 1
                                        border.color: tab.selected ? "#fff" : "#ccc"
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.name
                            color: tab.selected ? "#fff" : "#999"
                            font.pixelSize: 10
                        }
                    }

                    // Mini quota bar under unselected provider tabs, as on macOS.
                    Rectangle {
                        visible: !tab.selected && modelData.remaining >= 0
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 36
                        height: 2
                        radius: 1
                        color: "#333"

                        Rectangle {
                            width: parent.width * Math.max(0, modelData.remaining) / 100
                            height: parent.height
                            radius: 1
                            color: modelData.color
                        }
                    }

                    MouseArea {
                        id: tabArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedTab = modelData.id
                    }
                }
            }
        }

        Text {
            visible: root.providers.length === 0 && !root.fetchError
            text: "Loading…"
            color: "#999"
            font.pixelSize: 12
        }

        // ── Overview: every provider's general windows ──────────────────────

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.current === null && root.providers.length > 0
            spacing: 14

            Repeater {
                model: root.providers

                ColumnLayout {
                    id: card
                    readonly property var p: modelData
                    Layout.fillWidth: true
                    spacing: 6

                    // Clicking a provider's header opens its tab.
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: cardHeader.implicitHeight

                        RowLayout {
                            id: cardHeader
                            anchors.fill: parent
                            spacing: 8

                            ProviderLogo {
                                provider: card.p.id
                                size: 14
                            }

                            Text {
                                text: card.p.name
                                color: "#fff"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: card.p.plan
                                color: "#999"
                                font.pixelSize: 11
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedTab = card.p.id
                        }
                    }

                    Text {
                        visible: card.p.error !== ""
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: card.p.error
                        color: "#FF8C8C"
                        font.pixelSize: 11
                    }

                    Repeater {
                        model: card.p.windows.filter(w => w.main)

                        UsageWindowRow {
                            Layout.fillWidth: true
                            limit: modelData
                            tint: card.p.color
                            now: root.now
                            compact: true
                        }
                    }
                }
            }
        }

        // ── One provider, like the macOS menu card ──────────────────────────

        ColumnLayout {
            id: detail
            readonly property var p: root.current ?? ({ id: "", name: "", color: "#fff", plan: "", email: "",
                error: "", windows: [], resetCredits: "", dashboard: "", status: "", cost: null })
            readonly property bool hasCost: detail.p.cost !== null
            readonly property var cost: detail.p.cost ?? ({ today: 0, todayTokens: 0, history: 0,
                historyTokens: 0, historyLabel: "", days: [], maxDay: 0, windows: [], topModel: "" })
            readonly property var currentWindow: detail.cost.windows.length ? detail.cost.windows[0] : null

            Layout.fillWidth: true
            visible: root.current !== null
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    spacing: 1

                    Text {
                        text: detail.p.name
                        color: "#fff"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: root.updatedText()
                        color: "#999"
                        font.pixelSize: 11
                    }
                }

                Item { Layout.fillWidth: true }

                ColumnLayout {
                    spacing: 1

                    Text {
                        Layout.alignment: Qt.AlignRight
                        Layout.maximumWidth: 200
                        visible: detail.p.email !== ""
                        text: detail.p.email
                        elide: Text.ElideMiddle
                        color: "#ccc"
                        font.pixelSize: 12
                    }

                    Text {
                        Layout.alignment: Qt.AlignRight
                        text: detail.p.plan
                        color: "#999"
                        font.pixelSize: 11
                    }
                }
            }

            Text {
                visible: detail.p.error !== ""
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: detail.p.error
                color: "#FF8C8C"
                font.pixelSize: 12
            }

            Repeater {
                model: detail.p.windows

                UsageWindowRow {
                    Layout.fillWidth: true
                    limit: modelData
                    tint: detail.p.color
                    now: root.now
                }
            }

            Text {
                visible: detail.p.resetCredits !== ""
                text: detail.p.resetCredits
                color: "#999"
                font.pixelSize: 11
            }

            PopupDivider { visible: detail.hasCost }

            GridLayout {
                visible: detail.hasCost
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 12
                rowSpacing: 8

                UsageStat {
                    title: "Today"
                    value: root.formatCost(detail.cost.today)
                }

                UsageStat {
                    title: detail.currentWindow ? "Current window" : detail.cost.historyLabel + " cost"
                    value: root.formatCost(detail.currentWindow ? detail.currentWindow.cost : detail.cost.history)
                }

                UsageStat {
                    title: "Latest tokens"
                    value: root.formatTokens(detail.cost.todayTokens)
                }

                UsageStat {
                    title: detail.currentWindow ? "Current window tokens" : detail.cost.historyLabel + " tokens"
                    value: root.formatTokens(detail.currentWindow ? detail.currentWindow.tokens : detail.cost.historyTokens)
                }

                UsageStat {
                    visible: detail.currentWindow !== null
                    title: detail.cost.historyLabel + " cost"
                    value: root.formatCost(detail.cost.history)
                }

                UsageStat {
                    visible: detail.currentWindow !== null
                    title: detail.cost.historyLabel + " tokens"
                    value: root.formatTokens(detail.cost.historyTokens)
                }
            }

            // Daily cost over the history period.
            Item {
                visible: detail.hasCost
                Layout.fillWidth: true
                implicitHeight: 58

                Text {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    text: "$" + Math.round(detail.cost.maxDay)
                    color: "#999"
                    font.pixelSize: 10
                }

                Row {
                    id: chart
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 44
                    spacing: 2

                    Repeater {
                        model: detail.cost.days

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: (chart.width - chart.spacing * (detail.cost.days.length - 1)) / detail.cost.days.length
                            height: modelData.cost > 0 && detail.cost.maxDay > 0
                                ? Math.max(2, chart.height * modelData.cost / detail.cost.maxDay) : 1
                            color: modelData.cost > 0 ? detail.p.color : "#333"
                        }
                    }
                }
            }

            ColumnLayout {
                visible: detail.hasCost && detail.cost.windows.length > 0
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Recent windows"
                    color: "#999"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Repeater {
                    model: detail.cost.windows

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: modelData.label
                                color: "#ddd"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: root.formatCost(modelData.cost) + " · " + root.formatTokens(modelData.tokens)
                                color: "#ddd"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            text: root.formatInstant(modelData.start) + " – " + root.formatInstant(modelData.end)
                            color: "#999"
                            font.pixelSize: 11
                        }
                    }
                }
            }

            Text {
                visible: detail.hasCost && detail.cost.topModel !== ""
                text: "Top model: " + detail.cost.topModel
                color: "#999"
                font.pixelSize: 11
            }

            Text {
                visible: detail.hasCost
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "Estimated from local " + detail.p.name + " logs on this PC at API rates"
                color: "#777"
                font.pixelSize: 11
            }

            PopupDivider {}

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PopupMenuRow {
                    visible: detail.p.dashboard !== ""
                    label: "Usage Dashboard"
                    onActivated: {
                        Qt.openUrlExternally(detail.p.dashboard)
                        root.closeMenu()
                    }
                }

                PopupMenuRow {
                    visible: detail.p.status !== ""
                    label: "Status Page"
                    onActivated: {
                        Qt.openUrlExternally(detail.p.status)
                        root.closeMenu()
                    }
                }
            }
        }

        // ── Footer ──────────────────────────────────────────────────────────

        PopupDivider {}

        Text {
            visible: root.fetchError !== ""
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: root.fetchError + (root.fetchStderr ? ": " + root.fetchStderr : "")
            color: "#FF8C8C"
            font.pixelSize: 11
        }

        PopupMenuRow {
            label: "Refresh"
            hint: root.updatedText()
            onActivated: root.refresh()
        }
    }
}
