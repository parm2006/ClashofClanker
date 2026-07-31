#Requires AutoHotkey v2.0
#SingleInstance Force

global ADB_PINCH_COMPONENT := "com.example.instrumentation/PinchInstrumentation"
global ADBRefactorFlowAPI := ""
global FlowTestResultPath := A_Temp "\adb_refactor_flow_result.txt"
global FlowTestPassCount := 0
global FlowTestFailCount := 0

if FileExist(FlowTestResultPath)
    FileDelete(FlowTestResultPath)

#Include *i ADBcocbotrefactor_support.ahk
#Include *i loot_ocr_logic.ahk

class FakeFlowOperations {
    __New() {
        this.Log := []
        this.Messages := []
        this.ResponseQueues := Map()
    }

    Queue(name, values*) {
        this.ResponseQueues[name] := values
        return this
    }

    Do(name, args*) {
        if (name == "log") {
            this.Messages.Push(args[1])
            return true
        }
        entry := name
        for arg in args
            entry .= ":" FlowValueText(arg)
        this.Log.Push(entry)

        if this.ResponseQueues.Has(name) {
            queue := this.ResponseQueues[name]
            if (queue.Length == 0)
                throw Error("Response queue exhausted for " name ".")
            return queue.RemoveAt(1)
        }
        return true
    }
}

AssertMessagesContain(messages, requiredFragments, description) {
    for fragment in requiredFragments {
        found := false
        for message in messages {
            if InStr(message, fragment) {
                found := true
                break
            }
        }
        if !found
            throw Error(description ": missing message containing [" fragment "].")
    }
}

FlowValueText(value) {
    if !IsObject(value)
        return String(value)
    if value.HasOwnProp("name")
        return String(value.name)
    return "<object>"
}

AssertTrue(condition, description) {
    if !condition
        throw Error(description)
}

AssertEqual(expected, actual, description) {
    if (expected != actual)
        throw Error(Format("{}: expected [{}], got [{}].", description, expected, actual))
}

JoinLog(entries) {
    text := ""
    for index, entry in entries
        text .= (index == 1 ? "" : " -> ") entry
    return text
}

MakeLootResult(value, valid := true, reason := "consensus") {
    return {
        valid: valid,
        value: value,
        reason: reason,
        agreement: valid ? 2 : 0,
        readingCount: valid ? 2 : 0
    }
}

AssertLogEquals(expected, actual, description) {
    if (expected.Length != actual.Length) {
        throw Error(
            Format(
                "{}: expected {} operations, got {}.`nExpected: {}`nActual: {}",
                description,
                expected.Length,
                actual.Length,
                JoinLog(expected),
                JoinLog(actual)
            )
        )
    }
    for index, entry in expected {
        if (actual[index] != entry) {
            throw Error(
                Format(
                    "{}: operation {} expected [{}], got [{}].`nActual: {}",
                    description,
                    index,
                    entry,
                    actual[index],
                    JoinLog(actual)
                )
            )
        }
    }
}

AssertLogContainsInOrder(actual, expected, description) {
    actualIndex := 1
    for expectedEntry in expected {
        found := false
        while (actualIndex <= actual.Length) {
            if (actual[actualIndex] == expectedEntry) {
                found := true
                actualIndex += 1
                break
            }
            actualIndex += 1
        }
        if !found {
            throw Error(
                Format(
                    "{}: missing ordered operation [{}].`nActual: {}",
                    description,
                    expectedEntry,
                    JoinLog(actual)
                )
            )
        }
    }
}

AssertLogExcludesPrefix(actual, forbiddenPrefix, description) {
    for entry in actual {
        if (SubStr(entry, 1, StrLen(forbiddenPrefix)) == forbiddenPrefix)
            throw Error(description ": unexpected operation [" entry "].")
    }
}

AssertThrows(callback, description) {
    try {
        callback.Call()
    } catch {
        return
    }
    throw Error(description)
}

GetFlowAPI() {
    global ADBRefactorFlowAPI
    AssertTrue(
        IsObject(ADBRefactorFlowAPI),
        "ADB refactor flow controller is not implemented."
    )
    return ADBRefactorFlowAPI
}

RunFlowTest(name, callback) {
    global FlowTestPassCount, FlowTestFailCount, FlowTestResultPath
    try {
        callback.Call()
        FlowTestPassCount += 1
        FileAppend("PASS: " name "`n", FlowTestResultPath)
    } catch as err {
        FlowTestFailCount += 1
        FileAppend("FAIL: " name " - " err.Message "`n", FlowTestResultPath)
    }
}

