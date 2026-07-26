#Requires AutoHotkey v2
#Include OCR.ahk

SetTitleMatchMode 2

; ==============================================================================
; Home Village vs Battle Live Detection & Pixel Inspector
; ==============================================================================

global TargetWindowTitle := "Clash of Clans"
global AttackBtnX := 120
global AttackBtnY := 960
global WarLogoX := 50
global WarLogoY := 620
global ADBAttackBtnX := 0
global ADBAttackBtnY := 0
global ADBWarLogoX := 0
global ADBWarLogoY := 0
global IsLiveMonitoring := false

; Load config.ini settings if available
if FileExist("config.ini") {
    iniTarget := Trim(IniRead("config.ini", "Settings", "TargetWindowTitle", ""))
    if (iniTarget != "")
        TargetWindowTitle := iniTarget
        
    iniAtkX := IniRead("config.ini", "Coordinates", "AttackBtnX", "")
    if (iniAtkX != "" && IsNumber(iniAtkX))
        AttackBtnX := Integer(iniAtkX)
        
    iniAtkY := IniRead("config.ini", "Coordinates", "AttackBtnY", "")
    if (iniAtkY != "" && IsNumber(iniAtkY))
        AttackBtnY := Integer(iniAtkY)

    iniWarX := IniRead("config.ini", "Coordinates", "MVLogoX", "")
    if (iniWarX == "")
        iniWarX := IniRead("config.ini", "Coordinates", "WarLogoX", "")
    if (iniWarX != "" && IsNumber(iniWarX))
        WarLogoX := Integer(iniWarX)
        
    iniWarY := IniRead("config.ini", "Coordinates", "MVLogoY", "")
    if (iniWarY == "")
        iniWarY := IniRead("config.ini", "Coordinates", "WarLogoY", "")
    if (iniWarY != "" && IsNumber(iniWarY))
        WarLogoY := Integer(iniWarY)
}

; ------------------------------------------------------------------------------
; GUI Construction
; ------------------------------------------------------------------------------

MyGui := Gui("+Resize", "Clash of Clanker - Home Village vs Battle Pixel Inspector")
MyGui.SetFont("s10", "Segoe UI")

; Row 1: Target Window & Header
MyGui.Add("Text", "x15 y14 w100 h25", "Target Window:")
EditTarget := MyGui.Add("Edit", "x120 y10 w220 h26 vEditTarget", TargetWindowTitle)
ChkTop := MyGui.Add("Checkbox", "x355 y14 w130 h25 vChkTop", "Always On Top")
StatusText := MyGui.Add("Text", "x500 y14 w200 h25 vStatusText Right cGray", "Status: Ready")

; Row 2: Coordinate Inputs & Calibration
MyGui.Add("Text", "x15 y48 w75 h25", "Attack X/Y:")
EditAtkX := MyGui.Add("Edit", "x95 y44 w65 h26 vEditAtkX Number", AttackBtnX)
MyGui.Add("UpDown", "vSpinAtkX Range0-3840", AttackBtnX)
EditAtkY := MyGui.Add("Edit", "x165 y44 w65 h26 vEditAtkY Number", AttackBtnY)
MyGui.Add("UpDown", "vSpinAtkY Range0-2160", AttackBtnY)

MyGui.Add("Text", "x245 y48 w75 h25", "War X/Y:")
EditWarX := MyGui.Add("Edit", "x320 y44 w65 h26 vEditWarX Number", WarLogoX)
MyGui.Add("UpDown", "vSpinWarX Range0-3840", WarLogoX)
EditWarY := MyGui.Add("Edit", "x390 y44 w65 h26 vEditWarY Number", WarLogoY)
MyGui.Add("UpDown", "vSpinWarY Range0-2160", WarLogoY)

BtnSave := MyGui.Add("Button", "x470 y44 w110 h28", "Save Config")
BtnClear := MyGui.Add("Button", "x590 y44 w110 h28", "Clear Console")

; Row 3: Action Buttons
BtnInspect := MyGui.Add("Button", "x15 y80 w160 h35", "Inspect Once (F1)")
BtnLive    := MyGui.Add("Button", "x185 y80 w180 h35 vBtnLive", "Start Live Monitoring (F4)")

; GroupBox: Live State Header
MyGui.Add("GroupBox", "x15 y125 w685 h80", "Current State Verdict")
MyGui.SetFont("s16 Bold", "Segoe UI")
HomeVerdictText := MyGui.Add("Text", "x30 y150 w655 h45 vHomeVerdictText cBlue", "Detection: UNKNOWN")
MyGui.SetFont("s10 Norm", "Segoe UI")

