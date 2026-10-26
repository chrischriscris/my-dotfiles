import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var barWindow
    property var activeMenu: null
    property var popup
    property int gravity: Edges.Bottom | Edges.Right
    property var onMiddleClick: null

    default property alias content: contentContainer.data

    implicitWidth: contentContainer.childrenRect.width
    implicitHeight: contentContainer.childrenRect.height

    function togglePopup(): void {
        if (root.activeMenu === root.popup) {
            root.activeMenu = null
            return
        }
        const pos = root.mapToItem(null, root.width / 2, 0)
        const barBottom = root.barWindow
            ? (root.barWindow.exclusiveZone > 0 ? root.barWindow.exclusiveZone : root.barWindow.height)
            : root.height
        const popupW = Math.max((root.popup.panelTargetWidth ?? root.popup.width ?? 1)
            + (root.popup.cornerSize ?? 0) * 2, 1)
        root.popup.anchor.window = root.barWindow
        root.popup.anchor.rect.x = pos.x - popupW / 2
        root.popup.anchor.rect.y = Math.max(0, barBottom)
        root.popup.anchor.rect.width = 1
        root.popup.anchor.rect.height = 1
        root.popup.anchor.gravity = root.gravity
        root.activeMenu = root.popup
        if (root.popup.clampToScreen) root.popup.clampToScreen()
    }

    function checkClick(): void {
        if (!root.activeMenu || !root.activeMenu.visible) return
        cursorProcess.running = true
    }

    Process {
        id: cursorProcess
        command: ["hyprctl", "cursorpos"]

        stdout: SplitParser {
            onRead: data => {
                if (!root.activeMenu) return

                const parts = data.trim().split(",")
                if (parts.length !== 2) return

                const x = parseInt(parts[0].trim())
                const y = parseInt(parts[1].trim())

                const menu = root.activeMenu
                let outside
                if (menu.containsScreenPoint) {
                    outside = !menu.containsScreenPoint(x, y)
                } else {
                    const pos = menu.popupApproxTopLeftOnScreen(menu)
                    outside = x < pos.x || x > pos.x + menu.width ||
                              y < pos.y || y > pos.y + menu.height
                }

                const btn = root.mapToItem(null, 0, 0)
                const btnX = root.barWindow.screen.x + btn.x
                const btnY = root.barWindow.screen.y + btn.y
                const onButton = x >= btnX && x <= btnX + root.width &&
                                 y >= btnY && y <= btnY + root.height

                if (outside && !onButton) root.activeMenu = null
            }
        }
    }

    onActiveMenuChanged: {
        if (root.popup) root.popup.shown = (root.activeMenu === root.popup)
    }

    Connections {
        target: root.popup
        function onCloseMenu() { root.activeMenu = null }
    }

    opacity: mouseArea.containsMouse ? 1 : 0.8
    Behavior on opacity { NumberAnimation { duration: 100 } }

    Item {
        id: contentContainer
        anchors.fill: parent
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                if (root.onMiddleClick) root.onMiddleClick(mouse)
                return
            }

            root.togglePopup()
        }
    }
}
