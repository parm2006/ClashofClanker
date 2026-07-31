#Requires AutoHotkey v2.0
#SingleInstance Force
#Include builder_base_loop_logic.ahk
#Include loot_ocr_logic.ahk
#Include ADBcocbotrefactor_support.ahk

global BuilderBaseHarnessRunning := false
global BuilderBaseHarnessFlow := ""
global BuilderBaseHarnessSerial := ""
global BuilderBaseHarnessProvider := ""
global BuilderBaseHarnessViewport := ""
global BuilderBaseHarnessDisplay := ""
global BuilderBaseHarnessSides := []
global BuilderBaseHarnessPoints := ""
global BuilderBaseHarnessCaptureSequence := 0
global BuilderBaseHarnessGdipToken := 0
global BuilderBaseHarnessGui := ""
global BuilderBaseHarnessConsole := ""
global BuilderBaseHarnessPinchHelperSerial := ""
global BuilderBaseHarnessPinchTargetPackage := "com.cocbot.pinchtest.target"
global BuilderBaseHarnessPinchInstrumentationPackage := "com.cocbot.pinchtest.instrumentation"
global BuilderBaseHarnessPinchTargetApk := A_ScriptDir "\pinch_test\dist\pinch-target.apk"
global BuilderBaseHarnessPinchInstrumentationApk := A_ScriptDir "\pinch_test\dist\pinch-instrumentation.apk"

LoadBuilderBaseHarnessConfig()
CreateBuilderBaseHarnessGui()

F1:: TestBuilderBaseAttackTap()
F2:: TestBuilderBaseFindMatchTap()
F3:: TestBuilderBaseStageOneDeployment()
F4:: TestBuilderBaseStageOneMonitor()
F5:: TestBuilderBaseStageTwoDeployment()
F6:: TestBuilderBaseStageTwoMonitor()
F7:: TestBuilderBaseAttack()
F8:: ToggleBuilderBaseLoop()

^F1:: TestBuilderBaseAttackTap()
^F2:: TestBuilderBaseFindMatchTap()
^F3:: TestBuilderBaseStageOneDeployment()
^F4:: TestBuilderBaseStageOneMonitor(true)
^F5:: TestBuilderBaseStageTwoDeployment(true)
^F6:: TestBuilderBaseStageTwoMonitor(true)
^F7:: TestBuilderBaseAttack()
^F8:: ToggleBuilderBaseLoop()

CreateBuilderBaseHarnessGui() {
    global BuilderBaseHarnessGui, BuilderBaseHarnessConsole
    BuilderBaseHarnessGui := Gui("+Resize +MinSize490x430", "Clash of Clanker - Builder Base Loop")
    BuilderBaseHarnessGui.SetFont("s10", "Segoe UI")
    BuilderBaseHarnessGui.Add(
        "Text",
        "x15 y14 w460 h22 +Center",
        "Builder Base test harness — buttons and F1–F8 run the same actions"
    )

    buttons := [
        {label: "F1 - Attack", action: TestBuilderBaseAttackTap},
        {label: "F2 - Find Match", action: TestBuilderBaseFindMatchTap},
        {label: "F3 - Deploy Stage 1", action: TestBuilderBaseStageOneDeployment},
        {label: "F4 - Monitor Stage 1", action: TestBuilderBaseStageOneMonitor},
        {label: "F5 - Deploy Stage 2", action: TestBuilderBaseStageTwoDeployment},
        {label: "F6 - Monitor Stage 2", action: TestBuilderBaseStageTwoMonitor},
        {label: "F7 - Run One Attack", action: TestBuilderBaseAttack},
        {label: "F8 - Start / Stop", action: ToggleBuilderBaseLoop}
    ]
    for index, buttonSpec in buttons {
        column := Mod(index - 1, 2)
        row := (index - 1) // 2
        button := BuilderBaseHarnessGui.Add(
            "Button",
            "x" (15 + column * 230) " y" (48 + row * 40) " w220 h32",
            buttonSpec.label
        )
        button.OnEvent("Click", CreateBuilderBaseButtonHandler(buttonSpec.action))
    }

    BuilderBaseHarnessGui.Add("Text", "x15 y220 w460 h22", "Live status / log")
    BuilderBaseHarnessConsole := BuilderBaseHarnessGui.Add(
        "Edit",
        "x15 y245 w460 h165 ReadOnly +VScroll",
        ""
    )
    BuilderBaseHarnessGui.OnEvent("Close", CloseBuilderBaseHarnessGui)
    BuilderBaseHarnessGui.Show("w490 h430")
    BuilderBaseHarnessLog("Ready. Use F1–F8 or click the matching button.")
}

