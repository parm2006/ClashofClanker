#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ADBcocbotrefactor_support.ahk

SetTitleMatchMode 2
CoordMode "Mouse", "Screen"

; Read-only visual inspector for the exact Builder Base star detector used by F4.
global StarInspectorSerial := ""
global StarInspectorProvider := ""
global StarInspectorTargetWindowTitle := "Emulator"
global StarInspectorViewport := ""
global StarInspectorDisplay := ""
global StarInspectorPoints := []
global StarInspectorStartupPoints := []
global StarInspectorControls := []
global StarInspectorGui := ""
global VerdictText := ""
global PicPreview := ""
global ConsoleEdit := ""
global StarInspectorPreviewPath := A_Temp "\coc_builder_base_star_preview.png"
global StarInspectorCaptureSequence := 0
global StarInspectorCaptureTimeoutSeconds := 10
global StarInspectorGdipToken := 0
global StarInspectorIsRefreshing := false
global StarInspectorPixelProbePending := false
global StarInspectorCalibrationIndex := 0
global StarInspectorCalibrateButton := ""
global StarInspectorLastMappingSignature := ""
global StarInspectorLastDetectionSignature := ""

LoadBuilderBaseStarStartupConfig()
CaptureBuilderBaseStarStartupPoints()
CreateBuilderBaseStarInspectorGui()

F1::RunBuilderBaseStarInspectCycle(true)
F2::TapBuilderBaseStarTargets()
F7::ProbeBuilderBaseStarADBPixels()
Space:: CaptureBuilderBaseStarCalibrationPoint()

CreateBuilderBaseStarInspectorGui() {
    global StarInspectorGui, VerdictText, PicPreview, ConsoleEdit
    global StarInspectorPoints, StarInspectorControls
    global StarInspectorCalibrateButton

    StarInspectorGui := Gui("+Resize +MinSize760x680", "Clash of Clanker - Builder Base Star Inspector")
    StarInspectorGui.SetFont("s10", "Segoe UI")
    StarInspectorGui.Add("Text", "x15 y12 w720 h22 +Center", "F4 star inspection plus an explicit exact-target ADB tap test")

    StarInspectorGui.Add("GroupBox", "x15 y42 w730 h112", "Session-only calibrated client points (loaded from config.ini once at startup)")
    Loop 3 {
        index := A_Index
        x := 28 + (index - 1) * 238
        StarInspectorGui.Add("Text", "x" x " y69 w44 h22", "Star " index)
        StarInspectorGui.Add("Text", "x" (x + 48) " y69 w18 h22", "X")
        xEdit := StarInspectorGui.Add("Edit", "x" (x + 65) " y65 w62 h26 Number", String(StarInspectorPoints[index].x))
        StarInspectorGui.Add("UpDown", "Range0-5000", StarInspectorPoints[index].x)
        StarInspectorGui.Add("Text", "x" (x + 132) " y69 w18 h22", "Y")
        yEdit := StarInspectorGui.Add("Edit", "x" (x + 149) " y65 w62 h26 Number", String(StarInspectorPoints[index].y))
        StarInspectorGui.Add("UpDown", "Range0-5000", StarInspectorPoints[index].y)
        StarInspectorControls.Push({x: xEdit, y: yEdit})
        xEdit.OnEvent("Change", (*) => OnBuilderBaseStarPointChanged())
        yEdit.OnEvent("Change", (*) => OnBuilderBaseStarPointChanged())
    }
    BtnReset := StarInspectorGui.Add("Button", "x28 y106 w120 h30", "Reset Local")
    BtnRefresh := StarInspectorGui.Add("Button", "x158 y106 w170 h30", "Fresh Screenshot (F1)")
    StarInspectorCalibrateButton := StarInspectorGui.Add("Button", "x338 y106 w190 h30", "Calibrate 3 Stars")
    BtnTapTargets := StarInspectorGui.Add("Button", "x538 y106 w190 h30", "Tap 3 Targets (F2)")
    BtnReset.OnEvent("Click", (*) => ResetBuilderBaseStarPoints())
    BtnRefresh.OnEvent("Click", (*) => RunBuilderBaseStarInspectCycle())
    StarInspectorCalibrateButton.OnEvent("Click", (*) => BeginBuilderBaseStarCalibration())
    BtnTapTargets.OnEvent("Click", (*) => TapBuilderBaseStarTargets())

    StarInspectorGui.SetFont("s16 Bold", "Segoe UI")
    VerdictText := StarInspectorGui.Add("Text", "x20 y166 w720 h38 +Center cBlue", "Verdict: WAITING FOR FRESH FRAME")
    StarInspectorGui.SetFont("s10 Norm", "Segoe UI")

    StarInspectorGui.Add("GroupBox", "x15 y214 w730 h330", "ADB screenshot (yellow = exact transformed F4 sampling target)")
    ; No control border: mouse-to-image scaling must use the full exact picture area.
    PicPreview := StarInspectorGui.Add("Picture", "x25 y240 w710 h292", "")

    StarInspectorGui.Add("GroupBox", "x15 y554 w730 h180", "Diagnostics")
    StarInspectorGui.SetFont("s9", "Consolas")
    ConsoleEdit := StarInspectorGui.Add("Edit", "x25 y579 w710 h145 ReadOnly +VScroll +HScroll", "")
    StarInspectorGui.SetFont("s10", "Segoe UI")
    StarInspectorGui.OnEvent("Close", (*) => ExitApp())
    StarInspectorGui.Show("w760 h750")
    StarInspectorLog("Ready. Screenshots are manual: F1 refreshes the preview and F7 probes exact ADB pixels. Only F2 sends game input.")
}

