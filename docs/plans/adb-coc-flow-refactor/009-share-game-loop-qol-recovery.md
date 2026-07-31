# Plan 009: Share cycle recovery, timer exit, and double Return Home

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving on.
> If anything in "STOP conditions" occurs, stop and write a handback —
> do not improvise. When done, update this plan's status row in the
> effort README.
>
> **Drift check (run first)**:
> `git diff bc078e1 -- ADBcocbotrefactor_support.ahk ADBcocbotrefactor.ahk builder_base_loop_logic.ahk test_adb_refactor_flow.ahk test_adb_refactor_interactions.ahk`
> If in-scope files have changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Status**: DONE
- **Effort**: L
- **Risk**: HIGH
- **Depends on**: 008-integrate-builder-base-attack-flow.md
- **Planned at**: revision `bc078e1`, 2026-07-31

## Why this matters

The active Main Village and Builder Base loops now attack correctly, but their
cycle-level safeguards have drifted. Reload OCR remains trapped in a legacy
Main-only function, Builder Base never participates in the auto-stop timer,
and both current Return Home paths can stall behind a Star Bonus/result layer.
This plan gives both villages one tested cycle-completion and reconnect
contract while preserving their separate farming and battle behavior.

## Current state

- `ADBcocbotrefactor_support.ahk:367-885` defines the testable
  `ADBMainFlowSections`. `ReturnMainHome()` sends one Return Home tap and one
  wait before its fresh home frame; `FinishMainCycle()` records only a Main
  attack and owns the Main-only timer exit.
- `ADBcocbotrefactor_support.ahk:892-966` defines
  `ADBRefactorFlowController`. It has startup and Main-loop controllers but no
  active common completion/reconnect controller.
- `builder_base_loop_logic.ahk:15-21` repeats Builder attacks but does not
  record a completed cycle or invoke timer/reconnect recovery.
- `builder_base_loop_logic.ahk:155-183` waits once after a Return Home tap,
  captures a fresh frame, and checks Builder Base home.
- `ADBcocbotrefactor.ahk:2545-2594` contains legacy
  `CheckGameTimeout()`. It is gated by `IsRunning`, captures internally, uses a
  raw sleep, allows a blind fallback tap, and cannot safely route the active
  Builder flow.
- `ADBcocbotrefactor.ahk:3195-3624` is the live Main adapter. Its
  `RecordCompletedAttack()` increments `MainCompletedAttacks`, and
  `StopBot()` clears only `IsRunning`.
- `ADBcocbotrefactor.ahk:4184-4241` is the live Builder adapter and has no
  common cycle-completion operation.
- `test_adb_refactor_flow.ahk:883-929` already sketches inactive fifth-cycle
  reload tests. They are not registered in `flowTests` and describe an older
  routing shape; update and activate them rather than silently relying on
  dead tests.
- `test_adb_refactor_interactions.ahk:322-603` is the deterministic Builder
  flow suite and is the exemplar for fake-operation sequencing.

Runtime input must continue through `RunADBTapAt()`/`SendKey()`, waits must be
stop-aware, and every decision must consume its own supplied fresh ADB frame.
Match the operation-injection pattern used by `ADBMainFlowSections` and
`BuilderBaseFlow`; do not put orchestration in GUI hotkeys.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Interaction tests | `& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' '.\test_adb_refactor_interactions.ahk'` | `%TEMP%\adb_refactor_interactions_result.txt` ends with `0 failed` |
| Flow tests | `& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' '.\test_adb_refactor_flow.ahk'` | `%TEMP%\adb_refactor_flow_result.txt` ends with `0 failed` |
| Production syntax | `& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' /ErrorStdOut /Validate '.\ADBcocbotrefactor.ahk'` | exit 0 with no warnings |
| Diff hygiene | `git diff --check` | no output |

The AHK test processes must be awaited before reading their result files. The
PowerShell `System.Diagnostics.Process` pattern used in prior verification is
the reliable local runner.

## Scope

