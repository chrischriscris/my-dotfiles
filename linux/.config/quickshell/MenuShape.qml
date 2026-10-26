import QtQuick
import QtQuick.Shapes

// Unified menu shape using cubic Bezier curves.
// Renders the entire menu outline as a single Shape path with each corner
// independently computed as one of three states:
//
//   convex:  standard rounded corner (neither adjacent edge is flush)
//   concave: inverse curve bulging outward (exactly one adjacent edge is flush)
//   square:  degenerate right angle (both adjacent edges are flush)
//
// This is a general-purpose component: any combination of flush flags can
// be set independently. The shape grows/collapses by animating panelHeight
// (or panelWidth for horizontal grow), which naturally morphs the concave
// curves via clamped radius values.

Shape {
    id: root

    // ── Public properties ────────────────────────────────────────────────────

    property real panelWidth: 100
    property real panelHeight: 100
    property real cornerRadius: 16
    property color fillColor: "#000000"

    // Flush flags — which edges connect to a parent surface (bar, screen edge, etc.)
    // Each corner's state is determined by its two adjacent flush flags:
    //   both flush → square | neither flush → convex | one flush → concave
    property bool flushTop: false
    property bool flushBottom: false
    property bool flushLeft: false
    property bool flushRight: false

    // ── Derived values ───────────────────────────────────────────────────────

    // Bezier circle approximation constant: 4/3 * (sqrt(2) - 1)
    readonly property real _K: 0.5522847498
    readonly property real _R: cornerRadius
    readonly property real _kR: _K * _R

    // Clamped radii — when a dimension is smaller than 2*R, opposing corners
    // (concave on one side, convex on the other) must share the available
    // space. Each gets at most half the dimension, preventing path overlap
    // during grow/collapse animations.
    readonly property real _rh: Math.min(_R, panelHeight / 2)
    readonly property real _rw: Math.min(_R, panelWidth / 2)
    readonly property real _kRh: _K * _rh
    readonly property real _kRw: _K * _rw

    // Box bounds in local coordinates (R padding on all sides for concave extensions)
    readonly property real _L: _R                   // box left
    readonly property real _T: _R                   // box top
    readonly property real _Ri: _R + panelWidth     // box right
    readonly property real _B: _R + panelHeight     // box bottom

    // Internal aliases for brevity
    readonly property bool _ft: flushTop
    readonly property bool _fb: flushBottom
    readonly property bool _fl: flushLeft
    readonly property bool _fr: flushRight

    // ── TL corner ────────────────────────────────────────────────────────────
    // From left edge (going up) to top edge (going right)
    //   square:       ft && fl   (both adjacent edges flush)
    //   convex:      !ft && !fl  (neither flush)
    //   concave-top:  ft && !fl  (top flush only)
    //   concave-left: fl && !ft  (left flush only)

    readonly property real _tl_ax: _L
    readonly property real _tl_ay: (_ft && _fl) ? _T
                                 : (_ft)        ? _T + _rh
                                 : (_fl)        ? _T - _R
                                 :                _T + _rh
    readonly property real _tl_c1x: _L
    readonly property real _tl_c1y: (_ft && _fl) ? _T
                                  : (_ft)        ? _T
                                  : (_fl)        ? _T - _R
                                  :                _T + _rh - _kRh
    readonly property real _tl_c2x: (_ft && _fl) ? _L
                                  : (_ft)        ? _L - _R
                                  : (_fl)        ? _L
                                  :                _L + _rw - _kRw
    readonly property real _tl_c2y: _T
    readonly property real _tl_lx: (_ft && _fl) ? _L
                                 : (_ft)        ? _L - _R
                                 : (_fl)        ? _L + _rw
                                 :                _L + _rw
    readonly property real _tl_ly: _T

    // ── TR corner ────────────────────────────────────────────────────────────
    // From top edge (going right) to right edge (going down)
    //   square:        ft && fr   (both adjacent edges flush)
    //   convex:       !ft && !fr  (neither flush)
    //   concave-top:   ft && !fr  (top flush only)
    //   concave-right: fr && !ft  (right flush only)

    readonly property real _tr_ax: (_ft && _fr) ? _Ri
                                 : (_ft)        ? _Ri + _R
                                 : (_fr)        ? _Ri - _rw
                                 :                _Ri - _rw
    readonly property real _tr_ay: _T
    readonly property real _tr_c1x: (_ft && _fr) ? _Ri
                                  : (_ft)        ? _Ri + _R
                                  : (_fr)        ? _Ri
                                  :                _Ri - _rw + _kRw
    readonly property real _tr_c1y: _T
    readonly property real _tr_c2x: _Ri
    readonly property real _tr_c2y: (_ft && _fr) ? _T
                                  : (_ft)        ? _T
                                  : (_fr)        ? _T - _R
                                  :                _T + _rh - _kRh
    readonly property real _tr_lx: _Ri
    readonly property real _tr_ly: (_ft && _fr) ? _T
                                 : (_ft)        ? _T + _rh
                                 : (_fr)        ? _T - _R
                                 :                _T + _rh

    // ── BR corner ────────────────────────────────────────────────────────────
    // From right edge (going down) to bottom edge (going left)
    //   square:          fb && fr   (both adjacent edges flush)
    //   convex:         !fb && !fr  (neither flush)
    //   concave-bottom:  fb && !fr  (bottom flush only)
    //   concave-right:   fr && !fb  (right flush only)

    readonly property real _br_ax: _Ri
    readonly property real _br_ay: (_fb && _fr) ? _B
                                 : (_fb)        ? _B - _rh
                                 : (_fr)        ? _B + _R
                                 :                _B - _rh
    readonly property real _br_c1x: _Ri
    readonly property real _br_c1y: (_fb && _fr) ? _B
                                  : (_fb)        ? _B
                                  : (_fr)        ? _B + _R
                                  :                _B - _rh + _kRh
    readonly property real _br_c2x: (_fb && _fr) ? _Ri
                                  : (_fb)        ? _Ri + _R
                                  : (_fr)        ? _Ri
                                  :                _Ri - _rw + _kRw
    readonly property real _br_c2y: _B
    readonly property real _br_lx: (_fb && _fr) ? _Ri
                                 : (_fb)        ? _Ri + _R
                                 : (_fr)        ? _Ri - _rw
                                 :                _Ri - _rw
    readonly property real _br_ly: _B

    // ── BL corner ────────────────────────────────────────────────────────────
    // From bottom edge (going left) to left edge (going up)
    //   square:          fb && fl   (both adjacent edges flush)
    //   convex:         !fb && !fl  (neither flush)
    //   concave-bottom:  fb && !fl  (bottom flush only)
    //   concave-left:    fl && !fb  (left flush only)

    readonly property real _bl_ax: (_fb && _fl) ? _L
                                 : (_fb)        ? _L - _R
                                 : (_fl)        ? _L + _rw
                                 :                _L + _rw
    readonly property real _bl_ay: _B
    readonly property real _bl_c1x: (_fb && _fl) ? _L
                                  : (_fb)        ? _L - _R
                                  : (_fl)        ? _L
                                  :                _L + _rw - _kRw
    readonly property real _bl_c1y: _B
    readonly property real _bl_c2x: _L
    readonly property real _bl_c2y: (_fb && _fl) ? _B
                                  : (_fb)        ? _B
                                  : (_fl)        ? _B + _R
                                  :                _B - _rh + _kRh
    readonly property real _bl_lx: _L
    readonly property real _bl_ly: (_fb && _fl) ? _B
                                 : (_fb)        ? _B - _rh
                                 : (_fl)        ? _B + _R
                                 :                _B - _rh

    // ── Shape sizing ─────────────────────────────────────────────────────────

    implicitWidth:  panelWidth  + 2 * _R
    implicitHeight: panelHeight + 2 * _R

    // Disable when fully collapsed on either axis
    visible: panelHeight > 0.1 && panelWidth > 0.1
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fillColor
        strokeColor: "transparent"
        strokeWidth: 0

        // Start at TL leave point (top edge, going right)
        startX: root._tl_lx
        startY: root._tl_ly

        // Top edge -> TR approach
        PathLine {
            x: root._tr_ax
            y: root._tr_ay
        }

        // TR corner curve
        PathCubic {
            x:         root._tr_lx
            y:         root._tr_ly
            control1X: root._tr_c1x
            control1Y: root._tr_c1y
            control2X: root._tr_c2x
            control2Y: root._tr_c2y
        }

        // Right edge -> BR approach
        PathLine {
            x: root._br_ax
            y: root._br_ay
        }

        // BR corner curve
        PathCubic {
            x:         root._br_lx
            y:         root._br_ly
            control1X: root._br_c1x
            control1Y: root._br_c1y
            control2X: root._br_c2x
            control2Y: root._br_c2y
        }

        // Bottom edge -> BL approach
        PathLine {
            x: root._bl_ax
            y: root._bl_ay
        }

        // BL corner curve
        PathCubic {
            x:         root._bl_lx
            y:         root._bl_ly
            control1X: root._bl_c1x
            control1Y: root._bl_c1y
            control2X: root._bl_c2x
            control2Y: root._bl_c2y
        }

        // Left edge -> TL approach
        PathLine {
            x: root._tl_ax
            y: root._tl_ay
        }

        // TL corner curve (closes the path)
        PathCubic {
            x:         root._tl_lx
            y:         root._tl_ly
            control1X: root._tl_c1x
            control1Y: root._tl_c1y
            control2X: root._tl_c2x
            control2Y: root._tl_c2y
        }
    }
}