TestStartupRoutesAfterThreeClears() {
    operations := FakeFlowOperations()
    operations.Queue(
        "capture_fresh_frame",
        {section: "village", id: 1}
    )
    operations.Queue("detect_village_from_frame", "main")
    state := {
        timerMs: 3600000,
        mainCalibrated: true,
        builderCalibrated: true
    }

    sections := GetFlowAPI().CreateMainSections(operations)
    GetFlowAPI().RunStartup(sections, state)

    AssertLogEquals(
        [
            "verify_emulator",
            "verify_calibration",
            "start_timer:3600000",
            "clear_tap",
            "capture_fresh_frame:village",
            "detect_village_from_frame:<object>",
            "start_main_loop"
        ],
        operations.Log,
        "startup order"
    )
}

TestStartupRoutesBuilderWithoutZeroTimer() {
    operations := FakeFlowOperations()
    operations.Queue(
        "capture_fresh_frame",
        {section: "village", id: 1}
    )
    operations.Queue("detect_village_from_frame", "builder")
    state := {
        timerMs: 0,
        mainCalibrated: true,
        builderCalibrated: true
    }

    sections := GetFlowAPI().CreateMainSections(operations)
    GetFlowAPI().RunStartup(sections, state)

    AssertLogEquals(
        [
            "verify_emulator",
            "verify_calibration",
            "clear_tap",
            "capture_fresh_frame:village",
            "detect_village_from_frame:<object>",
            "start_builder_loop"
        ],
        operations.Log,
        "zero-timer Builder Base startup order"
    )
}

CreateMainHappyPathOperations() {
    operations := FakeFlowOperations()
    operations.Queue(
        "check_resource_thresholds",
        {gold: true, elixir: true, darkElixir: true}
    )
    return operations
}

TestMainLoopExactHappyPath() {
    operations := CreateMainHappyPathOperations()
    state := {
        completedAttacks: 39,
        collectorCount: 3,
        wallUpgradesEnabled: true,
        minGold: 500000,
        minElixir: 500000,
        timerEnabled: true
    }

    GetFlowAPI().RunMainLoop(operations, state)

    AssertLogEquals(
        [
            "reset_main_viewport",
            "collect_resources:3",
            "check_resource_thresholds",
            "run_builder_upgrade:<object>:1",
            "run_wall_upgrades:<object>:1",
            "run_lab_upgrade:<object>",
            "enter_main_battle",
            "find_eligible_base:500000:500000",
            "attack_main_base",
            "return_main_home",
            "finish_main_cycle"
        ],
        operations.Log,
        "Main Village exact sequence"
    )
}

TestMainLoopReservesLastBuilderForWalls() {
    primitives := FakeFlowOperations()
    primitives.Queue(
        "capture_fresh_frame",
        {section: "builder", id: 1}
    )
    primitives.Queue(
        "read_builders_from_frame",
        {free: 1, total: 6, goblin: false}
    )
    sections := GetFlowAPI().CreateMainSections(primitives)

    sections.Do(
        "run_builder_upgrade",
        {gold: true, elixir: true, darkElixir: true},
        true
    )

    AssertLogEquals(
        [
            "capture_fresh_frame:builder",
            "read_builders_from_frame:<object>"
        ],
        primitives.Log,
        "one free builder is reserved for walls"
    )
}

TestCollectResourcesOwnsRollAndIteration() {
    primitives := FakeFlowOperations()
    primitives.Queue("collection_roll", 1)
    sections := GetFlowAPI().CreateMainSections(primitives)

    sections.Do("collect_resources", 3)

    AssertLogEquals(
        [
            "collection_roll",
            "tap_collector:1",
            "tap_collector:2",
            "tap_collector:3"
        ],
        primitives.Log,
        "collector section owns roll and iteration"
    )
}

TestThresholdSectionUsesOneFreshFrame() {
    primitives := FakeFlowOperations()
    primitives.Queue(
        "capture_fresh_frame",
        {section: "thresholds", id: 1}
    )
    primitives.Queue(
        "read_resource_thresholds_from_frame",
        {gold: true, elixir: false, darkElixir: true}
    )
    sections := GetFlowAPI().CreateMainSections(primitives)

    thresholds := sections.Do("check_resource_thresholds")

    AssertTrue(thresholds.gold, "gold threshold")
    AssertTrue(!thresholds.elixir, "elixir threshold")
    AssertTrue(thresholds.darkElixir, "dark elixir threshold")
    AssertLogEquals(
        [
            "capture_fresh_frame:thresholds",
            "read_resource_thresholds_from_frame:<object>"
        ],
        primitives.Log,
        "one threshold frame serves all three booleans"
    )
}

