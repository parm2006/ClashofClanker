# Plan 005: Prove the Builder Info OCR detector in isolation

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving on. If
> anything in "STOP conditions" occurs, stop and write a handback—do not
> improvise. When done, update this plan's status row in the effort README.
>
> **Drift check (run first)**:
> `git -c safe.directory=C:/Users/parth/Projects/coc diff 26544a48ab31ba1bac71c2687a9262f53d197307 -- builder_info_ocr_logic.ahk test_builder_info_ocr.ahk test_adb_refactor_interactions.ahk`
> If these files changed after this plan was written, compare the current-state
> notes with the live code. Treat a conflicting change as a STOP condition.

## Status

- **Effort**: M
- **Risk**: MED
- **Depends on**: 003-align-main-and-builder-loops-to-flow.md
- **Planned at**: revision `26544a48ab31ba1bac71c2687a9262f53d197307`, 2026-07-27

## Why this matters

The refactor bot taps the calibrated confirmation point immediately after it
selects a suggested building. The game first shows a variable-width horizontal
action row. The stable first action is Info. A separately testable detector
must prove that it can find the Info word before the live bot sends any new
input.

## Current state

- `ADBcocbotrefactor_support.ahk:469-485` selects a builder suggestion and then
  calls `tap_upgrade_confirm`; it has no intermediate Info operation.
- `ADBcocbotrefactor.ahk:2748` implements `FindFlowSuggestedUpgrade`, the
  closest example of multi-scale OCR that returns client coordinates.
- `ADBcocbotrefactor.ahk:2643` implements `SaveADBFrameRegionToPNG`, the ADB
  frame-cropping pattern production will use later.
- `test_loot_ocr.ahk:386` and `test_storage_thresholds.ahk:668` are the recent
  visual-debugger exemplars.
- `OCR.ahk:71-94` exposes OCR lines, words, and word bounding rectangles.
- `test_adb_refactor_interactions.ahk:81` provides the terminating contract-test
  harness.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Run contract tests | `& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' /ErrorStdOut .\test_adb_refactor_interactions.ahk` | result file ends with `0 failed` |
| Run inspector self-check | `& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' /ErrorStdOut .\test_builder_info_ocr.ahk --self-check` | exits 0 without tapping |
| Run live inspector | `& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' /ErrorStdOut .\test_builder_info_ocr.ahk` | GUI opens; F1 performs one detection-only cycle |
| Check forbidden inputs | `rg -n 'RunADBTapAt|ADBClickPoint|ClientClickPoint|input tap|shell tap' builder_info_ocr_logic.ahk test_builder_info_ocr.ahk` | no matches |

## Scope

**In scope**:

- `builder_info_ocr_logic.ahk`
- `test_builder_info_ocr.ahk`
- `test_adb_refactor_interactions.ahk`

**Out of scope**:

- `ADBcocbotrefactor.ahk` and `ADBcocbotrefactor_support.ahk`—production waits
  for live visual approval.
- `ADBcoc_bot.ahk`—protected rollback reference.
- `scratch/`—final test scripts move there only after the revamp is complete.
- Lab, wall, battle, and Builder Base flows.

## Steps

### Step 1: Add failing detector and visual-inspector contracts

Add contract tests that require a shared Info OCR selector and visual
inspector. Test pure word-selection behavior with synthetic OCR word objects:
accept case-insensitive `Info`; accept `lnfo`; reject unrelated words; choose
the leftmost match; return the word center; return no match for an empty list.

Add source contracts requiring one fresh ADB frame, a bottom-35-percent crop,
multi-scale OCR from that one crop, client-coordinate translation, green/red
markers, editable crop controls, a bold verdict, Consolas diagnostics, and a
`--self-check` path. Forbid every tap API.

**Verify**: run contract tests → the new cases fail because the selector and
inspector do not exist.

### Step 2: Implement the shared OCR selector

Create `builder_info_ocr_logic.ahk`. Keep it input-free. It normalizes candidate
text, accepts only the approved variants, chooses the leftmost match, and
returns the word bounds and center. Follow the shared-logic style in
`resource_threshold_logic.ahk`.

The selector must not capture a frame, manipulate a window, convert coordinate
spaces, or tap.

**Verify**: run contract tests → the selector cases pass; the visual-inspector
contract remains red.

### Step 3: Build the detection-only visual inspector

Create `test_builder_info_ocr.ahk` following `test_loot_ocr.ahk` and
`test_storage_thresholds.ahk`.

One F1 cycle reloads configuration, validates mapping, captures one fresh ADB
frame, crops the bottom action bar (default bottom 35 percent), runs all OCR
scales against that saved crop, selects Info with the shared logic, translates
the word center from crop-local ADB coordinates to client coordinates, and
draws a green match rectangle or red search rectangle. Log every scale, raw
OCR text, candidate bounds, selected text, ADB point, client point, and verdict.

The GUI exposes editable X/Y/W/H crop controls, Reload Config, Save Config,
Inspect Once (F1), live monitoring, clear-console, and always-on-top controls.
It never taps.

**Verify**: self-check exits 0; contract tests end with `0 failed`; the
forbidden-input check has no matches.

### Step 4: Stop for the user's live validation

Give the user the live-inspector command. Ask them to select buildings that
produce two-button, three-button, and many-button action rows. For each layout,
F1 must put a green box around Info and report a client point in the lower half
of the first button.

Do not start Plan 006 from a self-check alone.

**Verify**: the user explicitly confirms live detection works.

## Test plan

- Synthetic tests cover variants, rejection, leftmost selection, empty input,
  and word-center calculation.
- Self-check covers config, crop bounds, scale reuse, coordinate conversion,
  and marker selection without a live game.
- Live validation covers the variable layouts that motivated the feature.

## Done criteria

- [ ] Contract tests end with `0 failed`.
- [ ] Inspector self-check exits 0.
- [ ] Forbidden-input scan has no matches.
- [ ] One F1 cycle uses one fresh ADB capture.
- [ ] The user confirms every tested layout highlights Info.
- [ ] Nothing moves to `scratch/`.

## STOP conditions

Stop if OCR cannot distinguish Info from other lower-bar text, the bottom 35
percent excludes a supplied layout, conversion requires saved ADB coordinates,
or the inspector needs a gameplay tap. Stop on any red or misplaced live
marker. Write a handback with the crop, OCR output, candidates, and conversion.

## Maintenance notes

Keep the selector input-free so the visual inspector and live flow use the same
match policy. Production integration belongs to Plan 006 after live approval.
