package com.frowndotorg.leaveby;

import android.content.Context;
import android.database.Cursor;
import android.provider.CalendarContract;
import java.util.*;

public final class CalendarImports {
    private CalendarImports(){}
    @android.annotation.SuppressLint("MissingPermission") // Activity requests READ_CALENDAR before calling.
    public static List<Plan> read(Context c,long selectedDay) {
        Calendar start=Calendar.getInstance();start.setTimeInMillis(selectedDay);
        start.set(Calendar.HOUR_OF_DAY,0);start.set(Calendar.MINUTE,0);start.set(Calendar.SECOND,0);start.set(Calendar.MILLISECOND,0);
        Calendar end=(Calendar)start.clone();end.add(Calendar.DATE,1);
        List<Plan> found=new ArrayList<>();Set<String> existing=new HashSet<>();
        for(Plan p:PlanStore.all(c))if(!p.sourceKey.isEmpty())existing.add(p.sourceKey);
        String[] columns={CalendarContract.Instances.EVENT_ID,CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.TITLE,CalendarContract.Instances.EVENT_LOCATION,CalendarContract.Instances.ALL_DAY};
        try(Cursor cursor=CalendarContract.Instances.query(c.getContentResolver(),columns,start.getTimeInMillis(),end.getTimeInMillis())) {
            if(cursor==null)return found;
            while(cursor.moveToNext() && found.size()<100) {
                long begin=cursor.getLong(1);
                if(cursor.getInt(4)!=0 || begin<start.getTimeInMillis() || begin>=end.getTimeInMillis())continue;
                String key=cursor.getLong(0)+"|"+begin;
                if(!existing.add(key))continue;
                Plan p=new Plan();p.sourceKey=key;p.arrival=begin;
                p.title=cursor.isNull(2)?"Calendar event":cursor.getString(2);
                if(p.title.trim().isEmpty())p.title="Calendar event";
                p.destination=cursor.isNull(3)?"":cursor.getString(3);
                found.add(p);
            }
        }
        found.sort(Comparator.comparingLong(p->p.arrival));return found;
    }
}

