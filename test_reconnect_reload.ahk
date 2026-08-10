#Requires AutoHotkey v2.0
#SingleInstance Force
#Include OCR.ahk
#Include loot_ocr_logic.ahk
#Include ADBcocbotrefactor_support.ahk

SetTitleMatchMode 2

global TargetWindowTitle := "Emulator"
global ViewportLeft := 0, ViewportTop := 0
global ViewportRight := -1, ViewportBottom := -1
global CalibratedClientWidth := 0, CalibratedClientHeight := 0
global CalibratedProvider := "", CalibratedSerial := ""
global DisplayWidth := 0, DisplayHeight := 0
global MappingIdentity := ""

global ReconnectFramePath := A_Temp "\coc_reconnect_fresh_frame.png"
global ReconnectCropPath := A_Temp "\coc_reconnect_crop.png"
global ReconnectPreviewPath := A_Temp "\coc_reconnect_preview.png"
global ReconnectCropLeftRatio := 0.28, ReconnectCropRightRatio := 0.72
global ReconnectCropTopRatio := 0.51, ReconnectCropBottomRatio := 0.64
global LastReconnectAnalysis := false
global ReconnectPreviewSourcePath := ""

ReloadReconnectConfig(true)

ReconnectGui := Gui("+Resize", "Clash of Clanker - Reconnect & Reload Inspector")
ReconnectGui.SetFont("s10", "Segoe UI")

ReconnectGui.Add("Text", "x15 y14 w110 h25", "Target Window:")
EditTarget := ReconnectGui.Add("Edit", "x130 y10 w260 h26", TargetWindowTitle)
BtnTarget := ReconnectGui.Add("Button", "x400 y10 w125 h26", "Update Title")

ReconnectGui.SetFont("s16 Bold", "Segoe UI")
ReconnectVerdict := ReconnectGui.Add("Text", "x15 y45 w880 h34 cBlue", "Verdict: READY")
ReconnectGui.SetFont("s10 Norm", "Segoe UI")
ReconnectStatus := ReconnectGui.Add("Text", "x15 y82 w880 h25 cBlue", "F1 analyzes one frame. F2 taps only F1's confirmed target.")

BtnInspect := ReconnectGui.Add("Button", "x15 y112 w180 h34", "F1 Analyze (No Tap)")
BtnTapConfirmed := ReconnectGui.Add("Button", "x205 y112 w210 h34", "F2 Tap Confirmed Result")
BtnClear := ReconnectGui.Add("Button", "x425 y112 w120 h34", "Clear Console")

ReconnectPreviewGroup := ReconnectGui.Add("GroupBox", "x15 y155 w890 h515", "Fresh ADB Screenshot (green outline = OCR action band; dot = F2 target)")
PicPreview := ReconnectGui.Add("Picture", "x25 y180 w860 h480 +Border", "")

ConsoleLabel := ReconnectGui.Add("Text", "x15 y680 w890 h22", "Console Output:")
ReconnectGui.SetFont("s9", "Consolas")
ConsoleEdit := ReconnectGui.Add("Edit", "x15 y705 w890 h210 ReadOnly +VScroll +HScroll", "")
ReconnectGui.SetFont("s10", "Segoe UI")

BtnTarget.OnEvent("Click", (*) => UpdateTargetTitle(EditTarget.Value))
BtnInspect.OnEvent("Click", (*) => RunReconnectTestCycle(true))
BtnTapConfirmed.OnEvent("Click", (*) => TapConfirmedReconnectAction())
BtnClear.OnEvent("Click", (*) => ClearConsole())
ReconnectGui.OnEvent("Close", (*) => ExitApp())
ReconnectGui.OnEvent("Size", ReconnectGuiResized)

ReconnectGui.Show("w920 h940")
LogToConsole("Ready. F1 captures and analyzes only; F2 taps only a successful F1 target.")
LogToConsole("The screenshot preserves its aspect ratio. Green outlines the OCR action band.")

