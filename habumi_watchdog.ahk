global HabumiWatchdog := {enabled: false, booting: false, missing: 0, deadline: 0, launched: 0, epoch: 0, consumed: 0, bin: "", probe: 0}

StartHabumiWatchdog() {
    global HabumiWatchdog, ADBProvider, HABUMI_PROVIDER
    if ADBProvider != HABUMI_PROVIDER && ADBProvider != "Habuki"
        return
    SplitPath(ResolveADBPath(), , &bin)
    if !FileExist(bin "\Habumi.exe")
        throw Error("Habumi launcher was not found beside the configured ADB executable.")
    HabumiWatchdog.bin := bin
    HabumiWatchdog.enabled := true
    HabumiWatchdog.booting := false
    HabumiWatchdog.missing := 0
    HabumiWatchdog.probe := 0
    HabumiWatchdog.consumed := HabumiWatchdog.epoch
    HabumiWatchdog.moved := Map()
    SetTimer(TickHabumiWatchdog, 2000)
    LogMessage("Habumi watchdog enabled; Pause stops monitoring and recovery.")
}

StopHabumiWatchdog() {
    global HabumiWatchdog
    HabumiWatchdog.enabled := false
    HabumiWatchdog.booting := false
    SetTimer(TickHabumiWatchdog, 0)
}

