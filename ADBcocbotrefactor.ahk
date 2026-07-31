#Requires AutoHotkey v2.0
#SingleInstance Force
; Refactor source: ADBcoc_bot.ahk SHA-256
; 41BBFC8851EA83E70D1979C736EA2D1150F008CD974EFE11E7815E4A5DEA71B5.
; ADBcoc_bot.ahk is the protected rollback reference and must remain unchanged.
#include "OCR.ahk"
#include "loot_ocr_logic.ahk"
#include "resource_threshold_logic.ahk"
#include "builder_info_ocr_logic.ahk"
#include "builder_base_loop_logic.ahk"
; Every gameplay input must enter through the client-coordinate interaction
; contract in this support file. Callers must never pretranslate coordinates.
#include "ADBcocbotrefactor_support.ahk"
; Set coordinate modes relative to the active window's client area and match substring titles
CoordMode "Mouse", "Client"
SetTitleMatchMode 2
; ==============================================================================
; CONFIGURATION VARIABLES (GLOBAL DEFAULTS)
; ==============================================================================
global TargetWindowTitle := "Clash of Clans"
global ButtonDelta := 5
global DeployDelta := 15
global TransitionDelay := 500
global BattleLoadDelay := 1500
global BBClickCount := 1
; --- ADB target and pinch helper ---
global GPGDE_PROVIDER := "Google Play Games Developer Emulator"
global BLUESTACKS_PROVIDER := "BlueStacks"
global GPGDE_SERIAL := "localhost:6520"
global ADBProvider := GPGDE_PROVIDER
global BlueStacksSerial := "127.0.0.1:5555"
global ADBConnectionSerial := ""
global ADBHelperSerial := ""
global ADBDisplaySerial := ""
global ADBDisplayWidth := 0
global ADBDisplayHeight := 0
global ADB_TARGET_PACKAGE := "com.supercell.clashofclans"
global ADB_PINCH_TARGET_PACKAGE := "com.cocbot.pinchtest.target"
global ADB_PINCH_INSTRUMENTATION_PACKAGE := "com.cocbot.pinchtest.instrumentation"
global ADB_PINCH_COMPONENT := ADB_PINCH_INSTRUMENTATION_PACKAGE "/com.cocbot.pinchtest.PinchInstrumentation"
global ADB_PINCH_TARGET_APK := A_ScriptDir "\pinch_test\dist\pinch-target.apk"
global ADB_PINCH_INSTRUMENTATION_APK := A_ScriptDir "\pinch_test\dist\pinch-instrumentation.apk"
; --- Farming Thresholds & Toggles ---
global MinGold := 500000
global MinElixir := 500000
global EnableLootSearch := true
global EnableWallUpgrade := true
; --- Troop Deployment Counts ---
global Troop1Count := 14
global Troop2Count := 14
global Troop3Count := 14
; --- Button & Target Coordinates ---
global AttackBtnX := 100
global AttackBtnY := 970
global FindMatchBtnX := 250
global FindMatchBtnY := 750
global AttackStartBtnX := 1630
global AttackStartBtnY := 920
global ReturnHomeClickX := 960
global ReturnHomeClickY := 920
global ReturnHomeColor := 0x5FA41A
global ReturnHomeTolerance := 35
global ClearTapX := 1676
global ClearTapY := 416
; --- Builder Base Coordinates & Stars ---
global BBAttackBtnX := 100
global BBAttackBtnY := 970
global BBFindMatchBtnX := 250
global BBFindMatchBtnY := 750
global BBStar1X := 960
global BBStar1Y := 540
global BBStar2X := 960
global BBStar2Y := 540
global BBStar3X := 960
global BBStar3Y := 540
global BBStarColor := 0x000000
global WarLogoX := 100
global WarLogoY := 700
global MVLogoX := 100
global MVLogoY := 700
global WarLogoColor := 0x000000
; --- OCR Target Areas ---
global BuilderFaceX := 960
global BuilderFaceY := 30
global LabFaceX := 960
global LabFaceY := 30
global UpgradeConfirmX := 960
global UpgradeConfirmY := 540
global GoldAreaX := 50
global GoldAreaY := 50
global GoldAreaW := 150
global GoldAreaH := 30
global ElixirAreaX := 50
global ElixirAreaY := 90
global ElixirAreaW := 150
global ElixirAreaH := 30
global GoldIconX := 45
global GoldIconY := 145
global ElixirIconX := 45
global ElixirIconY := 195
global LootCropOffsetX := 20
global LootCropOffsetY := -4
global LootCropW := 240
global LootCropH := 45
global NextMatchBtnX := 1630
global NextMatchBtnY := 850
; --- Storage Bar Check Coordinates ---
global DarkElixirBarThreshX := 1750
global DarkElixirBarThreshY := 100
global GoldBarThreshX := 1750
global GoldBarThreshY := 100
global ElixirBarThreshX := 1750
global ElixirBarThreshY := 160
; --- Wall Upgrade Coordinates ---
global UpgradeMoreBtnX := 960
global UpgradeMoreBtnY := 850
global AddWall1X := 960
global AddWall1Y := 800
global RemoveWallX := 960
global RemoveWallY := 800
global GoldUpgradeX := 960
global GoldUpgradeY := 800
global ElixirUpgradeX := 960
global ElixirUpgradeY := 800
; --- Clouds Checking Coordinates ---
global CloudPt1X := 500
global CloudPt1Y := 300
global CloudPt2X := 1420
global CloudPt2Y := 300
global CloudPt3X := 500
global CloudPt3Y := 780
global CloudPt4X := 1420
global CloudPt4Y := 780
global CloudGreyTolerance := 15
; --- Resource Collection Coordinates ---
global CollectorCoords := []
global ADBMainCalibrationVersion := 0
global ADBBBCalibrationVersion := 0
global ADB_COORDINATE_VERSION := 2
global ADBViewportLeft := 0
global ADBViewportTop := 0
global ADBViewportRight := -1
global ADBViewportBottom := -1
global ADBViewportClientWidth := 0
global ADBViewportClientHeight := 0
global ADBViewportProvider := ""
global ADBViewportSerial := ""
global ADBViewportVersion := 0
global ADB_VIEWPORT_VERSION := 1
global PendingViewportLeft := 0
global PendingViewportTop := 0
global BuilderMenuBottomX := 960, BuilderMenuBottomY := 800
; --- Attack Sides Calibration Globals ---
global Side1StartX := 1750, Side1StartY := 520, Side1EndX := 1400, Side1EndY := 800
global Side2StartX := 150, Side2StartY := 510, Side2EndX := 600, Side2EndY := 850
global Side3StartX := 150, Side3StartY := 510, Side3EndX := 507, Side3EndY := 230
global Side4StartX := 1131, Side4StartY := 40, Side4EndX := 1506, Side4EndY := 312
; --- Attack Sides Configuration (Randomized Sides) ---
global Sides := [
    {startX: Side1StartX, startY: Side1StartY, endX: Side1EndX, endY: Side1EndY},
    {startX: Side2StartX, startY: Side2StartY, endX: Side2EndX, endY: Side2EndY},
    {startX: Side3StartX, startY: Side3StartY, endX: Side3EndX, endY: Side3EndY},
    {startX: Side4StartX, startY: Side4StartY, endX: Side4EndX, endY: Side4EndY}
]
; --- Builder Base Attack Sides Calibration Globals ---
global BBSide1StartX := 1750, BBSide1StartY := 520, BBSide1EndX := 1400, BBSide1EndY := 800
global BBSide2StartX := 150, BBSide2StartY := 510, BBSide2EndX := 600, BBSide2EndY := 850
global BBSide3StartX := 150, BBSide3StartY := 510, BBSide3EndX := 507, BBSide3EndY := 230
global BBSide4StartX := 1131, BBSide4StartY := 40, BBSide4EndX := 1506, BBSide4EndY := 312
global BBSides := [
    {startX: BBSide1StartX, startY: BBSide1StartY, endX: BBSide1EndX, endY: BBSide1EndY},
    {startX: BBSide2StartX, startY: BBSide2StartY, endX: BBSide2EndX, endY: BBSide2EndY},
    {startX: BBSide3StartX, startY: BBSide3StartY, endX: BBSide3EndX, endY: BBSide3EndY},
    {startX: BBSide4StartX, startY: BBSide4StartY, endX: BBSide4EndX, endY: BBSide4EndY}
]
; ==============================================================================
; STATE CONTROL
; ==============================================================================
global IsRunning := false
global IsBBRunning := false
global IsCalibrating := false
global IsBBCalibrating := false
global IsWaitingForReset := false
global CalibStep := 0
global BBCalibStep := 0
global TimerStartTick := 0
global TimerDurationMs := 0
global SessionCompletedAttacks := 0


; ==============================================================================
; GUI ELEMENT REFERENCES
; ==============================================================================
global MyGui := ""
global EditWindow := ""
global EditBattleLoad := ""
global EditButtonDelta := ""
global EditDeployDelta := ""
global EditMinGold := ""
global EditMinElixir := ""
global CheckLootSearch := ""
global CheckWallUpgrade := ""
global TextCollectorCount := ""
global EditTroop1Count := ""
global EditTroop2Count := ""
global EditTroop3Count := ""
global LogEdit := ""
global StatusText := ""
global StartBtn := ""
global PauseBtn := ""
global CalibrationText := ""
global DDHours := ""
global DDMinutes := ""
global EditADBProvider := ""
global EditBlueStacksSerial := ""
global ADBStatusText := ""
global ADBFramePath := ""
global LastADBFrameTick := 0

; Load configuration settings
LoadConfig()
; Initialize GUI
CreateGUI()
LogMessage("Bot initialized. Ready.")

ResolveADBSerial(provider, blueStacksSerial) {
    global GPGDE_PROVIDER, BLUESTACKS_PROVIDER, GPGDE_SERIAL
    if (provider == GPGDE_PROVIDER)
        return GPGDE_SERIAL
    if (provider == BLUESTACKS_PROVIDER)
        return ValidateBlueStacksSerial(blueStacksSerial)
    throw Error("Choose Google Play Games Developer Emulator or BlueStacks.")
}

ValidateBlueStacksSerial(serial) {
    serial := Trim(serial)
    if !RegExMatch(serial, "^(localhost|127\.0\.0\.1):(\d{1,5})$", &match)
        throw Error("BlueStacks must use localhost:PORT or 127.0.0.1:PORT.")
    port := Integer(match[2])
    if (port < 1 || port > 65535)
        throw Error("BlueStacks port must be between 1 and 65535.")
    return serial
}

QuoteADBArgument(value) {
    return '"' value '"'
}

IsADBViewportValid(left, top, right, bottom, clientWidth, clientHeight) {
    return clientWidth > 0
        && clientHeight > 0
        && left >= 0
        && top >= 0
        && right > left
        && bottom > top
        && right < clientWidth
        && bottom < clientHeight
}

DoesADBViewportMatchRuntime(calibratedClientWidth, calibratedClientHeight, calibratedProvider, calibratedSerial,
    currentClientWidth, currentClientHeight, currentProvider, currentSerial) {
    return calibratedClientWidth == currentClientWidth
        && calibratedClientHeight == currentClientHeight
        && calibratedProvider == currentProvider
        && calibratedSerial == currentSerial
}

ParseBuilderFraction(text, &free, &total) {
    normalized := StrReplace(text, " ", "")
    for replacement in [["I", "1"], ["i", "1"], ["l", "1"], ["|", "1"], ["!", "1"], ["O", "0"], ["o", "0"]]
        normalized := StrReplace(normalized, replacement[1], replacement[2])
    if !RegExMatch(normalized, "([0-7])[/\\]([1-7])", &match)
        return false
    free := Integer(match[1])
    total := Integer(match[2])
    return free <= total
}

ClientToADBPoint(x, y) {
    viewportState := ValidateADBViewportRuntime()
    if !viewportState.Ok
        throw Error(viewportState.Message)
    return TranslateClientPointToADB(x, y)
}

GetADBClientViewportRect() {
    global ADBViewportLeft, ADBViewportTop, ADBViewportRight, ADBViewportBottom
    viewportState := ValidateADBViewportRuntime()
    if !viewportState.Ok
        throw Error(viewportState.Message)
    return {
        x: ADBViewportLeft,
        y: ADBViewportTop,
        width: ADBViewportRight - ADBViewportLeft,
        height: ADBViewportBottom - ADBViewportTop
    }
}

ClientRectToADBRect(x, y, width, height) {
    viewportState := ValidateADBViewportRuntime()
    if !viewportState.Ok
        throw Error(viewportState.Message)
    return TranslateClientRectToADB(x, y, width, height)
}

ADBFramePointToClient(adbRect, localX, localY) {
    viewportState := ValidateADBViewportRuntime()
    if !viewportState.Ok
        throw Error(viewportState.Message)
    return TranslateADBPointToClient(
        adbRect.x + localX,
        adbRect.y + localY
    )
}

ClientViewportPointFromFraction(xRatio, yRatio) {
    viewport := GetADBClientViewportRect()
    return {
        x: Round(viewport.x + (viewport.width - 1) * Max(0, Min(1, xRatio))),
        y: Round(viewport.y + (viewport.height - 1) * Max(0, Min(1, yRatio)))
    }
}

ValidateADBViewportRuntime() {
    global TargetWindowTitle, ADBProvider
    global ADBViewportLeft, ADBViewportTop, ADBViewportRight, ADBViewportBottom
    global ADBViewportClientWidth, ADBViewportClientHeight, ADBViewportProvider, ADBViewportSerial
    global ADBViewportVersion, ADB_VIEWPORT_VERSION
    if (ADBViewportVersion != ADB_VIEWPORT_VERSION)
        return {Ok: false, Message: "Android viewport calibration is missing or stale. Run Main Calibration."}
    if !IsADBViewportValid(ADBViewportLeft, ADBViewportTop, ADBViewportRight, ADBViewportBottom,
        ADBViewportClientWidth, ADBViewportClientHeight)
        return {Ok: false, Message: "Android viewport bounds are invalid. Run Main Calibration."}
    hwnd := WinExist(TargetWindowTitle)
    if !hwnd {
        InvalidateADBClientMapping()
        return {Ok: false, Message: "The configured emulator window was not found."}
    }
    isMinimized := WinGetMinMax(hwnd) == -1
    currentClientWidth := 0
    currentClientHeight := 0
    if !isMinimized
        WinGetClientPos ,, &currentClientWidth, &currentClientHeight, hwnd
    validationSize := ResolveADBValidationClientSize(
        isMinimized,
        currentClientWidth,
        currentClientHeight,
        ADBViewportClientWidth,
        ADBViewportClientHeight
    )
    clientWidth := validationSize.width
    clientHeight := validationSize.height
    currentSerial := GetSelectedADBSerial()
    if !DoesADBViewportMatchRuntime(
        ADBViewportClientWidth,
        ADBViewportClientHeight,
        ADBViewportProvider,
        ADBViewportSerial,
        clientWidth,
        clientHeight,
        ADBProvider,
        currentSerial
    ) {
        InvalidateADBClientMapping()
        return {Ok: false, Message: "The emulator identity or client size changed. Run Main Calibration."}
    }
    try {
        display := GetADBDisplaySize()
    } catch as err {
        InvalidateADBClientMapping()
        return {Ok: false, Message: err.Message}
    }
    if !ValidateADBClientMappingIdentity(
        clientWidth,
        clientHeight,
        ADBProvider,
        currentSerial,
        display.width,
        display.height
    ) {
        ConfigureADBClientMapping(
            ADBViewportLeft,
            ADBViewportTop,
            ADBViewportRight,
            ADBViewportBottom,
            display.width,
            display.height,
            clientWidth,
            clientHeight,
            ADBProvider,
            currentSerial
        )
    }
    return {Ok: true, Message: "Android viewport is valid."}
}

InvalidateADBViewport() {
    global ADBViewportVersion, ADBMainCalibrationVersion, ADBBBCalibrationVersion
    InvalidateADBClientMapping()
    ADBViewportVersion := 0
    ADBMainCalibrationVersion := 0
    ADBBBCalibrationVersion := 0
}

BuildBuilderMenuSwipe(builderFaceX, menuBottomY, builderFaceY) {
    return {
        startX: Round(builderFaceX),
        startY: Round(menuBottomY),
        endX: Round(builderFaceX),
        endY: Round(menuBottomY + ((builderFaceY - menuBottomY) * 0.75))
    }
}

ResolveADBPath() {
    for directory in StrSplit(EnvGet("PATH"), ";") {
        directory := Trim(directory, ' "')
        if (directory == "")
            continue
        candidate := RTrim(directory, "\/") "\adb.exe"
        if FileExist(candidate)
            return candidate
    }
    bundledADB := "C:\Program Files\Google\Play Games Developer Emulator\current\emulator\adb.exe"
    if FileExist(bundledADB)
        return bundledADB
    throw Error("adb.exe was not found in PATH or the GPGDE installation folder.")
}

RunADB(arguments, captureOutput := false) {
    adbPath := ResolveADBPath()
    try {
        if !captureOutput {
            exitCode := RunWait(QuoteADBArgument(adbPath) " " arguments, A_ScriptDir, "Hide")
            return {Ok: exitCode == 0, ExitCode: exitCode, Output: ""}
        }
        outputPath := A_ScriptDir "\scratch\coc_bot_adb_output.txt"
        DirCreate(A_ScriptDir "\scratch")
        if FileExist(outputPath)
            FileDelete(outputPath)
        command := A_ComSpec ' /D /S /C ""' adbPath '" ' arguments ' > "' outputPath '" 2>&1"'
        exitCode := RunWait(command, A_ScriptDir, "Hide")
        output := FileExist(outputPath) ? Trim(FileRead(outputPath), " `t`r`n") : ""
        if FileExist(outputPath)
            FileDelete(outputPath)
        return {Ok: exitCode == 0, ExitCode: exitCode, Output: output}
    } catch as err {
        throw Error("Could not run ADB: " err.Message)
    }
}

FormatADBResult(result) {
    return result.Output != "" ? result.Output : "ADB exit code " result.ExitCode "."
}

GetSelectedADBSerial() {
    global ADBProvider, BlueStacksSerial
    return ResolveADBSerial(ADBProvider, BlueStacksSerial)
}

EnsureADBConnection(force := false) {
    global ADBConnectionSerial, ADBHelperSerial, ADBDisplaySerial
    serial := GetSelectedADBSerial()
    if !force && ADBConnectionSerial == serial
        return {Ok: true, Message: "Connected (cached).", Serial: serial}
    state := RunADB('-s ' QuoteADBArgument(serial) ' get-state', true)
    if !state.Ok {
        connected := RunADB('connect ' QuoteADBArgument(serial), true)
        if !connected.Ok
            return {Ok: false, Message: "ADB connect failed. " FormatADBResult(connected), Serial: serial}
        state := RunADB('-s ' QuoteADBArgument(serial) ' get-state', true)
    }
    if !state.Ok
        return {Ok: false, Message: "The selected emulator is unavailable. " FormatADBResult(state), Serial: serial}
    if (ADBConnectionSerial != serial) {
        ADBHelperSerial := ""
        ADBDisplaySerial := ""
    }
    ADBConnectionSerial := serial
    return {Ok: true, Message: "Connected.", Serial: serial}
}

