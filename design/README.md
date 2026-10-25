# LeaveBy design and personality

This is the shared design template for both native apps. Use platform-native
controls, but keep the same hierarchy, colors, wording, and achievement catalog.
The iOS and Android apps remain separate implementations.

## Visual language
- Canvas: #101F36 deep navy; #1A2E49 rounded cards; #3A5272 borders.
- Primary accent: #8DB6FF soft blue; raised surfaces: #243F62. Filled accent buttons use #101F36 text.
- Text: #F1F5FC; secondary text: #B6C5DC; inputs: #14253E.
- Positive: #8DE0C0 text on #1C3943; achievement surfaces: #3B3547; destructive text: #FFABBA.
- Card corners: approximately 20 points/dp; fields 12; buttons 16.
- Content should stay comfortable on a phone and centered on wide screens.
- Make the next departure and countdown the strongest elements.
- Keep the calendar compact and events individually scannable.
- Give editing fields clear groups: plan, arrival, travel/buffer, departure.
- Never communicate status only through color. Preserve readable text and
  accessible native labels; allow text to wrap at larger sizes.
- Both platforms use the navy theme regardless of the device appearance. Native controls, dialogs, forms, and iOS widgets follow the same roles.

## Voice
Friendly, calm, practical, a little playful. Use the user's chosen first name or
nickname naturally in greetings and reminders, not in every label. No name is
required. Keep time, permission, error, and travel uncertainty messages clear.
Celebrate planning without claiming a trip was completed. Do not shame busyness
or encourage rushing, unsafe driving, or adding plans just to collect badges.

## Daily surprise achievements
The runtime source of truth for both apps is achievements.json in this folder.
Android packages the folder as assets; iOS bundles the catalog as a resource.
The count is saved plans grouped by arrival date in the device's current local
calendar. It includes manual and imported plans. It is not a completed-trip count.

Milestones: 5 (impressed), 8 (double take), 12 (astonished), 20 (teleportation joke),
30 (comically speechless). At each new milestone, randomly choose one title/body
combination and keep that choice stable for that date and milestone. Counts above
30 keep the highest tier. Include the actual plan count in the message.

Notify once for a newly reached milestone on that day. A batch import only gets
the highest newly reached milestone per day. Keep a persistent daily high-water
mark so editing, reopening, deletion/re-addition, or scheduling reminders doesn't
farm repeated notifications. Reaching the same milestone on another date is new.
Past-day achievements stay in-app; no past-day push. For future dates, say "on
[date]" rather than "today". Use one notification identity per date to replace
the prior achievement in the notification tray instead of stacking alerts.

Achievements appear in the calendar even if notifications are unavailable.
Only send a local notification if notification access is already allowed.
Never prompt for notification permission just because someone saves a plan.
Provide a separate achievement-notification toggle; it doesn't change departure
reminders. Milestones reached while muted or without permission are not replayed
later. Day identity uses the current device timezone at evaluation; timezone
changes can change the day grouping.

## Current platform status
Both platforms implement the achievement catalog, daily milestone tracking,
personalized copy, and a notification toggle. Android includes rounded cards,
a compact week selector, prominent countdowns, and collapsible earlier plans.
iOS includes the same visual roles, a next-departure card, achievement cards,
blue accents, and adaptive grouped backgrounds. It uses its native calendar
control rather than duplicating Android's exact calendar layout.

## Verification
Build both workflows. Android unit tests cover threshold boundaries, counts
above the highest tier, batch counts, and suppression after edits/deletion.
On-device checks: 4->5, 7->8, and 11->12 plans; random-but-stable wording; chosen
name and no-name fallback; editing/reopening without repeats; another date;
deletion/re-addition; import batches; denied permission; muted achievements with
departure reminders still working. Test iOS separately once signing is ready.