return

F1::RunReconnectTestCycle(true)
F2::TapConfirmedReconnectAction()

UpdateTargetTitle(newTitle) {
    global TargetWindowTitle
    TargetWindowTitle := Trim(newTitle)
    LogToConsole("Updated target window title to: '" TargetWindowTitle "'")
}

LogToConsole(msg) {
    timeStr := FormatTime(, "HH:mm:ss")
    ConsoleEdit.Value .= "[" timeStr "] " msg "`n"
    SendMessage(0x0115, 7, 0, ConsoleEdit)
}

ClearConsole() {
    ConsoleEdit.Value := ""
}

ReloadReconnectConfig(force := false) {
    global ViewportLeft, ViewportTop, ViewportRight, ViewportBottom
    global CalibratedClientWidth, CalibratedClientHeight
    global CalibratedProvider, CalibratedSerial

    if force {
        ViewportLeft := ReadConfigInt("ADBViewport", "Left", 0)
        ViewportTop := ReadConfigInt("ADBViewport", "Top", 0)
        ViewportRight := ReadConfigInt("ADBViewport", "Right", -1)
        ViewportBottom := ReadConfigInt("ADBViewport", "Bottom", -1)
        CalibratedClientWidth := ReadConfigInt("ADBViewport", "ClientWidth", 0)
        CalibratedClientHeight := ReadConfigInt("ADBViewport", "ClientHeight", 0)
        CalibratedProvider := IniRead("config.ini", "ADBViewport", "Provider", "")
        CalibratedSerial := IniRead("config.ini", "ADBViewport", "Serial", "")
    }
}

ReadConfigInt(section, key, fallback) {
    val := IniRead("config.ini", section, key, "")
    return (val != "" && IsNumber(val)) ? Number(val) : fallback
}

EnsureReconnectADBMapping(clientWidth, clientHeight) {
    global MappingIdentity, DisplayWidth, DisplayHeight
    global ViewportLeft, ViewportTop, ViewportRight, ViewportBottom
    global CalibratedClientWidth, CalibratedClientHeight
    global CalibratedProvider, CalibratedSerial

    if (CalibratedSerial == "")
        throw Error("ADBViewport.Serial missing in config.ini")
    if (clientWidth != CalibratedClientWidth || clientHeight != CalibratedClientHeight) {
        throw Error("Client size " clientWidth "x" clientHeight " != calibrated " CalibratedClientWidth "x" CalibratedClientHeight)
    }
    identity := clientWidth "|" clientHeight "|" CalibratedProvider "|" CalibratedSerial "|" ViewportLeft "|" ViewportTop "|" ViewportRight "|" ViewportBottom
    if (identity == MappingIdentity && DisplayWidth > 0 && DisplayHeight > 0)
        return
    display := QueryReconnectADBDisplaySize(CalibratedSerial)
    DisplayWidth := display.width
    DisplayHeight := display.height
    ConfigureADBClientMapping(
        ViewportLeft, ViewportTop, ViewportRight, ViewportBottom,
        DisplayWidth, DisplayHeight, clientWidth, clientHeight,
        CalibratedProvider, CalibratedSerial
    )
    MappingIdentity := identity
}

QueryReconnectADBDisplaySize(serial) {
    state := RunReconnectADBOutput('-s "' serial '" get-state')
    if !state.ok {
        connect := RunReconnectADBOutput('connect "' serial '"')
        if !connect.ok
            throw Error("ADB connection failed: " connect.output)
    }
    sizeResult := RunReconnectADBOutput('-s "' serial '" shell wm size')
    if !sizeResult.ok
        throw Error("Could not query ADB display size: " sizeResult.output)
    if RegExMatch(sizeResult.output, "i)Override size:\s*(\d+)x(\d+)", &match)
        return {width: Number(match[1]), height: Number(match[2])}
    if RegExMatch(sizeResult.output, "i)Physical size:\s*(\d+)x(\d+)", &match)
        return {width: Number(match[1]), height: Number(match[2])}
    throw Error("Unrecognized ADB display size: " sizeResult.output)
}