GetADBDisplaySize() {
    global ADBDisplaySerial, ADBDisplayWidth, ADBDisplayHeight
    ready := EnsureADBConnection()
    if !ready.Ok
        throw Error(ready.Message)
    if (ADBDisplaySerial == ready.Serial && ADBDisplayWidth > 0 && ADBDisplayHeight > 0)
        return {width: ADBDisplayWidth, height: ADBDisplayHeight}
    result := RunADB('-s ' QuoteADBArgument(ready.Serial) ' shell wm size', true)
    if !result.Ok
        throw Error("Could not read the Android display size. " FormatADBResult(result))
    if RegExMatch(result.Output, "i)Override size:\s*(\d+)x(\d+)", &match)
        ADBDisplayWidth := Integer(match[1]), ADBDisplayHeight := Integer(match[2])
    else if RegExMatch(result.Output, "i)Physical size:\s*(\d+)x(\d+)", &match)
        ADBDisplayWidth := Integer(match[1]), ADBDisplayHeight := Integer(match[2])
    else
        throw Error("ADB returned an unrecognized display size: " result.Output)
    ADBDisplaySerial := ready.Serial
    LogMessage("ADB display mapping: " ADBDisplayWidth "x" ADBDisplayHeight ".")
    return {width: ADBDisplayWidth, height: ADBDisplayHeight}
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

CaptureADBFrame(force := false) {
    global ADBFramePath, LastADBFrameTick
    if (ADBFramePath == "")
        ADBFramePath := A_ScriptDir "\scratch\adb_frame.png"
    
    DirCreate(A_ScriptDir "\scratch")
    if (!force && FileExist(ADBFramePath) && (A_TickCount - LastADBFrameTick < 150))
        return ADBFramePath

    ready := EnsureADBActionReady()
    if !ready.Ok
        return ADBFramePath

    adbPath := ResolveADBPath()
    outputPath := ADBFramePath
    command := A_ComSpec ' /D /S /C ""' adbPath '" -s ' QuoteADBArgument(ready.Serial) ' exec-out screencap -p > "' outputPath '" 2>&1"'
    RunWait(command, A_ScriptDir, "Hide")
    LastADBFrameTick := A_TickCount
    return ADBFramePath
}

GetADBPixelColor(clientX, clientY, forceRefresh := false) {
    adbPoint := ClientToADBPoint(clientX, clientY)
    framePath := CaptureADBFrame(forceRefresh)
    if !FileExist(framePath)
        return 0x000000

    InitGDIPlus()
    pBitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", framePath, "ptr*", &pBitmap) != 0
        return 0x000000

    argb := 0
    DllCall(
        "gdiplus\GdipBitmapGetPixel",
        "ptr",
        pBitmap,
        "int",
        adbPoint.x,
        "int",
        adbPoint.y,
        "uint*",
        &argb
    )
    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    return argb & 0x00FFFFFF
}

GetADBFramePixelColor(framePath, clientX, clientY) {
    if (framePath == "" || !FileExist(framePath))
        return 0x000000
    adbPoint := ClientToADBPoint(clientX, clientY)
    InitGDIPlus()
    pBitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", framePath, "ptr*", &pBitmap) != 0
        return 0x000000
    argb := 0
    DllCall(
        "gdiplus\GdipBitmapGetPixel",
        "ptr",
        pBitmap,
        "int",
        adbPoint.x,
        "int",
        adbPoint.y,
        "uint*",
        &argb
    )
    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    return argb & 0x00FFFFFF
}

GetADBFrameThresholdNeighborhood(
    framePath,
    clientX,
    clientY,
    clientRadiusX := 24,
    clientRadiusY := 0,
    clientStep := 1
) {
    if (framePath == "" || !FileExist(framePath))
        throw Error("Fresh ADB threshold frame is missing.")

    center := ClientToADBPoint(clientX, clientY)
    InitGDIPlus()
    pBitmap := 0
    if DllCall(
        "gdiplus\GdipCreateBitmapFromFile",
        "wstr",
        framePath,
        "ptr*",
        &pBitmap
    ) != 0
        throw Error("Fresh ADB threshold frame could not be opened.")

    colors := []
    try {
        clientOffsetY := -clientRadiusY
        while (clientOffsetY <= clientRadiusY) {
            clientOffsetX := -clientRadiusX
            while (clientOffsetX <= clientRadiusX) {
                point := ClientToADBPoint(
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
                        "ADB threshold neighborhood sample failed with "
                            "status " status "."
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
    return analysis
}

ReadResourceThresholdsFromADBFrame(framePath) {
    global GoldBarThreshX, GoldBarThreshY
    global ElixirBarThreshX, ElixirBarThreshY
    global DarkElixirBarThreshX, DarkElixirBarThreshY

    goldSample := GetADBFrameThresholdNeighborhood(
        framePath,
        GoldBarThreshX,
        GoldBarThreshY
    )
    goldColor := goldSample.color
    goldR := (goldColor >> 16) & 0xFF
    goldG := (goldColor >> 8) & 0xFF
    goldB := goldColor & 0xFF
    goldFilled := goldSample.valid
        && goldR > 120
        && goldG > 100
        && goldR > goldB + 20
        && goldG > goldB + 10

    elixirSample := GetADBFrameThresholdNeighborhood(
        framePath,
        ElixirBarThreshX,
        ElixirBarThreshY
    )
    elixirColor := elixirSample.color
    elixirR := (elixirColor >> 16) & 0xFF
    elixirG := (elixirColor >> 8) & 0xFF
    elixirB := elixirColor & 0xFF
    elixirFilled := elixirSample.valid
        && elixirR >= 180
        && elixirG >= 80
        && elixirG <= 220
        && elixirB >= 100
        && elixirB <= 230
        && elixirR > elixirG
        && elixirR >= elixirB * 0.75
        && (elixirR + elixirG + elixirB) / 3 > 140
    elixirFilled := elixirFilled
        || (elixirR > 120 && elixirB > 100 && elixirR > elixirG + 20)

    darkSample := GetADBFrameThresholdNeighborhood(
        framePath,
        DarkElixirBarThreshX,
        DarkElixirBarThreshY
    )
    darkColor := darkSample.color
    darkR := (darkColor >> 16) & 0xFF
    darkG := (darkColor >> 8) & 0xFF
    darkB := darkColor & 0xFF
    darkFilled := darkSample.valid
        && darkR < 70
        && darkG < 60
        && darkB < 80

    LogMessage(
        Format(
            "Resource threshold Gold: median RGB=({}, {}, {}), "
                "ignored-light={}/{}, evaluated={}, result={}.",
            goldR,
            goldG,
            goldB,
            goldSample.ignored,
            goldSample.total,
            goldSample.evaluated,
            goldFilled ? "YES" : "NO"
        )
    )
    LogMessage(
        Format(
            "Resource threshold Elixir: median RGB=({}, {}, {}), "
                "ignored-light={}/{}, evaluated={}, result={}.",
            elixirR,
            elixirG,
            elixirB,
            elixirSample.ignored,
            elixirSample.total,
            elixirSample.evaluated,
            elixirFilled ? "YES" : "NO"
        )
    )
    LogMessage(
        Format(
            "Resource threshold Dark Elixir: median RGB=({}, {}, {}), "
                "ignored-light={}/{}, evaluated={}, result={}.",
            darkR,
            darkG,
            darkB,
            darkSample.ignored,
            darkSample.total,
            darkSample.evaluated,
            darkFilled ? "YES" : "NO"
        )
    )

    return {
        gold: goldFilled,
        elixir: elixirFilled,
        darkElixir: darkFilled
    }
}

IsGoblinFaceInADBFrame(framePath, centerX, centerY) {
    if (centerX <= 0 || centerY <= 0)
        return false
    offsets := [
        [0, 0], [-7, 0], [7, 0], [0, -7], [0, 7],
        [-5, -5], [5, -5], [-5, 5], [5, 5], [0, -4]
    ]
    greenCount := 0
    for pt in offsets {
        color := GetADBFramePixelColor(
            framePath,
            centerX + pt[1],
            centerY + pt[2]
        )
        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF
        if (g > r && g > b + 15 && g >= 80)
            greenCount += 1
    }
    return greenCount >= 4
}

IsAttackButtonInADBFrame(framePath, x, y) {
    color := GetADBFramePixelColor(framePath, x, y)
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    return IsAttackBtnColor(r, g, b)
}

IsWarLogoInADBFrame(framePath) {
    global WarLogoX, WarLogoY, MVLogoX, MVLogoY
    targetX := WarLogoX > 0 ? WarLogoX : MVLogoX
    targetY := WarLogoY > 0 ? WarLogoY : MVLogoY
    offsets := [
        {x: 0, y: 0},
        {x: -20, y: -20},
        {x: 20, y: -20},
        {x: -20, y: 20},
        {x: 20, y: 20}
    ]
    for pt in offsets {
        color := GetADBFramePixelColor(
            framePath,
            targetX + pt.x,
            targetY + pt.y
        )
        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF
        if IsWarLogoColor(r, g, b)
            return true
    }
    return false
}

DetectVillageFromADBFrame(framePath) {
    global AttackBtnX, AttackBtnY, BBAttackBtnX, BBAttackBtnY
    mainAttack := IsAttackButtonInADBFrame(framePath, AttackBtnX - 45, AttackBtnY)
        || IsAttackButtonInADBFrame(framePath, AttackBtnX + 45, AttackBtnY)
    warLogo := IsWarLogoInADBFrame(framePath)
    if (mainAttack && warLogo)
        return "main"

    builderAttack := IsAttackButtonInADBFrame(
        framePath,
        BBAttackBtnX - 45,
        BBAttackBtnY
    ) || IsAttackButtonInADBFrame(
        framePath,
        BBAttackBtnX + 45,
        BBAttackBtnY
    )
    if (builderAttack && !warLogo)
        return "builder"
    return "battle"
}

AreCloudsPresentInADBFrame(framePath) {
    global CloudPt1X, CloudPt1Y, CloudPt2X, CloudPt2Y
    global CloudPt3X, CloudPt3Y, CloudPt4X, CloudPt4Y, CloudGreyTolerance
    greyCount := 0
    for point in [
        {x: CloudPt1X, y: CloudPt1Y},
        {x: CloudPt2X, y: CloudPt2Y},
        {x: CloudPt3X, y: CloudPt3Y},
        {x: CloudPt4X, y: CloudPt4Y}
    ] {
        color := GetADBFramePixelColor(framePath, point.x, point.y)
        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF
        if (r >= 120
            && Abs(r - g) <= CloudGreyTolerance
            && Abs(g - b) <= CloudGreyTolerance
            && Abs(r - b) <= CloudGreyTolerance)
            greyCount += 1
    }
    return greyCount >= 3
}

IsBrown(clientX, clientY) {
    try {
        color := GetADBPixelColor(clientX, clientY)
        actualHex := Integer(color)
        r := (actualHex >> 16) & 0xFF
        g := (actualHex >> 8) & 0xFF
        b := actualHex & 0xFF
        return (r > g) && (g > b) && (r - b >= 30) && (g - b >= 10) && (r >= 70 && r <= 250)
    } catch {
        return false
    }
}

IsGrey(clientX, clientY, tolerance := 15) {
    try {
        color := GetADBPixelColor(clientX, clientY)
        actualHex := Integer(color)
        r := (actualHex >> 16) & 0xFF
        g := (actualHex >> 8) & 0xFF
        b := actualHex & 0xFF
        return (r >= 120) && (Abs(r - g) <= tolerance) && (Abs(g - b) <= tolerance) && (Abs(r - b) <= tolerance)
    } catch {
        return false
    }
}

ColorMatches(clientX, clientY, targetColorRGB, tolerance := 20) {
    try {
        color := GetADBPixelColor(clientX, clientY)
        actualHex := Integer(color)
        tr := (targetColorRGB >> 16) & 0xFF
        tg := (targetColorRGB >> 8) & 0xFF
        tb := targetColorRGB & 0xFF
        ar := (actualHex >> 16) & 0xFF
        ag := (actualHex >> 8) & 0xFF
        ab := actualHex & 0xFF
        diffR := Abs(tr - ar)
        diffG := Abs(tg - ag)
        diffB := Abs(tb - ab)
        return (diffR <= tolerance) && (diffG <= tolerance) && (diffB <= tolerance)
    } catch {
        return false
    }
}

EnsureADBActionReady() {
    result := EnsureADBConnection()
    if !result.Ok
        LogMessage("ADB: " result.Message)
    return result
}

IsClashForeground(serial) {
    global ADB_TARGET_PACKAGE
    result := RunADB('-s ' QuoteADBArgument(serial) ' shell dumpsys activity activities', true)
    if !result.Ok
        return false
    return RegExMatch(result.Output, "im)^\s*(topResumedActivity|mResumedActivity|ResumedActivity).*" ADB_TARGET_PACKAGE "/")
}

RunADBInteractionCommand(arguments) {
    global ADBConnectionSerial, ADBHelperSerial, ADBDisplaySerial
    captureOutput := InStr(arguments, " am instrument ") > 0
    result := RunADB(arguments, captureOutput)
    if !result.Ok {
        ADBConnectionSerial := ""
        ADBHelperSerial := ""
        ADBDisplaySerial := ""
        throw Error(FormatADBResult(result))
    }
    if captureOutput && (InStr(result.Output, "Pinch failed:") || !InStr(result.Output, "Pinch injected successfully."))
        throw Error(FormatADBResult(result))
    return result
}

SleepADBInteractionJitter(milliseconds) {
    if (milliseconds > 0)
        Sleep(milliseconds)
}

RandomADBInteractionInt(minimum, maximum) {
    return Random(minimum, maximum)
}

CreateLiveADBClientInteraction() {
    ready := EnsureADBActionReady()
    if !ready.Ok
        throw Error(ready.Message)
    viewportState := ValidateADBViewportRuntime()
    if !viewportState.Ok
        throw Error(viewportState.Message)
    return CreateADBClientInteraction(
        ready.Serial,
        RunADBInteractionCommand,
        SleepADBInteractionJitter,
        RandomADBInteractionInt
    )
}

WaitForADBActionPreDelay(intendedDelayMs) {
    timing := GetADBActionTiming(intendedDelayMs)
    if (timing.PreDelay > 0)
        Sleep(timing.PreDelay)
    return timing.PreDelay
}

RunADBTapAt(clientX, clientY, intendedDelayMs := 0) {
    try {
        interaction := CreateLiveADBClientInteraction()
        WaitForADBActionPreDelay(intendedDelayMs)
        point := interaction.Tap(clientX, clientY, intendedDelayMs)
        return point
    } catch as err {
        LogMessage("ADB tap failed: " err.Message)
        return false
    }
}

RunADBClearTapAt(clientX, clientY, intendedDelayMs := 0) {
    try {
        interaction := CreateLiveADBClientInteraction()
        interaction.ClearTap(
            clientX,
            clientY,
            intendedDelayMs,
            WaitForADBActionPreDelay
        )
        return true
    } catch as err {
        LogMessage("ADB clear tap failed: " err.Message)
        return false
    }
}

RunADBShiftedPlacementAt(clientX, clientY, adbShiftPixels, intendedDelayMs := 0) {
    try {
        interaction := CreateLiveADBClientInteraction()
        WaitForADBActionPreDelay(intendedDelayMs)
        interaction.PlaceShiftedTowardCenter(
            clientX,
            clientY,
            adbShiftPixels,
            intendedDelayMs
        )
        return true
    } catch as err {
        LogMessage("ADB shifted placement failed: " err.Message)
        return false
    }
}

RunADBSwipeAt(startClientX, startClientY, endClientX, endClientY, durationMs := 200, intendedDelayMs := 0) {
    try {
        interaction := CreateLiveADBClientInteraction()
        WaitForADBActionPreDelay(intendedDelayMs)
        interaction.Swipe(
            startClientX,
            startClientY,
            endClientX,
            endClientY,
            durationMs,
            intendedDelayMs
        )
        return true
    } catch as err {
        LogMessage("ADB swipe failed: " err.Message)
        return false
    }
}

IsADBPackageInstalled(serial, packageName) {
    result := RunADB('-s ' QuoteADBArgument(serial) ' shell pm path ' QuoteADBArgument(packageName), true)
    return result.Ok && InStr(result.Output, "package:")
}

InstallADBHelper(serial, apkPath, packageName) {
    if IsADBPackageInstalled(serial, packageName)
        return
    if !FileExist(apkPath)
        throw Error("Pinch helper APK is missing: " apkPath)
    result := RunADB('-s ' QuoteADBArgument(serial) ' install -r ' QuoteADBArgument(apkPath), true)
    if !result.Ok || !InStr(result.Output, "Success")
        throw Error("Could not install pinch helper. " FormatADBResult(result))
}

EnsureADBPinchHelper(serial) {
    global ADBHelperSerial, ADB_PINCH_TARGET_APK, ADB_PINCH_INSTRUMENTATION_APK
    global ADB_PINCH_TARGET_PACKAGE, ADB_PINCH_INSTRUMENTATION_PACKAGE
    if (ADBHelperSerial == serial)
        return true
    InstallADBHelper(serial, ADB_PINCH_TARGET_APK, ADB_PINCH_TARGET_PACKAGE)
    InstallADBHelper(serial, ADB_PINCH_INSTRUMENTATION_APK, ADB_PINCH_INSTRUMENTATION_PACKAGE)
    ADBHelperSerial := serial
    return true
}

RunADBPinchAt(centerClientX, centerClientY, intendedDelayMs := 0) {
    try {
        ready := EnsureADBActionReady()
        if !ready.Ok
            return false
        EnsureADBPinchHelper(ready.Serial)
        interaction := CreateLiveADBClientInteraction()
        WaitForADBActionPreDelay(intendedDelayMs)
        interaction.Pinch(centerClientX, centerClientY, 200, 45, 200, intendedDelayMs)
        return true
    } catch as err {
        LogMessage("ADB pinch failed: " err.Message)
        return false
    }
}

; ==============================================================================
; CONFIGURATION LOADING AND SAVING
; ==============================================================================
LoadConfig() {
    global TargetWindowTitle, ButtonDelta, DeployDelta, TransitionDelay, BattleLoadDelay
    global MinGold, MinElixir, EnableLootSearch, EnableWallUpgrade, UpgradeConfirmX, UpgradeConfirmY
    global AttackBtnX, AttackBtnY, FindMatchBtnX, FindMatchBtnY, AttackStartBtnX, AttackStartBtnY
    global ReturnHomeClickX, ReturnHomeClickY, ReturnHomeColor, ReturnHomeTolerance
    global BBAttackBtnX, BBAttackBtnY, BBFindMatchBtnX, BBFindMatchBtnY
    global BBStar1X, BBStar1Y, BBStar2X, BBStar2Y, BBStar3X, BBStar3Y, BBStarColor
    global WarLogoX, WarLogoY, WarLogoColor
    global BuilderFaceX, BuilderFaceY, BuilderMenuBottomX, BuilderMenuBottomY, LabFaceX, LabFaceY, UpgradeConfirmX, UpgradeConfirmY
    global DarkElixirBarThreshX, DarkElixirBarThreshY, GoldBarThreshX, GoldBarThreshY, ElixirBarThreshX, ElixirBarThreshY
    global GoldAreaX, GoldAreaY, GoldAreaW, GoldAreaH
    global ElixirAreaX, ElixirAreaY, ElixirAreaW, ElixirAreaH
    global GoldIconX, GoldIconY, ElixirIconX, ElixirIconY
    global LootCropOffsetX, LootCropOffsetY, LootCropW, LootCropH
    global NextMatchBtnX, NextMatchBtnY
    global UpgradeMoreBtnX, UpgradeMoreBtnY, AddWall1X, AddWall1Y, RemoveWallX, RemoveWallY, GoldUpgradeX, GoldUpgradeY, ElixirUpgradeX, ElixirUpgradeY
    global CloudPt1X, CloudPt1Y, CloudPt2X, CloudPt2Y, CloudPt3X, CloudPt3Y, CloudPt4X, CloudPt4Y, CloudGreyTolerance
    global CollectorCoords
    global Troop1Count, Troop2Count, Troop3Count
    global Side1StartX, Side1StartY, Side1EndX, Side1EndY
    global Side2StartX, Side2StartY, Side2EndX, Side2EndY
    global Side3StartX, Side3StartY, Side3EndX, Side3EndY
    global Side4StartX, Side4StartY, Side4EndX, Side4EndY
    global Sides
    global BBSide1StartX, BBSide1StartY, BBSide1EndX, BBSide1EndY
    global BBSide2StartX, BBSide2StartY, BBSide2EndX, BBSide2EndY
    global BBSide3StartX, BBSide3StartY, BBSide3EndX, BBSide3EndY
    global BBSide4StartX, BBSide4StartY, BBSide4EndX, BBSide4EndY
    global BBSides
    global ADBProvider, BlueStacksSerial, GPGDE_PROVIDER, BLUESTACKS_PROVIDER
    global ADBMainCalibrationVersion, ADBBBCalibrationVersion
    global ADBViewportLeft, ADBViewportTop, ADBViewportRight, ADBViewportBottom
    global ADBViewportClientWidth, ADBViewportClientHeight, ADBViewportProvider, ADBViewportSerial, ADBViewportVersion
    global ClearTapX, ClearTapY
    TargetWindowTitle := IniRead("config.ini", "Settings", "TargetWindowTitle", "Clash of Clans")
    ButtonDelta := SafeInteger(IniRead("config.ini", "Settings", "ButtonDelta", ""), 5)
    DeployDelta := SafeInteger(IniRead("config.ini", "Settings", "DeployDelta", ""), 15)
    TransitionDelay := SafeInteger(IniRead("config.ini", "Settings", "TransitionDelay", ""), 500)
    BattleLoadDelay := SafeInteger(IniRead("config.ini", "Settings", "BattleLoadDelay", ""), 1500)
    BBClickCount := SafeInteger(IniRead("config.ini", "Settings", "BBClickCount", ""), 1)
    MinGold := SafeInteger(IniRead("config.ini", "Farming", "MinGold", ""), 500000)
    MinElixir := SafeInteger(IniRead("config.ini", "Farming", "MinElixir", ""), 500000)
    EnableLootSearch := IniRead("config.ini", "Farming", "EnableLootSearch", "1") == "1"
    EnableWallUpgrade := IniRead("config.ini", "Farming", "EnableWallUpgrade", "1") == "1"
    ADBProvider := IniRead("config.ini", "ADB", "Provider", GPGDE_PROVIDER)
    if (ADBProvider != GPGDE_PROVIDER && ADBProvider != BLUESTACKS_PROVIDER)
        ADBProvider := GPGDE_PROVIDER
    BlueStacksSerial := IniRead("config.ini", "ADB", "BlueStacksSerial", "127.0.0.1:5555")
    ADBMainCalibrationVersion := SafeInteger(IniRead("config.ini", "ADB", "MainCalibrationVersion", ""), 0)
    ADBBBCalibrationVersion := SafeInteger(IniRead("config.ini", "ADB", "BBCalibrationVersion", ""), 0)
    ADBViewportLeft := SafeInteger(IniRead("config.ini", "ADBViewport", "Left", ""), 0)
    ADBViewportTop := SafeInteger(IniRead("config.ini", "ADBViewport", "Top", ""), 0)
    ADBViewportRight := SafeInteger(IniRead("config.ini", "ADBViewport", "Right", ""), -1)
    ADBViewportBottom := SafeInteger(IniRead("config.ini", "ADBViewport", "Bottom", ""), -1)
    ADBViewportClientWidth := SafeInteger(IniRead("config.ini", "ADBViewport", "ClientWidth", ""), 0)
    ADBViewportClientHeight := SafeInteger(IniRead("config.ini", "ADBViewport", "ClientHeight", ""), 0)
    ADBViewportProvider := IniRead("config.ini", "ADBViewport", "Provider", "")
    ADBViewportSerial := IniRead("config.ini", "ADBViewport", "Serial", "")
    ADBViewportVersion := SafeInteger(IniRead("config.ini", "ADBViewport", "Version", ""), 0)
    defaultClearTapX := Round(
        ADBViewportLeft + (ADBViewportRight - ADBViewportLeft - 1) * 0.9522
    )
    defaultClearTapY := Round(
        ADBViewportTop + (ADBViewportBottom - ADBViewportTop - 1) * 0.383
    )
    ClearTapX := SafeInteger(
        IniRead("config.ini", "VisualTests", "ClearTapX", ""),
        defaultClearTapX
    )
    ClearTapY := SafeInteger(
        IniRead("config.ini", "VisualTests", "ClearTapY", ""),
        defaultClearTapY
    )
    try BlueStacksSerial := ValidateBlueStacksSerial(BlueStacksSerial)
    catch
        BlueStacksSerial := "127.0.0.1:5555"
    Troop1Count := SafeInteger(IniRead("config.ini", "Farming", "Troop1Count", ""), 14)
    Troop2Count := SafeInteger(IniRead("config.ini", "Farming", "Troop2Count", ""), 14)
    Troop3Count := SafeInteger(IniRead("config.ini", "Farming", "Troop3Count", ""), 14)
    AttackBtnX := SafeInteger(IniRead("config.ini", "Coordinates", "AttackBtnX", ""), 100)
    AttackBtnY := SafeInteger(IniRead("config.ini", "Coordinates", "AttackBtnY", ""), 970)
    FindMatchBtnX := SafeInteger(IniRead("config.ini", "Coordinates", "FindMatchBtnX", ""), 250)
    FindMatchBtnY := SafeInteger(IniRead("config.ini", "Coordinates", "FindMatchBtnY", ""), 750)
    AttackStartBtnX := SafeInteger(IniRead("config.ini", "Coordinates", "AttackStartBtnX", ""), 1630)
    AttackStartBtnY := SafeInteger(IniRead("config.ini", "Coordinates", "AttackStartBtnY", ""), 920)
    ReturnHomeClickX := SafeInteger(IniRead("config.ini", "Coordinates", "ReturnHomeClickX", ""), 960)
    ReturnHomeClickY := SafeInteger(IniRead("config.ini", "Coordinates", "ReturnHomeClickY", ""), 920)
    ReturnHomeColor := SafeInteger(IniRead("config.ini", "Coordinates", "ReturnHomeColor", ""), 0x5FA41A)
    ReturnHomeTolerance := SafeInteger(IniRead("config.ini", "Coordinates", "ReturnHomeTolerance", ""), 35)
    BBAttackBtnX := SafeInteger(IniRead("config.ini", "Coordinates", "BBAttackBtnX", ""), 100)
    BBAttackBtnY := SafeInteger(IniRead("config.ini", "Coordinates", "BBAttackBtnY", ""), 970)
    BBFindMatchBtnX := SafeInteger(IniRead("config.ini", "Coordinates", "BBFindMatchBtnX", ""), 250)
    BBFindMatchBtnY := SafeInteger(IniRead("config.ini", "Coordinates", "BBFindMatchBtnY", ""), 750)
    BBStar1X := SafeInteger(IniRead("config.ini", "Coordinates", "BBStar1X", ""), 960)
    BBStar1Y := SafeInteger(IniRead("config.ini", "Coordinates", "BBStar1Y", ""), 540)
    BBStar2X := SafeInteger(IniRead("config.ini", "Coordinates", "BBStar2X", ""), 960)
    BBStar2Y := SafeInteger(IniRead("config.ini", "Coordinates", "BBStar2Y", ""), 540)
    BBStar3X := SafeInteger(IniRead("config.ini", "Coordinates", "BBStar3X", ""), 960)
    BBStar3Y := SafeInteger(IniRead("config.ini", "Coordinates", "BBStar3Y", ""), 540)
    BBStarColor := SafeInteger(IniRead("config.ini", "Coordinates", "BBStarColor", ""), 0x000000)
    MVLogoX := SafeInteger(IniRead("config.ini", "Coordinates", "MVLogoX", ""), 100)
    MVLogoY := SafeInteger(IniRead("config.ini", "Coordinates", "MVLogoY", ""), 700)
    WarLogoX := MVLogoX
    WarLogoY := MVLogoY
    WarLogoColor := SafeInteger(IniRead("config.ini", "Coordinates", "MVLogoColor", ""), 0x000000)
    BuilderFaceX := SafeInteger(IniRead("config.ini", "Coordinates", "BuilderFaceX", ""), 960)
    BuilderFaceY := SafeInteger(IniRead("config.ini", "Coordinates", "BuilderFaceY", ""), 30)
    BuilderMenuBottomX := SafeInteger(IniRead("config.ini", "Coordinates", "BuilderMenuBottomX", ""), BuilderFaceX)
    BuilderMenuBottomY := SafeInteger(IniRead("config.ini", "Coordinates", "BuilderMenuBottomY", ""), 800)
    LabFaceX := SafeInteger(IniRead("config.ini", "Coordinates", "LabFaceX", ""), 960)
    LabFaceY := SafeInteger(IniRead("config.ini", "Coordinates", "LabFaceY", ""), 30)
    UpgradeConfirmX := SafeInteger(IniRead("config.ini", "Coordinates", "UpgradeConfirmX", ""), 960)
    UpgradeConfirmY := SafeInteger(IniRead("config.ini", "Coordinates", "UpgradeConfirmY", ""), 540)
    DarkElixirBarThreshX := SafeInteger(IniRead("config.ini", "Coordinates", "DarkElixirBarThreshX", ""), 0)
    DarkElixirBarThreshY := SafeInteger(IniRead("config.ini", "Coordinates", "DarkElixirBarThreshY", ""), 0)
    GoldBarThreshX := SafeInteger(IniRead("config.ini", "Coordinates", "GoldBarThreshX", ""), 1750)
    GoldBarThreshY := SafeInteger(IniRead("config.ini", "Coordinates", "GoldBarThreshY", ""), 100)
    ElixirBarThreshX := SafeInteger(IniRead("config.ini", "Coordinates", "ElixirBarThreshX", ""), 1750)
    ElixirBarThreshY := SafeInteger(IniRead("config.ini", "Coordinates", "ElixirBarThreshY", ""), 160)
    GoldAreaX := SafeInteger(IniRead("config.ini", "Coordinates", "GoldAreaX", ""), 50)
    GoldAreaY := SafeInteger(IniRead("config.ini", "Coordinates", "GoldAreaY", ""), 50)
    GoldAreaW := SafeInteger(IniRead("config.ini", "Coordinates", "GoldAreaW", ""), 150)
    GoldAreaH := SafeInteger(IniRead("config.ini", "Coordinates", "GoldAreaH", ""), 30)
    ElixirAreaX := SafeInteger(IniRead("config.ini", "Coordinates", "ElixirAreaX", ""), 50)
    ElixirAreaY := SafeInteger(IniRead("config.ini", "Coordinates", "ElixirAreaY", ""), 90)
    ElixirAreaW := SafeInteger(IniRead("config.ini", "Coordinates", "ElixirAreaW", ""), 150)
    ElixirAreaH := SafeInteger(IniRead("config.ini", "Coordinates", "ElixirAreaH", ""), 30)
    GoldIconX := SafeInteger(IniRead("config.ini", "Coordinates", "GoldIconX", ""), 45)
    GoldIconY := SafeInteger(IniRead("config.ini", "Coordinates", "GoldIconY", ""), 145)
    ElixirIconX := SafeInteger(IniRead("config.ini", "Coordinates", "ElixirIconX", ""), 45)
    ElixirIconY := SafeInteger(IniRead("config.ini", "Coordinates", "ElixirIconY", ""), 195)
    LootCropOffsetX := SafeInteger(IniRead("config.ini", "Settings", "LootCropOffsetX", ""), 20)
    LootCropOffsetY := SafeInteger(IniRead("config.ini", "Settings", "LootCropOffsetY", ""), -4)
    LootCropW := SafeInteger(IniRead("config.ini", "Settings", "LootCropW", ""), 240)
    LootCropH := SafeInteger(IniRead("config.ini", "Settings", "LootCropH", ""), 45)
    NextMatchBtnX := Integer(IniRead("config.ini", "Coordinates", "NextMatchBtnX", 1630))
    NextMatchBtnY := Integer(IniRead("config.ini", "Coordinates", "NextMatchBtnY", 850))
    UpgradeMoreBtnX := Integer(IniRead("config.ini", "Coordinates", "UpgradeMoreBtnX", 960))
    UpgradeMoreBtnY := Integer(IniRead("config.ini", "Coordinates", "UpgradeMoreBtnY", 850))
    AddWall1X := Integer(IniRead("config.ini", "Coordinates", "AddWall1X", 960))
    AddWall1Y := Integer(IniRead("config.ini", "Coordinates", "AddWall1Y", 800))
    RemoveWallX := Integer(IniRead("config.ini", "Coordinates", "RemoveWallX", 960))
    RemoveWallY := Integer(IniRead("config.ini", "Coordinates", "RemoveWallY", 800))
    GoldUpgradeX := Integer(IniRead("config.ini", "Coordinates", "GoldUpgradeX", 960))
    GoldUpgradeY := Integer(IniRead("config.ini", "Coordinates", "GoldUpgradeY", 800))
    ElixirUpgradeX := Integer(IniRead("config.ini", "Coordinates", "ElixirUpgradeX", 960))
    ElixirUpgradeY := Integer(IniRead("config.ini", "Coordinates", "ElixirUpgradeY", 800))
    CloudPt1X := Integer(IniRead("config.ini", "Coordinates", "CloudPt1X", 500))
    CloudPt1Y := Integer(IniRead("config.ini", "Coordinates", "CloudPt1Y", 300))
    CloudPt2X := Integer(IniRead("config.ini", "Coordinates", "CloudPt2X", 1420))
    CloudPt2Y := Integer(IniRead("config.ini", "Coordinates", "CloudPt2Y", 300))
    CloudPt3X := Integer(IniRead("config.ini", "Coordinates", "CloudPt3X", 500))
    CloudPt3Y := Integer(IniRead("config.ini", "Coordinates", "CloudPt3Y", 780))
    CloudPt4X := Integer(IniRead("config.ini", "Coordinates", "CloudPt4X", 1420))
    CloudPt4Y := Integer(IniRead("config.ini", "Coordinates", "CloudPt4Y", 780))
    CloudGreyTolerance := Integer(IniRead("config.ini", "Coordinates", "CloudGreyTolerance", 15))
    ; Load dynamic resource collectors list
    CollectorCoords := []
    collectorStr := IniRead("config.ini", "Coordinates", "CollectorCoords", "")
    if (collectorStr != "") {
        pairs := StrSplit(collectorStr, ";")
        for pair in pairs {
            if (pair == "")
                continue
            coords := StrSplit(pair, ",")
            if (coords.Length == 2) {
                CollectorCoords.Push({x: Integer(coords[1]), y: Integer(coords[2])})
            }
        }
    }
    Side1StartX := Integer(IniRead("config.ini", "Coordinates", "Side1StartX", 1750))
    Side1StartY := Integer(IniRead("config.ini", "Coordinates", "Side1StartY", 520))
    Side1EndX := Integer(IniRead("config.ini", "Coordinates", "Side1EndX", 1400))
    Side1EndY := Integer(IniRead("config.ini", "Coordinates", "Side1EndY", 800))
    Side2StartX := Integer(IniRead("config.ini", "Coordinates", "Side2StartX", 150))
    Side2StartY := Integer(IniRead("config.ini", "Coordinates", "Side2StartY", 510))
    Side2EndX := Integer(IniRead("config.ini", "Coordinates", "Side2EndX", 600))
    Side2EndY := Integer(IniRead("config.ini", "Coordinates", "Side2EndY", 850))
    Side3StartX := Integer(IniRead("config.ini", "Coordinates", "Side3StartX", 150))
    Side3StartY := Integer(IniRead("config.ini", "Coordinates", "Side3StartY", 510))
    Side3EndX := Integer(IniRead("config.ini", "Coordinates", "Side3EndX", 507))
    Side3EndY := Integer(IniRead("config.ini", "Coordinates", "Side3EndY", 230))
    Side4StartX := Integer(IniRead("config.ini", "Coordinates", "Side4StartX", 1131))
    Side4StartY := Integer(IniRead("config.ini", "Coordinates", "Side4StartY", 40))
    Side4EndX := Integer(IniRead("config.ini", "Coordinates", "Side4EndX", 1506))
    Side4EndY := Integer(IniRead("config.ini", "Coordinates", "Side4EndY", 312))
    Sides := [
        {startX: Side1StartX, startY: Side1StartY, endX: Side1EndX, endY: Side1EndY},
        {startX: Side2StartX, startY: Side2StartY, endX: Side2EndX, endY: Side2EndY},
        {startX: Side3StartX, startY: Side3StartY, endX: Side3EndX, endY: Side3EndY},
        {startX: Side4StartX, startY: Side4StartY, endX: Side4EndX, endY: Side4EndY}
    ]
    BBSide1StartX := Integer(IniRead("config.ini", "Coordinates", "BBSide1StartX", 1750))
    BBSide1StartY := Integer(IniRead("config.ini", "Coordinates", "BBSide1StartY", 520))
    BBSide1EndX := Integer(IniRead("config.ini", "Coordinates", "BBSide1EndX", 1400))
    BBSide1EndY := Integer(IniRead("config.ini", "Coordinates", "BBSide1EndY", 800))
    BBSide2StartX := Integer(IniRead("config.ini", "Coordinates", "BBSide2StartX", 150))
    BBSide2StartY := Integer(IniRead("config.ini", "Coordinates", "BBSide2StartY", 510))
    BBSide2EndX := Integer(IniRead("config.ini", "Coordinates", "BBSide2EndX", 600))
    BBSide2EndY := Integer(IniRead("config.ini", "Coordinates", "BBSide2EndY", 850))
    BBSide3StartX := Integer(IniRead("config.ini", "Coordinates", "BBSide3StartX", 150))
    BBSide3StartY := Integer(IniRead("config.ini", "Coordinates", "BBSide3StartY", 510))
    BBSide3EndX := Integer(IniRead("config.ini", "Coordinates", "BBSide3EndX", 507))
    BBSide3EndY := Integer(IniRead("config.ini", "Coordinates", "BBSide3EndY", 230))
    BBSide4StartX := Integer(IniRead("config.ini", "Coordinates", "BBSide4StartX", 1131))
    BBSide4StartY := Integer(IniRead("config.ini", "Coordinates", "BBSide4StartY", 40))
    BBSide4EndX := Integer(IniRead("config.ini", "Coordinates", "BBSide4EndX", 1506))
    BBSide4EndY := Integer(IniRead("config.ini", "Coordinates", "BBSide4EndY", 312))
    BBSides := [
        {startX: BBSide1StartX, startY: BBSide1StartY, endX: BBSide1EndX, endY: BBSide1EndY},
        {startX: BBSide2StartX, startY: BBSide2StartY, endX: BBSide2EndX, endY: BBSide2EndY},
        {startX: BBSide3StartX, startY: BBSide3StartY, endX: BBSide3EndX, endY: BBSide3EndY},
        {startX: BBSide4StartX, startY: BBSide4StartY, endX: BBSide4EndX, endY: BBSide4EndY}
    ]
}
SaveConfig() {
    global TargetWindowTitle, ButtonDelta, DeployDelta, TransitionDelay, BattleLoadDelay
    global MinGold, MinElixir, EnableLootSearch, EnableWallUpgrade, UpgradeConfirmX, UpgradeConfirmY
    global AttackBtnX, AttackBtnY, FindMatchBtnX, FindMatchBtnY, AttackStartBtnX, AttackStartBtnY
    global ReturnHomeClickX, ReturnHomeClickY, ReturnHomeColor, ReturnHomeTolerance
    global BBAttackBtnX, BBAttackBtnY, BBFindMatchBtnX, BBFindMatchBtnY
    global BBStar1X, BBStar1Y, BBStar2X, BBStar2Y, BBStar3X, BBStar3Y, BBStarColor
    global BuilderFaceX, BuilderFaceY, BuilderMenuBottomX, BuilderMenuBottomY, LabFaceX, LabFaceY, UpgradeConfirmX, UpgradeConfirmY
    global DarkElixirBarThreshX, DarkElixirBarThreshY, GoldBarThreshX, GoldBarThreshY, ElixirBarThreshX, ElixirBarThreshY
    global GoldAreaX, GoldAreaY, GoldAreaW, GoldAreaH
    global ElixirAreaX, ElixirAreaY, ElixirAreaW, ElixirAreaH
    global GoldIconX, GoldIconY, ElixirIconX, ElixirIconY
    global LootCropOffsetX, LootCropOffsetY, LootCropW, LootCropH
    global NextMatchBtnX, NextMatchBtnY
    global UpgradeMoreBtnX, UpgradeMoreBtnY, AddWall1X, AddWall1Y, RemoveWallX, RemoveWallY, GoldUpgradeX, GoldUpgradeY, ElixirUpgradeX, ElixirUpgradeY
    global CloudPt1X, CloudPt1Y, CloudPt2X, CloudPt2Y, CloudPt3X, CloudPt3Y, CloudPt4X, CloudPt4Y, CloudGreyTolerance
    global CollectorCoords
    global Troop1Count, Troop2Count, Troop3Count
    global Side1StartX, Side1StartY, Side1EndX, Side1EndY
    global Side2StartX, Side2StartY, Side2EndX, Side2EndY
    global Side3StartX, Side3StartY, Side3EndX, Side3EndY
    global Side4StartX, Side4StartY, Side4EndX, Side4EndY
    global BBSide1StartX, BBSide1StartY, BBSide1EndX, BBSide1EndY
    global BBSide2StartX, BBSide2StartY, BBSide2EndX, BBSide2EndY
    global BBSide3StartX, BBSide3StartY, BBSide3EndX, BBSide3EndY
    global BBSide4StartX, BBSide4StartY, BBSide4EndX, BBSide4EndY
    global ADBProvider, BlueStacksSerial, ADBMainCalibrationVersion, ADBBBCalibrationVersion
    global ADBViewportLeft, ADBViewportTop, ADBViewportRight, ADBViewportBottom
    global ADBViewportClientWidth, ADBViewportClientHeight, ADBViewportProvider, ADBViewportSerial, ADBViewportVersion
    IniWrite(TargetWindowTitle, "config.ini", "Settings", "TargetWindowTitle")
    IniWrite(ButtonDelta, "config.ini", "Settings", "ButtonDelta")
    IniWrite(DeployDelta, "config.ini", "Settings", "DeployDelta")
    IniWrite(TransitionDelay, "config.ini", "Settings", "TransitionDelay")
    IniWrite(BattleLoadDelay, "config.ini", "Settings", "BattleLoadDelay")
    IniWrite(BBClickCount, "config.ini", "Settings", "BBClickCount")
    IniWrite(ADBProvider, "config.ini", "ADB", "Provider")
    IniWrite(BlueStacksSerial, "config.ini", "ADB", "BlueStacksSerial")
    IniWrite(ADBMainCalibrationVersion, "config.ini", "ADB", "MainCalibrationVersion")
    IniWrite(ADBBBCalibrationVersion, "config.ini", "ADB", "BBCalibrationVersion")
    IniWrite(ADBViewportLeft, "config.ini", "ADBViewport", "Left")
    IniWrite(ADBViewportTop, "config.ini", "ADBViewport", "Top")
    IniWrite(ADBViewportRight, "config.ini", "ADBViewport", "Right")
    IniWrite(ADBViewportBottom, "config.ini", "ADBViewport", "Bottom")
    IniWrite(ADBViewportClientWidth, "config.ini", "ADBViewport", "ClientWidth")
    IniWrite(ADBViewportClientHeight, "config.ini", "ADBViewport", "ClientHeight")
    IniWrite(ADBViewportProvider, "config.ini", "ADBViewport", "Provider")
    IniWrite(ADBViewportSerial, "config.ini", "ADBViewport", "Serial")
    IniWrite(ADBViewportVersion, "config.ini", "ADBViewport", "Version")
    IniWrite(MinGold, "config.ini", "Farming", "MinGold")
    IniWrite(MinElixir, "config.ini", "Farming", "MinElixir")
    IniWrite(EnableLootSearch ? "1" : "0", "config.ini", "Farming", "EnableLootSearch")
    IniWrite(EnableWallUpgrade ? "1" : "0", "config.ini", "Farming", "EnableWallUpgrade")
    IniWrite(Troop1Count, "config.ini", "Farming", "Troop1Count")
    IniWrite(Troop2Count, "config.ini", "Farming", "Troop2Count")
    IniWrite(Troop3Count, "config.ini", "Farming", "Troop3Count")
    IniWrite(AttackBtnX, "config.ini", "Coordinates", "AttackBtnX")
    IniWrite(AttackBtnY, "config.ini", "Coordinates", "AttackBtnY")
    IniWrite(FindMatchBtnX, "config.ini", "Coordinates", "FindMatchBtnX")
    IniWrite(FindMatchBtnY, "config.ini", "Coordinates", "FindMatchBtnY")
    IniWrite(AttackStartBtnX, "config.ini", "Coordinates", "AttackStartBtnX")
    IniWrite(AttackStartBtnY, "config.ini", "Coordinates", "AttackStartBtnY")
    IniWrite(ReturnHomeClickX, "config.ini", "Coordinates", "ReturnHomeClickX")
    IniWrite(ReturnHomeClickY, "config.ini", "Coordinates", "ReturnHomeClickY")
    IniWrite(Format("0x{:06X}", ReturnHomeColor), "config.ini", "Coordinates", "ReturnHomeColor")
    IniWrite(ReturnHomeTolerance, "config.ini", "Coordinates", "ReturnHomeTolerance")
    IniWrite(BBAttackBtnX, "config.ini", "Coordinates", "BBAttackBtnX")
    IniWrite(BBAttackBtnY, "config.ini", "Coordinates", "BBAttackBtnY")
    IniWrite(BBFindMatchBtnX, "config.ini", "Coordinates", "BBFindMatchBtnX")
    IniWrite(BBFindMatchBtnY, "config.ini", "Coordinates", "BBFindMatchBtnY")
    IniWrite(BBStar1X, "config.ini", "Coordinates", "BBStar1X")
    IniWrite(BBStar1Y, "config.ini", "Coordinates", "BBStar1Y")
    IniWrite(BBStar2X, "config.ini", "Coordinates", "BBStar2X")
    IniWrite(BBStar2Y, "config.ini", "Coordinates", "BBStar2Y")
    IniWrite(BBStar3X, "config.ini", "Coordinates", "BBStar3X")
    IniWrite(BBStar3Y, "config.ini", "Coordinates", "BBStar3Y")
    IniWrite(Format("0x{:06X}", BBStarColor), "config.ini", "Coordinates", "BBStarColor")
    IniWrite(WarLogoX, "config.ini", "Coordinates", "MVLogoX")
    IniWrite(WarLogoY, "config.ini", "Coordinates", "MVLogoY")
    IniWrite(Format("0x{:06X}", WarLogoColor), "config.ini", "Coordinates", "MVLogoColor")
    IniWrite(BuilderFaceX, "config.ini", "Coordinates", "BuilderFaceX")
    IniWrite(BuilderFaceY, "config.ini", "Coordinates", "BuilderFaceY")
    IniWrite(BuilderMenuBottomX, "config.ini", "Coordinates", "BuilderMenuBottomX")
    IniWrite(BuilderMenuBottomY, "config.ini", "Coordinates", "BuilderMenuBottomY")
    IniWrite(LabFaceX, "config.ini", "Coordinates", "LabFaceX")
    IniWrite(LabFaceY, "config.ini", "Coordinates", "LabFaceY")
    IniWrite(UpgradeConfirmX, "config.ini", "Coordinates", "UpgradeConfirmX")
    IniWrite(UpgradeConfirmY, "config.ini", "Coordinates", "UpgradeConfirmY")
    IniWrite(DarkElixirBarThreshX, "config.ini", "Coordinates", "DarkElixirBarThreshX")
    IniWrite(DarkElixirBarThreshY, "config.ini", "Coordinates", "DarkElixirBarThreshY")
    IniWrite(GoldBarThreshX, "config.ini", "Coordinates", "GoldBarThreshX")
    IniWrite(GoldBarThreshY, "config.ini", "Coordinates", "GoldBarThreshY")
    IniWrite(ElixirBarThreshX, "config.ini", "Coordinates", "ElixirBarThreshX")
    IniWrite(ElixirBarThreshY, "config.ini", "Coordinates", "ElixirBarThreshY")
    IniWrite(GoldAreaX, "config.ini", "Coordinates", "GoldAreaX")
    IniWrite(GoldAreaY, "config.ini", "Coordinates", "GoldAreaY")
    IniWrite(GoldAreaW, "config.ini", "Coordinates", "GoldAreaW")
    IniWrite(GoldAreaH, "config.ini", "Coordinates", "GoldAreaH")
    IniWrite(ElixirAreaX, "config.ini", "Coordinates", "ElixirAreaX")
    IniWrite(ElixirAreaY, "config.ini", "Coordinates", "ElixirAreaY")
    IniWrite(ElixirAreaW, "config.ini", "Coordinates", "ElixirAreaW")
    IniWrite(ElixirAreaH, "config.ini", "Coordinates", "ElixirAreaH")
    IniWrite(GoldIconX, "config.ini", "Coordinates", "GoldIconX")
    IniWrite(GoldIconY, "config.ini", "Coordinates", "GoldIconY")
    IniWrite(ElixirIconX, "config.ini", "Coordinates", "ElixirIconX")
    IniWrite(ElixirIconY, "config.ini", "Coordinates", "ElixirIconY")
    IniWrite(LootCropOffsetX, "config.ini", "Settings", "LootCropOffsetX")
    IniWrite(LootCropOffsetY, "config.ini", "Settings", "LootCropOffsetY")
    IniWrite(LootCropW, "config.ini", "Settings", "LootCropW")
    IniWrite(LootCropH, "config.ini", "Settings", "LootCropH")
    IniWrite(NextMatchBtnX, "config.ini", "Coordinates", "NextMatchBtnX")
    IniWrite(NextMatchBtnY, "config.ini", "Coordinates", "NextMatchBtnY")
    IniWrite(UpgradeMoreBtnX, "config.ini", "Coordinates", "UpgradeMoreBtnX")
    IniWrite(UpgradeMoreBtnY, "config.ini", "Coordinates", "UpgradeMoreBtnY")
    IniWrite(AddWall1X, "config.ini", "Coordinates", "AddWall1X")
    IniWrite(AddWall1Y, "config.ini", "Coordinates", "AddWall1Y")
    IniWrite(RemoveWallX, "config.ini", "Coordinates", "RemoveWallX")
    IniWrite(RemoveWallY, "config.ini", "Coordinates", "RemoveWallY")
    IniWrite(GoldUpgradeX, "config.ini", "Coordinates", "GoldUpgradeX")
    IniWrite(GoldUpgradeY, "config.ini", "Coordinates", "GoldUpgradeY")
    IniWrite(ElixirUpgradeX, "config.ini", "Coordinates", "ElixirUpgradeX")
    IniWrite(ElixirUpgradeY, "config.ini", "Coordinates", "ElixirUpgradeY")
    IniWrite(CloudPt1X, "config.ini", "Coordinates", "CloudPt1X")
    IniWrite(CloudPt1Y, "config.ini", "Coordinates", "CloudPt1Y")
    IniWrite(CloudPt2X, "config.ini", "Coordinates", "CloudPt2X")
    IniWrite(CloudPt2Y, "config.ini", "Coordinates", "CloudPt2Y")
    IniWrite(CloudPt3X, "config.ini", "Coordinates", "CloudPt3X")
    IniWrite(CloudPt3Y, "config.ini", "Coordinates", "CloudPt3Y")
    IniWrite(CloudPt4X, "config.ini", "Coordinates", "CloudPt4X")
    IniWrite(CloudPt4Y, "config.ini", "Coordinates", "CloudPt4Y")
    IniWrite(CloudGreyTolerance, "config.ini", "Coordinates", "CloudGreyTolerance")
    IniWrite(Side1StartX, "config.ini", "Coordinates", "Side1StartX")
    IniWrite(Side1StartY, "config.ini", "Coordinates", "Side1StartY")
    IniWrite(Side1EndX, "config.ini", "Coordinates", "Side1EndX")
    IniWrite(Side1EndY, "config.ini", "Coordinates", "Side1EndY")
    IniWrite(Side2StartX, "config.ini", "Coordinates", "Side2StartX")
    IniWrite(Side2StartY, "config.ini", "Coordinates", "Side2StartY")
    IniWrite(Side2EndX, "config.ini", "Coordinates", "Side2EndX")
    IniWrite(Side2EndY, "config.ini", "Coordinates", "Side2EndY")
    IniWrite(Side3StartX, "config.ini", "Coordinates", "Side3StartX")
    IniWrite(Side3StartY, "config.ini", "Coordinates", "Side3StartY")
    IniWrite(Side3EndX, "config.ini", "Coordinates", "Side3EndX")
    IniWrite(Side3EndY, "config.ini", "Coordinates", "Side3EndY")
    IniWrite(Side4StartX, "config.ini", "Coordinates", "Side4StartX")
    IniWrite(Side4StartY, "config.ini", "Coordinates", "Side4StartY")
    IniWrite(Side4EndX, "config.ini", "Coordinates", "Side4EndX")
    IniWrite(Side4EndY, "config.ini", "Coordinates", "Side4EndY")
    IniWrite(BBSide1StartX, "config.ini", "Coordinates", "BBSide1StartX")
    IniWrite(BBSide1StartY, "config.ini", "Coordinates", "BBSide1StartY")
    IniWrite(BBSide1EndX, "config.ini", "Coordinates", "BBSide1EndX")
    IniWrite(BBSide1EndY, "config.ini", "Coordinates", "BBSide1EndY")
    IniWrite(BBSide2StartX, "config.ini", "Coordinates", "BBSide2StartX")
    IniWrite(BBSide2StartY, "config.ini", "Coordinates", "BBSide2StartY")
    IniWrite(BBSide2EndX, "config.ini", "Coordinates", "BBSide2EndX")
    IniWrite(BBSide2EndY, "config.ini", "Coordinates", "BBSide2EndY")
    IniWrite(BBSide3StartX, "config.ini", "Coordinates", "BBSide3StartX")
    IniWrite(BBSide3StartY, "config.ini", "Coordinates", "BBSide3StartY")
    IniWrite(BBSide3EndX, "config.ini", "Coordinates", "BBSide3EndX")
    IniWrite(BBSide3EndY, "config.ini", "Coordinates", "BBSide3EndY")
    IniWrite(BBSide4StartX, "config.ini", "Coordinates", "BBSide4StartX")
    IniWrite(BBSide4StartY, "config.ini", "Coordinates", "BBSide4StartY")
    IniWrite(BBSide4EndX, "config.ini", "Coordinates", "BBSide4EndX")
    IniWrite(BBSide4EndY, "config.ini", "Coordinates", "BBSide4EndY")
    collectorStr := ""
    for coord in CollectorCoords {
        collectorStr .= coord.x "," coord.y ";"
    }
    IniWrite(collectorStr, "config.ini", "Coordinates", "CollectorCoords")
}
; ==============================================================================
; USER INTERFACE
; ==============================================================================
CreateGUI() {
    global MyGui, EditWindow, EditBattleLoad, EditButtonDelta, EditDeployDelta
    global EditMinGold, EditMinElixir, CheckLootSearch, CheckWallUpgrade, TextCollectorCount
    global LogEdit, StatusText, StartBtn, PauseBtn, CalibrationText, EditBBClickCount
    global EditTroop1Count, EditTroop2Count, EditTroop3Count, DDHours, DDMinutes
    global EditADBProvider, EditBlueStacksSerial, ADBStatusText
    global ADBProvider, BlueStacksSerial, GPGDE_PROVIDER, BLUESTACKS_PROVIDER

    MyGui := Gui("+Resize +MinSize380x470", "CoC Bot Controller")
    ; Tab control
    Tab := MyGui.Add("Tab3", "w360 h440", ["Control", "Calibration", "Farming", "Settings", "ADB"])
    ; --- TAB 1: Control ---
    Tab.UseTab(1)
    MyGui.Add("Text", "x20 y50 w120 h20", "Target Window Title:")
    EditWindow := MyGui.Add("Edit", "x140 y48 w200 h20", TargetWindowTitle)
    StatusText := MyGui.Add("Text", "x20 y80 w320 h30 +Center", "STATUS: IDLE")
    StatusText.SetFont("s12 bold", "Segoe UI")
    StartBtn := MyGui.Add("Button", "x20 y120 w150 h40", "Start Bot (F1)")
    StartBtn.OnEvent("Click", (*) => UnifiedStart())
    PauseBtn := MyGui.Add("Button", "x190 y120 w150 h40", "Pause Bot (F2)")
    PauseBtn.OnEvent("Click", (*) => PauseBot())
    PauseBtn.Enabled := false
    MyGui.Add("GroupBox", "x20 y170 w320 h195", "Activity Log")
    LogEdit := MyGui.Add("Edit", "x30 y190 w300 h165 +ReadOnly +Multi +WantReturn", "")
    MyGui.Add("GroupBox", "x20 y375 w320 h65", "Auto-Stop Timer")
    MyGui.Add("Text", "x35 y398 w135 h20", "Stop Bot After (H : M):")
    hoursOpts := ["0"]
    Loop 24 {
        hoursOpts.Push(String(A_Index))
    }
    minsOpts := ["0"]
    Loop 59 {
        minsOpts.Push(String(A_Index))
    }
    DDHours := MyGui.Add("DropDownList", "x175 y395 w60 Choose1", hoursOpts)
    MyGui.Add("Text", "x240 y398 w10 h20 +Center", ":")
    DDMinutes := MyGui.Add("DropDownList", "x255 y395 w60 Choose1", minsOpts)

    ; --- TAB 2: Calibration ---
    Tab.UseTab(2)
    MyGui.Add("Text", "x20 y35 w320 h40", "Click a button below or use its shortcut to calibrate coordinates relative to the game window.")
    CalibStartBtn := MyGui.Add("Button", "x20 y75 w150 h35", "Main Calib (Ctrl+F1)")
    CalibStartBtn.OnEvent("Click", (*) => StartCalibration())
    CalibBBBtn := MyGui.Add("Button", "x180 y75 w150 h35", "BB Calib (Ctrl+F2)")
    CalibBBBtn.OnEvent("Click", (*) => StartBBCalibration())
    CalibrationText := MyGui.Add("Text", "x20 y120 w320 h100 +Border", "Calibration is inactive.`n`nClick a start button to begin.")
    CalibrationText.SetFont("s10", "Segoe UI")
    MyGui.Add("Text", "x20 y230 w320 h195", "Instructions:`nHover mouse over target and press SPACE.`n`nMain Steps (29 total):`n1-3. Storage Bar Thresholds`n4-6. Builder Face, Menu Bottom, Lab Face`n7-12. Wall Upgrade Controls`n13-16. War Logo and Attack Navigation`n17-19. Loot Areas and Next Match`n20-27. Sides 1-4 Start/End`n28. Return Home Button`n29. Collectors (press ENTER to finish).`n`nBB Steps (13 total):`n1-2. Attack, Find Match`n3-5. Star 1, 2, 3 Centers`n6-13. BB Sides 1-4 Start/End")
    ; --- TAB 3: Farming ---
    Tab.UseTab(3)
    MyGui.Add("GroupBox", "x20 y40 w320 h135", "Multiplayer Loot Search")
    CheckLootSearch := MyGui.Add("Checkbox", "x35 y65 w250 h20", "Enable Auto Loot Search")
    CheckLootSearch.Value := EnableLootSearch
    MyGui.Add("Text", "x35 y95 w150 h20", "Minimum Gold Limit:")
    EditMinGold := MyGui.Add("Edit", "x190 y93 w130 h20 Number", String(MinGold))
    MyGui.Add("Text", "x35 y125 w150 h20", "Minimum Elixir Limit:")
    EditMinElixir := MyGui.Add("Edit", "x190 y123 w130 h20 Number", String(MinElixir))
    MyGui.Add("GroupBox", "x20 y185 w320 h150", "Auto Wall Upgrader")
    CheckWallUpgrade := MyGui.Add("Checkbox", "x35 y210 w280 h20", "Enable Auto Wall Upgrade")
    CheckWallUpgrade.Value := EnableWallUpgrade
    MyGui.Add("Text", "x35 y240 w290 h80 +Wrap", "Upgrades cheapest walls dynamically. Before starting the upgrade sequence, it reads the pixel color at your calibrated Storage Bar Threshold points. Wall upgrading is only triggered if the bars have reached the yellow/pink color at those positions.")
    MyGui.Add("GroupBox", "x20 y345 w320 h60", "Resource Collection")
    MyGui.Add("Text", "x35 y370 w180 h20", "Calibrated Collectors:")
    TextCollectorCount := MyGui.Add("Text", "x220 y370 w80 h20", String(CollectorCoords.Length))
    TextCollectorCount.SetFont("bold")
    SaveBtnFarming := MyGui.Add("Button", "x20 y415 w320 h35", "Save Settings")
    SaveBtnFarming.OnEvent("Click", (*) => ApplyAndSaveSettings())
    ; --- TAB 4: Settings ---
    Tab.UseTab(4)
    MyGui.Add("GroupBox", "x20 y45 w320 h70", "Delays (milliseconds)")
    MyGui.Add("Text", "x35 y70 w180 h20", "Battle Load Delay:")
    EditBattleLoad := MyGui.Add("Edit", "x220 y68 w100 h20 Number", String(BattleLoadDelay))
    MyGui.Add("GroupBox", "x20 y120 w320 h60", "Builder Base Settings")
    MyGui.Add("Text", "x35 y145 w180 h20", "Clicks per Troop Slot:")
    EditBBClickCount := MyGui.Add("Edit", "x220 y143 w100 h20 Number", String(BBClickCount))
    MyGui.Add("GroupBox", "x20 y185 w320 h90", "Randomization Offsets (pixels)")
    MyGui.Add("Text", "x35 y210 w180 h20", "Button Click Delta (+/-):")
    EditButtonDelta := MyGui.Add("Edit", "x220 y208 w100 h20 Number", String(ButtonDelta))
    MyGui.Add("Text", "x35 y240 w180 h20", "Troop Deploy Delta (+/-):")
    EditDeployDelta := MyGui.Add("Edit", "x220 y238 w100 h20 Number", String(DeployDelta))
    MyGui.Add("GroupBox", "x20 y280 w320 h80", "Troop Deployment Clicks")
    MyGui.Add("Text", "x35 y305 w60 h20", "Troop 1:")
    EditTroop1Count := MyGui.Add("Edit", "x95 y303 w45 h20 Number", String(Troop1Count))
    MyGui.Add("Text", "x150 y305 w60 h20", "Troop 2:")
    EditTroop2Count := MyGui.Add("Edit", "x210 y303 w45 h20 Number", String(Troop2Count))
    MyGui.Add("Text", "x35 y335 w60 h20", "Troop 3:")
    EditTroop3Count := MyGui.Add("Edit", "x95 y333 w45 h20 Number", String(Troop3Count))
    SaveBtn := MyGui.Add("Button", "x20 y370 w320 h35", "Save Settings")
    SaveBtn.OnEvent("Click", (*) => ApplyAndSaveSettings())
    ; --- TAB 5: ADB ---
    Tab.UseTab(5)
    MyGui.Add("GroupBox", "x20 y45 w320 h150", "Single Emulator Target")
    MyGui.Add("Text", "x35 y70 w120 h20", "Emulator:")
    providerChoice := ADBProvider == BLUESTACKS_PROVIDER ? 2 : 1
    EditADBProvider := MyGui.Add("DropDownList", "x35 y92 w290 Choose" providerChoice, [GPGDE_PROVIDER, BLUESTACKS_PROVIDER])
    MyGui.Add("Text", "x35 y127 w120 h20", "BlueStacks serial:")
    EditBlueStacksSerial := MyGui.Add("Edit", "x155 y125 w170 h22", BlueStacksSerial)
    EditADBProvider.OnEvent("Change", OnADBProviderChanged)
    TestADBBtn := MyGui.Add("Button", "x35 y158 w135 h28", "Test Connection")
    TestADBBtn.OnEvent("Click", TestADBConnection)
    SaveADBBtn := MyGui.Add("Button", "x185 y158 w140 h28", "Save ADB Target")
    SaveADBBtn.OnEvent("Click", (*) => ApplyAndSaveSettings())
    MyGui.Add("GroupBox", "x20 y210 w320 h120", "Status")
    ADBStatusText := MyGui.Add("Text", "x35 y235 w290 h75 +Wrap", "Not tested. GPGDE uses localhost:6520. BlueStacks uses its configured local port.")
    MyGui.Add("Text", "x20 y350 w320 h60 +Wrap", "One emulator is controlled at a time. Multi-instance and simultaneous control are not supported yet.")
    OnADBProviderChanged()
    MyGui.OnEvent("Close", (*) => ExitApp())
    MyGui.Show("w380 h470")
}
LogMessage(message) {
    global LogEdit
    if !LogEdit
        return
    timeStr := FormatTime(, "HH:mm:ss")
    newLine := "[" timeStr "] " message "`r`n"

    totalLines := SendMessage(0x00BA, 0, 0, LogEdit) ; EM_GETLINECOUNT
    firstVisibleLine := SendMessage(0x00CE, 0, 0, LogEdit) ; EM_GETFIRSTVISIBLELINE
    wasAtBottom := (totalLines <= 1 || (totalLines - firstVisibleLine <= 14))

    currentText := LogEdit.Value
    lines := StrSplit(currentText, "`n")
    if lines.Length > 100 {
        newText := ""
        Loop 90 {
            newText .= lines[lines.Length - 90 + A_Index] "`n"
        }
        currentText := newText
    }
    LogEdit.Value := currentText . newLine

    if wasAtBottom {
        SendMessage(0x0115, 7, 0, LogEdit) ; SB_BOTTOM
    } else {
        SendMessage(0x00B6, 0, firstVisibleLine, LogEdit) ; EM_LINESCROLL
    }
}
ApplyAndSaveSettings() {
    global TargetWindowTitle, BattleLoadDelay, ButtonDelta, DeployDelta
    global MinGold, MinElixir, EnableLootSearch, EnableWallUpgrade, UpgradeConfirmX, UpgradeConfirmY
    global Troop1Count, Troop2Count, Troop3Count, BBClickCount
    global EditWindow, EditBattleLoad, EditButtonDelta, EditDeployDelta
    global EditMinGold, EditMinElixir, CheckLootSearch, CheckWallUpgrade
    global EditTroop1Count, EditTroop2Count, EditTroop3Count, EditBBClickCount
    global EditADBProvider, EditBlueStacksSerial, ADBProvider, BlueStacksSerial, GPGDE_PROVIDER
    global ADBConnectionSerial, ADBHelperSerial
    global ADBMainCalibrationVersion, ADBBBCalibrationVersion
    TargetWindowTitle := EditWindow.Value
    BBClickCount := Integer(EditBBClickCount.Value)
    BattleLoadDelay := Integer(EditBattleLoad.Value)
    ButtonDelta := Integer(EditButtonDelta.Value)
    DeployDelta := Integer(EditDeployDelta.Value)
    MinGold := Integer(EditMinGold.Value)
    MinElixir := Integer(EditMinElixir.Value)
    EnableLootSearch := CheckLootSearch.Value
    EnableWallUpgrade := CheckWallUpgrade.Value
    Troop1Count := Integer(EditTroop1Count.Value)
    Troop2Count := Integer(EditTroop2Count.Value)
    Troop3Count := Integer(EditTroop3Count.Value)
    newProvider := EditADBProvider.Text
    newSerial := newProvider == GPGDE_PROVIDER ? BlueStacksSerial : ValidateBlueStacksSerial(EditBlueStacksSerial.Value)
    if (newProvider != ADBProvider || newSerial != BlueStacksSerial) {
        ADBConnectionSerial := ""
        ADBHelperSerial := ""
        InvalidateADBViewport()
    }
    ADBProvider := newProvider
    BlueStacksSerial := newSerial
    SaveConfig()
    LogMessage("Settings saved successfully!")
    ShowToolTip("Settings saved!")
}

OnADBProviderChanged(*) {
    global EditADBProvider, EditBlueStacksSerial, GPGDE_PROVIDER, GPGDE_SERIAL, BlueStacksSerial
    if !EditADBProvider
        return
    isGPGDE := EditADBProvider.Text == GPGDE_PROVIDER
    EditBlueStacksSerial.Enabled := !isGPGDE
    EditBlueStacksSerial.Value := isGPGDE ? GPGDE_SERIAL : BlueStacksSerial
}

TestADBConnection(*) {
    global ADBProvider, BlueStacksSerial, EditADBProvider, EditBlueStacksSerial
    global ADBConnectionSerial, ADBHelperSerial, ADBDisplaySerial, ADBStatusText, GPGDE_PROVIDER
    global ADBMainCalibrationVersion, ADBBBCalibrationVersion
    try {
        newProvider := EditADBProvider.Text
        newSerial := newProvider == GPGDE_PROVIDER ? BlueStacksSerial : ValidateBlueStacksSerial(EditBlueStacksSerial.Value)
        if (newProvider != ADBProvider || newSerial != BlueStacksSerial) {
            InvalidateADBViewport()
        }
        ADBProvider := newProvider
        BlueStacksSerial := newSerial
        ADBConnectionSerial := ""
        ADBHelperSerial := ""
        ADBDisplaySerial := ""
        ADBStatusText.Value := "Testing connection..."
        result := EnsureADBConnection(true)
        if !result.Ok
            throw Error(result.Message)
        SaveConfig()
        if IsClashForeground(result.Serial)
            ADBStatusText.Value := "Connected to " result.Serial ". Clash of Clans is the foreground Android app."
        else
            ADBStatusText.Value := "Connected to " result.Serial ", but Clash of Clans is not the foreground Android app."
    } catch as err {
        ADBStatusText.Value := "Connection failed: " err.Message
    }
}
; ==============================================================================
; STATE CONTROL ACTIONS
; ==============================================================================
StartBot() {
    global IsRunning, StatusText, StartBtn, PauseBtn, TargetWindowTitle, DDHours, DDMinutes, TimerDurationMs, TimerStartTick

    if IsRunning {
        LogMessage("Bot is already running!")
        return
    }
    if !WinExist(TargetWindowTitle) {
        MsgBox("Please ensure the game window '" TargetWindowTitle "' is open before starting.", "Error", "Iconx")
        return
    }
    adbReady := EnsureADBConnection()
    if !adbReady.Ok {
        MsgBox(adbReady.Message, "ADB Error", "Iconx")
        return
    }
    IsRunning := true
    hrs := Integer(DDHours.Text)
    mins := Integer(DDMinutes.Text)
    TimerDurationMs := (hrs * 3600 + mins * 60) * 1000

    TimerStartTick := A_TickCount
    if (TimerDurationMs > 0) {
        LogMessage(Format("Auto-Stop Timer set for {}h {}m.", hrs, mins))
    } else {
        LogMessage("Auto-Stop Timer set to 0h 0m (Running indefinitely).")
    }
    StatusText.Text := "STATUS: RUNNING"
    StatusText.SetFont("cGreen")
    StartBtn.Enabled := false
    PauseBtn.Enabled := true
    LogMessage("Bot loop started.")
    SetTimer(StartBotLoop, -10) ; Start asynchronously

}
PauseBot() {
    global IsRunning, IsBBRunning, StatusText, StartBtn, PauseBtn
    SetTimer(UnifiedStart, 0)
    if !(IsRunning || IsBBRunning) {
        LogMessage("Bot is not running.")
        return
    }
    IsRunning := false
    IsBBRunning := false
    StatusText.Text := "STATUS: PAUSED"
    StatusText.SetFont("cFF9900")
    StartBtn.Enabled := true
    PauseBtn.Enabled := false
    LogMessage("Bot loop paused.")
}
; ==============================================================================
; INTERACTIVE CALIBRATION STATE MACHINE
; ==============================================================================
StartCalibration() {
    global IsCalibrating, CalibStep, TargetWindowTitle
    if IsCalibrating {
        CancelCalibration()
        return
    }
    if !WinExist(TargetWindowTitle) {
        MsgBox("Game window '" TargetWindowTitle "' must be open before calibrating.", "Calibration Error", "Iconx")
        return
    }
    WinActivate(TargetWindowTitle)
    try {
        display := GetADBDisplaySize()
        LogMessage(Format("ADB display detected at {}x{}. Main Calibration will now capture the Android viewport.",
            display.width, display.height))
    } catch as err {
        MsgBox("ADB display size could not be read: " err.Message, "Calibration Error", "Iconx")
        return
    }
    IsCalibrating := true
    CalibStep := 1
    LogMessage("Calibration started with the game window foregrounded once.")
    UpdateCalibrationUI()
}
CancelCalibration() {
    global IsCalibrating, CalibStep, CalibrationText, IsWaitingForReset
    IsCalibrating := false
    CalibStep := 0
    IsWaitingForReset := false
    SetTimer(RunCollectorReset, 0)
    SetTimer(RunSidesReset, 0)
    CalibrationText.Value := "Calibration cancelled.`n`nClick start to try again."
    LogMessage("Calibration cancelled.")
    ToolTip()
}
StartBBCalibration() {
    global IsCalibrating, IsBBCalibrating, BBCalibStep, TargetWindowTitle
    global ADBViewportLeft, ADBViewportTop, ADBViewportRight, ADBViewportBottom
    if IsCalibrating {
        MsgBox("Finish or cancel main calibration first.", "Calibration Error", "Iconx")
        return
    }
    if IsBBCalibrating {
        CancelBBCalibration()
        return
    }
    if !WinExist(TargetWindowTitle) {
        MsgBox("Game window '" TargetWindowTitle "' must be open before calibrating.", "Calibration Error", "Iconx")
        return
    }
    WinActivate(TargetWindowTitle)
    viewportState := ValidateADBViewportRuntime()
    if !viewportState.Ok {
        MsgBox(viewportState.Message, "Builder Base Calibration Error", "Iconx")
        return
    }
    try {
        display := GetADBDisplaySize()
        LogMessage(Format("BB calibration mapping: viewport ({}, {})-({}, {}) -> Android {}x{}.",
            ADBViewportLeft, ADBViewportTop, ADBViewportRight, ADBViewportBottom,
            display.width, display.height))
    } catch as err {
        MsgBox("ADB display size could not be read: " err.Message, "Calibration Error", "Iconx")
        return
    }
    IsBBCalibrating := true
    BBCalibStep := 1
    LogMessage("Builder Base Calibration started with the game window foregrounded once.")
    UpdateBBCalibrationUI()
}
CancelBBCalibration() {
    global IsBBCalibrating, BBCalibStep, CalibrationText
    IsBBCalibrating := false
    BBCalibStep := 0
    CalibrationText.Value := "BB Calibration cancelled.`n`nClick start to try again."
    LogMessage("BB Calibration cancelled.")
    ToolTip()
}
UpdateBBCalibrationUI() {
    global BBCalibStep, CalibrationText
    instructions := ""
    switch BBCalibStep {
        case 1:
            instructions := "Step 1/13: Builder Base Attack Button`n`nHover mouse over the 'Attack!' button in Builder Base and press SPACE."
        case 2:
            instructions := "Step 2/13: Builder Base Find Match Button`n`nHover mouse over the 'Find a Match!' button and press SPACE."
        case 3:
            instructions := "Step 3/13: Star 1 Center (Overall Damage Screen)`n`nHover mouse exactly over the center of the first star on the results screen and press SPACE."
        case 4:
            instructions := "Step 4/13: Star 2 Center`n`nHover mouse exactly over the center of the second star and press SPACE."
        case 5:
            instructions := "Step 5/13: Star 3 Center`n`nHover mouse exactly over the center of the third star and press SPACE."
        case 6:
            instructions := "Step 6/13: BB Side 1 (Bottom-Right) Start`n`nHover mouse over starting point of bottom-right deployment line and press SPACE."
        case 7:
            instructions := "Step 7/13: BB Side 1 (Bottom-Right) End`n`nHover mouse over ending point of bottom-right deployment line and press SPACE."
        case 8:
            instructions := "Step 8/13: BB Side 2 (Bottom-Left) Start`n`nHover mouse over starting point of bottom-left deployment line and press SPACE."
        case 9:
            instructions := "Step 9/13: BB Side 2 (Bottom-Left) End`n`nHover mouse over ending point of bottom-left deployment line and press SPACE."
        case 10:
            instructions := "Step 10/13: BB Side 3 (Top-Left) Start`n`nHover mouse over starting point of top-left deployment line and press SPACE."
        case 11:
            instructions := "Step 11/13: BB Side 3 (Top-Left) End`n`nHover mouse over ending point of top-left deployment line and press SPACE."
        case 12:
            instructions := "Step 12/13: BB Side 4 (Top-Right) Start`n`nHover mouse over starting point of top-right deployment line and press SPACE."
        case 13:
            instructions := "Step 13/13: BB Side 4 (Top-Right) End`n`nHover mouse over ending point of top-right deployment line and press SPACE.`n`nPress ENTER to finish and save."
    }
    CalibrationText.Value := instructions
    if (instructions != "") {
        ToolTip(instructions "`n`nPress ESC to cancel.")
    }
}
FinishBBCalibration() {
    global IsBBCalibrating, BBCalibStep, CalibrationText
    global ADBBBCalibrationVersion, ADB_COORDINATE_VERSION, BBSides
    IsBBCalibrating := false
    BBCalibStep := 0
    ADBBBCalibrationVersion := ADB_COORDINATE_VERSION
    SaveConfig()
    CalibrationText.Value := "Builder Base Calibration complete and saved!"
    LogMessage("Builder Base Calibration finished successfully.")
    ToolTip("Calibration saved!")
    SetTimer () => ToolTip(), -3000
}
RunCollectorReset() {
    global CalibStep, IsCalibrating, IsWaitingForReset, CollectorCoords, CalibrationText
    if !IsCalibrating || CalibStep != 31
        return
    ResetViewport()
    IsWaitingForReset := false
    instructions := "Step 31/31: Resource Collectors (Home Screen)`n`nHover over a Gold Mine, Elixir Collector, or DE Drill and press SPACE to record.`n`nCurrently added: " CollectorCoords.Length "`n`nPlease don't move the screen.`n`nPress ENTER to finish and save."
    CalibrationText.Value := instructions
    ToolTip(instructions "`n`nPress ESC to cancel.")
}
RunSidesReset() {
    global CalibStep, IsCalibrating, IsWaitingForReset, CalibrationText
    if !IsCalibrating || CalibStep != 22
        return
    ResetViewport()
    IsWaitingForReset := false
    instructions := "Step 22/31: Side 1 (Bottom-Right) Start Point`n`nHover mouse over the starting point of the Bottom-Right deployment line and press SPACE."
    CalibrationText.Value := instructions
    ToolTip(instructions "`n`nPress ESC to cancel.")
}
UpdateCalibrationUI() {
    global CalibStep, CalibrationText, CollectorCoords, IsWaitingForReset
    instructions := ""
    switch CalibStep {
        case 1:
            instructions := "Step 1/31: Android Viewport Top-Left`n`nHide the BlueStacks sidebar if applicable. Hover over the first visible pixel at the TOP-LEFT of the Android game picture, excluding emulator bars and black borders, then press SPACE."
        case 2:
            instructions := "Step 2/31: Android Viewport Bottom-Right`n`nWithout resizing or changing window mode, hover over the last visible pixel at the BOTTOM-RIGHT of the Android game picture, excluding emulator bars and black borders, then press SPACE."
        case 3:
            instructions := "Step 3/31: Dark Elixir Storage Bar Threshold Point (Home Screen)`n`nHover over your Dark Elixir storage bar at the point where you want lab upgrades to trigger (e.g. 85% full) and press SPACE."
        case 4:
            instructions := "Step 4/31: Elixir Storage Bar Threshold Point (Home Screen)`n`nHover over your Elixir storage bar at the point where you want wall/lab upgrades to trigger (e.g. 85% full) and press SPACE."
        case 5:
            instructions := "Step 5/31: Gold Storage Bar Threshold Point (Home Screen)`n`nHover over your Gold storage bar at the point where you want wall upgrades to trigger (e.g. 85% full) and press SPACE."
        case 6:
            instructions := "Step 6/31: Builder Face (Home Screen)`n`nHover mouse over the Builder's nose and press SPACE."
        case 7:
            instructions := "Step 7/31: Builder Menu Bottom`n`nClick the Builder Face to open the Builder menu. Hover over the bottom point where the upward drag should start and press SPACE. The ADB drag will use the Builder Face X and this point's Y."
        case 8:
            instructions := "Step 8/31: Lab Icon (Home Screen)`n`nClose the Builder menu, hover mouse over the Lab Icon (Rage Potion or Goblin Researcher) and press SPACE."
        case 9:
            instructions := "Step 9/31: Upgrade More Button (Wall Selected)`n`nHover mouse over the 'Upgrade More' button (first select a wall manually to show it) and press SPACE."
        case 10:
            instructions := "Step 10/31: Add Wall (+1) Button (Upgrade More Screen)`n`nHover mouse over the '+1 Add Wall' button (click 'Upgrade More' manually to show it) and press SPACE."
        case 11:
            instructions := "Step 11/31: Remove Wall (-1) Button (Upgrade More Screen)`n`nHover mouse over the '-1 Remove Wall' button and press SPACE."
        case 12:
            instructions := "Step 12/31: Gold Upgrade Button (Upgrade More Screen)`n`nHover mouse over the Gold Upgrade button (showing the gold hammer/cost) and press SPACE."
        case 13:
            instructions := "Step 13/31: Elixir Upgrade Button (Upgrade More Screen)`n`nHover mouse over the Elixir Upgrade button (showing the purple hammer/cost) and press SPACE."
        case 14:
            instructions := "Step 14/31: Upgrade Confirm Button (Upgrade Screen)`n`nHover mouse over the green 'Upgrade' confirmation button and press SPACE."
        case 15:
            instructions := "Step 15/31: War Logo (Home Screen)`n`nHover mouse over the War Logo (or any logo) directly ABOVE the Barbarian head / Attack button and press SPACE."
        case 16:
            instructions := "Step 16/31: Attack Button (Home Screen)`n`nHover mouse over the bottom-left brown 'Attack' button in your home village and press SPACE."
        case 17:
            instructions := "Step 17/31: Find Match Button (Multiplayer Dialog)`n`nHover mouse over the golden 'Find a Match' button (multiplayer tab) and press SPACE."
        case 18:
            instructions := "Step 18/31: Green 'Attack!' Start Button (My Army Dialog)`n`nHover mouse over the green 'Attack!' button (My Army dialog) and press SPACE."
        case 19:
            instructions := "Step 19/31: Gold Coin Symbol (Matchmaking Search)`n`nHover mouse over the CENTER of the round Gold Coin Icon symbol in a multiplayer match search and press SPACE."
        case 20:
            instructions := "Step 20/31: Elixir Drop Symbol (Matchmaking Search)`n`nHover mouse over the CENTER of the purple Elixir Drop Icon symbol in a multiplayer match search and press SPACE."
        case 21:
            instructions := "Step 21/31: Next Match Button (Matchmaking Search)`n`nHover mouse over the 'Next' button in a multiplayer match search and press SPACE."
        case 22:
            IsWaitingForReset := true
            instructions := "Top-Left Screen Zoom-Out Calibration`n`nPlease Wait."
            SetTimer RunSidesReset, -3000
        case 23:
            instructions := "Step 23/31: Side 1 (Bottom-Right) End Point`n`nHover mouse over the ending point of the Bottom-Right deployment line and press SPACE."
        case 24:
            instructions := "Step 24/31: Side 2 (Bottom-Left) Start Point`n`nHover mouse over the starting point of the Bottom-Left deployment line and press SPACE."
        case 25:
            instructions := "Step 25/31: Side 2 (Bottom-Left) End Point`n`nHover mouse over the ending point of the Bottom-Left deployment line and press SPACE."
        case 26:
            instructions := "Step 26/31: Side 3 (Top-Left) Start Point`n`nHover mouse over the starting point of the Top-Left deployment line and press SPACE."
        case 27:
            instructions := "Step 27/31: Side 3 (Top-Left) End Point`n`nHover mouse over the ending point of the Top-Left deployment line and press SPACE."
        case 28:
            instructions := "Step 28/31: Side 4 (Top-Right) Start Point`n`nHover mouse over the starting point of the Top-Right deployment line and press SPACE."
        case 29:
            instructions := "Step 29/31: Side 4 (Top-Right) End Point`n`nHover mouse over the ending point of the Top-Right deployment line and press SPACE."
        case 30:
            instructions := "Step 30/31: Return Home Button (Battle End)`n`nHover mouse over the center of the green 'Return Home' button and press SPACE."
        case 31:
            if (CollectorCoords.Length == 0) {
                IsWaitingForReset := true
                instructions := "Top-Left Screen Zoom-Out Calibration`n`nPress Button and Please Wait."
                SetTimer RunCollectorReset, -3000
            } else {
                instructions := "Step 31/31: Resource Collectors (Home Screen)`n`nHover over a Gold Mine, Elixir Collector, or DE Drill and press SPACE to record.`n`nCurrently added: " CollectorCoords.Length "`n`nPlease don't move the screen.`n`nPress ENTER to finish and save."
            }
    }
    CalibrationText.Value := instructions
    ToolTip(instructions "`n`nPress ESC to cancel.")
}
FinishCalibration() {
    global IsCalibrating, CalibStep, TextCollectorCount, CollectorCoords, IsWaitingForReset
    global ADBMainCalibrationVersion, ADB_COORDINATE_VERSION, Sides
    IsCalibrating := false
    CalibStep := 0
    IsWaitingForReset := false
    SetTimer(RunCollectorReset, 0)
    SetTimer(RunSidesReset, 0)
    ToolTip()
    ADBMainCalibrationVersion := ADB_COORDINATE_VERSION
    SaveConfig()
    if TextCollectorCount {
        TextCollectorCount.Value := String(CollectorCoords.Length)
    }
    LogMessage("Calibration complete. Saved " CollectorCoords.Length " resource collectors.")
    MsgBox("Calibration completed successfully and saved to config.ini!", "Success", "Iconi")
}
; ==============================================================================
; ADVANCED FARMING HELPER FUNCTIONS (OCR & AUTOMATION)
; ==============================================================================
CleanNumber(str) {
    str := StrReplace(str, " ", "")
    str := StrReplace(str, ",", "")
    str := StrReplace(str, ".", "")
    ; Replace common character substitutions in cartoon font
    str := StrReplace(str, "i", "1")
    str := StrReplace(str, "I", "1")
    str := StrReplace(str, "l", "1")
    str := StrReplace(str, "|", "1")
    str := StrReplace(str, "!", "1")
    str := StrReplace(str, "o", "0")
    str := StrReplace(str, "O", "0")
    ; Map s/S to 5 per user request
    str := StrReplace(str, "s", "5")
    str := StrReplace(str, "S", "5")
    str := StrReplace(str, "g", "9")
    str := StrReplace(str, "G", "9")
    str := StrReplace(str, "q", "9")
    ; Additional mappings observed in noisy backgrounds
    str := StrReplace(str, "b", "6")   ; lower-case b often looks like 6
    str := StrReplace(str, "B", "8")   ; upper-case B → 8
    str := StrReplace(str, "z", "2")   ; z → 2
    str := StrReplace(str, "Z", "2")   ; Z → 2
    str := StrReplace(str, "a", "4")   ; a → 4 (rare but helpful)
    str := StrReplace(str, "A", "4")
    ; Replace bullet (coin logo) with zero
    str := StrReplace(str, "•", "0")
    ; Collect only digits
    res := ""
    Loop Parse, str {
        if (A_LoopField >= "0" && A_LoopField <= "9")
            res .= A_LoopField
    }
    return res = "" ? 0 : Integer(res)
}
SafeInteger(str, defaultVal) {
    if (str = "" || str = "0")
        return defaultVal
    try {
        return Integer(str)
    } catch as err {
        return defaultVal
    }
}
GetLootValueMultiScale(relX, relY, relW, relH, label) {
    if (label == "Gold") {
        scrX := GoldAreaX
        scrY := GoldAreaY
    } else {
        scrX := ElixirAreaX
        scrY := ElixirAreaY
    }
    scales := [2.0, 2.5, 3.0, 1.5]
    rawValues := []
    roundedValues := []
    imgName := A_Temp "\coc_refactor_ocr_loot_temp.png"
    SaveRegionToPNG(scrX, scrY, relW, relH, imgName)
    for scaleVal in scales {
        try {
            result := OCR.FromFile(imgName, {scale: scaleVal})
            cleaned := CleanNumber(result.Text)
            if (cleaned > 0) {
                rounded := Round(cleaned / 10000) * 10000
                rawValues.Push(cleaned)
                roundedValues.Push(rounded)
            }
        } catch as err {
            ; Ignore errors on individual scales
        }
    }
    try FileDelete(imgName)
    if (rawValues.Length == 0) {
        LogMessage(label . " OCR: No valid scans detected.")
        return 0
    }
    ; ---------------------------------------------------
    ; 1️⃣ Find the most common rounded value (mode)
    ; ---------------------------------------------------
    frequencies := Map()
    maxFreq := 0
    bestRounded := 0
    for val in roundedValues {
        freq := frequencies.Has(val) ? frequencies[val] + 1 : 1
        frequencies[val] := freq
        if (freq > maxFreq) {
            maxFreq := freq
            bestRounded := val
        }
    }
    ; ---------------------------------------------------
    ; 2️⃣ If every rounded value is unique, fall back to the highest raw reading
    ; ---------------------------------------------------
    if (maxFreq == 1) {
        bestRaw := 0
        for val in rawValues {
            if (val > bestRaw)
                bestRaw := val
        }
        LogMessage(label . " OCR Result: " . bestRaw . " (unstable)")
        return bestRaw
    }
    ; ---------------------------------------------------
    ; 3️⃣ Gather all raw values that correspond to the winning rounded mode
    ; ---------------------------------------------------
    candidates := []
    for i, val in roundedValues {
        if (val == bestRounded) {
            candidates.Push(rawValues[i])
        }
    }
    ; ---------------------------------------------------
    ; 4️⃣ Choose the highest raw among the candidates – this guards against under-reads
    ; ---------------------------------------------------
    bestRaw := 0
    for cand in candidates {
        if (cand > bestRaw)
            bestRaw := cand
    }
    LogMessage(label . " OCR Result: " . bestRaw)
    return bestRaw
}
GetLootValues(&gold, &elixir) {
    global GoldAreaX, GoldAreaY, GoldAreaW, GoldAreaH
    global ElixirAreaX, ElixirAreaY, ElixirAreaW, ElixirAreaH
    gold := GetLootValueMultiScale(GoldAreaX, GoldAreaY, GoldAreaW, GoldAreaH, "Gold")
    elixir := GetLootValueMultiScale(ElixirAreaX, ElixirAreaY, ElixirAreaW, ElixirAreaH, "Elixir")
}
GetTroopCountsBattle() {
    global Troop1Count, Troop2Count, Troop3Count
    try {
        viewport := GetADBClientViewportRect()
    } catch as err {
        LogMessage("OCR Battle Troop Scan: " err.Message)
        return [Troop1Count, Troop2Count, Troop3Count]
    }
    ; Region for the troop selection bar (bottom 30% of the game client area, starts higher to capture top-right counts)
    scrX := viewport.x
    scrY := viewport.y + Integer(viewport.height * 0.70)
    scrW := viewport.width
    scrH := Integer(viewport.height * 0.25)
    counts := [0, 0, 0]
    imgName := A_Temp "\coc_refactor_troop_counts.png"
    try {
        adbCrop := SaveRegionToPNG(scrX, scrY, scrW, scrH, imgName)
        result := OCR.FromFile(imgName, {scale: 2})
        for word in result.Words {
            text := word.Text
            if RegExMatch(text, "i)^[x\*]?(\d+)$", &match) {
                val := Integer(match[1])
                if (val > 0) {
                    ; Relative X midpoint and relative Y within scanned region
                    relX := (word.x + word.w/2) / adbCrop.width
                    relY := word.y
                    ; Check if this is the troop count (has x/X/* prefix OR is in the top half of the scanned bar)
                    isCount := RegExMatch(text, "i)^[x\*]") || (relY < adbCrop.height * 0.5)
                    if isCount {
                        ; Column mapping
                        if (relX >= 0.04 && relX < 0.11) {
                            counts[1] := val
                        } else if (relX >= 0.11 && relX < 0.183) {
                            counts[2] := val
                        } else if (relX >= 0.183 && relX < 0.256) {
                            counts[3] := val
                        }
                    }
                }
            }
        }
    }
    catch as AnyError {
        LogMessage("OCR Battle Troop Scan error: " AnyError.Message)
    }
    try FileDelete(imgName)
    ; Apply fallback if count is 0
    activeCounts := [Troop1Count, Troop2Count, Troop3Count]
    summaryList := []
    for idx, val in counts {
        if (val > 0) {
            activeCounts[idx] := val
            summaryList.Push(Format("Slot {}: {} (OCR)", idx, val))
        } else {
            summaryList.Push(Format("Slot {}: {} (Fallback)", idx, activeCounts[idx]))
        }
    }
    LogMessage(Format("Troop counts for battle: {}, {}, {}", summaryList[1], summaryList[2], summaryList[3]))
    return activeCounts
}
GetStoragePixelColor(x, y) {
    try {
        return GetADBPixelColor(x, y)
    } catch {
    }
    return 0x000000
}

IsGoldBarFilled(x, y) {
    try {
        color := GetADBPixelColor(x, y)
        actualHex := Integer(color)
        r := (actualHex >> 16) & 0xFF
        g := (actualHex >> 8) & 0xFF
        b := actualHex & 0xFF
        return (r > 120) && (g > 100) && (r > b + 20) && (g > b + 10)
    }
    catch {
        return false
    }
}
IsElixirBarFilled(x, y) {
    try {
        color := GetADBPixelColor(x, y)
        actualHex := Integer(color)
        r := (actualHex >> 16) & 0xFF
        g := (actualHex >> 8) & 0xFF
        b := actualHex & 0xFF
        isPink := (r >= 180) && (g >= 80 && g <= 220) && (b >= 100 && b <= 230)
        isPink := isPink && (r > g) && (r >= b * 0.75)
        isPink := isPink && ((r + g + b) / 3 > 140)
        isDarkPink := (r > 120) && (b > 100) && (r > g + 20)
        return isPink || isDarkPink
    }
    catch {
        return false
    }
}
IsDarkElixirBarFilled(x, y) {
    try {
        targetX := (x > 0) ? x : DarkElixirBarThreshX
        targetY := (y > 0) ? y : DarkElixirBarThreshY
        if (targetX <= 0 || targetY <= 0)
            return false
        color := GetADBPixelColor(targetX, targetY)
        actualHex := Integer(color)
        r := (actualHex >> 16) & 0xFF
        g := (actualHex >> 8) & 0xFF
        b := actualHex & 0xFF
        
        ; Dark Elixir fluid is dark purple/black (r < 70, g < 50, b < 80).
        ; Empty DE bar background is light grey (r > 100, g > 100, b > 100).
        return (r < 70) && (g < 50) && (b < 80)
    } catch {
        return false
    }
}
GetBuilderCropRegion(h, &scrW, &scrH, &offX, &offY) {
    scrW := Max(100, Round(h * 0.1362))
    scrH := Max(24, Round(h * 0.0292))
    offX := Round(scrW * 0.22)
    offY := Round(scrH * 0.50)
}

IsGoblinFace(centerX, centerY) {
    if (centerX <= 0 || centerY <= 0)
        return false
        
    offsets := [
        [0, 0], [-7, 0], [7, 0], [0, -7], [0, 7],
        [-5, -5], [5, -5], [-5, 5], [5, 5], [0, -4]
    ]
    
    greenCount := 0
    try {
        for index, pt in offsets {
            c := GetADBPixelColor(centerX + pt[1], centerY + pt[2], index == 1)
            r := (c >> 16) & 0xFF
            g := (c >> 8) & 0xFF
            b := c & 0xFF
            if (g > r && g > b + 15 && g >= 80)
                greenCount++
        }
    } catch {
        return false
    }
    return greenCount >= 4
}

GetBuilderCount(&free, &total) {
    free := 0
    total := 0
    if (BuilderFaceX <= 0 || BuilderFaceY <= 0)
        return false
    viewport := GetADBClientViewportRect()
    h := viewport.height
    GetBuilderCropRegion(h, &scrW, &scrH, &offX, &offY)
    scrX := BuilderFaceX - offX
    scrY := BuilderFaceY - offY
    centerX := BuilderFaceX
    centerY := BuilderFaceY
    
    imgName := A_Temp "\coc_refactor_builder_area.png"
    SaveRegionToPNG(scrX, scrY, scrW, scrH, imgName)
    adbDisplay := GetADBDisplaySize()
    clean_out := Trim(RunWaitPythonScript('builders "' imgName '" ' adbDisplay.height))
    try FileDelete(imgName)
    
    if RegExMatch(clean_out, "SUCCESS: (\d)/(\d)", &match) {
        free := Integer(match[1])
        total := Integer(match[2])
        
        if (free > 0 && IsGoblinFace(centerX, centerY)) {
            LogMessage(Format("Goblin Builder detected at ({}, {})! Free={}. Ignoring Goblin Builder to prevent spending gems.", centerX, centerY, free))
            free := 0
        } else {
            LogMessage(Format("Builder OCR parsed: {}/{}", free, total))
        }
        return true
    }
    LogMessage("Builder OCR failed. Output: " clean_out)
    return false
}

CanUpgradeBuilding() {
    free := 0
    total := 0
    if !GetBuilderCount(&free, &total)
        return false
        
    return free >= 1
}

CanUpgradeWall() {
    free := 0
    total := 0
    if !GetBuilderCount(&free, &total)
        return false
        
    return free >= 1
}
FindCenterGreenButton(&outX, &outY) {
    try {
        viewport := GetADBClientViewportRect()
    } catch {
        return false
    }
    searchX := viewport.x + (viewport.width * 0.3)
    searchY := viewport.y + (viewport.height * 0.4)
    searchW := viewport.width * 0.4
    searchH := viewport.height * 0.4
    ; Scan a grid in the center area for the signature green color
    loop 20 {
        clientY := searchY + (A_Index * (searchH / 20))
        loop 20 {
            clientX := searchX + (A_Index * (searchW / 20))
            try {
                c := GetADBPixelColor(clientX, clientY)
            } catch {
                continue
            }
            actualHex := Integer(c)
            r := (actualHex >> 16) & 0xFF
            g := (actualHex >> 8) & 0xFF
            b := actualHex & 0xFF
            if (g > r + 30) && (g > b + 30) && (g > 100) {
                outX := clientX
                outY := clientY
                return true
            }
        }
    }
    return false
}
ProcessWallUpgrade(upgradeX, upgradeY, resourceType) {
    global DarkElixirBarThreshX, DarkElixirBarThreshY, GoldBarThreshX, GoldBarThreshY, ElixirBarThreshX, ElixirBarThreshY
    wallCount := 4
    ; First, add 3 walls to reach the maximum 4
    Loop 3 {
        ADBClickPoint(AddWall1X, AddWall1Y)
        if !SafeSleep(200)
            return false
    }
    Loop 4 {
        LogMessage(Format("Farming: Attempting to upgrade {} wall(s)...", wallCount))
        ADBClickPoint(upgradeX, upgradeY)
        if !SafeSleep(1500) ; Wait for confirmation popup
            return false
        ; 1. First, click the GREEN "Okay" confirmation button in the center
        if FindCenterGreenButton(&gx, &gy) {
            LogMessage("Farming: Clicking green Okay confirmation button...")
            ClientClickPoint(gx + 15, gy + 15) ; OCR result is a dynamic client point.
            if !SafeSleep(1500) ; Wait to see if it succeeds or pops up the Gem screen
                return false
            ; 2. Check if a SECOND green button is present (this means it was too expensive and the Gem popup appeared)
            if FindCenterGreenButton(&gx2, &gy2) {
                ; Verify the resource threshold is still met before trying to remove a wall and retrying
                stillHasResources := false
                if (resourceType == "gold") {
                    stillHasResources := IsGoldBarFilled(GoldBarThreshX, GoldBarThreshY)
                } else if (resourceType == "elixir") {
                    stillHasResources := IsElixirBarFilled(ElixirBarThreshX, ElixirBarThreshY)
                }
                if !stillHasResources {
                    LogMessage(Format("Farming: {} threshold no longer met after upgrade attempt (resources spent). Stopping.", resourceType))
                    ADBClickPoint(ReturnHomeClickX, ReturnHomeClickY) ; Dismiss Gem popup
                    SafeSleep(500)
                    break
                }
                LogMessage("Farming: Upgrade too expensive (Gem popup detected). Removing one wall...")
                ADBClickPoint(ReturnHomeClickX, ReturnHomeClickY) ; Dismiss Gem popup
                if !SafeSleep(800)
                    return false
                ADBClickPoint(RemoveWallX, RemoveWallY) ; Remove one wall
                if !SafeSleep(500)
                    return false
                wallCount--
                if (wallCount < 1) {
                    LogMessage("Farming: Cannot afford even 1 wall.")
                    break
                }
            } else {
                LogMessage("Farming: Upgrade successful!")
                break
            }
        } else {
            LogMessage("Farming: No confirmation popup found? Assuming success.")
            break
        }
    }
    ADBClickPoint(ReturnHomeClickX, ReturnHomeClickY)
    SafeSleep(500)
    return true
}
CollectResources() {
    if (CollectorCoords.Length == 0)
        return
    ; If you ever want to make this run 100% of the time, change this to Random(1, 1)
    ; DO NOT completely remove this random block!
    roll := Random(1, 40)
    if (roll != 1) {
        LogMessage("Farming: Skipping resource collection this cycle (Rolled " roll "/40, needs 1).")
        return
    }
    LogMessage("Farming: Collecting resources from " CollectorCoords.Length " mines/collectors...")
    for coord in CollectorCoords {
        if !IsRunning
            break
        ADBClickPoint(coord.x, coord.y)
        SafeSleep(250)
    }
}
FindAnyWallInDropdown() {
    global BuilderFaceX, BuilderFaceY, BuilderMenuBottomY, LabFaceX, LabFaceY, UpgradeConfirmX, UpgradeConfirmY
    viewport := GetADBClientViewportRect()
    w := viewport.width
    h := viewport.height
    menuLeft := BuilderFaceX - (w * 0.18)
    menuWidth := w * 0.36
    menuTop := viewport.y + h * 0.12
    menuHeight := h * 0.75
    imgName := A_Temp "\coc_refactor_wall_menu.png"
    ; Scroll down in chunks until we see ANY Wall text
    Loop 4 {
        for sc in [2.5, 2.0, 3.0] {
            try {
                adbCrop := SaveRegionToPNG(menuLeft, menuTop, menuWidth, menuHeight, imgName)
                result := OCR.FromFile(imgName, {scale: sc})
                for line in result.Lines {
                    ; Matches Wall, wall, Wa11, WaIl, Wail, Vall, val1, wal, val, etc.
                    if RegExMatch(line.Text, "i)\b[vw][aAeEoOuU01iI][lLiI1t]{1,2}\b") {
                        LogMessage(Format("Farming: Found Wall suggestion: '{}' (using scale {})", line.Text, sc))
                        clientPoint := ADBFramePointToClient(
                            adbCrop,
                            line.x + (line.w / 2),
                            line.y + (line.h / 2)
                        )
                        ClientClickPoint(clientPoint.x, clientPoint.y, 2)
                        try FileDelete(imgName)
                        return true
                    }
                }
            }
            catch as err {
                LogMessage("Farming: OCR error in suggestions dropdown: " err.Message)
            }
        }
        ; Three ADB swipes produce four OCR passes without requiring window focus.
        if (A_Index < 4) {
            RunADBSwipeAt(BuilderMenuBottomX, BuilderMenuBottomY, BuilderFaceX, BuilderFaceY, 200)
            Sleep 800
        }
    }
    try FileDelete(imgName)
    return false
}
UpgradeWalls(wallState := "") {
    global EnableWallUpgrade, IsRunning, TargetWindowTitle
    global BuilderFaceX, BuilderFaceY, LabFaceX, LabFaceY, UpgradeConfirmX, UpgradeConfirmY, ReturnHomeClickX, ReturnHomeClickY
    CoordMode "Mouse", "Client"
    global UpgradeMoreBtnX, UpgradeMoreBtnY
    global GoldUpgradeX, GoldUpgradeY, ElixirUpgradeX, ElixirUpgradeY
    global DarkElixirBarThreshX, DarkElixirBarThreshY, GoldBarThreshX, GoldBarThreshY, ElixirBarThreshX, ElixirBarThreshY
    if !EnableWallUpgrade
        return
    ; 1. Use the section's fresh frame decision when one was supplied.
    if IsObject(wallState) {
        runGoldUpgrade := wallState.gold
        runElixirUpgrade := wallState.elixir
    } else {
        runGoldUpgrade := IsGoldBarFilled(GoldBarThreshX, GoldBarThreshY)
        runElixirUpgrade := IsElixirBarFilled(ElixirBarThreshX, ElixirBarThreshY)
    }
    if !runGoldUpgrade && !runElixirUpgrade {
        LogMessage("Farming: Storage bars have not reached calibrated threshold points. Skipping wall upgrades.")
        return
    }
    LogMessage("Farming: Checking builder status for wall upgrades...")
    canUpgrade := IsObject(wallState) ? wallState.canUpgrade : CanUpgradeWall()
    if !canUpgrade {
        LogMessage("Farming: All builders are busy. Skipping wall upgrade.")
        return
    }
    ; --- 2. Elixir Wall Upgrade (Prioritized) ---
    if runElixirUpgrade {
        LogMessage("Farming: Elixir threshold met! Selecting a wall for Elixir upgrade...")
        ADBClickPoint(BuilderFaceX, BuilderFaceY)
        if !SafeSleep(800)
            return
        if FindAnyWallInDropdown() {
            if !SafeSleep(5000)
                return
            ADBClickPoint(UpgradeMoreBtnX, UpgradeMoreBtnY)
            if !SafeSleep(800)
                return
            ProcessWallUpgrade(ElixirUpgradeX, ElixirUpgradeY, "elixir")
        } else {
            LogMessage("Farming: No Wall upgrades found in builder suggestions.")
            ADBClickPoint(ReturnHomeClickX, ReturnHomeClickY)
            SafeSleep(500)
        }
    }
    ; --- 3. Gold Wall Upgrade ---
    if runGoldUpgrade {
        LogMessage("Farming: Gold bar threshold met! Selecting a wall for Gold upgrade...")
        ADBClickPoint(BuilderFaceX, BuilderFaceY)
        if !SafeSleep(800)
            return
        if FindAnyWallInDropdown() {
            if !SafeSleep(5000)
                return
            ADBClickPoint(UpgradeMoreBtnX, UpgradeMoreBtnY)
            if !SafeSleep(800)
                return
            ProcessWallUpgrade(GoldUpgradeX, GoldUpgradeY, "gold")
        } else {
            LogMessage("Farming: No Wall upgrades found in builder suggestions.")
            ADBClickPoint(ReturnHomeClickX, ReturnHomeClickY)
            SafeSleep(500)
        }
    }
}
IsReturnHomePresent() {
    global ReturnHomeClickX, ReturnHomeClickY
    return ReturnHomeClickX > 0 && ReturnHomeClickY > 0 && IsReturnHomePresentADB()
}
IsReturnHomePresentADB() {
    if (ReturnHomeClickX <= 0)
        return false
    matchCount := 0
    points := [
        {x: 0, y: 0},
        {x: -15, y: 0},
        {x: 15, y: 0},
        {x: 0, y: -10},
        {x: 0, y: 10}
    ]
    for pt in points {
        try {
            c := GetADBPixelColor(ReturnHomeClickX + pt.x, ReturnHomeClickY + pt.y)
            actualHex := Integer(c)
            r := (actualHex >> 16) & 0xFF
            g := (actualHex >> 8) & 0xFF
            b := actualHex & 0xFF
            if (g > 135) && (g > r + 25) && (g > b + 40) && (r > 30)
                matchCount++
        }
    }
    return (matchCount >= 3)
}
; ==============================================================================
; MAIN AUTOMATION LOOP
; ==============================================================================
CheckGameTimeout(force := false) {
    global IsRunning
    if !force && !IsRunning
        return
    try {
        viewport := GetADBClientViewportRect()
    } catch {
        return
    }
    searchX := viewport.x + (viewport.width * 0.25)
    searchY := viewport.y + (viewport.height * 0.4)
    searchW := viewport.width * 0.5
    searchH := viewport.height * 0.4
    imgName := A_Temp "\coc_refactor_timeout.png"
    try {
        adbCrop := SaveRegionToPNG(searchX, searchY, searchW, searchH, imgName)
        result := OCR.FromFile(imgName, {scale: 1.5})
        timeoutDetected := false
        buttonLine := ""
        for line in result.Lines {
            text := StrReplace(line.Text, " ", "")
            ; Check if any line indicates timeout / reload screen is active
            if InStr(text, "eload") || InStr(text, "Sync") || InStr(text, "Break") || InStr(text, "Connection") || InStr(text, "Another") {
                timeoutDetected := true
            }
            ; Check if this line is a button we can click
            if InStr(text, "eload") || InStr(text, "Try") || InStr(text, "Okay") || InStr(text, "Retry") {
                buttonLine := line
            }
        }
        if timeoutDetected {
            LogMessage("Farming: Game Timeout/Reload screen detected!")
            if (buttonLine != "") {
                LogMessage("Farming: Clicking detected reload/action button...")
                clientPoint := ADBFramePointToClient(
                    adbCrop,
                    buttonLine.x + (buttonLine.w / 2),
                    buttonLine.y + (buttonLine.h / 2)
                )
                ClientClickPoint(clientPoint.x, clientPoint.y)
            } else {
                LogMessage("Farming: No specific button text detected, clicking screen center fallback...")
                ADBClickFraction(0.5, 0.55)
            }
            Sleep 10000 ; Wait 10 seconds for game to reload
        }
        try FileDelete(imgName)
    } catch as err {
        try FileDelete(imgName)
        LogMessage("Timeout OCR failed: " err.Message)
    }
}
SaveRegionToPNG(x, y, w, h, filepath) {
    adbRect := ClientRectToADBRect(x, y, w, h)
    framePath := CaptureADBFrame()
    if !FileExist(framePath)
        throw Error("ADB frame capture did not produce an image.")
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
RunWaitPythonScript(args) {
    global A_ScriptDir
    outFile := A_Temp "\coc_refactor_exec_out.txt"
    try FileDelete(outFile)
    cmd := 'cmd.exe /c python "' A_ScriptDir '\vision_hook.py" ' args ' > "' outFile '" 2>&1'
    shell := ComObject("WScript.Shell")
    shell.Run(cmd, 0, true)
    output := ""
    if FileExist(outFile) {
        output := FileRead(outFile)
        try FileDelete(outFile)
    }
    return output
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
        pCroppedBitmap,
        "wstr",
        filepath,
        "ptr",
        clsid,
        "ptr",
        0
    )
    DllCall("gdiplus\GdipDisposeImage", "ptr", pCroppedBitmap)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pSourceBitmap)
    if (saveStatus != 0)
        throw Error("ADB crop could not be saved; GDI+ status " saveStatus ".")
    return adbRect
}

ReadBuilderAvailabilityFromADBFrame(framePath) {
    global BuilderFaceX, BuilderFaceY
    viewport := GetADBClientViewportRect()
    GetBuilderCropRegion(viewport.height, &cropW, &cropH, &offsetX, &offsetY)
    imagePath := A_Temp "\coc_refactor_flow_builder.png"
    SaveADBFrameRegionToPNG(
        framePath,
        BuilderFaceX - offsetX,
        BuilderFaceY - offsetY,
        cropW,
        cropH,
        imagePath
    )
    adbDisplay := GetADBDisplaySize()
    output := Trim(RunWaitPythonScript('builders "' imagePath '" ' adbDisplay.height))
    try FileDelete(imagePath)
    if !RegExMatch(output, "SUCCESS: (\d)/(\d)", &match)
        return {free: 0, total: 0, goblin: true}
    free := Integer(match[1])
    total := Integer(match[2])
    return {
        free: free,
        total: total,
        goblin: free > 0
            && IsGoblinFaceInADBFrame(framePath, BuilderFaceX, BuilderFaceY)
    }
}

ReadLabAvailabilityFromADBFrame(framePath) {
    global LabFaceX, LabFaceY
    viewport := GetADBClientViewportRect()
    GetLabCropRegion(viewport.height, &cropW, &cropH, &offsetX, &offsetY)
    imagePath := A_Temp "\coc_refactor_flow_lab.png"
    SaveADBFrameRegionToPNG(
        framePath,
        LabFaceX - offsetX,
        LabFaceY - offsetY,
        cropW,
        cropH,
        imagePath
    )
    adbDisplay := GetADBDisplaySize()
    output := Trim(RunWaitPythonScript('lab "' imagePath '" ' adbDisplay.height))
    try FileDelete(imagePath)
    if !RegExMatch(output, "SUCCESS: (\d)/(\d)", &match)
        return {free: 0, total: 0, goblin: true}
    free := Integer(match[1])
    total := Integer(match[2])
    return {
        free: free,
        total: total,
        goblin: free > 0
            && IsGoblinFaceInADBFrame(framePath, LabFaceX, LabFaceY)
    }
}

FindFlowSuggestedUpgrade(menuKind) {
    global BuilderFaceX, BuilderFaceY, BuilderMenuBottomY, LabFaceX
    viewport := GetADBClientViewportRect()
    if (menuKind == "builder") {
        menuX := BuilderFaceX - viewport.width * 0.20
        menuY := Max(viewport.y, BuilderFaceY)
        menuW := viewport.width * 0.42
        menuH := Max(1, BuilderMenuBottomY - menuY)
        scales := [2.0, 2.5, 1.5, 3.0]
    } else {
        menuX := LabFaceX - viewport.width * 0.18
        menuY := viewport.y + viewport.height * 0.12
        menuW := viewport.width * 0.36
        menuH := viewport.height * 0.75
        scales := [2.5, 2.0, 3.0]
    }
    imagePath := A_Temp "\coc_refactor_flow_" menuKind "_menu.png"
    framePath := CaptureADBFrame(true)
    adbCrop := SaveADBFrameRegionToPNG(
        framePath,
        menuX,
        menuY,
        menuW,
        menuH,
        imagePath
    )
    for scaleValue in scales {
        try {
            result := OCR.FromFile(imagePath, {scale: scaleValue})
            rawText := StrReplace(
                StrReplace(result.Text, "`r", "\r"),
                "`n",
                "\n"
            )
            LogMessage(
                "Suggested upgrades OCR " menuKind " scale "
                    scaleValue "x: raw='" rawText "'."
            )
            selected := SelectFirstSuggestedUpgradeOCRWord(result.Lines)
            if !IsObject(selected)
                continue
            selected := NormalizeBuilderOCRMatch(selected, scaleValue)
            clientPoint := ADBFramePointToClient(
                adbCrop,
                selected.tapX,
                selected.tapY
            )
            LogMessage(
                "Suggested upgrades " menuKind ": OCR selected '"
                    selected.lineText "' at normalized crop point ("
                    Round(selected.tapX) ", " Round(selected.tapY)
                    "), client (" clientPoint.x ", " clientPoint.y ")."
            )
            try FileDelete(imagePath)
            return {
                name: selected.lineText,
                x: clientPoint.x,
                y: clientPoint.y
            }
        } catch as err {
            LogMessage(
                "Suggested upgrades OCR " menuKind " scale "
                    scaleValue "x error: " err.Message
            )
        }
    }
    LogMessage(
        "Suggested upgrades OCR " menuKind
            " failed; preserved capture at " imagePath "."
    )
    return ""
}

FindBuilderInfoFromADBFrame(framePath) {
    viewport := GetADBClientViewportRect()
    clientCropX := viewport.x + Round(viewport.width * 0.15)
    clientCropY := viewport.y + Round(viewport.height * 0.65)
    clientCropW := Round(viewport.width * 0.70)
    clientCropH := Round(viewport.height * 0.30)
    imagePath := A_Temp "\coc_refactor_builder_info.png"
    adbRect := SaveADBFrameRegionToPNG(
        framePath,
        clientCropX,
        clientCropY,
        clientCropW,
        clientCropH,
        imagePath
    )
    adbDisplay := GetADBDisplaySize()
    output := Trim(
        RunWaitPythonScript(
            'info "' imagePath '" ' adbDisplay.height
        )
    )
    try FileDelete(imagePath)
    LogMessage("Builder Info template detector output: '" output "'.")
    if !RegExMatch(
        output,
        "SUCCESS:\s*(\d+)/(\d+)/([\d.]+)/(\d+)/(\d+)/(\d+)/(\d+)",
        &match
    ) {
        return ""
    }

    localX := Integer(match[1])
    localY := Integer(match[2])
    confidence := Number(match[3])
    clientPoint := ADBFramePointToClient(adbRect, localX, localY)
    LogMessage(
        "Builder Info template match: confidence "
            Format("{:.4f}", confidence) ", local center ("
            localX ", " localY "), client center ("
            clientPoint.x ", " clientPoint.y ")."
    )
    return {
        name: "Info icon",
        x: clientPoint.x,
        y: clientPoint.y,
        confidence: confidence
    }
}

ReadLootValueFromADBFrame(framePath, x, y, width, height, label) {
    imagePath := A_Temp "\coc_refactor_flow_loot_" label ".png"
    adbRect := SaveADBFrameRegionToPNG(
        framePath,
        x,
        y,
        width,
        height,
        imagePath
    )
    LogMessage(
        Format(
            "Loot OCR {} crop: client ({}, {}, {}, {}) "
                "-> ADB ({}, {}, {}, {}).",
            label,
            x,
            y,
            width,
            height,
            adbRect.x,
            adbRect.y,
            adbRect.width,
            adbRect.height
        )
    )
    readings := []
    for scaleValue in [2.0, 2.5, 3.0, 1.5] {
        try {
            result := OCR.FromFile(imagePath, {scale: scaleValue})
            cleaned := CleanNumber(result.Text)
            rawText := StrReplace(
                StrReplace(result.Text, "`r", "\r"),
                "`n",
                "\n"
            )
            LogMessage(
                Format(
                    "Loot OCR {} scale {:.1f}x: raw='{}', cleaned={}.",
                    label,
                    scaleValue,
                    rawText,
                    cleaned
                )
            )
            if (cleaned > 0)
                readings.Push(cleaned)
        } catch as err {
            LogMessage(
                Format(
                    "Loot OCR {} scale {:.1f}x error: {}",
                    label,
                    scaleValue,
                    err.Message
                )
            )
        }
    }
    try FileDelete(imagePath)
    result := SelectLootConsensus(readings)
    LogMessage(
        Format(
            "Loot OCR {} mode: valid={}, value={}, reason={}, "
                "agreement={}/{}.",
            label,
            result.valid ? "YES" : "NO",
            result.value,
            result.reason,
            result.agreement,
            result.readingCount
        )
    )
    return result
}

ReadLootFromADBFrame(framePath) {
    global GoldIconX, GoldIconY, ElixirIconX, ElixirIconY
    global LootCropOffsetX, LootCropOffsetY, LootCropW, LootCropH
    goldX := GoldIconX + LootCropOffsetX
    goldY := GoldIconY + LootCropOffsetY
    elixirX := ElixirIconX + LootCropOffsetX
    elixirY := ElixirIconY + LootCropOffsetY
    return {
        gold: ReadLootValueFromADBFrame(
            framePath,
            goldX,
            goldY,
            LootCropW,
            LootCropH,
            "gold"
        ),
        elixir: ReadLootValueFromADBFrame(
            framePath,
            elixirX,
            elixirY,
            LootCropW,
            LootCropH,
            "elixir"
        )
    }
}

FindTemplateUpgradeButton(&outX, &outY) {
    viewport := GetADBClientViewportRect()
    w := viewport.width
    h := viewport.height
    scrLeft := viewport.x
    scrTop := viewport.y + Integer(h * 0.65)
    image_path := A_Temp "\coc_refactor_upgrade_area.png"
    adbCrop := SaveRegionToPNG(scrLeft, scrTop, w, Integer(h * 0.35), image_path)
    adbDisplay := GetADBDisplaySize()
    output := Trim(RunWaitPythonScript('hammer "' image_path '" ' adbDisplay.height))
    try FileDelete(image_path)
    if RegExMatch(output, "SUCCESS:\s*(\d+)/(\d+)", &match) {
        match_x := Integer(match[1])
        match_y := Integer(match[2])
        ; Offset downwards by ~18px at 1080p to click the bottom half of the detected upgrade button
        buttonHeightOffset := Max(10, Round(adbDisplay.height * 0.016))
        clientPoint := ADBFramePointToClient(
            adbCrop,
            match_x,
            match_y + buttonHeightOffset
        )
        outX := clientPoint.x
        outY := clientPoint.y
        return true
    }
    return false
}
GetLabCropRegion(h, &scrW, &scrH, &offX, &offY) {
    scrW := Max(100, Round(h * 0.12))
    scrH := Max(30, Round(h * 0.04))
    offX := Round(scrW * 0.15)
    offY := Round(scrH * 0.50)
}

IsLabBusy() {
    if (LabFaceX <= 0 || LabFaceY <= 0)
        return true
    viewport := GetADBClientViewportRect()
    h := viewport.height
    GetLabCropRegion(h, &scrW, &scrH, &offX, &offY)
    scrX := LabFaceX - offX
    scrY := LabFaceY - offY
    centerX := LabFaceX
    centerY := LabFaceY

    imgName := A_Temp "\coc_refactor_lab_area.png"
    SaveRegionToPNG(scrX, scrY, scrW, scrH, imgName)
    adbDisplay := GetADBDisplaySize()
    clean_out := Trim(RunWaitPythonScript('lab "' imgName '" ' adbDisplay.height))
    try FileDelete(imgName)
    
    if RegExMatch(clean_out, "SUCCESS: (\d)/(\d)", &match) {
        free := Integer(match[1])
        total := Integer(match[2])
        
        if (free > 0 && IsGoblinFace(centerX, centerY)) {
            LogMessage(Format("Goblin Researcher detected at ({}, {})! Free={}. Treating Lab as busy to prevent spending gems.", centerX, centerY, free))
            return true
        }
        
        LogMessage(Format("Lab OCR parsed: {}/{}", free, total))
        return free == 0
    }
    LogMessage("Lab OCR failed. Output: " clean_out)
    return true ; Default to busy if OCR fails
}

UpgradeLab() {
    global LabFaceX, LabFaceY, UpgradeConfirmX, UpgradeConfirmY
    viewport := GetADBClientViewportRect()
    LogMessage("Lab available! Clicking Lab Face...")
    ADBClickPoint(LabFaceX, LabFaceY)
    Sleep 1200
    
    w := viewport.width
    h := viewport.height
    menuLeft := LabFaceX - (w * 0.18)
    menuWidth := w * 0.36
    menuTop := viewport.y + h * 0.12
    menuHeight := h * 0.75
    imgName := A_Temp "\coc_refactor_lab_menu.png"
    
    clickX := 0, clickY := 0
    found_suggestion := false
    
    for sc in [2.5, 2.0, 3.0] {
        try {
            adbCrop := SaveRegionToPNG(menuLeft, menuTop, menuWidth, menuHeight, imgName)
            result := OCR.FromFile(imgName, {scale: sc})
            lines := result.Lines
            suggested_idx := -1
            loop lines.Length {
                if InStr(lines[A_Index].Text, "ggested") || InStr(lines[A_Index].Text, "Suggested") || InStr(lines[A_Index].Text, "ggested upgr") {
                    suggested_idx := A_Index
                    break
                }
            }
            if (suggested_idx != -1 && suggested_idx < lines.Length) {
                target_line := lines[suggested_idx + 1]
                clientPoint := ADBFramePointToClient(
                    adbCrop,
                    target_line.x + 50,
                    target_line.y + (target_line.h / 2)
                )
                clickX := clientPoint.x
                clickY := clientPoint.y
                found_suggestion := true
                break
            }
        }
    }
    try FileDelete(imgName)
    
    if !found_suggestion {
        LogMessage("Failed to find 'Suggested upgrades' section.")
        ClearingClick()
        return
    }
    
    ClientClickPoint(clickX, clickY)
    Sleep 2000
    
    LogMessage("Confirming Lab Upgrade...")
    ADBClickPoint(UpgradeConfirmX, UpgradeConfirmY)
    Sleep 1500
    ClearingClick()
}
UpgradeBuilding() {
    global TargetWindowTitle, BuilderFaceX, BuilderFaceY, BuilderMenuBottomY, UpgradeConfirmX, UpgradeConfirmY
    hwnd := WinExist(TargetWindowTitle)
    if !hwnd
        return false
    viewport := GetADBClientViewportRect()
    LogMessage("Farming: Opening Builder suggestions menu...")
    ADBClickPoint(BuilderFaceX, BuilderFaceY)
    Sleep 1200
    w := viewport.width
    h := viewport.height
    topY := Max(viewport.y, BuilderFaceY)
    bottomY := (BuilderMenuBottomY > topY + 100) ? BuilderMenuBottomY : viewport.y + Integer(h * 0.85)
    menuLeft := BuilderFaceX - (w * 0.20)
    menuWidth := w * 0.42
    menuTop := topY
    menuHeight := bottomY - topY
    imgName := A_Temp "\coc_refactor_builder_menu.png"
    ; Scan dropdown using OCR
    suggestion_text := ""
    clickX := 0, clickY := 0
    found_suggestion := false
    for sc in [2.0, 2.5, 1.5, 3.0] {
        try {
            adbCrop := SaveRegionToPNG(menuLeft, menuTop, menuWidth, menuHeight, imgName)
            result := OCR.FromFile(imgName, {scale: sc})
            lines := result.Lines
            ; Find the "Suggested upgrades" header
            suggested_idx := -1
            loop lines.Length {
                t := lines[A_Index].Text
                if InStr(t, "ggested Upgr") || InStr(t, "ggested upgr") || InStr(t, "Suggested") || InStr(t, "gested") {
                    suggested_idx := A_Index
                    break
                }
            }
            ; If found, click the first line below it
            if (suggested_idx != -1 && suggested_idx < lines.Length) {
                target_line := lines[suggested_idx + 1]
                suggestion_text := target_line.Text
                clientPoint := ADBFramePointToClient(
                    adbCrop,
                    target_line.x + 50,
                    target_line.y + (target_line.h / 2)
                )
                clickX := clientPoint.x
                clickY := clientPoint.y
                found_suggestion := true
                break
            }
        }
        catch as err {
            LogMessage("Farming: OCR error in dropdown: " err.Message)
        }
    }
    try FileDelete(imgName)
    if !found_suggestion {
        LogMessage("Farming: Failed to find 'Suggested upgrades' section.")
        return false
    }
    ; Classify building vs hero
    is_hero := InStr(suggestion_text, "Queen") || InStr(suggestion_text, "King") || InStr(suggestion_text, "Warden") || InStr(suggestion_text, "Champion")
    LogMessage(Format("Farming: Target suggestion: '{}' (Type: {})", suggestion_text, is_hero ? "Hero" : "Building"))
    ; Click suggestion
    ClientClickPoint(clickX, clickY)
    Sleep 2000 ; 2-second camera settle delay
    if is_hero {
        ; Hero upgrade flow: skip Upgrade button, go straight to confirm
        LogMessage("Farming: Hero detected. Clicking calibrated confirmation button...")
        ADBClickPoint(UpgradeConfirmX, UpgradeConfirmY)
        Sleep 1500
        ClearingClick()
        return true
    } else {
        ; Building upgrade flow: find "Upgrade" button using Template Matching
        LogMessage("Farming: Building detected. Finding Upgrade hammer button...")
        btnX := 0, btnY := 0
        if FindTemplateUpgradeButton(&btnX, &btnY) {
            LogMessage(Format("Farming: Clicking Upgrade hammer button at client {}, {}", btnX, btnY))
            ClientClickPoint(btnX, btnY)
            Sleep 1200
            ; Click calibrated confirmation button directly
            LogMessage(Format("Farming: Clicking calibrated confirmation button at client {}, {}", UpgradeConfirmX, UpgradeConfirmY))
            ADBClickPoint(UpgradeConfirmX, UpgradeConfirmY)
            Sleep 1500
            ClearingClick()
            return true
        } else {
            LogMessage("Farming: Failed to find Upgrade hammer button (Template Match threshold not reached). Check vision_hook log.")
            ClearingClick()
        }
    }
    return false
}

class LiveADBFlowPrimitives {
    __New() {
        this.TroopCounts := ""
    }

    Do(name, args*) {
        switch name {
            case "log":
                LogMessage(args[1])
                return true
            case "verify_emulator":
                return this.VerifyEmulator()
            case "verify_calibration":
                return this.VerifyCalibration()
            case "start_timer":
                return this.StartTimer(args[1])
            case "clear_tap":
                return FlowClearTap()
            case "capture_fresh_frame":
                return this.CaptureFreshFrame(args[1])
            case "detect_village_from_frame":
                return DetectVillageFromADBFrame(this.RequireFramePath(args[1]))
            case "start_main_loop":
                return this.StartMainLoop()
            case "start_builder_loop":
                return this.StartBuilderLoop()
            case "reset_main_viewport":
                return ResetViewport()
            case "collection_roll":
                return Random(1, 40)
            case "tap_collector":
                return this.TapCollector(args[1])
            case "read_resource_thresholds_from_frame":
                return ReadResourceThresholdsFromADBFrame(
                    this.RequireFramePath(args[1], "thresholds")
                )
            case "read_builders_from_frame":
                return ReadBuilderAvailabilityFromADBFrame(
                    this.RequireFramePath(args[1], "builder")
                )
            case "open_builder_menu":
                return this.OpenUpgradeMenu("builder")
            case "ocr_builder_suggestion":
                return FindFlowSuggestedUpgrade("builder")
            case "tap_builder_suggestion", "tap_lab_suggestion":
                return this.TapSuggestion(args[1])
            case "find_builder_info_from_frame":
                return FindBuilderInfoFromADBFrame(
                    this.RequireFramePath(args[1], "builder_info")
                )
            case "tap_builder_info":
                return this.TapBuilderInfo(args[1])
            case "tap_upgrade_confirm":
                return this.TapUpgradeConfirm()
            case "read_wall_state_from_frame":
                return this.ReadWallState(args[1])
            case "perform_wall_upgrades":
                UpgradeWalls(args[1])
                return true
            case "read_lab_from_frame":
                return ReadLabAvailabilityFromADBFrame(
                    this.RequireFramePath(args[1], "lab")
                )
            case "open_lab_menu":
                return this.OpenUpgradeMenu("lab")
            case "ocr_lab_suggestion":
                return FindFlowSuggestedUpgrade("lab")
            case "tap_main_attack":
                return this.TapMainAttack()
            case "tap_find_match":
                return this.TapFindMatch()
            case "tap_attack_start":
                return this.TapAttackStart()
            case "wait":
                return this.Wait(args[1])
            case "check_clouds_from_frame":
                return AreCloudsPresentInADBFrame(
                    this.RequireFramePath(args[1], "clouds")
                )
            case "read_loot_from_frame":
                return ReadLootFromADBFrame(
                    this.RequireFramePath(args[1], "base")
                )
            case "tap_next_match":
                return this.TapNextMatch()
            case "random_side":
                return Random(1, 4)
            case "deploy_main":
                return this.DeployMain(args[1], args[2])
            case "deploy_spell":
                return this.DeploySpell(args[1], args[2], args[3])
            case "hero_ability":
                return SendKey(args[1])
            case "tap_return_home":
                return this.TapReturnHome()
            case "detect_main_home_from_frame":
                return DetectVillageFromADBFrame(
                    this.RequireFramePath(args[1], "home")
                ) == "main"
            case "complete_global_cycle":
                return CompleteLiveGlobalCycle(args[1])
            case "record_completed_attack":
                return this.RecordCompletedAttack(args[1])
            case "timer_triggered":
                return IsTimerUp()
            case "exit_game_after_timer":
                return this.ExitGameAfterTimer()
            case "find_reload_action_from_frame":
                return FindReloadActionFromADBFrame(args[1])
            case "tap_reload_action":
                return TapLiveReloadAction(args[1])
            case "route_village":
                return RouteLiveVillage(args[1])
            case "stop_bot":
                return this.StopBot()
        }
        throw Error("Unknown live flow operation: " name)
    }

    CaptureFreshFrame(section) {
        global ADBFramePath
        if (section == "")
            throw Error("A fresh frame requires a decision section.")
        if (ADBFramePath == "")
            ADBFramePath := A_ScriptDir "\scratch\adb_frame.png"
        if FileExist(ADBFramePath)
            FileDelete(ADBFramePath)
        framePath := CaptureADBFrame(true)
        if !this.IsValidPNG(framePath)
            throw Error("ADB did not return a fresh PNG frame for " section ".")
        return {
            section: section,
            path: framePath,
            capturedAt: A_TickCount
        }
    }

    RequireFramePath(frame, expectedSection := "") {
        if !IsObject(frame)
            throw Error("A captured ADB frame object is required.")
        if !frame.HasOwnProp("section") || !frame.HasOwnProp("path")
            throw Error("ADB frame metadata is incomplete.")
        if (expectedSection != "" && frame.section != expectedSection)
            throw Error("ADB frame belongs to " frame.section ", not " expectedSection ".")
        if !this.IsValidPNG(frame.path)
            throw Error("ADB frame is missing or invalid.")
        return frame.path
    }

    IsValidPNG(framePath) {
        if (framePath == "" || !FileExist(framePath) || FileGetSize(framePath) < 8)
            return false
        file := FileOpen(framePath, "r")
        if !IsObject(file)
            return false
        signature := []
        Loop 8
            signature.Push(file.ReadUChar())
        file.Close()
        expected := [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        Loop 8 {
            if (signature[A_Index] != expected[A_Index])
                return false
        }
        return true
    }

    ReadWallState(frame) {
        framePath := this.RequireFramePath(frame, "walls")
        thresholds := ReadResourceThresholdsFromADBFrame(framePath)
        builders := ReadBuilderAvailabilityFromADBFrame(framePath)
        return {
            canUpgrade: (thresholds.gold || thresholds.elixir)
                && builders.free > 0
                && !builders.goblin,
            gold: thresholds.gold,
            elixir: thresholds.elixir,
            free: builders.free,
            goblin: builders.goblin
        }
    }

    VerifyEmulator() {
        global TargetWindowTitle
        if !WinExist(TargetWindowTitle)
            throw Error("The configured emulator window is not open.")
        ready := EnsureADBConnection()
        if !ready.Ok
            throw Error(ready.Message)
        if !IsClashForeground(ready.Serial)
            throw Error("Clash of Clans is not the foreground Android app.")
        return true
    }

    VerifyCalibration() {
        viewportState := ValidateADBViewportRuntime()
        if !viewportState.Ok
            throw Error(viewportState.Message)
        return true
    }

    StartTimer(durationMs) {
        global TimerDurationMs, TimerStartTick
        TimerDurationMs := durationMs
        TimerStartTick := A_TickCount
        LogMessage("Auto-Stop Timer started for " durationMs " ms.")
        return true
    }

    StartMainLoop() {
        global IsRunning, IsBBRunning
        global ADBMainCalibrationVersion, ADB_COORDINATE_VERSION
        global StatusText, StartBtn, PauseBtn
        if (ADBMainCalibrationVersion != ADB_COORDINATE_VERSION)
            throw Error("Main Village calibration is missing or stale.")
        IsBBRunning := false
        IsRunning := true
        StatusText.Value := "Status: Running Main"
        StartBtn.Enabled := false
        PauseBtn.Enabled := true
        LogMessage("Main Village flow started.")
        SetTimer(StartBotLoop, -10)
        return true
    }

    StartBuilderLoop() {
        global IsRunning, IsBBRunning
        global ADBBBCalibrationVersion, ADB_COORDINATE_VERSION
        global StatusText, StartBtn, PauseBtn
        if (ADBBBCalibrationVersion != ADB_COORDINATE_VERSION)
            throw Error("Builder Base calibration is missing or stale.")
        IsRunning := false
        IsBBRunning := true
        StatusText.Value := "Status: Running BB"
        StartBtn.Enabled := false
        PauseBtn.Enabled := true
        LogMessage("Builder Base flow started.")
        SetTimer(RunBuilderBaseLoop, -100)
        return true
    }

    TapCollector(index) {
        global CollectorCoords
        if (index < 1 || index > CollectorCoords.Length)
            throw Error("Collector index is outside calibrated coordinates.")
        point := CollectorCoords[index]
        return RunADBTapAt(point.x, point.y, 250)
    }

    OpenUpgradeMenu(menuKind) {
        global BuilderFaceX, BuilderFaceY, LabFaceX, LabFaceY
        if (menuKind == "builder")
            tapped := RunADBTapAt(BuilderFaceX, BuilderFaceY, 200)
        else
            tapped := RunADBTapAt(LabFaceX, LabFaceY, 200)
        if !tapped || !SafeFlowWait(1200)
            throw Error("Could not open the " menuKind " upgrade menu.")
        return true
    }

    TapSuggestion(suggestion) {
        if !IsObject(suggestion)
            throw Error("Suggested upgrade did not include a client point.")
        if !RunADBTapAt(suggestion.x, suggestion.y, 200)
            throw Error("Could not tap the suggested upgrade.")
        if !SafeFlowWait(2000)
            throw Error("Bot stopped while the suggested upgrade opened.")
        return true
    }

    TapBuilderInfo(info) {
        if !IsObject(info)
            throw Error("Info template match did not include a client point.")
        if !RunADBTapAt(info.x, info.y, 200)
            throw Error("Could not tap the matched Info button.")
        if !SafeFlowWait(1200)
            throw Error("Bot stopped while the Info panel opened.")
        return true
    }

    TapUpgradeConfirm() {
        global UpgradeConfirmX, UpgradeConfirmY
        nominalPoint := ClientToADBPoint(
            UpgradeConfirmX,
            UpgradeConfirmY
        )
        LogMessage(
            "Upgrade confirmation: calibrated client ("
                UpgradeConfirmX ", " UpgradeConfirmY
                ") translates to nominal ADB ("
                nominalPoint.x ", " nominalPoint.y ")."
        )
        actualPoint := RunADBTapAt(
            UpgradeConfirmX,
            UpgradeConfirmY,
            200
        )
        if !IsObject(actualPoint) {
            LogMessage("Upgrade confirmation tap failed.")
            return false
        }
        LogMessage(
            "Upgrade confirmation tap: client ("
                UpgradeConfirmX ", " UpgradeConfirmY
                "), nominal ADB (" nominalPoint.x ", "
                nominalPoint.y "), randomized ADB actually sent ("
                actualPoint.x ", " actualPoint.y
                "). ADB command accepted."
        )
        return actualPoint
    }

    TapMainAttack() {
        global AttackBtnX, AttackBtnY
        return RunADBTapAt(AttackBtnX, AttackBtnY, 200)
    }

    TapFindMatch() {
        global FindMatchBtnX, FindMatchBtnY
        return RunADBTapAt(FindMatchBtnX, FindMatchBtnY, 800)
    }

    TapAttackStart() {
        global AttackStartBtnX, AttackStartBtnY
        return RunADBTapAt(AttackStartBtnX, AttackStartBtnY, 1000)
    }

    TapNextMatch() {
        global NextMatchBtnX, NextMatchBtnY
        return RunADBTapAt(NextMatchBtnX, NextMatchBtnY, 200)
    }

    TapReturnHome() {
        global ReturnHomeClickX, ReturnHomeClickY
        return RunADBTapAt(ReturnHomeClickX, ReturnHomeClickY, 200)
    }

    Wait(milliseconds) {
        if !SafeFlowWait(milliseconds)
            throw Error("Bot stopped during a flow wait.")
        return true
    }

    DeployMain(key, sideName) {
        global Sides
        sideIndex := Integer(SubStr(sideName, 5))
        side := Sides[sideIndex]
        if (key == "1" || key == "2" || key == "3") {
            if !IsObject(this.TroopCounts)
                this.TroopCounts := GetTroopCountsBattle()
            slot := Integer(key)
            count := this.TroopCounts[slot]
            if (count <= 0)
                return true
            clickCount := Max(1, Round(count * 1.1))
            delayMs := Max(20, 2000 // clickCount)
            DeployTroopLine(
                key,
                clickCount,
                delayMs,
                side.startX,
                side.startY,
                side.endX,
                side.endY
            )
            return true
        }
        DeploySinglePoint(key, side.startX, side.startY)
        return true
    }

    DeploySpell(key, sideName, adbShiftPixels) {
        global Sides
        sideIndex := Integer(SubStr(sideName, 5))
        clickCount := key == "a" ? 7 : 2
        DeployShiftedSpellLine(
            key,
            clickCount,
            Sides[sideIndex],
            adbShiftPixels,
            750
        )
        return true
    }

    RecordCompletedAttack(village) {
        global SessionCompletedAttacks
        if (village != "main" && village != "builder")
            throw Error("Completed attack village must be main or builder.")
        SessionCompletedAttacks += 1
        LogMessage(
            "Session completed attacks: " SessionCompletedAttacks
                " (latest: " village ")."
        )
        return SessionCompletedAttacks
    }

    ExitGameAfterTimer() {
        global ADBViewportLeft, ADBViewportTop
        global ADBViewportRight, ADBViewportBottom

        okayPoint := ResolveTimerExitOkayClientPoint(
            ADBViewportLeft,
            ADBViewportTop,
            ADBViewportRight,
            ADBViewportBottom
        )
        nominalPoint := ClientToADBPoint(okayPoint.x, okayPoint.y)
        LogMessage(
            "Timer exit: Okay target uses viewport-relative client ("
                okayPoint.x ", " okayPoint.y
                "), nominal ADB (" nominalPoint.x ", "
                nominalPoint.y ")."
        )
        LogMessage("Timer exit: sending Escape through ADB.")
        if !SendKey("ESCAPE")
            throw Error("Timer exit could not send Escape.")
        LogMessage(
            "Timer exit: tapping the green Okay button through ADB."
        )
        actualPoint := RunADBTapAt(
            okayPoint.x,
            okayPoint.y,
            650
        )
        if !IsObject(actualPoint)
            throw Error("Timer exit could not tap the Okay button.")
        LogMessage(
            "Timer exit Okay tap: client (" okayPoint.x ", "
                okayPoint.y "), nominal ADB (" nominalPoint.x ", "
                nominalPoint.y "), randomized ADB actually sent ("
                actualPoint.x ", " actualPoint.y ")."
        )
        return actualPoint
    }

    StopBot() {
        global IsRunning, IsBBRunning
        IsRunning := false
        IsBBRunning := false
        return true
    }
}

CompleteLiveGlobalCycle(village) {
    return ADBRefactorFlowAPI.RunCycleCompletion(
        LiveADBFlowPrimitives(),
        {currentVillage: village}
    )
}

FindReloadActionFromADBFrame(frame) {
    framePath := LiveADBFlowPrimitives().RequireFramePath(frame, "reload")
    viewport := GetADBClientViewportRect()
    searchX := Round(viewport.x + viewport.width * 0.25)
    searchY := Round(viewport.y + viewport.height * 0.40)
    searchW := Max(1, Round(viewport.width * 0.50))
    searchH := Max(1, Round(viewport.height * 0.40))
    processId := DllCall("GetCurrentProcessId", "uint")
    imagePath := (
        A_Temp "\coc_reload_recovery_" processId "_"
            A_TickCount ".png"
    )
    try {
        adbCrop := SaveADBFrameRegionToPNG(
            framePath,
            searchX,
            searchY,
            searchW,
            searchH,
            imagePath
        )
        result := OCR.FromFile(imagePath, {scale: 1.5})
        for line in result.Lines {
            if !IsExplicitReloadActionText(line.Text)
                continue
            clientPoint := ADBFramePointToClient(
                adbCrop,
                line.x + line.w / 2,
                line.y + line.h / 2
            )
            actionName := Trim(line.Text, " `t`r`n")
            LogMessage(
                "Reconnect OCR: explicit action '" actionName
                    "' at client (" clientPoint.x ", "
                    clientPoint.y ")."
            )
            return {
                name: actionName,
                x: clientPoint.x,
                y: clientPoint.y
            }
        }
        LogMessage("Reconnect OCR: no explicit Reload/Retry action found.")
        return false
    } finally {
        try FileDelete(imagePath)
    }
}

TapLiveReloadAction(action) {
    if (!IsObject(action)
        || !action.HasOwnProp("x")
        || !action.HasOwnProp("y")) {
        throw Error("Reload action is missing its client point.")
    }
    tapped := RunADBTapAt(action.x, action.y, 300)
    if !IsObject(tapped)
        throw Error("Could not tap the explicit Reload/Retry action.")
    return tapped
}

RouteLiveVillage(village) {
    global IsRunning, IsBBRunning
    global StatusText, StartBtn, PauseBtn
    global ADBMainCalibrationVersion, ADBBBCalibrationVersion
    global ADB_COORDINATE_VERSION
    if (village == "main") {
        if (ADBMainCalibrationVersion != ADB_COORDINATE_VERSION) {
            throw Error(
                "Reconnect cannot route Main Village: calibration is "
                    "missing or stale."
            )
        }
        IsBBRunning := false
        IsRunning := true
        StatusText.Value := "Status: Running Main"
        LogMessage("Reconnect route: scheduling Main Village flow.")
        SetTimer(StartBotLoop, -10)
    } else if (village == "builder") {
        if (ADBBBCalibrationVersion != ADB_COORDINATE_VERSION) {
            throw Error(
                "Reconnect cannot route Builder Base: calibration is "
                    "missing or stale."
            )
        }
        IsRunning := false
        IsBBRunning := true
        StatusText.Value := "Status: Running BB"
        LogMessage("Reconnect route: scheduling Builder Base flow.")
        SetTimer(RunBuilderBaseLoop, -100)
    } else {
        throw Error("Reconnect route must be main or builder.")
    }
    StartBtn.Enabled := false
    PauseBtn.Enabled := true
    return true
}

StartBotLoop() {
    global IsRunning, IsBBRunning, SessionCompletedAttacks
    global CollectorCoords, EnableWallUpgrade, MinGold, MinElixir
    global TimerDurationMs, StatusText, StartBtn, PauseBtn
    operations := CreateADBMainFlowSections(LiveADBFlowPrimitives())
    while IsRunning {
        state := {
            completedAttacks: SessionCompletedAttacks,
            collectorCount: CollectorCoords.Length,
            wallUpgradesEnabled: EnableWallUpgrade,
            minGold: MinGold,
            minElixir: MinElixir,
            timerEnabled: TimerDurationMs > 0
        }
        try {
            ADBRefactorFlowAPI.RunMainLoop(operations, state)
        } catch as err {
            if IsRunning
                LogMessage("Main Village flow stopped: " err.Message)
            IsRunning := false
        }
    }
    if !IsBBRunning {
        StatusText.Value := "Status: Idle"
        StartBtn.Enabled := true
        PauseBtn.Enabled := false
        LogMessage("Main Village flow ended.")
    } else {
        LogMessage("Main Village flow handed control to Builder Base.")
    }
}

LegacyStartBotLoop() {
    global IsRunning, StatusText, StartBtn, PauseBtn
    global AttackBtnX, AttackBtnY, FindMatchBtnX, FindMatchBtnY, AttackStartBtnX, AttackStartBtnY
    global ReturnHomeClickX, ReturnHomeClickY, BattleLoadDelay, ReturnHomeColor, ReturnHomeTolerance
    global EnableLootSearch, MinGold, MinElixir, NextMatchBtnX, NextMatchBtnY
    ; Check for game timeout immediately before doing anything else
    LastTimeoutCheck := A_TickCount
    CheckGameTimeout(true)
    ; Send an ADB tap without activating the emulator window.
    if WinExist(TargetWindowTitle) {
        LogMessage("Performing initial ADB focus clicks inside viewport...")
        ClearingClick()
    } else {
        LogMessage("Error: Game window not found. Skipping initial focus click.")
    }
    Loop {
        if !IsRunning
            break
        ; Check for game timeout every 20 minutes (before anything else in the loop)
        if (A_TickCount - LastTimeoutCheck > 1200000) { ; 20 minutes
            LastTimeoutCheck := A_TickCount
            CheckGameTimeout()
            if !IsRunning
                break
        }
        ; 1. Clearing Click to close any open menus
        ClearingClick()
        ; 3. Reset viewport before resource collection
        ResetViewport()
        ; Check if Auto-Stop Timer has elapsed
        if IsTimerUp() {
            LogMessage("Auto-Stop Timer elapsed! Stopping bot after cycle completed.")
            PauseBot()
            break
        }
        ; Collector resource farming (1 in 2 chance for testing)
        CollectResources()

        if !IsRunning
            break
        ; Lab upgrade farming
        if !IsLabBusy() {
            elixirFilled := IsElixirBarFilled(ElixirBarThreshX, ElixirBarThreshY)
            darkFilled := IsDarkElixirBarFilled(DarkElixirBarThreshX, DarkElixirBarThreshY)
            LogMessage(Format("Lab Upgrade Threshold Check: Elixir={}, DarkElixir={}", elixirFilled ? "YES" : "NO", darkFilled ? "YES" : "NO"))
            if (elixirFilled && darkFilled) {
                UpgradeLab()
            }
        }
        if !IsRunning
            break
            
        ; Building upgrades farming (triggered if there is a free builder and all three resources are filled)
        if CanUpgradeBuilding() {
            goldFilled := IsGoldBarFilled(GoldBarThreshX, GoldBarThreshY)
            elixirFilled := IsElixirBarFilled(ElixirBarThreshX, ElixirBarThreshY)
            darkFilled := IsDarkElixirBarFilled(DarkElixirBarThreshX, DarkElixirBarThreshY)
            LogMessage(Format("Building Upgrade Threshold Check: Gold={}, Elixir={}, DarkElixir={}", goldFilled ? "YES" : "NO", elixirFilled ? "YES" : "NO", darkFilled ? "YES" : "NO"))
            if (goldFilled && elixirFilled && darkFilled) {
                UpgradeBuilding()
            }
        }
        if !IsRunning
            break
        ; Wall upgrades farming
        UpgradeWalls()
        if !IsRunning
            break
        ; Step 1: Click the bottom-left "Attack" button (from Home Village)
        LogMessage("Step 1: Clicking Attack...")
        ADBClickPoint(AttackBtnX, AttackBtnY)
        if !SafeSleep(800)
            break
        ; Step 2: Click the gold "Find a Match" button (from Multiplayer dialog)
        LogMessage("Step 2: Clicking Find a Match...")
        ADBClickPoint(FindMatchBtnX, FindMatchBtnY)
        if !SafeSleep(1000) ; Wait for My Army dialog to open fully
            break
        ; Step 3: Click the green "Attack!" button (from My Army dialog)
        LogMessage("Step 3: Clicking Green Attack...")
        ADBClickPoint(AttackStartBtnX, AttackStartBtnY)
        LogMessage("Waiting 7s for matchmaking transition...")
        if !SafeSleep(7000)
            break
        ; Verify we successfully left the Home Village (menus didn't get stuck)
        if IsAtHomeVillage() {
            LogMessage("WARNING: Failed to enter matchmaking search. Menu click missed. Retrying...")
            continue
        }
    WaitForClouds:
        if AreCloudsPresent() {
            LogMessage("Step 4: Waiting for match / clouds to clear...")
            while AreCloudsPresent() {
                if !SafeSleep(5000)
                    goto LoopExit
                CheckGameTimeout()
            }
        }
        ; Check if we were kicked back to the Home Village (e.g. out of gold or error)
        if IsAtHomeVillage() {
            LogMessage("Farming: Detected back at Home Village during match search. Restarting cycle...")
            continue
        }
        ; Wait for enemy layout to render
        LogMessage("Waiting for map to load...")
        if !SafeSleep(BattleLoadDelay)
            break
        ; (Loot check moved to after ResetViewport so OCR runs on a calibrated view)
        ; Step 5: Choose a random side for the attack sequence
        sideIndex := Random(1, 4)
        side := Sides[sideIndex]
        lineStartX := side.startX
        lineStartY := side.startY
        lineEndX := side.endX
        lineEndY := side.endY
        ; Shift spell line towards the center of the window by 200 pixels
        spellStart := ShiftPointTowardsCenter(lineStartX, lineStartY, 200)
        spellEnd := ShiftPointTowardsCenter(lineEndX, lineEndY, 200)
        aLineStartX := spellStart.x
        aLineStartY := spellStart.y
        aLineEndX := spellEnd.x
        aLineEndY := spellEnd.y
        ; Use the outer start point for single hero/siege deployments to stay far outside the red zone
        midX := lineStartX
        midY := lineStartY
        LogMessage("Step 5: Selected Side " sideIndex " for deployment.")
        ; Reset viewport in battle so that the deployment lines align with calibration
        ResetViewport()
        ; Optional OCR Loot search check (after viewport calibration for cleaner OCR)
        if EnableLootSearch {
            LogMessage("Farming: Scanning base loot amounts (post-viewport)...")
            if !SafeSleep(800) ; Wait for numbers to render fully
                break
            gold := 0
            elixir := 0
            GetLootValues(&gold, &elixir)
            if (gold < MinGold && elixir < MinElixir) {
                if IsAtHomeVillage() {
                    LogMessage("Farming: Detected Home Village during search. Restarting cycle...")
                    continue
                }
                LogMessage(Format("Farming: Loot too low (G:{}/E:{}). Skipping base...", gold, elixir))
                ADBClickPoint(NextMatchBtnX, NextMatchBtnY)
                if !SafeSleep(1500) ; Wait for cloud transition to start
                    break
                goto WaitForClouds
            }
            LogMessage(Format("Farming: Loot threshold met (G:{}/E:{}). Launching attack!", gold, elixir))
        }
        ; Scan troop counts from the battle bar
        LogMessage("Scanning battle troop counts...")
        activeCounts := GetTroopCountsBattle()
        ; 1. Deploy Troop 1 (if count > 0)
        t1Count := activeCounts[1]
        if (t1Count > 0) {
            clickCount1 := Round(t1Count * 1.1)
            delayMs1 := 2000 // clickCount1
            if (delayMs1 < 20)
                delayMs1 := 20
            LogMessage(Format("Deploying Troop 1 ({}x, using {} clicks, delay {}ms)...", t1Count, clickCount1, delayMs1))
            DeployTroopLine("1", clickCount1, delayMs1, lineStartX, lineStartY, lineEndX, lineEndY)
            if !IsRunning
                break
        }
        ; 2. Deploy Troop 2 (if count > 0)
        t2Count := activeCounts[2]
        if (t2Count > 0) {
            clickCount2 := Round(t2Count * 1.1)
            delayMs2 := 2000 // clickCount2
            if (delayMs2 < 20)
                delayMs2 := 20
            LogMessage(Format("Deploying Troop 2 ({}x, using {} clicks, delay {}ms)...", t2Count, clickCount2, delayMs2))
            DeployTroopLine("2", clickCount2, delayMs2, lineStartX, lineStartY, lineEndX, lineEndY)
            if !IsRunning
                break
        }
        ; 3. Deploy Troop 3 (if count > 0)
        t3Count := activeCounts[3]
        if (t3Count > 0) {
            clickCount3 := Round(t3Count * 1.1)
            delayMs3 := 2000 // clickCount3
            if (delayMs3 < 20)
                delayMs3 := 20
            LogMessage(Format("Deploying Troop 3 ({}x, using {} clicks, delay {}ms)...", t3Count, clickCount3, delayMs3))
            DeployTroopLine("3", clickCount3, delayMs3, lineStartX, lineStartY, lineEndX, lineEndY)
            if !IsRunning
                break
        }
        ; 4. Deploy Siege Machine (z)
        LogMessage("Deploying Siege Machine (z)...")
        DeploySinglePoint("z", midX, midY)
        if !IsRunning
            break
        ; 5. Deploy Heroes (q, w, e, r)
        LogMessage("Deploying Heroes (q, w, e, r)...")
        DeploySinglePoint("q", midX, midY)
        DeploySinglePoint("w", midX, midY)
        DeploySinglePoint("e", midX, midY)
        DeploySinglePoint("r", midX, midY)
        if !IsRunning
            break
        ; 6. Deploy Spell (a)
        LogMessage("Deploying Spell (a)...")
        DeploySingleLine("a", 7, aLineStartX, aLineStartY, aLineEndX, aLineEndY, 750)
        DeploySingleLine("s", 2, aLineStartX, aLineStartY, aLineEndX, aLineEndY, 750)
        if !IsRunning
            break
        ; Step 6: Wait for battle to progress, then trigger Hero abilities via ADB
        LogMessage("Step 6: Battle in progress... waiting 30s")
        if !SafeSleep(30000)
            break
        LogMessage("Triggering Hero Abilities via background ADB (q, w, e, r)...")
        SendKey("q")
        SendKey("w")
        SendKey("e")
        SendKey("r")
        LogMessage("Step 6: Periodically checking for Return Home...")
        while !IsAtHomeVillage() {
            if !IsRunning
                goto LoopExit
            ADBClickPoint(ReturnHomeClickX, ReturnHomeClickY)
            if !SafeSleep(2000)
                goto LoopExit
            ; Unconditionally click where the Star Bonus "Okay" button would be
            WinGetClientPos ,, &cw, &ch, TargetWindowTitle
            if (cw && ch) {
                ADBClickFraction(0.5, 0.77)
                SafeSleep(400)
            }
            ; Dismiss Star Bonus or other post-battle popup screens
            ClearingClick()
            if IsAtHomeVillage()
                break
            CheckGameTimeout()
            ; Wait the rest of the ~15s cycle before clicking again
            if !SafeSleep(Random(12000, 14000))
                goto LoopExit
        }
        LogMessage("Step 7: Back at Home Village! Reloading...")
        if !SafeSleep(2000)
            break
        LogMessage("Cycle completed successfully. Starting next cycle.")
    }
LoopExit:
    ; Reset UI buttons and status
    IsRunning := false
    StatusText.Text := "STATUS: IDLE"
    StatusText.SetFont("cDefault")
    StartBtn.Enabled := true
    PauseBtn.Enabled := false
    LogMessage("Bot loop stopped.")
}
IsTimerUp() {
    global TimerDurationMs, TimerStartTick
    if (TimerDurationMs <= 0)
        return false
    elapsed := A_TickCount - TimerStartTick
    return elapsed >= TimerDurationMs
}

; ==============================================================================
; HELPER FUNCTIONS
; ==============================================================================
ClearingClick() {
    return FlowClearTap()
}

FlowClearTap() {
    global ClearTapX, ClearTapY
    return RunADBClearTapAt(ClearTapX, ClearTapY, 200)
}

SafeSleep(ms) {
    global IsRunning, IsBBRunning
    loopCount := ms // 100
    remainder := Mod(ms, 100)
    Loop loopCount {
        if !(IsRunning || IsBBRunning)
            return false
        Sleep 100
    }
    if remainder > 0 {
        if !(IsRunning || IsBBRunning)
            return false
        Sleep remainder
    }
    return (IsRunning || IsBBRunning)
}

SafeFlowWait(intendedDelayMs) {
    timing := GetADBActionTiming(intendedDelayMs)
    if !SafeSleep(timing.PreDelay)
        return false
    jitter := Random(timing.JitterMin, timing.JitterMax)
    return jitter == 0 ? true : SafeSleep(jitter)
}

RandomizedDelay(intendedDelayMs) {
    timing := GetADBActionTiming(intendedDelayMs)
    if (timing.PreDelay > 0)
        Sleep(timing.PreDelay)
    jitter := Random(timing.JitterMin, timing.JitterMax)
    if (jitter > 0)
        Sleep(jitter)
}

RandomADBClick(x, y, delta) {
    return RunADBTapAt(Round(x), Round(y), 100)
}
ADBClickPoint(x, y, delta := "") {
    return RandomADBClick(x, y, delta)
}
ADBClickFraction(xRatio, yRatio, delta := "") {
    point := ClientViewportPointFromFraction(xRatio, yRatio)
    return ADBClickPoint(point.x, point.y, delta)
}
ClientClickPoint(x, y, delta := "") {
    return ADBClickPoint(x, y, delta)
}
SendKey(keyName) {
    try {
        interaction := CreateLiveADBClientInteraction()
        keyCode := RegExMatch(keyName, "^\d$") ? "KEYCODE_" keyName : "KEYCODE_" StrUpper(keyName)
        WaitForADBActionPreDelay(100)
        interaction.KeyEvent(keyCode, 100)
        return true
    } catch as err {
        LogMessage("ADB key failed: " err.Message)
        return false
    }
}
DeployTroopLine(hotkeyName, clickCount, delayMs, startX, startY, endX, endY) {
    global IsRunning
    if !IsRunning
        return
    SendKey(hotkeyName)
    if !SafeFlowWait(150)
        return
    Loop clickCount {
        if !IsRunning
            break
        t := (clickCount > 1) ? (A_Index - 1) / (clickCount - 1) : 0
        rx := startX + t * (endX - startX)
        ry := startY + t * (endY - startY)
        if !RunADBTapAt(rx, ry, delayMs)
            break
    }
    SafeFlowWait(300)
}
DeploySinglePoint(hotkeyName, x, y) {
    global IsRunning
    if !IsRunning
        return
    SendKey(hotkeyName)
    if !RunADBTapAt(x, y, 350)
        return
    SafeFlowWait(150)
}
DeploySingleLine(hotkeyName, clickCount, startX, startY, endX, endY, clickDelay := 150) {
    global IsRunning, DeployDelta
    if !IsRunning
        return
    SendKey(hotkeyName)
    if !SafeSleep(750)
        return
    Loop clickCount {
        if !IsRunning
            break
        t := (clickCount > 1) ? (A_Index - 1) / (clickCount - 1) : 0.5
        rx := startX + t * (endX - startX)
        ry := startY + t * (endY - startY)
        RandomADBClick(rx, ry, DeployDelta)
        if !SafeSleep(clickDelay)
            break
    }
}

DeployShiftedSpellLine(hotkeyName, clickCount, side, adbShiftPixels, clickDelay := 750) {
    global IsRunning
    if !IsRunning
        return
    SendKey(hotkeyName)
    if !SafeFlowWait(750)
        return
    Loop clickCount {
        if !IsRunning
            return
        t := clickCount > 1 ? (A_Index - 1) / (clickCount - 1) : 0.5
        clientX := side.startX + t * (side.endX - side.startX)
        clientY := side.startY + t * (side.endY - side.startY)
        if !RunADBShiftedPlacementAt(
            clientX,
            clientY,
            adbShiftPixels,
            clickDelay
        )
            return
    }
}

IsGolden(x, y) {
    try {
        offsetsX := [-7, -3, 0, 3, 7]
        offsetsY := [-7, -3, 0, 3, 7]
        for dx in offsetsX {
            for dy in offsetsY {
                c := GetADBPixelColor(x + dx, y + dy)
                hx := Integer(c)
                r := (hx >> 16) & 0xFF
                g := (hx >> 8) & 0xFF
                b := hx & 0xFF
                if (r > 130) && (g > 100) && (r > b + 15) && (g > b - 30)
                    return true
            }
        }
        return false
    } catch {
        return false
    }
}
AreCloudsPresent() {
    global CloudPt1X, CloudPt1Y, CloudPt2X, CloudPt2Y, CloudPt3X, CloudPt3Y, CloudPt4X, CloudPt4Y, CloudGreyTolerance
    greyCount := 0
    if IsGrey(CloudPt1X, CloudPt1Y, CloudGreyTolerance)
        greyCount++
    if IsGrey(CloudPt2X, CloudPt2Y, CloudGreyTolerance)
        greyCount++
    if IsGrey(CloudPt3X, CloudPt3Y, CloudGreyTolerance)
        greyCount++
    if IsGrey(CloudPt4X, CloudPt4Y, CloudGreyTolerance)
        greyCount++
    return greyCount >= 3
}
IsAttackBtnColor(r, g, b) {
    ; 1. Brown Wood Shield Background (e.g. RGB 140, 75, 30)
    isBrownWood := (r > g) && (g > b) && (r - b >= 25) && (g - b >= 10) && (r >= 70 && r <= 250)
    ; 2. Tan / Beige / Yellow Paper Map (e.g. RGB 245, 220, 175)
    isTanMap := (r >= 180) && (g >= 140) && (b >= 90) && (r >= g) && (g >= b * 0.75)
    return isBrownWood || isTanMap
}

IsAttackBtnPresentADB(x, y) {
    try {
        c := GetADBPixelColor(x, y)
        actualHex := Integer(c)
        r := (actualHex >> 16) & 0xFF
        g := (actualHex >> 8) & 0xFF
        b := actualHex & 0xFF
        return IsAttackBtnColor(r, g, b)
    } catch {
        return false
    }
}

IsAtHomeVillage() {
    isHome := IsAttackBtnPresentADB(AttackBtnX - 45, AttackBtnY) || IsAttackBtnPresentADB(AttackBtnX + 45, AttackBtnY)
    if !isHome
        return false
    Sleep 300
    isHome := IsAttackBtnPresentADB(AttackBtnX - 45, AttackBtnY) || IsAttackBtnPresentADB(AttackBtnX + 45, AttackBtnY)
    if !isHome
        return false
    if !IsWarLogoPresent()
        return false
    return true
}
IsWarLogoColor(r, g, b) {
    ; 1. Silver / White Sword Blades (e.g. RGB 240, 235, 225)
    isSilverSword := (r >= 150) && (g >= 150) && (b >= 130) && (Abs(r - g) <= 40) && (Abs(g - b) <= 40)
    ; 2. Brown Wood Shield (e.g. RGB 140, 75, 30)
    isBrownWood := (r > g) && (g > b) && (r - b >= 20) && (g - b >= 5) && (r >= 70 && r <= 250)
    ; 3. Gold / Orange Outer Frame (e.g. RGB 245, 175, 50)
    isGoldFrame := (r >= 180) && (g >= 110) && (b <= 130) && (r > g + 15)
    return isSilverSword || isBrownWood || isGoldFrame
}

IsWarLogoPresentADB(x, y) {
    ; Check center and 4 diagonal offset points (+/- 20px)
    offsets := [{x:0, y:0}, {x:-20, y:-20}, {x:20, y:-20}, {x:-20, y:20}, {x:20, y:20}]
    for pt in offsets {
        try {
            c := GetADBPixelColor(x + pt.x, y + pt.y)
            actualHex := Integer(c)
            r := (actualHex >> 16) & 0xFF
            g := (actualHex >> 8) & 0xFF
            b := actualHex & 0xFF
            if IsWarLogoColor(r, g, b)
                return true
        }
    }
    return false
}

IsWarLogoPresent() {
    targetX := (WarLogoX > 0) ? WarLogoX : ((MVLogoX > 0) ? MVLogoX : WarLogoX)
    targetY := (WarLogoY > 0) ? WarLogoY : ((MVLogoY > 0) ? MVLogoY : WarLogoY)
    return IsWarLogoPresentADB(targetX, targetY)
}
IsAtBuilderBase() {
    hasAttackBtn := IsAttackBtnPresentADB(BBAttackBtnX - 45, BBAttackBtnY) || IsAttackBtnPresentADB(BBAttackBtnX + 45, BBAttackBtnY)
    return hasAttackBtn && !IsWarLogoPresent()
}
DeployBBTroops(side, phase) {
    global DeployDelta, BBClickCount
    keys := ["q", "1", "2", "3", "4", "5", "6", "7", "8"]
    numKeys := keys.Length
    LogMessage(Format("Starting Phase {} troop deployment ({} slots)...", phase, numKeys))
    for keyIndex, key in keys {
        LogMessage(Format("Phase {} Troop Slot {}/{} (Key: '{}')", phase, keyIndex, numKeys, key))
        SendKey(key)
        SafeSleep(175)
        slotT := (keyIndex - 1) * 0.1
        clickCount := BBClickCount
        Loop clickCount {
            t := slotT
            if (clickCount > 1) {
                spread := 0.15 / (clickCount - 1)
                t := slotT - 0.075 + (A_Index - 1) * spread
                t := Max(0.0, Min(1.0, t))
            }
            rx := side.startX + t * (side.endX - side.startX)
            ry := side.startY + t * (side.endY - side.startY)
            display := GetADBDisplaySize()
            ry := Min(ry, Round(display.height * 0.83))
            RandomADBClick(rx, ry, DeployDelta)
            SafeSleep(100)
        }
    }
    LogMessage(Format("Phase {} troop deployment complete.", phase))
}
class LiveBuilderBasePrimitives {
    __New() {
        this.DeploymentPhase := 0
    }

    Do(name, args*) {
        switch name {
            case "log":
                LogMessage(args[1])
                return true
            case "is_builder_running":
                global IsBBRunning
                return IsBBRunning
            case "tap_builder_attack":
                global BBAttackBtnX, BBAttackBtnY
                this.DeploymentPhase := 0
                return RunADBTapAt(BBAttackBtnX, BBAttackBtnY, 300)
            case "tap_builder_find_match":
                global BBFindMatchBtnX, BBFindMatchBtnY
                return RunADBTapAt(BBFindMatchBtnX, BBFindMatchBtnY, 500)
            case "wait":
                return SafeSleep(args[1])
            case "prepare_builder_viewport":
                ZoomOutBB()
                return true
            case "random_builder_side":
                global BBSides
                if (BBSides.Length == 0)
                    throw Error("No calibrated Builder Base deployment sides exist.")
                return Random(1, BBSides.Length)
            case "deploy_builder_troops":
                global BBSides
                sideIndex := args[1]
                if (sideIndex < 1 || sideIndex > BBSides.Length)
                    throw Error("Builder Base deployment side is invalid.")
                this.DeploymentPhase := this.DeploymentPhase == 1 ? 2 : 1
                DeployBBTroops(
                    BBSides[sideIndex],
                    this.DeploymentPhase
                )
                return true
            case "capture_builder_frame":
                return CaptureLiveBuilderBaseFrame(args[1])
            case "analyze_builder_three_stars":
                return AnalyzeLiveBuilderBaseThreeStars(args[1])
            case "tap_return_home":
                global ReturnHomeClickX, ReturnHomeClickY
                return RunADBTapAt(
                    ReturnHomeClickX,
                    ReturnHomeClickY,
                    300
                )
            case "detect_builder_home_from_frame":
                return DetectLiveBuilderBaseHome(args[1])
            case "complete_global_cycle":
                return CompleteLiveGlobalCycle(args[1])
        }
        throw Error("Unknown live Builder Base operation: " name)
    }
}

CaptureLiveBuilderBaseFrame(section) {
    if (section == "")
        throw Error("A Builder Base capture section is required.")
    framePath := CaptureADBFrame(true)
    if !IsLiveBuilderBasePNG(framePath) {
        LogMessage(
            "Fresh Builder Base " section
                " frame was invalid; retrying synchronously."
        )
        return false
    }
    return {
        valid: true,
        path: framePath,
        section: section,
        capturedAt: A_TickCount
    }
}

IsLiveBuilderBasePNG(framePath) {
    if (framePath == "" || !FileExist(framePath) || FileGetSize(framePath) < 8)
        return false
    file := FileOpen(framePath, "r")
    if !IsObject(file)
        return false
    expected := [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    try {
        Loop 8 {
            if (file.ReadUChar() != expected[A_Index])
                return false
        }
        return true
    } finally {
        file.Close()
    }
}

AnalyzeLiveBuilderBaseThreeStars(frame) {
    global BBStar1X, BBStar1Y, BBStar2X, BBStar2Y, BBStar3X, BBStar3Y
    if !IsObject(frame) || !frame.HasOwnProp("path")
        return false
    if !IsLiveBuilderBasePNG(frame.path)
        return false

    stars := [
        {x: BBStar1X, y: BBStar1Y},
        {x: BBStar2X, y: BBStar2Y},
        {x: BBStar3X, y: BBStar3Y}
    ]
    InitGDIPlus()
    bitmap := 0
    if DllCall(
        "gdiplus\GdipCreateBitmapFromFile",
        "wstr",
        frame.path,
        "ptr*",
        &bitmap
    ) != 0
        return false

    goldenCount := 0
    try {
        for index, star in stars {
            adbPoint := ClientToADBPoint(star.x, star.y)
            isGolden := IsLiveBuilderBaseGoldenStar(
                bitmap,
                adbPoint.x,
                adbPoint.y
            )
            if isGolden
                goldenCount += 1
            centerColor := ReadLiveBuilderBasePixel(
                bitmap,
                adbPoint.x,
                adbPoint.y
            )
            LogMessage(
                "Builder Base star " index ": #"
                    Format("{:06X}", centerColor) " at ADB("
                    adbPoint.x "," adbPoint.y ") "
                    (isGolden ? "GOLD" : "BRONZE") "."
            )
        }
    } finally {
        DllCall("gdiplus\GdipDisposeImage", "ptr", bitmap)
    }
    LogMessage("Builder Base star analysis: " goldenCount "/3 gold.")
    return goldenCount == 3
}

IsLiveBuilderBaseGoldenStar(bitmap, centerX, centerY) {
    for dx in [-7, -3, 0, 3, 7] {
        for dy in [-7, -3, 0, 3, 7] {
            color := ReadLiveBuilderBasePixel(
                bitmap,
                centerX + dx,
                centerY + dy
            )
            if IsLiveBuilderBaseGoldenColor(color)
                return true
        }
    }
    return false
}

IsLiveBuilderBaseGoldenColor(color) {
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    return (r > 130) && (g > 100)
        && (r > b + 15) && (g > b - 30)
}

ReadLiveBuilderBasePixel(bitmap, x, y) {
    color := 0
    status := DllCall(
        "gdiplus\GdipBitmapGetPixel",
        "ptr",
        bitmap,
        "int",
        Round(x),
        "int",
        Round(y),
        "uint*",
        &color
    )
    if (status != 0)
        return 0
    return color & 0xFFFFFF
}

DetectLiveBuilderBaseHome(frame) {
    if !IsObject(frame) || !frame.HasOwnProp("path")
        return false
    if !IsLiveBuilderBasePNG(frame.path)
        return false
    return DetectVillageFromADBFrame(frame.path) == "builder"
}

RunBuilderBaseLoop() {
    global IsRunning, IsBBRunning, StatusText, StartBtn, PauseBtn
    LogMessage("--- Starting Builder Base Loop ---")
    try {
        flow := BuilderBaseFlow(LiveBuilderBasePrimitives())
        flow.RunLoop()
    } catch as err {
        LogMessage(
            "Builder Base loop failed: " err.Message
                " | " err.File ":" err.Line
        )
    } finally {
        LogMessage("--- Builder Base Loop Stopped ---")
        IsBBRunning := false
        if !IsRunning {
            StatusText.Value := "Status: Stopped"
            StartBtn.Enabled := true
            PauseBtn.Enabled := false
        } else {
            LogMessage("Builder Base flow handed control to Main Village.")
        }
    }
}
ResetViewport() {
    global IsRunning, IsCalibrating
    viewport := GetADBClientViewportRect()
    LogMessage("Viewport: Sending ADB focus tap inside the Android display...")
    ADBClickFraction(0.8, 0.3)
    RandomizedDelay(300)
    LogMessage("Viewport: Zooming all the way out...")
    RunADBPinchAt(viewport.x + viewport.width // 2, viewport.y + viewport.height // 2, 300)
    RandomizedDelay(300)
    LogMessage("Viewport: Scrolling to top-left corner...")
    Loop 6 {
        if !IsRunning && !IsCalibrating
            break
        RunADBSwipeAt(
            Round(viewport.x + viewport.width * 0.25), Round(viewport.y + viewport.height * 0.25),
            Round(viewport.x + viewport.width * 0.75), Round(viewport.y + viewport.height * 0.75),
            200,
            100
        )
        RandomizedDelay(100)
    }
    RandomizedDelay(300)
}
ZoomOutBB() {
    viewport := GetADBClientViewportRect()
    LogMessage("Viewport: Zooming all the way out for Builder Base...")
    RunADBPinchAt(viewport.x + viewport.width // 2, viewport.y + viewport.height // 2, 300)
    RandomizedDelay(300)
}
ShowToolTip(message) {
    ToolTip message
    SetTimer () => ToolTip(), -3000
}
ShiftPointTowardsCenter(x, y, shiftDist := 250) {
    viewport := GetADBClientViewportRect()
    cx := viewport.x + viewport.width // 2
    cy := viewport.y + viewport.height // 2
    dx := cx - x
    dy := cy - y
    dist := Sqrt(dx*dx + dy*dy)
    if (dist > 0) {
        rx := x + (dx / dist) * shiftDist
        ry := y + (dy / dist) * shiftDist
        return {x: Round(rx), y: Round(ry)}
    }
    return {x: x, y: y}
}
; ==============================================================================
; HOTKEYS AND CONTEXT SENSITIVITY
; ==============================================================================
#HotIf IsCalibrating
Space:: {
    global CalibStep, IsCalibrating, CollectorCoords, IsWaitingForReset
    global PendingViewportLeft, PendingViewportTop
    global ADBViewportLeft, ADBViewportTop, ADBViewportRight, ADBViewportBottom
    global ADBViewportClientWidth, ADBViewportClientHeight, ADBViewportProvider, ADBViewportSerial
    global ADBViewportVersion, ADB_VIEWPORT_VERSION, ADBProvider
    global TargetWindowTitle
    global AttackBtnX, AttackBtnY, FindMatchBtnX, FindMatchBtnY, AttackStartBtnX, AttackStartBtnY
    global ReturnHomeClickX, ReturnHomeClickY, ReturnHomeColor
    global WarLogoX, WarLogoY, WarLogoColor
    global BuilderFaceX, BuilderFaceY, BuilderMenuBottomX, BuilderMenuBottomY, LabFaceX, LabFaceY, UpgradeConfirmX, UpgradeConfirmY
    global DarkElixirBarThreshX, DarkElixirBarThreshY, GoldBarThreshX, GoldBarThreshY, ElixirBarThreshX, ElixirBarThreshY
    global GoldAreaX, GoldAreaY, GoldAreaW, GoldAreaH
    global ElixirAreaX, ElixirAreaY, ElixirAreaW, ElixirAreaH
    global GoldIconX, GoldIconY, ElixirIconX, ElixirIconY
    global NextMatchBtnX, NextMatchBtnY
    global UpgradeMoreBtnX, UpgradeMoreBtnY, AddWall1X, AddWall1Y, RemoveWallX, RemoveWallY, GoldUpgradeX, GoldUpgradeY, ElixirUpgradeX, ElixirUpgradeY
    global Side1StartX, Side1StartY, Side1EndX, Side1EndY
    global Side2StartX, Side2StartY, Side2EndX, Side2EndY
    global Side3StartX, Side3StartY, Side3EndX, Side3EndY
    global Side4StartX, Side4StartY, Side4EndX, Side4EndY
    global Sides
    if IsWaitingForReset
        return
    CoordMode "Mouse", "Client"
    if !WinExist(TargetWindowTitle) {
        LogMessage("Calibration Error: Target window not found.")
        return
    }
    WinGetClientPos ,, &clientWidth, &clientHeight, TargetWindowTitle
    MouseGetPos &mx, &my
    if (CalibStep == 1) {
        if (mx < 0 || my < 0 || mx >= clientWidth || my >= clientHeight) {
            LogMessage("Calibration Error: Top-left viewport point must be inside the emulator client.")
            return
        }
        PendingViewportLeft := mx
        PendingViewportTop := my
        LogMessage(Format("Calibrated Android viewport top-left: {}, {}", mx, my))
        CalibStep := 2
        UpdateCalibrationUI()
        return
    }
    if (CalibStep == 2) {
        if !IsADBViewportValid(PendingViewportLeft, PendingViewportTop, mx, my, clientWidth, clientHeight) {
            LogMessage("Calibration Error: Bottom-right viewport point must be below/right of the top-left and inside the client.")
            ShowToolTip("Invalid Android viewport. Select the bottom-right game pixel again.")
            return
        }
        InvalidateADBViewport()
        ADBViewportLeft := PendingViewportLeft
        ADBViewportTop := PendingViewportTop
        ADBViewportRight := mx
        ADBViewportBottom := my
        ADBViewportClientWidth := clientWidth
        ADBViewportClientHeight := clientHeight
        ADBViewportProvider := ADBProvider
        ADBViewportSerial := GetSelectedADBSerial()
        ADBViewportVersion := ADB_VIEWPORT_VERSION
        try {
            display := GetADBDisplaySize()
            ConfigureADBClientMapping(
                ADBViewportLeft,
                ADBViewportTop,
                ADBViewportRight,
                ADBViewportBottom,
                display.width,
                display.height,
                clientWidth,
                clientHeight,
                ADBViewportProvider,
                ADBViewportSerial
            )
        } catch as err {
            InvalidateADBViewport()
            LogMessage("Calibration Error: could not cache client-to-ADB scale: " err.Message)
            ShowToolTip("ADB scale could not be cached. Repeat viewport calibration.")
            CalibStep := 1
            UpdateCalibrationUI()
            return
        }
        LogMessage(Format("Calibrated Android viewport: ({}, {})-({}, {}) within client {}x{}.",
            ADBViewportLeft, ADBViewportTop, ADBViewportRight, ADBViewportBottom, clientWidth, clientHeight))
        CalibStep := 3
        UpdateCalibrationUI()
        return
    }
    ; Store client-relative coordinates only; ADB translation occurs at each read/input boundary.
    switch CalibStep {
        case 3:
            DarkElixirBarThreshX := mx
            DarkElixirBarThreshY := my
            LogMessage(Format("Calibrated Dark Elixir Bar Thresh: {}, {}", mx, my))
            CalibStep := 4
            UpdateCalibrationUI()
        case 4:
            ElixirBarThreshX := mx
            ElixirBarThreshY := my
            LogMessage(Format("Calibrated Elixir Bar Thresh: {}, {}", mx, my))
            CalibStep := 5
            UpdateCalibrationUI()
        case 5:
            GoldBarThreshX := mx
            GoldBarThreshY := my
            LogMessage(Format("Calibrated Gold Bar Thresh: {}, {}", mx, my))
            CalibStep := 6
            UpdateCalibrationUI()
        case 6:
            BuilderFaceX := mx
            BuilderFaceY := my
            LogMessage(Format("Calibrated Builder Face: {}, {}", mx, my))
            CalibStep := 7
            UpdateCalibrationUI()
        case 7:
            BuilderMenuBottomX := mx
            BuilderMenuBottomY := my
            LogMessage(Format("Calibrated Builder Menu Bottom: {}, {}", mx, my))
            CalibStep := 8
            UpdateCalibrationUI()
        case 8:
            LabFaceX := mx
            LabFaceY := my
            LogMessage(Format("Calibrated Lab Face: {}, {}", mx, my))
            CalibStep := 9
            UpdateCalibrationUI()
        case 9:
            UpgradeMoreBtnX := mx
            UpgradeMoreBtnY := my
            LogMessage(Format("Calibrated Upgrade More Btn: {}, {}", mx, my))
            CalibStep := 10
            UpdateCalibrationUI()
        case 10:
            AddWall1X := mx
            AddWall1Y := my
            LogMessage(Format("Calibrated Add Wall1: {}, {}", mx, my))
            CalibStep := 11
            UpdateCalibrationUI()
        case 11:
            RemoveWallX := mx
            RemoveWallY := my
            LogMessage(Format("Calibrated Remove Wall1: {}, {}", mx, my))
            CalibStep := 12
            UpdateCalibrationUI()
        case 12:
            GoldUpgradeX := mx
            GoldUpgradeY := my
            LogMessage(Format("Calibrated Gold Upgrade: {}, {}", mx, my))
            CalibStep := 13
            UpdateCalibrationUI()
        case 13:
            ElixirUpgradeX := mx
            ElixirUpgradeY := my
            LogMessage(Format("Calibrated Elixir Upgrade: {}, {}", mx, my))
            CalibStep := 14
            UpdateCalibrationUI()
        case 14:
            UpgradeConfirmX := mx
            UpgradeConfirmY := my
            LogMessage(Format("Calibrated Upgrade Confirm: {}, {}", mx, my))
            CalibStep := 15
            UpdateCalibrationUI()
        case 15:
            WarLogoX := mx
            WarLogoY := my
            WarLogoColor := GetADBPixelColor(mx, my, true)
            LogMessage(Format("Calibrated War Logo: {}, {} (Color: {})", mx, my, WarLogoColor))
            CalibStep := 16
            UpdateCalibrationUI()
        case 16:
            AttackBtnX := mx
            AttackBtnY := my
            LogMessage(Format("Calibrated Attack Btn: {}, {}", mx, my))
            CalibStep := 17
            UpdateCalibrationUI()
        case 17:
            FindMatchBtnX := mx
            FindMatchBtnY := my
            LogMessage(Format("Calibrated Find Match Btn: {}, {}", mx, my))
            CalibStep := 18
            UpdateCalibrationUI()
        case 18:
            AttackStartBtnX := mx
            AttackStartBtnY := my
            LogMessage(Format("Calibrated Attack Start Btn: {}, {}", mx, my))
            CalibStep := 19
            UpdateCalibrationUI()
        case 19:
            GoldIconX := mx
            GoldIconY := my
            GoldAreaX := mx + LootCropOffsetX
            GoldAreaY := my + LootCropOffsetY
            GoldAreaW := LootCropW
            GoldAreaH := LootCropH
            LogMessage(Format("Calibrated Gold Coin Symbol: {}, {}", mx, my))
            CalibStep := 20
            UpdateCalibrationUI()
        case 20:
            ElixirIconX := mx
            ElixirIconY := my
            ElixirAreaX := mx + LootCropOffsetX
            ElixirAreaY := my + LootCropOffsetY
            ElixirAreaW := LootCropW
            ElixirAreaH := LootCropH
            LogMessage(Format("Calibrated Elixir Drop Symbol: {}, {}", mx, my))
            CalibStep := 21
            UpdateCalibrationUI()
        case 21:
            NextMatchBtnX := mx
            NextMatchBtnY := my
            LogMessage(Format("Calibrated Next Match Btn: {}, {}", mx, my))
            CalibStep := 22
            UpdateCalibrationUI()
        case 22:
            Side1StartX := mx
            Side1StartY := my
            LogMessage(Format("Calibrated Side1 Start: {}, {}", mx, my))
            CalibStep := 23
            UpdateCalibrationUI()
        case 23:
            Side1EndX := mx
            Side1EndY := my
            LogMessage(Format("Calibrated Side1 End: {}, {}", mx, my))
            CalibStep := 24
            UpdateCalibrationUI()
        case 24:
            Side2StartX := mx
            Side2StartY := my
            LogMessage(Format("Calibrated Side2 Start: {}, {}", mx, my))
            CalibStep := 25
            UpdateCalibrationUI()
        case 25:
            Side2EndX := mx
            Side2EndY := my
            LogMessage(Format("Calibrated Side2 End: {}, {}", mx, my))
            CalibStep := 26
            UpdateCalibrationUI()
        case 26:
            Side3StartX := mx
            Side3StartY := my
            LogMessage(Format("Calibrated Side3 Start: {}, {}", mx, my))
            CalibStep := 27
            UpdateCalibrationUI()
        case 27:
            Side3EndX := mx
            Side3EndY := my
            LogMessage(Format("Calibrated Side3 End: {}, {}", mx, my))
            CalibStep := 28
            UpdateCalibrationUI()
        case 28:
            Side4StartX := mx
            Side4StartY := my
            LogMessage(Format("Calibrated Side4 Start: {}, {}", mx, my))
            CalibStep := 29
            UpdateCalibrationUI()
        case 29:
            Side4EndX := mx
            Side4EndY := my
            LogMessage(Format("Calibrated Side4 End: {}, {}", mx, my))
            ; Reconstruct the Sides array
            Sides := [
                {startX: Side1StartX, startY: Side1StartY, endX: Side1EndX, endY: Side1EndY},
                {startX: Side2StartX, startY: Side2StartY, endX: Side2EndX, endY: Side2EndY},
                {startX: Side3StartX, startY: Side3StartY, endX: Side3EndX, endY: Side3EndY},
                {startX: Side4StartX, startY: Side4StartY, endX: Side4EndX, endY: Side4EndY}
            ]
            LogMessage("Reconstructed Sides array with newly calibrated points.")
            CalibStep := 30
            UpdateCalibrationUI()
        case 30:
            ReturnHomeClickX := mx
            ReturnHomeClickY := my
            ReturnHomeClickColor := GetADBPixelColor(mx, my, true)
            LogMessage(Format("Calibrated Return Home Click: {}, {} (Color: {})", mx, my, ReturnHomeClickColor))
            ; Auto-calculate cloud points inside the Android viewport, excluding emulator chrome.
            if (ADBViewportRight > ADBViewportLeft && ADBViewportBottom > ADBViewportTop) {
                global CloudPt1X, CloudPt1Y, CloudPt2X, CloudPt2Y, CloudPt3X, CloudPt3Y, CloudPt4X, CloudPt4Y
                viewportWidth := ADBViewportRight - ADBViewportLeft
                viewportHeight := ADBViewportBottom - ADBViewportTop
                CloudPt1X := ADBViewportLeft + viewportWidth // 4
                CloudPt1Y := ADBViewportTop + viewportHeight // 4
                CloudPt2X := ADBViewportLeft + (viewportWidth * 3) // 4
                CloudPt2Y := CloudPt1Y
                CloudPt3X := CloudPt1X
                CloudPt3Y := ADBViewportTop + (viewportHeight * 3) // 4
                CloudPt4X := CloudPt2X
                CloudPt4Y := CloudPt3Y
                LogMessage("Auto-calculated Cloud Detection points.")
            }
            ; Reset dynamic arrays before the final collector step.
            CollectorCoords := []
            CalibStep := 31
            UpdateCalibrationUI()
        case 31:
            CollectorCoords.Push({x: mx, y: my})
            LogMessage(Format("Added Resource Collector #{}: {}, {}", CollectorCoords.Length, mx, my))
            UpdateCalibrationUI()
    }
}
Enter:: {
    if (CalibStep == 31) {
        FinishCalibration()
    }
}
Esc:: {
    CancelCalibration()
}
#HotIf
#HotIf IsBBCalibrating
Space:: {
    global BBCalibStep, IsBBCalibrating
    global BBAttackBtnX, BBAttackBtnY, BBFindMatchBtnX, BBFindMatchBtnY
    global BBStar1X, BBStar1Y, BBStar2X, BBStar2Y, BBStar3X, BBStar3Y, BBStarColor
    global BBSide1StartX, BBSide1StartY, BBSide1EndX, BBSide1EndY
    global BBSide2StartX, BBSide2StartY, BBSide2EndX, BBSide2EndY
    global BBSide3StartX, BBSide3StartY, BBSide3EndX, BBSide3EndY
    global BBSide4StartX, BBSide4StartY, BBSide4EndX, BBSide4EndY
    global BBSides
    global TargetWindowTitle
    CoordMode "Mouse", "Client"
    if !WinExist(TargetWindowTitle) {
        LogMessage("Calibration Error: Target window not found.")
        return
    }
    MouseGetPos &mx, &my
    ; Store client-relative coordinates only; ADB translation occurs at each read/input boundary.
    switch BBCalibStep {
        case 1:
            BBAttackBtnX := mx
            BBAttackBtnY := my
            LogMessage(Format("Calibrated BB Attack Button: {}, {}", mx, my))
            BBCalibStep := 2
            UpdateBBCalibrationUI()
        case 2:
            BBFindMatchBtnX := mx
            BBFindMatchBtnY := my
            LogMessage(Format("Calibrated BB Find Match Button: {}, {}", mx, my))
            BBCalibStep := 3
            UpdateBBCalibrationUI()
        case 3:
            BBStar1X := mx
            BBStar1Y := my
            BBStarColor := GetADBPixelColor(mx, my, true)
            LogMessage(Format("Calibrated Star 1: {}, {} (Color: {})", mx, my, BBStarColor))
            BBCalibStep := 4
            UpdateBBCalibrationUI()
        case 4:
            BBStar2X := mx
            BBStar2Y := my
            LogMessage(Format("Calibrated Star 2: {}, {}", mx, my))
            BBCalibStep := 5
            UpdateBBCalibrationUI()
        case 5:
            BBStar3X := mx
            BBStar3Y := my
            LogMessage(Format("Calibrated Star 3: {}, {}", mx, my))
            ; Automatically zoom out for Builder Base sides calibration
            ZoomOutBB()
            BBCalibStep := 6
            UpdateBBCalibrationUI()
        case 6:
            BBSide1StartX := mx
            BBSide1StartY := my
            LogMessage(Format("Calibrated BB Side 1 Start: {}, {}", mx, my))
            BBCalibStep := 7
            UpdateBBCalibrationUI()
        case 7:
            BBSide1EndX := mx
            BBSide1EndY := my
            LogMessage(Format("Calibrated BB Side 1 End: {}, {}", mx, my))
            BBCalibStep := 8
            UpdateBBCalibrationUI()
        case 8:
            BBSide2StartX := mx
            BBSide2StartY := my
            LogMessage(Format("Calibrated BB Side 2 Start: {}, {}", mx, my))
            BBCalibStep := 9
            UpdateBBCalibrationUI()
        case 9:
            BBSide2EndX := mx
            BBSide2EndY := my
            LogMessage(Format("Calibrated BB Side 2 End: {}, {}", mx, my))
            BBCalibStep := 10
            UpdateBBCalibrationUI()
        case 10:
            BBSide3StartX := mx
            BBSide3StartY := my
            LogMessage(Format("Calibrated BB Side 3 Start: {}, {}", mx, my))
            BBCalibStep := 11
            UpdateBBCalibrationUI()
        case 11:
            BBSide3EndX := mx
            BBSide3EndY := my
            LogMessage(Format("Calibrated BB Side 3 End: {}, {}", mx, my))
            BBCalibStep := 12
            UpdateBBCalibrationUI()
        case 12:
            BBSide4StartX := mx
            BBSide4StartY := my
            LogMessage(Format("Calibrated BB Side 4 Start: {}, {}", mx, my))
            BBCalibStep := 13
            UpdateBBCalibrationUI()
        case 13:
            BBSide4EndX := mx
            BBSide4EndY := my
            LogMessage(Format("Calibrated BB Side 4 End: {}, {}", mx, my))
            ; Reconstruct the BBSides array
            BBSides := [
                {startX: BBSide1StartX, startY: BBSide1StartY, endX: BBSide1EndX, endY: BBSide1EndY},
                {startX: BBSide2StartX, startY: BBSide2StartY, endX: BBSide2EndX, endY: BBSide2EndY},
                {startX: BBSide3StartX, startY: BBSide3StartY, endX: BBSide3EndX, endY: BBSide3EndY},
                {startX: BBSide4StartX, startY: BBSide4StartY, endX: BBSide4EndX, endY: BBSide4EndY}
            ]
            LogMessage("Reconstructed BBSides array with newly calibrated points.")
            FinishBBCalibration()
    }
}
Enter:: {
    if (BBCalibStep == 13) {
        FinishBBCalibration()
    }
}
Esc:: {
    CancelBBCalibration()
}
#HotIf
#HotIf !IsCalibrating && !IsBBCalibrating
UnifiedStart() {
    global IsRunning, IsBBRunning, TimerDurationMs, TimerStartTick
    global SessionCompletedAttacks
    global DDHours, DDMinutes, StatusText
    if (IsRunning || IsBBRunning) {
        PauseBot()
        return
    }

    try {
        hours := Integer(DDHours.Text)
        minutes := Integer(DDMinutes.Text)
        TimerDurationMs := (hours * 3600 + minutes * 60) * 1000
        TimerStartTick := 0
        SessionCompletedAttacks := 0
        state := {
            timerMs: TimerDurationMs,
            mainCalibrated: true,
            builderCalibrated: true
        }
        operations := CreateADBMainFlowSections(LiveADBFlowPrimitives())
        ADBRefactorFlowAPI.RunStartup(operations, state)
    } catch as err {
        IsRunning := false
        IsBBRunning := false
        StatusText.Value := "Status: Start Failed"
        LogMessage("Startup flow stopped: " err.Message)
    }
}

LegacyUnifiedStart() {
    global IsRunning, IsBBRunning, StatusText, StartBtn, PauseBtn
    global ADBMainCalibrationVersion, ADBBBCalibrationVersion, ADB_COORDINATE_VERSION
    if IsRunning || IsBBRunning {
        PauseBot()
        IsBBRunning := false
        return
    }
    ; If the game window is not open, launch the normal Google Play Games version of Clash of Clans
    if !WinExist(TargetWindowTitle) {
        LogMessage("Game window not found. Launching Clash of Clans (Normal GPG)...")
        try {
            Run('"C:\Program Files\Google\Play Games\Bootstrapper.exe" --running_from_shortcut --launch_game_id=com.supercell.clashofclans')
        } catch {
            Run("googleplaygames://launch/?id=com.supercell.clashofclans")
        }
        ; Wait up to 30 seconds for the window to appear
        Loop 60 {
            if WinExist(TargetWindowTitle)
                break
            Sleep 500
        }
        ; Extra buffer to let the game load
        Sleep 5000
    }
    viewportState := ValidateADBViewportRuntime()
    if !viewportState.Ok {
        LogMessage("ADB viewport: " viewportState.Message)
        StatusText.Value := "Status: Main Calibration Needed"
        return
    }
    ; 1. Check for game timeout immediately during start
    CheckGameTimeout(true)
    ; 2. Clearing Click to close any open menus
    ClearingClick()
    ; 3. Reset viewport so that the village check runs on a calibrated standard view
    ResetViewport()
    ; 4. Check village type and start the appropriate loop
    if IsAtHomeVillage() {
        if (ADBMainCalibrationVersion != ADB_COORDINATE_VERSION) {
            LogMessage("ADB coordinates are stale. Run Main Calib (Ctrl+F1) once to rebuild them from client coordinates.")
            StatusText.Value := "Status: Main Calibration Needed"
            return
        }
        if (WarLogoColor == 0x000000) {
            LogMessage("WARNING: War Logo is uncalibrated! Please run Main Calib (Ctrl+F1).")
            StatusText.Value := "Status: Calibration Needed"
            return
        }
        StartBot()
    } else if IsAtBuilderBase() {
        if (ADBBBCalibrationVersion != ADB_COORDINATE_VERSION) {
            LogMessage("Builder Base ADB coordinates are stale. Run BB Calib (Ctrl+F2) once.")
            StatusText.Value := "Status: BB Calibration Needed"
            return
        }
        IsBBRunning := true
        LogMessage("Builder Base Attack Loop started.")
        StatusText.Value := "Status: Running BB"
        StartBtn.Enabled := false
        PauseBtn.Enabled := true
        SetTimer RunBuilderBaseLoop, -100
    } else {
        LogMessage("Could not determine village type. Re-checking in 15 seconds...")
        StatusText.Value := "Status: Retrying in 15s..."
        SetTimer UnifiedStart, -15000
    }
}
F1:: {
    UnifiedStart()
}
F2:: {
    PauseBot()
    IsBBRunning := false
}
^F1:: {
    StartCalibration()
}
^F2:: {
    StartBBCalibration()
}

; Milestone Checkpoint 2.5: Verified ADB Storage Bar Pixel Thresholds and Multi-Point Village Detection
Esc:: {
    ShowToolTip("Exiting Clash of Clans Bot...")
    Sleep 1000
    ExitApp
}
; Checkpoint: Functional Bot 2.2
#HotIf
