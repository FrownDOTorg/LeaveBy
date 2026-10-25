package com.frowndotorg.leaveby;

import android.app.*;
import android.appwidget.*;
import android.content.*;
import android.os.SystemClock;
import android.view.View;
import android.widget.RemoteViews;
import java.text.DateFormat;
import java.util.*;

public class DepartureWidget extends AppWidgetProvider {
    private static final String REFRESH="com.frowndotorg.leaveby.WIDGET_REFRESH";
    private static PendingIntent refresh(Context c) {
        return PendingIntent.getBroadcast(c,22,new Intent(c,DepartureWidget.class).setAction(REFRESH),
            PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
    }
    public static void update(Context c) {
        AppWidgetManager manager=AppWidgetManager.getInstance(c);
        int[] ids=manager.getAppWidgetIds(new ComponentName(c,DepartureWidget.class));
        AlarmManager alarms=(AlarmManager)c.getSystemService(Context.ALARM_SERVICE);
        if(ids.length==0){alarms.cancel(refresh(c));return;}
        long now=System.currentTimeMillis();Plan next=null;
        for(Plan plan:PlanStore.all(c))if(plan.departure()>now && (next==null || plan.departure()<next.departure()))next=plan;
        ThemePalette palette=ThemePalette.load(c);
        for(int id:ids) {
            RemoteViews view=new RemoteViews(c.getPackageName(),R.layout.departure_widget);
            view.setInt(R.id.widget_root,"setBackgroundResource","R".equals(ThemePalette.selected(c))?R.drawable.widget_r:R.drawable.widget_j);
            view.setTextColor(R.id.widget_heading,palette.color("accent","#A181D8"));
            view.setTextColor(R.id.widget_title,palette.color("text","#F4F0FA"));
            view.setTextColor(R.id.widget_timer,palette.color("accent","#A181D8"));
            view.setTextColor(R.id.widget_detail,palette.color("muted","#C7BED5"));
            if(next==null) {
                view.setTextViewText(R.id.widget_heading,"LEAVEBY");
                view.setTextViewText(R.id.widget_title,"Room for something good");
                view.setViewVisibility(R.id.widget_timer,View.GONE);
                view.setTextViewText(R.id.widget_detail,"Tap to plan your next outing.");
            } else {
                view.setTextViewText(R.id.widget_heading,"YOUR NEXT DEPARTURE");
                view.setTextViewText(R.id.widget_title,next.title);
                view.setViewVisibility(R.id.widget_timer,View.VISIBLE);
                view.setBoolean(R.id.widget_timer,"setCountDown",true);
                view.setChronometer(R.id.widget_timer,SystemClock.elapsedRealtime()+next.departure()-now,null,true);
                view.setTextViewText(R.id.widget_detail,"Leave "+DateFormat.getDateTimeInstance(DateFormat.SHORT,DateFormat.SHORT).format(new Date(next.departure())));
            }
            Intent open=new Intent(c,MainActivity.class);
            if(next!=null)open.putExtra("planId",next.id);
            PendingIntent tap=PendingIntent.getActivity(c,id,open,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
            view.setOnClickPendingIntent(R.id.widget_root,tap);manager.updateAppWidget(id,view);
        }
        if(next!=null)alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,next.departure()+1000,refresh(c));
        else alarms.cancel(refresh(c));
    }
    @Override public void onUpdate(Context c,AppWidgetManager manager,int[] ids){update(c);}
    @Override public void onReceive(Context c,Intent intent) {
        super.onReceive(c,intent);
        if(REFRESH.equals(intent.getAction()) || Intent.ACTION_TIME_CHANGED.equals(intent.getAction()) || Intent.ACTION_TIMEZONE_CHANGED.equals(intent.getAction()))update(c);
    }
    @Override public void onDisabled(Context c){((AlarmManager)c.getSystemService(Context.ALARM_SERVICE)).cancel(refresh(c));}
}

