#Requires AutoHotkey v2.0
#SingleInstance Force
#include "OCR.ahk"
; Set coordinate modes relative to the active window's client area and match substring titles
CoordMode "Mouse", "Client"
CoordMode "Pixel", "Client"
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
global ADBCollectorCoords := []
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
; --- Native Android display coordinates computed from client calibration points ---
global ADBAttackBtnX := 100, ADBAttackBtnY := 970
global ADBFindMatchBtnX := 250, ADBFindMatchBtnY := 750
global ADBAttackStartBtnX := 1630, ADBAttackStartBtnY := 920
global ADBReturnHomeClickX := 960, ADBReturnHomeClickY := 920
global ADBBBAttackBtnX := 100, ADBBBAttackBtnY := 970
global ADBBBFindMatchBtnX := 250, ADBBBFindMatchBtnY := 750
global ADBBBStar1X := 960, ADBBBStar1Y := 540
global ADBBBStar2X := 960, ADBBBStar2Y := 540
global ADBBBStar3X := 960, ADBBBStar3Y := 540
global ADBWarLogoX := 100, ADBWarLogoY := 700
global ADBBuilderFaceX := 960, ADBBuilderFaceY := 30
global ADBBuilderMenuBottomX := 960, ADBBuilderMenuBottomY := 800
global ADBLabFaceX := 960, ADBLabFaceY := 30
global ADBUpgradeConfirmX := 960, ADBUpgradeConfirmY := 540
global ADBGoldAreaX := 50, ADBGoldAreaY := 50
global ADBElixirAreaX := 50, ADBElixirAreaY := 90
global ADBNextMatchBtnX := 1630, ADBNextMatchBtnY := 850
global ADBDarkElixirBarThreshX := 1750, ADBDarkElixirBarThreshY := 100
global ADBGoldBarThreshX := 1750, ADBGoldBarThreshY := 100
global ADBElixirBarThreshX := 1750, ADBElixirBarThreshY := 160
global ADBUpgradeMoreBtnX := 960, ADBUpgradeMoreBtnY := 850
global ADBAddWall1X := 960, ADBAddWall1Y := 800
global ADBRemoveWallX := 960, ADBRemoveWallY := 800
global ADBGoldUpgradeX := 960, ADBGoldUpgradeY := 800
global ADBElixirUpgradeX := 960, ADBElixirUpgradeY := 800
global ADBSide1StartX := 1750, ADBSide1StartY := 520, ADBSide1EndX := 1400, ADBSide1EndY := 800
global ADBSide2StartX := 150, ADBSide2StartY := 510, ADBSide2EndX := 600, ADBSide2EndY := 850
global ADBSide3StartX := 150, ADBSide3StartY := 510, ADBSide3EndX := 507, ADBSide3EndY := 230
global ADBSide4StartX := 1131, ADBSide4StartY := 40, ADBSide4EndX := 1506, ADBSide4EndY := 312
global ADBBBSide1StartX := 1750, ADBBBSide1StartY := 520, ADBBBSide1EndX := 1400, ADBBBSide1EndY := 800
global ADBBBSide2StartX := 150, ADBBBSide2StartY := 510, ADBBBSide2EndX := 600, ADBBBSide2EndY := 850
global ADBBBSide3StartX := 150, ADBBBSide3StartY := 510, ADBBBSide3EndX := 507, ADBBBSide3EndY := 230
global ADBBBSide4StartX := 1131, ADBBBSide4StartY := 40, ADBBBSide4EndX := 1506, ADBBBSide4EndY := 312
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
global ADBSides := [
    {startX: ADBSide1StartX, startY: ADBSide1StartY, endX: ADBSide1EndX, endY: ADBSide1EndY},
    {startX: ADBSide2StartX, startY: ADBSide2StartY, endX: ADBSide2EndX, endY: ADBSide2EndY},
    {startX: ADBSide3StartX, startY: ADBSide3StartY, endX: ADBSide3EndX, endY: ADBSide3EndY},
    {startX: ADBSide4StartX, startY: ADBSide4StartY, endX: ADBSide4EndX, endY: ADBSide4EndY}
]
global ADBBBSides := [
    {startX: ADBBBSide1StartX, startY: ADBBBSide1StartY, endX: ADBBBSide1EndX, endY: ADBBBSide1EndY},
    {startX: ADBBBSide2StartX, startY: ADBBBSide2StartY, endX: ADBBBSide2EndX, endY: ADBBBSide2EndY},
    {startX: ADBBBSide3StartX, startY: ADBBBSide3StartY, endX: ADBBBSide3EndX, endY: ADBBBSide3EndY},
    {startX: ADBBBSide4StartX, startY: ADBBBSide4StartY, endX: ADBBBSide4EndX, endY: ADBBBSide4EndY}
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

if HasArgument("--adb-self-test") {
    RunADBIntegrationSelfTestEntry()
}

; Load configuration settings
LoadConfig()
; Initialize GUI
CreateGUI()
LogMessage("Bot initialized. Ready.")

HasArgument(expected) {
    for argument in A_Args {
        if (argument == expected)
            return true
    }
    return false
}

RunADBIntegrationSelfTests() {
    AssertADBEqual("localhost:6520", ResolveADBSerial("Google Play Games Developer Emulator", "127.0.0.1:5555"), "GPGDE serial")
    AssertADBEqual("127.0.0.1:5555", ResolveADBSerial("BlueStacks", "127.0.0.1:5555"), "BlueStacks serial")
    AssertADBEqual('-s "localhost:6520" shell input tap 500 400', BuildADBTapArguments("localhost:6520", 500, 400), "tap arguments")
    AssertADBEqual('-s "localhost:6520" shell input swipe 100 200 300 400 200', BuildADBSwipeArguments("localhost:6520", 100, 200, 300, 400, 200), "swipe arguments")
    topLeft := ScaleClientToADB(20, 40, 20, 40, 1820, 1040, 1920, 1080)
    AssertADBEqual(0, topLeft.x, "viewport top-left X")
    AssertADBEqual(0, topLeft.y, "viewport top-left Y")
    bottomRight := ScaleClientToADB(1820, 1040, 20, 40, 1820, 1040, 1920, 1080)
    AssertADBEqual(1919, bottomRight.x, "viewport bottom-right X")
    AssertADBEqual(1079, bottomRight.y, "viewport bottom-right Y")
    center := ScaleClientToADB(920, 540, 20, 40, 1820, 1040, 1920, 1080)
    AssertADBEqual(960, center.x, "offset viewport center X")
    AssertADBEqual(540, center.y, "offset viewport center Y")
    unequalScale := ScaleClientToADB(920, 290, 20, 40, 1820, 1040, 1920, 1080)
    AssertADBEqual(960, unequalScale.x, "independent viewport X scale")
    AssertADBEqual(270, unequalScale.y, "independent viewport Y scale")
    clampedLeft := ScaleClientToADB(10, 40, 20, 40, 1820, 1040, 1920, 1080)
    AssertADBEqual(0, clampedLeft.x, "clamped point left of viewport X")
    AssertADBThrows(() => ScaleClientToADB(20, 40, 100, 40, 100, 1040, 1920, 1080), "zero-width viewport")
    AssertADBEqual(true, IsADBViewportValid(20, 40, 1820, 1040, 1900, 1100), "valid viewport metadata")
    AssertADBEqual(false, IsADBViewportValid(20, 40, 1920, 1040, 1900, 1100), "viewport outside client")
    AssertADBEqual(true, DoesADBViewportMatchRuntime(1900, 1100, "BlueStacks", "127.0.0.1:5555",
        1900, 1100, "BlueStacks", "127.0.0.1:5555"), "matching viewport runtime")
    AssertADBEqual(false, DoesADBViewportMatchRuntime(1900, 1100, "BlueStacks", "127.0.0.1:5555",
        1920, 1080, "BlueStacks", "127.0.0.1:5555"), "resized client mismatch")
    AssertADBEqual(false, DoesADBViewportMatchRuntime(1900, 1100, "BlueStacks", "127.0.0.1:5555",
        1900, 1100, "Google Play Games Developer Emulator", "localhost:6520"), "provider identity mismatch")
    if !ParseBuilderFraction("I / 7", &parsedFree, &parsedTotal)
        throw Error("builder fraction parser rejected OCR substitutions")
    AssertADBEqual(1, parsedFree, "parsed builder free count")
    AssertADBEqual(7, parsedTotal, "parsed builder total count")
    menuSwipe := BuildBuilderMenuSwipe(839, 600, 49)
    AssertADBEqual(839, menuSwipe.startX, "builder swipe start X")
    AssertADBEqual(600, menuSwipe.startY, "builder swipe start Y")
    AssertADBEqual(839, menuSwipe.endX, "builder swipe end X")
    AssertADBEqual(187, menuSwipe.endY, "builder swipe end Y")
    Loop 250 {
        offset := RandomADBOffset()
        if (offset < -7 || offset > 8)
            throw Error("coordinate randomization escaped -7..8")
        duration := RandomADBDuration()
        if (duration < 185 || duration > 215)
            throw Error("duration randomization escaped 185..215")
    }
    pinch := BuildADBPinchArguments("localhost:6520", 960, 540, 200, 45, 200)
    if !InStr(pinch, "-e startRadius 200 -e endRadius 45 -e durationMs 200")
        throw Error("pinch arguments do not use 200 -> 45 over 200 ms")
}

RunADBIntegrationSelfTestEntry() {
    resultPath := A_ScriptDir "\scratch\coc_bot_adb_selftest.txt"
    DirCreate(A_ScriptDir "\scratch")
    if FileExist(resultPath)
        FileDelete(resultPath)
    try {
        RunADBIntegrationSelfTests()
        FileAppend("PASS: all integrated ADB tests passed`n", resultPath)
        ExitApp 0
    } catch as err {
        FileAppend("FAIL: " err.Message "`n", resultPath)
        ExitApp 1
    }
}

AssertADBEqual(expected, actual, description) {
    if (expected != actual)
        throw Error(description ": expected [" expected "], got [" actual "]")
}

AssertADBThrows(callback, description) {
    try {
        callback.Call()
    } catch {
        return
    }
    throw Error(description ": expected an error")
}

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

BuildADBTapArguments(serial, x, y) {
    return '-s "' serial '" shell input tap ' Round(x) ' ' Round(y)
}

BuildADBSwipeArguments(serial, startX, startY, endX, endY, durationMs) {
    return '-s "' serial '" shell input swipe ' Round(startX) ' ' Round(startY) ' ' Round(endX) ' ' Round(endY) ' ' durationMs
}

BuildADBPinchArguments(serial, centerX, centerY, startRadius, endRadius, durationMs) {
    global ADB_PINCH_COMPONENT
    return '-s ' QuoteADBArgument(serial)
        . ' shell am instrument -w'
        . ' -e centerX ' Round(centerX)
        . ' -e centerY ' Round(centerY)
        . ' -e startRadius ' startRadius
        . ' -e endRadius ' endRadius
        . ' -e durationMs ' durationMs
        . ' ' QuoteADBArgument(ADB_PINCH_COMPONENT)
}

ScaleClientToADB(x, y, viewportLeft, viewportTop, viewportRight, viewportBottom, adbWidth, adbHeight) {
    if (viewportRight <= viewportLeft || viewportBottom <= viewportTop)
        throw Error("Android viewport must have positive width and height.")
    if (adbWidth <= 0 || adbHeight <= 0)
        throw Error("Android display dimensions must be positive.")
    xClamped := Max(viewportLeft, Min(viewportRight, x))
    yClamped := Max(viewportTop, Min(viewportBottom, y))
    return {
        x: Max(0, Min(adbWidth - 1, Round((xClamped - viewportLeft) * (adbWidth - 1) / (viewportRight - viewportLeft)))),
        y: Max(0, Min(adbHeight - 1, Round((yClamped - viewportTop) * (adbHeight - 1) / (viewportBottom - viewportTop))))
    }
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
    global TargetWindowTitle
    global ADBViewportLeft, ADBViewportTop, ADBViewportRight, ADBViewportBottom
    global ADBViewportClientWidth, ADBViewportClientHeight
    static lastMapping := ""
    hwnd := WinExist(TargetWindowTitle)
    if !hwnd
        throw Error("The configured emulator window was not found.")
    WinGetClientPos ,, &clientWidth, &clientHeight, hwnd
    if !IsADBViewportValid(ADBViewportLeft, ADBViewportTop, ADBViewportRight, ADBViewportBottom,
        ADBViewportClientWidth, ADBViewportClientHeight)
        throw Error("Android viewport calibration is missing. Run Main Calibration.")
    display := GetADBDisplaySize()
    mappingKey := ADBViewportLeft "," ADBViewportTop "-" ADBViewportRight "," ADBViewportBottom
        . "->" display.width "x" display.height
    if (mappingKey != lastMapping) {
        lastMapping := mappingKey
    }
    return ScaleClientToADB(x, y, ADBViewportLeft, ADBViewportTop, ADBViewportRight, ADBViewportBottom,
        display.width, display.height)
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
    if !hwnd
        return {Ok: false, Message: "The configured emulator window was not found."}
    return {Ok: true, Message: "Android viewport is valid."}
}

InvalidateADBViewport() {
    global ADBViewportVersion, ADBMainCalibrationVersion, ADBBBCalibrationVersion
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

RandomADBOffset() {
    return Random(-7, 8)
}

RandomADBDuration() {
    return Random(185, 215)
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

GetADBPixelColor(adbX, adbY, forceRefresh := false) {
    framePath := CaptureADBFrame(forceRefresh)
    if !FileExist(framePath)
        return 0x000000

    InitGDIPlus()
    pBitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", framePath, "ptr*", &pBitmap) != 0
        return 0x000000

    argb := 0
    DllCall("gdiplus\GdipBitmapGetPixel", "ptr", pBitmap, "int", Round(adbX), "int", Round(adbY), "uint*", &argb)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    return argb & 0x00FFFFFF
}

IsBrownADB(adbX, adbY) {
    try {
        color := GetADBPixelColor(adbX, adbY)
        actualHex := Integer(color)
        r := (actualHex >> 16) & 0xFF
        g := (actualHex >> 8) & 0xFF
        b := actualHex & 0xFF
        return (r > g) && (g > b) && (r - b >= 30) && (g - b >= 10) && (r >= 70 && r <= 250)
    } catch {
        return false
    }
}

IsGreyADB(adbX, adbY, tolerance := 15) {
    try {
        color := GetADBPixelColor(adbX, adbY)
        actualHex := Integer(color)
        r := (actualHex >> 16) & 0xFF
        g := (actualHex >> 8) & 0xFF
        b := actualHex & 0xFF
        return (r >= 120) && (Abs(r - g) <= tolerance) && (Abs(g - b) <= tolerance) && (Abs(r - b) <= tolerance)
    } catch {
        return false
    }
}

ColorMatchesADB(adbX, adbY, targetColorRGB, tolerance := 20) {
    try {
        color := GetADBPixelColor(adbX, adbY)
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

RunADBTapAt(x, y) {
    global ADBConnectionSerial, ADBHelperSerial, ADBDisplaySerial
    ready := EnsureADBActionReady()
    if !ready.Ok
        return false
    result := RunADB(BuildADBTapArguments(ready.Serial, x, y))
    if !result.Ok {
        ADBConnectionSerial := ""
        ADBHelperSerial := ""
        ADBDisplaySerial := ""
        LogMessage("ADB tap failed: " FormatADBResult(result))
        return false
    }
    return true
}

RunADBSwipeAt(startX, startY, endX, endY, durationMs := "") {
    global ADBConnectionSerial, ADBHelperSerial
    ready := EnsureADBActionReady()
    if !ready.Ok
        return false
    if (durationMs == "")
        durationMs := RandomADBDuration()
    result := RunADB(BuildADBSwipeArguments(ready.Serial, startX, startY, endX, endY, durationMs))
    if !result.Ok {
        ADBConnectionSerial := ""
        ADBHelperSerial := ""
        LogMessage("ADB swipe failed: " FormatADBResult(result))
        return false
    }
    return true
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

RunADBPinchAt(centerX, centerY) {
    global ADBConnectionSerial, ADBHelperSerial
    try {
        ready := EnsureADBActionReady()
        if !ready.Ok
            return false
        EnsureADBPinchHelper(ready.Serial)
        result := RunADB(BuildADBPinchArguments(ready.Serial, centerX, centerY, 200, 45, RandomADBDuration()), true)
        if !result.Ok || InStr(result.Output, "Pinch failed:") || !InStr(result.Output, "Pinch injected successfully.")
            throw Error(FormatADBResult(result))
        return true
    } catch as err {
        ADBConnectionSerial := ""
        ADBHelperSerial := ""
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
    global NextMatchBtnX, NextMatchBtnY
    global UpgradeMoreBtnX, UpgradeMoreBtnY, AddWall1X, AddWall1Y, RemoveWallX, RemoveWallY, GoldUpgradeX, GoldUpgradeY, ElixirUpgradeX, ElixirUpgradeY
    global CloudPt1X, CloudPt1Y, CloudPt2X, CloudPt2Y, CloudPt3X, CloudPt3Y, CloudPt4X, CloudPt4Y, CloudGreyTolerance
    global CollectorCoords, ADBCollectorCoords
    global ADBAttackBtnX, ADBAttackBtnY, ADBFindMatchBtnX, ADBFindMatchBtnY, ADBAttackStartBtnX, ADBAttackStartBtnY
    global ADBReturnHomeClickX, ADBReturnHomeClickY, ADBBBAttackBtnX, ADBBBAttackBtnY, ADBBBFindMatchBtnX, ADBBBFindMatchBtnY
    global ADBBBStar1X, ADBBBStar1Y, ADBBBStar2X, ADBBBStar2Y, ADBBBStar3X, ADBBBStar3Y, ADBWarLogoX, ADBWarLogoY
    global ADBBuilderFaceX, ADBBuilderFaceY, ADBBuilderMenuBottomX, ADBBuilderMenuBottomY, ADBLabFaceX, ADBLabFaceY, ADBUpgradeConfirmX, ADBUpgradeConfirmY
    global ADBGoldAreaX, ADBGoldAreaY, ADBElixirAreaX, ADBElixirAreaY, ADBNextMatchBtnX, ADBNextMatchBtnY
    global ADBDarkElixirBarThreshX, ADBDarkElixirBarThreshY, ADBGoldBarThreshX, ADBGoldBarThreshY, ADBElixirBarThreshX, ADBElixirBarThreshY
    global ADBUpgradeMoreBtnX, ADBUpgradeMoreBtnY, ADBAddWall1X, ADBAddWall1Y, ADBRemoveWallX, ADBRemoveWallY
    global ADBGoldUpgradeX, ADBGoldUpgradeY, ADBElixirUpgradeX, ADBElixirUpgradeY
    global ADBSide1StartX, ADBSide1StartY, ADBSide1EndX, ADBSide1EndY, ADBSide2StartX, ADBSide2StartY, ADBSide2EndX, ADBSide2EndY
    global ADBSide3StartX, ADBSide3StartY, ADBSide3EndX, ADBSide3EndY, ADBSide4StartX, ADBSide4StartY, ADBSide4EndX, ADBSide4EndY
    global ADBBBSide1StartX, ADBBBSide1StartY, ADBBBSide1EndX, ADBBBSide1EndY, ADBBBSide2StartX, ADBBBSide2StartY, ADBBBSide2EndX, ADBBBSide2EndY
    global ADBBBSide3StartX, ADBBBSide3StartY, ADBBBSide3EndX, ADBBBSide3EndY, ADBBBSide4StartX, ADBBBSide4StartY, ADBBBSide4EndX, ADBBBSide4EndY
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
    global BBSides, ADBSides, ADBBBSides
    global ADBProvider, BlueStacksSerial, GPGDE_PROVIDER, BLUESTACKS_PROVIDER
    global ADBMainCalibrationVersion, ADBBBCalibrationVersion
    global ADBViewportLeft, ADBViewportTop, ADBViewportRight, ADBViewportBottom
    global ADBViewportClientWidth, ADBViewportClientHeight, ADBViewportProvider, ADBViewportSerial, ADBViewportVersion
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
    WarLogoX := SafeInteger(IniRead("config.ini", "Coordinates", "MVLogoX", ""), 100)
    WarLogoY := SafeInteger(IniRead("config.ini", "Coordinates", "MVLogoY", ""), 700)
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
    ADBDarkElixirBarThreshX := Integer(IniRead("config.ini", "ADBCoordinates", "DarkElixirBarThreshX", DarkElixirBarThreshX))
    ADBDarkElixirBarThreshY := Integer(IniRead("config.ini", "ADBCoordinates", "DarkElixirBarThreshY", DarkElixirBarThreshY))
    ADBElixirBarThreshX := Integer(IniRead("config.ini", "ADBCoordinates", "ElixirBarThreshX", ElixirBarThreshX))
    ADBElixirBarThreshY := Integer(IniRead("config.ini", "ADBCoordinates", "ElixirBarThreshY", ElixirBarThreshY))
    ADBGoldBarThreshX := Integer(IniRead("config.ini", "ADBCoordinates", "GoldBarThreshX", GoldBarThreshX))
    ADBGoldBarThreshY := Integer(IniRead("config.ini", "ADBCoordinates", "GoldBarThreshY", GoldBarThreshY))
    ADBBuilderFaceX := Integer(IniRead("config.ini", "ADBCoordinates", "BuilderFaceX", BuilderFaceX))
    ADBBuilderFaceY := Integer(IniRead("config.ini", "ADBCoordinates", "BuilderFaceY", BuilderFaceY))
    ADBBuilderMenuBottomX := Integer(IniRead("config.ini", "ADBCoordinates", "BuilderMenuBottomX", BuilderMenuBottomX))
    ADBBuilderMenuBottomY := Integer(IniRead("config.ini", "ADBCoordinates", "BuilderMenuBottomY", BuilderMenuBottomY))
    ADBLabFaceX := Integer(IniRead("config.ini", "ADBCoordinates", "LabFaceX", LabFaceX))
    ADBLabFaceY := Integer(IniRead("config.ini", "ADBCoordinates", "LabFaceY", LabFaceY))
    ADBUpgradeMoreBtnX := Integer(IniRead("config.ini", "ADBCoordinates", "UpgradeMoreBtnX", UpgradeMoreBtnX))
    ADBUpgradeMoreBtnY := Integer(IniRead("config.ini", "ADBCoordinates", "UpgradeMoreBtnY", UpgradeMoreBtnY))
    ADBAddWall1X := Integer(IniRead("config.ini", "ADBCoordinates", "AddWall1X", AddWall1X))
    ADBAddWall1Y := Integer(IniRead("config.ini", "ADBCoordinates", "AddWall1Y", AddWall1Y))
    ADBRemoveWallX := Integer(IniRead("config.ini", "ADBCoordinates", "RemoveWallX", RemoveWallX))
    ADBRemoveWallY := Integer(IniRead("config.ini", "ADBCoordinates", "RemoveWallY", RemoveWallY))
    ADBGoldUpgradeX := Integer(IniRead("config.ini", "ADBCoordinates", "GoldUpgradeX", GoldUpgradeX))
    ADBGoldUpgradeY := Integer(IniRead("config.ini", "ADBCoordinates", "GoldUpgradeY", GoldUpgradeY))
    ADBElixirUpgradeX := Integer(IniRead("config.ini", "ADBCoordinates", "ElixirUpgradeX", ElixirUpgradeX))
    ADBElixirUpgradeY := Integer(IniRead("config.ini", "ADBCoordinates", "ElixirUpgradeY", ElixirUpgradeY))
    ADBUpgradeConfirmX := Integer(IniRead("config.ini", "ADBCoordinates", "UpgradeConfirmX", UpgradeConfirmX))
    ADBUpgradeConfirmY := Integer(IniRead("config.ini", "ADBCoordinates", "UpgradeConfirmY", UpgradeConfirmY))
    ADBWarLogoX := Integer(IniRead("config.ini", "ADBCoordinates", "MVLogoX", WarLogoX))
    ADBWarLogoY := Integer(IniRead("config.ini", "ADBCoordinates", "MVLogoY", WarLogoY))
    ADBAttackBtnX := Integer(IniRead("config.ini", "ADBCoordinates", "AttackBtnX", AttackBtnX))
    ADBAttackBtnY := Integer(IniRead("config.ini", "ADBCoordinates", "AttackBtnY", AttackBtnY))
    ADBFindMatchBtnX := Integer(IniRead("config.ini", "ADBCoordinates", "FindMatchBtnX", FindMatchBtnX))
    ADBFindMatchBtnY := Integer(IniRead("config.ini", "ADBCoordinates", "FindMatchBtnY", FindMatchBtnY))
    ADBAttackStartBtnX := Integer(IniRead("config.ini", "ADBCoordinates", "AttackStartBtnX", AttackStartBtnX))
    ADBAttackStartBtnY := Integer(IniRead("config.ini", "ADBCoordinates", "AttackStartBtnY", AttackStartBtnY))
    ADBGoldAreaX := Integer(IniRead("config.ini", "ADBCoordinates", "GoldAreaX", GoldAreaX))
    ADBGoldAreaY := Integer(IniRead("config.ini", "ADBCoordinates", "GoldAreaY", GoldAreaY))
    ADBElixirAreaX := Integer(IniRead("config.ini", "ADBCoordinates", "ElixirAreaX", ElixirAreaX))
    ADBElixirAreaY := Integer(IniRead("config.ini", "ADBCoordinates", "ElixirAreaY", ElixirAreaY))
    ADBNextMatchBtnX := Integer(IniRead("config.ini", "ADBCoordinates", "NextMatchBtnX", NextMatchBtnX))
    ADBNextMatchBtnY := Integer(IniRead("config.ini", "ADBCoordinates", "NextMatchBtnY", NextMatchBtnY))
    ADBSide1StartX := Integer(IniRead("config.ini", "ADBCoordinates", "Side1StartX", Side1StartX))
    ADBSide1StartY := Integer(IniRead("config.ini", "ADBCoordinates", "Side1StartY", Side1StartY))
    ADBSide1EndX := Integer(IniRead("config.ini", "ADBCoordinates", "Side1EndX", Side1EndX))
    ADBSide1EndY := Integer(IniRead("config.ini", "ADBCoordinates", "Side1EndY", Side1EndY))
    ADBSide2StartX := Integer(IniRead("config.ini", "ADBCoordinates", "Side2StartX", Side2StartX))
    ADBSide2StartY := Integer(IniRead("config.ini", "ADBCoordinates", "Side2StartY", Side2StartY))
    ADBSide2EndX := Integer(IniRead("config.ini", "ADBCoordinates", "Side2EndX", Side2EndX))
    ADBSide2EndY := Integer(IniRead("config.ini", "ADBCoordinates", "Side2EndY", Side2EndY))
    ADBSide3StartX := Integer(IniRead("config.ini", "ADBCoordinates", "Side3StartX", Side3StartX))
    ADBSide3StartY := Integer(IniRead("config.ini", "ADBCoordinates", "Side3StartY", Side3StartY))
    ADBSide3EndX := Integer(IniRead("config.ini", "ADBCoordinates", "Side3EndX", Side3EndX))
    ADBSide3EndY := Integer(IniRead("config.ini", "ADBCoordinates", "Side3EndY", Side3EndY))
    ADBSide4StartX := Integer(IniRead("config.ini", "ADBCoordinates", "Side4StartX", Side4StartX))
    ADBSide4StartY := Integer(IniRead("config.ini", "ADBCoordinates", "Side4StartY", Side4StartY))
    ADBSide4EndX := Integer(IniRead("config.ini", "ADBCoordinates", "Side4EndX", Side4EndX))
    ADBSide4EndY := Integer(IniRead("config.ini", "ADBCoordinates", "Side4EndY", Side4EndY))
    ADBReturnHomeClickX := Integer(IniRead("config.ini", "ADBCoordinates", "ReturnHomeClickX", ReturnHomeClickX))
    ADBReturnHomeClickY := Integer(IniRead("config.ini", "ADBCoordinates", "ReturnHomeClickY", ReturnHomeClickY))
    ADBBBAttackBtnX := Integer(IniRead("config.ini", "ADBCoordinates", "BBAttackBtnX", BBAttackBtnX))
    ADBBBAttackBtnY := Integer(IniRead("config.ini", "ADBCoordinates", "BBAttackBtnY", BBAttackBtnY))
    ADBBBFindMatchBtnX := Integer(IniRead("config.ini", "ADBCoordinates", "BBFindMatchBtnX", BBFindMatchBtnX))
    ADBBBFindMatchBtnY := Integer(IniRead("config.ini", "ADBCoordinates", "BBFindMatchBtnY", BBFindMatchBtnY))
    ADBBBStar1X := Integer(IniRead("config.ini", "ADBCoordinates", "BBStar1X", BBStar1X))
    ADBBBStar1Y := Integer(IniRead("config.ini", "ADBCoordinates", "BBStar1Y", BBStar1Y))
    ADBBBStar2X := Integer(IniRead("config.ini", "ADBCoordinates", "BBStar2X", BBStar2X))
    ADBBBStar2Y := Integer(IniRead("config.ini", "ADBCoordinates", "BBStar2Y", BBStar2Y))
    ADBBBStar3X := Integer(IniRead("config.ini", "ADBCoordinates", "BBStar3X", BBStar3X))
    ADBBBStar3Y := Integer(IniRead("config.ini", "ADBCoordinates", "BBStar3Y", BBStar3Y))
    ADBBBSide1StartX := Integer(IniRead("config.ini", "ADBCoordinates", "BBSide1StartX", BBSide1StartX))
    ADBBBSide1StartY := Integer(IniRead("config.ini", "ADBCoordinates", "BBSide1StartY", BBSide1StartY))
    ADBBBSide1EndX := Integer(IniRead("config.ini", "ADBCoordinates", "BBSide1EndX", BBSide1EndX))
    ADBBBSide1EndY := Integer(IniRead("config.ini", "ADBCoordinates", "BBSide1EndY", BBSide1EndY))
    ADBBBSide2StartX := Integer(IniRead("config.ini", "ADBCoordinates", "BBSide2StartX", BBSide2StartX))
    ADBBBSide2StartY := Integer(IniRead("config.ini", "ADBCoordinates", "BBSide2StartY", BBSide2StartY))
    ADBBBSide2EndX := Integer(IniRead("config.ini", "ADBCoordinates", "BBSide2EndX", BBSide2EndX))
    ADBBBSide2EndY := Integer(IniRead("config.ini", "ADBCoordinates", "BBSide2EndY", BBSide2EndY))
    ADBBBSide3StartX := Integer(IniRead("config.ini", "ADBCoordinates", "BBSide3StartX", BBSide3StartX))
    ADBBBSide3StartY := Integer(IniRead("config.ini", "ADBCoordinates", "BBSide3StartY", BBSide3StartY))
    ADBBBSide3EndX := Integer(IniRead("config.ini", "ADBCoordinates", "BBSide3EndX", BBSide3EndX))
    ADBBBSide3EndY := Integer(IniRead("config.ini", "ADBCoordinates", "BBSide3EndY", BBSide3EndY))
    ADBBBSide4StartX := Integer(IniRead("config.ini", "ADBCoordinates", "BBSide4StartX", BBSide4StartX))
    ADBBBSide4StartY := Integer(IniRead("config.ini", "ADBCoordinates", "BBSide4StartY", BBSide4StartY))
    ADBBBSide4EndX := Integer(IniRead("config.ini", "ADBCoordinates", "BBSide4EndX", BBSide4EndX))
    ADBBBSide4EndY := Integer(IniRead("config.ini", "ADBCoordinates", "BBSide4EndY", BBSide4EndY))
    ADBCollectorCoords := []
    adbCollectorStr := IniRead("config.ini", "ADBCoordinates", "CollectorCoords", "")
    if (adbCollectorStr != "") {
        for entry in StrSplit(adbCollectorStr, ";") {
            if (entry == "")
                continue
            parts := StrSplit(entry, ",")
            if (parts.Length == 2)
                ADBCollectorCoords.Push({x: Integer(parts[1]), y: Integer(parts[2])})
        }
    }
    ADBSides := [
        {startX: ADBSide1StartX, startY: ADBSide1StartY, endX: ADBSide1EndX, endY: ADBSide1EndY},
        {startX: ADBSide2StartX, startY: ADBSide2StartY, endX: ADBSide2EndX, endY: ADBSide2EndY},
        {startX: ADBSide3StartX, startY: ADBSide3StartY, endX: ADBSide3EndX, endY: ADBSide3EndY},
        {startX: ADBSide4StartX, startY: ADBSide4StartY, endX: ADBSide4EndX, endY: ADBSide4EndY}
    ]
    ADBBBSides := [
        {startX: ADBBBSide1StartX, startY: ADBBBSide1StartY, endX: ADBBBSide1EndX, endY: ADBBBSide1EndY},
        {startX: ADBBBSide2StartX, startY: ADBBBSide2StartY, endX: ADBBBSide2EndX, endY: ADBBBSide2EndY},
        {startX: ADBBBSide3StartX, startY: ADBBBSide3StartY, endX: ADBBBSide3EndX, endY: ADBBBSide3EndY},
        {startX: ADBBBSide4StartX, startY: ADBBBSide4StartY, endX: ADBBBSide4EndX, endY: ADBBBSide4EndY}
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
    global NextMatchBtnX, NextMatchBtnY
    global UpgradeMoreBtnX, UpgradeMoreBtnY, AddWall1X, AddWall1Y, RemoveWallX, RemoveWallY, GoldUpgradeX, GoldUpgradeY, ElixirUpgradeX, ElixirUpgradeY
    global CloudPt1X, CloudPt1Y, CloudPt2X, CloudPt2Y, CloudPt3X, CloudPt3Y, CloudPt4X, CloudPt4Y, CloudGreyTolerance
    global CollectorCoords, ADBCollectorCoords
    global ADBAttackBtnX, ADBAttackBtnY, ADBFindMatchBtnX, ADBFindMatchBtnY, ADBAttackStartBtnX, ADBAttackStartBtnY
    global ADBReturnHomeClickX, ADBReturnHomeClickY, ADBBBAttackBtnX, ADBBBAttackBtnY, ADBBBFindMatchBtnX, ADBBBFindMatchBtnY
    global ADBBBStar1X, ADBBBStar1Y, ADBBBStar2X, ADBBBStar2Y, ADBBBStar3X, ADBBBStar3Y, ADBWarLogoX, ADBWarLogoY
    global ADBBuilderFaceX, ADBBuilderFaceY, ADBBuilderMenuBottomX, ADBBuilderMenuBottomY, ADBLabFaceX, ADBLabFaceY, ADBUpgradeConfirmX, ADBUpgradeConfirmY
    global ADBGoldAreaX, ADBGoldAreaY, ADBElixirAreaX, ADBElixirAreaY, ADBNextMatchBtnX, ADBNextMatchBtnY
    global ADBDarkElixirBarThreshX, ADBDarkElixirBarThreshY, ADBGoldBarThreshX, ADBGoldBarThreshY, ADBElixirBarThreshX, ADBElixirBarThreshY
    global ADBUpgradeMoreBtnX, ADBUpgradeMoreBtnY, ADBAddWall1X, ADBAddWall1Y, ADBRemoveWallX, ADBRemoveWallY
    global ADBGoldUpgradeX, ADBGoldUpgradeY, ADBElixirUpgradeX, ADBElixirUpgradeY
    global ADBSide1StartX, ADBSide1StartY, ADBSide1EndX, ADBSide1EndY, ADBSide2StartX, ADBSide2StartY, ADBSide2EndX, ADBSide2EndY
    global ADBSide3StartX, ADBSide3StartY, ADBSide3EndX, ADBSide3EndY, ADBSide4StartX, ADBSide4StartY, ADBSide4EndX, ADBSide4EndY
    global ADBBBSide1StartX, ADBBBSide1StartY, ADBBBSide1EndX, ADBBBSide1EndY, ADBBBSide2StartX, ADBBBSide2StartY, ADBBBSide2EndX, ADBBBSide2EndY
    global ADBBBSide3StartX, ADBBBSide3StartY, ADBBBSide3EndX, ADBBBSide3EndY, ADBBBSide4StartX, ADBBBSide4StartY, ADBBBSide4EndX, ADBBBSide4EndY
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
    IniWrite(ADBDarkElixirBarThreshX, "config.ini", "ADBCoordinates", "DarkElixirBarThreshX")
    IniWrite(ADBDarkElixirBarThreshY, "config.ini", "ADBCoordinates", "DarkElixirBarThreshY")
    IniWrite(ADBElixirBarThreshX, "config.ini", "ADBCoordinates", "ElixirBarThreshX")
    IniWrite(ADBElixirBarThreshY, "config.ini", "ADBCoordinates", "ElixirBarThreshY")
    IniWrite(ADBGoldBarThreshX, "config.ini", "ADBCoordinates", "GoldBarThreshX")
    IniWrite(ADBGoldBarThreshY, "config.ini", "ADBCoordinates", "GoldBarThreshY")
    IniWrite(ADBBuilderFaceX, "config.ini", "ADBCoordinates", "BuilderFaceX")
    IniWrite(ADBBuilderFaceY, "config.ini", "ADBCoordinates", "BuilderFaceY")
    IniWrite(ADBBuilderMenuBottomX, "config.ini", "ADBCoordinates", "BuilderMenuBottomX")
    IniWrite(ADBBuilderMenuBottomY, "config.ini", "ADBCoordinates", "BuilderMenuBottomY")
    IniWrite(ADBLabFaceX, "config.ini", "ADBCoordinates", "LabFaceX")
    IniWrite(ADBLabFaceY, "config.ini", "ADBCoordinates", "LabFaceY")
    IniWrite(ADBUpgradeMoreBtnX, "config.ini", "ADBCoordinates", "UpgradeMoreBtnX")
    IniWrite(ADBUpgradeMoreBtnY, "config.ini", "ADBCoordinates", "UpgradeMoreBtnY")
    IniWrite(ADBAddWall1X, "config.ini", "ADBCoordinates", "AddWall1X")
    IniWrite(ADBAddWall1Y, "config.ini", "ADBCoordinates", "AddWall1Y")
    IniWrite(ADBRemoveWallX, "config.ini", "ADBCoordinates", "RemoveWallX")
    IniWrite(ADBRemoveWallY, "config.ini", "ADBCoordinates", "RemoveWallY")
    IniWrite(ADBGoldUpgradeX, "config.ini", "ADBCoordinates", "GoldUpgradeX")
    IniWrite(ADBGoldUpgradeY, "config.ini", "ADBCoordinates", "GoldUpgradeY")
    IniWrite(ADBElixirUpgradeX, "config.ini", "ADBCoordinates", "ElixirUpgradeX")
    IniWrite(ADBElixirUpgradeY, "config.ini", "ADBCoordinates", "ElixirUpgradeY")
    IniWrite(ADBUpgradeConfirmX, "config.ini", "ADBCoordinates", "UpgradeConfirmX")
    IniWrite(ADBUpgradeConfirmY, "config.ini", "ADBCoordinates", "UpgradeConfirmY")
    IniWrite(ADBWarLogoX, "config.ini", "ADBCoordinates", "MVLogoX")
    IniWrite(ADBWarLogoY, "config.ini", "ADBCoordinates", "MVLogoY")
    IniWrite(ADBAttackBtnX, "config.ini", "ADBCoordinates", "AttackBtnX")
    IniWrite(ADBAttackBtnY, "config.ini", "ADBCoordinates", "AttackBtnY")
    IniWrite(ADBFindMatchBtnX, "config.ini", "ADBCoordinates", "FindMatchBtnX")
    IniWrite(ADBFindMatchBtnY, "config.ini", "ADBCoordinates", "FindMatchBtnY")
    IniWrite(ADBAttackStartBtnX, "config.ini", "ADBCoordinates", "AttackStartBtnX")
    IniWrite(ADBAttackStartBtnY, "config.ini", "ADBCoordinates", "AttackStartBtnY")
    IniWrite(ADBGoldAreaX, "config.ini", "ADBCoordinates", "GoldAreaX")
    IniWrite(ADBGoldAreaY, "config.ini", "ADBCoordinates", "GoldAreaY")
    IniWrite(ADBElixirAreaX, "config.ini", "ADBCoordinates", "ElixirAreaX")
    IniWrite(ADBElixirAreaY, "config.ini", "ADBCoordinates", "ElixirAreaY")
    IniWrite(ADBNextMatchBtnX, "config.ini", "ADBCoordinates", "NextMatchBtnX")
    IniWrite(ADBNextMatchBtnY, "config.ini", "ADBCoordinates", "NextMatchBtnY")
    IniWrite(ADBSide1StartX, "config.ini", "ADBCoordinates", "Side1StartX")
    IniWrite(ADBSide1StartY, "config.ini", "ADBCoordinates", "Side1StartY")
    IniWrite(ADBSide1EndX, "config.ini", "ADBCoordinates", "Side1EndX")
    IniWrite(ADBSide1EndY, "config.ini", "ADBCoordinates", "Side1EndY")
    IniWrite(ADBSide2StartX, "config.ini", "ADBCoordinates", "Side2StartX")
    IniWrite(ADBSide2StartY, "config.ini", "ADBCoordinates", "Side2StartY")
    IniWrite(ADBSide2EndX, "config.ini", "ADBCoordinates", "Side2EndX")
    IniWrite(ADBSide2EndY, "config.ini", "ADBCoordinates", "Side2EndY")
    IniWrite(ADBSide3StartX, "config.ini", "ADBCoordinates", "Side3StartX")
    IniWrite(ADBSide3StartY, "config.ini", "ADBCoordinates", "Side3StartY")
    IniWrite(ADBSide3EndX, "config.ini", "ADBCoordinates", "Side3EndX")
    IniWrite(ADBSide3EndY, "config.ini", "ADBCoordinates", "Side3EndY")
    IniWrite(ADBSide4StartX, "config.ini", "ADBCoordinates", "Side4StartX")
    IniWrite(ADBSide4StartY, "config.ini", "ADBCoordinates", "Side4StartY")
    IniWrite(ADBSide4EndX, "config.ini", "ADBCoordinates", "Side4EndX")
    IniWrite(ADBSide4EndY, "config.ini", "ADBCoordinates", "Side4EndY")
    IniWrite(ADBReturnHomeClickX, "config.ini", "ADBCoordinates", "ReturnHomeClickX")
    IniWrite(ADBReturnHomeClickY, "config.ini", "ADBCoordinates", "ReturnHomeClickY")
    IniWrite(ADBBBAttackBtnX, "config.ini", "ADBCoordinates", "BBAttackBtnX")
    IniWrite(ADBBBAttackBtnY, "config.ini", "ADBCoordinates", "BBAttackBtnY")
    IniWrite(ADBBBFindMatchBtnX, "config.ini", "ADBCoordinates", "BBFindMatchBtnX")
    IniWrite(ADBBBFindMatchBtnY, "config.ini", "ADBCoordinates", "BBFindMatchBtnY")
    IniWrite(ADBBBStar1X, "config.ini", "ADBCoordinates", "BBStar1X")
    IniWrite(ADBBBStar1Y, "config.ini", "ADBCoordinates", "BBStar1Y")
    IniWrite(ADBBBStar2X, "config.ini", "ADBCoordinates", "BBStar2X")
    IniWrite(ADBBBStar2Y, "config.ini", "ADBCoordinates", "BBStar2Y")
    IniWrite(ADBBBStar3X, "config.ini", "ADBCoordinates", "BBStar3X")
    IniWrite(ADBBBStar3Y, "config.ini", "ADBCoordinates", "BBStar3Y")
    IniWrite(ADBBBSide1StartX, "config.ini", "ADBCoordinates", "BBSide1StartX")
    IniWrite(ADBBBSide1StartY, "config.ini", "ADBCoordinates", "BBSide1StartY")
    IniWrite(ADBBBSide1EndX, "config.ini", "ADBCoordinates", "BBSide1EndX")
    IniWrite(ADBBBSide1EndY, "config.ini", "ADBCoordinates", "BBSide1EndY")
    IniWrite(ADBBBSide2StartX, "config.ini", "ADBCoordinates", "BBSide2StartX")
    IniWrite(ADBBBSide2StartY, "config.ini", "ADBCoordinates", "BBSide2StartY")
    IniWrite(ADBBBSide2EndX, "config.ini", "ADBCoordinates", "BBSide2EndX")
    IniWrite(ADBBBSide2EndY, "config.ini", "ADBCoordinates", "BBSide2EndY")
    IniWrite(ADBBBSide3StartX, "config.ini", "ADBCoordinates", "BBSide3StartX")
    IniWrite(ADBBBSide3StartY, "config.ini", "ADBCoordinates", "BBSide3StartY")
    IniWrite(ADBBBSide3EndX, "config.ini", "ADBCoordinates", "BBSide3EndX")
    IniWrite(ADBBBSide3EndY, "config.ini", "ADBCoordinates", "BBSide3EndY")
    IniWrite(ADBBBSide4StartX, "config.ini", "ADBCoordinates", "BBSide4StartX")
    IniWrite(ADBBBSide4StartY, "config.ini", "ADBCoordinates", "BBSide4StartY")
    IniWrite(ADBBBSide4EndX, "config.ini", "ADBCoordinates", "BBSide4EndX")
    IniWrite(ADBBBSide4EndY, "config.ini", "ADBCoordinates", "BBSide4EndY")
    adbCollectorStr := ""
    for coord in ADBCollectorCoords
        adbCollectorStr .= coord.x "," coord.y ";"
    IniWrite(adbCollectorStr, "config.ini", "ADBCoordinates", "CollectorCoords")
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
    ResizeBtn := MyGui.Add("Button", "x20 y370 w320 h30", "Resize Game Window to 1920x1080")
    ResizeBtn.OnEvent("Click", (*) => ResizeGameWindow())
    SaveBtn := MyGui.Add("Button", "x20 y405 w320 h35", "Save Settings")
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
ResizeGameWindow() {
    global TargetWindowTitle
    if !WinExist(TargetWindowTitle) {
        MsgBox("Game window '" TargetWindowTitle "' not found.", "Error", "Iconx")
        return
    }
    WinMove ,, 1920, 1080, TargetWindowTitle
    LogMessage("Game window resized to 1920x1080.")
    ShowToolTip("Resized to 1920x1080")
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
ActivateGameWindow() {
    global TargetWindowTitle
    if !WinExist(TargetWindowTitle) {
        LogMessage("Error: Window '" TargetWindowTitle "' not found!")
        return false
    }
    return true
}
EnsureWindowActive() {
    global TargetWindowTitle
    return WinExist(TargetWindowTitle) ? true : false
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
    if !ActivateGameWindow() {
        MsgBox("Game window '" TargetWindowTitle "' must be open before calibrating.", "Calibration Error", "Iconx")
        return
    }
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
    LogMessage("Calibration started. Switch to the game window.")
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
    if !ActivateGameWindow() {
        MsgBox("Game window '" TargetWindowTitle "' must be open before calibrating.", "Calibration Error", "Iconx")
        return
    }
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
    LogMessage("Builder Base Calibration started. Switch to the game window.")
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
    global ADBBBCalibrationVersion, ADB_COORDINATE_VERSION, ADBBBSides
    global ADBBBSide1StartX, ADBBBSide1StartY, ADBBBSide1EndX, ADBBBSide1EndY
    global ADBBBSide2StartX, ADBBBSide2StartY, ADBBBSide2EndX, ADBBBSide2EndY
    global ADBBBSide3StartX, ADBBBSide3StartY, ADBBBSide3EndX, ADBBBSide3EndY
    global ADBBBSide4StartX, ADBBBSide4StartY, ADBBBSide4EndX, ADBBBSide4EndY
    IsBBCalibrating := false
    BBCalibStep := 0
    ADBBBSides := [
        {startX: ADBBBSide1StartX, startY: ADBBBSide1StartY, endX: ADBBBSide1EndX, endY: ADBBBSide1EndY},
        {startX: ADBBBSide2StartX, startY: ADBBBSide2StartY, endX: ADBBBSide2EndX, endY: ADBBBSide2EndY},
        {startX: ADBBBSide3StartX, startY: ADBBBSide3StartY, endX: ADBBBSide3EndX, endY: ADBBBSide3EndY},
        {startX: ADBBBSide4StartX, startY: ADBBBSide4StartY, endX: ADBBBSide4EndX, endY: ADBBBSide4EndY}
    ]
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
            instructions := "Step 6/31: Builder Face (Home Screen)`n`nHover mouse over the top-center Builder head icon and press SPACE."
        case 7:
            instructions := "Step 7/31: Builder Menu Bottom`n`nClick the Builder Face to open the Builder menu. Hover over the bottom point where the upward drag should start and press SPACE. The ADB drag will use the Builder Face X and this point's Y."
        case 8:
            instructions := "Step 8/31: Lab Face (Home Screen)`n`nClose the Builder menu, hover mouse over the top-center Lab icon (potion and sword), and press SPACE."
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
            instructions := "Step 19/31: Multiplayer Gold Area (Matchmaking Search)`n`nHover mouse over the Gold count digits in a multiplayer match search and press SPACE."
        case 20:
            instructions := "Step 20/31: Multiplayer Elixir Area (Matchmaking Search)`n`nHover mouse over the Elixir count digits in a multiplayer match search and press SPACE."
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
    global ADBMainCalibrationVersion, ADB_COORDINATE_VERSION, ADBSides
    global ADBSide1StartX, ADBSide1StartY, ADBSide1EndX, ADBSide1EndY
    global ADBSide2StartX, ADBSide2StartY, ADBSide2EndX, ADBSide2EndY
    global ADBSide3StartX, ADBSide3StartY, ADBSide3EndX, ADBSide3EndY
    global ADBSide4StartX, ADBSide4StartY, ADBSide4EndX, ADBSide4EndY
    IsCalibrating := false
    CalibStep := 0
    IsWaitingForReset := false
    SetTimer(RunCollectorReset, 0)
    SetTimer(RunSidesReset, 0)
    ToolTip()
    ADBSides := [
        {startX: ADBSide1StartX, startY: ADBSide1StartY, endX: ADBSide1EndX, endY: ADBSide1EndY},
        {startX: ADBSide2StartX, startY: ADBSide2StartY, endX: ADBSide2EndX, endY: ADBSide2EndY},
        {startX: ADBSide3StartX, startY: ADBSide3StartY, endX: ADBSide3EndX, endY: ADBSide3EndY},
        {startX: ADBSide4StartX, startY: ADBSide4StartY, endX: ADBSide4EndX, endY: ADBSide4EndY}
    ]
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
    global TargetWindowTitle, ADBAttackBtnX
    global ADBGoldAreaX, ADBGoldAreaY, ADBElixirAreaX, ADBElixirAreaY
    isADB := (ADBAttackBtnX > 0)
    if isADB {
        if (label == "Gold") {
            scrX := ADBGoldAreaX
            scrY := ADBGoldAreaY
        } else {
            scrX := ADBElixirAreaX
            scrY := ADBElixirAreaY
        }
    } else {
        if !WinExist(TargetWindowTitle)
            return 0
        WinGetClientPos &cx, &cy,,, TargetWindowTitle
        scrX := cx + relX
        scrY := cy + relY
    }
    scales := [1, 1.5, 2, 2.5, 3, 4]
    rawValues := []
    roundedValues := []
    imgName := A_ScriptDir "\scratch\ocr_loot_temp.png"
    if isADB {
        SaveRegionToPNG(scrX, scrY, relW, relH, imgName)
    }
    for scaleVal in scales {
        try {
            if isADB {
                result := OCR.FromFile(imgName, {scale: scaleVal})
            } else {
                result := OCR.FromRect(scrX, scrY, relW, relH, {scale: scaleVal})
            }
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
    if isADB {
        try FileDelete(imgName)
    }
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
    global TargetWindowTitle, Troop1Count, Troop2Count, Troop3Count
    if !WinExist(TargetWindowTitle) {
        LogMessage("OCR Battle Troop Scan: Game window not found.")
        return [Troop1Count, Troop2Count, Troop3Count]
    }
    WinGetClientPos &cx, &cy, &w, &h, TargetWindowTitle
    ; Region for the troop selection bar (bottom 30% of the game client area, starts higher to capture top-right counts)
    scrX := cx
    scrY := cy + Integer(h * 0.70)
    scrW := w
    scrH := Integer(h * 0.25)
    counts := [0, 0, 0]
    try {
        ; Use scale: 2 for better OCR accuracy
        result := OCR.FromRect(scrX, scrY, scrW, scrH, {scale: 2})
        for word in result.Words {
            text := word.Text
            if RegExMatch(text, "i)^[x\*]?(\d+)$", &match) {
                val := Integer(match[1])
                if (val > 0) {
                    ; Relative X midpoint and relative Y within scanned region
                    relX := (word.x + word.w/2 - cx) / w
                    relY := word.y - scrY
                    ; Check if this is the troop count (has x/X/* prefix OR is in the top half of the scanned bar)
                    isCount := RegExMatch(text, "i)^[x\*]") || (relY < scrH * 0.5)
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
IsGoldBarFilled(x, y) {
    global ADBGoldBarThreshX
    try {
        color := (ADBGoldBarThreshX > 0) ? GetADBPixelColor(x, y) : (CoordMode("Pixel", "Client"), PixelGetColor(x, y))
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
    global ADBElixirBarThreshX
    try {
        color := (ADBElixirBarThreshX > 0) ? GetADBPixelColor(x, y) : (CoordMode("Pixel", "Client"), PixelGetColor(x, y))
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
    global ADBDarkElixirBarThreshX
    try {
        topColor := (ADBDarkElixirBarThreshX > 0) ? GetADBPixelColor(x, y) : (CoordMode("Pixel", "Client"), PixelGetColor(x, y))
        bottomColor := (ADBDarkElixirBarThreshX > 0) ? GetADBPixelColor(x, y + 3) : (CoordMode("Pixel", "Client"), PixelGetColor(x, y + 3))
        
        topR := (topColor >> 16) & 0xFF
        topG := (topColor >> 8) & 0xFF
        topB := topColor & 0xFF
        
        botR := (bottomColor >> 16) & 0xFF
        botG := (bottomColor >> 8) & 0xFF
        botB := bottomColor & 0xFF
        
        isTopEmpty := (topR > 110 && topG > 110 && topB > 110) && (Abs(topR - topG) < 20)
        isBotDark := (botR < 70) && (botG < 70) && (botB < 70)
        isTopDark := (topR < 110) && (topG < 110) && (topB < 110)
        topLighterThanBot := (topR >= botR) && (topG >= botG) && (topB >= botB)
        
        if (isBotDark && isTopDark && topLighterThanBot && !isTopEmpty)
            return true
            
        return false
    } catch {
        return false
    }
}
GetBuilderCountFromWindowsOCR(scrX, scrY, scrW, scrH, &free, &total) {
    candidates := Map()
    scanLog := ""
    for scale in [1, 1.5, 2, 2.5, 3, 4] {
        try {
            result := OCR.FromRect(scrX, scrY, scrW, scrH, {scale: scale})
            rawText := Trim(result.Text)
            scanLog .= "[" scale ": " rawText "] "
            if ParseBuilderFraction(rawText, &candidateFree, &candidateTotal) {
                key := candidateFree "/" candidateTotal
                if !candidates.Has(key)
                    candidates[key] := {count: 0, free: candidateFree, total: candidateTotal}
                candidates[key].count += 1
            }
        } catch as err {
            scanLog .= "[" scale ": error] "
        }
    }
    best := ""
    for key, candidate in candidates {
        if !IsObject(best) || candidate.count > best.count
            best := candidate
    }
    if IsObject(best) && best.count >= 2 {
        free := best.free
        total := best.total
        LogMessage("Builder Windows OCR consensus: " free "/" total " (" best.count "/6).")
        return true
    }
    LogMessage("Builder Windows OCR had no consensus. " scanLog)
    return false
}

GetBuilderCount(&free, &total) {
    global ADBBuilderFaceX, ADBBuilderFaceY, BuilderFaceX, BuilderFaceY, TargetWindowTitle
    free := 0
    total := 0
    if (ADBBuilderFaceX > 0) {
        scrX := ADBBuilderFaceX - 30
        scrY := ADBBuilderFaceY - 15
        scrW := 130
        scrH := 30
        h := 1080
    } else {
        if !WinExist(TargetWindowTitle)
            return false
        WinGetClientPos &cx, &cy, &w, &h, TargetWindowTitle
        scrX := cx + BuilderFaceX - 30
        scrY := cy + BuilderFaceY - 15
        scrW := 130
        scrH := 30
    }
    windowsFree := 0
    windowsTotal := 0
    hasWindowsConsensus := (ADBBuilderFaceX == 0) ? GetBuilderCountFromWindowsOCR(scrX, scrY, scrW, scrH, &windowsFree, &windowsTotal) : false
    
    imgName := A_ScriptDir "\builder_area_bot.png"
    SaveRegionToPNG(scrX, scrY, scrW, scrH, imgName)
    clean_out := Trim(RunWaitPythonScript('builders "' imgName '" ' h))
    try FileDelete(imgName)
    
    hasTemplateResult := RegExMatch(clean_out, "SUCCESS: (\d)/(\d)", &match)
    if hasWindowsConsensus {
        free := windowsFree
        total := windowsTotal
        if hasTemplateResult {
            templateFree := Integer(match[1])
            templateTotal := Integer(match[2])
            if (templateFree != free || templateTotal != total)
                LogMessage(Format("Builder OCR disagreement: Windows={}/{}, template={}/{}. Using multi-scale Windows consensus.", free, total, templateFree, templateTotal))
        }
        return true
    }
    if hasTemplateResult {
        free := Integer(match[1])
        total := Integer(match[2])
        LogMessage(Format("Builder template OCR parsed: {}/{}", free, total))
        return true
    }
    LogMessage("Builder OCR failed. Output: " clean_out)
    return false
}

CanUpgradeBuilding() {
    global EnableWallUpgrade
    free := 0
    total := 0
    if !GetBuilderCount(&free, &total)
        return false ; If OCR fails, assume we can't upgrade to be safe
    
    if (EnableWallUpgrade) {
        ; If walls are enabled, we must leave 1 builder for walls.
        ; So we need at least 2 builders to do a building upgrade.
        return free >= 2
    } else {
        ; If walls are disabled, we can use the last builder for buildings.
        return free >= 1
    }
}

CanUpgradeWall() {
    free := 0
    total := 0
    if !GetBuilderCount(&free, &total)
        return false
        
    return free >= 1
}
FindCenterGreenButton(&outX, &outY) {
    global TargetWindowTitle, ADBAttackBtnX
    hwnd := WinExist(TargetWindowTitle)
    if !hwnd
        return false
    WinGetClientPos &cx, &cy, &w, &h, hwnd
    searchX := cx + (w * 0.3)
    searchY := cy + (h * 0.4)
    searchW := w * 0.4
    searchH := h * 0.4
    ; Scan a grid in the center area for the signature green color
    loop 20 {
        dy := searchY + (A_Index * (searchH / 20))
        loop 20 {
            dx := searchX + (A_Index * (searchW / 20))
            clientX := dx - cx
            clientY := dy - cy
            if (ADBAttackBtnX > 0) {
                try {
                    adbPt := ClientToADBPoint(clientX, clientY)
                    c := GetADBPixelColor(adbPt.x, adbPt.y)
                } catch {
                    continue
                }
            } else {
                if !EnsureWindowActive()
                    return false
                c := PixelGetColor(dx, dy)
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
    global ADBAddWall1X, ADBAddWall1Y, ADBRemoveWallX, ADBRemoveWallY, ADBReturnHomeClickX, ADBReturnHomeClickY
    global DarkElixirBarThreshX, DarkElixirBarThreshY, GoldBarThreshX, GoldBarThreshY, ElixirBarThreshX, ElixirBarThreshY
    wallCount := 4
    ; First, add 3 walls to reach the maximum 4
    Loop 3 {
        ADBClickPoint(ADBAddWall1X, ADBAddWall1Y)
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
                    ADBClickPoint(ADBReturnHomeClickX, ADBReturnHomeClickY) ; Dismiss Gem popup
                    SafeSleep(500)
                    break
                }
                LogMessage("Farming: Upgrade too expensive (Gem popup detected). Removing one wall...")
                ADBClickPoint(ADBReturnHomeClickX, ADBReturnHomeClickY) ; Dismiss Gem popup
                if !SafeSleep(800)
                    return false
                ADBClickPoint(ADBRemoveWallX, ADBRemoveWallY) ; Remove one wall
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
    ADBClickPoint(ADBReturnHomeClickX, ADBReturnHomeClickY)
    SafeSleep(500)
    return true
}
CollectResources() {
    global ADBCollectorCoords, IsRunning
    if (ADBCollectorCoords.Length == 0)
        return
    ; If you ever want to make this run 100% of the time, change this to Random(1, 1)
    ; DO NOT completely remove this random block!
    roll := Random(1, 40)
    if (roll != 1) {
        LogMessage("Farming: Skipping resource collection this cycle (Rolled " roll "/40, needs 1).")
        return
    }
    LogMessage("Farming: Collecting resources from " ADBCollectorCoords.Length " mines/collectors...")
    for coord in ADBCollectorCoords {
        if !IsRunning
            break
        ADBClickPoint(coord.x, coord.y)
        SafeSleep(250)
    }
}
FindAnyWallInDropdown() {
    global BuilderFaceX, BuilderFaceY, BuilderMenuBottomY, LabFaceX, LabFaceY, UpgradeConfirmX, UpgradeConfirmY, TargetWindowTitle
    global ADBBuilderFaceX, ADBBuilderFaceY, ADBBuilderMenuBottomX, ADBBuilderMenuBottomY
    WinGetClientPos &cx, &cy, &w, &h, TargetWindowTitle
    menuLeft := BuilderFaceX - (w * 0.18)
    menuWidth := w * 0.36
    menuTop := h * 0.12
    menuHeight := h * 0.75
    scrLeft := cx + menuLeft
    scrTop := cy + menuTop
    ; Scroll down in chunks until we see ANY Wall text
    Loop 4 {
        for sc in [2.5, 2.0, 3.0] {
            try {
                result := OCR.FromRect(scrLeft, scrTop, menuWidth, menuHeight, {scale: sc})
                for line in result.Lines {
                    ; Matches Wall, wall, Wa11, WaIl, Wail, Vall, val1, wal, val, etc.
                    if RegExMatch(line.Text, "i)\b[vw][aAeEoOuU01iI][lLiI1t]{1,2}\b") {
                        LogMessage(Format("Farming: Found Wall suggestion: '{}' (using scale {})", line.Text, sc))
                        relX := (line.x + (line.w / 2)) - cx
                        relY := (line.y + (line.h / 2)) - cy
                        ClientClickPoint(relX, relY, 2) ; OCR result is a dynamic client point.
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
            RunADBSwipeAt(ADBBuilderMenuBottomX, ADBBuilderMenuBottomY, ADBBuilderFaceX, ADBBuilderFaceY, RandomADBDuration())
            Sleep 800
        }
    }
    return false
}
UpgradeWalls() {
    global EnableWallUpgrade, IsRunning, TargetWindowTitle
    global BuilderFaceX, BuilderFaceY, LabFaceX, LabFaceY, UpgradeConfirmX, UpgradeConfirmY, ReturnHomeClickX, ReturnHomeClickY
    CoordMode "Mouse", "Client"
    global UpgradeMoreBtnX, UpgradeMoreBtnY
    global GoldUpgradeX, GoldUpgradeY, ElixirUpgradeX, ElixirUpgradeY
    global ADBBuilderFaceX, ADBBuilderFaceY, ADBUpgradeMoreBtnX, ADBUpgradeMoreBtnY
    global ADBGoldUpgradeX, ADBGoldUpgradeY, ADBElixirUpgradeX, ADBElixirUpgradeY, ADBReturnHomeClickX, ADBReturnHomeClickY
    global DarkElixirBarThreshX, DarkElixirBarThreshY, GoldBarThreshX, GoldBarThreshY, ElixirBarThreshX, ElixirBarThreshY
    if !EnableWallUpgrade
        return
    ; 1. Check if resource thresholds are reached by reading bar colors
    runGoldUpgrade := IsGoldBarFilled(GoldBarThreshX, GoldBarThreshY)
    runElixirUpgrade := IsElixirBarFilled(ElixirBarThreshX, ElixirBarThreshY)
    if !runGoldUpgrade && !runElixirUpgrade {
        LogMessage("Farming: Storage bars have not reached calibrated threshold points. Skipping wall upgrades.")
        return
    }
    LogMessage("Farming: Checking builder status for wall upgrades...")
    if !CanUpgradeWall() {
        LogMessage("Farming: All builders are busy. Skipping wall upgrade.")
        return
    }
    ; --- 2. Elixir Wall Upgrade (Prioritized) ---
    if runElixirUpgrade {
        LogMessage("Farming: Elixir threshold met! Selecting a wall for Elixir upgrade...")
        ADBClickPoint(ADBBuilderFaceX, ADBBuilderFaceY)
        if !SafeSleep(800)
            return
        if EnsureWindowActive() {
            if FindAnyWallInDropdown() {
                if !SafeSleep(5000)
                    return
                ADBClickPoint(ADBUpgradeMoreBtnX, ADBUpgradeMoreBtnY)
                if !SafeSleep(800)
                    return
                ProcessWallUpgrade(ADBElixirUpgradeX, ADBElixirUpgradeY, "elixir")
            } else {
                LogMessage("Farming: No Wall upgrades found in builder suggestions.")
                ADBClickPoint(ADBReturnHomeClickX, ADBReturnHomeClickY)
                SafeSleep(500)
            }
        }
    }
    ; --- 3. Gold Wall Upgrade ---
    if runGoldUpgrade {
        LogMessage("Farming: Gold bar threshold met! Selecting a wall for Gold upgrade...")
        ADBClickPoint(ADBBuilderFaceX, ADBBuilderFaceY)
        if !SafeSleep(800)
            return
        if EnsureWindowActive() {
            if FindAnyWallInDropdown() {
                if !SafeSleep(5000)
                    return
                ADBClickPoint(ADBUpgradeMoreBtnX, ADBUpgradeMoreBtnY)
                if !SafeSleep(800)
                    return
                ProcessWallUpgrade(ADBGoldUpgradeX, ADBGoldUpgradeY, "gold")
            } else {
                LogMessage("Farming: No Wall upgrades found in builder suggestions.")
                ADBClickPoint(ADBReturnHomeClickX, ADBReturnHomeClickY)
                SafeSleep(500)
            }
        }
    }
}
IsReturnHomePresent() {
    global ADBReturnHomeClickX, ADBReturnHomeClickY, ReturnHomeColor, ReturnHomeTolerance
    global ReturnHomeClickX, ReturnHomeClickY
    if (ADBReturnHomeClickX > 0) {
        return IsReturnHomePresentADB()
    }
    if !EnsureWindowActive()
        return false
    ; 1. Check calibrated color
    if ColorMatches(ReturnHomeClickX, ReturnHomeClickY, ReturnHomeColor, ReturnHomeTolerance)
        return true
    ; 2. Fallback: Scan a vertical line of pixels to find the specific bright green button background (avoiding white text)
    offsets := [-25, -15, -5, 5, 15, 25]
    for dy in offsets {
        try {
            c := PixelGetColor(ReturnHomeClickX, ReturnHomeClickY + dy)
            actualHex := Integer(c)
            r := (actualHex >> 16) & 0xFF
            g := (actualHex >> 8) & 0xFF
            b := actualHex & 0xFF
            ; Bright green button check (guaranteed not to match day/night battlefield grass)
            if (g > 140) && (g > r + 35) && (g > b + 70)
                return true
        }
    }
    return false
}
IsReturnHomePresentADB() {
    global ADBReturnHomeClickX, ADBReturnHomeClickY, ReturnHomeColor, ReturnHomeTolerance
    if (ADBReturnHomeClickX <= 0)
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
            c := GetADBPixelColor(ADBReturnHomeClickX + pt.x, ADBReturnHomeClickY + pt.y)
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
    global TargetWindowTitle, IsRunning
    if !force && !IsRunning
        return
    if !EnsureWindowActive()
        return
    WinGetClientPos &cx, &cy, &w, &h, TargetWindowTitle
    searchX := cx + (w * 0.25)
    searchY := cy + (h * 0.4)
    searchW := w * 0.5
    searchH := h * 0.4
    try {
        result := OCR.FromRect(searchX, searchY, searchW, searchH, {scale: 1.5})
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
                relX := (buttonLine.x + (buttonLine.w / 2)) - cx
                relY := (buttonLine.y + (buttonLine.h / 2)) - cy
                ClientClickPoint(relX, relY)
            } else {
                LogMessage("Farming: No specific button text detected, clicking screen center fallback...")
                ADBClickFraction(0.5, 0.55)
            }
            Sleep 10000 ; Wait 10 seconds for game to reload
        }
    }
}
SaveRegionToPNG(x, y, w, h, filepath) {
    framePath := CaptureADBFrame()
    if FileExist(framePath) {
        InitGDIPlus()
        pSourceBitmap := 0
        if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", framePath, "ptr*", &pSourceBitmap) == 0 {
            pCroppedBitmap := 0
            DllCall("gdiplus\GdipCloneBitmapArea", "float", Float(x), "float", Float(y), "float", Float(w), "float", Float(h), "int", 0x26200A, "ptr", pSourceBitmap, "ptr*", &pCroppedBitmap)
            clsid := Buffer(16, 0)
            DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid)
            DllCall("gdiplus\GdipSaveImageToFile", "ptr", pCroppedBitmap, "wstr", filepath, "ptr", clsid, "ptr", 0)
            DllCall("gdiplus\GdipDisposeImage", "ptr", pCroppedBitmap)
            DllCall("gdiplus\GdipDisposeImage", "ptr", pSourceBitmap)
            return
        }
    }
    pi := Buffer(24, 0)
    NumPut("uint", 1, pi, 0)
    token := 0
    DllCall("gdiplus\GdiplusStartup", "ptr*", &token, "ptr", pi, "ptr", 0)
    hdcScreen := DllCall("GetDC", "ptr", 0, "ptr")
    hdcMem := DllCall("CreateCompatibleDC", "ptr", hdcScreen, "ptr")
    hbm := DllCall("CreateCompatibleBitmap", "ptr", hdcScreen, "int", w, "int", h, "ptr")
    obm := DllCall("SelectObject", "ptr", hdcMem, "ptr", hbm, "ptr")
    DllCall("BitBlt", "ptr", hdcMem, "int", 0, "int", 0, "int", w, "int", h, "ptr", hdcScreen, "int", x, "int", y, "uint", 0x00CC0020 | 0x40000000)
    pBitmap := 0
    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hbm, "ptr", 0, "ptr*", &pBitmap)
    clsid := Buffer(16, 0)
    DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid)
    DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "wstr", filepath, "ptr", clsid, "ptr", 0)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    DllCall("SelectObject", "ptr", hdcMem, "ptr", obm)
    DllCall("DeleteObject", "ptr", hbm)
    DllCall("DeleteDC", "ptr", hdcMem)
    DllCall("ReleaseDC", "ptr", 0, "ptr", hdcScreen)
}
RunWaitPythonScript(args) {
    global A_ScriptDir
    outFile := A_ScriptDir "\scratch\exec_out.txt"
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
FindTemplateUpgradeButton(hwnd, &outX, &outY) {
    global ADBProvider
    if (ADBProvider != "") {
        display := GetADBDisplaySize()
        w := display.width
        h := display.height
        scrLeft := 0
        scrTop := Integer(h * 0.65)
    } else {
        WinGetClientPos &cx, &cy, &w, &h, hwnd
        scrLeft := cx
        scrTop := cy + Integer(h * 0.65)
    }
    
    imgName := "upgrade_area.png"
    image_path := A_ScriptDir "\" imgName
    SaveRegionToPNG(scrLeft, scrTop, w, Integer(h * 0.35), image_path)
    output := Trim(RunWaitPythonScript('hammer "' image_path '" ' h))
    try FileDelete(image_path)
    if RegExMatch(output, "SUCCESS:\s*(\d+)/(\d+)", &match) {
        match_x := Integer(match[1])
        match_y := Integer(match[2])
        outX := scrLeft + match_x
        outY := scrTop + match_y
        return true
    }
    return false
}
IsLabBusy() {
    global ADBLabFaceX, ADBLabFaceY, LabFaceX, LabFaceY, TargetWindowTitle
    if (ADBLabFaceX > 0) {
        scrX := ADBLabFaceX
        scrY := ADBLabFaceY - 22
        scrW := 115
        scrH := 44
        h := 1080
    } else {
        if !WinExist(TargetWindowTitle)
            return true
        WinGetClientPos &cx, &cy, &w, &h, TargetWindowTitle
        scrX := cx + LabFaceX
        scrY := cy + LabFaceY - 22
        scrW := 115
        scrH := 44
    }

    imgName := A_ScriptDir "\lab_area_bot.png"
    SaveRegionToPNG(scrX, scrY, scrW, scrH, imgName)
    clean_out := Trim(RunWaitPythonScript('lab "' imgName '" ' h))
    try FileDelete(imgName)
    
    if RegExMatch(clean_out, "SUCCESS: (\d)/(\d)", &match) {
        free := Integer(match[1])
        total := Integer(match[2])
        LogMessage(Format("Lab OCR parsed: {}/{}", free, total))
        if free > 0
            return false
        return true
    }
    LogMessage("Lab OCR failed. Output: " clean_out)
    return true ; Default to busy if OCR fails
}

UpgradeLab() {
    global TargetWindowTitle, LabFaceX, LabFaceY, UpgradeConfirmX, UpgradeConfirmY
    global ADBLabFaceX, ADBLabFaceY, ADBUpgradeConfirmX, ADBUpgradeConfirmY
    hwnd := WinExist(TargetWindowTitle)
    if !hwnd
        return
    LogMessage("Lab available! Clicking Lab Face...")
    ADBClickPoint(ADBLabFaceX, ADBLabFaceY)
    Sleep 1200
    
    WinGetClientPos &cx, &cy, &w, &h, hwnd
    menuLeft := LabFaceX - (w * 0.18)
    menuWidth := w * 0.36
    menuTop := h * 0.12
    menuHeight := h * 0.75
    scrLeft := cx + menuLeft
    scrTop := cy + menuTop
    
    clickX := 0, clickY := 0
    found_suggestion := false
    
    for sc in [2.5, 2.0, 3.0] {
        try {
            result := OCR.FromRect(scrLeft, scrTop, menuWidth, menuHeight, {scale: sc})
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
                clickX := (target_line.x + 50) - cx
                clickY := (target_line.y + (target_line.h / 2)) - cy
                found_suggestion := true
                break
            }
        }
    }
    
    if !found_suggestion {
        LogMessage("Failed to find 'Suggested upgrades' section.")
        ClearingClick()
        return
    }
    
    ClientClickPoint(clickX, clickY)
    Sleep 2000
    
    LogMessage("Confirming Lab Upgrade...")
    ADBClickPoint(ADBUpgradeConfirmX, ADBUpgradeConfirmY)
    Sleep 1500
    ClearingClick()
}
UpgradeBuilding() {
    global TargetWindowTitle, BuilderFaceX, BuilderFaceY, UpgradeConfirmX, UpgradeConfirmY
    global ADBBuilderFaceX, ADBBuilderFaceY, ADBUpgradeConfirmX, ADBUpgradeConfirmY
    hwnd := WinExist(TargetWindowTitle)
    if !hwnd
        return false
    LogMessage("Farming: Opening Builder suggestions menu...")
    ADBClickPoint(ADBBuilderFaceX, ADBBuilderFaceY)
    Sleep 1200
    WinGetClientPos &cx, &cy, &w, &h, hwnd
    menuLeft := BuilderFaceX - (w * 0.18)
    menuWidth := w * 0.36
    menuTop := h * 0.12
    menuHeight := h * 0.75
    scrLeft := cx + menuLeft
    scrTop := cy + menuTop
    ; Scan dropdown using OCR
    suggestion_text := ""
    clickX := 0, clickY := 0
    found_suggestion := false
    for sc in [2.5, 2.0, 3.0] {
        try {
            result := OCR.FromRect(scrLeft, scrTop, menuWidth, menuHeight, {scale: sc})
            lines := result.Lines
            ; Find the "Suggested upgrades" header
            suggested_idx := -1
            loop lines.Length {
                if InStr(lines[A_Index].Text, "ggested Upgr") || InStr(lines[A_Index].Text, "ggested upgr") || InStr(lines[A_Index].Text, "Suggested") {
                    suggested_idx := A_Index
                    break
                }
            }
            ; If found, click the first line below it
            if (suggested_idx != -1 && suggested_idx < lines.Length) {
                target_line := lines[suggested_idx + 1]
                suggestion_text := target_line.Text
                clickX := (target_line.x + 50) - cx
                clickY := (target_line.y + (target_line.h / 2)) - cy
                found_suggestion := true
                break
            }
        }
        catch as err {
            LogMessage("Farming: OCR error in dropdown: " err.Message)
        }
    }
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
        ADBClickPoint(ADBUpgradeConfirmX, ADBUpgradeConfirmY)
        Sleep 1500
        ClearingClick()
        return true
    } else {
        ; Building upgrade flow: find "Upgrade" button using Template Matching
        LogMessage("Farming: Building detected. Finding Upgrade hammer button...")
        btnX := 0, btnY := 0
        if FindTemplateUpgradeButton(hwnd, &btnX, &btnY) {
            clickBtnX := btnX - cx
            clickBtnY := btnY - cy
            LogMessage(Format("Farming: Clicking Upgrade hammer button at client {}, {}", clickBtnX, clickBtnY))
            ClientClickPoint(clickBtnX, clickBtnY)
            Sleep 1200
            ; Click calibrated confirmation button directly
            LogMessage(Format("Farming: Clicking calibrated confirmation button at client {}, {}", UpgradeConfirmX, UpgradeConfirmY))
            ADBClickPoint(ADBUpgradeConfirmX, ADBUpgradeConfirmY)
            Sleep 1500
            ClearingClick()
            return true
        } else {
            LogMessage("Farming: Failed to find Upgrade hammer button.")
            ClearingClick()
        }
    }
    return false
}
StartBotLoop() {
    global IsRunning, StatusText, StartBtn, PauseBtn
    global AttackBtnX, AttackBtnY, FindMatchBtnX, FindMatchBtnY, AttackStartBtnX, AttackStartBtnY
    global ReturnHomeClickX, ReturnHomeClickY, BattleLoadDelay, ReturnHomeColor, ReturnHomeTolerance
    global EnableLootSearch, MinGold, MinElixir, NextMatchBtnX, NextMatchBtnY
    global ADBSides, Troop1Count, Troop2Count, Troop3Count
    global ADBAttackBtnX, ADBAttackBtnY, ADBFindMatchBtnX, ADBFindMatchBtnY, ADBAttackStartBtnX, ADBAttackStartBtnY
    global ADBReturnHomeClickX, ADBReturnHomeClickY, ADBNextMatchBtnX, ADBNextMatchBtnY
    ; Check for game timeout immediately before doing anything else
    LastTimeoutCheck := A_TickCount
    CheckGameTimeout(true)
    ; Send an ADB tap without activating the emulator window.
    if WinExist(TargetWindowTitle) {
        WinGetClientPos ,, &cw, &ch, TargetWindowTitle
        LogMessage("Performing initial ADB tap inside the Android viewport...")
        ADBClickFraction(0.8, 0.3)
        SafeSleep(300)
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
        ADBClickPoint(ADBAttackBtnX, ADBAttackBtnY)
        if !SafeSleep(800)
            break
        ; Step 2: Click the gold "Find a Match" button (from Multiplayer dialog)
        LogMessage("Step 2: Clicking Find a Match...")
        ADBClickPoint(ADBFindMatchBtnX, ADBFindMatchBtnY)
        if !SafeSleep(1000) ; Wait for My Army dialog to open fully
            break
        ; Step 3: Click the green "Attack!" button (from My Army dialog)
        LogMessage("Step 3: Clicking Green Attack...")
        ADBClickPoint(ADBAttackStartBtnX, ADBAttackStartBtnY)
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
        side := ADBSides[sideIndex]
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
                ADBClickPoint(ADBNextMatchBtnX, ADBNextMatchBtnY)
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
            ADBClickPoint(ADBReturnHomeClickX, ADBReturnHomeClickY)
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
    global TargetWindowTitle
    if WinExist(TargetWindowTitle) {
        WinGetClientPos ,, &cw, &ch, TargetWindowTitle
        ADBClickFraction(0.8, 0.3)
        SafeSleep(300)
    }
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
RandomADBClick(x, y, delta) {
    return RunADBTapAt(Round(x) + RandomADBOffset(), Round(y) + RandomADBOffset())
}
ADBClickPoint(x, y, delta := "") {
    RandomADBClick(x, y, delta)
    Sleep 100
}
ADBClickFraction(xRatio, yRatio, delta := "") {
    display := GetADBDisplaySize()
    ADBClickPoint(Round((display.width - 1) * xRatio), Round((display.height - 1) * yRatio), delta)
}
ClientClickPoint(x, y, delta := "") {
    point := ClientToADBPoint(x, y)
    ADBClickPoint(point.x, point.y, delta)
}
SendKey(keyName) {
    ready := EnsureADBActionReady()
    if !ready.Ok
        return false
    keyCode := RegExMatch(keyName, "^\d$") ? "KEYCODE_" keyName : "KEYCODE_" StrUpper(keyName)
    result := RunADB('-s ' QuoteADBArgument(ready.Serial) ' shell input keyevent ' keyCode)
    if !result.Ok {
        LogMessage("ADB key failed: " FormatADBResult(result))
        return false
    }
    Sleep 100
    return true
}
DeployTroopLine(hotkeyName, clickCount, delayMs, startX, startY, endX, endY) {
    global IsRunning, DeployDelta
    if !IsRunning
        return
    SendKey(hotkeyName)
    if !SafeSleep(150) ; Wait for selection state
        return
    Loop clickCount {
        if !IsRunning
            break
        t := (clickCount > 1) ? (A_Index - 1) / (clickCount - 1) : 0
        rx := startX + t * (endX - startX)
        ry := startY + t * (endY - startY)
        RandomADBClick(rx, ry, DeployDelta)
        if !SafeSleep(delayMs)
            break
    }
    SafeSleep(300)
}
DeploySinglePoint(hotkeyName, x, y) {
    global IsRunning, DeployDelta
    if !IsRunning
        return
    SendKey(hotkeyName)
    if !SafeSleep(350)
        return
    RandomADBClick(x, y, DeployDelta)
    SafeSleep(150)
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
ColorMatches(x, y, targetColorRGB, tolerance := 20) {
    CoordMode "Pixel", "Client"
    try {
        color := PixelGetColor(x, y)
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
    }
    catch {
        return false
    }
}
IsGolden(x, y) {
    global ADBBBStar3X, ADBBBStar3Y, BBStar3X
    if (ADBBBStar3X > 0) {
        if (x == BBStar3X)
            return IsGoldenADB(ADBBBStar3X, ADBBBStar3Y)
        adbPoint := ClientToADBPoint(x, y)
        return IsGoldenADB(adbPoint.x, adbPoint.y)
    }
    try {
        c := PixelGetColor(x, y)
        hx := Integer(c)
        r := (hx >> 16) & 0xFF
        g := (hx >> 8) & 0xFF
        b := hx & 0xFF
        return (r > 120) && (r > b + 40) && (g > b + 20)
    } catch {
        return false
    }
}
IsGoldenADB(adbX, adbY) {
    try {
        offsetsX := [-7, -3, 0, 3, 7]
        offsetsY := [-7, -3, 0, 3, 7]
        for dx in offsetsX {
            for dy in offsetsY {
                c := GetADBPixelColor(adbX + dx, adbY + dy)
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
    pt1 := ClientToADBPoint(CloudPt1X, CloudPt1Y)
    pt2 := ClientToADBPoint(CloudPt2X, CloudPt2Y)
    pt3 := ClientToADBPoint(CloudPt3X, CloudPt3Y)
    pt4 := ClientToADBPoint(CloudPt4X, CloudPt4Y)
    if IsGreyADB(pt1.x, pt1.y, CloudGreyTolerance)
        greyCount++
    if IsGreyADB(pt2.x, pt2.y, CloudGreyTolerance)
        greyCount++
    if IsGreyADB(pt3.x, pt3.y, CloudGreyTolerance)
        greyCount++
    if IsGreyADB(pt4.x, pt4.y, CloudGreyTolerance)
        greyCount++
    return greyCount >= 3
}
IsGrey(x, y, tolerance := 15) {
    CoordMode "Pixel", "Client"
    try {
        color := PixelGetColor(x, y)
        actualHex := Integer(color)
        r := (actualHex >> 16) & 0xFF
        g := (actualHex >> 8) & 0xFF
        b := actualHex & 0xFF
        return (r >= 120) && (Abs(r - g) <= tolerance) && (Abs(g - b) <= tolerance) && (Abs(r - b) <= tolerance)
    }
    catch {
        return false
    }
}
IsBrown(x, y) {
    CoordMode "Pixel", "Client"
    try {
        color := PixelGetColor(x, y)
        actualHex := Integer(color)
        r := (actualHex >> 16) & 0xFF
        g := (actualHex >> 8) & 0xFF
        b := actualHex & 0xFF
        return (r > g) && (g > b) && (r - b >= 30) && (g - b >= 10) && (r >= 70 && r <= 250)
    }
    catch {
        return false
    }
}
IsAtHomeVillage() {
    global ADBAttackBtnX, ADBAttackBtnY, AttackBtnX, AttackBtnY, WarLogoColor
    if (ADBAttackBtnX > 0) {
        isHome := IsBrownADB(ADBAttackBtnX - 45, ADBAttackBtnY) || IsBrownADB(ADBAttackBtnX + 45, ADBAttackBtnY)
        if !isHome
            return false
        Sleep 300
        isHome := IsBrownADB(ADBAttackBtnX - 45, ADBAttackBtnY) || IsBrownADB(ADBAttackBtnX + 45, ADBAttackBtnY)
        if !isHome
            return false
        if !IsWarLogoPresent()
            return false
        return true
    }
    if !EnsureWindowActive()
        return false
    isHome := IsBrown(AttackBtnX - 45, AttackBtnY) || IsBrown(AttackBtnX + 45, AttackBtnY)
    if !isHome
        return false
    Sleep 300
    isHome := IsBrown(AttackBtnX - 45, AttackBtnY) || IsBrown(AttackBtnX + 45, AttackBtnY)
    if !isHome
        return false
    if !IsWarLogoPresent()
        return false
    return true
}
IsWarLogoPresent() {
    global ADBWarLogoX, ADBWarLogoY, WarLogoX, WarLogoY, WarLogoColor
    if (ADBWarLogoX > 0) {
        return IsBrownADB(ADBWarLogoX, ADBWarLogoY)
    }
    return IsBrown(WarLogoX, WarLogoY)
}
IsAtBuilderBase() {
    global ADBBBAttackBtnX, ADBBBAttackBtnY, BBAttackBtnX, BBAttackBtnY
    if (ADBBBAttackBtnX > 0) {
        return IsBrownADB(ADBBBAttackBtnX - 45, ADBBBAttackBtnY) || IsBrownADB(ADBBBAttackBtnX + 45, ADBBBAttackBtnY)
    }
    if !EnsureWindowActive()
        return false
    isBB := IsBrown(BBAttackBtnX - 45, BBAttackBtnY) || IsBrown(BBAttackBtnX + 45, BBAttackBtnY)
    if !isBB
        return false
    Sleep 300
    return IsBrown(BBAttackBtnX - 45, BBAttackBtnY) || IsBrown(BBAttackBtnX + 45, BBAttackBtnY)
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
RunBuilderBaseLoop() {
    global IsBBRunning, TransitionDelay, BattleLoadDelay, ReturnHomeClickX, ReturnHomeClickY, StartBtn, PauseBtn
    global ADBBBAttackBtnX, ADBBBAttackBtnY, ADBBBFindMatchBtnX, ADBBBFindMatchBtnY, ADBBBSides
    global ADBReturnHomeClickX, ADBReturnHomeClickY
    LogMessage("--- Starting Builder Base Loop ---")
    while IsBBRunning {
        LogMessage("Step 1: Clicking BB Attack Button")
        ADBClickPoint(ADBBBAttackBtnX, ADBBBAttackBtnY)
        if !SafeSleep(TransitionDelay)
            break
        LogMessage("Step 2: Clicking BB Find Match")
        ADBClickPoint(ADBBBFindMatchBtnX, ADBBBFindMatchBtnY)
        if !SafeSleep(TransitionDelay)
            break
        LogMessage("Waiting 7s for matchmaking transition...")
        if !SafeSleep(7000)
            goto BBLoopExit
        if AreCloudsPresent() {
            LogMessage("Step 4: Waiting for battle to load...")
            while AreCloudsPresent() {
                if !SafeSleep(5000)
                    goto BBLoopExit
                CheckGameTimeout()
            }
        }
        ; Deduct 10s from BattleLoadDelay to start faster, minimum 100ms
        actualLoadDelay := (BattleLoadDelay > 10000) ? (BattleLoadDelay - 10000) : 100
        if !SafeSleep(actualLoadDelay)
            break
        sideIdx := Random(1, 4)
        chosenSide := ADBBBSides[sideIdx]
        p1TimerEnd := A_TickCount + 130000 ; 2 minutes 10 seconds timer
        LogMessage("Step 5: Picked Side " sideIdx " for BB deployment.")
        ZoomOutBB()
        DeployBBTroops(chosenSide, 1)
        LogMessage("Step 6: Phase 1 battle running. Clicking Return Home every 15s, checking stars/village every 5s...")
        threeStars := false
        early3Stars := false
        lastReturnHomeClick := A_TickCount - 15000 ; Force click on first pass
        lastCheckTick := 0
        while (A_TickCount < p1TimerEnd) {
            if !IsBBRunning
                goto BBLoopExit
            
            ; 1. Click Return Home location every 15 seconds
            if (A_TickCount - lastReturnHomeClick >= 15000) {
                LogMessage("Clicking Return Home location...")
                ADBClickPoint(ADBReturnHomeClickX, ADBReturnHomeClickY)
                lastReturnHomeClick := A_TickCount
            }
            
            ; 2. Check status every 5 seconds
            if (A_TickCount - lastCheckTick >= 5000) {
                lastCheckTick := A_TickCount
                CaptureADBFrame(true)
                
                if IsAtBuilderBase() {
                    LogMessage("Returned to Builder Base during Phase 1.")
                    break
                }
                if IsGolden(BBStar3X, BBStar3Y) {
                    threeStars := true
                    early3Stars := true
                    LogMessage("Phase 1 cleared! 3 stars detected early!")
                    break
                }
            }
            
            if !SafeSleep(200)
                goto BBLoopExit
        }
        
        ; Fallback: If 2m 10s timer expired while still in battle and not back at village, Phase 2 is ready
        if (!threeStars && !IsAtBuilderBase() && A_TickCount >= p1TimerEnd) {
            threeStars := true
            LogMessage("Phase 1 2m 10s timer expired! Troops walked to Stage 2, starting Phase 2.")
        }

        if threeStars {
            if early3Stars {
                LogMessage("Step 7: Early 3 stars detected! Waiting 6s for stage transition...")
                if !SafeSleep(6000)
                    goto BBLoopExit
            } else {
                LogMessage("Step 7: 2m 10s timer reached! Stage 2 ready, deploying Phase 2 immediately...")
            }
            
            LogMessage("Step 7.5: Phase 2 deployment starting on Side " sideIdx)
            ZoomOutBB()
            DeployBBTroops(chosenSide, 2)
            
            LogMessage("Step 8: Phase 2 battle running. Clicking Return Home every 15s until village...")
            p2StartTime := A_TickCount
            p2LastReturnHomeClick := A_TickCount - 15000 ; Force click on first pass
            p2LastCheckTick := 0
            while ((A_TickCount - p2StartTime) < 180000) { ; 3 minutes max for Phase 2
                if !IsBBRunning
                    goto BBLoopExit
                
                ; 1. Click Return Home location every 15 seconds
                if (A_TickCount - p2LastReturnHomeClick >= 15000) {
                    LogMessage("Clicking Return Home location...")
                    ADBClickPoint(ADBReturnHomeClickX, ADBReturnHomeClickY)
                    p2LastReturnHomeClick := A_TickCount
                }
                
                ; 2. Check village status every 5 seconds
                if (A_TickCount - p2LastCheckTick >= 5000) {
                    p2LastCheckTick := A_TickCount
                    CaptureADBFrame(true)
                    
                    if IsAtBuilderBase() {
                        LogMessage("Returned to Builder Base during Phase 2.")
                        break
                    }
                }
                
                if !SafeSleep(200)
                    goto BBLoopExit
            }
        }
        LogMessage("Step 9: Battle Over. Clicking Return Home.")
        ADBClickPoint(ADBReturnHomeClickX, ADBReturnHomeClickY)
        if !SafeSleep(5000)
            goto BBLoopExit
        LogMessage("Step 10: Waiting to return to Builder Base...")
        if !SafeSleep(2000)
            break
        while !IsAtBuilderBase() {
            if !IsBBRunning
                goto BBLoopExit
            ADBClickPoint(ADBReturnHomeClickX, ADBReturnHomeClickY)
            if !SafeSleep(2000)
                goto BBLoopExit
            ; Unconditionally click where the Star Bonus "Okay" button would be
            WinGetClientPos ,, &cw, &ch, TargetWindowTitle
            if (cw && ch) {
                ADBClickFraction(0.5, 0.77)
                SafeSleep(400)
            }
            ; Dismiss Star Bonus or other post-battle popup screens
            ClearingClick()
            if IsAtBuilderBase()
                break
            CheckGameTimeout()
            if !SafeSleep(Random(12000, 14000))
                goto BBLoopExit
        }
        LogMessage("Returned to Builder Base. Reloading loop...")
        if !SafeSleep(2000)
            break
    }
BBLoopExit:
    LogMessage("--- Builder Base Loop Stopped ---")
    IsBBRunning := false
    StatusText.Value := "Status: Stopped"
    StartBtn.Enabled := true
    PauseBtn.Enabled := false
}
ResetViewport() {
    global IsRunning, IsCalibrating
    display := GetADBDisplaySize()
    LogMessage("Viewport: Sending ADB focus tap inside the Android display...")
    ADBClickFraction(0.8, 0.3)
    Sleep 300
    LogMessage("Viewport: Zooming all the way out...")
    RunADBPinchAt(display.width // 2, display.height // 2)
    Sleep 300
    LogMessage("Viewport: Scrolling to top-left corner...")
    Loop 6 {
        if !IsRunning && !IsCalibrating
            break
        RunADBSwipeAt(
            Round(display.width * 0.25), Round(display.height * 0.25),
            Round(display.width * 0.75), Round(display.height * 0.75),
            RandomADBDuration()
        )
        Sleep 100
    }
    Sleep 300
}
ZoomOutBB() {
    display := GetADBDisplaySize()
    LogMessage("Viewport: Zooming all the way out for Builder Base...")
    RunADBPinchAt(display.width // 2, display.height // 2)
    Sleep 300
}
ShowToolTip(message) {
    ToolTip message
    SetTimer () => ToolTip(), -3000
}
ShiftPointTowardsCenter(x, y, shiftDist := 250) {
    display := GetADBDisplaySize()
    cx := display.width // 2
    cy := display.height // 2
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
    global CalibStep, IsCalibrating, CollectorCoords, ADBCollectorCoords, IsWaitingForReset
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
    global NextMatchBtnX, NextMatchBtnY
    global UpgradeMoreBtnX, UpgradeMoreBtnY, AddWall1X, AddWall1Y, RemoveWallX, RemoveWallY, GoldUpgradeX, GoldUpgradeY, ElixirUpgradeX, ElixirUpgradeY
    global Side1StartX, Side1StartY, Side1EndX, Side1EndY
    global Side2StartX, Side2StartY, Side2EndX, Side2EndY
    global Side3StartX, Side3StartY, Side3EndX, Side3EndY
    global Side4StartX, Side4StartY, Side4EndX, Side4EndY
    global Sides
    global ADBDarkElixirBarThreshX, ADBDarkElixirBarThreshY, ADBElixirBarThreshX, ADBElixirBarThreshY, ADBGoldBarThreshX, ADBGoldBarThreshY
    global ADBBuilderFaceX, ADBBuilderFaceY, ADBBuilderMenuBottomX, ADBBuilderMenuBottomY, ADBLabFaceX, ADBLabFaceY, ADBUpgradeMoreBtnX, ADBUpgradeMoreBtnY
    global ADBAddWall1X, ADBAddWall1Y, ADBRemoveWallX, ADBRemoveWallY, ADBGoldUpgradeX, ADBGoldUpgradeY, ADBElixirUpgradeX, ADBElixirUpgradeY
    global ADBUpgradeConfirmX, ADBUpgradeConfirmY, ADBWarLogoX, ADBWarLogoY, ADBAttackBtnX, ADBAttackBtnY
    global ADBFindMatchBtnX, ADBFindMatchBtnY, ADBAttackStartBtnX, ADBAttackStartBtnY, ADBGoldAreaX, ADBGoldAreaY, ADBElixirAreaX, ADBElixirAreaY
    global ADBNextMatchBtnX, ADBNextMatchBtnY, ADBReturnHomeClickX, ADBReturnHomeClickY
    global ADBSide1StartX, ADBSide1StartY, ADBSide1EndX, ADBSide1EndY, ADBSide2StartX, ADBSide2StartY, ADBSide2EndX, ADBSide2EndY
    global ADBSide3StartX, ADBSide3StartY, ADBSide3EndX, ADBSide3EndY, ADBSide4StartX, ADBSide4StartY, ADBSide4EndX, ADBSide4EndY
    if IsWaitingForReset
        return
    CoordMode "Mouse", "Client"
    if !WinExist(TargetWindowTitle) {
        LogMessage("Calibration Error: Target window not found.")
        return
    }
    WinActivate(TargetWindowTitle)
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
        LogMessage(Format("Calibrated Android viewport: ({}, {})-({}, {}) within client {}x{}.",
            ADBViewportLeft, ADBViewportTop, ADBViewportRight, ADBViewportBottom, clientWidth, clientHeight))
        CalibStep := 3
        UpdateCalibrationUI()
        return
    }
    ; Store true Android-display coordinates, never desktop screen coordinates.
    adbPoint := ClientToADBPoint(mx, my)
    msx := adbPoint.x
    msy := adbPoint.y
    switch CalibStep {
        case 3:
            DarkElixirBarThreshX := mx
            DarkElixirBarThreshY := my
            ADBDarkElixirBarThreshX := msx
            ADBDarkElixirBarThreshY := msy
            LogMessage(Format("Calibrated Dark Elixir Bar Thresh: {}, {}", mx, my))
            CalibStep := 4
            UpdateCalibrationUI()
        case 4:
            ElixirBarThreshX := mx
            ElixirBarThreshY := my
            ADBElixirBarThreshX := msx
            ADBElixirBarThreshY := msy
            LogMessage(Format("Calibrated Elixir Bar Thresh: {}, {}", mx, my))
            CalibStep := 5
            UpdateCalibrationUI()
        case 5:
            GoldBarThreshX := mx
            GoldBarThreshY := my
            ADBGoldBarThreshX := msx
            ADBGoldBarThreshY := msy
            LogMessage(Format("Calibrated Gold Bar Thresh: {}, {}", mx, my))
            CalibStep := 6
            UpdateCalibrationUI()
        case 6:
            BuilderFaceX := mx
            BuilderFaceY := my
            ADBBuilderFaceX := msx
            ADBBuilderFaceY := msy
            LogMessage(Format("Calibrated Builder Face: {}, {}", mx, my))
            CalibStep := 7
            UpdateCalibrationUI()
        case 7:
            BuilderMenuBottomX := mx
            BuilderMenuBottomY := my
            ADBBuilderMenuBottomX := msx
            ADBBuilderMenuBottomY := msy
            LogMessage(Format("Calibrated Builder Menu Bottom: {}, {}", mx, my))
            CalibStep := 8
            UpdateCalibrationUI()
        case 8:
            LabFaceX := mx
            LabFaceY := my
            ADBLabFaceX := msx
            ADBLabFaceY := msy
            LogMessage(Format("Calibrated Lab Face: {}, {}", mx, my))
            CalibStep := 9
            UpdateCalibrationUI()
        case 9:
            UpgradeMoreBtnX := mx
            UpgradeMoreBtnY := my
            ADBUpgradeMoreBtnX := msx
            ADBUpgradeMoreBtnY := msy
            LogMessage(Format("Calibrated Upgrade More Btn: {}, {}", mx, my))
            CalibStep := 10
            UpdateCalibrationUI()
        case 10:
            AddWall1X := mx
            AddWall1Y := my
            ADBAddWall1X := msx
            ADBAddWall1Y := msy
            LogMessage(Format("Calibrated Add Wall1: {}, {}", mx, my))
            CalibStep := 11
            UpdateCalibrationUI()
        case 11:
            RemoveWallX := mx
            RemoveWallY := my
            ADBRemoveWallX := msx
            ADBRemoveWallY := msy
            LogMessage(Format("Calibrated Remove Wall1: {}, {}", mx, my))
            CalibStep := 12
            UpdateCalibrationUI()
        case 12:
            GoldUpgradeX := mx
            GoldUpgradeY := my
            ADBGoldUpgradeX := msx
            ADBGoldUpgradeY := msy
            LogMessage(Format("Calibrated Gold Upgrade: {}, {}", mx, my))
            CalibStep := 13
            UpdateCalibrationUI()
        case 13:
            ElixirUpgradeX := mx
            ElixirUpgradeY := my
            ADBElixirUpgradeX := msx
            ADBElixirUpgradeY := msy
            LogMessage(Format("Calibrated Elixir Upgrade: {}, {}", mx, my))
            CalibStep := 14
            UpdateCalibrationUI()
        case 14:
            UpgradeConfirmX := mx
            UpgradeConfirmY := my
            ADBUpgradeConfirmX := msx
            ADBUpgradeConfirmY := msy
            LogMessage(Format("Calibrated Upgrade Confirm: {}, {}", mx, my))
            CalibStep := 15
            UpdateCalibrationUI()
        case 15:
            WarLogoX := mx
            WarLogoY := my
            ADBWarLogoX := msx
            ADBWarLogoY := msy
            WarLogoColor := PixelGetColor(mx, my)
            LogMessage(Format("Calibrated War Logo: {}, {} (Color: {})", mx, my, WarLogoColor))
            CalibStep := 16
            UpdateCalibrationUI()
        case 16:
            AttackBtnX := mx
            AttackBtnY := my
            ADBAttackBtnX := msx
            ADBAttackBtnY := msy
            LogMessage(Format("Calibrated Attack Btn: {}, {}", mx, my))
            CalibStep := 17
            UpdateCalibrationUI()
        case 17:
            FindMatchBtnX := mx
            FindMatchBtnY := my
            ADBFindMatchBtnX := msx
            ADBFindMatchBtnY := msy
            LogMessage(Format("Calibrated Find Match Btn: {}, {}", mx, my))
            CalibStep := 18
            UpdateCalibrationUI()
        case 18:
            AttackStartBtnX := mx
            AttackStartBtnY := my
            ADBAttackStartBtnX := msx
            ADBAttackStartBtnY := msy
            LogMessage(Format("Calibrated Attack Start Btn: {}, {}", mx, my))
            CalibStep := 19
            UpdateCalibrationUI()
        case 19:
            GoldAreaX := mx - 120
            GoldAreaY := my - 15
            adbArea := ClientToADBPoint(GoldAreaX, GoldAreaY)
            ADBGoldAreaX := adbArea.x
            ADBGoldAreaY := adbArea.y
            GoldAreaW := 220
            GoldAreaH := 30
            LogMessage(Format("Calibrated Gold Area: {}, {}", mx, my))
            CalibStep := 20
            UpdateCalibrationUI()
        case 20:
            ElixirAreaX := mx - 120
            ElixirAreaY := my - 15
            adbArea := ClientToADBPoint(ElixirAreaX, ElixirAreaY)
            ADBElixirAreaX := adbArea.x
            ADBElixirAreaY := adbArea.y
            ElixirAreaW := 220
            ElixirAreaH := 30
            LogMessage(Format("Calibrated Elixir Area: {}, {}", mx, my))
            CalibStep := 21
            UpdateCalibrationUI()
        case 21:
            NextMatchBtnX := mx
            NextMatchBtnY := my
            ADBNextMatchBtnX := msx
            ADBNextMatchBtnY := msy
            LogMessage(Format("Calibrated Next Match Btn: {}, {}", mx, my))
            CalibStep := 22
            UpdateCalibrationUI()
        case 22:
            Side1StartX := mx
            Side1StartY := my
            ADBSide1StartX := msx
            ADBSide1StartY := msy
            LogMessage(Format("Calibrated Side1 Start: {}, {}", mx, my))
            CalibStep := 23
            UpdateCalibrationUI()
        case 23:
            Side1EndX := mx
            Side1EndY := my
            ADBSide1EndX := msx
            ADBSide1EndY := msy
            LogMessage(Format("Calibrated Side1 End: {}, {}", mx, my))
            CalibStep := 24
            UpdateCalibrationUI()
        case 24:
            Side2StartX := mx
            Side2StartY := my
            ADBSide2StartX := msx
            ADBSide2StartY := msy
            LogMessage(Format("Calibrated Side2 Start: {}, {}", mx, my))
            CalibStep := 25
            UpdateCalibrationUI()
        case 25:
            Side2EndX := mx
            Side2EndY := my
            ADBSide2EndX := msx
            ADBSide2EndY := msy
            LogMessage(Format("Calibrated Side2 End: {}, {}", mx, my))
            CalibStep := 26
            UpdateCalibrationUI()
        case 26:
            Side3StartX := mx
            Side3StartY := my
            ADBSide3StartX := msx
            ADBSide3StartY := msy
            LogMessage(Format("Calibrated Side3 Start: {}, {}", mx, my))
            CalibStep := 27
            UpdateCalibrationUI()
        case 27:
            Side3EndX := mx
            Side3EndY := my
            ADBSide3EndX := msx
            ADBSide3EndY := msy
            LogMessage(Format("Calibrated Side3 End: {}, {}", mx, my))
            CalibStep := 28
            UpdateCalibrationUI()
        case 28:
            Side4StartX := mx
            Side4StartY := my
            ADBSide4StartX := msx
            ADBSide4StartY := msy
            LogMessage(Format("Calibrated Side4 Start: {}, {}", mx, my))
            CalibStep := 29
            UpdateCalibrationUI()
        case 29:
            Side4EndX := mx
            Side4EndY := my
            ADBSide4EndX := msx
            ADBSide4EndY := msy
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
            ADBReturnHomeClickX := msx
            ADBReturnHomeClickY := msy
            ReturnHomeClickColor := PixelGetColor(mx, my)
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
            ADBCollectorCoords := []
            CalibStep := 31
            UpdateCalibrationUI()
        case 31:
            CollectorCoords.Push({x: mx, y: my})
            ADBCollectorCoords.Push({x: msx, y: msy})
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
    global ADBBBAttackBtnX, ADBBBAttackBtnY, ADBBBFindMatchBtnX, ADBBBFindMatchBtnY
    global ADBBBStar1X, ADBBBStar1Y, ADBBBStar2X, ADBBBStar2Y, ADBBBStar3X, ADBBBStar3Y
    global ADBBBSide1StartX, ADBBBSide1StartY, ADBBBSide1EndX, ADBBBSide1EndY
    global ADBBBSide2StartX, ADBBBSide2StartY, ADBBBSide2EndX, ADBBBSide2EndY
    global ADBBBSide3StartX, ADBBBSide3StartY, ADBBBSide3EndX, ADBBBSide3EndY
    global ADBBBSide4StartX, ADBBBSide4StartY, ADBBBSide4EndX, ADBBBSide4EndY
    CoordMode "Mouse", "Client"
    if !WinExist(TargetWindowTitle) {
        LogMessage("Calibration Error: Target window not found.")
        return
    }
    WinActivate(TargetWindowTitle)
    MouseGetPos &mx, &my
    ; Store true Android-display coordinates, never desktop screen coordinates.
    adbPoint := ClientToADBPoint(mx, my)
    msx := adbPoint.x
    msy := adbPoint.y
    switch BBCalibStep {
        case 1:
            BBAttackBtnX := mx
            BBAttackBtnY := my
            ADBBBAttackBtnX := msx
            ADBBBAttackBtnY := msy
            LogMessage(Format("Calibrated BB Attack Button: {}, {}", mx, my))
            BBCalibStep := 2
            UpdateBBCalibrationUI()
        case 2:
            BBFindMatchBtnX := mx
            BBFindMatchBtnY := my
            ADBBBFindMatchBtnX := msx
            ADBBBFindMatchBtnY := msy
            LogMessage(Format("Calibrated BB Find Match Button: {}, {}", mx, my))
            BBCalibStep := 3
            UpdateBBCalibrationUI()
        case 3:
            BBStar1X := mx
            BBStar1Y := my
            ADBBBStar1X := msx
            ADBBBStar1Y := msy
            BBStarColor := PixelGetColor(mx, my)
            LogMessage(Format("Calibrated Star 1: {}, {} (Color: {})", mx, my, BBStarColor))
            BBCalibStep := 4
            UpdateBBCalibrationUI()
        case 4:
            BBStar2X := mx
            BBStar2Y := my
            ADBBBStar2X := msx
            ADBBBStar2Y := msy
            LogMessage(Format("Calibrated Star 2: {}, {}", mx, my))
            BBCalibStep := 5
            UpdateBBCalibrationUI()
        case 5:
            BBStar3X := mx
            BBStar3Y := my
            ADBBBStar3X := msx
            ADBBBStar3Y := msy
            LogMessage(Format("Calibrated Star 3: {}, {}", mx, my))
            ; Automatically zoom out for Builder Base sides calibration
            ZoomOutBB()
            BBCalibStep := 6
            UpdateBBCalibrationUI()
        case 6:
            BBSide1StartX := mx
            BBSide1StartY := my
            ADBBBSide1StartX := msx
            ADBBBSide1StartY := msy
            LogMessage(Format("Calibrated BB Side 1 Start: {}, {}", mx, my))
            BBCalibStep := 7
            UpdateBBCalibrationUI()
        case 7:
            BBSide1EndX := mx
            BBSide1EndY := my
            ADBBBSide1EndX := msx
            ADBBBSide1EndY := msy
            LogMessage(Format("Calibrated BB Side 1 End: {}, {}", mx, my))
            BBCalibStep := 8
            UpdateBBCalibrationUI()
        case 8:
            BBSide2StartX := mx
            BBSide2StartY := my
            ADBBBSide2StartX := msx
            ADBBBSide2StartY := msy
            LogMessage(Format("Calibrated BB Side 2 Start: {}, {}", mx, my))
            BBCalibStep := 9
            UpdateBBCalibrationUI()
        case 9:
            BBSide2EndX := mx
            BBSide2EndY := my
            ADBBBSide2EndX := msx
            ADBBBSide2EndY := msy
            LogMessage(Format("Calibrated BB Side 2 End: {}, {}", mx, my))
            BBCalibStep := 10
            UpdateBBCalibrationUI()
        case 10:
            BBSide3StartX := mx
            BBSide3StartY := my
            ADBBBSide3StartX := msx
            ADBBBSide3StartY := msy
            LogMessage(Format("Calibrated BB Side 3 Start: {}, {}", mx, my))
            BBCalibStep := 11
            UpdateBBCalibrationUI()
        case 11:
            BBSide3EndX := mx
            BBSide3EndY := my
            ADBBBSide3EndX := msx
            ADBBBSide3EndY := msy
            LogMessage(Format("Calibrated BB Side 3 End: {}, {}", mx, my))
            BBCalibStep := 12
            UpdateBBCalibrationUI()
        case 12:
            BBSide4StartX := mx
            BBSide4StartY := my
            ADBBBSide4StartX := msx
            ADBBBSide4StartY := msy
            LogMessage(Format("Calibrated BB Side 4 Start: {}, {}", mx, my))
            BBCalibStep := 13
            UpdateBBCalibrationUI()
        case 13:
            BBSide4EndX := mx
            BBSide4EndY := my
            ADBBBSide4EndX := msx
            ADBBBSide4EndY := msy
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
Esc:: {
    ShowToolTip("Exiting Clash of Clans Bot...")
    Sleep 1000
    ExitApp
}
; Checkpoint: Functional Bot 2.0
#HotIf
