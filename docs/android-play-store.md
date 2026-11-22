# Android & Google Play Release Guide

Path of Leash Resistance ships for Android (`com.santtunykanen.pathofleashresistance`) using Godot 4.7's GL Compatibility renderer, gradle AAB builds (`targetSdkVersion = 36`, `minSdkVersion = 24`), safe-area HUD/touch inset layout, Android Back navigation, and pause-on-background handling.

## Signing Keys & GitHub Secrets

Generate a dedicated upload keystore locally (never commit the `.keystore` file):

```bash
keytool -genkeypair -v -keystore upload.keystore -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
base64 -w0 upload.keystore
```

Add these as secrets of the `google-play` environment (**Settings > Environments**, deploying from `v*` tags and `main`; see `docs/release-secrets.md`, which also says how to check them with `credentials.yml` without publishing):

| Secret | Value | Required |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded `upload.keystore` | Yes (without it, `.github/workflows/release.yml`'s `android` job skips cleanly) |
| `ANDROID_KEY_ALIAS` | Key alias (e.g. `upload`) | Yes when building Android |
| `ANDROID_KEY_PASSWORD` | Keystore/key password | Yes when building Android |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Google Play Console API JSON key | Optional (enables automatic upload to the `internal` track) |

## Regenerating Adaptive Icons

Android adaptive icons (`432x432` foreground + background in `store/android/`) are generated from the same vector artwork in `tools/make_icon.gd`:

```bash
godot/Godot_v4.7-stable_win64_console.exe --rendering-method gl_compatibility --path . --script res://tools/make_icon.gd -- --android
```

## Google Play Console Setup

- **App identity**: package `com.santtunykanen.pathofleashresistance`, landscape orientation, Play App Signing enrolled on first internal upload.
- **Closed Testing requirement**:
  - **Personal developer accounts** created after November 2023 must run a Closed Test with at least **12–20 opted-in testers continuously for 14 days** before Production access unlocks.
  - **Organization accounts** do not have the 14-day tester gate.
- **Data Safety**:
  - Collects no personal data (`No, we do not collect or share user data`).
  - Save progress (`user://save.json`) is stored strictly on-device with no analytics, ads, or network requests (`permissions/internet=false`).
- **Content Rating (IARC)**: Mild comic mischief and stylized cartoon fantasy mild peril/bugs/fireworks; no gambling, real-money IAP, or user-generated content.
