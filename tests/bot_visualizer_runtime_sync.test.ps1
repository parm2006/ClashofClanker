$ErrorActionPreference = 'Stop'
$main = Get-Content -Raw (Join-Path $PSScriptRoot '..\ADBcoc_bot.ahk')
$visualizer = Get-Content -Raw (Join-Path $PSScriptRoot '..\ADBcoc_bot_click_visualizer.ahk')

function Get-RuntimeBlock([string]$source, [string]$name) {
    $start = [regex]::Match($source, "(?m)^(?:class )?$name(?:\([^\r\n]*\)|[^\r\n]*)\s*\{")
    if (!$start.Success) { throw "Missing runtime function/class: $name" }
    $tail = $source.Substring($start.Index)
    $end = [regex]::Match($tail, '(?m)^\}')
    if (!$end.Success) { throw "Missing closing brace: $name" }
    return (($tail.Substring(0, $end.Index + 1) -split '\r?\n') | ForEach-Object { $_.Trim() }) -join "`n"
}

$sharedBehavior = @(
    'LoadConfig', 'SaveConfig', 'ResolveADBSerial', 'ValidateBlueStacksSerial',
    'GetSelectedADBSerial', 'EnsureADBConnection', 'GetADBDisplaySize', 'IsClashForeground',
    'GetBuilderCount', 'IsLabBusy', 'GetBuilderCropRegion', 'GetLabCropRegion',
    'ReadBuilderAvailabilityFromADBFrame', 'ReadLabAvailabilityFromADBFrame',
    'FindFlowSuggestedUpgrade', 'ReadResourceThresholdsFromADBFrame', 'IsDarkElixirBarFilled', 'ReadLootValueFromADBFrame', 'ReadLootFromADBFrame',
    'FindTemplateUpgradeButton', 'DeployTroopLine', 'DeploySinglePoint',
    'DeployShiftedSpellLine', 'SelectBattleSlot', 'SendKey', 'CloseDrawer', 'FlowClearTap',
    'LiveADBFlowPrimitives', 'LiveBuilderBasePrimitives', 'StartBotLoop', 'RunBuilderBaseLoop'
)
foreach ($name in $sharedBehavior) {
    if ((Get-RuntimeBlock $main $name) -cne (Get-RuntimeBlock $visualizer $name)) {
        throw "Bot/visualizer gameplay differs: $name"
    }
}
$clear = Get-RuntimeBlock $main 'FlowClearTap'
if ($clear -notmatch 'RunADBTapAt\(WarLogoX, WarLogoY, 200\)' -or
    $clear -notmatch 'RunADBTapAt\(oppositeX, WarLogoY, 200\)' -or
    !$clear.Contains('viewport.x + viewport.width - 1 - (WarLogoX - viewport.x)')) {
    throw 'Clearing must tap both the mirrored left point and calibrated Dark Elixir point inside the Android viewport.'
}
$support = Get-Content -Raw (Join-Path $PSScriptRoot '..\ADBcocbotrefactor_support.ahk')
$manual = Get-Content -Raw (Join-Path $PSScriptRoot '..\visualizer_manual_actions.ahk')
if ($support -notmatch '(?s)RunMainLoop\(operations, state\)\s*\{\s*return this.RunMainCycle\(operations, state, true\)' -or
    $manual -notmatch 'ADBRefactorFlowAPI.RunMainCycle\(' -or
    $visualizer -notmatch 'ADBRefactorFlowAPI.RunHomeStage\(' -or
    $visualizer -notmatch 'ADBRefactorFlowAPI.RunAttackStage\(') {
    throw 'The actual bot and visualizer cycle entry points must delegate to the same shared stages.'
}
foreach ($source in @($main, $visualizer)) {
    if ($source -notmatch '#include "bot_runtime.ahk"' -or
        $source -notmatch 'exitCode := RunADBProcess\(' -or
        $source -notmatch 'state := GetLiveMainCycleState\(\)') {
        throw 'Both frontends must use the same cycle state and bounded ADB execution.'
    }
}
if ($support -match 'operations.Do\("(?:check_pet_house|run_pet_upgrade)"') {
    throw 'Unimplemented pet/workshop placeholders must not run in the automatic farming cycle.'
}
Write-Host "PASS: shared cycle entry points, bounded ADB runtime, and $($sharedBehavior.Count) gameplay/config blocks match."
