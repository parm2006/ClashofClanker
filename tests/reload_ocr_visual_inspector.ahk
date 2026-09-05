#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "..\OCR.ahk"
#Include "..\reload_ocr_logic.ahk"

SetWorkingDir A_ScriptDir "\.."
CoordMode "Mouse", "Screen"
SetTitleMatchMode 2

global ProjectRoot := A_ScriptDir "\.."
global ConfigPath := ProjectRoot "\config.ini"
global ScratchDir := ProjectRoot "\scratch"
global InspectorGui := ""
global VerdictText := ""
global ConfigurationText := ""
global FullPreview := ""
global CropPreview := ""
global ConsoleEdit := ""
global TapReloadButton := ""
global CropXEdit := "", CropYEdit := "", CropWEdit := "", CropHEdit := ""
global TargetWindowTitle := ""
global ADBSerial := ""
global Viewport := ""
global CropDirty := false
global SyncingControls := false
global Inspecting := false
global ReloadAction := false
global FullPreviewPath := ScratchDir "\reload_ocr_inspector_full.png"
global CropPreviewPath := ScratchDir "\reload_ocr_inspector_crop.png"
global FramePath := ScratchDir "\reload_ocr_inspector_frame.png"

CreateInspectorGui()
RunInspectCycle()
return

CreateInspectorGui() {
    global InspectorGui, VerdictText, ConfigurationText, FullPreview, CropPreview, ConsoleEdit, TapReloadButton
    global CropXEdit, CropYEdit, CropWEdit, CropHEdit

    InspectorGui := Gui("+Resize +MinSize1120x760", "Reload OCR Visual Inspector")
    InspectorGui.SetFont("s10", "Segoe UI")
    InspectorGui.Add("Text", "x20 y15 w130 h22", "Target window:")
    ConfigurationText := InspectorGui.Add("Text", "x145 y15 w900 h22 cBlue", "Loading config.ini...")
    InspectorGui.Add("GroupBox", "x18 y43 w500 h112", "Reload OCR crop (client coordinates)")

    InspectorGui.Add("Text", "x35 y75 w18 h22", "X")
    CropXEdit := InspectorGui.Add("Edit", "x55 y72 w75 Number")
    InspectorGui.Add("UpDown", "Range0-10000", 0)
    InspectorGui.Add("Text", "x145 y75 w18 h22", "Y")
    CropYEdit := InspectorGui.Add("Edit", "x165 y72 w75 Number")
    InspectorGui.Add("UpDown", "Range0-10000", 0)
    InspectorGui.Add("Text", "x255 y75 w20 h22", "W")
    CropWEdit := InspectorGui.Add("Edit", "x278 y72 w75 Number")
    InspectorGui.Add("UpDown", "Range1-10000", 1)
    InspectorGui.Add("Text", "x367 y75 w18 h22", "H")
    CropHEdit := InspectorGui.Add("Edit", "x388 y72 w75 Number")
    InspectorGui.Add("UpDown", "Range1-10000", 1)

    captureButton := InspectorGui.Add("Button", "x35 y112 w130 h30", "Capture && OCR (Ctrl+R)")
    calibrateButton := InspectorGui.Add("Button", "x175 y112 w150 h30", "Set XY from Mouse (Space)")
    saveButton := InspectorGui.Add("Button", "x335 y112 w130 h30", "Save Crop to Config")
    captureButton.OnEvent("Click", RunInspectCycle)
    calibrateButton.OnEvent("Click", SetCropOriginFromMouse)
    saveButton.OnEvent("Click", SaveCropToConfig)
    for control in [CropXEdit, CropYEdit, CropWEdit, CropHEdit]
        control.OnEvent("Change", MarkCropDirty)

    InspectorGui.SetFont("s16 Bold", "Segoe UI")
    VerdictText := InspectorGui.Add("Text", "x535 y55 w560 h45 cBlue +Center", "Verdict: READY")
    InspectorGui.SetFont("s10 Norm", "Segoe UI")
    InspectorGui.Add("Text", "x535 y106 w560 h30 +Center", "Green outline = Reload recognized. Red outline = Reload not recognized.")
    TapReloadButton := InspectorGui.Add("Button", "x760 y125 w215 h30 Disabled", "Tap Recognized Reload (ADB)")
    TapReloadButton.OnEvent("Click", TapReloadAction)

    InspectorGui.Add("GroupBox", "x18 y166 w535 h335", "Full ADB frame with crop outline")
    FullPreview := InspectorGui.Add("Picture", "x28 y190 w515 h300 +Border")
    InspectorGui.Add("GroupBox", "x565 y166 w535 h335", "Exact OCR crop")
    CropPreview := InspectorGui.Add("Picture", "x575 y190 w515 h300 +Border")

    InspectorGui.Add("GroupBox", "x18 y512 w1082 h220", "Diagnostics")
    InspectorGui.SetFont("s9", "Consolas")
    ConsoleEdit := InspectorGui.Add("Edit", "x28 y537 w1062 h182 ReadOnly +VScroll +HScroll", "")
    InspectorGui.SetFont("s10", "Segoe UI")
    InspectorGui.OnEvent("Close", (*) => ExitApp())
    InspectorGui.Show("w1120 h750")
}

