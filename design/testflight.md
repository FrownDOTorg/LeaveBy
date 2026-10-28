# TestFlight uploads

The Upload iOS to TestFlight workflow is manual-only and only runs from main. Normal pushes keep using the simulator build check.

Required repository Actions secrets:
- ASC_PRIVATE_KEY: entire downloaded App Store Connect team API .p8 key
- ASC_KEY_ID and ASC_ISSUER_ID: identifiers from the same team key
- IOS_CERTIFICATE_P12_BASE64: base64 Apple Distribution certificate plus matching private key
- IOS_CERTIFICATE_PASSWORD: password for that P12
- IOS_APP_PROFILE_BASE64 and IOS_WIDGET_PROFILE_BASE64: base64 App Store Connect profiles for the main app and widget

The workflow validates bundle IDs, team, shared App Group, expiry and distribution type. It installs signing material only on the temporary Mac runner, signs both targets, archives version 1.0 with a unique run/attempt build number, and uploads using Xcode's App Store Connect authentication. Temporary certificates, API keys and profiles are cleaned up even after failure. Signing material is never uploaded as a workflow artifact.

After committing and pushing: Actions > Upload iOS to TestFlight > Run workflow > main > Run workflow. A successful upload still requires Apple processing. Then check TestFlight, complete any requested export compliance information, and add an internal tester group with yourself. Friends outside your App Store Connect team use external testing, which can require beta review. This workflow does not submit a public App Store release.

The navy/purple clock is a simple initial app icon. The app and widgets still require real iPhone verification, including the shared group and reminders. This Windows machine cannot run Xcode; the Mac workflow performs the first signed archive/export validation.

Local signing files live outside the repository in LeaveBy-Signing. Keep those files private and retain a secure backup. Never commit them or paste their contents in chat.
