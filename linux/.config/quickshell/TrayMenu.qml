import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

PopUp {
    id: root

    property var menuHandle
    property real outerPadding: 16
    property real screenHeight: barWindow?.screen?.height ?? 1080
    property real barHeight: barWindow?.height ?? 48
    property real availableBelowBar: Math.max(screenHeight - barHeight - 12, 1)
    property real trayHeightCap: Math.min(screenHeight * 0.6, 520)

    panelTargetWidth: menuStack.implicitWidth + 16
    windowHeight: Math.max(1, Math.min(availableBelowBar, trayHeightCap))
    panelTargetHeight: Math.min(menuStack.implicitHeight + outerPadding, windowHeight)

    Flickable {
        id: menuScroller
        anchors.centerIn: parent
        width: 192
        height: Math.max(root.panelHeight - root.outerPadding, 1)
        clip: true
        contentWidth: width
        contentHeight: menuStack.implicitHeight
        interactive: contentHeight > height

        StackView {
            id: menuStack
            width: menuScroller.width
            implicitWidth: currentItem?.implicitWidth ?? 192
            implicitHeight: currentItem?.implicitHeight ?? 32
            height: implicitHeight

            initialItem: SubMenu { handle: root.menuHandle }

            // Instant transitions (no animation for submenu navigation)
            pushEnter: Transition {}
            pushExit: Transition {}
            popEnter: Transition {}
            popExit: Transition {}
        }
    }

    // SubMenu component - used for root and all nested menus
    component SubMenu: Item {
        id: submenu

        required property var handle
        property bool isSubmenu: menuStack.depth > 1

        implicitWidth: 192
        implicitHeight: content.implicitHeight

        QsMenuOpener {
            id: opener
            menu: submenu.handle  // Keep menu active even when hidden to preserve NetworkManager data
        }

        Column {
            id: content
            anchors.fill: parent
            spacing: 2

            // Back button for submenus
            Rectangle {
                visible: submenu.isSubmenu
                width: parent.width
                height: visible ? 28 : 0
                color: backMouseArea.containsMouse ? "#333" : "transparent"
                radius: 4

                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                    spacing: 8

                    Text {
                        text: "\u2039"
                        color: "#888"
                        font.pixelSize: 16
                    }

                    Text {
                        text: "Back"
                        color: "#fff"
                        font.pixelSize: 13
                    }

                    Item { Layout.fillWidth: true }
                }

                MouseArea {
                    id: backMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: menuStack.pop()
                }
            }

            // Separator after back button
            Rectangle {
                visible: submenu.isSubmenu
                width: parent.width - 16
                anchors.horizontalCenter: parent.horizontalCenter
                height: visible ? 1 : 0
                color: "#333"
            }

            // Menu items
            Repeater {
                model: opener.children

                delegate: Item {
                    id: menuItem

                    required property var modelData
                    property var entry: modelData

                    visible: entry && (entry.isSeparator || entry.enabled !== undefined)

                    width: content.width
                    implicitHeight: entry ? entry.isSeparator ? 9 : 28 : 0

                    // Separator
                    Rectangle {
                        visible: !!entry?.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: "#333"
                    }

                    // Menu item
                    Rectangle {
                        visible: !entry?.isSeparator
                        anchors { fill: parent; leftMargin: 4; rightMargin: 4 }
                        color: itemMouseArea.containsMouse && entry?.enabled ? "#333" : "transparent"
                        radius: 4

                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                            spacing: 8

                            // Checkbox/Radio indicator
                            Item {
                                visible: entry && entry.buttonType !== 0
                                Layout.preferredWidth: 14
                                Layout.preferredHeight: 14

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 12; height: 12
                                    radius: entry?.buttonType === 2 ? 6 : 2
                                    color: "transparent"
                                    border { color: entry?.enabled ? "#888" : "#555"; width: 1 }

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 6; height: 6
                                        radius: entry?.buttonType === 2 ? 3 : 1
                                        color: entry?.enabled ? "#CF577C" : "#666" // was "#FD7C40"
                                        visible: entry?.checkState === Qt.Checked
                                    }
                                }
                            }

                            // Icon
                            IconImage {
                                visible: entry && entry.icon !== ""
                                source: entry?.icon ?? ""
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                            }

                            // Text
                            Text {
                                text: entry?.text ?? ""
                                color: entry?.enabled ? "#fff" : "#666"
                                font.pixelSize: 13
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            // Submenu arrow
                            Text {
                                visible: entry && entry.hasChildren
                                text: "\u203a"
                                color: "#888"
                                font.pixelSize: 16
                            }
                        }

                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: entry?.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                            onClicked: {
                                if (!entry?.enabled) return

                                if (entry?.hasChildren) {
                                    // Push submenu onto stack
                                    menuStack.push(submenuComponent, { handle: entry })
                                } else {
                                    // Trigger action and close menu
                                    entry?.triggered()
                                    root.closeMenu()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Component for creating submenu instances
    Component {
        id: submenuComponent
        SubMenu {}
    }

    // Reset stack when menu closes
    onVisibleChanged: {
        if (!visible && menuStack.depth > 1) {
            menuStack.pop(null) // Pop to root
        }
        if (!visible) menuScroller.contentY = 0
    }
}
