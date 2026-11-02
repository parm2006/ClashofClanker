; Manual controls call the same primitives as the bot. Nothing starts a farming loop.
ManualVisualizerGroups() {
    return [
        {name: "Overview", help: "Start one complete path below. Full cycle: Home > resources + upgrades > matchmaking > deployment + abilities > Return Home. Nothing repeats automatically.", items: [
            ["path_cycle", "Start full cycle (once)", "path"], ["path_home", "Start Home + farming path", "path"],
            ["path_battle", "Start battle + return path", "path"], ["path_builder", "Start building upgrade path", "path"],
            ["path_lab", "Start laboratory upgrade path", "path"], ["path_walls", "Start wall upgrade path", "path"],
            ["path_collect", "Start resource collection", "path"], ["path_enter", "Start battle entry path", "path"],
            ["path_search", "Start loot search path", "path"], ["path_attack", "Start deployment + abilities", "path"],
            ["path_return", "Start Return Home path", "path"], ["path_bb", "Start Builder Base attack", "path"],
            ["recover", "Start Clash reopen recovery", "path"],
            ["calibrate_main", "Main calibration (same as bot)", "calibration"]]},
        {name: "InTesting", help: "Reserved for unfinished upgrade paths. Pet and workshop are not implemented yet.", items: [
            ["pet_tab", "Tap Pet drawer tab", "input"],
            ["pet_upgrade", "Pet upgrade: not implemented", "todo"],
            ["workshop", "Workshop: not implemented", "todo"]]},
        {name: "Calibration", help: "Uses the main bot's exact wizard and saves to the same config.ini. Hover over each requested point in the game and press Space; Enter finishes, Esc cancels.", items: [
            ["calibrate_main", "Start Main calibration", "calibration"],
            ["calibrate_bb", "Start Builder Base calibration", "calibration"],
            ["calibrate_cancel", "Cancel calibration", "calibration"]]},
        {name: "Inspect", help: "Read-only checks. Results are observations, not a claim that an upgrade succeeded.", items: [
            ["connection", "Test ADB connection", "read"], ["calibration", "Validate calibration", "read"],
            ["screenshot", "Capture current frame", "read"], ["village", "Detect village", "read"],
            ["thresholds", "Read resource thresholds", "read"], ["builders", "Read free builders", "read"],
            ["lab", "Read laboratory status", "read"], ["loot", "Read available loot", "read"],
            ["clouds", "Detect clouds", "read"], ["troop_counts", "Read troop counts", "read"],
            ["reload_scan", "Find Reload button", "read"], ["home_check", "Detect home screen", "read"],
            ["timer", "Read auto-stop timer", "read"]]},
        {name: "Navigation", help: "Live inputs. Put the game on the matching screen first; each button runs once.", items: [
            ["clear", "Clear: left side + Dark Elixir", "input"], ["reset", "Reset zoom + position", "input"],
            ["pinch", "Zoom out only", "input"], ["pan", "Pan toward top-left once", "input"],
            ["attack", "Tap Battle / Attack", "input"], ["find_match", "Tap Find a Match", "input"],
            ["attack_start", "Tap green Attack!", "input"], ["next", "Tap Next base", "input"],
            ["return_tap", "Tap Return Home once", "input"], ["escape", "Send Android Back", "input"],
            ["collector", "Tap selected collector", "input"], ["recover", "Reopen Clash from launcher", "input"],
            ["reload_tap", "Tap found Reload button", "input"]]},
        {name: "Upgrades", help: "Open the drawer through the Builder count icon first, read a candidate, then select it. Confirm Upgrade is a separate live input that can spend resources.", items: [
            ["open_drawer", "Open drawer via Builder count", "input"], ["builder_badge", "Tap Builder count badge", "input"],
            ["lab_badge", "Tap Lab count badge", "input"], ["builder_tab", "Tap Builder drawer tab", "input"],
            ["lab_tab", "Tap Laboratory drawer tab", "input"],
            ["builder_scan", "Read building candidate", "read"], ["builder_suggestion", "Select + confirm building (spends)", "input"],
            ["lab_scan", "Read laboratory candidate", "read"], ["lab_suggestion", "Select + confirm lab (spends)", "input"],
            ["info_scan", "Find building Info button", "read"], ["info_tap", "Tap found Info button", "input"],
            ["upgrade_scan", "Find Upgrade hammer", "read"], ["upgrade_tap", "Tap found Upgrade hammer", "input"],
            ["confirm", "Confirm Upgrade (spends)", "input"], ["close_drawer", "Close upgrade drawer", "input"]]},
        {name: "Walls", help: "Select a wall in the game first. These buttons isolate the calibrated wall controls; resource/confirm buttons can spend resources.", items: [
            ["wall_find", "Find + select wall suggestion", "input"], ["wall_more", "Tap Upgrade More", "input"],
            ["wall_add", "Tap Add Wall (+1)", "input"], ["wall_remove", "Tap Remove Wall (-1)", "input"],
            ["wall_gold", "Tap Gold upgrade (spends)", "input"], ["wall_elixir", "Tap Elixir upgrade (spends)", "input"],
            ["confirm", "Tap upgrade confirmation", "input"], ["wall_state", "Read wall eligibility", "read"]]},
        {name: "Slots", help: "Select only. These buttons use the bot's raw ADB slot taps plus its Android keyevents; they do not deploy on the map.", items: [
            ["slot:1", "Select troop 1", "input"], ["slot:2", "Select troop 2", "input"], ["slot:3", "Select troop 3", "input"],
            ["slot:z", "Select siege (Z)", "input"], ["slot:q", "Select hero Q", "input"], ["slot:w", "Select hero W", "input"],
            ["slot:e", "Select hero E", "input"], ["slot:r", "Select hero R", "input"],
            ["slot:a", "Select spell A", "input"], ["slot:s", "Select spell S", "input"]]},
        {name: "Deploy", help: "Choose a side above. Draw targets sends no input. Single casts isolate spell placement; line buttons use the bot's full deployment counts.", items: [
            ["draw_side", "Draw side + shifted spell line", "draw"], ["deploy:1", "Deploy troop 1 line", "input"],
            ["deploy:2", "Deploy troop 2 line", "input"], ["deploy:3", "Deploy troop 3 line", "input"],
            ["deploy:z", "Deploy siege once", "input"], ["deploy:q", "Deploy hero Q once", "input"],
            ["deploy:w", "Deploy hero W once", "input"], ["deploy:e", "Deploy hero E once", "input"],
            ["deploy:r", "Deploy hero R once", "input"], ["cast:a", "Cast spell A once", "input"],
            ["cast:s", "Cast spell S once", "input"], ["spell_line:a", "Deploy full spell A line", "input"],
            ["spell_line:s", "Deploy full spell S line", "input"], ["place_start", "Tap side start (current unit)", "input"],
            ["place_end", "Tap side end (current unit)", "input"]]},
        {name: "Abilities", help: "Use during an attack after the corresponding hero has deployed. Buttons send exactly the production hero-ability inputs.", items: [
            ["ability:q", "Trigger hero Q ability", "input"], ["ability:w", "Trigger hero W ability", "input"],
            ["ability:e", "Trigger hero E ability", "input"], ["ability:r", "Trigger hero R ability", "input"]]},
        {name: "Builder", help: "Builder Base coordinates must be calibrated. Prepare the matching phase before deploying; tests never start the Builder loop.", items: [
            ["bb_attack", "Tap Builder Attack", "input"], ["bb_match", "Tap Builder Find Match", "input"],
            ["bb_zoom", "Prepare Builder viewport", "input"], ["bb_draw", "Draw Builder deployment side", "draw"],
            ["bb_phase1", "Deploy phase 1 troops", "input"], ["bb_phase2", "Deploy phase 2 troops", "input"],
            ["bb_stars", "Read Builder stars", "read"], ["bb_home", "Detect Builder home", "read"],
            ["return_tap", "Tap Return Home once", "input"]]}
    ]
}

