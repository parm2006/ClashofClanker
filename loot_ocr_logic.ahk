#Requires AutoHotkey v2.0

global LootOCRLogicLoaded := true

SelectLootConsensus(readings) {
    frequencies := Map()
    validReadings := []
    for reading in readings {
        if !IsNumber(reading)
            continue
        value := Number(reading)
        if (value <= 0 || value != Floor(value))
            continue
        roundedValue := Round(value / 1000) * 1000
        validReadings.Push(roundedValue)
        frequencies[roundedValue] := frequencies.Has(roundedValue)
            ? frequencies[roundedValue] + 1
            : 1
    }
    if (validReadings.Length == 0) {
        return {
            valid: false,
            value: 0,
            reason: "no_integer",
            agreement: 0,
            readingCount: 0
        }
    }

    winnerValue := 0
    winnerCount := 0
    for value, count in frequencies {
        if (count > winnerCount
            || (count == winnerCount && value > winnerValue)) {
            winnerValue := value
            winnerCount := count
        }
    }
    tiedModes := 0
    for value, count in frequencies {
        if (count == winnerCount)
            tiedModes += 1
    }
    return {
        valid: true,
        value: winnerValue,
        reason: tiedModes > 1 ? "rounded_tie_highest" : "rounded_mode",
        agreement: winnerCount,
        readingCount: validReadings.Length
    }
}

EvaluateLootAttackDecision(goldResult, elixirResult, minGold, minElixir) {
    if (!goldResult.valid && !elixirResult.valid) {
        return {
            attack: true,
            reason: "both_invalid"
        }
    }
    goldMet := goldResult.valid && goldResult.value >= minGold
    elixirMet := elixirResult.valid && elixirResult.value >= minElixir
    if (goldMet || elixirMet) {
        return {
            attack: true,
            reason: "threshold_met"
        }
    }
    return {
        attack: false,
        reason: "below_threshold"
    }
}
