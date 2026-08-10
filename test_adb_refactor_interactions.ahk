#Requires AutoHotkey v2.0
#SingleInstance Force

global ADB_PINCH_COMPONENT := "com.example.instrumentation/PinchInstrumentation"
global ADBRefactorSupportLoaded := false
global LootOCRLogicLoaded := false
global ResourceThresholdLogicLoaded := false
global BuilderInfoOCRLogicLoaded := false
global TestResultPath := A_Temp "\adb_refactor_interactions_result.txt"

if FileExist(TestResultPath)
    FileDelete(TestResultPath)

#Include *i ADBcocbotrefactor_support.ahk
#Include *i builder_base_loop_logic.ahk
#Include *i loot_ocr_logic.ahk
#Include *i resource_threshold_logic.ahk
#Include *i builder_info_ocr_logic.ahk

if !ADBRefactorSupportLoaded {
    FileAppend("FAIL: ADB refactor interaction contract is not implemented.`n", TestResultPath)
    ExitApp(1)
}

global TestPassCount := 0
global TestFailCount := 0

class TestRecorder {
    __New() {
        this.Commands := []
        this.Delays := []
    }

    RecordCommand(arguments) {
        this.Commands.Push(arguments)
    }

    RecordDelay(milliseconds) {
        this.Delays.Push(milliseconds)
    }
}

class SequenceRandom {
    __New(values) {
        this.Values := values
        this.Index := 1
    }

    Next(minimum, maximum) {
        if (this.Index > this.Values.Length)
            throw Error("Random sequence exhausted.")
        value := this.Values[this.Index]
        this.Index += 1
        if (value < minimum || value > maximum)
            throw Error(Format("Injected random value {} escaped {}..{}.", value, minimum, maximum))
        return value
    }
}

class BuilderFlowRecorder {
    __New(infoFound := true, confirmSucceeds := true) {
        this.InfoFound := infoFound
        this.ConfirmSucceeds := confirmSucceeds
        this.Operations := []
        this.WaitDurations := []
    }

    Do(name, args*) {
        this.Operations.Push(name)
        switch name {
            case "log":
                return true
            case "capture_fresh_frame":
                return {
                    section: args[1],
                    path: "fresh-" args[1] ".png"
                }
            case "read_builders_from_frame":
                return {free: 2, total: 7, goblin: false}
            case "open_builder_menu":
                return true
            case "ocr_builder_suggestion":
                return {name: "X-Bow", x: 700, y: 450}
            case "tap_builder_suggestion":
                return true
            case "find_builder_info_from_frame":
                return this.InfoFound
                    ? {name: "Info icon", x: 800, y: 700}
                    : ""
            case "tap_builder_info":
                return true
            case "tap_upgrade_confirm":
                return this.ConfirmSucceeds
            case "clear_tap":
                return true
            case "wait":
                this.WaitDurations.Push(args[1])
                return true
        }
        throw Error("Unexpected builder-flow operation: " name)
    }
}

class LabFlowRecorder {
    __New(confirmSucceeds := true) {
        this.ConfirmSucceeds := confirmSucceeds
        this.Operations := []
    }

    Do(name, args*) {
        this.Operations.Push(name)
        switch name {
            case "log":
                return true
            case "capture_fresh_frame":
                return {section: args[1], path: "fresh-lab.png"}
            case "read_lab_from_frame":
                return {free: 1, total: 1, goblin: false}
            case "open_lab_menu":
                return true
            case "ocr_lab_suggestion":
                return {name: "Dragon", x: 700, y: 450}
            case "tap_lab_suggestion":
                return true
            case "tap_upgrade_confirm":
                return this.ConfirmSucceeds
            case "wait", "clear_tap":
                return true
        }
        throw Error("Unexpected lab-flow operation: " name)
    }
}

class TimerCycleRecorder {
    __New(triggered) {
        this.Triggered := triggered
        this.Operations := []
    }

    Do(name, args*) {
        this.Operations.Push(name)
        switch name {
            case "log":
                return true
            case "record_completed_attack":
                return 1
            case "timer_triggered":
                return this.Triggered
            case "exit_game_after_timer", "stop_bot":
                return true
        }
        throw Error("Unexpected timer-cycle operation: " name)
    }
}

FindOperationIndex(operations, name) {
    for index, operation in operations {
        if (operation == name)
            return index
    }
    return 0
}

FindOperationIndices(operations, name) {
    indices := []
    for index, operation in operations {
        if (operation == name)
            indices.Push(index)
    }
    return indices
}

AssertEqual(expected, actual, description) {
    if (expected != actual)
        throw Error(Format("{}: expected [{}], got [{}].", description, expected, actual))
}

AssertNear(expected, actual, tolerance, description) {
    if (Abs(expected - actual) > tolerance)
        throw Error(Format("{}: expected {} +/- {}, got {}.", description, expected, tolerance, actual))
}

AssertTrue(condition, description) {
    if !condition
        throw Error(description)
}

AssertThrows(callback, description) {
    try {
        callback.Call()
    } catch {
        return
    }
    throw Error(description ": expected an exception.")
}

RunTest(name, callback) {
    global TestPassCount, TestFailCount, TestResultPath
    try {
        callback.Call()
        TestPassCount += 1
        FileAppend("PASS: " name "`n", TestResultPath)
    } catch as err {
        TestFailCount += 1
        FileAppend(
            "FAIL: " name " - " err.Message
                " | What: " err.What
                " | Extra: " err.Extra
                " | At: " err.File ":" err.Line
                "`n",
            TestResultPath
        )
    }
}

class BuilderBaseFlowRecorder {
    __New(scriptedResults := Map()) {
        this.Operations := []
        this.ScriptedResults := scriptedResults
    }

    Do(name, args*) {
        this.Operations.Push({Name: name, Args: args})
        if this.ScriptedResults.Has(name) {
            results := this.ScriptedResults[name]
            if (results.Length > 0)
                return results.RemoveAt(1)
        }
        switch name {
            case "is_builder_running":
                return false
            case "random_builder_side":
                return 1
            case "capture_builder_frame":
                return {valid: true}
            case "analyze_builder_three_stars":
                return false
            case "detect_builder_home_from_frame":
                return false
        }
        return true
    }
}

BuilderBaseOperationNames(recorder) {
    names := []
    for operation in recorder.Operations
        names.Push(operation.Name)
    return names
}

CountBuilderBaseOperations(recorder, name) {
    count := 0
    for operation in recorder.Operations {
        if (operation.Name == name)
            count += 1
    }
    return count
}

FindBuilderBaseOperationIndex(recorder, name, occurrence := 1) {
    found := 0
    for index, operation in recorder.Operations {
        if (operation.Name == name) {
            found += 1
            if (found == occurrence)
                return index
        }
    }
    return 0
}

FindBuilderBaseOperation(recorder, name, occurrence := 1) {
    found := 0
    for operation in recorder.Operations {
        if (operation.Name == name) {
            found += 1
            if (found == occurrence)
                return operation
        }
    }
    throw Error("Builder Base operation was not recorded: " name)
}

CreateBuilderBaseFlowForTest(recorder) {
    if !IsSet(BuilderBaseFlow)
        throw Error("BuilderBaseFlow is not implemented.")
    return BuilderBaseFlow(recorder)
}

TestBuilderBaseAttackOrdersNavigationBeforeDeployment() {
    recorder := BuilderBaseFlowRecorder(Map(
        "is_builder_running", [true, false],
        "random_builder_side", [3],
        "capture_builder_frame", [{valid: true}],
        "analyze_builder_three_stars", [false]
    ))
    flow := CreateBuilderBaseFlowForTest(recorder)

    result := flow.Attack()

    AssertEqual("stopped", result, "attack stops when the builder loop stops")
    names := BuilderBaseOperationNames(recorder)
    expected := [
        "tap_builder_attack",
        "tap_builder_find_match",
        "wait",
        "prepare_builder_viewport",
        "random_builder_side",
        "deploy_builder_troops"
    ]
    Loop expected.Length {
        AssertEqual(expected[A_Index], names[A_Index], "Builder Base attack operation order " A_Index)
    }
    AssertEqual(
        4000,
        FindBuilderBaseOperation(recorder, "wait").Args[1],
        "matchmaking wait is four seconds"
    )
}

TestBuilderBaseStageOneReturnsHomeAfterFourCompletedAnalyses() {
    recorder := BuilderBaseFlowRecorder(Map(
        "is_builder_running", [true, true, true, true],
        "capture_builder_frame", [
            {valid: true}, {valid: true}, {valid: true}, {valid: true},
            {valid: true}
        ],
        "analyze_builder_three_stars", [false, false, false, false],
        "detect_builder_home_from_frame", [true]
    ))
    flow := CreateBuilderBaseFlowForTest(recorder)

    result := flow.MonitorStageOne()

    AssertEqual("home", result, "stage one reports Builder Base home")
    AssertEqual(
        5,
        CountBuilderBaseOperations(recorder, "capture_builder_frame"),
        "fourth star check captures a distinct home frame"
    )
    AssertEqual(
        4,
        CountBuilderBaseOperations(recorder, "analyze_builder_three_stars"),
        "four completed star analyses run before Return Home"
    )
    AssertEqual(
        5,
        CountBuilderBaseOperations(recorder, "wait"),
        "star checks and both Return Home taps are paced"
    )
    Loop 3 {
        AssertEqual(
            1000,
            FindBuilderBaseOperation(recorder, "wait", A_Index).Args[1],
            "stage-one star-check interval " A_Index " is one second"
        )
    }
    AssertEqual(
        2000,
        FindBuilderBaseOperation(recorder, "wait", 4).Args[1],
        "first Return Home tap waits two seconds"
    )
    AssertEqual(
        2000,
        FindBuilderBaseOperation(recorder, "wait", 5).Args[1],
        "second Return Home tap waits two seconds before the fresh home check"
    )
    AssertEqual(
        2,
        CountBuilderBaseOperations(recorder, "tap_return_home"),
        "one Builder Base home attempt sends two Return Home taps"
    )
    firstReturnHomeIndex := FindBuilderBaseOperationIndex(
        recorder,
        "tap_return_home",
        1
    )
    firstSettleWaitIndex := FindBuilderBaseOperationIndex(recorder, "wait", 4)
    secondReturnHomeIndex := FindBuilderBaseOperationIndex(
        recorder,
        "tap_return_home",
        2
    )
    secondSettleWaitIndex := FindBuilderBaseOperationIndex(recorder, "wait", 5)
    homeCaptureIndex := FindBuilderBaseOperationIndex(
        recorder,
        "capture_builder_frame",
        5
    )
    AssertTrue(
        firstReturnHomeIndex > 0
            && firstSettleWaitIndex > firstReturnHomeIndex
            && secondReturnHomeIndex > firstSettleWaitIndex
            && secondSettleWaitIndex > secondReturnHomeIndex
            && homeCaptureIndex > secondSettleWaitIndex,
        "both Return Home taps settle before the fresh Builder Base home capture"
    )
}

TestBuilderBaseStageOneResetsFourCheckCycle() {
    recorder := BuilderBaseFlowRecorder(Map(
        "is_builder_running", [true, true, true, true, true, false],
        "capture_builder_frame", [
            {valid: true}, {valid: true}, {valid: true}, {valid: true},
            {valid: true}, {valid: true}
        ],
        "analyze_builder_three_stars", [
            false, false, false, false, false
        ],
        "detect_builder_home_from_frame", [false]
    ))
    flow := CreateBuilderBaseFlowForTest(recorder)

    result := flow.MonitorStageOne()

    AssertEqual("stopped", result, "stage one remains stoppable after a failed home check")
    AssertEqual(
        2,
        CountBuilderBaseOperations(recorder, "tap_return_home"),
        "the first four-check cycle sends one two-tap Return Home attempt"
    )
    AssertEqual(
        7,
        CountBuilderBaseOperations(recorder, "wait"),
        "completed non-star checks and the home transition are paced"
    )
    messages := []
    for operation in recorder.Operations {
        if (operation.Name == "log")
            messages.Push(operation.Args[1])
    }
    combined := ""
    for message in messages
        combined .= message "`n"
    AssertTrue(
        InStr(combined, "Stage-one check cycle reset to 0/4.") > 0,
        "failed home detection reports the four-check cycle reset"
    )
    AssertTrue(
        InStr(combined, "Stage-one check 5/4") == 0,
        "stage-one progress never grows beyond four"
    )
    firstCheckCount := 0
    for message in messages {
        if (message == "Stage-one check 1/4 completed.")
            firstCheckCount += 1
    }
    AssertEqual(
        2,
        firstCheckCount,
        "the first check after Return Home restarts at 1/4"
    )
}

