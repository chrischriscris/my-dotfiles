import QtQuick
import QtQuick.Layouts
import Quickshell

BarButton {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    onMiddleClick: _mouse => usagePopup.refresh()

    popup: usagePopup

    AiUsagePopup {
        id: usagePopup
        barWindow: root.barWindow
    }

    RowLayout {
        id: row
        spacing: 10

        // Before the first successful fetch.
        Text {
            visible: usagePopup.providers.length === 0
            text: usagePopup.fetchError ? "AI !" : "AI …"
            color: usagePopup.fetchError ? "#FF8C8C" : "#888"
            font.pixelSize: 16
        }

        Repeater {
            model: usagePopup.providers

            RowLayout {
                spacing: 4

                ProviderLogo {
                    provider: modelData.id
                    size: 18
                }

                Text {
                    text: modelData.remaining < 0 ? "–" : modelData.remaining + "%"
                    color: usagePopup.levelColor(modelData.remaining)
                    font.pixelSize: 16
                }
            }
        }
    }
}
