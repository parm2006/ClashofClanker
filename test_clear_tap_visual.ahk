#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ADBcocbotrefactor_support.ahk

SetTitleMatchMode 2
CoordMode "Mouse", "Screen"

global TargetWindowTitle := "Emulator"
global ViewportLeft := 0
global ViewportTop := 0
global ViewportRight := 1
global ViewportBottom := 1
global CalibratedClientWidth := 0
global CalibratedClientHeight := 0
global CalibratedProvider := ""
global CalibratedSerial := ""
global DisplayWidth := 0
global DisplayHeight := 0
global ClearTapX := 0
global ClearTapY := 0
global UseBotFraction := true
global IsCalibrating := false
global IsUpdatingControls := false
global MappingIdentity := ""
global TapCommandIndex := 0
global LastTapADBPoints := []
global LastStatusMessage := ""
global LocalPreviewWidth := 340
global LocalPreviewHeight := 180
global OverviewPath := A_Temp "\coc_clear_tap_overview.png"
global LocalPreviewPath := A_Temp "\coc_clear_tap_local.png"

ReloadInspectorConfig(true)
DeriveBotClearTapPoint()

ClearTapGui := Gui("+Resize", "Clash of Clanker - Clear Tap Visual Inspector")
ClearTapGui.SetFont("s10", "Segoe UI")

ClearTapGui.Add("Text", "x15 y14 w90 h24", "Target:")
EditTarget := ClearTapGui.Add(
    "Edit",
    "x105 y10 w225 h26",
    TargetWindowTitle
)
ChkTop := ClearTapGui.Add(
    "Checkbox",
    "x345 y14 w120 h24",
    "Always On Top"
)
StatusText := ClearTapGui.Add(
    "Text",
    "x475 y14 w270 h24 Right cGray",
    "Status: Initializing"
)

ClearTapGui.Add(
    "GroupBox",
    "x15 y42 w730 h78",
    "Client-coordinate tap target and live preview box"
)
ClearTapGui.Add("Text", "x25 y70 w70 h22", "Client X:")
EditTapX := ClearTapGui.Add(
    "Edit",
    "x92 y66 w75 h26 Number",
    "" ClearTapX
)
ClearTapGui.Add("UpDown", "Range0-3840", ClearTapX)
ClearTapGui.Add("Text", "x180 y70 w70 h22", "Client Y:")
EditTapY := ClearTapGui.Add(
    "Edit",
    "x247 y66 w75 h26 Number",
    "" ClearTapY
)
ClearTapGui.Add("UpDown", "Range0-2160", ClearTapY)
ChkUseBotPoint := ClearTapGui.Add(
    "Checkbox",
    "x340 y68 w205 h24 Checked",
    "Use bot point (95.2%, 38.3%)"
)
BtnCalibrate := ClearTapGui.Add(
    "Button",
    "x555 y64 w105 h30",
    "Calibrate (Space)"
)
BtnSave := ClearTapGui.Add(
    "Button",
    "x665 y64 w70 h30",
    "Save Config"
)
CoordinateText := ClearTapGui.Add(
    "Text",
    "x25 y96 w700 h20 cBlue",
    "Client: --, --  |  ADB: --, --"
)

BtnInspect := ClearTapGui.Add(
    "Button",
    "x15 y128 w130 h34",
    "Refresh View (F1)"
)
BtnSend := ClearTapGui.Add(
    "Button",
    "x155 y128 w190 h34",
    "SEND 3 CLEAR TAPS (F2)"
)
BtnClear := ClearTapGui.Add(
    "Button",
    "x355 y128 w110 h34",
    "Clear Console"
)
BtnReload := ClearTapGui.Add(
    "Button",
    "x475 y128 w150 h34",
    "Reload Mapping"
)

ClearTapGui.Add(
    "GroupBox",
    "x15 y170 w730 h74",
    "Live verdict"
)
ClearTapGui.SetFont("s16 Bold", "Segoe UI")
VerdictText := ClearTapGui.Add(
    "Text",
    "x30 y195 w700 h38 cBlue",
    "Verdict: CHECKING MAPPING"
)
ClearTapGui.SetFont("s10 Norm", "Segoe UI")