TestBuilderBaseInvalidCaptureDoesNotAdvanceTheFourthCheck() {
    recorder := BuilderBaseFlowRecorder(Map(
        "is_builder_running", [true, true, true, true, true],
        "capture_builder_frame", [
            false,
            {valid: true}, {valid: true}, {valid: true}, {valid: true},
            {valid: true}
        ],
        "analyze_builder_three_stars", [false, false, false, false],
        "detect_builder_home_from_frame", [true]
    ))
    flow := CreateBuilderBaseFlowForTest(recorder)

    result := flow.MonitorStageOne()

    AssertEqual("home", result, "home is still returned after a capture retry")
    AssertEqual(
        4,
        CountBuilderBaseOperations(recorder, "analyze_builder_three_stars"),
        "invalid capture does not count as a star analysis"
    )
    AssertEqual(
        2,
        CountBuilderBaseOperations(recorder, "tap_return_home"),
        "Return Home waits for four successful analyses, then taps twice"
    )
    invalidCaptureIndex := FindBuilderBaseOperationIndex(
        recorder,
        "capture_builder_frame"
    )
    retryWaitIndex := FindBuilderBaseOperationIndex(recorder, "wait", 1)
    nextCaptureIndex := FindBuilderBaseOperationIndex(
        recorder,
        "capture_builder_frame",
        2
    )
    AssertTrue(
        retryWaitIndex > invalidCaptureIndex && nextCaptureIndex > retryWaitIndex,
        "invalid capture is retried synchronously after a stop-aware wait"
    )
    AssertEqual(
        1000,
        FindBuilderBaseOperation(recorder, "wait", 1).Args[1],
        "invalid capture waits one second before the next synchronous retry"
    )
}

TestBuilderBaseThreeStarsDeploysStageTwoOnTheSameSide() {
    recorder := BuilderBaseFlowRecorder(Map(
        "is_builder_running", [true, true],
        "random_builder_side", [4],
        "capture_builder_frame", [{valid: true}, {valid: true}],
        "analyze_builder_three_stars", [true],
        "detect_builder_home_from_frame", [true]
    ))
    flow := CreateBuilderBaseFlowForTest(recorder)

    result := flow.Attack()

    AssertEqual("home", result, "stage two returns home")
    firstDeployment := FindBuilderBaseOperation(
        recorder,
        "deploy_builder_troops",
        1
    )
    secondDeployment := FindBuilderBaseOperation(
        recorder,
        "deploy_builder_troops",
        2
    )
    AssertEqual(4, firstDeployment.Args[1], "stage one uses selected side")
    AssertEqual(4, secondDeployment.Args[1], "stage two reuses selected side")
    AssertEqual(
        15000,
        FindBuilderBaseOperation(recorder, "wait", 2).Args[1],
        "stage two waits fifteen seconds before deployment"
    )
    AssertEqual(
        15000,
        FindBuilderBaseOperation(recorder, "wait", 3).Args[1],
        "stage two waits fifteen seconds before Return Home"
    )
}

TestBuilderBaseStageTwoRequiresACompletedDeployment() {
    recorder := BuilderBaseFlowRecorder()
    flow := CreateBuilderBaseFlowForTest(recorder)

    AssertThrows(
        () => flow.MonitorStageTwo(),
        "stage-two monitoring rejects an undeployed stage"
    )
}

TestBuilderBaseStageTwoTracksDeploymentAndInvalidCaptureRetry() {
    recorder := BuilderBaseFlowRecorder(Map(
        "is_builder_running", [true],
        "capture_builder_frame", [false, {valid: true}],
        "detect_builder_home_from_frame", [true]
    ))
    flow := CreateBuilderBaseFlowForTest(recorder)
    flow.State.stageOneOutcome := "three_stars"

    deployed := flow.DeployStageTwo()
    AssertTrue(deployed, "stage two deploys after a three-star stage one")
    AssertTrue(
        flow.State.stageTwoDeployed,
        "successful deployment owns the stage-two lifecycle state"
    )

    result := flow.MonitorStageTwo()

    AssertEqual("home", result, "stage two returns home after a valid home frame")
    AssertEqual(
        1000,
        FindBuilderBaseOperation(recorder, "wait", 5).Args[1],
        "invalid home capture waits one second before synchronous retry"
    )
    AssertEqual(
        2000,
        FindBuilderBaseOperation(recorder, "wait", 3).Args[1],
        "stage two lets the first Return Home tap settle"
    )
    AssertEqual(
        2000,
        FindBuilderBaseOperation(recorder, "wait", 4).Args[1],
        "stage two lets the second Return Home tap settle before capture"
    )
    AssertTrue(
        !flow.State.stageTwoDeployed,
        "stage two clears its deployed state after reaching home"
    )
}

TestBuilderBaseOuterLoopCanCompleteAndStartTheNextAttack() {
    recorder := BuilderBaseFlowRecorder(Map(
        "is_builder_running", [true, true, true, true, false],
        "random_builder_side", [2, 3],
        "capture_builder_frame", [
            {valid: true}, {valid: true}, {valid: true}
        ],
        "analyze_builder_three_stars", [true, false],
        "detect_builder_home_from_frame", [true]
    ))
    flow := CreateBuilderBaseFlowForTest(recorder)

    flow.RunLoop()

    AssertEqual(
        2,
        CountBuilderBaseOperations(recorder, "tap_builder_attack"),
        "outer loop begins a second attack after the first reaches home"
    )
    AssertEqual(
        3,
        CountBuilderBaseOperations(recorder, "deploy_builder_troops"),
        "completed first attack deploys both stages before second stage one"
    )
    AssertEqual(
        2,
        FindBuilderBaseOperation(recorder, "deploy_builder_troops", 1).Args[1],
        "first attack stage one uses its selected side"
    )
    AssertEqual(
        2,
        FindBuilderBaseOperation(recorder, "deploy_builder_troops", 2).Args[1],
        "first attack stage two reuses its selected side"
    )
    AssertEqual(
        3,
        FindBuilderBaseOperation(recorder, "deploy_builder_troops", 3).Args[1],
        "next attack selects its own side after state reset"
    )
    AssertEqual(
        1,
        CountBuilderBaseOperations(recorder, "complete_global_cycle"),
        "Builder Base completes the shared lifecycle only after reaching home"
    )
    completion := FindBuilderBaseOperation(
        recorder,
        "complete_global_cycle"
    )
    AssertEqual(
        "builder",
        completion.Args[1],
        "Builder Base identifies its village to the shared lifecycle"
    )
    homeDetectionIndex := FindBuilderBaseOperationIndex(
        recorder,
        "detect_builder_home_from_frame"
    )
    completionIndex := FindBuilderBaseOperationIndex(
        recorder,
        "complete_global_cycle"
    )
    AssertTrue(
        completionIndex > homeDetectionIndex,
        "shared completion runs only after fresh Builder Base home detection"
    )
}

TestBuilderBaseOuterLoopOnlyBeginsAttacks() {
    recorder := BuilderBaseFlowRecorder(Map(
        "is_builder_running", [true, false, false],
        "random_builder_side", [2],
        "capture_builder_frame", [{valid: true}],
        "analyze_builder_three_stars", [false]
    ))
    flow := CreateBuilderBaseFlowForTest(recorder)

    flow.RunLoop()

    names := BuilderBaseOperationNames(recorder)
    AssertEqual("is_builder_running", names[1], "outer loop checks run state")
    AssertEqual("tap_builder_attack", names[2], "outer loop starts with attack")
    AssertEqual(
        1,
        CountBuilderBaseOperations(recorder, "tap_builder_attack"),
        "outer loop starts one attack before stop"
    )
}

TestBuilderBaseVisualHarnessContract() {
    harnessPath := A_ScriptDir "\test_builder_base_loop_visual.ahk"
    AssertTrue(
        FileExist(harnessPath) != "",
        "Builder Base visual harness exists"
    )
    source := FileRead(harnessPath)
    lootIncludeIndex := InStr(source, "#Include loot_ocr_logic.ahk")
    supportIncludeIndex := InStr(
        source,
        "#Include ADBcocbotrefactor_support.ahk"
    )
    AssertTrue(
        lootIncludeIndex > 0 && supportIncludeIndex > lootIncludeIndex,
        "Builder Base visual harness loads loot logic before shared support"
    )
    for required in [
        "#Include builder_base_loop_logic.ahk",
        "#Include ADBcocbotrefactor_support.ahk",
        "class BuilderBaseHarnessPrimitives",
        "F1:: TestBuilderBaseAttackTap()",
        "F2:: TestBuilderBaseFindMatchTap()",
        "F3:: TestBuilderBaseStageOneDeployment()",
        "F4:: TestBuilderBaseStageOneMonitor()",
        "F5:: TestBuilderBaseStageTwoDeployment()",
        "F6:: TestBuilderBaseStageTwoMonitor()",
        "F7:: TestBuilderBaseAttack()",
        "F8:: ToggleBuilderBaseLoop()",
        'case "complete_global_cycle"',
        "^F1:: TestBuilderBaseAttackTap()",
        "^F2:: TestBuilderBaseFindMatchTap()",
        "^F3:: TestBuilderBaseStageOneDeployment()",
        "^F4:: TestBuilderBaseStageOneMonitor(true)",
        "^F5:: TestBuilderBaseStageTwoDeployment(true)",
        "^F6:: TestBuilderBaseStageTwoMonitor(true)",
        "^F7:: TestBuilderBaseAttack()",
        "^F8:: ToggleBuilderBaseLoop()",
        "CreateBuilderBaseBypassFlow(4)",
        "CreateBuilderBaseBypassFlow(5)",
        "CreateBuilderBaseBypassFlow(6)",
        "prerequisite bypass active",
        "CreateBuilderBaseHarnessGui()",
        "BuilderBaseHarnessConsole",
        "ReadOnly +VScroll",
        'FormatTime(A_Now, "HH:mm:ss")',
        "F1 - Attack",
        "F8 - Start / Stop",
        "F1 started: Attack",
        "F2 started: Find Match",
        "F3 started: Deploy Stage 1",
        "F4 started: Monitor Stage 1",
        "F5 started: Deploy Stage 2",
        "F6 started: Monitor Stage 2",
        "F7 started: Run One Attack",
        "F8 started: Start / Stop",
        "EnsureBuilderBaseHarnessPinchHelper",
        "Pinch helper APK is missing",
        "ADB interaction failed: ",
        "BuilderBaseFlow(",
        "CaptureBuilderBaseFrame",
        "AnalyzeBuilderBaseThreeStars",
        "i)(?:Override|Physical) size:\s*(\d+)x(\d+)",
        "20",
        "Capture complete before analysis",
        "ADB exit=",
        "bytes=",
        "BuilderBaseHarnessCaptureSequence",
        'DllCall("GetCurrentProcessId", "uint")',
        "framePath :=",
        ".stderr.txt",
        '2> "',
        "ADB screencap stderr:",
        "IsBuilderBasePngFrame(",
        "frameHasPngSignature := IsBuilderBasePngFrame",
        "if (exitCode != 0 || !frameHasPngSignature)",
        "ReleaseBuilderBaseFrame",
        "Star analysis: ",
        "/3 gold",
        'case "log"',
        "Return Home"
    ] {
        AssertTrue(
            InStr(source, required) > 0,
            "Builder Base visual harness includes " required
        )
    }
    AssertTrue(
        !InStr(source, "#Include ADBcocbotrefactor.ahk"),
        "Builder Base visual harness does not start the production bot"
    )
    AssertTrue(
        !InStr(source, "global BuilderBaseHarnessFramePath :="),
        "Builder Base capture does not reuse a stale fixed frame path"
    )
    AssertTrue(
        !InStr(source, "A_Pid"),
        "Builder Base capture does not use an undefined A_Pid variable"
    )
    buttonBlockStart := InStr(source, "buttons := [")
    buttonBlockEnd := InStr(source, "]", true, buttonBlockStart)
    buttonBlock := SubStr(
        source,
        buttonBlockStart,
        buttonBlockEnd - buttonBlockStart + 1
    )
    AssertTrue(
        !InStr(buttonBlock, "Ctrl+") && !InStr(buttonBlock, "true"),
        "Builder Base GUI buttons retain normal prerequisite behavior"
    )
}

TestPinchHelperTargetsCurrentAndroid() {
    for manifestName in [
        "target\\AndroidManifest.xml",
        "instrumentation\\AndroidManifest.xml"
    ] {
        manifestPath := A_ScriptDir "\\pinch_test\\android-helper\\" manifestName
        AssertTrue(FileExist(manifestPath) != "", "pinch helper manifest exists: " manifestName)
        source := FileRead(manifestPath)
        AssertTrue(
            InStr(source, 'android:targetSdkVersion="36"') > 0,
            "pinch helper targets Android 36: " manifestName
        )
    }
    buildSource := FileRead(A_ScriptDir "\\pinch_test\\android-helper\\build.ps1")
    for required in [
        "ANDROID_SDK_ROOT",
        "Android\Sdk",
        "Android Studio\jbr",
        "android-36.1",
        "build-tools\36.0.0"
    ] {
        AssertTrue(
            InStr(buildSource, required) > 0,
            "pinch helper build discovers Android Studio tooling: " required
        )
    }
}

TestBuilderBaseGdipCallsUseValidDllNames() {
    source := FileRead(A_ScriptDir "\\test_builder_base_loop_visual.ahk")
    AssertTrue(
        !InStr(source, "gdiplus\\"),
        "Builder Base image analysis does not use an invalid double-backslash DLL name"
    )
    AssertTrue(
        InStr(source, "gdiplus\GdiplusStartup") > 0,
        "Builder Base image analysis starts GDI+ through the valid DLL name"
    )
    AssertTrue(
        !InStr(source, "GdipGetImagePixel"),
        "Builder Base image analysis excludes the nonexistent GDI+ pixel export"
    )
    AssertTrue(
        InStr(source, "gdiplus\GdipBitmapGetPixel") > 0,
        "Builder Base image analysis uses the exported GDI+ bitmap pixel function"
    )
}

