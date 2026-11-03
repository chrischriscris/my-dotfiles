import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
    id: bar

    function checkClick() {
        aiUsage.checkClick()
        tray.checkClick()
        systemIcon.checkClick()
        clock.checkClick()
        volume.checkClick()
        battery.checkClick()
    }
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 48
    exclusiveZone: 32
    color: "transparent"

    MenuShape {
        panelWidth: bar.width
        panelHeight: 32
        cornerRadius: 16
        fillColor: "#000000"
        flushTop: true
        flushLeft: true
        flushRight: true
        x: -cornerRadius
        y: -cornerRadius
    }

    RowLayout {
        spacing: 16
        height: 32
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            leftMargin: 12
            rightMargin: 12
        }

        RowLayout {
            spacing: 12
            SystemIcon { id: systemIcon; barWindow: bar }
            Workspaces {}
            ActiveWindow {}
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            spacing: 16
            ScreenRecording {}
            AiUsage { id: aiUsage; barWindow: bar }
            Tray { id: tray; barWindow: bar }
            Battery { id: battery; barWindow: bar }
            Volume { id: volume; barWindow: bar }
            Clock { id: clock; barWindow: bar }
        }

    }
}
