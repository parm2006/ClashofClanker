$ErrorActionPreference = 'Stop'

# -----------------------------------------------------------------------------
# 1. Target Standalone Script Verification
# -----------------------------------------------------------------------------
$targetPath = Join-Path $PSScriptRoot '..\ADBcoc_bot_click_visualizer.ahk'
if (!(Test-Path -LiteralPath $targetPath)) {
    throw "Target standalone visualizer script was not found: $targetPath"
}

$source = Get-Content -Raw -LiteralPath $targetPath
if ([string]::IsNullOrWhiteSpace($source)) {
    throw 'Target standalone visualizer script is empty.'
}

# Must be a standalone copy and must NOT include ADBcoc_bot.ahk
if ($source -match '(?im)^\s*#Include\s+["'']?[^"''\r\n]*\bADBcoc_bot\.ahk\b') {
    throw 'Standalone visualizer must not #Include ADBcoc_bot.ahk; it must be a standalone script.'
}

# -----------------------------------------------------------------------------
# 2. Click-Through Transparent Overlay Definition
# -----------------------------------------------------------------------------
# Must define click-through window styles (+E0x20 / WS_EX_TRANSPARENT) and transparency
$hasClickThrough = $source -match '(?i)(\+E0x20|\+E0x80020|WS_EX_TRANSPARENT)'
$hasTransparency = $source -match '(?i)(TransColor|WinSetTransColor|WinSetTransparent|Transparent)'
if (!$hasClickThrough) {
    throw 'Visualizer must define a click-through transparent overlay (missing +E0x20 / WS_EX_TRANSPARENT style).'
}
if (!$hasTransparency) {
    throw 'Visualizer must define transparent color keying or window transparency (e.g. TransColor).'
}

# -----------------------------------------------------------------------------
# 3. Persistent Rectangular Tap-Jitter Regions and 1-Pixel Gesture Lines
# -----------------------------------------------------------------------------
# Rectangular tap-jitter regions
$hasJitter = $source -match '(?i)\bjitter\b'
$hasRectDraw = $source -match '(?i)(GdipDrawRectangle|GdipFillRectangle|DrawRectangle|FillRectangle)'
if (!$hasJitter -or !$hasRectDraw) {
    throw 'Visualizer must draw rectangular tap-jitter regions using GDI+ rectangle drawing and jitter offsets/bounds.'
}
$hasSolidTapFill = ($source -match '(?i)GdipCreateSolidFill') -and
    ($source -match '(?i)GdipFillRectangle')
if (!$hasSolidTapFill) {
    throw 'Visualizer must draw tap-jitter regions as solid filled rectangles.'
}

# One-pixel gesture lines
$hasLineDraw = $source -match '(?i)(GdipDrawLine|DrawLine)'
if (!$hasLineDraw) {
    throw 'Visualizer must draw gesture lines using GDI+ line drawing (GdipDrawLine).'
}
$hasOnePixelPen = $source -match '(?is)(GdipCreatePen1[^\r\n]*"float"\s*,\s*1(\.0)?\b|width\s*:=\s*1|PenWidth\s*:=\s*1|one pixel wide|1-pixel)'
if (!$hasOnePixelPen) {
    throw 'Visualizer must draw gesture lines with a 1-pixel pen width.'
}

# -----------------------------------------------------------------------------
# Helper Functions for AST/Block Inspection
# -----------------------------------------------------------------------------
function Get-AhkFunctionBodies([string]$code, [string]$namePattern) {
    $results = @()
    $matches = [regex]::Matches($code, ('(?im)^[ \t]*(' + $namePattern + ')\s*\([^)]*\)\s*\{'))
    foreach ($m in $matches) {
        $name = $m.Groups[1].Value
        $openBrace = $code.IndexOf('{', $m.Index)
        $depth = 0
        for ($i = $openBrace; $i -lt $code.Length; $i++) {
            if ($code[$i] -eq '{') { $depth++ }
            elseif ($code[$i] -eq '}') {
                $depth--
                if ($depth -eq 0) {
                    $results += [PSCustomObject]@{
                        Name = $name
                        Body = $code.Substring($openBrace + 1, $i - $openBrace - 1)
                        Index = $m.Index
                    }
                    break
                }
            }
        }
    }
    return $results
}

