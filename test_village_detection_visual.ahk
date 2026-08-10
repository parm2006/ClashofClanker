#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ADBcocbotrefactor_support.ahk

SetTitleMatchMode 2

global VillageInspectorTargetTitle := "Emulator"
global VillageInspectorViewportLeft := 0, VillageInspectorViewportTop := 0
global VillageInspectorViewportRight := -1, VillageInspectorViewportBottom := -1
global VillageInspectorClientWidth := 0, VillageInspectorClientHeight := 0
global VillageInspectorProvider := "", VillageInspectorSerial := ""
global VillageInspectorDisplayWidth := 0, VillageInspectorDisplayHeight := 0
global VillageInspectorMappingIdentity := ""
global VillageInspectorAttackX := 0, VillageInspectorAttackY := 0
global VillageInspectorBBAttackX := 0, VillageInspectorBBAttackY := 0
global VillageInspectorWarLogoX := 0, VillageInspectorWarLogoY := 0
global VillageInspectorFramePath := A_Temp "\coc_village_detection_frame.png"
global VillageInspectorPreviewPath := A_Temp "\coc_village_detection_preview.png"
global VillageInspectorPreviewSourcePath := ""
global VillageInspectorGui := "", VillageInspectorVerdict := ""
global VillageInspectorStatus := "", VillageInspectorPicture := ""
global VillageInspectorConsole := "", VillageInspectorPreviewGroup := ""
global VillageInspectorConsoleLabel := ""

ReloadVillageInspectorConfig()
AssertProductionDetectorContract()
CreateVillageInspectorGui()
return

F1::RunVillageInspector()

CreateVillageInspectorGui() {
    global VillageInspectorGui, VillageInspectorVerdict, VillageInspectorStatus
    global VillageInspectorPicture, VillageInspectorConsole
    global VillageInspectorPreviewGroup, VillageInspectorConsoleLabel

    VillageInspectorGui := Gui("+Resize +MinSize720x720", "Clash of Clanker - Village Detection Inspector")
    VillageInspectorGui.SetFont("s10", "Segoe UI")
    VillageInspectorGui.Add("Text", "x15 y14 w875 h22", "Read-only: runs the production village identifier logic on one fresh ADB frame. F1 never taps.")
    button := VillageInspectorGui.Add("Button", "x15 y44 w200 h34", "F1 Capture + Identify")
    button.OnEvent("Click", (*) => RunVillageInspector())
    clearButton := VillageInspectorGui.Add("Button", "x225 y44 w120 h34", "Clear Console")
    clearButton.OnEvent("Click", (*) => VillageInspectorConsole.Value := "")

    VillageInspectorGui.SetFont("s16 Bold", "Segoe UI")
    VillageInspectorVerdict := VillageInspectorGui.Add("Text", "x15 y88 w875 h34 cBlue", "Verdict: READY")
    VillageInspectorGui.SetFont("s10 Norm", "Segoe UI")
    VillageInspectorStatus := VillageInspectorGui.Add("Text", "x15 y124 w875 h24 cBlue", "Main = Attack + war logo. Builder = Attack + no war logo.")

    VillageInspectorPreviewGroup := VillageInspectorGui.Add("GroupBox", "x15 y155 w890 h515", "Fresh ADB Screenshot (green = passed color test; red = failed color test)")
    VillageInspectorPicture := VillageInspectorGui.Add("Picture", "x25 y180 w860 h480 +Border", "")
    VillageInspectorConsoleLabel := VillageInspectorGui.Add("Text", "x15 y680 w890 h22", "Diagnostic console")
    VillageInspectorGui.SetFont("s9", "Consolas")
    VillageInspectorConsole := VillageInspectorGui.Add("Edit", "x15 y705 w890 h210 ReadOnly +VScroll +HScroll", "")
    VillageInspectorGui.SetFont("s10", "Segoe UI")

    VillageInspectorGui.OnEvent("Close", (*) => ExitApp())
    VillageInspectorGui.OnEvent("Size", VillageInspectorGuiResized)
    VillageInspectorGui.Show("w920 h940")
    VillageInspectorLog("Ready. F1 captures a fresh frame and evaluates the exact production decision rule.")
    VillageInspectorLog("Overlay order: M = Main attack samples; B = Builder attack samples; W = war-logo samples.")
}

