#Requires AutoHotkey v2.0
#SingleInstance Force
#Include OCR.ahk
#Include ADBcocbotrefactor_support.ahk

; AHK-only comparison harness for the Builder and Laboratory availability
; fractions. It captures one ADB frame per F1 press and never taps the game.

global BLComparisonFramePath := A_Temp "\coc_builder_lab_ocr_comparison_frame.png"
global BLBuilderCropPath := A_Temp "\coc_builder_lab_ocr_comparison_builder.png"
global BLLabCropPath := A_Temp "\coc_builder_lab_ocr_comparison_lab.png"
global BLBuilderGreyCropPath := A_Temp "\coc_builder_lab_ocr_comparison_builder_grey.png"
global BLLabGreyCropPath := A_Temp "\coc_builder_lab_ocr_comparison_lab_grey.png"
global BLBuilderContrastCropPath := A_Temp "\coc_builder_lab_ocr_comparison_builder_contrast.png"
global BLLabContrastCropPath := A_Temp "\coc_builder_lab_ocr_comparison_lab_contrast.png"
global BLMappingIdentity := "", BLDisplayWidth := 0, BLDisplayHeight := 0
global BLSerial := "", BLViewportLeft := 0, BLViewportTop := 0
global BLViewportRight := -1, BLViewportBottom := -1
global BLClientWidth := 0, BLClientHeight := 0, BLProvider := ""
global BLBuilderFaceX := 960, BLBuilderFaceY := 30
global BLLabFaceX := 960, BLLabFaceY := 30

LoadBLComparisonConfig()

BLGui := Gui("+Resize", "Clash of Clans - Builder/Lab AHK OCR Comparator")
BLGui.SetFont("s10", "Segoe UI")
BLGui.Add("Text", "x15 y14 w690 h40", "F1 captures one fresh ADB frame, then compares the Builder and Laboratory fractions with AHK OCR only. No Python vision hook and no game taps are used.")
BLStatus := BLGui.Add("Text", "x15 y60 w690 h25 cBlue", "Status: Ready - press F1 to capture and compare.")
BtnCapture := BLGui.Add("Button", "x15 y92 w180 h34", "Capture / Compare (F1)")
BtnClear := BLGui.Add("Button", "x205 y92 w120 h34", "Clear Console")
BLGui.Add("GroupBox", "x15 y140 w335 h150", "Builder fraction - Normal crop")
BLBuilderPicture := BLGui.Add("Picture", "x25 y165 w315 h110 +Border", "")
BLGui.Add("GroupBox", "x370 y140 w335 h150", "Laboratory fraction - Normal crop")
BLLabPicture := BLGui.Add("Picture", "x380 y165 w315 h110 +Border", "")
BLGui.Add("GroupBox", "x15 y300 w335 h150", "Builder fraction - Grey preview")
BLBuilderGreyPicture := BLGui.Add("Picture", "x25 y325 w315 h110 +Border", "")
BLGui.Add("GroupBox", "x370 y300 w335 h150", "Laboratory fraction - Grey preview")
BLLabGreyPicture := BLGui.Add("Picture", "x380 y325 w315 h110 +Border", "")
BLGui.Add("GroupBox", "x15 y460 w335 h150", "Builder fraction - Contrast preview")
BLBuilderContrastPicture := BLGui.Add("Picture", "x25 y485 w315 h110 +Border", "")
BLGui.Add("GroupBox", "x370 y460 w335 h150", "Laboratory fraction - Contrast preview")
BLLabContrastPicture := BLGui.Add("Picture", "x380 y485 w315 h110 +Border", "")
BLGui.Add("Text", "x15 y622 w690 h22", "Each line shows a unified fraction plus individual readings at 1.5x, 2.0x, 2.5x, and 3.0x.")
BLGui.SetFont("s9", "Consolas")
BLConsole := BLGui.Add("Edit", "x15 y650 w690 h195 ReadOnly +VScroll +HScroll", "")
BLGui.SetFont("s10", "Segoe UI")
BtnCapture.OnEvent("Click", (*) => CaptureBuilderLabComparison())
BtnClear.OnEvent("Click", (*) => ClearBLConsole())
BLGui.OnEvent("Close", HandleBLClose)
BLGui.Show("w720 h865")
BLLog("Ready. Uses AutoHotkey OCR only; it does not call the Python vision hook.")
BLLog("Contrast = grayscale then luminance threshold 160: below 160 black; 160 or above white.")
return