; GroupBox: Image Previews with Pixel Highlight Markers
MyGui.Add("GroupBox", "x15 y215 w335 h140", "Attack Button Area (-45px / +45px points)")
PicAttack := MyGui.Add("Picture", "x30 y240 w305 h100 +Border vPicAttack", "")

MyGui.Add("GroupBox", "x365 y215 w335 h140", "War Logo Area (Center Point)")
PicWar := MyGui.Add("Picture", "x380 y240 w305 h100 +Border vPicWar", "")

; GroupBox: Console Log
MyGui.Add("GroupBox", "x15 y365 w685 h290", "Diagnostic Log & Color Breakdown")
MyGui.SetFont("s9", "Consolas")
ConsoleEdit := MyGui.Add("Edit", "x25 y390 w665 h255 ReadOnly +VScroll +HScroll vConsoleEdit", "")
MyGui.SetFont("s10", "Segoe UI")

; Event Bindings
EditTarget.OnEvent("Change", (*) => UpdateTargetTitle(EditTarget.Value))
ChkTop.OnEvent("Click", (*) => ToggleAlwaysOnTop(ChkTop.Value))

EditAtkX.OnEvent("Change", (*) => OnCoordChange())
EditAtkY.OnEvent("Change", (*) => OnCoordChange())
EditWarX.OnEvent("Change", (*) => OnCoordChange())
EditWarY.OnEvent("Change", (*) => OnCoordChange())

BtnSave.OnEvent("Click", (*) => SaveConfigIni())
BtnInspect.OnEvent("Click", (*) => RunInspectCycle())
BtnLive.OnEvent("Click", (*) => ToggleLiveMonitoring())
BtnClear.OnEvent("Click", (*) => ClearConsole())

MyGui.OnEvent("Close", (*) => ExitApp())
MyGui.Show("w715 h670")

LogToConsole("--- Home Village vs Battle Pixel Inspector Initialized ---")
LogToConsole(Format("Target: '{}' | AttackBtn: ({}, {}) | WarLogo: ({}, {})", TargetWindowTitle, AttackBtnX, AttackBtnY, WarLogoX, WarLogoY))
LogToConsole("Press F1 to Inspect Once | F4 to Toggle Live Monitoring (500ms)`n")

; Background live preview timer
SetTimer(RefreshPreviewsAndVerdict, 500)

; ------------------------------------------------------------------------------
; Event Handlers
; ------------------------------------------------------------------------------

UpdateTargetTitle(newTitle) {
    global TargetWindowTitle
    TargetWindowTitle := Trim(newTitle)
    if (TargetWindowTitle == "")
        TargetWindowTitle := "Clash of Clans"
    LogToConsole("Target Window Title set to: '" TargetWindowTitle "'")
}

ToggleAlwaysOnTop(isTop) {
    MyGui.Opt((isTop ? "+" : "-") "AlwaysOnTop")
    LogToConsole("Always On Top mode " (isTop ? "ENABLED" : "DISABLED") ".")
}

OnCoordChange() {
    global AttackBtnX, AttackBtnY, WarLogoX, WarLogoY
    try {
        AttackBtnX := Integer(EditAtkX.Value)
        AttackBtnY := Integer(EditAtkY.Value)
        WarLogoX := Integer(EditWarX.Value)
        WarLogoY := Integer(EditWarY.Value)
        SetTimer(RefreshPreviewsAndVerdict, -150)
    }
}

SaveConfigIni() {
    global TargetWindowTitle, AttackBtnX, AttackBtnY, WarLogoX, WarLogoY
    try {
        IniWrite(TargetWindowTitle, "config.ini", "Settings", "TargetWindowTitle")
        IniWrite(AttackBtnX, "config.ini", "Coordinates", "AttackBtnX")
        IniWrite(AttackBtnY, "config.ini", "Coordinates", "AttackBtnY")
        IniWrite(WarLogoX, "config.ini", "Coordinates", "MVLogoX")
        IniWrite(WarLogoY, "config.ini", "Coordinates", "MVLogoY")
        SoundBeep(1200, 150)
        LogToConsole(Format("SAVED TO config.ini -> AttackBtn: ({}, {}), MVLogo: ({}, {})", AttackBtnX, AttackBtnY, WarLogoX, WarLogoY))
        MsgBox("Saved coordinates to config.ini!", "Config Saved", 64)
    } catch as err {
        LogToConsole("ERROR saving config: " err.Message)
    }
}

LogToConsole(msg) {
    timeStr := FormatTime(, "HH:mm:ss")
    formattedMsg := "[" timeStr "] " msg "`n"
    ConsoleEdit.Value .= formattedMsg
    SendMessage(0x0115, 7, 0, ConsoleEdit) ; WM_VSCROLL = 0x0115, SB_BOTTOM = 7
}

ClearConsole() {
    ConsoleEdit.Value := ""
    LogToConsole("Console cleared.")
}