CreateClickVisualizerGUI() {
    global MyGui, LogEdit, StatusText, StartBtn, PauseBtn
    global VisualizerStageText, VisualizerMarkCountText, VisualizerActionButtons
    global VisualizerSideChoice, VisualizerCollectorChoice, VisualizerResultText, VisualizerNote
    global VisualizerReviewButtons
    global CalibrationText, TextCollectorCount
    MyGui := Gui("+AlwaysOnTop", "CoC Manual Click Visualizer")
    MyGui.SetFont("s10", "Segoe UI")
    MyGui.Add("Text", "x18 y12 w710 h25", "Watch complete paths run").SetFont("s14 bold")
    MyGui.Add("Text", "x18 y43 w710 h21", "Overview runs whole paths. Pink: taps | cyan: gestures | yellow box + eye: reads.")
    StatusText := MyGui.Add("Text", "x18 y70 w710 h22", "STATUS: IDLE - choose a test")
    StatusText.SetFont("bold")
    MyGui.Add("Text", "x18 y104 w40 h22", "Side:")
    VisualizerSideChoice := MyGui.Add("DropDownList", "x58 y100 w160 Choose1", ["1 / Bottom-right", "2 / Bottom-left", "3 / Top-left", "4 / Top-right"])
    MyGui.Add("Text", "x234 y104 w67 h22", "Collector:")
    VisualizerCollectorChoice := MyGui.Add("Edit", "x303 y100 w45 h25 Number", "1")
    clearBtn := MyGui.Add("Button", "x386 y97 w140 h30", "Clear marks")
    clearBtn.OnEvent("Click", (*) => ClearOverlayMarks())
    PauseBtn := MyGui.Add("Button", "x540 y97 w188 h30", "Stop test (Ctrl+Shift+F2)")
    PauseBtn.OnEvent("Click", (*) => StopClickVisualizerStage())
    groups := ManualVisualizerGroups(), names := []
    for group in groups
        names.Push(group.name)
    tabs := MyGui.Add("Tab3", "x18 y140 w710 h320", names)
    VisualizerActionButtons := []
    for index, group in groups {
        tabs.UseTab(index)
        MyGui.Add("Text", "x30 y174 w680 h44 +Wrap", group.help)
        for itemIndex, item in group.items {
            col := Mod(itemIndex - 1, 3), row := (itemIndex - 1) // 3
            button := MyGui.Add("Button", "x" (30 + col * 230) " y" (224 + row * 36) " w218 h30", item[2])
            button.Enabled := item[3] != "todo"
            button.OnEvent("Click", QueueVisualizerAction.Bind(item[1], item[2], item[3]))
            VisualizerActionButtons.Push({control: button, available: item[3] != "todo", id: item[1]})
        }
        if (group.name == "Calibration") {
            CalibrationText := MyGui.Add("Text", "x30 y267 w680 h142 +Border +Wrap", "Calibration is inactive. Main: 30 steps. Builder Base: 13 steps.`n`nFor troop placement, choose both endpoints so the entire line is outside the red area, with room for tap jitter.`n`nSpell shift is now 75 ADB pixels per axis toward the center.")
            MyGui.Add("Text", "x30 y423 w180 h22", "Registered collectors:")
            TextCollectorCount := MyGui.Add("Text", "x215 y423 w80 h22", String(CollectorCoords.Length))
        }
    }
    tabs.UseTab()
    StartBtn := VisualizerActionButtons[1].control
    VisualizerStageText := MyGui.Add("Text", "x18 y472 w530 h22", "Last test: none")
    VisualizerMarkCountText := MyGui.Add("Text", "x552 y472 w176 h22 +Right", "Visible marks: 0")
    VisualizerResultText := MyGui.Add("Edit", "x18 y498 w710 h46 ReadOnly +Multi", "Choose an action, inspect the game and marks, then record your verdict below.")
    VisualizerNote := MyGui.Add("Edit", "x18 y555 w398 h28", "")
    DllCall("user32\SendMessageW", "ptr", VisualizerNote.Hwnd, "uint", 0x1501, "ptr", true, "wstr", "What happened? Optional note for this test")
    passBtn := MyGui.Add("Button", "x428 y553 w142 h31", "Works")
    failBtn := MyGui.Add("Button", "x582 y553 w146 h31", "Needs fix")
    passBtn.OnEvent("Click", (*) => RecordVisualizerVerdict("WORKS"))
    failBtn.OnEvent("Click", (*) => RecordVisualizerVerdict("NEEDS_FIX"))
    VisualizerReviewButtons := [passBtn, failBtn]
    for button in VisualizerReviewButtons
        button.Enabled := false
    LogEdit := MyGui.Add("Edit", "x18 y596 w710 h96 ReadOnly +Multi +WantReturn -Wrap", "")
    MyGui.Add("Text", "x18 y699 w710 h20", "Verdicts: scratch\visualizer_review.tsv    |    Exact inputs: scratch\visualizer_inputs.log")
    MyGui.OnEvent("Close", (*) => ExitApp())
    MyGui.Show("w748 h728")
}

