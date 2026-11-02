SetupSettingsAutoSave() {
    global EditWindow, EditBattleLoad, EditButtonDelta, EditDeployDelta
    global EditMinGold, EditMinElixir, CheckLootSearch, CheckWallUpgrade
    global EditTroop1Count, EditTroop2Count, EditTroop3Count, EditBBClickCount
    global EditADBProvider, EditBlueStacksSerial
    for control in [CheckLootSearch, CheckWallUpgrade]
        control.OnEvent("Click", (*) => AutoSaveSettings())
    for control in [EditWindow, EditBattleLoad, EditButtonDelta, EditDeployDelta,
        EditMinGold, EditMinElixir, EditTroop1Count, EditTroop2Count, EditTroop3Count,
        EditBBClickCount, EditADBProvider, EditBlueStacksSerial]
        control.OnEvent("Change", (*) => SetTimer(AutoSaveSettings, -400))
}

AutoSaveSettings(*) {
    global EditBattleLoad, EditButtonDelta, EditDeployDelta, EditMinGold, EditMinElixir
    global EditTroop1Count, EditTroop2Count, EditTroop3Count, EditBBClickCount
    global EditWindow, EditADBProvider, EditBlueStacksSerial, GPGDE_PROVIDER
    ; Allow temporary empty fields while typing; retain the last valid settings.
    for control in [EditBattleLoad, EditButtonDelta, EditDeployDelta, EditMinGold,
        EditMinElixir, EditTroop1Count, EditTroop2Count, EditTroop3Count, EditBBClickCount] {
        if !RegExMatch(control.Value, "^\d+$")
            return
    }
    if Trim(EditWindow.Value) == ""
        return
    try {
        if EditADBProvider.Text != GPGDE_PROVIDER
            ValidateBlueStacksSerial(EditBlueStacksSerial.Value)
        ApplyAndSaveSettings()
    } catch as err {
        LogMessage("Settings not saved: " err.Message)
    }
}
