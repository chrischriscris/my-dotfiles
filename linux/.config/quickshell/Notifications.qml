import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

BarButton {
    id: root

    popup: notificationPopup

    NotificationPopup {
        id: notificationPopup
        barWindow: root.barWindow
    }

    RowLayout {
        spacing: 2

        IconImage {
            width: 20
            height: 20
            source: NotificationManager.unreadCount > 0
                ? Qt.resolvedUrl("icons/notification.svg")
                : Qt.resolvedUrl("icons/notification-empty.svg")
        }

        Text {
            visible: NotificationManager.unreadCount > 0
            color: "#CF577C" // was "#FD7C40"
            font.pixelSize: 16
            text: {
                const count = NotificationManager.unreadCount;
                const max = NotificationManager.unreadBadgeMax;
                return count > max ? max + "+" : count;
            }
        }
    }
}
