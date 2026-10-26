import QtQuick
import QtQuick.Layouts

// Title/value pair in the spend grid, e.g. "Today / $5.47".
ColumnLayout {
    id: root

    property string title
    property string value

    Layout.preferredWidth: 154
    spacing: 1

    Text {
        text: root.title
        color: "#999"
        font.pixelSize: 11
    }

    Text {
        text: root.value
        color: "#fff"
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }
}