TestMutableSectionsUseSeparateFreshFrames() {
    primitives := FakeFlowOperations()
    primitives.Queue(
        "capture_fresh_frame",
        {section: "builder", id: 1},
        {section: "walls", id: 2},
        {section: "lab", id: 3}
    )
    primitives.Queue(
        "read_builders_from_frame",
        {free: 0, total: 6, goblin: false}
    )
    primitives.Queue(
        "read_wall_state_from_frame",
        {canUpgrade: false}
    )
    primitives.Queue(
        "read_lab_from_frame",
        {free: 0, total: 1, goblin: false}
    )
    sections := GetFlowAPI().CreateMainSections(primitives)
    thresholds := {gold: true, elixir: true, darkElixir: true}

    sections.Do("run_builder_upgrade", thresholds, true)
    sections.Do("run_wall_upgrades", thresholds, true)
    sections.Do("run_lab_upgrade", thresholds)

    AssertLogContainsInOrder(
        primitives.Log,
        [
            "capture_fresh_frame:builder",
            "read_builders_from_frame:<object>",
            "capture_fresh_frame:walls",
            "read_wall_state_from_frame:<object>",
            "capture_fresh_frame:lab",
            "read_lab_from_frame:<object>"
        ],
        "mutable sections use separate frames"
    )
}

TestLabRequiresElixirAndDarkElixirThresholds() {
    for thresholds in [
        {gold: true, elixir: false, darkElixir: true},
        {gold: true, elixir: true, darkElixir: false}
    ] {
        primitives := FakeFlowOperations()
        sections := GetFlowAPI().CreateMainSections(primitives)

        upgraded := sections.Do("run_lab_upgrade", thresholds)

        AssertTrue(!upgraded, "lab is skipped when either required threshold is false")
        AssertLogExcludesPrefix(
            primitives.Log,
            "capture_fresh_frame:",
            "lab skip must not take an unnecessary ADB screenshot"
        )
        AssertMessagesContain(
            primitives.Messages,
            ["Lab upgrade skipped: Elixir and Dark Elixir thresholds are required"],
            "lab threshold skip reason"
        )
    }
}

TestSectionRejectsFrameFromAnotherDecision() {
    primitives := FakeFlowOperations()
    primitives.Queue(
        "capture_fresh_frame",
        {section: "thresholds", id: 1}
    )
    sections := GetFlowAPI().CreateMainSections(primitives)

    AssertThrows(
        () => sections.Do(
            "run_builder_upgrade",
            {gold: true, elixir: true, darkElixir: true},
            false
        ),
        "builder section must reject a threshold frame"
    )
}

TestEnterMainBattleOwnsThreeInputs() {
    primitives := FakeFlowOperations()
    sections := GetFlowAPI().CreateMainSections(primitives)

    sections.Do("enter_main_battle")

    AssertLogEquals(
        [
            "tap_main_attack",
            "tap_find_match",
            "tap_attack_start"
        ],
        primitives.Log,
        "battle entry order"
    )
}

TestEligibleBaseOwnsCloudAndLootRetries() {
    primitives := FakeFlowOperations()
    primitives.Queue(
        "capture_fresh_frame",
        {section: "clouds", id: 1},
        {section: "clouds", id: 2},
        {section: "base", id: 3}
    )
    primitives.Queue("check_clouds_from_frame", true, false)
    primitives.Queue("detect_village_from_frame", "battle")
    primitives.Queue(
        "read_loot_from_frame",
        {gold: MakeLootResult(500000), elixir: MakeLootResult(100)}
    )
    sections := GetFlowAPI().CreateMainSections(primitives)

    sections.Do("find_eligible_base", 500000, 500000)

    AssertLogEquals(
        [
            "wait:4000",
            "capture_fresh_frame:clouds",
            "check_clouds_from_frame:<object>",
            "wait:2000",
            "capture_fresh_frame:clouds",
            "check_clouds_from_frame:<object>",
            "reset_main_viewport",
            "capture_fresh_frame:base",
            "detect_village_from_frame:<object>",
            "read_loot_from_frame:<object>"
        ],
        primitives.Log,
        "eligible base cloud and loot sequence"
    )
}

