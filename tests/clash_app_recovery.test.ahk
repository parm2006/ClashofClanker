#Requires AutoHotkey v2.0
#Warn All, StdOut
#Include "..\clash_app_recovery.ahk"

global ADB_TARGET_PACKAGE := "com.supercell.clashofclans"
global StatusText := {Value: "Status: Running Main"}
global IsRunning := true, IsBBRunning := false, IsStarting := false
global foregroundChecks := [], commands := [], cancelWait := false

try {
    foregroundChecks := [true]
    Assert(!EnsureClashAppForeground("test", TestWait), "Already-open game must not relaunch")
    Assert(commands.Length == 0, "Already-open game must not send inputs")

    foregroundChecks := [false, false, true]
    Assert(EnsureClashAppForeground("test", TestWait), "Recovery should retry and succeed")
    Assert(commands.Length == 6, "Each retry must send Home, swipe, and launch")
    Assert(InStr(commands[1], "KEYCODE_HOME"), "Home must precede drawer swipe")
    Assert(InStr(commands[2], "input swipe 640 720 640 240 400"), "Swipe must use display coordinates")
    Assert(InStr(commands[3], "com.supercell.clashofclans/com.supercell.titan.GameApp"), "Launch must target Clash")
    Assert(StatusText.Value == "Status: Running Main", "Successful recovery must restore status")

    commands := [], foregroundChecks := [false, false, false, false, false, false, false, false, false]
    failed := false
    try EnsureClashAppForeground("test", TestWait)
    catch as err
        failed := InStr(err.Message, "8 recovery attempts") > 0
    Assert(failed && commands.Length == 24, "Failed recovery must stop after eight attempts")

    commands := [], foregroundChecks := [false], cancelWait := true
    failed := false
    try EnsureClashAppForeground("test", TestWait)
    catch as err
        failed := InStr(err.Message, "cancelled") > 0
    Assert(failed, "Pause must cancel recovery")
    Assert(StatusText.Value == "Status: Paused", "Recovery must not overwrite pause status")
    FileAppend("PASS: recovery retries, display coordinates, bounds, status, and cancellation.`n", "*")
    ExitApp(0)
} catch as err {
    FileAppend("FAIL: " err.Message "`n", "*")
    ExitApp(1)
}

Assert(condition, message) {
    if !condition
        throw Error(message)
}
IsClashForeground(serial) {
    global foregroundChecks
    return foregroundChecks.RemoveAt(1)
}
GetADBDisplaySize() {
    return {width: 1280, height: 800}
}
GetSelectedADBSerial() {
    return "test"
}
RunADB(command, capture := false) {
    global commands
    commands.Push(command)
    return {Ok: true}
}
QuoteADBArgument(value) {
    return '"' value '"'
}
TestWait(milliseconds) {
    global cancelWait, IsRunning, StatusText
    if cancelWait {
        IsRunning := false
        StatusText.Value := "Status: Paused"
    }
}
LogMessage(message) {
}
FormatADBResult(result) {
    return "mock launch failure"
}

WaitForHabumiWatchdog() => false
