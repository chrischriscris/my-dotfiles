import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

BarButton {
    id: root

    popup: calendar

    Calendar {
        id: calendar
        barWindow: root.barWindow
    }

    RowLayout {
        id: row
        spacing: 2

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        IconImage {
            width: 20
            height: 20
            source: Qt.resolvedUrl("icons/calendar.svg")
        }

        Text {
            text: {
                const d = clock.date
                if (!d || !(d instanceof Date) || isNaN(d.getTime()))
                    return ""
                return Qt.formatDateTime(d, "HH:mm")
            }
            color: "#ccc"
            font.pixelSize: 16
        }
    }
}
