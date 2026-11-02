#Requires AutoHotkey v2.0
#Warn All, StdOut
#Include "..\settings_autosave.ahk"
global EditBattleLoad := {Value: "1500"}, EditButtonDelta := {Value: "5"}, EditDeployDelta := {Value: "15"}
global EditMinGold := {Value: "500000"}, EditMinElixir := {Value: "500000"}
global EditTroop1Count := {Value: "1"}, EditTroop2Count := {Value: "1"}, EditTroop3Count := {Value: "1"}
global EditBBClickCount := {Value: "1"}, EditWindow := {Value: "Android"}
global EditADBProvider := {Text: "Habumi"}, EditBlueStacksSerial := {Value: "127.0.0.1:15555"}
global GPGDE_PROVIDER := "GPGDE", saved := 0
global CheckLootSearch := false, CheckWallUpgrade := false
ApplyAndSaveSettings() {
    global saved
    saved += 1
}
ValidateBlueStacksSerial(value) {
    if !InStr(value, ":")
        throw Error("Invalid serial")
}
LogMessage(*) {
}
try {
    AutoSaveSettings()
    if saved != 1
        throw Error("Valid settings did not save")
    EditMinGold.Value := ""
    AutoSaveSettings()
    if saved != 1
        throw Error("Empty numeric edit saved")
    EditMinGold.Value := "600000"
    EditBlueStacksSerial.Value := "invalid"
    AutoSaveSettings()
    if saved != 1
        throw Error("Invalid target saved")
    EditBlueStacksSerial.Value := "127.0.0.1:15555"
    AutoSaveSettings()
    if saved != 2
        throw Error("Corrected settings did not save")
    FileAppend("PASS: autosave accepts valid edits, retains settings during incomplete/invalid edits, and resumes after correction.`n", "*")
    ExitApp(0)
} catch as testFailure {
    FileAppend("FAIL: " testFailure.Message "`n", "*")
    ExitApp(1)
}
