# LeaveBy for Android

Native Android app for Android 7.0 / API 24 and later, including LDPlayer.
The iOS implementation remains separate.

## Screens
- Home: next departure/countdown, today's plan count, reminder status,
  daily achievements, and upcoming plans.
- Calendar: compact week selection, full-date picker, per-day plan list,
  add/edit/delete, and calendar import for the selected day.
- Plans: search event names, places, and notes; filter upcoming/all/reminder plans.
- Settings: preferred name, R/J themes, notification settings/test, achievement
  notification toggle, and Home Screen widget installation.
- Event editor: arrival date/time, start/destination, notes, driving/walking,
  manual travel and buffer minutes, countdown, save, reminders, and directions.

## Travel and calendars
Open directions sends the entered places to Google Maps or a browser, using Maps
URLs without an API key. It does not import the ETA. Enter travel time manually;
live route estimates need a future routing-provider integration.
Calendar import requests READ_CALENDAR only after an explicit import action.
Only timed events starting on the selected local day are listed, up to 100.
Select the events to copy; original events stay untouched. Calendar occurrence
ID + start time prevents duplicate imports, though provider resyncs/rescheduling
can change IDs. Copies are not synchronized. No reminders are set by import.
LDPlayer may have no calendar account/events; manual plans still work.

## Widget
Use Settings > Add a departure widget, or the launcher's Widgets picker.
The widget shows the next saved departure, live Chronometer countdown, and the
chosen theme. Edits/deletions, theme changes, and app launches refresh it.
An inexact alarm requests a transition after departure, with periodic refreshes
as a fallback. Android may delay updates: after a missed transition the native
Chronometer can briefly count past zero until refresh. No traffic polling.
Widget taps and departure notification taps open their associated saved plan.

## Build and install
Commit and push, then open GitHub Actions > Build Android. The workflow uses
JDK 17, Gradle 8.11.1, AGP 8.9.2, and Android SDK 35. It runs unit tests, lint,
and assembles a debug APK. Download LeaveBy-Android-APK from a successful run,
extract the ZIP, and drag app-debug.apk into LDPlayer.
No Apple or Google Play developer membership is required for emulator testing.

The APK uses Android debug signing. GitHub caches its test keystore to allow
updates while the cache survives. If the cache expires and Android reports a
signing conflict, a reinstall may be needed and deletes local plans. A production
release needs a durable release signing key stored securely outside the repo.

## Notifications and storage
Reminders use inexact AlarmManager scheduling; Android may delay delivery.
Keep LDPlayer running. Test notification sends an immediate separate alert.
Android 13+ requests notification permission. Editing/saving clears an old
reminder unless Save & remind me is chosen. Reboot restores future reminders.
Force-stop may disable alarms until the app is opened and reminders reset.
Plans, settings, and achievement history stay locally on this device; no iOS
sync or cloud account. Existing saved plans migrate with defaults for new fields.

## Verification
CI unit tests cover departure math, input names, achievement thresholds/dedup,
search, and calendar-day boundaries. Device checks still required:
- All tabs, Back navigation, theme persistence, and existing plan retention.
- Add/edit/delete, notes, search/filter, and movement between calendar dates.
- Save/relaunch, countdown, reminder replacement/cancellation and deep links.
- Calendar permission allow/deny, empty provider, duplicates, batch import,
  all-day exclusion, and original event preservation.
- Directions with and without a Maps app/browser.
- Widget pinning, themes, tap behavior, edits, deletion, and departure transition.
- Notification test, real reminder, and achievement boundaries independently.

Android testing does not validate the separate SwiftUI iOS app.
