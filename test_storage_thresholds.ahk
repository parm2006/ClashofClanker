#Requires AutoHotkey v2
#Include OCR.ahk

SetTitleMatchMode 2

; ==============================================================================
; Storage Bar Thresholds Visual Inspector
; ==============================================================================

global TargetWindowTitle := "Clash of Clans"
global GoldBarThreshX := 1494, GoldBarThreshY := 84
global ElixirBarThreshX := 1492, ElixirBarThreshY := 163
global DarkElixirBarThreshX := 1562, DarkElixirBarThreshY := 245

global ADBGoldBarThreshX := 1626, ADBGoldBarThreshY := 46
global ADBElixirBarThreshX := 1624, ADBElixirBarThreshY := 133
global ADBDarkElixirBarThreshX := 1701, ADBDarkElixirBarThreshY := 222

if FileExist("config.ini") {
    iniTarget := Trim(IniRead("config.ini", "Settings", "TargetWindowTitle", ""))
    if (iniTarget != "")
        TargetWindowTitle := iniTarget
        
    GoldBarThreshX := Integer(IniRead("config.ini", "Coordinates", "GoldBarThreshX", 1494))
    GoldBarThreshY := Integer(IniRead("config.ini", "Coordinates", "GoldBarThreshY", 84))
    ElixirBarThreshX := Integer(IniRead("config.ini", "Coordinates", "ElixirBarThreshX", 1492))
    ElixirBarThreshY := Integer(IniRead("config.ini", "Coordinates", "ElixirBarThreshY", 163))
    DarkElixirBarThreshX := Integer(IniRead("config.ini", "Coordinates", "DarkElixirBarThreshX", 1562))
    DarkElixirBarThreshY := Integer(IniRead("config.ini", "Coordinates", "DarkElixirBarThreshY", 245))
    
    ADBGoldBarThreshX := Integer(IniRead("config.ini", "ADBCoordinates", "GoldBarThreshX", GoldBarThreshX))
    ADBGoldBarThreshY := Integer(IniRead("config.ini", "ADBCoordinates", "GoldBarThreshY", GoldBarThreshY))
    ADBElixirBarThreshX := Integer(IniRead("config.ini", "ADBCoordinates", "ElixirBarThreshX", ElixirBarThreshX))
    ADBElixirBarThreshY := Integer(IniRead("config.ini", "ADBCoordinates", "ElixirBarThreshY", ElixirBarThreshY))
    ADBDarkElixirBarThreshX := Integer(IniRead("config.ini", "ADBCoordinates", "DarkElixirBarThreshX", DarkElixirBarThreshX))
    ADBDarkElixirBarThreshY := Integer(IniRead("config.ini", "ADBCoordinates", "DarkElixirBarThreshY", DarkElixirBarThreshY))
}

; ------------------------------------------------------------------------------
; GUI Construction
; ------------------------------------------------------------------------------

MyGui := Gui("+Resize", "Clash of Clanker - Storage Bar Thresholds Inspector")
MyGui.SetFont("s10", "Segoe UI")

; Header
MyGui.Add("Text", "x15 y14 w100 h25", "Target Window:")
EditTarget := MyGui.Add("Edit", "x120 y10 w220 h26 vEditTarget", TargetWindowTitle)
ChkTop := MyGui.Add("Checkbox", "x355 y14 w130 h25 vChkTop", "Always On Top")
StatusText := MyGui.Add("Text", "x500 y14 w200 h25 vStatusText Right cGray", "Status: Ready")

; Buttons
BtnInspect := MyGui.Add("Button", "x15 y48 w160 h35", "Inspect Once (F1)")
BtnLive    := MyGui.Add("Button", "x185 y48 w180 h35 vBtnLive", "Start Live Monitoring (F4)")
BtnClear   := MyGui.Add("Button", "x590 y48 w110 h35", "Clear Console")

; GroupBox: State Verdict
MyGui.Add("GroupBox", "x15 y90 w685 h75", "Resource Threshold Status")
MyGui.SetFont("s14 Bold", "Segoe UI")
VerdictText := MyGui.Add("Text", "x30 y115 w655 h40 vVerdictText cBlue", "Gold: ? | Elixir: ? | Dark Elixir: ?")
MyGui.SetFont("s10 Norm", "Segoe UI")

; Image Previews
MyGui.Add("GroupBox", "x15 y170 w220 h130", "Gold Bar Point")
PicGold := MyGui.Add("Picture", "x25 y195 w200 h95 +Border vPicGold", "")

