$ErrorActionPreference = 'Stop'

$sourcePath = Join-Path $PSScriptRoot '..\ADBcoc_bot.ahk'
$source = Get-Content -Raw $sourcePath

function Get-AhkFunctionBody([string] $name) {
    $start = $source.IndexOf("$name() {")
    if ($start -lt 0) {
        throw "Function '$name' was not found."
    }

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

$verifyEmulator = Get-AhkFunctionBody 'VerifyEmulator'
if ($verifyEmulator -match 'WinExist\(') {
    throw 'VerifyEmulator must not require the emulator Windows window during runtime.'
}
if ($verifyEmulator -notmatch 'IsClashForeground\(ready\.Serial\)') {
    throw 'VerifyEmulator must require Clash of Clans to be the foreground Android app.'
}

$validateViewport = Get-AhkFunctionBody 'ValidateADBViewportRuntime'
if ($validateViewport -match 'The configured emulator window was not found') {
    throw 'Viewport validation must use calibrated dimensions when the emulator is on another virtual desktop.'
}
if ($validateViewport -notmatch 'ResolveADBValidationClientSize\(') {
    throw 'Viewport validation must preserve calibrated dimensions when the window is unavailable.'
}

$expectedHotkeys = @(
    '\^\+F1::\s*\{\s*UnifiedStart\(\)',
    '\^\+F2::\s*\{\s*PauseBot\(\)',
    '\^!\+F1::\s*\{\s*StartCalibration\(\)',
    '\^!\+F2::\s*\{\s*StartBBCalibration\(\)'
)
foreach ($pattern in $expectedHotkeys) {
    if ($source -notmatch $pattern) {
        throw "Required virtual-desktop-safe hotkey is missing: $pattern"
    }
}

Write-Host 'PASS: runtime validation is independent of the emulator Windows window and retains the ADB Clash check.'
