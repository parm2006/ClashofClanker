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
global HomeLoadDelay := 6000
global BattleLoadDelay := 1500
global SpamDelay := 30

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

global ReturnHomeX1 := 880
global ReturnHomeY1 := 915
global ReturnHomeX2 := 1040
global ReturnHomeY2 := 915
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
global BuilderAreaX := 900
global BuilderAreaY := 15
global BuilderAreaW := 120
global BuilderAreaH := 40

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
    {startX: Side1StartX, startY: Side1StartY, endX: Side1EndX, endY: Side1EndY, shiftX: -350},
    {startX: Side2StartX, startY: Side2StartY, endX: Side2EndX, endY: Side2EndY, shiftX: 350},
    {startX: Side3StartX, startY: Side3StartY, endX: Side3EndX, endY: Side3EndY, shiftX: 350},
    {startX: Side4StartX, startY: Side4StartY, endX: Side4EndX, endY: Side4EndY, shiftX: -350}
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
global EditSpam := ""
global EditBattleLoad := ""
global EditHomeLoad := ""
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
    global TargetWindowTitle, ButtonDelta, DeployDelta, TransitionDelay, HomeLoadDelay, BattleLoadDelay, SpamDelay
    global MinGold, MinElixir, EnableLootSearch, EnableWallUpgrade
    global AttackBtnX, AttackBtnY, FindMatchBtnX, FindMatchBtnY, AttackStartBtnX, AttackStartBtnY
    global ReturnHomeX1, ReturnHomeX2, ReturnHomeY1, ReturnHomeY2, ReturnHomeClickX, ReturnHomeClickY, ReturnHomeColor, ReturnHomeTolerance
    global BBAttackBtnX, BBAttackBtnY, BBFindMatchBtnX, BBFindMatchBtnY
    global BBStar1X, BBStar1Y, BBStar2X, BBStar2Y, BBStar3X, BBStar3Y, BBStarColor
    global MVLogoX, MVLogoY, MVLogoColor
    global BuilderFaceX, BuilderFaceY, BuilderAreaX, BuilderAreaY, BuilderAreaW, BuilderAreaH
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
    
    TargetWindowTitle := IniRead("config.ini", "Settings", "TargetWindowTitle", "Clash of Clans")
    ButtonDelta := SafeInteger(IniRead("config.ini", "Settings", "ButtonDelta", ""), 5)
    DeployDelta := SafeInteger(IniRead("config.ini", "Settings", "DeployDelta", ""), 25)
    TransitionDelay := SafeInteger(IniRead("config.ini", "Settings", "TransitionDelay", ""), 500)
    HomeLoadDelay := SafeInteger(IniRead("config.ini", "Settings", "HomeLoadDelay", ""), 6000)
    BattleLoadDelay := SafeInteger(IniRead("config.ini", "Settings", "BattleLoadDelay", ""), 1500)
    SpamDelay := SafeInteger(IniRead("config.ini", "Settings", "SpamDelay", ""), 30)

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

    ReturnHomeX1 := SafeInteger(IniRead("config.ini", "Coordinates", "ReturnHomeX1", ""), 880)
    ReturnHomeY1 := SafeInteger(IniRead("config.ini", "Coordinates", "ReturnHomeY1", ""), 915)
    ReturnHomeX2 := SafeInteger(IniRead("config.ini", "Coordinates", "ReturnHomeX2", ""), 1040)
    ReturnHomeY2 := SafeInteger(IniRead("config.ini", "Coordinates", "ReturnHomeY2", ""), 915)
    ReturnHomeClickX := SafeInteger(IniRead("config.ini", "Coordinates", "ReturnHomeClickX", ""), 960)
    ReturnHomeClickY := SafeInteger(IniRead("config.ini", "Coordinates", "ReturnHomeClickY", ""), 920)
    
    colorStr := IniRead("config.ini", "Coordinates", "ReturnHomeColor", "0x5FA41A")
    ReturnHomeColor := (colorStr = "" ? 0x5FA41A : SafeInteger(colorStr, 0x5FA41A))
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
    bbcolorStr := IniRead("config.ini", "Coordinates", "BBStarColor", "0x000000")
    BBStarColor := (bbcolorStr = "" ? 0x000000 : SafeInteger(bbcolorStr, 0x000000))
    
    MVLogoX := SafeInteger(IniRead("config.ini", "Coordinates", "MVLogoX", ""), 100)
    MVLogoY := SafeInteger(IniRead("config.ini", "Coordinates", "MVLogoY", ""), 700)
    mvcolorStr := IniRead("config.ini", "Coordinates", "MVLogoColor", "0x000000")
    MVLogoColor := (mvcolorStr = "" ? 0x000000 : SafeInteger(mvcolorStr, 0x000000))

    BuilderFaceX := SafeInteger(IniRead("config.ini", "Coordinates", "BuilderFaceX", ""), 960)
    BuilderFaceY := SafeInteger(IniRead("config.ini", "Coordinates", "BuilderFaceY", ""), 30)
    BuilderAreaX := SafeInteger(IniRead("config.ini", "Coordinates", "BuilderAreaX", ""), 900)
    BuilderAreaY := SafeInteger(IniRead("config.ini", "Coordinates", "BuilderAreaY", ""), 15)
    BuilderAreaW := SafeInteger(IniRead("config.ini", "Coordinates", "BuilderAreaW", ""), 120)
    BuilderAreaH := SafeInteger(IniRead("config.ini", "Coordinates", "BuilderAreaH", ""), 40)

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
        {startX: Side1StartX, startY: Side1StartY, endX: Side1EndX, endY: Side1EndY, shiftX: -350},
        {startX: Side2StartX, startY: Side2StartY, endX: Side2EndX, endY: Side2EndY, shiftX: 350},
        {startX: Side3StartX, startY: Side3StartY, endX: Side3EndX, endY: Side3EndY, shiftX: 350},
        {startX: Side4StartX, startY: Side4StartY, endX: Side4EndX, endY: Side4EndY, shiftX: -350}
    ]
}