ClearTapGui.Add(
    "GroupBox",
    "x15 y250 w730 h275",
    "Desktop capture: complete emulator client (green rectangle = Android viewport)"
)
PicOverview := ClearTapGui.Add(
    "Picture",
    "x25 y275 w710 h240 +Border",
    ""
)

ClearTapGui.Add(
    "GroupBox",
    "x15 y535 w355 h220",
    "Desktop capture: clear-tap neighborhood"
)
PicLocal := ClearTapGui.Add(
    "Picture",
    "x25 y560 w335 h185 +Border",
    ""
)

ClearTapGui.Add(
    "GroupBox",
    "x380 y535 w365 h220",
    "Tap commands, timing, and coordinate translation"
)
ClearTapGui.SetFont("s9", "Consolas")
ConsoleEdit := ClearTapGui.Add(
    "Edit",
    "x390 y560 w345 h185 ReadOnly +VScroll +HScroll",
    ""
)
ClearTapGui.SetFont("s10", "Segoe UI")

EditTarget.OnEvent("Change", (*) => UpdateTargetTitle())
ChkTop.OnEvent(
    "Click",
    (*) => ClearTapGui.Opt((ChkTop.Value ? "+" : "-") "AlwaysOnTop")
)
EditTapX.OnEvent("Change", (*) => OnTapPointChanged())
EditTapY.OnEvent("Change", (*) => OnTapPointChanged())
ChkUseBotPoint.OnEvent("Click", (*) => OnBotPointModeChanged())
BtnCalibrate.OnEvent("Click", (*) => BeginCalibration())
BtnSave.OnEvent("Click", (*) => SaveInspectorConfig())
BtnInspect.OnEvent("Click", (*) => RunInspectCycle(true))
BtnSend.OnEvent("Click", (*) => SendThreeClearTaps())
BtnClear.OnEvent("Click", (*) => ClearConsole())
BtnReload.OnEvent("Click", (*) => ReloadMapping())
ClearTapGui.OnEvent("Close", (*) => ExitApp())

ClearTapGui.Show("w760 h770")
LogToConsole("--- Clear Tap Visual Inspector initialized ---")
LogToConsole(
    "Phase 1 preview source: Windows desktop capture. "
        "Tap execution source: translated ADB input."
)
LogToConsole(
    "The SEND button is the only control that transmits taps. "
        "F1 and live previews are read-only."
)
SetTimer(RefreshLivePreview, 500)
SetTimer(() => RunInspectCycle(true), -100)

