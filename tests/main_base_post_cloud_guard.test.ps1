$ErrorActionPreference = 'Stop'

$source = Get-Content -Raw (
    Join-Path $PSScriptRoot '..\ADBcocbotrefactor_support.ahk'
)

$methodStart = [regex]::Match(
    $source,
    '(?m)^\s*FindEligibleBase\([^)]*\)\s*\{'
)
if (!$methodStart.Success) {
    throw 'FindEligibleBase was not found.'
}

$openBrace = $source.IndexOf('{', $methodStart.Index)
$depth = 0
$methodBody = $null
for ($index = $openBrace; $index -lt $source.Length; $index++) {
    if ($source[$index] -eq '{') {
        $depth++
    }
    elseif ($source[$index] -eq '}') {
        $depth--
        if ($depth -eq 0) {
            $methodBody = $source.Substring(
                $openBrace + 1,
                $index - $openBrace - 1
            )
            break
        }
    }
}
if ($null -eq $methodBody) {
    throw 'FindEligibleBase has an unmatched opening brace.'
}

foreach ($forbidden in @(
    'detect_main_home_from_frame',
    'detect_village_from_frame',
    'Expected a Main Village battle after clouds cleared'
)) {
    if ($methodBody -match $forbidden) {
        throw "Eligible-base search still performs a post-cloud state check: $forbidden"
    }
}

foreach ($required in @(
    'baseFrame\s*:=\s*this\._CaptureFreshFrame\("base"\)',
    'read_loot_from_frame",\s*baseFrame'
)) {
    if ($methodBody -notmatch $required) {
        throw "Eligible-base search does not pass the fresh base frame to loot OCR: $required"
    }
}

Write-Host 'PASS: Main eligible-base search goes directly from clouds to loot OCR.'
