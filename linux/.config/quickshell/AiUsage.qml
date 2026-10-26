import QtQuick
import QtQuick.Layouts
import Quickshell

BarButton {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    onMiddleClick: _mouse => usagePopup.refresh()

    popup: usagePopup

    // Like CodexBar's macOS menu bar: the selected tab's provider, or the first one on Overview.
    readonly property var shownProvider: usagePopup.current ?? usagePopup.providers[0] ?? null

    AiUsagePopup {
        id: usagePopup
        barWindow: root.barWindow
    }

    RowLayout {
        id: row
        spacing: 4

        // Before the first successful fetch.
        Text {
            visible: !root.shownProvider
            text: usagePopup.fetchError ? "AI !" : "AI …"
            color: usagePopup.fetchError ? "#FF8C8C" : "#888"
            font.pixelSize: 16
        }

        ProviderLogo {
            visible: !!root.shownProvider
            provider: root.shownProvider ? root.shownProvider.id : ""
            size: 18
        }

        Text {
            visible: !!root.shownProvider
            text: !root.shownProvider || root.shownProvider.remaining < 0 ? "–" : root.shownProvider.remaining + "%"
            color: usagePopup.levelColor(root.shownProvider ? root.shownProvider.remaining : -1)
            font.pixelSize: 16
        }
    }
}