CloseBuilderBaseHarnessGui(*) {
    global BuilderBaseHarnessRunning
    BuilderBaseHarnessRunning := false
    ExitApp()
}

CreateBuilderBaseButtonHandler(action) {
    return (*) => action.Call()
}

CreateBuilderBaseBypassFlow(stepNumber) {
    global BuilderBaseHarnessRunning, BuilderBaseHarnessFlow
    global BuilderBaseHarnessSides
    EnsureBuilderBaseHarnessMapping()
    BuilderBaseHarnessRunning := true
    BuilderBaseHarnessFlow := BuilderBaseFlow(BuilderBaseHarnessPrimitives())

    switch stepNumber {
        case 4:
            ; Stage-one monitoring needs no deployment-side state.
        case 5:
            if (BuilderBaseHarnessSides.Length == 0)
                throw Error("No calibrated Builder Base deployment sides exist.")
            BuilderBaseHarnessFlow.State.side := Random(
                1,
                BuilderBaseHarnessSides.Length
            )
            BuilderBaseHarnessFlow.State.stageOneOutcome := "three_stars"
        case 6:
            BuilderBaseHarnessFlow.State.stageTwoDeployed := true
        default:
            throw Error("Unsupported Builder Base bypass step: " stepNumber)
    }

    BuilderBaseHarnessLog(
        "Ctrl+F" stepNumber ": prerequisite bypass active."
    )
    return BuilderBaseHarnessFlow
}

class BuilderBaseHarnessPrimitives {
    Do(name, args*) {
        switch name {
            case "log":
                BuilderBaseHarnessLog(args[1])
                return true
            case "is_builder_running":
                global BuilderBaseHarnessRunning
                return BuilderBaseHarnessRunning
            case "tap_builder_attack":
                return TapBuilderBaseClient("attack", 300)
            case "tap_builder_find_match":
                return TapBuilderBaseClient("find_match", 500)
            case "wait":
                return WaitForBuilderBaseHarness(args[1])
            case "prepare_builder_viewport":
                return PrepareBuilderBaseViewport()
            case "random_builder_side":
                return Random(1, BuilderBaseHarnessSides.Length)
            case "deploy_builder_troops":
                return DeployBuilderBaseTroops(args[1])
            case "capture_builder_frame":
                return CaptureBuilderBaseFrame(args[1])
            case "analyze_builder_three_stars":
                return AnalyzeBuilderBaseThreeStars(args[1])
            case "tap_return_home":
                BuilderBaseHarnessLog("Return Home tap sent.")
                return TapBuilderBaseClient("return_home", 300)
            case "detect_builder_home_from_frame":
                return DetectBuilderBaseHome(args[1])
        }
        throw Error("Unknown Builder Base harness operation: " name)
    }
}

TestBuilderBaseAttackTap() {
    BuilderBaseHarnessLog("F1 started: Attack")
    try {
        EnsureBuilderBaseHarnessMapping()
        TapBuilderBaseClient("attack", 300)
        BuilderBaseHarnessLog("F1: Builder Base Attack tap sent.")
    } catch as err {
        BuilderBaseHarnessLog("F1 failed: " FormatBuilderBaseHarnessError(err))
    }
}

TestBuilderBaseFindMatchTap() {
    BuilderBaseHarnessLog("F2 started: Find Match")
    try {
        EnsureBuilderBaseHarnessMapping()
        TapBuilderBaseClient("find_match", 500)
        BuilderBaseHarnessLog("F2: green Find Match tap sent.")
    } catch as err {
        BuilderBaseHarnessLog("F2 failed: " FormatBuilderBaseHarnessError(err))
    }
}

TestBuilderBaseStageOneDeployment() {
    global BuilderBaseHarnessRunning, BuilderBaseHarnessFlow
    BuilderBaseHarnessLog("F3 started: Deploy Stage 1")
    try {
        EnsureBuilderBaseHarnessMapping()
        BuilderBaseHarnessRunning := true
        BuilderBaseHarnessFlow := BuilderBaseFlow(BuilderBaseHarnessPrimitives())
        if !BuilderBaseHarnessFlow._Wait(4000)
            throw Error("Builder Base harness stopped during matchmaking wait.")
        if !BuilderBaseHarnessFlow.PrepareStageOne()
            throw Error("Builder Base viewport or stage-one deployment failed.")
        BuilderBaseHarnessLog("F3: stage-one deployment complete.")
    } catch as err {
        BuilderBaseHarnessRunning := false
        BuilderBaseHarnessLog("F3 failed: " FormatBuilderBaseHarnessError(err))
    }
}

