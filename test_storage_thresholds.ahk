#Requires AutoHotkey v2.0
#SingleInstance Force
#Include OCR.ahk
#Include loot_ocr_logic.ahk
#Include resource_threshold_logic.ahk
#Include builder_info_ocr_logic.ahk
#Include ADBcocbotrefactor_support.ahk

SetTitleMatchMode 2

global TargetWindowTitle := "Clash of Clans"
global GoldBarThreshX := 1492, GoldBarThreshY := 87
global ElixirBarThreshX := 1494, ElixirBarThreshY := 165
global DarkElixirBarThreshX := 1559, DarkElixirBarThreshY := 240
global BuilderFaceX := 839, BuilderFaceY := 85
global BuilderMenuBottomX := 909, BuilderMenuBottomY := 627
global ClearTapX := 1676, ClearTapY := 416

global ViewportLeft := 0, ViewportTop := 0
global ViewportRight := -1, ViewportBottom := -1
global CalibratedClientWidth := 0, CalibratedClientHeight := 0
global CalibratedProvider := "", CalibratedSerial := ""
global DisplayWidth := 0, DisplayHeight := 0
global MappingIdentity := ""

global CoordinatesDirty := false
global IsUpdatingControls := false
global IsLiveMonitoring := false
global IsCalibrating := false
global CalibrationStage := ""

global ThresholdFramePath := A_Temp "\coc_threshold_fresh_adb_frame.png"
global GoldPreviewPath := A_Temp "\coc_threshold_gold_preview.png"
global ElixirPreviewPath := A_Temp "\coc_threshold_elixir_preview.png"
global DarkPreviewPath := A_Temp "\coc_threshold_dark_preview.png"
global BuilderCountCropPath := A_Temp "\coc_builder_info_builder_count.png"
global SuggestionCropPath := A_Temp "\coc_builder_info_suggestions.png"
global SuggestionPreviewPath := A_Temp "\coc_builder_info_suggestion_tap.png"
global InfoCropPath := A_Temp "\coc_builder_info_action_bar.png"
global InfoPreviewPath := A_Temp "\coc_builder_info_action_preview.png"

ReloadThresholdConfig(true)

ThresholdGui := Gui(
    "+Resize",
    "Clash of Clanker - Fresh ADB Resource Threshold Inspector"
)
ThresholdGui.SetFont("s10", "Segoe UI")

ThresholdGui.Add("Text", "x15 y14 w100 h25", "Target Window:")
EditTarget := ThresholdGui.Add(
    "Edit",
    "x120 y10 w220 h26",
    TargetWindowTitle
)
ChkTop := ThresholdGui.Add(
    "Checkbox",
    "x355 y14 w130 h25",
    "Always On Top"
)
StatusText := ThresholdGui.Add(
    "Text",
    "x500 y14 w200 h25 Right cGray",
    "Status: Ready"
)

ThresholdGui.Add(
    "GroupBox",
    "x15 y43 w685 h112",
    "Threshold Points (Client Coordinates)"
)
AddPointControls(
    "Gold",
    25,
    68,
    GoldBarThreshX,
    GoldBarThreshY,
    &EditGoldX,
    &EditGoldY
)
AddPointControls(
    "Elixir",
    245,
    68,
    ElixirBarThreshX,
    ElixirBarThreshY,
    &EditElixirX,
    &EditElixirY
)
AddPointControls(
    "Dark Elixir",
    465,
    68,
    DarkElixirBarThreshX,
    DarkElixirBarThreshY,
    &EditDarkX,
    &EditDarkY
)
BtnCalibrate := ThresholdGui.Add(
    "Button",
    "x25 y116 w145 h28",
    "Calibrate (Space)"
)
BtnSave := ThresholdGui.Add(
    "Button",
    "x180 y116 w110 h28",
    "Save Config"
)
BtnReload := ThresholdGui.Add(
    "Button",
    "x300 y116 w130 h28",
    "Reload Config"
)

BtnInspect := ThresholdGui.Add(
    "Button",
    "x15 y165 w155 h35",
    "Inspect Once (F1)"
)
BtnLive := ThresholdGui.Add(
    "Button",
    "x180 y165 w170 h35",
    "Start Live Monitoring"
)
BtnBuilderFlow := ThresholdGui.Add(
    "Button",
    "x360 y165 w215 h35",
    "Run Builder to Info (F2)"
)
BtnClear := ThresholdGui.Add(
    "Button",
    "x590 y165 w110 h35",
    "Clear Console"
)

ThresholdGui.Add(
    "GroupBox",
    "x15 y208 w685 h75",
    "Fresh ADB Threshold Verdict"
)
ThresholdGui.SetFont("s16 Bold", "Segoe UI")
VerdictText := ThresholdGui.Add(
    "Text",
    "x30 y232 w655 h42 cBlue",
    "Verdict: READY FOR ADB FRAME"
)
ThresholdGui.SetFont("s10 Norm", "Segoe UI")

ThresholdGui.Add(
    "GroupBox",
    "x15 y290 w220 h145",
    "Gold Point"
)
PicGold := ThresholdGui.Add(
    "Picture",
    "x25 y315 w200 h110 +Border",
    ""
)
ThresholdGui.Add(
    "GroupBox",
    "x245 y290 w220 h145",
    "Elixir Point"
)
PicElixir := ThresholdGui.Add(
    "Picture",
    "x255 y315 w200 h110 +Border",
    ""
)
ThresholdGui.Add(
    "GroupBox",
    "x475 y290 w220 h145",
    "Dark Elixir Point"
)
PicDark := ThresholdGui.Add(
    "Picture",
    "x485 y315 w200 h110 +Border",
    ""
)

ThresholdGui.Add(
    "GroupBox",
    "x15 y443 w335 h170",
    "Suggested Upgrade Tap (final ADB point)"
)
PicSuggestion := ThresholdGui.Add(
    "Picture",
    "x25 y468 w315 h135 +Border",
    ""
)
ThresholdGui.Add(
    "GroupBox",
    "x365 y443 w335 h170",
    "Info Template Match (stops before confirmation)"
)
PicInfoFlow := ThresholdGui.Add(
    "Picture",
    "x375 y468 w315 h135 +Border",
    ""
)

ThresholdGui.Add(
    "GroupBox",
    "x15 y621 w685 h350",
    "Fresh ADB RGB Diagnostics"
)
ThresholdGui.SetFont("s9", "Consolas")
ConsoleEdit := ThresholdGui.Add(
    "Edit",
    "x25 y646 w665 h315 ReadOnly +VScroll +HScroll",
    ""
)
ThresholdGui.SetFont("s10", "Segoe UI")

