#Requires AutoHotkey v2
#Include OCR.ahk

SetTitleMatchMode 2

; ==============================================================================
; Builder Suggestions Dropdown OCR Visual Debugger
; ==============================================================================

global TargetWindowTitle := "Clash of Clans"
global BuilderFaceX := 960
global BuilderFaceY := 85
global ScaleFactor := 2.0
global CropWidthPct := 0.40
global CropHeightPct := 0.82
global CropTopPct := 0.10

global BuilderMenuBottomY := 800

if FileExist("config.ini") {
    iniTarget := Trim(IniRead("config.ini", "Settings", "TargetWindowTitle", ""))
    if (iniTarget != "")
        TargetWindowTitle := iniTarget
        
    iniFaceX := IniRead("config.ini", "Coordinates", "BuilderFaceX", "")
    if (iniFaceX != "" && IsNumber(iniFaceX))
        BuilderFaceX := Integer(iniFaceX)
        
    iniFaceY := IniRead("config.ini", "Coordinates", "BuilderFaceY", "")
    if (iniFaceY != "" && IsNumber(iniFaceY))
        BuilderFaceY := Integer(iniFaceY)
        
    iniBotY := IniRead("config.ini", "Coordinates", "BuilderMenuBottomY", "")
    if (iniBotY != "" && IsNumber(iniBotY))
        BuilderMenuBottomY := Integer(iniBotY)
}

; ------------------------------------------------------------------------------
; GUI Construction
; ------------------------------------------------------------------------------

MyGui := Gui("+Resize", "Clash of Clanker - Builder Suggestions Dropdown OCR Inspector")
MyGui.SetFont("s10", "Segoe UI")

; Row 1: Target Window & Header
MyGui.Add("Text", "x15 y14 w100 h25", "Target Window:")
EditTarget := MyGui.Add("Edit", "x120 y10 w220 h26 vEditTarget", TargetWindowTitle)
ChkTop := MyGui.Add("Checkbox", "x355 y14 w130 h25 vChkTop", "Always On Top")
StatusText := MyGui.Add("Text", "x500 y14 w200 h25 vStatusText Right cGray", "Status: Ready")

; Row 2: Controls & OCR Tuning
MyGui.Add("Text", "x15 y48 w75 h25", "Face X/Y:")
EditFaceX := MyGui.Add("Edit", "x95 y44 w65 h26 vEditFaceX Number", BuilderFaceX)
MyGui.Add("UpDown", "vSpinFaceX Range0-3840", BuilderFaceX)
EditFaceY := MyGui.Add("Edit", "x165 y44 w65 h26 vEditFaceY Number", BuilderFaceY)
MyGui.Add("UpDown", "vSpinFaceY Range0-2160", BuilderFaceY)

MyGui.Add("Text", "x245 y48 w75 h25", "OCR Scale:")
EditScale := MyGui.Add("Edit", "x320 y44 w55 h26 vEditScale", "2.0")

BtnSave := MyGui.Add("Button", "x470 y44 w110 h28", "Save Config")
BtnClear := MyGui.Add("Button", "x590 y44 w110 h28", "Clear Console")

; Row 3: Action Buttons
BtnOpenMenu := MyGui.Add("Button", "x15 y80 w160 h35", "Open Menu (ADB)")
BtnRunOCR   := MyGui.Add("Button", "x185 y80 w180 h35", "Run Dropdown OCR (F1)")

; GroupBox: Verdict Header
MyGui.Add("GroupBox", "x15 y125 w685 h75", "OCR Detection Verdict")
MyGui.SetFont("s15 Bold", "Segoe UI")
VerdictText := MyGui.Add("Text", "x30 y150 w655 h40 vVerdictText cBlue", "Verdict: UNKNOWN")
MyGui.SetFont("s10 Norm", "Segoe UI")

; GroupBox: Crop Image Preview
MyGui.Add("GroupBox", "x15 y210 w685 h240", "Builder Dropdown Menu OCR Crop (Green=Header, Cyan=First Upgrade Target)")
PicPreview := MyGui.Add("Picture", "x25 y235 w665 h205 +Border vPicPreview", "")

; GroupBox: Diagnostic Log
MyGui.Add("GroupBox", "x15 y460 w685 h200", "OCR Line Breakdown & Coordinates")
MyGui.SetFont("s9", "Consolas")
ConsoleEdit := MyGui.Add("Edit", "x25 y485 w665 h165 ReadOnly +VScroll +HScroll vConsoleEdit", "")
MyGui.SetFont("s10", "Segoe UI")

; Event Handlers
EditTarget.OnEvent("Change", (*) => UpdateTargetTitle(EditTarget.Value))
ChkTop.OnEvent("Click", (*) => ToggleAlwaysOnTop(ChkTop.Value))

EditFaceX.OnEvent("Change", (*) => OnCoordChange())
EditFaceY.OnEvent("Change", (*) => OnCoordChange())

