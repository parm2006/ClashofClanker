#Requires AutoHotkey v2.0
#Warn All, StdOut
#Include "..\upgrade_row_logic.ahk"
Row(text, y) => {Text: text, x: 10, y: y, w: 200, h: 20}
Check(value, message) {
    if !value
        throw Error(message)
}
try {
    rows := [Row("Laboratory", 10), Row("Suggested upgrades", 50),
        Row("Barbarian King", 80), Row("245 000", 100), Row("Grand Warden", 130),
        Row("Builder's Hut x 5", 180), Row("Other upgrades", 230), Row("Monolith", 270)]
    picked := SelectUpgradeRow(rows, "builder")
    Check(picked.found && picked.name == "Builder's Hut x 5" && picked.heroes == 2, "Skip heroes and ongoing upgrades")
    Check(SelectUpgradeRow(rows, "lab").name == "Barbarian King", "Lab has no hero filter")
    Check(SelectUpgradeRow([Row("Other upgrades", 10), Row("Monolith", 50)], "builder").name == "Monolith", "Other upgrades allowed")
    for hero in ["Barbarian King", "Archer Queen", "Minion Prince", "Grand Warden", "Dragon Duke", "Royal Champion"]
        Check(!SelectUpgradeRow([Row("Suggested upgrades", 0), Row(hero, 40)], "builder").found, "Hero excluded: " hero)
    Check(!SelectUpgradeRow([Row("Elixir Storage", 20)], "builder").found, "Missing section must not select ongoing rows")
    Check(SelectUpgradeRow([Row("Monolith", 20)], "builder", true).found, "Continue after scroll without heading")
    Check(SelectUpgradeRow([Row("Builders Hut x 5", 20), Row("Other upgrades", 80), Row("Monolith", 120)], "builder").name == "Builders Hut x 5", "Rows above Other remain eligible after manual scroll")
    Check(SelectUpgradeRow([Row("Builders Hut x 5", 20)], "builder", false, 1, [], 0).found, "Heading evidence shared from another OCR pass")
    Check(SelectUpgradeRow([Row("Other upgrades", 0), Row("Monolith", 120), Row("Builders Hut x 5", 40)], "builder").name == "Builders Hut x 5", "Pick by vertical position, not OCR output order")
    Check(!PreferUpgradeCandidate({y: 99, height: 20, scale: 1.5}, {y: 100, height: 20, scale: 1}), "One pixel jitter must preserve 1x")
    Check(PreferUpgradeCandidate({y: 40, height: 20, scale: 1.5}, {y: 100, height: 20, scale: 1}), "Earlier distinct row must win")
    for text in ["BaebaRiaN Kiæg", "Baebaniaufiæg", "IBaRbaRiaN,Kiæg", "GnaNd'WaRdeN", "Qargd'WaRdeN",
        "ARCHeR Queeæ", "noyal'CHaMpi0N", "Dnag0N Duke", "Miüi0N DRiæce"] {
        matched := IsUpgradeHero(text)
        FileAppend("OCR hero: " text " => " (matched ? "SKIP" : "MISS") "`n", "*")
        Check(matched, "Garbled hero must be skipped: " text)
    }
    for text in ["Builder's Hut x 5", "buitde*s; Hut x", "Army Camp", "ARMVdtCaMpJY", "Dark Elixir Storage",
        "Longshot", "Smasher", "Logger", "Super Wizard Tower", "Monolith", "Clan Castle", "Pet House",
        "Elixir Storage", "Air Defense", "Hidden Tesla", "Mortar", "Bomb Tower", "Giga Bomb", "Seeking Air Mine",
        "X Bow", "Inferno Tower", "Spell Tower", "Archer Tower", "Wizard Tower", "Dragon Statue"] {
        matched := IsUpgradeHero(text)
        FileAppend("Building: " text " => " (matched ? "FALSE HERO" : "ALLOW") "`n", "*")
        Check(!matched, "Building must not be mistaken for hero: " text)
    }
    noisy := [Row("Suggested upgrades", 0), Row("Baebaniaufiæg", 40), Row("GnaNd'WaRdeN", 80), Row("buitde*s; Hut x", 120)]
    Check(SelectUpgradeRow(noisy, "builder").name == "buitde*s; Hut x", "Real OCR errors must select Hut after skipping both heroes")
    headings := [Row("Suggested upgRades", 0), Row("Baebaniaufiæg", 40), Row("GnaNd'WaRdeN", 80),
        Row("0tHeR upgRades", 120), Row("MoæolitH", 160)]
    Check(SelectUpgradeRow(headings, "builder").name == "MoæolitH", "Other heading with zero must never be selected")
    Check(!SelectUpgradeRow([Row("0tHeR upgRades", 0)], "builder").found, "Heading alone is not a candidate")
    Check(SelectUpgradeRow([Row("0tHeR upgRades", 0), Row("Bat Spell", 40)], "lab").name == "Bat Spell", "Lab also recognizes garbled Other heading")
    Check(SelectUpgradeRow([Row("Other upgrades", 0), Row("Süp@R", 40), Row("Monolith", 80)], "builder").name == "Süp@R", "Short stripped text remains eligible")
    Check(SelectUpgradeRow([Row("Other upgrades", 0), Row("塔", 40)], "builder").name == "塔", "Non-English OCR text remains eligible")
    blocked := [{y: 50, height: 10}]
    split := [Row("Suggested upgrades", 0), Row("Kieug•", 90), Row("24 oo", 160), Row("Builder's Hut", 230)]
    Check(SelectUpgradeRow(split, "builder", false, 2, blocked).name == "Builder's Hut", "Hero recognized at another scale vetoes partial King; prices excluded")
    Check(SelectUpgradeRow(split, "lab", false, 2, blocked).name == "Kieug•", "Cross-scale hero veto does not apply to lab")
    FileAppend("PASS: upgrade row selection, hero exclusions, section gating and scroll continuation.`n", "*")
    ExitApp(0)
} catch as err {
    FileAppend("FAIL: " err.Message "`n", "*")
    ExitApp(1)
}
