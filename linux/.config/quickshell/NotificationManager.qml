pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    // ── Public state ─────────────────────────────────────────────────────────

    property alias notifications: server.trackedNotifications
    property int unreadCount: 0
    property bool panelOpen: false

    // ── Configuration ────────────────────────────────────────────────────────

    property int toastDurationMs: 5000
    property int maxVisibleToasts: 3
    property int unreadBadgeMax: 99
    property bool clearing: false

    // ── Signals ──────────────────────────────────────────────────────────────

    signal newNotification(var notification)
    signal dismissAllToasts()
    signal notificationDismissed(var notification)

    // ── D-Bus server ─────────────────────────────────────────────────────────

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: notification => {
            notification.tracked = true;

            // Reload artifacts — don't count as new
            if (notification.lastGeneration) return;

            if (root.panelOpen) {
                // Panel is visible — notification appears in list reactively.
                // Don't increment unread (user is looking), don't show toast.
                return;
            }

            root.unreadCount++;
            root.newNotification(notification);
        }
    }

    // ── Public methods ───────────────────────────────────────────────────────

    /// Dismiss a single notification (close button, swipe, etc.)
    function dismissOne(notification) {
        markOneRead();
        notification.dismiss();
        root.notificationDismissed(notification);
    }

    /// Activate a notification's default (first) action, then dismiss it.
    function activateOne(notification) {
        if (notification.actions.length > 0) {
            notification.actions[0].invoke();
        }
        dismissOne(notification);
    }

    /// Activate a specific action on a notification, then dismiss it.
    function activateAction(notification, action) {
        action.invoke();
        dismissOne(notification);
    }

    /// Dismiss every tracked notification and clear toasts.
    function clearAll() {
        root.clearing = true;
        const vals = server.trackedNotifications.values;
        const snapshot = [];
        for (let i = 0; i < vals.length; i++) snapshot.push(vals[i]);
        for (let i = 0; i < snapshot.length; i++) snapshot[i].dismiss();
        root.clearing = false;
        root.unreadCount = 0;
        root.dismissAllToasts();
    }

    /// Mark all notifications as read (unread count → 0). Does not dismiss.
    function markAllRead() {
        root.unreadCount = 0;
    }

    /// Decrement unread count by one (floor 0).
    function markOneRead() {
        if (root.unreadCount > 0) root.unreadCount--;
    }
}
