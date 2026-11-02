param(
    [string]$Command = "STATUS",
    [int]$TimeoutSeconds = 10
)

$botDir = "c:\Users\parth\Projects\coc_bot"
$scratchDir = Join-Path $botDir "scratch"
$cmdFile = Join-Path $scratchDir "bot_cmd.txt"
$resultFile = Join-Path $scratchDir "bot_cmd_result.json"
$stateFile = Join-Path $scratchDir "bot_state.json"
$logFile = Join-Path $scratchDir "bot_activity.log"
$ahkExe = "C:\Users\parth\AppData\Local\Programs\AutoHotkey\v2\AutoHotkey64.exe"
$ahkScript = Join-Path $botDir "ADBcoc_bot.ahk"

if (-not (Test-Path $scratchDir)) {
    New-Item -ItemType Directory -Path $scratchDir -Force | Out-Null
}

function Ensure-BotRunning {
    $proc = Get-Process -Name "AutoHotkey64" -ErrorAction SilentlyContinue | Where-Object {
        $_.MainWindowTitle -like "*CoC Bot*" -or $_.CommandLine -like "*ADBcoc_bot.ahk*"
    }
    if (-not $proc) {
        Write-Host "[API] Launching ADBcoc_bot.ahk..."
        Start-Process -FilePath $ahkExe -ArgumentList "`"$ahkScript`"" -WorkingDirectory $botDir
        Start-Sleep -Seconds 2
    }
}

function Send-BotCommand([string]$cmd) {
    Ensure-BotRunning
    if (Test-Path $resultFile) {
        Remove-Item $resultFile -Force -ErrorAction SilentlyContinue
    }
    [System.IO.File]::WriteAllText($cmdFile, $cmd.Trim())
    Write-Host "[API] Sent command: $cmd"

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        Start-Sleep -Milliseconds 250
        if (Test-Path $resultFile) {
            $resp = Get-Content -Path $resultFile -Raw -Encoding UTF8
            Write-Host "[API] Response: $resp"
            return $resp
        }
    }
    Write-Warning "[API] Timeout waiting for command response."
    return $null
}

function Get-BotState {
    if (Test-Path $stateFile) {
        return (Get-Content -Path $stateFile -Raw -Encoding UTF8)
    }
    return "No state file found."
}

function Show-RecentLogs([int]$lines = 20) {
    if (Test-Path $logFile) {
        Get-Content -Path $logFile -Tail $lines
    } else {
        Write-Host "No log file found."
    }
}

switch ($Command.ToUpper()) {
    "LAUNCH" {
        Ensure-BotRunning
        Write-Host "Bot launched."
    }
    "STATE" {
        Get-BotState
    }
    "LOGS" {
        Show-RecentLogs
    }
    default {
        Send-BotCommand $Command
    }
}
