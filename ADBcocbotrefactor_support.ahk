; Shared client-coordinate ADB interaction contract.
; The implementation is intentionally introduced through
; test_adb_refactor_interactions.ahk.

global ADBRefactorSupportLoaded := true
global ADBScaleX := 0.0
global ADBScaleY := 0.0
global ADBRefactorViewportLeft := 0
global ADBRefactorViewportTop := 0
global ADBRefactorViewportRight := -1
global ADBRefactorViewportBottom := -1
global ADBRefactorDisplayWidth := 0
global ADBRefactorDisplayHeight := 0
global ADBRefactorClientWidth := 0
global ADBRefactorClientHeight := 0
global ADBRefactorProvider := ""
global ADBRefactorSerial := ""
global ADB_PINCH_INSTRUMENTATION_PACKAGE := "com.cocbot.pinchtest.instrumentation"
global ADB_PINCH_COMPONENT := ADB_PINCH_INSTRUMENTATION_PACKAGE "/com.cocbot.pinchtest.PinchInstrumentation"

ConfigureADBClientMapping(
    viewportLeft,
    viewportTop,
    viewportRight,
    viewportBottom,
    adbWidth,
    adbHeight,
    clientWidth := 0,
    clientHeight := 0,
    provider := "",
    serial := ""
) {
    global ADBScaleX, ADBScaleY
    global ADBRefactorViewportLeft, ADBRefactorViewportTop
    global ADBRefactorViewportRight, ADBRefactorViewportBottom
    global ADBRefactorDisplayWidth, ADBRefactorDisplayHeight
    global ADBRefactorClientWidth, ADBRefactorClientHeight
    global ADBRefactorProvider, ADBRefactorSerial

    if (viewportRight <= viewportLeft)
        throw Error("Android viewport width must be positive.")
    if (viewportBottom <= viewportTop)
        throw Error("Android viewport height must be positive.")
    if (adbWidth <= 0)
        throw Error("Android display width must be positive.")
    if (adbHeight <= 0)
        throw Error("Android display height must be positive.")

    ADBRefactorViewportLeft := viewportLeft
    ADBRefactorViewportTop := viewportTop
    ADBRefactorViewportRight := viewportRight
    ADBRefactorViewportBottom := viewportBottom
    ADBRefactorDisplayWidth := adbWidth
    ADBRefactorDisplayHeight := adbHeight
    ADBRefactorClientWidth := clientWidth
    ADBRefactorClientHeight := clientHeight
    ADBRefactorProvider := provider
    ADBRefactorSerial := serial
    ADBScaleX := adbWidth / (viewportRight - viewportLeft)
    ADBScaleY := adbHeight / (viewportBottom - viewportTop)
    return {ScaleX: ADBScaleX, ScaleY: ADBScaleY}
}

ValidateADBClientMappingIdentity(clientWidth, clientHeight, provider, serial, adbWidth, adbHeight) {
    global ADBScaleX, ADBScaleY
    global ADBRefactorDisplayWidth, ADBRefactorDisplayHeight
    global ADBRefactorClientWidth, ADBRefactorClientHeight
    global ADBRefactorProvider, ADBRefactorSerial

    isCurrent := ADBScaleX > 0
        && ADBScaleY > 0
        && ADBRefactorClientWidth == clientWidth
        && ADBRefactorClientHeight == clientHeight
        && ADBRefactorProvider == provider
        && ADBRefactorSerial == serial
        && ADBRefactorDisplayWidth == adbWidth
        && ADBRefactorDisplayHeight == adbHeight
    if !isCurrent
        InvalidateADBClientMapping()
    return isCurrent
}

ResolveADBValidationClientSize(
    isMinimized,
    currentClientWidth,
    currentClientHeight,
    calibratedClientWidth,
    calibratedClientHeight
) {
    if isMinimized {
        if (calibratedClientWidth <= 0 || calibratedClientHeight <= 0)
            throw Error("Cached calibrated client dimensions are invalid.")
        return {
            width: calibratedClientWidth,
            height: calibratedClientHeight,
            usedCached: true
        }
    }
    return {
        width: currentClientWidth,
        height: currentClientHeight,
        usedCached: false
    }
}

ResolveTimerExitOkayClientPoint(
    viewportLeft,
    viewportTop,
    viewportRight,
    viewportBottom
) {
    if (viewportRight <= viewportLeft)
        throw Error("Timer exit requires a positive viewport width.")
    if (viewportBottom <= viewportTop)
        throw Error("Timer exit requires a positive viewport height.")
    return {
        x: Round(
            viewportLeft
                + (viewportRight - viewportLeft - 1) * 0.60
        ),
        y: Round(
            viewportTop
                + (viewportBottom - viewportTop - 1) * 0.605
        )
    }
}

IsExplicitReloadActionText(text) {
    normalized := StrLower(RegExReplace(String(text), "[^A-Za-z]", ""))
    if (InStr(normalized, "disconnect") > 0)
        return false
    return InStr(normalized, "reload") > 0
        || InStr(normalized, "retry") > 0
        || InStr(normalized, "tryagain") > 0
        || InStr(normalized, "reconnect") > 0
        || InStr(normalized, "relogin") > 0
        || InStr(normalized, "okay") > 0
        || InStr(normalized, "connect") > 0
        || normalized == "ok"
}