EditTarget.OnEvent("Change", (*) => UpdateThresholdTarget())
ChkTop.OnEvent(
    "Click",
    (*) => ThresholdGui.Opt(
        (ChkTop.Value ? "+" : "-") "AlwaysOnTop"
    )
)
for control in [
    EditGoldX,
    EditGoldY,
    EditElixirX,
    EditElixirY,
    EditDarkX,
    EditDarkY
] {
    control.OnEvent("Change", (*) => OnThresholdPointChanged())
}
BtnCalibrate.OnEvent("Click", (*) => BeginThresholdCalibration())
BtnSave.OnEvent("Click", (*) => SaveThresholdConfig())
BtnReload.OnEvent("Click", (*) => ReloadThresholdPoints())
BtnInspect.OnEvent("Click", (*) => RunInspectCycle())
BtnLive.OnEvent("Click", (*) => ToggleLiveMonitoring())
BtnBuilderFlow.OnEvent("Click", (*) => RunBuilderUpgradeInfoFlow())
BtnClear.OnEvent("Click", (*) => ClearThresholdConsole())
ThresholdGui.OnEvent("Close", (*) => ExitApp())
ThresholdGui.Show("w715 h986")

ThresholdLog(
    "Ready. F1 captures one fresh ADB frame and evaluates all three "
        "resource points from that same frame."
)
ThresholdLog(
    "Dark Elixir rule: R < 70, G < 60, B < 80. "
        "No Windows desktop pixels or saved ADB coordinates are used."
)
ThresholdLog(
    "F2 runs thresholds, builder availability, the first suggestion, and "
        "Info through background ADB. It NEVER presses confirmation."
)

AddPointControls(
    label,
    x,
    y,
    pointX,
    pointY,
    &editX,
    &editY
) {
    global ThresholdGui
    ThresholdGui.Add("Text", "x" x " y" y " w85 h20", label " X:")
    editX := ThresholdGui.Add(
        "Edit",
        "x" (x + 75) " y" (y - 3) " w55 h24 Number",
        String(pointX)
    )
    ThresholdGui.Add("UpDown", "Range0-4000", pointX)
    ThresholdGui.Add(
        "Text",
        "x" x " y" (y + 27) " w85 h20",
        label " Y:"
    )
    editY := ThresholdGui.Add(
        "Edit",
        "x" (x + 75) " y" (y + 24) " w55 h24 Number",
        String(pointY)
    )
    ThresholdGui.Add("UpDown", "Range0-4000", pointY)
}

ReloadThresholdConfig(reloadPoints := false) {
    global TargetWindowTitle
    global GoldBarThreshX, GoldBarThreshY
    global ElixirBarThreshX, ElixirBarThreshY
    global DarkElixirBarThreshX, DarkElixirBarThreshY
    global BuilderFaceX, BuilderFaceY
    global BuilderMenuBottomX, BuilderMenuBottomY
    global ClearTapX, ClearTapY
    global ViewportLeft, ViewportTop, ViewportRight, ViewportBottom
    global CalibratedClientWidth, CalibratedClientHeight
    global CalibratedProvider, CalibratedSerial

    if !FileExist("config.ini")
        return
    TargetWindowTitle := IniRead(
        "config.ini",
        "Settings",
        "TargetWindowTitle",
        TargetWindowTitle
    )
    ViewportLeft := ReadThresholdInteger(
        "ADBViewport",
        "Left",
        ViewportLeft
    )
    ViewportTop := ReadThresholdInteger(
        "ADBViewport",
        "Top",
        ViewportTop
    )
    ViewportRight := ReadThresholdInteger(
        "ADBViewport",
        "Right",
        ViewportRight
    )
    ViewportBottom := ReadThresholdInteger(
        "ADBViewport",
        "Bottom",
        ViewportBottom
    )
    CalibratedClientWidth := ReadThresholdInteger(
        "ADBViewport",
        "ClientWidth",
        CalibratedClientWidth
    )
    CalibratedClientHeight := ReadThresholdInteger(
        "ADBViewport",
        "ClientHeight",
        CalibratedClientHeight
    )
    CalibratedProvider := IniRead(
        "config.ini",
        "ADBViewport",
        "Provider",
        CalibratedProvider
    )
    CalibratedSerial := IniRead(
        "config.ini",
        "ADBViewport",
        "Serial",
        CalibratedSerial
    )
    BuilderFaceX := ReadThresholdInteger(
        "Coordinates",
        "BuilderFaceX",
        BuilderFaceX
    )
    BuilderFaceY := ReadThresholdInteger(
        "Coordinates",
        "BuilderFaceY",
        BuilderFaceY
    )
    BuilderMenuBottomX := ReadThresholdInteger(
        "Coordinates",
        "BuilderMenuBottomX",
        BuilderMenuBottomX
    )
    BuilderMenuBottomY := ReadThresholdInteger(
        "Coordinates",
        "BuilderMenuBottomY",
        BuilderMenuBottomY
    )
    ClearTapX := ReadThresholdInteger(
        "VisualTests",
        "ClearTapX",
        ClearTapX
    )
    ClearTapY := ReadThresholdInteger(
        "VisualTests",
        "ClearTapY",
        ClearTapY
    )
    if reloadPoints {
        GoldBarThreshX := ReadThresholdInteger(
            "Coordinates",
            "GoldBarThreshX",
            GoldBarThreshX
        )
        GoldBarThreshY := ReadThresholdInteger(
            "Coordinates",
            "GoldBarThreshY",
            GoldBarThreshY
        )
        ElixirBarThreshX := ReadThresholdInteger(
            "Coordinates",
            "ElixirBarThreshX",
            ElixirBarThreshX
        )
        ElixirBarThreshY := ReadThresholdInteger(
            "Coordinates",
            "ElixirBarThreshY",
            ElixirBarThreshY
        )
        DarkElixirBarThreshX := ReadThresholdInteger(
            "Coordinates",
            "DarkElixirBarThreshX",
            DarkElixirBarThreshX
        )
        DarkElixirBarThreshY := ReadThresholdInteger(
            "Coordinates",
            "DarkElixirBarThreshY",
            DarkElixirBarThreshY
        )
    }
}

ReadThresholdInteger(section, key, fallback) {
    value := IniRead("config.ini", section, key, "")
    return (value != "" && IsNumber(value))
        ? Number(value)
        : fallback
}

UpdateThresholdTarget() {
    global TargetWindowTitle
    TargetWindowTitle := Trim(EditTarget.Value)
}

UpdateThresholdPointControls() {
    global IsUpdatingControls
    global GoldBarThreshX, GoldBarThreshY
    global ElixirBarThreshX, ElixirBarThreshY
    global DarkElixirBarThreshX, DarkElixirBarThreshY
    IsUpdatingControls := true
    EditGoldX.Value := String(GoldBarThreshX)
    EditGoldY.Value := String(GoldBarThreshY)
    EditElixirX.Value := String(ElixirBarThreshX)
    EditElixirY.Value := String(ElixirBarThreshY)
    EditDarkX.Value := String(DarkElixirBarThreshX)
    EditDarkY.Value := String(DarkElixirBarThreshY)
    IsUpdatingControls := false
}

