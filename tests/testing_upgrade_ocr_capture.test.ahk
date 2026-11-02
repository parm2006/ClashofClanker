#Requires AutoHotkey v2.0
#Warn All, StdOut
#Include "..\OCR.ahk"
#Include "..\upgrade_rows.ahk"

; Saved-capture integration test: no ADB connection or input is used.
global CapturePath := A_Args.Length ? A_Args[1] : A_ScriptDir "\fixtures\upgrades\builders_hut_drawer.png"
try {
    picked := FindUpgradeRow("builder")
    if !IsObject(picked) || !InStr(UpgradeRowName(picked.name), "buildershut")
        throw Error("Expected the visible Hut, got " (IsObject(picked) ? picked.name : picked))
    if Abs(picked.y - 177) > 8
        throw Error("Wrong normalized row coordinate: " picked.y)
    FileAppend("PASS: whole-region OCR selects Hut at y=" picked.y ", tapped=" picked.tapped "`n", "*")
    ExitApp(0)
} catch as err {
    FileAppend("FAIL: " err.Message "`n", "*")
    ExitApp(1)
}

GetADBClientViewportRect() => {x: 0, y: 0, width: 1280, height: 800}
CaptureADBFrame(fresh) => CapturePath
SaveADBFrameRegionToPNG(frame, x, y, w, h, path) {
    SplitPath(path, , &directory)
    DirCreate(directory)
    FileCopy(frame, path, true)
    return {x: 0, y: 0}
}
RunWaitPythonScript(arguments) {
    command := '"' A_ScriptDir '\..\.venv\Scripts\python.exe" "' A_ScriptDir '\..\vision_hook.py" ' arguments
    if RunWait(command, , "Hide") != 0
        throw Error("Preprocessing failed")
    return "SUCCESS:"
}
ADBFramePointToClient(crop, x, y) => {x: x, y: y}
LogMessage(message) => FileAppend(message "`n", "*")
RunADBTapAt(*) {
    throw Error("Unexpected tap")
}
RunADBSwipeAt(*) {
    throw Error("Unexpected swipe")
}
SafeFlowWait(*) {
    throw Error("Unexpected wait")
}