TestEligibleBaseRetriesBattleEntryWhenStillMain() {
    primitives := FakeFlowOperations()
    primitives.Queue(
        "capture_fresh_frame",
        {section: "clouds", id: 1},
        {section: "base", id: 2},
        {section: "clouds", id: 3},
        {section: "base", id: 4}
    )
    primitives.Queue("check_clouds_from_frame", false, false)
    primitives.Queue("detect_village_from_frame", "main", "battle")
    primitives.Queue(
        "read_loot_from_frame",
        {gold: MakeLootResult(600000), elixir: MakeLootResult(100)}
    )
    sections := GetFlowAPI().CreateMainSections(primitives)

    sections.Do("find_eligible_base", 500000, 500000)

    AssertLogEquals(
        [
            "wait:4000",
            "capture_fresh_frame:clouds",
            "check_clouds_from_frame:<object>",
            "reset_main_viewport",
            "capture_fresh_frame:base",
            "detect_village_from_frame:<object>",
            "tap_main_attack",
            "tap_find_match",
            "tap_attack_start",
            "wait:4000",
            "capture_fresh_frame:clouds",
            "check_clouds_from_frame:<object>",
            "reset_main_viewport",
            "capture_fresh_frame:base",
            "detect_village_from_frame:<object>",
            "read_loot_from_frame:<object>"
        ],
        primitives.Log,
        "Main Village battle-entry recovery sequence"
    )
    AssertMessagesContain(
        primitives.Messages,
        ["still at Main Village", "retrying the complete battle entry"],
        "battle-entry retry is visible in the console"
    )
}

TestBothInvalidLootAttacksWithoutNext() {
    primitives := FakeFlowOperations()
    primitives.Queue(
        "capture_fresh_frame",
        {section: "clouds", id: 1},
        {section: "base", id: 2}
    )
    primitives.Queue("check_clouds_from_frame", false)
    primitives.Queue("detect_village_from_frame", "battle")
    primitives.Queue(
        "read_loot_from_frame",
        {
            gold: MakeLootResult(0, false, "no_integer"),
            elixir: MakeLootResult(0, false, "no_integer")
        }
    )
    sections := GetFlowAPI().CreateMainSections(primitives)

    sections.Do("find_eligible_base", 500000, 500000)

    AssertTrue(
        !InStr(JoinLog(primitives.Log), "tap_next_match"),
        "both invalid loot results must attack without tapping Next"
    )
    AssertMessagesContain(
        primitives.Messages,
        ["both Gold and Elixir OCR results are invalid"],
        "both-invalid fallback is visible in the console"
    )
}

TestAttackMainBaseOwnsDeploymentAndAbilities() {
    primitives := FakeFlowOperations()
    primitives.Queue("random_side", 3)
    sections := GetFlowAPI().CreateMainSections(primitives)

    sections.Do("attack_main_base")

    AssertLogEquals(
        [
            "random_side",
            "deploy_main:1:side3",
            "deploy_main:2:side3",
            "deploy_main:3:side3",
            "deploy_main:z:side3",
            "deploy_main:q:side3",
            "deploy_main:w:side3",
            "deploy_main:e:side3",
            "deploy_main:r:side3",
            "deploy_spell:a:side3:35",
            "deploy_spell:s:side3:35",
            "wait:30000",
            "hero_ability:q",
            "hero_ability:w",
            "hero_ability:e",
            "hero_ability:r"
        ],
        primitives.Log,
        "attack section"
    )
}

TestReturnHomeOwnsFreshRetryLoop() {
    primitives := FakeFlowOperations()
    primitives.Queue(
        "capture_fresh_frame",
        {section: "home", id: 1},
        {section: "home", id: 2}
    )
    primitives.Queue("detect_main_home_from_frame", false, true)
    sections := GetFlowAPI().CreateMainSections(primitives)

    sections.Do("return_main_home")

    AssertLogEquals(
        [
            "tap_return_home",
            "wait:2000",
            "tap_return_home",
            "wait:2000",
            "capture_fresh_frame:home",
            "detect_main_home_from_frame:<object>",
            "tap_return_home",
            "wait:2000",
            "tap_return_home",
            "wait:2000",
            "capture_fresh_frame:home",
            "detect_main_home_from_frame:<object>",
            "reset_main_viewport"
        ],
        primitives.Log,
        "Return Home retry sequence"
    )
}