IsErrorCardColorMatch(framePath, viewportX, viewportY, viewportW, viewportH) {
    if (framePath == "" || !FileExist(framePath))
        return {isMatch: false, count: 0, total: 6}

    centerX := viewportX + viewportW * 0.50
    centerY := viewportY + viewportH * 0.50

    offsets := [
        {x: 0, y: 0},
        {x: -15, y: 0},
        {x: 15, y: 0},
        {x: 0, y: -15},
        {x: 0, y: 15},
        {x: -15, y: -15}
    ]

    matchCount := 0
    InitGDIPlus()
    pBitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", framePath, "ptr*", &pBitmap) != 0
        return {isMatch: false, count: 0, total: 6}

    try {
        for off in offsets {
            adbPt := TranslateClientPointToADB(centerX + off.x, centerY + off.y)
            argb := 0
            status := DllCall("gdiplus\GdipBitmapGetPixel", "ptr", pBitmap, "int", Round(adbPt.x), "int", Round(adbPt.y), "uint*", &argb)
            if (status == 0) {
                rgb := argb & 0x00FFFFFF
                r := (rgb >> 16) & 0xFF
                g := (rgb >> 8) & 0xFF
                b := rgb & 0xFF
                if (Abs(r - 0x19) <= 15 && Abs(g - 0x1C) <= 15 && Abs(b - 0x1E) <= 15)
                    matchCount += 1
            }
        }
    } finally {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    }

    return {isMatch: matchCount >= 3, count: matchCount, total: offsets.Length}
}

InvalidateADBClientMapping() {
    global ADBScaleX, ADBScaleY
    global ADBRefactorDisplayWidth, ADBRefactorDisplayHeight
    global ADBRefactorClientWidth, ADBRefactorClientHeight
    global ADBRefactorProvider, ADBRefactorSerial

    ADBScaleX := 0.0
    ADBScaleY := 0.0
    ADBRefactorDisplayWidth := 0
    ADBRefactorDisplayHeight := 0
    ADBRefactorClientWidth := 0
    ADBRefactorClientHeight := 0
    ADBRefactorProvider := ""
    ADBRefactorSerial := ""
}

TranslateClientPointToADB(clientX, clientY) {
    global ADBScaleX, ADBScaleY
    global ADBRefactorViewportLeft, ADBRefactorViewportTop
    global ADBRefactorViewportRight, ADBRefactorViewportBottom
    global ADBRefactorDisplayWidth, ADBRefactorDisplayHeight

    if (ADBScaleX <= 0 || ADBScaleY <= 0 || ADBRefactorDisplayWidth <= 0 || ADBRefactorDisplayHeight <= 0)
        throw Error("ADB client mapping is not configured.")

    clampedX := Max(ADBRefactorViewportLeft, Min(ADBRefactorViewportRight, clientX))
    clampedY := Max(ADBRefactorViewportTop, Min(ADBRefactorViewportBottom, clientY))
    return {
        x: _ClampADBRefactorCoordinate(
            Round((clampedX - ADBRefactorViewportLeft) * ADBScaleX),
            ADBRefactorDisplayWidth
        ),
        y: _ClampADBRefactorCoordinate(
            Round((clampedY - ADBRefactorViewportTop) * ADBScaleY),
            ADBRefactorDisplayHeight
        )
    }
}

TranslateADBPointToClient(adbX, adbY) {
    global ADBScaleX, ADBScaleY
    global ADBRefactorViewportLeft, ADBRefactorViewportTop
    global ADBRefactorViewportRight, ADBRefactorViewportBottom
    global ADBRefactorDisplayWidth, ADBRefactorDisplayHeight

    if (ADBScaleX <= 0 || ADBScaleY <= 0 || ADBRefactorDisplayWidth <= 0 || ADBRefactorDisplayHeight <= 0)
        throw Error("ADB client mapping is not configured.")

    clampedADBX := Max(0, Min(ADBRefactorDisplayWidth - 1, adbX))
    clampedADBY := Max(0, Min(ADBRefactorDisplayHeight - 1, adbY))
    return {
        x: Max(
            ADBRefactorViewportLeft,
            Min(ADBRefactorViewportRight, Round(ADBRefactorViewportLeft + clampedADBX / ADBScaleX))
        ),
        y: Max(
            ADBRefactorViewportTop,
            Min(ADBRefactorViewportBottom, Round(ADBRefactorViewportTop + clampedADBY / ADBScaleY))
        )
    }
}

TranslateClientRectToADB(clientX, clientY, clientWidth, clientHeight) {
    if (clientWidth <= 0 || clientHeight <= 0)
        throw Error("Client crop dimensions must be positive.")
    topLeft := TranslateClientPointToADB(clientX, clientY)
    bottomRight := TranslateClientPointToADB(
        clientX + clientWidth - 1,
        clientY + clientHeight - 1
    )
    return {
        x: topLeft.x,
        y: topLeft.y,
        width: Max(1, bottomRight.x - topLeft.x + 1),
        height: Max(1, bottomRight.y - topLeft.y + 1)
    }
}

GetADBActionTiming(intendedDelayMs) {
    intendedDelayMs := Max(0, Round(intendedDelayMs))
    jitterRadius := intendedDelayMs <= 75 ? 5 : 15
    return {
        PreDelay: Max(0, intendedDelayMs - jitterRadius),
        JitterMin: 0,
        JitterMax: jitterRadius * 2
    }
}