MarkCropDirty(*) {
    global CropDirty, SyncingControls
    if SyncingControls
        return
    CropDirty := true
    SetTimer(RunInspectCycle, -150)
}

RunInspectCycle(*) {
    global Inspecting, CropDirty, CropXEdit, CropYEdit, CropWEdit, CropHEdit
    global FullPreview, CropPreview, FullPreviewPath, CropPreviewPath, FramePath, Viewport
    global TapReloadButton, ReloadAction

    if Inspecting
        return
    Inspecting := true
    ReloadAction := false
    TapReloadButton.Enabled := false
    try {
        ReloadConfig()
        cropClient := {
            x: ControlInteger(CropXEdit, Viewport.x),
            y: ControlInteger(CropYEdit, Viewport.y),
            w: Max(1, ControlInteger(CropWEdit, Round(Viewport.width * 0.80))),
            h: Max(1, ControlInteger(CropHEdit, Round(Viewport.height * 0.30)))
        }
        frame := CaptureADBFrame()
        frameSize := GetImageSize(frame)
        cropImage := ClientRectToImageRect(cropClient, Viewport, frameSize)
        SaveImageRegion(frame, cropImage, CropPreviewPath)

        cardCheck := IsErrorCardColorMatch(frame, Viewport, frameSize)
        ocrLines := []
        ocrWords := []
        reloadFound := false
        try {
            ocrScale := 1.5
            result := OCR.FromFile(CropPreviewPath, {scale: ocrScale})
            for line in result.Lines {
                text := Trim(line.Text, " `t`r`n")
                if (text != "")
                    ocrLines.Push(text)
            }
            for word in result.Words {
                normalizedWord := NormalizeOCRFromFileWord(word, ocrScale)
                text := Trim(normalizedWord.text, " `t`r`n")
                if (text != "")
                    ocrWords.Push(text)
                if IsReloadText(text) {
                    reloadFound := true
                    if !IsObject(ReloadAction) {
                        imageX := cropImage.x + normalizedWord.x + normalizedWord.w / 2
                        imageY := cropImage.y + normalizedWord.y + normalizedWord.h / 2
                        clientPoint := ImagePointToClient(imageX, imageY, Viewport, frameSize)
                        ReloadAction := {
                            text: text,
                            adbX: imageX,
                            adbY: imageY,
                            clientX: clientPoint.x,
                            clientY: clientPoint.y
                        }
                    }
                }
            }
        } catch as err {
            ocrLines.Push("OCR error: " err.Message)
        }

        passed := cardCheck.isMatch && reloadFound
        tapPoint := false
        if IsObject(ReloadAction)
            tapPoint := {x: ReloadAction.adbX, y: ReloadAction.adbY}
        SaveFrameWithCropOutline(frame, cropImage, FullPreviewPath, passed, tapPoint)
        FullPreview.Value := FullPreviewPath
        CropPreview.Value := CropPreviewPath
        SetVerdict(passed, "", cardCheck.isMatch, reloadFound)
        TapReloadButton.Enabled := passed && IsObject(ReloadAction)
        AppendLog(Format("Reconnect card color gate: {}/{} samples matched.", cardCheck.count, cardCheck.total))
        AppendLog(Format(
            "Client crop x={} y={} w={} h={} -> ADB crop x={} y={} w={} h={}.",
            cropClient.x, cropClient.y, cropClient.w, cropClient.h,
            cropImage.x, cropImage.y, cropImage.width, cropImage.height
        ))
        AppendLog("OCR lines: " (ocrLines.Length ? JoinLines(ocrLines) : "(none)"))
        AppendLog("OCR words: " (ocrWords.Length ? JoinLines(ocrWords) : "(none)"))
        if IsObject(ReloadAction)
            AppendLog(Format("Tap target: '{}' at ADB ({}, {}), client ({}, {}).",
                ReloadAction.text, Round(ReloadAction.adbX), Round(ReloadAction.adbY),
                Round(ReloadAction.clientX), Round(ReloadAction.clientY)))
    } catch as err {
        SetVerdict(false, "ERROR: " err.Message)
        AppendLog("Inspector error: " err.Message)
    } finally {
        Inspecting := false
    }
}

