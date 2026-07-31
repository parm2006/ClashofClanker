# ADB CoC Flow Refactor

These plans implement the approved [ADB CoC Flow Refactor Design](../../superpowers/specs/2026-07-27-adb-coc-flow-refactor-design.md) from revision `260ef1d`. They create and modify `ADBcocbotrefactor.ahk` while keeping `ADBcoc_bot.ahk` unchanged. The work is sequenced so a testable client-coordinate interaction boundary exists before desktop paths are removed, then the runtime flow and visual inspectors build on that boundary.

Execute in the order below. Each executor must read the selected plan fully, run its drift check, honor its STOP conditions, and update this table.

## Execution order & status

| Plan | Title | Effort | Depends on | Status |
|---|---|---|---|---|
| [001](001-establish-refactor-and-interaction-contract.md) | Establish the isolated refactor and testable ADB interaction contract | M | — | DONE |
| [002](002-migrate-client-coordinates-and-remove-desktop-runtime.md) | Make the refactor client-coordinate and ADB-only at runtime | L | 001 | DONE |
| [003](003-align-main-and-builder-loops-to-flow.md) | Align both runtime loops and recovery paths with flow.txt | L | 002 | IN PROGRESS |
| [004](004-restore-adb-visual-ocr-inspectors.md) | Restore ADB-based visual OCR inspectors outside scratch | M | 003 | TODO |
| [005](005-prove-builder-info-ocr-detector.md) | Prove the Builder Info OCR detector in isolation | M | 003 | IN PROGRESS |
| [006](006-integrate-builder-info-before-confirmation.md) | Require Builder Info before upgrade confirmation | M | 005 + user validation | TODO |
| [007](007-prove-timer-exit-interaction.md) | Prove the end-of-loop timer exit interaction in isolation | M | 002 | DONE |

Status values: TODO | IN PROGRESS | DONE | BLOCKED (one-line reason) | SUPERSEDED (one-line pointer to what replaced it)

## Dependency notes

- **001 → 002**: The interaction boundary gives calibration and observation code one conversion/timing policy.
- **002 → 003**: The flows cannot be ADB-only while client/ADB coordinate copies and desktop observation fallbacks remain.
- **003 → 004**: Inspectors need the settled ADB frame and client-coordinate contracts, and final packaging waits for full runtime verification.

- **003 → 005**: The isolated detector relies on the settled fresh-frame and
  client-coordinate contracts.
- **005 → 006**: Production integration starts only after the user confirms
  that the live visual inspector finds Info across variable action rows.

## Reconciliation log

- **2026-07-28**: Closed Plan 007 after the user confirmed both visual phases.
  Integrated the proven Main Village timer exit as one end-of-cycle operation:
  Escape, viewport-relative randomized ADB tap on Okay, then stop. Builder Base
  remains unchanged.

- **2026-07-28**: Added Plan 007 for the approved two-phase timer exit test.
  It can execute now because it depends only on the established client/ADB
  interaction boundary. Production timer integration remains deferred until
  the user validates both visual phases.

- **2026-07-27**: Added Plans 005-006 for the approved Builder Info OCR
  transition. Execute 005 now; hold 006 until the user validates the isolated
  visual detector. Plan 004 remains the broader final inspector effort.

- **2026-07-27**: Plan 003 Step 2 amended at `a06c6e2`: Main Village uses
  section-level operations with internal randomization and recovery. One frame
  serves one current decision; thresholds, builder, walls, lab, clouds, loot,
  and home checks use fresh decision-boundary frames. Builder Base remains
  frozen pending separate approval.

- **2026-07-27**: Plan 002 closed — 11 interaction/coordinate tests pass; the refactor starts cleanly; runtime observation is ADB-only; only the two calibration-start functions may foreground the emulator; the original bot remains unchanged. Next: 003 Step 1.
- **2026-07-27**: Plan 001 closed — 6 interaction contract tests pass; the original bot hash remains `41BBFC8851EA83E70D1979C736EA2D1150F008CD974EFE11E7815E4A5DEA71B5`. Next: 002.
- **2026-07-27**: Initial plans written from the approved design and `flow.txt`. The original bot is intentionally outside scope. Next: 001.

## Considered and rejected

- Full monolith rewrite: rejected because it would replace working calibration/OCR behavior before the tested interaction boundary exists.
- Updating `ADBcoc_bot.ahk` directly: rejected by the user's explicit rollback requirement.
- Retaining Windows pixel/capture fallbacks: rejected by the pure-background ADB requirement.

## Deferred

- Moving final visual inspector scripts and generated artifacts into `scratch/`: deferred until all refactor plans are verified and the user explicitly confirms the revamp is complete.