BtnSave.OnEvent("Click", (*) => SaveConfigIni())
BtnOpenMenu.OnEvent("Click", (*) => OpenBuilderMenu())
BtnRunOCR.OnEvent("Click", (*) => RunDropdownOCR())
BtnClear.OnEvent("Click", (*) => ClearConsole())

MyGui.OnEvent("Close", (*) => ExitApp())
MyGui.Show("w715 h675")

LogToConsole("--- Builder Suggestions Dropdown OCR Inspector Initialized ---")
LogToConsole("Click 'Open Menu' to tap the Builder nose, then press F1 to run OCR!")

; ------------------------------------------------------------------------------
; Functions
; ------------------------------------------------------------------------------

UpdateTargetTitle(newTitle) {
    global TargetWindowTitle
    TargetWindowTitle := Trim(newTitle)
    if (TargetWindowTitle == "")
        TargetWindowTitle := "Clash of Clans"
}

ToggleAlwaysOnTop(isTop) {
    MyGui.Opt((isTop ? "+" : "-") "AlwaysOnTop")
}

OnCoordChange() {
    global BuilderFaceX, BuilderFaceY
    try {
        BuilderFaceX := Integer(EditFaceX.Value)
        BuilderFaceY := Integer(EditFaceY.Value)
    }
}

SaveConfigIni() {
    global TargetWindowTitle, BuilderFaceX, BuilderFaceY
    try {
        IniWrite(TargetWindowTitle, "config.ini", "Settings", "TargetWindowTitle")
        IniWrite(BuilderFaceX, "config.ini", "Coordinates", "BuilderFaceX")
        IniWrite(BuilderFaceY, "config.ini", "Coordinates", "BuilderFaceY")
        SoundBeep(1200, 150)
        LogToConsole("Saved BuilderFaceX/Y to config.ini!")
    } catch as err {
        LogToConsole("ERROR saving config: " err.Message)
    }
}

LogToConsole(msg) {
    timeStr := FormatTime(, "HH:mm:ss")
    ConsoleEdit.Value .= "[" timeStr "] " msg "`n"
    SendMessage(0x0115, 7, 0, ConsoleEdit)
}

ClearConsole() {
    ConsoleEdit.Value := ""
}

global ADBBuilderFaceX := 0
global ADBBuilderFaceY := 0

OpenBuilderMenu() {
    global TargetWindowTitle, BuilderFaceX, BuilderFaceY, ADBBuilderFaceX, ADBBuilderFaceY
    if !WinExist(TargetWindowTitle) {
        LogToConsole("ERROR: Target window not found!")
        return
    }
    
    ; Read ADBBuilderFaceX/Y from config if available
    if (ADBBuilderFaceX == 0 && FileExist("config.ini")) {
        iniADBFaceX := IniRead("config.ini", "ADBCoordinates", "BuilderFaceX", "")
        if (iniADBFaceX != "" && IsNumber(iniADBFaceX))
            ADBBuilderFaceX := Integer(iniADBFaceX)
            
        iniADBFaceY := IniRead("config.ini", "ADBCoordinates", "BuilderFaceY", "")
        if (iniADBFaceY != "" && IsNumber(iniADBFaceY))
            ADBBuilderFaceY := Integer(iniADBFaceY)
    }
    
    LogToConsole("Sending ADB tap & Client click to Builder Face...")
    
    if (ADBBuilderFaceX > 0 && ADBBuilderFaceY > 0) {
        cmd := Format("adb shell input tap {} {}", ADBBuilderFaceX, ADBBuilderFaceY)
        try {
            Run(A_ComSpec " /c " cmd, , "Hide")
            LogToConsole(Format("ADB Shell Tap sent: ({}, {})", ADBBuilderFaceX, ADBBuilderFaceY))
        }
    }
    
    if WinExist(TargetWindowTitle) {
        WinActivate(TargetWindowTitle)
        Sleep 200
        CoordMode "Mouse", "Client"
        Click(BuilderFaceX, BuilderFaceY)
        LogToConsole(Format("Client Click sent: ({}, {})", BuilderFaceX, BuilderFaceY))
    }
    
    Sleep 1200
    RunDropdownOCR()
}

