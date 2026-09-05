$ErrorActionPreference = 'Stop'

$source = Get-Content -Raw (Join-Path $PSScriptRoot '..\ADBcoc_bot.ahk')

function Get-AhkFunctionBody([string] $name) {
    $match = [regex]::Match(
        $source,
        ('(?m)^' + [regex]::Escape($name) + '\([^)]*\)\s*\{')
    )
    if (!$match.Success) {
        throw "Function '$name' was not found."
    }

    $openBrace = $source.IndexOf('{', $match.Index)
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

$timeoutBody = Get-AhkFunctionBody 'CheckGameTimeout'
foreach ($required in @(
    'CaptureADBFrame\(true\)',
    'FindReloadActionFromADBFrame\(frame\)',
    'TapLiveReloadAction\(reloadAction\)'
)) {
    if ($timeoutBody -notmatch $required) {
        throw "Legacy timeout entry point is not routed through unified reload recovery: $required"
    }
}

foreach ($forbidden in @(
    'buttonLine',
    'ADBClickFraction',
    'OCR\.FromFile',
    'SaveRegionToPNG'
)) {
    if ($timeoutBody -match $forbidden) {
        throw "Legacy timeout entry point still contains obsolete reload behavior: $forbidden"
    }
}

Write-Host 'PASS: every timeout entry point uses fresh-frame normalized OCR reload recovery.'
