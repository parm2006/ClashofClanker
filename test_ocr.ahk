#Requires AutoHotkey v2.0
#SingleInstance Force
#include "OCR.ahk"

SetTitleMatchMode 2
winTitle := "Clash of Clans"

; Create a sleek floating diagnostic GUI
ocrGui := Gui("+AlwaysOnTop +ToolWindow", "CoC OCR Multi-Scale Tester")
ocrGui.SetFont("s10", "Segoe UI")
ocrGui.Add("Text", "w450 vStatusText", "Press F2 to scan when Clash of Clans is active.")
ocrGui.Add("Edit", "w450 h400 ReadOnly vResultEdit", "")
btnScan := ocrGui.Add("Button", "w120 y+10", "Scan Now (F2)")
btnScan.OnEvent("Click", ScanOCR)

ocrGui.OnEvent("Close", (*) => ExitApp())
ocrGui.Show("NoActivate x20 y20") ; Position at top-left, don't steal focus

; Set up a conditional hotkey to scan when game or test GUI is active
#HotIf WinActive(winTitle) or WinActive("ahk_id " ocrGui.Hwnd)
F2::ScanOCR()
#HotIf

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
    
    ; Additional mappings for noisy backgrounds
    str := StrReplace(str, "b", "6")   ; lower‑case b often looks like 6
    str := StrReplace(str, "B", "8")   ; upper‑case B → 8
    str := StrReplace(str, "z", "2")   ; z → 2
    str := StrReplace(str, "Z", "2")   ; Z → 2
    str := StrReplace(str, "a", "4")   ; a → 4 (rare but helpful)
    str := StrReplace(str, "A", "4")
    
    ; If bullet character appears, treat as invalid
    if (InStr(str, "•"))
        return 0
    
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

