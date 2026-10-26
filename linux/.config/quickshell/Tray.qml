import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray

RowLayout {
    id: root

    property var barWindow
    property var activeMenu: null
    property var activeItem: null

    function checkClick(): void {
        if (!root.activeMenu || !root.activeMenu.visible) return
        cursorProcess.running = true
    }

    // Process to get cursor position from Hyprland
    Process {
        id: cursorProcess
        command: ["hyprctl", "cursorpos"]

        stdout: SplitParser {
            onRead: data => {
                if (!root.activeMenu) return

                // Parse "X, Y" format
                const parts = data.trim().split(",")
                if (parts.length !== 2) return

                const x = parseInt(parts[0].trim())
                const y = parseInt(parts[1].trim())

                // Get menu bounds
                const menu = root.activeMenu
                let outside
                if (menu.containsScreenPoint) {
                    outside = !menu.containsScreenPoint(x, y)
                } else {
                    const pos = menu.popupApproxTopLeftOnScreen(menu)
                    const menuX = pos.x
                    const menuY = pos.y
                    const menuW = menu.width
                    const menuH = menu.height
                    outside = x < menuX || x > menuX + menuW ||
                              y < menuY || y > menuY + menuH
                }

                // Ignore clicks on the button that owns the open menu
                let onButton = false
                if (root.activeItem) {
                    const btn = root.activeItem.mapToItem(null, 0, 0)
                    const btnX = root.barWindow.screen.x + btn.x
                    const btnY = root.barWindow.screen.y + btn.y
                    onButton = x >= btnX && x <= btnX + root.activeItem.width &&
                               y >= btnY && y <= btnY + root.activeItem.height
                }

                if (outside && !onButton) {
                    root.activeMenu = null
                    root.activeItem = null
                }
            }
        }
    }

    Repeater {
        model: SystemTray.items.values

        Item {
            id: trayItem
            implicitWidth: 22
            implicitHeight: 22

            required property var modelData

            visible: modelData.status !== SystemTrayItem.Passive

            property var iconCandidates: []
            property int iconIndex: 0

            // Subtle hover effect
            opacity: mouseArea.containsMouse ? 1 : 0.8
            Behavior on opacity { NumberAnimation { duration: 100 } }

            function rebuildIconCandidates() {
                const s = modelData.icon || ""

                // Matches:
                // 1) image://icon/<name>?path=<dir>...
                // 2) image://icon/<name>
                const mWithPath = s.match(/^image:\/\/icon\/([^?]+)\?path=([^&]+).*$/)
                const mNoPath   = s.match(/^image:\/\/icon\/([^?]+)$/)

                function stripSymbolic(name) {
                    // common case: foo-symbolic
                    return name.endsWith("-symbolic") ? name.slice(0, -"-symbolic".length) : name
                }

                function addIf(v) {
                    if (v && v.length > 0) iconCandidates.push(v)
                }

                iconCandidates = []
                iconIndex = 0

                if (mWithPath || mNoPath) {
                    const name = (mWithPath ? mWithPath[1] : mNoPath[1]) || ""
                    const dir  = mWithPath ? mWithPath[2] : ""

                    const clean = stripSymbolic(name)

                    // 1) Theme lookup, prefer non-symbolic name first
                    addIf(Quickshell.iconPath(clean, true))
                    addIf(Quickshell.iconPath(name, true))

                    // 2) If the tray item provides a concrete icon directory, try files there too
                    // Prefer non-symbolic filenames first, then original.
                    if (dir) {
                        const exts = [".png", ".svg", ".xpm"]
                        for (let i = 0; i < exts.length; i++) addIf("file://" + dir + "/" + clean + exts[i])
                        for (let j = 0; j < exts.length; j++) addIf("file://" + dir + "/" + name  + exts[j])
                    }

                    // 3) Last resort: whatever the item gave us
                    addIf(s)
                } else {
                    // Already a usable URL (file://, qrc:/, data:, etc.)
                    iconCandidates = [s]
                }

                icon.source = iconCandidates[0] || ""
            }


            IconImage {
                id: icon
                anchors.fill: parent
                onStatusChanged: {
                    if (status === Image.Error && iconIndex < iconCandidates.length - 1) {
                        iconIndex++
                        source = iconCandidates[iconIndex]
                    }
                }
            }

            Component.onCompleted: rebuildIconCandidates()

            Connections {
                target: modelData
                function onIconChanged() { rebuildIconCandidates() }
            }

            TrayMenu {
                id: menu
                menuHandle: trayItem.modelData.menu
                barWindow: root.barWindow
                shown: root.activeMenu === menu
                onCloseMenu: { root.activeMenu = null; root.activeItem = null }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        if (modelData.onlyMenu && modelData.hasMenu)
                            toggleMenu()
                        else
                            modelData.activate()
                    } else if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                        toggleMenu()
                    } else if (mouse.button === Qt.MiddleButton) {
                        modelData.secondaryActivate()
                    }
                }

                onWheel: wheel => modelData.scroll(wheel.angleDelta.y / 120, wheel.angleDelta.x !== 0)

                function toggleMenu() {
                    if (root.activeMenu === menu) {
                        root.activeMenu = null
                        root.activeItem = null
                    } else {
                        const pos = trayItem.mapToItem(null, trayItem.width / 2, 0)
                        const barBottom = root.barWindow
                            ? (root.barWindow.exclusiveZone > 0 ? root.barWindow.exclusiveZone : root.barWindow.height)
                            : trayItem.height
                        const popupW = Math.max((menu.panelTargetWidth ?? menu.width ?? 1) + (menu.cornerSize ?? 0) * 2, 1)
                        menu.anchor.window = root.barWindow
                        menu.anchor.rect.x = pos.x - popupW / 2
                        menu.anchor.rect.y = Math.max(0, barBottom)
                        menu.anchor.rect.width = 1
                        menu.anchor.rect.height = 1
                        menu.anchor.gravity = Edges.Bottom | Edges.Right
                        root.activeMenu = menu
                        root.activeItem = trayItem
                        if (menu.clampToScreen) menu.clampToScreen()
                    }
                }
            }
        }
    }
}
