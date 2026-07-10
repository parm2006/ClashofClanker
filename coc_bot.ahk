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
global DeployDelta := 25
global TransitionDelay := 500
global BattleLoadDelay := 1500
global BBClickCount := 1
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
global MVLogoX := 100
global MVLogoY := 700
global MVLogoColor := 0x000000
; --- OCR Target Areas ---
global BuilderFaceX := 960
global BuilderFaceY := 30
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
; ==============================================================================
; STATE CONTROL
; ==============================================================================
global IsRunning := false
global IsBBRunning := false
global IsCalibrating := false
global IsBBCalibrating := false
global CalibStep := 0
global BBCalibStep := 0
global IsWaitingForReset := false
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
; Load configuration settings
LoadConfig()
; Initialize GUI
CreateGUI()
LogMessage("Bot initialized. Ready.")
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
    global MVLogoX, MVLogoY, MVLogoColor
    global BuilderFaceX, BuilderFaceY, UpgradeConfirmX, UpgradeConfirmY
    global GoldBarThreshX, GoldBarThreshY, ElixirBarThreshX, ElixirBarThreshY
    global GoldAreaX, GoldAreaY, GoldAreaW, GoldAreaH
    global ElixirAreaX, ElixirAreaY, ElixirAreaW, ElixirAreaH
    global NextMatchBtnX, NextMatchBtnY
    global UpgradeMoreBtnX, UpgradeMoreBtnY, AddWall1X, AddWall1Y, RemoveWallX, RemoveWallY, GoldUpgradeX, GoldUpgradeY, ElixirUpgradeX, ElixirUpgradeY
    global CloudPt1X, CloudPt1Y, CloudPt2X, CloudPt2Y, CloudPt3X, CloudPt3Y, CloudPt4X, CloudPt4Y, CloudGreyTolerance
    global CollectorCoords
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
    global BBSides
    TargetWindowTitle := IniRead("config.ini", "Settings", "TargetWindowTitle", "Clash of Clans")
    ButtonDelta := SafeInteger(IniRead("config.ini", "Settings", "ButtonDelta", ""), 5)
    DeployDelta := SafeInteger(IniRead("config.ini", "Settings", "DeployDelta", ""), 25)
    TransitionDelay := SafeInteger(IniRead("config.ini", "Settings", "TransitionDelay", ""), 500)
    BattleLoadDelay := SafeInteger(IniRead("config.ini", "Settings", "BattleLoadDelay", ""), 1500)
    BBClickCount := SafeInteger(IniRead("config.ini", "Settings", "BBClickCount", ""), 1)
    MinGold := SafeInteger(IniRead("config.ini", "Farming", "MinGold", ""), 500000)
    MinElixir := SafeInteger(IniRead("config.ini", "Farming", "MinElixir", ""), 500000)
    EnableLootSearch := IniRead("config.ini", "Farming", "EnableLootSearch", "1") == "1"
    EnableWallUpgrade := IniRead("config.ini", "Farming", "EnableWallUpgrade", "1") == "1"
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
    MVLogoX := SafeInteger(IniRead("config.ini", "Coordinates", "MVLogoX", ""), 100)
    MVLogoY := SafeInteger(IniRead("config.ini", "Coordinates", "MVLogoY", ""), 700)
    MVLogoColor := SafeInteger(IniRead("config.ini", "Coordinates", "MVLogoColor", ""), 0x000000)
    BuilderFaceX := SafeInteger(IniRead("config.ini", "Coordinates", "BuilderFaceX", ""), 960)
    BuilderFaceY := SafeInteger(IniRead("config.ini", "Coordinates", "BuilderFaceY", ""), 30)
    UpgradeConfirmX := SafeInteger(IniRead("config.ini", "Coordinates", "UpgradeConfirmX", ""), 960)
    UpgradeConfirmY := SafeInteger(IniRead("config.ini", "Coordinates", "UpgradeConfirmY", ""), 540)
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
}
SaveConfig() {
    global TargetWindowTitle, ButtonDelta, DeployDelta, TransitionDelay, BattleLoadDelay
    global MinGold, MinElixir, EnableLootSearch, EnableWallUpgrade, UpgradeConfirmX, UpgradeConfirmY
    global AttackBtnX, AttackBtnY, FindMatchBtnX, FindMatchBtnY, AttackStartBtnX, AttackStartBtnY
    global ReturnHomeClickX, ReturnHomeClickY, ReturnHomeColor, ReturnHomeTolerance
    global BBAttackBtnX, BBAttackBtnY, BBFindMatchBtnX, BBFindMatchBtnY
    global BBStar1X, BBStar1Y, BBStar2X, BBStar2Y, BBStar3X, BBStar3Y, BBStarColor
    global BuilderFaceX, BuilderFaceY, UpgradeConfirmX, UpgradeConfirmY
    global GoldBarThreshX, GoldBarThreshY, ElixirBarThreshX, ElixirBarThreshY
    global GoldAreaX, GoldAreaY, GoldAreaW, GoldAreaH
    global ElixirAreaX, ElixirAreaY, ElixirAreaW, ElixirAreaH
    global NextMatchBtnX, NextMatchBtnY
    global UpgradeMoreBtnX, UpgradeMoreBtnY, AddWall1X, AddWall1Y, RemoveWallX, RemoveWallY, GoldUpgradeX, GoldUpgradeY, ElixirUpgradeX, ElixirUpgradeY
    global CloudPt1X, CloudPt1Y, CloudPt2X, CloudPt2Y, CloudPt3X, CloudPt3Y, CloudPt4X, CloudPt4Y, CloudGreyTolerance
    global CollectorCoords
    global Troop1Count, Troop2Count, Troop3Count
    global Side1StartX, Side1StartY, Side1EndX, Side1EndY
    global Side2StartX, Side2StartY, Side2EndX, Side2EndY
    global Side3StartX, Side3StartY, Side3EndX, Side3EndY
    global Side4StartX, Side4StartY, Side4EndX, Side4EndY
    global BBSide1StartX, BBSide1StartY, BBSide1EndX, BBSide1EndY
    global BBSide2StartX, BBSide2StartY, BBSide2EndX, BBSide2EndY
    global BBSide3StartX, BBSide3StartY, BBSide3EndX, BBSide3EndY
    global BBSide4StartX, BBSide4StartY, BBSide4EndX, BBSide4EndY
    IniWrite(ButtonDelta, "config.ini", "Settings", "ButtonDelta")
    IniWrite(DeployDelta, "config.ini", "Settings", "DeployDelta")
    IniWrite(TransitionDelay, "config.ini", "Settings", "TransitionDelay")
    IniWrite(BattleLoadDelay, "config.ini", "Settings", "BattleLoadDelay")
    IniWrite(BBClickCount, "config.ini", "Settings", "BBClickCount")
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
    IniWrite(MVLogoX, "config.ini", "Coordinates", "MVLogoX")
    IniWrite(MVLogoY, "config.ini", "Coordinates", "MVLogoY")
    IniWrite(Format("0x{:06X}", MVLogoColor), "config.ini", "Coordinates", "MVLogoColor")
    IniWrite(BuilderFaceX, "config.ini", "Coordinates", "BuilderFaceX")
    IniWrite(BuilderFaceY, "config.ini", "Coordinates", "BuilderFaceY")
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
}
; ==============================================================================
; USER INTERFACE
; ==============================================================================
CreateGUI() {
    global MyGui, EditWindow, EditBattleLoad, EditButtonDelta, EditDeployDelta
    global EditMinGold, EditMinElixir, CheckLootSearch, CheckWallUpgrade, TextCollectorCount
    global LogEdit, StatusText, StartBtn, PauseBtn, CalibrationText, EditBBClickCount
    MyGui := Gui("+Resize +MinSize380x470", "CoC Bot Controller")
    ; Tab control
    Tab := MyGui.Add("Tab3", "w360 h440", ["Control", "Calibration", "Farming", "Settings"])
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
    MyGui.Add("GroupBox", "x20 y170 w320 h240", "Activity Log")
    LogEdit := MyGui.Add("Edit", "x30 y190 w300 h210 +ReadOnly +Multi +WantReturn", "")
    ; --- TAB 2: Calibration ---
    Tab.UseTab(2)
    MyGui.Add("Text", "x20 y35 w320 h40", "Click a button below or use its shortcut to calibrate coordinates relative to the game window.")
    CalibStartBtn := MyGui.Add("Button", "x20 y75 w150 h35", "Main Calib (^F1)")
    CalibStartBtn.OnEvent("Click", (*) => StartCalibration())
    CalibBBBtn := MyGui.Add("Button", "x180 y75 w150 h35", "BB Calib (^F2)")
    CalibBBBtn.OnEvent("Click", (*) => StartBBCalibration())
    CalibrationText := MyGui.Add("Text", "x20 y120 w320 h100 +Border", "Calibration is inactive.`n`nClick a start button to begin.")
    CalibrationText.SetFont("s10", "Segoe UI")
    MyGui.Add("Text", "x20 y230 w320 h195", "Instructions:`nHover mouse over target and press SPACE.`n`nMain Steps (26 total):`n1-3. Gold/Elixir Storage Bar, Builder Face (Home)`n4-8. Upgrade More, Add/Remove Wall, G/E Upgrade`n9-11. War Logo, Attack, Find Match (Menus)`n12-14. Green Attack, Loot Area G/E (Battle)`n15-23. Next Match, Sides 1-4 Start/End`n24. Return Home Button (Battle End)`n25. Collector Coordinates (Home - press ENTER).`n`nBB Steps (13 total):`n1-2. Attack, Find Match`n3-5. Star 1, 2, 3 Centers`n6-13. BB Sides 1-4 Start/End")
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
    MyGui.OnEvent("Close", (*) => ExitApp())
    MyGui.Show("w380 h470")
}
LogMessage(message) {
    global LogEdit
    if !LogEdit
        return
    timeStr := FormatTime(, "HH:mm:ss")
    currentText := LogEdit.Value
    lines := StrSplit(currentText, "`n")
    if lines.Length > 100 {
        newText := ""
        Loop 90 {
            newText .= lines[lines.Length - 90 + A_Index] "`n"
        }
        currentText := newText
    }
    LogEdit.Value := currentText . "[" timeStr "] " message "`r`n"
    SendMessage(0x0115, 7, 0, LogEdit) ; Scroll to bottom
}
ApplyAndSaveSettings() {
    global TargetWindowTitle, BattleLoadDelay, ButtonDelta, DeployDelta
    global MinGold, MinElixir, EnableLootSearch, EnableWallUpgrade, UpgradeConfirmX, UpgradeConfirmY
    global Troop1Count, Troop2Count, Troop3Count, BBClickCount
    global EditWindow, EditBattleLoad, EditButtonDelta, EditDeployDelta
    global EditMinGold, EditMinElixir, CheckLootSearch, CheckWallUpgrade
    global EditTroop1Count, EditTroop2Count, EditTroop3Count, EditBBClickCount
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
    SaveConfig()
    LogMessage("Settings saved successfully!")
    ShowToolTip("Settings saved!")
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
    global IsRunning, StatusText, StartBtn, PauseBtn, TargetWindowTitle
    if IsRunning {
        LogMessage("Bot is already running!")
        return
    }
    if !ActivateGameWindow() {
        MsgBox("Please ensure the game window '" TargetWindowTitle "' is open before starting.", "Error", "Iconx")
        return
    }
    IsRunning := true
    StatusText.Text := "STATUS: RUNNING"
    StatusText.SetFont("cGreen")
    StartBtn.Enabled := false
    PauseBtn.Enabled := true
    LogMessage("Bot loop started.")
    SetTimer(StartBotLoop, -10) ; Start asynchronously
}
PauseBot() {
    global IsRunning, IsBBRunning, StatusText, StartBtn, PauseBtn
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
    WinActivate(TargetWindowTitle)
    WinWaitActive(TargetWindowTitle,, 3)
    return true
}
EnsureWindowActive() {
    global TargetWindowTitle
    if !WinActive(TargetWindowTitle) {
        if WinExist(TargetWindowTitle) {
            WinActivate(TargetWindowTitle)
            if WinWaitActive(TargetWindowTitle,, 2) {
                return true
            }
        }
        return false
    }
    return true
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
        case 10:
            instructions := "Step 9/13: BB Side 2 (Bottom-Left) End`n`nHover mouse over ending point of bottom-left deployment line and press SPACE."
        case 11:
            instructions := "Step 10/13: BB Side 3 (Top-Left) Start`n`nHover mouse over starting point of top-left deployment line and press SPACE."
        case 12:
            instructions := "Step 11/13: BB Side 3 (Top-Left) End`n`nHover mouse over ending point of top-left deployment line and press SPACE."
        case 13:
            instructions := "Step 12/13: BB Side 4 (Top-Right) Start`n`nHover mouse over starting point of top-right deployment line and press SPACE."
        case 14:
            instructions := "Step 13/13: BB Side 4 (Top-Right) End`n`nHover mouse over ending point of top-right deployment line and press SPACE.`n`nPress ENTER to finish and save."
    }
    if (instructions != "") {
        CalibrationText.Value := instructions
        ToolTip(instructions "`n`nPress ESC to cancel.")
    }
}
FinishBBCalibration() {
    global IsBBCalibrating, BBCalibStep, CalibrationText
    IsBBCalibrating := false
    BBCalibStep := 0
    SaveConfig()
    CalibrationText.Value := "Builder Base Calibration complete and saved!"
    LogMessage("Builder Base Calibration finished successfully.")
    ToolTip("Calibration saved!")
    SetTimer () => ToolTip(), -3000
}
RunCollectorReset() {
    global CalibStep, IsCalibrating, IsWaitingForReset, CollectorCoords, CalibrationText
    if !IsCalibrating || CalibStep != 26
        return
    ResetViewport()
    IsWaitingForReset := false
    instructions := "Step 26/26: Resource Collectors (Home Screen)`n`nHover over a Gold Mine, Elixir Collector, or DE Drill and press SPACE to record.`n`nCurrently added: " CollectorCoords.Length "`n`nPlease don't move the screen.`n`nPress ENTER to finish and save."
    CalibrationText.Value := instructions
    ToolTip(instructions "`n`nPress ESC to cancel.")
}
RunSidesReset() {
    global CalibStep, IsCalibrating, IsWaitingForReset, CalibrationText
    if !IsCalibrating || CalibStep != 17
        return
    ResetViewport()
    IsWaitingForReset := false
    instructions := "Step 17/26: Side 1 (Bottom-Right) Start Point`n`nHover mouse over the starting point of the Bottom-Right deployment line and press SPACE."
    CalibrationText.Value := instructions
    ToolTip(instructions "`n`nPress ESC to cancel.")
}
UpdateCalibrationUI() {
    global CalibStep, CalibrationText, CollectorCoords, IsWaitingForReset
    instructions := ""
    switch CalibStep {
        case 1:
            instructions := "Step 1/26: Gold Storage Bar Threshold Point (Home Screen)`n`nHover over your Gold storage bar at the point where you want wall upgrades to trigger (e.g. 85% full) and press SPACE."
        case 2:
            instructions := "Step 2/26: Elixir Storage Bar Threshold Point (Home Screen)`n`nHover over your Elixir storage bar at the point where you want wall upgrades to trigger (e.g. 85% full) and press SPACE."
        case 3:
            instructions := "Step 3/26: Builder Face (Home Screen)`n`nHover mouse over the top-center Builder head icon and press SPACE."
        case 4:
            instructions := "Step 4/26: Upgrade More Button (Wall Selected)`n`nHover mouse over the 'Upgrade More' button (first select a wall manually to show it) and press SPACE."
        case 5:
            instructions := "Step 5/26: Add Wall (+1) Button (Upgrade More Screen)`n`nHover mouse over the '+1 Add Wall' button (click 'Upgrade More' manually to show it) and press SPACE."
        case 6:
            instructions := "Step 6/26: Remove Wall (-1) Button (Upgrade More Screen)`n`nHover mouse over the '-1 Remove Wall' button and press SPACE."
        case 7:
            instructions := "Step 7/26: Gold Upgrade Button (Upgrade More Screen)`n`nHover mouse over the Gold Upgrade button (showing the gold hammer/cost) and press SPACE."
        case 8:
            instructions := "Step 8/26: Elixir Upgrade Button (Upgrade More Screen)`n`nHover mouse over the Elixir Upgrade button (showing the purple hammer/cost) and press SPACE."
        case 10:
            instructions := "Step 10/26: War Logo (Home Screen)`n`nHover mouse over the War Logo (or any logo) directly ABOVE the Barbarian head / Attack button and press SPACE."
        case 11:
            instructions := "Step 11/26: Attack Button (Home Screen)`n`nHover mouse over the bottom-left brown 'Attack' button in your home village and press SPACE."
        case 12:
            instructions := "Step 12/26: Find Match Button (Multiplayer Dialog)`n`nHover mouse over the golden 'Find a Match' button (multiplayer tab) and press SPACE."
        case 13:
            instructions := "Step 13/26: Green 'Attack!' Start Button (My Army Dialog)`n`nHover mouse over the green 'Attack!' button (My Army dialog) and press SPACE."
        case 14:
            instructions := "Step 14/26: Multiplayer Gold Area (Matchmaking Search)`n`nHover mouse over the Gold count digits in a multiplayer match search and press SPACE."
        case 15:
            instructions := "Step 15/26: Multiplayer Elixir Area (Matchmaking Search)`n`nHover mouse over the Elixir count digits in a multiplayer match search and press SPACE."
        case 16:
            instructions := "Step 16/26: Next Match Button (Matchmaking Search)`n`nHover mouse over the 'Next' button in a multiplayer match search and press SPACE."
        case 17:
            IsWaitingForReset := true
            instructions := "Top-Left Screen Zoom-Out Calibration`n`nPlease Wait."
            SetTimer(RunSidesReset, -3000)
        case 18:
            instructions := "Step 18/26: Side 1 (Bottom-Right) End Point`n`nHover mouse over the ending point of the Bottom-Right deployment line and press SPACE."
        case 19:
            instructions := "Step 19/26: Side 2 (Bottom-Left) Start Point`n`nHover mouse over the starting point of the Bottom-Left deployment line and press SPACE."
        case 20:
            instructions := "Step 20/26: Side 2 (Bottom-Left) End Point`n`nHover mouse over the ending point of the Bottom-Left deployment line and press SPACE."
        case 21:
            instructions := "Step 21/26: Side 3 (Top-Left) Start Point`n`nHover mouse over the starting point of the Top-Left deployment line and press SPACE."
        case 22:
            instructions := "Step 22/26: Side 3 (Top-Left) End Point`n`nHover mouse over the ending point of the Top-Left deployment line and press SPACE."
        case 23:
            instructions := "Step 23/26: Side 4 (Top-Right) Start Point`n`nHover mouse over the starting point of the Top-Right deployment line and press SPACE."
        case 24:
            instructions := "Step 24/26: Side 4 (Top-Right) End Point`n`nHover mouse over the ending point of the Top-Right deployment line and press SPACE."
        case 25:
            instructions := "Step 25/26: Return Home Button (Battle End)`n`nHover mouse over the center of the green 'Return Home' button and press SPACE."
        case 26:
            if (CollectorCoords.Length == 0) {
                IsWaitingForReset := true
                instructions := "Top-Left Screen Zoom-Out Calibration`n`nPress Button and Please Wait."
                SetTimer(RunCollectorReset, -3000)
            } else {
                instructions := "Step 26/26: Resource Collectors (Home Screen)`n`nHover over a Gold Mine, Elixir Collector, or DE Drill and press SPACE to record.`n`nCurrently added: " CollectorCoords.Length "`n`nPlease don't move the screen.`n`nPress ENTER to finish and save."
            }
        default:
            instructions := "Calibration completed successfully!"
    }
    CalibrationText.Value := instructions
    ToolTip(instructions "`n`nPress ESC to cancel.")
}
FinishCalibration() {
    global IsCalibrating, CalibStep, TextCollectorCount, CollectorCoords, IsWaitingForReset
    IsCalibrating := false
    CalibStep := 0
    IsWaitingForReset := false
    SetTimer(RunCollectorReset, 0)
    SetTimer(RunSidesReset, 0)
    ToolTip()
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
    global TargetWindowTitle
    if !WinExist(TargetWindowTitle)
        return 0
    WinGetClientPos &cx, &cy,,, TargetWindowTitle
    scrX := cx + relX
    scrY := cy + relY
    scales := [1, 1.5, 2, 2.5, 3, 4]
    rawValues := []
    roundedValues := []
    logDetails := label . " OCR scans: "
    for scaleVal in scales {
        try {
            result := OCR.FromRect(scrX, scrY, relW, relH, {scale: scaleVal})
            cleaned := CleanNumber(result.Text)
            ; If CleanNumber returns 0 we consider this scan invalid and skip it
            if (cleaned > 0) {
                rounded := Round(cleaned / 10000) * 10000
                rawValues.Push(cleaned)
                roundedValues.Push(rounded)
                logDetails .= "[" . scaleVal . ": raw=" . cleaned . " rnd=" . rounded . "] "
            } else {
                ; Record that the scan gave no usable number – helpful for debugging noisy backgrounds
                logDetails .= "[" . scaleVal . ": empty] "
            }
        } catch as err {
            logDetails .= "[" . scaleVal . ": err=" . err.Message . "] "
        }
    }
    if (rawValues.Length == 0) {
        ; No scan produced a usable number – return 0 so the bot can decide to skip loot handling
        LogMessage(logDetails . " -> Final Result: 0 (no valid scans)")
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
        LogMessage(logDetails . " -> Final Result: " . bestRaw . " (no mode, fallback to max raw)")
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
    LogMessage(logDetails . " -> Best Rounded Mode: " . bestRounded . " -> Final Result: " . bestRaw)
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
        LogMessage("OCR Battle Troop Scan raw: '" result.Text "'")
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
    for idx, val in counts {
        if (val > 0) {
            activeCounts[idx] := val
            LogMessage(Format("Slot {} count overridden by OCR: {} (was {})", idx, val, [Troop1Count, Troop2Count, Troop3Count][idx]))
        } else {
            LogMessage(Format("Slot {} count using fallback: {}", idx, activeCounts[idx]))
        }
    }
    return activeCounts
}
IsGoldBarFilled(x, y) {
    CoordMode "Pixel", "Client"
    if !EnsureWindowActive()
        return false
    try {
        color := PixelGetColor(x, y)
        actualHex := Integer(color)
        r := (actualHex >> 16) & 0xFF
        g := (actualHex >> 8) & 0xFF
        b := actualHex & 0xFF
        ; Yellow/Gold color signature: high R and G, lower B
        ; Made extremely lenient: Red and Green just need to be noticeably higher than Blue
        return (r > 120) && (g > 100) && (r > b + 20) && (g > b + 10)
    }
    catch {
        return false
    }
}
IsElixirBarFilled(x, y) {
    CoordMode "Pixel", "Client"
    if !EnsureWindowActive()
        return false
    try {
        color := PixelGetColor(x, y)
        actualHex := Integer(color)
        r := (actualHex >> 16) & 0xFF
        g := (actualHex >> 8) & 0xFF
        b := actualHex & 0xFF
        ; Loose RGB bounds for "pink" as requested
        isPink := (r >= 180) && (g >= 80 && g <= 220) && (b >= 100 && b <= 230)
        isPink := isPink && (r > g) && (r >= b * 0.75)
        isPink := isPink && ((r + g + b) / 3 > 140)
        ; Fallback for transparent UI over dark background
        isDarkPink := (r > 120) && (b > 100) && (r > g + 20)
        return isPink || isDarkPink
    }
    catch {
        return false
    }
}
GetBuilderCount(&free, &total) {
    global BuilderFaceX, BuilderFaceY, UpgradeConfirmX, UpgradeConfirmY, TargetWindowTitle
    free := 0
    total := 0
    if !WinExist(TargetWindowTitle)
        return false
    WinGetClientPos &cx, &cy,,, TargetWindowTitle
    scrX := cx + BuilderFaceX - 30
    scrY := cy + BuilderFaceY - 15
    scrW := 130
    scrH := 30
    scales := [3.5, 3.0, 2.5, 2.0, 1.5]
    for sc in scales {
        try {
            result := OCR.FromRect(scrX, scrY, scrW, scrH, {scale: sc})
            text := StrReplace(result.Text, " ", "")
            LogMessage("Builder OCR (scale " sc ") raw text: '" text "'")
            if RegExMatch(text, "(\d)[/|iI1\-:.](\d)", &match) {
                free := Integer(match[1])
                total := Integer(match[2])
                LogMessage(Format("Builder OCR parsed: {}/{} (using scale {})", free, total, sc))
                return true
            }
        }
        catch as err {
            LogMessage("Builder OCR error: " err.Message)
        }
    }
    return false
}
AreBuildersBusy() {
    ; TODO: Re-enable Builder count OCR later when calibration / screen issue is resolved
    ; free := 0
    ; total := 0
    ; if GetBuilderCount(&free, &total) {
    ;     if (total == 7) {
    ;         return free < 2
    ;     }
    ;     if (total <= 6 && total > 0) {
    ;         return free < 1
    ;     }
    ; }
    ; LogMessage("Farming: Builder count OCR failed or invalid. Assuming busy to prevent accidental gem spending.")
    ; return true
    ; Temporarily assume we always have an available builder
    return false
}
FindCenterGreenButton(&outX, &outY) {
    global TargetWindowTitle
    if !EnsureWindowActive()
        return false
    WinGetClientPos &cx, &cy, &w, &h, TargetWindowTitle
    searchX := cx + (w * 0.3)
    searchY := cy + (h * 0.4)
    searchW := w * 0.4
    searchH := h * 0.4
    ; Scan a grid in the center area for the signature green color
    loop 20 {
        dy := searchY + (A_Index * (searchH / 20))
        loop 20 {
            dx := searchX + (A_Index * (searchW / 20))
            c := PixelGetColor(dx, dy)
            actualHex := Integer(c)
            r := (actualHex >> 16) & 0xFF
            g := (actualHex >> 8) & 0xFF
            b := actualHex & 0xFF
            if (g > r + 30) && (g > b + 30) && (g > 100) {
                outX := dx
                outY := dy
                return true
            }
        }
    }
    return false
}
ProcessWallUpgrade(upgradeX, upgradeY, resourceType) {
    global AddWall1X, AddWall1Y, RemoveWallX, RemoveWallY, ReturnHomeClickX, ReturnHomeClickY
    global GoldBarThreshX, GoldBarThreshY, ElixirBarThreshX, ElixirBarThreshY
    wallCount := 4
    ; First, add 3 walls to reach the maximum 4
    Loop 3 {
        ClickPoint(AddWall1X, AddWall1Y)
        if !SafeSleep(200)
            return false
    }
    Loop 4 {
        LogMessage(Format("Farming: Attempting to upgrade {} wall(s)...", wallCount))
        ClickPoint(upgradeX, upgradeY)
        if !SafeSleep(1500) ; Wait for confirmation popup
            return false
        ; 1. First, click the GREEN "Okay" confirmation button in the center
        if FindCenterGreenButton(&gx, &gy) {
            LogMessage("Farming: Clicking green Okay confirmation button...")
            ClickPoint(gx + 15, gy + 15) ; Offset to ensure we click inside the button, not just the edge
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
                    ClickPoint(ReturnHomeClickX, ReturnHomeClickY) ; Dismiss Gem popup
                    SafeSleep(500)
                    break
                }
                LogMessage("Farming: Upgrade too expensive (Gem popup detected). Removing one wall...")
                ClickPoint(ReturnHomeClickX, ReturnHomeClickY) ; Dismiss Gem popup
                if !SafeSleep(800)
                    return false
                ClickPoint(RemoveWallX, RemoveWallY) ; Remove one wall
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
    ClickPoint(ReturnHomeClickX, ReturnHomeClickY)
    SafeSleep(500)
    return true
}
CollectResources() {
    global CollectorCoords, IsRunning
    if (CollectorCoords.Length == 0)
        return
    ; If you ever want to make this run 100% of the time, change this to Random(1, 1)
    ; DO NOT completely remove this random block!
    roll := Random(1, 40)
    if (roll != 1) {
        LogMessage("Farming: Skipping resource collection this cycle (Rolled " roll "/40, needs 1).")
        return
    }
    LogMessage("Farming: Collecting resources from " CollectorCoords.Length " mines/collectors...")
    for coord in CollectorCoords {
        if !IsRunning
            break
        ClickPoint(coord.x, coord.y)
        SafeSleep(250)
    }
}
FindAnyWallInDropdown() {
    global BuilderFaceX, BuilderFaceY, UpgradeConfirmX, UpgradeConfirmY, TargetWindowTitle
    WinGetClientPos &cx, &cy, &w, &h, TargetWindowTitle
    menuLeft := BuilderFaceX - (w * 0.18)
    menuWidth := w * 0.36
    menuTop := h * 0.12
    menuHeight := h * 0.75
    scrLeft := cx + menuLeft
    scrTop := cy + menuTop
    CoordMode "Mouse", "Client"
    MouseMove BuilderFaceX, BuilderFaceY + 150
    Sleep 200
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
                        ClickPoint(relX, relY, 2) ; Use a tiny delta of 2 to avoid clicking through transparent background
                        return true
                    }
                }
            }
            catch as err {
                LogMessage("Farming: OCR error in suggestions dropdown: " err.Message)
            }
        }
        ; If we didn't find it, scroll down and search again
        Loop 4 {
            Click "WheelDown"
            Sleep 150
        }
        Sleep 800
    }
    return false
}
UpgradeWalls() {
    global EnableWallUpgrade, IsRunning, TargetWindowTitle
    global BuilderFaceX, BuilderFaceY, UpgradeConfirmX, UpgradeConfirmY, ReturnHomeClickX, ReturnHomeClickY
    CoordMode "Mouse", "Client"
    global UpgradeMoreBtnX, UpgradeMoreBtnY
    global GoldUpgradeX, GoldUpgradeY, ElixirUpgradeX, ElixirUpgradeY
    global GoldBarThreshX, GoldBarThreshY, ElixirBarThreshX, ElixirBarThreshY
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
    if AreBuildersBusy() {
        LogMessage("Farming: All builders are busy. Skipping wall upgrade.")
        return
    }
    ; --- 2. Elixir Wall Upgrade (Prioritized) ---
    if runElixirUpgrade {
        LogMessage("Farming: Elixir threshold met! Selecting a wall for Elixir upgrade...")
        ClickPoint(BuilderFaceX, BuilderFaceY)
        if !SafeSleep(800)
            return
        if EnsureWindowActive() {
            if FindAnyWallInDropdown() {
                if !SafeSleep(5000)
                    return
                ClickPoint(UpgradeMoreBtnX, UpgradeMoreBtnY)
                if !SafeSleep(800)
                    return
                ProcessWallUpgrade(ElixirUpgradeX, ElixirUpgradeY, "elixir")
            } else {
                LogMessage("Farming: No Wall upgrades found in builder suggestions.")
                ClickPoint(ReturnHomeClickX, ReturnHomeClickY)
                SafeSleep(500)
            }
        }
    }
    ; --- 3. Gold Wall Upgrade ---
    if runGoldUpgrade {
        LogMessage("Farming: Gold bar threshold met! Selecting a wall for Gold upgrade...")
        ClickPoint(BuilderFaceX, BuilderFaceY)
        if !SafeSleep(800)
            return
        if EnsureWindowActive() {
            if FindAnyWallInDropdown() {
                if !SafeSleep(5000)
                    return
                ClickPoint(UpgradeMoreBtnX, UpgradeMoreBtnY)
                if !SafeSleep(800)
                    return
                ProcessWallUpgrade(GoldUpgradeX, GoldUpgradeY, "gold")
            } else {
                LogMessage("Farming: No Wall upgrades found in builder suggestions.")
                ClickPoint(ReturnHomeClickX, ReturnHomeClickY)
                SafeSleep(500)
            }
        }
    }
}
IsReturnHomePresent() {
    global ReturnHomeClickX, ReturnHomeClickY, ReturnHomeColor, ReturnHomeTolerance
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
                ClickPoint(relX, relY)
            } else {
                LogMessage("Farming: No specific button text detected, clicking screen center fallback...")
                ClickPoint(w // 2, Integer(h * 0.55))
            }
            Sleep 10000 ; Wait 10 seconds for game to reload
        }
    }
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
FindTemplateUpgradeButton(hwnd, &outX, &outY) {
    WinGetClientPos &cx, &cy, &w, &h, hwnd
    ; Define crop region for the bottom menu (FULL WIDTH)
    scrLeft := cx
    scrTop := cy + Integer(h * 0.65)
    scrW := w
    scrH := Integer(h * 0.35)
    image_path := A_ScriptDir "\current_upgrade_area.png"
    SaveRegionToPNG(scrLeft, scrTop, scrW, scrH, image_path)
    cmd := 'python "' A_ScriptDir '\upgrade_button_hook.py" "' image_path '" ' h
    shell := ComObject("WScript.Shell")
    exec := shell.Exec(cmd)
    while !exec.Status {
        Sleep(50)
    }
    output := Trim(exec.StdOut.ReadAll())
    if RegExMatch(output, "SUCCESS:\s*(\d+)/(\d+)", &match) {
        match_x := Integer(match[1])
        match_y := Integer(match[2])
        outX := scrLeft + match_x
        outY := scrTop + match_y
        return true
    }
    return false
}
UpgradeBuilding() {
    global TargetWindowTitle, BuilderFaceX, BuilderFaceY, UpgradeConfirmX, UpgradeConfirmY
    hwnd := WinExist(TargetWindowTitle)
    if !hwnd
        return false
    LogMessage("Farming: Opening Builder suggestions menu...")
    ClickPoint(BuilderFaceX, BuilderFaceY)
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
    ClickPoint(clickX, clickY)
    Sleep 2000 ; 2-second camera settle delay
    if is_hero {
        ; Hero upgrade flow: skip Upgrade button, go straight to confirm
        LogMessage("Farming: Hero detected. Clicking calibrated confirmation button...")
        ClickPoint(UpgradeConfirmX, UpgradeConfirmY)
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
            ClickPoint(clickBtnX, clickBtnY)
            Sleep 1200
            ; Click calibrated confirmation button directly
            LogMessage(Format("Farming: Clicking calibrated confirmation button at client {}, {}", UpgradeConfirmX, UpgradeConfirmY))
            ClickPoint(UpgradeConfirmX, UpgradeConfirmY)
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
    global Sides, Troop1Count, Troop2Count, Troop3Count
    ; Check for game timeout immediately before doing anything else
    LastTimeoutCheck := A_TickCount
    CheckGameTimeout(true)
    ; Perform a screen-relative focus click in the right-middle grass area of the game window
    if WinExist(TargetWindowTitle) {
        WinGetClientPos &cx, &cy, &cw, &ch, TargetWindowTitle
        safeScrX := cx + (cw * 8) // 10
        safeScrY := cy + (ch * 3) // 10
        LogMessage(Format("Performing initial screen-relative focus click at {}, {}...", safeScrX, safeScrY))
        CoordMode "Mouse", "Screen"
        Click safeScrX, safeScrY
        CoordMode "Mouse", "Client"
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
        ; Collector resource farming (1 in 2 chance for testing)
        CollectResources()
        if !IsRunning
            break
        ; Building upgrades farming (triggered if there is a free builder and both storages are above threshold)
        if !AreBuildersBusy() {
            if IsGoldBarFilled(GoldBarThreshX, GoldBarThreshY) && IsElixirBarFilled(ElixirBarThreshX, ElixirBarThreshY) {
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
        ClickPoint(AttackBtnX, AttackBtnY)
        ; Wait up to 3 seconds for the Attack menu to open (IsAtHomeVillage becomes false)
        menuOpened := false
        Loop 15 {
            if !SafeSleep(200)
                break
            if !IsAtHomeVillage() {
                menuOpened := true
                break
            }
        }
        if !menuOpened {
            LogMessage("WARNING: Attack menu failed to open. Retrying...")
            continue
        }
        ; Step 2: Click the gold "Find a Match" button (from Multiplayer dialog)
        LogMessage("Step 2: Clicking Find a Match...")
        ClickPoint(FindMatchBtnX, FindMatchBtnY)
        if !SafeSleep(1000) ; Wait for My Army dialog to open fully
            break
        ; Step 3: Click the green "Attack!" button (from My Army dialog)
        LogMessage("Step 3: Clicking Green Attack...")
        ClickPoint(AttackStartBtnX, AttackStartBtnY)
        if !SafeSleep(1500) ; Wait for clouds transition to start
            break
        ; Verify we successfully left the Home Village (menus didn't get stuck)
        if IsAtHomeVillage() {
            LogMessage("WARNING: Failed to enter matchmaking search. Menu click missed. Retrying...")
            continue
        }
    WaitForClouds:
        ; Step 4: Wait for Clouds screen to end
        LogMessage("Step 4: Waiting for match / clouds to clear...")
        while AreCloudsPresent() {
            if !SafeSleep(250)
                goto LoopExit
            CheckGameTimeout()
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
        side := Sides[sideIndex]
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
                ClickPoint(NextMatchBtnX, NextMatchBtnY)
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
        DeploySingleLine("a", 32, aLineStartX, aLineStartY, aLineEndX, aLineEndY, 750)
        DeploySingleLine("s", 5, aLineStartX, aLineStartY, aLineEndX, aLineEndY, 750)
        if !IsRunning
            break
        ; Step 6: Wait for battle to progress, then check Return Home
        LogMessage("Step 6: Battle in progress... waiting 30s")
        if !SafeSleep(30000)
            break
        LogMessage("Step 6: Periodically checking for Return Home...")
        while !IsAtHomeVillage() {
            if !IsRunning
                goto LoopExit
            ClickPoint(ReturnHomeClickX, ReturnHomeClickY)
            if !SafeSleep(2000)
                goto LoopExit
            ; Unconditionally click where the Star Bonus "Okay" button would be
            WinGetClientPos ,, &cw, &ch, TargetWindowTitle
            if (cw && ch) {
                ClickPoint(cw // 2, Integer(ch * 0.77))
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
; ==============================================================================
; HELPER FUNCTIONS
; ==============================================================================
ClearingClick() {
    global TargetWindowTitle
    if EnsureWindowActive() {
        WinGetClientPos ,, &cw, &ch, TargetWindowTitle
        safeX := (cw * 8) // 10
        safeY := (ch * 3) // 10
        ClickPoint(safeX, safeY)
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
RandomClick(x, y, delta) {
    CoordMode "Mouse", "Client"
    if !EnsureWindowActive()
        return
    rx := x + Random(-delta, delta)
    ry := y + Random(-delta, delta)
    Click rx, ry
}
ClickPoint(x, y, delta := "") {
    global ButtonDelta
    if (delta == "")
        delta := ButtonDelta
    CoordMode "Mouse", "Client"
    if !EnsureWindowActive()
        return
    RandomClick(x, y, delta)
    Sleep 100
}
SendKey(keyName) {
    SendEvent "{" keyName " Down}"
    Sleep 50
    SendEvent "{" keyName " Up}"
    Sleep 50
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
        RandomClick(rx, ry, DeployDelta)
        if !SafeSleep(delayMs)
            break
    }
    SafeSleep(300)
}
DeploySinglePoint(hotkeyName, x, y) {
    global IsRunning, DeployDelta
    if !IsRunning
        return
    SendEvent "{" hotkeyName " Down}"
    Sleep 150
    SendEvent "{" hotkeyName " Up}"
    if !SafeSleep(350)
        return
    RandomClick(x, y, DeployDelta)
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
        RandomClick(rx, ry, DeployDelta)
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
    try {
        c := PixelGetColor(x, y)
        hx := Integer(c)
        r := (hx >> 16) & 0xFF
        g := (hx >> 8) & 0xFF
        b := hx & 0xFF
        ; Must have enough red/green (gold) and be distinctly not grey
        return (r > 120) && (r > b + 40) && (g > b + 20)
    } catch {
        return false
    }
}
AreCloudsPresent() {
    global CloudPt1X, CloudPt1Y, CloudPt2X, CloudPt2Y, CloudPt3X, CloudPt3Y, CloudPt4X, CloudPt4Y, CloudGreyTolerance
    if !EnsureWindowActive()
        return false
    greyCount := 0
    if IsGrey(CloudPt1X, CloudPt1Y, CloudGreyTolerance)
        greyCount++
    if IsGrey(CloudPt2X, CloudPt2Y, CloudGreyTolerance)
        greyCount++
    if IsGrey(CloudPt3X, CloudPt3Y, CloudGreyTolerance)
        greyCount++
    if IsGrey(CloudPt4X, CloudPt4Y, CloudGreyTolerance)
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
        return (Abs(r - g) <= tolerance) && (Abs(g - b) <= tolerance) && (Abs(r - b) <= tolerance)
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
    global AttackBtnX, AttackBtnY, MVLogoColor
    if !EnsureWindowActive()
        return false
    ; Use the original OR logic to be lenient and catch the orange button edge
    isHome := IsBrown(AttackBtnX - 45, AttackBtnY) || IsBrown(AttackBtnX + 45, AttackBtnY)
    if !isHome
        return false
    ; Double-check after 300ms to ensure it's a static UI element, not a moving troop/explosion
    Sleep 300
    isHome := IsBrown(AttackBtnX - 45, AttackBtnY) || IsBrown(AttackBtnX + 45, AttackBtnY)
    if !isHome
        return false
    ; To prevent false-positives on the Battle End screen's brown background, require the MVLogo if calibrated
    if (MVLogoColor != 0x000000) {
        if !IsMVLogoPresent()
            return false
    }
    return true
}
IsMVLogoPresent() {
    global MVLogoX, MVLogoY, MVLogoColor
    if !EnsureWindowActive()
        return false
    if (MVLogoColor == 0x000000) {
        LogMessage("WARNING: Main Village Logo uncalibrated! Please run Ctrl+F1 calibration.")
        return false ; Uncalibrated, fail safe
    }
    return ColorMatches(MVLogoX, MVLogoY, MVLogoColor, 35)
}
IsAtBuilderBase() {
    global BBAttackBtnX, BBAttackBtnY
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
    ; Phase 1 deploys Hero (Q) and slots 1-6. Phase 2 deploys Hero (Q) and slots 1-8.
    keys := (phase == 1) ? ["q", "1", "2", "3", "4", "5", "6"] : ["q", "1", "2", "3", "4", "5", "6", "7", "8"]
    for key in keys {
        SendKey(key)
        SafeSleep(175)
        clickCount := BBClickCount
        Loop clickCount {
            t := (clickCount > 1) ? (A_Index - 1) / (clickCount - 1) : 0
            shiftedStart := ShiftPointTowardsCenter(side.startX, side.startY, 30)
            shiftedEnd := ShiftPointTowardsCenter(side.endX, side.endY, 30)
            rx := shiftedStart.x + t * (shiftedEnd.x - shiftedStart.x)
            ry := shiftedStart.y + t * (shiftedEnd.y - shiftedStart.y)
            ; Safety clamp: Ensure deployment clicks never go too low into the bottom UI (troop bar/abilities/boost potions)
            ry := Min(ry, 900)
            RandomClick(rx, ry, DeployDelta)
            SafeSleep(100)
        }
    }
}
RunBuilderBaseLoop() {
    global IsBBRunning, TransitionDelay, BattleLoadDelay, ReturnHomeClickX, ReturnHomeClickY
    global BBAttackBtnX, BBAttackBtnY, BBFindMatchBtnX, BBFindMatchBtnY, Sides
    LogMessage("--- Starting Builder Base Loop ---")
    while IsBBRunning {
        LogMessage("Step 1: Clicking BB Attack Button")
        ClickPoint(BBAttackBtnX, BBAttackBtnY)
        if !SafeSleep(TransitionDelay)
            break
        LogMessage("Step 2: Clicking BB Find Match")
        ClickPoint(BBFindMatchBtnX, BBFindMatchBtnY)
        if !SafeSleep(TransitionDelay)
            break
        LogMessage("Step 3: Waiting for clouds...")
        cloudWaitCount := 0
        while (!AreCloudsPresent()) {
            if !SafeSleep(500)
                goto BBLoopExit
            cloudWaitCount++
            if (cloudWaitCount > 20)
                break
        }
        LogMessage("Step 4: Waiting for battle to load...")
        while (AreCloudsPresent()) {
            if !SafeSleep(500)
                goto BBLoopExit
            CheckGameTimeout()
        }
        ; Deduct 10s from BattleLoadDelay to start faster, minimum 100ms
        actualLoadDelay := (BattleLoadDelay > 10000) ? (BattleLoadDelay - 10000) : 100
        if !SafeSleep(actualLoadDelay)
            break
        ; Pick random side
        sideIdx := Random(1, 4)
        chosenSide := BBSides[sideIdx]
        LogMessage("Step 5: Picked Side " sideIdx " for BB deployment.")
        ZoomOutBB()
        DeployBBTroops(chosenSide, 1)
        LogMessage("Step 6: Phase 1 battle running. Monitoring for 3-stars or early finish...")
        waitTimer := 0
        threeStars := false
        while (waitTimer < 900) { ; 900 * 200ms = 180 seconds
            if !IsBBRunning
                goto BBLoopExit
            if IsGolden(BBStar3X, BBStar3Y) {
                threeStars := true
                break
            }
            if IsReturnHomePresent() {
                LogMessage("Phase 1 finished early (Return Home detected).")
                break
            }
            if !SafeSleep(200)
                goto BBLoopExit
            waitTimer++
        }
        if !threeStars {
            LogMessage("Step 6.5: Phase 1 might be running or finished. Periodically checking...")
            waitTimerPost := 0
            while (waitTimerPost < 12) { ; Check for up to 180 seconds (12 * 15s)
                if !IsBBRunning
                    goto BBLoopExit
                ; Check if we achieved 3 stars while waiting
                if IsGolden(BBStar3X, BBStar3Y) {
                    threeStars := true
                    LogMessage("Safeguard: 3 stars detected during post-check. Switching to Phase 2!")
                    break
                }
                ; Check if we are already back at the Builder Base (battle ended and we returned home)
                if IsAtBuilderBase() {
                    LogMessage("Returned to Builder Base during post-check.")
                    break
                }
                ; Click Return Home
                LogMessage("Clicking Return Home...")
                ClickPoint(ReturnHomeClickX, ReturnHomeClickY)
                if !SafeSleep(2000)
                    goto BBLoopExit
                ; Unconditionally click Okay to dismiss popups
                WinGetClientPos ,, &cw, &ch, TargetWindowTitle
                if (cw && ch) {
                    ClickPoint(cw // 2, Integer(ch * 0.77))
                    SafeSleep(400)
                }
                ClearingClick()
                if IsAtBuilderBase()
                    break
                CheckGameTimeout()
                ; Instead of sleeping 13 seconds all at once, sleep in 200ms chunks and check for 3 stars!
                loopCount := 13000 // 200
                Loop loopCount {
                    if !IsBBRunning
                        goto BBLoopExit
                    if IsGolden(BBStar3X, BBStar3Y) {
                        threeStars := true
                        LogMessage("Safeguard: 3 stars detected during post-check delay! Switching to Phase 2.")
                        break 2
                    }
                    if !SafeSleep(200)
                        goto BBLoopExit
                }
                if threeStars
                    break
                waitTimerPost++
            }
        }
        if threeStars {
            LogMessage("Step 7: 3 stars detected! Waiting 30s for troops to walk to 2nd base...")
            if !SafeSleep(30000)
                goto BBLoopExit
            LogMessage("Phase 2 starting. Deploying on Side " sideIdx)
            ZoomOutBB()
            DeployBBTroops(chosenSide, 2)
            LogMessage("Step 8: Phase 2 battle running. Monitoring for Return Home...")
            waitTimer2 := 0
            while (waitTimer2 < 180) {
                if !IsBBRunning
                    goto BBLoopExit
                if IsReturnHomePresent() {
                    LogMessage("Phase 2 finished (Return Home detected).")
                    break
                }
                if !SafeSleep(1000)
                    goto BBLoopExit
                waitTimer2++
            }
        }
        LogMessage("Step 9: Battle Over. Clicking Return Home.")
        ClickPoint(ReturnHomeClickX, ReturnHomeClickY)
        if !SafeSleep(5000)
            goto BBLoopExit
        LogMessage("Step 10: Waiting to return to Builder Base...")
        if !SafeSleep(2000)
            break
        while !IsAtBuilderBase() {
            if !IsBBRunning
                goto BBLoopExit
            ClickPoint(ReturnHomeClickX, ReturnHomeClickY)
            if !SafeSleep(2000)
                goto BBLoopExit
            ; Unconditionally click where the Star Bonus "Okay" button would be
            WinGetClientPos ,, &cw, &ch, TargetWindowTitle
            if (cw && ch) {
                ClickPoint(cw // 2, Integer(ch * 0.77))
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
}
MouseDragClient(x1, y1, x2, y2, speed := 15) {
    CoordMode "Mouse", "Client"
    MouseMove x1, y1, 0
    Sleep 80
    Click "Down"
    Sleep 80
    MouseMove x2, y2, speed
    Sleep 80
    Click "Up"
    Sleep 100
}
ResetViewport() {
    if !EnsureWindowActive()
        return
    CoordMode "Mouse", "Client"
    WinGetClientPos ,, &w, &h, TargetWindowTitle
    if (w && h) {
        safeX := (w * 8) // 10
        safeY := (h * 3) // 10
        LogMessage(Format("Viewport: Clicking to lock window focus at client {}, {}...", safeX, safeY))
        Click safeX, safeY
        Sleep 300
    }
    LogMessage("Viewport: Zooming all the way out...")
    Loop 25 {
        Send "^{WheelDown}"
        Sleep 40
    }
    Sleep 300
    LogMessage("Viewport: Scrolling to top-left corner...")
    if (w && h) {
        cx := w // 2
        cy := h // 2
        Loop 6 {
            if !IsRunning && !IsCalibrating
                break
            MouseDragClient(cx - (w * 0.25), cy - (h * 0.25), cx + (w * 0.25), cy + (h * 0.25), 15)
            Sleep 100
        }
    }
    Sleep 300
}
ZoomOutBB() {
    if !EnsureWindowActive()
        return
    CoordMode "Mouse", "Client"
    WinGetClientPos ,, &w, &h, TargetWindowTitle
    if (w && h) {
        cx := w // 2
        cy := h // 2
        MouseMove cx, cy, 0
        Sleep 100
    }
    LogMessage("Viewport: Zooming all the way out for Builder Base...")
    Loop 25 {
        Send "^{WheelDown}"
        Sleep 40
    }
    Sleep 300
}
ShowToolTip(message) {
    ToolTip message
    SetTimer () => ToolTip(), -3000
}
ShiftPointTowardsCenter(x, y, shiftDist := 250) {
    global TargetWindowTitle
    cx := 960
    cy := 540
    if WinExist(TargetWindowTitle) {
        WinGetClientPos ,, &w, &h, TargetWindowTitle
        if (w && h) {
            cx := w // 2
            cy := h // 2
        }
    }
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
    global CalibStep, IsCalibrating, CollectorCoords, IsWaitingForReset
    if IsWaitingForReset
        return
    CoordMode "Mouse", "Screen"
    global AttackBtnX, AttackBtnY, FindMatchBtnX, FindMatchBtnY, AttackStartBtnX, AttackStartBtnY
    global ReturnHomeClickX, ReturnHomeClickY, ReturnHomeColor
    global BuilderFaceX, BuilderFaceY, UpgradeConfirmX, UpgradeConfirmY
    global GoldBarThreshX, GoldBarThreshY, ElixirBarThreshX, ElixirBarThreshY
    global GoldAreaX, GoldAreaY, GoldAreaW, GoldAreaH
    global ElixirAreaX, ElixirAreaY, ElixirAreaW, ElixirAreaH
    global NextMatchBtnX, NextMatchBtnY
    global UpgradeMoreBtnX, UpgradeMoreBtnY, AddWall1X, AddWall1Y, RemoveWallX, RemoveWallY, GoldUpgradeX, GoldUpgradeY, ElixirUpgradeX, ElixirUpgradeY
    global Side1StartX, Side1StartY, Side1EndX, Side1EndY
    global Side2StartX, Side2StartY, Side2EndX, Side2EndY
    global Side3StartX, Side3StartY, Side3EndX, Side3EndY
    global Side4StartX, Side4StartY, Side4EndX, Side4EndY
    global Sides
    MouseGetPos &msx, &msy
    if !WinExist(TargetWindowTitle) {
        LogMessage("Calibration Error: Target window not found.")
        return
    }
    WinGetClientPos &cx, &cy,,, TargetWindowTitle
    mx := msx - cx
    my := msy - cy
    switch CalibStep {
        case 1:
            GoldBarThreshX := mx
            GoldBarThreshY := my
            LogMessage(Format("Calibrated Gold Bar Threshold Point: {}, {}", mx, my))
            CalibStep := 2
            UpdateCalibrationUI()
        case 2:
            ElixirBarThreshX := mx
            ElixirBarThreshY := my
            LogMessage(Format("Calibrated Elixir Bar Threshold Point: {}, {}", mx, my))
            CalibStep := 3
            UpdateCalibrationUI()
        case 3:
            BuilderFaceX := mx
            BuilderFaceY := my
            LogMessage(Format("Calibrated Builder Face Coordinate: {}, {}", mx, my))
            CalibStep := 4
            UpdateCalibrationUI()
        case 4:
            UpgradeMoreBtnX := mx
            UpgradeMoreBtnY := my
            LogMessage(Format("Calibrated Upgrade More Button: {}, {}", mx, my))
            CalibStep := 5
            UpdateCalibrationUI()
        case 5:
            AddWall1X := mx
            AddWall1Y := my
            LogMessage(Format("Calibrated Add Wall (+1) Button: {}, {}", mx, my))
            CalibStep := 6
            UpdateCalibrationUI()
        case 6:
            RemoveWallX := mx
            RemoveWallY := my
            LogMessage(Format("Calibrated Remove Wall (-1) Button: {}, {}", mx, my))
            CalibStep := 7
            UpdateCalibrationUI()
        case 7:
            GoldUpgradeX := mx
            GoldUpgradeY := my
            LogMessage(Format("Calibrated Gold Upgrade Button: {}, {}", mx, my))
            CalibStep := 8
            UpdateCalibrationUI()
        case 8:
            ElixirUpgradeX := mx
            ElixirUpgradeY := my
            LogMessage(Format("Calibrated Elixir Upgrade Button: {}, {}", mx, my))
            CalibStep := 9
            UpdateCalibrationUI()
        case 10:
            MVLogoX := mx
            MVLogoY := my
            MVLogoColor := PixelGetColor(mx, my)
            LogMessage(Format("Calibrated War Logo: {}, {} (Color: {})", mx, my, MVLogoColor))
            CalibStep := 11
            UpdateCalibrationUI()
        case 11:
            AttackBtnX := mx
            AttackBtnY := my
            LogMessage(Format("Calibrated Attack Button: {}, {}", mx, my))
            CalibStep := 12
            UpdateCalibrationUI()
        case 12:
            FindMatchBtnX := mx
            FindMatchBtnY := my
            LogMessage(Format("Calibrated Find Match Button: {}, {}", mx, my))
            CalibStep := 13
            UpdateCalibrationUI()
        case 13:
            AttackStartBtnX := mx
            AttackStartBtnY := my
            LogMessage(Format("Calibrated Attack Start Button: {}, {}", mx, my))
            CalibStep := 14
            UpdateCalibrationUI()
        case 14:
            GoldAreaX := mx - 120
            GoldAreaY := my - 15
            GoldAreaW := 220
            GoldAreaH := 30
            LogMessage(Format("Calibrated Gold Search Loot Area: {}, {}", mx, my))
            CalibStep := 15
            UpdateCalibrationUI()
        case 15:
            ElixirAreaX := mx - 120
            ElixirAreaY := my - 15
            ElixirAreaW := 220
            ElixirAreaH := 30
            LogMessage(Format("Calibrated Elixir Search Loot Area: {}, {}", mx, my))
            CalibStep := 16
            UpdateCalibrationUI()
        case 16:
            NextMatchBtnX := mx
            NextMatchBtnY := my
            LogMessage(Format("Calibrated Next Match Button: {}, {}", mx, my))
            CalibStep := 17
            UpdateCalibrationUI()
        case 17:
            Side1StartX := mx
            Side1StartY := my
            LogMessage(Format("Calibrated Side 1 (Bottom-Right) Start: {}, {}", mx, my))
            CalibStep := 18
            UpdateCalibrationUI()
        case 18:
            Side1EndX := mx
            Side1EndY := my
            LogMessage(Format("Calibrated Side 1 (Bottom-Right) End: {}, {}", mx, my))
            CalibStep := 19
            UpdateCalibrationUI()
        case 19:
            Side2StartX := mx
            Side2StartY := my
            LogMessage(Format("Calibrated Side 2 (Bottom-Left) Start: {}, {}", mx, my))
            CalibStep := 20
            UpdateCalibrationUI()
        case 20:
            Side2EndX := mx
            Side2EndY := my
            LogMessage(Format("Calibrated Side 2 (Bottom-Left) End: {}, {}", mx, my))
            CalibStep := 21
            UpdateCalibrationUI()
        case 21:
            Side3StartX := mx
            Side3StartY := my
            LogMessage(Format("Calibrated Side 3 (Top-Left) Start: {}, {}", mx, my))
            CalibStep := 22
            UpdateCalibrationUI()
        case 22:
            Side3EndX := mx
            Side3EndY := my
            LogMessage(Format("Calibrated Side 3 (Top-Left) End: {}, {}", mx, my))
            CalibStep := 23
            UpdateCalibrationUI()
        case 23:
            Side4StartX := mx
            Side4StartY := my
            LogMessage(Format("Calibrated Side 4 (Top-Right) Start: {}, {}", mx, my))
            CalibStep := 24
            UpdateCalibrationUI()
        case 24:
            Side4EndX := mx
            Side4EndY := my
            LogMessage(Format("Calibrated Side 4 (Top-Right) End: {}, {}", mx, my))
            ; Reconstruct the Sides array
            Sides := [
                {startX: Side1StartX, startY: Side1StartY, endX: Side1EndX, endY: Side1EndY},
                {startX: Side2StartX, startY: Side2StartY, endX: Side2EndX, endY: Side2EndY},
                {startX: Side3StartX, startY: Side3StartY, endX: Side3EndX, endY: Side3EndY},
                {startX: Side4StartX, startY: Side4StartY, endX: Side4EndX, endY: Side4EndY}
            ]
            LogMessage("Reconstructed Sides array with newly calibrated points.")
            CalibStep := 25
            UpdateCalibrationUI()
        case 25:
            ReturnHomeClickX := mx
            ReturnHomeClickY := my
            ReturnHomeColor := PixelGetColor(mx, my)
            LogMessage(Format("Calibrated Return Home Button: {}, {} (Color: {})", mx, my, ReturnHomeColor))
            ; Auto-calculate cloud points based on window size
            WinGetClientPos ,, &w, &h, TargetWindowTitle
            if (w && h) {
                global CloudPt1X, CloudPt1Y, CloudPt2X, CloudPt2Y, CloudPt3X, CloudPt3Y, CloudPt4X, CloudPt4Y
                CloudPt1X := w // 4
                CloudPt1Y := h // 4
                CloudPt2X := (w * 3) // 4
                CloudPt2Y := h // 4
                CloudPt3X := w // 4
                CloudPt3Y := (h * 3) // 4
                CloudPt4X := (w * 3) // 4
                CloudPt4Y := (h * 3) // 4
                LogMessage("Auto-calculated Cloud Detection points.")
            }
            ; Reset dynamic array for collectors
            CollectorCoords := []
            CalibStep := 26
            UpdateCalibrationUI()
        case 26:
            CollectorCoords.Push({x: mx, y: my})
            LogMessage(Format("Added Resource Collector #{}: {}, {}", CollectorCoords.Length, mx, my))
            UpdateCalibrationUI()
    }
}
Enter:: {
    if (CalibStep == 26) {
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
    CoordMode "Mouse", "Screen"
    global BBAttackBtnX, BBAttackBtnY, BBFindMatchBtnX, BBFindMatchBtnY
    global BBStar1X, BBStar1Y, BBStar2X, BBStar2Y, BBStar3X, BBStar3Y, BBStarColor
    global BBSide1StartX, BBSide1StartY, BBSide1EndX, BBSide1EndY
    global BBSide2StartX, BBSide2StartY, BBSide2EndX, BBSide2EndY
    global BBSide3StartX, BBSide3StartY, BBSide3EndX, BBSide3EndY
    global BBSide4StartX, BBSide4StartY, BBSide4EndX, BBSide4EndY
    global BBSides
    global TargetWindowTitle
    MouseGetPos &msx, &msy
    if !WinExist(TargetWindowTitle) {
        LogMessage("Calibration Error: Target window not found.")
        return
    }
    WinGetClientPos &cx, &cy,,, TargetWindowTitle
    mx := msx - cx
    my := msy - cy
    switch BBCalibStep {
        case 1:
            BBAttackBtnX := mx
            BBAttackBtnY := my
            LogMessage(Format("Calibrated BB Attack Button: {}, {}", mx, my))
            BBCalibStep := 2
            UpdateBBCalibrationUI()
        case 2:
            BBFindMatchBtnX := mx
            BBFindMatchBtnY := my
            LogMessage(Format("Calibrated BB Find Match Button: {}, {}", mx, my))
            BBCalibStep := 3
            UpdateBBCalibrationUI()
        case 3:
            BBStar1X := mx
            BBStar1Y := my
            BBStarColor := PixelGetColor(mx, my)
            LogMessage(Format("Calibrated Star 1: {}, {} (Color: {})", mx, my, BBStarColor))
            BBCalibStep := 4
            UpdateBBCalibrationUI()
        case 4:
            BBStar2X := mx
            BBStar2Y := my
            LogMessage(Format("Calibrated Star 2: {}, {}", mx, my))
            BBCalibStep := 5
            UpdateBBCalibrationUI()
        case 5:
            BBStar3X := mx
            BBStar3Y := my
            LogMessage(Format("Calibrated Star 3: {}, {}", mx, my))
            ; Automatically zoom out for Builder Base sides calibration
            ZoomOutBB()
            BBCalibStep := 6
            UpdateBBCalibrationUI()
        case 6:
            BBSide1StartX := mx
            BBSide1StartY := my
            LogMessage(Format("Calibrated BB Side 1 Start: {}, {}", mx, my))
            BBCalibStep := 7
            UpdateBBCalibrationUI()
        case 7:
            BBSide1EndX := mx
            BBSide1EndY := my
            LogMessage(Format("Calibrated BB Side 1 End: {}, {}", mx, my))
            BBCalibStep := 8
            UpdateBBCalibrationUI()
        case 8:
            BBSide2StartX := mx
            BBSide2StartY := my
            LogMessage(Format("Calibrated BB Side 2 Start: {}, {}", mx, my))
            BBCalibStep := 9
            UpdateBBCalibrationUI()
        case 10:
            BBSide2EndX := mx
            BBSide2EndY := my
            LogMessage(Format("Calibrated BB Side 2 End: {}, {}", mx, my))
            BBCalibStep := 11
            UpdateBBCalibrationUI()
        case 11:
            BBSide3StartX := mx
            BBSide3StartY := my
            LogMessage(Format("Calibrated BB Side 3 Start: {}, {}", mx, my))
            BBCalibStep := 12
            UpdateBBCalibrationUI()
        case 12:
            BBSide3EndX := mx
            BBSide3EndY := my
            LogMessage(Format("Calibrated BB Side 3 End: {}, {}", mx, my))
            BBCalibStep := 13
            UpdateBBCalibrationUI()
        case 13:
            BBSide4StartX := mx
            BBSide4StartY := my
            LogMessage(Format("Calibrated BB Side 4 Start: {}, {}", mx, my))
            BBCalibStep := 14
            UpdateBBCalibrationUI()
        case 14:
            BBSide4EndX := mx
            BBSide4EndY := my
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
    global IsRunning, IsBBRunning, StatusText
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
    ; 1. Check for game timeout immediately during start
    CheckGameTimeout(true)
    ; 2. Clearing Click to close any open menus
    ClearingClick()
    ; 3. Reset viewport so that the village check runs on a calibrated standard view
    ResetViewport()
    ; 4. Check village type and start the appropriate loop
    if IsAtHomeVillage() {
        if (MVLogoColor == 0x000000) {
            LogMessage("WARNING: Main Village Logo is uncalibrated! Please run Main Calib (^F1).")
            StatusText.Value := "Status: Calibration Needed"
            return
        }
        StartBot()
    } else if IsAtBuilderBase() {
        IsBBRunning := true
        LogMessage("Builder Base Attack Loop started.")
        StatusText.Value := "Status: Running BB"
        SetTimer RunBuilderBaseLoop, -100
    } else {
        LogMessage("Error: Could not determine village type. Please open the game to the Main Village or Builder Base.")
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
#HotIf