BuildADBTapArguments(serial, x, y) {
    return '-s "' serial '" shell input tap ' Round(x) ' ' Round(y)
}

BuildADBSwipeArguments(serial, startX, startY, endX, endY, durationMs) {
    return '-s "' serial '" shell input swipe '
        . Round(startX) ' ' Round(startY) ' '
        . Round(endX) ' ' Round(endY) ' ' Round(durationMs)
}

BuildADBPinchArguments(serial, centerX, centerY, startRadius, endRadius, durationMs) {
    global ADB_PINCH_COMPONENT
    return '-s "' serial '"'
        . ' shell am instrument -w'
        . ' -e centerX ' Round(centerX)
        . ' -e centerY ' Round(centerY)
        . ' -e startRadius ' Round(startRadius)
        . ' -e endRadius ' Round(endRadius)
        . ' -e durationMs ' Round(durationMs)
        . ' "' ADB_PINCH_COMPONENT '"'
}

BuildADBKeyEventArguments(serial, keyCode) {
    return '-s "' serial '" shell input keyevent ' keyCode
}

_ClampADBRefactorCoordinate(value, displaySize) {
    return Max(0, Min(displaySize - 1, Round(value)))
}

_RandomizeADBRefactorPoint(point, randomIntSink) {
    global ADBRefactorDisplayWidth, ADBRefactorDisplayHeight
    return {
        x: _ClampADBRefactorCoordinate(point.x + randomIntSink.Call(-7, 8), ADBRefactorDisplayWidth),
        y: _ClampADBRefactorCoordinate(point.y + randomIntSink.Call(-7, 8), ADBRefactorDisplayHeight)
    }
}

class ADBClientInteraction {
    __New(serial, commandSink, delaySink, randomIntSink) {
        if (serial == "")
            throw Error("ADB serial is required.")
        if !IsObject(commandSink) || !IsObject(delaySink) || !IsObject(randomIntSink)
            throw Error("Command, delay, and random sinks are required.")
        this.Serial := serial
        this.CommandSink := commandSink
        this.DelaySink := delaySink
        this.RandomIntSink := randomIntSink
    }

    Tap(clientX, clientY, intendedDelayMs := 0) {
        point := this._RandomizedPoint(clientX, clientY)
        this._ApplyInternalJitter(intendedDelayMs)
        this.CommandSink.Call(BuildADBTapArguments(this.Serial, point.x, point.y))
        return point
    }

    Swipe(startClientX, startClientY, endClientX, endClientY, durationMs, intendedDelayMs := 0) {
        startPoint := this._RandomizedPoint(startClientX, startClientY)
        endPoint := this._RandomizedPoint(endClientX, endClientY)
        this._ApplyInternalJitter(intendedDelayMs)
        this.CommandSink.Call(BuildADBSwipeArguments(
            this.Serial,
            startPoint.x,
            startPoint.y,
            endPoint.x,
            endPoint.y,
            durationMs
        ))
        return {Start: startPoint, End: endPoint}
    }

    Pinch(centerClientX, centerClientY, startRadius, endRadius, durationMs, intendedDelayMs := 0) {
        centerPoint := this._RandomizedPoint(centerClientX, centerClientY)
        this._ApplyInternalJitter(intendedDelayMs)
        this.CommandSink.Call(BuildADBPinchArguments(
            this.Serial,
            centerPoint.x,
            centerPoint.y,
            startRadius,
            endRadius,
            durationMs
        ))
        return centerPoint
    }

    Place(clientX, clientY, intendedDelayMs := 0) {
        return this.Tap(clientX, clientY, intendedDelayMs)
    }

    ClearTap(clientX, clientY, intendedDelayMs := 0, beforeEachTapSink := "") {
        points := []
        Loop 3 {
            if IsObject(beforeEachTapSink)
                beforeEachTapSink.Call(intendedDelayMs)
            points.Push(this.Tap(clientX, clientY, intendedDelayMs))
        }
        return points
    }

    PlaceShiftedTowardCenter(clientX, clientY, adbShiftPixels, intendedDelayMs := 0) {
        global ADBRefactorDisplayWidth, ADBRefactorDisplayHeight
        point := TranslateClientPointToADB(clientX, clientY)
        centerX := (ADBRefactorDisplayWidth - 1) / 2
        centerY := (ADBRefactorDisplayHeight - 1) / 2
        deltaX := centerX - point.x
        deltaY := centerY - point.y
        shiftX := deltaX > 0 ? adbShiftPixels : (deltaX < 0 ? -adbShiftPixels : 0)
        shiftY := deltaY > 0 ? adbShiftPixels : (deltaY < 0 ? -adbShiftPixels : 0)
        point := {
            x: _ClampADBRefactorCoordinate(
                point.x + shiftX,
                ADBRefactorDisplayWidth
            ),
            y: _ClampADBRefactorCoordinate(
                point.y + shiftY,
                ADBRefactorDisplayHeight
            )
        }
        point := _RandomizeADBRefactorPoint(point, this.RandomIntSink)
        this._ApplyInternalJitter(intendedDelayMs)
        this.CommandSink.Call(BuildADBTapArguments(this.Serial, point.x, point.y))
        return point
    }

    KeyEvent(keyCode, intendedDelayMs := 0) {
        this._ApplyInternalJitter(intendedDelayMs)
        arguments := BuildADBKeyEventArguments(this.Serial, keyCode)
        this.CommandSink.Call(arguments)
        return arguments
    }

