package com.frowndotorg.leaveby;

import android.Manifest;
import android.app.*;
import android.content.*;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.*;
import android.text.*;
import android.view.*;
import android.widget.*;
import java.text.DateFormat;
import java.util.*;

public class MainActivity extends Activity {
    private LinearLayout page;
    private Calendar day = Calendar.getInstance();
    private Plan draft, permissionPlan;
    private boolean permissionTest, editing = false;
    private EditText title, origin, destination, travel, buffer;
    private TextView countdown, departure, arrivalLabel;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable tick = new Runnable() {
        @Override public void run() { updateCountdown(); handler.postDelayed(this, 1000); }
    };

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        home();
        if (!PlanStore.prefs(this).getBoolean("nameSet", false)) profile();
    }
    @Override protected void onResume() { super.onResume(); handler.post(tick); }
    @Override protected void onPause() { handler.removeCallbacks(tick); super.onPause(); }

    private int dp(int value) { return Math.round(value * getResources().getDisplayMetrics().density); }
    private void page(String heading) {
        LinearLayout outer = new LinearLayout(this);
        outer.setOrientation(LinearLayout.VERTICAL); outer.setBackgroundColor(Color.rgb(245,247,252));
        outer.setPadding(dp(18),dp(16),dp(18),dp(16));
        outer.setOnApplyWindowInsetsListener((v, insets) -> {
            v.setPadding(dp(18), insets.getSystemWindowInsetTop()+dp(16), dp(18), insets.getSystemWindowInsetBottom()+dp(16));
            return insets;
        });
        ScrollView scroll = new ScrollView(this);
        page = new LinearLayout(this); page.setOrientation(LinearLayout.VERTICAL);
        scroll.addView(page); outer.addView(scroll);
        setContentView(outer);
        text(heading, 28, true);
    }
    private TextView text(String value, int size, boolean bold) {
        TextView t = new TextView(this); t.setText(value); t.setTextSize(size);
        t.setTextColor(Color.rgb(30,41,65)); t.setPadding(0,dp(8),0,dp(8));
        if (bold) t.setTypeface(null, android.graphics.Typeface.BOLD);
        page.addView(t); return t;
    }
    private Button button(String label, Runnable action) {
        Button b = new Button(this); b.setText(label); b.setAllCaps(false);
        page.addView(b, new LinearLayout.LayoutParams(-1, dp(54))); b.setOnClickListener(v -> action.run()); return b;
    }
    private EditText input(String label, String value, boolean number) {
        text(label, 14, true);
        EditText e = new EditText(this); e.setSingleLine(true); e.setText(value); e.setTextSize(17);
        e.setInputType(number ? android.text.InputType.TYPE_CLASS_NUMBER :
            android.text.InputType.TYPE_CLASS_TEXT | android.text.InputType.TYPE_TEXT_FLAG_CAP_SENTENCES);
        page.addView(e, new LinearLayout.LayoutParams(-1,dp(52))); return e;
    }
    private String when(long instant) { return DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT).format(new Date(instant)); }
    private boolean sameDay(long instant) {
        Calendar c = Calendar.getInstance(); c.setTimeInMillis(instant);
        return c.get(Calendar.YEAR) == day.get(Calendar.YEAR) && c.get(Calendar.DAY_OF_YEAR) == day.get(Calendar.DAY_OF_YEAR);
    }

    private void home() {
        editing = false; draft = null; countdown = null;
        page("LeaveBy");
        String name = PlanStore.name(this);
        text(name.isEmpty() ? "Hi there! Let's plan your day." : "Hi, " + name + "! Let's plan your day.", 19, true);
        button("Your name or nickname", this::profile);
        CalendarView calendar = new CalendarView(this); calendar.setDate(day.getTimeInMillis());
        page.addView(calendar, new LinearLayout.LayoutParams(-1,dp(300)));
        calendar.setOnDateChangeListener((view, y, m, d) -> {
            day.set(y,m,d); home();
        });
        text(DateFormat.getDateInstance(DateFormat.FULL).format(day.getTime()),18,true);
        button("+ Add a plan", () -> {
            Plan p = new Plan();
            Calendar c = (Calendar)day.clone(); c.set(Calendar.HOUR_OF_DAY,9); c.set(Calendar.MINUTE,0); c.set(Calendar.SECOND,0);
            p.arrival = c.getTimeInMillis();
            Calendar now = Calendar.getInstance();
            if (day.get(Calendar.YEAR)==now.get(Calendar.YEAR) && day.get(Calendar.DAY_OF_YEAR)==now.get(Calendar.DAY_OF_YEAR)) p.arrival = System.currentTimeMillis()+3_600_000;
            edit(p);
        });
        boolean any = false;
        for (Plan p : PlanStore.all(this)) if (sameDay(p.arrival)) {
            any = true;
            button(p.title + "\nArrive " + DateFormat.getTimeInstance(DateFormat.SHORT).format(new Date(p.arrival)), () -> edit(p));
        }
        if (!any) text("A little breathing room! Tap + to add your next plan.",16,false);
        button("Test notification", () -> requestNotification(new Plan(), true));
        text("Android preview: travel time is entered manually. Live Maps estimates, calendar import, and widgets aren't included yet. Plans stay in this emulator; they don't sync to the iPhone app.",14,false);
    }

    private void profile() {
        EditText field = new EditText(this); field.setSingleLine(true); field.setHint("Your name or nickname");
        field.setText(PlanStore.name(this)); field.setFilters(new InputFilter[]{new InputFilter.LengthFilter(80)});
        new AlertDialog.Builder(this).setTitle("What should we call you?")
            .setMessage("A first name or nickname is perfect. It stays on this device and may appear in notification previews.")
            .setView(field).setPositiveButton("Save", (d,w) -> {
                PlanStore.prefs(this).edit().putString("name", DepartureMath.cleanName(field.getText().toString())).putBoolean("nameSet",true).apply(); home();
            }).setNeutralButton("Skip / remove name", (d,w) -> {
                PlanStore.prefs(this).edit().putString("name","").putBoolean("nameSet",true).apply(); home();
            }).setNegativeButton("Cancel", null).show();
    }

    private void edit(Plan plan) {
        editing = true; draft = plan;
        page("Your next plan");
        button("Back to calendar", this::confirmBack);
        title = input("Event name", plan.title, false);
        origin = input("Starting point (optional)",plan.origin,false);
        destination = input("Destination (optional)",plan.destination,false);
        arrivalLabel = text("Arrive by " + when(plan.arrival),18,true);
        button("Choose arrival date", () -> {
            Calendar c = Calendar.getInstance(); c.setTimeInMillis(draft.arrival);
            new DatePickerDialog(this,(v,y,m,d) -> {
                c.set(y,m,d); draft.arrival=c.getTimeInMillis(); arrivalLabel.setText("Arrive by "+when(draft.arrival)); updateCountdown();
            },c.get(Calendar.YEAR),c.get(Calendar.MONTH),c.get(Calendar.DAY_OF_MONTH)).show();
        });
        button("Choose arrival time", () -> {
            Calendar c = Calendar.getInstance(); c.setTimeInMillis(draft.arrival);
            new TimePickerDialog(this,(v,h,m) -> {
                c.set(Calendar.HOUR_OF_DAY,h); c.set(Calendar.MINUTE,m); c.set(Calendar.SECOND,0); c.set(Calendar.MILLISECOND,0);
                draft.arrival=c.getTimeInMillis(); arrivalLabel.setText("Arrive by "+when(draft.arrival)); updateCountdown();
            },c.get(Calendar.HOUR_OF_DAY),c.get(Calendar.MINUTE),android.text.format.DateFormat.is24HourFormat(this)).show();
        });
        travel = input("Travel time in minutes (0-600)",String.valueOf(plan.travel),true);
        buffer = input("Extra time in minutes (0-120)",String.valueOf(plan.buffer),true);
        departure = text("",22,true); countdown = text("",19,false);
        TextWatcher watcher = new TextWatcher() {
            public void beforeTextChanged(CharSequence s,int start,int count,int after) {}
            public void onTextChanged(CharSequence s,int start,int before,int count) { updateCountdown(); }
            public void afterTextChanged(Editable e) {}
        };
        travel.addTextChangedListener(watcher); buffer.addTextChangedListener(watcher);
        text(plan.reminder ? "A reminder is saved. Saving edits clears it; use Save & remind me to set it again." : "Add a reminder when your plan is ready.",14,false);
        button("Save plan", () -> { if (saveDraft()!=null) { toast("Your plan is saved!"); home(); } });
        button("Save & remind me", () -> {
            Plan p = saveDraft(); if (p!=null) requestNotification(p,false);
        });
        text("Reminders use Android's flexible scheduling and may arrive late. Keep LDPlayer running to receive them. This preview doesn't request special exact-alarm access.",14,false);
        if (PlanStore.find(this,plan.id)!=null) button("Delete plan", () ->
            new AlertDialog.Builder(this).setTitle("Delete this plan?").setMessage("This also clears its departure reminder.")
            .setPositiveButton("Delete",(d,w)->{ReminderReceiver.cancel(this,plan.id);PlanStore.delete(this,plan.id);home();})
            .setNegativeButton("Keep it",null).show());
        updateCountdown();
    }

    private int minutes(EditText field, int max) {
        try { int n=Integer.parseInt(field.getText().toString()); return n>=0 && n<=max ? n : -1; }
        catch (NumberFormatException e) { return -1; }
    }
    private void updateCountdown() {
        if (!editing || draft==null || travel==null || buffer==null || countdown==null) return;
        int t=minutes(travel,600), b=minutes(buffer,120);
        if (t<0 || b<0) { departure.setText("Let's check those minutes"); countdown.setText("Use 0-600 for travel and 0-120 for extra time."); return; }
        long leave=DepartureMath.departure(draft.arrival,t,b);
        departure.setText("Leave by " + when(leave));
        long seconds=(leave-System.currentTimeMillis())/1000;
        if (seconds<=0) countdown.setText("Your departure time has passed. Let's check your plan.");
        else countdown.setText(String.format(Locale.getDefault(),"%dh %02dm %02ds until departure",seconds/3600,(seconds%3600)/60,seconds%60));
    }
    private Plan saveDraft() {
        int t=minutes(travel,600), b=minutes(buffer,120);
        if (t<0 || b<0) { toast("Check your minutes: travel 0-600, extra time 0-120."); return null; }
        String eventTitle=title.getText().toString().trim();
        if (eventTitle.isEmpty()) { title.setError("What shall we call this plan?"); return null; }
        draft.title=eventTitle; draft.origin=origin.getText().toString().trim(); draft.destination=destination.getText().toString().trim();
        draft.travel=t; draft.buffer=b; draft.reminder=false;
        ReminderReceiver.cancel(this,draft.id); PlanStore.put(this,draft); return draft;
    }
    private void requestNotification(Plan p, boolean test) {
        if (!test && p.departure()<System.currentTimeMillis()+5000) { toast("Your plan is saved. Pick a later departure to add a reminder."); return; }
        permissionPlan=p; permissionTest=test;
        if (Build.VERSION.SDK_INT>=33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)
            requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS},7);
        else finishNotification();
    }
    private void finishNotification() {
        if (!ReminderReceiver.allowed(this)) {
            new AlertDialog.Builder(this).setTitle("Let's turn on notifications")
                .setMessage("Allow LeaveBy notifications in Settings, then try again.")
                .setPositiveButton("Settings",(d,w)-> startActivity(new Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS, android.net.Uri.parse("package:" + getPackageName()))))
                .setNegativeButton("Maybe later",null).show(); return;
        }
        if (permissionTest) { ReminderReceiver.show(this,permissionPlan,true); toast("Your test notification is ready. Check the notification panel!"); }
        else {
            if (permissionPlan.departure()<System.currentTimeMillis()+5000) { toast("That departure is too soon now. Pick a later time."); return; }
            permissionPlan.reminder=true; PlanStore.put(this,permissionPlan); ReminderReceiver.schedule(this,permissionPlan);
            String name=PlanStore.name(this);
            toast(name.isEmpty() ? "You're all set! Your reminder is scheduled." : "You're all set, "+name+"!");
            home();
        }
        permissionPlan=null;
    }
    @Override public void onRequestPermissionsResult(int code,String[] permissions,int[] results) {
        super.onRequestPermissionsResult(code,permissions,results);
        if (code==7 && permissionPlan!=null) finishNotification();
    }
    private void toast(String message) { Toast.makeText(this,message,Toast.LENGTH_LONG).show(); }
    private void confirmBack() {
        new AlertDialog.Builder(this).setTitle("Leave this plan?")
            .setMessage("Save your changes before heading back, or leave without saving.")
            .setPositiveButton("Save & go back",(d,w)->{if(saveDraft()!=null)home();})
            .setNegativeButton("Discard changes",(d,w)->home()).setNeutralButton("Keep editing",null).show();
    }
    @Override public void onBackPressed() { if(editing) confirmBack(); else super.onBackPressed(); }
}