HabumiInstallationPids(name) {
    global HabumiWatchdog
    pids := []
    for process in ComObjGet("winmgmts:").ExecQuery("SELECT ProcessId FROM Win32_Process WHERE Name='" name "'") {
        try {
            if StrLower(ProcessGetPath(process.ProcessId)) == StrLower(HabumiWatchdog.bin "\" name)
                pids.Push(process.ProcessId)
        }
    }
    return pids
}

HabumiAndroidAlive() {
    ; Include hidden/cloaked windows on other virtual desktops; foreground is irrelevant.
    previous := DetectHiddenWindows(true)
    try {
    for pid in HabumiInstallationPids("qemu-nostro.exe") {
        for hwnd in WinGetList("ahk_pid " pid) {
            if WinGetTitle("ahk_id " hwnd) == "Android"
                return true
        }
    }
    ; Some Habumi versions host the Android surface in the launcher process.
    for pid in HabumiInstallationPids("Habumi.exe") {
        for hwnd in WinGetList("ahk_pid " pid) {
            if WinGetTitle("ahk_id " hwnd) == "Android"
                return HabumiInstallationPids("qemu-nostro.exe").Length > 0
        }
    }
    return false
    } finally {
        DetectHiddenWindows(previous)
    }
}

HabumiADBAlive() {
    try {
        result := RunADB('-s ' QuoteADBArgument(GetSelectedADBSerial()) ' shell echo coc_watchdog_alive', true)
        return result.Ok && Trim(result.Output) == "coc_watchdog_alive"
    } catch {
        return false
    }
}

MoveHabumiToControllerDesktop() {
    global HabumiWatchdog, MyGui
    ; Best effort: some Windows versions deny moving another process's windows.
    try {
        manager := ComObject("{AA509086-5CA9-4C25-8F95-589D3C07B48A}", "{A5CD92FF-29BE-454C-8D04-D82879FB3F1B}")
        desktop := Buffer(16, 0)
        ComCall(4, manager, "ptr", MyGui.Hwnd, "ptr", desktop)
        previous := DetectHiddenWindows(true)
        try {
            for name in ["Habumi.exe", "qemu-nostro.exe"] {
                for pid in HabumiInstallationPids(name) {
                    for hwnd in WinGetList("ahk_pid " pid) {
                        if HabumiWatchdog.moved.Has(hwnd)
                            continue
                        HabumiWatchdog.moved[hwnd] := true
                        try ComCall(5, manager, "ptr", hwnd, "ptr", desktop)
                        catch as moveError
                            LogMessage("Habumi desktop placement unavailable: " moveError.Message)
                    }
                }
            }
        } finally {
            DetectHiddenWindows(previous)
        }
    } catch {
        ; Desktop placement must never interfere with emulator recovery.
    }
}

TickHabumiWatchdog() {
    global HabumiWatchdog, ADBConnectionSerial, ADBHelperSerial, ADBDisplaySerial
    static busy := false
    if !HabumiWatchdog.enabled || busy
        return
    if HabumiWatchdog.probe && A_TickCount - HabumiWatchdog.probe < 2000
        return
    HabumiWatchdog.probe := A_TickCount
    busy := true
    try {
        alive := HabumiAndroidAlive()
        if HabumiWatchdog.booting {
            MoveHabumiToControllerDesktop()
            if A_TickCount > HabumiWatchdog.deadline
                throw Error("Habumi did not boot within 240 seconds.")
            if !alive || A_TickCount - HabumiWatchdog.launched < 25000
                return
            serial := GetSelectedADBSerial()
            try {
                RunADB('connect ' QuoteADBArgument(serial), true)
                boot := RunADB('-s ' QuoteADBArgument(serial) ' shell getprop sys.boot_completed', true)
            } catch {
                ; ADB can be unavailable during boot; keep waiting until the deadline.
                return
            }
            if !HabumiWatchdog.enabled
                return
            if boot.Ok && Trim(boot.Output) == "1" {
                HabumiWatchdog.booting := false
                HabumiWatchdog.missing := 0
                LogMessage("Habumi recovered; Android boot is complete.")
            }
            return
        }
        healthy := alive && HabumiADBAlive()
        HabumiWatchdog.missing := healthy ? 0 : HabumiWatchdog.missing + 1
        if HabumiWatchdog.missing < 3
            return
        if !HabumiWatchdog.enabled
            return
        ; Final independent check: a transient failure must not trigger a restart.
        if HabumiAndroidAlive() && HabumiADBAlive() {
            HabumiWatchdog.missing := 0
            return
        }
        if !HabumiWatchdog.enabled
            return
        HabumiWatchdog.booting := true
        HabumiWatchdog.launched := A_TickCount
        HabumiWatchdog.deadline := A_TickCount + 240000
        HabumiWatchdog.epoch += 1
        HabumiWatchdog.moved := Map()
        ADBConnectionSerial := "", ADBHelperSerial := "", ADBDisplaySerial := ""
        LogMessage("Habumi crash detected: closing leftover launcher/emulator and restarting this installation.")
        for name in ["qemu-nostro.exe", "Habumi.exe"] {
            for pid in HabumiInstallationPids(name) {
                if !HabumiWatchdog.enabled
                    return
                ; Recheck identity immediately before closing; never kill by image name.
                try {
                    if StrLower(ProcessGetPath(pid)) == StrLower(HabumiWatchdog.bin "\" name)
                        ProcessClose(pid)
                }
            }
        }
        if !HabumiWatchdog.enabled
            return
        Run('"' HabumiWatchdog.bin '\Habumi.exe"', HabumiWatchdog.bin)
    } catch as err {
        LogMessage("Habumi watchdog stopped: " err.Message)
        StopHabumiWatchdog()
        PauseBot()
    } finally {
        busy := false
    }
}

WaitForHabumiWatchdog(consume := true) {
    global HabumiWatchdog
    if !HabumiWatchdog.enabled
        return false
    Loop {
        if !HabumiWatchdog.enabled
            throw Error("Habumi recovery cancelled.")
        TickHabumiWatchdog()
        if !HabumiWatchdog.enabled
            throw Error("Habumi recovery stopped.")
        if !HabumiWatchdog.booting && HabumiWatchdog.missing == 0
            break
        Sleep 250
    }
    if HabumiWatchdog.epoch != HabumiWatchdog.consumed {
        if consume
            HabumiWatchdog.consumed := HabumiWatchdog.epoch
        return true
    }
    return false
}

RecoverHabumiAfterFlowError() {
    global HabumiWatchdog
    if !HabumiWatchdog.enabled
        return false
    if !HabumiWatchdog.booting && HabumiAndroidAlive()
        return false
    WaitForHabumiWatchdog()
    EnsureClashAppForeground(GetSelectedADBSerial())
    return true
}
