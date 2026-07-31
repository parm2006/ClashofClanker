#Requires AutoHotkey v2.0

global BuilderInfoOCRLogicLoaded := true

NormalizeBuilderInfoOCRText(text) {
    normalized := StrLower(RegExReplace(String(text), "[^A-Za-z|]", ""))
    if (normalized == "|nfo")
        return "lnfo"
    return normalized
}

IsBuilderInfoOCRText(text) {
    normalized := NormalizeBuilderInfoOCRText(text)
    return normalized == "info" || normalized == "lnfo"
}

SelectBuilderInfoOCRWord(words) {
    selected := ""
    for word in words {
        if !IsObject(word) || !word.HasProp("Text")
            continue
        if !IsBuilderInfoOCRText(word.Text)
            continue
        if !word.HasProp("x")
            || !word.HasProp("y")
            || !word.HasProp("w")
            || !word.HasProp("h")
            continue
        if !IsObject(selected) || word.x < selected.x
            selected := word
    }
    if !IsObject(selected)
        return ""
    return {
        text: selected.Text,
        x: selected.x,
        y: selected.y,
        w: selected.w,
        h: selected.h,
        centerX: selected.x + selected.w / 2,
        centerY: selected.y + selected.h / 2
    }
}

SelectFirstSuggestedUpgradeOCRWord(lines) {
    for index, line in lines {
        if !IsObject(line) || !line.HasProp("Text")
            continue
        lineText := StrLower(line.Text)
        hasSuggested := InStr(lineText, "suggested")
            || InStr(lineText, "gested")
            || RegExMatch(lineText, "i)(^|\s)sug\S*")
        if !hasSuggested
            continue

        headerEndIndex := 0
        if InStr(lineText, "upgr") {
            headerEndIndex := index
        } else if (index < lines.Length) {
            nextHeaderText := StrLower(lines[index + 1].Text)
            if InStr(nextHeaderText, "upgr")
                headerEndIndex := index + 1
        }
        if (headerEndIndex == 0 || headerEndIndex >= lines.Length)
            return ""

        targetLine := lines[headerEndIndex + 1]
        if !IsObject(targetLine) || !targetLine.HasProp("Words")
            return ""
        if !targetLine.HasProp("x")
            || !targetLine.HasProp("y")
            || !targetLine.HasProp("w")
            || !targetLine.HasProp("h")
            return ""
        for word in targetLine.Words {
            if !IsObject(word) || !word.HasProp("Text")
                continue
            meaningfulText := RegExReplace(word.Text, "[^A-Za-z0-9]", "")
            if (StrLen(meaningfulText) < 2)
                continue
            if !word.HasProp("x")
                || !word.HasProp("y")
                || !word.HasProp("w")
                || !word.HasProp("h")
                continue
            return {
                text: word.Text,
                lineText: targetLine.Text,
                x: word.x,
                y: word.y,
                w: word.w,
                h: word.h,
                centerX: word.x + word.w / 2,
                centerY: word.y + word.h / 2,
                lineX: targetLine.x,
                lineY: targetLine.y,
                lineW: targetLine.w,
                lineH: targetLine.h
            }
        }
        return ""
    }
    return ""
}

NormalizeBuilderOCRMatch(match, scale) {
    if !IsObject(match)
        return ""
    if !IsNumber(scale) || scale <= 0
        throw Error("OCR coordinate scale must be positive.")
    normalized := {
        text: match.text,
        lineText: match.HasProp("lineText") ? match.lineText : match.text,
        x: match.x / scale,
        y: match.y / scale,
        w: match.w / scale,
        h: match.h / scale,
        centerX: match.centerX / scale,
        centerY: match.centerY / scale
    }
    if match.HasProp("lineX") {
        normalized.lineX := match.lineX / scale
        normalized.lineY := match.lineY / scale
        normalized.lineW := match.lineW / scale
        normalized.lineH := match.lineH / scale
        ; Preserve the original bot's proven first-row click rule.
        normalized.tapX := normalized.lineX + 50
        normalized.tapY := normalized.lineY + normalized.lineH / 2
    } else {
        normalized.tapX := normalized.centerX
        normalized.tapY := normalized.centerY
    }
    return normalized
}
