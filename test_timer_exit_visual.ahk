#Requires AutoHotkey v2.0
#SingleInstance Force
#Include loot_ocr_logic.ahk
#Include ADBcocbotrefactor_support.ahk

SetTitleMatchMode 2
CoordMode "Mouse", "Screen"

global TargetWindowTitle := "Emulator"
global TimerExitOkayX := 0
global TimerExitOkayY := 0

global ViewportLeft := 0
global ViewportTop := 0
global ViewportRight := -1
global ViewportBottom := -1
global CalibratedClientWidth := 0
global CalibratedClientHeight := 0
global CalibratedProvider := ""
global CalibratedSerial := ""
global DisplayWidth := 0
global DisplayHeight := 0
global MappingIdentity := ""
global CoordinatesDirty := false
global IsUpdatingControls := false

global TimerExitFramePath := A_Temp "\coc_timer_exit_frame.png"
global TimerExitPreviewPath := A_Temp "\coc_timer_exit_preview.png"

ReloadTimerExitConfig(true)

ExitGui := Gui("+Resize", "Clash of Clanker - Timer Exit Inspector")
ExitGui.SetFont("s10", "Segoe UI")

ExitGui.Add("Text", "x15 y14 w100 h25", "Target Window:")
EditTarget := ExitGui.Add(
    "Edit",
    "x115 y10 w220 h26",
    TargetWindowTitle
)
ChkTop := ExitGui.Add(
    "Checkbox",
    "x350 y14 w130 h25",
    "Always On Top"
)
StatusText := ExitGui.Add(
    "Text",
    "x490 y14 w205 h25 Right cGray",
    "Status: Ready"
)

ExitGui.Add(
    "GroupBox",
    "x15 y45 w680 h90",
    "Green Okay Button (Client Coordinates)"
)
ExitGui.Add("Text", "x30 y72 w65 h20", "Okay X:")
EditOkayX := ExitGui.Add(
    "Edit",
    "x95 y68 w80 h24 Number",
    String(TimerExitOkayX)
)
ExitGui.Add("UpDown", "Range0-4000", TimerExitOkayX)
ExitGui.Add("Text", "x195 y72 w65 h20", "Okay Y:")
EditOkayY := ExitGui.Add(
    "Edit",
    "x260 y68 w80 h24 Number",
    String(TimerExitOkayY)
)
ExitGui.Add("UpDown", "Range0-4000", TimerExitOkayY)
BtnSave := ExitGui.Add(
    "Button",
    "x365 y65 w100 h30",
    "Save Point"
)
BtnReload := ExitGui.Add(
    "Button",
    "x475 y65 w100 h30",
    "Reload Config"
)
BtnCalibrate := ExitGui.Add(
    "Button",
    "x30 y100 w235 h27",
    "Hover Okay + Press Space"
)
ExitGui.Add(
    "Text",
    "x280 y103 w400 h20",
    "Space captures and saves the current mouse position."
)

BtnPreview := ExitGui.Add(
    "Button",
    "x15 y145 w250 h38",
    "Preview Okay Location (F1)"
)
BtnADBExit := ExitGui.Add(
    "Button",
    "x280 y145 w250 h38",
    "Run Real ADB Exit (F2)"
)
BtnRefresh := ExitGui.Add(
    "Button",
    "x545 y145 w150 h38",
    "Refresh Preview"
)

ExitGui.SetFont("s16 Bold", "Segoe UI")
VerdictText := ExitGui.Add(
    "Text",
    "x20 y195 w670 h42 cBlue +Center",
    "Verdict: READY"
)
ExitGui.SetFont("s10 Norm", "Segoe UI")

ExitGui.Add(
    "GroupBox",
    "x15 y240 w680 h230",
    "Fresh ADB Target Preview"
)
PicPreview := ExitGui.Add(
    "Picture",
    "x25 y265 w660 h195 +Border",
    ""
)

ExitGui.Add(
    "GroupBox",
    "x15 y480 w680 h260",
    "Timer Exit Diagnostics"
)
ExitGui.SetFont("s9", "Consolas")
ConsoleEdit := ExitGui.Add(
    "Edit",
    "x25 y505 w660 h225 ReadOnly +VScroll +HScroll",
    ""
)
ExitGui.SetFont("s10", "Segoe UI")

