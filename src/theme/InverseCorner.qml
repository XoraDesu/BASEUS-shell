pragma ComponentBehavior: Bound

// BASEUS — Inverse Corner Radius (ICR) Component
// Copyright (c) 2026 xoradesu — MIT License
//
// Implements the concave/fillet corner transition specified in:
//   - DESIGN.md §10 (Inverse Corner Radius)
//   - MASTER.md §10 (Dock edge integration)
//   - MASTER.md §14 (App Drawer edge integration)
//
// Creates the organic, anchored transition where an edge-integrated
// surface flares outward into the screen perimeter instead of floating.
//
// Positions:
//   - "bottom-left": for left base of bottom-dock
//   - "bottom-right": for right base of bottom-dock
//   - "top-left": for left base of top-island
//   - "top-right": for right base of top-island

import QtQuick

Canvas {
    id: icrCanvas

    property int cornerRadius: 12
    property color fillColor: "transparent"
    // "bottom-left", "bottom-right", "top-left", "top-right"
    property string position: "bottom-left"

    width: cornerRadius
    height: cornerRadius

    onFillColorChanged: requestPaint()
    onCornerRadiusChanged: requestPaint()
    onPositionChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.fillStyle = fillColor
        var r = cornerRadius

        ctx.beginPath()
        if (position === "bottom-left") {
            // Sits to the left of the dock at screen bottom.
            // Fills the bottom-right corner of the canvas with an outward concave arc.
            ctx.moveTo(r, 0)
            ctx.lineTo(r, r)
            ctx.lineTo(0, r)
            ctx.arcTo(r, r, r, 0, r)
        } else if (position === "bottom-right") {
            // Sits to the right of the dock at screen bottom.
            ctx.moveTo(0, 0)
            ctx.lineTo(0, r)
            ctx.lineTo(r, r)
            ctx.arcTo(0, r, 0, 0, r)
        } else if (position === "top-left") {
            // Sits to the left of the top island at screen top.
            ctx.moveTo(r, r)
            ctx.lineTo(r, 0)
            ctx.lineTo(0, 0)
            ctx.arcTo(r, 0, r, r, r)
        } else if (position === "top-right") {
            // Sits to the right of the top island at screen top.
            ctx.moveTo(0, r)
            ctx.lineTo(0, 0)
            ctx.lineTo(r, 0)
            ctx.arcTo(0, 0, 0, r, r)
        }
        ctx.closePath()
        ctx.fill()
    }
}
