#!/bin/bash
set -euo pipefail
umask 077
for name in ASC_PRIVATE_KEY ASC_KEY_ID ASC_ISSUER_ID IOS_CERTIFICATE_P12_BASE64 IOS_CERTIFICATE_PASSWORD IOS_APP_PROFILE_BASE64 IOS_WIDGET_PROFILE_BASE64; do
  if [ -z "${!name:-}" ]; then
    echo "::error::Missing repository secret: $name"
    exit 1
  fi
done
mkdir -p "$RUNNER_TEMP/leaveby-signing" build
python3 scripts/ios/prepare_signing.py
KEYCHAIN="$RUNNER_TEMP/leaveby-signing.keychain-db"
KEYCHAIN_PASSWORD=$(openssl rand -hex 32)
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security set-keychain-settings -lut 21600 "$KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security import "$RUNNER_TEMP/leaveby-signing/certificate.p12" -k "$KEYCHAIN" -P "$IOS_CERTIFICATE_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN" >/dev/null
security list-keychains -d user -s "$KEYCHAIN" "$HOME/Library/Keychains/login.keychain-db"
ruby scripts/ios/release_project.rb
xcodegen generate --spec project-release.json --project .
xcodebuild -project LeaveBy.xcodeproj -scheme LeaveBy -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/LeaveBy.xcarchive \
  -derivedDataPath build/DerivedData archive
python3 scripts/ios/verify_archive.py
xcodebuild -exportArchive -archivePath build/LeaveBy.xcarchive \
  -exportPath build/export -exportOptionsPlist build/ExportOptions.plist \
  -authenticationKeyPath "$RUNNER_TEMP/leaveby-signing/AuthKey_${ASC_KEY_ID}.p8" \
  -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID"
echo "Upload finished. Apple still needs to process the build before it appears in TestFlight."