OnBuilderBaseStarPointChanged() {
    global StarInspectorControls, StarInspectorPoints
    Loop 3 {
        x := StarInspectorControls[A_Index].x.Value
        y := StarInspectorControls[A_Index].y.Value
        if !IsNumber(x) || !IsNumber(y)
            return
        StarInspectorPoints[A_Index] := {x: Round(Number(x)), y: Round(Number(y))}
    }
}

LoadBuilderBaseStarStartupConfig() {
    global StarInspectorSerial, StarInspectorProvider, StarInspectorTargetWindowTitle, StarInspectorViewport
    global StarInspectorPoints
    if !FileExist("config.ini")
        throw Error("config.ini was not found.")
    StarInspectorSerial := IniRead("config.ini", "ADBViewport", "Serial", "")
    StarInspectorProvider := IniRead("config.ini", "ADBViewport", "Provider", "")
    StarInspectorTargetWindowTitle := IniRead("config.ini", "Settings", "TargetWindowTitle", StarInspectorTargetWindowTitle)
    StarInspectorViewport := {
        left: ReadBuilderBaseStarInteger("ADBViewport", "Left"),
        top: ReadBuilderBaseStarInteger("ADBViewport", "Top"),
        right: ReadBuilderBaseStarInteger("ADBViewport", "Right"),
        bottom: ReadBuilderBaseStarInteger("ADBViewport", "Bottom"),
        clientWidth: ReadBuilderBaseStarInteger("ADBViewport", "ClientWidth"),
        clientHeight: ReadBuilderBaseStarInteger("ADBViewport", "ClientHeight")
    }
    StarInspectorPoints := []
    Loop 3 {
        index := A_Index
        StarInspectorPoints.Push({
            x: ReadBuilderBaseStarInteger("Coordinates", "BBStar" index "X"),
            y: ReadBuilderBaseStarInteger("Coordinates", "BBStar" index "Y")
        })
    }
}

ReadBuilderBaseStarInteger(section, key) {
    value := IniRead("config.ini", section, key, "")
    if (value == "" || !IsNumber(value))
        throw Error("config.ini is missing " section "." key ".")
    return Round(Number(value))
}

CaptureBuilderBaseStarStartupPoints() {
    global StarInspectorPoints, StarInspectorStartupPoints
    StarInspectorStartupPoints := []
    for point in StarInspectorPoints
        StarInspectorStartupPoints.Push({x: point.x, y: point.y})
}

ResetBuilderBaseStarPoints() {
    global StarInspectorPoints, StarInspectorStartupPoints, StarInspectorControls
    StarInspectorPoints := []
    for point in StarInspectorStartupPoints
        StarInspectorPoints.Push({x: point.x, y: point.y})
    Loop 3 {
        StarInspectorControls[A_Index].x.Value := StarInspectorPoints[A_Index].x
        StarInspectorControls[A_Index].y.Value := StarInspectorPoints[A_Index].y
    }
    StarInspectorLog("Local points reset to the config.ini startup snapshot. Press F1 to refresh the markers.")
}