EditTarget.OnEvent("Change", (*) => UpdateTimerExitTarget())
ChkTop.OnEvent(
    "Click",
    (*) => ExitGui.Opt(
        (ChkTop.Value ? "+" : "-") "AlwaysOnTop"
    )
)
EditOkayX.OnEvent("Change", (*) => OnTimerExitPointChanged())
EditOkayY.OnEvent("Change", (*) => OnTimerExitPointChanged())
BtnSave.OnEvent("Click", (*) => SaveTimerExitOkayPoint())
BtnReload.OnEvent("Click", (*) => ReloadTimerExitControls())
BtnCalibrate.OnEvent(
    "Click",
    (*) => TimerExitLog(
        "Calibration armed by instruction: hover over Okay and press Space."
    )
)
BtnPreview.OnEvent("Click", (*) => RunTimerExitPointerPreview())
BtnADBExit.OnEvent("Click", (*) => RunTimerExitADBTest())
BtnRefresh.OnEvent("Click", (*) => RefreshTimerExitPreview())
ExitGui.OnEvent("Close", (*) => ExitApp())
ExitGui.Show("w710 h755")

TimerExitLog(
    "Ready. F1 does not click: it sends Escape, then moves the Windows "
        "mouse to the proposed Okay client point."
)
TimerExitLog(
    "F2 exits Clash of Clans: it sends Escape and performs one randomized "
        "background ADB tap without moving the Windows mouse."
)
TimerExitLog(
    "If F1 misses, hover over the center of Okay and press Space to save "
        "the exact client coordinate."
)
SetTimer(RefreshTimerExitPreview, -100)