**In scope** (the only source/test files you should modify):

- `ADBcocbotrefactor_support.ahk`
- `ADBcocbotrefactor.ahk`
- `builder_base_loop_logic.ahk`
- `test_adb_refactor_flow.ahk`
- `test_adb_refactor_interactions.ahk`
- `test_builder_base_loop_visual.ahk` — add only the compatibility operation
  needed by the shared Builder flow; do not add production recovery behavior.
- `docs/plans/adb-coc-flow-refactor/009-share-game-loop-qol-recovery.md`
- `docs/plans/adb-coc-flow-refactor/README.md`

**Out of scope**:

- `ADBcoc_bot.ahk` — protected rollback reference with a pre-existing user
  modification; never stage, edit, or revert it.
- Visual Builder Base battle behavior — the F8 flow is already user-validated;
  only its required common-completion adapter case is in scope.
- Blind center taps, generic popup classifiers, and automatic process launch.
- Village-specific farming, loot, deployment, star, or cloud behavior.
- The five-completion cadence and the two-second inter-tap waits fixed by the
  approved design.

## Steps

### Step 1: Add failing common-cycle and double-tap contracts

Update `test_adb_refactor_flow.ahk` with active deterministic cases proving:

- Main and Builder completions use one shared counter operation;
- completion counts not divisible by five skip reload capture/OCR;
- the fifth completion captures once, consumes that supplied frame for OCR,
  and does not tap when no explicit Reload/Retry action exists;
- a matched action taps its OCR point, waits 15 seconds, then uses distinct
  fresh frames until village detection returns `main` or `builder`;
- timer expiry takes precedence over reconnect, exits the game, and stops both
  loops;
- Main Return Home sends two taps separated by two stop-aware waits before
  its fresh home capture.

Update `test_adb_refactor_interactions.ahk` to prove Builder Base performs the
same two-tap sequence and invokes common completion only after an attack
returns home.

Register every new or formerly dormant test. Run both suites and observe
failures caused by missing common operations/double taps, not syntax mistakes.

**Verify**: both test commands → the new named tests fail for the expected
missing behavior.

### Step 2: Implement the pure shared lifecycle

In `ADBcocbotrefactor_support.ahk`, add one injected-operations lifecycle
controller used by both villages. It must:

- record one session-wide completed attack only after home confirmation;
- inspect the timer immediately after recording and stop/exit without running
  reconnect when elapsed;
- run reconnect recovery only when `Mod(completedAttacks, 5) == 0`;
- consume one supplied reload-decision frame;
- accept only an explicit reload action result, never a blind fallback;
- wait 15 seconds after the reload tap;
- sequentially capture/detect until `main` or `builder`, with stop-aware retry
  waits for unknown/battle frames;
- route only when the detected village differs from the current loop.

Make `ADBMainFlowSections.FinishMainCycle()` delegate to this shared operation
instead of owning Main-only timer logic. Change `ReturnMainHome()` to the
approved tap → 2s → tap → 2s → fresh frame sequence.

In `builder_base_loop_logic.ahk`, add the same completion operation after
`Attack()` returns `home`, and add the second Return Home tap before the fresh
home frame. Keep the existing fourth-check and stage-two cadence unchanged.

In `test_builder_base_loop_visual.ahk`, acknowledge
`complete_global_cycle` with a logged `continue` result so the isolated F8
harness remains compatible without running production timer/reconnect routing.

**Verify**: flow and interaction tests → all pure-flow tests pass.

### Step 3: Connect production ADB, OCR, state, and routing

In `ADBcocbotrefactor.ahk`, implement the live operations required by the
shared lifecycle:

- replace the Main-only completed counter with one session counter incremented
  for either village and reset only at a new `UnifiedStart()` session;
- capture reload and post-reload village frames through the forced-fresh ADB
  frame boundary;
- crop the center from the supplied frame and OCR only explicit
  Reload/Retry/Try Again actions;
- translate the OCR result back to a client point and tap it through
  `RunADBTapAt()`;
