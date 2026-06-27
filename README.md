# Clash of Clans Automation Bot

An automated AutoHotkey (AHK) v2.0 script for Clash of Clans, designed to handle multiplayer loot farming, resource collection, and wall upgrades.

## Features
- **Client-Relative Clicks**: Immune to window movement, maximized states, and scaling issues.
- **Auto Loot Search**: Scans and parses Gold and Elixir counts in matchmaking using OCR.
- **Smart Deployment**: Deploys troops, siege machines, heroes, and spells sequentially.
- **Automated Upgrades**: Upgrades walls dynamically based on custom resource thresholds.
- **Builder Base Support**: Fully automated Builder Base attacks (Phase 1 & 2 support) with dynamic transitioning based on battle results and stars.
- **Automatic Base Detection**: Automatically detects whether you are viewing the Main Village or Builder Base and runs the appropriate loop.
- **Interactive Calibration**: Simple wizards to calibrate click targets relative to your game viewport for both Main Village and Builder Base.

---

## Prerequisites
1. **AutoHotkey v2.0+**: Ensure you have AHK v2 installed on your system.
2. **Game Window**: The Clash of Clans emulator window (e.g., Google Play Games PC, BlueStacks, LDPlayer) must be open.

---

## Getting Started & Calibration

Because screen sizes and window placements differ, **you must calibrate the bot before running it**. The local `config.ini` settings are ignored by Git so that each installation has its own customized settings.

### Main Village Calibration Steps (`Ctrl + F1`)
1. Double-click `coc_bot.ahk` to launch the bot GUI.
2. Click **Start Calibration** in the GUI or press **`Ctrl + F1`**.
3. Switch to the game window. Follow the onscreen tooltips to calibrate the 25 targets:
   - **Steps 1–3 (Home Village - Storage & Focus)**: Gold Storage Bar Threshold, Elixir Storage Bar Threshold, Builder Face.
   - **Steps 4–8 (Home Village - Wall Upgrades)**: Upgrade More, Add Wall (+1), Remove Wall (-1), Gold Upgrade, Elixir Upgrade.
   - **Steps 9–11 (Navigation Menus)**: Attack, Find Match, Green Attack Start.
   - **Steps 12–14 (In-Battle Metrics)**: Loot Gold Area, Loot Elixir Area, Next Match.
   - **Step 15 (Base Detection)**: Main Village Logo (War/Season Challenge icon).
   - **Steps 16–23 (Deployment Sides)**: Starting and ending points for Sides 1, 2, 3, and 4.
   - **Step 24 (Battle End)**: Return Home Button.
   - **Step 25 (Resource Collectors)**: Hover over your Gold Mines, Elixir Collectors, or Dark Elixir Drills and press **`SPACE`** to add each one. Press **`ENTER`** to finish and save.

### Builder Base Calibration Steps (`Ctrl + F2`)
1. In the Builder Base, press **`Ctrl + F2`** to start calibration.
2. Follow the tooltips to calibrate the 5 targets:
   - **Step 1**: BB Attack Button
   - **Step 2**: BB Find Match Button
   - **Steps 3-5**: The 3 stars at the top of the battle screen (used to detect phase transition).

---

## GUI Customization (Settings & Farming)

The bot GUI includes tabs that allow you to customize configuration variables at runtime:

### Farming Tab
- **Enable Auto Loot Search**: Toggles OCR loot checking during matchmaking. Checked by default.
- **Minimum Gold / Elixir Limits**: Sets the minimum threshold (default: `500,000` each). The bot will click 'Next Match' if the base doesn't meet either of these limits.
- **Enable Auto Wall Upgrade**: Toggles automatic wall upgrading. Checked by default. When storage bar threshold points are full, the bot will automatically dump resources into upgrading walls.
- **Resource Collection**: Displays the total count of registered resource collectors (Gold Mines, Elixir Collectors, DE Drills).

### Settings Tab
- **Delays (ms)**: Fine-tune timing durations:
  - **Troop Spam Click Delay**: Cooldown between clicks during troop deployment.
  - **Battle Load Delay**: How long to wait for the battle map to load before deploying.
  - **Home Load Delay**: Wait duration when transitioning back to home village.
- **Randomization Offsets (pixels)**: Adds human-like click variance:
  - **Button Click Variance**: Random pixel variance added to button click positions.
  - **Troop Deploy Variance**: Random pixel variance added when deploying troops.
- **Troop Deployment Clicks**: Sets the number of clicks/spams for Troop 1, Troop 2, and Troop 3.

---

## Hotkeys

| Hotkey | Action |
| --- | --- |
| **`Ctrl + F1`** | Start / Cancel Main Village Calibration |
| **`Ctrl + F2`** | Start / Cancel Builder Base Calibration |
| **`F1`** | Unified Start (Detects Base and Starts Loop) |
| **`F2`** | Pause Bot Loop |
| **`ESC`** | Exit Bot |

---

## License
This project is licensed under the GPL v3 License - see the `LICENSE` file for details.

## Disclaimer

This project is for educational purposes only. Automated botting is strictly against Supercell's Terms of Service. Using this bot or any automated script may result in a temporary ban or permanent suspension of your Clash of Clans account. The creators and contributors of this project are not responsible for any actions taken against your account or any damages incurred. Use at your own risk.