QueueVisualizerAction(id, label, mode, *) {
    global VisualizerStageRunning, VisualizerLastAction, VisualizerLastLabel, VisualizerLastMode
    global VisualizerInputCount, VisualizerInputFailed, VisualizerCancelled, StatusText, VisualizerStageText
    global VisualizerNote, VisualizerReviewButtons, VisualizerCache
    global IsCalibrating, IsBBCalibrating
    if VisualizerStageRunning
        return
    if (mode == "calibration") {
        HandleManualVisualizerCalibration(id)
        return
    }
    if (IsCalibrating || IsBBCalibrating)
        return
    VisualizerStageRunning := true
    VisualizerLastAction := id, VisualizerLastLabel := label, VisualizerLastMode := mode
    VisualizerInputCount := 0, VisualizerInputFailed := false, VisualizerCancelled := false
    ; Cached OCR points are valid only through their immediate follow-up tap.
    if !RegExMatch(id, "^(builder_suggestion|lab_suggestion|info_tap|upgrade_tap|reload_tap)$")
        VisualizerCache := Map()
    VisualizerNote.Value := ""
    ClearOverlayMarks()
    SetManualVisualizerButtons(false)
    for button in VisualizerReviewButtons
        button.Enabled := false
    StatusText.Value := "STATUS: RUNNING - " label
    VisualizerStageText.Value := "Last test: " id
    SetTimer(RunManualVisualizerAction, -10)
}