TestBuilderBaseStageOneMonitor(bypassPrerequisites := false) {
    global BuilderBaseHarnessRunning, BuilderBaseHarnessFlow
    BuilderBaseHarnessLog("F4 started: Monitor Stage 1")
    try {
        if bypassPrerequisites
            CreateBuilderBaseBypassFlow(4)
        if !IsObject(BuilderBaseHarnessFlow) {
            BuilderBaseHarnessLog("F4 requires F3 or F7 to choose a deployment side.")
            return
        }
        outcome := BuilderBaseHarnessFlow.MonitorStageOne()
        BuilderBaseHarnessFlow.State.stageOneOutcome := outcome
        BuilderBaseHarnessLog("F4: stage-one monitor ended with " outcome ".")
        if (outcome != "three_stars")
            BuilderBaseHarnessRunning := false
    } catch as err {
        BuilderBaseHarnessRunning := false
        BuilderBaseHarnessLog("F4 failed: " FormatBuilderBaseHarnessError(err))
    }
}

TestBuilderBaseStageTwoDeployment(bypassPrerequisites := false) {
    global BuilderBaseHarnessRunning, BuilderBaseHarnessFlow
    BuilderBaseHarnessLog("F5 started: Deploy Stage 2")
    try {
        if bypassPrerequisites
            CreateBuilderBaseBypassFlow(5)
        if !IsObject(BuilderBaseHarnessFlow) {
            BuilderBaseHarnessLog("F5 requires the stage-one flow from F3 or F7.")
            return
        }
        if (BuilderBaseHarnessFlow.State.stageOneOutcome != "three_stars") {
            BuilderBaseHarnessLog("F5 requires F4 to report three_stars.")
            return
        }
        if !BuilderBaseHarnessFlow.DeployStageTwo()
            throw Error("Builder Base harness stopped before stage-two deployment.")
        BuilderBaseHarnessLog("F5: stage-two deployment complete.")
    } catch as err {
        BuilderBaseHarnessRunning := false
        BuilderBaseHarnessLog("F5 failed: " FormatBuilderBaseHarnessError(err))
    }
}

TestBuilderBaseStageTwoMonitor(bypassPrerequisites := false) {
    global BuilderBaseHarnessRunning, BuilderBaseHarnessFlow
    BuilderBaseHarnessLog("F6 started: Monitor Stage 2")
    try {
        if bypassPrerequisites
            CreateBuilderBaseBypassFlow(6)
        if !IsObject(BuilderBaseHarnessFlow) {
            BuilderBaseHarnessLog("F6 requires the stage-two flow from F5.")
            return
        }
        if !BuilderBaseHarnessFlow.State.stageTwoDeployed {
            BuilderBaseHarnessLog("F6 requires F5 to complete stage-two deployment.")
            return
        }
        outcome := BuilderBaseHarnessFlow.MonitorStageTwo()
        BuilderBaseHarnessLog("F6: stage-two monitor ended with " outcome ".")
        BuilderBaseHarnessRunning := false
    } catch as err {
        BuilderBaseHarnessRunning := false
        BuilderBaseHarnessLog("F6 failed: " FormatBuilderBaseHarnessError(err))
    }
}

TestBuilderBaseAttack() {
    global BuilderBaseHarnessRunning, BuilderBaseHarnessFlow
    BuilderBaseHarnessLog("F7 started: Run One Attack")
    try {
        EnsureBuilderBaseHarnessMapping()
        BuilderBaseHarnessRunning := true
        BuilderBaseHarnessFlow := BuilderBaseFlow(BuilderBaseHarnessPrimitives())
        outcome := BuilderBaseHarnessFlow.Attack()
        BuilderBaseHarnessLog("F7: BuilderBaseAttack ended with " outcome ".")
    } catch as err {
        BuilderBaseHarnessLog("F7 failed: " FormatBuilderBaseHarnessError(err))
    } finally {
        BuilderBaseHarnessRunning := false
    }
}

