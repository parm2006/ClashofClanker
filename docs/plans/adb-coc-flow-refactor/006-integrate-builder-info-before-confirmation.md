# Plan 006: Require Builder Info before upgrade confirmation

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving on. If
> anything in "STOP conditions" occurs, stop and write a handback—do not
> improvise. When done, update this plan's status row in the effort README.
>
> **Drift check (run first)**:
> `git -c safe.directory=C:/Users/parth/Projects/coc diff 26544a48ab31ba1bac71c2687a9262f53d197307 -- ADBcocbotrefactor.ahk ADBcocbotrefactor_support.ahk builder_info_ocr_logic.ahk test_adb_refactor_flow.ahk test_adb_refactor_interactions.ahk`
> If in-scope code changed after planning, reconcile the current-state excerpts
> before proceeding. Treat a flow-order conflict as a STOP condition.

## Status

- **Effort**: M
- **Risk**: HIGH
- **Depends on**: 005-prove-builder-info-ocr-detector.md plus explicit user
  confirmation of the live visual test
- **Planned at**: revision `26544a48ab31ba1bac71c2687a9262f53d197307`, 2026-07-27

## Why this matters

The live builder operation currently taps confirmation while the game still
shows the building action bar. This misses the required transition and can tap
an unrelated screen location. The flow must find and tap Info once, then reach
the calibrated confirmation screen. A failed Info detection must skip safely.

## Current state

- `ADBcocbotrefactor_support.ahk:469-485` orders builder suggestion selection
  directly before `tap_upgrade_confirm`.
- `ADBcocbotrefactor.ahk:3137-3178` dispatches live flow primitives.
- `ADBcocbotrefactor.ahk:3221` captures fresh section-bound ADB frames.
- `ADBcocbotrefactor.ahk:3363-3375` shows the client-coordinate
  `RunADBTapAt` pattern for suggestion and confirmation taps.
- `ADBcocbotrefactor.ahk:2643` crops a supplied frame without recapturing.
- `test_adb_refactor_flow.ahk:13-43` provides queued fake operations and an
  ordered operation log.
- Plan 005 supplies the approved shared selector.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Run flow tests | `& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' /ErrorStdOut .\test_adb_refactor_flow.ahk` | result file ends with `0 failed` |
| Run interaction tests | `& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' /ErrorStdOut .\test_adb_refactor_interactions.ahk` | result file ends with `0 failed` |
| Load-check refactor | create a temporary wrapper that schedules `ExitApp()` and includes `ADBcocbotrefactor.ahk`; run with `/ErrorStdOut`; remove it afterward | exits 0 with no warning |
| Check protected original | `git -c safe.directory=C:/Users/parth/Projects/coc diff --exit-code -- ADBcoc_bot.ahk` | exits 0 |

## Scope

**In scope**:

- `ADBcocbotrefactor.ahk`
- `ADBcocbotrefactor_support.ahk`
- `builder_info_ocr_logic.ahk`
- `test_adb_refactor_flow.ahk`
- `test_adb_refactor_interactions.ahk`

**Out of scope**:

- `ADBcoc_bot.ahk`—protected rollback reference.
- `test_builder_info_ocr.ahk`—Plan 005 owns the approved inspector.
- `scratch/`—deferred until the revamp is complete.
- Lab upgrades—the requested transition is builder-specific.
- Builder Base, walls, battles, and legacy cleanup.

## Steps

### Step 1: Add failing builder-flow sequence tests

Add an eligible success case to `test_adb_refactor_flow.ahk` requiring:

`open_builder_menu → ocr_builder_suggestion → tap_builder_suggestion → capture builder_info frame → detect Info → tap Info → tap_upgrade_confirm → clear_tap`

Add a no-match case. It makes one Info detection attempt, logs the skip, clears
the selection, returns `false`, and never calls `tap_upgrade_confirm`.

Add interaction contracts requiring the shared selector include, lower-bar crop
from the supplied frame, client-coordinate result, and randomized tap boundary.

**Verify**: both suites fail because production Info operations do not exist.

### Step 2: Add live detection and tap primitives

In `ADBcocbotrefactor.ahk`, include the approved selector before flow support.
Add a detection operation that receives the fresh `builder_info` frame, crops
its bottom 35 percent with `SaveADBFrameRegionToPNG`, runs all OCR scales on
that one crop, selects Info with the shared logic, converts the word center
with `ADBFramePointToClient`, and returns a client-coordinate match or no match.

Add a separate tap operation that accepts only the structured client point,
calls `RunADBTapAt`, and performs the flow-aware settle wait. Keep detection
free of input and tapping free of OCR.

**Verify**: interaction tests pass the new live-operation contracts.

### Step 3: Insert Info into the builder operation

In `ADBcocbotrefactor_support.ahk::RunBuilderUpgrade`, after
`tap_builder_suggestion`:

1. capture one fresh `builder_info` decision frame;
2. call the Info detector;
3. on no match, log the single-attempt skip, clear, and return `false`;
4. log accepted text and client point;
5. call the randomized Info tap operation;
6. only then call `tap_upgrade_confirm`;
7. preserve the final three-tap clear.

Do not add a retry or confirmation fallback.

**Verify**: flow tests pass both success and no-match sequences.

### Step 4: Run regression and hand off the live bot

Run both suites, the refactor load check, and original-file check. Give the user
the normal bot command and identify new Info capture, match, tap, skip, and
confirmation log lines.

**Verify**: both result files end with `0 failed`; load and original checks
exit 0.

## Test plan

- Success proves Info occurs between suggestion and confirmation.
- Failure proves one attempt, clear, false return, and no confirmation.
- Interaction contracts prove one supplied frame, shared selector use,
  client conversion, and randomized tap abstraction.
- Existing threshold, loot, clear-tap, lab-condition, and battle tests stay
  green.

## Done criteria

- [ ] The live visual detector has explicit user approval.
- [ ] Flow and interaction suites end with `0 failed`.
- [ ] Info precedes confirmation on success.
- [ ] No-match makes one attempt, clears, skips, and never confirms.
- [ ] Every gameplay tap uses `RunADBTapAt`.
- [ ] `ADBcoc_bot.ahk` has no diff.

## STOP conditions

Stop if Plan 005 lacks live approval, Info does not lead to the calibrated
confirmation screen, a hero needs a different transition, the frame cannot use
a `builder_info` section, or a test requires a raw/pretranslated ADB tap. Write
a handback describing the screen, operation log, and unresolved fork.

## Maintenance notes

Keep Info OCR builder-specific. Do not reuse it for lab upgrades or heroes
without separate examples and approval. Preserve the one-attempt failure rule.
