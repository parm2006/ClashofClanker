$ErrorActionPreference = 'Stop'
foreach ($script in 'ADBcoc_bot.ahk', 'ADBcoc_bot_click_visualizer.ahk') {
    $source = Get-Content -Raw (Join-Path $PSScriptRoot "..\$script")
    $uiStart = $source.IndexOf('UpdateCalibrationUI() {')
    $uiEnd = $source.IndexOf('FinishCalibration() {', $uiStart)
    $ui = $source.Substring($uiStart, $uiEnd - $uiStart)
    $inputStart = $source.IndexOf('Space:: {')
    $inputEnd = $source.IndexOf('Enter:: {', $inputStart)
    $inputBody = $source.Substring($inputStart, $inputEnd - $inputStart)
    $checks = @(
        @(3, 'Village Identifier', 'WarLogoX'),
        @(4, 'Dark Elixir Storage Bar', 'DarkElixirBarThreshX'),
        @(7, 'Builder Count Badge', 'BuilderFaceX'),
        @(8, 'Lab Count Badge', 'LabFaceX'),
        @(9, 'Wall Action Bar', 'UpgradeMoreBtnX'),
        @(29, 'Return Home Button', 'ReturnHomeClickX')
    )
    foreach ($check in $checks) {
        $step, $label, $variable = $check
        if ($ui -notmatch "case ${step}:\s*instructions := `"Step $step/30: $label") {
            throw "$script calibration step $step has the wrong prompt"
        }
        $body = [regex]::Match($inputBody, "(?s)case ${step}:\s*(.*?)(?=\s*case \d+:)").Groups[1].Value
        if ($body -notmatch "$variable := mx" -or $body -notmatch "CalibStep := $($step + 1)\b") {
            throw "$script calibration step $step does not save the prompted point or advance correctly"
        }
    }
    foreach ($coordinate in 'BuilderFaceX', 'BuilderFaceY', 'DrawerCloseBtnX', 'DrawerCloseBtnY', 'DrawerTabBuilderX', 'DrawerTabLabX', 'DrawerTabY') {
        if ($source -notmatch "global $coordinate :=" -or $source -notmatch "$coordinate := SafeInteger\(IniRead" -or $source -notmatch "IniWrite\($coordinate,") {
            throw "$script is missing default/load/save support for $coordinate"
        }
    }
}
Write-Host 'PASS: calibration prompts match captures and drawer coordinates have defaults/load/save in both controllers.'

$main = Get-Content -Raw (Join-Path $PSScriptRoot '..\ADBcoc_bot.ahk')
$visualizer = Get-Content -Raw (Join-Path $PSScriptRoot '..\ADBcoc_bot_click_visualizer.ahk')
$mainStart = $main.IndexOf('StartCalibration() {')
$visualizerStart = $visualizer.IndexOf('StartCalibration() {')
$mainWizard = $main.Substring($mainStart, $main.IndexOf('CleanNumber(str) {', $mainStart) - $mainStart)
$visualizerWizard = $visualizer.Substring($visualizerStart, $visualizer.IndexOf('CleanNumber(str) {', $visualizerStart) - $visualizerStart)
if ($mainWizard -cne $visualizerWizard) {
    throw 'The visualizer wizard must match the main calibration flow, prompts, and saving exactly.'
}
$manual = Get-Content -Raw (Join-Path $PSScriptRoot '..\visualizer_manual_actions.ahk')
foreach ($required in 'calibrate_main', 'calibrate_bb', 'calibrate_cancel', 'StartCalibration()', 'StartBBCalibration()') {
    if (!$manual.Contains($required)) {
        throw "Missing visualizer calibration control: $required"
    }
}
if ($visualizer -match 'This standalone visualizer never writes calibration') {
    throw 'Visualizer calibration hotkeys must launch the wizard, not display the old unsupported message.'
}
Write-Host 'PASS: visualizer calibration uses the same main/builder wizard and saving, with working entry controls.'
