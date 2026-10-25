package com.frowndotorg.leaveby;

import org.junit.Test;
import static org.junit.Assert.*;

public class DepartureMathTest {
    @Test public void subtractsTravelAndBufferAcrossMidnight() {
        assertEquals(-600_000L, DepartureMath.departure(1_200_000L, 20, 10));
    }
    @Test public void zeroDurationsKeepArrival() {
        assertEquals(99L, DepartureMath.departure(99L, 0, 0));
    }
    @Test(expected = IllegalArgumentException.class) public void rejectsNegativeTravel() {
        DepartureMath.departure(0, -1, 10);
    }
    @Test public void preservesNicknameAndNormalizesWhitespace() {
        assertEquals("O'Neil Jo", DepartureMath.cleanName("  O'Neil  Jo  "));
        assertEquals("", DepartureMath.cleanName(null));
    }
    @Test public void longNamesDoNotSplitEmoji() {
        String name = "😀".repeat(45);
        assertEquals("😀".repeat(40), DepartureMath.cleanName(name));
    }
}