SetManualVisualizerButtons(enabled) {
    global VisualizerActionButtons, VisualizerSideChoice, VisualizerCollectorChoice
    global IsCalibrating, IsBBCalibrating
    calibrating := IsCalibrating || IsBBCalibrating
    for entry in VisualizerActionButtons
        entry.control.Enabled := enabled && entry.available && (!calibrating || entry.id == "calibrate_cancel")
    VisualizerSideChoice.Enabled := enabled && !calibrating
    VisualizerCollectorChoice.Enabled := enabled && !calibrating
}

HandleManualVisualizerCalibration(id) {
    global VisualizerStageRunning, IsCalibrating, IsBBCalibrating, MyGui, StatusText
    if VisualizerStageRunning
        return
    if (id == "calibrate_cancel") {
        if IsCalibrating
            CancelCalibration()
        if IsBBCalibrating
            CancelBBCalibration()
        UpdateManualVisualizerCalibrationState()
        return
    }
    if (IsCalibrating || IsBBCalibrating)
        return
    WinSetAlwaysOnTop(false, MyGui.Hwnd)
    ClearOverlayMarks()
    if (id == "calibrate_main")
        StartCalibration()
    else
        StartBBCalibration()
    if (IsCalibrating || IsBBCalibrating) {
        StatusText.Value := "STATUS: CALIBRATING - hover in game and press Space"
        SetTimer(UpdateManualVisualizerCalibrationState, 250)
    }
    UpdateManualVisualizerCalibrationState()
}

UpdateManualVisualizerCalibrationState() {
    global IsCalibrating, IsBBCalibrating, MyGui, StatusText, VisualizerCalibrationWasActive
    active := IsCalibrating || IsBBCalibrating
    SetManualVisualizerButtons(true)
    if !active {
        SetTimer(UpdateManualVisualizerCalibrationState, 0)
        WinSetAlwaysOnTop(true, MyGui.Hwnd)
        if VisualizerCalibrationWasActive
            StatusText.Value := "STATUS: IDLE - calibration finished or cancelled"
    }
    VisualizerCalibrationWasActive := active
}

