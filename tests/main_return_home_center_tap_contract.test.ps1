$ErrorActionPreference = 'Stop'

$source = Get-Content -Raw (
    Join-Path $PSScriptRoot '..\ADBcoc_bot.ahk'
)

$methodStart = $source.IndexOf('    TapReturnHome() {')
if ($methodStart -lt 0) {
    throw 'TapReturnHome was not found.'
}

$openBrace = $source.IndexOf('{', $methodStart)
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
    throw 'TapReturnHome has an unmatched opening brace.'
}

if ($methodBody -notmatch 'return RunADBTapAt\(ReturnHomeClickX, ReturnHomeClickY, 200\)' -or
    ([regex]::Matches($methodBody, 'RunADBTapAt\(')).Count -ne 1 -or $methodBody -match 'centerPoint') {
    throw 'Return Home must tap only the calibrated results-screen button, without a center or End Battle tap.'
}
Write-Host 'PASS: Return Home taps only the calibrated results-screen button.'
