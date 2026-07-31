#Requires AutoHotkey v2.0

global ResourceThresholdLogicLoaded := true

IsThresholdLightColor(color) {
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF

    ; White and light-neutral number pixels do not participate in the reading.
    ; Saturated Gold and Elixir colors remain eligible because at least one
    ; channel is below this limit.
    highest := Max(r, g, b)
    lowest := Min(r, g, b)
    return lowest >= 90 && highest - lowest <= 45
}

AnalyzeThresholdNeighborhood(colors) {
    redValues := []
    greenValues := []
    blueValues := []
    ignored := 0

    for color in colors {
        if IsThresholdLightColor(color) {
            ignored += 1
            continue
        }
        redValues.Push((color >> 16) & 0xFF)
        greenValues.Push((color >> 8) & 0xFF)
        blueValues.Push(color & 0xFF)
    }

    evaluated := redValues.Length
    if (evaluated == 0) {
        return {
            valid: false,
            color: 0,
            ignored: ignored,
            evaluated: 0,
            total: colors.Length
        }
    }

    r := ThresholdMedianChannel(redValues)
    g := ThresholdMedianChannel(greenValues)
    b := ThresholdMedianChannel(blueValues)
    return {
        valid: true,
        color: (r << 16) | (g << 8) | b,
        ignored: ignored,
        evaluated: evaluated,
        total: colors.Length
    }
}

ThresholdMedianChannel(values) {
    ordered := values.Clone()
    index := 2
    while (index <= ordered.Length) {
        value := ordered[index]
        insertAt := index
        while (insertAt > 1 && ordered[insertAt - 1] > value) {
            ordered[insertAt] := ordered[insertAt - 1]
            insertAt -= 1
        }
        ordered[insertAt] := value
        index += 1
    }

    middle := Floor((ordered.Length + 1) / 2)
    if Mod(ordered.Length, 2)
        return ordered[middle]
    return Round((ordered[middle] + ordered[middle + 1]) / 2)
}
