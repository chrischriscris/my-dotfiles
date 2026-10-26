import QtQuick
import Quickshell.Widgets

// Provider logo from icons/provider-<id>.svg, falling back to the provider's initial.
Item {
    id: root

    property string provider: ""
    property int size: 16

    readonly property bool hasIcon: logo.status === Image.Ready

    implicitWidth: hasIcon ? size : tag.implicitWidth
    implicitHeight: size

    IconImage {
        id: logo
        anchors.centerIn: parent
        implicitSize: root.size
        source: root.provider ? Qt.resolvedUrl("icons/provider-" + root.provider + ".svg") : ""
        visible: root.hasIcon
    }

    Text {
        id: tag
        anchors.centerIn: parent
        visible: !root.hasIcon
        text: root.provider.charAt(0).toUpperCase()
        color: "#ccc"
        font.pixelSize: root.size - 2
        font.weight: Font.Bold
    }
}
