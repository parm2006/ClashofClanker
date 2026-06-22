# Clash of Clans Automation Bot

An automated AutoHotkey (AHK) v2.0 script for Clash of Clans, designed to handle multiplayer loot farming, resource collection, and wall upgrades.

## Features
- **Client-Relative Clicks**: Immune to window movement, maximized states, and scaling issues.
- **Auto Loot Search**: Scans and parses Gold and Elixir counts in matchmaking using OCR.
- **Smart Deployment**: Deploys troops, siege machines, heroes, and spells sequentially.
- **Automated Upgrades**: Upgrades walls dynamically based on custom resource thresholds.
- **Interactive Calibration**: Simple wizard to calibrate click targets relative to your game viewport.

---

## Prerequisites
1. **AutoHotkey v2.0+**: Ensure you have AHK v2 installed on your system.
2. **Game Window**: The Clash of Clans emulator window (e.g., Google Play Games PC, BlueStacks, LDPlayer) must be open.

---

## Getting Started & Calibration

Because screen sizes and window placements differ, **you must calibrate the bot before running it**. The local `config.ini` settings are ignored by Git so that each installation has its own customized settings.

### Calibration Steps
1. Double-click `coc_bot.ahk` to launch the bot GUI.
2. Click **Start Calibration** in the GUI or press **`Ctrl + F1`**.
3. Switch to the game window. Follow the onscreen tooltips to calibrate the 25 targets:
   - **Steps 1–4 (Home Village)**: Attack Button, Builder Face, Gold Storage Bar, Elixir Storage Bar.
   - **Steps 5–9 (Home Village Wall Upgrades)**: Upgrade More, Add Wall (+1), Remove Wall (-1), Gold Upgrade, Elixir Upgrade.
   - **Steps 10–11 (Multiplayer Menus)**: Find Match, Green Attack button.
   - **Steps 12–16 (In-Battle Metrics)**: Loot Gold Area, Loot Elixir Area, Next Match, Return Home Left, Return Home Right.
   - **Steps 17–24 (Deployment Sides)**: Starting and ending points for Sides 1, 2, 3, and 4.
   - **Step 25 (Resource Collectors)**: Hover over your Gold Mines, Elixir Collectors, or Dark Elixir Drills and press **`SPACE`** to add each one. Press **`ENTER`** to finish and save.

---

## Hotkeys

| Hotkey | Action |
| --- | --- |
| **`Ctrl + F1`** | Start / Cancel Interactive Calibration |
| **`F1`** | Start Bot Loop |
| **`F2`** | Pause Bot Loop |
| **`ESC`** | Exit Bot |

---

## License
This project is licensed under the GPL v3 License - see the `LICENSE` file for details.
