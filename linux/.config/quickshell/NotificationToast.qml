import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    // ── Layout constants ─────────────────────────────────────────────────────

    property real cornerSize: 16
    property real panelWidth: 288
    property real barGap: 0
    property real contentPadding: 8

    // ── Animation state ──────────────────────────────────────────────────────

    property real reveal: 0              // 0 = closed, 1 = fully open
    property real panelHeight: 0         // animated — drives MenuShape + content clip
    property real windowPanelHeight: 0   // drives window size — snaps on grow, syncs on shrink finish
    property bool shouldBeVisible: false // explicit visibility flag

    // Desired panel height — derived from content, used by doUpdateGeometry.
    readonly property real targetPanelHeight:
        toastModel.count > 0 && toastList.contentHeight > 0
            ? toastList.contentHeight + contentPadding * 2
            : 0

    // ── Data model ───────────────────────────────────────────────────────────

    ListModel {
        id: toastModel
    }

    Connections {
        target: NotificationManager

        function onNewNotification(notification) {
            // Safety: manager suppresses this when panel is open, but guard anyway
            if (NotificationManager.panelOpen) return;

            while (toastModel.count >= NotificationManager.maxVisibleToasts) {
                toastModel.remove(toastModel.count - 1);
            }
            toastModel.insert(0, { notif: notification });
        }

        function onDismissAllToasts() {
            toastModel.clear();
        }

        function onNotificationDismissed(notification) {
            root.removeToastByRef(notification);
        }
    }

    function removeToastByIndex(index) {
        if (index >= 0 && index < toastModel.count) {
            toastModel.remove(index);
        }
    }

    function removeToastByRef(notification) {
        for (let i = 0; i < toastModel.count; i++) {
            if (toastModel.get(i).notif === notification) {
                toastModel.remove(i);
                return;
            }
        }
    }

    // ── Geometry engine ──────────────────────────────────────────────────────
    //
    // Every change flows through targetPanelHeight (a reactive binding on
    // toastModel.count + toastList.contentHeight).  When it changes we
    // schedule a geometry update via a zero-interval timer so that rapid
    // successive changes in the same frame are batched into one.

    onTargetPanelHeightChanged: geometryTimer.restart()

    Timer {
        id: geometryTimer
        interval: 0
        onTriggered: root.doUpdateGeometry()
    }

    function doUpdateGeometry() {
        const count = toastModel.count;
        const targetH = root.targetPanelHeight;

        // ── Close ────────────────────────────────────────────────────
        if (count === 0 || targetH <= 0) {
            if (reveal > 0 || revealIn.running) {
                revealIn.stop();
                fadeIn.stop();
                heightAnim.stop();
                revealOut.restart();
                fadeOut.restart();
            } else if (!revealOut.running) {
                // Already fully closed — ensure clean state
                shouldBeVisible = false;
                windowPanelHeight = 0;
                panelHeight = 0;
            }
            return;
        }

        // ── Opening (from closed or mid-close) ──────────────────────
        if (revealOut.running || (reveal === 0 && !revealIn.running)) {
            revealOut.stop();
            fadeOut.stop();
            heightAnim.stop();
            shouldBeVisible = true;
            panelHeight = targetH;
            windowPanelHeight = targetH;
            revealIn.restart();
            fadeIn.restart();
            return;
        }

        // ── Growing (or same size) while open ────────────────────────
        // Compare against the heightAnim target if it's running, so we
        // don't snap past an in-flight shrink that hasn't finished yet.
        var effectiveH = heightAnim.running ? heightAnim.to : panelHeight;
        if (targetH >= effectiveH) {
            heightAnim.stop();
            panelHeight = targetH;
            windowPanelHeight = targetH;
            return;
        }

        // ── Shrinking while open ─────────────────────────────────────
        heightAnim.to = targetH;
        heightAnim.restart();
    }

    // ── Animations ───────────────────────────────────────────────────────────

    NumberAnimation {
        id: revealIn
        target: root; property: "reveal"
        to: 1; duration: 200; easing.type: Easing.InOutQuad
    }

    NumberAnimation {
        id: revealOut
        target: root; property: "reveal"
        to: 0; duration: 200; easing.type: Easing.InOutQuad
        onFinished: {
            root.shouldBeVisible = false;
            root.windowPanelHeight = 0;
            root.panelHeight = 0;
        }
    }

    NumberAnimation {
        id: heightAnim
        target: root; property: "panelHeight"
        duration: 200; easing.type: Easing.InOutQuad
        onFinished: root.windowPanelHeight = root.panelHeight
    }

    NumberAnimation {
        id: fadeIn
        target: contentLayer; property: "opacity"
        to: 1; duration: 200; easing.type: Easing.InOutQuad
    }

    NumberAnimation {
        id: fadeOut
        target: contentLayer; property: "opacity"
        to: 0; duration: 150; easing.type: Easing.InOutQuad
    }

    // ── Window ───────────────────────────────────────────────────────────────

    PanelWindow {
        id: toastWindow

        anchors {
            top: true
            right: true
        }
        implicitWidth: root.panelWidth + root.cornerSize
        implicitHeight: Math.max(1, root.barGap + root.windowPanelHeight + root.cornerSize)
        exclusiveZone: 0
        color: "transparent"
        visible: root.shouldBeVisible || toastModel.count > 0

        // Unified panel background — flushTop + flushRight for concave
        // connection to bar and right screen edge.
        MenuShape {
            panelWidth:  root.panelWidth
            panelHeight: root.panelHeight * root.reveal
            cornerRadius: root.cornerSize
            fillColor: "#000000"
            flushTop: true
            flushRight: true
            x: 0
            y: root.barGap - root.cornerSize
        }

        // Content area — clipped to the panel bounds, slides down + fades in.
        Item {
            id: contentClip
            x: root.cornerSize
            y: root.barGap
            width: root.panelWidth - root.cornerSize
            height: root.panelHeight * root.reveal
            clip: true

            Item {
                id: contentLayer
                width: parent.width
                height: root.panelHeight

                // Content slides down from the top as the panel grows
                y: -(1 - root.reveal) * root.panelHeight

                opacity: 0

                ListView {
                    id: toastList

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        topMargin: root.contentPadding
                    }
                    width: parent.width - root.contentPadding * 2
                    height: contentHeight
                    interactive: false
                    spacing: 0
                    model: toastModel

                    // New toast slides in from above its final position
                    add: Transition {
                        id: addTrans
                        NumberAnimation {
                            property: "y"
                            from: addTrans.ViewTransition.destination.y - addTrans.ViewTransition.item.height
                            duration: 200; easing.type: Easing.InOutQuad
                        }
                    }

                    // Existing toasts slide down when a new one is added
                    addDisplaced: Transition {
                        NumberAnimation {
                            property: "y"; duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }

                    // Remaining toasts slide up when one is removed
                    removeDisplaced: Transition {
                        NumberAnimation {
                            property: "y"; duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }

                    delegate: NotificationToastItem {
                        width: toastList.width
                        onRemoved: root.removeToastByIndex(index)
                    }
                }
            }
        }
    }
}