ResolveReconnectADBPath() {
    for directory in StrSplit(EnvGet("PATH"), ";") {
        directory := Trim(directory, ' "')
        if (directory == "")
            continue
        candidate := RTrim(directory, "\/") "\adb.exe"
        if FileExist(candidate)
            return candidate
    }
    bundled := "C:\Program Files\Google\Play Games Developer Emulator\current\emulator\adb.exe"
    if FileExist(bundled)
        return bundled
    throw Error("adb.exe was not found.")
}

RunReconnectADBOutput(arguments) {
    adbPath := ResolveReconnectADBPath()
    outputPath := A_Temp "\coc_reconnect_adb_output.txt"
    try FileDelete(outputPath)
    command := A_ComSpec ' /D /S /C ""' adbPath '" ' arguments ' > "' outputPath '" 2>&1"'
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    output := FileExist(outputPath) ? Trim(FileRead(outputPath), " `t`r`n") : ""
    try FileDelete(outputPath)
    return {ok: exitCode == 0, output: output, exitCode: exitCode}
}

RunReconnectADBOutputCommand(command) {
    return RunReconnectADBOutput(command)
}

CaptureReconnectADBFrame() {
    global CalibratedSerial, ReconnectFramePath
    adbPath := ResolveReconnectADBPath()
    try FileDelete(ReconnectFramePath)
    command := A_ComSpec ' /D /S /C ""' adbPath '" -s "' CalibratedSerial '" exec-out screencap -p > "' ReconnectFramePath '""'
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    if (exitCode != 0 || !FileExist(ReconnectFramePath))
        throw Error("Fresh ADB screenshot failed with exit " exitCode ".")
    if (FileGetSize(ReconnectFramePath) < 1024)
        throw Error("Fresh ADB screenshot is unexpectedly small.")
    return ReconnectFramePath
}

ClientRectToADBRect(x, y, width, height) {
    return TranslateClientRectToADB(x, y, width, height)
}

SaveADBFrameRegionToPNG(framePath, x, y, w, h, filepath) {
    if (framePath == "" || !FileExist(framePath))
        throw Error("ADB frame is unavailable.")
    adbRect := ClientRectToADBRect(x, y, w, h)
    InitGDIPlus()
    pSourceBitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", framePath, "ptr*", &pSourceBitmap) != 0
        throw Error("ADB frame could not be opened.")
    pCroppedBitmap := 0
    status := DllCall(
        "gdiplus\GdipCloneBitmapArea",
        "float", Float(adbRect.x),
        "float", Float(adbRect.y),
        "float", Float(adbRect.width),
        "float", Float(adbRect.height),
        "int", 0x26200A,
        "ptr", pSourceBitmap,
        "ptr*", &pCroppedBitmap
    )
    if (status != 0) {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pSourceBitmap)
        throw Error("ADB frame crop failed with GDI+ status " status ".")
    }
    clsid := Buffer(16, 0)
    DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid)
    saveStatus := DllCall("gdiplus\GdipSaveImageToFile", "ptr", pCroppedBitmap, "wstr", filepath, "ptr", clsid, "ptr", 0)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pCroppedBitmap)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pSourceBitmap)
    if (saveStatus != 0)
        throw Error("ADB crop could not be saved; GDI+ status " saveStatus ".")
    return adbRect
}

ADBFramePointToClient(adbRect, localX, localY) {
    return TranslateADBPointToClient(
        adbRect.x + localX,
        adbRect.y + localY
    )
}

ClientClickPoint(clientX, clientY) {
    global CalibratedSerial
    interaction := CreateADBClientInteraction(
        CalibratedSerial,
        RunReconnectADBOutputCommand,
        Sleep,
        Random
    )
    return interaction.Tap(clientX, clientY, 100)
}

