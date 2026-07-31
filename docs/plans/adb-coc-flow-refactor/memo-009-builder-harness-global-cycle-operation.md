# Memo: Preserve the F8 harness after adding common cycle completion

## Verdict

Add `complete_global_cycle` to the standalone Builder Base harness adapter as
a logged no-op returning `continue`. Production continues to own the real
session counter, timer exit, reconnect OCR, and cross-village routing.

## Evidence

- `builder_base_loop_logic.ahk:15-27` now invokes `complete_global_cycle` after
  a complete attack reaches Builder Base home.
- `test_builder_base_loop_visual.ahk:128-160` implements the operation adapter
  used by F7/F8 but has no common lifecycle operation.
- `ADBcocbotrefactor.ahk:4184-4243` has the production adapter that delegates
  the operation to the live common lifecycle.

Without the harness case, F8 reaches the adapter's unknown-operation error
immediately after a successful home detection. The harness intentionally does
not run the production timer/reconnect service because it is an isolated
battle-flow debugger and has no Main Village routing lifecycle.

## Rejected alternatives

- Remove completion from `BuilderBaseFlow`: Builder production would again
  have no shared completed-attack boundary.
- Make unknown operations silently succeed: this would hide future adapter
  drift and weaken the harness.
- Duplicate production recovery inside the harness: this would expand F8
  beyond its isolated debugging contract and risk live cross-village routing.
