#Requires AutoHotkey v2
#SingleInstance Force
#Include OCR.ahk
#Include ADBcocbotrefactor_support.ahk
#Include loot_ocr_logic.ahk

SetTitleMatchMode 2

; ==============================================================================
; Gold & Elixir Icon-Based OCR Visual Debugger with Live Offset Adjusters
; ==============================================================================

global TargetWindowTitle := "Clash of Clans"
global GoldIconX := 45, GoldIconY := 145
global ElixirIconX := 45, ElixirIconY := 195

global LootCropOffsetX := 20
global LootCropOffsetY := -4
global LootCropW := 240
global LootCropH := 45

global IsAutoScanning := false
global ViewportLeft := 0, ViewportTop := 0
global ViewportRight := -1, ViewportBottom := -1
global CalibratedClientWidth := 0, CalibratedClientHeight := 0
global CalibratedProvider := "", CalibratedSerial := ""
global DisplayWidth := 0, DisplayHeight := 0
global MappingIdentity := ""
global IsCalibrating := false, CalibrationStage := ""
global IsUpdatingControls := false
global GoldPreviewPath := A_Temp "\coc_loot_gold_preview.png"
global ElixirPreviewPath := A_Temp "\coc_loot_elixir_preview.png"
global GoldOCRPath := A_Temp "\coc_loot_gold_ocr.png"
global ElixirOCRPath := A_Temp "\coc_loot_elixir_ocr.png"
global LootADBFramePath := A_Temp "\coc_loot_fresh_adb_frame.png"
global MinGold := 500000, MinElixir := 500000

ReloadConfig(force := false) {
    global TargetWindowTitle, GoldIconX, GoldIconY, ElixirIconX, ElixirIconY
    global LootCropOffsetX, LootCropOffsetY, LootCropW, LootCropH
    global ViewportLeft, ViewportTop, ViewportRight, ViewportBottom
    global CalibratedClientWidth, CalibratedClientHeight
    global CalibratedProvider, CalibratedSerial
    global MinGold, MinElixir
    
    if FileExist("config.ini") {
        iniTarget := Trim(IniRead("config.ini", "Settings", "TargetWindowTitle", ""))
        if (iniTarget != "")
            TargetWindowTitle := iniTarget
            
        if force {
            LootCropOffsetX := Number(IniRead("config.ini", "Settings", "LootCropOffsetX", 35))
            LootCropOffsetY := Number(IniRead("config.ini", "Settings", "LootCropOffsetY", -17))
            LootCropW       := Number(IniRead("config.ini", "Settings", "LootCropW", 220))
            LootCropH       := Number(IniRead("config.ini", "Settings", "LootCropH", 40))
        }
        
        if force {
            GoldIconX   := ReadConfigInteger("Coordinates", "GoldIconX", GoldIconX)
            GoldIconY   := ReadConfigInteger("Coordinates", "GoldIconY", GoldIconY)
            ElixirIconX := ReadConfigInteger("Coordinates", "ElixirIconX", ElixirIconX)
            ElixirIconY := ReadConfigInteger("Coordinates", "ElixirIconY", ElixirIconY)
        }
        ViewportLeft := ReadConfigInteger("ADBViewport", "Left", ViewportLeft)
        ViewportTop := ReadConfigInteger("ADBViewport", "Top", ViewportTop)
        ViewportRight := ReadConfigInteger("ADBViewport", "Right", ViewportRight)
        ViewportBottom := ReadConfigInteger("ADBViewport", "Bottom", ViewportBottom)
        CalibratedClientWidth := ReadConfigInteger(
            "ADBViewport", "ClientWidth", CalibratedClientWidth
        )
        CalibratedClientHeight := ReadConfigInteger(
            "ADBViewport", "ClientHeight", CalibratedClientHeight
        )
        CalibratedProvider := IniRead(
            "config.ini", "ADBViewport", "Provider", CalibratedProvider
        )
        CalibratedSerial := IniRead(
            "config.ini", "ADBViewport", "Serial", CalibratedSerial
        )
        MinGold := ReadConfigInteger("Farming", "MinGold", 500000)
        MinElixir := ReadConfigInteger("Farming", "MinElixir", 500000)
    }
}

ReadConfigInteger(section, key, fallback) {
    value := IniRead("config.ini", section, key, "")
    return (value != "" && IsNumber(value)) ? Number(value) : fallback
}

