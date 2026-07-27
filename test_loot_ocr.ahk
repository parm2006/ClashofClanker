#Requires AutoHotkey v2
#Include OCR.ahk

SetTitleMatchMode 2

; ==============================================================================
; Gold & Elixir Icon-Based OCR Visual Debugger with Auto-Update Loop
; ==============================================================================

global TargetWindowTitle := "Clash of Clans"
global GoldIconX := 100, GoldIconY := 120
global ElixirIconX := 100, ElixirIconY := 160

global ADBGoldIconX := 0, ADBGoldIconY := 0
global ADBElixirIconX := 0, ADBElixirIconY := 0
global ADBAttackBtnX := 0

global IsAutoScanning := false

ReloadConfig() {
    global TargetWindowTitle, GoldIconX, GoldIconY, ElixirIconX, ElixirIconY
    global ADBGoldIconX, ADBGoldIconY, ADBElixirIconX, ADBElixirIconY, ADBAttackBtnX
    
    if FileExist("config.ini") {
        iniTarget := Trim(IniRead("config.ini", "Settings", "TargetWindowTitle", ""))
        if (iniTarget != "")
            TargetWindowTitle := iniTarget
            
        ; Try reading icon coords first, fall back to area coords + 120 if uncalibrated
        gAreaX := Integer(IniRead("config.ini", "Coordinates", "GoldAreaX", 100))
        gAreaY := Integer(IniRead("config.ini", "Coordinates", "GoldAreaY", 120))
        eAreaX := Integer(IniRead("config.ini", "Coordinates", "ElixirAreaX", 100))
        eAreaY := Integer(IniRead("config.ini", "Coordinates", "ElixirAreaY", 160))
        
        GoldIconX := Integer(IniRead("config.ini", "Coordinates", "GoldIconX", gAreaX + 120))
        GoldIconY := Integer(IniRead("config.ini", "Coordinates", "GoldIconY", gAreaY + 15))
        ElixirIconX := Integer(IniRead("config.ini", "Coordinates", "ElixirIconX", eAreaX + 120))
        ElixirIconY := Integer(IniRead("config.ini", "Coordinates", "ElixirIconY", eAreaY + 15))
        
        ADBGoldIconX := Integer(IniRead("config.ini", "ADBCoordinates", "GoldIconX", 0))
        ADBGoldIconY := Integer(IniRead("config.ini", "ADBCoordinates", "GoldIconY", 0))
        ADBElixirIconX := Integer(IniRead("config.ini", "ADBCoordinates", "ElixirIconX", 0))
        ADBElixirIconY := Integer(IniRead("config.ini", "ADBCoordinates", "ElixirIconY", 0))
        ADBAttackBtnX := Integer(IniRead("config.ini", "ADBCoordinates", "AttackBtnX", 0))
    }
}

ReloadConfig()

; ------------------------------------------------------------------------------
; GUI Construction
; ------------------------------------------------------------------------------

MyGui := Gui("+Resize", "Clash of Clanker - Gold & Elixir OCR Inspector")
MyGui.SetFont("s10", "Segoe UI")

; Controls Header
MyGui.Add("Text", "x15 y14 w100 h25", "Target Window:")
EditTarget := MyGui.Add("Edit", "x120 y10 w220 h26 vEditTarget", TargetWindowTitle)
ChkTop := MyGui.Add("Checkbox", "x355 y14 w130 h25 vChkTop", "Always On Top")
StatusText := MyGui.Add("Text", "x500 y14 w200 h25 vStatusText Right cGray", "Status: Idle")

; Buttons
BtnScan  := MyGui.Add("Button", "x15 y48 w150 h35", "Scan Once (F1)")
BtnToggleAuto := MyGui.Add("Button", "x175 y48 w160 h35 vBtnToggleAuto", "Start Auto Scan")
BtnClear := MyGui.Add("Button", "x590 y48 w110 h35", "Clear Console")

; GroupBox: Verdict Header
MyGui.Add("GroupBox", "x15 y90 w685 h75", "Parsed Loot Quantities")
MyGui.SetFont("s14 Bold", "Segoe UI")
VerdictText := MyGui.Add("Text", "x30 y115 w655 h40 vVerdictText cBlue", "Gold: ? | Elixir: ?")
MyGui.SetFont("s10 Norm", "Segoe UI")

; Picture Previews
MyGui.Add("GroupBox", "x15 y170 w335 h140", "Gold Digit Crop (Offset from Coin Icon)")
PicGold := MyGui.Add("Picture", "x25 y195 w315 h105 +Border vPicGold", "")

