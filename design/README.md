# LeaveBy design and personality

This is the shared design template for both native apps. Use platform-native
controls, but keep the same hierarchy, colors, wording, and achievement catalog.
The iOS and Android apps remain separate implementations.

## Visual language
Use design/themes.json as the shared runtime palette for both apps and iOS widgets.

| Role | R theme | J theme |
| --- | --- | --- |
| background | #101F36 | #18191F |
| card | #1A2E49 | #22232C |
| field | #14253E | #1B1C25 |
| elevated | #243F62 | #2C2538 |
| accent | #85AFF8 | #A181D8 |
| text | #F1F5FC | #F4F0FA |
| muted | #B6C5DC | #C7BED5 |
| border | #3A5272 | #494457 |
| positive | #1C304D | #2A2536 |
| achievement | #24354E | #32283E |
| success | #9BBEFF | #B29BDA |
| danger | #FFABBA | #F5A9BD |

R theme preserves the navy design with slightly darker blue buttons. J theme is
charcoal/dark gray with purple accents. J theme is the default when no preference
is saved. Both stay dark regardless of system appearance. Filled accent buttons
use the background color for labels to keep good contrast.

Android: choose a Theme under Make it yours. iOS: open name/preferences, then
Your colors. Selection persists locally. The iOS app shares it with widgets
through its App Group. Android native dialog styles mirror the JSON palette
in res/values/styles.xml.

- Card corners: approximately 20 points/dp; fields 12; buttons 16.
- Keep content comfortable on phones and centered on wide screens.
- Emphasize the next departure and countdown; keep events easy to scan.
- Group editor fields into plan, arrival, travel/buffer, and departure.
- Never use color alone for status; preserve readable labels and wrapping text.
- Theme changes do not alter plans, names, or reminder schedules.

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
