import QtQuick
import QtQuick.Effects
import Quickshell

Rectangle {
    id: root

    required property LockScreen lockContext
    color: "#000000"

    Item {
        id: blurContainer
        anchors.fill: parent
        visible: screenshotBg.status === Image.Ready

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            autoPaddingEnabled: false
            blur: root.lockContext.blurPass2Amount
            blurMax: root.lockContext.blurPass2Max
            blurMultiplier: root.lockContext.blurPass2Multiplier
            saturation: root.lockContext.blurPass2Saturation
        }

        Image {
            id: screenshotBg
            anchors.fill: parent
            source: root.lockContext.screenshotPath
            fillMode: Image.PreserveAspectCrop
            cache: false

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                autoPaddingEnabled: false
                blur: root.lockContext.blurPass1Amount
                blurMax: root.lockContext.blurPass1Max
                blurMultiplier: root.lockContext.blurPass1Multiplier
                saturation: root.lockContext.blurPass1Saturation
            }
        }
    }

    Image {
        anchors.fill: parent
        source: "noise.png"
        fillMode: Image.Tile
        smooth: false
        cache: true
        visible: status === Image.Ready && root.lockContext.ditherStrength > 0
        opacity: root.lockContext.ditherStrength
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, root.lockContext.tintOpacity)
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
        width: 320

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                const d = clock.date;
                if (!d || !(d instanceof Date) || isNaN(d.getTime())) return "";
                return Qt.formatDateTime(d, "HH:mm");
            }
            color: "#ffffff"
            font.pixelSize: 72
            font.weight: Font.Light
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 4
            text: {
                const d = clock.date;
                if (!d || !(d instanceof Date) || isNaN(d.getTime())) return "";
                return Qt.formatDateTime(d, "dddd, MMMM d");
            }
            color: "#aaaaaa"
            font.pixelSize: 16
        }

        Item { width: 1; height: 48 }

        Rectangle {
            id: passwordContainer
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280
            height: 40
            radius: 20
            color: root.lockContext.unlockInProgress ? "#25ffffff" : "#33ffffff"
            border.color: root.lockContext.unlockInProgress ? "#30ffffff"
                        : passwordInput.activeFocus ? "#80ffffff" : "#40ffffff"
            border.width: 1

            Behavior on border.color { ColorAnimation { duration: 150 } }
            Behavior on color { ColorAnimation { duration: 150 } }

            TextInput {
                id: passwordInput
                anchors {
                    fill: parent
                    leftMargin: 16
                    rightMargin: 16
                }
                verticalAlignment: TextInput.AlignVCenter
                color: "#ffffff"
                selectionColor: "#555555"
                font.pixelSize: 14
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData
                clip: true
                visible: !root.lockContext.unlockInProgress

                enabled: !root.lockContext.unlockInProgress
                focus: true

                onTextChanged: root.lockContext.currentText = text
                onAccepted: root.lockContext.tryUnlock()

                Connections {
                    target: root.lockContext

                    function onCurrentTextChanged() {
                        if (passwordInput.text !== root.lockContext.currentText) {
                            passwordInput.text = root.lockContext.currentText;
                        }
                    }
                }
            }

            Text {
                anchors {
                    fill: parent
                    leftMargin: 16
                    rightMargin: 16
                }
                verticalAlignment: Text.AlignVCenter
                text: "Password"
                color: "#66ffffff"
                font.pixelSize: 14
                visible: passwordInput.text === "" && !root.lockContext.unlockInProgress
            }

            Row {
                anchors.centerIn: parent
                spacing: 10
                visible: root.lockContext.unlockInProgress

                Item {
                    id: spinner
                    width: 18
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter

                    Canvas {
                        anchors.fill: parent
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = "#aaffffff";
                            ctx.lineWidth = 2;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.arc(width / 2, height / 2, width / 2 - 2, 0, Math.PI * 1.5);
                            ctx.stroke();
                        }
                        Component.onCompleted: requestPaint()
                    }

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 800
                        loops: Animation.Infinite
                        running: spinner.visible
                    }
                }

                Text {
                    text: "Authenticating..."
                    color: "#88ffffff"
                    font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Item { width: 1; height: 12 }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Incorrect password"
            color: "#ff6666"
            font.pixelSize: 13
            height: 20

            opacity: root.lockContext.showFailure ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

}
