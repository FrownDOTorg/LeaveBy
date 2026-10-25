# LeaveBy
A native SwiftUI departure planner for iOS 17 and later.

## First milestone
Enter an event and arrival time, search Apple Maps for both places, then choose driving or walking and calculate travel time. Extra time shifts the requested arrival earlier. Manual travel duration is also available. Places and settings persist; estimates must be recalculated after trip changes or relaunch. Departure reminders are available with notification permission. Calendar access and widgets are not implemented yet.

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

Widgets require a WidgetKit extension. Sharing event data normally uses an
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
asks for notification permission only when setting a reminder. One pending reminder
is supported; setting it again replaces the previous one. It remains scheduled
when the app closes, including after relaunch. Editing the plan or recalculating
cancels the old reminder; explicitly set a new one afterward. A denied permission
shows a link to Settings. Focus and system settings may delay or silence alerts.
The reminder uses the saved departure, not background traffic updates.

Device validation once signing is ready: allow permission and schedule a manual
trip departing two minutes from now; check delivery while locked and while the
app is open. Check cancellation after editing, replacement, relaunch persistence,
past-departure rejection, and denied permission with Settings recovery.