RunManualVisualizerAction() {
    global IsRunning, IsBBRunning, IsStarting, VisualizerStageRunning, VisualizerCancelled
    global VisualizerLastAction, VisualizerLastLabel, VisualizerLastMode, VisualizerInputCount, VisualizerInputFailed
    global VisualizerResultText, StatusText, VisualizerReviewButtons
    global VisualizerActionExecuting, ADBBBCalibrationVersion, ADB_COORDINATE_VERSION
    VisualizerActionExecuting := true
    IsRunning := true, IsBBRunning := false
    LogMessage("MANUAL BEGIN [" VisualizerLastAction "] " VisualizerLastLabel)
    try {
        if !RegExMatch(VisualizerLastAction, "^(connection|calibration|screenshot|recover)$") {
            ready := EnsureADBConnection()
            if !ready.Ok
                throw Error(ready.Message)
            if !IsClashForeground(ready.Serial)
                throw Error("Clash is not open. Use Navigation > Reopen Clash from launcher first.")
            mapping := ValidateADBViewportRuntime()
            if !mapping.Ok
                throw Error(mapping.Message)
            if RegExMatch(VisualizerLastAction, "^(bb_|path_bb$)") && ADBBBCalibrationVersion != ADB_COORDINATE_VERSION
                throw Error("Builder Base calibration is missing or stale. Calibrate it in the main bot first.")
        }
        result := DispatchManualVisualizerAction(VisualizerLastAction)
        if VisualizerCancelled
            throw Error("Stopped by you.")
        if VisualizerInputFailed
            throw Error("At least one ADB input failed. Check the log.")
        summary := FormatManualVisualizerResult(result)
        VisualizerResultText.Value := summary "`r`nADB input commands: " VisualizerInputCount ". Inspect the game, then choose Works or Needs fix."
        StatusText.Value := "STATUS: FINISHED - awaiting your verdict"
        LogMessage("MANUAL RESULT [" VisualizerLastAction "] " summary)
    } catch as err {
        VisualizerResultText.Value := err.Message
        StatusText.Value := VisualizerCancelled ? "STATUS: STOPPED" : "STATUS: ERROR - see result"
        LogMessage("MANUAL ERROR [" VisualizerLastAction "] " err.Message)
    } finally {
        IsRunning := false, IsBBRunning := false, IsStarting := false
        VisualizerStageRunning := false
        VisualizerActionExecuting := false
        SetManualVisualizerButtons(true)
        for button in VisualizerReviewButtons
            button.Enabled := true
        LogMessage("MANUAL END. No next action is scheduled.")
    }
}

FormatManualVisualizerResult(value, depth := 0) {
    if (depth > 3)
        return "..."
    if IsObject(value) {
        output := ""
        if (value is Array) {
            for index, item in value
                output .= (output == "" ? "" : "; ") index ": " FormatManualVisualizerResult(item, depth + 1)
        } else {
            for key, item in value.OwnProps()
                output .= (output == "" ? "" : "; ") key "=" FormatManualVisualizerResult(item, depth + 1)
        }
        return output == "" ? "No details returned." : output
    }
    if (value == "")
        return "Action returned no result; inspect the log and game."
    if (depth > 0)
        return String(value)
    if (Type(value) == "Integer")
        return value ? "Returned TRUE (not yet visually verified)." : "Returned FALSE: no match, skipped, or failed. See log."
    return String(value)
}

TraceManualVisualizerInput(arguments) {
    global VisualizerStageRunning, VisualizerInputCount, VisualizerLastAction
    if !VisualizerStageRunning
        return
    VisualizerInputCount += 1
    line := FormatTime(, "yyyy-MM-dd HH:mm:ss") "`t" VisualizerLastAction "`t" arguments "`n"
    DirCreate(A_ScriptDir "\scratch")
    FileAppend(line, A_ScriptDir "\scratch\visualizer_inputs.log", "UTF-8")
    LogMessage("ADB INPUT " VisualizerInputCount ": " arguments)
}

