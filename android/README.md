
# Android test version

Native Android preview for Android 7.0 / API 24 or later, including LDPlayer.
Features: preferred name, calendar with multiple saved events, manual travel and
buffer time, countdowns, per-event departure notifications, and a test notification.
Data is stored locally in the emulator. This is separate from iOS storage.
Live travel estimates, calendar import, Android widgets, and cloud sync are not
included. Apple Maps cannot run on Android.

## Build and install
Push to main, then open GitHub Actions > Build Android. The workflow uses JDK 17,
Gradle 8.11.1, AGP 8.9.2, and Android SDK 35. It runs unit tests, lint, and assembles
a debug APK. Download LeaveBy-Android-APK from the successful run, extract the ZIP,
then drag app-debug.apk into the running LDPlayer window.
No Apple membership or Google Play developer membership is needed for this test.

The APK uses Android debug signing, not a production signing key. GitHub caches
the debug keystore to allow upgrades while that cache survives. If it expires and
Android reports a signing conflict, uninstall the old preview before reinstalling;
uninstalling deletes local plans. Production distribution requires a durable,
securely stored release signing key. Never use the debug key for a public release.

## Reminder limits
These are inexact AlarmManager reminders: Android may delay them. Keep the emulator
running; a suspended/off emulator cannot deliver a notification. Test notification
sends an immediate notification, separate from the departure alarm. Notification
permission is requested on Android 13+. Editing/saving cancels an old alarm unless
Save & remind me is chosen. Reboot restores future saved reminders; force-stopping
the app may prevent reminders until it is opened and reminders are set again.

## Verification
Unit tests cover travel/buffer subtraction across midnight, zero and invalid
durations, nickname whitespace, and Unicode name truncation.
After installation, verify naming/skip/change, multiple dates and events, saving
and relaunch, countdown updates, invalid times, notification permission/denial,
test notification, reminder replacement, and deletion. Emulator success does not
verify the SwiftUI iOS app; those platforms still need separate device testing.