TestFinishMainCycleUsesCommonLifecycle() {
    primitives := FakeFlowOperations()
    sections := GetFlowAPI().CreateMainSections(primitives)

    sections.Do("finish_main_cycle")

    AssertLogEquals(
        ["complete_global_cycle:main"],
        primitives.Log,
        "Main finish cycle common lifecycle delegation"
    )
}

TestCommonCycleSkipsReloadBeforeFifth() {
    operations := FakeFlowOperations()
    operations.Queue("record_completed_attack", 4)
    operations.Queue("timer_triggered", false)

    result := GetFlowAPI().RunCycleCompletion(
        operations,
        {currentVillage: "main"}
    )

    AssertEqual("continue", result, "non-fifth completion continues")
    AssertLogEquals(
        [
            "record_completed_attack:main",
            "timer_triggered"
        ],
        operations.Log,
        "non-fifth completion skips reconnect OCR"
    )
}

TestCommonTimerExitTakesPrecedence() {
    operations := FakeFlowOperations()
    operations.Queue("record_completed_attack", 5)
    operations.Queue("timer_triggered", true)

    result := GetFlowAPI().RunCycleCompletion(
        operations,
        {currentVillage: "builder"}
    )

    AssertEqual("stopped", result, "elapsed common timer stops the session")
    AssertLogEquals(
        [
            "record_completed_attack:builder",
            "timer_triggered",
            "exit_game_after_timer",
            "stop_bot"
        ],
        operations.Log,
        "timer exit precedes fifth-cycle reconnect"
    )
}

TestDetailedMessagesExposeMainFlowDecisions() {
    primitives := FakeFlowOperations()
    primitives.Queue(
        "capture_fresh_frame",
        {section: "village", id: 1},
        {section: "thresholds", id: 2},
        {section: "lab", id: 3},
        {section: "clouds", id: 4},
        {section: "base", id: 5},
        {section: "clouds", id: 6},
        {section: "base", id: 7},
        {section: "home", id: 8}
    )
    primitives.Queue("detect_village_from_frame", "main", "battle", "battle")
    primitives.Queue("collection_roll", 9)
    primitives.Queue(
        "read_resource_thresholds_from_frame",
        {gold: false, elixir: true, darkElixir: true}
    )
    primitives.Queue("read_lab_from_frame", {free: 0, total: 1, goblin: false})
    primitives.Queue("check_clouds_from_frame", false, false)
    primitives.Queue(
        "read_loot_from_frame",
        {gold: MakeLootResult(100), elixir: MakeLootResult(200)},
        {gold: MakeLootResult(600000), elixir: MakeLootResult(200)}
    )
    primitives.Queue("random_side", 1)
    primitives.Queue("detect_main_home_from_frame", true)
    primitives.Queue("timer_triggered", false)
    sections := GetFlowAPI().CreateMainSections(primitives)

    GetFlowAPI().RunStartup(
        sections,
        {timerMs: 0, mainCalibrated: true, builderCalibrated: true}
    )
    sections.Do("collect_resources", 3)
    thresholds := sections.Do("check_resource_thresholds")
    sections.Do("run_builder_upgrade", thresholds, true)
    sections.Do("run_wall_upgrades", thresholds, false)
    sections.Do("run_lab_upgrade", thresholds)
    sections.Do("enter_main_battle")
    sections.Do("find_eligible_base", 500000, 500000)
    sections.Do("attack_main_base")
    sections.Do("return_main_home")
    sections.Do("finish_main_cycle")

    AssertMessagesContain(
        primitives.Messages,
        [
            "Startup: verifying emulator",
            "Clear tap: sending 3",
            "Village detection result: main",
            "Resource collection skipped",
            "Resource thresholds: Gold=NO, Elixir=YES, Dark Elixir=YES",
            "Builder upgrade skipped",
            "Wall upgrades skipped",
            "Lab availability: 0/1",
            "Battle entry: tapping Attack",
            "Cloud check 1: CLEAR",
            "Loot OCR: Gold=100, Elixir=200",
            "Loot below thresholds",
            "Loot threshold met",
            "Attack: selected side1",
            "Deploying troop slot 1",
            "Deploying spell a",
            "Return Home attempt 1",
            "Main Village cycle complete"
        ],
        "detailed Main Village console coverage"
    )
}