RunVillageInspector() {
    global VillageInspectorTargetTitle, VillageInspectorClientWidth, VillageInspectorClientHeight
    global VillageInspectorVerdict, VillageInspectorStatus, VillageInspectorFramePath
    global VillageInspectorPreviewPath

    try {
        ReloadVillageInspectorConfig()
        AssertProductionDetectorContract()
        hwnd := WinExist(VillageInspectorTargetTitle)
        if !hwnd
            throw Error("Target window '" VillageInspectorTargetTitle "' was not found.")
        WinGetClientPos &clientX, &clientY, &clientW, &clientH, hwnd
        EnsureVillageInspectorMapping(clientW, clientH)
        framePath := CaptureVillageInspectorFrame()
        analysis := AnalyzeVillageFrameUsingProductionCopy(framePath)
        SaveVillageInspectorOverlay(framePath, analysis.samples, VillageInspectorPreviewPath)
        ShowVillageInspectorPreview(VillageInspectorPreviewPath)

        if (analysis.village == "main") {
            VillageInspectorVerdict.Text := "Verdict: MAIN VILLAGE"
            VillageInspectorVerdict.Opt("cGreen")
            VillageInspectorStatus.Text := "Main attack=" analysis.mainAttack " | War logo=" analysis.warLogo " | Builder attack=" analysis.builderAttack
            VillageInspectorStatus.Opt("cGreen")
        } else if (analysis.village == "builder") {
            VillageInspectorVerdict.Text := "Verdict: BUILDER BASE"
            VillageInspectorVerdict.Opt("cGreen")
            VillageInspectorStatus.Text := "Main attack=" analysis.mainAttack " | War logo=" analysis.warLogo " | Builder attack=" analysis.builderAttack
            VillageInspectorStatus.Opt("cGreen")
        } else {
            VillageInspectorVerdict.Text := "Verdict: BATTLE / UNKNOWN"
            VillageInspectorVerdict.Opt("cRed")
            VillageInspectorStatus.Text := "Main attack=" analysis.mainAttack " | War logo=" analysis.warLogo " | Builder attack=" analysis.builderAttack
            VillageInspectorStatus.Opt("cRed")
        }
        VillageInspectorLog("==========================================================================")
        VillageInspectorLog("PRODUCTION COPY RESULT: " StrUpper(analysis.village))
        VillageInspectorLog("Main condition  = main attack [" analysis.mainAttack "] AND war logo [" analysis.warLogo "]")
        VillageInspectorLog("Builder condition = builder attack [" analysis.builderAttack "] AND NOT war logo [" !analysis.warLogo "]")
        for sample in analysis.samples
            VillageInspectorLog(sample.label " client(" sample.clientX "," sample.clientY ") -> ADB(" sample.adbX "," sample.adbY ") RGB=" sample.rgb " matched=" sample.matched)
        VillageInspectorLog("==========================================================================")
    } catch as err {
        VillageInspectorVerdict.Text := "Verdict: ANALYSIS ERROR"
        VillageInspectorVerdict.Opt("cRed")
        VillageInspectorStatus.Text := "Status: " err.Message
        VillageInspectorStatus.Opt("cRed")
        VillageInspectorLog("ERROR: " err.Message)
    }
}