ReloadConfig(true)

; ------------------------------------------------------------------------------
; GUI Construction
; ------------------------------------------------------------------------------

MyGui := Gui("+Resize", "Clash of Clanker - ADB Loot OCR Inspector")
MyGui.SetFont("s10", "Segoe UI")

; Controls Header
MyGui.Add("Text", "x15 y14 w100 h25", "Target Window:")
EditTarget := MyGui.Add("Edit", "x120 y10 w220 h26 vEditTarget", TargetWindowTitle)
ChkTop := MyGui.Add("Checkbox", "x355 y14 w130 h25 vChkTop", "Always On Top")
StatusText := MyGui.Add("Text", "x500 y14 w200 h25 vStatusText Right cGray", "Status: Idle")

; Adjuster GroupBox
MyGui.Add("GroupBox", "x15 y42 w685 h60", "Live Bounding Box Adjusters (Shared Gold & Elixir Offsets)")
MyGui.Add("Text", "x25 y68 w75 h20", "Offset X:")
EditOffsetX := MyGui.Add("Edit", "x100 y65 w50 h24 Number vEditOffsetX", "" LootCropOffsetX)
MyGui.Add("UpDown", "vSpinOffsetX Range-100-200", LootCropOffsetX)

MyGui.Add("Text", "x165 y68 w75 h20", "Offset Y:")
EditOffsetY := MyGui.Add("Edit", "x240 y65 w50 h24 vEditOffsetY", "" LootCropOffsetY)
MyGui.Add("UpDown", "vSpinOffsetY Range-100-200", LootCropOffsetY)

MyGui.Add("Text", "x305 y68 w75 h20", "Width:")
EditWidth := MyGui.Add("Edit", "x380 y65 w55 h24 Number vEditWidth", "" LootCropW)
MyGui.Add("UpDown", "vSpinWidth Range50-500", LootCropW)

MyGui.Add("Text", "x450 y68 w75 h20", "Height:")
EditHeight := MyGui.Add("Edit", "x525 y65 w55 h24 Number vEditHeight", "" LootCropH)
MyGui.Add("UpDown", "vSpinHeight Range10-200", LootCropH)

BtnSaveOffsets := MyGui.Add("Button", "x595 y63 w95 h28", "Save Config")

; Icon anchor coordinates are always client coordinates.
MyGui.Add("GroupBox", "x15 y108 w685 h68", "Loot Icon Anchors (Client Coordinates)")
MyGui.Add("Text", "x25 y135 w65 h20", "Gold X:")
EditGoldX := MyGui.Add("Edit", "x85 y132 w55 h24 Number vEditGoldX", "" GoldIconX)
MyGui.Add("UpDown", "Range0-4000", GoldIconX)
MyGui.Add("Text", "x150 y135 w65 h20", "Gold Y:")
EditGoldY := MyGui.Add("Edit", "x210 y132 w55 h24 Number vEditGoldY", "" GoldIconY)
MyGui.Add("UpDown", "Range0-4000", GoldIconY)
MyGui.Add("Text", "x285 y135 w70 h20", "Elixir X:")
EditElixirX := MyGui.Add("Edit", "x350 y132 w55 h24 Number vEditElixirX", "" ElixirIconX)
MyGui.Add("UpDown", "Range0-4000", ElixirIconX)
MyGui.Add("Text", "x415 y135 w70 h20", "Elixir Y:")
EditElixirY := MyGui.Add("Edit", "x480 y132 w55 h24 Number vEditElixirY", "" ElixirIconY)
MyGui.Add("UpDown", "Range0-4000", ElixirIconY)
BtnCalibrate := MyGui.Add("Button", "x550 y130 w140 h29", "Calibrate (Space)")

; Action Buttons
BtnScan       := MyGui.Add("Button", "x15 y185 w150 h35", "Scan Once (F1)")
BtnToggleAuto := MyGui.Add("Button", "x175 y185 w160 h35 vBtnToggleAuto", "Start Auto Scan")
BtnClear      := MyGui.Add("Button", "x590 y185 w110 h35", "Clear Console")

; GroupBox: Verdict Header
MyGui.Add("GroupBox", "x15 y230 w685 h70", "Parsed Loot Quantities")
MyGui.SetFont("s16 Bold", "Segoe UI")
VerdictText := MyGui.Add("Text", "x30 y250 w655 h44 vVerdictText cBlue", "Verdict: READY FOR ADB SCAN")
MyGui.SetFont("s10 Norm", "Segoe UI")

