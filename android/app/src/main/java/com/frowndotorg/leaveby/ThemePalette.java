package com.frowndotorg.leaveby;

import android.content.Context;
import android.graphics.Color;
import org.json.JSONObject;
import java.io.*;
import java.nio.charset.StandardCharsets;

public final class ThemePalette {
    private final JSONObject colors;
    private ThemePalette(JSONObject colors) { this.colors=colors; }
    public static String selected(Context context) {
        return "R".equals(PlanStore.prefs(context).getString("appearanceTheme","J"))?"R":"J";
    }
    public static ThemePalette load(Context context) {
        try(BufferedReader reader=new BufferedReader(new InputStreamReader(context.getAssets().open("themes.json"),StandardCharsets.UTF_8))) {
            StringBuilder json=new StringBuilder();String line;
            while((line=reader.readLine())!=null)json.append(line);
            return new ThemePalette(new JSONObject(json.toString()).getJSONObject(selected(context)));
        } catch(Exception e) {return new ThemePalette(new JSONObject());}
    }
    public int color(String role,String fallback) {return Color.parseColor(colors.optString(role,fallback));}
}

