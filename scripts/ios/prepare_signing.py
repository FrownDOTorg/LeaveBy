"""Decode runner-only signing secrets and validate profile entitlements. Never logs secret values."""
import base64
import datetime
import json
import os
from pathlib import Path
import plistlib
import subprocess

TEAM = "WCL29SZ993"
GROUP = "group.com.frowndotorg.leaveby"

def main():
    folder = Path(os.environ["RUNNER_TEMP"]) / "leaveby-signing"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "certificate.p12").write_bytes(base64.b64decode(os.environ["IOS_CERTIFICATE_P12_BASE64"], validate=True))
    key = os.environ["ASC_PRIVATE_KEY"].strip()
    if not key.startswith("-----BEGIN PRIVATE KEY-----"):
        raise ValueError("ASC_PRIVATE_KEY must contain the complete downloaded .p8 file")
    key_id = os.environ["ASC_KEY_ID"].strip()
    if not key_id.isalnum():
        raise ValueError("ASC_KEY_ID contains unexpected characters")
    (folder / f"AuthKey_{key_id}.p8").write_text(key + "\n")
    profiles = Path.home() / "Library/MobileDevice/Provisioning Profiles"
    profiles.mkdir(parents=True, exist_ok=True)
    mapping = {}
    for role, secret, bundle in [
        ("app", "IOS_APP_PROFILE_BASE64", "com.leaveby.planner"),
        ("widget", "IOS_WIDGET_PROFILE_BASE64", "com.leaveby.planner.widgets"),
    ]:
        path = profiles / f"leaveby-{role}.mobileprovision"
        path.write_bytes(base64.b64decode(os.environ[secret], validate=True))
        data = plistlib.loads(subprocess.check_output(["security", "cms", "-D", "-i", str(path)]))
        entitlements = data["Entitlements"]
        if data["TeamIdentifier"] != [TEAM] or entitlements["application-identifier"] != f"{TEAM}.{bundle}":
            raise ValueError(f"Wrong team or app in {secret}")
        if GROUP not in entitlements.get("com.apple.security.application-groups", []):
            raise ValueError(f"Missing shared widget group in {secret}")
        if entitlements.get("get-task-allow") or data.get("ProvisionedDevices") or data.get("ProvisionsAllDevices"):
            raise ValueError(f"{secret} must be an App Store Connect distribution profile")
        if data["ExpirationDate"] <= datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None):
            raise ValueError(f"{secret} has expired")
        mapping[bundle] = data["UUID"]
    Path("build/profiles.json").write_text(json.dumps(mapping))
    options = {
        "method": "app-store-connect", "destination": "upload", "teamID": TEAM,
        "signingStyle": "manual", "signingCertificate": "Apple Distribution",
        "provisioningProfiles": mapping, "uploadSymbols": True,
        "manageAppVersionAndBuildNumber": False,
    }
    with open("build/ExportOptions.plist", "wb") as output:
        plistlib.dump(options, output)
    print("Validated app and widget distribution profiles.")

if __name__ == "__main__":
    main()