BeginBuilderBaseStarCalibration() {
    global StarInspectorCalibrationIndex, StarInspectorCalibrateButton
    StarInspectorCalibrationIndex := 1
    StarInspectorCalibrateButton.Text := "Hover Emulator Star 1"
    StarInspectorLog("Calibration armed: hover over star 1 in the emulator client and press Space.")
}

CaptureBuilderBaseStarCalibrationPoint() {
    global StarInspectorCalibrationIndex, StarInspectorCalibrateButton
    global StarInspectorTargetWindowTitle
    global StarInspectorPoints, StarInspectorControls
    if (StarInspectorCalibrationIndex == 0)
        return
    hwnd := WinExist(StarInspectorTargetWindowTitle)
    if !hwnd {
        StarInspectorLog("Calibration failed: emulator window not found: " StarInspectorTargetWindowTitle)
        return
    }
    WinGetClientPos(&clientScreenX, &clientScreenY, &clientWidth, &clientHeight, hwnd)
    cursorPoint := GetBuilderBaseStarCursorClientPoint(hwnd)
    clientX := cursorPoint.x
    clientY := cursorPoint.y
    if (clientX < 0 || clientY < 0 || clientX >= clientWidth || clientY >= clientHeight) {
        StarInspectorLog("Calibration failed: hover inside the emulator client.")
        return
    }
    EnsureBuilderBaseStarMapping()
    mappedPoint := TranslateClientPointToADB(clientX, clientY)
    index := StarInspectorCalibrationIndex
    StarInspectorPoints[index] := {x: clientX, y: clientY}
    StarInspectorControls[index].x.Value := clientX
    StarInspectorControls[index].y.Value := clientY
    StarInspectorLog(
        "Star " index " calibrated: cursor screen(" cursorPoint.screenX "," cursorPoint.screenY
            "), emulator origin(" clientScreenX "," clientScreenY
            "), AHK client(" clientX "," clientY
            ") -> F4 ADB(" mappedPoint.x "," mappedPoint.y ")."
    )
    if (index >= 3) {
        StarInspectorCalibrationIndex := 0
        StarInspectorCalibrateButton.Text := "Calibrate 3 Stars"
        StarInspectorLog("All three client points captured. Press F1 to refresh the yellow markers, or F7 to probe their raw ADB pixels. config.ini was not modified.")
    } else {
        StarInspectorCalibrationIndex += 1
        StarInspectorCalibrateButton.Text := "Hover Emulator Star " StarInspectorCalibrationIndex
    }
}

GetBuilderBaseStarCursorClientPoint(hwnd) {
    CoordMode "Mouse", "Screen"
    cursorPoint := Buffer(8, 0)
    if !DllCall("GetCursorPos", "ptr", cursorPoint)
        throw OSError(A_LastError, "GetCursorPos")
    screenX := NumGet(cursorPoint, 0, "Int")
    screenY := NumGet(cursorPoint, 4, "Int")
    if !DllCall("ScreenToClient", "ptr", hwnd, "ptr", cursorPoint)
        throw OSError(A_LastError, "ScreenToClient")
    return {
        screenX: screenX,
        screenY: screenY,
        x: NumGet(cursorPoint, 0, "Int"),
        y: NumGet(cursorPoint, 4, "Int")
    }
}

TapBuilderBaseStarTargets() {
    global StarInspectorPoints
    StarInspectorLog("F2 started: sending exact ADB taps to the three transformed F4 targets.")
    try {
        EnsureBuilderBaseStarMapping()
        for index, clientPoint in StarInspectorPoints {
            adbPoint := TranslateClientPointToADB(clientPoint.x, clientPoint.y)
            RunBuilderBaseStarExactADB(adbPoint, index)
            if (index < StarInspectorPoints.Length)
                Sleep(600)
        }
        StarInspectorLog("F2 complete: all three exact target taps were sent.")
    } catch as err {
        StarInspectorLog("F2 failed: " err.Message)
    }
}

