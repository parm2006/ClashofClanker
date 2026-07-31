# Builder Base Loop Design

## Goal

Add a Builder Base attack loop to the active ADB refactor. The first version
does one thing: the outer Builder Base loop repeatedly calls an isolated attack
operation. The design leaves room to add Builder Base features before or after
the attack call.

Develop and prove the behavior in one root-level AutoHotkey test harness before
integrating it into `ADBcocbotrefactor.ahk`. Do not modify the protected
`ADBcoc_bot.ahk`.

## Architecture

The implementation has three layers:

1. `BuilderBaseFlow` owns orchestration and battle state.
2. `BuilderBaseOperations` owns isolated actions such as navigation, viewport
   preparation, deployment, capture, star analysis, Return Home, and home
   detection.
3. The test harness maps function keys to thin wrappers around those operations.

The flow layer depends only on the operations interface. Automated tests can
substitute deterministic operations without running ADB. The visual harness
uses live ADB operations and the existing calibrated client-coordinate
boundary.

The outer loop has this shape:

```text
while Builder Base is running
    BuilderBaseAttack()
```

No other Builder Base feature runs in this first version.

## Attack flow

`BuilderBaseAttack()` performs these steps:

1. Tap the calibrated Builder Base Attack button.
2. Tap the calibrated green Find Match button.
3. Wait four seconds.
4. Call `BeginBuilderBaseAttack()`.

`BeginBuilderBaseAttack()` prepares the viewport, chooses one of the four
calibrated deployment sides at random, stores that side for both stages, and
deploys `Q12345678` along it.

The flow then enters the stage-one monitor. If it detects Builder Base home, the
attack ends and control returns to the outer loop. If it detects three stars,
the flow enters stage two.

## Synchronous star monitoring

The stage-one monitor runs one check at a time:

```text
capture one fresh frame
wait for capture completion
validate the frame
crop and analyze the star region
discard the result
increment the completed-check counter
```

The next capture cannot start until analysis of the current frame finishes.
The implementation must not use a repeating capture timer or queue capture
requests.

ADB still captures the complete Android frame. The analyzer sees only a crop
whose edges are the minimum and maximum calibrated coordinates of the three
stars plus a 20-client-pixel margin on each side. It samples a small
neighborhood around each calibrated star from that single crop and reports
three stars only when all three neighborhoods match the gold-star rules.

A failed or invalid capture logs its error and retries after a stop-aware short
wait. It does not increment the completed-check counter.

After every fifth completed star analysis, the monitor:

1. taps Return Home;
2. waits for that input operation to finish;
3. captures one new frame;
4. checks that new frame for Builder Base home.

The home check never reuses the star frame because the Return Home tap may
change the screen.

## Stage two

When stage one reports three stars, the flow:

1. stops stage-one monitoring;
2. waits 15 seconds;
3. prepares the viewport again;
4. deploys `Q12345678` along the same stored side;
5. waits 15 seconds between Return Home attempts;
6. captures and analyzes one fresh frame after each attempt;
7. returns only when Builder Base home is detected or the user stops the bot.

Stage two does not run star checks.

## Test harness

Create one root-level harness, `test_builder_base_loop_visual.ahk`. Each
function key calls one isolated test wrapper, so the user can exercise the
attack in sequence without opening multiple scripts:

| key | isolated step |
|---|---|
| F1 | Tap Builder Base Attack |
| F2 | Tap green Find Match |
| F3 | Wait four seconds, prepare viewport, choose and store a random side, then deploy stage-one `Q12345678` |
| F4 | Run the synchronous stage-one monitor until it reports home or three stars |
| F5 | If F4 reported three stars, wait 15 seconds, prepare the viewport, and deploy stage-two `Q12345678` on the stored side |
| F6 | Run the 15-second Return Home and home-check loop |
| F7 | Run one complete `BuilderBaseAttack()` |
| F8 | Start or stop the minimal outer Builder Base loop |

The script stores only the state needed between sequential keys: the chosen
side and the latest stage-one outcome. Each key wrapper validates its
prerequisites and logs a clear message instead of guessing missing state.

The harness includes the production support and logic modules. It must not
duplicate the internal flow functions inside hotkey bodies.

## Stop, pause, and error behavior

Every wait, capture retry, input sequence, deployment loop, and monitoring loop
checks the existing stop and pause state. A stop exits to the harness without
leaving a timer or capture running.

An ADB input or viewport failure ends the current isolated step and logs the
failed operation. A capture failure retries because it may be transient. An
invalid or stale Builder Base calibration prevents the attack from starting.

## Verification

Automated tests will prove:

- the outer loop calls only the attack operation;
- navigation order is Attack, Find Match, four-second wait, Begin Attack;
- the same random side is used for both deployments;
- stage one never overlaps or queues captures;
- only successful analyses advance the counter;
- each fifth successful analysis triggers Return Home followed by a fresh home
  capture;
- detecting home exits to the outer loop;
- detecting three stars waits 15 seconds before stage-two viewport preparation
  and deployment;
- stage two waits 15 seconds between Return Home attempts and exits on home;
- stop requests interrupt every long-running path;
- production source routes all taps, placements, captures, and coordinate
  translation through the shared ADB boundary.

The visual sequence is F1 through F6. F7 verifies the composed attack, and F8
verifies repetition. Integration into the active refactor requires successful
automated tests and the user's confirmation that the visual harness works.