ReloadConfig() {
    global ConfigPath, TargetWindowTitle, ADBSerial, Viewport, CropDirty, SyncingControls
    global CropXEdit, CropYEdit, CropWEdit, CropHEdit, ConfigurationText

    if !FileExist(ConfigPath)
        throw Error("config.ini is missing: " ConfigPath)

    TargetWindowTitle := IniRead(ConfigPath, "Settings", "TargetWindowTitle", "Clash of Clans")
    provider := IniRead(ConfigPath, "ADB", "Provider", "Google Play Games Developer Emulator")
    ADBSerial := provider == "BlueStacks"
        ? IniRead(ConfigPath, "ADB", "BlueStacksSerial", "127.0.0.1:5555")
        : "localhost:6520"
    left := ReadIniInteger("ADBViewport", "Left", 0)
    top := ReadIniInteger("ADBViewport", "Top", 0)
    right := ReadIniInteger("ADBViewport", "Right", -1)
    bottom := ReadIniInteger("ADBViewport", "Bottom", -1)
    if (right <= left || bottom <= top)
        throw Error("ADB viewport calibration is invalid. Run Main Calibration first.")
    Viewport := {x: left, y: top, width: right - left, height: bottom - top}
    ConfigurationText.Value := Format(
        "Target: {} | ADB: {} | calibrated viewport: ({}, {}) {}x{}",
        TargetWindowTitle, ADBSerial, Viewport.x, Viewport.y, Viewport.width, Viewport.height
    )

    if !CropDirty {
        SyncingControls := true
        try {
            CropXEdit.Value := ReadIniInteger("VisualTests", "ReloadCropX", Round(Viewport.x + Viewport.width * 0.10))
            CropYEdit.Value := ReadIniInteger("VisualTests", "ReloadCropY", Round(Viewport.y + Viewport.height * 0.35))
            CropWEdit.Value := ReadIniInteger("VisualTests", "ReloadCropW", Round(Viewport.width * 0.80))
            CropHEdit.Value := ReadIniInteger("VisualTests", "ReloadCropH", Round(Viewport.height * 0.30))
        } finally {
            SyncingControls := false
        }
    }
}

ReadIniInteger(section, key, fallback) {
    global ConfigPath
    value := IniRead(ConfigPath, section, key, "")
    return RegExMatch(value, "^-?\d+$") ? Integer(value) : fallback
}

ControlInteger(control, fallback) {
    value := Trim(control.Value)
    return RegExMatch(value, "^-?\d+$") ? Integer(value) : fallback
}

