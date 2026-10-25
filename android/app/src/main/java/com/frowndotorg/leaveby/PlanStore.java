package com.frowndotorg.leaveby;

import android.content.Context;
import android.content.SharedPreferences;
import org.json.JSONArray;
import org.json.JSONException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public final class PlanStore {
    private PlanStore() {}
    public static SharedPreferences prefs(Context c) { return c.getSharedPreferences("leaveby", Context.MODE_PRIVATE); }
    public static String name(Context c) { return DepartureMath.cleanName(prefs(c).getString("name", "")); }
    public static List<Plan> all(Context c) {
        ArrayList<Plan> plans = new ArrayList<>();
        try {
            JSONArray a = new JSONArray(prefs(c).getString("plans", "[]"));
            for (int i = 0; i < a.length(); i++) plans.add(Plan.from(a.getJSONObject(i)));
        } catch (JSONException e) { throw new IllegalStateException("Saved plans could not be read", e); }
        plans.sort(Comparator.comparingLong(p -> p.arrival));
        return plans;
    }
    public static Plan find(Context c, String id) {
        for (Plan p : all(c)) if (p.id.equals(id)) return p;
        return null;
    }
    public static void put(Context c, Plan p) {
        List<Plan> plans = all(c);
        plans.removeIf(old -> old.id.equals(p.id));
        plans.add(p); write(c, plans);
    }
    public static void delete(Context c, String id) {
        List<Plan> plans = all(c); plans.removeIf(p -> p.id.equals(id)); write(c, plans);
    }
    private static void write(Context c, List<Plan> plans) {
        JSONArray a = new JSONArray();
        try { for (Plan p : plans) a.put(p.json()); }
        catch (JSONException e) { throw new IllegalStateException(e); }
        prefs(c).edit().putString("plans", a.toString()).apply();
    }
}

