# Shared Game-Loop QoL Design

## Goal

Give the active Main Village and Builder Base loops one shared lifecycle for:

- completed-attack counting;
- five-cycle Reload/reconnect recovery;
- end-of-cycle auto-stop timer and game exit;
- two-tap Return Home recovery for battle-result and Star Bonus screens.

The implementation must remain ADB-only at runtime, preserve stop/pause
authority, and never start overlapping Main and Builder loop timers.

## Shared cycle state

One session counter records completed attacks from either village. It starts at
zero when the user starts a new bot session and is not reset when reconnect
recovery routes from one village to the other.

An attack is completed only after a fresh screenshot confirms Main Village or
Builder Base home. Every fifth completion runs the shared reconnect checkpoint.
Other completion counts skip reconnect OCR.

## Double Return Home

Every Main Village and Builder Base Return Home attempt uses the same sequence:

1. tap the calibrated Return Home point;
2. wait two seconds for the battle-result or Star Bonus screen to change;
3. tap the calibrated Return Home point a second time;
4. wait two seconds;
5. capture one fresh frame and perform the village-home check.

The second tap deliberately handles the Star Bonus/result layer. A failed home
check starts another complete two-tap attempt. The home check never reuses a
frame captured before either tap.

## Reload and reconnect recovery

After every fifth completed attack:

1. capture one fresh frame;
2. OCR the center region for an explicit Reload/Retry action;
3. if no action is found, continue the current village loop;
4. if found, tap the OCR-derived client point through the shared ADB boundary;
5. wait 15 seconds with a stop-aware wait;
6. capture fresh frames until village detection returns `main` or `builder`;
7. resume exactly that village's loop.

Recovery never uses a blind center fallback. Unknown/battle frames are logged
and retried without incrementing the completed-attack counter. Routing changes
the active run flag before scheduling the other loop, preventing overlapping
loop instances.

The existing legacy `CheckGameTimeout()` may supply OCR rules, but it must not
remain the orchestration boundary: it is gated to Main Village, captures its
own mutable frame, performs raw sleeps, and cannot safely route the active
refactor after recovery.

## Common timer and game exit

The configured timer starts once at session startup. Both villages inspect it
only after reaching home and recording the completed attack. This preserves
the existing promise that a timer does not abandon an attack midway.

When elapsed, the common completion service:

1. sends Escape through ADB;
2. taps the existing viewport-relative green Okay point through ADB;
3. clears both Main and Builder run flags;
4. returns control without scheduling another loop.

When not elapsed, the same service runs the fifth-cycle reconnect checkpoint
and then continues or reroutes according to the detected village.

## Boundaries

- A pure flow/controller layer owns count, cadence, retry, routing, and timer
  decisions.
- Live adapters own ADB capture, OCR, village detection, taps, waits, and UI
  run-state changes.
- Main Village and Builder Base call the same completion/recovery controller.
- Village-specific farming, deployment, star detection, and viewport behavior
  remain in their existing flows.

## Error and stop behavior

- Capture or OCR failures log actionable details and retry only while a bot
  run flag remains active.
- A pause/stop request interrupts all waits and prevents new captures or loop
  scheduling.
- ADB command failures clear cached connection state through the existing
  interaction boundary so the next attempt reconnects.
- Reload recovery does not reset calibration or completed-attack state.

## Verification

Deterministic tests must prove:

- Main and Builder completions increment the same session counter;
- reconnect OCR runs only on multiples of five;
- no Reload result continues without tapping;
- a Reload result taps once, waits 15 seconds, and routes from a fresh village
  frame;
- unknown post-reload frames retry sequentially;
- Main and Builder Return Home attempts tap twice before the fresh home frame;
- timer expiry after either village exits the game and stops both run flags;
- a disabled/unexpired timer continues without exiting;
- routing never schedules both village loops;
- production syntax validates without warnings;
- existing interaction and flow suites remain green without connecting to an
  emulator.

## Deferred

Generic blind popup clicking, automatic app relaunch after a process crash, and
changing the five-cycle cadence are outside this change. They require separate
visual proof before runtime integration.
