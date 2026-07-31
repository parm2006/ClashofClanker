package com.cocbot.pinchtest;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public final class PinchPlan {
    public enum Action {
        DOWN,
        POINTER_DOWN,
        MOVE,
        POINTER_UP,
        UP
    }

    public static final class Points {
        public final float x0;
        public final float y0;
        public final float x1;
        public final float y1;

        private Points(float x0, float y0, float x1, float y1) {
            this.x0 = x0;
            this.y0 = y0;
            this.x1 = x1;
            this.y1 = y1;
        }
    }

    public static final class Frame {
        public final Action action;
        public final long elapsedMs;
        public final Points points;

        private Frame(Action action, long elapsedMs, Points points) {
            this.action = action;
            this.elapsedMs = elapsedMs;
            this.points = points;
        }
    }

    public final float startX0;
    public final float startX1;
    public final float endX0;
    public final float endX1;
    public final float y;
    public final int durationMs;

    private final int startRadius;
    private final int endRadius;

    private PinchPlan(int centerX, int centerY, int startRadius, int endRadius, int durationMs) {
        this.startX0 = centerX - startRadius;
        this.startX1 = centerX + startRadius;
        this.endX0 = centerX - endRadius;
        this.endX1 = centerX + endRadius;
        this.y = centerY;
        this.startRadius = startRadius;
        this.endRadius = endRadius;
        this.durationMs = durationMs;
    }

    public static PinchPlan create(int centerX, int centerY, int startRadius, int endRadius, int durationMs) {
        if (centerX < 0 || centerY < 0) {
            throw new IllegalArgumentException("Center coordinates must be nonnegative.");
        }
        if (startRadius <= 0 || endRadius <= 0) {
            throw new IllegalArgumentException("Radii must be positive.");
        }
        if (startRadius == endRadius) {
            throw new IllegalArgumentException("Start and end radii must differ.");
        }
        if (durationMs < 50 || durationMs > 5000) {
            throw new IllegalArgumentException("Duration must be between 50 and 5000 ms.");
        }

        int largestRadius = Math.max(startRadius, endRadius);
        if (centerX < largestRadius || ((long) centerX + largestRadius) > Integer.MAX_VALUE) {
            throw new IllegalArgumentException("The pinch extends outside valid display coordinates.");
        }
        return new PinchPlan(centerX, centerY, startRadius, endRadius, durationMs);
    }

    public boolean isPinchOut() {
        return endRadius > startRadius;
    }

    public Points pointsAt(float progress) {
        if (progress < 0f || progress > 1f) {
            throw new IllegalArgumentException("Progress must be between 0 and 1.");
        }
        float leftX = startX0 + ((endX0 - startX0) * progress);
        float rightX = startX1 + ((endX1 - startX1) * progress);
        return new Points(leftX, y, rightX, y);
    }

    public List<Frame> frames() {
        int moveSteps = Math.max(2, (int) Math.ceil(durationMs / 16.0));
        List<Frame> frames = new ArrayList<>(moveSteps + 4);
        Points start = pointsAt(0f);
        frames.add(new Frame(Action.DOWN, 0L, start));
        frames.add(new Frame(Action.POINTER_DOWN, 0L, start));

        for (int step = 1; step <= moveSteps; step++) {
            float progress = step / (float) moveSteps;
            long elapsedMs = Math.round(durationMs * progress);
            frames.add(new Frame(Action.MOVE, elapsedMs, pointsAt(progress)));
        }

        Points end = pointsAt(1f);
        frames.add(new Frame(Action.POINTER_UP, durationMs, end));
        frames.add(new Frame(Action.UP, durationMs, end));
        return Collections.unmodifiableList(frames);
    }
}