function Get-StageCodeBlock([string]$code, [string]$stageName) {
    # 1. Prefer the standalone visualizer's explicit stage contract/runner.
    $preferredPattern = "(?im)^[ \t]*((?:Run)?Visualizer$stageName(?:Stage|StageSteps))\s*\([^)]*\)\s*\{"
    $funcMatches = [regex]::Matches($code, $preferredPattern)
    if ($funcMatches.Count -eq 0) {
        # Fallback for equivalent implementations with different names.
        $funcMatches = [regex]::Matches($code, "(?im)^[ \t]*([A-Za-z0-9_]*$stageName[A-Za-z0-9_]*)\s*\([^)]*\)\s*\{")
    }
    foreach ($m in $funcMatches) {
        $openBrace = $code.IndexOf('{', $m.Index)
        $depth = 0
        for ($i = $openBrace; $i -lt $code.Length; $i++) {
            if ($code[$i] -eq '{') { $depth++ }
            elseif ($code[$i] -eq '}') {
                $depth--
                if ($depth -eq 0) {
                    return $code.Substring($openBrace + 1, $i - $openBrace - 1)
                }
            }
        }
    }

    # 2. Case "$stageName": block
    $caseMatch = [regex]::Match($code, "(?im)case\s+[`"']" + $stageName + "[`"']\s*:")
    if ($caseMatch.Success) {
        $startIndex = $caseMatch.Index + $caseMatch.Length
        $nextMatch = [regex]::Match($code.Substring($startIndex), "(?im)(case\s+[`"']|default\s*:|\})")
        if ($nextMatch.Success) {
            return $code.Substring($startIndex, $nextMatch.Index)
        }
        return $code.Substring($startIndex)
    }

    # 3. If block matching stageName
    $ifMatch = [regex]::Match($code, "(?im)if\s*\([^)]*" + $stageName + "[^)]*\)\s*\{")
    if ($ifMatch.Success) {
        $openBrace = $code.IndexOf('{', $ifMatch.Index)
        $depth = 0
        for ($i = $openBrace; $i -lt $code.Length; $i++) {
            if ($code[$i] -eq '{') { $depth++ }
            elseif ($code[$i] -eq '}') {
                $depth--
                if ($depth -eq 0) {
                    return $code.Substring($openBrace + 1, $i - $openBrace - 1)
                }
            }
        }
    }

    # 4. Array or object definition containing stageName (e.g. HomeStageSteps := [...])
    $arrMatch = [regex]::Match($code, "(?im)([A-Za-z0-9_]*$stageName[A-Za-z0-9_]*)\s*:=\s*\[([^\]]*)\]")
    if ($arrMatch.Success) {
        return $arrMatch.Groups[2].Value
    }

    return $null
}

# -----------------------------------------------------------------------------
# 4. Manual-only execution and review controls
# -----------------------------------------------------------------------------
if ($source -match '(?i)SetTimer\s*\(\s*StartAutomaticVisualizerLoop\s*,') {
    throw 'Opening the visualizer must not schedule an automatic farming loop.'
}
$manualPath = Join-Path $PSScriptRoot '..\visualizer_manual_actions.ahk'
$manual = Get-Content -Raw -LiteralPath $manualPath
if ($source -notmatch '#include "visualizer_manual_actions.ahk"') {
    throw 'Visualizer must load the manual action panel.'
}
foreach ($control in 'QueueVisualizerAction', 'RunManualVisualizerAction', 'RecordVisualizerVerdict', 'StopClickVisualizerStage') {
    if ($manual -notmatch "$control\(") { throw "Missing manual control: $control" }
}
if ($manual -match 'SetTimer\(RunManualVisualizerAction, -(?:2000|250)\)') {
    throw 'Manual test completion must not schedule another action.'
}
foreach ($pathId in 'path_builder', 'path_lab', 'path_walls', 'path_return', 'cast:a', 'cast:s', 'ability:q', 'bb_phase2') {
    if ($manual -notmatch [regex]::Escape($pathId)) { throw "Missing independently testable path: $pathId" }
}
$groups = @(Get-AhkFunctionBodies $manual 'ManualVisualizerGroups')[0].Body
if ($groups -notmatch '(?s)return\s*\[\s*\{name: "Overview"') {
    throw 'The visualizer must open on the complete-path Overview page.'
}
$cycle = @(Get-AhkFunctionBodies $manual 'RunManualVisualizerCycle')[0].Body
if ($cycle -notmatch 'ADBRefactorFlowAPI.RunMainCycle\(' -or $cycle -match 'SetTimer|while\s') {
    throw 'The full-cycle button must run Home then Attack once, honor cancellation, and never start a loop.'
}
if ($manual -notmatch 'visualizer_review\.tsv' -or $manual -notmatch 'visualizer_inputs\.log') {
    throw 'Manual verdicts and exact ADB inputs must be saved for review.'
}
if ($manual -notmatch 'SetTimer\(RunManualVisualizerAction, 0\)') {
    throw 'Stop must cancel queued manual tests.'
}
$stop = @(Get-AhkFunctionBodies $manual 'StopClickVisualizerStage')[0].Body
if ($stop -notmatch 'Reload\(\)') {
    throw 'Stop must reset the controller so a blocked path cannot keep all buttons disabled.'
}
if ($source -notmatch 'AddVisualizerADBReadRegion\(adbRect.x, adbRect.y, adbRect.width, adbRect.height\)' -or
    $source -notmatch 'DrawVisualizerEye\(') {
    throw 'OCR crops must have read boxes and eye icons.'
}

# -----------------------------------------------------------------------------
# 5. Home Stage Contract
# -----------------------------------------------------------------------------
# Home stage runs through tap_main_attack and tap_find_match, then pauses before tap_attack_start
$sharedFlow = Get-Content -Raw (Join-Path $PSScriptRoot '..\ADBcocbotrefactor_support.ahk')
$homeBlock = @(Get-AhkFunctionBodies $sharedFlow 'RunHomeStage')[0].Body
if ($null -eq $homeBlock) {
    throw 'Visualizer must define a Home stage flow or handler.'
}

$homeAttackMatch = [regex]::Match($homeBlock, '(?i)("tap_main_attack"|TapMainAttack\b)')
$homeFindMatch = [regex]::Match($homeBlock, '(?i)("tap_find_match"|TapFindMatch\b)')

if (!$homeAttackMatch.Success) {
    throw 'Home stage must execute tap_main_attack.'
}
if (!$homeFindMatch.Success) {
    throw 'Home stage must execute tap_find_match.'
}
if ($homeAttackMatch.Index -ge $homeFindMatch.Index) {
    throw 'Home stage must execute tap_main_attack before tap_find_match.'
}

$homeAttackStartMatch = [regex]::Match($homeBlock, '(?i)("tap_attack_start"|TapAttackStart\b)')
if ($homeAttackStartMatch.Success) {
    $between = $homeBlock.Substring(
        $homeFindMatch.Index,
        $homeAttackStartMatch.Index - $homeFindMatch.Index
    )
    if ($between -notmatch '(?i)(pause|msgbox|wait|sleep|prompt|confirm)') {
        throw 'Home stage must pause before tap_attack_start.'
    }
}

# -----------------------------------------------------------------------------
# 6. Attack Stage Contract
# -----------------------------------------------------------------------------
# Attack stage begins with tap_attack_start and contains find_eligible_base, attack_main_base, and return_main_home in that order
$attackBlock = @(Get-AhkFunctionBodies $sharedFlow 'RunAttackStage')[0].Body
if ($null -eq $attackBlock) {
    throw 'Visualizer must define an Attack stage flow or handler.'
}

$attackStartMatch = [regex]::Match($attackBlock, '(?i)("tap_attack_start"|TapAttackStart\b)')
$findBaseMatch = [regex]::Match($attackBlock, '(?i)("find_eligible_base"|FindEligibleBase\b)')
$attackBaseMatch = [regex]::Match($attackBlock, '(?i)("attack_main_base"|AttackMainBase\b)')
$returnHomeMatch = [regex]::Match($attackBlock, '(?i)("return_main_home"|ReturnMainHome\b)')

if (!$attackStartMatch.Success) {
    throw 'Attack stage must begin with tap_attack_start.'
}
if (!$findBaseMatch.Success) {
    throw 'Attack stage must contain find_eligible_base.'
}
if (!$attackBaseMatch.Success) {
    throw 'Attack stage must contain attack_main_base.'
}
if (!$returnHomeMatch.Success) {
    throw 'Attack stage must contain return_main_home.'
}

if (!($attackStartMatch.Index -lt $findBaseMatch.Index -and
      $findBaseMatch.Index -lt $attackBaseMatch.Index -and
      $attackBaseMatch.Index -lt $returnHomeMatch.Index)) {
    throw 'Attack stage must execute tap_attack_start, find_eligible_base, attack_main_base, and return_main_home in that exact order.'
}

# -----------------------------------------------------------------------------
# 7. Self-Test Command-Line Mode
# -----------------------------------------------------------------------------
# Must support self-test command line mode without requiring live ADB interaction
if ($source -notmatch '\bA_Args\b') {
    throw 'Visualizer must inspect A_Args to support a command-line execution mode.'
}
if ($source -notmatch '(?i)(--test|--self-test|/test|/selftest|selftest|self_test)') {
    throw 'Visualizer must recognize a self-test command-line switch (e.g. --self-test, --test, /selftest).'
}
$selfTestFunc = [regex]::Match($source, '(?im)^[ \t]*([A-Za-z0-9_]*SelfTest[A-Za-z0-9_]*)\s*\([^)]*\)\s*\{')
$hasSelfTestInvocation = $selfTestFunc.Success -or ($source -match '(?i)(RunSelfTest|SelfTest)\s*\(')
if (!$hasSelfTestInvocation) {
    throw 'Visualizer must implement a self-test routine (e.g. RunSelfTest or SelfTest).'
}

# -----------------------------------------------------------------------------
# PASS
# -----------------------------------------------------------------------------
Write-Host 'PASS: main flow click visualizer contract verified.'