    _RandomizedPoint(clientX, clientY) {
        return _RandomizeADBRefactorPoint(
            TranslateClientPointToADB(clientX, clientY),
            this.RandomIntSink
        )
    }

    _ApplyInternalJitter(intendedDelayMs) {
        timing := GetADBActionTiming(intendedDelayMs)
        jitter := this.RandomIntSink.Call(timing.JitterMin, timing.JitterMax)
        this.DelaySink.Call(jitter)
        return jitter
    }
}

CreateADBClientInteraction(serial, commandSink, delaySink, randomIntSink) {
    return ADBClientInteraction(serial, commandSink, delaySink, randomIntSink)
}

class ADBMainFlowSections {
    __New(primitives) {
        if !IsObject(primitives)
            throw Error("Main flow primitives are required.")
        this.Primitives := primitives
    }

    Do(name, args*) {
        switch name {
            case "detect_village":
                return this.DetectVillage()
            case "reset_main_viewport":
                return this.Primitives.Do("reset_main_viewport")
            case "collect_resources":
                return this.CollectResources(args[1])
            case "check_resource_thresholds":
                return this.CheckResourceThresholds()
            case "run_builder_upgrade":
                return this.RunBuilderUpgrade(args[1], args[2])
            case "run_wall_upgrades":
                return this.RunWallUpgrades(args[1], args[2])
            case "run_lab_upgrade":
                return this.RunLabUpgrade(args[1])
            case "enter_main_battle":
                return this.EnterMainBattle()
            case "find_eligible_base":
                return this.FindEligibleBase(args[1], args[2])
            case "attack_main_base":
                return this.AttackMainBase()
            case "return_main_home":
                return this.ReturnMainHome()
            case "finish_main_cycle":
                return this.FinishMainCycle()
        }
        return this.Primitives.Do(name, args*)
    }

    DetectVillage() {
        this._Log("Village detection: capturing a fresh ADB frame.")
        frame := this._CaptureFreshFrame("village")
        village := this.Primitives.Do("detect_village_from_frame", frame)
        this._Log("Village detection result: " village ".")
        return village
    }

    CollectResources(collectorCount) {
        roll := this.Primitives.Do("collection_roll")
        if (roll != 1) {
            this._Log(
                "Resource collection skipped (roll " roll "/40; requires 1)."
            )
            return false
        }
        this._Log(
            "Resource collection: tapping " collectorCount
                " calibrated collectors."
        )
        Loop collectorCount {
            this._Log(
                "Resource collection: tapping collector "
                    A_Index "/" collectorCount "."
            )
            this.Primitives.Do("tap_collector", A_Index)
        }
        this._Log("Resource collection complete.")
        return true
    }

    CheckResourceThresholds() {
        this._Log(
            "Resource thresholds: capturing one fresh frame for Gold, "
                "Elixir, and Dark Elixir."
        )
        frame := this._CaptureFreshFrame("thresholds")
        thresholds := this.Primitives.Do(
            "read_resource_thresholds_from_frame",
            frame
        )
        if !IsObject(thresholds)
            throw Error("Resource threshold check did not return three booleans.")
        this._Log(
            "Resource thresholds: Gold=" this._YesNo(thresholds.gold)
                ", Elixir=" this._YesNo(thresholds.elixir)
                ", Dark Elixir=" this._YesNo(thresholds.darkElixir) "."
        )
        return thresholds
    }

    RunBuilderUpgrade(thresholds, wallUpgradesEnabled) {
        if !this._AllThresholdsMet(thresholds) {
            this._Log(
                "Builder upgrade skipped: all three resource thresholds "
                    "are not met."
            )
            return false
        }
        this._Log("Builder upgrade: capturing a fresh builder-status frame.")
        frame := this._CaptureFreshFrame("builder")
        builders := this.Primitives.Do("read_builders_from_frame", frame)
        if !IsObject(builders)
            throw Error("Builder availability could not be read.")
        if (builders.HasOwnProp("valid") && !builders.valid) {
            errorText := builders.HasOwnProp("error") ? builders.error : "no OCR result"
            this._Log("Builder availability OCR failed: " errorText ".")
            return false
        }
        this._Log(
            "Builder availability: " builders.free "/" builders.total
                ", Goblin=" this._YesNo(builders.goblin) "."
        )
        reserveLastBuilder := wallUpgradesEnabled && builders.free == 1
        if (builders.free <= 0) {
            this._Log("Builder upgrade skipped: no normal builders are free.")
            return false
        }
        if builders.goblin {
            this._Log(
                "Builder upgrade skipped: Goblin Builder detected; "
                    "gem spending is blocked."
            )
            return false
        }
        if reserveLastBuilder {
            this._Log(
                "Builder upgrade skipped: reserving the last free builder "
                    "for walls."
            )
            return false
        }
        this._Log("Builder upgrade: opening Suggested Upgrades.")
        this.Primitives.Do("open_builder_menu")
        suggestion := this.Primitives.Do("ocr_builder_suggestion")
        if !this._HasSuggestion(suggestion) {
            this._Log("Builder upgrade skipped: OCR found no suggestion.")
            return false
        }
        this._Log(
            "Builder upgrade: OCR selected '" this._SuggestionName(suggestion)
                "'."
        )
        this.Primitives.Do("tap_builder_suggestion", suggestion)
        this._Log(
            "Builder upgrade: capturing one fresh frame for the Info button."
        )
        infoFrame := this._CaptureFreshFrame("builder_info")
        info := this.Primitives.Do("find_builder_info_from_frame", infoFrame)
        if !this._HasSuggestion(info) {
            this._Log(
                "Builder upgrade skipped: the single Info template attempt "
                    "found no match."
            )
            this._Log("Builder upgrade: clearing the selected building.")
            this.Primitives.Do("clear_tap")
            return false
        }
        this._Log(
            "Builder upgrade: Info template matched at client ("
                info.x ", " info.y ")."
        )
        this.Primitives.Do("tap_builder_info", info)
        this._Log(
            "Builder upgrade: tapping the calibrated confirmation "
                "(1 of 2)."
        )
        if !this.Primitives.Do("tap_upgrade_confirm") {
            this._Log(
                "Builder upgrade failed: first confirmation tap was not sent."
            )
            this.Primitives.Do("clear_tap")
            return false
        }
        this.Primitives.Do("wait", 300)
        this._Log(
            "Builder upgrade: tapping the calibrated confirmation "
                "(2 of 2)."
        )
        if !this.Primitives.Do("tap_upgrade_confirm") {
            this._Log(
                "Builder upgrade failed: second confirmation tap was not sent."
            )
            this.Primitives.Do("clear_tap")
            return false
        }
        this.Primitives.Do("wait", 1500)
        this._Log("Builder upgrade: clearing the selection with 3 taps.")
        this.Primitives.Do("clear_tap")
        this._Log("Builder upgrade attempt complete.")
        return true
    }

