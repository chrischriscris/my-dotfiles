import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

PopUp {
    id: root

    panelTargetWidth: 192 + 16
    panelTargetHeight: row.implicitHeight + 24

    property int currentBrightness: 0
    property int maxBrightness: 7500
    property bool initialReadDone: false

    // Read brightness once on open
    Process {
        id: readProcess
        command: ["brightnessctl", "--machine-readable", "info"]

        stdout: SplitParser {
            onRead: data => {
                // Format: "device,class,current,percent,max"
                const parts = data.trim().split(",")
                if (parts.length >= 5) {
                    root.currentBrightness = parseInt(parts[2])
                    root.maxBrightness = parseInt(parts[4])
                    root.initialReadDone = true
                }
            }
        }
    }

    Process {
        id: writeProcess
    }

    Component.onCompleted: readProcess.running = true

    onVisibleChanged: {
        if (visible) {
            root.initialReadDone = false
            readProcess.running = true
        }
    }

    onCurrentBrightnessChanged: {
        if (root.initialReadDone && root.currentBrightness >= 0) {
            writeProcess.command = ["brightnessctl", "set", root.currentBrightness.toString()]
            writeProcess.running = true
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        width: 192
        spacing: 8

        // Brightness icon
        IconImage {
            source: Quickshell.iconPath("display-brightness-symbolic")
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
        }

        // Slider
        Item {
            Layout.fillWidth: true
            implicitHeight: 20

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: "#333"
            }

            Rectangle {
                id: fill
                anchors.verticalCenter: track.verticalCenter
                anchors.left: track.left
                width: root.maxBrightness > 0
                       ? Math.round(track.width * (root.currentBrightness / root.maxBrightness))
                       : 0
                height: 4
                radius: 2
                color: "#8CFFA9"
            }

            Rectangle {
                anchors.verticalCenter: track.verticalCenter
                x: Math.max(0, fill.width - 6)
                width: 12; height: 12
                radius: 6
                color: "#fff"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                function setBrightnessFromMouse(mx) {
                    const ratio = Math.max(0.01, Math.min(1.0, mx / track.width))
                    root.currentBrightness = Math.round(ratio * root.maxBrightness)
                }

                onPressed:         mouse => setBrightnessFromMouse(mouse.x)
                onPositionChanged: mouse => setBrightnessFromMouse(mouse.x)

                onWheel: wheel => {
                    const step = wheel.angleDelta.y / 120 * 0.05
                    const minBrightness = Math.round(0.01 * root.maxBrightness)
                    root.currentBrightness = Math.max(minBrightness, Math.min(root.maxBrightness, root.currentBrightness + Math.round(step * root.maxBrightness)))
                }
            }
        }

        // Percentage label
        Text {
            text: root.maxBrightness > 0
                  ? Math.round((root.currentBrightness / root.maxBrightness) * 100) + "%"
                  : "–"
            color: "#8CFFA9"
            font.pixelSize: 13
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 34
        }
    }
}
