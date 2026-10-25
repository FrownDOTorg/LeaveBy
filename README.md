# LeaveBy
A native SwiftUI departure planner for iOS 17 and later.

## First milestone
Enter an event and arrival time, search Apple Maps for both places, then choose driving or walking and calculate travel time. Extra time shifts the requested arrival earlier. Manual travel duration is also available. Places and settings persist; estimates must be recalculated after trip changes or relaunch. Departure reminders are available with notification permission. A built-in calendar supports multiple locally saved events. Apple Calendar import copies selected timed events from the selected day. Home and Lock Screen widget code is included; device validation is pending.

## Build from Windows
Commit and push with GitHub Desktop. The Build iOS workflow uses a standard
macOS runner, generates an Xcode project with XcodeGen, and compiles for iPhone
Simulator. The downloaded LeaveBy-simulator artifact is NOT an installable
phone IPA. No Apple credentials are needed for this build.

Standard GitHub-hosted runners are free for public repositories. Build artifacts
are retained for seven days; storage limits still apply.

## Later installation and widget setup
Device installation requires appropriate signing. Apple's free Personal Team
provisioning profiles expire after seven days. Choosing a distribution method
for friends is a separate step; a successful simulator build does not establish
sideloading support.

Widgets use the included WidgetKit extension. Sharing event data normally uses an
App Group. Confirm signing and sideloading support for the widget extension
and its entitlements before relying on widgets. Widget refresh is controlled by
iOS; widgets cannot continuously poll Maps. A system-rendered countdown can
show time until a previously calculated departure.

Never commit passwords, signing certificates, or provisioning profiles. Before
a device release, choose a unique bundle identifier and configure signing.

On a Mac with Xcode and XcodeGen installed: run `xcodegen generate`, then open
LeaveBy.xcodeproj. The generated project is ignored because project.yml is the
source of truth.

## Departure reminders
Set a reminder after calculating a departure, or use manual travel time. The app
asks for notification permission only when setting a reminder. One pending reminder per event is supported; setting it again replaces the reminder for that event. It remains scheduled
when the app closes, including after relaunch. Editing the plan or recalculating
cancels the old reminder; explicitly set a new one afterward. A denied permission
shows a link to Settings. Focus and system settings may delay or silence alerts.
The reminder uses the saved departure, not background traffic updates.

Device validation once signing is ready: allow permission and schedule a manual
trip departing two minutes from now; check delivery while locked and while the
app is open. Check cancellation after editing, replacement, relaunch persistence,
past-departure rejection, and denied permission with Settings recovery.

## Calendar and multiple events
Choose a date in the built-in calendar and tap + to add an event. Tap an event to
edit it; changes save automatically and Done closes the editor. Events appear on
their arrival date and are sorted by arrival time. Swipe an event to delete, then
confirm. Deletion also removes its reminder. Existing single-event settings migrate
on first launch of this version; any legacy reminder must be set again.

Each event has independent places, travel mode, buffer, and notification identity.
Maps estimates are intentionally not persisted; recalculate when reopening an event.
An already scheduled reminder remains until the plan changes or is recalculated.
Use Import to read selected-day events from Apple Calendar; original events are never modified.

Device checks: create two events on different dates, edit and reopen both, restart
the app to verify persistence, schedule independent reminders, and delete one to
confirm the other remains. Check that changing an event date moves it to that day.

## Home and Lock Screen widgets
The app embeds LeaveByWidgets. Small and medium Home widgets and inline, circular,
and rectangular Lock Screen widgets show the next future departure across events.
Manual trips use entered travel time; Maps trips need a successfully calculated
estimate. The snapshot is kept for widgets across launches. Changes to the route,
arrival time, or buffer invalidate it until recalculation. A widget countdown uses
system-rendered timer text; widget refresh and event transitions remain subject
to iOS scheduling. It does not continuously check traffic. Event details are marked
privacy-sensitive for system redaction. Tapping a widget opens the app.

Before signing, register group.com.frowndotorg.leaveby as an App Group and enable it
for BOTH the app and widget identifiers. Both targets reference
Shared/LeaveBy.entitlements and Shared/WidgetStore.swift. If the group identifier
must change, update both files together. The current unsigned simulator build
checks compilation and embedding; it does not validate App Group provisioning.
No signing credentials belong in the repository.

On-device checks after enrollment: launch LeaveBy, create a manual future trip,
add each widget size, then verify a Maps trip, empty state, countdown at departure,
next-event transition, edit/delete propagation, relaunch, and Lock Screen privacy.

## Apple Calendar import
On the selected day, tap Import, then Load events from Apple Calendar. iOS 17+
requires Full Access for reading existing events; the purpose string is configured
only on the main app target. This implementation never writes to EventKit.
Select events and tap Import. Already imported occurrences are disabled, keyed by
calendar item identifier plus start timestamp, so recurring dates stay distinct.
Calendar account resyncs or rescheduled originals may change those keys; imports
are independent copies, not ongoing sync. All-day events and events starting on
other days are excluded. Existing timed events in calendars available on the
phone are supported, not just iCloud calendars.

Imported location text seeds destination search. Confirm a real place in Maps and
choose a starting point before calculating. Event notes, attendees, meeting links,
and original alarms are not imported. No departure reminders are set automatically.

Device validation: permission allow/deny and recovery, empty day, two selected
imports, repeat import prevention, recurring occurrences on separate dates,
location search, deletion and reimport, and verifying original events stay intact.

## Friendly messages and preferred names
On first launch, LeaveBy asks for a first name or nickname. Naming is optional;
Maybe later keeps friendly generic wording. The profile button lets the user
change or remove the name anytime. Names are trimmed, repeated whitespace is
collapsed, and input is limited to 40 characters, including Unicode names.

Shared FriendlyCopy wording personalizes greetings, reminder titles and success
messages, and Home widget greetings/empty states. Short action labels and compact
Lock Screen widgets stay concise. Errors use friendly recovery instructions.
Names are stored locally and shared with the widget through the App Group; they
may be visible in notification previews. Editing the name refreshes pending
reminder wording without changing their triggers. New reminders use the saved
name. Device checks: skip, blank/whitespace, nicknames with apostrophes, Unicode,
long names, rename/remove, relaunch, and notification/widget wording.

## Android app
The native Android app is in android/. See android/README.md for setup and scope.
Build Android produces a debug APK for LDPlayer or Android phones. It includes
Home/Calendar/Plans/Settings tabs, saved plans with notes, plan search and filters,
calendar import, manual travel time, directions links, personalized reminders,
achievements, R/J themes, and a Home Screen departure widget.
Live route estimates and cloud/iOS sync remain future integrations.
Android testing does not validate the separate SwiftUI iOS implementation.

## Shared design and daily achievements
See design/README.md for the cross-platform design template. Both apps use the
same design/achievements.json catalog for random daily achievement messages at
5, 8, 12, 20, and 30 saved plans per arrival day. Milestones grow more astonished,
use the preferred name, and notify only once per milestone per day when existing
notification access permits. Each app has a separate achievement-notification
toggle. These count plans, not completed journeys.
