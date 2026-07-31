# Plan 008: Route production Builder Base attacks through the proven flow

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving on.
> If anything in "STOP conditions" occurs, stop and write a handback —
> do not improvise. When done, update this plan's status row in the
> effort README.
>
> **Drift check (run first)**:
> `git diff 9d500a2 -- ADBcocbotrefactor.ahk builder_base_loop_logic.ahk test_adb_refactor_interactions.ahk`
> If in-scope files have changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Status**: DONE
- **Effort**: M
- **Risk**: HIGH
- **Depends on**: 003-align-main-and-builder-loops-to-flow.md
- **Planned at**: revision `9d500a2`, 2026-07-30

## Why this matters

The tested `BuilderBaseFlow` already owns the approved attack state machine,
but production still runs an older inline timer loop. That legacy loop checks
only one star, mixes cached and fresh frames, and uses different Return Home
timing. This plan makes production call the proven four-check flow through a
dedicated live adapter, so the visual harness and runtime share one
orchestration implementation.

The approved execution amendment is authoritative over the older design spec:
stage one attempts Return Home after every **fourth** completed star analysis,
not every fifth.

## Current state

- `builder_base_loop_logic.ahk:3-145` defines `BuilderBaseFlow`. Its
  `MonitorStageOne()` synchronously captures and analyzes one frame at a time,
  attempts Return Home after four completed analyses, performs a distinct
  fresh home capture, resets to `0/4` when not home, and returns
  `three_stars` only when all three calibrated star samples match.
- `ADBcocbotrefactor.ahk:4183-4338` still defines the legacy
  `RunBuilderBaseLoop()`. It uses elapsed-time polling, calls
  `IsGolden(BBStar3X, BBStar3Y)` for only star 3, and contains independent
  phase-transition behavior.
- `test_builder_base_loop_visual.ahk:128-160` is the live-adapter exemplar.
  `BuilderBaseHarnessPrimitives.Do()` maps isolated operation names to live
  ADB actions without putting orchestration in the adapter.
- `test_builder_base_loop_visual.ahk:592-690` is the proven raw-frame star
  detector. It opens one ADB PNG bitmap, translates the three stored client
  coordinates through the shared mapping, samples all three neighborhoods,
  and requires all three to be gold.
- `ADBcocbotrefactor.ahk:808-827` is the fresh-frame home-detector exemplar.
  `DetectVillageFromADBFrame()` classifies a supplied frame without requesting
  a second screenshot.
- `test_adb_refactor_interactions.ahk:322-561` already proves the abstract
  four-check, fresh-home-frame, same-side stage-two, retry, and stop behavior.

Coordinate translation must continue using the shared mapping:
`ConfigureADBClientMapping()` computes
`adbHeight / (viewportBottom - viewportTop)`, and
`TranslateClientPointToADB()` subtracts `viewportTop` before scaling. Do not
add another title-bar offset in Builder Base code.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Interaction tests | `& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' '.\test_adb_refactor_interactions.ahk'` | `%TEMP%\adb_refactor_interactions_result.txt` ends with `0 failed` |
| Flow tests | `& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' '.\test_adb_refactor_flow.ahk'` | `%TEMP%\adb_refactor_flow_result.txt` ends with `0 failed` |
| Production syntax | `& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' /ErrorStdOut /Validate '.\ADBcocbotrefactor.ahk'` | exit 0 |

## Scope

**In scope** (the only source files you should modify):

- `ADBcocbotrefactor.ahk`
- `test_adb_refactor_interactions.ahk`
- `docs/plans/adb-coc-flow-refactor/008-integrate-builder-base-attack-flow.md`
- `docs/plans/adb-coc-flow-refactor/README.md`

`builder_base_loop_logic.ahk` is expected to remain unchanged because its
approved state machine is already proven. Modify it only if a new failing
contract test exposes a genuine orchestration defect; treat that as a design
fork and STOP first.

**Out of scope**:

- `ADBcoc_bot.ahk` — protected rollback reference; never modify.
- `test_builder_base_loop_visual.ahk` — the approved live behavior exemplar,
  not production.
- `test_builder_base_stars_visual.ahk` — diagnostic GUI and marker rendering
  do not belong in runtime.
- Shared viewport scale formulas — the calibrated top/left subtraction and
  `(bottom-top)` ratio already exist.
- New Builder Base features outside the attack call.

## Steps

### Step 1: Add a failing production-integration contract

Extend `test_adb_refactor_interactions.ahk` with a focused test that inspects
`ADBcocbotrefactor.ahk` and proves:

- production includes `builder_base_loop_logic.ahk`;
- `RunBuilderBaseLoop()` constructs `BuilderBaseFlow` with a dedicated live
  primitives adapter and calls `RunLoop()`;
- the adapter implements every operation consumed by `BuilderBaseFlow`;
- star analysis uses one supplied raw ADB frame and all three `BBStar` client
  points;
- each star point enters the shared `ClientToADBPoint()` boundary exactly once;
- Builder Base home detection consumes the supplied post-Return-Home frame;
- the production `RunBuilderBaseLoop()` function no longer contains the legacy
  elapsed-time loops, the one-star `IsGolden(BBStar3X, BBStar3Y)` shortcut, or
  the 130-second fallback transition.

