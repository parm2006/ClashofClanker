#Requires AutoHotkey v2.0
#Warn All, StdOut
#Include "..\reload_ocr_logic.ahk"
#Include "..\loot_ocr_logic.ahk"
#Include "..\ADBcocbotrefactor_support.ahk"

try {
    state := {collectorCount: 3, wallUpgradesEnabled: false, minGold: 500000, minElixir: 500000}
    manual := TraceOperations()
    ADBRefactorFlowAPI.RunMainCycle(manual, state)
    bot := TraceOperations()
    ADBRefactorFlowAPI.RunMainLoop(bot, state)
    Assert(bot.Calls.Pop() == "finish_main_cycle", "Only the bot adds cycle completion")
    Assert(Join(manual.Calls) == Join(bot.Calls), "Manual and automatic gameplay operation order must match exactly")
    expected := ["verify_emulator", "verify_calibration", "verify_main_calibration", "clear_tap",
        "reset_main_viewport", "detect_village", "reset_main_viewport", "collect_resources",
        "check_resource_thresholds", "run_builder_upgrade", "run_wall_upgrades", "run_lab_upgrade",
        "tap_main_attack", "tap_find_match", "verify_emulator", "verify_calibration", "verify_main_calibration",
        "tap_attack_start", "find_eligible_base", "attack_main_base", "return_main_home"]
    Assert(Join(manual.Calls) == Join(expected), "Shared cycle must preserve the working visualizer sequence")
    stopped := TraceOperations("tap_find_match")
    threw := false
    try ADBRefactorFlowAPI.RunMainCycle(stopped, state)
    catch
        threw := true
    Assert(threw && !InStr(Join(stopped.Calls), "tap_attack_start"), "A stopped Home stage cannot continue into Attack")
    startup := TraceOperations()
    ADBRefactorFlowAPI.RunStartup(startup, {timerMs: 0})
    Assert(Join(startup.Calls) == "verify_emulator|verify_calibration|clear_tap|reset_main_viewport|detect_village|start_main_loop|",
        "Startup must clear menus and reset the viewport before detecting and routing the village")
    retry := TraceOperations()
    retry.Villages := ["battle", "main"]
    ADBRefactorFlowAPI.RunStartup(retry, {timerMs: 0})
    Assert(InStr(Join(retry.Calls), "detect_village|wait|detect_village|start_main_loop"), "Startup must retry a transient village mismatch")
    retry := TraceOperations()
    retry.Villages := ["battle", "battle"]
    failed := false
    try ADBRefactorFlowAPI.RunStartup(retry, {timerMs: 0})
    catch
        failed := true
    Assert(failed && retry.Villages.Length == 0, "Startup must stop after two unsuccessful detections")
    FileAppend("PASS: automatic/manual operation traces match; cancellation prevents continuation.`n", "*")
    ExitApp(0)
} catch as testFailure {
    FileAppend("FAIL: " testFailure.Message "`n", "*")
    ExitApp(1)
}

class TraceOperations {
    __New(stopAt := "") {
        this.Calls := [], this.StopAt := stopAt, this.Villages := []
    }
    Do(name, args*) {
        if (name == "log")
            return true
        this.Calls.Push(name)
        if (name == this.StopAt)
            throw Error("Stopped")
        if (name == "detect_village")
            return this.Villages.Length ? this.Villages.RemoveAt(1) : "main"
        if (name == "check_resource_thresholds")
            return {gold: true, elixir: true, darkElixir: true}
        return true
    }
}
Join(items) {
    output := ""
    for item in items
        output .= item "|"
    return output
}
Assert(condition, message) {
    if !condition
        throw Error(message)
}
InitGDIPlus() {
    throw Error("Cycle test must not touch live graphics")
}
