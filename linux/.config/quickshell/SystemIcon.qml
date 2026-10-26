import QtQuick
import Quickshell
import Quickshell.Widgets

BarButton {
    id: root

    popup: powerMenu

    implicitWidth: 20
    implicitHeight: 20

    PowerMenu {
        id: powerMenu
        barWindow: root.barWindow
    }

    IconImage {
        anchors.fill: parent
        source: Qt.resolvedUrl("icons/arch.png")
    }
}
