import QtQuick
import Quickshell.Hyprland

Text {
    text: Hyprland.workspaces.values.find(value => value.active)?.toplevels.values.find(value => value.activated)?.title ?? ""
    maximumLineCount: 1
    color: "white"
    font {
        pixelSize: 14
        weight: Font.DemiBold
    }

}