SetCropOriginFromMouse(*) {
    global TargetWindowTitle, CropXEdit, CropYEdit, CropDirty, Viewport

    ReloadConfig()
    if !WinExist(TargetWindowTitle) {
        AppendLog("Calibration failed: target window '" TargetWindowTitle "' was not found.")
        return
    }
    WinGetClientPos &clientLeft, &clientTop, &clientWidth, &clientHeight, TargetWindowTitle
    MouseGetPos &mouseX, &mouseY
    x := mouseX - clientLeft
    y := mouseY - clientTop
    if (x < Viewport.x || y < Viewport.y || x >= Viewport.x + Viewport.width || y >= Viewport.y + Viewport.height) {
        AppendLog("Calibration failed: mouse is outside the calibrated Android viewport.")
        return
    }
    CropXEdit.Value := x
    CropYEdit.Value := y
    CropDirty := true
    AppendLog(Format("Crop origin set from mouse: x={} y={}. Adjust W/H, then capture.", x, y))
    SetTimer(RunInspectCycle, -150)
}

SaveCropToConfig(*) {
    global ConfigPath, CropXEdit, CropYEdit, CropWEdit, CropHEdit, CropDirty

    IniWrite(CropXEdit.Value, ConfigPath, "VisualTests", "ReloadCropX")
    IniWrite(CropYEdit.Value, ConfigPath, "VisualTests", "ReloadCropY")
    IniWrite(CropWEdit.Value, ConfigPath, "VisualTests", "ReloadCropW")
    IniWrite(CropHEdit.Value, ConfigPath, "VisualTests", "ReloadCropH")
    CropDirty := false
    AppendLog("Saved ReloadCropX/Y/W/H to config.ini [VisualTests].")
}

CaptureADBFrame() {
    global ADBSerial, ScratchDir, FramePath, ProjectRoot

    DirCreate(ScratchDir)
    try FileDelete(FramePath)
    adbPath := ResolveADBPath()
    command := A_ComSpec ' /D /S /C ""' adbPath '" -s "' ADBSerial '" exec-out screencap -p > "' FramePath '""'
    exitCode := RunWait(command, ProjectRoot, "Hide")
    if (exitCode != 0 || !FileExist(FramePath) || FileGetSize(FramePath) < 100)
        throw Error("ADB screencap failed for " ADBSerial ".")
    return FramePath
}

ResolveADBPath() {
    for directory in StrSplit(EnvGet("PATH"), ";") {
        directory := Trim(directory, ' "')
        if (directory == "")
            continue
        candidate := RTrim(directory, "\\/") "\\adb.exe"
        if FileExist(candidate)
            return candidate
    }
    bundledADB := "C:\\Program Files\\Google\\Play Games Developer Emulator\\current\\emulator\\adb.exe"
    if FileExist(bundledADB)
        return bundledADB
    throw Error("adb.exe was not found in PATH or the Google Play Games Developer Emulator folder.")
}

ClientRectToImageRect(clientRect, viewport, imageSize) {
    left := Max(viewport.x, Min(viewport.x + viewport.width - 1, clientRect.x))
    top := Max(viewport.y, Min(viewport.y + viewport.height - 1, clientRect.y))
    right := Max(left + 1, Min(viewport.x + viewport.width, clientRect.x + clientRect.w))
    bottom := Max(top + 1, Min(viewport.y + viewport.height, clientRect.y + clientRect.h))
    imageLeft := Round((left - viewport.x) * imageSize.width / viewport.width)
    imageTop := Round((top - viewport.y) * imageSize.height / viewport.height)
    imageRight := Round((right - viewport.x) * imageSize.width / viewport.width)
    imageBottom := Round((bottom - viewport.y) * imageSize.height / viewport.height)
    return {
        x: Max(0, imageLeft),
        y: Max(0, imageTop),
        width: Max(1, Min(imageSize.width, imageRight) - imageLeft),
        height: Max(1, Min(imageSize.height, imageBottom) - imageTop)
    }
}

GetImageSize(imagePath) {
    InitGDIPlus()
    bitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", imagePath, "ptr*", &bitmap) != 0
        throw Error("Could not open image: " imagePath)
    try {
        width := 0, height := 0
        DllCall("gdiplus\GdipGetImageWidth", "ptr", bitmap, "uint*", &width)
        DllCall("gdiplus\GdipGetImageHeight", "ptr", bitmap, "uint*", &height)
        return {width: width, height: height}
    } finally {
        DllCall("gdiplus\GdipDisposeImage", "ptr", bitmap)
    }
}