    RunWallUpgrades(thresholds, wallUpgradesEnabled) {
        if !wallUpgradesEnabled {
            this._Log("Wall upgrades skipped: wall upgrades are disabled.")
            return false
        }
        if (!thresholds.gold && !thresholds.elixir) {
            this._Log(
                "Wall upgrades skipped: neither Gold nor Elixir threshold "
                    "is met."
            )
            return false
        }
        this._Log("Wall upgrades: capturing a fresh wall-decision frame.")
        frame := this._CaptureFreshFrame("walls")
        wallState := this.Primitives.Do("read_wall_state_from_frame", frame)
        if !IsObject(wallState)
            throw Error("Wall upgrade state could not be read.")
        this._Log(
            "Wall upgrade state: CanUpgrade="
                this._YesNo(
                    wallState.HasOwnProp("canUpgrade")
                        && wallState.canUpgrade
                )
                ", Gold=" this._OptionalYesNo(wallState, "gold")
                ", Elixir=" this._OptionalYesNo(wallState, "elixir") "."
        )
        if !wallState.HasOwnProp("canUpgrade") || !wallState.canUpgrade {
            this._Log("Wall upgrades skipped: no eligible normal builder.")
            return false
        }
        this._Log("Wall upgrades: starting the contained upgrade routine.")
        this.Primitives.Do("perform_wall_upgrades", wallState)
        this._Log("Wall upgrade routine complete.")
        return true
    }

    RunLabUpgrade(thresholds) {
        if !IsObject(thresholds)
            throw Error("Lab upgrade requires resource threshold results.")
        if (!thresholds.elixir || !thresholds.darkElixir) {
            this._Log(
                "Lab upgrade skipped: Elixir and Dark Elixir thresholds "
                    "are required."
            )
            return false
        }
        this._Log("Lab upgrade: capturing a fresh lab-status frame.")
        frame := this._CaptureFreshFrame("lab")
        lab := this.Primitives.Do("read_lab_from_frame", frame)
        if !IsObject(lab)
            throw Error("Lab availability could not be read.")
        if (lab.HasOwnProp("valid") && !lab.valid) {
            errorText := lab.HasOwnProp("error") ? lab.error : "no OCR result"
            this._Log("Lab availability OCR failed: " errorText ".")
            return false
        }
        this._Log(
            "Lab availability: " lab.free "/" lab.total
                ", Goblin=" this._YesNo(lab.goblin) "."
        )
        if (lab.free <= 0) {
            this._Log("Lab upgrade skipped: the laboratory is busy.")
            return false
        }
        if lab.goblin {
            this._Log(
                "Lab upgrade skipped: Goblin Researcher detected; "
                    "gem spending is blocked."
            )
            return false
        }
        this._Log("Lab upgrade: opening Suggested Upgrades.")
        this.Primitives.Do("open_lab_menu")
        suggestion := this.Primitives.Do("ocr_lab_suggestion")
        if !this._HasSuggestion(suggestion) {
            this._Log("Lab upgrade skipped: OCR found no suggestion.")
            return false
        }
        this._Log(
            "Lab upgrade: OCR selected '" this._SuggestionName(suggestion)
                "'."
        )
        this.Primitives.Do("tap_lab_suggestion", suggestion)
        this._Log("Lab upgrade: tapping the calibrated confirmation.")
        if !this.Primitives.Do("tap_upgrade_confirm") {
            this._Log("Lab upgrade failed: confirmation tap was not sent.")
            this.Primitives.Do("clear_tap")
            return false
        }
        this.Primitives.Do("wait", 1500)
        this._Log("Lab upgrade: clearing the selection with 3 taps.")
        this.Primitives.Do("clear_tap")
        this._Log("Lab upgrade attempt complete.")
        return true
    }

