import QtQuick
import QtQuick.Layouts

// Menu-style action row with an optional right-aligned hint.
Item {
    id: root

    property string label
    property string hint

    signal activated()

    Layout.fillWidth: true
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -6
        anchors.rightMargin: -6
        radius: 6
        color: rowArea.containsMouse ? "#1f1f1f" : "transparent"
    }

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: "#ddd"
        font.pixelSize: 13
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.hint
        color: "#777"
        font.pixelSize: 11
    }

    MouseArea {
        id: rowArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
