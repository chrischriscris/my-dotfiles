import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

PopUp {
    id: root

    panelTargetWidth: 224 + 16
    windowHeight: 16 + 28 + 20 + (24 * 6) + 4
    panelTargetHeight: content.implicitHeight + 16

    property int displayMonth: new Date().getMonth()  // 0-indexed
    property int displayYear:  new Date().getFullYear()

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    readonly property int todayDay:   clock.date.getDate()
    readonly property int todayMonth: clock.date.getMonth()
    readonly property int todayYear:  clock.date.getFullYear()

    property int selectedDay:   -1
    property int selectedMonth: -1
    property int selectedYear:  -1

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    // Build flat array of day cells for the grid.
    // Sunday-first. Each cell: { day, currentMonth, today }
    readonly property var days: {
        const todayY = root.todayYear
        const todayM = root.todayMonth
        const todayD = root.todayDay

        const firstDow = new Date(displayYear, displayMonth, 1).getDay() // Sun=0
        const daysInMonth = new Date(displayYear, displayMonth + 1, 0).getDate()

        // Days from previous month to fill the first row
        const prevDays = new Date(displayYear, displayMonth, 0).getDate()

        const totalCells = Math.ceil((firstDow + daysInMonth) / 7) * 7
        const cells = []

        for (let i = 0; i < totalCells; i++) {
            let day, currentMonth, isToday
            if (i < firstDow) {
                // Previous month padding
                day = prevDays - firstDow + 1 + i
                currentMonth = false
                isToday = false
            } else if (i < firstDow + daysInMonth) {
                // Current month
                day = i - firstDow + 1
                currentMonth = true
                isToday = (day === todayD && displayMonth === todayM && displayYear === todayY)
            } else {
                // Next month padding
                day = i - firstDow - daysInMonth + 1
                currentMonth = false
                isToday = false
            }
            cells.push({ day, currentMonth, isToday })
        }
        return cells
    }

    Column {
        id: content
        anchors.centerIn: parent
        width: 224
        spacing: 2

        // Navigation header
        Item {
            width: parent.width
            height: 28

            Rectangle {
                width: 28; height: 28
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 4 }
                color: prevMouse.containsMouse ? "#333" : "transparent"
                radius: 4
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "\u2039"
                    color: "#888"
                    font.pixelSize: 18
                }

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.displayMonth === 0) { root.displayMonth = 11; root.displayYear-- }
                        else root.displayMonth--
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.monthNames[root.displayMonth] + " " + root.displayYear
                color: "#fff"
                font.pixelSize: 13
            }

            Rectangle {
                width: 28; height: 28
                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 4 }
                color: nextMouse.containsMouse ? "#333" : "transparent"
                radius: 4
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "\u203a"
                    color: "#888"
                    font.pixelSize: 18
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.displayMonth === 11) { root.displayMonth = 0; root.displayYear++ }
                        else root.displayMonth++
                    }
                }
            }
        }

        // Day-of-week labels (Sun–Sat)
        Row {
            width: parent.width

            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                Text {
                    required property string modelData
                    width: 32; height: 20
                    text: modelData
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: "#666"
                    font.pixelSize: 11
                }
            }
        }

        // Day grid
        Grid {
            width: parent.width
            columns: 7

            Repeater {
                model: root.days

                Item {
                    required property var modelData
                    width: 32; height: 24

                    readonly property bool isSelected:
                        modelData.currentMonth &&
                        !modelData.isToday &&
                        modelData.day === root.selectedDay &&
                        root.displayMonth === root.selectedMonth &&
                        root.displayYear  === root.selectedYear

                    // Selection highlight
                    Rectangle {
                        anchors.centerIn: parent
                        width: 22; height: 22
                        radius: 11
                        color: "#555"
                        visible: parent.isSelected
                    }

                    // Today highlight
                    Rectangle {
                        anchors.centerIn: parent
                        width: 22; height: 22
                        radius: 11
                        color: "#CF577C" // was "#FD7C40"
                        visible: modelData.isToday
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        font.pixelSize: 12
                        color: modelData.isToday      ? "#000"
                             : parent.isSelected      ? "#fff"
                             : modelData.currentMonth ? "#fff"
                             : "#444"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: modelData.currentMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: modelData.currentMonth
                        onClicked: {
                            if (modelData.isToday) {
                                // Clicking today clears any selection
                                root.selectedDay   = -1
                                root.selectedMonth = -1
                                root.selectedYear  = -1
                            } else if (root.selectedDay   === modelData.day &&
                                       root.selectedMonth === root.displayMonth &&
                                       root.selectedYear  === root.displayYear) {
                                // Clicking the selected day deselects it
                                root.selectedDay   = -1
                                root.selectedMonth = -1
                                root.selectedYear  = -1
                            } else {
                                root.selectedDay   = modelData.day
                                root.selectedMonth = root.displayMonth
                                root.selectedYear  = root.displayYear
                            }
                        }
                    }
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            const now = new Date()
            root.displayMonth = now.getMonth()
            root.displayYear  = now.getFullYear()
        } else {
            root.selectedDay   = -1
            root.selectedMonth = -1
            root.selectedYear  = -1
        }
    }
}
