package com.frowndotorg.leaveby;
import org.junit.Test;
import static org.junit.Assert.*;

public class AchievementRulesTest {
    private final int[] tiers={5,8,12,20,30};
    @Test public void beginsAtFivePlans() {
        assertEquals(0,AchievementRules.highestReached(4,tiers));
        assertEquals(5,AchievementRules.highestReached(5,tiers));
    }
    @Test public void growsOnlyAtMilestones() {
        assertEquals(5,AchievementRules.highestReached(7,tiers));
        assertEquals(8,AchievementRules.highestReached(8,tiers));
        assertEquals(12,AchievementRules.highestReached(19,tiers));
        assertEquals(20,AchievementRules.highestReached(20,tiers));
        assertEquals(30,AchievementRules.highestReached(100,tiers));
    }
    @Test public void editsAndDeletionReadditionDoNotReplay() {
        assertFalse(AchievementRules.shouldNotify(5,5));
        assertFalse(AchievementRules.shouldNotify(5,8));
        assertFalse(AchievementRules.shouldNotify(0,0));
        assertTrue(AchievementRules.shouldNotify(12,8));
    }
    @Test public void batchImportSelectsHighestMilestone() {
        assertEquals(20,AchievementRules.highestReached(25,tiers));
    }
}

