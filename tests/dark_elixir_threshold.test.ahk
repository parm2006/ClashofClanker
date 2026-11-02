#Requires AutoHotkey v2.0
#Warn All, StdOut
#Include "..\resource_threshold_logic.ahk"
try {
    for testColor in [0x76657E, 0x705F78, 0x270D33, 0x290F35] {
        Assert(IsDarkElixirThresholdColor(testColor), "Captured filled-bar shades must match")
        Assert(!IsThresholdLightColor(testColor), "Filled Dark Elixir must survive filtering")
    }
    for testColor in [0x72726C, 0x767676, 0xFFFFFF, 0xFDFDFD, 0x0D0D0D, 0x000000, 0xF2D965, 0xD976D9]
        Assert(!IsDarkElixirThresholdColor(testColor), "Gray/white/black borders and other resources must not match")
    samples := []
    Loop 49
        samples.Push(0x76657E)
    analysis := AnalyzeThresholdNeighborhood(samples)
    Assert(analysis.valid && analysis.evaluated == 49 && analysis.ignored == 0, "Original 49/49-discarded case must now retain every purple sample")
    Assert(IsDarkElixirThresholdColor(analysis.color), "Original failed sample must now produce YES")
    mixed := AnalyzeThresholdNeighborhood([0xFFFFFF, 0xFDFDFD, 0x76657E, 0x76657E, 0x705F78])
    Assert(mixed.ignored == 2 && IsDarkElixirThresholdColor(mixed.color), "White text must not hide filled fluid")
    empty := AnalyzeThresholdNeighborhood([0x72726C, 0x767676, 0xFFFFFF])
    Assert(!empty.valid, "Empty/light samples must remain NO, without treating fallback zero as fluid")
    FileAppend("PASS: static Dark Elixir swatches match; empty bar/text/borders rejected; purple samples retained.`n", "*")
    ExitApp(0)
} catch as testFailure {
    FileAppend("FAIL: " testFailure.Message "`n", "*")
    ExitApp(1)
}
Assert(condition, message) {
    if !condition
        throw Error(message)
}