F1::CaptureBuilderLabComparison()
F2::BLLog("F2 has no action in this one-shot inspector. Press F1 for another fresh frame.")

CaptureBuilderLabComparison() {
    global BLStatus, BLBuilderPicture, BLLabPicture
    global BLBuilderGreyPicture, BLLabGreyPicture, BLBuilderContrastPicture, BLLabContrastPicture
    global BLViewportTop, BLViewportBottom
    global BLBuilderFaceX, BLBuilderFaceY, BLLabFaceX, BLLabFaceY
    global BLBuilderCropPath, BLLabCropPath
    global BLBuilderGreyCropPath, BLLabGreyCropPath, BLBuilderContrastCropPath, BLLabContrastCropPath
    try {
        LoadBLComparisonConfig()
        EnsureBLMapping()
        BLStatus.Text := "Status: Capturing one fresh frame."
        BLStatus.Opt("cGreen")
        BLLog("=== Builder/Lab comparison | one fresh frame ===")
        framePath := CaptureBuilderLabADBFrame()
        viewportHeight := BLViewportBottom - BLViewportTop
        GetBLBuilderCropRegion(viewportHeight, &builderW, &builderH, &builderOffX, &builderOffY)
        GetBLLabCropRegion(viewportHeight, &labW, &labH, &labOffX, &labOffY)
        SaveBLCrop(framePath, BLBuilderFaceX - builderOffX, BLBuilderFaceY - builderOffY, builderW, builderH, BLBuilderCropPath)
        SaveBLCrop(framePath, BLLabFaceX - labOffX, BLLabFaceY - labOffY, labW, labH, BLLabCropPath)
        SaveBLPreviewVariant(BLBuilderCropPath, BLBuilderGreyCropPath, "Grey")
        SaveBLPreviewVariant(BLLabCropPath, BLLabGreyCropPath, "Grey")
        SaveBLPreviewVariant(BLBuilderCropPath, BLBuilderContrastCropPath, "Contrast")
        SaveBLPreviewVariant(BLLabCropPath, BLLabContrastCropPath, "Contrast")
        BLBuilderPicture.Value := BLBuilderCropPath
        BLLabPicture.Value := BLLabCropPath
        BLBuilderGreyPicture.Value := BLBuilderGreyCropPath
        BLLabGreyPicture.Value := BLLabGreyCropPath
        BLBuilderContrastPicture.Value := BLBuilderContrastCropPath
        BLLabContrastPicture.Value := BLLabContrastCropPath

        normalBuilder := ReadFractionWithComparisonMethod(BLBuilderCropPath, "Normal")
        normalLab := ReadFractionWithComparisonMethod(BLLabCropPath, "Normal")
        greyBuilder := ReadFractionWithComparisonMethod(BLBuilderCropPath, "Grey")
        greyLab := ReadFractionWithComparisonMethod(BLLabCropPath, "Grey")
        contrastBuilder := ReadFractionWithComparisonMethod(BLBuilderCropPath, "Contrast")
        contrastLab := ReadFractionWithComparisonMethod(BLLabCropPath, "Contrast")
        BLLog("Normal: Builder=" normalBuilder.summary ", Lab=" normalLab.summary)
        BLLog("Grey: Builder=" greyBuilder.summary ", Lab=" greyLab.summary)
        BLLog("Contrast: Builder=" contrastBuilder.summary ", Lab=" contrastLab.summary)
        BLStatus.Text := "Status: Complete - press F1 for another fresh frame."
        BLStatus.Opt("cBlue")
    } catch as err {
        BLStatus.Text := "Status: Capture error"
        BLStatus.Opt("cRed")
        BLLog("Capture error: " err.Message)
    }
}

