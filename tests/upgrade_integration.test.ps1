$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot '..'
$main = Get-Content (Join-Path $root 'ADBcoc_bot.ahk') -Raw
$visualizer = Get-Content (Join-Path $root 'ADBcoc_bot_click_visualizer.ahk') -Raw
$manual = Get-Content (Join-Path $root 'visualizer_manual_actions.ahk') -Raw
foreach ($source in @($main, $visualizer)) {
    if ($source -notmatch '(?s)OpenUpgradeMenu\(menuKind\) \{\s*return OpenUpgradeDrawer\(menuKind\)\s*\}') {
        throw 'Both apps must open upgrade menus through the same shared badge action.'
    }
    if (!$source.Contains('#include "upgrade_rows.ahk"') -or
        $source -notmatch '(?s)FindFlowSuggestedUpgrade\(menuKind\) \{\s*return FindUpgradeRow\(menuKind, false, true\)\s*\}') {
        throw 'Both apps must use the shared promoted upgrade selector.'
    }
    if ($source.Contains('Suggested upgrades OCR " menuKind " scale')) {
        throw 'Obsolete suggestion OCR remains.'
    }
}
foreach ($kind in @('builder', 'lab')) {
    if (!$manual.Contains('return OpenUpgradeDrawer("' + $kind + '")')) {
        throw "Visualizer $kind badge must use the same opening action as the bot."
    }
}
if (!$main.Contains('AddNoUpgradesToggle(MyGui, "x35 y375 w280 h20")') -or
    $visualizer.Contains('AddNoUpgradesToggle(') -or $manual.Contains('AddNoUpgradesToggle(')) {
    throw 'No upgrades must be exposed only in the main bot Settings tab.'
}
if ($manual -match 'testing_(builder|lab)_' -or
    $manual -notmatch '(?s)name: "InTesting".*?pet_upgrade.*?workshop.*?name: "Calibration"') {
    throw 'InTesting must hold unfinished paths rather than promoted upgrade actions.'
}
Write-Output 'PASS: shared production upgrade selector, unfinished-path placement, and main-only Settings toggle.'
