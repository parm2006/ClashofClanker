# Clash of Clanker Video Tutorial

Watch the video tutorial on YouTube:
[Clash of Clanker Video Tutorial](https://youtu.be/OE67o9Qc3Jw)

---

## Tutorial

1) **Launch the Bot:** Double-click `coc_bot.ahk` to open the GUI.
2) **Configure Limits:** Set your farming limits in the GUI (e.g. 500k Gold/Elixir minimum, and toggle Wall Upgrades on/off). **Note: You must click the 'Save Settings' button at the bottom of the tab to save and apply any changes.** 
3) **Run Calibration (`Ctrl + F1`):** The bot will maximize the game window and guide you through 26 calibration steps:
   - **Step 1–2:** Gold and Elixir storage thresholds (tells the bot when your storages are full).
   - **Step 3:** The Builder Head icon (top-center of the screen).
   - **Steps 4–8:** Wall upgrade menu coordinates (Upgrade More, Add Wall, Remove Wall, Gold/Elixir upgrade buttons).
   - **Step 9:** **Upgrade Confirm Button** (Hover over the green 'Upgrade' confirmation button on a standard building's confirmation popup and press SPACE).
   - **Steps 10–12:** Navigation menu buttons (Attack, Find a Match, Green Start Attack).
   - **Steps 13–15:** Matchmaking loot scanning and Next button.
   - **Step 16:** Base detection logo (War/Season logo above the attack button).
   - **Steps 17–24:** Deploy starting and ending coordinates for the 4 deployment lines surrounding the base.
   - **Step 25:** Return Home button at the end of the battle.
   - **Step 26:** Resource Collectors (Hover over your Gold Mines, Elixir Collectors, or DE drills and press SPACE for each. Press ENTER to save).
4) **Suggested Upgrades Flow:**
   - The bot automatically scans your builder menu. If a builder is free **and both Gold and Elixir storages are past their threshold**, it clicks the first suggested upgrade.
   - For **Heroes**, it goes straight to the confirm coordinates.
   - For **Buildings**, it uses Python template matching (`upgrade_button_hook.py`) with your magenta template (`hammer_template_trans.png`) to locate the Upgrade button center.
   - By default, it hovers on the confirmation coordinates and clears the selection (skipping the actual click for testing safety).
5) **Builder Base Calibration (`Ctrl + F2`):** Run this if you want the bot to farm the Builder Base (it spams attacks and switches phases).