ReadFractionWithComparisonMethod(imagePath, methodName) {
    readings := []
    perScale := []
    for scaleValue in [1.5, 2.0, 2.5, 3.0] {
        options := {scale: scaleValue}
        if (methodName = "Grey")
            options.grayscale := true
        else if (methodName = "Contrast")
            options := {scale: scaleValue, grayscale: true, monochrome: 160}
        fraction := ""
        try {
            ocrResult := OCR.FromFile(imagePath, options)
            fraction := ParseComparisonFraction(ocrResult.Text)
        } catch as err {
            fraction := ""
        }
        if (fraction != "")
            readings.Push(fraction)
        perScale.Push(Format("{:.1f}={}", scaleValue, fraction != "" ? fraction : "-"))
    }
    unified := SelectComparisonFractionConsensus(readings)
    unifiedText := unified.valid ? unified.value : "INVALID"
    return {summary: "U=" unifiedText " [" JoinBLComparison(perScale, "; ") "]"}
}

ParseComparisonFraction(text) {
    normalized := StrReplace(text, " ", "")
    normalized := StrReplace(normalized, "`r", "")
    normalized := StrReplace(normalized, "`n", "")
    for replacement in [
        ["i", "1"], ["I", "1"], ["l", "1"], ["|", "1"], ["!", "1"],
        ["o", "0"], ["O", "0"], ["s", "5"], ["S", "5"], ["g", "9"],
        ["G", "9"], ["q", "9"], ["b", "6"], ["B", "8"], ["z", "2"],
        ["Z", "2"], ["a", "4"], ["A", "4"]
    ]
        normalized := StrReplace(normalized, replacement[1], replacement[2])
    if !RegExMatch(normalized, "(\d)\s*/\s*(\d)", &match)
        return ""
    free := Integer(match[1])
    total := Integer(match[2])
    if (total <= 0 || free > total)
        return ""
    return free "/" total
}

SelectComparisonFractionConsensus(readings) {
    frequencies := Map()
    for value in readings
        frequencies[value] := frequencies.Has(value) ? frequencies[value] + 1 : 1
    if (readings.Length = 0)
        return {valid: false, value: ""}
    winner := "", winnerCount := 0, tied := false
    for value, count in frequencies {
        if (count > winnerCount) {
            winner := value, winnerCount := count, tied := false
        } else if (count = winnerCount) {
            tied := true
        }
    }
    return {valid: !tied, value: winner}
}

JoinBLComparison(items, delimiter) {
    joined := ""
    for index, item in items
        joined .= (index > 1 ? delimiter : "") item
    return joined
}

GetBLBuilderCropRegion(height, &width, &cropHeight, &offsetX, &offsetY) {
    fullWidth := Max(100, Round(height * 0.1362))
    cropHeight := Max(24, Round(height * 0.0292))
    fullOffsetX := Round(fullWidth * 0.22)
    ; Keep the old right edge fixed while bringing only the left edge in.
    width := Max(80, Round(fullWidth * 0.55))
    offsetX := fullOffsetX - Round(fullWidth * 0.45)
    offsetY := Round(cropHeight * 0.50)
}

GetBLLabCropRegion(height, &width, &cropHeight, &offsetX, &offsetY) {
    fullWidth := Max(100, Round(height * 0.12))
    cropHeight := Max(30, Round(height * 0.04))
    fullOffsetX := Round(fullWidth * 0.15)
    ; Keep the old right edge fixed while bringing only the left edge in.
    width := Max(75, Round(fullWidth * 0.50))
    offsetX := fullOffsetX - Round(fullWidth * 0.50)
    offsetY := Round(cropHeight * 0.50)
}

LoadBLComparisonConfig() {
    global BLSerial, BLViewportLeft, BLViewportTop, BLViewportRight, BLViewportBottom
    global BLClientWidth, BLClientHeight, BLProvider
    global BLBuilderFaceX, BLBuilderFaceY, BLLabFaceX, BLLabFaceY
    configPath := A_ScriptDir "\config.ini"
    BLSerial := IniRead(configPath, "ADBViewport", "Serial", "")
    BLViewportLeft := ReadBLIniInt(configPath, "ADBViewport", "Left", 0)
    BLViewportTop := ReadBLIniInt(configPath, "ADBViewport", "Top", 0)
    BLViewportRight := ReadBLIniInt(configPath, "ADBViewport", "Right", -1)
    BLViewportBottom := ReadBLIniInt(configPath, "ADBViewport", "Bottom", -1)
    BLClientWidth := ReadBLIniInt(configPath, "ADBViewport", "ClientWidth", 0)
    BLClientHeight := ReadBLIniInt(configPath, "ADBViewport", "ClientHeight", 0)
    BLProvider := IniRead(configPath, "ADBViewport", "Provider", "")
    BLBuilderFaceX := ReadBLIniInt(configPath, "Coordinates", "BuilderFaceX", 960)
    BLBuilderFaceY := ReadBLIniInt(configPath, "Coordinates", "BuilderFaceY", 30)
    BLLabFaceX := ReadBLIniInt(configPath, "Coordinates", "LabFaceX", 960)
    BLLabFaceY := ReadBLIniInt(configPath, "Coordinates", "LabFaceY", 30)
}