MyGui.Add("GroupBox", "x245 y170 w220 h130", "Elixir Bar Point")
PicElixir := MyGui.Add("Picture", "x255 y195 w200 h95 +Border vPicElixir", "")

MyGui.Add("GroupBox", "x475 y170 w220 h130", "Dark Elixir Bar Point")
PicDE := MyGui.Add("Picture", "x485 y195 w200 h95 +Border vPicDE", "")

; Console
MyGui.Add("GroupBox", "x15 y310 w685 h350", "Diagnostic Color Log & Coordinate Breakdown")
MyGui.SetFont("s9", "Consolas")
ConsoleEdit := MyGui.Add("Edit", "x25 y335 w665 h315 ReadOnly +VScroll +HScroll vConsoleEdit", "")
MyGui.SetFont("s10", "Segoe UI")

; Event Handlers
EditTarget.OnEvent("Change", (*) => UpdateTargetTitle(EditTarget.Value))
ChkTop.OnEvent("Click", (*) => MyGui.Opt((ChkTop.Value ? "+" : "-") "AlwaysOnTop"))
BtnInspect.OnEvent("Click", (*) => RunInspectCycle())
BtnLive.OnEvent("Click", (*) => ToggleLiveMonitoring())
BtnClear.OnEvent("Click", (*) => ClearConsole())

MyGui.OnEvent("Close", (*) => ExitApp())
MyGui.Show("w715 h675")

SetTimer(RunInspectCycle, 500)

; ------------------------------------------------------------------------------
; Functions
; ------------------------------------------------------------------------------

UpdateTargetTitle(newTitle) {
    global TargetWindowTitle
    TargetWindowTitle := Trim(newTitle)
    if (TargetWindowTitle == "")
        TargetWindowTitle := "Clash of Clans"
}

LogToConsole(msg) {
    timeStr := FormatTime(, "HH:mm:ss")
    ConsoleEdit.Value .= "[" timeStr "] " msg "`n"
    SendMessage(0x0115, 7, 0, ConsoleEdit)
}

ClearConsole() {
    ConsoleEdit.Value := ""
}

IsGoldColor(r, g, b) {
    return (r > 120) && (g > 100) && (r > b + 20) && (g > b + 10)
}

IsElixirColor(r, g, b) {
    isPink := (r >= 180) && (g >= 80 && g <= 220) && (b >= 100 && b <= 230) && (r > g) && (r >= b * 0.75) && ((r + g + b) / 3 > 140)
    isDarkPink := (r > 120) && (b > 100) && (r > g + 20)
    return isPink || isDarkPink
}

IsDEColor(topR, topG, topB, botR, botG, botB) {
    isTopEmpty := (topR > 110 && topG > 110 && topB > 110) && (Abs(topR - topG) < 20)
    isBotDark := (botR < 70) && (botG < 70) && (botB < 70)
    isTopDark := (topR < 110) && (topG < 110) && (topB < 110)
    topLighterThanBot := (topR >= botR) && (topG >= botG) && (topB >= botB)
    return (isBotDark && isTopDark && topLighterThanBot && !isTopEmpty)
}

SaveRegionWithPointMarker(x, y, w, h, filepath, relX, relY, isPass) {
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
    pGraphics := 0
    DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", pBitmap, "ptr*", &pGraphics)
    
    pPen := 0
    penColor := isPass ? 0xFF00FF00 : 0xFFFF0000
    DllCall("gdiplus\GdipCreatePen1", "uint", penColor, "float", 3.0, "int", 2, "ptr*", &pPen)
    DllCall("gdiplus\GdipDrawRectangle", "ptr", pGraphics, "ptr", pPen, "float", relX - 5, "float", relY - 5, "float", 10.0, "float", 10.0)
    
    DllCall("gdiplus\GdipDeletePen", "ptr", pPen)
    DllCall("gdiplus\GdipDeleteGraphics", "ptr", pGraphics)
    
    clsid := Buffer(16, 0)
    DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid)
    DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "wstr", filepath, "ptr", clsid, "ptr", 0)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    DllCall("SelectObject", "ptr", hdcMem, "ptr", obm)
    DllCall("DeleteObject", "ptr", hbm)
    DllCall("DeleteDC", "ptr", hdcMem)
    DllCall("ReleaseDC", "ptr", 0, "ptr", hdcScreen)
}

