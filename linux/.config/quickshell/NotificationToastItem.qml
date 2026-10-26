import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

Item {
    id: toastItem

    required property var notif
    required property int index

    signal removed()

    height: swipeContent.implicitHeight
    clip: true

    // ── Race condition guard ─────────────────────────────────────────────────
    //
    // _exiting prevents multiple dismissal paths from triggering simultaneously.
    // _notifHandled tracks whether the notification was already dismissed/invoked
    // (used by swipe animation onFinished to know if it should dismiss).

    property bool _exiting: false
    property bool _notifHandled: false

    function beginExit() {
        if (_exiting) return false;
        _exiting = true;
        return true;
    }

    // Dismiss the notification directly (bypass NotificationManager.dismissOne
    // to avoid emitting notificationDismissed, which would cause the toast
    // container to remove us from the model while our animation is running).
    function _dismissNotif() {
        NotificationManager.markOneRead();
        toastItem.notif.dismiss();
    }

    // ── Auto-dismiss timer ───────────────────────────────────────────────────

    Timer {
        id: autoDismiss
        running: !toastItem._exiting
        interval: {
            const t = toastItem.notif.expireTimeout;
            if (t > 0) return Math.min(t * 1000, 10000);
            return NotificationManager.toastDurationMs;
        }
        onTriggered: {
            // Timeout: dismiss toast only, keep notification active
            if (!toastItem.beginExit()) return;
            fadeOut.restart();
        }
    }

    // ── Swipe / click handler ────────────────────────────────────────────────

    MouseArea {
        id: swipeArea
        anchors.fill: parent
        drag.target: swipeContent
        drag.axis: Drag.XAxis
        drag.minimumX: 0
        drag.maximumX: toastItem.width

        cursorShape: Qt.PointingHandCursor

        onReleased: {
            if (swipeContent.x > toastItem.width * 0.3) {
                // Swipe dismiss: animate out, then dismiss notification
                if (!toastItem.beginExit()) return;
                dismissSwipe.start();
            } else {
                snapBack.start();
            }
        }

        onClicked: {
            if (toastItem._exiting) return;
            const n = toastItem.notif;

            if (n.actions.length <= 1) {
                // 0 or 1 action: body click activates + dismisses
                if (!toastItem.beginExit()) return;
                if (n.actions.length > 0) n.actions[0].invoke();
                toastItem._dismissNotif();
                toastItem._notifHandled = true;
                fadeOut.restart();
            }
            // >1 actions: body click does nothing (user must use action buttons)
        }
    }

    // ── Swipeable content ────────────────────────────────────────────────────

    Item {
        id: swipeContent
        width: parent.width
        implicitHeight: toastEntry.implicitHeight
            + (toastItem.index > 0
                ? separator.height + separator.anchors.topMargin * 2
                : 0)

        // Fade as it slides right
        opacity: 1 - (x / Math.max(toastItem.width, 1)) * 0.5

        // Separator between entries
        Rectangle {
            id: separator
            visible: toastItem.index > 0
            width: parent.width
            height: visible ? 1 : 0
            color: "#333"
            anchors {
                top: parent.top
                topMargin: visible ? 6 : 0
            }
        }

        ColumnLayout {
            id: toastEntry
            anchors {
                left: parent.left
                right: parent.right
                top: separator.visible ? separator.bottom : parent.top
                topMargin: separator.visible ? 6 : 0
            }
            spacing: 4

            // Header: app icon + summary + close
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                IconImage {
                    visible: toastItem.notif.appIcon !== ""
                    source: toastItem.notif.appIcon
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                }

                Text {
                    text: toastItem.notif.summary
                        || toastItem.notif.appName
                        || "Notification"
                    color: "#fff"
                    font {
                        pixelSize: 14
                        weight: Font.DemiBold
                    }
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                // Close button
                Text {
                    text: "\u2715"
                    color: closeMouse.containsMouse ? "#fff" : "#666"
                    font.pixelSize: 12

                    Behavior on color { ColorAnimation { duration: 100 } }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Close button: dismiss toast + notification
                            if (!toastItem.beginExit()) return;
                            toastItem._dismissNotif();
                            toastItem._notifHandled = true;
                            fadeOut.restart();
                        }
                    }
                }
            }

            // App name (when summary is present and different)
            Text {
                visible: toastItem.notif.appName !== ""
                    && toastItem.notif.summary !== ""
                    && toastItem.notif.appName !== toastItem.notif.summary
                text: toastItem.notif.appName
                color: "#888"
                font.pixelSize: 11
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // Body
            Text {
                visible: toastItem.notif.body !== ""
                text: toastItem.notif.body
                color: "#ccc"
                font.pixelSize: 12
                textFormat: Text.PlainText
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }

            // Action buttons (shown only when >1 action)
            RowLayout {
                visible: toastItem.notif.actions.length > 1
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: toastItem.notif.actions

                    delegate: Rectangle {
                        required property var modelData

                        Layout.preferredWidth: actionText.implicitWidth + 12
                        Layout.preferredHeight: 22
                        radius: 4
                        color: actionMouse.containsMouse ? "#555" : "#333"

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: modelData.text
                            color: "#CF577C" // was "#FD7C40"
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // Action button: invoke action, dismiss, swipe out
                                if (!toastItem.beginExit()) return;
                                modelData.invoke();
                                toastItem._dismissNotif();
                                toastItem._notifHandled = true;
                                dismissSwipe.start();
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Dismiss animations ───────────────────────────────────────────────────

    // Fade out (used by auto-dismiss, body click, and close button).
    NumberAnimation {
        id: fadeOut
        target: toastItem; property: "opacity"
        to: 0; duration: 150; easing.type: Easing.InOutQuad
        onFinished: toastItem.removed()
    }

    // Swipe right (used by swipe gesture and action button clicks).
    NumberAnimation {
        id: dismissSwipe
        target: swipeContent; property: "x"
        to: toastItem.width
        duration: 150; easing.type: Easing.InOutQuad
        onFinished: {
            // Swipe gesture dismisses on finish. Action buttons and other paths
            // set _notifHandled = true before starting the animation.
            if (!toastItem._notifHandled) {
                toastItem._dismissNotif();
            }
            toastItem.removed();
        }
    }

    NumberAnimation {
        id: snapBack
        target: swipeContent; property: "x"
        to: 0
        duration: 100; easing.type: Easing.InOutQuad
    }
}