; Picture Previews
MyGui.Add("GroupBox", "x15 y308 w335 h130", "Fresh ADB Gold Crop (green=valid, red=invalid)")
PicGold := MyGui.Add("Picture", "x25 y330 w315 h98 +Border vPicGold", "")

MyGui.Add("GroupBox", "x365 y308 w335 h130", "Fresh ADB Elixir Crop (green=valid, red=invalid)")
PicElixir := MyGui.Add("Picture", "x375 y330 w315 h98 +Border vPicElixir", "")

; Console
MyGui.Add("GroupBox", "x15 y448 w685 h340", "OCR Diagnostic Output & Client-to-ADB Coordinates")
MyGui.SetFont("s9", "Consolas")
ConsoleEdit := MyGui.Add("Edit", "x25 y473 w665 h305 ReadOnly +VScroll +HScroll vConsoleEdit", "")
MyGui.SetFont("s10", "Segoe UI")

; Event Handlers
EditTarget.OnEvent("Change", (*) => UpdateTargetTitle(EditTarget.Value))
ChkTop.OnEvent("Click", (*) => MyGui.Opt((ChkTop.Value ? "+" : "-") "AlwaysOnTop"))
BtnScan.OnEvent("Click", (*) => RunLootOCR())
BtnToggleAuto.OnEvent("Click", (*) => ToggleAutoScan())
BtnClear.OnEvent("Click", (*) => ClearConsole())
BtnSaveOffsets.OnEvent("Click", (*) => SaveCurrentOffsets())
BtnCalibrate.OnEvent("Click", (*) => BeginCalibration())

EditOffsetX.OnEvent("Change", (*) => OnOffsetChanged())
EditOffsetY.OnEvent("Change", (*) => OnOffsetChanged())
EditWidth.OnEvent("Change", (*) => OnOffsetChanged())
EditHeight.OnEvent("Change", (*) => OnOffsetChanged())
EditGoldX.OnEvent("Change", (*) => OnAnchorChanged())
EditGoldY.OnEvent("Change", (*) => OnAnchorChanged())
EditElixirX.OnEvent("Change", (*) => OnAnchorChanged())
EditElixirY.OnEvent("Change", (*) => OnAnchorChanged())

MyGui.OnEvent("Close", (*) => ExitApp())
MyGui.Show("w715 h803")

; ------------------------------------------------------------------------------
; Functions
; ------------------------------------------------------------------------------

UpdateTargetTitle(newTitle) {
    global TargetWindowTitle
    TargetWindowTitle := Trim(newTitle)
}

LogToConsole(msg) {
    timeStr := FormatTime(, "HH:mm:ss")
    ConsoleEdit.Value .= "[" timeStr "] " msg "`n"
    SendMessage(0x0115, 7, 0, ConsoleEdit)
}

ClearConsole() {
    ConsoleEdit.Value := ""
}

SaveCurrentOffsets() {
    global LootCropOffsetX, LootCropOffsetY, LootCropW, LootCropH
    global GoldIconX, GoldIconY, ElixirIconX, ElixirIconY
    if FileExist("config.ini") {
        IniWrite("" LootCropOffsetX, "config.ini", "Settings", "LootCropOffsetX")
        IniWrite("" LootCropOffsetY, "config.ini", "Settings", "LootCropOffsetY")
        IniWrite("" LootCropW,       "config.ini", "Settings", "LootCropW")
        IniWrite("" LootCropH,       "config.ini", "Settings", "LootCropH")
        IniWrite("" GoldIconX, "config.ini", "Coordinates", "GoldIconX")
        IniWrite("" GoldIconY, "config.ini", "Coordinates", "GoldIconY")
        IniWrite("" ElixirIconX, "config.ini", "Coordinates", "ElixirIconX")
        IniWrite("" ElixirIconY, "config.ini", "Coordinates", "ElixirIconY")
        LogToConsole(
            Format(
                "Saved config: crop offset ({}, {}), size {}x{}; "
                    "Gold icon ({}, {}); Elixir icon ({}, {}).",
                LootCropOffsetX,
                LootCropOffsetY,
                LootCropW,
                LootCropH,
                GoldIconX,
                GoldIconY,
                ElixirIconX,
                ElixirIconY
            )
        )
    }
}