ReadBLIniInt(configPath, section, key, fallback) {
    value := IniRead(configPath, section, key, "")
    if (value = "")
        return fallback
    try return Integer(value)
    catch
        return fallback
}

EnsureBLMapping() {
    global BLMappingIdentity, BLDisplayWidth, BLDisplayHeight
    global BLSerial, BLViewportLeft, BLViewportTop, BLViewportRight, BLViewportBottom
    global BLClientWidth, BLClientHeight, BLProvider
    if (BLSerial = "")
        throw Error("ADBViewport.Serial is missing from config.ini.")
    if (BLViewportRight <= BLViewportLeft || BLViewportBottom <= BLViewportTop)
        throw Error("ADBViewport bounds in config.ini are invalid.")
    identity := BLSerial "|" BLViewportLeft "|" BLViewportTop "|" BLViewportRight "|" BLViewportBottom
    if (identity = BLMappingIdentity && BLDisplayWidth > 0 && BLDisplayHeight > 0)
        return
    display := QueryBLADBDisplaySize(BLSerial)
    BLDisplayWidth := display.width, BLDisplayHeight := display.height
    ConfigureADBClientMapping(BLViewportLeft, BLViewportTop, BLViewportRight, BLViewportBottom, BLDisplayWidth, BLDisplayHeight, BLClientWidth, BLClientHeight, BLProvider, BLSerial)
    BLMappingIdentity := identity
    BLLog("ADB mapping ready: client " BLClientWidth "x" BLClientHeight ", ADB " BLDisplayWidth "x" BLDisplayHeight ".")
}

QueryBLADBDisplaySize(serial) {
    state := RunBLADBOutput('-s "' serial '" get-state')
    if !state.ok
        throw Error("ADB device is not ready.")
    result := RunBLADBOutput('-s "' serial '" shell wm size')
    if !result.ok
        throw Error("Could not query ADB display size.")
    if RegExMatch(result.output, "i)Override size:\s*(\d+)x(\d+)", &match)
        return {width: Number(match[1]), height: Number(match[2])}
    if RegExMatch(result.output, "i)Physical size:\s*(\d+)x(\d+)", &match)
        return {width: Number(match[1]), height: Number(match[2])}
    throw Error("ADB returned an unrecognized display size.")
}