ScanOCR(*) {
    global winTitle, ocrGui
    
    if !WinExist(winTitle) {
        ocrGui["StatusText"].Text := "Error: Clash of Clans window not found."
        return
    }
    
    ; Reload coordinates from config.ini dynamically on every scan
    try {
        GoldAreaX := SafeInteger(IniRead("config.ini", "Coordinates", "GoldAreaX", ""), 100)
        GoldAreaY := SafeInteger(IniRead("config.ini", "Coordinates", "GoldAreaY", ""), 150)
        GoldAreaW := SafeInteger(IniRead("config.ini", "Coordinates", "GoldAreaW", ""), 150)
        GoldAreaH := SafeInteger(IniRead("config.ini", "Coordinates", "GoldAreaH", ""), 30)
        
        ElixirAreaX := SafeInteger(IniRead("config.ini", "Coordinates", "ElixirAreaX", ""), 100)
        ElixirAreaY := SafeInteger(IniRead("config.ini", "Coordinates", "ElixirAreaY", ""), 200)
        ElixirAreaW := SafeInteger(IniRead("config.ini", "Coordinates", "ElixirAreaW", ""), 150)
        ElixirAreaH := SafeInteger(IniRead("config.ini", "Coordinates", "ElixirAreaH", ""), 30)
    } catch as err {
        ocrGui["StatusText"].Text := "Error reading config.ini: " . err.Message
        return
    }
    
    WinGetClientPos(&cx, &cy, &cw, &ch, winTitle)
    
    goldScrX := cx + GoldAreaX
    goldScrY := cy + GoldAreaY
    elixirScrX := cx + ElixirAreaX
    elixirScrY := cy + ElixirAreaY
    
    ocrGui["StatusText"].Text := "Scanning... Please wait."
    
    scales := [1, 1.5, 2, 2.5, 3, 4]
    
    ; Run multi-scale scan for Gold
    goldRaw := []
    goldRnd := []
    goldTexts := []
    for s in scales {
        try {
            resText := OCR.FromRect(goldScrX, goldScrY, GoldAreaW, GoldAreaH, {scale: s}).Text
            goldTexts.Push(resText)
            val := CleanNumber(resText)
            goldRaw.Push(val)
            goldRnd.Push(Round(val / 10000) * 10000)
        } catch as err {
            goldTexts.Push("ERROR: " . err.Message . "`r`nStack: " . err.Stack)
            goldRaw.Push(0)
            goldRnd.Push(0)
        }
    }
    
    ; Run multi-scale scan for Elixir
    elixirRaw := []
    elixirRnd := []
    elixirTexts := []
    for s in scales {
        try {
            resText := OCR.FromRect(elixirScrX, elixirScrY, ElixirAreaW, ElixirAreaH, {scale: s}).Text
            elixirTexts.Push(resText)
            val := CleanNumber(resText)
            elixirRaw.Push(val)
            elixirRnd.Push(Round(val / 10000) * 10000)
        } catch as err {
            elixirTexts.Push("ERROR: " . err.Message . "`r`nStack: " . err.Stack)
            elixirRaw.Push(0)
            elixirRnd.Push(0)
        }
    }
    
    ; Resolve Gold Mode
    goldFreq := Map()
    goldMax := 0
    goldBestRnd := 0
    for v in goldRnd {
        if (v == 0)
            continue
        freq := goldFreq.Has(v) ? goldFreq[v] + 1 : 1
        goldFreq[v] := freq
        if (freq > goldMax) {
            goldMax := freq
            goldBestRnd := v
        }
    }
    
    goldFinal := 0
    if (goldMax == 0) {
        goldFinal := 0
    } else if (goldMax == 1) {
        ; fallback to max raw
        for v in goldRaw {
            if (v > goldFinal)
                goldFinal := v
        }
    } else {
        for i, v in goldRnd {
            if (v == goldBestRnd && goldRaw[i] > goldFinal) {
                goldFinal := goldRaw[i]
            }
        }
    }
    
    ; Resolve Elixir Mode
    elixirFreq := Map()
    elixirMax := 0
    elixirBestRnd := 0
    for v in elixirRnd {
        if (v == 0)
            continue
        freq := elixirFreq.Has(v) ? elixirFreq[v] + 1 : 1
        elixirFreq[v] := freq
        if (freq > elixirMax) {
            elixirMax := freq
            elixirBestRnd := v
        }
    }
    
    elixirFinal := 0
    if (elixirMax == 0) {
        elixirFinal := 0
    } else if (elixirMax == 1) {
        ; fallback to max raw
        for v in elixirRaw {
            if (v > elixirFinal)
                elixirFinal := v
        }
    } else {
        for i, v in elixirRnd {
            if (v == elixirBestRnd && elixirRaw[i] > elixirFinal) {
                elixirFinal := elixirRaw[i]
            }
        }
    }
    
    ; Form output string
    out := "Coordinates (Client):`r`n"
    out .= "  Gold:   X:" . GoldAreaX . " Y:" . GoldAreaY . " W:" . GoldAreaW . " H:" . GoldAreaH . "`r`n"
    out .= "  Elixir: X:" . ElixirAreaX . " Y:" . ElixirAreaY . " W:" . ElixirAreaW . " H:" . ElixirAreaH . "`r`n`r`n"
    
    out .= "--- GOLD SCANS ---`r`n"
    for i, s in scales {
        out .= "Scale " . s . ": '" . goldTexts[i] . "' -> raw: " . goldRaw[i] . " -> rounded: " . goldRnd[i] . "`r`n"
    }
    out .= "Best Rounded Mode: " . goldBestRnd . " (Freq: " . goldMax . ")`r`n"
    out .= "Final Resolved GOLD: " . goldFinal . "`r`n`r`n"
    
    out .= "--- ELIXIR SCANS ---`r`n"
    for i, s in scales {
        out .= "Scale " . s . ": '" . elixirTexts[i] . "' -> raw: " . elixirRaw[i] . " -> rounded: " . elixirRnd[i] . "`r`n"
    }
    out .= "Best Rounded Mode: " . elixirBestRnd . " (Freq: " . elixirMax . ")`r`n"
    out .= "Final Resolved ELIXIR: " . elixirFinal . "`r`n"
    
    ocrGui["ResultEdit"].Value := out
    ocrGui["StatusText"].Text := "Scan completed at " . FormatTime(, "HH:mm:ss") . ". Press F2 to scan again."
}


