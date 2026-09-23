# Publishing to the Microsoft Store

How to get the Windows build of Path of Leash Resistance into the Microsoft
Store through Partner Center. Written 2026-09-23 against Partner Center's
"Apps and games" page as it stood then. Microsoft changed the game publishing
options in mid-2026, so check the "Still unconfirmed" list before relying on
the product-type choice.

What already exists:

- `release.yml` builds `build/win/PathOfLeashResistance.exe` (x86_64, PCK
  embedded, over 20 MB) on every version tag, and attaches it to the GitHub
  release as `leash-resistance-windows.zip`.
- `store/msix/` holds the Store manifest (with this product's identity) and
  tile images generated from `icon.png` by `tools/make_msix_assets.py`.
- `tools/pack_msix.ps1` packs an exported exe into an unsigned MSIX;
  `tools/verify_msix.ps1` installs it with a throwaway test certificate,
  launches it packaged, and checks Godot's log.
- `release.yml` has an `msix` job: on every version tag it packs the freshly
  exported exe, verifies it on a Windows runner, and attaches
  `PathOfLeashResistance-X.Y.0.0.msix` to the GitHub release. That file is
  the Partner Center upload.
- `msix.yml` runs the same pack, install and launch, plus WACK, on PRs that
  touch the packaging, against the latest release's exe.
- WACK runs fine on GitHub's hosted Windows runners
  (`tools/wack_msix.ps1`). The v1.54 package's overall result is WARNING:
  "Blocked executables" fails, but it is optional (the Godot engine
  references process-launch APIs, which only matters for Windows 10 S), and
  "DPIAwarenessValidation" warns because Godot enables DPI awareness at
  runtime, where a static scan can't see it. Neither blocks certification.
- The old `ms-store-msix` branch was superseded by this and is not needed.

## 0. Pick the product type

Partner Center > Apps and games > **New product** offers four types:

| Option | What it is | Fit for this game |
|---|---|---|
| MSIX or PWA app | Store-hosted MSIX, app categories | Works technically, but files a game as an app |
| EXE or MSI app | Store lists an installer you host at your own URL; installer must be Authenticode-signed | No: needs a paid code-signing certificate and our own hosting |
| GDK game | Microsoft's recommended route for Win32 games since June 2026; self-service, packaged as MSIXVC with the GDK's `MakePkg` and a `MicrosoftGame.config` | Recommended by the docs, but Windows-only tooling and a new pipeline |
| **MSIX or PWA game** | Store-hosted MSIX in the Games section | **Use this.** `store/msix/` is built for it |

The docs route *UWP and PWA* games to "MSIX or PWA game" and *Win32* games to
"GDK game". No doc says a full-trust Win32 MSIX is refused under "MSIX or PWA
game", and a desktop-bridge MSIX is still an MSIX package. Try it first, since
the reservation and the first upload cost nothing. If package ingestion
refuses the full-trust package, switch to **GDK game** (see the end of this
doc).

Your existing live product (type "MSIX or PWA app") is not affected by any of
this.

## 1. Reserve the name

1. **New product > MSIX or PWA game**.
2. Enter `Path of Leash Resistance`, check availability, and **Reserve product
   name**. The reservation holds for 3 months before a submission must follow.

## 2. Copy the product identity

Done for this product. Partner Center > Product management > Product
identity shows:

| Partner Center field | Value | In `store/msix/AppxManifest.xml` |
|---|---|---|
| Package/Identity/Name | `SanttuNyknen.PathofLeashResistance` | `<Identity Name>` |
| Package/Identity/Publisher | `CN=B41D15B4-C2B7-498F-920E-E8D2AEA35338` | `<Identity Publisher>` |
| Package/Properties/PublisherDisplayName | `Santtu Nykänen` | `<PublisherDisplayName>` |
| Store ID | `9P5D14V8RBQX` | used by the CLI in step 7 |

If Partner Center ever shows different values, the manifest is what changes.

## 3. Build the MSIX

Normally nothing to do: tag a release, and the `msix` job in `release.yml`
attaches `PathOfLeashResistance-X.Y.0.0.msix` to the GitHub release. Download
it from there.

To build one by hand on Windows (needs the Windows SDK for MakeAppx):

```
powershell -File tools/pack_msix.ps1 -Exe build/win/PathOfLeashResistance.exe -Tag v1.55
```

Take the exe from the tag's `leash-resistance-windows.zip` release asset, so
it carries the stamped version label.

What the script does, for when something needs changing:

- **Version:** tag `vX.Y` becomes `X.Y.0.0`, and `vX.Y.Z` becomes `X.Y.Z.0`.
  The Store needs four parts, each 0-65535, the first above 0 and the last 0,
  and each submission higher than the previous one.
- **Contents:** the exe, `store/msix/AppxManifest.xml` with that version
  written in, and `store/msix/Assets/`. After changing `icon.png`, rerun
  `python tools/make_msix_assets.py`. WACK rejects images over 200 KB and
  default template images.
- **Manifest:** a full-trust desktop game (`runFullTrust`, `uap10`
  `packagedClassicApp`, Windows 10 19041 or later, x64).
- **Unsigned on purpose:** the Store re-signs every package and replaces
  any existing signature. Upload the unsigned `.msix`; `.msixupload` is not
  needed.

## 4. Test the package

CI already installs and launches every package it builds
(`tools/verify_msix.ps1`: throwaway test certificate, launch through the
package's app entry, Godot's log read from the package's private AppData).
`msix.yml` also runs the Windows App Certification Kit and uploads its report.

Still worth doing by hand before the first submission, in an elevated
PowerShell on your own machine:

```
powershell -File tools/verify_msix.ps1 -Msix PathOfLeashResistance-1.55.0.0.msix -RunSeconds 5
```

Then play from the Start menu entry the script installed. That entry goes
away when the script uninstalls it, so to play longer, comment out the
`Remove-AppxPackage` line or reinstall. Check that:

- a walk plays start to finish
- settings and records survive a restart. Godot's `user://` lives under
  `%APPDATA%\Godot\app_userdata\Path of Leash Resistance`, which MSIX
  redirects to `%LOCALAPPDATA%\Packages\<family name>\LocalCache\Roaming\...`
  and deletes on uninstall. If that folder already exists from normal runs,
  the packaged build uses the real one, so rename it while testing.
- WACK passes (`appcert.exe test -appxpackagepath <msix> -reportoutputpath
  wack.xml`, as admin). Required: image sizes, version ending in 0, x64
  binaries, no elevation, no `.pfx` in the package.

## 5. Fill in the submission

Start a submission on the product. Every section must be complete:

1. **Pricing and availability:** Free. All markets, unless there is a reason
   to exclude some. Free matters later: the CLI can only push updates to free
   products.
2. **Properties:** category **Games**, then 1-3 genres (e.g. Action +
   adventure, Family + kids, Simulation). A product published as Games can
   never change category. Privacy policy URL: only required if the game
   collects personal information. It does not today (saves are local), so
   leave it empty unless that changes.
3. **Age ratings:** complete the IARC questionnaire, or enter an existing
   IARC rating ID if itch or another store already produced one.
4. **Packages:** upload the `.msix` from step 3. Ingestion validates it here.
   If it rejects the full-trust package for this product type, that is the
   signal to switch to GDK game.
5. **Store listings (English):**
   - Description, and short description from `PROJECT.md`'s pitch.
   - Screenshots: PNG, at least **1366x768** (up to 3840x2160), at least 1,
     4 or more recommended, 10 at most. The sweep's shots are 1280x720, too
     small, so take listing shots at 1920x1080 with the existing flags:

     ```
     godot/Godot_v4.7-stable_win64_console.exe --rendering-method gl_compatibility --resolution 1920x1080 --path . -- --shot --shot-quit --shot-out=store-park.png --level=park
     ```

     Use `--shot-at=N` with `--autowalk` for mid-walk moments, and
     `--shot-title` for the title. Run it on a stamped build, or delete
     `build_label.txt` first, so the corner label is what you want shown.
   - Store logos: 2:3 poster art at 720x1080 (strongly recommended for
     games), 1:1 box art at 1080x1080, 1:1 tile icon at 300x300. The concept
     key art in `assets/concept/` is the starting point.
   - A trailer is optional. If you add one, 16:9 hero art at 1920x1080 becomes
     required.
6. **Submission options > Restricted capabilities:** a justification for
   `runFullTrust` is required. Suggested text: "Path of Leash Resistance is a
   Win32 desktop game built with the Godot engine. runFullTrust is required
   to run the packaged Win32 executable; the game uses no other restricted
   capabilities." A Partner Center bug reported in April 2026 can leave this
   section showing "Incomplete" after it is filled. Re-save it, or ask
   support if it persists.
7. **Submit to the Store.** Certification takes up to three business days.
   Once it passes, the listing appears in about 15 minutes.

## 6. Each release after the first

1. Tag the release. When `release.yml` finishes, download the `.msix` from
   the GitHub release.
2. Create a new submission in Partner Center (it copies the previous one),
   replace the package, update "What's new", and submit.

## 7. Automating it later (optional)

Only once the first submission is live, and only while the game is free:

- The Microsoft Store Developer CLI (`msstore`, runs on Windows, macOS and
  Linux, needs .NET 9) pushes a package to an existing product:
  `msstore publish . --inputFile PathOfLeashResistance-1.55.0.0.msix --appId <Store ID>`.
  It needs an Entra ID tenant linked to Partner Center and an app
  registration with the Manager role (`msstore reconfigure --tenantId
  --sellerId --clientId --clientSecret`), stored as repo secrets.
- The official Action is `microsoft/microsoft-store-apppublisher`. Its
  examples run on `windows-latest`, which the MakeAppx step needs anyway, so
  the job would be a Windows job in `release.yml`, after the itch push, so a
  Store failure never blocks itch.

## Fallback: GDK game

If "MSIX or PWA game" refuses the package, reserve the name under **GDK
game** instead. That route needs:

- the Microsoft GDK (Windows) and its `MakePkg` tool, packaging the exe as
  MSIXVC with a `MicrosoftGame.config`. The docs' sample config needs no code
  changes to the game.
- identity values from **Game setup > Identity details** (Store ID, MSAAppId,
  TitleId) instead of Product identity.

That is a separate pipeline and would replace most of `store/msix/`, so do
not start it until the MSIX route has actually been refused.

## Still unconfirmed (as of 2026-09-23)

1. Whether "MSIX or PWA game" accepts a full-trust Win32 MSIX. The docs only
   route UWP and PWA games there. The first package upload answers this.
2. Whether the GDK route truly needs no ID@Xbox enrolment. One GDK packaging
   page still says it does; the June 2026 self-service page says it does not.
3. Whether `makemsix` on Linux produces packages Partner Center accepts.

## Sources

- Game publishing options (2026): https://learn.microsoft.com/en-us/windows/apps/publish/whats-new-game-publishing
- Product identity: https://learn.microsoft.com/en-us/windows/apps/publish/view-app-identity-details
- Package requirements: https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/app-package-requirements
- Manual desktop-to-MSIX manifest: https://learn.microsoft.com/en-us/windows/msix/desktop/desktop-to-uwp-manual-conversion
- MakeAppx: https://learn.microsoft.com/en-us/windows/msix/package/create-app-package-with-makeappx-tool
- MSIX file system behaviour: https://learn.microsoft.com/en-us/windows/msix/desktop/desktop-to-uwp-behind-the-scenes
- WACK: https://learn.microsoft.com/en-us/windows/uwp/debug-test-perf/windows-app-certification-kit
- Desktop package tests: https://learn.microsoft.com/en-us/windows/uwp/debug-test-perf/windows-desktop-bridge-app-tests
- Submission checklist: https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/create-app-submission
- Categories: https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/categories-and-subcategories
- Age ratings: https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/age-ratings
- Screenshots and images: https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/screenshots-and-images
- Certification: https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/app-certification-process
- msstore CLI: https://learn.microsoft.com/en-us/windows/apps/publish/msstore-dev-cli/commands
- msstore in GitHub Actions: https://learn.microsoft.com/en-us/windows/apps/publish/msstore-dev-cli/github-actions
- MSIX SDK on Linux: https://learn.microsoft.com/en-us/windows/msix/msix-sdk/msix-linux