SaveConfig() {
    global TargetWindowTitle, ButtonDelta, DeployDelta, TransitionDelay, HomeLoadDelay, BattleLoadDelay, SpamDelay
    global MinGold, MinElixir, EnableLootSearch, EnableWallUpgrade
    global AttackBtnX, AttackBtnY, FindMatchBtnX, FindMatchBtnY, AttackStartBtnX, AttackStartBtnY
    global ReturnHomeX1, ReturnHomeX2, ReturnHomeY1, ReturnHomeY2, ReturnHomeClickX, ReturnHomeClickY, ReturnHomeColor, ReturnHomeTolerance
    global BBAttackBtnX, BBAttackBtnY, BBFindMatchBtnX, BBFindMatchBtnY
    global BBStar1X, BBStar1Y, BBStar2X, BBStar2Y, BBStar3X, BBStar3Y, BBStarColor
    global BuilderFaceX, BuilderFaceY, BuilderAreaX, BuilderAreaY, BuilderAreaW, BuilderAreaH
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

    IniWrite(TargetWindowTitle, "config.ini", "Settings", "TargetWindowTitle")
    IniWrite(ButtonDelta, "config.ini", "Settings", "ButtonDelta")
    IniWrite(DeployDelta, "config.ini", "Settings", "DeployDelta")
    IniWrite(TransitionDelay, "config.ini", "Settings", "TransitionDelay")
    IniWrite(HomeLoadDelay, "config.ini", "Settings", "HomeLoadDelay")
    IniWrite(BattleLoadDelay, "config.ini", "Settings", "BattleLoadDelay")
    IniWrite(SpamDelay, "config.ini", "Settings", "SpamDelay")

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

    IniWrite(ReturnHomeX1, "config.ini", "Coordinates", "ReturnHomeX1")
    IniWrite(ReturnHomeY1, "config.ini", "Coordinates", "ReturnHomeY1")
    IniWrite(ReturnHomeX2, "config.ini", "Coordinates", "ReturnHomeX2")
    IniWrite(ReturnHomeY2, "config.ini", "Coordinates", "ReturnHomeY2")
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
    IniWrite(BuilderAreaX, "config.ini", "Coordinates", "BuilderAreaX")
    IniWrite(BuilderAreaY, "config.ini", "Coordinates", "BuilderAreaY")
    IniWrite(BuilderAreaW, "config.ini", "Coordinates", "BuilderAreaW")
    IniWrite(BuilderAreaH, "config.ini", "Coordinates", "BuilderAreaH")

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
    global MyGui, EditWindow, EditSpam, EditBattleLoad, EditHomeLoad, EditButtonDelta, EditDeployDelta
    global EditMinGold, EditMinElixir, CheckLootSearch, CheckWallUpgrade, TextCollectorCount
    global LogEdit, StatusText, StartBtn, PauseBtn, CalibrationText
    
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
    
    MyGui.Add("Text", "x20 y230 w320 h195", "Instructions:`nHover mouse over target and press SPACE.`n`nMain Steps (25 total):`n1-3. Gold/Elixir Storage Bar, Builder Face (Home)`n4-8. Upgrade More, Add/Remove Wall, G/E Upgrade`n9-11. Attack, Main Logo, Find Match (Menus)`n12-14. Green Attack, Loot Area G/E (Battle)`n15-23. Next Match, Sides 1-4 Start/End`n24. Return Home Button (Battle End)`n25. Collector Coordinates (Home - press ENTER).`n`nBB Steps (5 total):`n1-2. Attack, Find Match`n3-5. Star 1, 2, 3 Centers")
    
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
    
    ; --- TAB 4: Settings ---
    Tab.UseTab(4)
    MyGui.Add("GroupBox", "x20 y45 w320 h130", "Delays (milliseconds)")
    MyGui.Add("Text", "x35 y70 w180 h20", "Troop Spam Click Delay:")
    EditSpam := MyGui.Add("Edit", "x220 y68 w100 h20 Number", String(SpamDelay))
    
    MyGui.Add("Text", "x35 y100 w180 h20", "Battle Load Delay:")
    EditBattleLoad := MyGui.Add("Edit", "x220 y98 w100 h20 Number", String(BattleLoadDelay))
    
    MyGui.Add("Text", "x35 y130 w180 h20", "Home Load Delay:")
    EditHomeLoad := MyGui.Add("Edit", "x220 y128 w100 h20 Number", String(HomeLoadDelay))
    
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
    global TargetWindowTitle, SpamDelay, BattleLoadDelay, HomeLoadDelay, ButtonDelta, DeployDelta
    global MinGold, MinElixir, EnableLootSearch, EnableWallUpgrade
    global Troop1Count, Troop2Count, Troop3Count
    global EditWindow, EditSpam, EditBattleLoad, EditHomeLoad, EditButtonDelta, EditDeployDelta
    global EditMinGold, EditMinElixir, CheckLootSearch, CheckWallUpgrade
    global EditTroop1Count, EditTroop2Count, EditTroop3Count
    
    TargetWindowTitle := EditWindow.Value
    SpamDelay := Integer(EditSpam.Value)
    BattleLoadDelay := Integer(EditBattleLoad.Value)
    HomeLoadDelay := Integer(EditHomeLoad.Value)
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
            instructions := "Step 1/5: Builder Base Attack Button`n`nHover mouse over the 'Attack!' button in Builder Base and press SPACE."
        case 2:
            instructions := "Step 2/5: Builder Base Find Match Button`n`nHover mouse over the 'Find a Match!' button and press SPACE."
        case 3:
            instructions := "Step 3/5: Star 1 Center (Overall Damage Screen)`n`nHover mouse exactly over the center of the first star on the results screen and press SPACE."
        case 4:
            instructions := "Step 4/5: Star 2 Center`n`nHover mouse exactly over the center of the second star and press SPACE."
        case 5:
            instructions := "Step 5/5: Star 3 Center`n`nHover mouse exactly over the center of the third star and press SPACE.`n`nPress ENTER to finish and save."
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
    if !IsCalibrating || CalibStep != 25
        return
        
    ResetViewport()
    IsWaitingForReset := false
        
    instructions := "Step 25/25: Resource Collectors (Home Screen)`n`nHover over a Gold Mine, Elixir Collector, or DE Drill and press SPACE to record.`n`nCurrently added: " CollectorCoords.Length "`n`nPlease don't move the screen.`n`nPress ENTER to finish and save."
    CalibrationText.Value := instructions
    ToolTip(instructions "`n`nPress ESC to cancel.")
}