OnOffsetChanged() {
    global LootCropOffsetX, LootCropOffsetY, LootCropW, LootCropH
    try {
        if (EditOffsetX.Value != "")
            LootCropOffsetX := Number(EditOffsetX.Value)
        if (EditOffsetY.Value != "")
            LootCropOffsetY := Number(EditOffsetY.Value)
        if (EditWidth.Value != "")
            LootCropW := Number(EditWidth.Value)
        if (EditHeight.Value != "")
            LootCropH := Number(EditHeight.Value)
        SetTimer () => RunLootOCR(), -100
    }
}

OnAnchorChanged() {
    global IsUpdatingControls
    global GoldIconX, GoldIconY, ElixirIconX, ElixirIconY
    if IsUpdatingControls
        return
    try {
        if (EditGoldX.Value != "")
            GoldIconX := Number(EditGoldX.Value)
        if (EditGoldY.Value != "")
            GoldIconY := Number(EditGoldY.Value)
        if (EditElixirX.Value != "")
            ElixirIconX := Number(EditElixirX.Value)
        if (EditElixirY.Value != "")
            ElixirIconY := Number(EditElixirY.Value)
        SetTimer () => RunLootOCR(), -100
    }
}

UpdateAnchorControls() {
    global IsUpdatingControls
    global GoldIconX, GoldIconY, ElixirIconX, ElixirIconY
    IsUpdatingControls := true
    EditGoldX.Value := "" GoldIconX
    EditGoldY.Value := "" GoldIconY
    EditElixirX.Value := "" ElixirIconX
    EditElixirY.Value := "" ElixirIconY
    IsUpdatingControls := false
}

BeginCalibration() {
    global IsCalibrating, CalibrationStage
    IsCalibrating := true
    CalibrationStage := "gold"
    BtnCalibrate.Text := "Gold: HOVER + SPACE"
    LogToConsole(
        "Calibration armed: hover over the GOLD icon in the emulator "
            "and press Space."
    )
}

CaptureCalibrationPoint() {
    global IsCalibrating, CalibrationStage, TargetWindowTitle
    global GoldIconX, GoldIconY, ElixirIconX, ElixirIconY
    if !IsCalibrating
        return
    hwnd := WinExist(TargetWindowTitle)
    if !hwnd {
        LogToConsole("Calibration failed: emulator window was not found.")
        return
    }
    WinGetClientPos &clientScreenX, &clientScreenY,,, hwnd
    MouseGetPos &mouseX, &mouseY
    clientX := mouseX - clientScreenX
    clientY := mouseY - clientScreenY
    if (CalibrationStage == "gold") {
        GoldIconX := clientX
        GoldIconY := clientY
        CalibrationStage := "elixir"
        BtnCalibrate.Text := "Elixir: HOVER + SPACE"
        UpdateAnchorControls()
        LogToConsole(
            "Gold anchor captured at client (" clientX ", " clientY "). "
                "Now hover over the ELIXIR icon and press Space."
        )
        return
    }
    ElixirIconX := clientX
    ElixirIconY := clientY
    IsCalibrating := false
    CalibrationStage := ""
    BtnCalibrate.Text := "Calibrate (Space)"
    UpdateAnchorControls()
    LogToConsole(
        "Elixir anchor captured at client (" clientX ", " clientY "). "
            "Calibration complete; use Save Config to persist it."
    )
    RunLootOCR()
}

ToggleAutoScan() {
    global IsAutoScanning, BtnToggleAuto, StatusText
    IsAutoScanning := !IsAutoScanning
    if IsAutoScanning {
        BtnToggleAuto.Text := "Stop Auto Scan"
        StatusText.Value := "Status: Auto Scanning (1s)"
        StatusText.Opt("cGreen")
        SetTimer () => RunLootOCR(), 1000
        RunLootOCR()
    } else {
        BtnToggleAuto.Text := "Start Auto Scan"
        StatusText.Value := "Status: Stopped"
        StatusText.Opt("cGray")
        SetTimer () => RunLootOCR(), 0
    }
}