RunBuilderBaseStarExactADB(adbPoint, index) {
    global StarInspectorSerial
    arguments := BuildADBTapArguments(StarInspectorSerial, adbPoint.x, adbPoint.y)
    result := RunBuilderBaseStarADBOutput(arguments)
    if !result.ok
        throw Error("Star " index " exact ADB tap failed: " result.output)
    StarInspectorLog("  Star " index " exact tap sent at ADB(" adbPoint.x "," adbPoint.y ").")
}

ProbeBuilderBaseStarADBPixels(isPendingRun := false) {
    global StarInspectorIsRefreshing, StarInspectorPixelProbePending
    global StarInspectorPoints
    if !isPendingRun
        StarInspectorLog("F7 started: capturing one fresh ADB screenshot.")
    if StarInspectorIsRefreshing {
        StarInspectorPixelProbePending := true
        if !isPendingRun
            StarInspectorLog("F7 waiting for the current screenshot to finish; no additional capture was queued.")
        return
    }
    StarInspectorPixelProbePending := false
    StarInspectorIsRefreshing := true
    framePath := "", bitmap := 0
    try {
        EnsureBuilderBaseStarMapping()
        framePath := CaptureBuilderBaseStarFrame()
        bitmap := LoadBuilderBaseStarBitmap(framePath)
        labels := []
        pointLabels := []
        for index, star in StarInspectorPoints {
            adbPoint := TranslateClientPointToADB(star.x, star.y)
            color := ReadBuilderBaseStarPixel(bitmap, adbPoint.x, adbPoint.y)
            labels.Push("Star " index ": #" Format("{:06X}", color))
            pointLabels.Push("Star " index ": (" adbPoint.x "," adbPoint.y ")")
        }
        StarInspectorLog(
            "F7 ADB pixels: " labels[1] " | " labels[2] " | " labels[3]
        )
        StarInspectorLog(
            "F7 ADB points: " pointLabels[1] " | " pointLabels[2] " | " pointLabels[3]
        )
    } catch as err {
        StarInspectorLog("F7 failed: " err.Message " | " err.File ":" err.Line)
    } finally {
        if bitmap
            DllCall("gdiplus\GdipDisposeImage", "ptr", bitmap)
        if (framePath != "")
            try FileDelete(framePath)
        StarInspectorIsRefreshing := false
        if StarInspectorPixelProbePending
            SetTimer(() => ProbeBuilderBaseStarADBPixels(true), -10)
    }
}

