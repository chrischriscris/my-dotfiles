import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower

BarButton {
    id: root
    readonly property var device: UPower.displayDevice
    readonly property bool hasBattery: !!device && device.ready && device.isLaptopBattery && device.isPresent
    visible: hasBattery

    popup: brightnessPopup

    BrightnessPopup {
        id: brightnessPopup
        barWindow: root.barWindow
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton

        onWheel: wheel => {
            if (!brightnessPopup.initialReadDone) return
            const step = wheel.angleDelta.y / 120 * 0.05
            const minBrightness = Math.round(0.01 * brightnessPopup.maxBrightness)
            brightnessPopup.currentBrightness = Math.max(minBrightness, Math.min(brightnessPopup.maxBrightness, brightnessPopup.currentBrightness + Math.round(step * brightnessPopup.maxBrightness)))
        }
    }

    RowLayout {
        id: row
        spacing: 6

        function batteryPercent() {
            if (!root.hasBattery) return -1
            return Math.max(0, Math.min(100, Math.round(root.device.percentage * 100)))
        }

        function batteryIcon() {
            if (!root.hasBattery) return ""

            if (root.device.state === UPowerDeviceState.Charging ||
                root.device.state === UPowerDeviceState.PendingCharge) {
                return Qt.resolvedUrl("icons/battery-charging.svg")
            }

            const p = batteryPercent()
            if (p < 0)  return ""
            if (p < 10) return Qt.resolvedUrl("icons/battery-low.svg")
            if (p < 30) return Qt.resolvedUrl("icons/battery-20.svg")
            if (p < 50) return Qt.resolvedUrl("icons/battery-40.svg")
            if (p < 70) return Qt.resolvedUrl("icons/battery-60.svg")
            if (p < 90) return Qt.resolvedUrl("icons/battery-80.svg")
            return Qt.resolvedUrl("icons/battery-100.svg")
        }

        IconImage {
            width: 20
            height: 20
            source: row.batteryIcon()
        }

        Text {
            color: "#8CFFA9"
            font.pixelSize: 16
            text: {
                const percent = row.batteryPercent()
                if (percent < 0) return ""
                return percent + "%"
            }
        }
    }
}