CleanNumberStr(str) {
    str := StrReplace(str, " ", "")
    str := StrReplace(str, ",", "")
    str := StrReplace(str, ".", "")
    str := StrReplace(str, "i", "1")
    str := StrReplace(str, "I", "1")
    str := StrReplace(str, "l", "1")
    str := StrReplace(str, "|", "1")
    str := StrReplace(str, "!", "1")
    str := StrReplace(str, "o", "0")
    str := StrReplace(str, "O", "0")
    str := StrReplace(str, "s", "5")
    str := StrReplace(str, "S", "5")
    str := StrReplace(str, "g", "9")
    str := StrReplace(str, "G", "9")
    str := StrReplace(str, "q", "9")
    str := StrReplace(str, "b", "6")
    str := StrReplace(str, "B", "8")
    str := StrReplace(str, "z", "2")
    str := StrReplace(str, "Z", "2")
    str := StrReplace(str, "a", "4")
    str := StrReplace(str, "A", "4")
    str := StrReplace(str, "•", "0")
    res := ""
    Loop Parse, str {
        if (A_LoopField >= "0" && A_LoopField <= "9")
            res .= A_LoopField
    }
    return res == "" ? 0 : Number(res)
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

SaveADBRegionToPNG(framePath, adbRect, filepath) {
    InitGDIPlus()
    if (framePath == "" || !FileExist(framePath))
        throw Error("Fresh ADB frame is unavailable.")
    pSourceBitmap := 0
    if DllCall(
        "gdiplus\GdipCreateBitmapFromFile",
        "wstr",
        framePath,
        "ptr*",
        &pSourceBitmap
    ) != 0
        throw Error("Fresh ADB frame could not be opened.")
    pCropBitmap := 0
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
        pSourceBitmap,
        "ptr*",
        &pCropBitmap
    )
    DllCall("gdiplus\GdipDisposeImage", "ptr", pSourceBitmap)
    if (status != 0)
        throw Error("ADB crop failed with GDI+ status " status ".")
    SaveGDIPlusBitmapToPNG(pCropBitmap, filepath)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pCropBitmap)
}

SaveADBRegionWithMarkers(framePath, adbRect, filepath, isPass) {
    InitGDIPlus()
    if (framePath == "" || !FileExist(framePath))
        throw Error("Fresh ADB frame is unavailable.")
    pSourceBitmap := 0
    if DllCall(
        "gdiplus\GdipCreateBitmapFromFile",
        "wstr",
        framePath,
        "ptr*",
        &pSourceBitmap
    ) != 0
        throw Error("Fresh ADB frame could not be opened.")
    pCropBitmap := 0
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
        pSourceBitmap,
        "ptr*",
        &pCropBitmap
    )
    DllCall("gdiplus\GdipDisposeImage", "ptr", pSourceBitmap)
    if (status != 0)
        throw Error("ADB preview crop failed with GDI+ status " status ".")
    pGraphics := 0
    pPen := 0
    DllCall(
        "gdiplus\GdipGetImageGraphicsContext",
        "ptr",
        pCropBitmap,
        "ptr*",
        &pGraphics
    )
    markerColor := isPass ? 0xFF00FF00 : 0xFFFF0000
    DllCall(
        "gdiplus\GdipCreatePen1",
        "uint",
        markerColor,
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
        1.0,
        "float",
        1.0,
        "float",
        Float(Max(1, adbRect.width - 3)),
        "float",
        Float(Max(1, adbRect.height - 3))
    )
    DllCall("gdiplus\GdipDeletePen", "ptr", pPen)
    DllCall("gdiplus\GdipDeleteGraphics", "ptr", pGraphics)
    SaveGDIPlusBitmapToPNG(pCropBitmap, filepath)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pCropBitmap)
}

SaveGDIPlusBitmapToPNG(pBitmap, filepath) {
    clsid := Buffer(16, 0)
    DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid)
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
        throw Error("PNG save failed with GDI+ status " status ".")
}

