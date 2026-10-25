package com.frowndotorg.leaveby;

import android.Manifest;
import android.app.*;
import android.content.*;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;

public class ReminderReceiver extends BroadcastReceiver {
    private static final String CHANNEL = "departures";
    public static PendingIntent pending(Context c, String id) {
        Intent i = new Intent(c, ReminderReceiver.class).setData(Uri.parse("leaveby://reminder/" + id)).putExtra("id", id);
        return PendingIntent.getBroadcast(c, 0, i, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }
    public static void schedule(Context c, Plan p) {
        AlarmManager alarm = (AlarmManager)c.getSystemService(Context.ALARM_SERVICE);
        // Intentionally inexact: no special exact-alarm access is required.
        alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, p.departure(), pending(c, p.id));
    }
    public static void cancel(Context c, String id) {
        ((AlarmManager)c.getSystemService(Context.ALARM_SERVICE)).cancel(pending(c, id));
        ((NotificationManager)c.getSystemService(Context.NOTIFICATION_SERVICE)).cancel(id, 1);
    }
    public static boolean allowed(Context c) {
        if (Build.VERSION.SDK_INT >= 33 && c.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return false;
        return Build.VERSION.SDK_INT < 24 || ((NotificationManager)c.getSystemService(Context.NOTIFICATION_SERVICE)).areNotificationsEnabled();
    }
    @android.annotation.SuppressLint("MissingPermission") // allowed() checks permission before notifying.
    public static void show(Context c, Plan p, boolean test) {
        if (!allowed(c)) return;
        NotificationManager manager = (NotificationManager)c.getSystemService(Context.NOTIFICATION_SERVICE);
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(new NotificationChannel(CHANNEL, "Departure reminders", NotificationManager.IMPORTANCE_HIGH));
        String name = PlanStore.name(c);
        String heading = test ? "Your test reminder is here!" : (name.isEmpty() ? "Time to head out" : name + ", it's time to head out");
        Intent open = new Intent(c, MainActivity.class);
        PendingIntent tap = PendingIntent.getActivity(c, 0, open, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        Notification.Builder b = Build.VERSION.SDK_INT >= 26 ? new Notification.Builder(c, CHANNEL) : new Notification.Builder(c);
        b.setSmallIcon(com.frowndotorg.leaveby.R.drawable.ic_leaveby)
            .setContentTitle(heading).setContentText(test ? "You're ready to try LeaveBy reminders." : "Time to leave for " + p.title + ". Have a good trip!")
            .setContentIntent(tap).setAutoCancel(true).setVisibility(Notification.VISIBILITY_PRIVATE)
            .setPriority(Notification.PRIORITY_HIGH);
        manager.notify(p.id, test ? 2 : 1, b.build());
    }
    @Override public void onReceive(Context c, Intent intent) {
        Plan p = PlanStore.find(c, intent.getStringExtra("id"));
        if (p == null || !p.reminder) return;
        p.reminder = false; PlanStore.put(c, p);
        show(c, p, false);
    }
}
