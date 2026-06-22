#Requires AutoHotkey v2.0
#include "OCR.ahk"
SetTitleMatchMode 2
winTitle := "Clash of Clans"

if !WinExist(winTitle) {
    MsgBox("Clash of Clans window not found.", "Error", "Iconx")
    ExitApp
}

WinActivate winTitle
WinWaitActive winTitle
WinGetClientPos(&cx, &cy, &cw, &ch, winTitle)

; Load coordinates from config.ini
GoldAreaX := Integer(IniRead("config.ini", "Coordinates", "GoldAreaX", 100))
GoldAreaY := Integer(IniRead("config.ini", "Coordinates", "GoldAreaY", 150))
GoldAreaW := Integer(IniRead("config.ini", "Coordinates", "GoldAreaW", 150))
GoldAreaH := Integer(IniRead("config.ini", "Coordinates", "GoldAreaH", 30))

ElixirAreaX := Integer(IniRead("config.ini", "Coordinates", "ElixirAreaX", 100))
ElixirAreaY := Integer(IniRead("config.ini", "Coordinates", "ElixirAreaY", 200))
ElixirAreaW := Integer(IniRead("config.ini", "Coordinates", "ElixirAreaW", 150))
ElixirAreaH := Integer(IniRead("config.ini", "Coordinates", "ElixirAreaH", 30))

MsgBox("Testing OCR. Make sure you are in matchmaking search (with clouds cleared) where the loot digits are visible, then press OK.")

; Test Gold OCR
goldScrX := cx + GoldAreaX
goldScrY := cy + GoldAreaY
goldResult := OCR.FromRect(goldScrX, goldScrY, GoldAreaW, GoldAreaH, {scale: 2})

; Test Elixir OCR
elixirScrX := cx + ElixirAreaX
elixirScrY := cy + ElixirAreaY
elixirResult := OCR.FromRect(elixirScrX, elixirScrY, ElixirAreaW, ElixirAreaH, {scale: 2})

MsgBox("Gold OCR result: '" goldResult.Text "'`nElixir OCR result: '" elixirResult.Text "'")
ExitApp