; Exact behavioral copy of DetectVillageFromADBFrame() in ADBcocbotrefactor.ahk.
AnalyzeVillageFrameUsingProductionCopy(framePath) {
    global VillageInspectorAttackX, VillageInspectorAttackY
    global VillageInspectorBBAttackX, VillageInspectorBBAttackY
    global VillageInspectorWarLogoX, VillageInspectorWarLogoY

    samples := []
    mainLeft := VillageInspectorAttackSample(framePath, VillageInspectorAttackX - 45, VillageInspectorAttackY, "M-left")
    mainRight := VillageInspectorAttackSample(framePath, VillageInspectorAttackX + 45, VillageInspectorAttackY, "M-right")
    mainAttack := mainLeft.matched || mainRight.matched
    samples.Push(mainLeft, mainRight)

    warResult := VillageInspectorWarLogoSamples(framePath)
    warLogo := warResult.matched
    for sample in warResult.samples
        samples.Push(sample)

    builderLeft := VillageInspectorAttackSample(framePath, VillageInspectorBBAttackX - 45, VillageInspectorBBAttackY, "B-left")
    builderRight := VillageInspectorAttackSample(framePath, VillageInspectorBBAttackX + 45, VillageInspectorBBAttackY, "B-right")
    builderAttack := builderLeft.matched || builderRight.matched
    samples.Push(builderLeft, builderRight)

    ; Keep this decision ordering exactly aligned with DetectVillageFromADBFrame().
    village := "battle"
    if (mainAttack && warLogo)
        village := "main"
    else if (builderAttack && !warLogo)
        village := "builder"
    return {village: village, mainAttack: mainAttack, warLogo: warLogo, builderAttack: builderAttack, samples: samples}
}

VillageInspectorAttackSample(framePath, clientX, clientY, label) {
    color := VillageInspectorFramePixel(framePath, clientX, clientY)
    r := (color >> 16) & 0xFF, g := (color >> 8) & 0xFF, b := color & 0xFF
    point := TranslateClientPointToADB(clientX, clientY)
    return {label: label, clientX: clientX, clientY: clientY, adbX: point.x, adbY: point.y, rgb: Format("#{:06X}", color), matched: ProductionCopyIsAttackBtnColor(r, g, b), type: "attack"}
}

VillageInspectorWarLogoSamples(framePath) {
    global VillageInspectorWarLogoX, VillageInspectorWarLogoY
    offsets := [{x: 0, y: 0}, {x: -20, y: -20}, {x: 20, y: -20}, {x: -20, y: 20}, {x: 20, y: 20}]
    samples := []
    matched := false
    for index, offset in offsets {
        clientX := VillageInspectorWarLogoX + offset.x
        clientY := VillageInspectorWarLogoY + offset.y
        color := VillageInspectorFramePixel(framePath, clientX, clientY)
        r := (color >> 16) & 0xFF, g := (color >> 8) & 0xFF, b := color & 0xFF
        point := TranslateClientPointToADB(clientX, clientY)
        isMatch := ProductionCopyIsWarLogoColor(r, g, b)
        samples.Push({label: "W-" index, clientX: clientX, clientY: clientY, adbX: point.x, adbY: point.y, rgb: Format("#{:06X}", color), matched: isMatch, type: "war"})
        if isMatch
            matched := true
    }
    return {matched: matched, samples: samples}
}

; Exact behavioral copies of the production color predicates.
ProductionCopyIsAttackBtnColor(r, g, b) {
    isBrownWood := (r > g) && (g > b) && (r - b >= 25) && (g - b >= 10) && (r >= 70 && r <= 250)
    isTanMap := (r >= 180) && (g >= 140) && (b >= 90) && (r >= g) && (g >= b * 0.75)
    return isBrownWood || isTanMap
}

ProductionCopyIsWarLogoColor(r, g, b) {
    isSilverSword := (r >= 150) && (g >= 150) && (b >= 130) && (Abs(r - g) <= 40) && (Abs(g - b) <= 40)
    isBrownWood := (r > g) && (g > b) && (r - b >= 20) && (g - b >= 5) && (r >= 70 && r <= 250)
    isGoldFrame := (r >= 180) && (g >= 110) && (b <= 130) && (r > g + 15)
    return isSilverSword || isBrownWood || isGoldFrame
}