SaveRegionWithBoxMarkers(x, y, w, h, filepath, headerBox, targetBox) {
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
    
    ; Green pen for Header
    pPenGreen := 0
    DllCall("gdiplus\GdipCreatePen1", "uint", 0xFF00FF00, "float", 3.0, "int", 2, "ptr*", &pPenGreen)
    ; Cyan pen for Target Upgrade Item
    pPenCyan := 0
    DllCall("gdiplus\GdipCreatePen1", "uint", 0xFF00FFFF, "float", 3.0, "int", 2, "ptr*", &pPenCyan)
    
    if (headerBox != "") {
        DllCall("gdiplus\GdipDrawRectangle", "ptr", pGraphics, "ptr", pPenGreen, "float", headerBox.x, "float", headerBox.y, "float", headerBox.w, "float", headerBox.h)
    }
    
    if (targetBox != "") {
        DllCall("gdiplus\GdipDrawRectangle", "ptr", pGraphics, "ptr", pPenCyan, "float", targetBox.x, "float", targetBox.y, "float", targetBox.w, "float", targetBox.h)
        ; Target click point crosshair inside box
        cx := targetBox.x + 50
        cy := targetBox.y + (targetBox.h / 2)
        DllCall("gdiplus\GdipDrawLine", "ptr", pGraphics, "ptr", pPenCyan, "float", cx - 10, "float", cy, "float", cx + 10, "float", cy)
        DllCall("gdiplus\GdipDrawLine", "ptr", pGraphics, "ptr", pPenCyan, "float", cx, "float", cy - 10, "float", cx, "float", cy + 10)
    }
    
    DllCall("gdiplus\GdipDeletePen", "ptr", pPenGreen)
    DllCall("gdiplus\GdipDeletePen", "ptr", pPenCyan)
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

RunDropdownOCR() {
    global TargetWindowTitle, BuilderFaceX, BuilderFaceY, BuilderMenuBottomY
    if !WinExist(TargetWindowTitle) {
        LogToConsole("ERROR: Target window '" TargetWindowTitle "' not found!")
        return
    }
    
    WinGetClientPos &cx, &cy, &w, &h, TargetWindowTitle
    topY := Max(0, BuilderFaceY)
    bottomY := (BuilderMenuBottomY > topY + 100) ? BuilderMenuBottomY : Integer(h * 0.85)
    
    menuLeft := BuilderFaceX - (w * 0.20)
    menuWidth := w * 0.42
    menuTop := topY
    menuHeight := bottomY - topY
    
    scrLeft := cx + menuLeft
    scrTop := cy + menuTop
    
    sc := IsNumber(EditScale.Value) ? Float(EditScale.Value) : 2.0
    LogToConsole(Format("Scanning rect: ({}, {}, {}, {}) @ Scale {}", Integer(scrLeft), Integer(scrTop), Integer(menuWidth), Integer(menuHeight), sc))
    
    try {
        result := OCR.FromRect(scrLeft, scrTop, menuWidth, menuHeight, {scale: sc})
        lines := result.Lines
        LogToConsole("--- OCR Lines Detected: " lines.Length " ---")
        
        suggested_idx := -1
        loop lines.Length {
            t := lines[A_Index].Text
            LogToConsole(Format("Line {:2d}: '{}'", A_Index, t))
            if (suggested_idx == -1) && (InStr(t, "ggested Upgr") || InStr(t, "ggested upgr") || InStr(t, "Suggested") || InStr(t, "gested")) {
                suggested_idx := A_Index
            }
        }
        
        headerBox := ""
        targetBox := ""
        
        if (suggested_idx != -1) {
            hLine := lines[suggested_idx]
            headerBox := {x: (hLine.x - scrLeft), y: (hLine.y - scrTop), w: hLine.w, h: hLine.h}
            LogToConsole(Format("FOUND 'Suggested upgrades' at Line {}", suggested_idx))
            
            if (suggested_idx < lines.Length) {
                tLine := lines[suggested_idx + 1]
                targetBox := {x: (tLine.x - scrLeft), y: (tLine.y - scrTop), w: tLine.w, h: tLine.h}
                
                clickClientX := (tLine.x + 50) - cx
                clickClientY := (tLine.y + (tLine.h / 2)) - cy
                
                is_hero := InStr(tLine.Text, "Queen") || InStr(tLine.Text, "King") || InStr(tLine.Text, "Warden") || InStr(tLine.Text, "Champion")
                
                VerdictText.Text := Format("FOUND: '{}' (Line {}) -> Click ({}, {})", tLine.Text, suggested_idx + 1, Integer(clickClientX), Integer(clickClientY))
                VerdictText.Opt("cGreen")
                
                LogToConsole(Format(">>> FIRST SUGGESTED ITEM: '{}' (Type: {})", tLine.Text, is_hero ? "Hero" : "Building"))
                LogToConsole(Format(">>> TARGET CLICK POINT: Client ({}, {})", Integer(clickClientX), Integer(clickClientY)))
            } else {
                VerdictText.Text := "Header found, but no item line below it!"
                VerdictText.Opt("cOrange")
            }
        } else {
            VerdictText.Text := "'Suggested upgrades' HEADER NOT FOUND"
            VerdictText.Opt("cRed")
            LogToConsole("WARNING: Could not find 'Suggested upgrades' header line!")
        }
        
        previewImgPath := A_ScriptDir "\scratch\builder_menu_marked.png"
        SaveRegionWithBoxMarkers(scrLeft, scrTop, menuWidth, menuHeight, previewImgPath, headerBox, targetBox)
        try PicPreview.Value := previewImgPath
        
    } catch as err {
        LogToConsole("ERROR in OCR: " err.Message)
    }
}

; Hotkeys
F1:: RunDropdownOCR()