TestRuntimeUsesSharedStartupAndMainController() {
    source := FileRead(A_ScriptDir "\ADBcocbotrefactor.ahk")
    AssertTrue(
        InStr(source, "ADBRefactorFlowAPI.RunStartup(") > 0,
        "UnifiedStart must run the shared startup controller"
    )
    AssertTrue(
        InStr(source, "ADBRefactorFlowAPI.RunMainLoop(") > 0,
        "StartBotLoop must run the shared Main Village controller"
    )
    AssertTrue(
        InStr(source, "CreateADBMainFlowSections(") > 0,
        "runtime must create the support-library Main sections"
    )
    AssertTrue(
        InStr(source, "LiveADBFlowPrimitives") > 0,
        "runtime must supply a thin live primitive adapter"
    )
}

CreateBuilderPhaseTwoOperations(homeAfterFifth := false) {
    operations := FakeFlowOperations()
    operations.Queue("check_clouds_from_frame", true, false)
    operations.Queue("random_side", 2, 4)
    if homeAfterFifth {
        operations.Queue(
            "read_three_stars_from_frame",
            {allBronze: false},
            {allBronze: false},
            {allBronze: false},
            {allBronze: false},
            {allBronze: false}
        )
        operations.Queue("detect_builder_home_from_frame", true)
    } else {
        operations.Queue(
            "read_three_stars_from_frame",
            {allBronze: false},
            {allBronze: false},
            {allBronze: false},
            {allBronze: false},
            {allBronze: false},
            {allBronze: true}
        )
        operations.Queue("detect_builder_home_from_frame", false, false, true)
    }
    return operations
}

TestBuilderLoopSequentialPollAndPhaseTwo() {
    operations := CreateBuilderPhaseTwoOperations(false)
    state := {completedAttacks: 0}

    GetFlowAPI().RunBuilderLoop(operations, state)

    expectedPrefix := [
        "tap_builder_attack",
        "tap_find_match",
        "wait:4000",
        "capture_cloud_frame",
        "check_clouds_from_frame",
        "wait:2000",
        "capture_cloud_frame",
        "check_clouds_from_frame",
        "reset_builder_viewport",
        "random_side"
    ]
    AssertLogContainsInOrder(operations.Log, expectedPrefix, "Builder Base cloud/reset order")
    AssertLogContainsInOrder(
        operations.Log,
        [
            "deploy_builder:phase1:q:side2",
            "deploy_builder:phase1:1:side2",
            "deploy_builder:phase1:2:side2",
            "deploy_builder:phase1:3:side2",
            "deploy_builder:phase1:4:side2",
            "deploy_builder:phase1:5:side2",
            "deploy_builder:phase1:6:side2",
            "deploy_builder:phase1:7:side2",
            "deploy_builder:phase1:8:side2"
        ],
        "Builder Base phase-one key order"
    )
    AssertLogContainsInOrder(
        operations.Log,
        [
            "capture_star_frame:1",
            "read_three_stars_from_frame:1",
            "capture_star_frame:2",
            "read_three_stars_from_frame:2",
            "capture_star_frame:3",
            "read_three_stars_from_frame:3",
            "capture_star_frame:4",
            "read_three_stars_from_frame:4",
            "capture_star_frame:5",
            "read_three_stars_from_frame:5",
            "tap_return_home",
            "capture_village_frame",
            "detect_builder_home_from_frame",
            "capture_star_frame:6",
            "read_three_stars_from_frame:6",
            "wait:5000",
            "reset_builder_viewport",
            "random_side",
            "deploy_builder:phase2:q:side4",
            "deploy_builder:phase2:1:side4",
            "deploy_builder:phase2:2:side4",
            "deploy_builder:phase2:3:side4",
            "deploy_builder:phase2:4:side4",
            "deploy_builder:phase2:5:side4",
            "deploy_builder:phase2:6:side4",
            "deploy_builder:phase2:7:side4",
            "deploy_builder:phase2:8:side4",
            "tap_return_home",
            "capture_village_frame",
            "detect_builder_home_from_frame",
            "wait:2000",
            "tap_return_home",
            "capture_village_frame",
            "detect_builder_home_from_frame",
            "record_completed_attack",
            "start_builder_loop"
        ],
        "Builder Base sequential polling and phase-two order"
    )
}