RunReconnectTestCycle(isManual := true) {
    global TargetWindowTitle, ReconnectStatus, ReconnectVerdict
    global ReconnectFramePath, ReconnectCropPath, ReconnectPreviewPath
    global CalibratedClientWidth, CalibratedClientHeight
    global ReconnectCropLeftRatio, ReconnectCropRightRatio
    global ReconnectCropTopRatio, ReconnectCropBottomRatio
    global LastReconnectAnalysis

    try {
        LastReconnectAnalysis := false
        ReloadReconnectConfig(true)
        if !WinExist(TargetWindowTitle) {
            ReconnectStatus.Text := "Status: Target window not found!"
            ReconnectStatus.Opt("cRed")
            ReconnectVerdict.Text := "Verdict: TARGET WINDOW NOT FOUND"
            ReconnectVerdict.Opt("cRed")
            if isManual
                LogToConsole("Error: Target window '" TargetWindowTitle "' not found.")
            return
        }
        hwnd := WinExist(TargetWindowTitle)
        WinGetClientPos &cx, &cy, &cw, &ch, hwnd
        EnsureReconnectADBMapping(cw, ch)

        framePath := CaptureReconnectADBFrame()

        viewportX := ViewportLeft
        viewportY := ViewportTop
        viewportW := ViewportRight - ViewportLeft
        viewportH := ViewportBottom - ViewportTop

        cardCheck := IsErrorCardColorMatch(framePath, viewportX, viewportY, viewportW, viewportH)
        searchX := Round(viewportX + viewportW * ReconnectCropLeftRatio)
        searchY := Round(viewportY + viewportH * ReconnectCropTopRatio)
        searchW := Max(1, Round(viewportW * (ReconnectCropRightRatio - ReconnectCropLeftRatio)))
        searchH := Max(1, Round(viewportH * (ReconnectCropBottomRatio - ReconnectCropTopRatio)))

        adbCrop := SaveADBFrameRegionToPNG(framePath, searchX, searchY, searchW, searchH, ReconnectCropPath)
        SaveReconnectFrameOverlay(framePath, adbCrop, false, ReconnectPreviewPath)
        ShowReconnectPreview(ReconnectPreviewPath)

        if !cardCheck.isMatch {
            ReconnectStatus.Text := "Status: No error popup card detected (#191C1E matched " cardCheck.count "/6 points)."
            ReconnectStatus.Opt("cBlue")
            ReconnectVerdict.Text := "Verdict: NO RELOAD POPUP"
            ReconnectVerdict.Opt("cBlue")
            if isManual
                LogToConsole("NO POPUP DETECTED - Center card color #191C1E matched " cardCheck.count "/" cardCheck.total " points. Safe Skip.")
            return
        }

        LogToConsole("ERROR POPUP CARD DETECTED (Color #191C1E matched " cardCheck.count "/" cardCheck.total " points). Running OCR...")

        foundAction := false
        matchedText := ""
        matchedClientPoint := {x: 0, y: 0}
        matchedADBRect := {x: 0, y: 0, w: 0, h: 0}

        try {
            ocrRes := OCR.FromFile(ReconnectCropPath, {scale: 1.5})
            for line in ocrRes.Lines {
                if IsExplicitReloadActionText(line.Text) {
                    foundAction := true
                    matchedText := Trim(line.Text, " `t`r`n")
                    matchedADBRect := {x: line.x, y: line.y, w: line.w, h: line.h}
                    matchedClientPoint := ADBFramePointToClient(
                        adbCrop,
                        line.x + line.w / 2,
                        line.y + line.h / 2
                    )
                }
            }
        }

        if !foundAction {
            ReconnectStatus.Text := "Status: Popup card found, but no action label was found in the OCR band."
            ReconnectStatus.Opt("cBlue")
            ReconnectVerdict.Text := "Verdict: ACTION NOT FOUND"
            ReconnectVerdict.Opt("cRed")
            if isManual
                LogToConsole("NO ACTION FOUND - F2 remains disabled until a later successful F1 analysis.")
            return
        }

        matchedFramePoint := {
            x: adbCrop.x + matchedADBRect.x + matchedADBRect.w / 2,
            y: adbCrop.y + matchedADBRect.y + matchedADBRect.h / 2
        }
        SaveReconnectFrameOverlay(
            framePath,
            adbCrop,
            matchedFramePoint,
            ReconnectPreviewPath
        )
        ShowReconnectPreview(ReconnectPreviewPath)
        LastReconnectAnalysis := {
            name: matchedText,
            clientPoint: matchedClientPoint,
            framePoint: matchedFramePoint
        }

        ReconnectStatus.Text := "Status: MATCH FOUND '" matchedText "' - verify the dot, then press F2 to tap."
        ReconnectStatus.Opt("cGreen")
        ReconnectVerdict.Text := "Verdict: F1 ACTION CONFIRMED"
        ReconnectVerdict.Opt("cGreen")
        LogToConsole("==========================================================================")
        LogToConsole("DISCONNECT POPUP MATCH FOUND: '" matchedText "'")
        LogToConsole(Format("Button target: Client ({}, {}) -> ADB ({}, {})", matchedClientPoint.x, matchedClientPoint.y, Round(searchX + matchedADBRect.x + matchedADBRect.w/2), Round(searchY + matchedADBRect.y + matchedADBRect.h/2)))
        LogToConsole("F1 did not tap. Inspect the green box and dot, then press F2 to tap.")
        LogToConsole("==========================================================================")

    } catch as err {
        ReconnectStatus.Text := "Status: Error - " err.Message
        ReconnectStatus.Opt("cRed")
        ReconnectVerdict.Text := "Verdict: ANALYSIS ERROR"
        ReconnectVerdict.Opt("cRed")
        LogToConsole("ERROR: " err.Message)
    }
}

