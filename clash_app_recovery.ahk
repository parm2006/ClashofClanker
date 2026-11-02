; Shared by the normal and visualizer controllers.
AcquireADBControllerLock() {
    ; Keep the handle alive until this process exits, including across elevation levels.
    static handle := DllCall("CreateMutexW", "ptr", 0, "int", false,
        "str", "Local\ClashofClanker.ADBController", "ptr")
    if (!handle || A_LastError == 183) {
        MsgBox("Another CoC controller is already open. Close it before opening this script.", "CoC Bot")
        ExitApp()
    }
}

class ClashAppRecoveredError extends Error {
}

CheckClashAppBeforeFlow(name) {
    global IsRunning, IsBBRunning, IsStarting
    static lastCheck := 0
    if name != "log" && WaitForHabumiWatchdog() {
        EnsureClashAppForeground(GetSelectedADBSerial())
        if !IsStarting
            throw ClashAppRecoveredError("Habumi restarted; discard the interrupted flow and return home.")
    }
    if (name == "log" || name == "verify_emulator" || name == "stop_bot"
        || name == "is_builder_running" || !(IsRunning || IsBBRunning || IsStarting))
        return
    if (lastCheck && A_TickCount - lastCheck < 2000)
        return
    lastCheck := A_TickCount
    serial := GetSelectedADBSerial()
    if IsClashForeground(serial)
        return
    EnsureClashAppForeground(serial)
    if !IsStarting
        throw ClashAppRecoveredError("Clash reopened; discard the interrupted flow and return home.")
}

EnsureClashAppForeground(serial, wait := 0) {
    global ADB_TARGET_PACKAGE, StatusText, IsRunning, IsBBRunning, IsStarting
    if IsClashForeground(serial)
        return false
    if !IsObject(wait)
        wait := Sleep
    previousStatus := StatusText.Value
    StatusText.Value := "Status: Recovering Clash"
    LogMessage("Clash left the foreground. Recovering through Android Home.")
    try {
        display := GetADBDisplaySize()
        prefix := '-s ' QuoteADBArgument(serial) ' shell '
        Loop 8 {
            if !(IsRunning || IsBBRunning || IsStarting)
                throw Error("Clash recovery cancelled.")
            LogMessage("Clash recovery attempt " A_Index "/8: Home, swipe up, launch Clash.")
            RunADB(prefix 'input keyevent KEYCODE_HOME')
            wait.Call(500)
            RunADB(prefix 'input swipe ' Round(display.width / 2) ' ' Round(display.height * 0.90)
                ' ' Round(display.width / 2) ' ' Round(display.height * 0.30) ' 400')
            wait.Call(500)
            ; Launch the same activity as the icon, independent of its drawer position.
            launch := RunADB(prefix 'am start -n ' ADB_TARGET_PACKAGE '/com.supercell.titan.GameApp', true)
            if !launch.Ok
                LogMessage("Clash launch: " FormatADBResult(launch))
            Loop 40 {
                if !(IsRunning || IsBBRunning || IsStarting)
                    throw Error("Clash recovery cancelled.")
                wait.Call(1000)
            }
            if IsClashForeground(serial) {
                LogMessage("Clash is back in the foreground after the loading wait.")
                return true
            }
        }
        throw Error("Clash did not stay open after 8 recovery attempts.")
    } finally {
        ; A pause or failure must not be overwritten by a stale Running label.
        if (IsRunning || IsBBRunning || IsStarting)
            StatusText.Value := previousStatus
    }
}
