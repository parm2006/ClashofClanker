; Shared upgrade-row selection for the production bot and visualizer.
UpgradeRowName(text) {
    return StrLower(RegExReplace(text, "[^A-Za-z]", ""))
}

UpgradeNameSimilarity(left, right) {
    previous := []
    Loop StrLen(right) + 1
        previous.Push(A_Index - 1)
    Loop StrLen(left) {
        i := A_Index
        current := [i]
        Loop StrLen(right) {
            j := A_Index
            cost := SubStr(left, i, 1) == SubStr(right, j, 1) ? 0 : 1
            current.Push(Min(current[j] + 1, previous[j + 1] + 1, previous[j] + cost))
        }
        previous := current
    }
    return 1 - previous[previous.Length] / Max(1, StrLen(left), StrLen(right))
}

IsUpgradeHero(text) {
    name := UpgradeRowName(text)
    for hero in ["Barbarian King", "Archer Queen", "Minion Prince", "Grand Warden", "Grand Wardon", "Dragon Duke", "Royal Champion"] {
        if InStr(name, UpgradeRowName(hero))
            return true
        ; Archer Tower shares "Archer" with Queen, so require a closer match.
        cutoff := hero == "Archer Queen" ? 0.72 : 0.60
        if UpgradeNameSimilarity(name, UpgradeRowName(hero)) >= cutoff
            return true
    }
    return false
}

IsUpgradeHeading(text) {
    ; OCR commonly substitutes zero for the O in Other.
    name := UpgradeRowName(StrReplace(text, "0", "o"))
    for heading in ["suggestedupgrades", "otherupgrades"] {
        if InStr(name, heading) || UpgradeNameSimilarity(name, heading) >= 0.80
            return true
    }
    return false
}

IsBlockedHeroRow(line, scale, heroRows) {
    ; OCR.FromFile scales twice internally and normalizes once; lines still need /scale.
    centerY := (line.y + line.h / 2) / scale
    for row in heroRows {
        if Abs(centerY - row.y) <= Max(line.h / scale, row.height) * 2
            return true
    }
    return false
}

UpgradeSectionTop(lines, scale := 1) {
    other := false
    for line in lines {
        if !IsUpgradeHeading(line.Text)
            continue
        name := UpgradeRowName(StrReplace(line.Text, "0", "o"))
        if UpgradeNameSimilarity(name, "suggestedupgrades") > UpgradeNameSimilarity(name, "otherupgrades")
            return line.y / scale
        other := true
    }
    ; With Suggested scrolled out, rows above Other are still upgrade candidates.
    return other ? 0 : -1
}

PreferUpgradeCandidate(candidate, best) {
    if !IsObject(best)
        return true
    tolerance := Max(candidate.height, best.height) / 2
    if Abs(candidate.y - best.y) <= tolerance
        return candidate.scale < best.scale
    return candidate.y < best.y
}

SelectUpgradeRow(lines, kind, continued := false, scale := 1, heroRows := false, sectionTop := -1) {
    if sectionTop < 0
        sectionTop := UpgradeSectionTop(lines, scale)
    inSection := continued || sectionTop >= 0
    heroes := 0
    best := false
    for line in lines {
        name := UpgradeRowName(line.Text)
        if IsUpgradeHeading(line.Text) {
            inSection := true
            continue
        }
        if !inSection || (!continued && line.y / scale < sectionTop) || Trim(line.Text) == ""
            continue
        ; Price/time lines and the green New sublabel are not row names.
        if RegExMatch(line.Text, "i)^\s*\d[\d\W]*(?:[dhms]\b|$)")
            || RegExMatch(line.Text, "i)^\s*[\d\s.,'o]+\s*$") || name == "new"
            continue
        if kind == "builder" && (IsUpgradeHero(line.Text)
            || (IsObject(heroRows) && IsBlockedHeroRow(line, scale, heroRows))) {
            heroes += 1
            continue
        }
        if !IsObject(best) || line.y < best.y - line.h / 2
            best := {found: true, name: line.Text, x: line.x + line.w / 2,
                y: line.y + line.h / 2, height: line.h / scale, heroes: heroes}
    }
    if IsObject(best)
        return best
    return {found: false, heroes: heroes, section: inSection}
}