RunBuilderBaseStarInspectCycle(forceLog := false) {
    global StarInspectorIsRefreshing, StarInspectorPixelProbePending
    global StarInspectorDisplay, StarInspectorViewport, StarInspectorProvider, StarInspectorSerial
    global StarInspectorPoints, VerdictText, PicPreview, StarInspectorPreviewPath
    global StarInspectorLastMappingSignature, StarInspectorLastDetectionSignature
    if StarInspectorIsRefreshing
        return
    StarInspectorIsRefreshing := true
    try {
        EnsureBuilderBaseStarMapping()
        framePath := CaptureBuilderBaseStarFrame()
        bitmap := LoadBuilderBaseStarBitmap(framePath)
        try {
            exactRegion := ResolveBuilderBaseExactStarRegion()
            starResults := []
            goldenCount := 0
            for star in StarInspectorPoints {
                adbPoint := TranslateClientPointToADB(star.x, star.y)
                result := InspectBuilderBaseGoldenStar(bitmap, adbPoint.x, adbPoint.y)
                result.client := star
                result.adb := adbPoint
                starResults.Push(result)
                if result.gold
                    goldenCount += 1
            }
            previewRegion := ExpandBuilderBaseStarRegion(exactRegion.adb, 220, 90)
            DrawBuilderBaseStarOverlay(bitmap, previewRegion, exactRegion.adb, starResults, StarInspectorPreviewPath)
            PicPreview.Value := StarInspectorPreviewPath
            if (goldenCount == 3) {
                VerdictText.Opt("cGreen")
                VerdictText.Value := "Verdict: THREE GOLD STARS DETECTED (TRUE)"
            } else {
                VerdictText.Opt("cRed")
                VerdictText.Value := "Verdict: " goldenCount "/3 GOLD STARS (FALSE)"
            }
            mappingSignature := (
                exactRegion.client.x "," exactRegion.client.y ","
                . exactRegion.client.width "," exactRegion.client.height ">"
                . exactRegion.adb.x "," exactRegion.adb.y ","
                . exactRegion.adb.width "," exactRegion.adb.height
            )
            for index, result in starResults {
                mappingSignature .= "|" result.client.x "," result.client.y ">" result.adb.x "," result.adb.y
            }
            if forceLog
                StarInspectorLastMappingSignature := ""
            if (mappingSignature != StarInspectorLastMappingSignature) {
                StarInspectorLog("Exact client box: x=" exactRegion.client.x " y=" exactRegion.client.y " w=" exactRegion.client.width " h=" exactRegion.client.height)
                StarInspectorLog("Exact ADB box:    x=" exactRegion.adb.x " y=" exactRegion.adb.y " w=" exactRegion.adb.width " h=" exactRegion.adb.height)
                for index, result in starResults
                    StarInspectorLog("Star " index ": stored client(" result.client.x "," result.client.y ") -> YELLOW F4 ADB(" result.adb.x "," result.adb.y ").")
                StarInspectorLastMappingSignature := mappingSignature
            }
            detectionSignature := String(goldenCount)
            for result in starResults
                detectionSignature .= result.gold ? "1" : "0"
            if (forceLog || detectionSignature != StarInspectorLastDetectionSignature) {
                StarInspectorLog("Detection changed: " goldenCount "/3 gold stars; states=" SubStr(detectionSignature, 2) ".")
                for index, result in starResults
                    StarInspectorLog("  Star " index ": center=#" Format("{:06X}", result.centerColor) " hits=" result.hits "/25 " (result.gold ? "GOLD" : "BRONZE"))
                StarInspectorLastDetectionSignature := detectionSignature
            }
        } finally {
            DllCall("gdiplus\GdipDisposeImage", "ptr", bitmap)
            try FileDelete(framePath)
        }
    } catch as err {
        VerdictText.Opt("cRed")
        VerdictText.Value := "Verdict: INSPECTION FAILED"
        StarInspectorLog("ERROR: " err.Message " | " err.File ":" err.Line)
    } finally {
        StarInspectorIsRefreshing := false
        if StarInspectorPixelProbePending
            SetTimer(() => ProbeBuilderBaseStarADBPixels(true), -10)
    }
}

EnsureBuilderBaseStarMapping() {
    global StarInspectorSerial, StarInspectorProvider, StarInspectorViewport, StarInspectorDisplay
    if (StarInspectorSerial == "")
        throw Error("ADBViewport.Serial is missing.")
    if IsObject(StarInspectorDisplay)
        return
    StarInspectorDisplay := QueryBuilderBaseStarDisplay()
    ConfigureADBClientMapping(StarInspectorViewport.left, StarInspectorViewport.top, StarInspectorViewport.right, StarInspectorViewport.bottom, StarInspectorDisplay.width, StarInspectorDisplay.height, StarInspectorViewport.clientWidth, StarInspectorViewport.clientHeight, StarInspectorProvider, StarInspectorSerial)
}

ResolveBuilderBaseExactStarRegion() {
    global StarInspectorPoints
    minimumX := StarInspectorPoints[1].x, maximumX := minimumX
    minimumY := StarInspectorPoints[1].y, maximumY := minimumY
    for star in StarInspectorPoints {
        minimumX := Min(minimumX, star.x), maximumX := Max(maximumX, star.x)
        minimumY := Min(minimumY, star.y), maximumY := Max(maximumY, star.y)
    }
    margin := 20
    client := {x: minimumX - margin, y: minimumY - margin, width: maximumX - minimumX + margin * 2 + 1, height: maximumY - minimumY + margin * 2 + 1}
    return {client: client, adb: TranslateClientRectToADB(client.x, client.y, client.width, client.height)}
}

ExpandBuilderBaseStarRegion(region, marginX, marginY) {
    global StarInspectorDisplay
    left := Max(0, region.x - marginX), top := Max(0, region.y - marginY)
    right := Min(StarInspectorDisplay.width - 1, region.x + region.width - 1 + marginX)
    bottom := Min(StarInspectorDisplay.height - 1, region.y + region.height - 1 + marginY)
    return {x: left, y: top, width: right - left + 1, height: bottom - top + 1}
}

