# Clash of Clanker tutorial

The existing [video tutorial on YouTube](https://youtu.be/OE67o9Qc3Jw) is a companion reference. Its GUI labels, calibration sequence, and setup may differ from the current code. Follow the [README](README.md) for current instructions.

## Current setup and first run

1. Install AutoHotkey v2, an ADB-enabled emulator, and uv. Download the complete repository and run `uv sync --locked` inside its folder. The vision runtime uses Python 3.13 and the locked OpenCV dependency; a global `pip install` is unnecessary.
2. Open Clash of Clans and launch `ADBcoc_bot.ahk`. Set **Target Window Title** in **Control**. Select Habumi, Google Play Games Developer Emulator, or BlueStacks in **ADB**, check the target serial, and click **Test Connection**.
3. Open **Calibration** and run **Main Calib**. The current wizard has **30 steps**, starting with the Android viewport corners. Hover over each requested point and press **Space**. At the collector step, record each collector with Space and finish with **Enter**. Follow the changing prompt; the static tab summary is older than the wizard.
4. For Builder Base, also run the **13-step BB Calib** wizard. It records attack buttons, the three results-screen stars, and four deployment lines. Record the final endpoint, then press Enter to save.
5. Review **Farming** and **Settings**. Valid edits save automatically to local `config.ini`; there is no Save Settings button. **No upgrades** in Settings disables resource-threshold eligibility for automatic upgrades.
6. Return to a village home screen. Optionally set the auto-stop timer in **Control**, then click **Start Bot**. Watch the Activity Log and use **Pause Bot** or **Ctrl + Shift + F2** to stop.

See the [calibration tables](README.md#calibration), [GUI reference](README.md#controller-gui), and [troubleshooting guide](README.md#background-operation-and-troubleshooting) for details.

## Inspecting actions

Close the production controller and launch `ADBcoc_bot_click_visualizer.ahk` for the manual visualizer. **Inspect** reads game state; **Overview** runs a selected path once; the other action tabs expose individual inputs. It shares `config.ini` with the production bot.

The visualizer controls the real game. Upgrade confirmations can spend resources, and battle actions can deploy troops. Pet and workshop upgrade actions marked unfinished are not implemented.