TestBuilderLoopDoesNotRunPhaseTwoAfterHome() {
    operations := CreateBuilderPhaseTwoOperations(true)
    state := {completedAttacks: 4}

    GetFlowAPI().RunBuilderLoop(operations, state)

    AssertLogContainsInOrder(
        operations.Log,
        [
            "capture_star_frame:5",
            "read_three_stars_from_frame:5",
            "tap_return_home",
            "capture_village_frame",
            "detect_builder_home_from_frame",
            "record_completed_attack",
            "start_builder_loop"
        ],
        "home-confirmed Builder Base restart"
    )
    AssertLogExcludesPrefix(
        operations.Log,
        "deploy_builder:phase2",
        "phase two requires three bronze stars"
    )
}

TestEveryFifthMainAttackReloadRecovery() {
    operations := FakeFlowOperations()
    operations.Queue("record_completed_attack", 5)
    operations.Queue("timer_triggered", false)
    operations.Queue(
        "capture_fresh_frame",
        {section: "reload", id: 1}
    )
    operations.Queue("find_reload_action_from_frame", false)

    result := GetFlowAPI().RunCycleCompletion(
        operations,
        {currentVillage: "main"}
    )

    AssertEqual("continue", result, "no Reload action continues Main")
    AssertLogEquals(
        [
            "record_completed_attack:main",
            "timer_triggered",
            "capture_fresh_frame:reload",
            "find_reload_action_from_frame:<object>"
        ],
        operations.Log,
        "fifth Main Village attack checks without blind tap"
    )
}

TestEveryFifthBuilderAttackReloadRecovery() {
    operations := FakeFlowOperations()
    operations.Queue("record_completed_attack", 10)
    operations.Queue("timer_triggered", false)
    operations.Queue(
        "capture_fresh_frame",
        {section: "reload", id: 1},
        {section: "reconnect", id: 2}
    )
    operations.Queue(
        "find_reload_action_from_frame",
        {name: "Reload", x: 900, y: 600}
    )
    operations.Queue("detect_village_from_frame", "main")

    result := GetFlowAPI().RunCycleCompletion(
        operations,
        {currentVillage: "builder"}
    )

    AssertEqual("routed", result, "reconnect can route Builder to Main")
    AssertLogEquals(
        [
            "record_completed_attack:builder",
            "timer_triggered",
            "capture_fresh_frame:reload",
            "find_reload_action_from_frame:<object>",
            "tap_reload_action:Reload",
            "wait:15000",
            "capture_fresh_frame:reconnect",
            "detect_village_from_frame:<object>",
            "route_village:main"
        ],
        operations.Log,
        "fifth Builder Base attack reload recovery and routing"
    )
}

TestReconnectRetriesUnknownFreshFrames() {
    operations := FakeFlowOperations()
    operations.Queue("record_completed_attack", 5)
    operations.Queue("timer_triggered", false)
    operations.Queue(
        "capture_fresh_frame",
        {section: "reload", id: 1},
        {section: "reconnect", id: 2},
        {section: "reconnect", id: 3}
    )
    operations.Queue(
        "find_reload_action_from_frame",
        {name: "Retry", x: 900, y: 600}
    )
    operations.Queue("detect_village_from_frame", "battle", "main")

    result := GetFlowAPI().RunCycleCompletion(
        operations,
        {currentVillage: "main"}
    )

    AssertEqual("continue", result, "same-village reconnect continues")
    AssertLogEquals(
        [
            "record_completed_attack:main",
            "timer_triggered",
            "capture_fresh_frame:reload",
            "find_reload_action_from_frame:<object>",
            "tap_reload_action:Retry",
            "wait:15000",
            "capture_fresh_frame:reconnect",
            "detect_village_from_frame:<object>",
            "wait:2000",
            "capture_fresh_frame:reconnect",
            "detect_village_from_frame:<object>"
        ],
        operations.Log,
        "unknown reconnect frames retry sequentially"
    )
}

TestReconnectRetriesInvalidFreshCapture() {
    operations := FakeFlowOperations()
    operations.Queue("record_completed_attack", 5)
    operations.Queue("timer_triggered", false)
    operations.Queue(
        "capture_fresh_frame",
        false,
        {section: "reload", id: 2}
    )
    operations.Queue("find_reload_action_from_frame", false)

    result := GetFlowAPI().RunCycleCompletion(
        operations,
        {currentVillage: "main"}
    )

    AssertEqual("continue", result, "capture retry can continue Main")
    AssertLogEquals(
        [
            "record_completed_attack:main",
            "timer_triggered",
            "capture_fresh_frame:reload",
            "wait:1000",
            "capture_fresh_frame:reload",
            "find_reload_action_from_frame:<object>"
        ],
        operations.Log,
        "invalid reconnect capture retries before OCR"
    )
}