RunSidesReset() {
    global CalibStep, IsCalibrating, IsWaitingForReset, CalibrationText
    if !IsCalibrating || CalibStep != 16
        return
        
    ResetViewport()
    IsWaitingForReset := false
    
    instructions := "Step 16/25: Side 1 (Bottom-Right) Start Point`n`nHover mouse over the starting point of the Bottom-Right deployment line and press SPACE."
    CalibrationText.Value := instructions
    ToolTip(instructions "`n`nPress ESC to cancel.")
}

UpdateCalibrationUI() {
    global CalibStep, CalibrationText, CollectorCoords, IsWaitingForReset
    instructions := ""
    switch CalibStep {
        case 1:
            instructions := "Step 1/25: Gold Storage Bar Threshold Point (Home Screen)`n`nHover over your Gold storage bar at the point where you want wall upgrades to trigger (e.g. 85% full) and press SPACE."
        case 2:
            instructions := "Step 2/25: Elixir Storage Bar Threshold Point (Home Screen)`n`nHover over your Elixir storage bar at the point where you want wall upgrades to trigger (e.g. 85% full) and press SPACE."
        case 3:
            instructions := "Step 3/25: Builder Face (Home Screen)`n`nHover mouse over the top-center Builder head icon and press SPACE."
        case 4:
            instructions := "Step 4/25: Upgrade More Button (Wall Selected)`n`nHover mouse over the 'Upgrade More' button (first select a wall manually to show it) and press SPACE."
        case 5:
            instructions := "Step 5/25: Add Wall (+1) Button (Upgrade More Screen)`n`nHover mouse over the '+1 Add Wall' button (click 'Upgrade More' manually to show it) and press SPACE."
        case 6:
            instructions := "Step 6/25: Remove Wall (-1) Button (Upgrade More Screen)`n`nHover mouse over the '-1 Remove Wall' button and press SPACE."
        case 7:
            instructions := "Step 7/25: Gold Upgrade Button (Upgrade More Screen)`n`nHover mouse over the Gold Upgrade button (showing the gold hammer/cost) and press SPACE."
        case 8:
            instructions := "Step 8/25: Elixir Upgrade Button (Upgrade More Screen)`n`nHover mouse over the Elixir Upgrade button (showing the purple hammer/cost) and press SPACE."
        case 9:
            instructions := "Step 9/25: Attack Button (Home Screen)`n`nHover mouse over the bottom-left brown 'Attack' button in your home village and press SPACE."
        case 10:
            instructions := "Step 10/25: Main Village Logo (Home Screen)`n`nHover mouse over the War Logo (or any logo) directly ABOVE the Barbarian head / Attack button and press SPACE."
        case 11:
            instructions := "Step 11/25: Find Match Button (Multiplayer Dialog)`n`nHover mouse over the golden 'Find a Match' button (multiplayer tab) and press SPACE."
        case 12:
            instructions := "Step 12/25: Green 'Attack!' Start Button (My Army Dialog)`n`nHover mouse over the green 'Attack!' button (My Army dialog) and press SPACE."
        case 13:
            instructions := "Step 13/25: Multiplayer Gold Area (Matchmaking Search)`n`nHover mouse over the Gold count digits in a multiplayer match search and press SPACE."
        case 14:
            instructions := "Step 14/25: Multiplayer Elixir Area (Matchmaking Search)`n`nHover mouse over the Elixir count digits in a multiplayer match search and press SPACE."
        case 15:
            instructions := "Step 15/25: Next Match Button (Matchmaking Search)`n`nHover mouse over the 'Next' button in a multiplayer match search and press SPACE."
        case 16:
            IsWaitingForReset := true
            instructions := "Top-Left Screen Zoom-Out Calibration`n`nPlease Wait."
            SetTimer(RunSidesReset, -3000)
        case 17:
            instructions := "Step 17/25: Side 1 (Bottom-Right) End Point`n`nHover mouse over the ending point of the Bottom-Right deployment line and press SPACE."
        case 18:
            instructions := "Step 18/25: Side 2 (Bottom-Left) Start Point`n`nHover mouse over the starting point of the Bottom-Left deployment line and press SPACE."
        case 19:
            instructions := "Step 19/25: Side 2 (Bottom-Left) End Point`n`nHover mouse over the ending point of the Bottom-Left deployment line and press SPACE."
        case 20:
            instructions := "Step 20/25: Side 3 (Top-Left) Start Point`n`nHover mouse over the starting point of the Top-Left deployment line and press SPACE."
        case 21:
            instructions := "Step 21/25: Side 3 (Top-Left) End Point`n`nHover mouse over the ending point of the Top-Left deployment line and press SPACE."
        case 22:
            instructions := "Step 22/25: Side 4 (Top-Right) Start Point`n`nHover mouse over the starting point of the Top-Right deployment line and press SPACE."
        case 23:
            instructions := "Step 23/25: Side 4 (Top-Right) End Point`n`nHover mouse over the ending point of the Top-Right deployment line and press SPACE."
        case 24:
            instructions := "Step 24/25: Return Home Button (Battle End)`n`nHover mouse over the center of the green 'Return Home' button and press SPACE."
        case 25:
            if (CollectorCoords.Length == 0) {
                IsWaitingForReset := true
                instructions := "Top-Left Screen Zoom-Out Calibration`n`nPress Button and Please Wait."
                SetTimer(RunCollectorReset, -3000)
            } else {
                instructions := "Step 25/25: Resource Collectors (Home Screen)`n`nHover over a Gold Mine, Elixir Collector, or DE Drill and press SPACE to record.`n`nCurrently added: " CollectorCoords.Length "`n`nPlease don't move the screen.`n`nPress ENTER to finish and save."
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

GetOCRText(relX, relY, relW, relH) {
    global TargetWindowTitle
    if !WinExist(TargetWindowTitle)
        return ""
        
    WinGetClientPos &cx, &cy,,, TargetWindowTitle
    
    scrX := cx + relX
    scrY := cy + relY
    
    try {
        result := OCR.FromRect(scrX, scrY, relW, relH, {scale: 2})
        return result.Text
    }
    catch {
        return ""
    }
}

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
        
        ; Pink/Purple color signature: high R and B, lower G
        ; Made extremely lenient: Red and Blue just need to be noticeably higher than Green
        return (r > 120) && (b > 100) && (r > g + 20) && (b > g + 10)
    }
    catch {
        return false
    }
}

AreBuildersBusy() {
    ; The transparent background makes OCR impossible, and checking for red text doesn't work.
    ; Instead of trying to read the builder count, we will simply assume a builder is free 
    ; and let the bot attempt the upgrade. If a popup appears because 0 builders are free, 
    ; our robust popup-dismissal clicks will handle it.
    return false
}

ClickOkayIfPresent() {
    global TargetWindowTitle
    WinGetClientPos &cx, &cy, &cw, &ch, TargetWindowTitle
    
    ; Search the center area for the popup buttons
    searchX := cx + (cw * 0.2)
    searchY := cy + (ch * 0.4)
    searchW := cw * 0.6
    searchH := ch * 0.4
    
    try {
        result := OCR.FromRect(searchX, searchY, searchW, searchH, {scale: 1.5})
        for line in result.Lines {
            text := StrReplace(line.Text, " ", "")
            if InStr(text, "Okay") || InStr(text, "0kay") || InStr(text, "Cancel") || InStr(text, "Cance") {
                LogMessage("Farming: Detected Upgrade confirmation popup! Clicking Okay.")
                ; The Okay button is always roughly 65% across and 70% down
                okX := cx + (cw * 0.66)
                okY := cy + (ch * 0.68)
                ClickPoint(okX, okY)
                return true
            }
        }
    }
    
    LogMessage("Farming: 'Okay' button not found. Dismissing popup safely.")
    return false
}

IsCostRed(btnX, btnY) {
    ; Create a small search window strictly around the cost text above the button
    ; to avoid scanning the transparent village background below the menu
    x1 := btnX - 50
    y1 := btnY - 40
    x2 := btnX + 50
    y2 := btnY - 15
    
    ; Search for bright red (0xFF2222) with a moderate variation of 40.
    ; This avoids false positives on random background objects while still catching the red text.
    return PixelSearch(&foundX, &foundY, x1, y1, x2, y2, 0xFF2222, 40)
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

UpgradeWalls() {
    global EnableWallUpgrade, IsRunning, TargetWindowTitle
    global BuilderFaceX, BuilderFaceY
    CoordMode "Mouse", "Client"
    global UpgradeMoreBtnX, UpgradeMoreBtnY
    global AddWall1X, AddWall1Y, RemoveWallX, RemoveWallY
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
    
    ; 2. Gold Wall Upgrade (If storage threshold met)
    if runGoldUpgrade {
        LogMessage("Farming: Gold bar threshold met! Selecting cheapest wall for Gold upgrade...")
        
        ; Open Builder Dropdown Menu
        ClickPoint(BuilderFaceX, BuilderFaceY)
        if !SafeSleep(800)
            return
            
        ; Scroll dropdown list down to reveal walls
        if !EnsureWindowActive()
            return
        CoordMode "Mouse", "Client"
        MouseMove BuilderFaceX, BuilderFaceY + 150
        Loop 10 {
            Click "WheelDown"
            Sleep 150
        }
        if !SafeSleep(800)
            return
            
        ; OCR dropdown list to select cheapest Wall suggestion
        WinGetClientPos &cx, &cy, &w, &h, TargetWindowTitle
        
        menuLeft := BuilderFaceX - (w * 0.18)
        menuWidth := w * 0.36
        menuTop := h * 0.12
        menuHeight := h * 0.75
        
        scrLeft := cx + menuLeft
        scrTop := cy + menuTop
        
        try {
            result := OCR.FromRect(scrLeft, scrTop, menuWidth, menuHeight, {scale: 2})
            cheapestWallLine := ""
            for line in result.Lines {
                if InStr(line.Text, "Wall") {
                    cheapestWallLine := line
                }
            }
            
            if !cheapestWallLine {
                LogMessage("Farming: No Wall upgrades found in builder suggestions.")
                ClickPoint(ReturnHomeClickX, ReturnHomeClickY)
                SafeSleep(500)
                goto CheckElixirPhase
            }
            
            ; Click directly in the center of the text to avoid clicking through transparent background
            relX := (cheapestWallLine.x + (cheapestWallLine.w / 2)) - cx
            relY := (cheapestWallLine.y + (cheapestWallLine.h / 2)) - cy
            ClickPoint(relX, relY)
        }
        catch {
            ClickPoint(ReturnHomeClickX, ReturnHomeClickY)
            SafeSleep(500)
            goto CheckElixirPhase
        }
        
        if !SafeSleep(5000)
            return
            
        ClickPoint(UpgradeMoreBtnX, UpgradeMoreBtnY)
        if !SafeSleep(800)
            return
            
        if IsCostRed(GoldUpgradeX, GoldUpgradeY) {
            LogMessage("Farming: Gold upgrade is unaffordable (insufficient Gold).")
            ClickPoint(ReturnHomeClickX, ReturnHomeClickY)
            SafeSleep(500)
        } else {
            goldCount := 1
            Loop 4 {
                ClickPoint(AddWall1X, AddWall1Y)
                if !SafeSleep(250)
                    return
                if IsCostRed(GoldUpgradeX, GoldUpgradeY) {
                    ClickPoint(RemoveWallX, RemoveWallY) ; Step back to maximum affordable
                    if !SafeSleep(250)
                        return
                    break
                }
                goldCount++
            }
            LogMessage(Format("Farming: Upgrading {} wall(s) with Gold!", goldCount))
            ClickPoint(GoldUpgradeX, GoldUpgradeY)
            if !SafeSleep(1500)
                return
                
            ClickOkayIfPresent()
            SafeSleep(1000)
            ClickPoint(ReturnHomeClickX, ReturnHomeClickY) ; Always dismiss potential gem popups safely
            SafeSleep(500)
        }
    }
    
CheckElixirPhase:
    ; 3. Elixir Wall Upgrade (If storage threshold met)
    if runElixirUpgrade {
        LogMessage("Farming: Elixir threshold met. Selecting cheapest wall for Elixir upgrade...")
        UpgradeWallsCycle2()
    }
}

UpgradeWallsCycle2() {
    global EnableWallUpgrade, IsRunning, TargetWindowTitle
    global BuilderFaceX, BuilderFaceY
    CoordMode "Mouse", "Client"
    global UpgradeMoreBtnX, UpgradeMoreBtnY
    global AddWall1X, AddWall1Y, RemoveWallX, RemoveWallY
    global ElixirUpgradeX, ElixirUpgradeY
    
    LogMessage("Farming: Rechecking builder dropdown to search for Elixir wall upgrades...")
    
    ; 1. Open Builder Dropdown Menu
    ClickPoint(BuilderFaceX, BuilderFaceY)
    if !SafeSleep(800)
        return false
        
    ; 2. Scroll dropdown list down to reveal walls
    if !EnsureWindowActive()
        return false
    CoordMode "Mouse", "Client"
    MouseMove BuilderFaceX, BuilderFaceY + 150
    Loop 10 {
        Click "WheelDown"
        Sleep 150
    }
    if !SafeSleep(800)
        return false
        
    ; 3. OCR and select cheapest Wall suggestion
    WinGetClientPos &cx, &cy, &w, &h, TargetWindowTitle
    
    menuLeft := BuilderFaceX - (w * 0.18)
    menuWidth := w * 0.36
    menuTop := h * 0.12
    menuHeight := h * 0.75
    
    scrLeft := cx + menuLeft
    scrTop := cy + menuTop
    
    try {
        result := OCR.FromRect(scrLeft, scrTop, menuWidth, menuHeight, {scale: 2})
        cheapestWallLine := ""
        for line in result.Lines {
            if InStr(line.Text, "Wall") {
                cheapestWallLine := line
            }
        }
        
        if !cheapestWallLine {
            ClickPoint(ReturnHomeClickX, ReturnHomeClickY)
            SafeSleep(500)
            return false
        }
        
        ; Click directly in the center of the text to avoid clicking through transparent background
        relX := (cheapestWallLine.x + (cheapestWallLine.w / 2)) - cx
        relY := (cheapestWallLine.y + (cheapestWallLine.h / 2)) - cy
        ClickPoint(relX, relY)
    }
    catch {
        ClickPoint(ReturnHomeClickX, ReturnHomeClickY)
        SafeSleep(500)
        return false
    }
    if !SafeSleep(5000)
        return false
        
    ; 4. Click Upgrade More
    ClickPoint(UpgradeMoreBtnX, UpgradeMoreBtnY)
    if !SafeSleep(800)
        return false
        
    ; 5. Perform Elixir Upgrades
    LogMessage("Farming: Checking Elixir wall upgrade affordability...")
    if IsCostRed(ElixirUpgradeX, ElixirUpgradeY) {
        LogMessage("Farming: Elixir upgrade is currently unaffordable.")
    } else {
        LogMessage("Farming: Elixir upgrade affordable. Batching walls (max 5)...")
        elixirCount := 1
        Loop 4 {
            ClickPoint(AddWall1X, AddWall1Y)
            if !SafeSleep(250)
                return false
            if IsCostRed(ElixirUpgradeX, ElixirUpgradeY) {
                ClickPoint(RemoveWallX, RemoveWallY)
                if !SafeSleep(250)
                    return false
                break
            }
            elixirCount++
        }
        LogMessage(Format("Farming: Upgrading {} wall(s) with Elixir!", elixirCount))
        ClickPoint(ElixirUpgradeX, ElixirUpgradeY)
        if !SafeSleep(1500)
            return false
            
        ClickOkayIfPresent()
        SafeSleep(1000)
        ClickPoint(ReturnHomeClickX, ReturnHomeClickY) ; Always dismiss potential gem popups safely
        SafeSleep(500)
    }
    
    ClickPoint(ReturnHomeClickX, ReturnHomeClickY)
    SafeSleep(500)
    return true
}

IsReturnHomePresent() {
    global ReturnHomeClickX, ReturnHomeClickY, ReturnHomeColor, ReturnHomeTolerance
    if !EnsureWindowActive()
        return false
        
    ; 1. Check calibrated color
    if ColorMatches(ReturnHomeClickX, ReturnHomeClickY, ReturnHomeColor, ReturnHomeTolerance)
        return true
        
    ; 2. Fallback: Scan a vertical line of pixels to find the green background (avoiding white text)
    offsets := [-20, -10, 0, 10, 20]
    for dy in offsets {
        try {
            c := PixelGetColor(ReturnHomeClickX, ReturnHomeClickY + dy)
            actualHex := Integer(c)
            r := (actualHex >> 16) & 0xFF
            g := (actualHex >> 8) & 0xFF
            b := actualHex & 0xFF
            
            ; Green button typical RGB ranges (e.g. 95, 164, 26)
            if (g > r + 30) && (g > b + 30) && (g > 100)
                return true
        }
    }
    return false
}

; ==============================================================================
; MAIN AUTOMATION LOOP
; ==============================================================================

StartBotLoop() {
    global IsRunning, StatusText, StartBtn, PauseBtn
    global AttackBtnX, AttackBtnY, FindMatchBtnX, FindMatchBtnY, AttackStartBtnX, AttackStartBtnY
    global ReturnHomeClickX, ReturnHomeClickY, BattleLoadDelay, ReturnHomeX1, ReturnHomeY1, ReturnHomeColor, ReturnHomeTolerance
    global EnableLootSearch, MinGold, MinElixir, NextMatchBtnX, NextMatchBtnY
    global Sides, Troop1Count, Troop2Count, Troop3Count
    ; Perform a screen-relative focus click in the right-middle grass area of the game window
    if WinExist(TargetWindowTitle) {
        WinGetClientPos &cx, &cy, &cw, &ch, TargetWindowTitle
        safeScrX := cx + (cw * 8) // 10
        safeScrY := cy + (ch * 3) // 10
        LogMessage(Format("Performing initial screen-relative focus click at {}, {}...", safeScrX, safeScrY))
        
        PerformClick(safeScrX, safeScrY)
        Sleep 500
        
        SafeSleep(300)
    } else {
        LogMessage("Error: Game window not found. Skipping initial focus click.")
    }
    
    Loop {
        if !IsRunning
            break
            
        ; Reset viewport before resource collection
        ResetViewport()
        
        ; Collector resource farming (1 in 2 chance for testing)
        CollectResources()
        if !IsRunning
            break
            
        ; Wall upgrades farming
        UpgradeWalls()
        if !IsRunning
            break
            
        ; Step 1: Click the bottom-left "Attack" button (from Home Village)
        LogMessage("Step 1: Clicking Attack...")
        ClickPoint(AttackBtnX, AttackBtnY)
        if !SafeSleep(1000) ; Wait for Multiplayer dialog to open fully (was 400)
            break
            
        ; Step 2: Click the gold "Find a Match" button (from Multiplayer dialog)
        LogMessage("Step 2: Clicking Find a Match...")
        ClickPoint(FindMatchBtnX, FindMatchBtnY)
        if !SafeSleep(800) ; Wait for My Army dialog to open fully (was 350)
            break
            
        ; Step 3: Click the green "Attack!" button (from My Army dialog)
        LogMessage("Step 3: Clicking Green Attack...")
        ClickPoint(AttackStartBtnX, AttackStartBtnY)
        if !SafeSleep(500) ; Wait for clouds transition to start (was 250)
            break
            
    WaitForClouds:
        ; Step 4: Wait for Clouds screen to end
        LogMessage("Step 4: Waiting for match / clouds to clear...")
        while AreCloudsPresent() {
            if !SafeSleep(250)
                goto LoopExit
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
        
        ; Shift spell line towards the center of the window by 250 pixels
        spellStart := ShiftPointTowardsCenter(lineStartX, lineStartY, 250)
        spellEnd := ShiftPointTowardsCenter(lineEndX, lineEndY, 250)
        
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
        DeploySingleLine("a", 5, aLineStartX, aLineStartY, aLineEndX, aLineEndY, 750)
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
            
            ; Check if home 2s after clicking (early detection)
            if !SafeSleep(2000)
                goto LoopExit
            if IsAtHomeVillage()
                break
            
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

PerformClick(x, y) {
    RunWait(A_ComSpec " /c adb shell input tap " Round(x) " " Round(y), , "Hide")
}

RandomClick(x, y, delta) {
    if (delta > 0) {
        rx := x + Random(-delta, delta)
        ry := y + Random(-delta, delta)
    } else {
        rx := x
        ry := y
    }
    PerformClick(rx, ry)
}

ClickPoint(x, y, delta := "") {
    global ButtonDelta
    if (delta == "")
        delta := ButtonDelta
        
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
        t := (clickCount > 1) ? (A_Index - 1) / (clickCount - 1) : 0.5
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
    global AttackBtnX, AttackBtnY
    if !EnsureWindowActive()
        return false
    return IsBrown(AttackBtnX - 45, AttackBtnY) || IsBrown(AttackBtnX + 45, AttackBtnY)
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
    return IsBrown(BBAttackBtnX - 45, BBAttackBtnY) || IsBrown(BBAttackBtnX + 45, BBAttackBtnY)
}

AreThreeStarsPresent() {
    global BBStar1X, BBStar1Y, BBStar2X, BBStar2Y, BBStar3X, BBStar3Y, BBStarColor
    if !EnsureWindowActive()
        return false
        
    ; Helper to ensure the pixel is actually golden/brown (not black/grey)
    IsGolden(x, y) {
        try {
            c := PixelGetColor(x, y)
            hx := Integer(c)
            r := (hx >> 16) & 0xFF
            g := (hx >> 8) & 0xFF
            b := hx & 0xFF
            ; Must have enough red/green (gold) and be distinctly not grey
            return (r > 120) && (r > b + 40) && (g > b + 20)
        }
        return false
    }

    match1 := ColorMatches(BBStar1X, BBStar1Y, BBStarColor, 40) && IsGolden(BBStar1X, BBStar1Y)
    match2 := ColorMatches(BBStar2X, BBStar2Y, BBStarColor, 40) && IsGolden(BBStar2X, BBStar2Y)
    match3 := ColorMatches(BBStar3X, BBStar3Y, BBStarColor, 40) && IsGolden(BBStar3X, BBStar3Y)
    
    return match1 && match2 && match3
}

DeployBBTroops(side) {
    global DeployDelta
    ; Deploy Hero (Q) and Troops (1-8) along the side
    for key in ["q", "1", "2", "3", "4", "5", "6", "7", "8"] {
        SendKey(key)
        SafeSleep(175)
        ; Spread clicks along line
        Loop 3 {
            t := (A_Index - 1) / 2
            rx := side.startX + t * (side.endX - side.startX)
            ry := side.startY + t * (side.endY - side.startY)
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
        }
        
        ; Deduct 10s from BattleLoadDelay to start faster, minimum 100ms
        actualLoadDelay := (BattleLoadDelay > 10000) ? (BattleLoadDelay - 10000) : 100
        if !SafeSleep(actualLoadDelay)
            break
            
        ; Pick random side
        sideIdx := Random(1, 4)
        chosenSide := Sides[sideIdx]
        LogMessage("Step 5: Picked Side " sideIdx " for BB deployment.")
        
        DeployBBTroops(chosenSide)
        
        LogMessage("Step 6: Phase 1 battle running. Monitoring for 3-stars or early finish...")
        waitTimer := 0
        threeStars := false
        while (waitTimer < 180) {
            if !IsBBRunning
                goto BBLoopExit
                
            if AreThreeStarsPresent() {
                threeStars := true
                break
            }
            if IsReturnHomePresent() {
                LogMessage("Phase 1 finished early (Return Home detected).")
                break
            }
            if !SafeSleep(1000)
                goto BBLoopExit
            waitTimer++
        }
        
        if threeStars {
            LogMessage("Step 7: 3 stars detected! Waiting 30s for troops to walk to 2nd base...")
            if !SafeSleep(30000)
                goto BBLoopExit
                
            LogMessage("Phase 2 starting. Deploying on Side " sideIdx)
            DeployBBTroops(chosenSide)
            
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
            if IsAtBuilderBase()
                break
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
        PerformClick(safeX, safeY)
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
    global ReturnHomeX1, ReturnHomeY1, ReturnHomeX2, ReturnHomeY2, ReturnHomeClickX, ReturnHomeClickY, ReturnHomeColor
    global BuilderFaceX, BuilderFaceY, BuilderAreaX, BuilderAreaY, BuilderAreaW, BuilderAreaH
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
            BuilderAreaX := mx - 60
            BuilderAreaY := my - 20
            BuilderAreaW := 120
            BuilderAreaH := 40
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
            
        case 9:
            AttackBtnX := mx
            AttackBtnY := my
            LogMessage(Format("Calibrated Attack Button: {}, {}", mx, my))
            CalibStep := 10
            UpdateCalibrationUI()
            
        case 10:
            MVLogoX := mx
            MVLogoY := my
            MVLogoColor := PixelGetColor(mx, my)
            LogMessage(Format("Calibrated Main Village Logo: {}, {} (Color: {})", mx, my, MVLogoColor))
            CalibStep := 11
            UpdateCalibrationUI()
            
        case 11:
            FindMatchBtnX := mx
            FindMatchBtnY := my
            LogMessage(Format("Calibrated Find Match Button: {}, {}", mx, my))
            CalibStep := 12
            UpdateCalibrationUI()
            
        case 12:
            AttackStartBtnX := mx
            AttackStartBtnY := my
            LogMessage(Format("Calibrated Attack Start Button: {}, {}", mx, my))
            CalibStep := 13
            UpdateCalibrationUI()
            
        case 13:
            GoldAreaX := mx - 75
            GoldAreaY := my - 15
            GoldAreaW := 150
            GoldAreaH := 30
            LogMessage(Format("Calibrated Gold Search Loot Area: {}, {}", mx, my))
            CalibStep := 14
            UpdateCalibrationUI()
            
        case 14:
            ElixirAreaX := mx - 75
            ElixirAreaY := my - 15
            ElixirAreaW := 150
            ElixirAreaH := 30
            LogMessage(Format("Calibrated Elixir Search Loot Area: {}, {}", mx, my))
            CalibStep := 15
            UpdateCalibrationUI()
            
        case 15:
            NextMatchBtnX := mx
            NextMatchBtnY := my
            LogMessage(Format("Calibrated Next Match Button: {}, {}", mx, my))
            CalibStep := 16
            UpdateCalibrationUI()
            
        case 16:
            Side1StartX := mx
            Side1StartY := my
            LogMessage(Format("Calibrated Side 1 (Bottom-Right) Start: {}, {}", mx, my))
            CalibStep := 17
            UpdateCalibrationUI()
            
        case 17:
            Side1EndX := mx
            Side1EndY := my
            LogMessage(Format("Calibrated Side 1 (Bottom-Right) End: {}, {}", mx, my))
            CalibStep := 18
            UpdateCalibrationUI()
            
        case 18:
            Side2StartX := mx
            Side2StartY := my
            LogMessage(Format("Calibrated Side 2 (Bottom-Left) Start: {}, {}", mx, my))
            CalibStep := 19
            UpdateCalibrationUI()
            
        case 19:
            Side2EndX := mx
            Side2EndY := my
            LogMessage(Format("Calibrated Side 2 (Bottom-Left) End: {}, {}", mx, my))
            CalibStep := 20
            UpdateCalibrationUI()
            
        case 20:
            Side3StartX := mx
            Side3StartY := my
            LogMessage(Format("Calibrated Side 3 (Top-Left) Start: {}, {}", mx, my))
            CalibStep := 21
            UpdateCalibrationUI()
            
        case 21:
            Side3EndX := mx
            Side3EndY := my
            LogMessage(Format("Calibrated Side 3 (Top-Left) End: {}, {}", mx, my))
            CalibStep := 22
            UpdateCalibrationUI()
            
        case 22:
            Side4StartX := mx
            Side4StartY := my
            LogMessage(Format("Calibrated Side 4 (Top-Right) Start: {}, {}", mx, my))
            CalibStep := 23
            UpdateCalibrationUI()
            
        case 23:
            Side4EndX := mx
            Side4EndY := my
            LogMessage(Format("Calibrated Side 4 (Top-Right) End: {}, {}", mx, my))
            
            ; Reconstruct the Sides array
            Sides := [
                {startX: Side1StartX, startY: Side1StartY, endX: Side1EndX, endY: Side1EndY, shiftX: -350},
                {startX: Side2StartX, startY: Side2StartY, endX: Side2EndX, endY: Side2EndY, shiftX: 350},
                {startX: Side3StartX, startY: Side3StartY, endX: Side3EndX, endY: Side3EndY, shiftX: 350},
                {startX: Side4StartX, startY: Side4StartY, endX: Side4EndX, endY: Side4EndY, shiftX: -350}
            ]
            LogMessage("Reconstructed Sides array with newly calibrated points.")
            
            CalibStep := 24
            UpdateCalibrationUI()
            
        case 24:
            ReturnHomeClickX := mx
            ReturnHomeClickY := my
            ReturnHomeX1 := mx
            ReturnHomeY1 := my
            ReturnHomeX2 := mx
            ReturnHomeY2 := my
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
            CalibStep := 25
            UpdateCalibrationUI()
            
        case 25:
            CollectorCoords.Push({x: mx, y: my})
            LogMessage(Format("Added Resource Collector #{}: {}, {}", CollectorCoords.Length, mx, my))
            UpdateCalibrationUI()
    }
}

Enter:: {
    if (CalibStep == 25) {
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
            FinishBBCalibration()
    }
}

Enter:: {
    if (BBCalibStep == 5) {
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
    
    if IsAtHomeVillage() {
        if (MVLogoColor == 0x000000) {
            LogMessage("WARNING: Main Village Logo is uncalibrated! Please run Main Calib (^F1).")
            StatusText.Value := "Status: Calibration Needed"
            return
        }
        
        if IsMVLogoPresent() {
            StartBot()
        } else {
            IsBBRunning := true
            LogMessage("Builder Base Attack Loop started.")
            StatusText.Value := "Status: Running BB"
            SetTimer RunBuilderBaseLoop, -100
        }
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
