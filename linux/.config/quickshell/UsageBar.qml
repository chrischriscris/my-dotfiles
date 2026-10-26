import QtQuick

// Remaining-quota bar drawn like CodexBar's macOS menu: warning ticks at 50% and 20% left,
// and a stripe where a sustainable pace would be (green in reserve, red in deficit).
Item {
    id: root

    property real remaining: 0         // 0–100; negative when unknown
    property color tint: "#A1BFFF"
    property real paceMarker: -1       // remaining-% position of the pace stripe; negative hides it
    property bool paceDeficit: false
    property var warnings: [50, 20]
    property color background: "#000000"

    implicitHeight: 6

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "#2a2a2a"
    }

    Rectangle {
        visible: root.remaining > 0
        width: Math.round(parent.width * Math.min(100, root.remaining) / 100)
        height: parent.height
        radius: height / 2
        color: root.tint
    }

    Repeater {
        model: root.warnings

        Item {
            x: Math.round(root.width * modelData / 100) - 1.5
            width: 3
            height: root.height

            Rectangle { anchors.fill: parent; color: root.background }
            Rectangle { anchors.centerIn: parent; width: 1; height: parent.height; color: "#8a8a8a" }
        }
    }

    Item {
        visible: root.paceMarker >= 0
        x: Math.round(root.width * Math.min(100, root.paceMarker) / 100) - 2
        y: -2
        width: 4
        height: root.height + 4

        Rectangle { anchors.fill: parent; radius: 1; color: root.background }
        Rectangle {
            anchors.centerIn: parent
            width: 2
            height: parent.height
            radius: 1
            color: root.paceDeficit ? "#FF453A" : "#32D74B"
        }
    }
}
