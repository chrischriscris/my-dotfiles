import QtQuick
import Quickshell

PopupWindow {
    id: root

    default property alias content: contentLayer.data

    property var barWindow
    property bool shown: false

    // Sizing
    property real panelTargetWidth: 1
    property real panelTargetHeight: 1
    property real windowHeight: panelTargetHeight  // override to fix window height (e.g. Calendar, TrayMenu)
    property real panelHeight: panelTargetHeight   // driven imperatively when open
    property real cornerSize: 16

    // Grow reveal (0=collapsed, 1=fully grown) — driven imperatively
    property real reveal: 0

    // Edge snap state — set by clampToScreen()
    property bool snappedLeft: false
    property bool snappedRight: false

    // Horizontal panel offset inside popup window (for snapped edges)
    property real panelX: snappedLeft ? 0 : (snappedRight ? cornerSize * 2 : cornerSize)
    property bool _closeImmediateNext: false

    signal closeMenu()

    function closeMenuNow() {
        _closeImmediateNext = true
        closeMenu()
    }

    anchor.edges: Edges.Top | Edges.Left
    anchor.adjustment: PopupAdjustment.None

    implicitWidth:  Math.max(panelTargetWidth + cornerSize * 2, 1)
    implicitHeight: Math.max(windowHeight + cornerSize, 1)
    visible: reveal > 0 || shown
    color: "transparent"

    // ── Public API ────────────────────────────────────────────────────────────

    // Called by BarButton / Tray after setting anchor.rect
    function clampToScreen() {
        const win = root.anchor.window
        if (!win || !win.screen) return
        const popupW = root.panelTargetWidth + root.cornerSize * 2
        const windowW = win.screen.width
        const minX = 0
        const maxX = Math.max(windowW - popupW, 0)
        const desired = root.anchor.rect.x
        const clamped = Math.max(minX, Math.min(maxX, desired))
        root.anchor.rect.x = clamped
        const eps = 0.5
        if (maxX <= eps) {
            root.snappedLeft = true
            root.snappedRight = false
        } else {
            root.snappedLeft  = clamped <= minX + eps
            root.snappedRight = clamped >= maxX - eps
        }
    }

    // ── Position helpers (used by clickaway) ─────────────────────────────────

    function panelTopLeft(win) {
        const s = win.screen
        const a = win.anchors
        const m = win.margins
        let x = s.x + (a.left   ? m.left   : 0)
        let y = s.y + (a.top    ? m.top    : 0)
        if (a.right  && !a.left)  x = s.x + s.width  - win.width  - m.right
        if (a.bottom && !a.top)   y = s.y + s.height - win.height - m.bottom
        return Qt.point(x, y)
    }

    function popupApproxTopLeftOnScreen(popup) {
        const parent = popup.anchor.window
        if (!parent || !parent.screen) return Qt.point(0, 0)
        const base = panelTopLeft(parent)
        const r = popup.anchor.rect
        const e = popup.anchor.edges
        const g = popup.anchor.gravity
        const ax = base.x + r.x + ((e & Edges.Right)  ? r.width  : 0)
        const ay = base.y + r.y + ((e & Edges.Bottom) ? r.height : 0)
        let px
        if      (g & Edges.Left)  px = ax - popup.width
        else if (g & Edges.Right) px = ax
        else                      px = ax - popup.width / 2
        let py
        if      (g & Edges.Top)    py = ay - popup.height
        else if (g & Edges.Bottom) py = ay
        else                       py = ay - popup.height / 2
        return Qt.point(px, py)
    }

    // Panel rect in screen coords
    function popupApproxPanelRectOnScreen(popup) {
        const p  = popupApproxTopLeftOnScreen(popup)
        const currentH = popup.panelHeight * popup.reveal
        return Qt.rect(
            p.x + popup.panelX,
            p.y,
            popup.panelTargetWidth,
            currentH
        )
    }

    // Clickaway hit test — corners excluded, always closes on hit outside
    function containsScreenPoint(x, y) {
        const r = popupApproxPanelRectOnScreen(root)
        return x >= r.x && x <= r.x + r.width &&
               y >= r.y && y <= r.y + r.height
    }

    // ── Animations ───────────────────────────────────────────────────────────

    // Shape grow/collapse — drives reveal
    NumberAnimation {
        id: growOpen
        target: root; property: "reveal"
        to: 1; duration: 200; easing.type: Easing.InOutQuad
    }
    NumberAnimation {
        id: growClose
        target: root; property: "reveal"
        to: 0; duration: 200; easing.type: Easing.InOutQuad
    }

    // Panel height resize (only while open, for dynamic content like TrayMenu)
    NumberAnimation {
        id: panelResize
        target: root; property: "panelHeight"
        duration: 200; easing.type: Easing.InOutQuad
    }

    // Content opacity
    NumberAnimation {
        id: contentFadeIn
        target: contentLayer; property: "opacity"
        to: 1; duration: 200; easing.type: Easing.InOutQuad
    }
    NumberAnimation {
        id: contentFadeOut
        target: contentLayer; property: "opacity"
        to: 0; duration: 150; easing.type: Easing.InOutQuad
    }

    // Re-clamp once layout settles (e.g. dynamic width menus)
    Timer {
        id: reclampTimer
        interval: 0
        repeat: false
        onTriggered: {
            if (root.shown) root.clampToScreen()
        }
    }

    // ── Triggers ─────────────────────────────────────────────────────────────

    onShownChanged: {
        if (shown) {
            _closeImmediateNext = false
            root.clampToScreen()
            reclampTimer.restart()

            // Stop close animations
            growClose.stop()
            contentFadeOut.stop()

            // Start open animations
            growOpen.restart()
            contentFadeIn.restart()
        } else {
            if (_closeImmediateNext) {
                _closeImmediateNext = false
                growOpen.stop()
                contentFadeIn.stop()
                growClose.stop()
                contentFadeOut.stop()
                reveal = 0
                contentLayer.opacity = 0
                panelHeight = panelTargetHeight
                return
            }

            // Stop open animations
            growOpen.stop()
            contentFadeIn.stop()

            // Start close animations
            growClose.restart()
            contentFadeOut.restart()
        }
    }

    onPanelTargetWidthChanged: {
        if (shown) reclampTimer.restart()
    }

    onPanelTargetHeightChanged: {
        if (shown) {
            panelResize.to = panelTargetHeight
            panelResize.restart()
        } else {
            panelHeight = panelTargetHeight
        }
    }

    // ── Visual ───────────────────────────────────────────────────────────────

    // Unified menu shape — single path with concave top corners and convex bottom.
    // Positioned at y=-cornerSize so shape-local y=R (the ear tips and panel top)
    // maps to popup y=0, flush with the bar's bottom edge. The top R pixels of
    // the shape (empty padding) extend above the popup surface and get clipped
    // harmlessly by the compositor.
    MenuShape {
        id: menuShape

        panelWidth:  root.panelTargetWidth
        panelHeight: root.panelHeight * root.reveal
        cornerRadius: root.cornerSize
        fillColor: "#000000"
        flushTop: true
        flushLeft: root.snappedLeft
        flushRight: root.snappedRight

        x: root.panelX - root.cornerSize
        y: -root.cornerSize
    }

    // Content area — clipped to the panel bounds, slides down + fades in.
    // Starts at y=0 (popup top = bar bottom = panel body top).
    Item {
        id: contentClip
        x: root.panelX
        y: 0
        width: root.panelTargetWidth
        height: root.panelHeight * root.reveal
        clip: true

        Item {
            id: contentLayer
            width: parent.width
            height: root.panelHeight

            // Content slides down from the top as the panel grows
            y: -(1 - root.reveal) * root.panelHeight

            opacity: 0
        }
    }
}