ReloadTimerExitConfig(reloadPoint := false) {
    global TargetWindowTitle
    global TimerExitOkayX, TimerExitOkayY
    global ViewportLeft, ViewportTop, ViewportRight, ViewportBottom
    global CalibratedClientWidth, CalibratedClientHeight
    global CalibratedProvider, CalibratedSerial

    if !FileExist("config.ini")
        throw Error("config.ini was not found.")

    TargetWindowTitle := IniRead(
        "config.ini",
        "Settings",
        "TargetWindowTitle",
        TargetWindowTitle
    )
    ViewportLeft := ReadTimerExitInteger(
        "ADBViewport",
        "Left",
        ViewportLeft
    )
    ViewportTop := ReadTimerExitInteger(
        "ADBViewport",
        "Top",
        ViewportTop
    )
    ViewportRight := ReadTimerExitInteger(
        "ADBViewport",
        "Right",
        ViewportRight
    )
    ViewportBottom := ReadTimerExitInteger(
        "ADBViewport",
        "Bottom",
        ViewportBottom
    )
    CalibratedClientWidth := ReadTimerExitInteger(
        "ADBViewport",
        "ClientWidth",
        CalibratedClientWidth
    )
    CalibratedClientHeight := ReadTimerExitInteger(
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

    if reloadPoint {
        savedX := IniRead(
            "config.ini",
            "VisualTests",
            "TimerExitOkayX",
            ""
        )
        savedY := IniRead(
            "config.ini",
            "VisualTests",
            "TimerExitOkayY",
            ""
        )
        if (savedX != "" && IsNumber(savedX))
            TimerExitOkayX := Round(Number(savedX))
        if (savedY != "" && IsNumber(savedY))
            TimerExitOkayY := Round(Number(savedY))
    }

    if (
        TimerExitOkayX <= 0
        && ViewportRight > ViewportLeft
    ) {
        TimerExitOkayX := Round(
            ViewportLeft
                + (ViewportRight - ViewportLeft - 1) * 0.60
        )
    }
    if (
        TimerExitOkayY <= 0
        && ViewportBottom > ViewportTop
    ) {
        TimerExitOkayY := Round(
            ViewportTop
                + (ViewportBottom - ViewportTop - 1) * 0.605
        )
    }
}

ReadTimerExitInteger(section, key, fallback) {
    value := IniRead("config.ini", section, key, "")
    return (value != "" && IsNumber(value))
        ? Round(Number(value))
        : fallback
}

UpdateTimerExitTarget() {
    global TargetWindowTitle
    TargetWindowTitle := Trim(EditTarget.Value)
}

UpdateTimerExitControls() {
    global IsUpdatingControls
    global TimerExitOkayX, TimerExitOkayY
    IsUpdatingControls := true
    EditTarget.Value := TargetWindowTitle
    EditOkayX.Value := String(TimerExitOkayX)
    EditOkayY.Value := String(TimerExitOkayY)
    IsUpdatingControls := false
}

OnTimerExitPointChanged() {
    global IsUpdatingControls, CoordinatesDirty
    global TimerExitOkayX, TimerExitOkayY
    if IsUpdatingControls
        return
    try {
        if (EditOkayX.Value != "")
            TimerExitOkayX := Round(Number(EditOkayX.Value))
        if (EditOkayY.Value != "")
            TimerExitOkayY := Round(Number(EditOkayY.Value))
        CoordinatesDirty := true
        SetTimer(RefreshTimerExitPreview, -150)
    }
}

SaveTimerExitOkayPoint() {
    global CoordinatesDirty
    global TimerExitOkayX, TimerExitOkayY
    OnTimerExitPointChanged()
    IniWrite(
        TimerExitOkayX,
        "config.ini",
        "VisualTests",
        "TimerExitOkayX"
    )
    IniWrite(
        TimerExitOkayY,
        "config.ini",
        "VisualTests",
        "TimerExitOkayY"
    )
    CoordinatesDirty := false
    TimerExitLog(
        "Saved Okay client point ("
            TimerExitOkayX ", " TimerExitOkayY
            ") to [VisualTests]."
    )
    SetTimer(RefreshTimerExitPreview, -50)
}

ReloadTimerExitControls() {
    global CoordinatesDirty, MappingIdentity
    CoordinatesDirty := false
    MappingIdentity := ""
    ReloadTimerExitConfig(true)
    UpdateTimerExitControls()
    TimerExitLog(
        "Reloaded the Okay point and ADB viewport from config.ini."
    )
    RefreshTimerExitPreview()
}

CaptureTimerExitOkayPoint() {
    global TimerExitOkayX, TimerExitOkayY
    global CoordinatesDirty, TargetWindowTitle

    hwnd := WinExist(TargetWindowTitle)
    if !hwnd {
        SetTimerExitVerdict("CALIBRATION ERROR", false)
        TimerExitLog(
            "Calibration failed: target window '"
                TargetWindowTitle "' was not found."
        )
        return false
    }

    try {
        WinGetClientPos(
            &clientScreenX,
            &clientScreenY,
            &clientWidth,
            &clientHeight,
            hwnd
        )
        MouseGetPos(&mouseScreenX, &mouseScreenY)
        clientX := Round(mouseScreenX - clientScreenX)
        clientY := Round(mouseScreenY - clientScreenY)
        if (
            clientX < 0
            || clientY < 0
            || clientX >= clientWidth
            || clientY >= clientHeight
        ) {
            throw Error(
                "The mouse is outside the target window client area."
            )
        }
        TimerExitOkayX := clientX
        TimerExitOkayY := clientY
        CoordinatesDirty := true
        UpdateTimerExitControls()
        SaveTimerExitOkayPoint()
        SetTimerExitVerdict("OKAY POINT CALIBRATED", true)
        TimerExitLog(
            "Space calibration captured screen ("
                mouseScreenX ", " mouseScreenY
                ") as client (" clientX ", " clientY ")."
        )
        return true
    } catch as err {
        SetTimerExitVerdict("CALIBRATION ERROR", false)
        TimerExitLog("Calibration failed: " err.Message)
        return false
    }
}

EnsureTimerExitADBMapping() {
    global MappingIdentity, DisplayWidth, DisplayHeight
    global ViewportLeft, ViewportTop, ViewportRight, ViewportBottom
    global CalibratedClientWidth, CalibratedClientHeight
    global CalibratedProvider, CalibratedSerial

    if (CalibratedSerial == "")
        throw Error("ADBViewport.Serial is missing from config.ini.")
    if (
        ViewportRight <= ViewportLeft
        || ViewportBottom <= ViewportTop
    ) {
        throw Error("ADBViewport bounds in config.ini are invalid.")
    }

    identity := (
        CalibratedClientWidth "|" CalibratedClientHeight "|"
        CalibratedProvider "|" CalibratedSerial "|"
        ViewportLeft "|" ViewportTop "|"
        ViewportRight "|" ViewportBottom
    )
    if (
        identity == MappingIdentity
        && DisplayWidth > 0
        && DisplayHeight > 0
    ) {
        return
    }

    display := QueryTimerExitADBDisplaySize(CalibratedSerial)
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
    TimerExitLog(
        "Mapping loaded: viewport (" ViewportLeft ", "
            ViewportTop ")-(" ViewportRight ", "
            ViewportBottom "), client "
            CalibratedClientWidth "x" CalibratedClientHeight
            ", ADB " DisplayWidth "x" DisplayHeight
            ", serial " CalibratedSerial "."
    )
}

ResolveTimerExitADBPath() {
    for directory in StrSplit(EnvGet("PATH"), ";") {
        directory := Trim(directory, ' "')
        if (directory == "")
            continue
        candidate := RTrim(directory, "\/") "\adb.exe"
        if FileExist(candidate)
            return candidate
    }
    bundled := (
        "C:\Program Files\Google\Play Games Developer Emulator"
        "\current\emulator\adb.exe"
    )
    if FileExist(bundled)
        return bundled
    throw Error("adb.exe was not found.")
}

RunTimerExitADBOutput(arguments) {
    adbPath := ResolveTimerExitADBPath()
    outputPath := A_Temp "\coc_timer_exit_adb_output.txt"
    try FileDelete(outputPath)
    command := (
        A_ComSpec ' /D /S /C ""' adbPath '" '
            arguments ' > "' outputPath '" 2>&1"'
    )
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    output := FileExist(outputPath)
        ? Trim(FileRead(outputPath), " `t`r`n")
        : ""
    try FileDelete(outputPath)
    return {
        ok: exitCode == 0,
        output: output,
        exitCode: exitCode
    }
}

QueryTimerExitADBDisplaySize(serial) {
    state := RunTimerExitADBOutput('-s "' serial '" get-state')
    if !state.ok {
        connect := RunTimerExitADBOutput('connect "' serial '"')
        if !connect.ok
            throw Error("ADB connection failed: " connect.output)
    }
    sizeResult := RunTimerExitADBOutput(
        '-s "' serial '" shell wm size'
    )
    if !sizeResult.ok
        throw Error("Could not query ADB size: " sizeResult.output)
    if RegExMatch(
        sizeResult.output,
        "i)Override size:\s*(\d+)x(\d+)",
        &match
    ) {
        return {
            width: Number(match[1]),
            height: Number(match[2])
        }
    }
    if RegExMatch(
        sizeResult.output,
        "i)Physical size:\s*(\d+)x(\d+)",
        &match
    ) {
        return {
            width: Number(match[1]),
            height: Number(match[2])
        }
    }
    throw Error(
        "Unrecognized ADB display size: " sizeResult.output
    )
}

CaptureTimerExitADBFrame() {
    global CalibratedSerial, TimerExitFramePath
    adbPath := ResolveTimerExitADBPath()
    try FileDelete(TimerExitFramePath)
    command := (
        A_ComSpec ' /D /S /C ""' adbPath '" -s "'
            CalibratedSerial
            '" exec-out screencap -p > "'
            TimerExitFramePath '""'
    )
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    if (
        exitCode != 0
        || !FileExist(TimerExitFramePath)
    ) {
        throw Error(
            "Fresh ADB screenshot failed with exit "
                exitCode "."
        )
    }
    if (FileGetSize(TimerExitFramePath) < 1024)
        throw Error("Fresh ADB screenshot is unexpectedly small.")
    return TimerExitFramePath
}

TimerExitCommandSink(arguments) {
    adbPath := ResolveTimerExitADBPath()
    exitCode := RunWait(
        '"' adbPath '" ' arguments,
        A_ScriptDir,
        "Hide"
    )
    if (exitCode != 0)
        throw Error("ADB interaction failed with exit " exitCode ".")
}

TimerExitDelaySink(milliseconds) {
    if (milliseconds > 0)
        Sleep milliseconds
}

TimerExitRandomSink(minimum, maximum) {
    return Random(minimum, maximum)
}

WaitForTimerExitPreDelay(intendedDelayMs) {
    timing := GetADBActionTiming(intendedDelayMs)
    if (timing.PreDelay > 0)
        Sleep timing.PreDelay
    return timing.PreDelay
}

CreateTimerExitInteraction() {
    global CalibratedSerial
    return CreateADBClientInteraction(
        CalibratedSerial,
        TimerExitCommandSink,
        TimerExitDelaySink,
        TimerExitRandomSink
    )
}

SendTimerExitEscape() {
    interaction := CreateTimerExitInteraction()
    WaitForTimerExitPreDelay(100)
    return interaction.KeyEvent("KEYCODE_ESCAPE", 100)
}

TapTimerExitOkay(intendedDelayMs := 650) {
    global TimerExitOkayX, TimerExitOkayY
    interaction := CreateTimerExitInteraction()
    WaitForTimerExitPreDelay(intendedDelayMs)
    return interaction.Tap(
        TimerExitOkayX,
        TimerExitOkayY,
        intendedDelayMs
    )
}

RunTimerExitPointerPreview() {
    global CoordinatesDirty, TargetWindowTitle
    global TimerExitOkayX, TimerExitOkayY

    BtnPreview.Enabled := false
    try {
        ReloadTimerExitConfig(!CoordinatesDirty)
        UpdateTimerExitControls()
        EnsureTimerExitADBMapping()
        nominal := TranslateClientPointToADB(
            TimerExitOkayX,
            TimerExitOkayY
        )
        TimerExitLog("=== F1 POINTER PREVIEW START ===")
        TimerExitLog(
            "F1 does not click. Sending KEYCODE_ESCAPE through ADB."
        )
        SendTimerExitEscape()
        Sleep 650

        hwnd := WinExist(TargetWindowTitle)
        if !hwnd
            throw Error("The visible target window was not found.")
        WinGetClientPos(
            &clientScreenX,
            &clientScreenY,
            &clientWidth,
            &clientHeight,
            hwnd
        )
        if (
            TimerExitOkayX < 0
            || TimerExitOkayY < 0
            || TimerExitOkayX >= clientWidth
            || TimerExitOkayY >= clientHeight
        ) {
            throw Error(
                "The Okay client point is outside the visible client."
            )
        }
        screenX := clientScreenX + TimerExitOkayX
        screenY := clientScreenY + TimerExitOkayY
        MouseMove(screenX, screenY, 0)
        TimerExitLog(
            "Pointer preview: client (" TimerExitOkayX ", "
                TimerExitOkayY "), nominal ADB ("
                nominal.x ", " nominal.y "), screen ("
                screenX ", " screenY ")."
        )
        RefreshTimerExitPreview()
        SetTimerExitVerdict("POINTER MOVED — NO CLICK", true)
        TimerExitLog(
            "F1 preview complete. Dismiss the dialog manually before F2. "
                "If the pointer missed, hover Okay and press Space."
        )
        return true
    } catch as err {
        SetTimerExitVerdict("F1 PREVIEW ERROR", false)
        TimerExitLog("F1 preview failed: " err.Message)
        return false
    } finally {
        BtnPreview.Enabled := true
    }
}

RunTimerExitADBTest() {
    global CoordinatesDirty
    global TimerExitOkayX, TimerExitOkayY

    BtnADBExit.Enabled := false
    try {
        ReloadTimerExitConfig(!CoordinatesDirty)
        UpdateTimerExitControls()
        EnsureTimerExitADBMapping()
        nominal := TranslateClientPointToADB(
            TimerExitOkayX,
            TimerExitOkayY
        )
        MouseGetPos(&pointerBeforeX, &pointerBeforeY)
        TimerExitLog("=== F2 REAL ADB EXIT START ===")
        TimerExitLog(
            "F2 exits Clash of Clans. Sending KEYCODE_ESCAPE through ADB."
        )
        SendTimerExitEscape()
        actual := TapTimerExitOkay(650)
        MouseGetPos(&pointerAfterX, &pointerAfterY)
        pointerStayed := (
            pointerAfterX == pointerBeforeX
            && pointerAfterY == pointerBeforeY
        )
        TimerExitLog(
            "Okay tap: client (" TimerExitOkayX ", "
                TimerExitOkayY "), nominal ADB ("
                nominal.x ", " nominal.y
                "), randomized ADB actually sent ("
                actual.x ", " actual.y ")."
        )
        TimerExitLog(
            "Windows pointer before=(" pointerBeforeX ", "
                pointerBeforeY "), after=(" pointerAfterX ", "
                pointerAfterY ")."
        )
        if !pointerStayed
            throw Error("The Windows pointer moved during the ADB test.")
        TimerExitLog("Windows pointer remained stationary.")
        SetTimerExitVerdict("ADB EXIT TAP SENT", true)
        StatusText.Text := "Status: Complete"
        StatusText.Opt("cGreen")
        return true
    } catch as err {
        SetTimerExitVerdict("F2 ADB EXIT ERROR", false)
        TimerExitLog("F2 ADB exit failed: " err.Message)
        return false
    } finally {
        BtnADBExit.Enabled := true
    }
}

RefreshTimerExitPreview() {
    global CoordinatesDirty
    global TimerExitOkayX, TimerExitOkayY
    global TimerExitPreviewPath
    try {
        ReloadTimerExitConfig(!CoordinatesDirty)
        UpdateTimerExitControls()
        EnsureTimerExitADBMapping()
        nominal := TranslateClientPointToADB(
            TimerExitOkayX,
            TimerExitOkayY
        )
        framePath := CaptureTimerExitADBFrame()
        SaveTimerExitPreviewWithMarker(
            framePath,
            TimerExitPreviewPath,
            nominal.x,
            nominal.y,
            true
        )
        PicPreview.Value := ""
        PicPreview.Value := TimerExitPreviewPath
        StatusText.Text := "Status: Preview refreshed"
        StatusText.Opt("cGreen")
        TimerExitLog(
            "Fresh preview: client (" TimerExitOkayX ", "
                TimerExitOkayY ") -> nominal ADB ("
                nominal.x ", " nominal.y ")."
        )
        return true
    } catch as err {
        StatusText.Text := "Status: Preview error"
        StatusText.Opt("cRed")
        TimerExitLog("Preview refresh failed: " err.Message)
        return false
    }
}

InitTimerExitGDIPlus() {
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

SaveTimerExitPreviewWithMarker(
    framePath,
    previewPath,
    adbX,
    adbY,
    isPass
) {
    InitTimerExitGDIPlus()
    pBitmap := 0
    if DllCall(
        "gdiplus\GdipCreateBitmapFromFile",
        "wstr",
        framePath,
        "ptr*",
        &pBitmap
    ) != 0 {
        throw Error("Fresh ADB frame could not be opened for preview.")
    }

    pGraphics := 0
    pPen := 0
    try {
        DllCall(
            "gdiplus\GdipGetImageGraphicsContext",
            "ptr",
            pBitmap,
            "ptr*",
            &pGraphics
        )
        color := isPass ? 0xFF00FF00 : 0xFFFF0000
        DllCall(
            "gdiplus\GdipCreatePen1",
            "uint",
            color,
            "float",
            8.0,
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
            Float(adbX - 24),
            "float",
            Float(adbY - 24),
            "float",
            48.0,
            "float",
            48.0
        )
        try FileDelete(previewPath)
        SaveTimerExitBitmapPNG(pBitmap, previewPath)
    } finally {
        if pPen
            DllCall("gdiplus\GdipDeletePen", "ptr", pPen)
        if pGraphics
            DllCall(
                "gdiplus\GdipDeleteGraphics",
                "ptr",
                pGraphics
            )
        if pBitmap
            DllCall(
                "gdiplus\GdipDisposeImage",
                "ptr",
                pBitmap
            )
    }
}

SaveTimerExitBitmapPNG(pBitmap, filepath) {
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
        throw Error("Preview PNG save failed with status " status ".")
}

SetTimerExitVerdict(message, isPass) {
    VerdictText.Text := "Verdict: " message
    VerdictText.Opt(isPass ? "cGreen" : "cRed")
    StatusText.Text := isPass ? "Status: Complete" : "Status: Error"
    StatusText.Opt(isPass ? "cGreen" : "cRed")
}

TimerExitLog(message) {
    timeText := FormatTime(, "HH:mm:ss")
    ConsoleEdit.Value .= "[" timeText "] " message "`n"
    SendMessage(0x0115, 7, 0, ConsoleEdit)
}

F1:: RunTimerExitPointerPreview()
F2:: RunTimerExitADBTest()
Space:: CaptureTimerExitOkayPoint()