MyGui.Add("GroupBox", "x365 y170 w335 h140", "Elixir Digit Crop (Offset from Drop Icon)")
PicElixir := MyGui.Add("Picture", "x375 y195 w315 h105 +Border vPicElixir", "")

; Console
MyGui.Add("GroupBox", "x15 y320 w685 h340", "OCR Diagnostic Output & Multi-Scale Results")
MyGui.SetFont("s9", "Consolas")
ConsoleEdit := MyGui.Add("Edit", "x25 y345 w665 h305 ReadOnly +VScroll +HScroll vConsoleEdit", "")
MyGui.SetFont("s10", "Segoe UI")

; Event Handlers
EditTarget.OnEvent("Change", (*) => UpdateTargetTitle(EditTarget.Value))
ChkTop.OnEvent("Click", (*) => MyGui.Opt((ChkTop.Value ? "+" : "-") "AlwaysOnTop"))
BtnScan.OnEvent("Click", (*) => RunLootOCR())
BtnToggleAuto.OnEvent("Click", (*) => ToggleAutoScan())
BtnClear.OnEvent("Click", (*) => ClearConsole())

MyGui.OnEvent("Close", (*) => ExitApp())
MyGui.Show("w715 h675")

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

ToggleAutoScan() {
    global IsAutoScanning, BtnToggleAuto, StatusText
    IsAutoScanning := !IsAutoScanning
    if IsAutoScanning {
        BtnToggleAuto.Text := "Stop Auto Scan"
        StatusText.Value := "Status: Auto Scanning (1s)"
        StatusText.Opt("cGreen")
        SetTimer RunLootOCR, 1000
        RunLootOCR()
    } else {
        BtnToggleAuto.Text := "Start Auto Scan"
        StatusText.Value := "Status: Stopped"
        StatusText.Opt("cGray")
        SetTimer RunLootOCR, 0
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
    return res = "" ? 0 : Integer(res)
}

SaveRegionToPNG(x, y, w, h, filepath) {
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

ScanLootRegion(cropX, cropY, cropW, cropH, label) {
    scales := [2.0, 2.5, 3.0, 1.5]
    readings := []
    for sc in scales {
        try {
            result := OCR.FromRect(cropX, cropY, cropW, cropH, {scale: sc})
            cleaned := CleanNumberStr(result.Text)
            if (cleaned > 0) {
                readings.Push(cleaned)
                LogToConsole(Format("  Scale {:.1f}x -> Raw Text: '{}' | Cleaned: {:d}", sc, result.Text, cleaned))
            }
        } catch as err {
            LogToConsole("  Scale Error: " err.Message)
        }
    }
    if (readings.Length == 0)
        return 0
        
    ; Find highest candidate
    bestVal := 0
    for v in readings {
        if (v > bestVal)
            bestVal := v
    }
    return bestVal
}

RunLootOCR() {
    global TargetWindowTitle, GoldIconX, GoldIconY, ElixirIconX, ElixirIconY
    
    ; Dynamic config reloading at start of cycle
    ReloadConfig()
    
    if !WinExist(TargetWindowTitle) {
        VerdictText.Text := "Target Window Not Found!"
        VerdictText.Opt("cGray")
        return
    }
    
    WinGetClientPos &cx, &cy, &cw, &ch, TargetWindowTitle
    
    ; Calculate crop region starting to the right of the icon
    goldCropX := cx + GoldIconX + 35
    goldCropY := cy + GoldIconY - 18
    goldW := 260, goldH := 42
    
    elixirCropX := cx + ElixirIconX + 35
    elixirCropY := cy + ElixirIconY - 18
    elixirW := 260, elixirH := 42
    
    LogToConsole("--- Scanning Gold Loot OCR ---")
    SaveRegionToPNG(goldCropX, goldCropY, goldW, goldH, A_ScriptDir "\scratch\gold_crop.png")
    try PicGold.Value := A_ScriptDir "\scratch\gold_crop.png"
    parsedGold := ScanLootRegion(goldCropX, goldCropY, goldW, goldH, "Gold")
    
    LogToConsole("--- Scanning Elixir Loot OCR ---")
    SaveRegionToPNG(elixirCropX, elixirCropY, elixirW, elixirH, A_ScriptDir "\scratch\elixir_crop.png")
    try PicElixir.Value := A_ScriptDir "\scratch\elixir_crop.png"
    parsedElixir := ScanLootRegion(elixirCropX, elixirCropY, elixirW, elixirH, "Elixir")
    
    VerdictText.Text := Format("Gold: {:L} | Elixir: {:L}", Format("{:d}", parsedGold), Format("{:d}", parsedElixir))
    VerdictText.Opt((parsedGold > 0 || parsedElixir > 0) ? "cGreen" : "cRed")
}

F1:: RunLootOCR()