TestBuilderBaseGoldenDetectorUsesProvenADBRule() {
    source := FileRead(A_ScriptDir "\\test_builder_base_loop_visual.ahk")
    detectorStart := InStr(source, "IsBuilderBaseGoldenColor(color) {")
    detectorEnd := InStr(
        source,
        "ReleaseBuilderBaseFrame(frame) {",
        false,
        detectorStart
    )
    AssertTrue(
        detectorStart > 0 && detectorEnd > detectorStart,
        "Builder Base golden-color detector can be inspected independently"
    )
    detectorSource := SubStr(
        source,
        detectorStart,
        detectorEnd - detectorStart
    )
    for required in [
        "r > 130",
        "g > 100",
        "r > b + 15",
        "g > b - 30",
        "Proven ADB detector copied from IsGoldenADB"
    ] {
        AssertTrue(
            InStr(detectorSource, required) > 0,
            "Builder Base detector retains the proven rule: " required
        )
    }
    AssertTrue(
        InStr(source, "for dx in [-7, -3, 0, 3, 7]") > 0
            && InStr(source, "for dy in [-7, -3, 0, 3, 7]") > 0,
        "Builder Base detector samples the proven 5x5 star neighborhood"
    )
}

TestBuilderBaseStarInspectorContract() {
    inspectorPath := A_ScriptDir "\\test_builder_base_stars_visual.ahk"
    AssertTrue(
        FileExist(inspectorPath) != "",
        "isolated Builder Base star inspector exists"
    )
    source := FileRead(inspectorPath)
    for required in [
        "#Include ADBcocbotrefactor_support.ahk",
        "SetTitleMatchMode 2",
        "Clash of Clanker - Builder Base Star Inspector",
        "VerdictText",
        "PicPreview",
        "ConsoleEdit",
        "ReadOnly +VScroll +HScroll",
        "RunBuilderBaseStarInspectCycle",
        "CaptureBuilderBaseStarFrame",
        "DrawBuilderBaseStarOverlay",
        "GdipDrawRectangle",
        "GdipCreateSolidFill",
        "GdipFillEllipse",
        "adbX - 3",
        "adbY - 3",
        "6.0",
        "0xFFFFFF00",
        '"BBStar" index "X"',
        "LoadBuilderBaseStarStartupConfig",
        "CaptureBuilderBaseStarStartupPoints",
        "ResetBuilderBaseStarPoints",
        "Calibrate 3 Stars",
        "BeginBuilderBaseStarCalibration",
        "Space:: CaptureBuilderBaseStarCalibrationPoint()",
        'CoordMode "Mouse", "Screen"',
        "WinGetClientPos",
        "GetBuilderBaseStarCursorClientPoint",
        'DllCall("GetCursorPos"',
        'DllCall("ScreenToClient"',
        'NumGet(cursorPoint, 0, "Int")',
        "cursor screen(",
        "hover over star 1 in the emulator client",
        "StarInspectorCalibrationIndex",
        "Tap 3 Targets (F2)",
        "F2::TapBuilderBaseStarTargets()",
        "F7::ProbeBuilderBaseStarADBPixels()",
        "ProbeBuilderBaseStarADBPixels",
        "F7 started: capturing one fresh ADB screenshot.",
        "F7 ADB pixels: ",
        '"Star " index ": #"',
        "StarInspectorCaptureTimeoutSeconds := 10",
        "closedPid := ProcessWaitClose(",
        "!closedPid && ProcessExist(capturePid)",
        "ADB screenshot completed in ",
        "taskkill /PID ",
        "if IsObject(StarInspectorDisplay)",
        "BuildADBTapArguments",
        "RunBuilderBaseStarExactADB",
        "F2 failed: ",
        "StarInspectorLastMappingSignature",
        "if (mappingSignature != StarInspectorLastMappingSignature)",
        "r > 130",
        "g > 100",
        "r > b + 15",
        "g > b - 30"
    ] {
        AssertTrue(
            InStr(source, required) > 0,
            "Builder Base star inspector includes " required
        )
    }
    AssertTrue(
        !InStr(source, "IniWrite"),
        "isolated star inspector performs no config writes"
    )
    AssertTrue(
        !InStr(source, "0xFFFF1493") && !InStr(source, "rawX :="),
        "ADB preview excludes misleading raw-client markers"
    )
    AssertTrue(
        !InStr(source, "previewX * (StarInspectorLastPreviewRegion.width - 1)")
            && !InStr(source, "TranslateADBPointToClient")
            && !InStr(source, "mouseScreenX - clientScreenX")
            && !InStr(source, "mouseScreenY - clientScreenY"),
        "star calibration records the emulator client position before forward ADB translation"
    )
    AssertTrue(
        !InStr(source, "GdipDrawEllipse") && !InStr(source, "GdipDrawLine"),
        "star point overlays use centered dots instead of crosshair targets"
    )
    AssertTrue(
        !InStr(source, "SetTimer(RunBuilderBaseStarInspectCycle, 1000)")
            && !InStr(
                source,
                "SetTimer(() => RunBuilderBaseStarInspectCycle"
            ),
        "star inspector screenshots are manual-only and cannot monopolize ADB"
    )
    probeStart := InStr(
        source,
        "ProbeBuilderBaseStarADBPixels(isPendingRun := false) {"
    )
    inspectStart := InStr(
        source,
        "RunBuilderBaseStarInspectCycle(",
        false,
        probeStart
    )
    probeSource := SubStr(source, probeStart, inspectStart - probeStart)
    AssertTrue(
        probeStart > 0
            && InStr(probeSource, "CaptureBuilderBaseStarFrame()") > 0
            && InStr(probeSource, "LoadBuilderBaseStarBitmap(") > 0
            && InStr(probeSource, "ReadBuilderBaseStarPixel(") > 0,
        "F7 samples all three points from one fresh raw ADB frame"
    )
}

TestBuilderBaseGdipRuntimeLoadsAndSamplesPng() {
    pngPath := A_ScriptDir "\\OCRimages\\cropped images\\info_button_template.png"
    AssertTrue(FileExist(pngPath) != "", "runtime GDI+ probe PNG exists")

    startupInput := Buffer(24, 0)
    NumPut("UInt", 1, startupInput, 0)
    token := 0
    bitmap := 0
    startupStatus := DllCall(
        "gdiplus\GdiplusStartup",
        "ptr*", &token,
        "ptr", startupInput,
        "ptr", 0
    )
    AssertEqual(0, startupStatus, "GDI+ runtime startup status")
    AssertTrue(token != 0, "GDI+ runtime startup returns a token")

    try {
        loadStatus := DllCall(
            "gdiplus\GdipLoadImageFromFile",
            "wstr", pngPath,
            "ptr*", &bitmap
        )
        AssertEqual(0, loadStatus, "GDI+ runtime loads a real project PNG")
        AssertTrue(bitmap != 0, "GDI+ runtime returns a bitmap")

        color := 0
        pixelStatus := DllCall(
            "gdiplus\GdipBitmapGetPixel",
            "ptr", bitmap,
            "int", 0,
            "int", 0,
            "uint*", &color
        )
        AssertEqual(0, pixelStatus, "GDI+ runtime samples a bitmap pixel")
    } finally {
        if bitmap
            DllCall("gdiplus\GdipDisposeImage", "ptr", bitmap)
    }
}

TestBuilderBaseHarnessReportsActionableErrors() {
    source := FileRead(A_ScriptDir "\\test_builder_base_loop_visual.ahk")
    StrReplace(
        source,
        "FormatBuilderBaseHarnessError(err)",
        "",
        true,
        &formattedCatchCount
    )
    AssertEqual(
        9,
        formattedCatchCount,
        "all F-key and outer-loop catches use detailed error formatting"
    )
    AssertTrue(
        !InStr(source, '" err.Message'),
        "Builder Base catches do not discard file and line diagnostics"
    )
    AssertTrue(
        InStr(source, "Stack: ") > 0,
        "Builder Base detailed errors include the AHK stack"
    )
}

TestBuilderBaseFlowLogsCheckAndReturnHomeProgress() {
    source := FileRead(A_ScriptDir "\\builder_base_loop_logic.ahk")
    for required in ["Stage-one check ", "attempting Return Home"] {
        AssertTrue(
            InStr(source, required) > 0,
            "Builder Base flow reports monitor progress: " required
        )
    }
}

TestLiveBuilderBaseUsesProvenFlow() {
    source := FileRead(A_ScriptDir "\ADBcocbotrefactor.ahk")
    AssertTrue(
        InStr(source, '#include "builder_base_loop_logic.ahk"') > 0,
        "production includes the proven Builder Base flow"
    )

    adapterStart := InStr(source, "class LiveBuilderBasePrimitives {")
    AssertTrue(
        adapterStart > 0,
        "production defines a dedicated live Builder Base adapter"
    )
    loopStart := InStr(source, "RunBuilderBaseLoop() {", false, adapterStart)
    AssertTrue(
        loopStart > adapterStart,
        "live Builder Base adapter is inspectable before the loop wrapper"
    )
    adapterSource := SubStr(
        source,
        adapterStart,
        loopStart - adapterStart
    )
    for required in [
        'case "log"',
        'case "is_builder_running"',
        'case "tap_builder_attack"',
        'case "tap_builder_find_match"',
        'case "wait"',
        'case "prepare_builder_viewport"',
        'case "random_builder_side"',
        'case "deploy_builder_troops"',
        'case "capture_builder_frame"',
        'case "analyze_builder_three_stars"',
        'case "tap_return_home"',
        'case "detect_builder_home_from_frame"',
        "CaptureADBFrame(true)",
        "AnalyzeLiveBuilderBaseThreeStars(",
        "DetectLiveBuilderBaseHome(",
        "BBStar1X",
        "BBStar2X",
        "BBStar3X",
        "ClientToADBPoint(",
        "DetectVillageFromADBFrame("
    ] {
        AssertTrue(
            InStr(adapterSource, required) > 0,
            "live Builder Base adapter includes " required
        )
    }

    loopEnd := InStr(source, "ZoomOutBB() {", false, loopStart)
    AssertTrue(
        loopEnd > loopStart,
        "production Builder Base loop wrapper can be isolated"
    )
    loopSource := SubStr(source, loopStart, loopEnd - loopStart)
    for required in [
        "BuilderBaseFlow(LiveBuilderBasePrimitives())",
        ".RunLoop()",
        "Builder Base loop failed:",
        "IsBBRunning := false"
    ] {
        AssertTrue(
            InStr(loopSource, required) > 0,
            "production Builder Base loop includes " required
        )
    }
    for forbidden in [
        "p1TimerEnd",
        "p2StartTime",
        "IsGolden(BBStar3X, BBStar3Y)",
        "130000",
        "while !IsAtBuilderBase()"
    ] {
        AssertTrue(
            !InStr(loopSource, forbidden),
            "production Builder Base loop removes legacy path " forbidden
        )
    }
}

TestExplicitReloadActionLabels() {
    for text in ["Reload", "RELOAD", "Retry", "Try Again", "TryAgain"] {
        AssertTrue(
            IsExplicitReloadActionText(text),
            "explicit reconnect action is accepted: " text
        )
    }
    for text in ["Okay", "Connection Lost", "Another Device", ""] {
        AssertTrue(
            !IsExplicitReloadActionText(text),
            "non-action text is rejected: " text
        )
    }
}

TestVisionRuntimeUsesProjectManagedEnvironment() {
    projectPath := A_ScriptDir "\\pyproject.toml"
    versionPath := A_ScriptDir "\\.python-version"
    source := FileRead(A_ScriptDir "\\ADBcocbotrefactor.ahk")

    AssertTrue(FileExist(projectPath) != "", "vision runtime project manifest exists")
    AssertTrue(FileExist(versionPath) != "", "vision runtime pins its Python version")

    project := FileRead(projectPath)
    AssertTrue(
        InStr(project, "opencv-python") > 0,
        "vision runtime declares its OpenCV dependency"
    )
    AssertTrue(
        InStr(source, "EnsureVisionPythonEnvironment()") > 0,
        "vision runner bootstraps the project environment before use"
    )
    AssertTrue(
        InStr(source, "ResolveVisionUVExecutable()") > 0,
        "vision runner resolves uv when the current shell has not refreshed PATH"
    )
    AssertTrue(
        InStr(source, ".venv\\Scripts\\python.exe") > 0,
        "vision runner invokes the project virtual-environment interpreter"
    )
    AssertTrue(
        InStr(source, 'cmd.exe /c python "') == 0,
        "vision runner does not invoke an unpinned global Python"
    )
}

TestLabFractionOCRPreservesTheDenominatorLeadingEdge() {
    source := FileRead(A_ScriptDir "\\vision_hook.py")
    AssertTrue(
        InStr(source, "slash_x + sh_w - 7") > 0,
        "lab denominator search includes the pixels hidden by slash-template padding"
    )
}

