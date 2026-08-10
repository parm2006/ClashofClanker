#Requires AutoHotkey v2.0
#SingleInstance Force
#Include OCR.ahk
#Include loot_ocr_logic.ahk
#Include ADBcocbotrefactor_support.ahk

; Manual loot-OCR comparison harness. It never makes an attack decision.
; Each cycle captures exactly one ADB frame, evaluates Gold and Elixir from that
; same frame, then (while running) taps Next Match for the next manual sample.

global ComparisonRunning := false
global ComparisonStopping := false
global ComparisonCycle := 0
global ComparisonFramePath := A_Temp "\coc_loot_ocr_comparison_frame.png"
global ComparisonGoldCropPath := A_Temp "\coc_loot_ocr_comparison_gold.png"
global ComparisonElixirCropPath := A_Temp "\coc_loot_ocr_comparison_elixir.png"
global ComparisonMappingIdentity := ""
global ComparisonDisplayWidth := 0, ComparisonDisplayHeight := 0

global ComparisonSerial := ""
global ComparisonViewportLeft := 0, ComparisonViewportTop := 0
global ComparisonViewportRight := -1, ComparisonViewportBottom := -1
global ComparisonClientWidth := 0, ComparisonClientHeight := 0
global ComparisonProvider := ""
global ComparisonGoldIconX := 45, ComparisonGoldIconY := 145
global ComparisonElixirIconX := 45, ComparisonElixirIconY := 195
global ComparisonLootOffsetX := 10, ComparisonLootOffsetY := -27
global ComparisonLootWidth := 161, ComparisonLootHeight := 59
global ComparisonNextMatchX := 1630, ComparisonNextMatchY := 850

LoadComparisonConfig()

ComparisonGui := Gui("+Resize", "Clash of Clans - Loot OCR Comparator")
ComparisonGui.SetFont("s10", "Segoe UI")
ComparisonGui.Add("Text", "x15 y14 w690 h40", "Open a search result manually, then press F1. Each cycle uses one fresh frame for Gold and Elixir, compares Normal / Grey / Contrast at 1.5x, 2.0x, 2.5x, and 3.0x, then taps Next.")
ComparisonStatus := ComparisonGui.Add("Text", "x15 y60 w690 h25 cBlue", "Status: Ready - F1 starts; F2 pauses after the current comparison.")
BtnStart := ComparisonGui.Add("Button", "x15 y92 w135 h34", "Start (F1)")
BtnPause := ComparisonGui.Add("Button", "x160 y92 w135 h34", "Pause (F2)")
BtnClear := ComparisonGui.Add("Button", "x305 y92 w135 h34", "Clear Console")
ComparisonGui.Add("GroupBox", "x15 y140 w335 h150", "Gold crop from the current single frame")
ComparisonGoldPicture := ComparisonGui.Add("Picture", "x25 y165 w315 h110 +Border", "")
ComparisonGui.Add("GroupBox", "x370 y140 w335 h150", "Elixir crop from the current single frame")
ComparisonElixirPicture := ComparisonGui.Add("Picture", "x380 y165 w315 h110 +Border", "")
ComparisonGui.Add("Text", "x15 y302 w690 h22", "Unified value is the rounded 1,000-value consensus across the four scales. The per-scale readings remain visible for comparison.")
ComparisonConsole := ComparisonGui.Add("Edit", "x15 y330 w690 h300 ReadOnly +VScroll +HScroll", "")
BtnStart.OnEvent("Click", (*) => StartLootComparison())
BtnPause.OnEvent("Click", (*) => StopLootComparison())
BtnClear.OnEvent("Click", (*) => ClearComparisonConsole())
ComparisonGui.OnEvent("Close", HandleComparisonClose)
ComparisonGui.Show("w720 h650")
ComparisonLog("Ready. This tool only captures, compares, logs, and taps Next Match.")
ComparisonLog("High contrast = grayscale, then luminance threshold 160: below 160 is black; 160 or above is white.")
return

