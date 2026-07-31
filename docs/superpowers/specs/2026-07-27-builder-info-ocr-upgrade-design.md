# Builder Info OCR Upgrade Design

## Goal

Insert the missing Info-button step between selecting a suggested building
upgrade and tapping the calibrated confirmation button. The change applies to
the refactor bot only. `ADBcoc_bot.ahk` remains unchanged.

## Flow

The builder upgrade operation will perform these steps:

1. Open Suggested Upgrades.
2. OCR and tap one suggested building.
3. Wait for the building action bar to settle.
4. Capture one fresh ADB frame.
5. OCR the bottom 35 percent of that frame.
6. Find the `Info` word in the horizontal action bar.
7. Convert the OCR word's ADB-frame coordinates to client coordinates.
8. Tap the center of the `Info` word through the randomized interaction
   abstraction. This point lies in the button's lower half.
9. Wait for the information screen.
10. Tap the calibrated upgrade confirmation point.
11. Clear the selection with the existing three-tap clear operation.

## Detection

The detector will OCR multiple scales from one ADB capture. It will accept
case-insensitive `Info` and the common `lnfo` misread. It will reject matches
outside the bottom action-bar crop. When several readings match, it will choose
the leftmost match because Info is always the first action button.

The detector returns the matched text, OCR bounds, client tap point, scale, and
crop metadata. It never sends input.

## Failure Behavior

The bot makes one detection attempt. If OCR finds no valid Info match, the
builder operation logs the failure, clears the current selection, skips the
upgrade, and returns `false`. It never taps the calibrated confirmation point
after a failed Info detection.

## Interaction Boundary

The detector produces client coordinates. The live primitive sends the tap
through the existing randomized ADB interaction abstraction. No caller
pretranslates coordinates or sends a raw ADB tap.

## Visual Test

An isolated visual-debugger script will:

- use a fresh ADB capture;
- display the bottom action-bar crop;
- draw a green box around the accepted Info word or a red search region when
  detection fails;
- show editable crop controls;
- log every OCR scale, raw text, accepted match, OCR bounds, and client point;
- provide detection only, with no gameplay tap.

The production flow will be updated only after the visual detector works in
isolation.

## Automated Tests

Contract tests will verify that:

- the builder flow detects and taps Info before confirmation;
- confirmation is unreachable when detection fails;
- one fresh frame supplies all OCR scales;
- the detector searches only the lower action bar;
- the tap uses client coordinates and the randomized interaction boundary;
- the protected original bot remains outside the implementation.
