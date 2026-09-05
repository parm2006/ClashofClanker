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

$centerPoint = $methodBody.IndexOf(
    'centerPoint := ClientViewportPointFromFraction(0.5, 0.5)'
)
$centerTap = $methodBody.IndexOf(
    'RunADBTapAt(centerPoint.x, centerPoint.y, 200)'
)
$returnHomeTap = $methodBody.IndexOf(
    'return RunADBTapAt(ReturnHomeClickX, ReturnHomeClickY, 200)'
)

if ($centerPoint -lt 0 -or $centerTap -lt 0 -or $returnHomeTap -lt 0) {
    throw 'TapReturnHome must use the normal client-coordinate ADB path for both taps.'
}
if (!($centerPoint -lt $centerTap -and $centerTap -lt $returnHomeTap)) {
    throw 'TapReturnHome must tap the viewport center before the Return Home button.'
}

Write-Host 'PASS: Main Return Home taps viewport center before the calibrated button.'