TestVisionFailuresAreNotReportedAsResourceAvailability() {
    source := FileRead(A_ScriptDir "\\ADBcocbotrefactor.ahk")
    for readerName in [
        "ReadBuilderAvailabilityFromADBFrame(framePath)",
        "ReadLabAvailabilityFromADBFrame(framePath)"
    ] {
        readerStart := InStr(source, readerName)
        readerEnd := InStr(source, "`n}", false, readerStart)
        readerSource := SubStr(source, readerStart, readerEnd - readerStart)
        AssertTrue(
            InStr(readerSource, "valid: false") > 0,
            readerName " marks failed OCR as invalid"
        )
        AssertTrue(
            InStr(readerSource, "goblin: true") == 0,
            readerName " does not fabricate a Goblin result after OCR failure"
        )
        AssertTrue(
            InStr(readerSource, "total <= 0") > 0,
            readerName " rejects an impossible zero denominator"
        )
    }
}

TestStartDoesNotPauseARunningBot() {
    source := FileRead(A_ScriptDir "\\ADBcocbotrefactor.ahk")
    start := InStr(source, "UnifiedStart() {")
    end := InStr(source, "`nLegacyUnifiedStart()", false, start)
    unifiedStart := SubStr(source, start, end - start)
    AssertTrue(
        InStr(unifiedStart, "PauseBot()") == 0,
        "a repeated Start/F1 leaves the running bot active"
    )
}

TestDiagnosticLogsRedactUserPathsAndPruneImages() {
    source := FileRead(A_ScriptDir "\\ADBcocbotrefactor.ahk")
    AssertTrue(
        InStr(source, "SanitizeLogMessage(message)") > 0,
        "the visible log sanitizes messages before displaying them"
    )
    AssertTrue(
        InStr(source, "[A-Z]:\\Users\\") > 0,
        "the visible log redacts absolute Windows user paths"
    )
    AssertTrue(
        InStr(source, "PruneRefactorDiagnosticImages()") > 0,
        "the bot periodically prunes stale diagnostic images"
    )
    AssertTrue(
        InStr(source, "coc_refactor_*.png") > 0,
        "only bot-owned temporary images are eligible for cleanup"
    )
    AssertTrue(
        InStr(source, "retained a diagnostic capture temporarily") > 0,
        "the failure log names no diagnostic image path"
    )
}

TestMultiPointRecognitionUsesOneFreshFrame() {
    source := FileRead(A_ScriptDir "\\ADBcocbotrefactor.ahk")
    for contract in [
        "FindCenterGreenButton(&outX, &outY) {",
        "IsGoblinFace(centerX, centerY) {",
        "IsReturnHomePresentADB() {",
        "IsGolden(x, y) {",
        "AreCloudsPresent() {",
        "IsWarLogoPresentADB(x, y, framePath := "
    ] {
        AssertTrue(InStr(source, contract) > 0, "multi-point recognizer declares the shared-frame contract")
    }
    for required in [
        "framePath := CaptureADBFrame(true)",
        "GetADBFramePixelColor(framePath, clientX, clientY)",
        "GetADBFramePixelColor(framePath, centerX + pt[1], centerY + pt[2])",
        "GetADBFramePixelColor(framePath, ReturnHomeClickX + pt.x, ReturnHomeClickY + pt.y)",
        "GetADBFramePixelColor(framePath, x + dx, y + dy)",
        "AreCloudsPresentInADBFrame(framePath)",
        "GetADBFramePixelColor(framePath, x + pt.x, y + pt.y)"
    ] {
        AssertTrue(InStr(source, required) > 0, "multi-point recognition reads a shared ADB frame")
    }
}

TestLiveGlobalCycleProductionContract() {
    source := FileRead(A_ScriptDir "\ADBcocbotrefactor.ahk")
    support := FileRead(A_ScriptDir "\ADBcocbotrefactor_support.ahk")

    for required in [
        "global SessionCompletedAttacks := 0",
        'case "complete_global_cycle"',
        'case "find_reload_action_from_frame"',
        'case "tap_reload_action"',
        'case "route_village"',
        "CompleteLiveGlobalCycle(",
        "FindReloadActionFromADBFrame(",
        "SaveADBFrameRegionToPNG(",
        "RunADBTapAt(",
        "SessionCompletedAttacks += 1"
    ] {
        AssertTrue(
            InStr(source, required) > 0,
            "live common lifecycle includes " required
        )
    }
    AssertTrue(
        InStr(support, "class ADBGlobalCycleFlow") > 0
            && InStr(support, "IsExplicitReloadActionText(") > 0,
        "support owns the shared cycle controller and action classifier"
    )
    AssertTrue(
        InStr(support, 'this.Primitives.Do("wait", 1000)') > 0
            && InStr(support, 'this.Primitives.Do("wait", 10000)') > 0
            && InStr(support, "OOOO") == 0,
        "shared recovery waits before and after its quiet explicit action tap"
    )
    reloadStart := InStr(source, "FindReloadActionFromADBFrame(frame) {")
    reloadEnd := InStr(source, "TapLiveReloadAction(action) {", false, reloadStart)
    AssertTrue(
        reloadStart > 0 && reloadEnd > reloadStart,
        "live reload OCR can be isolated"
    )
    reloadSource := SubStr(source, reloadStart, reloadEnd - reloadStart)
    for required in [
        "global ReconnectCropLeftRatio, ReconnectCropRightRatio",
        "global ReconnectCropTopRatio, ReconnectCropBottomRatio",
        "viewport.width * ReconnectCropLeftRatio",
        "viewport.height * ReconnectCropTopRatio",
        "ReconnectCropRightRatio - ReconnectCropLeftRatio",
        "ReconnectCropBottomRatio - ReconnectCropTopRatio"
    ] {
        AssertTrue(
            InStr(reloadSource, required) > 0,
            "live reload OCR uses calibrated action-band geometry " required
        )
    }

    builderStart := InStr(source, "class LiveBuilderBasePrimitives {")
    builderEnd := InStr(
        source,
        "CaptureLiveBuilderBaseFrame(section) {",
        false,
        builderStart
    )
    AssertTrue(
        builderStart > 0 && builderEnd > builderStart,
        "live Builder adapter can be isolated"
    )
    builderSource := SubStr(
        source,
        builderStart,
        builderEnd - builderStart
    )
    AssertTrue(
        InStr(builderSource, 'case "complete_global_cycle"') > 0
            && InStr(builderSource, "CompleteLiveGlobalCycle(") > 0,
        "Builder adapter delegates to the live common lifecycle"
    )

    mainLoopStart := InStr(source, "StartBotLoop() {")
    mainLoopEnd := InStr(source, "LegacyStartBotLoop() {", false, mainLoopStart)
    AssertTrue(
        mainLoopStart > 0 && mainLoopEnd > mainLoopStart,
        "active Main loop can be isolated"
    )
    activeMainSource := SubStr(
        source,
        mainLoopStart,
        mainLoopEnd - mainLoopStart
    )
    AssertTrue(
        !InStr(activeMainSource, "CheckGameTimeout("),
        "active Main loop does not call legacy timeout recovery"
    )

    routeStart := InStr(source, "RouteLiveVillage(village) {")
    routeEnd := InStr(source, "StartBotLoop() {", false, routeStart)
    AssertTrue(
        routeStart > 0 && routeEnd > routeStart,
        "live reconnect router can be isolated"
    )
    routeSource := SubStr(source, routeStart, routeEnd - routeStart)
    AssertTrue(
        InStr(routeSource, "ADBMainCalibrationVersion") > 0
            && InStr(routeSource, "ADBBBCalibrationVersion") > 0
            && InStr(routeSource, "ADB_COORDINATE_VERSION") > 0,
        "cross-village reconnect routing validates target calibration"
    )

    stopStart := InStr(source, "    StopBot() {")
    stopEnd := InStr(source, "`n}", false, stopStart)
    AssertTrue(
        stopStart > 0 && stopEnd > stopStart,
        "live StopBot method can be isolated"
    )
    stopSource := SubStr(source, stopStart, stopEnd - stopStart)
    AssertTrue(
        InStr(stopSource, "IsRunning := false") > 0
            && InStr(stopSource, "IsBBRunning := false") > 0,
        "common stop clears both village run flags"
    )
}

TestReconnectReloadInspectorContract() {
    harnessPath := A_ScriptDir "\test_reconnect_reload.ahk"
    AssertTrue(FileExist(harnessPath) != "", "reconnect inspector exists")
    source := FileRead(harnessPath)
    for required in [
        "F1::RunReconnectTestCycle(true)",
        "F2::TapConfirmedReconnectAction()",
        "F1 Analyze (No Tap)",
        "F2 Tap Confirmed Result",
        "ReconnectCropLeftRatio := 0.28",
        "ReconnectCropRightRatio := 0.72",
        "ReconnectCropTopRatio := 0.51",
        "ReconnectCropBottomRatio := 0.64",
        "SaveReconnectFrameOverlay(",
        "0xFF00FF00",
        "DrawReconnectMarkerDot(",
        "FitReconnectPreviewToImage("
    ] {
        AssertTrue(
            InStr(source, required) > 0,
            "reconnect inspector includes " required
        )
    }

    analysisStart := InStr(source, "RunReconnectTestCycle(isManual := true) {")
    analysisEnd := InStr(
        source,
        "TapConfirmedReconnectAction() {",
        false,
        analysisStart
    )
    AssertTrue(
        analysisStart > 0 && analysisEnd > analysisStart,
        "reconnect analysis and explicit tap paths can be isolated"
    )
    analysisSource := SubStr(source, analysisStart, analysisEnd - analysisStart)
    AssertTrue(
        InStr(analysisSource, "ClientClickPoint(") == 0,
        "F1 reconnect analysis never taps"
    )
}

TestScaleCacheAndTranslation() {
    ConfigureADBClientMapping(10, 20, 110, 220, 200, 400)
    global ADBScaleX, ADBScaleY
    AssertNear(2.0, ADBScaleX, 0.000001, "X scale")
    AssertNear(2.0, ADBScaleY, 0.000001, "Y scale")

    center := TranslateClientPointToADB(60, 120)
    AssertEqual(100, center.x, "translated center X")
    AssertEqual(200, center.y, "translated center Y")

    outside := TranslateClientPointToADB(999, -20)
    AssertEqual(199, outside.x, "right clamp")
    AssertEqual(0, outside.y, "top clamp")
}

TestInvalidMappingFails() {
    AssertThrows(
        () => ConfigureADBClientMapping(10, 20, 10, 220, 200, 400),
        "zero-width viewport"
    )
    AssertThrows(
        () => ConfigureADBClientMapping(10, 20, 110, 20, 200, 400),
        "zero-height viewport"
    )
    AssertThrows(
        () => ConfigureADBClientMapping(10, 20, 110, 220, 0, 400),
        "zero-width Android display"
    )
    AssertThrows(
        () => ConfigureADBClientMapping(10, 20, 110, 220, 200, 0),
        "zero-height Android display"
    )
}

TestMappingIdentityInvalidation() {
    mismatches := [
        [121, 130, "ProviderA", "serialA", 200, 200, "client width"],
        [120, 131, "ProviderA", "serialA", 200, 200, "client height"],
        [120, 130, "ProviderB", "serialA", 200, 200, "provider"],
        [120, 130, "ProviderA", "serialB", 200, 200, "serial"],
        [120, 130, "ProviderA", "serialA", 201, 200, "Android width"],
        [120, 130, "ProviderA", "serialA", 200, 201, "Android height"]
    ]

    for mismatch in mismatches {
        ConfigureADBClientMapping(0, 0, 100, 100, 200, 200, 120, 130, "ProviderA", "serialA")
        AssertTrue(
            !ValidateADBClientMappingIdentity(
                mismatch[1],
                mismatch[2],
                mismatch[3],
                mismatch[4],
                mismatch[5],
                mismatch[6]
            ),
            mismatch[7] " mismatch invalidates mapping"
        )
        AssertThrows(
            () => TranslateClientPointToADB(50, 50),
            mismatch[7] " mismatch blocks translated input"
        )
    }

    ConfigureADBClientMapping(0, 0, 100, 100, 200, 200, 120, 130, "ProviderA", "serialA")
    AssertTrue(
        ValidateADBClientMappingIdentity(120, 130, "ProviderA", "serialA", 200, 200),
        "matching mapping identity stays valid"
    )
}

TestMinimizedWindowUsesCachedClientDimensions() {
    minimized := ResolveADBValidationClientSize(
        true,
        0,
        0,
        1767,
        1028
    )
    AssertEqual(1767, minimized.width, "minimized cached client width")
    AssertEqual(1028, minimized.height, "minimized cached client height")
    AssertTrue(minimized.usedCached, "minimized mapping reports cached dimensions")

    restored := ResolveADBValidationClientSize(
        false,
        1600,
        900,
        1767,
        1028
    )
    AssertEqual(1600, restored.width, "restored runtime client width")
    AssertEqual(900, restored.height, "restored runtime client height")
    AssertTrue(!restored.usedCached, "restored mapping checks actual dimensions")

    source := FileRead(A_ScriptDir "\ADBcocbotrefactor.ahk")
    AssertTrue(
        InStr(source, "WinGetMinMax(hwnd) == -1") > 0,
        "runtime explicitly recognizes a minimized emulator window"
    )
    AssertTrue(
        InStr(source, "ResolveADBValidationClientSize(") > 0,
        "runtime resolves effective dimensions through the tested helper"
    )
}