OnThresholdPointChanged() {
    global IsUpdatingControls, CoordinatesDirty
    global GoldBarThreshX, GoldBarThreshY
    global ElixirBarThreshX, ElixirBarThreshY
    global DarkElixirBarThreshX, DarkElixirBarThreshY
    if IsUpdatingControls
        return
    try {
        if (EditGoldX.Value != "")
            GoldBarThreshX := Number(EditGoldX.Value)
        if (EditGoldY.Value != "")
            GoldBarThreshY := Number(EditGoldY.Value)
        if (EditElixirX.Value != "")
            ElixirBarThreshX := Number(EditElixirX.Value)
        if (EditElixirY.Value != "")
            ElixirBarThreshY := Number(EditElixirY.Value)
        if (EditDarkX.Value != "")
            DarkElixirBarThreshX := Number(EditDarkX.Value)
        if (EditDarkY.Value != "")
            DarkElixirBarThreshY := Number(EditDarkY.Value)
        CoordinatesDirty := true
        SetTimer(() => RunInspectCycle(), -150)
    }
}

ReloadThresholdPoints() {
    global CoordinatesDirty, MappingIdentity
    CoordinatesDirty := false
    MappingIdentity := ""
    ReloadThresholdConfig(true)
    UpdateThresholdPointControls()
    ThresholdLog("Reloaded client points and ADB calibration from config.ini.")
    RunInspectCycle()
}

SaveThresholdConfig() {
    global CoordinatesDirty
    global GoldBarThreshX, GoldBarThreshY
    global ElixirBarThreshX, ElixirBarThreshY
    global DarkElixirBarThreshX, DarkElixirBarThreshY
    IniWrite(
        GoldBarThreshX,
        "config.ini",
        "Coordinates",
        "GoldBarThreshX"
    )
    IniWrite(
        GoldBarThreshY,
        "config.ini",
        "Coordinates",
        "GoldBarThreshY"
    )
    IniWrite(
        ElixirBarThreshX,
        "config.ini",
        "Coordinates",
        "ElixirBarThreshX"
    )
    IniWrite(
        ElixirBarThreshY,
        "config.ini",
        "Coordinates",
        "ElixirBarThreshY"
    )
    IniWrite(
        DarkElixirBarThreshX,
        "config.ini",
        "Coordinates",
        "DarkElixirBarThreshX"
    )
    IniWrite(
        DarkElixirBarThreshY,
        "config.ini",
        "Coordinates",
        "DarkElixirBarThreshY"
    )
    CoordinatesDirty := false
    ThresholdLog(
        "Saved client points: Gold (" GoldBarThreshX ", "
            GoldBarThreshY "), Elixir (" ElixirBarThreshX ", "
            ElixirBarThreshY "), Dark Elixir ("
            DarkElixirBarThreshX ", " DarkElixirBarThreshY ")."
    )
}

BeginThresholdCalibration() {
    global IsCalibrating, CalibrationStage
    IsCalibrating := true
    CalibrationStage := "gold"
    BtnCalibrate.Text := "Gold: HOVER + SPACE"
    ThresholdLog(
        "Calibration armed: hover over the Gold threshold point "
            "and press Space."
    )
}

CaptureThresholdCalibrationPoint() {
    global IsCalibrating, CalibrationStage, CoordinatesDirty
    global TargetWindowTitle
    global GoldBarThreshX, GoldBarThreshY
    global ElixirBarThreshX, ElixirBarThreshY
    global DarkElixirBarThreshX, DarkElixirBarThreshY
    if !IsCalibrating
        return
    hwnd := WinExist(TargetWindowTitle)
    if !hwnd {
        ThresholdLog("Calibration failed: emulator window was not found.")
        return
    }
    WinGetClientPos &clientScreenX, &clientScreenY,,, hwnd
    CoordMode "Mouse", "Screen"
    MouseGetPos &mouseX, &mouseY
    clientX := mouseX - clientScreenX
    clientY := mouseY - clientScreenY
    switch CalibrationStage {
        case "gold":
            GoldBarThreshX := clientX
            GoldBarThreshY := clientY
            CalibrationStage := "elixir"
            BtnCalibrate.Text := "Elixir: HOVER + SPACE"
            ThresholdLog(
                "Gold captured at client (" clientX ", " clientY "). "
                    "Now capture Elixir."
            )
        case "elixir":
            ElixirBarThreshX := clientX
            ElixirBarThreshY := clientY
            CalibrationStage := "dark"
            BtnCalibrate.Text := "Dark: HOVER + SPACE"
            ThresholdLog(
                "Elixir captured at client (" clientX ", " clientY "). "
                    "Now capture Dark Elixir."
            )
        case "dark":
            DarkElixirBarThreshX := clientX
            DarkElixirBarThreshY := clientY
            CalibrationStage := ""
            IsCalibrating := false
            BtnCalibrate.Text := "Calibrate (Space)"
            ThresholdLog(
                "Dark Elixir captured at client ("
                    clientX ", " clientY "). Calibration complete."
            )
    }
    CoordinatesDirty := true
    UpdateThresholdPointControls()
    if !IsCalibrating
        RunInspectCycle()
}

ThresholdLog(message) {
    timeText := FormatTime(, "HH:mm:ss")
    ConsoleEdit.Value .= "[" timeText "] " message "`n"
    SendMessage(0x0115, 7, 0, ConsoleEdit)
}

ClearThresholdConsole() {
    ConsoleEdit.Value := ""
}

ToggleLiveMonitoring() {
    global IsLiveMonitoring
    IsLiveMonitoring := !IsLiveMonitoring
    if IsLiveMonitoring {
        BtnLive.Text := "Stop Live Monitoring"
        SetTimer(RunInspectCycle, 1000)
        RunInspectCycle()
    } else {
        BtnLive.Text := "Start Live Monitoring"
        SetTimer(RunInspectCycle, 0)
    }
}

