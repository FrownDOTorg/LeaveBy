package com.frowndotorg.leaveby;
import java.util.*;

public final class PlanQueries {
    private PlanQueries(){}
    public static boolean matches(String query,String... values) {
        String term=query==null?"":query.trim().toLowerCase(Locale.ROOT);
        if(term.isEmpty())return true;
        for(String value:values)if(value!=null && value.toLowerCase(Locale.ROOT).contains(term))return true;
        return false;
    }
    public static boolean sameDay(long a,long b) {
        Calendar first=Calendar.getInstance(),second=Calendar.getInstance();
        first.setTimeInMillis(a);second.setTimeInMillis(b);
        return first.get(Calendar.YEAR)==second.get(Calendar.YEAR) &&
            first.get(Calendar.DAY_OF_YEAR)==second.get(Calendar.DAY_OF_YEAR);
    }
}