RunInspectCycle() {
    global TargetWindowTitle, GoldBarThreshX, GoldBarThreshY, ElixirBarThreshX, ElixirBarThreshY, DarkElixirBarThreshX, DarkElixirBarThreshY
    global ADBGoldBarThreshX, ADBGoldBarThreshY, ADBElixirBarThreshX, ADBElixirBarThreshY, ADBDarkElixirBarThreshX, ADBDarkElixirBarThreshY
    
    ; Auto-reload calibration from config.ini
    if FileExist("config.ini") {
        GoldBarThreshX := Integer(IniRead("config.ini", "Coordinates", "GoldBarThreshX", GoldBarThreshX))
        GoldBarThreshY := Integer(IniRead("config.ini", "Coordinates", "GoldBarThreshY", GoldBarThreshY))
        ElixirBarThreshX := Integer(IniRead("config.ini", "Coordinates", "ElixirBarThreshX", ElixirBarThreshX))
        ElixirBarThreshY := Integer(IniRead("config.ini", "Coordinates", "ElixirBarThreshY", ElixirBarThreshY))
        DarkElixirBarThreshX := Integer(IniRead("config.ini", "Coordinates", "DarkElixirBarThreshX", DarkElixirBarThreshX))
        DarkElixirBarThreshY := Integer(IniRead("config.ini", "Coordinates", "DarkElixirBarThreshY", DarkElixirBarThreshY))
    }
    
    if !WinExist(TargetWindowTitle) {
        VerdictText.Text := "Target Window Not Found!"
        VerdictText.Opt("cGray")
        return
    }
    
    WinGetClientPos &cx, &cy, &cw, &ch, TargetWindowTitle
    
    ; 1. Gold Check
    gScrX := cx + GoldBarThreshX
    gScrY := cy + GoldBarThreshY
    CoordMode "Pixel", "Screen"
    cG := PixelGetColor(gScrX, gScrY)
    rG := (cG >> 16) & 0xFF, gG := (cG >> 8) & 0xFF, bG := cG & 0xFF
    passGold := IsGoldColor(rG, gG, bG)
    
    ; 2. Elixir Check
    eScrX := cx + ElixirBarThreshX
    eScrY := cy + ElixirBarThreshY
    cE := PixelGetColor(eScrX, eScrY)
    rE := (cE >> 16) & 0xFF, gE := (cE >> 8) & 0xFF, bE := cE & 0xFF
    passElixir := IsElixirColor(rE, gE, bE)
    
    ; 3. Dark Elixir Check
    deScrX := cx + DarkElixirBarThreshX
    deScrY := cy + DarkElixirBarThreshY
    cDETop := PixelGetColor(deScrX, deScrY)
    cDEBot := PixelGetColor(deScrX, deScrY + 3)
    topR := (cDETop >> 16) & 0xFF, topG := (cDETop >> 8) & 0xFF, topB := cDETop & 0xFF
    botR := (cDEBot >> 16) & 0xFF, botG := (cDEBot >> 8) & 0xFF, botB := cDEBot & 0xFF
    passDE := IsDEColor(topR, topG, topB, botR, botG, botB)
    
    VerdictText.Text := Format("Gold: {} | Elixir: {} | Dark Elixir: {}", passGold ? "FILLED" : "NO", passElixir ? "FILLED" : "NO", passDE ? "FILLED" : "NO")
    VerdictText.Opt((passGold && passElixir && passDE) ? "cGreen" : "cRed")
    
    ; RenderPreviews
    SaveRegionWithPointMarker(Max(0, gScrX - 50), Max(0, gScrY - 25), 100, 50, A_ScriptDir "\scratch\gold_thresh.png", 50, 25, passGold)
    try PicGold.Value := A_ScriptDir "\scratch\gold_thresh.png"
    
    SaveRegionWithPointMarker(Max(0, eScrX - 50), Max(0, eScrY - 25), 100, 50, A_ScriptDir "\scratch\elixir_thresh.png", 50, 25, passElixir)
    try PicElixir.Value := A_ScriptDir "\scratch\elixir_thresh.png"
    
    SaveRegionWithPointMarker(Max(0, deScrX - 50), Max(0, deScrY - 25), 100, 50, A_ScriptDir "\scratch\de_thresh.png", 50, 25, passDE)
    try PicDE.Value := A_ScriptDir "\scratch\de_thresh.png"
}

ToggleLiveMonitoring() {
    ; Background timer active by default
}

F1:: RunInspectCycle()
