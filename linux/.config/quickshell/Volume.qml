import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire

BarButton {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    onMiddleClick: _mouse => openPavucontrol.running = true

    popup: volumePopup

    Process {
        id: openPavucontrol
        command: ["pavucontrol"]
    }

    VolumePopup {
        id: volumePopup
        barWindow: root.barWindow
    }

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton

        onWheel: wheel => {
            const sink = Pipewire.defaultAudioSink
            if (!sink || !sink.audio) return
            const step = wheel.angleDelta.y / 120 * 0.05
            sink.audio.muted = false
            sink.audio.volume = Math.max(0.0, Math.min(1.0, sink.audio.volume + step))
        }
    }

    RowLayout {
        id: row
        spacing: 2

        function volumePercent() {
            const sink = Pipewire.defaultAudioSink
            if (!sink || !sink.audio) return -1
            return Math.round(sink.audio.volume * 100)
        }

        function volumeIcon() {
            const sink = Pipewire.defaultAudioSink
            if (!sink || !sink.audio) return ""
            if (sink.audio.muted) return Qt.resolvedUrl("icons/volume-mute.svg")
            const p = volumePercent()
            if (p < 0)   return ""
            if (p < 10)  return Qt.resolvedUrl("icons/volume-low.svg")
            if (p < 30)  return Qt.resolvedUrl("icons/volume-20.svg")
            if (p < 80)  return Qt.resolvedUrl("icons/volume-50.svg")
            return Qt.resolvedUrl("icons/volume-100.svg")
        }

        IconImage {
            width: 20
            height: 20
            source: row.volumeIcon()
        }

        Text {
            color: "#A1BFFF"
            font.pixelSize: 16
            text: {
                const percent = row.volumePercent()
                if (percent < 0) return ""
                return percent + "%"
            }
        }
    }
}
