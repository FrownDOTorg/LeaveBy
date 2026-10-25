package com.frowndotorg.leaveby;

import org.json.JSONObject;
import org.json.JSONException;
import java.util.UUID;

public class Plan {
    public String id = UUID.randomUUID().toString();
    public String title = "New event";
    public String origin = "", destination = "", notes = "", sourceKey = "";
    public boolean walking = false;
    public long arrival = System.currentTimeMillis() + 3_600_000L;
    public int travel = 20, buffer = 10;
    public boolean reminder = false;
    public long departure() { return DepartureMath.departure(arrival, travel, buffer); }
    public JSONObject json() throws JSONException {
        JSONObject j = new JSONObject();
        j.put("id", id); j.put("title", title); j.put("origin", origin); j.put("destination", destination);
        j.put("notes",notes);j.put("sourceKey",sourceKey);j.put("walking",walking);
        j.put("arrival", arrival); j.put("travel", travel); j.put("buffer", buffer); j.put("reminder", reminder);
        return j;
    }
    public static Plan from(JSONObject j) {
        Plan p = new Plan();
        p.id = j.optString("id", p.id); p.title = j.optString("title", "New event");
        p.origin = j.optString("origin", ""); p.destination = j.optString("destination", "");
        p.notes=j.optString("notes","");p.sourceKey=j.optString("sourceKey","");p.walking=j.optBoolean("walking",false);
        p.arrival = j.optLong("arrival", p.arrival);
        p.travel = Math.max(0, Math.min(600, j.optInt("travel", 20)));
        p.buffer = Math.max(0, Math.min(120, j.optInt("buffer", 10)));
        p.reminder = j.optBoolean("reminder", false);
        return p;
    }
}