F1::StartLootComparison()
F2::StopLootComparison()

StartLootComparison() {
    global ComparisonRunning, ComparisonStopping, ComparisonStatus
    if ComparisonRunning {
        ComparisonLog("Already running.")
        return
    }
    try {
        LoadComparisonConfig()
        EnsureComparisonADBMapping()
    } catch as err {
        ComparisonStatus.Text := "Status: Setup error"
        ComparisonStatus.Opt("cRed")
        ComparisonLog("Setup error: " err.Message)
        return
    }

    ComparisonRunning := true
    ComparisonStopping := false
    ComparisonStatus.Text := "Status: Running - comparing current base."
    ComparisonStatus.Opt("cGreen")
    while ComparisonRunning {
        try {
            RunComparisonCycle()
        } catch as err {
            ComparisonLog("Cycle error: " err.Message)
            ComparisonRunning := false
            break
        }
        if !ComparisonRunning
            break
        ComparisonStatus.Text := "Status: Waiting 5 seconds before Next Match."
        Sleep(5000)
        if !ComparisonRunning
            break
        ComparisonStatus.Text := "Status: Tapping Next Match; waiting 4 seconds."
        TapComparisonNextMatch()
        Sleep(4000)
    }
    ComparisonStopping := false
    ComparisonStatus.Text := "Status: Paused - no Next Match tap was sent after the latest comparison."
    ComparisonStatus.Opt("cBlue")
}

StopLootComparison() {
    global ComparisonRunning, ComparisonStopping, ComparisonStatus
    if !ComparisonRunning {
        ComparisonStatus.Text := "Status: Already paused."
        ComparisonStatus.Opt("cBlue")
        return
    }
    ComparisonStopping := true
    ComparisonRunning := false
    ComparisonStatus.Text := "Status: Finishing current comparison; Next Match will not be tapped."
    ComparisonStatus.Opt("cFFA500")
    ComparisonLog("Pause requested: finishing Normal, Grey, and Contrast for the current base.")
}

RunComparisonCycle() {
    global ComparisonCycle, ComparisonRunning, ComparisonStopping
    global ComparisonStatus, ComparisonGoldPicture, ComparisonElixirPicture
    global ComparisonGoldIconX, ComparisonGoldIconY, ComparisonElixirIconX, ComparisonElixirIconY
    global ComparisonLootOffsetX, ComparisonLootOffsetY, ComparisonLootWidth, ComparisonLootHeight
    global ComparisonGoldCropPath, ComparisonElixirCropPath

    ComparisonCycle += 1
    ComparisonStatus.Text := "Status: Capturing one fresh frame for comparison #" ComparisonCycle "."
    ComparisonStatus.Opt("cGreen")
    ComparisonLog("=== Comparison #" ComparisonCycle " | one fresh frame ===")
    framePath := CaptureComparisonADBFrame()
    SaveComparisonCrop(
        framePath,
        ComparisonGoldIconX + ComparisonLootOffsetX,
        ComparisonGoldIconY + ComparisonLootOffsetY,
        ComparisonLootWidth,
        ComparisonLootHeight,
        ComparisonGoldCropPath
    )
    SaveComparisonCrop(
        framePath,
        ComparisonElixirIconX + ComparisonLootOffsetX,
        ComparisonElixirIconY + ComparisonLootOffsetY,
        ComparisonLootWidth,
        ComparisonLootHeight,
        ComparisonElixirCropPath
    )
    ComparisonGoldPicture.Value := ComparisonGoldCropPath
    ComparisonElixirPicture.Value := ComparisonElixirCropPath

    ; Do not stop midway: F2 deliberately lets all three image variants finish.
    normalGold := ReadLootWithComparisonMethod(ComparisonGoldCropPath, "Normal")
    normalElixir := ReadLootWithComparisonMethod(ComparisonElixirCropPath, "Normal")
    greyGold := ReadLootWithComparisonMethod(ComparisonGoldCropPath, "Grey")
    greyElixir := ReadLootWithComparisonMethod(ComparisonElixirCropPath, "Grey")
    contrastGold := ReadLootWithComparisonMethod(ComparisonGoldCropPath, "Contrast")
    contrastElixir := ReadLootWithComparisonMethod(ComparisonElixirCropPath, "Contrast")

    ComparisonLog("Normal: G=" normalGold.summary ", E=" normalElixir.summary)
    ComparisonLog("Grey: G=" greyGold.summary ", E=" greyElixir.summary)
    ComparisonLog("Contrast: G=" contrastGold.summary ", E=" contrastElixir.summary)
    ComparisonLog("Comparison #" ComparisonCycle " complete.")

    if ComparisonStopping
        ComparisonLog("Paused after comparison #" ComparisonCycle ".")
}

