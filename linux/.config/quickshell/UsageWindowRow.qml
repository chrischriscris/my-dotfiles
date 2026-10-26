import QtQuick
import QtQuick.Layouts

// One rate window: "Session 92% left · Resets in 2h 45m", its bar, and the pace line.
ColumnLayout {
    id: root

    property var limit
    property color tint: "#A1BFFF"
    property real now: Date.now()
    property bool compact: false

    spacing: 5

    function resetText(resetsAt) {
        if (isNaN(resetsAt)) return ""
        const mins = Math.max(0, Math.round((resetsAt - root.now) / 60000))
        if (mins < 60) return "Resets in " + mins + "m"
        const hours = Math.floor(mins / 60)
        if (hours < 24) return "Resets in " + hours + "h " + (mins % 60) + "m"
        return "Resets in " + Math.floor(hours / 24) + "d " + (hours % 24) + "h"
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: root.limit.label + " " + (root.limit.remaining < 0 ? "unknown" : root.limit.remaining + "% left")
            color: "#fff"
            font.pixelSize: root.compact ? 12 : 13
            font.weight: Font.DemiBold
        }

        Item { Layout.fillWidth: true }

        Text {
            text: root.resetText(root.limit.resetsAt)
            color: "#999"
            font.pixelSize: 11
        }
    }

    UsageBar {
        Layout.fillWidth: true
        remaining: root.limit.remaining
        tint: root.tint
        paceMarker: root.limit.paceMarker
        paceDeficit: root.limit.paceDeficit
    }

    Text {
        visible: !root.compact && root.limit.pace !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: root.limit.pace
        color: "#999"
        font.pixelSize: 11
    }
}
