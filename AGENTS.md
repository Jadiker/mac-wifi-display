# Repository Instructions

- When changing app code or user-visible behavior, update the version metadata in `Packaging/Info.plist`.
- Increment `CFBundleVersion` for every changed build.
- Increment `CFBundleShortVersionString` when the change should be visible as a new user-facing app version.
- After updating version metadata, rebuild and install with `scripts/build_app.sh --install` when the user wants the app installed locally.
