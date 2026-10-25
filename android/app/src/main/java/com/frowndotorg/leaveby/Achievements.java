package com.frowndotorg.leaveby;

import android.app.*;
import android.content.*;
import android.os.Build;
import org.json.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.text.DateFormat;
import java.util.*;

public final class Achievements {
    private Achievements() {}
    private static JSONArray tiers;
    public static class Badge {
        public final String title,body;
        public final int milestone;
        Badge(String title,String body,int milestone) {this.title=title;this.body=body;this.milestone=milestone;}
    }
    private static JSONArray tiers(Context c) {
        if(tiers!=null)return tiers;
        try(BufferedReader reader=new BufferedReader(new InputStreamReader(c.getAssets().open("achievements.json"),StandardCharsets.UTF_8))) {
            StringBuilder json=new StringBuilder(); String line;
            while((line=reader.readLine())!=null)json.append(line);
            tiers=new JSONObject(json.toString()).getJSONArray("tiers");
        } catch(IOException|JSONException e) {tiers=new JSONArray();}
        return tiers;
    }
    private static String dayKey(long time) {
        Calendar day=Calendar.getInstance();day.setTimeInMillis(time);
        return String.format(Locale.ROOT,"%04d-%02d-%02d",day.get(Calendar.YEAR),day.get(Calendar.MONTH)+1,day.get(Calendar.DAY_OF_MONTH));
    }
    public static Badge badge(Context c,int count,long day) {
        try {
            JSONArray all=tiers(c);JSONObject best=null;
            int[] thresholds=new int[all.length()];
            for(int i=0;i<all.length();i++) thresholds[i]=all.getJSONObject(i).getInt("count");
            int milestone=AchievementRules.highestReached(count,thresholds);
            if(milestone==0)return null;
            for(int i=0;i<all.length();i++) if(all.getJSONObject(i).getInt("count")==milestone)best=all.getJSONObject(i);
            if(best==null)return null;
            JSONArray titles=best.getJSONArray("titles"),messages=best.getJSONArray("messages");
            String key="achievement.variant."+dayKey(day)+"."+milestone;
            int variant=PlanStore.prefs(c).getInt(key,-1);
            if(variant<0) {variant=new Random().nextInt(Math.max(titles.length(),messages.length()));PlanStore.prefs(c).edit().putInt(key,variant).apply();}
            String name=PlanStore.name(c);
            String date=dayKey(day).equals(dayKey(System.currentTimeMillis()))?"today":"on "+DateFormat.getDateInstance(DateFormat.MEDIUM).format(new Date(day));
            String body=messages.getString(variant%messages.length()).replace("{namePrefix}",name.isEmpty()?"":name+", ")
                .replace("{count}",String.valueOf(count)).replace("{day}",date);
            return new Badge(titles.getString(variant%titles.length()),body,milestone);
        } catch(JSONException e) {return null;}
    }
    public static void evaluate(Context c,List<Plan> plans) {
        Map<String,List<Plan>> groups=new HashMap<>();
        for(Plan p:plans)groups.computeIfAbsent(dayKey(p.arrival),key->new ArrayList<>()).add(p);
        Calendar today=Calendar.getInstance();today.set(Calendar.HOUR_OF_DAY,0);today.set(Calendar.MINUTE,0);today.set(Calendar.SECOND,0);today.set(Calendar.MILLISECOND,0);
        for(Map.Entry<String,List<Plan>> group:groups.entrySet()) {
            long day=group.getValue().get(0).arrival;
            Badge badge=badge(c,group.getValue().size(),day);if(badge==null)continue;
            String key="achievement.highest."+group.getKey();
            if(!AchievementRules.shouldNotify(badge.milestone,PlanStore.prefs(c).getInt(key,0)))continue;
            PlanStore.prefs(c).edit().putInt(key,badge.milestone).apply();
            if(day<today.getTimeInMillis() || !PlanStore.prefs(c).getBoolean("achievementNotifications",true))continue;
            notify(c,badge,group.getKey());
        }
    }
    @android.annotation.SuppressLint("MissingPermission") // Reuses the checked notification permission.
    private static void notify(Context c,Badge badge,String dayKey) {
        if(!ReminderReceiver.allowed(c))return;
        NotificationManager manager=(NotificationManager)c.getSystemService(Context.NOTIFICATION_SERVICE);
        String channel="achievements";
        if(Build.VERSION.SDK_INT>=26)manager.createNotificationChannel(new NotificationChannel(channel,"Playful achievements",NotificationManager.IMPORTANCE_DEFAULT));
        PendingIntent tap=PendingIntent.getActivity(c,3,new Intent(c,MainActivity.class),PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
        Notification.Builder builder=Build.VERSION.SDK_INT>=26?new Notification.Builder(c,channel):new Notification.Builder(c);
        builder.setSmallIcon(R.drawable.ic_leaveby).setContentTitle(badge.title).setContentText(badge.body)
            .setStyle(new Notification.BigTextStyle().bigText(badge.body)).setAutoCancel(true).setContentIntent(tap)
            .setVisibility(Notification.VISIBILITY_PRIVATE);
        manager.notify("achievement."+dayKey,3,builder.build());
    }
}