    EnterMainBattle() {
        this._Log("Battle entry: tapping Attack.")
        this.Primitives.Do("tap_main_attack")
        this._Log("Battle entry: tapping Find a Match.")
        this.Primitives.Do("tap_find_match")
        this._Log("Battle entry: tapping the green Attack button.")
        this.Primitives.Do("tap_attack_start")
        this._Log("Battle entry inputs complete.")
        return true
    }

    FindEligibleBase(minGold, minElixir) {
        baseAttempt := 0
        Loop {
            baseAttempt += 1
            this._Log(
                "Base search attempt " baseAttempt
                    ": waiting 4000 ms for matchmaking."
            )
            this.Primitives.Do("wait", 4000)
            cloudCheck := 0
            Loop {
                cloudCheck += 1
                cloudFrame := this._CaptureFreshFrame("clouds")
                cloudsPresent := this.Primitives.Do(
                    "check_clouds_from_frame",
                    cloudFrame
                )
                this._Log(
                    "Cloud check " cloudCheck ": "
                        (cloudsPresent ? "CLOUDS PRESENT" : "CLEAR") "."
                )
                if !cloudsPresent
                    break
                this._Log("Clouds remain; waiting 2000 ms before rechecking.")
                this.Primitives.Do("wait", 2000)
            }

            this._Log(
                "Base search: clouds cleared; resetting the viewport before "
                    "state detection and loot OCR."
            )
            this.Primitives.Do("reset_main_viewport")
            baseFrame := this._CaptureFreshFrame("base")
            village := this.Primitives.Do(
                "detect_village_from_frame",
                baseFrame
            )
            this._Log("Base search state detection: " village ".")
            if (village == "main") {
                this._Log(
                    "Base search is still at Main Village; retrying the "
                        "complete battle entry."
                )
                this.EnterMainBattle()
                continue
            }
            if (village != "battle") {
                throw Error(
                    "Expected a Main Village battle after clouds cleared; "
                        "detected " village "."
                )
            }
            loot := this.Primitives.Do("read_loot_from_frame", baseFrame)
            if (!IsObject(loot)
                || !loot.HasOwnProp("gold")
                || !loot.HasOwnProp("elixir")
                || !IsObject(loot.gold)
                || !IsObject(loot.elixir)) {
                throw Error("Loot OCR did not return gold and elixir values.")
            }
            goldText := loot.gold.valid
                ? String(loot.gold.value)
                : "INVALID:" loot.gold.reason
            elixirText := loot.elixir.valid
                ? String(loot.elixir.value)
                : "INVALID:" loot.elixir.reason
            this._Log(
                "Loot OCR: Gold=" goldText ", Elixir=" elixirText
                    " (minimums: Gold=" minGold
                    ", Elixir=" minElixir ")."
            )
            decision := this._EvaluateLootAttackDecision(
                loot.gold,
                loot.elixir,
                minGold,
                minElixir
            )
            if decision.attack {
                if (decision.reason == "both_invalid") {
                    this._Log(
                        "Loot fallback: both Gold and Elixir OCR results are invalid; "
                            "attacking this base to avoid an "
                            "endless Next loop."
                    )
                } else {
                    this._Log(
                        "Loot threshold met; this base will be attacked."
                    )
                }
                return loot
            }
            this._Log(
                "Loot below thresholds; tapping Next to search again."
            )
            this.Primitives.Do("tap_next_match")
        }
    }

    AttackMainBase() {
        sideName := "side" this.Primitives.Do("random_side")
        this._Log("Attack: selected " sideName " for deployment.")
        for key in ["1", "2", "3"] {
            this._Log("Deploying troop slot " key " on " sideName ".")
            this.Primitives.Do("deploy_main", key, sideName)
        }
        this._Log("Deploying siege machine z on " sideName ".")
        this.Primitives.Do("deploy_main", "z", sideName)
        for key in ["q", "w", "e", "r"] {
            this._Log("Deploying hero " key " on " sideName ".")
            this.Primitives.Do("deploy_main", key, sideName)
        }
        for key in ["a", "s"] {
            this._Log(
                "Deploying spell " key " on " sideName
                    " with a 35-pixel-per-axis inward shift."
            )
            this.Primitives.Do("deploy_spell", key, sideName, 35)
        }
        this._Log("Battle in progress; waiting 30000 ms.")
        this.Primitives.Do("wait", 30000)
        for key in ["q", "w", "e", "r"] {
            this._Log("Triggering hero ability " key ".")
            this.Primitives.Do("hero_ability", key)
        }
        this._Log("Deployment and hero-ability sequence complete.")
        return sideName
    }

    ReturnMainHome() {
        attempt := 0
        Loop {
            attempt += 1
            this._Log(
                "Return Home attempt " attempt
                    ": tapping the calibrated location."
            )
            this.Primitives.Do("tap_return_home")
            this.Primitives.Do("wait", 2000)
            this._Log(
                "Return Home attempt " attempt
                    ": sending the second tap for result/Star Bonus recovery."
            )
            this.Primitives.Do("tap_return_home")
            this.Primitives.Do("wait", 2000)
            frame := this._CaptureFreshFrame("home")
            atHome := this.Primitives.Do(
                "detect_main_home_from_frame",
                frame
            )
            this._Log(
                "Return Home attempt " attempt
                    " detection: " (atHome ? "HOME" : "NOT HOME") "."
            )
            if atHome
                break
            if (attempt >= 25) {
                this._Log(
                    "Return Home reached 25 failed attempts; checking for a reload popup."
                )
                if this._RecoverReturnHomeAfterRetryLimit()
                    break
                throw Error(
                    "Return Home failed after 25 attempts and no reload action restored Main Village."
                )
            }
        }
        this._Log("Home confirmed; resetting the Main Village viewport.")
        this.Primitives.Do("reset_main_viewport")
        this._Log("Return Home complete.")
        return true
    }