ToggleBuilderBaseLoop() {
    global BuilderBaseHarnessRunning
    BuilderBaseHarnessLog("F8 started: Start / Stop")
    if BuilderBaseHarnessRunning {
        BuilderBaseHarnessRunning := false
        BuilderBaseHarnessLog("F8: stop requested; the current operation will finish its stop check.")
        return
    }
    try {
        EnsureBuilderBaseHarnessMapping()
        BuilderBaseHarnessRunning := true
        SetTimer(RunBuilderBaseHarnessLoop, -10)
        BuilderBaseHarnessLog("F8: minimal outer Builder Base loop started.")
    } catch as err {
        BuilderBaseHarnessRunning := false
        BuilderBaseHarnessLog("F8 failed: " FormatBuilderBaseHarnessError(err))
    }
}

RunBuilderBaseHarnessLoop() {
    global BuilderBaseHarnessRunning, BuilderBaseHarnessFlow
    try {
        BuilderBaseHarnessFlow := BuilderBaseFlow(BuilderBaseHarnessPrimitives())
        BuilderBaseHarnessFlow.RunLoop()
    } catch as err {
        BuilderBaseHarnessLog("Outer loop failed: " FormatBuilderBaseHarnessError(err))
    } finally {
        BuilderBaseHarnessRunning := false
        BuilderBaseHarnessLog("Outer Builder Base loop stopped.")
    }
}

LoadBuilderBaseHarnessConfig() {
    global BuilderBaseHarnessSerial, BuilderBaseHarnessProvider
    global BuilderBaseHarnessViewport, BuilderBaseHarnessSides, BuilderBaseHarnessPoints
    if !FileExist("config.ini")
        throw Error("config.ini was not found.")

    BuilderBaseHarnessSerial := IniRead("config.ini", "ADBViewport", "Serial", "")
    BuilderBaseHarnessProvider := IniRead("config.ini", "ADBViewport", "Provider", "")
    BuilderBaseHarnessViewport := {
        left: ReadBuilderBaseHarnessInteger("ADBViewport", "Left"),
        top: ReadBuilderBaseHarnessInteger("ADBViewport", "Top"),
        right: ReadBuilderBaseHarnessInteger("ADBViewport", "Right"),
        bottom: ReadBuilderBaseHarnessInteger("ADBViewport", "Bottom"),
        clientWidth: ReadBuilderBaseHarnessInteger("ADBViewport", "ClientWidth"),
        clientHeight: ReadBuilderBaseHarnessInteger("ADBViewport", "ClientHeight")
    }
    BuilderBaseHarnessPoints := {
        attack: {
            x: ReadBuilderBaseHarnessInteger("Coordinates", "BBAttackBtnX"),
            y: ReadBuilderBaseHarnessInteger("Coordinates", "BBAttackBtnY")
        },
        find_match: {
            x: ReadBuilderBaseHarnessInteger("Coordinates", "BBFindMatchBtnX"),
            y: ReadBuilderBaseHarnessInteger("Coordinates", "BBFindMatchBtnY")
        },
        return_home: {
            x: ReadBuilderBaseHarnessInteger("Coordinates", "ReturnHomeClickX"),
            y: ReadBuilderBaseHarnessInteger("Coordinates", "ReturnHomeClickY")
        },
        stars: [
            {x: ReadBuilderBaseHarnessInteger("Coordinates", "BBStar1X"), y: ReadBuilderBaseHarnessInteger("Coordinates", "BBStar1Y")},
            {x: ReadBuilderBaseHarnessInteger("Coordinates", "BBStar2X"), y: ReadBuilderBaseHarnessInteger("Coordinates", "BBStar2Y")},
            {x: ReadBuilderBaseHarnessInteger("Coordinates", "BBStar3X"), y: ReadBuilderBaseHarnessInteger("Coordinates", "BBStar3Y")}
        ]
    }
    BuilderBaseHarnessSides := []
    Loop 4 {
        index := A_Index
        BuilderBaseHarnessSides.Push({
            startX: ReadBuilderBaseHarnessInteger("Coordinates", "BBSide" index "StartX"),
            startY: ReadBuilderBaseHarnessInteger("Coordinates", "BBSide" index "StartY"),
            endX: ReadBuilderBaseHarnessInteger("Coordinates", "BBSide" index "EndX"),
            endY: ReadBuilderBaseHarnessInteger("Coordinates", "BBSide" index "EndY")
        })
    }
}

