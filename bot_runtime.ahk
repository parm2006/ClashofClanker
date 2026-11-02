; Shared runtime state and bounded process execution for both frontends.
GetLiveMainCycleState() {
    global SessionCompletedAttacks, CollectorCoords, EnableWallUpgrade, MinGold, MinElixir, TimerDurationMs
    return {completedAttacks: SessionCompletedAttacks, collectorCount: CollectorCoords.Length,
        wallUpgradesEnabled: EnableWallUpgrade, minGold: MinGold, minElixir: MinElixir,
        timerEnabled: TimerDurationMs > 0}
}

RunADBProcess(command, timeoutSeconds := 24) {
    startup := Buffer(A_PtrSize == 8 ? 104 : 68, 0)
    NumPut("uint", startup.Size, startup)
    processInfo := Buffer(A_PtrSize * 2 + 8, 0)
    commandBuffer := Buffer(StrPut(command, "UTF-16") * 2)
    StrPut(command, commandBuffer, "UTF-16")
    if !DllCall("kernel32\CreateProcessW", "ptr", 0, "ptr", commandBuffer,
        "ptr", 0, "ptr", 0, "int", false, "uint", 0x08000000,
        "ptr", 0, "wstr", A_ScriptDir, "ptr", startup, "ptr", processInfo)
        throw Error("Could not start ADB process. Windows error " A_LastError ".")
    processHandle := NumGet(processInfo, 0, "ptr")
    threadHandle := NumGet(processInfo, A_PtrSize, "ptr")
    processId := NumGet(processInfo, A_PtrSize * 2, "uint")
    try {
        ; Short waits keep AHK responsive to Pause and other GUI events.
        deadline := A_TickCount + Round(timeoutSeconds * 1000)
        Loop {
            waitResult := DllCall("kernel32\WaitForSingleObject", "ptr", processHandle, "uint", 0, "uint")
            if (waitResult == 0)
                break
            if (waitResult != 258)
                throw Error("Could not wait for ADB process. Windows error " A_LastError ".")
            if (A_TickCount >= deadline) {
                ; Only kill the process tree created by this call; never the shared ADB server.
                RunWait('"' A_WinDir '\System32\taskkill.exe" /PID ' processId ' /T /F', A_ScriptDir, "Hide")
                throw Error("ADB command timed out after " timeoutSeconds " seconds.")
            }
            Sleep 50
        }
        exitCode := 0
        if !DllCall("kernel32\GetExitCodeProcess", "ptr", processHandle, "uint*", &exitCode)
            throw Error("Could not read ADB process exit code.")
        return exitCode
    } finally {
        DllCall("kernel32\CloseHandle", "ptr", threadHandle)
        DllCall("kernel32\CloseHandle", "ptr", processHandle)
    }
}
