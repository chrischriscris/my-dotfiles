import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

Item {
    id: root

    property bool triggerHovered: false
    property bool dockHovered: false
    property bool isHovered: triggerHovered || dockHovered
    property bool dockVisible: isHovered || showTimer.running || hideTimer.running || reveal > 0

    // Grow reveal (0=collapsed, 1=fully grown) — driven imperatively
    property real reveal: 0
    property real panelContentHeight: iconColumn.implicitHeight + 24

    Timer {
        id: showTimer
        interval: 10
    }

    Timer {
        id: hideTimer
        interval: 210
    }

    // Shape grow/collapse — drives reveal
    NumberAnimation {
        id: openAnim
        target: root; property: "reveal"
        to: 1; duration: 200; easing.type: Easing.InOutQuad
    }
    NumberAnimation {
        id: closeAnim
        target: root; property: "reveal"
        to: 0; duration: 200; easing.type: Easing.InOutQuad
    }

    // Content opacity
    NumberAnimation {
        id: contentFadeIn
        target: contentLayer; property: "opacity"
        to: 1; duration: 200; easing.type: Easing.InOutQuad
    }
    NumberAnimation {
        id: contentFadeOut
        target: contentLayer; property: "opacity"
        to: 0; duration: 150; easing.type: Easing.InOutQuad
    }

    onIsHoveredChanged: {
        if (isHovered) {
            hideTimer.stop()
            showTimer.restart()
            closeAnim.stop()
            contentFadeOut.stop()
            openAnim.restart()
            contentFadeIn.restart()
        } else {
            showTimer.stop()
            hideTimer.restart()
            openAnim.stop()
            contentFadeIn.stop()
            closeAnim.restart()
            contentFadeOut.restart()
        }
    }

    property var dockItems: [
        { name: "Terminal", icon: "image://icon/utilities-terminal", exec: "kitty" },
        { name: "Files", icon: "image://icon/system-file-manager", exec: "nemo" },
        { name: "Calculator", icon: "image://icon/gnome-calculator", exec: "gnome-calculator" },
        { name: "Chrome", icon: "image://icon/google-chrome", exec: "google-chrome-stable" },
        { name: "VSCode", icon: "image://icon/vscode", exec: "code" },
        { name: "Launcher", icon: "image://icon/system-search", exec: "vicinae toggle" }
    ]

    // Trigger window - always visible, 8px wide
    PanelWindow {
        id: triggerWindow
        anchors {
            right: true
        }
        implicitWidth: 8
        implicitHeight: dockWindow.implicitHeight
        exclusiveZone: 0
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: root.triggerHovered = containsMouse
        }
    }

    // Dock window - only visible when triggered
    PanelWindow {
        id: dockWindow
        anchors {
            right: true
        }
        visible: root.dockVisible
        implicitWidth: 64
        implicitHeight: root.panelContentHeight + 32
        exclusiveZone: 0
        color: "transparent"

        // Background shape — grows from right edge.
        // flushRight produces concave ears at TR/BR (extending along the
        // screen edge) and convex corners at TL/BL. panelWidth animates
        // via reveal, and the clamped radii morph the ears naturally.
        MenuShape {
            panelWidth:  64 * root.reveal
            panelHeight: root.panelContentHeight
            cornerRadius: 16
            fillColor: "#000000"
            flushRight: true
            x: 48 - panelWidth   // keeps right edge fixed at window x=64
            y: 0
        }

        // Panel body — hover detection wraps the content so dock item
        // hover events propagate up to this ancestor's HoverHandler.
        Item {
            id: dockPanel
            x: 0
            y: 16
            width: 64
            height: root.panelContentHeight

            HoverHandler {
                id: dockPanelHover
                onHoveredChanged: root.dockHovered = hovered
            }

            // Content area — clipped to the panel bounds, slides in from right.
            // Horizontal mirror of PopUp's vertical clip/slide pattern.
            Item {
                id: contentClip
                x: 64 - 64 * root.reveal
                width: 64 * root.reveal
                height: parent.height
                clip: true

                Item {
                    id: contentLayer
                    width: 64
                    height: parent.height
                    x: 0
                    opacity: 0

                    ColumnLayout {
                        id: iconColumn
                        anchors.centerIn: parent

                        Repeater {
                            model: root.dockItems

                            delegate: Item {
                                id: dockItem
                                width: 64
                                height: 52
                                Layout.alignment: Qt.AlignHCenter

                                property bool hovered: false

                                HoverHandler {
                                    onHoveredChanged: dockItem.hovered = hovered
                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    onTapped: Hyprland.dispatch("exec " + modelData.exec)
                                }

                                IconImage {
                                    width: 48
                                    height: 48
                                    anchors.centerIn: parent
                                    source: modelData.icon
                                    scale: dockItem.hovered ? 1.2 : 1.0

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 150
                                            easing.type: Easing.OutQuad
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
