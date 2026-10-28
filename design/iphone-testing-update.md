# iPhone testing update

Implemented for the next TestFlight build:

- Plan/name/place-search keyboard dismissal toolbar and interactive scroll dismissal.
- Rebuild visible tab content when appearance changes, bind countdown colors to the selected theme, and make widget theme reads come from the shared app group. Existing plans keep their data.
- One-shot foreground My Location selection with When In Use permission; no continuous tracking. Saved Home, Work and Gym can be selected for either end of a trip and managed in Settings.
- Drive/walk estimate badge beside Calculate, adapting vertically for large text, with a last-successful-update timestamp.
- Store travel seconds independently from extra time. Extra-time changes shift departure without discarding the route estimate; route/mode/arrival changes still require a new estimate. Previous saved estimates migrate on load.
- Read-only selected-calendar sync over a rolling 12 months, fetched in monthly windows, excluding all-day events. Reconcile on launch/return and EventKit database changes, defer while editing, keep LeaveBy notes/travel preferences, and prevent deleted LeaveBy copies from reappearing. Selected calendar name/time/location are authoritative; changed time/location clears the old reminder and changed location requires confirming a new Maps place. Calendar identifiers can change after account/provider resets; reconnecting may require checking for duplicate plans.
- Foreground and opportunistic background refresh for up to three earliest saved Maps trips in the next 24 hours, no more than once per 15 minutes per successful estimate. Active reminders and widget snapshots update after successful refresh. Current-location trips use the point captured when selected. Failed refresh retains the last estimate/time; iOS controls wakeups and widgets can also refresh late.
- Home next-departure delete button and context menu; upcoming plans support swipe/context-menu delete, all with confirmation.
- Calendar bulk sync establishes achievement history silently so a year of events does not cause a burst of alerts. Milestones remain absent from explanatory UI.

GitHub build and upload workflows now run real Swift regression checks for departure math, buffer edits, persistence, route invalidation and legacy migration before compiling the app. Windows checks cover source/configuration review and palette contrast; SwiftUI compilation and on-device permission/background behavior still require the Mac runner and iPhone.

## Phone smoke test

1. Switch J > R > Light > Dark with existing plans; inspect Home countdown, tabs, editor, popups and widgets.
2. Calculate a Maps trip, change extra time up/down, close/reopen, then change the destination and verify recalculation is required.
3. Hide the keyboard in plan, profile and search fields. Test large text.
4. Deny/allow My Location, select Home/Work/Gym and check saved places survive reopening.
5. Connect a test calendar with events months apart and recurring instances. Add/move/delete a calendar event; verify notes and travel choices survive and reminders do not keep obsolete times.
6. Delete a linked plan in LeaveBy and refresh; it must stay hidden while the Apple event remains.
7. Schedule a future reminder and return after the estimate is old enough for automatic refresh. Check the timestamp, departure, pending reminder and widgets. Background refresh is opportunistic, not an exact timer.

No certificate or profile changes are needed for foreground location and background fetch. New Info.plist configuration includes the permission explanation, background task ID/fetch mode and the current app's non-exempt-encryption declaration.