ReloadInspectorConfig(forcePoint := false) {
    global TargetWindowTitle
    global ViewportLeft, ViewportTop, ViewportRight, ViewportBottom
    global CalibratedClientWidth, CalibratedClientHeight
    global CalibratedProvider, CalibratedSerial
    global ClearTapX, ClearTapY, UseBotFraction

    if !FileExist("config.ini")
        return
    TargetWindowTitle := IniRead(
        "config.ini",
        "Settings",
        "TargetWindowTitle",
        TargetWindowTitle
    )
    ViewportLeft := ReadInspectorInteger(
        "ADBViewport",
        "Left",
        ViewportLeft
    )
    ViewportTop := ReadInspectorInteger(
        "ADBViewport",
        "Top",
        ViewportTop
    )
    ViewportRight := ReadInspectorInteger(
        "ADBViewport",
        "Right",
        ViewportRight
    )
    ViewportBottom := ReadInspectorInteger(
        "ADBViewport",
        "Bottom",
        ViewportBottom
    )
    CalibratedClientWidth := ReadInspectorInteger(
        "ADBViewport",
        "ClientWidth",
        CalibratedClientWidth
    )
    CalibratedClientHeight := ReadInspectorInteger(
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
    if forcePoint {
        ClearTapX := ReadInspectorInteger(
            "VisualTests",
            "ClearTapX",
            ClearTapX
        )
        ClearTapY := ReadInspectorInteger(
            "VisualTests",
            "ClearTapY",
            ClearTapY
        )
        UseBotFraction := ReadInspectorInteger(
            "VisualTests",
            "ClearTapUseBotFraction",
            1
        ) != 0
    }
}

ReadInspectorInteger(section, key, fallback) {
    value := IniRead("config.ini", section, key, "")
    if (value == "" || !IsNumber(value))
        return fallback
    return Integer(value)
}

DeriveBotClearTapPoint() {
    global ViewportLeft, ViewportTop, ViewportRight, ViewportBottom
    global ClearTapX, ClearTapY
    ClearTapX := Round(
        ViewportLeft + (ViewportRight - ViewportLeft - 1) * 0.9522
    )
    ClearTapY := Round(
        ViewportTop + (ViewportBottom - ViewportTop - 1) * 0.383
    )
}

UpdateTargetTitle() {
    global TargetWindowTitle
    TargetWindowTitle := Trim(EditTarget.Value)
    RunInspectCycle(true)
}

OnTapPointChanged() {
    global IsUpdatingControls, ClearTapX, ClearTapY, UseBotFraction
    if IsUpdatingControls
        return
    if (EditTapX.Value == "" || EditTapY.Value == "")
        return
    try {
        ClearTapX := Integer(EditTapX.Value)
        ClearTapY := Integer(EditTapY.Value)
        UseBotFraction := false
        ChkUseBotPoint.Value := 0
        SetTimer(() => RunInspectCycle(true), -150)
    }
}

OnBotPointModeChanged() {
    global UseBotFraction
    UseBotFraction := ChkUseBotPoint.Value != 0
    if UseBotFraction
        DeriveBotClearTapPoint()
    UpdatePointControls()
    RunInspectCycle(true)
}

UpdatePointControls() {
    global IsUpdatingControls, ClearTapX, ClearTapY, UseBotFraction
    IsUpdatingControls := true
    EditTapX.Value := "" ClearTapX
    EditTapY.Value := "" ClearTapY
    ChkUseBotPoint.Value := UseBotFraction ? 1 : 0
    IsUpdatingControls := false
}

BeginCalibration() {
    global IsCalibrating
    IsCalibrating := true
    BtnCalibrate.Text := "HOVER + SPACE"
    LogToConsole(
        "Calibration armed: hover over the desired clear point inside "
            "the emulator and press Space."
    )
}

CaptureCalibrationPoint() {
    global IsCalibrating, ClearTapX, ClearTapY, UseBotFraction
    if !IsCalibrating
        return
    hwnd := WinExist(TargetWindowTitle)
    if !hwnd {
        LogToConsole("Calibration failed: emulator window was not found.")
        return
    }
    WinGetClientPos &clientScreenX, &clientScreenY,,, hwnd
    MouseGetPos &mouseX, &mouseY
    ClearTapX := mouseX - clientScreenX
    ClearTapY := mouseY - clientScreenY
    UseBotFraction := false
    IsCalibrating := false
    BtnCalibrate.Text := "Calibrate (Space)"
    UpdatePointControls()
    LogToConsole(
        "Calibration captured client point ("
            ClearTapX ", " ClearTapY ")."
    )
    RunInspectCycle(true)
}

SaveInspectorConfig() {
    global ClearTapX, ClearTapY, UseBotFraction
    IniWrite(ClearTapX, "config.ini", "VisualTests", "ClearTapX")
    IniWrite(ClearTapY, "config.ini", "VisualTests", "ClearTapY")
    IniWrite(
        UseBotFraction ? 1 : 0,
        "config.ini",
        "VisualTests",
        "ClearTapUseBotFraction"
    )
    LogToConsole(
        "Saved visual-test clear point: client ("
            ClearTapX ", " ClearTapY "), useBotFraction="
            (UseBotFraction ? "YES" : "NO") "."
    )
}

ReloadMapping() {
    global MappingIdentity, DisplayWidth, DisplayHeight
    MappingIdentity := ""
    DisplayWidth := 0
    DisplayHeight := 0
    ReloadInspectorConfig(true)
    if UseBotFraction
        DeriveBotClearTapPoint()
    UpdatePointControls()
    RunInspectCycle(true)
}

RefreshLivePreview() {
    RunInspectCycle(false)
}

RunInspectCycle(logDetails := false) {
    global TargetWindowTitle, UseBotFraction
    global ClearTapX, ClearTapY
    global ViewportLeft, ViewportTop, ViewportRight, ViewportBottom
    global LocalPreviewWidth, LocalPreviewHeight
    global OverviewPath, LocalPreviewPath

    ReloadInspectorConfig()
    if UseBotFraction
        DeriveBotClearTapPoint()
    UpdatePointControls()

    hwnd := WinExist(TargetWindowTitle)
    if !hwnd {
        SetInspectorFailure("Emulator window not found: " TargetWindowTitle)
        return false
    }
    WinGetClientPos(
        &clientScreenX,
        &clientScreenY,
        &clientWidth,
        &clientHeight,
        hwnd
    )
    try {
        EnsureInspectorMapping(clientWidth, clientHeight)
        adbPoint := TranslateClientPointToADB(ClearTapX, ClearTapY)
        insideViewport := ClearTapX >= ViewportLeft
            && ClearTapX <= ViewportRight
            && ClearTapY >= ViewportTop
            && ClearTapY <= ViewportBottom
        if !insideViewport
            throw Error("Clear point is outside the calibrated Android viewport.")

        localScreenX := Max(
            0,
            clientScreenX + ClearTapX - LocalPreviewWidth // 2
        )
        localScreenY := Max(
            0,
            clientScreenY + ClearTapY - LocalPreviewHeight // 2
        )
        localClientX := localScreenX - clientScreenX
        localClientY := localScreenY - clientScreenY
        localADBRect := TranslateClientRectToADB(
            localClientX,
            localClientY,
            LocalPreviewWidth,
            LocalPreviewHeight
        )
        overviewMarkers := BuildPreviewMarkers(
            ClearTapX,
            ClearTapY,
            0,
            0,
            true
        )
        localMarkers := BuildPreviewMarkers(
            ClearTapX,
            ClearTapY,
            localClientX,
            localClientY,
            true
        )
        SaveDesktopRegionWithMarkers(
            clientScreenX,
            clientScreenY,
            clientWidth,
            clientHeight,
            OverviewPath,
            overviewMarkers,
            [{
                relX: ViewportLeft,
                relY: ViewportTop,
                width: ViewportRight - ViewportLeft,
                height: ViewportBottom - ViewportTop,
                isPass: true
            }]
        )
        SaveDesktopRegionWithMarkers(
            localScreenX,
            localScreenY,
            LocalPreviewWidth,
            LocalPreviewHeight,
            LocalPreviewPath,
            localMarkers,
            []
        )
        PicOverview.Value := OverviewPath
        PicLocal.Value := LocalPreviewPath
        CoordinateText.Text := Format(
            "Client point: ({}, {})  ->  ADB point: ({}, {})  |  "
                "Scale X={:.4f}, Y={:.4f}",
            ClearTapX,
            ClearTapY,
            adbPoint.x,
            adbPoint.y,
            ADBScaleX,
            ADBScaleY
        )
        VerdictText.Text := "Verdict: MAPPING VALID - READY TO TEST"
        VerdictText.Opt("cGreen")
        StatusText.Text := "Status: Live desktop preview"
        StatusText.Opt("cGreen")
        if logDetails {
            LogToConsole("=== CLEAR TAP INSPECTION ===")
            LogToConsole(
                Format(
                    "Window client: {}x{} at screen ({}, {})",
                    clientWidth,
                    clientHeight,
                    clientScreenX,
                    clientScreenY
                )
            )
            LogToConsole(
                Format(
                    "Android viewport client box: ({}, {})-({}, {})",
                    ViewportLeft,
                    ViewportTop,
                    ViewportRight,
                    ViewportBottom
                )
            )
            LogToConsole(
                Format(
                    "Clear point client ({}, {}) -> ADB ({}, {})",
                    ClearTapX,
                    ClearTapY,
                    adbPoint.x,
                    adbPoint.y
                )
            )
            LogToConsole(
                Format(
                    "Local preview client box ({}, {}, {}, {}) "
                        "-> ADB box ({}, {}, {}, {})",
                    localClientX,
                    localClientY,
                    LocalPreviewWidth,
                    LocalPreviewHeight,
                    localADBRect.x,
                    localADBRect.y,
                    localADBRect.width,
                    localADBRect.height
                )
            )
        }
        return true
    } catch as err {
        SetInspectorFailure(err.Message)
        return false
    }
}

BuildPreviewMarkers(pointClientX, pointClientY, cropClientX, cropClientY, isPass) {
    global LastTapADBPoints
    markers := [{
        relX: pointClientX - cropClientX,
        relY: pointClientY - cropClientY,
        isPass: isPass
    }]
    for adbPoint in LastTapADBPoints {
        try {
            clientPoint := TranslateADBPointToClient(adbPoint.x, adbPoint.y)
            markers.Push({
                relX: clientPoint.x - cropClientX,
                relY: clientPoint.y - cropClientY,
                isPass: true
            })
        }
    }
    return markers
}

SetInspectorFailure(message) {
    global LastStatusMessage
    VerdictText.Text := "Verdict: NOT READY - " message
    VerdictText.Opt("cRed")
    StatusText.Text := "Status: Mapping error"
    StatusText.Opt("cRed")
    if (message != LastStatusMessage) {
        LogToConsole("NOT READY: " message)
        LastStatusMessage := message
    }
}

EnsureInspectorMapping(clientWidth, clientHeight) {
    global MappingIdentity, DisplayWidth, DisplayHeight
    global ViewportLeft, ViewportTop, ViewportRight, ViewportBottom
    global CalibratedClientWidth, CalibratedClientHeight
    global CalibratedProvider, CalibratedSerial

    if (CalibratedSerial == "")
        throw Error("ADBViewport.Serial is missing from config.ini.")
    if (clientWidth != CalibratedClientWidth
        || clientHeight != CalibratedClientHeight) {
        throw Error(
            "Current client size " clientWidth "x" clientHeight
                " does not match calibrated size "
                CalibratedClientWidth "x" CalibratedClientHeight "."
        )
    }
    identity := clientWidth "|" clientHeight "|" CalibratedProvider "|" CalibratedSerial "|" ViewportLeft "|" ViewportTop "|" ViewportRight "|" ViewportBottom
    if (identity == MappingIdentity
        && DisplayWidth > 0
        && DisplayHeight > 0) {
        return
    }
    display := QueryADBDisplaySize(CalibratedSerial)
    DisplayWidth := display.width
    DisplayHeight := display.height
    ConfigureADBClientMapping(
        ViewportLeft,
        ViewportTop,
        ViewportRight,
        ViewportBottom,
        DisplayWidth,
        DisplayHeight,
        clientWidth,
        clientHeight,
        CalibratedProvider,
        CalibratedSerial
    )
    MappingIdentity := identity
    LogToConsole(
        Format(
            "Mapping loaded: client {}x{}, viewport ({}, {})-({}, {}), "
                "ADB {}x{}, serial {}.",
            clientWidth,
            clientHeight,
            ViewportLeft,
            ViewportTop,
            ViewportRight,
            ViewportBottom,
            DisplayWidth,
            DisplayHeight,
            CalibratedSerial
        )
    )
}

QueryADBDisplaySize(serial) {
    state := RunInspectorADBOutput(
        '-s "' serial '" get-state'
    )
    if !state.ok {
        connect := RunInspectorADBOutput('connect "' serial '"')
        if !connect.ok
            throw Error("ADB connection failed: " connect.output)
    }
    sizeResult := RunInspectorADBOutput(
        '-s "' serial '" shell wm size'
    )
    if !sizeResult.ok
        throw Error("Could not query ADB display size: " sizeResult.output)
    if RegExMatch(
        sizeResult.output,
        "i)Override size:\s*(\d+)x(\d+)",
        &match
    ) {
        return {width: Integer(match[1]), height: Integer(match[2])}
    }
    if RegExMatch(
        sizeResult.output,
        "i)Physical size:\s*(\d+)x(\d+)",
        &match
    ) {
        return {width: Integer(match[1]), height: Integer(match[2])}
    }
    throw Error("Unrecognized ADB display size: " sizeResult.output)
}

ResolveInspectorADBPath() {
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

RunInspectorADBOutput(arguments) {
    adbPath := ResolveInspectorADBPath()
    outputPath := A_Temp "\coc_clear_tap_adb_output.txt"
    try FileDelete(outputPath)
    command := A_ComSpec ' /D /S /C ""' adbPath '" ' arguments ' > "' outputPath '" 2>&1"'
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    output := FileExist(outputPath)
        ? Trim(FileRead(outputPath), " `t`r`n")
        : ""
    try FileDelete(outputPath)
    return {ok: exitCode == 0, output: output, exitCode: exitCode}
}

SendThreeClearTaps() {
    global CalibratedSerial, ClearTapX, ClearTapY
    global TapCommandIndex, LastTapADBPoints

    if !RunInspectCycle(true) {
        LogToConsole("Tap test cancelled because the mapping is not ready.")
        return
    }
    TapCommandIndex := 0
    LastTapADBPoints := []
    LogToConsole("=== SENDING THREE CLEAR TAPS ===")
    LogToConsole(
        "Target timing: 200 ms each -> 185 ms pre-delay + "
            "uniform random 0..30 ms internal delay."
    )
    LogToConsole(
        "Each translated ADB coordinate receives an independent "
            "uniform random offset from -7..+8 on X and Y."
    )
    try {
        interaction := CreateADBClientInteraction(
            CalibratedSerial,
            RunInspectorADBCommand,
            InspectorJitterDelay,
            InspectorRandomInt
        )
        interaction.ClearTap(
            ClearTapX,
            ClearTapY,
            200,
            InspectorPreDelay
        )
        LogToConsole("SUCCESS: all 3 clear-tap commands completed.")
        VerdictText.Text := "Verdict: 3 CLEAR TAPS SENT SUCCESSFULLY"
        VerdictText.Opt("cGreen")
        RunInspectCycle(false)
    } catch as err {
        LogToConsole("FAILED: " err.Message)
        VerdictText.Text := "Verdict: CLEAR TAP FAILED"
        VerdictText.Opt("cRed")
    }
}

InspectorPreDelay(intendedDelayMs) {
    timing := GetADBActionTiming(intendedDelayMs)
    LogToConsole(
        "Pre-delay: " timing.PreDelay
            " ms before the next abstracted tap."
    )
    if timing.PreDelay > 0
        Sleep(timing.PreDelay)
}

InspectorJitterDelay(milliseconds) {
    LogToConsole("Internal randomized timing: +" milliseconds " ms.")
    if milliseconds > 0
        Sleep(milliseconds)
}

InspectorRandomInt(minimum, maximum) {
    return Random(minimum, maximum)
}

RunInspectorADBCommand(arguments) {
    global TapCommandIndex, LastTapADBPoints
    TapCommandIndex += 1
    if RegExMatch(
        arguments,
        "shell input tap\s+(-?\d+)\s+(-?\d+)",
        &match
    ) {
        adbX := Integer(match[1])
        adbY := Integer(match[2])
        LastTapADBPoints.Push({x: adbX, y: adbY})
        clientPoint := TranslateADBPointToClient(adbX, adbY)
        LogToConsole(
            Format(
                "Tap {}/3 -> randomized ADB ({}, {}) "
                    "-> displayed client ({}, {})",
                TapCommandIndex,
                adbX,
                adbY,
                clientPoint.x,
                clientPoint.y
            )
        )
    } else {
        LogToConsole("Tap " TapCommandIndex "/3 command: " arguments)
    }
    adbPath := ResolveInspectorADBPath()
    exitCode := RunWait(
        '"' adbPath '" ' arguments,
        A_ScriptDir,
        "Hide"
    )
    if exitCode != 0
        throw Error("ADB tap command exited with code " exitCode ".")
    return true
}

SaveDesktopRegionWithMarkers(
    screenX,
    screenY,
    width,
    height,
    filePath,
    markers,
    rectangles
) {
    width := Max(1, Round(width))
    height := Max(1, Round(height))
    InitInspectorGDIPlus()
    screenDC := DllCall("GetDC", "ptr", 0, "ptr")
    memoryDC := DllCall("CreateCompatibleDC", "ptr", screenDC, "ptr")
    bitmap := DllCall(
        "CreateCompatibleBitmap",
        "ptr",
        screenDC,
        "int",
        width,
        "int",
        height,
        "ptr"
    )
    oldBitmap := DllCall(
        "SelectObject",
        "ptr",
        memoryDC,
        "ptr",
        bitmap,
        "ptr"
    )
    DllCall(
        "BitBlt",
        "ptr",
        memoryDC,
        "int",
        0,
        "int",
        0,
        "int",
        width,
        "int",
        height,
        "ptr",
        screenDC,
        "int",
        Round(screenX),
        "int",
        Round(screenY),
        "uint",
        0x00CC0020 | 0x40000000
    )
    sourceBitmap := 0
    DllCall(
        "gdiplus\GdipCreateBitmapFromHBITMAP",
        "ptr",
        bitmap,
        "ptr",
        0,
        "ptr*",
        &sourceBitmap
    )
    graphics := 0
    DllCall(
        "gdiplus\GdipGetImageGraphicsContext",
        "ptr",
        sourceBitmap,
        "ptr*",
        &graphics
    )
    greenPen := 0
    redPen := 0
    DllCall(
        "gdiplus\GdipCreatePen1",
        "uint",
        0xFF00FF00,
        "float",
        3.0,
        "int",
        2,
        "ptr*",
        &greenPen
    )
    DllCall(
        "gdiplus\GdipCreatePen1",
        "uint",
        0xFFFF0000,
        "float",
        3.0,
        "int",
        2,
        "ptr*",
        &redPen
    )
    for rectangle in rectangles {
        pen := rectangle.isPass ? greenPen : redPen
        DllCall(
            "gdiplus\GdipDrawRectangle",
            "ptr",
            graphics,
            "ptr",
            pen,
            "float",
            rectangle.relX,
            "float",
            rectangle.relY,
            "float",
            rectangle.width,
            "float",
            rectangle.height
        )
    }
    for marker in markers {
        pen := marker.isPass ? greenPen : redPen
        DllCall(
            "gdiplus\GdipDrawRectangle",
            "ptr",
            graphics,
            "ptr",
            pen,
            "float",
            marker.relX - 7,
            "float",
            marker.relY - 7,
            "float",
            14.0,
            "float",
            14.0
        )
        DllCall(
            "gdiplus\GdipDrawLine",
            "ptr",
            graphics,
            "ptr",
            pen,
            "float",
            marker.relX - 12,
            "float",
            marker.relY,
            "float",
            marker.relX + 12,
            "float",
            marker.relY
        )
        DllCall(
            "gdiplus\GdipDrawLine",
            "ptr",
            graphics,
            "ptr",
            pen,
            "float",
            marker.relX,
            "float",
            marker.relY - 12,
            "float",
            marker.relX,
            "float",
            marker.relY + 12
        )
    }
    DllCall("gdiplus\GdipDeletePen", "ptr", greenPen)
    DllCall("gdiplus\GdipDeletePen", "ptr", redPen)
    DllCall("gdiplus\GdipDeleteGraphics", "ptr", graphics)
    pngClsid := Buffer(16, 0)
    DllCall(
        "ole32\CLSIDFromString",
        "wstr",
        "{557CF406-1A04-11D3-9A73-0000F81EF32E}",
        "ptr",
        pngClsid
    )
    saveStatus := DllCall(
        "gdiplus\GdipSaveImageToFile",
        "ptr",
        sourceBitmap,
        "wstr",
        filePath,
        "ptr",
        pngClsid,
        "ptr",
        0
    )
    DllCall("gdiplus\GdipDisposeImage", "ptr", sourceBitmap)
    DllCall("SelectObject", "ptr", memoryDC, "ptr", oldBitmap)
    DllCall("DeleteObject", "ptr", bitmap)
    DllCall("DeleteDC", "ptr", memoryDC)
    DllCall("ReleaseDC", "ptr", 0, "ptr", screenDC)
    if saveStatus != 0
        throw Error("Desktop preview save failed with GDI+ status " saveStatus ".")
}

InitInspectorGDIPlus() {
    static token := 0
    if token != 0
        return token
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
    return token
}

LogToConsole(message) {
    timestamp := FormatTime(, "HH:mm:ss")
    ConsoleEdit.Value .= "[" timestamp "] " message "`n"
    SendMessage(0x0115, 7, 0, ConsoleEdit)
}

ClearConsole() {
    ConsoleEdit.Value := ""
    LogToConsole("Console cleared.")
}

F1::RunInspectCycle(true)
F2::SendThreeClearTaps()

~Space:: {
    if IsCalibrating
        CaptureCalibrationPoint()
}