ScanLootRegion(imagePath, label) {
    scales := [2.0, 2.5, 3.0, 1.5]
    readings := []
    for sc in scales {
        try {
            result := OCR.FromFile(imagePath, {scale: sc, grayscale: true, monochrome: 160})
            cleaned := CleanNumberStr(result.Text)
            rawText := StrReplace(StrReplace(result.Text, "`r", "\r"), "`n", "\n")
            LogToConsole(
                Format(
                    "{} scale {:.1f}x: raw='{}' | cleaned={:d}",
                    label,
                    sc,
                    rawText,
                    cleaned
                )
            )
            if (cleaned > 0)
                readings.Push(cleaned)
        } catch as err {
            errMsg := (HasProp(err, "Message") ? err.Message : Format("{}", err))
            LogToConsole(
                Format("{} scale {:.1f}x ERROR: {}", label, sc, errMsg)
            )
        }
    }
    consensus := SelectLootConsensus(readings)
    LogToConsole(
        Format(
            "{} consensus: valid={}, value={}, reason={}, agreement={}/{}.",
            label,
            consensus.valid ? "YES" : "NO",
            consensus.value,
            consensus.reason,
            consensus.agreement,
            consensus.readingCount
        )
    )
    return consensus
}

EnsureLootADBMapping(clientWidth, clientHeight) {
    global MappingIdentity, DisplayWidth, DisplayHeight
    global ViewportLeft, ViewportTop, ViewportRight, ViewportBottom
    global CalibratedClientWidth, CalibratedClientHeight
    global CalibratedProvider, CalibratedSerial

    if (CalibratedSerial == "")
        throw Error("ADBViewport.Serial is missing from config.ini.")
    if (ViewportRight <= ViewportLeft || ViewportBottom <= ViewportTop)
        throw Error("ADBViewport bounds in config.ini are invalid.")
    if (clientWidth != CalibratedClientWidth
        || clientHeight != CalibratedClientHeight) {
        throw Error(
            "Visible client is " clientWidth "x" clientHeight
                ", but calibration is "
                CalibratedClientWidth "x" CalibratedClientHeight "."
        )
    }
    identity := clientWidth "|" clientHeight "|" CalibratedProvider "|" CalibratedSerial "|" ViewportLeft "|" ViewportTop "|" ViewportRight "|" ViewportBottom
    if (identity == MappingIdentity
        && DisplayWidth > 0
        && DisplayHeight > 0)
        return
    display := QueryLootADBDisplaySize(CalibratedSerial)
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
            "Mapping loaded: visible client {}x{}, viewport "
                "({}, {})-({}, {}), ADB {}x{}, serial {}.",
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

QueryLootADBDisplaySize(serial) {
    state := RunLootInspectorADBOutput('-s "' serial '" get-state')
    if !state.ok {
        connect := RunLootInspectorADBOutput('connect "' serial '"')
        if !connect.ok
            throw Error("ADB connection failed: " connect.output)
    }
    sizeResult := RunLootInspectorADBOutput(
        '-s "' serial '" shell wm size'
    )
    if !sizeResult.ok
        throw Error("Could not query ADB display size: " sizeResult.output)
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

ResolveLootInspectorADBPath() {
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

RunLootInspectorADBOutput(arguments) {
    adbPath := ResolveLootInspectorADBPath()
    outputPath := A_Temp "\coc_loot_inspector_adb_output.txt"
    try FileDelete(outputPath)
    command := A_ComSpec ' /D /S /C ""' adbPath '" ' arguments ' > "' outputPath '" 2>&1"'
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    output := FileExist(outputPath)
        ? Trim(FileRead(outputPath), " `t`r`n")
        : ""
    try FileDelete(outputPath)
    return {ok: exitCode == 0, output: output, exitCode: exitCode}
}

CaptureLootADBFrame() {
    global CalibratedSerial, LootADBFramePath
    if (CalibratedSerial == "")
        throw Error("ADBViewport.Serial is missing from config.ini.")
    adbPath := ResolveLootInspectorADBPath()
    try FileDelete(LootADBFramePath)
    command := A_ComSpec ' /D /S /C ""' adbPath '" -s "' CalibratedSerial '" exec-out screencap -p > "' LootADBFramePath '""'
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    if (exitCode != 0 || !FileExist(LootADBFramePath))
        throw Error("Fresh ADB screenshot failed with exit code " exitCode ".")
    if (FileGetSize(LootADBFramePath) < 1024)
        throw Error("Fresh ADB screenshot is unexpectedly small.")
    return LootADBFramePath
}

RunLootOCR() {
    global TargetWindowTitle, GoldIconX, GoldIconY, ElixirIconX, ElixirIconY
    global LootCropOffsetX, LootCropOffsetY, LootCropW, LootCropH
    global GoldPreviewPath, ElixirPreviewPath, GoldOCRPath, ElixirOCRPath
    global CalibratedClientWidth, CalibratedClientHeight
    global MinGold, MinElixir
    
    ReloadConfig()
    goldClientX := GoldIconX + LootCropOffsetX
    goldClientY := GoldIconY + LootCropOffsetY
    elixirClientX := ElixirIconX + LootCropOffsetX
    elixirClientY := ElixirIconY + LootCropOffsetY

    try {
        EnsureLootADBMapping(
            CalibratedClientWidth,
            CalibratedClientHeight
        )
        goldADB := TranslateClientRectToADB(
            goldClientX, goldClientY, LootCropW, LootCropH
        )
        elixirADB := TranslateClientRectToADB(
            elixirClientX, elixirClientY, LootCropW, LootCropH
        )
    } catch as err {
        stackMsg := err.Message " at " (HasProp(err, "File") ? err.File : "") ":" (HasProp(err, "Line") ? err.Line : "")
        VerdictText.Text := "Mapping not ready: " stackMsg
        VerdictText.Opt("cRed")
        LogToConsole("NOT READY: " stackMsg "`n" (HasProp(err, "Stack") ? err.Stack : ""))
        return
    }

    LogToConsole("=== NEW FRESH-ADB LOOT OCR CYCLE ===")
    LogToConsole(
        Format(
            "Calibrated client {}x{}; thresholds Gold={}, Elixir={}.",
            CalibratedClientWidth,
            CalibratedClientHeight,
            MinGold,
            MinElixir
        )
    )
    LogToConsole(
        Format(
            "Gold client box ({}, {}, {}, {}) "
                "-> ADB ({}, {}, {}, {}).",
            goldClientX,
            goldClientY,
            LootCropW,
            LootCropH,
            goldADB.x,
            goldADB.y,
            goldADB.width,
            goldADB.height
        )
    )
    LogToConsole(
        Format(
            "Elixir client box ({}, {}, {}, {}) "
                "-> ADB ({}, {}, {}, {}).",
            elixirClientX,
            elixirClientY,
            LootCropW,
            LootCropH,
            elixirADB.x,
            elixirADB.y,
            elixirADB.width,
            elixirADB.height
        )
    )

    try {
        LogToConsole(
            "ADB capture: requesting one fresh frame for both loot crops."
        )
        framePath := CaptureLootADBFrame()
        LogToConsole("ADB capture complete: " framePath)
        SaveADBRegionToPNG(framePath, goldADB, GoldOCRPath)
        SaveADBRegionToPNG(framePath, elixirADB, ElixirOCRPath)
        goldResult := ScanLootRegion(GoldOCRPath, "Gold")
        elixirResult := ScanLootRegion(ElixirOCRPath, "Elixir")
        SaveADBRegionWithMarkers(
            framePath,
            goldADB,
            GoldPreviewPath,
            goldResult.valid
        )
        SaveADBRegionWithMarkers(
            framePath,
            elixirADB,
            ElixirPreviewPath,
            elixirResult.valid
        )
    } catch as err {
        stackMsg := err.Message " at "
            (HasProp(err, "File") ? err.File : "") ":"
            (HasProp(err, "Line") ? err.Line : "")
        VerdictText.Text := "Verdict: ADB CAPTURE/CROP ERROR"
        VerdictText.Opt("cRed")
        LogToConsole("ADB OCR CYCLE ERROR: " stackMsg)
        return
    }
    try PicGold.Value := GoldPreviewPath
    try PicElixir.Value := ElixirPreviewPath

    decision := EvaluateLootAttackDecision(
        goldResult,
        elixirResult,
        MinGold,
        MinElixir
    )
    actionText := decision.attack ? "ATTACK" : "NEXT"
    VerdictText.Text := Format(
        "Verdict: {} | G:{} | E:{}",
        actionText,
        FormatLootResult(goldResult),
        FormatLootResult(elixirResult)
    )
    VerdictText.Opt(decision.attack ? "cGreen" : "cRed")
    LogToConsole(
        Format(
            "DECISION: {} (reason={}). Gold={}, Elixir={}.",
            actionText,
            decision.reason,
            FormatLootResult(goldResult),
            FormatLootResult(elixirResult)
        )
    )
}

FormatLootResult(result) {
    return result.valid
        ? String(result.value)
        : "INVALID:" result.reason
}

F1:: RunLootOCR()

#HotIf IsCalibrating
Space:: CaptureCalibrationPoint()
#HotIf
