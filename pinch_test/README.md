# Pinch Test

The root-level `adb_gesture_test.ahk` is the single standalone GUI for ADB tap, swipe, pinch-in, and pinch-out testing. It does not import or modify the Clash bot.

## Run the test

1. Launch Google Play Games Developer Emulator or BlueStacks.
2. Open the Android app you want to test and leave it in the foreground inside Android.
3. Run `..\adb_gesture_test.ahk` with AutoHotkey v2.
4. Select the emulator and click **Test Connection**.
5. Enter Android display coordinates, radii, and duration.
6. Click **Tap**, **Swipe**, or **Pinch**.

The helper APKs under `dist/` install automatically on the first pinch that needs them. Tap and swipe use built-in ADB commands. The emulator's Windows window does not need focus and may remain minimized or behind another window.

The GUI caches a successful connection until the selected emulator changes or a gesture fails. It also caches helper readiness after the first pinch, avoiding repeated package checks.

## Coordinates and direction

- Center X and Center Y use Android display coordinates from `adb shell wm size`.
- The two fingers sit horizontally around the center.
- End Radius greater than Start Radius pinches out.
- End Radius less than Start Radius pinches in.
- Duration accepts 50-5000 milliseconds.

The default values target the center of a 1920x1080 Android display.

## Supported emulator connections

- GPGDE: fixed at `localhost:6520`.
- BlueStacks: one editable local serial such as `127.0.0.1:5555`.

This proof controls one emulator at a time. It does not support physical Android devices or multi-instance synchronization.

## Rebuild the APKs

End users do not need Java, Android Studio, Gradle, Python, Node, or Appium. The following steps are only for maintainers rebuilding the bundled APKs.

The local development setup used for this proof places Microsoft OpenJDK 17 and Android API/build-tools 35 under the ignored `.tooling/` directory. With those tools present, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\pinch_test\android-helper\test.ps1
powershell -ExecutionPolicy Bypass -File .\pinch_test\android-helper\build.ps1
```

The build produces:

- `dist/pinch-target.apk`
- `dist/pinch-instrumentation.apk`

The instrumentation uses Android's `UiAutomation.injectInputEvent` API. It creates `DOWN`, `POINTER_DOWN`, timed `MOVE`, `POINTER_UP`, and `UP` events without relying on accessibility nodes or raw `/dev/input` access.
