import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire

PopUp {
    id: root

    panelTargetWidth: 192 + 16
    panelTargetHeight: row.implicitHeight + 24

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool available: sink && sink.audio

    RowLayout {
        id: row
        anchors.centerIn: parent
        width: 192
        spacing: 8

        // Mute toggle icon
        IconImage {
            source: {
                if (!root.available) return Qt.resolvedUrl("icons/volume-mute.svg")
                if (root.sink.audio.muted) return Qt.resolvedUrl("icons/volume-mute.svg")
                const p = Math.round(root.sink.audio.volume * 100)
                if (p < 10)  return Qt.resolvedUrl("icons/volume-low.svg")
                if (p < 30)  return Qt.resolvedUrl("icons/volume-20.svg")
                if (p < 80)  return Qt.resolvedUrl("icons/volume-50.svg")
                return Qt.resolvedUrl("icons/volume-100.svg")
            }
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (root.available) root.sink.audio.muted = !root.sink.audio.muted }
            }
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
                width: root.available && !root.sink.audio.muted
                       ? Math.round(track.width * Math.min(root.sink.audio.volume, 1.0))
                       : 0
                height: 4
                radius: 2
                color: "#A1BFFF"
            }

            Rectangle {
                anchors.verticalCenter: track.verticalCenter
                x: Math.max(0, fill.width - 6)
                width: 12; height: 12
                radius: 6
                color: "#fff"
                visible: root.available && !root.sink.audio.muted
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                function setVolumeFromMouse(mx) {
                    if (!root.available) return
                    root.sink.audio.muted = false
                    root.sink.audio.volume = Math.max(0.0, Math.min(1.0, mx / track.width))
                }

                onPressed:         mouse => setVolumeFromMouse(mouse.x)
                onPositionChanged: mouse => setVolumeFromMouse(mouse.x)

                onWheel: wheel => {
                    if (!root.available) return
                    const step = wheel.angleDelta.y / 120 * 0.05
                    root.sink.audio.muted = false
                    root.sink.audio.volume = Math.max(0.0, Math.min(1.0, root.sink.audio.volume + step))
                }
            }
        }

        // Percentage label
        Text {
            text: {
                if (!root.available) return "–"
                if (root.sink.audio.muted) return "–"
                return Math.round(root.sink.audio.volume * 100) + "%"
            }
            color: "#A1BFFF"
            font.pixelSize: 13
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 34
        }
    }
}