EnsureThresholdADBMapping() {
    global MappingIdentity, DisplayWidth, DisplayHeight
    global ViewportLeft, ViewportTop, ViewportRight, ViewportBottom
    global CalibratedClientWidth, CalibratedClientHeight
    global CalibratedProvider, CalibratedSerial
    if (CalibratedSerial == "")
        throw Error("ADBViewport.Serial is missing from config.ini.")
    if (ViewportRight <= ViewportLeft || ViewportBottom <= ViewportTop)
        throw Error("ADBViewport bounds in config.ini are invalid.")
    identity := (
        CalibratedClientWidth . "|" .
        CalibratedClientHeight . "|" .
        CalibratedProvider . "|" .
        CalibratedSerial . "|" .
        ViewportLeft . "|" .
        ViewportTop . "|" .
        ViewportRight . "|" .
        ViewportBottom
    )
    if (identity == MappingIdentity
        && DisplayWidth > 0
        && DisplayHeight > 0)
        return
    display := QueryThresholdADBDisplaySize(CalibratedSerial)
    DisplayWidth := display.width
    DisplayHeight := display.height
    ConfigureADBClientMapping(
        ViewportLeft,
        ViewportTop,
        ViewportRight,
        ViewportBottom,
        DisplayWidth,
        DisplayHeight,
        CalibratedClientWidth,
        CalibratedClientHeight,
        CalibratedProvider,
        CalibratedSerial
    )
    MappingIdentity := identity
    ThresholdLog(
        "Mapping loaded: client " CalibratedClientWidth "x"
            CalibratedClientHeight ", ADB " DisplayWidth "x"
            DisplayHeight ", serial " CalibratedSerial "."
    )
}

QueryThresholdADBDisplaySize(serial) {
    state := RunThresholdADBOutput('-s "' serial '" get-state')
    if !state.ok {
        connect := RunThresholdADBOutput('connect "' serial '"')
        if !connect.ok
            throw Error("ADB connection failed: " connect.output)
    }
    sizeResult := RunThresholdADBOutput(
        '-s "' serial '" shell wm size'
    )
    if !sizeResult.ok
        throw Error("Could not query ADB size: " sizeResult.output)
    if RegExMatch(
        sizeResult.output,
        "i)Override size:\s*(\d+)x(\d+)",
        &match
    )
        return {width: Number(match[1]), height: Number(match[2])}
    if RegExMatch(
        sizeResult.output,
        "i)Physical size:\s*(\d+)x(\d+)",
        &match
    )
        return {width: Number(match[1]), height: Number(match[2])}
    throw Error("Unrecognized ADB display size: " sizeResult.output)
}

