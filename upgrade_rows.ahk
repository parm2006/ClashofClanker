#Include "upgrade_row_logic.ahk"

OpenUpgradeDrawer(kind) {
    global BuilderFaceX, BuilderFaceY
    if kind != "builder" && kind != "lab"
        throw Error("Unknown upgrade drawer: " kind)
    x := BuilderFaceX
    y := BuilderFaceY
    LogMessage("Opening " kind " drawer through calibrated badge at (" x ", " y ").")
    if !RunADBTapAt(x, y, 200) || !SafeFlowWait(800)
        throw Error("Could not open the " kind " upgrade drawer.")
    if kind == "lab" {
        viewport := GetADBClientViewportRect()
        ; Laboratory is the second of the four tabs along the drawer bottom.
        tabX := viewport.x + viewport.width * (0.67 + 0.32 * 0.375)
        tabY := viewport.y + viewport.height * 0.94
        LogMessage("Selecting Laboratory drawer tab before upgrade OCR.")
        if !RunADBTapAt(tabX, tabY, 200) || !SafeFlowWait(800)
            throw Error("Could not select the Laboratory drawer tab.")
    }
    return true
}

FindUpgradeRow(kind, selectCandidate := false, allowScroll := false) {
    viewport := GetADBClientViewportRect()
    ; The drawer occupies the right third; exclude its title and bottom tabs.
    x := viewport.x + viewport.width * 0.67
    y := viewport.y + viewport.height * 0.08
    w := viewport.width * 0.32 * 0.80
    h := viewport.height * 0.80
    continued := false
    Loop 2 {
        attempt := A_Index
        path := A_ScriptDir "\scratch\upgrade_" kind "_rows.png"
        crop := SaveADBFrameRegionToPNG(CaptureADBFrame(true), x, y, w, h, path)
        contrastPath := A_ScriptDir "\scratch\upgrade_" kind "_rows_contrast.png"
        if FileExist(contrastPath)
            FileDelete(contrastPath)
        output := RunWaitPythonScript('upgrade_contrast "' path '" 0')
        if !InStr(output, "SUCCESS:") || !FileExist(contrastPath)
            throw Error("Upgrade rows contrast preprocessing failed: " output)
        selected := {found: false, heroes: 0, section: false}
        best := false
        passes := [], heroRows := [], sectionTop := -1
        for source in [{name: "contrast", path: contrastPath}, {name: "text", path: StrReplace(path, ".png", "_text.png")}] {
          for scale in [1.0, 1.5] {
            result := OCR.FromFile(source.path, {lang: "en-US", scale: scale})
            LogMessage("Upgrade rows " kind " OCR " source.name " " scale "x: " StrReplace(result.Text, "`n", " | "))
            passes.Push({scale: scale, lines: result.Lines})
            top := UpgradeSectionTop(result.Lines, scale)
            if top >= 0 && (sectionTop < 0 || top > sectionTop)
                sectionTop := top
            if kind == "builder" {
                for line in result.Lines {
                    if IsUpgradeHero(line.Text)
                        heroRows.Push({y: (line.y + line.h / 2) / scale, height: line.h / scale})
                }
            }
          }
        }
        LogMessage("Upgrade rows: combining contrast/text at 1x and 1.5x; hero row observations=" heroRows.Length ".")
        for pass in passes {
            scale := pass.scale
            candidate := SelectUpgradeRow(pass.lines, kind, continued, scale, heroRows, sectionTop)
            if candidate.found {
                point := ADBFramePointToClient(crop, candidate.x / scale, candidate.y / scale)
                bottom := ADBFramePointToClient(crop, candidate.x / scale, candidate.y / scale + candidate.height)
                LogMessage("Upgrade rows " kind " candidate at " scale "x: '" candidate.name "', y=" Round(point.y) ".")
                next := {name: candidate.name, x: point.x, y: point.y, heroes: candidate.heroes, scale: scale,
                    height: Abs(bottom.y - point.y)}
                if PreferUpgradeCandidate(next, best)
                    best := next
            }
            if candidate.heroes > selected.heroes
                selected := candidate
        }
        if IsObject(best) {
            LogMessage("Upgrade rows " kind ": selected '" best.name "' from " best.scale "x after all scales, skipped " best.heroes " heroes.")
            if selectCandidate && !RunADBTapAt(best.x, best.y, 200)
                throw Error("Candidate tap failed.")
            return {name: best.name, x: best.x, y: best.y, tapped: selectCandidate}
        }
        ; Manual reads never scroll. Automated selection gets at most one swipe,
        ; only after positively recognizing the section and excluded heroes.
        if !(selectCandidate || allowScroll) || attempt == 2 || !selected.section || selected.heroes == 0 {
            LogMessage("No eligible upgrade row read. Diagnostic: " path)
            return ""
        }
        LogMessage("Upgrade rows: visible candidates were heroes; swiping up once.")
        if !RunADBSwipeAt(x + w * 0.5, y + h * 0.88, x + w * 0.5, y + h * 0.30, 450)
            throw Error("Upgrade-list swipe failed.")
        if !SafeFlowWait(800)
            throw Error("Stopped during upgrade-list scroll.")
        continued := true
    }
}