CaptureBuilderBaseStarFrame() {
    global StarInspectorSerial, StarInspectorCaptureSequence
    global StarInspectorCaptureTimeoutSeconds
    StarInspectorCaptureSequence += 1
    processId := DllCall("GetCurrentProcessId", "uint")
    framePath := A_Temp "\coc_builder_base_star_" processId "_" A_TickCount "_" StarInspectorCaptureSequence ".png"
    adbPath := ResolveBuilderBaseStarADBPath()
    command := A_ComSpec ' /D /S /C ""' adbPath '" -s "' StarInspectorSerial '" exec-out screencap -p > "' framePath '""'
    capturePid := 0
    captureStartedAt := A_TickCount
    Run(command, A_ScriptDir, "Hide", &capturePid)
    closedPid := 0
    if ProcessExist(capturePid)
        closedPid := ProcessWaitClose(
            capturePid,
            StarInspectorCaptureTimeoutSeconds
        )
    if (!closedPid && ProcessExist(capturePid)) {
        killCommand := (
            A_ComSpec ' /D /S /C "taskkill /PID ' capturePid
            ' /T /F >NUL 2>&1"'
        )
        try RunWait(killCommand, A_ScriptDir, "Hide")
        try FileDelete(framePath)
        throw Error(
            "Fresh ADB screenshot timed out after "
                StarInspectorCaptureTimeoutSeconds
                " seconds."
        )
    }
    if !IsBuilderBaseStarPng(framePath) {
        bytes := FileExist(framePath) ? FileGetSize(framePath) : 0
        try FileDelete(framePath)
        throw Error("Fresh ADB screenshot failed (bytes=" bytes ").")
    }
    StarInspectorLog(
        "ADB screenshot completed in " (A_TickCount - captureStartedAt) " ms."
    )
    return framePath
}

InspectBuilderBaseGoldenStar(bitmap, centerX, centerY) {
    hits := 0
    for dx in [-7, -3, 0, 3, 7] {
        for dy in [-7, -3, 0, 3, 7] {
            if IsBuilderBaseStarGoldenColor(ReadBuilderBaseStarPixel(bitmap, centerX + dx, centerY + dy))
                hits += 1
        }
    }
    return {gold: hits > 0, hits: hits, centerColor: ReadBuilderBaseStarPixel(bitmap, centerX, centerY)}
}

IsBuilderBaseStarGoldenColor(color) {
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    return (r > 130) && (g > 100) && (r > b + 15) && (g > b - 30)
}

DrawBuilderBaseStarOverlay(sourceBitmap, previewRegion, exactRegion, starResults, outputPath) {
    InitBuilderBaseStarGdip()
    crop := 0, graphics := 0, cyanPen := 0, yellowBrush := 0
    status := DllCall("gdiplus\GdipCloneBitmapAreaI", "int", previewRegion.x, "int", previewRegion.y, "int", previewRegion.width, "int", previewRegion.height, "int", 0x26200A, "ptr", sourceBitmap, "ptr*", &crop)
    if (status != 0 || !crop)
        throw Error("Could not crop the Builder Base star preview.")
    try {
        DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", crop, "ptr*", &graphics)
        DllCall("gdiplus\GdipCreatePen1", "uint", 0xFF00FFFF, "float", 3.0, "int", 2, "ptr*", &cyanPen)
        DllCall("gdiplus\GdipCreateSolidFill", "uint", 0xFFFFFF00, "ptr*", &yellowBrush)
        DllCall("gdiplus\GdipDrawRectangle", "ptr", graphics, "ptr", cyanPen, "float", exactRegion.x - previewRegion.x, "float", exactRegion.y - previewRegion.y, "float", exactRegion.width, "float", exactRegion.height)
        for result in starResults {
            adbX := result.adb.x - previewRegion.x
            adbY := result.adb.y - previewRegion.y
            ; The center of this dot is the exact transformed ADB coordinate.
            DllCall("gdiplus\GdipFillEllipse", "ptr", graphics, "ptr", yellowBrush, "float", adbX - 3, "float", adbY - 3, "float", 6.0, "float", 6.0)
        }
        SaveBuilderBaseStarPng(crop, outputPath)
    } finally {
        if cyanPen
            DllCall("gdiplus\GdipDeletePen", "ptr", cyanPen)
        if yellowBrush
            DllCall("gdiplus\GdipDeleteBrush", "ptr", yellowBrush)
        if graphics
            DllCall("gdiplus\GdipDeleteGraphics", "ptr", graphics)
        if crop
            DllCall("gdiplus\GdipDisposeImage", "ptr", crop)
    }
}

