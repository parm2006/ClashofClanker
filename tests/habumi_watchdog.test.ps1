$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$source = Get-Content (Join-Path $root 'habumi_watchdog.ahk') -Raw
$start = $source.IndexOf('TickHabumiWatchdog() {')
$end = $source.IndexOf('WaitForHabumiWatchdog(', $start)
$tick = $source.Substring($start, $end - $start)
# Execute the actual state machine with native boundaries replaced by recording fakes.
$tick = $tick.Replace('A_TickCount', 'FakeTick').Replace('ProcessGetPath(', 'FakeProcessPath(').Replace('ProcessClose(', 'FakeClose(').Replace('Run(', 'FakeLaunch(')
$test = @'
#Requires AutoHotkey v2.0
#Warn All, StdOut
global HabumiWatchdog := {}, FakeTick := 10000, fakeAlive := true, fakeADB := true, killed := [], launched := 0, paused := 0
global ADBConnectionSerial := "cached", ADBHelperSerial := "cached", ADBDisplaySerial := "cached"
Reset() {
    global HabumiWatchdog, killed, launched, fakeAlive, fakeADB, FakeTick
    HabumiWatchdog := {enabled:true, booting:false, missing:0, probe:0, deadline:0, launched:0, epoch:0, consumed:0, bin:"C:\fixture"}
    killed := [], launched := 0, fakeAlive := true, fakeADB := true, FakeTick := 10000
}
HabumiAndroidAlive() {
    global fakeAlive
    return fakeAlive
}
HabumiADBAlive() {
    global fakeADB
    return fakeADB
}
MoveHabumiToControllerDesktop() {
}
HabumiInstallationPids(name) => name == "Habumi.exe" ? [100] : [200]
FakeProcessPath(pid) => pid == 100 ? "C:\fixture\Habumi.exe" : "C:\fixture\qemu-nostro.exe"
FakeClose(pid) {
    global killed
    killed.Push(pid)
}
FakeLaunch(*) {
    global launched
    launched += 1
}
GetSelectedADBSerial() => "127.0.0.1:15555"
QuoteADBArgument(value) => value
RunADB(*) => {Ok:true, Output:"1"}
LogMessage(*) {
}
StopHabumiWatchdog() {
    global HabumiWatchdog
    HabumiWatchdog.enabled := false
}
PauseBot() {
    global paused
    paused += 1
}
Check(value, message) {
    if !value
        throw Error(message)
}
'@
$test += "`n" + $tick + @'

try {
    Reset()
    TickHabumiWatchdog()
    Check(launched == 0 && killed.Length == 0, "Healthy emulator must remain untouched")
    fakeAlive := false
    Loop 3 {
        FakeTick += 2000
        TickHabumiWatchdog()
    }
    Check(launched == 1 && killed.Length == 2 && HabumiWatchdog.booting, "Confirmed loss restarts launcher and QEMU once")
    Check(ADBConnectionSerial == "" && HabumiWatchdog.epoch == 1, "Restart clears connection cache and marks interrupted flow")
    Check(HabumiWatchdog.deadline == FakeTick + 240000, "Boot allowance must be doubled to 240 seconds")
    FakeTick += 10000
    TickHabumiWatchdog()
    Check(launched == 1, "Boot grace period must prevent restart loops")
    fakeAlive := true
    FakeTick += 20000
    TickHabumiWatchdog()
    Check(!HabumiWatchdog.booting && HabumiWatchdog.missing == 0, "Boot-complete signal restores health")
    StopHabumiWatchdog()
    fakeAlive := false
    FakeTick += 2000
    TickHabumiWatchdog()
    Check(launched == 1 && killed.Length == 2, "Pause prevents all recovery actions")
    Reset()
    HabumiWatchdog.booting := true
    HabumiWatchdog.deadline := FakeTick - 1
    TickHabumiWatchdog()
    Check(!HabumiWatchdog.enabled && paused == 1 && launched == 0, "Boot timeout stops and pauses instead of retrying forever")
    Reset()
    fakeADB := false
    TickHabumiWatchdog()
    Check(launched == 0, "A single ADB failure must not restart")
    fakeADB := true
    FakeTick += 2000
    TickHabumiWatchdog()
    Check(HabumiWatchdog.missing == 0 && launched == 0, "Recovered ADB clears failed-check count")
    fakeADB := false
    Loop 3 {
        FakeTick += 2000
        TickHabumiWatchdog()
    }
    Check(launched == 1, "Persistent ADB loss restarts even with the Android window present")
    FileAppend("PASS: missing window OR ADB loss, transient failures, healthy, confirmed crash, exact-PID cleanup, boot grace, reconnection cache, Pause, and boot timeout.`n", "*")
    ExitApp(0)
} catch as failure {
    FileAppend("FAIL: " failure.Message "`n", "*")
    ExitApp(1)
}
'@
$path = Join-Path $root 'scratch/habumi-watchdog-isolated.test.ahk'
[IO.File]::WriteAllText($path, $test)
$exe = 'C:/Users/parth/AppData/Local/Programs/AutoHotkey/v2/AutoHotkey64.exe'
$output = Join-Path $root 'scratch/habumi-watchdog-isolated.txt'
$errors = Join-Path $root 'scratch/habumi-watchdog-isolated-error.txt'
$process = Start-Process -FilePath $exe -ArgumentList '/ErrorStdOut', $path -WindowStyle Hidden -PassThru -RedirectStandardOutput $output -RedirectStandardError $errors
if (!$process.WaitForExit(10000)) {
    $process.Kill()
    throw 'Watchdog test timed out.'
}
Get-Content $output, $errors
if ($process.ExitCode -ne 0) { throw 'Watchdog tests failed.' }
