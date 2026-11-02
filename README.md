# Clash of Clanker

A Windows desktop bot for Clash of Clans, built with AutoHotkey v2. It automates Main Village farming and Builder Base attacks through Android Debug Bridge (ADB), with a controller GUI and a separate manual click visualizer.

Gameplay taps, swipes, keyevents, and screenshots use ADB, so normal operation does not take over your Windows mouse or keyboard. Initial calibration requires the emulator to be visible on the active desktop.

## Requirements

- **Windows and [AutoHotkey v2](https://www.autohotkey.com/)**. AutoHotkey v1 cannot run these scripts.
- **An ADB-enabled emulator with Clash of Clans installed.** The GUI provides targets for Habumi, [Google Play Games Developer Emulator](https://developer.android.com/games/playgames/emulator), and BlueStacks. The regular Google Play Games desktop app is not the Developer Emulator.
- **`adb.exe`**, available on `PATH` or in an emulator installation folder recognized by the script.
- **[uv](https://docs.astral.sh/uv/getting-started/installation/)** for the vision runtime. The repository requires Python 3.13 and manages OpenCV through `pyproject.toml` and `uv.lock`; a global `pip install` is unnecessary.
- Internet access for initial dependency setup. Keep the complete repository, including `OCRimages/` and the bundled pinch-helper APKs in `pinch_test/dist/`.

## Quick start

1. Download and extract the [main branch ZIP](https://github.com/parm2006/ClashofClanker/archive/refs/heads/main.zip), or clone the repository:

   ```powershell
   git clone https://github.com/parm2006/ClashofClanker.git
   cd ClashofClanker
   ```

2. Install the requirements, then prepare the vision environment from the repository folder:

   ```powershell
   uv sync --locked
   ```

   This creates the local `.venv`. The bot also runs a locked sync when it first needs the Python vision runtime.

3. Open Clash of Clans and double-click **`ADBcoc_bot.ahk`**. In **Control**, set **Target Window Title** to match the emulator window. In **ADB**, select your emulator and click **Test Connection**.
4. Run **Main Calib** in **Calibration**. Also run **BB Calib** for Builder Base attacks. Read the [calibration guide](#calibration) before starting.
5. Review **Farming** and **Settings**, return to a village home screen, and click **Start Bot**. Watch the **Activity Log** during the first cycle. Use **Pause Bot** to stop the loop.

Settings and calibration are saved locally in `config.ini`, which Git ignores. `config.ini.example` illustrates the format; its coordinates are not a calibration for your emulator. Back up your own `config.ini` before replacing an installation.

## Controller GUI

The production entry point is **`ADBcoc_bot.ahk`**, which opens **CoC Bot Controller** with five tabs. Valid settings save automatically: checkboxes apply immediately and edited fields save after a short typing delay. There is no Save Settings button. Invalid or temporarily empty fields retain the previous settings; check the Activity Log for save errors.

| Tab | Controls |
| --- | --- |
| **Control** | Target window title, Start Bot, Pause Bot, status, Activity Log, and an optional hours/minutes auto-stop timer. Leave it at `0 : 0` for no time limit; set it before starting. |
| **Calibration** | Main Village and Builder Base calibration buttons and the current step prompt. Follow the changing prompt: the static tab summary still describes an older sequence. |
| **Farming** | Auto Loot Search, minimum Gold and Elixir limits (initially `500000` each), Auto Wall Upgrade, and the calibrated collector count. |
| **Settings** | Battle Load Delay in milliseconds, Builder Base clicks per troop slot, button/deployment position variance, troop 1–3 deployment click counts, and **No upgrades**. No upgrades disables resource-threshold eligibility for the automatic upgrade paths. |
| **ADB** | Emulator provider, target serial where applicable, Test Connection, and connection status. |

### Emulator targets

| Provider | Default ADB serial |
| --- | --- |
| Habumi | `127.0.0.1:15555` |
| Google Play Games Developer Emulator | `localhost:6520` (fixed by the controller) |
| BlueStacks | `127.0.0.1:5555` (change to your instance's local port) |

Enable ADB in the emulator first and select the serial for the instance running the game. One emulator is controlled at a time; multi-instance and simultaneous control are not supported. The bot and visualizer share a controller lock, so close one before opening the other.

## Calibration

Keep the emulator visible on the active Windows desktop. Hover over each requested point and press **Space**; navigate the game manually when a prompt asks for another menu or screen. **Esc** cancels the active wizard. Follow zoom/reset prompts before recording the next point.

### Main Village: 30 steps

Start **Main Calib** or press **Ctrl + Shift + Alt + F1**.

| Steps | Targets |
| --- | --- |
| 1–2 | Top-left and bottom-right of the visible Android picture, excluding emulator toolbars, sidebars, and black borders. |
| 3 | Village identifier: the Dark Elixir drop icon or bar. |
| 4–6 | Dark Elixir, Elixir, and Gold storage threshold points, in that order. Choose the fill level at which upgrade eligibility should trigger. |
| 7–8 | Builder count badge and laboratory count badge. |
| 9–14 | Upgrade More, Add Wall, Remove Wall, Gold wall upgrade, Elixir wall upgrade, and upgrade confirmation. |
| 15–17 | Battle/Attack, Find a Match, and the green Attack start button. |
| 18–20 | Center of the Gold coin icon, center of the Elixir drop icon during matchmaking, and Next Match. OCR regions are derived from the icon positions. |
| 21–28 | Start/end points for four deployment lines: bottom-right, bottom-left, top-left, top-right. |
| 29 | Return Home button. |
| 30 | Resource collectors: press Space for each Gold Mine, Elixir Collector, or Dark Elixir Drill, then **Enter** to finish and save. |

Keep deployment lines outside the red no-deploy area, including the entire line between endpoints, with at least **10 Android/ADB pixels** of clearance. Do not move the game view while recording collectors.

### Builder Base: 13 steps

Complete Main calibration first so the Android viewport is known. Open the Builder Base and start **BB Calib** or press **Ctrl + Shift + Alt + F2**.

| Steps | Targets |
| --- | --- |
| 1–2 | Builder Base Attack and Find a Match. |
| 3–5 | Centers of the three stars on the Overall Damage results screen. |
| 6–13 | Start/end points for the four Builder Base deployment lines, in the same side order as Main Village. |

Record the last endpoint with Space, then press **Enter** to finish and save.

Recalibrate after switching provider/device, changing the Android display resolution, or changing the viewport/window layout. Calibration is tied to the selected provider, serial, and viewport. Moving a window alone does not require new points.

Loot search skips a base only when **both** Gold and Elixir are below their limits; meeting either limit is enough to proceed. Disabling Auto Loot Search bypasses this filter.

## Automated behavior

- **Main Village:** resource collection, resource-threshold checks, available builder/laboratory upgrade paths, matchmaking, optional Gold/Elixir loot filtering, troop/siege/hero/spell deployment, hero abilities, and Return Home.
- **Wall upgrades:** controlled by Enable Auto Wall Upgrade and calibrated storage threshold checks.
- **Builder Base:** village detection, attack entry, two-phase deployment, results checks, and return/retry handling.
- **Recovery:** reload detection and Clash app recovery, plus provider-specific Habumi watchdog handling. Failures and retries appear in the Activity Log.

Upgrade actions can spend in-game resources. Pet and workshop upgrade paths are unfinished in the manual visualizer and should not be treated as supported automated features.

## Manual click visualizer

Close the production controller and launch **`ADBcoc_bot_click_visualizer.ahk`** to open **CoC Manual Click Visualizer**. It shares local calibration and runtime helpers with the bot.

| Area | Purpose |
| --- | --- |
| **Overview** | Run a selected path once: a full cycle, resource collection, upgrades, deployment, recovery, or a Builder Base attack. Paths do not repeat automatically. |
| **Inspect** | Read connection/calibration status, screenshots, village, resource thresholds, builders, laboratory, loot, and other game state. |
| **Navigation, Upgrades, Walls, Slots, Deploy, Abilities, Builder** | Run individual actions. Prepare the matching game screen first. |
| **Calibration** | Run the wizards and save to the same `config.ini`. |
| **InTesting** | Unfinished pet/workshop actions. |

Overlay colors identify **pink taps**, **cyan gestures**, and **yellow read regions**. This tool sends real game inputs: upgrade confirmations can spend resources and deployment actions can deploy troops. It is not a simulation.

## Hotkeys

| Hotkey | Action |
| --- | --- |
| Ctrl + Shift + F1 | Start; detect the current village and select its loop. |
| Ctrl + Shift + F2 | Pause the bot loop. |
| Ctrl + Shift + Alt + F1 | Start/cancel Main Village calibration. |
| Ctrl + Shift + Alt + F2 | Start/cancel Builder Base calibration. |
| Space | Record the requested calibration point. |
| Enter | Finish calibration at its final step. |
| Esc | Cancel active calibration; otherwise exit when the bot GUI has focus. |

## Background operation and troubleshooting

After calibration, the bot and emulator can run on another Windows virtual desktop. Runtime checks use ADB to verify the selected device and that Clash of Clans is the foreground **Android app**. Calibration still requires a visible emulator on the active desktop.

| Problem | Check |
| --- | --- |
| ADB connection fails | Enable emulator ADB, check provider/serial, and use Test Connection. If `adb.exe` is not discovered, add its folder to `PATH` and restart the bot. |
| Target window is not found | Match Target Window Title to the emulator's actual Windows title and keep it visible during calibration. |
| Calibration is rejected or taps miss | Re-run Main calibration with correct Android viewport bounds. Also run BB calibration for Builder Base targets. Check for resolution/layout changes. |
| Vision setup fails | Confirm uv is installed and run `uv sync --locked` from the repository folder. Read the Activity Log error. |
| Loot or upgrade reads are wrong | Check calibrated icon/threshold points and game layout. Use the visualizer's Inspect actions to examine reads before restarting the loop. |
| Another controller is already running | Close the other bot/visualizer instance before starting a new one. |

## Updating and reporting issues

For a Git checkout, stop the bot and run `git pull --ff-only`, then `uv sync --locked`. For a ZIP installation, extract the full new copy and preserve your local `config.ini`. Re-test the ADB connection and recalibrate if the new code requests it or your emulator layout changed.

The [tutorial](Tutorial.md) links to the existing video; use this README for current GUI labels and setup. [Report issues](https://github.com/parm2006/ClashofClanker/issues) with your emulator/provider, display resolution, reproduction steps, and relevant Activity Log output. Contributions should explain the behavior changed and checks run; do not commit personal `config.ini`, `.venv`, or scratch screenshots.

## License and disclaimer

Licensed under [GNU GPL v3](LICENSE).

This project is for educational purposes. Automated botting is against Supercell's Terms of Service and can result in temporary or permanent account suspension. Use at your own risk; the authors and contributors are not responsible for account actions or damages.