SaveBuilderBaseStarPng(bitmap, outputPath) {
    try FileDelete(outputPath)
    clsid := Buffer(16, 0)
    DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid)
    status := DllCall("gdiplus\GdipSaveImageToFile", "ptr", bitmap, "wstr", outputPath, "ptr", clsid, "ptr", 0)
    if (status != 0)
        throw Error("Could not save the marked star preview.")
}

LoadBuilderBaseStarBitmap(path) {
    InitBuilderBaseStarGdip()
    bitmap := 0
    status := DllCall("gdiplus\GdipLoadImageFromFile", "wstr", path, "ptr*", &bitmap)
    if (status != 0 || !bitmap)
        throw Error("Could not load the fresh Builder Base screenshot.")
    return bitmap
}

ReadBuilderBaseStarPixel(bitmap, x, y) {
    color := 0
    status := DllCall("gdiplus\GdipBitmapGetPixel", "ptr", bitmap, "int", Round(x), "int", Round(y), "uint*", &color)
    return status == 0 ? color & 0xFFFFFF : 0
}

InitBuilderBaseStarGdip() {
    global StarInspectorGdipToken
    if StarInspectorGdipToken
        return StarInspectorGdipToken
    startupInput := Buffer(24, 0), token := 0
    NumPut("UInt", 1, startupInput, 0)
    status := DllCall("gdiplus\GdiplusStartup", "ptr*", &token, "ptr", startupInput, "ptr", 0)
    if (status != 0 || !token)
        throw Error("GDI+ could not start.")
    StarInspectorGdipToken := token
    return token
}

IsBuilderBaseStarPng(path) {
    if (!FileExist(path) || FileGetSize(path) < 8)
        return false
    file := FileOpen(path, "r")
    if !IsObject(file)
        return false
    try return file.ReadUChar() == 0x89 && file.ReadUChar() == 0x50 && file.ReadUChar() == 0x4E && file.ReadUChar() == 0x47 && file.ReadUChar() == 0x0D && file.ReadUChar() == 0x0A && file.ReadUChar() == 0x1A && file.ReadUChar() == 0x0A
    finally file.Close()
}

ResolveBuilderBaseStarADBPath() {
    for directory in StrSplit(EnvGet("PATH"), ";") {
        candidate := RTrim(Trim(directory, ' "'), "\\/") "\\adb.exe"
        if FileExist(candidate)
            return candidate
    }
    bundled := "C:\\Program Files\\Google\\Play Games Developer Emulator\\current\\emulator\\adb.exe"
    if FileExist(bundled)
        return bundled
    throw Error("adb.exe was not found.")
}

RunBuilderBaseStarADBOutput(arguments) {
    global StarInspectorSerial
    outputPath := A_Temp "\coc_builder_base_star_adb_output.txt"
    command := A_ComSpec ' /D /S /C ""' ResolveBuilderBaseStarADBPath() '" ' arguments ' > "' outputPath '" 2>&1"'
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    output := FileExist(outputPath) ? Trim(FileRead(outputPath), " `t`r`n") : ""
    try FileDelete(outputPath)
    return {ok: exitCode == 0, output: output}
}

QueryBuilderBaseStarDisplay() {
    global StarInspectorSerial
    result := RunBuilderBaseStarADBOutput('-s "' StarInspectorSerial '" shell wm size')
    if !result.ok
        throw Error("Could not query ADB display size: " result.output)
    if RegExMatch(result.output, "i)(?:Override|Physical) size:\s*(\d+)x(\d+)", &match)
        return {width: Number(match[1]), height: Number(match[2])}
    throw Error("Unrecognized ADB display size: " result.output)
}

StarInspectorLog(message) {
    global ConsoleEdit
    line := "[" FormatTime(A_Now, "HH:mm:ss") "] " message "`r`n"
    ConsoleEdit.Value .= line
    SendMessage(0x0115, 7, 0, ConsoleEdit.Hwnd)
}