ReadBuilderBaseHarnessInteger(section, key) {
    value := IniRead("config.ini", section, key, "")
    if (value == "" || !IsNumber(value))
        throw Error("config.ini is missing " section "." key ".")
    return Round(Number(value))
}

EnsureBuilderBaseHarnessMapping() {
    global BuilderBaseHarnessSerial, BuilderBaseHarnessProvider
    global BuilderBaseHarnessViewport, BuilderBaseHarnessDisplay
    if (BuilderBaseHarnessSerial == "")
        throw Error("ADBViewport.Serial is missing. Run Builder Base calibration first.")
    if (
        BuilderBaseHarnessViewport.right <= BuilderBaseHarnessViewport.left
        || BuilderBaseHarnessViewport.bottom <= BuilderBaseHarnessViewport.top
    ) {
        throw Error("ADB viewport bounds are invalid. Run Builder Base calibration first.")
    }
    BuilderBaseHarnessDisplay := QueryBuilderBaseHarnessDisplay()
    ConfigureADBClientMapping(
        BuilderBaseHarnessViewport.left,
        BuilderBaseHarnessViewport.top,
        BuilderBaseHarnessViewport.right,
        BuilderBaseHarnessViewport.bottom,
        BuilderBaseHarnessDisplay.width,
        BuilderBaseHarnessDisplay.height,
        BuilderBaseHarnessViewport.clientWidth,
        BuilderBaseHarnessViewport.clientHeight,
        BuilderBaseHarnessProvider,
        BuilderBaseHarnessSerial
    )
}

PrepareBuilderBaseViewport() {
    global BuilderBaseHarnessViewport
    EnsureBuilderBaseHarnessPinchHelper()
    interaction := CreateBuilderBaseHarnessInteraction()
    centerX := BuilderBaseHarnessViewport.left
        + (BuilderBaseHarnessViewport.right - BuilderBaseHarnessViewport.left) // 2
    centerY := BuilderBaseHarnessViewport.top
        + (BuilderBaseHarnessViewport.bottom - BuilderBaseHarnessViewport.top) // 2
    WaitForBuilderBaseHarnessPreDelay(300)
    interaction.Pinch(centerX, centerY, 200, 45, 200, 300)
    if !WaitForBuilderBaseHarness(300)
        return false
    BuilderBaseHarnessLog("Viewport zoom-out sent through the calibrated ADB pinch boundary.")
    return true
}

TapBuilderBaseClient(pointName, intendedDelayMs) {
    global BuilderBaseHarnessPoints
    point := BuilderBaseHarnessPoints.%pointName%
    interaction := CreateBuilderBaseHarnessInteraction()
    WaitForBuilderBaseHarnessPreDelay(intendedDelayMs)
    return interaction.Tap(point.x, point.y, intendedDelayMs)
}

CreateBuilderBaseHarnessInteraction() {
    global BuilderBaseHarnessSerial
    return CreateADBClientInteraction(
        BuilderBaseHarnessSerial,
        BuilderBaseHarnessCommandSink,
        BuilderBaseHarnessDelaySink,
        BuilderBaseHarnessRandomSink
    )
}

BuilderBaseHarnessCommandSink(arguments) {
    result := RunBuilderBaseHarnessADBOutput(arguments)
    if !result.ok
        throw Error("ADB interaction failed: " result.output)
}

EnsureBuilderBaseHarnessPinchHelper() {
    global BuilderBaseHarnessSerial, BuilderBaseHarnessPinchHelperSerial
    global BuilderBaseHarnessPinchTargetApk, BuilderBaseHarnessPinchInstrumentationApk
    global BuilderBaseHarnessPinchTargetPackage, BuilderBaseHarnessPinchInstrumentationPackage
    if (BuilderBaseHarnessPinchHelperSerial == BuilderBaseHarnessSerial)
        return true
    InstallBuilderBaseHarnessPinchHelper(
        BuilderBaseHarnessSerial,
        BuilderBaseHarnessPinchTargetApk,
        BuilderBaseHarnessPinchTargetPackage
    )
    InstallBuilderBaseHarnessPinchHelper(
        BuilderBaseHarnessSerial,
        BuilderBaseHarnessPinchInstrumentationApk,
        BuilderBaseHarnessPinchInstrumentationPackage
    )
    BuilderBaseHarnessPinchHelperSerial := BuilderBaseHarnessSerial
    return true
}

