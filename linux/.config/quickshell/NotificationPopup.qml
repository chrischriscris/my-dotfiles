import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

PopUp {
    id: root

    property real outerPadding: 16
    property real innerWidth: 284
    property real screenHeight: barWindow?.screen?.height ?? 1080
    property real barHeight: barWindow?.height ?? 48
    property real availableBelowBar: Math.max(screenHeight - barHeight - 12, 1)
    property real heightCap: Math.min(screenHeight * 0.6, 520)

    panelTargetWidth: 300
    windowHeight: Math.max(1, Math.min(availableBelowBar, heightCap))

    // Total desired height = header + separator + scrollable content (or empty state)
    // Column spacing is 4, applied between each visible child (2 gaps for 3 children)
    panelTargetHeight: Math.min(
        headerRow.height + separatorLine.height + 8 /* 2 × column spacing */ +
            Math.max(notifList.implicitHeight, emptyState.visible ? emptyState.height : 0)
            + outerPadding,
        windowHeight
    )

    // ── Panel open / close ───────────────────────────────────────────────────

    Connections {
        target: root
        function onShownChanged() {
            if (root.shown) {
                NotificationManager.panelOpen = true;
                NotificationManager.markAllRead();
                NotificationManager.dismissAllToasts();
            } else {
                NotificationManager.panelOpen = false;
            }
        }
    }

    // ── Layout: sticky header + scrollable list ──────────────────────────────

    Column {
        id: outerColumn
        anchors.centerIn: parent
        width: root.innerWidth
        spacing: 4

        // ── Sticky header ────────────────────────────────────────────────

        RowLayout {
            id: headerRow
            width: parent.width
            height: 28

            Text {
                text: "Notifications"
                color: "#fff"
                font {
                    pixelSize: 13
                    weight: Font.DemiBold
                }
                Layout.fillWidth: true
                Layout.leftMargin: 4
            }

            Rectangle {
                visible: !NotificationManager.clearing && NotificationManager.notifications.values.length > 0
                Layout.preferredWidth: clearText.implicitWidth + 16
                Layout.preferredHeight: 24
                radius: 4
                color: clearMouse.containsMouse ? "#333" : "transparent"

                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    id: clearText
                    anchors.centerIn: parent
                    text: "Clear All"
                    color: "#888"
                    font.pixelSize: 11
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // Clear all — panel stays open, shows empty state
                        NotificationManager.clearAll();
                    }
                }
            }
        }

        // ── Separator ────────────────────────────────────────────────────

        Rectangle {
            id: separatorLine
            width: parent.width - 8
            anchors.horizontalCenter: parent.horizontalCenter
            height: 1
            color: "#333"
        }

        // ── Empty state ──────────────────────────────────────────────────

        Text {
            id: emptyState
            visible: NotificationManager.clearing || NotificationManager.notifications.values.length === 0
            width: parent.width
            height: 48
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "No notifications"
            color: "#666"
            font.pixelSize: 13
        }

        // ── Scrollable notification list ─────────────────────────────────

        Flickable {
            id: scroller
            visible: !NotificationManager.clearing && NotificationManager.notifications.values.length > 0
            width: parent.width
            // Fill remaining space in the panel
            height: Math.max(1,
                root.panelHeight - root.outerPadding
                - headerRow.height - separatorLine.height - 8 /* 2 × column spacing */)
            clip: true
            contentWidth: width
            contentHeight: notifList.implicitHeight
            interactive: contentHeight > height

            Column {
                id: notifList
                width: scroller.width
                spacing: 0

                Repeater {
                    model: NotificationManager.clearing ? [] : NotificationManager.notifications.values

                    delegate: Item {
                        id: notifItem
                        required property var modelData

                        width: notifList.width
                        implicitHeight: swipeContent.implicitHeight
                        clip: true

                        // ── Swipe / click area ───────────────────────

                        MouseArea {
                            id: swipeArea
                            anchors.fill: parent
                            drag.target: swipeContent
                            drag.axis: Drag.XAxis
                            drag.minimumX: 0
                            drag.maximumX: notifItem.width
                            hoverEnabled: true

                            onReleased: {
                                if (swipeContent.x > notifItem.width * 0.3) {
                                    // Swipe dismiss: dismiss notification, panel stays open
                                    dismissSwipe.start();
                                } else {
                                    snapBack.start();
                                }
                            }

                            onClicked: {
                                const n = notifItem.modelData;
                                if (n.actions.length <= 1) {
                                    // 0 or 1 action: body click activates + dismisses + closes panel
                                    NotificationManager.activateOne(n);
                                    root.closeMenu();
                                }
                                // >1 actions: body click does nothing
                            }
                        }

                        // ── Swipeable content ────────────────────────

                        Item {
                            id: swipeContent
                            width: parent.width
                            implicitHeight: notifBackground.implicitHeight

                            opacity: 1 - (x / Math.max(notifItem.width, 1)) * 0.5

                            Rectangle {
                                id: notifBackground
                                width: parent.width
                                implicitHeight: notifContent.implicitHeight + 16
                                radius: 4
                                color: swipeArea.containsMouse ? "#222" : "transparent"

                                Behavior on color { ColorAnimation { duration: 100 } }
                            }

                            ColumnLayout {
                                id: notifContent
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: 8
                                }
                                spacing: 4

                                // Header: app icon + summary + close button
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    IconImage {
                                        visible: notifItem.modelData.appIcon !== ""
                                        source: notifItem.modelData.appIcon
                                        Layout.preferredWidth: 16
                                        Layout.preferredHeight: 16
                                    }

                                    Text {
                                        text: notifItem.modelData.summary
                                            || notifItem.modelData.appName
                                            || "Notification"
                                        color: "#fff"
                                        font {
                                            pixelSize: 13
                                            weight: Font.DemiBold
                                        }
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    // Close button — dismisses notification, panel stays open
                                    Text {
                                        text: "\u2715"
                                        color: dismissMouse.containsMouse ? "#fff" : "#666"
                                        font.pixelSize: 11

                                        Behavior on color { ColorAnimation { duration: 100 } }

                                        MouseArea {
                                            id: dismissMouse
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                NotificationManager.dismissOne(
                                                    notifItem.modelData);
                                            }
                                        }
                                    }
                                }

                                // App name (if different from summary)
                                Text {
                                    visible: notifItem.modelData.appName !== ""
                                        && notifItem.modelData.summary !== ""
                                        && notifItem.modelData.appName !== notifItem.modelData.summary
                                    text: notifItem.modelData.appName
                                    color: "#888"
                                    font.pixelSize: 11
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                // Body text
                                Text {
                                    visible: notifItem.modelData.body !== ""
                                    text: notifItem.modelData.body
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
                                    visible: notifItem.modelData.actions.length > 1
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Repeater {
                                        model: notifItem.modelData.actions

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
                                                    NotificationManager.activateAction(
                                                        notifItem.modelData, modelData);
                                                    root.closeMenu();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── Dismiss animations ──────────────────────

                        NumberAnimation {
                            id: dismissSwipe
                            target: swipeContent; property: "x"
                            to: notifItem.width
                            duration: 150; easing.type: Easing.InOutQuad
                            onFinished: {
                                NotificationManager.dismissOne(notifItem.modelData);
                            }
                        }

                        NumberAnimation {
                            id: snapBack
                            target: swipeContent; property: "x"
                            to: 0
                            duration: 100; easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }
    }

    // Reset scroll position when closed
    onVisibleChanged: {
        if (!visible) scroller.contentY = 0;
    }
}
