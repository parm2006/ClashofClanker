#Requires AutoHotkey v2
#Include OCR.ahk

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

ReloadConfig(force := false) {
    global TargetWindowTitle, GoldIconX, GoldIconY, ElixirIconX, ElixirIconY
    global LootCropOffsetX, LootCropOffsetY, LootCropW, LootCropH
    
    if FileExist("config.ini") {
        iniTarget := Trim(IniRead("config.ini", "Settings", "TargetWindowTitle", ""))
        if (iniTarget != "")
            TargetWindowTitle := iniTarget
            
        if force {
            LootCropOffsetX := Integer(IniRead("config.ini", "Settings", "LootCropOffsetX", 35))
            LootCropOffsetY := Integer(IniRead("config.ini", "Settings", "LootCropOffsetY", -17))
            LootCropW       := Integer(IniRead("config.ini", "Settings", "LootCropW", 220))
            LootCropH       := Integer(IniRead("config.ini", "Settings", "LootCropH", 40))
        }
        
        GoldIconX   := Integer(IniRead("config.ini", "Coordinates", "GoldIconX", 45))
        GoldIconY   := Integer(IniRead("config.ini", "Coordinates", "GoldIconY", 145))
        ElixirIconX := Integer(IniRead("config.ini", "Coordinates", "ElixirIconX", 45))
        ElixirIconY := Integer(IniRead("config.ini", "Coordinates", "ElixirIconY", 195))
    }
}

ReloadConfig(true)

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

; Adjuster GroupBox
MyGui.Add("GroupBox", "x15 y42 w685 h60", "Live Bounding Box Adjusters (Shared Gold & Elixir Offsets)")
MyGui.Add("Text", "x25 y68 w75 h20", "Offset X:")
EditOffsetX := MyGui.Add("Edit", "x100 y65 w50 h24 Number vEditOffsetX", String(LootCropOffsetX))
MyGui.Add("UpDown", "vSpinOffsetX Range-100-200", LootCropOffsetX)

MyGui.Add("Text", "x165 y68 w75 h20", "Offset Y:")
EditOffsetY := MyGui.Add("Edit", "x240 y65 w50 h24 vEditOffsetY", String(LootCropOffsetY))
MyGui.Add("UpDown", "vSpinOffsetY Range-100-200", LootCropOffsetY)

MyGui.Add("Text", "x305 y68 w75 h20", "Width:")
EditWidth := MyGui.Add("Edit", "x380 y65 w55 h24 Number vEditWidth", String(LootCropW))
MyGui.Add("UpDown", "vSpinWidth Range50-500", LootCropW)

MyGui.Add("Text", "x450 y68 w75 h20", "Height:")
EditHeight := MyGui.Add("Edit", "x525 y65 w55 h24 Number vEditHeight", String(LootCropH))
MyGui.Add("UpDown", "vSpinHeight Range10-200", LootCropH)

BtnSaveOffsets := MyGui.Add("Button", "x595 y63 w95 h28", "Save Offsets")

; Action Buttons
BtnScan       := MyGui.Add("Button", "x15 y110 w150 h35", "Scan Once (F1)")
BtnToggleAuto := MyGui.Add("Button", "x175 y110 w160 h35 vBtnToggleAuto", "Start Auto Scan")
BtnClear      := MyGui.Add("Button", "x590 y110 w110 h35", "Clear Console")

; GroupBox: Verdict Header
MyGui.Add("GroupBox", "x15 y152 w685 h70", "Parsed Loot Quantities")
MyGui.SetFont("s14 Bold", "Segoe UI")
VerdictText := MyGui.Add("Text", "x30 y175 w655 h40 vVerdictText cBlue", "Gold: ? | Elixir: ?")
MyGui.SetFont("s10 Norm", "Segoe UI")

; Picture Previews
MyGui.Add("GroupBox", "x15 y230 w335 h130", "Gold Digit Crop (Icon Center + Offsets)")
PicGold := MyGui.Add("Picture", "x25 y252 w315 h98 +Border vPicGold", "")

