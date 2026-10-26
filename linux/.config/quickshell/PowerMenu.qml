import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

PopUp {
    id: root

    panelTargetWidth: 192 + 16
    panelTargetHeight: column.implicitHeight + 16

    // Shared process for running power commands
    Process {
        id: actionProcess
        property string pendingCommand: ""
        command: pendingCommand.length > 0 ? ["sh", "-c", pendingCommand] : []
    }

    Column {
        id: column
        anchors {
            centerIn: parent
            margins: 8
        }
        width: 192
        spacing: 2

        Repeater {
            model: [
                { label: "Lock",     icon: "system-lock-screen", command: "loginctl lock-session", immediateClose: true },
                { label: "Logout",   icon: "system-log-out",     command: "hyprctl dispatch exit", immediateClose: false },
                { label: "Reboot",   icon: "system-reboot",      command: "systemctl reboot", immediateClose: false },
                { label: "Shutdown", icon: "system-shutdown",    command: "systemctl poweroff", immediateClose: false }
            ]

            delegate: Rectangle {
                required property var modelData
                required property int index

                width: column.width
                height: 28
                anchors { leftMargin: 4; rightMargin: 4 }
                color: itemMouseArea.containsMouse ? "#333" : "transparent"
                radius: 4

                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                    spacing: 8

                    IconImage {
                        source: Quickshell.iconPath(modelData.icon)
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                    }

                    Text {
                        text: modelData.label
                        color: "#fff"
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: itemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        actionProcess.pendingCommand = modelData.command

                        if (modelData.immediateClose) {
                            root.closeMenuNow()
                            actionProcess.running = true
                        } else {
                            root.closeMenu()
                            actionProcess.running = true
                        }
                    }
                }
            }
        }
    }
}