TestClientCoordinatePersistenceOnly() {
    sourcePath := A_ScriptDir "\ADBcocbotrefactor.ahk"
    AssertTrue(FileExist(sourcePath), "refactor source exists")
    source := FileRead(sourcePath)

    AssertTrue(!InStr(source, "ADBCoordinates"), "legacy ADBCoordinates section is absent")
    AssertTrue(!InStr(source, "adbCollectorStr"), "legacy Android collector copy is absent")
    AssertTrue(
        InStr(source, 'IniRead("config.ini", "Coordinates", "CollectorCoords"') > 0,
        "collector points load from the client Coordinates section"
    )
    AssertTrue(
        InStr(source, 'IniWrite(collectorStr, "config.ini", "Coordinates", "CollectorCoords")') > 0,
        "collector points save only to the client Coordinates section"
    )
    AssertTrue(
        InStr(source, "ConfigureADBClientMapping(") > 0,
        "calibration caches the client-to-ADB mapping"
    )
    AssertTrue(
        InStr(source, "ValidateADBClientMappingIdentity(") > 0,
        "runtime validates mapping identity before reuse"
    )
}

TestObservationCoordinateConversions() {
    ConfigureADBClientMapping(10, 20, 110, 220, 200, 400)

    clientPoint := TranslateADBPointToClient(100, 200)
    AssertEqual(60, clientPoint.x, "ADB OCR point converts back to client X")
    AssertEqual(120, clientPoint.y, "ADB OCR point converts back to client Y")

    adbRect := TranslateClientRectToADB(20, 40, 11, 21)
    AssertEqual(20, adbRect.x, "client crop translates top-left X")
    AssertEqual(40, adbRect.y, "client crop translates top-left Y")
    AssertEqual(21, adbRect.width, "client crop translates inclusive width")
    AssertEqual(41, adbRect.height, "client crop translates inclusive height")
}

TestADBOnlyObservationSource() {
    source := FileRead(A_ScriptDir "\ADBcocbotrefactor.ahk")
    for forbidden in [
        "PixelGetColor",
        'CoordMode "Pixel"',
        "BitBlt",
        "OCR.FromRect",
        "IsAttackBtnPresentClient",
        "IsWarLogoPresentClient"
    ] {
        AssertTrue(!InStr(source, forbidden), "ADB-only observation excludes " forbidden)
    }
    AssertTrue(
        InStr(source, "adbPoint := ClientToADBPoint(clientX, clientY)") > 0,
        "pixel sampling translates its client point at the read boundary"
    )
    AssertTrue(
        InStr(source, "adbRect := ClientRectToADBRect(x, y, w, h)") > 0,
        "frame cropping translates its client rectangle at the read boundary"
    )
}

TestCalibrationOwnsForegroundActivation() {
    source := FileRead(A_ScriptDir "\ADBcocbotrefactor.ahk")
    StrReplace(source, "WinActivate(TargetWindowTitle)", "", true, &activationCount)
    AssertEqual(2, activationCount, "foreground activation count")

    mainStart := InStr(source, "StartCalibration() {")
    mainEnd := InStr(source, "CancelCalibration() {", true, mainStart)
    bbStart := InStr(source, "StartBBCalibration() {")
    bbEnd := InStr(source, "CancelBBCalibration() {", true, bbStart)
    AssertTrue(mainStart > 0 && mainEnd > mainStart, "main calibration function is identifiable")
    AssertTrue(bbStart > 0 && bbEnd > bbStart, "Builder Base calibration function is identifiable")
    AssertTrue(
        InStr(SubStr(source, mainStart, mainEnd - mainStart), "WinActivate(TargetWindowTitle)") > 0,
        "main calibration owns one foreground activation"
    )
    AssertTrue(
        InStr(SubStr(source, bbStart, bbEnd - bbStart), "WinActivate(TargetWindowTitle)") > 0,
        "Builder Base calibration owns one foreground activation"
    )

    for forbidden in [
        "ResizeGameWindow",
        "WinMove",
        "EnsureWindowActive",
        "ActivateGameWindow",
        "--adb-self-test"
    ] {
        AssertTrue(!InStr(source, forbidden), "foreground boundary excludes " forbidden)
    }
}

TestCoordinateOffsetBounds() {
    ConfigureADBClientMapping(10, 20, 110, 220, 200, 400)
    recorder := TestRecorder()
    randomValues := SequenceRandom([-7, 8, 0])
    interaction := CreateADBClientInteraction(
        "serial",
        ObjBindMethod(recorder, "RecordCommand"),
        ObjBindMethod(recorder, "RecordDelay"),
        ObjBindMethod(randomValues, "Next")
    )

    point := interaction.Tap(60, 120, 0)
    AssertEqual(93, point.x, "minimum X offset")
    AssertEqual(208, point.y, "maximum Y offset")
    AssertTrue(InStr(recorder.Commands[1], "shell input tap 93 208") > 0, "tap command uses randomized point")
}

TestTimingBands() {
    shortTiming := GetADBActionTiming(75)
    AssertEqual(70, shortTiming.PreDelay, "75 ms pre-delay")
    AssertEqual(10, shortTiming.JitterMax, "75 ms jitter maximum")

    longTiming := GetADBActionTiming(200)
    AssertEqual(185, longTiming.PreDelay, "200 ms pre-delay")
    AssertEqual(30, longTiming.JitterMax, "200 ms jitter maximum")

    clampedTiming := GetADBActionTiming(3)
    AssertEqual(0, clampedTiming.PreDelay, "short pre-delay clamp")
    AssertEqual(10, clampedTiming.JitterMax, "short jitter maximum")
}

TestInternalTimingJitter() {
    ConfigureADBClientMapping(0, 0, 100, 100, 200, 200)
    recorder := TestRecorder()
    randomValues := SequenceRandom([0, 0, 30])
    interaction := CreateADBClientInteraction(
        "serial",
        ObjBindMethod(recorder, "RecordCommand"),
        ObjBindMethod(recorder, "RecordDelay"),
        ObjBindMethod(randomValues, "Next")
    )

    interaction.Tap(50, 50, 200)
    AssertEqual(30, recorder.Delays[1], "long-band internal jitter")
}

TestAllActionsUseBoundary() {
    ConfigureADBClientMapping(0, 0, 100, 100, 200, 200)
    recorder := TestRecorder()
    randomValues := SequenceRandom([
        0, 0, 0, 0, 0,
        0, 0, 0,
        0, 0, 0,
        0
    ])
    interaction := CreateADBClientInteraction(
        "serial",
        ObjBindMethod(recorder, "RecordCommand"),
        ObjBindMethod(recorder, "RecordDelay"),
        ObjBindMethod(randomValues, "Next")
    )

    interaction.Swipe(10, 20, 30, 40, 250, 75)
    interaction.Pinch(50, 50, 200, 45, 200, 75)
    interaction.Place(60, 70, 75)
    interaction.KeyEvent(4, 75)

    AssertEqual(4, recorder.Commands.Length, "command count")
    AssertTrue(InStr(recorder.Commands[1], "shell input swipe") > 0, "swipe command")
    AssertTrue(InStr(recorder.Commands[2], "am instrument") > 0, "pinch command")
    AssertTrue(InStr(recorder.Commands[3], "shell input tap") > 0, "placement command")
    AssertTrue(InStr(recorder.Commands[4], "shell input keyevent 4") > 0, "key command")
    AssertEqual(4, recorder.Delays.Length, "all actions use internal timing jitter")
}

TestSpellOffsetAppliesAfterClientTranslation() {
    ConfigureADBClientMapping(0, 0, 199, 199, 400, 400)
    recorder := TestRecorder()
    randomValues := SequenceRandom([0, 0, 0])
    interaction := CreateADBClientInteraction(
        "serial",
        ObjBindMethod(recorder, "RecordCommand"),
        ObjBindMethod(recorder, "RecordDelay"),
        ObjBindMethod(randomValues, "Next")
    )
    clientX := 50
    clientY := 50

    interaction.PlaceShiftedTowardCenter(clientX, clientY, 35, 75)

    AssertTrue(
        InStr(recorder.Commands[1], "shell input tap 136 136") > 0,
        "35-pixel-per-axis spell shift is applied after ADB translation"
    )
    AssertEqual(50, clientX, "stored client x remains unchanged")
    AssertEqual(50, clientY, "stored client y remains unchanged")
}

TestClearTapOwnsThreeRandomizedTaps() {
    ConfigureADBClientMapping(0, 0, 199, 199, 400, 400)
    recorder := TestRecorder()
    randomValues := SequenceRandom([0, 0, 0, 0, 0, 0, 0, 0, 0])
    interaction := CreateADBClientInteraction(
        "serial",
        ObjBindMethod(recorder, "RecordCommand"),
        ObjBindMethod(recorder, "RecordDelay"),
        ObjBindMethod(randomValues, "Next")
    )

    interaction.ClearTap(50, 50, 75)

    AssertEqual(3, recorder.Commands.Length, "clear tap command count")
    AssertEqual(3, recorder.Delays.Length, "clear tap timing count")
    for command in recorder.Commands {
        AssertTrue(
            InStr(command, "shell input tap 101 101") > 0,
            "each clear tap uses the client-coordinate input boundary"
        )
    }
}

TestLiveClearTapUsesV2CallbackReference() {
    source := FileRead(A_ScriptDir "\ADBcocbotrefactor.ahk")
    AssertTrue(
        !InStr(source, 'Func("WaitForADBActionPreDelay")'),
        "live clear tap must not construct a callback with Func(), which throws Invalid base in AHK v2"
    )
    AssertTrue(
        RegExMatch(
            source,
            "s)interaction\.ClearTap\(.*?WaitForADBActionPreDelay\s*\)"
        ) > 0,
        "live clear tap passes the pre-delay function object directly"
    )
    AssertTrue(
        InStr(
            source,
            'IniRead("config.ini", "VisualTests", "ClearTapX"'
        ) > 0,
        "live clear tap loads the inspector-proven client X coordinate"
    )
    AssertTrue(
        InStr(
            source,
            'IniRead("config.ini", "VisualTests", "ClearTapY"'
        ) > 0,
        "live clear tap loads the inspector-proven client Y coordinate"
    )
    AssertTrue(
        InStr(
            source,
            "RunADBClearTapAt(ClearTapX, ClearTapY, 200)"
        ) > 0,
        "live clear tap uses the saved client point"
    )
}

TestClearTapVisualInspectorContract() {
    inspectorPath := A_ScriptDir "\test_clear_tap_visual.ahk"
    AssertTrue(FileExist(inspectorPath), "clear-tap visual inspector exists")
    source := FileRead(inspectorPath)
    for required in [
        "BitBlt",
        "TranslateClientPointToADB",
        "interaction.ClearTap",
        "SetTimer",
        "ReloadInspectorConfig",
        "Calibrate (Space)",
        "Save Config",
        "cGreen",
        "cRed",
        "Consolas",
        "SendMessage(0x0115"
    ] {
        AssertTrue(
            InStr(source, required) > 0,
            "clear-tap visual inspector includes " required
        )
    }
}

TestLootVisualInspectorContract() {
    inspectorPath := A_ScriptDir "\test_loot_ocr.ahk"
    AssertTrue(FileExist(inspectorPath), "loot visual inspector exists")
    source := FileRead(inspectorPath)
    for required in [
        "CaptureLootADBFrame",
        "OCR.FromFile",
        "TranslateClientRectToADB",
        "ReloadConfig",
        "SaveADBRegionWithMarkers",
        "EvaluateLootAttackDecision",
        "Calibrate (Space)",
        "Save Config",
        "A_Temp",
        "cGreen",
        "cRed",
        "Consolas",
        "SendMessage(0x0115"
    ] {
        AssertTrue(
            InStr(source, required) > 0,
            "loot visual inspector includes " required
        )
    }
    AssertTrue(
        !InStr(source, "OCR.FromRect"),
        "Phase 2 loot inspector does not OCR the Windows desktop"
    )
    AssertTrue(
        !InStr(source, "WinActivate("),
        "loot visual inspector never foregrounds the emulator"
    )
}

TestLootConsensusRejectsOversizedOutlier() {
    AssertTrue(
        FileExist(A_ScriptDir "\loot_ocr_logic.ahk"),
        "loot OCR logic library exists"
    )
    result := SelectLootConsensus([667926, 667926, 6679261, 667926])
    AssertTrue(result.valid, "three matching readings form a consensus")
    AssertEqual(668000, result.value, "rounded mode beats a larger outlier")
}

TestLootModeAcceptsOneValidInteger() {
    result := SelectLootConsensus([702564])
    AssertTrue(result.valid, "one integer plus OCR errors is valid")
    AssertEqual(703000, result.value, "the only integer is rounded to 1,000")
    result := SelectLootConsensus([])
    AssertTrue(!result.valid, "no integer readings is invalid")
}

TestLootModeRoundsCloseValidReadings() {
    result := SelectLootConsensus([762659, 762555])
    AssertTrue(result.valid, "close valid integers produce a rounded mode")
    AssertEqual(763000, result.value, "close readings round to 763000")
    result := SelectLootConsensus([100100, 200100, 300100])
    AssertTrue(result.valid, "valid integers take priority over OCR errors")
    AssertEqual(300000, result.value, "a rounded tie uses the highest bin")
}

TestBothInvalidLootAttacks() {
    invalid := {valid: false, value: 0}
    decision := EvaluateLootAttackDecision(invalid, invalid, 500000, 500000)
    AssertTrue(decision.attack, "both invalid OCR results attack the base")
}

