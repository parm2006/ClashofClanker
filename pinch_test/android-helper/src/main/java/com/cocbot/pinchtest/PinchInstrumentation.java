package com.cocbot.pinchtest;

import android.app.Activity;
import android.app.Instrumentation;
import android.app.UiAutomation;
import android.os.Bundle;
import android.os.SystemClock;
import android.view.InputDevice;
import android.view.MotionEvent;

public final class PinchInstrumentation extends Instrumentation {
    private Bundle arguments;

    @Override
    public void onCreate(Bundle arguments) {
        super.onCreate(arguments);
        this.arguments = arguments == null ? new Bundle() : arguments;
        start();
    }

    @Override
    public void onStart() {
        Bundle result = new Bundle();
        try {
            PinchPlan plan = PinchPlan.create(
                    readInt("centerX"),
                    readInt("centerY"),
                    readInt("startRadius"),
                    readInt("endRadius"),
                    readInt("durationMs"));
            inject(plan);
            result.putString("stream", "Pinch injected successfully.\n");
            finish(Activity.RESULT_OK, result);
        } catch (Throwable error) {
            String message = error.getClass().getSimpleName() + ": " + error.getMessage();
            result.putString("shortMsg", message);
            result.putString("stream", "Pinch failed: " + message + "\n");
            finish(Activity.RESULT_CANCELED, result);
        }
    }

    private int readInt(String name) {
        String value = arguments.getString(name);
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException("Missing argument: " + name);
        }
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException error) {
            throw new IllegalArgumentException(name + " must be a whole number.");
        }
    }

    private void inject(PinchPlan plan) {
        UiAutomation automation = getUiAutomation();
        if (automation == null) {
            throw new IllegalStateException("UiAutomation is unavailable.");
        }

        long downTime = SystemClock.uptimeMillis();
        for (PinchPlan.Frame frame : plan.frames()) {
            long eventTime = downTime + frame.elapsedMs;
            long delay = eventTime - SystemClock.uptimeMillis();
            if (delay > 0L) {
                SystemClock.sleep(delay);
            }

            MotionEvent event = createEvent(downTime, eventTime, frame);
            try {
                if (!automation.injectInputEvent(event, true)) {
                    throw new IllegalStateException("Android rejected " + frame.action + " input.");
                }
            } finally {
                event.recycle();
            }
        }
    }

    private MotionEvent createEvent(long downTime, long eventTime, PinchPlan.Frame frame) {
        int pointerCount = pointerCount(frame.action);
        MotionEvent.PointerProperties[] properties = new MotionEvent.PointerProperties[pointerCount];
        MotionEvent.PointerCoords[] coordinates = new MotionEvent.PointerCoords[pointerCount];

        properties[0] = pointerProperties(0);
        coordinates[0] = pointerCoordinates(frame.points.x0, frame.points.y0);
        if (pointerCount == 2) {
            properties[1] = pointerProperties(1);
            coordinates[1] = pointerCoordinates(frame.points.x1, frame.points.y1);
        }

        return MotionEvent.obtain(
                downTime,
                eventTime,
                androidAction(frame.action),
                pointerCount,
                properties,
                coordinates,
                0,
                0,
                1f,
                1f,
                0,
                0,
                InputDevice.SOURCE_TOUCHSCREEN,
                0);
    }

    private static int pointerCount(PinchPlan.Action action) {
        return action == PinchPlan.Action.DOWN || action == PinchPlan.Action.UP ? 1 : 2;
    }

    private static int androidAction(PinchPlan.Action action) {
        switch (action) {
            case DOWN:
                return MotionEvent.ACTION_DOWN;
            case POINTER_DOWN:
                return MotionEvent.ACTION_POINTER_DOWN
                        | (1 << MotionEvent.ACTION_POINTER_INDEX_SHIFT);
            case MOVE:
                return MotionEvent.ACTION_MOVE;
            case POINTER_UP:
                return MotionEvent.ACTION_POINTER_UP
                        | (1 << MotionEvent.ACTION_POINTER_INDEX_SHIFT);
            case UP:
                return MotionEvent.ACTION_UP;
            default:
                throw new IllegalArgumentException("Unknown action: " + action);
        }
    }

    private static MotionEvent.PointerProperties pointerProperties(int id) {
        MotionEvent.PointerProperties properties = new MotionEvent.PointerProperties();
        properties.id = id;
        properties.toolType = MotionEvent.TOOL_TYPE_FINGER;
        return properties;
    }

    private static MotionEvent.PointerCoords pointerCoordinates(float x, float y) {
        MotionEvent.PointerCoords coordinates = new MotionEvent.PointerCoords();
        coordinates.x = x;
        coordinates.y = y;
        coordinates.pressure = 1f;
        coordinates.size = 1f;
        return coordinates;
    }
}