TapConfirmedReconnectAction() {
    global LastReconnectAnalysis, ReconnectStatus, ReconnectVerdict
    if !IsObject(LastReconnectAnalysis) {
        ReconnectStatus.Text := "Status: F2 ignored. Run F1 and confirm a matching action first."
        ReconnectStatus.Opt("cRed")
        ReconnectVerdict.Text := "Verdict: NO CONFIRMED F1 TARGET"
        ReconnectVerdict.Opt("cRed")
        LogToConsole("F2 TAP REFUSED - no successful F1 analysis is stored.")
        return
    }
    try {
        point := LastReconnectAnalysis.clientPoint
        ClientClickPoint(point.x, point.y)
        ReconnectStatus.Text := "Status: F2 tapped confirmed '" LastReconnectAnalysis.name "' target through ADB."
        ReconnectStatus.Opt("cGreen")
        ReconnectVerdict.Text := "Verdict: CONFIRMED ACTION TAPPED"
        ReconnectVerdict.Opt("cGreen")
        LogToConsole("F2 TAP SENT - '" LastReconnectAnalysis.name "' at client (" point.x ", " point.y ").")
        LastReconnectAnalysis := false
    } catch as err {
        ReconnectStatus.Text := "Status: F2 tap failed - " err.Message
        ReconnectStatus.Opt("cRed")
        ReconnectVerdict.Text := "Verdict: TAP ERROR"
        ReconnectVerdict.Opt("cRed")
        LogToConsole("F2 TAP ERROR - " err.Message)
    }
}

ShowReconnectPreview(imagePath) {
    global PicPreview, ReconnectPreviewSourcePath
    ReconnectPreviewSourcePath := imagePath
    FitReconnectPreviewToImage(imagePath)
    PicPreview.Value := ""
    PicPreview.Value := imagePath
}