ResolveBLADBPath() {
    for directory in StrSplit(EnvGet("PATH"), ";") {
        directory := Trim(directory, ' "')
        if (directory = "")
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

RunBLADBOutput(arguments) {
    adbPath := ResolveBLADBPath()
    outputPath := A_Temp "\coc_builder_lab_ocr_comparison_adb_output.txt"
    try FileDelete(outputPath)
    command := A_ComSpec ' /D /S /C ""' adbPath '" ' arguments ' > "' outputPath '" 2>&1"'
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    output := FileExist(outputPath) ? Trim(FileRead(outputPath), " `t`r`n") : ""
    try FileDelete(outputPath)
    return {ok: exitCode = 0, output: output}
}

CaptureBuilderLabADBFrame() {
    global BLSerial, BLComparisonFramePath
    adbPath := ResolveBLADBPath()
    try FileDelete(BLComparisonFramePath)
    command := A_ComSpec ' /D /S /C ""' adbPath '" -s "' BLSerial '" exec-out screencap -p > "' BLComparisonFramePath '""'
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    if (exitCode != 0 || !FileExist(BLComparisonFramePath) || FileGetSize(BLComparisonFramePath) < 1024)
        throw Error("Fresh ADB screenshot failed.")
    return BLComparisonFramePath
}

InitBLGDIPlus() {
    static token := 0
    if (token = 0) {
        startupInput := Buffer(24, 0)
        NumPut("uint", 1, startupInput, 0)
        DllCall("gdiplus\GdiplusStartup", "ptr*", &token, "ptr", startupInput, "ptr", 0)
    }
    return token
}

SaveBLCrop(framePath, clientX, clientY, clientW, clientH, destinationPath) {
    adbRect := TranslateClientRectToADB(clientX, clientY, clientW, clientH)
    InitBLGDIPlus()
    source := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", framePath, "ptr*", &source) != 0
        throw Error("ADB frame could not be opened for cropping.")
    cropped := 0
    status := DllCall("gdiplus\GdipCloneBitmapArea", "float", Float(adbRect.x), "float", Float(adbRect.y), "float", Float(adbRect.width), "float", Float(adbRect.height), "int", 0x26200A, "ptr", source, "ptr*", &cropped)
    if (status != 0) {
        DllCall("gdiplus\GdipDisposeImage", "ptr", source)
        throw Error("ADB frame crop failed.")
    }
    clsid := Buffer(16, 0)
    DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid)
    try FileDelete(destinationPath)
    saveStatus := DllCall("gdiplus\GdipSaveImageToFile", "ptr", cropped, "wstr", destinationPath, "ptr", clsid, "ptr", 0)
    DllCall("gdiplus\GdipDisposeImage", "ptr", cropped)
    DllCall("gdiplus\GdipDisposeImage", "ptr", source)
    if (saveStatus != 0)
        throw Error("Crop could not be saved.")
}

SaveBLPreviewVariant(sourcePath, destinationPath, variant) {
    InitBLGDIPlus()
    bitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", sourcePath, "ptr*", &bitmap) != 0
        throw Error("Preview source could not be opened.")
    width := 0, height := 0
    DllCall("gdiplus\GdipGetImageWidth", "ptr", bitmap, "uint*", &width)
    DllCall("gdiplus\GdipGetImageHeight", "ptr", bitmap, "uint*", &height)
    Loop height {
        y := A_Index - 1
        Loop width {
            x := A_Index - 1
            pixel := 0
            if DllCall("gdiplus\GdipBitmapGetPixel", "ptr", bitmap, "int", x, "int", y, "uint*", &pixel) != 0
                continue
            red := (pixel >> 16) & 0xFF
            green := (pixel >> 8) & 0xFF
            blue := pixel & 0xFF
            luminance := Round((red * 299 + green * 587 + blue * 114) / 1000)
            if (variant = "Contrast")
                outputPixel := luminance >= 160 ? 0xFFFFFFFF : 0xFF000000
            else
                outputPixel := 0xFF000000 | (luminance << 16) | (luminance << 8) | luminance
            DllCall("gdiplus\GdipBitmapSetPixel", "ptr", bitmap, "int", x, "int", y, "uint", outputPixel)
        }
    }
    clsid := Buffer(16, 0)
    DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid)
    try FileDelete(destinationPath)
    saveStatus := DllCall("gdiplus\GdipSaveImageToFile", "ptr", bitmap, "wstr", destinationPath, "ptr", clsid, "ptr", 0)
    DllCall("gdiplus\GdipDisposeImage", "ptr", bitmap)
    if (saveStatus != 0)
        throw Error("Preview image could not be saved.")
}

ClearBLConsole() {
    global BLConsole
    BLConsole.Value := ""
}

BLLog(message) {
    global BLConsole
    BLConsole.Value := BLConsole.Value message "`r`n"
    SendMessage(0x0115, 7, 0, BLConsole.Hwnd)
}

HandleBLClose(*) {
    CleanupBLFiles()
    ExitApp()
}

CleanupBLFiles() {
    global BLComparisonFramePath, BLBuilderCropPath, BLLabCropPath
    global BLBuilderGreyCropPath, BLLabGreyCropPath, BLBuilderContrastCropPath, BLLabContrastCropPath
    for path in [BLComparisonFramePath, BLBuilderCropPath, BLLabCropPath, BLBuilderGreyCropPath, BLLabGreyCropPath, BLBuilderContrastCropPath, BLLabContrastCropPath, A_Temp "\coc_builder_lab_ocr_comparison_adb_output.txt"]
        try FileDelete(path)
}
