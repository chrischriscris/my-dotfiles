import QtQuick
import Quickshell

PanelWindow {
    id: bottomCorners

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: 16
    exclusiveZone: 0
    color: "transparent"

    MenuShape {
        panelWidth: bottomCorners.width
        panelHeight: 1
        cornerRadius: 16
        fillColor: "#000000"
        flushBottom: true
        flushLeft: true
        flushRight: true
        x: -cornerRadius
        y: bottomCorners.height - cornerRadius - panelHeight
    }
}