- use `SafeFlowWait()`/`SafeSleep()` for recovery waits;
- route by setting mutually exclusive run flags before scheduling the target
  loop;
- make stop clear both `IsRunning` and `IsBBRunning`;
- reuse the existing ADB Escape plus viewport-relative Okay timer-exit
  operation for either village.

Connect both `LiveADBFlowPrimitives` and `LiveBuilderBasePrimitives` to the
same lifecycle implementation. Do not call legacy `CheckGameTimeout()` from
either active flow.

**Verify**: production syntax command → exit 0 with no warnings; interaction
source contract confirms both adapters use the shared lifecycle.

### Step 4: Verify the whole runtime boundary

Run syntax validation and both complete offline suites. Inspect the diff for
duplicate loop scheduling, mutable-frame reuse, raw desktop input, raw sleeps
inside the new recovery path, and accidental protected-file changes.

Update this plan and the effort README to `DONE` only after all checks pass.

**Verify**:

- interaction suite → `0 failed`;
- flow suite → `0 failed`;
- production syntax → exit 0 with no warnings;
- `git diff --check` → no output;
- `git diff --name-only -- ADBcoc_bot.ahk` shows only the pre-existing user
  change and the file is not staged.

## Test plan

- Activate and modernize the existing dormant reload tests in
  `test_adb_refactor_flow.ahk`.
- Add common-cycle tests for non-fifth, fifth-no-action, fifth-reload,
  unknown-frame retry, cross-village route, and timer precedence.
- Update Main Return Home expected operation order to two taps/two waits.
- Update Builder Base stage-one/stage-two tests to two taps and one distinct
  fresh home frame per attempt.
- Add a production-source contract verifying Main and Builder adapters
  delegate to the same lifecycle and the active paths do not call
  `CheckGameTimeout()`.
- Run no live emulator actions during automated verification.

## Done criteria

- [x] One shared session counter records Main and Builder completions.
- [x] Reload OCR runs only after every fifth confirmed attack.
- [x] Reload recovery consumes one supplied frame and has no blind tap.
- [x] Recovery waits 15 seconds and reroutes from sequential fresh frames.
- [x] Main and Builder Return Home each tap twice before a fresh home check.
- [x] Timer expiry after either village uses the common game-exit path.
- [x] Stop clears both run flags and routing never overlaps loops.
- [x] Active flows do not call legacy `CheckGameTimeout()`.
- [x] Interaction and flow suites end with `0 failed`.
- [x] Production syntax validation exits 0 without warnings.
- [x] No in-scope implementation touches or stages `ADBcoc_bot.ahk`.

## Completion evidence

- `test_adb_refactor_interactions.ahk`: 63 passed, 0 failed.
- `test_adb_refactor_flow.ahk`: 24 passed, 0 failed.
- `ADBcocbotrefactor.ahk` syntax validation: exit 0.
- `test_builder_base_loop_visual.ahk` syntax validation: exit 0.
- `git diff --check`: no output.
- Automated verification made no emulator connection and sent no game input.

## STOP conditions

Stop and write a handback if:

- a completed Builder attack cannot be distinguished from a stopped attack;
- reload OCR cannot consume the supplied immutable frame;
- routing requires both run flags to be true at once;
- timer exit requires desktop/window input;
- the two-tap sequence conflicts with the validated fourth-check Builder flow;
- implementation would require changing visual harness battle behavior or
  editing `ADBcoc_bot.ahk`;
- a verification command fails twice after a reasonable fix attempt;
- a new popup/action label beyond explicit Reload/Retry/Try Again is required.

The handback must describe current state, desired outcome, and the unresolved
fork without selecting a new design.

## Maintenance notes

Future global protections should enter through the shared lifecycle rather
than being copied into the two village loops. Reviewers should scrutinize
counter reset ownership, stop-aware waits, immutable frame use, and mutually
exclusive route flags. Generic popup OCR and automatic app relaunch remain
deliberately deferred pending visual proof.
