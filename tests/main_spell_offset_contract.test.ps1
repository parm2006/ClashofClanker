$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$supportPath = Join-Path $repoRoot 'ADBcocbotrefactor_support.ahk'
$mainPath = Join-Path $repoRoot 'ADBcoc_bot.ahk'
$visualizerPath = Join-Path $repoRoot 'ADBcoc_bot_click_visualizer.ahk'

$support = Get-Content -Raw $supportPath
$main = Get-Content -Raw $mainPath
$visualizer = Get-Content -Raw $visualizerPath

if ($support -notmatch '(?m)^global MAIN_SPELL_INWARD_OFFSET_PIXELS := 150\s*$') {
    throw 'Shared Main Village spell deployment must define a single 150-pixel-per-axis inward offset.'
}

if ($support -notmatch '(?s)AttackMainBase\(\).*?global MAIN_SPELL_INWARD_OFFSET_PIXELS.*?deploy_spell.*?MAIN_SPELL_INWARD_OFFSET_PIXELS') {
    throw 'AttackMainBase must pass the shared 150-pixel offset to deploy_spell.'
}

$visibleEntryPointNote = 'Main Village spells use a 150-pixel-per-axis inward ADB shift'
if (!$main.Contains($visibleEntryPointNote)) {
    throw 'ADBcoc_bot.ahk must visibly document its shared 150-pixel Main Village spell offset.'
}
if (!$visualizer.Contains($visibleEntryPointNote)) {
    throw 'The standalone visualizer must visibly document the same shared 150-pixel spell offset.'
}

$trackedTextFiles = @(& git -C $repoRoot ls-files -- '*.ahk' '*.md' '*.ps1' '*.txt')
if ($LASTEXITCODE -ne 0) {
    throw 'Could not enumerate tracked text files for the spell-offset documentation audit.'
}

$thisTest = 'tests/main_spell_offset_contract.test.ps1'
$legacyOffset = (30 + 5).ToString()
$legacyPattern = '(?is)(spell.{0,180}\b' + $legacyOffset + '(?:-pixel)?\b|\b' + $legacyOffset + '(?:-pixel)?\b.{0,180}spell)'
$staleReferences = @()
foreach ($relativePath in $trackedTextFiles) {
    if ($relativePath.Replace('\', '/') -eq $thisTest) {
        continue
    }
    $text = Get-Content -Raw (Join-Path $repoRoot $relativePath)
    if ($text -match $legacyPattern) {
        $staleReferences += $relativePath
    }
}

if ($staleReferences.Count -gt 0) {
    throw ('Tracked spell documentation/code still references the legacy offset: ' + ($staleReferences -join ', '))
}

Write-Output 'PASS: Main Village spells use one documented 150-pixel-per-axis inward offset.'