TestLootThresholdDecisionRemainsAuthoritative() {
    belowGold := {valid: true, value: 499999}
    belowElixir := {valid: true, value: 400000}
    decision := EvaluateLootAttackDecision(
        belowGold, belowElixir, 500000, 500000
    )
    AssertTrue(!decision.attack, "valid values below limits skip the base")
    thresholdGold := {valid: true, value: 500000}
    decision := EvaluateLootAttackDecision(
        thresholdGold, belowElixir, 500000, 500000
    )
    AssertTrue(decision.attack, "either resource meeting its limit attacks")
}

TestLiveLootOCRUsesProvenADBContract() {
    botSource := FileRead(A_ScriptDir "\ADBcocbotrefactor.ahk")
    supportSource := FileRead(
        A_ScriptDir "\ADBcocbotrefactor_support.ahk"
    )
    for required in [
        '#include "loot_ocr_logic.ahk"',
        "GoldIconX + LootCropOffsetX",
        "GoldIconY + LootCropOffsetY",
        "ElixirIconX + LootCropOffsetX",
        "ElixirIconY + LootCropOffsetY",
        "SelectLootConsensus(readings)",
        "IniWrite(LootCropOffsetX",
        "global LootCropOffsetX := 10",
        "global LootCropOffsetY := -27",
        "global LootCropW := 161",
        "global LootCropH := 59",
        "for scaleValue in [1.5]",
        "monochrome: 160"
    ] {
        AssertTrue(
            InStr(botSource, required) > 0,
            "live bot loot OCR includes " required
        )
    }
    AssertTrue(
        InStr(supportSource, "EvaluateLootAttackDecision(") > 0,
        "base search uses the shared loot decision"
    )
    AssertTrue(
        InStr(
            supportSource,
            "decision := this._EvaluateLootAttackDecision("
        ) > 0,
        "support owns the loot decision needed by its base-search section"
    )
    AssertTrue(
        InStr(supportSource, "_EvaluateLootAttackDecision(") > 0,
        "support defines its self-contained loot decision helper"
    )
    AssertTrue(
        InStr(
            supportSource,
            "both Gold and Elixir OCR results are invalid"
        ) > 0,
        "both-invalid attack fallback is logged"
    )
}

TestLootOCRComparisonHarnessContract() {
    harnessPath := A_ScriptDir "\test_loot_ocr_comparison.ahk"
    AssertTrue(FileExist(harnessPath) != "", "loot OCR comparison harness exists")
    source := FileRead(harnessPath)
    for required in [
        "F1::StartLootComparison()",
        "F2::StopLootComparison()",
        "CaptureComparisonADBFrame()",
        "TapComparisonNextMatch()",
        "Normal:",
        "Grey:",
        "Contrast:",
        "monochrome: 160",
        "SelectLootConsensus(",
        "Override size:\s*(\d+)x(\d+)",
        "Physical size:\s*(\d+)x(\d+)",
        "gdiplus\GdipCreateBitmapFromFile",
        "cFFA500",
        "finishing Normal, Grey, and Contrast",
        "Waiting 5 seconds before Next Match.",
        "Sleep(5000)"
    ] {
        AssertTrue(
            InStr(source, required) > 0,
            "loot OCR comparison harness includes " required
        )
    }
}

TestBuilderLabOCRComparisonHarnessContract() {
    harnessPath := A_ScriptDir "\test_builder_lab_ocr_comparison.ahk"
    AssertTrue(FileExist(harnessPath) != "", "builder/lab OCR comparison harness exists")
    source := FileRead(harnessPath)
    for required in [
        "F1::CaptureBuilderLabComparison()",
        "CaptureBuilderLabADBFrame()",
        "OCR.FromFile(",
        "Normal:",
        "Grey:",
        "Contrast:",
        "monochrome: 160",
        "ParseComparisonFraction(",
        "SelectComparisonFractionConsensus(",
        "global BLViewportTop, BLViewportBottom",
        "SaveBLPreviewVariant(",
        "Grey preview",
        "Contrast preview",
        "BLBuilderGreyCropPath",
        "BLBuilderContrastCropPath",
        "RunWaitPythonScript"
    ] {
        if (required = "RunWaitPythonScript") {
            AssertTrue(
                InStr(source, required) == 0,
                "builder/lab comparison harness does not call the Python vision hook"
            )
        } else {
            AssertTrue(
                InStr(source, required) > 0,
                "builder/lab comparison harness includes " required
            )
        }
    }
}

TestBuilderLabComparisonCropsTrimOnlyTheirLeftEdges() {
    source := FileRead(A_ScriptDir "\test_builder_lab_ocr_comparison.ahk")
    AssertEqual(
        1,
        StrSplit(source, "Round(fullWidth * 0.55)").Length - 1,
        "Builder crop retains 55% of its original width after another 10% left trim"
    )
    AssertEqual(
        1,
        StrSplit(source, "offsetX := fullOffsetX - Round(fullWidth * 0.45)").Length - 1,
        "Builder crop moves only its left edge inward by 45% total"
    )
    AssertEqual(
        1,
        StrSplit(source, "width := Max(75, Round(fullWidth * 0.50))").Length - 1,
        "Laboratory crop retains 50% of its original width to exclude the sword"
    )
    AssertEqual(
        1,
        StrSplit(source, "offsetX := fullOffsetX - Round(fullWidth * 0.50)").Length - 1,
        "Laboratory crop moves only its left edge inward by 50% total"
    )
}

TestThresholdVisualInspectorUsesFreshADBContract() {
    inspectorPath := A_ScriptDir "\test_storage_thresholds.ahk"
    AssertTrue(
        FileExist(inspectorPath),
        "resource-threshold visual inspector exists"
    )
    source := FileRead(inspectorPath)
    for required in [
        "CaptureThresholdADBFrame",
        "TranslateClientPointToADB",
        "GetThresholdADBFrameNeighborhood",
        "SaveADBThresholdPreview",
        "ReloadThresholdConfig",
        "Calibrate (Space)",
        "Save Config",
        "Dark Elixir rule: R < 70, G < 60, B < 80",
        "A_Temp",
        "cGreen",
        "cRed",
        "Consolas",
        "SendMessage(0x0115"
    ] {
        AssertTrue(
            InStr(source, required) > 0,
            "threshold inspector includes " required
        )
    }
    for forbidden in ["PixelGetColor", "BitBlt", "ADBCoordinates"] {
        AssertTrue(
            !InStr(source, forbidden),
            "threshold inspector excludes stale path " forbidden
        )
    }
    lootLogicInclude := InStr(
        source,
        "#Include loot_ocr_logic.ahk"
    )
    supportInclude := InStr(
        source,
        "#Include ADBcocbotrefactor_support.ahk"
    )
    AssertTrue(
        lootLogicInclude > 0 && lootLogicInclude < supportInclude,
        "threshold inspector loads loot logic before shared flow support"
    )
    AssertTrue(
        InStr(
            source,
            'CalibratedClientWidth . "|" .'
        ) > 0,
        "threshold mapping identity uses explicit multiline concatenation"
    )
    AssertTrue(
        !InStr(
            source,
            'CalibratedClientHeight "|"`r`n        CalibratedProvider'
        ),
        "threshold mapping identity cannot parse a string as a function call"
    )
}

TestThresholdNeighborhoodIgnoresLightPixels() {
    logicPath := A_ScriptDir "\resource_threshold_logic.ahk"
    AssertTrue(
        FileExist(logicPath),
        "resource threshold neighborhood logic exists"
    )
    if !FileExist(logicPath)
        return

    source := FileRead(logicPath)
    AssertTrue(
        InStr(source, "IsThresholdLightColor(") > 0,
        "threshold logic defines light-pixel exclusion"
    )
    AssertTrue(
        InStr(source, "AnalyzeThresholdNeighborhood(") > 0,
        "threshold logic defines neighborhood analysis"
    )

    sample := AnalyzeThresholdNeighborhood([
        0xFFFFFF,
        0xD8D8D8,
        0x302040
    ])
    AssertTrue(sample.valid, "a non-light bar pixel remains usable")
    AssertEqual(2, sample.ignored, "white and light-gray pixels are ignored")
    AssertEqual(1, sample.evaluated, "only the bar pixel is evaluated")
    AssertEqual(0x302040, sample.color, "ignored pixels do not affect color")
    AssertTrue(
        !IsThresholdLightColor(0xD6C264),
        "saturated gold fill is not mistaken for white text"
    )
    AssertTrue(
        IsThresholdLightColor(0x707070),
        "dimmed neutral-white text is still ignored"
    )
    AssertTrue(
        !IsThresholdLightColor(0x5E552C),
        "dimmed saturated Gold remains eligible"
    )

    allLight := AnalyzeThresholdNeighborhood([0xFFFFFF, 0xE0E0E0])
    AssertTrue(!allLight.valid, "an all-light neighborhood has no reading")
}

TestLiveThresholdReaderUsesProvenNeighborhoodContract() {
    botPath := A_ScriptDir "\ADBcocbotrefactor.ahk"
    source := FileRead(botPath)

    resourceInclude := InStr(
        source,
        '#include "resource_threshold_logic.ahk"'
    )
    supportInclude := InStr(
        source,
        '#include "ADBcocbotrefactor_support.ahk"'
    )
    AssertTrue(
        resourceInclude > 0 && resourceInclude < supportInclude,
        "live bot loads resource threshold logic before flow support"
    )
    for required in [
        "GetADBFrameThresholdNeighborhood(",
        "AnalyzeThresholdNeighborhood(",
        "clientRadiusX := 24",
        "clientRadiusY := 0",
        "clientStep := 1",
        "darkG < 60",
        "ignored-light="
    ] {
        AssertTrue(
            InStr(source, required) > 0,
            "live threshold reader includes " required
        )
    }
    AssertTrue(
        !InStr(
            source,
            "GetADBFramePixelColor(framePath, GoldBarThreshX"
        ),
        "live Gold threshold no longer uses one fragile pixel"
    )
}

TestBuilderUpgradeInfoFlowHarnessContract() {
    logicPath := A_ScriptDir "\builder_info_ocr_logic.ahk"
    harnessPath := A_ScriptDir "\test_storage_thresholds.ahk"
    AssertTrue(FileExist(logicPath), "builder Info OCR logic exists")
    source := FileRead(harnessPath)
    for required in [
        "#Include builder_info_ocr_logic.ahk",
        "RunBuilderUpgradeInfoFlow(",
        "ReadBuilderAvailabilityForInfoFlow(",
        "FindFirstSuggestedUpgradeForInfoFlow(",
        "FindBuilderInfoForInfoFlow(",
        "TapBuilderInfoFlowPoint(",
        "RunInfoFlowVisionHook(",
        "BuilderCountCropPath",
        "'builders ",
        "'info ",
        "Info template detector output:",
        "Info template match: confidence",
        "viewportWidth * 0.70",
        "viewportHeight * 0.30",
        "READY BEFORE CONFIRMATION",
        "F2:: RunBuilderUpgradeInfoFlow()",
        "CreateADBClientInteraction("
    ] {
        AssertTrue(
            InStr(source, required) > 0,
            "builder Info flow harness includes " required
        )
    }
    AssertTrue(
        FileExist(
            A_ScriptDir
                "\OCRimages\cropped images\info_button_template.png"
        ),
        "builder Info icon template exists"
    )
    for forbidden in [
        "UpgradeConfirmX",
        "UpgradeConfirmY",
        "tap_upgrade_confirm"
    ] {
        AssertTrue(
            !InStr(source, forbidden),
            "builder Info flow harness excludes confirmation input "
                forbidden
        )
    }

    selected := SelectBuilderInfoOCRWord([
        {Text: "Upgrade", x: 25, y: 10, w: 40, h: 18},
        {Text: "Info", x: 80, y: 20, w: 32, h: 16},
        {Text: "lnfo", x: 12, y: 22, w: 30, h: 14}
    ])
    AssertTrue(IsObject(selected), "Info selector returns a match")
    AssertEqual("lnfo", selected.text, "leftmost accepted Info variant wins")
    AssertEqual(27, selected.centerX, "Info tap uses word center X")
    AssertEqual(29, selected.centerY, "Info tap uses word center Y")
    AssertTrue(
        !IsObject(SelectBuilderInfoOCRWord([
            {Text: "Upgrade", x: 1, y: 1, w: 10, h: 10}
        ])),
        "unrelated OCR words do not produce an Info match"
    )

    suggestion := SelectFirstSuggestedUpgradeOCRWord([
        {
            Text: "Suggested upgrades:",
            Words: [
                {Text: "Suggested", x: 10, y: 100, w: 80, h: 20},
                {Text: "upgrades:", x: 95, y: 100, w: 70, h: 20}
            ]
        },
        {
            Text: "e X-Bow",
            x: 30,
            y: 140,
            w: 80,
            h: 20,
            Words: [
                {Text: "e", x: 30, y: 140, w: 8, h: 20},
                {Text: "X-Bow", x: 48, y: 140, w: 62, h: 20}
            ]
        },
        {
            Text: "e Grand Warden",
            x: 30,
            y: 180,
            w: 120,
            h: 20,
            Words: [
                {Text: "e", x: 30, y: 180, w: 8, h: 20},
                {Text: "Grand", x: 48, y: 180, w: 55, h: 20}
            ]
        }
    ])
    AssertTrue(
        IsObject(suggestion),
        "suggestion selector returns the first upgrade word"
    )
    AssertEqual(
        "X-Bow",
        suggestion.text,
        "suggestion selector skips the bullet and selects X-Bow itself"
    )
    AssertEqual(79, suggestion.centerX, "suggestion tap centers on X-Bow X")
    AssertEqual(150, suggestion.centerY, "suggestion tap centers on X-Bow Y")

    normalizedSuggestion := NormalizeBuilderOCRMatch(suggestion, 2.0)
    AssertEqual(
        24,
        normalizedSuggestion.x,
        "2x suggestion OCR X is normalized before translation"
    )
    AssertEqual(
        70,
        normalizedSuggestion.y,
        "2x suggestion OCR Y is normalized before translation"
    )
    AssertEqual(
        39.5,
        normalizedSuggestion.centerX,
        "2x suggestion OCR center X is normalized"
    )
    AssertEqual(
        75,
        normalizedSuggestion.centerY,
        "2x suggestion OCR center Y is normalized"
    )
    AssertEqual(
        65,
        normalizedSuggestion.tapX,
        "suggestion keeps the original normalized line X plus 50 rule"
    )
    AssertEqual(
        75,
        normalizedSuggestion.tapY,
        "suggestion keeps the original normalized line center Y rule"
    )
}