ReadLootWithComparisonMethod(imagePath, methodName) {
    readings := []
    perScale := []
    for scaleValue in [1.5, 2.0, 2.5, 3.0] {
        options := {scale: scaleValue}
        if (methodName = "Grey")
            options.grayscale := true
        else if (methodName = "Contrast")
            options := {scale: scaleValue, grayscale: true, monochrome: 160}
        cleaned := 0
        try {
            ocrResult := OCR.FromFile(imagePath, options)
            cleaned := CleanComparisonNumber(ocrResult.Text)
        } catch as err {
            cleaned := 0
        }
        if (cleaned > 0)
            readings.Push(cleaned)
        perScale.Push(Format("{:.1f}={}", scaleValue, cleaned > 0 ? cleaned : "-"))
    }
    unified := SelectLootConsensus(readings)
    unifiedText := unified.valid ? unified.value : "INVALID"
    return {
        summary: "U=" unifiedText " [" JoinComparison(perScale, "; ") "]",
        result: unified
    }
}

CleanComparisonNumber(text) {
    text := StrReplace(text, " ", "")
    text := StrReplace(text, ",", "")
    text := StrReplace(text, ".", "")
    for replacement in [
        ["i", "1"], ["I", "1"], ["l", "1"], ["|", "1"], ["!", "1"],
        ["o", "0"], ["O", "0"], ["s", "5"], ["S", "5"], ["g", "9"],
        ["G", "9"], ["q", "9"], ["b", "6"], ["B", "8"], ["z", "2"],
        ["Z", "2"], ["a", "4"], ["A", "4"]
    ]
        text := StrReplace(text, replacement[1], replacement[2])
    digits := ""
    Loop Parse, text {
        if (A_LoopField >= "0" && A_LoopField <= "9")
            digits .= A_LoopField
    }
    return digits = "" ? 0 : Integer(digits)
}

JoinComparison(items, delimiter) {
    joined := ""
    for index, item in items
        joined .= (index > 1 ? delimiter : "") item
    return joined
}