    _RecoverReturnHomeAfterRetryLimit() {
        frame := this._CaptureFreshFrame("reload")
        reloadAction := this.Primitives.Do(
            "find_reload_action_from_frame",
            frame
        )
        if !IsObject(reloadAction) {
            this._Log("Return Home recovery: no explicit reload action found.")
            return false
        }

        this._Log("Return Home recovery: waiting 1000 ms before tapping reload action.")
        if !this.Primitives.Do("wait", 1000)
            return false
        this.Primitives.Do("tap_reload_action", reloadAction)
        this._Log("Return Home recovery: waiting 10000 ms for Main Village.")
        if !this.Primitives.Do("wait", 10000)
            return false

        frame := this._CaptureFreshFrame("home")
        atHome := this.Primitives.Do("detect_main_home_from_frame", frame)
        this._Log(
            "Return Home recovery detection: " (atHome ? "HOME" : "NOT HOME") "."
        )
        return atHome
    }

    FinishMainCycle() {
        this._Log("Main Village cycle complete; entering shared lifecycle.")
        return this.Primitives.Do("complete_global_cycle", "main")
    }

    _CaptureFreshFrame(section) {
        this._Log("ADB capture: requesting fresh frame for " section ".")
        frame := this.Primitives.Do("capture_fresh_frame", section)
        if !IsObject(frame)
            throw Error("Fresh " section " frame was not captured.")
        if !frame.HasOwnProp("section") || frame.section != section
            throw Error("Fresh frame belongs to another decision section.")
        this._Log("ADB capture complete for " section ".")
        return frame
    }

    _AllThresholdsMet(thresholds) {
        return IsObject(thresholds)
            && thresholds.gold
            && thresholds.elixir
            && thresholds.darkElixir
    }

    _HasSuggestion(suggestion) {
        return IsObject(suggestion) || suggestion != ""
    }

    _SuggestionName(suggestion) {
        if IsObject(suggestion) && suggestion.HasOwnProp("name")
            return suggestion.name
        return "" suggestion
    }

    _YesNo(value) {
        return value ? "YES" : "NO"
    }

    _OptionalYesNo(value, propertyName) {
        if !IsObject(value) || !value.HasOwnProp(propertyName)
            return "UNKNOWN"
        return this._YesNo(value.%propertyName%)
    }

    _EvaluateLootAttackDecision(goldResult, elixirResult, minGold, minElixir) {
        if (!goldResult.valid && !elixirResult.valid) {
            return {attack: true, reason: "both_invalid"}
        }
        goldMet := goldResult.valid && goldResult.value >= minGold
        elixirMet := elixirResult.valid && elixirResult.value >= minElixir
        if (goldMet || elixirMet)
            return {attack: true, reason: "threshold_met"}
        return {attack: false, reason: "below_threshold"}
    }

    _Log(message) {
        this.Primitives.Do("log", message)
    }
}

CreateADBMainFlowSections(primitives) {
    return ADBMainFlowSections(primitives)
}

class ADBGlobalCycleFlow {
    __New(primitives) {
        if !IsObject(primitives)
            throw Error("Global cycle primitives are required.")
        this.Primitives := primitives
    }

    Complete(currentVillage) {
        this._RequireVillage(currentVillage)
        completedAttacks := this.Primitives.Do(
            "record_completed_attack",
            currentVillage
        )
        this._Log(
            "Shared cycle complete for " currentVillage
                ". Session attacks: " completedAttacks "."
        )

        timerTriggered := this.Primitives.Do("timer_triggered")
        this._Log(
            "Shared auto-stop timer: "
                (timerTriggered ? "TRIGGERED" : "not triggered") "."
        )
        if timerTriggered {
            this._Log("Shared timer elapsed; exiting Clash of Clans.")
            this.Primitives.Do("exit_game_after_timer")
            this.Primitives.Do("stop_bot")
            return "stopped"
        }

        if (Mod(completedAttacks, 5) != 0) {
            this._Log("Reconnect checkpoint skipped until attack multiple 5.")
            return "continue"
        }
        return this.RunReloadRecovery(currentVillage, completedAttacks)
    }