TestTimerExitVisualHarnessContract() {
    harnessPath := A_ScriptDir "\test_timer_exit_visual.ahk"
    AssertTrue(
        FileExist(harnessPath),
        "timer exit visual harness exists"
    )
    source := FileRead(harnessPath)
    lootIncludeIndex := InStr(source, "#Include loot_ocr_logic.ahk")
    supportIncludeIndex := InStr(
        source,
        "#Include ADBcocbotrefactor_support.ahk"
    )
    AssertTrue(
        lootIncludeIndex > 0
            && supportIncludeIndex > lootIncludeIndex,
        "timer exit harness loads loot logic before shared flow support"
    )
    for required in [
        "#Include ADBcocbotrefactor_support.ahk",
        "Preview Okay Location (F1)",
        "Run Real ADB Exit (F2)",
        "F1:: RunTimerExitPointerPreview()",
        "F2:: RunTimerExitADBTest()",
        "Space:: CaptureTimerExitOkayPoint()",
        "KEYCODE_ESCAPE",
        "TimerExitOkayX",
        "TimerExitOkayY",
        '"VisualTests"',
        '"ADBViewport"',
        "TranslateClientPointToADB(",
        "CreateADBClientInteraction(",
        "randomized ADB actually sent",
        "Windows pointer remained stationary",
        "PicPreview",
        "VerdictText",
        "ConsoleEdit",
        "+VScroll",
        "F1 does not click",
        "F2 exits Clash of Clans"
    ] {
        AssertTrue(
            InStr(source, required) > 0,
            "timer exit visual harness includes " required
        )
    }
    AssertTrue(
        !InStr(source, "#Include ADBcocbotrefactor.ahk"),
        "timer exit harness does not start the production bot"
    )
}

TestTimerExitRunsOnlyAfterTriggeredEndOfCycleCheck() {
    primitives := TimerCycleRecorder(true)
    flow := ADBGlobalCycleFlow(primitives)

    AssertEqual(
        "stopped",
        flow.Complete("main"),
        "triggered shared cycle stops"
    )
    timerIndex := FindOperationIndex(
        primitives.Operations,
        "timer_triggered"
    )
    exitIndex := FindOperationIndex(
        primitives.Operations,
        "exit_game_after_timer"
    )
    stopIndex := FindOperationIndex(primitives.Operations, "stop_bot")
    AssertTrue(timerIndex > 0, "timer is checked at cycle completion")
    AssertTrue(
        exitIndex > timerIndex,
        "game exit happens only after the timer check is triggered"
    )
    AssertTrue(
        stopIndex > exitIndex,
        "bot stops only after the game exit operation"
    )
}

TestTimerExitDoesNothingBeforeTimerIsTriggered() {
    primitives := TimerCycleRecorder(false)
    flow := ADBGlobalCycleFlow(primitives)

    AssertEqual(
        "continue",
        flow.Complete("builder"),
        "untriggered shared cycle continues"
    )
    AssertEqual(
        0,
        FindOperationIndex(
            primitives.Operations,
            "exit_game_after_timer"
        ),
        "untriggered timer does not exit the game"
    )
    AssertEqual(
        0,
        FindOperationIndex(primitives.Operations, "stop_bot"),
        "untriggered timer does not stop the bot"
    )
}

TestTimerExitOkayPointScalesWithViewport() {
    small := ResolveTimerExitOkayClientPoint(0, 0, 1001, 1001)
    AssertEqual(600, small.x, "small viewport Okay X")
    AssertEqual(605, small.y, "small viewport Okay Y")

    wide := ResolveTimerExitOkayClientPoint(10, 20, 2010, 1020)
    AssertEqual(1209, wide.x, "wide viewport Okay X")
    AssertEqual(624, wide.y, "wide viewport Okay Y")
    AssertThrows(
        () => ResolveTimerExitOkayClientPoint(10, 20, 10, 1020),
        "timer exit rejects an invalid viewport"
    )
}

TestLiveTimerExitProductionContract() {
    support := FileRead(A_ScriptDir "\ADBcocbotrefactor_support.ahk")
    bot := FileRead(A_ScriptDir "\ADBcocbotrefactor.ahk")
    for required in [
        'this.Primitives.Do("exit_game_after_timer")',
        "ResolveTimerExitOkayClientPoint("
    ] {
        AssertTrue(
            InStr(support, required) > 0,
            "timer exit support includes " required
        )
    }
    for required in [
        'case "exit_game_after_timer"',
        "ExitGameAfterTimer()",
        'SendKey("ESCAPE")',
        "ResolveTimerExitOkayClientPoint(",
        "ADBViewportLeft",
        "ADBViewportTop",
        "ADBViewportRight",
        "ADBViewportBottom",
        "RunADBTapAt("
    ] {
        AssertTrue(
            InStr(bot, required) > 0,
            "live timer exit includes " required
        )
    }
}

TestLiveBuilderFlowRequiresInfoBeforeConfirmation() {
    primitives := BuilderFlowRecorder(true)
    flow := ADBMainFlowSections(primitives)
    result := flow.RunBuilderUpgrade(
        {gold: true, elixir: true, darkElixir: true},
        false
    )

    infoFindIndex := FindOperationIndex(
        primitives.Operations,
        "find_builder_info_from_frame"
    )
    infoTapIndex := FindOperationIndex(
        primitives.Operations,
        "tap_builder_info"
    )
    confirmIndex := FindOperationIndex(
        primitives.Operations,
        "tap_upgrade_confirm"
    )
    AssertTrue(result, "builder upgrade succeeds after Info is tapped")
    AssertTrue(infoFindIndex > 0, "live builder flow searches for Info")
    AssertTrue(
        infoTapIndex > infoFindIndex,
        "live builder flow taps the matched Info icon"
    )
    AssertTrue(
        confirmIndex > infoTapIndex,
        "confirmation occurs only after the Info tap"
    )
}

TestLiveBuilderFlowSkipsConfirmationWithoutInfo() {
    primitives := BuilderFlowRecorder(false)
    flow := ADBMainFlowSections(primitives)
    result := flow.RunBuilderUpgrade(
        {gold: true, elixir: true, darkElixir: true},
        false
    )

    AssertTrue(!result, "missing Info aborts the builder upgrade")
    AssertEqual(
        0,
        FindOperationIndex(primitives.Operations, "tap_upgrade_confirm"),
        "missing Info cannot reach confirmation"
    )
    AssertTrue(
        FindOperationIndex(primitives.Operations, "clear_tap") > 0,
        "missing Info clears the selected building"
    )
}

TestSplitSuggestedUpgradesHeaderSelectsFollowingChoice() {
    selected := SelectFirstSuggestedUpgradeOCRWord([
        {
            Text: "Suggested",
            x: 20,
            y: 100,
            w: 90,
            h: 20,
            Words: [
                {Text: "Suggested", x: 20, y: 100, w: 90, h: 20}
            ]
        },
        {
            Text: "Upgrades:",
            x: 20,
            y: 122,
            w: 85,
            h: 20,
            Words: [
                {Text: "Upgrades:", x: 20, y: 122, w: 85, h: 20}
            ]
        },
        {
            Text: "e Dragon",
            x: 30,
            y: 160,
            w: 100,
            h: 22,
            Words: [
                {Text: "e", x: 30, y: 160, w: 8, h: 22},
                {Text: "Dragon", x: 48, y: 160, w: 70, h: 22}
            ]
        }
    ])
    AssertTrue(IsObject(selected), "split Suggested Upgrades header is found")
    AssertEqual(
        "Dragon",
        selected.text,
        "selector skips both header lines and chooses the upgrade"
    )
}

TestRealCorruptedSuggestedHeadersSelectFollowingChoice() {
    for headerText in [
        "SugdeSbed upgrades:",
        "SugåéSbed upgrades:",
        "SugoeSbed upgrades:",
        "Sugåesbed upgrades:"
    ] {
        selected := SelectFirstSuggestedUpgradeOCRWord([
            {
                Text: headerText,
                x: 20,
                y: 100,
                w: 180,
                h: 20,
                Words: [
                    {Text: headerText, x: 20, y: 100, w: 180, h: 20}
                ]
            },
            {
                Text: "e X-Bow",
                x: 30,
                y: 140,
                w: 100,
                h: 22,
                Words: [
                    {Text: "e", x: 30, y: 140, w: 8, h: 22},
                    {Text: "X-Bow", x: 48, y: 140, w: 70, h: 22}
                ]
            }
        ])
        AssertTrue(
            IsObject(selected),
            "real OCR header variant is accepted: " headerText
        )
        AssertEqual(
            "X-Bow",
            selected.text,
            "real OCR header variant selects the following upgrade"
        )
    }
}

TestBuilderConfirmationFailureCannotComplete() {
    primitives := BuilderFlowRecorder(true, false)
    flow := ADBMainFlowSections(primitives)
    result := flow.RunBuilderUpgrade(
        {gold: true, elixir: true, darkElixir: true},
        false
    )
    AssertTrue(!result, "failed builder confirmation tap aborts completion")
}

TestBuilderConfirmsTwiceBeforeClear() {
    primitives := BuilderFlowRecorder(true, true)
    flow := ADBMainFlowSections(primitives)
    result := flow.RunBuilderUpgrade(
        {gold: true, elixir: true, darkElixir: true},
        false
    )
    confirmIndices := FindOperationIndices(
        primitives.Operations,
        "tap_upgrade_confirm"
    )
    clearIndex := FindOperationIndex(primitives.Operations, "clear_tap")
    AssertTrue(result, "builder flow completes after two confirmations")
    AssertEqual(2, confirmIndices.Length, "builder sends two confirmations")
    AssertTrue(
        confirmIndices[2] > confirmIndices[1],
        "second builder confirmation follows the first"
    )
    AssertTrue(
        clearIndex > confirmIndices[2],
        "builder clear tap happens after the second confirmation"
    )
    AssertEqual(
        300,
        primitives.WaitDurations[1],
        "builder waits 300 ms between confirmation taps"
    )
}

TestLabFlowConfirmsDirectlyWithoutInfo() {
    primitives := LabFlowRecorder(true)
    flow := ADBMainFlowSections(primitives)
    result := flow.RunLabUpgrade(
        {gold: false, elixir: true, darkElixir: true}
    )
    suggestionIndex := FindOperationIndex(
        primitives.Operations,
        "tap_lab_suggestion"
    )
    confirmIndex := FindOperationIndex(
        primitives.Operations,
        "tap_upgrade_confirm"
    )
    AssertTrue(result, "lab upgrade completes after confirmation")
    AssertTrue(
        confirmIndex > suggestionIndex,
        "lab confirms directly after tapping the suggestion"
    )
    AssertEqual(
        1,
        FindOperationIndices(
            primitives.Operations,
            "tap_upgrade_confirm"
        ).Length,
        "lab still sends exactly one confirmation"
    )
    AssertEqual(
        0,
        FindOperationIndex(
            primitives.Operations,
            "find_builder_info_from_frame"
        ),
        "lab flow never searches for the builder Info button"
    )
}

TestLabConfirmationFailureCannotComplete() {
    primitives := LabFlowRecorder(false)
    flow := ADBMainFlowSections(primitives)
    result := flow.RunLabUpgrade(
        {gold: false, elixir: true, darkElixir: true}
    )
    AssertTrue(!result, "failed lab confirmation tap aborts completion")
}

TestLiveBuilderInfoProductionContract() {
    botPath := A_ScriptDir "\ADBcocbotrefactor.ahk"
    source := FileRead(botPath)
    for required in [
        '#include "builder_info_ocr_logic.ahk"',
        "NormalizeBuilderOCRMatch(",
        "selected.tapX",
        "selected.tapY",
        "FindBuilderInfoFromADBFrame(",
        "'info ",
        '"builder_info"',
        'case "find_builder_info_from_frame"',
        'case "tap_builder_info"',
        "TapBuilderInfo(info)"
    ] {
        AssertTrue(
            InStr(source, required) > 0,
            "live builder Info integration includes " required
        )
    }
    AssertTrue(
        FileExist(
            A_ScriptDir
                "\OCRimages\cropped images\info_button_template.png"
        ),
        "live builder Info template asset exists"
    )
}