RecordVisualizerVerdict(verdict) {
    global VisualizerStageRunning, VisualizerLastAction, VisualizerNote, VisualizerResultText, StatusText
    if VisualizerStageRunning || VisualizerLastAction == ""
        return
    note := RegExReplace(VisualizerNote.Value, "[\t\r\n]+", " ")
    result := RegExReplace(VisualizerResultText.Value, "[\t\r\n]+", " ")
    path := A_ScriptDir "\scratch\visualizer_review.tsv"
    if !FileExist(path)
        FileAppend("time`taction`tverdict`tnote`tresult`n", path, "UTF-8")
    FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") "`t" VisualizerLastAction "`t" verdict "`t" note "`t" result "`n", path, "UTF-8")
    StatusText.Value := "STATUS: SAVED " verdict " - " VisualizerLastAction
    LogMessage("YOUR VERDICT [" VisualizerLastAction "] " verdict " " note)
}

PlayVisualizerStage() {
    LogMessage("Choose a named action button. Keyboard Start does not run a farming loop.")
}

StopClickVisualizerStage() {
    global IsRunning, IsBBRunning, IsStarting, VisualizerCancelled, StatusText
    VisualizerCancelled := true
    IsRunning := false, IsBBRunning := false, IsStarting := false
    global VisualizerActionExecuting, VisualizerStageRunning
    SetTimer(RunManualVisualizerAction, 0)
    SetTimer(StartBotLoop, 0)
    SetTimer(RunBuilderBaseLoop, 0)
    StatusText.Value := "STATUS: STOP REQUESTED"
    if !VisualizerActionExecuting {
        VisualizerStageRunning := false
        SetManualVisualizerButtons(true)
        StatusText.Value := "STATUS: STOPPED"
    }
    LogMessage("Stop requested. No more tests will be started.")
    ; Reset the controller even if an OCR call or nested path has not unwound yet.
    ; Reload exits the old AHK threads and opens an idle manual panel.
    Reload()
}

DispatchManualVisualizerAction(id) {
    global Sides, BBSides, CollectorCoords, VisualizerSideChoice, VisualizerCollectorChoice, VisualizerCache
    global BuilderFaceX, BuilderFaceY, LabFaceX, LabFaceY
    global DrawerTabBuilderX, DrawerTabLabX, DrawerTabPetX, DrawerTabY, ReturnHomeClickX, ReturnHomeClickY
    global UpgradeMoreBtnX, UpgradeMoreBtnY, AddWall1X, AddWall1Y, RemoveWallX, RemoveWallY
    global GoldUpgradeX, GoldUpgradeY, ElixirUpgradeX, ElixirUpgradeY, EnableWallUpgrade
    global MinGold, MinElixir, MAIN_SPELL_INWARD_OFFSET_PIXELS
    global TimerDurationMs, TimerStartTick, IsRunning, IsBBRunning
    primitives := LiveADBFlowPrimitives()
    operations := CreateADBMainFlowSections(primitives)
    sideIndex := VisualizerSideChoice.Value
    side := Sides[sideIndex]
    sideName := "side" sideIndex
    if RegExMatch(id, "^(slot|ability|deploy|cast|spell_line):(.+)$", &match) {
        key := match[2]
        switch match[1] {
            case "slot", "ability":
                return SendKey(key)
            case "deploy":
                return primitives.DeployMain(key, sideName)
            case "spell_line":
                return primitives.DeploySpell(key, sideName, MAIN_SPELL_INWARD_OFFSET_PIXELS)
            case "cast":
                if !SendKey(key)
                    return false
                return RunADBShiftedPlacementAt((side.startX + side.endX) / 2,
                    (side.startY + side.endY) / 2, MAIN_SPELL_INWARD_OFFSET_PIXELS, 200)
        }
    }
    switch id {
        case "connection": return EnsureADBConnection(true)
        case "calibration": return ValidateADBViewportRuntime()
        case "screenshot": return "Fresh frame: " CaptureADBFrame(true)
        case "village": return operations.Do("detect_village")
        case "thresholds": return operations.Do("check_resource_thresholds")
        case "builders": return ReadBuilderAvailabilityFromADBFrame(CaptureADBFrame(true))
        case "lab": return ReadLabAvailabilityFromADBFrame(CaptureADBFrame(true))
        case "loot": return ReadLootFromADBFrame(CaptureADBFrame(true))
        case "clouds": return AreCloudsPresentInADBFrame(CaptureADBFrame(true))
        case "troop_counts": return GetTroopCountsBattle()
        case "reload_scan": return CacheManualVisualizerPoint("reload", FindReloadActionFromADBFrame(primitives.CaptureFreshFrame("reload")))
        case "home_check": return DetectVillageFromADBFrame(CaptureADBFrame(true)) == "main"
        case "timer": return {durationMs: TimerDurationMs, startedAt: TimerStartTick, elapsed: IsTimerUp()}
        case "reload_tap": return TapLiveReloadAction(GetManualVisualizerPoint("reload"))
        case "clear": return FlowClearTap()
        case "reset":
            ResetViewport()
            return "Viewport sequence finished. Inspect zoom and position."
        case "pinch":
            viewport := GetADBClientViewportRect()
            return RunADBPinchAt(viewport.x + viewport.width / 2, viewport.y + viewport.height / 2)
        case "pan":
            viewport := GetADBClientViewportRect()
            return RunADBSwipeAt(viewport.x + viewport.width * 0.25, viewport.y + viewport.height * 0.25,
                viewport.x + viewport.width * 0.75, viewport.y + viewport.height * 0.75, 200)
        case "attack": return primitives.TapMainAttack()
        case "find_match": return primitives.TapFindMatch()
        case "attack_start": return primitives.TapAttackStart()
        case "next": return primitives.TapNextMatch()
        case "return_tap": return RunADBTapAt(ReturnHomeClickX, ReturnHomeClickY, 200)
        case "escape":
            interaction := CreateLiveADBClientInteraction()
            interaction.KeyEvent("KEYCODE_BACK", 100)
            return "Android Back sent."
        case "collector":
            index := Integer(VisualizerCollectorChoice.Value)
            if (index < 1 || index > CollectorCoords.Length)
                throw Error("Collector index must be between 1 and " CollectorCoords.Length ".")
            return primitives.TapCollector(index)
        case "recover": return EnsureClashAppForeground(GetSelectedADBSerial())
        case "open_drawer": return OpenUpgradeDrawer("builder")
        case "builder_badge": return OpenUpgradeDrawer("builder")
        case "lab_badge": return OpenUpgradeDrawer("lab")
        case "builder_tab": return RunADBTapAt(DrawerTabBuilderX, DrawerTabY, 200)
        case "lab_tab": return RunADBTapAt(DrawerTabLabX, DrawerTabY, 200)
        case "pet_tab": return RunADBTapAt(DrawerTabPetX, DrawerTabY, 200)
        case "builder_scan": return CacheManualVisualizerPoint("builder", FindUpgradeRow("builder"))
        case "lab_scan": return CacheManualVisualizerPoint("lab", FindUpgradeRow("lab"))
        case "builder_suggestion": return SelectAndConfirmVisualizerUpgrade("builder")
        case "lab_suggestion": return SelectAndConfirmVisualizerUpgrade("lab")
        case "info_scan": return CacheManualVisualizerPoint("info", FindBuilderInfoFromADBFrame(CaptureADBFrame(true)))
        case "info_tap": return primitives.TapBuilderInfo(GetManualVisualizerPoint("info"))
        case "upgrade_scan":
            x := 0, y := 0
            if !FindTemplateUpgradeButton(&x, &y)
                return "No Upgrade hammer matched. Nothing clicked."
            return CacheManualVisualizerPoint("upgrade", {x: x, y: y})
        case "upgrade_tap":
            point := GetManualVisualizerPoint("upgrade")
            return RunADBTapAt(point.x, point.y, 200)
        case "confirm": return primitives.TapUpgradeConfirm()
        case "close_drawer": return primitives.CloseDrawer()
        case "wall_find": return FindAnyWallInDropdown()
        case "wall_more": return RunADBTapAt(UpgradeMoreBtnX, UpgradeMoreBtnY, 200)
        case "wall_add": return RunADBTapAt(AddWall1X, AddWall1Y, 200)
        case "wall_remove": return RunADBTapAt(RemoveWallX, RemoveWallY, 200)
        case "wall_gold": return RunADBTapAt(GoldUpgradeX, GoldUpgradeY, 200)
        case "wall_elixir": return RunADBTapAt(ElixirUpgradeX, ElixirUpgradeY, 200)
        case "wall_state": return primitives.ReadWallState(primitives.CaptureFreshFrame("walls"))
        case "draw_side": return DrawManualVisualizerSide(side, true)
        case "place_start": return RunADBTapAt(side.startX, side.startY, 200)
        case "place_end": return RunADBTapAt(side.endX, side.endY, 200)
        case "bb_attack": return LiveBuilderBasePrimitives().Do("tap_builder_attack")
        case "bb_match": return LiveBuilderBasePrimitives().Do("tap_builder_find_match")
        case "bb_zoom":
            ZoomOutBB()
            return "Builder viewport sequence finished. Inspect the game."
        case "bb_draw": return DrawManualVisualizerSide(BBSides[sideIndex], false)
        case "bb_phase1", "bb_phase2":
            DeployBBTroops(BBSides[sideIndex], id == "bb_phase1" ? 1 : 2)
            return "Builder deployment inputs finished. Inspect the game."
        case "bb_stars": return AnalyzeLiveBuilderBaseThreeStars(CaptureLiveBuilderBaseFrame("manual"))
        case "bb_home": return DetectLiveBuilderBaseHome(CaptureLiveBuilderBaseFrame("manual"))
        case "path_cycle": return RunManualVisualizerCycle()
        case "path_bb":
            IsRunning := false, IsBBRunning := true
            return BuilderBaseFlow(LiveBuilderBasePrimitives()).Attack()
        case "path_builder": return operations.Do("run_builder_upgrade", operations.Do("check_resource_thresholds"), EnableWallUpgrade)
        case "path_lab": return operations.Do("run_lab_upgrade", operations.Do("check_resource_thresholds"))
        case "path_walls":
            if !EnableWallUpgrade
                return "Skipped: wall upgrades are disabled in config.ini. Individual wall buttons remain available."
            return operations.Do("run_wall_upgrades", operations.Do("check_resource_thresholds"), true)
        case "path_collect":
            for index, point in CollectorCoords {
                if !primitives.TapCollector(index)
                    return false
            }
            return "Tapped " CollectorCoords.Length " collectors (no random collection roll)."
        case "path_enter": return operations.Do("enter_main_battle")
        case "path_search": return operations.Do("find_eligible_base", MinGold, MinElixir)
        case "path_attack": return operations.Do("attack_main_base")
        case "path_return": return operations.Do("return_main_home")
        case "path_home":
            RunVisualizerHomeStage()
            return "Home stage finished once. Automatic continuation is off."
        case "path_battle":
            RunVisualizerAttackStage()
            return "Attack stage finished once. Automatic continuation is off."
    }
    throw Error("Manual action has no implementation: " id)
}

CacheManualVisualizerPoint(key, point) {
    global VisualizerCache
    if !IsObject(point)
        return "No match found. Nothing clicked."
    VisualizerCache[key] := {point: point, capturedAt: A_TickCount}
    if point.HasOwnProp("x") && point.HasOwnProp("y")
        AddVisualizerTapJitter(point.x, point.y)
    return point
}

GetManualVisualizerPoint(key) {
    global VisualizerCache
    if !VisualizerCache.Has(key) || A_TickCount - VisualizerCache[key].capturedAt > 30000
        throw Error("Run the matching Find button on the current screen first (within 30 seconds).")
    point := VisualizerCache[key].point
    VisualizerCache.Delete(key)
    return point
}

DrawManualVisualizerSide(side, includeSpells) {
    global MAIN_SPELL_INWARD_OFFSET_PIXELS
    start := ClientToADBPoint(side.startX, side.startY)
    finish := ClientToADBPoint(side.endX, side.endY)
    AddVisualizerADBLine(start.x, start.y, finish.x, finish.y)
    if includeSpells {
        shiftedStart := ResolveVisualizerShiftedADBPoint(side.startX, side.startY, MAIN_SPELL_INWARD_OFFSET_PIXELS)
        shiftedEnd := ResolveVisualizerShiftedADBPoint(side.endX, side.endY, MAIN_SPELL_INWARD_OFFSET_PIXELS)
        AddVisualizerADBLine(shiftedStart.x, shiftedStart.y, shiftedEnd.x, shiftedEnd.y)
        AddVisualizerADBLine(start.x, start.y, shiftedStart.x, shiftedStart.y)
        AddVisualizerADBLine(finish.x, finish.y, shiftedEnd.x, shiftedEnd.y)
        return "Draw only; no input sent. Deployment line ADB (" start.x ", " start.y ") to (" finish.x ", " finish.y
            . "). Spell line (" shiftedStart.x ", " shiftedStart.y ") to (" shiftedEnd.x ", " shiftedEnd.y ")."
    }
    return "Draw only; no input sent. Builder side ADB (" start.x ", " start.y ") to (" finish.x ", " finish.y ")."
}

RunManualVisualizerCycle() {
    global VisualizerStageText
    VisualizerStageText.Value := "Shared cycle: Home > farming > Attack > deployment > Return Home"
    ADBRefactorFlowAPI.RunMainCycle(CreateADBMainFlowSections(LiveADBFlowPrimitives()), GetLiveMainCycleState())
    LogMessage("FULL CYCLE COMPLETE: returned home. No next cycle scheduled.")
    return "Shared Main cycle finished once. Review the click trail and log."
}

SelectAndConfirmVisualizerUpgrade(kind) {
    candidate := FindUpgradeRow(kind, false, true)
    if !IsObject(candidate)
        return false
    primitives := LiveADBFlowPrimitives()
    primitives.TapSuggestion(candidate)
    if !primitives.TapUpgradeConfirm()
        return false
    if kind == "builder" {
        if !SafeFlowWait(300)
            return false
        if !primitives.TapUpgradeConfirm()
            return false
    }
    return candidate
}