ResolveThresholdADBPath() {
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

RunThresholdADBOutput(arguments) {
    adbPath := ResolveThresholdADBPath()
    outputPath := A_Temp "\coc_threshold_adb_output.txt"
    try FileDelete(outputPath)
    command := A_ComSpec ' /D /S /C ""' adbPath '" ' arguments ' > "' outputPath '" 2>&1"'
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    output := FileExist(outputPath)
        ? Trim(FileRead(outputPath), " `t`r`n")
        : ""
    try FileDelete(outputPath)
    return {ok: exitCode == 0, output: output, exitCode: exitCode}
}

CaptureThresholdADBFrame() {
    global CalibratedSerial, ThresholdFramePath
    adbPath := ResolveThresholdADBPath()
    try FileDelete(ThresholdFramePath)
    command := A_ComSpec ' /D /S /C ""' adbPath '" -s "' CalibratedSerial '" exec-out screencap -p > "' ThresholdFramePath '""'
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    if (exitCode != 0 || !FileExist(ThresholdFramePath))
        throw Error("Fresh ADB screenshot failed with exit " exitCode ".")
    if (FileGetSize(ThresholdFramePath) < 1024)
        throw Error("Fresh ADB screenshot is unexpectedly small.")
    return ThresholdFramePath
}

InitThresholdGDIPlus() {
    static token := 0
    if (token == 0) {
        startupInput := Buffer(24, 0)
        NumPut("uint", 1, startupInput, 0)
        DllCall(
            "gdiplus\GdiplusStartup",
            "ptr*",
            &token,
            "ptr",
            startupInput,
            "ptr",
            0
        )
    }
    return token
}

GetThresholdADBFrameNeighborhood(
    framePath,
    clientX,
    clientY,
    clientRadiusX := 24,
    clientRadiusY := 0,
    clientStep := 1
) {
    center := TranslateClientPointToADB(clientX, clientY)
    InitThresholdGDIPlus()
    pBitmap := 0
    if DllCall(
        "gdiplus\GdipCreateBitmapFromFile",
        "wstr",
        framePath,
        "ptr*",
        &pBitmap
    ) != 0
        throw Error("Fresh ADB frame could not be opened.")

    colors := []
    try {
        clientOffsetY := -clientRadiusY
        while (clientOffsetY <= clientRadiusY) {
            clientOffsetX := -clientRadiusX
            while (clientOffsetX <= clientRadiusX) {
                point := TranslateClientPointToADB(
                    clientX + clientOffsetX,
                    clientY + clientOffsetY
                )
                argb := 0
                status := DllCall(
                    "gdiplus\GdipBitmapGetPixel",
                    "ptr",
                    pBitmap,
                    "int",
                    point.x,
                    "int",
                    point.y,
                    "uint*",
                    &argb
                )
                if (status != 0)
                    throw Error(
                        "ADB neighborhood sample failed with status "
                            status "."
                    )
                colors.Push(argb & 0x00FFFFFF)
                clientOffsetX += clientStep
            }
            clientOffsetY += clientStep
        }
    } finally {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    }

    analysis := AnalyzeThresholdNeighborhood(colors)
    analysis.adbX := center.x
    analysis.adbY := center.y
    analysis.radiusX := clientRadiusX
    analysis.radiusY := clientRadiusY
    return analysis
}

SaveADBThresholdPreview(
    framePath,
    adbX,
    adbY,
    filepath,
    isPass
) {
    global DisplayWidth, DisplayHeight
    InitThresholdGDIPlus()
    cropX := Max(0, Min(DisplayWidth - 100, adbX - 50))
    cropY := Max(0, Min(DisplayHeight - 60, adbY - 30))
    cropW := Min(100, DisplayWidth - cropX)
    cropH := Min(60, DisplayHeight - cropY)
    pSource := 0
    if DllCall(
        "gdiplus\GdipCreateBitmapFromFile",
        "wstr",
        framePath,
        "ptr*",
        &pSource
    ) != 0
        throw Error("ADB preview frame could not be opened.")
    pCrop := 0
    status := DllCall(
        "gdiplus\GdipCloneBitmapArea",
        "float",
        Float(cropX),
        "float",
        Float(cropY),
        "float",
        Float(cropW),
        "float",
        Float(cropH),
        "int",
        0x26200A,
        "ptr",
        pSource,
        "ptr*",
        &pCrop
    )
    DllCall("gdiplus\GdipDisposeImage", "ptr", pSource)
    if (status != 0)
        throw Error("ADB preview crop failed with status " status ".")
    pGraphics := 0
    pPen := 0
    DllCall(
        "gdiplus\GdipGetImageGraphicsContext",
        "ptr",
        pCrop,
        "ptr*",
        &pGraphics
    )
    color := isPass ? 0xFF00FF00 : 0xFFFF0000
    DllCall(
        "gdiplus\GdipCreatePen1",
        "uint",
        color,
        "float",
        3.0,
        "int",
        2,
        "ptr*",
        &pPen
    )
    DllCall(
        "gdiplus\GdipDrawRectangle",
        "ptr",
        pGraphics,
        "ptr",
        pPen,
        "float",
        Float(adbX - cropX - 6),
        "float",
        Float(adbY - cropY - 6),
        "float",
        12.0,
        "float",
        12.0
    )
    DllCall("gdiplus\GdipDeletePen", "ptr", pPen)
    DllCall("gdiplus\GdipDeleteGraphics", "ptr", pGraphics)
    clsid := Buffer(16, 0)
    DllCall(
        "ole32\CLSIDFromString",
        "wstr",
        "{557CF406-1A04-11D3-9A73-0000F81EF32E}",
        "ptr",
        clsid
    )
    saveStatus := DllCall(
        "gdiplus\GdipSaveImageToFile",
        "ptr",
        pCrop,
        "wstr",
        filepath,
        "ptr",
        clsid,
        "ptr",
        0
    )
    DllCall("gdiplus\GdipDisposeImage", "ptr", pCrop)
    if (saveStatus != 0)
        throw Error("ADB preview save failed with status " saveStatus ".")
}

IsThresholdGoldFilled(r, g, b) {
    return r > 120
        && g > 100
        && r > b + 20
        && g > b + 10
}

IsThresholdElixirFilled(r, g, b) {
    isPink := r >= 180
        && g >= 80
        && g <= 220
        && b >= 100
        && b <= 230
        && r > g
        && r >= b * 0.75
        && (r + g + b) / 3 > 140
    return isPink || (r > 120 && b > 100 && r > g + 20)
}

IsThresholdDarkElixirFilled(r, g, b) {
    return r < 70 && g < 60 && b < 80
}

ColorChannels(color) {
    return {
        r: (color >> 16) & 0xFF,
        g: (color >> 8) & 0xFF,
        b: color & 0xFF
    }
}

RunInspectCycle() {
    global CoordinatesDirty
    global GoldBarThreshX, GoldBarThreshY
    global ElixirBarThreshX, ElixirBarThreshY
    global DarkElixirBarThreshX, DarkElixirBarThreshY
    global GoldPreviewPath, ElixirPreviewPath, DarkPreviewPath

    ReloadThresholdConfig(!CoordinatesDirty)
    if !CoordinatesDirty
        UpdateThresholdPointControls()
    try {
        EnsureThresholdADBMapping()
        StatusText.Text := "Status: Capturing fresh ADB frame"
        StatusText.Opt("cBlue")
        ThresholdLog(
            "=== NEW FRESH-ADB RESOURCE THRESHOLD CYCLE ==="
        )
        framePath := CaptureThresholdADBFrame()
        ThresholdLog(
            "ADB capture complete; all three points use this same frame."
        )

        goldSample := GetThresholdADBFrameNeighborhood(
            framePath,
            GoldBarThreshX,
            GoldBarThreshY
        )
        elixirSample := GetThresholdADBFrameNeighborhood(
            framePath,
            ElixirBarThreshX,
            ElixirBarThreshY
        )
        darkSample := GetThresholdADBFrameNeighborhood(
            framePath,
            DarkElixirBarThreshX,
            DarkElixirBarThreshY
        )
        goldRGB := ColorChannels(goldSample.color)
        elixirRGB := ColorChannels(elixirSample.color)
        darkRGB := ColorChannels(darkSample.color)
        goldFilled := goldSample.valid && IsThresholdGoldFilled(
            goldRGB.r,
            goldRGB.g,
            goldRGB.b
        )
        elixirFilled := elixirSample.valid && IsThresholdElixirFilled(
            elixirRGB.r,
            elixirRGB.g,
            elixirRGB.b
        )
        darkFilled := darkSample.valid && IsThresholdDarkElixirFilled(
            darkRGB.r,
            darkRGB.g,
            darkRGB.b
        )

        LogThresholdSample(
            "Gold",
            GoldBarThreshX,
            GoldBarThreshY,
            goldSample,
            goldRGB,
            goldFilled
        )
        LogThresholdSample(
            "Elixir",
            ElixirBarThreshX,
            ElixirBarThreshY,
            elixirSample,
            elixirRGB,
            elixirFilled
        )
        LogThresholdSample(
            "Dark Elixir",
            DarkElixirBarThreshX,
            DarkElixirBarThreshY,
            darkSample,
            darkRGB,
            darkFilled
        )
        ThresholdLog(
            "Dark Elixir rule: R < 70, G < 60, B < 80; "
                "observed R=" darkRGB.r ", G=" darkRGB.g
                ", B=" darkRGB.b "; ignored light pixels="
                darkSample.ignored "/" darkSample.total "."
        )

        SaveADBThresholdPreview(
            framePath,
            goldSample.adbX,
            goldSample.adbY,
            GoldPreviewPath,
            goldFilled
        )
        SaveADBThresholdPreview(
            framePath,
            elixirSample.adbX,
            elixirSample.adbY,
            ElixirPreviewPath,
            elixirFilled
        )
        SaveADBThresholdPreview(
            framePath,
            darkSample.adbX,
            darkSample.adbY,
            DarkPreviewPath,
            darkFilled
        )
        try PicGold.Value := GoldPreviewPath
        try PicElixir.Value := ElixirPreviewPath
        try PicDark.Value := DarkPreviewPath

        VerdictText.Text := Format(
            "G:{} | E:{} | DE:{}",
            goldFilled ? "FILLED" : "NO",
            elixirFilled ? "FILLED" : "NO",
            darkFilled ? "FILLED" : "NO"
        )
        VerdictText.Opt(
            (goldFilled && elixirFilled && darkFilled)
                ? "cGreen"
                : "cRed"
        )
        StatusText.Text := "Status: Complete"
        StatusText.Opt("cGreen")
        return {
            gold: goldFilled,
            elixir: elixirFilled,
            darkElixir: darkFilled,
            framePath: framePath
        }
    } catch as err {
        VerdictText.Text := "Verdict: ADB THRESHOLD TEST ERROR"
        VerdictText.Opt("cRed")
        StatusText.Text := "Status: Error"
        StatusText.Opt("cRed")
        ThresholdLog(FormatThresholdError(err))
        return false
    }
}

FormatThresholdError(err) {
    location := ""
    if HasProp(err, "File") && err.File != ""
        location := " at " err.File
    if HasProp(err, "Line") && err.Line
        location .= ":" err.Line

    details := "ERROR: " err.Message location
    if HasProp(err, "Stack") && err.Stack != ""
        details .= "`r`n" err.Stack
    return details
}

LogThresholdSample(
    label,
    clientX,
    clientY,
    sample,
    rgb,
    isFilled
) {
    ThresholdLog(
        Format(
            "{} client ({}, {}) -> ADB ({}, {}): "
                "median RGB=({}, {}, {}), hex=0x{:06X}, "
                "ignored-light={}/{}, evaluated={}, result={}.",
            label,
            clientX,
            clientY,
            sample.adbX,
            sample.adbY,
            rgb.r,
            rgb.g,
            rgb.b,
            sample.color,
            sample.ignored,
            sample.total,
            sample.evaluated,
            isFilled ? "FILLED" : "NO"
        )
    )
}

RunBuilderUpgradeInfoFlow() {
    global IsLiveMonitoring
    global BuilderFaceX, BuilderFaceY

    BtnBuilderFlow.Enabled := false
    if IsLiveMonitoring {
        IsLiveMonitoring := false
        SetTimer(RunInspectCycle, 0)
        BtnLive.Text := "Start Live Monitoring"
    }

    try {
        ThresholdLog("=== BUILDER UPGRADE-TO-INFO TEST START ===")
        ThresholdLog(
            "Safety boundary: this test has no confirmation coordinate "
                "and will stop immediately after tapping Info."
        )

        thresholds := RunInspectCycle()
        if !IsObject(thresholds)
            throw Error("Resource thresholds could not be evaluated.")
        if !(thresholds.gold && thresholds.elixir && thresholds.darkElixir) {
            ThresholdLog(
                "Builder-to-Info skipped: Gold, Elixir, and Dark Elixir "
                    "thresholds must all be FILLED."
            )
            SetBuilderInfoFlowVerdict(
                "SKIPPED: RESOURCE THRESHOLDS NOT MET",
                false
            )
            return false
        }

        ThresholdLog(
            "Builder availability: capturing a separate fresh ADB frame."
        )
        builderFrame := CaptureThresholdADBFrame()
        builders := ReadBuilderAvailabilityForInfoFlow(builderFrame)
        ThresholdLog(
            "Builder availability result: " builders.free "/"
                builders.total ", Goblin="
                (builders.goblin ? "YES" : "NO") "."
        )
        if (builders.free <= 0 || builders.goblin) {
            ThresholdLog(
                "Builder-to-Info skipped: no safe normal builder is free."
            )
            SetBuilderInfoFlowVerdict("SKIPPED: NO SAFE BUILDER", false)
            return false
        }

        ThresholdLog(
            "Builder menu: randomized ADB tap at calibrated client point ("
                BuilderFaceX ", " BuilderFaceY ")."
        )
        TapBuilderInfoFlowPoint(BuilderFaceX, BuilderFaceY, 200)
        Sleep 1200

        ThresholdLog(
            "Suggested upgrades: capturing one fresh ADB frame after menu "
                "settle."
        )
        suggestionFrame := CaptureThresholdADBFrame()
        suggestion := FindFirstSuggestedUpgradeForInfoFlow(suggestionFrame)
        if !IsObject(suggestion) {
            ThresholdLog(
                "Builder-to-Info skipped: OCR found no first suggestion."
            )
            ClearBuilderInfoFlowSelection()
            SetBuilderInfoFlowVerdict("SKIPPED: NO SUGGESTION", false)
            return false
        }
        ThresholdLog(
            "Suggested upgrades: OCR selected '" suggestion.text
                "' at client (" suggestion.clientX ", "
                suggestion.clientY ")."
        )
        suggestionTap := TapBuilderInfoFlowPoint(
            suggestion.clientX,
            suggestion.clientY,
            200
        )
        ShowSuggestionTapPreview(suggestion, suggestionTap)
        ThresholdLog(
            "Suggested upgrades: X-Bow click sent at randomized ADB ("
                suggestionTap.x ", " suggestionTap.y ")."
        )
        Sleep 2000

        ThresholdLog(
            "Info button: capturing one fresh ADB frame for the single OCR "
                "attempt."
        )
        infoFrame := CaptureThresholdADBFrame()
        info := FindBuilderInfoForInfoFlow(infoFrame)
        if !IsObject(info) {
            ThresholdLog(
                "Builder-to-Info skipped: one OCR attempt found no Info "
                    "button. Confirmation was not touched."
            )
            ClearBuilderInfoFlowSelection()
            SetBuilderInfoFlowVerdict("SKIPPED: INFO NOT FOUND", false)
            return false
        }

        ThresholdLog(
            "Info button: template matched '" info.text "' at client ("
                info.clientX ", " info.clientY "), confidence "
                Format("{:.4f}", info.confidence) "."
        )
        ThresholdLog(
            "Info button: randomized ADB tap at the template center."
        )
        TapBuilderInfoFlowPoint(info.clientX, info.clientY, 200)
        Sleep 1200

        SetBuilderInfoFlowVerdict("READY BEFORE CONFIRMATION", true)
        ThresholdLog(
            "READY BEFORE CONFIRMATION: Info was tapped successfully. "
                "The test is stopping now and will not press confirmation."
        )
        return true
    } catch as err {
        SetBuilderInfoFlowVerdict("BUILDER-TO-INFO TEST ERROR", false)
        ThresholdLog(FormatThresholdError(err))
        return false
    } finally {
        BtnBuilderFlow.Enabled := true
    }
}

SetBuilderInfoFlowVerdict(message, isPass) {
    VerdictText.Text := "Verdict: " message
    VerdictText.Opt(isPass ? "cGreen" : "cRed")
    StatusText.Text := isPass
        ? "Status: Waiting before confirmation"
        : "Status: Builder flow stopped"
    StatusText.Opt(isPass ? "cGreen" : "cRed")
}

ReadBuilderAvailabilityForInfoFlow(framePath) {
    global BuilderFaceX, BuilderFaceY
    global BuilderCountCropPath
    global ViewportTop, ViewportBottom
    global DisplayHeight

    viewportHeight := ViewportBottom - ViewportTop
    cropW := Max(100, Round(viewportHeight * 0.1362))
    cropH := Max(24, Round(viewportHeight * 0.0292))
    offsetX := Round(cropW * 0.22)
    offsetY := Round(cropH * 0.50)
    adbRect := TranslateClientRectToADB(
        BuilderFaceX - offsetX,
        BuilderFaceY - offsetY,
        cropW,
        cropH
    )
    SaveInfoFlowADBRegion(framePath, adbRect, BuilderCountCropPath)

    output := Trim(
        RunInfoFlowVisionHook(
            'builders "' BuilderCountCropPath '" ' DisplayHeight
        )
    )
    ThresholdLog("Builder specialized detector output: '" output "'.")
    if !RegExMatch(output, "SUCCESS:\s*(\d)/(\d)", &match)
        return {free: 0, total: 0, goblin: true}
    free := Integer(match[1])
    total := Integer(match[2])
    return {
        free: free,
        total: total,
        goblin: free > 0
            && IsGoblinBuilderInInfoFlowFrame(
                framePath,
                BuilderFaceX,
                BuilderFaceY
            )
    }
}

IsGoblinBuilderInInfoFlowFrame(framePath, clientX, clientY) {
    offsets := [
        [0, 0], [-7, 0], [7, 0], [0, -7], [0, 7],
        [-5, -5], [5, -5], [-5, 5], [5, 5], [0, -4]
    ]
    InitThresholdGDIPlus()
    pBitmap := 0
    if DllCall(
        "gdiplus\GdipCreateBitmapFromFile",
        "wstr",
        framePath,
        "ptr*",
        &pBitmap
    ) != 0
        return true
    greenCount := 0
    try {
        for offset in offsets {
            point := TranslateClientPointToADB(
                clientX + offset[1],
                clientY + offset[2]
            )
            argb := 0
            status := DllCall(
                "gdiplus\GdipBitmapGetPixel",
                "ptr",
                pBitmap,
                "int",
                point.x,
                "int",
                point.y,
                "uint*",
                &argb
            )
            if (status != 0)
                continue
            color := argb & 0x00FFFFFF
            r := (color >> 16) & 0xFF
            g := (color >> 8) & 0xFF
            b := color & 0xFF
            if (g > r && g > b + 15 && g >= 80)
                greenCount += 1
        }
    } finally {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    }
    return greenCount >= 4
}

FindFirstSuggestedUpgradeForInfoFlow(framePath) {
    global BuilderFaceX, BuilderFaceY, BuilderMenuBottomY
    global SuggestionCropPath, SuggestionPreviewPath
    global ViewportLeft, ViewportTop, ViewportRight

    viewportWidth := ViewportRight - ViewportLeft
    menuX := BuilderFaceX - viewportWidth * 0.20
    menuY := Max(ViewportTop, BuilderFaceY)
    menuW := viewportWidth * 0.42
    menuH := Max(1, BuilderMenuBottomY - menuY)
    adbRect := TranslateClientRectToADB(menuX, menuY, menuW, menuH)
    SaveInfoFlowADBRegion(framePath, adbRect, SuggestionCropPath)

    for scaleValue in [2.0, 2.5, 1.5, 3.0] {
        try {
            result := OCR.FromFile(
                SuggestionCropPath,
                {scale: scaleValue}
            )
            rawText := StrReplace(
                StrReplace(result.Text, "`r", "\r"),
                "`n",
                "\n"
            )
            ThresholdLog(
                "Suggestion OCR scale " scaleValue "x: raw='"
                    rawText "'."
            )
            selected := SelectFirstSuggestedUpgradeOCRWord(result.Lines)
            if !IsObject(selected)
                continue
            selected := NormalizeBuilderOCRMatch(selected, scaleValue)
            adbX := adbRect.x + selected.tapX
            adbY := adbRect.y + selected.tapY
            clientPoint := TranslateADBPointToClient(adbX, adbY)
            SaveInfoFlowPreview(
                SuggestionCropPath,
                SuggestionPreviewPath,
                selected
            )
            try PicSuggestion.Value := SuggestionPreviewPath
            ThresholdLog(
                "Suggestion OCR normalized bounds: local ("
                    Round(selected.x) ", " Round(selected.y) ", "
                    Round(selected.w) ", " Round(selected.h)
                    "), original line-offset ADB tap ("
                    Round(adbX) ", " Round(adbY)
                    "), client center (" clientPoint.x ", "
                    clientPoint.y ")."
            )
            return {
                text: selected.text,
                lineText: selected.lineText,
                clientX: clientPoint.x,
                clientY: clientPoint.y,
                scale: scaleValue,
                bounds: selected,
                cropADBX: adbRect.x,
                cropADBY: adbRect.y
            }
        } catch as err {
            ThresholdLog(
                "Suggestion OCR scale " scaleValue "x error: "
                    err.Message
            )
        }
    }
    return ""
}

ShowSuggestionTapPreview(suggestion, adbTapPoint) {
    global SuggestionCropPath, SuggestionPreviewPath
    marker := {
        x: adbTapPoint.x - suggestion.cropADBX,
        y: adbTapPoint.y - suggestion.cropADBY,
        w: 1,
        h: 1
    }
    SaveInfoFlowPreview(
        SuggestionCropPath,
        SuggestionPreviewPath,
        marker
    )
    try PicSuggestion.Value := SuggestionPreviewPath
    ThresholdLog(
        "Suggested upgrades: visual marker placed at crop-local ADB ("
            Round(marker.x) ", " Round(marker.y) ")."
    )
}

FindBuilderInfoForInfoFlow(framePath) {
    global ViewportLeft, ViewportTop, ViewportRight, ViewportBottom
    global InfoCropPath, InfoPreviewPath
    global DisplayHeight

    viewportWidth := ViewportRight - ViewportLeft
    viewportHeight := ViewportBottom - ViewportTop
    clientCropX := ViewportLeft + Round(viewportWidth * 0.15)
    clientCropY := ViewportTop + Round(viewportHeight * 0.65)
    clientCropW := Round(viewportWidth * 0.70)
    clientCropH := Round(viewportHeight * 0.30)
    adbRect := TranslateClientRectToADB(
        clientCropX,
        clientCropY,
        clientCropW,
        clientCropH
    )
    SaveInfoFlowADBRegion(framePath, adbRect, InfoCropPath)

    output := Trim(
        RunInfoFlowVisionHook(
            'info "' InfoCropPath '" ' DisplayHeight
        )
    )
    ThresholdLog("Info template detector output: '" output "'.")
    selected := ""
    if RegExMatch(
        output,
        "SUCCESS:\s*(\d+)/(\d+)/([\d.]+)/(\d+)/(\d+)/(\d+)/(\d+)",
        &match
    ) {
        selected := {
            centerX: Integer(match[1]),
            centerY: Integer(match[2]),
            confidence: Number(match[3]),
            x: Integer(match[4]),
            y: Integer(match[5]),
            w: Integer(match[6]),
            h: Integer(match[7])
        }
    }

    SaveInfoFlowPreview(
        InfoCropPath,
        InfoPreviewPath,
        selected
    )
    try PicInfoFlow.Value := InfoPreviewPath
    if !IsObject(selected)
        return ""

    adbX := adbRect.x + selected.centerX
    adbY := adbRect.y + selected.centerY
    clientPoint := TranslateADBPointToClient(adbX, adbY)
    ThresholdLog(
        "Info template match: confidence "
            Format("{:.4f}", selected.confidence) ", local bounds ("
            selected.x ", " selected.y ", " selected.w ", "
            selected.h "), ADB center ("
            Round(adbX) ", " Round(adbY) "), client center ("
            clientPoint.x ", " clientPoint.y ")."
    )
    return {
        text: "Info icon",
        clientX: clientPoint.x,
        clientY: clientPoint.y,
        confidence: selected.confidence,
        bounds: selected
    }
}

TapBuilderInfoFlowPoint(clientX, clientY, intendedDelayMs := 200) {
    global CalibratedSerial
    timing := GetADBActionTiming(intendedDelayMs)
    if (timing.PreDelay > 0)
        Sleep timing.PreDelay
    interaction := CreateADBClientInteraction(
        CalibratedSerial,
        InfoFlowCommandSink,
        InfoFlowDelaySink,
        InfoFlowRandomSink
    )
    return interaction.Tap(clientX, clientY, intendedDelayMs)
}

ClearBuilderInfoFlowSelection() {
    global CalibratedSerial, ClearTapX, ClearTapY
    if (ClearTapX <= 0 || ClearTapY <= 0) {
        ThresholdLog(
            "Clear selection skipped: VisualTests ClearTap point is absent."
        )
        return false
    }
    interaction := CreateADBClientInteraction(
        CalibratedSerial,
        InfoFlowCommandSink,
        InfoFlowDelaySink,
        InfoFlowRandomSink
    )
    interaction.ClearTap(
        ClearTapX,
        ClearTapY,
        200,
        InfoFlowPreDelaySink
    )
    ThresholdLog("Selection cleared with 3 randomized ADB taps.")
    return true
}

RunInfoFlowVisionHook(arguments) {
    outputPath := A_Temp "\coc_builder_info_vision_output.txt"
    try FileDelete(outputPath)
    command := (
        'cmd.exe /D /S /C python "' .
        A_ScriptDir .
        '\vision_hook.py" ' .
        arguments .
        ' > "' .
        outputPath .
        '" 2>&1'
    )
    shell := ComObject("WScript.Shell")
    exitCode := shell.Run(command, 0, true)
    output := FileExist(outputPath)
        ? FileRead(outputPath)
        : ""
    try FileDelete(outputPath)
    if (exitCode != 0)
        throw Error(
            "Specialized builder detector failed with exit " exitCode
                ": " Trim(output)
        )
    return output
}

InfoFlowCommandSink(arguments) {
    adbPath := ResolveThresholdADBPath()
    command := '"' adbPath '" ' arguments
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    if (exitCode != 0)
        throw Error("ADB interaction failed with exit " exitCode ".")
}

InfoFlowDelaySink(milliseconds) {
    if (milliseconds > 0)
        Sleep milliseconds
}

InfoFlowPreDelaySink(intendedDelayMs) {
    timing := GetADBActionTiming(intendedDelayMs)
    if (timing.PreDelay > 0)
        Sleep timing.PreDelay
}

InfoFlowRandomSink(minimum, maximum) {
    return Random(minimum, maximum)
}

SaveInfoFlowADBRegion(framePath, adbRect, filepath) {
    InitThresholdGDIPlus()
    pSource := 0
    if DllCall(
        "gdiplus\GdipCreateBitmapFromFile",
        "wstr",
        framePath,
        "ptr*",
        &pSource
    ) != 0
        throw Error("Fresh ADB frame could not be opened for OCR crop.")
    pCrop := 0
    status := DllCall(
        "gdiplus\GdipCloneBitmapArea",
        "float",
        Float(adbRect.x),
        "float",
        Float(adbRect.y),
        "float",
        Float(adbRect.width),
        "float",
        Float(adbRect.height),
        "int",
        0x26200A,
        "ptr",
        pSource,
        "ptr*",
        &pCrop
    )
    DllCall("gdiplus\GdipDisposeImage", "ptr", pSource)
    if (status != 0)
        throw Error("ADB OCR crop failed with GDI+ status " status ".")
    SaveInfoFlowBitmapPNG(pCrop, filepath)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pCrop)
}

