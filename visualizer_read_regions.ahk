; Reading overlays are drawn on Windows, so they never contaminate ADB OCR frames.
VisualizerReadRegionBounds(x, y, width, height, displayWidth, displayHeight) {
    if (width <= 0 || height <= 0 || displayWidth <= 0 || displayHeight <= 0
        || x >= displayWidth || y >= displayHeight || x + width <= 0 || y + height <= 0)
        return false
    return {
        left: Max(0, Floor(x)), top: Max(0, Floor(y)),
        right: Min(displayWidth - 1, Ceil(x + width) - 1),
        bottom: Min(displayHeight - 1, Ceil(y + height) - 1)
    }
}

AddVisualizerClientReadRegion(x, y, width, height) {
    rect := ClientRectToADBRect(x, y, width, height)
    AddVisualizerADBReadRegion(rect.x, rect.y, rect.width, rect.height)
}

AddVisualizerADBReadRegion(x, y, width, height) {
    global VisualizerOverlayMarks, VisualizerReadRegionKeys
    global ADBRefactorDisplayWidth, ADBRefactorDisplayHeight
    bounds := VisualizerReadRegionBounds(x, y, width, height, ADBRefactorDisplayWidth, ADBRefactorDisplayHeight)
    if !IsObject(bounds)
        return
    key := bounds.left "," bounds.top "," bounds.right "," bounds.bottom
    if VisualizerReadRegionKeys.Has(key)
        return
    VisualizerReadRegionKeys[key] := true
    bounds.kind := "read"
    VisualizerOverlayMarks.Push(bounds)
    RenderClickOverlay()
    UpdateVisualizerMarkCount()
}

DrawVisualizerEye(graphics, x, y, pen, backgroundBrush, pupilBrush) {
    path := 0
    DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &path)
    if !path
        return
    try {
        DllCall("gdiplus\GdipAddPathBezier", "ptr", path,
            "float", x, "float", y + 9, "float", x + 7, "float", y - 1,
            "float", x + 21, "float", y - 1, "float", x + 28, "float", y + 9)
        DllCall("gdiplus\GdipAddPathBezier", "ptr", path,
            "float", x + 28, "float", y + 9, "float", x + 21, "float", y + 19,
            "float", x + 7, "float", y + 19, "float", x, "float", y + 9)
        DllCall("gdiplus\GdipClosePathFigure", "ptr", path)
        DllCall("gdiplus\GdipFillPath", "ptr", graphics, "ptr", backgroundBrush, "ptr", path)
        DllCall("gdiplus\GdipDrawPath", "ptr", graphics, "ptr", pen, "ptr", path)
        DllCall("gdiplus\GdipFillEllipse", "ptr", graphics, "ptr", pupilBrush,
            "float", x + 10, "float", y + 5, "float", 8, "float", 8)
    } finally {
        DllCall("gdiplus\GdipDeletePath", "ptr", path)
    }
}
