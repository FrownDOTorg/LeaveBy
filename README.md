# LeaveBy
A native SwiftUI departure planner for iOS 17 and later.

## First milestone
Enter an event and arrival time, search Apple Maps for both places, then choose driving or walking and calculate travel time. Extra time shifts the requested arrival earlier. Manual travel duration is also available. Places and settings persist; estimates must be recalculated after trip changes or relaunch. Calendar access, notifications, and widgets are not implemented yet.

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