InstallBuilderBaseHarnessPinchHelper(serial, apkPath, packageName) {
    if IsBuilderBaseHarnessPackageInstalled(serial, packageName)
        return true
    if !FileExist(apkPath)
        throw Error("Pinch helper APK is missing: " apkPath)
    result := RunBuilderBaseHarnessADBOutput(
        '-s "' serial '" install -r "' apkPath '"'
    )
    if !result.ok || !InStr(result.output, "Success")
        throw Error("Could not install pinch helper: " result.output)
    return true
}

IsBuilderBaseHarnessPackageInstalled(serial, packageName) {
    result := RunBuilderBaseHarnessADBOutput(
        '-s "' serial '" shell pm path "' packageName '"'
    )
    return result.ok && InStr(result.output, "package:")
}

BuilderBaseHarnessDelaySink(milliseconds) {
    if (milliseconds > 0)
        Sleep milliseconds
}

BuilderBaseHarnessRandomSink(minimum, maximum) {
    return Random(minimum, maximum)
}

WaitForBuilderBaseHarnessPreDelay(intendedDelayMs) {
    timing := GetADBActionTiming(intendedDelayMs)
    if (timing.PreDelay > 0)
        Sleep timing.PreDelay
}

WaitForBuilderBaseHarness(milliseconds) {
    global BuilderBaseHarnessRunning
    remaining := milliseconds
    while (remaining > 0) {
        if !BuilderBaseHarnessRunning
            return false
        slice := Min(100, remaining)
        Sleep slice
        remaining -= slice
    }
    return true
}

DeployBuilderBaseTroops(sideIndex) {
    global BuilderBaseHarnessSides
    if (sideIndex < 1 || sideIndex > BuilderBaseHarnessSides.Length)
        throw Error("Builder Base side is outside calibration.")
    side := BuilderBaseHarnessSides[sideIndex]
    interaction := CreateBuilderBaseHarnessInteraction()
    for keyIndex, key in ["q", "1", "2", "3", "4", "5", "6", "7", "8"] {
        if !WaitForBuilderBaseHarness(175)
            return false
        interaction.KeyEvent("KEYCODE_" StrUpper(key), 100)
        slotPosition := (keyIndex - 1) * 0.1
        Loop 1 {
            clientX := side.startX + slotPosition * (side.endX - side.startX)
            clientY := side.startY + slotPosition * (side.endY - side.startY)
            WaitForBuilderBaseHarnessPreDelay(100)
            interaction.Tap(clientX, clientY, 100)
        }
    }
    BuilderBaseHarnessLog("Deployed Q12345678 on Builder Base side " sideIndex ".")
    return true
}

