## 2026-11-22 - Android build that runs

- The Android export now installs Godot's gradle build template, targets
  API 36 (what Google Play requires of new apps and updates since August
  2026) and takes its signing key through Godot's own environment variables
  instead of writing the password into export_presets.cfg.
- One script, `tools/android_export.sh`, does the export for release.yml and
  for the new android.yml, which builds it on every pull request touching the
  Android export with a throwaway key and keeps the APK to install by hand.