SaveImageRegion(sourcePath, rect, destinationPath) {
    InitGDIPlus()
    source := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", sourcePath, "ptr*", &source) != 0
        throw Error("Could not open ADB frame for cropping.")
    cropped := 0
    try {
        status := DllCall(
            "gdiplus\GdipCloneBitmapArea",
            "float", Float(rect.x), "float", Float(rect.y),
            "float", Float(rect.width), "float", Float(rect.height),
            "int", 0x26200A, "ptr", source, "ptr*", &cropped
        )
        if (status != 0)
            throw Error("GDI+ crop failed with status " status ".")
        SaveBitmap(cropped, destinationPath)
    } finally {
        if cropped
            DllCall("gdiplus\GdipDisposeImage", "ptr", cropped)
        DllCall("gdiplus\GdipDisposeImage", "ptr", source)
    }
}

SaveFrameWithCropOutline(sourcePath, rect, destinationPath, passed, tapPoint := false) {
    InitGDIPlus()
    bitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", sourcePath, "ptr*", &bitmap) != 0
        throw Error("Could not open ADB frame for preview.")
    graphics := 0, pen := 0, tapPen := 0
    try {
        DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", bitmap, "ptr*", &graphics)
        color := passed ? 0xFF00FF00 : 0xFFFF0000
        DllCall("gdiplus\GdipCreatePen1", "uint", color, "float", 4.0, "int", 2, "ptr*", &pen)
        DllCall(
            "gdiplus\GdipDrawRectangle",
            "ptr", graphics, "ptr", pen,
            "float", Float(rect.x), "float", Float(rect.y),
            "float", Float(rect.width), "float", Float(rect.height)
        )
        if IsObject(tapPoint) {
            ; Tap target crosshair: the exact point passed to ADB.
            DllCall("gdiplus\GdipCreatePen1", "uint", 0xFFFFFF00, "float", 4.0, "int", 2, "ptr*", &tapPen)
            radius := 18
            DllCall(
                "gdiplus\GdipDrawLine", "ptr", graphics, "ptr", tapPen,
                "float", Float(tapPoint.x - radius), "float", Float(tapPoint.y),
                "float", Float(tapPoint.x + radius), "float", Float(tapPoint.y)
            )
            DllCall(
                "gdiplus\GdipDrawLine", "ptr", graphics, "ptr", tapPen,
                "float", Float(tapPoint.x), "float", Float(tapPoint.y - radius),
                "float", Float(tapPoint.x), "float", Float(tapPoint.y + radius)
            )
        }
        SaveBitmap(bitmap, destinationPath)
    } finally {
        if tapPen
            DllCall("gdiplus\GdipDeletePen", "ptr", tapPen)
        if pen
            DllCall("gdiplus\GdipDeletePen", "ptr", pen)
        if graphics
            DllCall("gdiplus\GdipDeleteGraphics", "ptr", graphics)
        DllCall("gdiplus\GdipDisposeImage", "ptr", bitmap)
    }
}

SaveBitmap(bitmap, destinationPath) {
    clsid := Buffer(16, 0)
    DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid)
    status := DllCall(
        "gdiplus\GdipSaveImageToFile",
        "ptr", bitmap, "wstr", destinationPath, "ptr", clsid, "ptr", 0
    )
    if (status != 0)
        throw Error("GDI+ preview save failed with status " status ".")
}

InitGDIPlus() {
    static token := 0
    if (token == 0) {
        startupInput := Buffer(24, 0)
        NumPut("uint", 1, startupInput, 0)
        DllCall("gdiplus\GdiplusStartup", "ptr*", &token, "ptr", startupInput, "ptr", 0)
    }
}

IsReloadText(text) {
    normalized := StrLower(RegExReplace(String(text), "[^A-Za-z]", ""))
    return InStr(normalized, "reload") > 0
}