SaveInfoFlowPreview(cropPath, filepath, match) {
    InitThresholdGDIPlus()
    pBitmap := 0
    if DllCall(
        "gdiplus\GdipCreateBitmapFromFile",
        "wstr",
        cropPath,
        "ptr*",
        &pBitmap
    ) != 0
        throw Error("Info crop could not be opened for preview.")
    width := 0
    height := 0
    DllCall(
        "gdiplus\GdipGetImageWidth",
        "ptr",
        pBitmap,
        "uint*",
        &width
    )
    DllCall(
        "gdiplus\GdipGetImageHeight",
        "ptr",
        pBitmap,
        "uint*",
        &height
    )
    pGraphics := 0
    pPen := 0
    DllCall(
        "gdiplus\GdipGetImageGraphicsContext",
        "ptr",
        pBitmap,
        "ptr*",
        &pGraphics
    )
    color := IsObject(match) ? 0xFF00FF00 : 0xFFFF0000
    DllCall(
        "gdiplus\GdipCreatePen1",
        "uint",
        color,
        "float",
        4.0,
        "int",
        2,
        "ptr*",
        &pPen
    )
    if IsObject(match) {
        markerX := match.x - 4
        markerY := match.y - 4
        markerW := match.w + 8
        markerH := match.h + 8
    } else {
        markerX := 2
        markerY := 2
        markerW := Max(1, width - 5)
        markerH := Max(1, height - 5)
    }
    DllCall(
        "gdiplus\GdipDrawRectangle",
        "ptr",
        pGraphics,
        "ptr",
        pPen,
        "float",
        Float(markerX),
        "float",
        Float(markerY),
        "float",
        Float(markerW),
        "float",
        Float(markerH)
    )
    DllCall("gdiplus\GdipDeletePen", "ptr", pPen)
    DllCall("gdiplus\GdipDeleteGraphics", "ptr", pGraphics)
    SaveInfoFlowBitmapPNG(pBitmap, filepath)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
}

SaveInfoFlowBitmapPNG(pBitmap, filepath) {
    clsid := Buffer(16, 0)
    DllCall(
        "ole32\CLSIDFromString",
        "wstr",
        "{557CF406-1A04-11D3-9A73-0000F81EF32E}",
        "ptr",
        clsid
    )
    status := DllCall(
        "gdiplus\GdipSaveImageToFile",
        "ptr",
        pBitmap,
        "wstr",
        filepath,
        "ptr",
        clsid,
        "ptr",
        0
    )
    if (status != 0)
        throw Error("Info preview PNG save failed with status " status ".")
}

F1:: RunInspectCycle()
F2:: RunBuilderUpgradeInfoFlow()

#HotIf IsCalibrating
Space:: CaptureThresholdCalibrationPoint()
#HotIf