VillageInspectorFramePixel(framePath, clientX, clientY) {
    point := TranslateClientPointToADB(clientX, clientY)
    InitVillageInspectorGDIPlus()
    bitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", framePath, "ptr*", &bitmap) != 0
        throw Error("Could not open fresh ADB frame.")
    try {
        argb := 0
        status := DllCall("gdiplus\GdipBitmapGetPixel", "ptr", bitmap, "int", point.x, "int", point.y, "uint*", &argb)
        if (status != 0)
            throw Error("Could not sample ADB pixel at " point.x "," point.y ".")
        return argb & 0x00FFFFFF
    } finally {
        DllCall("gdiplus\GdipDisposeImage", "ptr", bitmap)
    }
}

ReloadVillageInspectorConfig() {
    global VillageInspectorTargetTitle, VillageInspectorViewportLeft, VillageInspectorViewportTop
    global VillageInspectorViewportRight, VillageInspectorViewportBottom
    global VillageInspectorClientWidth, VillageInspectorClientHeight
    global VillageInspectorProvider, VillageInspectorSerial
    global VillageInspectorAttackX, VillageInspectorAttackY
    global VillageInspectorBBAttackX, VillageInspectorBBAttackY
    global VillageInspectorWarLogoX, VillageInspectorWarLogoY

    VillageInspectorTargetTitle := IniRead("config.ini", "Settings", "TargetWindowTitle", VillageInspectorTargetTitle)
    VillageInspectorViewportLeft := VillageInspectorConfigInt("ADBViewport", "Left", 0)
    VillageInspectorViewportTop := VillageInspectorConfigInt("ADBViewport", "Top", 0)
    VillageInspectorViewportRight := VillageInspectorConfigInt("ADBViewport", "Right", -1)
    VillageInspectorViewportBottom := VillageInspectorConfigInt("ADBViewport", "Bottom", -1)
    VillageInspectorClientWidth := VillageInspectorConfigInt("ADBViewport", "ClientWidth", 0)
    VillageInspectorClientHeight := VillageInspectorConfigInt("ADBViewport", "ClientHeight", 0)
    VillageInspectorProvider := IniRead("config.ini", "ADBViewport", "Provider", "")
    VillageInspectorSerial := IniRead("config.ini", "ADBViewport", "Serial", "")
    VillageInspectorAttackX := VillageInspectorConfigInt("Coordinates", "AttackBtnX", 100)
    VillageInspectorAttackY := VillageInspectorConfigInt("Coordinates", "AttackBtnY", 970)
    VillageInspectorBBAttackX := VillageInspectorConfigInt("Coordinates", "BBAttackBtnX", 100)
    VillageInspectorBBAttackY := VillageInspectorConfigInt("Coordinates", "BBAttackBtnY", 970)
    VillageInspectorWarLogoX := VillageInspectorConfigInt("Coordinates", "MVLogoX", 100)
    VillageInspectorWarLogoY := VillageInspectorConfigInt("Coordinates", "MVLogoY", 700)
}

VillageInspectorConfigInt(section, key, fallback) {
    value := IniRead("config.ini", section, key, "")
    return (value != "" && IsNumber(value)) ? Number(value) : fallback
}

EnsureVillageInspectorMapping(clientWidth, clientHeight) {
    global VillageInspectorMappingIdentity, VillageInspectorDisplayWidth, VillageInspectorDisplayHeight
    global VillageInspectorViewportLeft, VillageInspectorViewportTop, VillageInspectorViewportRight, VillageInspectorViewportBottom
    global VillageInspectorClientWidth, VillageInspectorClientHeight, VillageInspectorProvider, VillageInspectorSerial

    if (VillageInspectorSerial == "")
        throw Error("ADBViewport.Serial is missing from config.ini.")
    if (clientWidth != VillageInspectorClientWidth || clientHeight != VillageInspectorClientHeight)
        throw Error("Client size " clientWidth "x" clientHeight " does not match calibration " VillageInspectorClientWidth "x" VillageInspectorClientHeight ".")
    identity := clientWidth "|" clientHeight "|" VillageInspectorProvider "|" VillageInspectorSerial "|" VillageInspectorViewportLeft "|" VillageInspectorViewportTop "|" VillageInspectorViewportRight "|" VillageInspectorViewportBottom
    if (identity == VillageInspectorMappingIdentity && VillageInspectorDisplayWidth > 0 && VillageInspectorDisplayHeight > 0)
        return
    display := QueryVillageInspectorDisplaySize()
    VillageInspectorDisplayWidth := display.width, VillageInspectorDisplayHeight := display.height
    ConfigureADBClientMapping(VillageInspectorViewportLeft, VillageInspectorViewportTop, VillageInspectorViewportRight, VillageInspectorViewportBottom, display.width, display.height, clientWidth, clientHeight, VillageInspectorProvider, VillageInspectorSerial)
    VillageInspectorMappingIdentity := identity
}

