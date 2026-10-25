package com.frowndotorg.leaveby;
import android.content.Context;
import android.graphics.Color;
import org.json.JSONObject;
import java.io.*;
import java.nio.charset.StandardCharsets;

public final class ThemePalette {
    private final JSONObject colors;
    private ThemePalette(JSONObject colors){this.colors=colors;}
    public static String selected(Context c){
        String saved=PlanStore.prefs(c).getString("appearanceTheme","J");
        return "R".equals(saved)||"Light".equals(saved)||"Dark".equals(saved)?saved:"J";
    }
    public static String label(Context c){String id=selected(c);return "R".equals(id)||"J".equals(id)?id+" theme":id+" mode";}
    public static int style(Context c){
        switch(selected(c)){
            case "R":return R.style.Theme_LeaveBy_R;
            case "Light":return R.style.Theme_LeaveBy_Light;
            case "Dark":return R.style.Theme_LeaveBy_Dark;
            default:return R.style.Theme_LeaveBy_J;
        }
    }
    public static int widgetBackground(Context c){
        switch(selected(c)){
            case "R":return R.drawable.widget_r;
            case "Light":return R.drawable.widget_light;
            case "Dark":return R.drawable.widget_dark;
            default:return R.drawable.widget_j;
        }
    }
    public static ThemePalette load(Context context){
        try(BufferedReader reader=new BufferedReader(new InputStreamReader(context.getAssets().open("themes.json"),StandardCharsets.UTF_8))){
            StringBuilder json=new StringBuilder();String line;
            while((line=reader.readLine())!=null)json.append(line);
            return new ThemePalette(new JSONObject(json.toString()).getJSONObject(selected(context)));
        }catch(Exception e){return new ThemePalette(new JSONObject());}
    }
    public int color(String role,String fallback){return Color.parseColor(colors.optString(role,fallback));}
}