flowTests := [
    {
        name: "startup validates, runs one triple clear, then routes Main Village",
        callback: TestStartupRoutesAfterThreeClears
    },
    {
        name: "zero timer is skipped before Builder Base routing",
        callback: TestStartupRoutesBuilderWithoutZeroTimer
    },
    {
        name: "Main Village sequence matches flow.txt",
        callback: TestMainLoopExactHappyPath
    },
    {
        name: "Main Village reserves the last builder for walls",
        callback: TestMainLoopReservesLastBuilderForWalls
    },
    {
        name: "collector section owns its roll and iteration",
        callback: TestCollectResourcesOwnsRollAndIteration
    },
    {
        name: "threshold section uses one fresh frame for three booleans",
        callback: TestThresholdSectionUsesOneFreshFrame
    },
    {
        name: "builder, walls, and lab use separate fresh frames",
        callback: TestMutableSectionsUseSeparateFreshFrames
    },
    {
        name: "lab requires Elixir and Dark Elixir before capturing",
        callback: TestLabRequiresElixirAndDarkElixirThresholds
    },
    {
        name: "sections reject frames captured for another decision",
        callback: TestSectionRejectsFrameFromAnotherDecision
    },
    {
        name: "battle entry owns all three navigation inputs",
        callback: TestEnterMainBattleOwnsThreeInputs
    },
    {
        name: "eligible-base search owns cloud and loot retries",
        callback: TestEligibleBaseOwnsCloudAndLootRetries
    },
    {
        name: "eligible-base search retries battle entry when still at Main",
        callback: TestEligibleBaseRetriesBattleEntryWhenStillMain
    },
    {
        name: "both invalid loot readings attack without tapping Next",
        callback: TestBothInvalidLootAttacksWithoutNext
    },
    {
        name: "attack section owns deployment and hero abilities",
        callback: TestAttackMainBaseOwnsDeploymentAndAbilities
    },
    {
        name: "Return Home owns fresh capture retries",
        callback: TestReturnHomeOwnsFreshRetryLoop
    },
    {
        name: "Main finish cycle uses the common lifecycle",
        callback: TestFinishMainCycleUsesCommonLifecycle
    },
    {
        name: "common cycle skips reconnect before the fifth attack",
        callback: TestCommonCycleSkipsReloadBeforeFifth
    },
    {
        name: "common timer exit precedes reconnect recovery",
        callback: TestCommonTimerExitTakesPrecedence
    },
    {
        name: "fifth Main attack checks reload without a blind tap",
        callback: TestEveryFifthMainAttackReloadRecovery
    },
    {
        name: "fifth Builder attack can reconnect and route Main",
        callback: TestEveryFifthBuilderAttackReloadRecovery
    },
    {
        name: "reconnect retries unknown fresh frames sequentially",
        callback: TestReconnectRetriesUnknownFreshFrames
    },
    {
        name: "reconnect retries an invalid fresh capture",
        callback: TestReconnectRetriesInvalidFreshCapture
    },
    {
        name: "detailed messages expose Main Village decisions",
        callback: TestDetailedMessagesExposeMainFlowDecisions
    },
    {
        name: "runtime uses the shared startup and Main Village controller",
        callback: TestRuntimeUsesSharedStartupAndMainController
    },
    ; Builder battle mechanics remain covered by the dedicated fake-primitives
    ; suite in test_adb_refactor_interactions.ahk. Shared cycle recovery is
    ; covered here for both village values.
]

if !IsObject(ADBRefactorFlowAPI) {
    for testCase in flowTests {
        FileAppend(
            "FAIL: " testCase.name
                " - ADB refactor flow controller is not implemented.`n",
            FlowTestResultPath
        )
        FlowTestFailCount += 1
    }
} else {
    for testCase in flowTests
        RunFlowTest(testCase.name, testCase.callback)
}

FileAppend(
    Format("RESULT: {} passed, {} failed.`n", FlowTestPassCount, FlowTestFailCount),
    FlowTestResultPath
)
ExitApp(FlowTestFailCount == 0 ? 0 : 1)