IsBuilderBasePngFrame(framePath) {
    if (framePath == "" || !FileExist(framePath) || FileGetSize(framePath) < 8)
        return false
    file := FileOpen(framePath, "r")
    if !IsObject(file)
        return false
    signature := []
    Loop 8
        signature.Push(file.ReadUChar())
    file.Close()
    expected := [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    Loop 8 {
        if (signature[A_Index] != expected[A_Index])
            return false
    }
    return true
}

CaptureBuilderBaseFrame(section) {
    global BuilderBaseHarnessCaptureSequence, BuilderBaseHarnessSerial
    adbPath := ResolveBuilderBaseHarnessADBPath()
    BuilderBaseHarnessCaptureSequence += 1
    safeSection := RegExReplace(section, "[^A-Za-z0-9_-]", "_")
    scriptProcessId := DllCall("GetCurrentProcessId", "uint")
    framePath := (
        A_Temp "\coc_builder_base_loop_"
            scriptProcessId "_" A_TickCount "_"
            BuilderBaseHarnessCaptureSequence "_"
            safeSection ".png"
    )
    captureStderrPath := framePath ".stderr.txt"
    command := (
        A_ComSpec ' /D /S /C ""' adbPath '" -s "'
            BuilderBaseHarnessSerial
            '" exec-out screencap -p > "'
            framePath '" 2> "'
            captureStderrPath '""'
    )
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    fileSize := FileExist(framePath)
        ? FileGetSize(framePath)
        : 0
    if (exitCode != 0 && FileExist(captureStderrPath)) {
        captureStderr := Trim(FileRead(captureStderrPath), " `t`r`n")
        if (captureStderr != "") {
            captureStderr := RegExReplace(captureStderr, "\s+", " ")
            if (StrLen(captureStderr) > 500)
                captureStderr := SubStr(captureStderr, 1, 500) "..."
            BuilderBaseHarnessLog("ADB screencap stderr: " captureStderr)
        }
    }
    frameHasPngSignature := IsBuilderBasePngFrame(framePath)
    if (exitCode != 0 || !frameHasPngSignature) {
        BuilderBaseHarnessLog(
            "Fresh " section " frame invalid (ADB exit=" exitCode ", bytes=" fileSize "); retrying after one second."
        )
        ReleaseBuilderBaseFrame({path: framePath})
        return false
    }
    try FileDelete(captureStderrPath)
    BuilderBaseHarnessLog("Capture complete before analysis: " section ".")
    return {valid: true, path: framePath, section: section}
}

AnalyzeBuilderBaseThreeStars(frame) {
    global BuilderBaseHarnessPoints
    if (!IsObject(frame) || !frame.valid)
        return false
    region := ResolveBuilderBaseStarRegion()
    bitmap := 0
    try {
        bitmap := LoadBuilderBaseFrameBitmap(frame.path)
        results := []
        goldenStarCount := 0
        for star in BuilderBaseHarnessPoints.stars {
            adbPoint := TranslateClientPointToADB(star.x, star.y)
            if (
                adbPoint.x < region.adb.x
                || adbPoint.y < region.adb.y
                || adbPoint.x >= region.adb.x + region.adb.width
                || adbPoint.y >= region.adb.y + region.adb.height
            ) {
                throw Error("Calibrated star lies outside the star bounding box.")
            }
            isGolden := IsGoldenBuilderBaseStar(bitmap, adbPoint.x, adbPoint.y)
            results.Push(isGolden)
            if isGolden
                goldenStarCount += 1
        }
        threeStars := results[1] && results[2] && results[3]
        BuilderBaseHarnessLog(
            "Star analysis: " goldenStarCount "/3 gold; box client ("
                region.client.x "," region.client.y " "
                region.client.width "x" region.client.height ")."
        )
        return threeStars
    } finally {
        if bitmap
            DllCall("gdiplus\GdipDisposeImage", "ptr", bitmap)
        ReleaseBuilderBaseFrame(frame)
    }
}

ResolveBuilderBaseStarRegion() {
    global BuilderBaseHarnessPoints
    minimumX := BuilderBaseHarnessPoints.stars[1].x
    maximumX := minimumX
    minimumY := BuilderBaseHarnessPoints.stars[1].y
    maximumY := minimumY
    for star in BuilderBaseHarnessPoints.stars {
        minimumX := Min(minimumX, star.x)
        maximumX := Max(maximumX, star.x)
        minimumY := Min(minimumY, star.y)
        maximumY := Max(maximumY, star.y)
    }
    margin := 20
    client := {
        x: minimumX - margin,
        y: minimumY - margin,
        width: maximumX - minimumX + margin * 2 + 1,
        height: maximumY - minimumY + margin * 2 + 1
    }
    return {client: client, adb: TranslateClientRectToADB(client.x, client.y, client.width, client.height)}
}

DetectBuilderBaseHome(frame) {
    global BuilderBaseHarnessPoints
    if (!IsObject(frame) || !frame.valid)
        return false
    bitmap := 0
    try {
        bitmap := LoadBuilderBaseFrameBitmap(frame.path)
        point := BuilderBaseHarnessPoints.attack
        left := TranslateClientPointToADB(point.x - 45, point.y)
        right := TranslateClientPointToADB(point.x + 45, point.y)
        return IsBuilderBaseAttackColor(ReadBuilderBasePixel(bitmap, left.x, left.y))
            || IsBuilderBaseAttackColor(ReadBuilderBasePixel(bitmap, right.x, right.y))
    } finally {
        if bitmap
            DllCall("gdiplus\GdipDisposeImage", "ptr", bitmap)
        ReleaseBuilderBaseFrame(frame)
    }
}

IsGoldenBuilderBaseStar(bitmap, centerX, centerY) {
    for dx in [-7, -3, 0, 3, 7] {
        for dy in [-7, -3, 0, 3, 7] {
            color := ReadBuilderBasePixel(bitmap, centerX + dx, centerY + dy)
            if IsBuilderBaseGoldenColor(color)
                return true
        }
    }
    return false
}

IsBuilderBaseGoldenColor(color) {
    ; Proven ADB detector copied from IsGoldenADB in the original bot.
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    return (r > 130) && (g > 100)
        && (r > b + 15) && (g > b - 30)
}

ReleaseBuilderBaseFrame(frame) {
    if !IsObject(frame) || !frame.HasOwnProp("path") || frame.path == ""
        return
    try FileDelete(frame.path)
    try FileDelete(frame.path ".stderr.txt")
}

IsBuilderBaseAttackColor(color) {
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    isBrownWood := (r > g) && (g > b) && (r - b >= 25) && (g - b >= 10) && (r >= 70 && r <= 250)
    isTanMap := (r >= 180) && (g >= 140) && (b >= 90) && (r >= g) && (g >= b * 0.75)
    return isBrownWood || isTanMap
}

LoadBuilderBaseFrameBitmap(framePath) {
    InitBuilderBaseHarnessGdip()
    bitmap := 0
    status := DllCall("gdiplus\GdipLoadImageFromFile", "wstr", framePath, "ptr*", &bitmap)
    if (status != 0 || !bitmap)
        throw Error("Could not load the fresh Builder Base frame.")
    return bitmap
}

ReadBuilderBasePixel(bitmap, x, y) {
    color := 0
    status := DllCall("gdiplus\GdipBitmapGetPixel", "ptr", bitmap, "int", Round(x), "int", Round(y), "uint*", &color)
    if (status != 0)
        return 0
    return color & 0xFFFFFF
}

InitBuilderBaseHarnessGdip() {
    global BuilderBaseHarnessGdipToken
    if BuilderBaseHarnessGdipToken
        return BuilderBaseHarnessGdipToken
    startupInput := Buffer(24, 0)
    NumPut("UInt", 1, startupInput, 0)
    token := 0
    status := DllCall("gdiplus\GdiplusStartup", "ptr*", &token, "ptr", startupInput, "ptr", 0)
    if (status != 0 || !token)
        throw Error("GDI+ could not start for Builder Base frame analysis.")
    BuilderBaseHarnessGdipToken := token
    return token
}

ResolveBuilderBaseHarnessADBPath() {
    for directory in StrSplit(EnvGet("PATH"), ";") {
        directory := Trim(directory, ' "')
        if (directory == "")
            continue
        candidate := RTrim(directory, "\\/") "\\adb.exe"
        if FileExist(candidate)
            return candidate
    }
    bundled := "C:\\Program Files\\Google\\Play Games Developer Emulator\\current\\emulator\\adb.exe"
    if FileExist(bundled)
        return bundled
    throw Error("adb.exe was not found.")
}

RunBuilderBaseHarnessADBOutput(arguments) {
    adbPath := ResolveBuilderBaseHarnessADBPath()
    outputPath := A_Temp "\\coc_builder_base_loop_adb_output.txt"
    try FileDelete(outputPath)
    command := A_ComSpec ' /D /S /C ""' adbPath '" ' arguments ' > "' outputPath '" 2>&1"'
    exitCode := RunWait(command, A_ScriptDir, "Hide")
    output := FileExist(outputPath) ? Trim(FileRead(outputPath), " `t`r`n") : ""
    try FileDelete(outputPath)
    return {ok: exitCode == 0, output: output}
}

QueryBuilderBaseHarnessDisplay() {
    global BuilderBaseHarnessSerial
    result := RunBuilderBaseHarnessADBOutput('-s "' BuilderBaseHarnessSerial '" shell wm size')
    if !result.ok
        throw Error("Could not query ADB display size: " result.output)
    if RegExMatch(result.output, "i)(?:Override|Physical) size:\s*(\d+)x(\d+)", &match)
        return {width: Number(match[1]), height: Number(match[2])}
    throw Error("Unrecognized ADB display size: " result.output)
}

BuilderBaseHarnessLog(message) {
    global BuilderBaseHarnessConsole
    timestampedMessage := "[" FormatTime(A_Now, "HH:mm:ss") "] " message
    OutputDebug("Builder Base Harness: " timestampedMessage)
    if IsObject(BuilderBaseHarnessConsole) {
        BuilderBaseHarnessConsole.Value .= timestampedMessage "`r`n"
        SendMessage(0x115, 7, 0, BuilderBaseHarnessConsole.Hwnd)
    }
    ToolTip(message)
    SetTimer(() => ToolTip(), -2500)
}

FormatBuilderBaseHarnessError(error) {
    details := error.Message
    if (error.What != "")
        details .= " | What: " error.What
    if (error.File != "" || error.Line != 0)
        details .= " | At: " error.File ":" error.Line
    if (error.Stack != "")
        details .= "`r`nStack: " error.Stack
    return details
}
