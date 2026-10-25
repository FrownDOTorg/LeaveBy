package com.frowndotorg.leaveby;

public final class DepartureMath {
    private DepartureMath() {}
    public static long departure(long arrival, int travel, int buffer) {
        if (travel < 0 || buffer < 0) throw new IllegalArgumentException("Durations must be positive");
        return arrival - ((long) travel + buffer) * 60_000L;
    }
    public static String cleanName(String name) {
        String clean = name == null ? "" : name.trim().replaceAll("\\s+", " ");
        int count = clean.codePointCount(0, clean.length());
        return count <= 40 ? clean : clean.substring(0, clean.offsetByCodePoints(0, 40));
    }
}