MyGui.Add("GroupBox", "x365 y230 w335 h130", "Elixir Digit Crop (Icon Center + Offsets)")
PicElixir := MyGui.Add("Picture", "x375 y252 w315 h98 +Border vPicElixir", "")

; Console
MyGui.Add("GroupBox", "x15 y370 w685 h340", "OCR Diagnostic Output & Multi-Scale Results")
MyGui.SetFont("s9", "Consolas")
ConsoleEdit := MyGui.Add("Edit", "x25 y395 w665 h305 ReadOnly +VScroll +HScroll vConsoleEdit", "")
MyGui.SetFont("s10", "Segoe UI")

; Event Handlers
EditTarget.OnEvent("Change", (*) => UpdateTargetTitle(EditTarget.Value))
ChkTop.OnEvent("Click", (*) => MyGui.Opt((ChkTop.Value ? "+" : "-") "AlwaysOnTop"))
BtnScan.OnEvent("Click", (*) => RunLootOCR())
BtnToggleAuto.OnEvent("Click", (*) => ToggleAutoScan())
BtnClear.OnEvent("Click", (*) => ClearConsole())
BtnSaveOffsets.OnEvent("Click", (*) => SaveCurrentOffsets())

EditOffsetX.OnEvent("Change", (*) => OnOffsetChanged())
EditOffsetY.OnEvent("Change", (*) => OnOffsetChanged())
EditWidth.OnEvent("Change", (*) => OnOffsetChanged())
EditHeight.OnEvent("Change", (*) => OnOffsetChanged())

MyGui.OnEvent("Close", (*) => ExitApp())
MyGui.Show("w715 h725")

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
    if FileExist("config.ini") {
        IniWrite(String(LootCropOffsetX), "config.ini", "Settings", "LootCropOffsetX")
        IniWrite(String(LootCropOffsetY), "config.ini", "Settings", "LootCropOffsetY")
        IniWrite(String(LootCropW),       "config.ini", "Settings", "LootCropW")
        IniWrite(String(LootCropH),       "config.ini", "Settings", "LootCropH")
        LogToConsole(Format("Saved Offsets to config.ini: OffsetX={}, OffsetY={}, W={}, H={}", LootCropOffsetX, LootCropOffsetY, LootCropW, LootCropH))
    }
}

OnOffsetChanged() {
    global LootCropOffsetX, LootCropOffsetY, LootCropW, LootCropH
    try {
        if (EditOffsetX.Value != "")
            LootCropOffsetX := Integer(EditOffsetX.Value)
        if (EditOffsetY.Value != "")
            LootCropOffsetY := Integer(EditOffsetY.Value)
        if (EditWidth.Value != "")
            LootCropW := Integer(EditWidth.Value)
        if (EditHeight.Value != "")
            LootCropH := Integer(EditHeight.Value)
        SetTimer RunLootOCR, -100
    }
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
        
    bestVal := 0
    for v in readings {
        if (v > bestVal)
            bestVal := v
    }
    return bestVal
}

RunLootOCR() {
    global TargetWindowTitle, GoldIconX, GoldIconY, ElixirIconX, ElixirIconY
    global LootCropOffsetX, LootCropOffsetY, LootCropW, LootCropH
    
    ReloadConfig()
    
    if !WinExist(TargetWindowTitle) {
        VerdictText.Text := "Target Window Not Found!"
        VerdictText.Opt("cGray")
        return
    }
    
    WinGetClientPos &cx, &cy, &cw, &ch, TargetWindowTitle
    
    ; Shared offset math from icon center for both Gold & Elixir
    goldCropX := cx + GoldIconX + LootCropOffsetX
    goldCropY := cy + GoldIconY + LootCropOffsetY
    goldW := LootCropW, goldH := LootCropH
    
    elixirCropX := cx + ElixirIconX + LootCropOffsetX
    elixirCropY := cy + ElixirIconY + LootCropOffsetY
    elixirW := LootCropW, elixirH := LootCropH
    
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
