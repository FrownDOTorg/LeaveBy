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
        setTheme("R".equals(ThemePalette.selected(this)) ? R.style.Theme_LeaveBy_R : R.style.Theme_LeaveBy_J);
        super.onCreate(state);
        if(state!=null)day.setTimeInMillis(state.getLong("selectedDay",System.currentTimeMillis()));
        home();
        if (!PlanStore.prefs(this).getBoolean("nameSet", false)) profile();
    }
    @Override protected void onResume() { super.onResume(); handler.post(tick); }
    @Override protected void onPause() { handler.removeCallbacks(tick); super.onPause(); }

    private int INK, MUTED, BLUE, LINE, BACKGROUND, SURFACE, ELEVATED, FIELD, POSITIVE, ACHIEVEMENT, SUCCESS, DANGER;
    private void applyPalette() {
        ThemePalette palette=ThemePalette.load(this);
        INK=palette.color("text","#F4F0FA");
        MUTED=palette.color("muted","#C7BED5");
        BLUE=palette.color("accent","#A181D8");
        LINE=palette.color("border","#494457");
        BACKGROUND=palette.color("background","#18191F");
        SURFACE=palette.color("card","#22232C");
        ELEVATED=palette.color("elevated","#2C2538");
        FIELD=palette.color("field","#1B1C25");
        POSITIVE=palette.color("positive","#2A2536");
        ACHIEVEMENT=palette.color("achievement","#32283E");
        SUCCESS=palette.color("success","#B29BDA");
        DANGER=palette.color("danger","#F5A9BD");
    }
    private LinearLayout rootPage;
    private TextView homeCountdown;
    private long homeDeparture;
    private boolean showEarlier = false;

    private int dp(int value) { return Math.round(value * getResources().getDisplayMetrics().density); }
    private android.graphics.drawable.GradientDrawable rounded(int fill, int radius, int border) {
        android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
        bg.setColor(fill); bg.setCornerRadius(dp(radius));
        if (border != 0) bg.setStroke(dp(1), border);
        return bg;
    }
    private android.graphics.drawable.RippleDrawable ripple(int fill, int border) {
        return new android.graphics.drawable.RippleDrawable(android.content.res.ColorStateList.valueOf((BLUE & 0x00FFFFFF) | 0x33000000),
            rounded(fill, 16, border), rounded(Color.WHITE, 16, 0));
    }
    private void page(String heading) {
        applyPalette();
        LinearLayout outer = new LinearLayout(this);
        outer.setOrientation(LinearLayout.VERTICAL); outer.setBackgroundColor(BACKGROUND);
        outer.setOnApplyWindowInsetsListener((v, insets) -> {
            v.setPadding(0, insets.getSystemWindowInsetTop(), 0, insets.getSystemWindowInsetBottom());
            return insets;
        });
        ScrollView scroll = new ScrollView(this); scroll.setFillViewport(true);
        scroll.setClipToPadding(false);
        android.widget.FrameLayout frame = new android.widget.FrameLayout(this);
        page = new LinearLayout(this); page.setOrientation(LinearLayout.VERTICAL);
        page.setPadding(dp(20),dp(22),dp(20),dp(28));
        rootPage = page;
        int width = Math.min(getResources().getDisplayMetrics().widthPixels, dp(680));
        android.widget.FrameLayout.LayoutParams content = new android.widget.FrameLayout.LayoutParams(width,-2,Gravity.TOP|Gravity.CENTER_HORIZONTAL);
        frame.addView(page,content); scroll.addView(frame); outer.addView(scroll);
        setContentView(outer);
        text(heading,30,true);
    }
    private TextView label(String value, int size, boolean bold) {
        TextView t = new TextView(this); t.setText(value); t.setTextSize(size);
        t.setTextColor(INK); t.setFontFeatureSettings("kern");
        if (bold) t.setTypeface(null, android.graphics.Typeface.BOLD);
        return t;
    }
    private TextView text(String value, int size, boolean bold) {
        TextView t=label(value,size,bold);
        t.setPadding(0,dp(5),0,dp(7)); page.addView(t); return t;
    }
    private void caption(String value) { text(value,13,false).setTextColor(MUTED); }
    private void sectionTitle(String value) {
        TextView t=text(value,12,true); t.setTextColor(MUTED); t.setLetterSpacing(0.09f);
        t.setPadding(0,dp(22),0,dp(10));
    }
    private void beginCard(int color) {
        LinearLayout card=new LinearLayout(this); card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(18),dp(16),dp(18),dp(16)); card.setBackground(rounded(color,20,LINE));
        LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-1,-2); lp.setMargins(0,dp(6),0,dp(8));
        rootPage.addView(card,lp); page=card;
    }
    private void endCard() { page=rootPage; }
    private Button button(String value,Runnable action) {
        Button b=new Button(this); b.setText(value); b.setAllCaps(false); b.setTextColor(BLUE);
        b.setTextSize(15); b.setTypeface(null,android.graphics.Typeface.BOLD);
        b.setPadding(dp(14),dp(12),dp(14),dp(12)); b.setMinHeight(dp(50));
        b.setBackground(ripple(SURFACE,LINE));
        LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-1,-2); lp.setMargins(0,dp(5),0,dp(5));
        page.addView(b,lp); b.setOnClickListener(v->action.run()); return b;
    }
    private Button primary(String value,Runnable action) {
        Button b=button(value,action); b.setBackground(ripple(BLUE,0)); b.setTextColor(BACKGROUND); return b;
    }
    private EditText input(String title,String value,boolean number) {
        TextView titleView=text(title,13,true); titleView.setPadding(0,dp(12),0,dp(6));
        EditText e=new EditText(this); e.setSingleLine(true); e.setText(value); e.setTextSize(16); e.setTextColor(INK);
        e.setInputType(number?android.text.InputType.TYPE_CLASS_NUMBER:
            android.text.InputType.TYPE_CLASS_TEXT|android.text.InputType.TYPE_TEXT_FLAG_CAP_SENTENCES);
        e.setPadding(dp(14),dp(12),dp(14),dp(12)); e.setBackground(rounded(FIELD,12,LINE));
        page.addView(e,new LinearLayout.LayoutParams(-1,dp(50))); return e;
    }
    private String when(long instant) { return DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT).format(new Date(instant)); }
    private boolean sameDay(long instant) {
        Calendar c = Calendar.getInstance(); c.setTimeInMillis(instant);
        return c.get(Calendar.YEAR) == day.get(Calendar.YEAR) && c.get(Calendar.DAY_OF_YEAR) == day.get(Calendar.DAY_OF_YEAR);
    }

    private void home() {
        editing=false; draft=null; countdown=null; homeCountdown=null;
        page("LeaveBy");
        String name=PlanStore.name(this);
        text(name.isEmpty()?"A little more time. A little less rush.":"Hi, "+name+". A little less rush today.",16,false).setTextColor(MUTED);
        Button profile=button("Your name & preferences",this::profile); profile.setTextSize(13);

        Plan next=null;
        for(Plan p:PlanStore.all(this)) if(p.departure()>System.currentTimeMillis() && (next==null || p.departure()<next.departure())) next=p;
        if(next!=null) {
            final Plan upcoming=next;
            beginCard(ELEVATED);
            text("YOUR NEXT DEPARTURE",11,true).setTextColor(BLUE);
            text(next.title,23,true);
            homeDeparture=next.departure();
            homeCountdown=text("",32,true); homeCountdown.setTextColor(BLUE);
            caption("Leave "+when(next.departure())+"  ·  Arrive "+DateFormat.getTimeInstance(DateFormat.SHORT).format(new Date(next.arrival)));
            primary("View your plan",()->edit(upcoming));
            endCard();
        } else {
            beginCard(POSITIVE);
            text("Room for something good",22,true);
            caption("Pick a day below and plan your next outing.");
            endCard();
        }

        sectionTitle("YOUR CALENDAR");
        button(new java.text.SimpleDateFormat("MMMM yyyy",Locale.getDefault()).format(day.getTime())+"  ·  Choose a date",()->{
            new DatePickerDialog(this,(v,y,m,d)->{day.set(y,m,d);showEarlier=false;home();},
                day.get(Calendar.YEAR),day.get(Calendar.MONTH),day.get(Calendar.DAY_OF_MONTH)).show();
        });
        LinearLayout week=new LinearLayout(this);
        Calendar start=(Calendar)day.clone();
        int offset=(start.get(Calendar.DAY_OF_WEEK)-start.getFirstDayOfWeek()+7)%7;
        start.add(Calendar.DAY_OF_MONTH,-offset);
        for(int i=0;i<7;i++) {
            final Calendar date=(Calendar)start.clone(); date.add(Calendar.DAY_OF_MONTH,i);
            boolean active=date.get(Calendar.DAY_OF_YEAR)==day.get(Calendar.DAY_OF_YEAR) && date.get(Calendar.YEAR)==day.get(Calendar.YEAR);
            TextView chip=label(new java.text.SimpleDateFormat("EE",Locale.getDefault()).format(date.getTime())+"\n"+date.get(Calendar.DAY_OF_MONTH),12,active);
            chip.setGravity(Gravity.CENTER); chip.setLineSpacing(dp(5),1);
            chip.setTextColor(active?BACKGROUND:MUTED); chip.setBackground(ripple(active?BLUE:SURFACE,active?0:LINE));
            LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(0,dp(64),1); lp.setMargins(dp(2),dp(6),dp(2),dp(6));
            week.addView(chip,lp); chip.setContentDescription(DateFormat.getDateInstance(DateFormat.FULL).format(date.getTime()));
            chip.setOnClickListener(v->{day=(Calendar)date.clone();showEarlier=false;home();});
        }
        page.addView(week);
        int plansOnDay=0;
        for(Plan plan:PlanStore.all(this))if(sameDay(plan.arrival))plansOnDay++;
        Achievements.Badge badge=Achievements.badge(this,plansOnDay,day.getTimeInMillis());
        if(badge!=null) {
            beginCard(ACHIEVEMENT);
            text("DAILY ACHIEVEMENT",11,true).setTextColor(BLUE);
            text(badge.title,22,true);caption(badge.body);endCard();
        }
        sectionTitle(DateFormat.getDateInstance(DateFormat.FULL).format(day.getTime()).toUpperCase(Locale.getDefault()));
        primary("+  Add a plan",()->{
            Plan p=new Plan();
            Calendar c=(Calendar)day.clone();c.set(Calendar.HOUR_OF_DAY,9);c.set(Calendar.MINUTE,0);c.set(Calendar.SECOND,0);
            p.arrival=c.getTimeInMillis();
            if(sameDay(System.currentTimeMillis()))p.arrival=System.currentTimeMillis()+3_600_000;
            edit(p);
        });
        int count=0,earlier=0;
        for(Plan p:PlanStore.all(this)) if(sameDay(p.arrival)) {
            count++;
            if(p.arrival<System.currentTimeMillis()) {earlier++;if(!showEarlier)continue;}
            eventCard(p);
        }
        if(earlier>0)button((showEarlier?"Hide":"Show")+" earlier plans ("+earlier+")",()->{showEarlier=!showEarlier;home();});
        if(count==0) {
            beginCard(SURFACE); text("A little breathing room",18,true);
            caption("Nothing planned for this day. Add something to look forward to.");endCard();
        }
        sectionTitle("MAKE IT YOURS");
        button("Theme: "+ThemePalette.selected(this)+" theme",this::chooseTheme);
        Switch achievements=new Switch(this);
        achievements.setText("Playful achievement notifications");
        achievements.setTextSize(14);achievements.setTextColor(INK);achievements.setMinHeight(dp(48));
        achievements.setChecked(PlanStore.prefs(this).getBoolean("achievementNotifications",true));
        achievements.setOnCheckedChangeListener((view,checked)->PlanStore.prefs(this).edit().putBoolean("achievementNotifications",checked).apply());
        page.addView(achievements);
        caption("A little celebration at 5, 8, 12, 20, and 30 plans in a day. Uses your existing notification permission.");
        sectionTitle("TRY IT OUT");
        button("Send a test notification",()->requestNotification(new Plan(),true));
        caption("Android preview · Travel time is entered manually. Your plans stay on this device.");
        updateCountdown();
    }

    private void eventCard(Plan p) {
        beginCard(SURFACE);
        LinearLayout card=page;
        TextView meta=text("ARRIVE "+DateFormat.getTimeInstance(DateFormat.SHORT).format(new Date(p.arrival)),11,true);
        meta.setTextColor(BLUE);meta.setLetterSpacing(0.06f);
        text(p.title,20,true);
        if(!p.destination.isEmpty())caption(p.destination);
        caption("Leave "+DateFormat.getTimeInstance(DateFormat.SHORT).format(new Date(p.departure()))+
            "  ·  "+p.travel+" min travel  ·  "+p.buffer+" min extra");
        TextView state=text(p.reminder && p.departure()>System.currentTimeMillis()?"Reminder set":"Tap to view your plan",12,false);
        state.setTextColor(p.reminder?SUCCESS:MUTED);
        card.setBackground(ripple(SURFACE,LINE));card.setOnClickListener(v->edit(p));
        card.setContentDescription(p.title+", arrive "+when(p.arrival)+". Open plan");
        endCard();
    }
    private void chooseTheme() {
        String[] choices={"R theme · Navy & blue","J theme · Charcoal & purple"};
        int checked="R".equals(ThemePalette.selected(this))?0:1;
        new AlertDialog.Builder(this).setTitle("Make it your own")
            .setSingleChoiceItems(choices,checked,(dialog,index)->{
                PlanStore.prefs(this).edit().putString("appearanceTheme",index==0?"R":"J").apply();
                dialog.dismiss();recreate();
            }).setNegativeButton("Keep current theme",null).show();
    }
    @Override protected void onSaveInstanceState(Bundle state) {
        state.putLong("selectedDay",day.getTimeInMillis());
        super.onSaveInstanceState(state);
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
        editing = true; draft = plan; homeCountdown = null;
        page("Your next plan");
        button("Back to calendar", this::confirmBack);
        sectionTitle("THE PLAN");
        beginCard(SURFACE);
        title = input("Event name", plan.title, false);
        origin = input("Starting point (optional)",plan.origin,false);
        destination = input("Destination (optional)",plan.destination,false);
        endCard();
        sectionTitle("WHEN TO BE THERE");
        beginCard(SURFACE);
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
        endCard();
        sectionTitle("GIVE YOURSELF ENOUGH TIME");
        beginCard(SURFACE);
        travel = input("Travel time · minutes",String.valueOf(plan.travel),true);
        buffer = input("A little extra time · minutes",String.valueOf(plan.buffer),true);
        caption("Up to 600 minutes of travel and 120 minutes of extra time.");
        endCard();
        sectionTitle("YOUR DEPARTURE");
        beginCard(ELEVATED);
        departure = text("",19,true); countdown = text("",32,true);
        countdown.setTextColor(BLUE);
        endCard();
        TextWatcher watcher = new TextWatcher() {
            public void beforeTextChanged(CharSequence s,int start,int count,int after) {}
            public void onTextChanged(CharSequence s,int start,int before,int count) { updateCountdown(); }
            public void afterTextChanged(Editable e) {}
        };
        travel.addTextChangedListener(watcher); buffer.addTextChangedListener(watcher);
        text(plan.reminder ? "A reminder is saved. Saving edits clears it; use Save & remind me to set it again." : "Add a reminder when your plan is ready.",14,false);
        primary("Save plan", () -> { if (saveDraft()!=null) { toast("Your plan is saved!"); home(); } });
        button("Save & remind me", () -> {
            Plan p = saveDraft(); if (p!=null) requestNotification(p,false);
        });
        caption("Keep LDPlayer running for reminders. Android may deliver them a little late.");
        if (PlanStore.find(this,plan.id)!=null) button("Delete plan", () ->
            new AlertDialog.Builder(this).setTitle("Delete this plan?").setMessage("This also clears its departure reminder.")
            .setPositiveButton("Delete",(d,w)->{ReminderReceiver.cancel(this,plan.id);PlanStore.delete(this,plan.id);home();})
            .setNegativeButton("Keep it",null).show()).setTextColor(DANGER);
        updateCountdown();
    }

    private int minutes(EditText field, int max) {
        try { int n=Integer.parseInt(field.getText().toString()); return n>=0 && n<=max ? n : -1; }
        catch (NumberFormatException e) { return -1; }
    }
    private void updateCountdown() {
        if (homeCountdown != null) homeCountdown.setText(remaining(homeDeparture));
        if (!editing || draft==null || travel==null || buffer==null || countdown==null) return;
        int t=minutes(travel,600), b=minutes(buffer,120);
        if (t<0 || b<0) { departure.setText("Let's check those minutes"); countdown.setText("Use 0-600 for travel and 0-120 for extra time."); return; }
        long leave=DepartureMath.departure(draft.arrival,t,b);
        departure.setText("Leave by " + when(leave));
        long seconds=(leave-System.currentTimeMillis())/1000;
        if (seconds<=0) countdown.setText("Your departure time has passed. Let's check your plan.");
        else countdown.setText(remaining(leave));
    }
    private String remaining(long instant) {
        long seconds=Math.max(0,(instant-System.currentTimeMillis())/1000);
        if(seconds<=0)return "Time to head out";
        if(seconds>=86400)return String.format(Locale.getDefault(),"%dd %dh to go",seconds/86400,(seconds%86400)/3600);
        if(seconds>=3600)return String.format(Locale.getDefault(),"%dh %02dm %02ds",seconds/3600,(seconds%3600)/60,seconds%60);
        return String.format(Locale.getDefault(),"%dm %02ds to go",seconds/60,seconds%60);
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
