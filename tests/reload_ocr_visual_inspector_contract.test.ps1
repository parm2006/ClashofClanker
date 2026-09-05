$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'reload_ocr_visual_inspector.ahk'
if (!(Test-Path $scriptPath)) {
    throw 'Reload OCR visual inspector script is missing.'
}

$source = Get-Content -Raw $scriptPath
if ($source -match 'DllCall\("[^"]*\\\\') {
    throw 'Reload OCR visual inspector must use a single module separator in every DllCall target.'
}
$requiredPatterns = @(
    '#Include "\.\.\\OCR\.ahk"',
    'RunInspectCycle\(',
    'SaveFrameWithCropOutline\(',
    'CaptureADBFrame\(',
    'IsErrorCardColorMatch\(',
    'TapReloadAction\(',
    'TapReloadButton',
    'shell input tap',
    'GdipDrawLine',
    'Tap target crosshair',
    'OCR\.FromFile\(',
    'SetCropOriginFromMouse\(',
    'SaveCropToConfig\(',
    'ReloadCropX',
    'ReloadCropY',
    'ReloadCropW',
    'ReloadCropH',
    'ReadOnly \+VScroll \+HScroll',
    'Consolas',
    'cGreen',
    'cRed'
)

foreach ($pattern in $requiredPatterns) {
    if ($source -notmatch $pattern) {
        throw "Reload OCR visual inspector is missing required test-GUI capability: $pattern"
    }
}

Write-Host 'PASS: reload OCR visual inspector provides an adjustable capture, crop overlay, OCR verdict, and diagnostics.'