; ------------------------------------------------------------------------------
; Pixel Logic & Highlighted Capture
; ------------------------------------------------------------------------------

IsAttackBtnColor(r, g, b) {
    ; 1. Brown Wood Shield Background (e.g. RGB 140, 75, 30)
    isBrownWood := (r > g) && (g > b) && (r - b >= 25) && (g - b >= 10) && (r >= 70 && r <= 250)
    ; 2. Tan / Beige / Yellow Paper Map (e.g. RGB 245, 220, 175)
    isTanMap := (r >= 180) && (g >= 140) && (b >= 90) && (r >= g) && (g >= b * 0.75)
    return isBrownWood || isTanMap
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

SaveRegionWithMarkers(x, y, w, h, filepath, markers) {
    ; markers is array of {relX, relY, isPass}
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
    
    ; Draw graphics markers over bitmap
    pGraphics := 0
    DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", pBitmap, "ptr*", &pGraphics)
    
    pPenGreen := 0, pPenRed := 0
    DllCall("gdiplus\GdipCreatePen1", "uint", 0xFF00FF00, "float", 3.0, "int", 2, "ptr*", &pPenGreen) ; Green pen
    DllCall("gdiplus\GdipCreatePen1", "uint", 0xFFFF0000, "float", 3.0, "int", 2, "ptr*", &pPenRed)   ; Red pen
    
    for m in markers {
        pen := m.isPass ? pPenGreen : pPenRed
        ; Draw 10x10 crosshair / square around sample point
        mx := m.relX
        my := m.relY
        DllCall("gdiplus\GdipDrawRectangle", "ptr", pGraphics, "ptr", pen, "float", mx - 5, "float", my - 5, "float", 10.0, "float", 10.0)
    }
    
    DllCall("gdiplus\GdipDeletePen", "ptr", pPenGreen)
    DllCall("gdiplus\GdipDeletePen", "ptr", pPenRed)
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

RefreshPreviewsAndVerdict() {
    global AttackBtnX, AttackBtnY, WarLogoX, WarLogoY, TargetWindowTitle
    if !WinExist(TargetWindowTitle) {
        StatusText.Value := Format("Status: Not Found ('{}')", TargetWindowTitle)
        HomeVerdictText.Text := "Detection: WINDOW NOT FOUND"
        HomeVerdictText.Opt("cGray")
        return
    }
    
    WinGetClientPos &cx, &cy, &cw, &ch, TargetWindowTitle
    StatusText.Value := Format("Window: {}x{}", cw, ch)
    
    ; 1. Inspect Attack Button Sample Points (-45px, +45px)
    leftX := cx + AttackBtnX - 45
    leftY := cy + AttackBtnY
    rightX := cx + AttackBtnX + 45
    rightY := cy + AttackBtnY
    
    CoordMode "Pixel", "Screen"
    cLeft := PixelGetColor(leftX, leftY)
    cRight := PixelGetColor(rightX, rightY)
    
    rL := (cLeft >> 16) & 0xFF, gL := (cLeft >> 8) & 0xFF, bL := cLeft & 0xFF
    rR := (cRight >> 16) & 0xFF, gR := (cRight >> 8) & 0xFF, bR := cRight & 0xFF
    
    passLeft := IsAttackBtnColor(rL, gL, bL)
    passRight := IsAttackBtnColor(rR, gR, bR)
    passAttack := passLeft || passRight
    
    ; 2. Inspect War Logo Sample Point + 4 Diagonal Points (+/- 20px)
    warX := cx + WarLogoX
    warY := cy + WarLogoY
    CoordMode "Pixel", "Screen"
    
    warOffsets := [{x:0, y:0}, {x:-20, y:-20}, {x:20, y:-20}, {x:-20, y:20}, {x:20, y:20}]
    passWar := false
    warMarkers := []
    
    for pt in warOffsets {
        pX := warX + pt.x
        pY := warY + pt.y
        c := PixelGetColor(pX, pY)
        r := (c >> 16) & 0xFF, g := (c >> 8) & 0xFF, b := c & 0xFF
        isP := IsWarLogoColor(r, g, b)
        if isP
            passWar := true
        warMarkers.Push({relX: (pX - (Max(0, cx + WarLogoX - 50))), relY: (pY - (Max(0, cy + WarLogoY - 50))), isPass: isP})
    }
    
    isHome := passAttack && passWar
    
    ; Update Verdict Header Text
    if isHome {
        HomeVerdictText.Text := "Verdict: AT HOME VILLAGE (TRUE)"
        HomeVerdictText.Opt("cGreen")
    } else {
        HomeVerdictText.Text := "Verdict: IN BATTLE / NOT HOME (FALSE)"
        HomeVerdictText.Opt("cRed")
    }
    
    ; Save Attack Button Crop Region with highlighted markers (160x80 around AttackBtn)
    atkCropX := Max(0, cx + AttackBtnX - 80)
    atkCropY := Max(0, cy + AttackBtnY - 40)
    atkMarkers := [
        {relX: (leftX - atkCropX), relY: (leftY - atkCropY), isPass: passLeft},
        {relX: (rightX - atkCropX), relY: (rightY - atkCropY), isPass: passRight}
    ]
    atkImgPath := A_ScriptDir "\scratch\atk_preview_marked.png"
    SaveRegionWithMarkers(atkCropX, atkCropY, 160, 80, atkImgPath, atkMarkers)
    try PicAttack.Value := atkImgPath
    
    ; Save War Logo Crop Region with 5 highlighted markers (100x100 around WarLogo)
    warCropX := Max(0, cx + WarLogoX - 50)
    warCropY := Max(0, cy + WarLogoY - 50)
    warImgPath := A_ScriptDir "\scratch\war_preview_marked.png"
    SaveRegionWithMarkers(warCropX, warCropY, 100, 100, warImgPath, warMarkers)
    try PicWar.Value := warImgPath
}

RunInspectCycle() {
    global AttackBtnX, AttackBtnY, WarLogoX, WarLogoY, TargetWindowTitle
    if !WinExist(TargetWindowTitle) {
        LogToConsole("ERROR: Target window '" TargetWindowTitle "' not found!")
        return
    }
    
    WinGetClientPos &cx, &cy, &cw, &ch, TargetWindowTitle
    leftX := cx + AttackBtnX - 45
    leftY := cy + AttackBtnY
    rightX := cx + AttackBtnX + 45
    rightY := cy + AttackBtnY
    warX := cx + WarLogoX
    warY := cy + WarLogoY
    
    CoordMode "Pixel", "Screen"
    cLeft := PixelGetColor(leftX, leftY)
    cRight := PixelGetColor(rightX, rightY)
    
    rL := (cLeft >> 16) & 0xFF, gL := (cLeft >> 8) & 0xFF, bL := cLeft & 0xFF
    rR := (cRight >> 16) & 0xFF, gR := (cRight >> 8) & 0xFF, bR := cRight & 0xFF
    
    pLeft := IsAttackBtnColor(rL, gL, bL)
    pRight := IsAttackBtnColor(rR, gR, bR)
    
    warOffsets := [{x:0, y:0}, {x:-20, y:-20}, {x:20, y:-20}, {x:-20, y:20}, {x:20, y:20}]
    pWar := false
    for pt in warOffsets {
        c := PixelGetColor(warX + pt.x, warY + pt.y)
        r := (c >> 16) & 0xFF, g := (c >> 8) & 0xFF, b := c & 0xFF
        if IsWarLogoColor(r, g, b) {
            pWar := true
            break
        }
    }
    
    isHome := (pLeft || pRight) && pWar
    
    LogToConsole("=== INSPECTION RUN ===")
    LogToConsole(Format("Attack Left (-45px)  @ ({}, {}): RGB({}, {}, {}) -> Hex: {} -> Pass: {}", leftX, leftY, rL, gL, bL, cLeft, pLeft ? "YES [GREEN]" : "NO [RED]"))
    LogToConsole(Format("Attack Right (+45px) @ ({}, {}): RGB({}, {}, {}) -> Hex: {} -> Pass: {}", rightX, rightY, rR, gR, bR, cRight, pRight ? "YES [GREEN]" : "NO [RED]"))
    LogToConsole(Format("War Logo 5-Pt Check @ ({}, {}): Pass: {}", warX, warY, pWar ? "YES [GREEN]" : "NO [RED]"))
    LogToConsole(Format("OVERALL VERDICT: {}`n", isHome ? "AT HOME VILLAGE (TRUE)" : "IN BATTLE / NOT HOME (FALSE)"))
    
    RefreshPreviewsAndVerdict()
}

ToggleLiveMonitoring() {
    global IsLiveMonitoring
    IsLiveMonitoring := !IsLiveMonitoring
    if IsLiveMonitoring {
        BtnLive.Text := "Stop Live Monitoring (F4)"
        LogToConsole("Live monitoring STARTED (inspecting every 500ms)...")
        SetTimer(RunInspectCycle, 500)
    } else {
        SetTimer(RunInspectCycle, 0)
        BtnLive.Text := "Start Live Monitoring (F4)"
        LogToConsole("Live monitoring STOPPED (background preview active).")
        SetTimer(RefreshPreviewsAndVerdict, 500)
    }
}

; ------------------------------------------------------------------------------
; Hotkey Handlers
; ------------------------------------------------------------------------------

F1:: RunInspectCycle()
F4:: ToggleLiveMonitoring()
