package com.frowndotorg.leaveby;

public final class AchievementRules {
    private AchievementRules() {}
    public static int highestReached(int count, int[] thresholds) {
        int result=0;
        for(int threshold: thresholds) if(count>=threshold && threshold>result) result=threshold;
        return result;
    }
    public static boolean shouldNotify(int milestone,int previous) {
        return milestone>0 && milestone>previous;
    }
}

