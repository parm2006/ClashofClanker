# Timer Exit Interaction Test Design

## Goal

Prove the shutdown interaction in isolation before adding it to the bot. The
interaction sends Android Escape, waits for the Clash of Clans exit dialog,
and taps the green **Okay** button through background ADB.

The production timer behavior remains unchanged during this test phase. The
bot checks the timer boolean only at the end of the Main Village loop.

## Test Harness

Create one AutoHotkey v2 visual test script with two user-triggered phases.
The script reads the current Android viewport and serial from `config.ini` on
every run.

### Phase 1: Desktop Pointer Preview

Pressing F1:

1. Sends `KEYCODE_ESCAPE` through ADB.
2. Waits for the exit dialog.
3. Converts the configured Okay client coordinate to ADB coordinates.
4. Moves the Windows mouse to the client coordinate without clicking.
5. Logs the client coordinate and translated ADB coordinate.

This phase lets the user confirm the target visually. After inspection, the
user dismisses the dialog manually before starting Phase 2.

### Phase 2: Complete Background ADB Test

Pressing F2:

1. Sends `KEYCODE_ESCAPE` through the shared ADB key-event abstraction.
2. Uses the tap abstraction's intended delay to wait for the dialog.
3. Taps the configured Okay client coordinate through background ADB.
4. Leaves the Windows mouse untouched.
5. Logs the client coordinate, nominal ADB coordinate, and actual randomized
   ADB coordinate.

Phase 2 exits Clash of Clans.

## Coordinate Model

The harness stores and edits only client coordinates. It translates them at
the interaction boundary with the current calibrated viewport ratios.

The initial point is derived from the supplied screenshot at approximately
60% of the Android viewport width and 60.5% of its height. The GUI exposes
editable X and Y controls so the F1 pointer preview can correct the target.
The harness can save the confirmed client point under a dedicated
`[VisualTests]` key without changing production bot coordinates.

The final ADB tap applies the standard independent `-7..+8` pixel offsets.

## GUI and Diagnostics

The visual debugger contains:

- editable Okay X and Y client-coordinate controls;
- F1 **Preview Okay Location** and F2 **Run Real ADB Exit** buttons;
- a high-contrast READY, PREVIEW, SUCCESS, or ERROR verdict;
- a fresh ADB preview marked at the translated target;
- a scrollable timestamped console.

The console states clearly that F1 does not click and F2 exits the game.

## Safety and Error Handling

- F1 never clicks.
- F2 requires a valid ADB connection and current viewport calibration.
- Failed key or tap commands stop the phase and log the exact error.
- The script performs no clear taps, retries, OCR, or bot-loop actions.
- The script never modifies `ADBcoc_bot.ahk`.

## Acceptance Criteria

1. F1 opens the exit dialog and moves the mouse to the center of the green
   Okay button without clicking.
2. F1 logs matching client and nominal ADB coordinates.
3. F2 opens the exit dialog, leaves the mouse stationary, and exits the game
   with one randomized ADB tap.
4. F2 logs the client, nominal ADB, and actual randomized ADB coordinates.
5. Existing refactor tests continue to pass.

## Future Integration

After both phases pass, replace the end-of-loop `stop_bot` operation with one
contained timer-expiry operation:

1. send `KEYCODE_ESCAPE`;
2. tap the proven Okay client coordinate;
3. stop the bot state.

The timer remains an end-of-loop boolean check.
