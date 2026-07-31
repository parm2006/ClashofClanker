package com.cocbot.pinchtest;

import java.util.List;

public final class PinchPlanTest {
    public static void main(String[] args) {
        createsSymmetricPinchOut();
        createsPinchIn();
        interpolatesBothPointers();
        ordersPointerActions();
        rejectsInvalidInput();
        System.out.println("PASS: PinchPlan tests");
    }

    private static void createsSymmetricPinchOut() {
        PinchPlan plan = PinchPlan.create(500, 400, 50, 150, 320);
        assertEquals(450f, plan.startX0, "start left X");
        assertEquals(550f, plan.startX1, "start right X");
        assertEquals(350f, plan.endX0, "end left X");
        assertEquals(650f, plan.endX1, "end right X");
        assertEquals(400f, plan.y, "shared Y");
        assertTrue(plan.isPinchOut(), "pinch-out direction");
    }

    private static void createsPinchIn() {
        PinchPlan plan = PinchPlan.create(500, 400, 150, 50, 320);
        assertFalse(plan.isPinchOut(), "pinch-in direction");
        assertEquals(350f, plan.startX0, "pinch-in start left X");
        assertEquals(450f, plan.endX0, "pinch-in end left X");
    }

    private static void interpolatesBothPointers() {
        PinchPlan plan = PinchPlan.create(500, 400, 50, 150, 320);
        PinchPlan.Points halfway = plan.pointsAt(0.5f);
        assertEquals(400f, halfway.x0, "halfway left X");
        assertEquals(600f, halfway.x1, "halfway right X");
        assertEquals(400f, halfway.y0, "halfway left Y");
        assertEquals(400f, halfway.y1, "halfway right Y");
    }

    private static void ordersPointerActions() {
        PinchPlan plan = PinchPlan.create(500, 400, 50, 150, 320);
        List<PinchPlan.Frame> frames = plan.frames();
        assertEquals(PinchPlan.Action.DOWN, frames.get(0).action, "first action");
        assertEquals(PinchPlan.Action.POINTER_DOWN, frames.get(1).action, "second action");
        assertEquals(PinchPlan.Action.MOVE, frames.get(2).action, "first move");
        assertEquals(PinchPlan.Action.POINTER_UP, frames.get(frames.size() - 2).action, "penultimate action");
        assertEquals(PinchPlan.Action.UP, frames.get(frames.size() - 1).action, "last action");
        assertEquals(0L, frames.get(0).elapsedMs, "down elapsed time");
        assertEquals(320L, frames.get(frames.size() - 1).elapsedMs, "up elapsed time");
    }

    private static void rejectsInvalidInput() {
        assertThrows(() -> PinchPlan.create(-1, 400, 50, 150, 320), "negative center");
        assertThrows(() -> PinchPlan.create(500, 400, 0, 150, 320), "zero radius");
        assertThrows(() -> PinchPlan.create(500, 400, 50, 50, 320), "equal radii");
        assertThrows(() -> PinchPlan.create(25, 400, 50, 150, 320), "negative calculated coordinate");
        assertThrows(() -> PinchPlan.create(500, 400, 50, 150, 49), "short duration");
        assertThrows(() -> PinchPlan.create(500, 400, 50, 150, 5001), "long duration");
    }

    private static void assertThrows(Runnable action, String description) {
        try {
            action.run();
        } catch (IllegalArgumentException expected) {
            return;
        }
        throw new AssertionError(description + ": expected IllegalArgumentException");
    }

    private static void assertTrue(boolean actual, String description) {
        if (!actual) {
            throw new AssertionError(description + ": expected true");
        }
    }

    private static void assertFalse(boolean actual, String description) {
        if (actual) {
            throw new AssertionError(description + ": expected false");
        }
    }

    private static void assertEquals(Object expected, Object actual, String description) {
        if (!expected.equals(actual)) {
            throw new AssertionError(description + ": expected " + expected + ", got " + actual);
        }
    }

    private static void assertEquals(float expected, float actual, String description) {
        if (Float.compare(expected, actual) != 0) {
            throw new AssertionError(description + ": expected " + expected + ", got " + actual);
        }
    }
}