QueryVillageInspectorDisplaySize() {
    global VillageInspectorSerial
    result := RunVillageInspectorADB('-s "' VillageInspectorSerial '" shell wm size')
    if !result.ok
        throw Error("Could not query ADB display size: " result.output)
    if RegExMatch(result.output, "i)Override size:\\s*(\\d+)x(\\d+)", &match)
        return {width: Number(match[1]), height: Number(match[2])}
    if RegExMatch(result.output, "i)Physical size:\\s*(\\d+)x(\\d+)", &match)
        return {width: Number(match[1]), height: Number(match[2])}
    throw Error("Unrecognized ADB display size: " result.output)
}

CaptureVillageInspectorFrame() {
    global VillageInspectorSerial, VillageInspectorFramePath
    adbPath := ResolveVillageInspectorADBPath()
    try FileDelete(VillageInspectorFramePath)
    command := A_ComSpec ' /D /S /C ""' adbPath '" -s "' VillageInspectorSerial '" exec-out screencap -p > "' VillageInspectorFramePath '""'
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    if (exitCode != 0 || !FileExist(VillageInspectorFramePath) || FileGetSize(VillageInspectorFramePath) < 1024)
        throw Error("Fresh ADB screenshot failed with exit " exitCode ".")
    return VillageInspectorFramePath
}

ResolveVillageInspectorADBPath() {
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

RunVillageInspectorADB(arguments) {
    adbPath := ResolveVillageInspectorADBPath()
    outputPath := A_Temp "\coc_village_detection_adb_output.txt"
    try FileDelete(outputPath)
    command := A_ComSpec ' /D /S /C ""' adbPath '" ' arguments ' > "' outputPath '" 2>&1"'
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    output := FileExist(outputPath) ? Trim(FileRead(outputPath), " `t`r`n") : ""
    try FileDelete(outputPath)
    return {ok: exitCode == 0, output: output}
}

SaveVillageInspectorOverlay(sourcePath, samples, destinationPath) {
    InitVillageInspectorGDIPlus()
    bitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", sourcePath, "ptr*", &bitmap) != 0
        throw Error("Could not create overlay from fresh ADB frame.")
    graphics := 0
    DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", bitmap, "ptr*", &graphics)
    try {
        for sample in samples {
            color := sample.matched ? 0xFF00FF00 : 0xFFFF0000
            pen := 0
            DllCall("gdiplus\GdipCreatePen1", "uint", color, "float", 5.0, "int", 2, "ptr*", &pen)
            try DllCall("gdiplus\GdipDrawRectangle", "ptr", graphics, "ptr", pen, "float", Float(sample.adbX - 10), "float", Float(sample.adbY - 10), "float", 20.0, "float", 20.0)
            finally DllCall("gdiplus\GdipDeletePen", "ptr", pen)
        }
    } finally {
        if graphics
            DllCall("gdiplus\GdipDeleteGraphics", "ptr", graphics)
    }
    clsid := Buffer(16, 0)
    DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid)
    status := DllCall("gdiplus\GdipSaveImageToFile", "ptr", bitmap, "wstr", destinationPath, "ptr", clsid, "ptr", 0)
    DllCall("gdiplus\GdipDisposeImage", "ptr", bitmap)
    if (status != 0)
        throw Error("Could not save overlay; GDI+ status " status ".")
}

ShowVillageInspectorPreview(imagePath) {
    global VillageInspectorPicture, VillageInspectorPreviewSourcePath
    VillageInspectorPreviewSourcePath := imagePath
    FitVillageInspectorPreview(imagePath)
    VillageInspectorPicture.Value := ""
    VillageInspectorPicture.Value := imagePath
}