IsErrorCardColorMatch(framePath, viewport, imageSize) {
    centerX := viewport.x + viewport.width * 0.50
    centerY := viewport.y + viewport.height * 0.50
    offsets := [
        {x: 0, y: 0}, {x: -15, y: 0}, {x: 15, y: 0},
        {x: 0, y: -15}, {x: 0, y: 15}, {x: -15, y: -15}
    ]
    InitGDIPlus()
    bitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", framePath, "ptr*", &bitmap) != 0
        throw Error("Could not open ADB frame for reconnect-card detection.")
    matches := 0
    try {
        for offset in offsets {
            point := ClientPointToImagePoint(centerX + offset.x, centerY + offset.y, viewport, imageSize)
            argb := 0
            status := DllCall(
                "gdiplus\GdipBitmapGetPixel", "ptr", bitmap,
                "int", point.x, "int", point.y, "uint*", &argb
            )
            if (status != 0)
                continue
            rgb := argb & 0x00FFFFFF
            red := (rgb >> 16) & 0xFF
            green := (rgb >> 8) & 0xFF
            blue := rgb & 0xFF
            if (Abs(red - 0x19) <= 15 && Abs(green - 0x1C) <= 15 && Abs(blue - 0x1E) <= 15)
                matches += 1
        }
    } finally {
        DllCall("gdiplus\GdipDisposeImage", "ptr", bitmap)
    }
    return {isMatch: matches >= 3, count: matches, total: offsets.Length}
}

ClientPointToImagePoint(clientX, clientY, viewport, imageSize) {
    return {
        x: Round((clientX - viewport.x) * imageSize.width / viewport.width),
        y: Round((clientY - viewport.y) * imageSize.height / viewport.height)
    }
}

ImagePointToClient(imageX, imageY, viewport, imageSize) {
    return {
        x: Round(viewport.x + imageX * viewport.width / imageSize.width),
        y: Round(viewport.y + imageY * viewport.height / imageSize.height)
    }
}

TapReloadAction(*) {
    global ReloadAction, TapReloadButton, ADBSerial, ProjectRoot

    if !IsObject(ReloadAction) {
        AppendLog("Tap blocked: capture a recognized Reload action first.")
        return
    }
    TapReloadButton.Enabled := false
    try {
        adbPath := ResolveADBPath()
        command := '"' adbPath '" -s "' ADBSerial '" shell input tap ' Round(ReloadAction.adbX) ' ' Round(ReloadAction.adbY)
        exitCode := RunWait(command, ProjectRoot, "Hide")
        if (exitCode != 0)
            throw Error("ADB tap failed with exit code " exitCode ".")
        AppendLog(Format("Tapped '{}' at ADB ({}, {}). Recapturing in 500 ms.",
            ReloadAction.text, Round(ReloadAction.adbX), Round(ReloadAction.adbY)))
        Sleep(500)
        RunInspectCycle()
    } catch as err {
        AppendLog("Tap error: " err.Message)
        SetVerdict(false, "TAP ERROR: " err.Message)
    }
}

SetVerdict(passed, errorText := "", cardMatched := false, reloadFound := false) {
    global VerdictText
    if (errorText != "") {
        VerdictText.Opt("cRed")
        VerdictText.Value := "Verdict: " errorText
        return
    }
    if passed {
        VerdictText.Opt("cGreen")
        VerdictText.Value := "Verdict: RELOAD RECOVERY READY (PASS)"
    } else {
        VerdictText.Opt("cRed")
        VerdictText.Value := "Verdict: FAIL — card=" (cardMatched ? "yes" : "no") " reload=" (reloadFound ? "yes" : "no")
    }
}

AppendLog(message) {
    global ConsoleEdit
    timestamp := FormatTime(, "HH:mm:ss")
    ConsoleEdit.Value .= "[" timestamp "] " message "`r`n"
    SendMessage(0x0115, 7, 0, ConsoleEdit.Hwnd)
}

JoinLines(lines) {
    output := ""
    for index, line in lines
        output .= (index > 1 ? " | " : "") line
    return output
}

#HotIf WinActive("Reload OCR Visual Inspector")
^r::RunInspectCycle()
Space::SetCropOriginFromMouse()
#HotIf
