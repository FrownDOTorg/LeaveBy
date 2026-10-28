"""Reject mismatched app/extension versions before sending an archive to Apple."""
from pathlib import Path
import plistlib

app = Path("build/LeaveBy.xcarchive/Products/Applications/LeaveBy.app")
with (app / "Info.plist").open("rb") as handle:
    parent = plistlib.load(handle)
extensions = list((app / "PlugIns").glob("*.appex/Info.plist"))
if not extensions:
    raise SystemExit("Expected the LeaveBy widget in the archive")
for path in extensions:
    with path.open("rb") as handle:
        child = plistlib.load(handle)
    for key in ("CFBundleVersion", "CFBundleShortVersionString"):
        if child.get(key) != parent.get(key):
            raise SystemExit(f"{path.parent.name}: {key} does not match the app")
print(f"Verified app and widget versions: {parent['CFBundleShortVersionString']} ({parent['CFBundleVersion']})")