LoadComparisonConfig() {
    global ComparisonSerial, ComparisonViewportLeft, ComparisonViewportTop
    global ComparisonViewportRight, ComparisonViewportBottom, ComparisonClientWidth, ComparisonClientHeight
    global ComparisonProvider, ComparisonGoldIconX, ComparisonGoldIconY
    global ComparisonElixirIconX, ComparisonElixirIconY, ComparisonLootOffsetX, ComparisonLootOffsetY
    global ComparisonLootWidth, ComparisonLootHeight, ComparisonNextMatchX, ComparisonNextMatchY
    configPath := A_ScriptDir "\config.ini"
    ComparisonSerial := IniRead(configPath, "ADBViewport", "Serial", "")
    ComparisonViewportLeft := ReadComparisonIniInt(configPath, "ADBViewport", "Left", 0)
    ComparisonViewportTop := ReadComparisonIniInt(configPath, "ADBViewport", "Top", 0)
    ComparisonViewportRight := ReadComparisonIniInt(configPath, "ADBViewport", "Right", -1)
    ComparisonViewportBottom := ReadComparisonIniInt(configPath, "ADBViewport", "Bottom", -1)
    ComparisonClientWidth := ReadComparisonIniInt(configPath, "ADBViewport", "ClientWidth", 0)
    ComparisonClientHeight := ReadComparisonIniInt(configPath, "ADBViewport", "ClientHeight", 0)
    ComparisonProvider := IniRead(configPath, "ADBViewport", "Provider", "")
    ComparisonGoldIconX := ReadComparisonIniInt(configPath, "Coordinates", "GoldIconX", 45)
    ComparisonGoldIconY := ReadComparisonIniInt(configPath, "Coordinates", "GoldIconY", 145)
    ComparisonElixirIconX := ReadComparisonIniInt(configPath, "Coordinates", "ElixirIconX", 45)
    ComparisonElixirIconY := ReadComparisonIniInt(configPath, "Coordinates", "ElixirIconY", 195)
    ComparisonLootOffsetX := ReadComparisonIniInt(configPath, "Settings", "LootCropOffsetX", 10)
    ComparisonLootOffsetY := ReadComparisonIniInt(configPath, "Settings", "LootCropOffsetY", -27)
    ComparisonLootWidth := ReadComparisonIniInt(configPath, "Settings", "LootCropW", 161)
    ComparisonLootHeight := ReadComparisonIniInt(configPath, "Settings", "LootCropH", 59)
    ComparisonNextMatchX := ReadComparisonIniInt(configPath, "Coordinates", "NextMatchBtnX", 1630)
    ComparisonNextMatchY := ReadComparisonIniInt(configPath, "Coordinates", "NextMatchBtnY", 850)
}

ReadComparisonIniInt(configPath, section, key, fallback) {
    value := IniRead(configPath, section, key, "")
    if (value = "")
        return fallback
    try return Integer(value)
    catch
        return fallback
}

EnsureComparisonADBMapping() {
    global ComparisonMappingIdentity, ComparisonDisplayWidth, ComparisonDisplayHeight
    global ComparisonSerial, ComparisonViewportLeft, ComparisonViewportTop
    global ComparisonViewportRight, ComparisonViewportBottom, ComparisonClientWidth, ComparisonClientHeight, ComparisonProvider
    if (ComparisonSerial = "")
        throw Error("ADBViewport.Serial is missing from config.ini.")
    if (ComparisonViewportRight <= ComparisonViewportLeft || ComparisonViewportBottom <= ComparisonViewportTop)
        throw Error("ADBViewport bounds in config.ini are invalid.")
    identity := ComparisonSerial "|" ComparisonViewportLeft "|" ComparisonViewportTop "|" ComparisonViewportRight "|" ComparisonViewportBottom
    if (identity = ComparisonMappingIdentity && ComparisonDisplayWidth > 0 && ComparisonDisplayHeight > 0)
        return
    display := QueryComparisonADBDisplaySize(ComparisonSerial)
    ComparisonDisplayWidth := display.width
    ComparisonDisplayHeight := display.height
    ConfigureADBClientMapping(
        ComparisonViewportLeft, ComparisonViewportTop,
        ComparisonViewportRight, ComparisonViewportBottom,
        ComparisonDisplayWidth, ComparisonDisplayHeight,
        ComparisonClientWidth, ComparisonClientHeight,
        ComparisonProvider, ComparisonSerial
    )
    ComparisonMappingIdentity := identity
    ComparisonLog("ADB mapping ready: client " ComparisonClientWidth "x" ComparisonClientHeight ", ADB " ComparisonDisplayWidth "x" ComparisonDisplayHeight ".")
}