Run the interaction suite and observe this new test fail because production is
still wired to the legacy loop.

**Verify**: interaction command → the new integration test fails for the
missing live adapter or legacy `RunBuilderBaseLoop()` body.

### Step 2: Add the dedicated production primitives adapter

In `ADBcocbotrefactor.ahk`, include `builder_base_loop_logic.ahk` beside the
other refactor modules and add a `LiveBuilderBasePrimitives` class matching the
operation boundary demonstrated by `BuilderBaseHarnessPrimitives`.

The adapter must:

- reset per-attack deployment logging state when tapping Builder Base Attack;
- route calibrated taps through `RunADBTapAt()`/the shared interaction
  boundary;
- route waits through `SafeSleep()` so stop and pause remain authoritative;
- prepare the Builder Base viewport through the existing calibrated pinch
  boundary;
- choose a side index and deploy `Q12345678` through existing deployment
  helpers;
- request exactly one forced fresh ADB frame for each
  `capture_builder_frame` operation and return section/path metadata;
- analyze all three calibrated star neighborhoods from that supplied frame,
  using one opened bitmap and the proven gold rule;
- classify Builder Base home from the supplied fresh frame via
  `DetectVillageFromADBFrame(framePath) == "builder"`;
- log through `LogMessage()` and expose `IsBBRunning` for stop checks.

Keep orchestration, counters, phase transitions, and Return Home cadence out of
the adapter.

**Verify**: production syntax command → exit 0.

### Step 3: Replace the legacy production loop body

Replace only the internals of `RunBuilderBaseLoop()` with lifecycle setup,
`BuilderBaseFlow(LiveBuilderBasePrimitives()).RunLoop()`, actionable error
logging, and the existing final UI/run-state cleanup.

The wrapper must not add another attack loop around `RunLoop()` because
`BuilderBaseFlow.RunLoop()` already owns repetition. It must not retain the
legacy timeout transition, cached home checks, popup-click loop, or star-3-only
shortcut.

**Verify**: interaction command → all tests pass and the new production
integration contract passes.

### Step 4: Verify the complete refactor boundary

Run syntax validation and both automated suites. Confirm that the protected
legacy bot remains unstaged/unmodified by this plan.

Update this plan and the effort README status to `DONE` only after every check
passes.

**Verify**:

- production syntax command → exit 0;
- interaction suite → all pass, `0 failed`;
- flow suite → all pass, `0 failed`;
- `git diff --name-only -- ADBcoc_bot.ahk` shows no change introduced by this
  plan.

## Test plan

- Add one production-source contract test in
  `test_adb_refactor_interactions.ahk`.
- Reuse the existing deterministic flow tests for:
  - four completed star checks before Return Home;
  - a distinct fresh frame for the home check;
  - reset to `0/4` when Return Home does not reach home;
  - three stars entering stage two;
  - same-side phase-two deployment;
  - 15-second phase-two Return Home cadence;
  - invalid capture retry without counter advancement;
  - stop-aware exit and outer-loop restart.
- Do not connect to or send input to an emulator during automated verification.

## Done criteria

- [x] Production `RunBuilderBaseLoop()` delegates to `BuilderBaseFlow.RunLoop()`.
- [x] One dedicated live adapter implements the abstract operation boundary.
- [x] Runtime star detection samples all three calibrated points from one raw
  ADB frame.
- [x] Every fourth completed analysis triggers Return Home and a distinct fresh
  Builder Base home frame.
- [x] A successful home check returns to the outer loop; a failed home check
  resets the counter and resumes star monitoring.
- [x] Three stars, when not already home, transitions to phase two.
- [x] No title-bar compensation or alternate coordinate transform is added.
- [x] Production syntax validation exits 0.
- [x] Interaction and flow suites end with `0 failed`.
- [x] No source file outside the scope list is modified by this plan.

## Completion evidence

- `test_adb_refactor_interactions.ahk`: 61 passed, 0 failed.
- `test_adb_refactor_flow.ahk`: 18 passed, 0 failed.
- `ADBcocbotrefactor.ahk` syntax validation: exit 0.
- The pre-existing local `ADBcoc_bot.ahk` modification was preserved and was
  not touched by this plan.

## STOP conditions

Stop and write a handback if:

- `BuilderBaseFlow.MonitorStageOne()` no longer implements the approved
  four-check sequence.
- The live detector cannot consume one supplied ADB frame without requesting
  another screenshot.
- Production deployment requires orchestration state not expressible through
  the current primitives boundary.
- Home detection requires reusing the pre-Return-Home star frame.
- Integration would require modifying `ADBcoc_bot.ahk`, either visual harness,
  or the shared coordinate formula.
- A verification command fails twice after a reasonable fix attempt.

## Maintenance notes

Future Builder Base features should be added around `BuilderBaseFlow.Attack()`
through explicit operations, not by growing `RunBuilderBaseLoop()` again.
Reviewers should scrutinize frame ownership, single translation of calibrated
client coordinates, and the boundary between orchestration and live ADB
actions. The diagnostic yellow-dot preview remains deliberately separate from
runtime detection.
