package com.frowndotorg.leaveby;

import android.content.*;
public class BootReceiver extends BroadcastReceiver {
    @Override public void onReceive(Context c, Intent i) {
        if (!Intent.ACTION_BOOT_COMPLETED.equals(i.getAction())) return;
        DepartureWidget.update(c);
        for (Plan p : PlanStore.all(c)) if (p.reminder && p.departure() > System.currentTimeMillis()) ReminderReceiver.schedule(c, p);
    }
}
