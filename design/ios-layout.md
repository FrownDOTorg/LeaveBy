# iOS app layout

The iOS app now follows the Android app's four-tab layout, using native SwiftUI controls and the shared J, R, Light and Dark palettes.

- Home: personal greeting, live next-departure countdown, quick add, today's plan count, scheduled reminders and upcoming plans.
- Calendar: date selection, per-day plans, Apple Calendar import, and add/edit/delete.
- Plans: search titles, selected place names, calendar locations and notes; Upcoming, All and Reminders filters; plans grouped by day.
- Settings: name, theme, notification settings, extra notifications and widget instructions. Achievement milestones stay a surprise.
- Plan editor: Apple Maps place search and driving/walking estimates, manual travel time, extra time, notes and departure reminders.

Existing saved plans are compatible: notes are optional. Reopening a saved Maps plan reuses its matching saved estimate until route inputs change. Editing reminder inputs clears the old reminder; the editor lets the user set a fresh one.

## Verification before TestFlight

Push changes and confirm the Build iOS workflow succeeds. That compiles the app and widget on a Mac runner; its simulator artifact cannot be installed on an iPhone.

Then, on an iPhone with a signed TestFlight build:

1. Choose a name and switch through all four themes. Check readability and large text.
2. Add a manual plan with notes, edit it, and search for its title and notes. Check day and reminder filters.
3. Calculate an Apple Maps trip, close and reopen the editor, and confirm the saved departure remains. Change a route input and check that a new calculation is required.
4. Schedule a future reminder, confirm it arrives, and check the reminder count after returning to the app.
5. Import a calendar event, verify duplicate prevention, and delete the copy without affecting Apple Calendar.
6. Add Home and Lock Screen widgets, then change the next departure and theme.
7. Relaunch the app and confirm plans, notes, name and theme persist.

The layout changes have not been run in an iOS Simulator on this Windows computer. Signing and TestFlight upload setup are still separate steps.
