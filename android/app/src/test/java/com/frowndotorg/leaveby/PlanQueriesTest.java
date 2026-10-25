package com.frowndotorg.leaveby;
import org.junit.Test;
import static org.junit.Assert.*;
import java.util.*;

public class PlanQueriesTest {
    @Test public void searchIsCaseInsensitiveAndIncludesNotes() {
        assertTrue(PlanQueries.matches("  TICKETS  ","Concert","Bring tickets"));
        assertFalse(PlanQueries.matches("airport","Concert","Bring tickets"));
        assertTrue(PlanQueries.matches("",(String)null));
    }
    @Test public void calendarDatesIgnoreTimeOfDay() {
        Calendar a=Calendar.getInstance();a.set(2026,9,25,1,0,0);
        Calendar b=(Calendar)a.clone();b.set(Calendar.HOUR_OF_DAY,23);
        assertTrue(PlanQueries.sameDay(a.getTimeInMillis(),b.getTimeInMillis()));
        b.add(Calendar.DATE,1);
        assertFalse(PlanQueries.sameDay(a.getTimeInMillis(),b.getTimeInMillis()));
    }
    @Test public void sameDayNumberInAnotherYearDoesNotMatch() {
        Calendar a=Calendar.getInstance();a.set(2025,0,1,12,0,0);
        Calendar b=(Calendar)a.clone();b.set(Calendar.YEAR,2026);
        assertFalse(PlanQueries.sameDay(a.getTimeInMillis(),b.getTimeInMillis()));
    }
}

