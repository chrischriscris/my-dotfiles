//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    IpcHandler {
        target: "shell"
        function checkClick(): void {
            bar.checkClick()
        }
        function toggleNotifications(): void {
            bar.toggleNotifications()
        }
    }

    Bar { id: bar }
    BottomCorners {}
    Dock {}
    NotificationToast {}
}