QueryComparisonADBDisplaySize(serial) {
    state := RunComparisonADBOutput('-s "' serial '" get-state')
    if !state.ok {
        connect := RunComparisonADBOutput('connect "' serial '"')
        if !connect.ok
            throw Error("ADB connection failed.")
    }
    sizeResult := RunComparisonADBOutput('-s "' serial '" shell wm size')
    if !sizeResult.ok
        throw Error("Could not query ADB display size.")
    if RegExMatch(sizeResult.output, "i)Override size:\s*(\d+)x(\d+)", &match)
        return {width: Number(match[1]), height: Number(match[2])}
    if RegExMatch(sizeResult.output, "i)Physical size:\s*(\d+)x(\d+)", &match)
        return {width: Number(match[1]), height: Number(match[2])}
    throw Error("ADB returned an unrecognized display size.")
}

ResolveComparisonADBPath() {
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

RunComparisonADBOutput(arguments) {
    adbPath := ResolveComparisonADBPath()
    outputPath := A_Temp "\coc_loot_ocr_comparison_adb_output.txt"
    try FileDelete(outputPath)
    command := A_ComSpec ' /D /S /C ""' adbPath '" ' arguments ' > "' outputPath '" 2>&1"'
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    output := FileExist(outputPath) ? Trim(FileRead(outputPath), " `t`r`n") : ""
    try FileDelete(outputPath)
    return {ok: exitCode = 0, output: output}
}

CaptureComparisonADBFrame() {
    global ComparisonSerial, ComparisonFramePath
    adbPath := ResolveComparisonADBPath()
    try FileDelete(ComparisonFramePath)
    command := A_ComSpec ' /D /S /C ""' adbPath '" -s "' ComparisonSerial '" exec-out screencap -p > "' ComparisonFramePath '""'
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    if (exitCode != 0 || !FileExist(ComparisonFramePath) || FileGetSize(ComparisonFramePath) < 1024)
        throw Error("Fresh ADB screenshot failed.")
    return ComparisonFramePath
}

TapComparisonNextMatch() {
    global ComparisonSerial, ComparisonNextMatchX, ComparisonNextMatchY
    adbPoint := TranslateClientPointToADB(ComparisonNextMatchX, ComparisonNextMatchY)
    result := RunComparisonADBOutput(BuildADBTapArguments(ComparisonSerial, adbPoint.x, adbPoint.y))
    if !result.ok
        throw Error("Next Match tap failed.")
    ComparisonLog("Next Match tapped.")
}

InitComparisonGDIPlus() {
    static token := 0
    if (token = 0) {
        startupInput := Buffer(24, 0)
        NumPut("uint", 1, startupInput, 0)
        DllCall("gdiplus\GdiplusStartup", "ptr*", &token, "ptr", startupInput, "ptr", 0)
    }
    return token
}

SaveComparisonCrop(framePath, clientX, clientY, clientW, clientH, destinationPath) {
    adbRect := TranslateClientRectToADB(clientX, clientY, clientW, clientH)
    InitComparisonGDIPlus()
    source := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", framePath, "ptr*", &source) != 0
        throw Error("ADB frame could not be opened for cropping.")
    cropped := 0
    status := DllCall(
        "gdiplus\GdipCloneBitmapArea",
        "float", Float(adbRect.x), "float", Float(adbRect.y),
        "float", Float(adbRect.width), "float", Float(adbRect.height),
        "int", 0x26200A, "ptr", source, "ptr*", &cropped
    )
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
        throw Error("Loot crop could not be saved.")
}

ClearComparisonConsole() {
    global ComparisonConsole
    ComparisonConsole.Value := ""
}

ComparisonLog(message) {
    global ComparisonConsole
    ComparisonConsole.Value := ComparisonConsole.Value message "`r`n"
    SendMessage(0x0115, 7, 0, ComparisonConsole.Hwnd)
}

HandleComparisonClose(*) {
    CleanupComparisonFiles()
    ExitApp()
}

CleanupComparisonFiles() {
    global ComparisonFramePath, ComparisonGoldCropPath, ComparisonElixirCropPath
    for path in [ComparisonFramePath, ComparisonGoldCropPath, ComparisonElixirCropPath, A_Temp "\coc_loot_ocr_comparison_adb_output.txt"]
        try FileDelete(path)
}
