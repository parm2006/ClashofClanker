global NoUpgrades := IniRead(A_ScriptDir "\config.ini", "Farming", "NoUpgrades", "0") == "1"

AddNoUpgradesToggle(window, options) {
    global NoUpgrades
    control := window.Add("Checkbox", options, "No upgrades")
    control.Value := NoUpgrades
    control.OnEvent("Click", SaveNoUpgradesToggle)
    return control
}

SaveNoUpgradesToggle(control, *) {
    global NoUpgrades
    NoUpgrades := !!control.Value
    IniWrite(NoUpgrades ? "1" : "0", A_ScriptDir "\config.ini", "Farming", "NoUpgrades")
}