ReconnectGuiResized(guiObj, minMax, width, height) {
    global ReconnectPreviewSourcePath
    if (minMax == -1 || ReconnectPreviewSourcePath == "")
        return
    FitReconnectPreviewToImage(ReconnectPreviewSourcePath)
}

FitReconnectPreviewToImage(imagePath) {
    global ReconnectGui, ReconnectPreviewGroup, PicPreview, ConsoleLabel, ConsoleEdit
    dimensions := GetReconnectImageDimensions(imagePath)
    if (dimensions.width <= 0 || dimensions.height <= 0)
        return
    ReconnectGui.GetClientPos(&clientX, &clientY, &clientW, &clientH)
    maxW := Max(300, clientW - 50)
    maxH := Max(180, clientH - 360)
    scale := Min(maxW / dimensions.width, maxH / dimensions.height)
    displayW := Max(1, Round(dimensions.width * scale))
    displayH := Max(1, Round(dimensions.height * scale))
    pictureX := Round((clientW - displayW) / 2)
    pictureY := 180
    consoleY := pictureY + displayH + 35
    ReconnectPreviewGroup.Move(15, 155, clientW - 30, displayH + 50)
    PicPreview.Move(pictureX, pictureY, displayW, displayH)
    ConsoleLabel.Move(15, consoleY, clientW - 30, 22)
    ConsoleEdit.Move(15, consoleY + 25, clientW - 30, Max(150, clientH - consoleY - 40))
}

GetReconnectImageDimensions(imagePath) {
    InitGDIPlus()
    pBitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", imagePath, "ptr*", &pBitmap) != 0
        return {width: 0, height: 0}
    try {
        width := 0, height := 0
        DllCall("gdiplus\GdipGetImageWidth", "ptr", pBitmap, "uint*", &width)
        DllCall("gdiplus\GdipGetImageHeight", "ptr", pBitmap, "uint*", &height)
        return {width: width, height: height}
    } finally {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    }
}

SaveReconnectFrameOverlay(srcPath, adbCrop, markerPoint, dstPath) {
    InitGDIPlus()
    pBitmap := 0
    DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", srcPath, "ptr*", &pBitmap)
    if !pBitmap
        return

    pGraphics := 0
    DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", pBitmap, "ptr*", &pGraphics)
    if pGraphics {
        pPen := 0
        DllCall("gdiplus\GdipCreatePen1", "uint", 0xFF00FF00, "float", 4.0, "int", 2, "ptr*", &pPen)
        if pPen {
            DllCall("gdiplus\GdipDrawRectangle", "ptr", pGraphics, "ptr", pPen, "float", Float(adbCrop.x), "float", Float(adbCrop.y), "float", Float(adbCrop.width), "float", Float(adbCrop.height))
            DllCall("gdiplus\GdipDeletePen", "ptr", pPen)
        }
        if IsObject(markerPoint)
            DrawReconnectMarkerDot(pGraphics, markerPoint.x, markerPoint.y)
        DllCall("gdiplus\GdipDeleteGraphics", "ptr", pGraphics)
    }
    clsid := Buffer(16, 0)
    DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid)
    DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "wstr", dstPath, "ptr", clsid, "ptr", 0)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
}

DrawReconnectMarkerDot(pGraphics, x, y) {
    pBrush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "uint", 0xFFFFFF00, "ptr*", &pBrush)
    if !pBrush
        return
    try {
        DllCall("gdiplus\GdipFillEllipse", "ptr", pGraphics, "ptr", pBrush, "float", Float(x - 7), "float", Float(y - 7), "float", 14.0, "float", 14.0)
    } finally {
        DllCall("gdiplus\GdipDeleteBrush", "ptr", pBrush)
    }
}

InitGDIPlus() {
    static token := 0
    if (token == 0) {
        pi := Buffer(24, 0)
        NumPut("uint", 1, pi, 0)
        DllCall("gdiplus\GdiplusStartup", "ptr*", &token, "ptr", pi, "ptr", 0)
    }
    return token
}
