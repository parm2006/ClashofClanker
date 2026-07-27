# Main Flow Section Abstractions

## Scope

This design revises Plan 003 Step 2 only. It restructures startup and the Main
Village loop. Builder Base behavior and shared reload recovery remain unchanged
until the user approves Step 3.

`ADBcocbotrefactor_support.ahk` is a library used by
`ADBcocbotrefactor.ahk`. The support library owns the reusable input boundary,
flow controller, section boundaries, and deterministic policies. The main bot
owns the GUI, configuration, live ADB commands, screenshot processing, and OCR
adapters.

## Flow boundary

The Main Village controller calls section-level operations:

```ahk
operations.Do("reset_main_viewport")
operations.Do("collect_resources")

thresholds := operations.Do("check_resource_thresholds")
operations.Do("run_builder_upgrade", thresholds, wallUpgradesEnabled)
operations.Do("run_lab_upgrade")

operations.Do("enter_main_battle")
operations.Do("find_eligible_base", minGold, minElixir)
operations.Do("attack_main_base")
operations.Do("return_main_home")
operations.Do("finish_main_cycle")
```

Each operation hides its internal captures, retries, waits, random choices,
error correction, and low-level inputs. The controller shows the required
business sequence without exposing individual taps or polling loops.

## Section responsibilities

`clear_tap` performs three taps at the calibrated clearing point. Each tap gets
an independent coordinate offset and timing offset from the shared interaction
layer. Callers invoke `clear_tap` once.

`collect_resources` rolls 1 through 40. On 1, it taps every calibrated
collector in order. The function owns the roll, iteration, cancellation checks,
and randomized action timing.

`check_resource_thresholds` takes one fresh ADB screenshot and reads the gold,
elixir, and dark-elixir threshold points from that image. It returns:

```ahk
{gold: Boolean, elixir: Boolean, darkElixir: Boolean}
```

`run_builder_upgrade` returns immediately unless all three thresholds are met.
It takes one builder screenshot, rejects a zero builder count or Goblin
Builder, reserves the last builder when wall upgrades are enabled, opens the
builder menu, finds the suggested upgrade, selects it, confirms it, and invokes
one `clear_tap`.

`run_lab_upgrade` takes one lab screenshot, rejects an unavailable lab or
Goblin Researcher, opens the lab menu, finds the suggested upgrade, selects it,
confirms it, and invokes one `clear_tap`.

`enter_main_battle` performs Attack, Find Match, and Attack in order. It owns
the randomized input delays and reports failure if an input cannot be sent.

`find_eligible_base` waits four seconds, captures a frame, and checks clouds.
While clouds remain, it waits two seconds and captures a new frame without
overlapping captures. When clouds clear, it resets the viewport and uses the
last valid frame to confirm battle state and read loot. If both loot values are
below their configured thresholds, it taps Next and repeats the cloud and loot
checks. Missing configuration values default to 500,000.

`attack_main_base` selects a random calibrated side; deploys
`1, 2, 3, z, q, w, e, r`; deploys spells `a, s`; waits 30 seconds; and sends
hero abilities `q, w, e, r`. It owns troop-count OCR, deployment spacing,
cancellation checks, randomized inputs, and timing offsets.

`return_main_home` taps Return Home, waits two seconds, captures a fresh frame,
and checks Main Village state until confirmed. It resets the Main Village
viewport after confirmation.

`finish_main_cycle` increments the completed-attack count and evaluates the
stop timer. It stops only after the completed cycle. Step 3 may extend this
section with the approved every-fifth-attack reload recovery.

## Spell placement

Spell placement stores and receives client coordinates. The interaction layer
translates each client point to ADB coordinates, then moves each translated
axis 35 pixels toward the Android display center:

```text
shiftedX = adbX + sign(centerX - adbX) * 35
shiftedY = adbY + sign(centerY - adbY) * 35
```

For a diagonal point, this moves the spell approximately 49.5 pixels toward
the center. An axis already aligned with the center remains unchanged. After
the shift, the interaction layer clamps the point, applies independent uniform
offsets from -7 through +8, and sends the tap. It never changes stored client
calibration.

## Randomization and error handling

Every coordinate-bearing input enters the shared interaction layer. Each
coordinate receives a uniform -7 through +8 ADB offset.

For an intended delay of 75 ms or less, the caller waits `target - 5` ms and
the abstraction adds a uniform 0-10 ms delay. For a longer delay, the caller
waits `target - 15` ms and the abstraction adds a uniform 0-30 ms delay.
Section functions use the same timing policy for standalone waits.

Each section owns its retries and error correction. A section returns a useful
value on success or throws a descriptive error after exhausting its internal
recovery. The controller stops the current loop cleanly when a section throws
or the user pauses the bot. Runtime code never activates the emulator window.

## Verification

The interaction tests prove triple clearing taps, independent offsets, both
timing bands, and the component-wise spell shift after translation.

The flow tests assert the short section-level Main Village sequence and the
three threshold booleans. Focused operation tests cover collector iteration,
builder reservation, lab rejection, battle entry order, cloud retry cadence,
loot retry behavior, deployment order, Return Home retry, and timer-at-end
behavior. The actual refactor must load without AutoHotkey warnings, and
`ADBcoc_bot.ahk`, `config.ini`, and `flow.txt` must remain unchanged.
