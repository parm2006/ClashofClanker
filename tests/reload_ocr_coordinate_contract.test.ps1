$ErrorActionPreference = 'Stop'

function Get-AhkFunctionBody([string] $source, [string] $name) {
    $match = [regex]::Match(
        $source,
        ('(?m)^' + [regex]::Escape($name) + '\([^)]*\)\s*\{')
    )
    if (!$match.Success) {
        throw "Function '$name' was not found."
    }
    $start = $match.Index

    $openBrace = $source.IndexOf('{', $start)
    $depth = 0
    for ($index = $openBrace; $index -lt $source.Length; $index++) {
        if ($source[$index] -eq '{') { $depth++ }
        elseif ($source[$index] -eq '}') {
            $depth--
            if ($depth -eq 0) {
                return $source.Substring($openBrace + 1, $index - $openBrace - 1)
            }
        }
    }

    throw "Function '$name' has an unmatched opening brace."
}

$botSource = Get-Content -Raw (Join-Path $PSScriptRoot '..\ADBcoc_bot.ahk')
$reloadFinder = Get-AhkFunctionBody $botSource 'FindReloadActionFromADBFrame'
if ($reloadFinder -notmatch 'for word in result\.Words') {
    throw 'Reload recovery must derive its click point from normalized OCR words, not scaled OCR lines.'
}
if ($reloadFinder -notmatch 'NormalizeOCRFromFileWord\(word,\s*ocrScale\)') {
    throw 'Reload recovery must remove the residual FromFile OCR scale before mapping the word center.'
}
foreach ($coordinate in 'adbX', 'adbY') {
    if ($reloadFinder -notmatch ($coordinate + ':\s*')) {
        throw "Reload recovery must retain the direct OCR frame coordinate '$coordinate'."
    }
}

$reloadTapper = Get-AhkFunctionBody $botSource 'TapLiveReloadAction'
if ($reloadTapper -notmatch 'RunADBDirectTapAt\(action\.adbX,\s*action\.adbY') {
    throw 'Production reload tapping must use the direct OCR-derived ADB point.'
}
if ($reloadTapper -match 'RunADBTapAt\(action\.x,\s*action\.y') {
    throw 'Production reload tapping must not round-trip the OCR point through client coordinates.'
}

$inspectorSource = Get-Content -Raw (Join-Path $PSScriptRoot 'reload_ocr_visual_inspector.ahk')
if ($inspectorSource -notmatch 'for word in result\.Words') {
    throw 'The reload inspector must preview the normalized OCR word click point used by recovery.'
}
if ($inspectorSource -notmatch 'NormalizeOCRFromFileWord\(word,\s*ocrScale\)') {
    throw 'The reload inspector must remove the residual FromFile OCR scale before drawing the target.'
}

$logicSource = Get-Content -Raw (Join-Path $PSScriptRoot '..\reload_ocr_logic.ahk')
foreach ($property in 'x', 'y', 'w', 'h') {
    if ($logicSource -notmatch ($property + ':\s*word\.' + $property + '\s*/\s*scale')) {
        throw "Reload OCR normalization must divide word.$property by the residual scale."
    }
}

Write-Host 'PASS: Reload taps are derived from fresh, normalized OCR word coordinates.'
