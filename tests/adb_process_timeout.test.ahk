#Requires AutoHotkey v2.0
#Warn All, StdOut
#Include "..\bot_runtime.ahk"
global SessionCompletedAttacks := 0, CollectorCoords := [], EnableWallUpgrade := false
global MinGold := 500000, MinElixir := 500000, TimerDurationMs := 0
try {
    if (RunADBProcess(A_ComSpec ' /D /C exit 7', 3) != 7)
        throw Error("Process exit codes must be preserved")
    timedOut := false
    start := A_TickCount
    try RunADBProcess('"' A_WinDir '\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command "Start-Sleep -Seconds 10"', 0.2)
    catch as err
        timedOut := InStr(err.Message, "timed out") > 0
    if !timedOut || A_TickCount - start > 5000
        throw Error("A blocked child must terminate promptly at its deadline")
    FileAppend("PASS: process exit codes preserved; blocked child terminated at timeout.`n", "*")
    ExitApp(0)
} catch as err {
    FileAppend("FAIL: " err.Message "`n", "*")
    ExitApp(1)
}