VillageInspectorGuiResized(gui, minMax, width, height) {
    global VillageInspectorPreviewSourcePath
    if (minMax != -1 && VillageInspectorPreviewSourcePath != "")
        FitVillageInspectorPreview(VillageInspectorPreviewSourcePath)
}

FitVillageInspectorPreview(imagePath) {
    global VillageInspectorGui, VillageInspectorPreviewGroup, VillageInspectorPicture, VillageInspectorConsoleLabel, VillageInspectorConsole
    size := VillageInspectorImageSize(imagePath)
    if (size.width <= 0 || size.height <= 0)
        return
    VillageInspectorGui.GetClientPos(&x, &y, &width, &height)
    maxWidth := Max(300, width - 50), maxHeight := Max(180, height - 360)
    scale := Min(maxWidth / size.width, maxHeight / size.height)
    previewWidth := Round(size.width * scale), previewHeight := Round(size.height * scale)
    previewX := Round((width - previewWidth) / 2), previewY := 180
    consoleY := previewY + previewHeight + 35
    VillageInspectorPreviewGroup.Move(15, 155, width - 30, previewHeight + 50)
    VillageInspectorPicture.Move(previewX, previewY, previewWidth, previewHeight)
    VillageInspectorConsoleLabel.Move(15, consoleY, width - 30, 22)
    VillageInspectorConsole.Move(15, consoleY + 25, width - 30, Max(150, height - consoleY - 40))
}

VillageInspectorImageSize(imagePath) {
    InitVillageInspectorGDIPlus()
    bitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", imagePath, "ptr*", &bitmap) != 0
        return {width: 0, height: 0}
    try {
        width := 0, height := 0
        DllCall("gdiplus\GdipGetImageWidth", "ptr", bitmap, "uint*", &width)
        DllCall("gdiplus\GdipGetImageHeight", "ptr", bitmap, "uint*", &height)
        return {width: width, height: height}
    } finally {
        DllCall("gdiplus\GdipDisposeImage", "ptr", bitmap)
    }
}

VillageInspectorLog(message) {
    global VillageInspectorConsole
    VillageInspectorConsole.Value .= "[" FormatTime(, "HH:mm:ss") "] " message "`n"
    SendMessage(0x0115, 7, 0, VillageInspectorConsole)
}

InitVillageInspectorGDIPlus() {
    static token := 0
    if (token == 0) {
        startupInput := Buffer(24, 0)
        NumPut("uint", 1, startupInput, 0)
        DllCall("gdiplus\GdiplusStartup", "ptr*", &token, "ptr", startupInput, "ptr", 0)
    }
    return token
}

AssertProductionDetectorContract() {
    source := FileRead(A_ScriptDir "\ADBcocbotrefactor.ahk")
    start := InStr(source, "DetectVillageFromADBFrame(framePath) {")
    end := InStr(source, "AreCloudsPresentInADBFrame(framePath) {", false, start)
    if (!start || !end)
        throw Error("Could not locate the production village detector.")
    production := RegExReplace(SubStr(source, start, end - start), "\s+")
    expected := RegExReplace("DetectVillageFromADBFrame(framePath) { global AttackBtnX, AttackBtnY, BBAttackBtnX, BBAttackBtnY mainAttack := IsAttackButtonInADBFrame(framePath, AttackBtnX - 45, AttackBtnY) || IsAttackButtonInADBFrame(framePath, AttackBtnX + 45, AttackBtnY) warLogo := IsWarLogoInADBFrame(framePath) if (mainAttack && warLogo) return \"main\" builderAttack := IsAttackButtonInADBFrame(framePath, BBAttackBtnX - 45, BBAttackBtnY) || IsAttackButtonInADBFrame(framePath, BBAttackBtnX + 45, BBAttackBtnY) if (builderAttack && !warLogo) return \"builder\" return \"battle\" }", "\s+")
    if (production != expected)
        throw Error("Production village detector changed; update this inspector before using it.")
}
