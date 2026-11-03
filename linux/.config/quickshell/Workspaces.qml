import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Item {
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton

        onWheel: wheel => {
            const ws = Hyprland.workspaces.values;
            const focused = Hyprland.focusedWorkspace;
            if (!focused || ws.length === 0) return;

            let idx = -1;
            for (let i = 0; i < ws.length; i++) {
                if (ws[i].id === focused.id) { idx = i; break; }
            }
            if (idx === -1) return;

            // activate() sends the legacy `workspace N` dispatch, which Hyprland 0.57 rejects.
            let target = null;
            if (wheel.angleDelta.y > 0 && idx > 0)
                target = ws[idx - 1];
            else if (wheel.angleDelta.y < 0 && idx < ws.length - 1)
                target = ws[idx + 1];
            if (target)
                Hyprland.dispatch("hl.dsp.focus({ workspace = " + target.id + " })");
        }
    }

    RowLayout {
        id: row
        spacing: 6

        Repeater {
            model: Hyprland.workspaces.values

            delegate: Rectangle {
                implicitWidth: model.active ? 36 : 18
                implicitHeight: 18
                radius: 9

                color: model.active ? "#CF577C" : model.toplevels.values.length ? "#6E2043" : "#2B2B2B"
                // color: model.active ? "#FD7C40" : model.toplevels.values.length ? "#A23D0D" : "#2B2B2B"

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }

                Text {
                    anchors.centerIn: parent
                    // Special workspaces (scratchpad) have negative ids.
                    text: model.id > 0 ? model.id : "S"
                    color: model.active ? "#fff" : model.toplevels.values.length ? "#E8B4C6" : "#888"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + model.id + " })")
                }
            }
        }
    }
}