TestLiveTapReturnsRandomizedADBPointForLogging() {
    source := FileRead(A_ScriptDir "\ADBcocbotrefactor.ahk")
    AssertTrue(
        InStr(source, "point := interaction.Tap(") > 0,
        "live tap boundary retains the randomized ADB point"
    )
    AssertTrue(
        InStr(source, "return point") > 0,
        "live tap boundary returns the randomized ADB point"
    )
    AssertTrue(
        InStr(source, "randomized ADB actually sent") > 0,
        "confirmation log reports the actual randomized ADB coordinate"
    )
}

TestLiveSuggestedUpgradeUsesOneImmutableCapture() {
    source := FileRead(A_ScriptDir "\ADBcocbotrefactor.ahk")
    functionStart := InStr(source, "FindFlowSuggestedUpgrade(menuKind) {")
    functionEnd := InStr(
        source,
        "FindBuilderInfoFromADBFrame(framePath) {",
        false,
        functionStart
    )
    AssertTrue(
        functionStart > 0 && functionEnd > functionStart,
        "live suggested-upgrade function can be inspected"
    )
    functionSource := SubStr(
        source,
        functionStart,
        functionEnd - functionStart
    )
    freshFrameIndex := InStr(
        functionSource,
        "framePath := CaptureADBFrame(true)"
    )
    captureIndex := InStr(
        functionSource,
        "adbCrop := SaveADBFrameRegionToPNG("
    )
    scaleLoopIndex := InStr(functionSource, "for scaleValue in scales")
    AssertTrue(
        freshFrameIndex > 0
            && freshFrameIndex < captureIndex
            && captureIndex < scaleLoopIndex,
        "live suggested-upgrade OCR captures once before all scales"
    )
    AssertTrue(
        InStr(functionSource, "Suggested upgrades OCR ") > 0,
        "live suggested-upgrade OCR logs each raw scale result"
    )
}

TestLegacyWallPickerUsesSuggestedMenuRow() {
    source := FileRead(A_ScriptDir "\ADBcocbotrefactor.ahk")
    functionStart := InStr(source, "FindAnyWallInDropdown() {")
    functionEnd := InStr(source, "UpgradeWalls(wallState :=", false, functionStart)
    AssertTrue(
        functionStart > 0 && functionEnd > functionStart,
        "legacy wall picker can be inspected"
    )
    functionSource := SubStr(source, functionStart, functionEnd - functionStart)
    AssertTrue(
        InStr(functionSource, "SelectFirstSuggestedUpgradeOCRWord(result.Lines)") > 0,
        "legacy wall picker selects only the first Suggested Upgrades row"
    )
    AssertTrue(
        InStr(functionSource, "NormalizeBuilderOCRMatch(selected, sc)") > 0,
        "legacy wall picker normalizes its OCR row coordinates"
    )
    AssertTrue(
        InStr(functionSource, "IsWallSuggestedUpgrade(selected)") > 0,
        "legacy wall picker verifies that the Suggested row is a Wall"
    )
}

TestWallSuggestedUpgradeRejectsVillageOverlayText() {
    AssertTrue(
        IsWallSuggestedUpgrade({text: "Wall"}),
        "Wall is a valid suggested-upgrade word"
    )
    AssertTrue(
        IsWallSuggestedUpgrade({text: "Wa11"}),
        "common Wall OCR substitution is accepted"
    )
    AssertTrue(
        !IsWallSuggestedUpgrade({text: "Wall Level 3"}),
        "selected village Wall Level text is never treated as the menu word"
    )
}

TestWallPickerSelectsRowDirectlyBelowSuggestedHeader() {
    selected := SelectFirstSuggestedUpgradeOCRWord([
        {
            Text: "Suggested upgrades:",
            x: 20,
            y: 100,
            w: 180,
            h: 20,
            Words: [{Text: "Suggested", x: 20, y: 100, w: 90, h: 20}]
        },
        {
            Text: "Wall x16",
            x: 20,
            y: 140,
            w: 130,
            h: 22,
            Words: [
                {Text: "Wall", x: 20, y: 140, w: 54, h: 22},
                {Text: "x16", x: 84, y: 140, w: 40, h: 22}
            ]
        },
        {
            Text: "Wall Level 3",
            x: 430,
            y: 500,
            w: 180,
            h: 30,
            Words: [{Text: "Wall", x: 430, y: 500, w: 54, h: 30}]
        }
    ])
    AssertTrue(IsObject(selected), "Suggested Upgrades produces a first-row selection")
    AssertEqual("Wall", selected.text, "wall picker selects the row directly below the header")
    AssertEqual(20, selected.x, "wall picker retains the menu word coordinate")
    AssertEqual(140, selected.y, "wall picker retains the menu row coordinate")
}

RunTest("scale cache and client translation", TestScaleCacheAndTranslation)
RunTest("invalid mapping fails explicitly", TestInvalidMappingFails)
RunTest("mapping identity changes invalidate cached scales", TestMappingIdentityInvalidation)
RunTest("minimized window uses cached client dimensions", TestMinimizedWindowUsesCachedClientDimensions)
RunTest("config persists client coordinates only", TestClientCoordinatePersistenceOnly)
RunTest("observation coordinates translate in both directions", TestObservationCoordinateConversions)
RunTest("runtime observation source is ADB-only", TestADBOnlyObservationSource)
RunTest("only calibration startup can foreground the emulator", TestCalibrationOwnsForegroundActivation)
RunTest("coordinate offsets stay within -7..+8", TestCoordinateOffsetBounds)
RunTest("timing bands split at 75 ms", TestTimingBands)
RunTest("interaction applies internal timing jitter", TestInternalTimingJitter)
RunTest("tap/swipe/pinch/place/key share the boundary", TestAllActionsUseBoundary)
RunTest("spell offset is applied after client translation", TestSpellOffsetAppliesAfterClientTranslation)
RunTest("clear tap owns three randomized taps", TestClearTapOwnsThreeRandomizedTaps)
RunTest("live clear tap uses an AutoHotkey v2 callback reference", TestLiveClearTapUsesV2CallbackReference)
RunTest("clear-tap visual inspector follows the live debugger contract", TestClearTapVisualInspectorContract)
RunTest("loot visual inspector follows the Phase 2 debugger contract", TestLootVisualInspectorContract)
RunTest("loot consensus rejects an oversized outlier", TestLootConsensusRejectsOversizedOutlier)
RunTest("loot mode accepts one valid integer", TestLootModeAcceptsOneValidInteger)
RunTest("loot mode rounds close valid readings", TestLootModeRoundsCloseValidReadings)
RunTest("both invalid loot readings attack", TestBothInvalidLootAttacks)
RunTest("valid loot readings preserve the 500k decision", TestLootThresholdDecisionRemainsAuthoritative)
RunTest("live loot OCR uses the proven ADB contract", TestLiveLootOCRUsesProvenADBContract)
RunTest("loot OCR comparison harness contract", TestLootOCRComparisonHarnessContract)
RunTest("builder/lab OCR comparison harness contract", TestBuilderLabOCRComparisonHarnessContract)
RunTest("builder/lab comparison crops trim only their left edges", TestBuilderLabComparisonCropsTrimOnlyTheirLeftEdges)
RunTest("threshold inspector uses one fresh ADB contract", TestThresholdVisualInspectorUsesFreshADBContract)
RunTest("threshold neighborhoods ignore light text", TestThresholdNeighborhoodIgnoresLightPixels)
RunTest("live thresholds use proven neighborhoods", TestLiveThresholdReaderUsesProvenNeighborhoodContract)
RunTest("builder upgrade test stops before confirmation", TestBuilderUpgradeInfoFlowHarnessContract)
RunTest("timer exit visual harness follows the approved contract", TestTimerExitVisualHarnessContract)
RunTest("triggered timer exits before stopping at cycle end", TestTimerExitRunsOnlyAfterTriggeredEndOfCycleCheck)
RunTest("untriggered timer does not exit or stop", TestTimerExitDoesNothingBeforeTimerIsTriggered)
RunTest("timer exit Okay point scales with the viewport", TestTimerExitOkayPointScalesWithViewport)
RunTest("live timer exit uses the scalable ADB contract", TestLiveTimerExitProductionContract)
RunTest("live builder flow taps Info before confirmation", TestLiveBuilderFlowRequiresInfoBeforeConfirmation)
RunTest("live builder flow skips confirmation without Info", TestLiveBuilderFlowSkipsConfirmationWithoutInfo)
RunTest("live bot contains the proven builder Info integration", TestLiveBuilderInfoProductionContract)
RunTest("live suggestions reuse one immutable ADB capture", TestLiveSuggestedUpgradeUsesOneImmutableCapture)
RunTest("legacy wall picker uses the Suggested Upgrades row", TestLegacyWallPickerUsesSuggestedMenuRow)
RunTest("wall picker rejects village overlay text", TestWallSuggestedUpgradeRejectsVillageOverlayText)
RunTest("wall picker selects the row below Suggested Upgrades", TestWallPickerSelectsRowDirectlyBelowSuggestedHeader)
RunTest("split Suggested Upgrades header selects the following choice", TestSplitSuggestedUpgradesHeaderSelectsFollowingChoice)
RunTest("real corrupted Suggested headers select the following choice", TestRealCorruptedSuggestedHeadersSelectFollowingChoice)
RunTest("builder confirmation failure cannot complete", TestBuilderConfirmationFailureCannotComplete)
RunTest("builder confirms twice before clear tap", TestBuilderConfirmsTwiceBeforeClear)
RunTest("lab confirms directly without builder Info", TestLabFlowConfirmsDirectlyWithoutInfo)
RunTest("lab confirmation failure cannot complete", TestLabConfirmationFailureCannotComplete)
RunTest("live tap returns its randomized ADB point", TestLiveTapReturnsRandomizedADBPointForLogging)
RunTest("Builder Base attack orders navigation before deployment", TestBuilderBaseAttackOrdersNavigationBeforeDeployment)
RunTest("Builder Base stage one returns home after four completed analyses", TestBuilderBaseStageOneReturnsHomeAfterFourCompletedAnalyses)
RunTest("Builder Base stage one resets its four-check cycle", TestBuilderBaseStageOneResetsFourCheckCycle)
RunTest("Builder Base invalid capture does not advance the fourth check", TestBuilderBaseInvalidCaptureDoesNotAdvanceTheFourthCheck)
RunTest("Builder Base three stars deploys stage two on the same side", TestBuilderBaseThreeStarsDeploysStageTwoOnTheSameSide)
RunTest("Builder Base stage two requires completed deployment", TestBuilderBaseStageTwoRequiresACompletedDeployment)
RunTest("Builder Base stage two tracks state and capture retries", TestBuilderBaseStageTwoTracksDeploymentAndInvalidCaptureRetry)
RunTest("Builder Base outer loop completes and begins the next attack", TestBuilderBaseOuterLoopCanCompleteAndStartTheNextAttack)
RunTest("Builder Base outer loop only begins attacks", TestBuilderBaseOuterLoopOnlyBeginsAttacks)
RunTest("Builder Base visual harness follows the one-script F-key contract", TestBuilderBaseVisualHarnessContract)
RunTest("pinch helper targets a supported Android version", TestPinchHelperTargetsCurrentAndroid)
RunTest("Builder Base image analysis uses valid GDI+ DLL names", TestBuilderBaseGdipCallsUseValidDllNames)
RunTest("Builder Base star analysis uses the proven ADB gold detector", TestBuilderBaseGoldenDetectorUsesProvenADBRule)
RunTest("isolated Builder Base star inspector follows the visual-debugger contract", TestBuilderBaseStarInspectorContract)
RunTest("Builder Base GDI+ runtime loads and samples a PNG", TestBuilderBaseGdipRuntimeLoadsAndSamplesPng)
RunTest("Builder Base harness reports actionable errors", TestBuilderBaseHarnessReportsActionableErrors)
RunTest("Builder Base monitor reports check and Return Home progress", TestBuilderBaseFlowLogsCheckAndReturnHomeProgress)
RunTest("production Builder Base loop uses the proven flow", TestLiveBuilderBaseUsesProvenFlow)
RunTest("reload OCR accepts only explicit action labels", TestExplicitReloadActionLabels)
RunTest("vision OCR uses a project-managed Python runtime", TestVisionRuntimeUsesProjectManagedEnvironment)
RunTest("lab fraction OCR preserves the denominator leading edge", TestLabFractionOCRPreservesTheDenominatorLeadingEdge)
RunTest("vision OCR failures are not reported as availability", TestVisionFailuresAreNotReportedAsResourceAvailability)
RunTest("repeated Start does not pause the running bot", TestStartDoesNotPauseARunningBot)
RunTest("diagnostic logs redact user paths and prune images", TestDiagnosticLogsRedactUserPathsAndPruneImages)
RunTest("multi-point recognition uses one fresh frame", TestMultiPointRecognitionUsesOneFreshFrame)
RunTest("production uses one shared live cycle lifecycle", TestLiveGlobalCycleProductionContract)
RunTest("reconnect inspector separates analysis from confirmed tap", TestReconnectReloadInspectorContract)

FileAppend(
    Format("RESULT: {} passed, {} failed.`n", TestPassCount, TestFailCount),
    TestResultPath
)
ExitApp(TestFailCount == 0 ? 0 : 1)