    RunReloadRecovery(currentVillage, completedAttacks) {
        this._RequireVillage(currentVillage)
        this._Log(
            "Reconnect checkpoint after attack " completedAttacks
                ": capturing a fresh center frame."
        )
        Loop {
            frame := this._CaptureFreshFrame("reload")
            try {
                reloadAction := this.Primitives.Do(
                    "find_reload_action_from_frame",
                    frame
                )
                break
            } catch as err {
                this._Log(
                    "Reconnect OCR failed: " err.Message
                        "; retrying with a fresh frame in 1000 ms."
                )
                if !this.Primitives.Do("wait", 1000)
                    return "stopped"
            }
        }
        if !IsObject(reloadAction) {
            this._Log("Reconnect checkpoint: no explicit Reload/Retry action.")
            return "continue"
        }

        this._Log("Reconnect checkpoint: action found; waiting 1000 ms before tap.")
        if !this.Primitives.Do("wait", 1000)
            return "stopped"
        this._Log("Reconnect checkpoint: tapping explicit reload action.")
        this.Primitives.Do("tap_reload_action", reloadAction)
        if !this.Primitives.Do("wait", 10000)
            return "stopped"

        Loop {
            frame := this._CaptureFreshFrame("reconnect")
            detectedVillage := this.Primitives.Do(
                "detect_village_from_frame",
                frame
            )
            this._Log(
                "Reconnect village detection: " detectedVillage "."
            )
            if (detectedVillage == "main"
                || detectedVillage == "builder") {
                if (detectedVillage != currentVillage) {
                    this.Primitives.Do(
                        "route_village",
                        detectedVillage
                    )
                    return "routed"
                }
                return "continue"
            }
            if !this.Primitives.Do("wait", 2000)
                return "stopped"
        }
    }

    _CaptureFreshFrame(section) {
        Loop {
            frame := false
            try {
                frame := this.Primitives.Do(
                    "capture_fresh_frame",
                    section
                )
            } catch as err {
                this._Log(
                    "Fresh " section " capture failed: " err.Message
                        "; retrying in 1000 ms."
                )
            }
            if (IsObject(frame)
                && frame.HasOwnProp("section")
                && frame.section == section) {
                return frame
            }
            if !IsObject(frame) {
                this._Log(
                    "Fresh " section
                        " capture was invalid; retrying in 1000 ms."
                )
            } else {
                this._Log(
                    "Fresh frame belongs to another cycle decision; "
                        "retrying in 1000 ms."
                )
            }
            if !this.Primitives.Do("wait", 1000)
                throw Error("Global cycle stopped during capture retry.")
        }
    }

    _RequireVillage(village) {
        if (village != "main" && village != "builder")
            throw Error("Global cycle village must be main or builder.")
    }

    _Log(message) {
        this.Primitives.Do("log", message)
    }
}

class ADBRefactorFlowController {
    CreateMainSections(primitives) {
        return CreateADBMainFlowSections(primitives)
    }

    RunStartup(operations, state) {
        operations.Do("log", "Startup: verifying emulator and ADB connection.")
        operations.Do("verify_emulator")
        operations.Do("log", "Startup: emulator and ADB connection verified.")
        operations.Do("log", "Startup: validating client-to-ADB calibration.")
        operations.Do("verify_calibration")
        operations.Do("log", "Startup: calibration is valid.")
        if (state.timerMs > 0) {
            operations.Do(
                "log",
                "Startup: starting auto-stop timer for "
                    state.timerMs " ms."
            )
            operations.Do("start_timer", state.timerMs)
        } else {
            operations.Do("log", "Startup: auto-stop timer is disabled.")
        }
        operations.Do(
            "log",
            "Clear tap: sending 3 randomized taps before village detection."
        )
        operations.Do("clear_tap")
        operations.Do("log", "Clear tap complete.")
        operations.Do(
            "log",
            "Startup: restoring the calibrated viewport before village detection."
        )
        operations.Do("reset_main_viewport")

        village := operations.Do("detect_village")
        if (village == "main") {
            operations.Do(
                "log",
                "Startup route: Main Village detected; starting Main flow."
            )
            operations.Do("start_main_loop")
            return village
        }
        if (village == "builder") {
            operations.Do(
                "log",
                "Startup route: Builder Base detected; starting Builder flow."
            )
            operations.Do("start_builder_loop")
            return village
        }
        throw Error("Village detection did not return main or builder.")
    }

    RunMainLoop(operations, state) {
        operations.Do("reset_main_viewport")
        operations.Do("collect_resources", state.collectorCount)
        thresholds := operations.Do("check_resource_thresholds")
        operations.Do(
            "run_builder_upgrade",
            thresholds,
            state.wallUpgradesEnabled
        )
        operations.Do(
            "run_wall_upgrades",
            thresholds,
            state.wallUpgradesEnabled
        )
        operations.Do("run_lab_upgrade", thresholds)
        operations.Do("enter_main_battle")
        minGold := state.HasOwnProp("minGold") ? state.minGold : 500000
        minElixir := state.HasOwnProp("minElixir") ? state.minElixir : 500000
        operations.Do("find_eligible_base", minGold, minElixir)
        operations.Do("attack_main_base")
        operations.Do("return_main_home")
        operations.Do("finish_main_cycle")
    }

    RunCycleCompletion(operations, state) {
        if !IsObject(state) || !state.HasOwnProp("currentVillage")
            throw Error("Cycle completion requires the current village.")
        return ADBGlobalCycleFlow(operations).Complete(
            state.currentVillage
        )
    }

    RunReloadRecovery(operations, state) {
        if (!IsObject(state)
            || !state.HasOwnProp("currentVillage")
            || !state.HasOwnProp("completedAttacks")) {
            throw Error(
                "Reload recovery requires village and completed attacks."
            )
        }
        return ADBGlobalCycleFlow(operations).RunReloadRecovery(
            state.currentVillage,
            state.completedAttacks
        )
    }
}

global ADBRefactorFlowAPI := ADBRefactorFlowController()
