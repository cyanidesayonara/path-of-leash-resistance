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
- Branch `ms-store-msix` (5 commits, only on the other machine, not yet
  pushed) wraps that exe in an MSIX. It predates v1.54 and needs a rebase onto
  `main` before it builds. This guide assumes that branch provides the
  `AppxManifest.xml` and assets. The template in step 3 is a reference to
  check it against, not a replacement.

## 0. Pick the product type

Partner Center > Apps and games > **New product** offers four types:

| Option | What it is | Fit for this game |
|---|---|---|
| MSIX or PWA app | Store-hosted MSIX, app categories | Works technically, but files a game as an app |
| EXE or MSI app | Store lists an installer you host at your own URL; installer must be Authenticode-signed | No: needs a paid code-signing certificate and our own hosting |
| GDK game | Microsoft's recommended route for Win32 games since June 2026; self-service, packaged as MSIXVC with the GDK's `MakePkg` and a `MicrosoftGame.config` | Recommended by the docs, but Windows-only tooling and a new pipeline |
| **MSIX or PWA game** | Store-hosted MSIX in the Games section | **Use this.** It matches the existing `ms-store-msix` work |

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

In the new product: **Product management > Product identity**. Copy these
three values exactly (they are case-sensitive):

| Partner Center field | Goes into AppxManifest.xml |
|---|---|
| Package/Identity/Name | `<Identity Name="...">` |
| Package/Identity/Publisher | `<Identity Publisher="CN=...">` |
| Package/Properties/PublisherDisplayName | `<PublisherDisplayName>` |

Also note the **Store ID** (12 characters, starts with `9`). The CLI in step 8
needs it.

## 3. Build the MSIX (on Windows)

MakeAppx and the Windows App Certification Kit are Windows-only. The MSIX SDK
can pack on Linux (`makemsix`, built with `-DMSIX_PACK=on`), but whether
Partner Center accepts its output is undocumented, so pack on Windows. That
means locally, or later on a `windows-latest` job.

1. Get the exe for the tag you are shipping: download
   `leash-resistance-windows.zip` from that tag's GitHub release. It carries
   the stamped version label, so the Store build shows e.g. `v1.55 (a1b2c3d)`
   on its title screen.
2. Lay out a staging folder:

   ```
   msix/
     AppxManifest.xml
     PathOfLeashResistance.exe
     Assets/StoreLogo.png          50x50
     Assets/Square44x44Logo.png    44x44
     Assets/Square150x150Logo.png  150x150
     Assets/Wide310x150Logo.png    310x150 (optional)
   ```

   Each image must be under 200 KB and must not be a default template image;
   WACK checks both. Generate them from `icon.png` / `tools/make_icon.gd`
   rather than drawing new ones.

3. Check the branch's manifest against this minimum for a full-trust desktop
   game:

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <Package
     xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
     xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
     xmlns:uap10="http://schemas.microsoft.com/appx/manifest/uap/windows10/10"
     xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
     IgnorableNamespaces="uap uap10 rescap">
     <Identity Name="(from step 2)" Publisher="CN=(from step 2)"
               Version="1.55.0.0" ProcessorArchitecture="x64" />
     <Properties>
       <DisplayName>Path of Leash Resistance</DisplayName>
       <PublisherDisplayName>(from step 2)</PublisherDisplayName>
       <Logo>Assets\StoreLogo.png</Logo>
     </Properties>
     <Dependencies>
       <TargetDeviceFamily Name="Windows.Desktop"
                           MinVersion="10.0.19041.0" MaxVersionTested="10.0.26100.0" />
     </Dependencies>
     <Resources><Resource Language="en-us" /></Resources>
     <Applications>
       <Application Id="PathOfLeashResistance"
                    Executable="PathOfLeashResistance.exe"
                    uap10:RuntimeBehavior="packagedClassicApp"
                    uap10:TrustLevel="mediumIL">
         <uap:VisualElements DisplayName="Path of Leash Resistance"
                             Description="You are the dog. Go touch grass."
                             BackgroundColor="transparent"
                             Square150x150Logo="Assets\Square150x150Logo.png"
                             Square44x44Logo="Assets\Square44x44Logo.png" />
       </Application>
     </Applications>
     <Capabilities>
       <rescap:Capability Name="runFullTrust" />
     </Capabilities>
   </Package>
   ```

   To support Windows older than 10.0.19041, replace the two `uap10:`
   attributes with `EntryPoint="Windows.FullTrustApplication"`.

4. **Version:** four parts, each 0-65535. The first part must not be 0 and the
   last part must be 0 for the Store. Map tag `vX.Y` to `X.Y.0.0`, e.g. `v1.55`
   becomes `1.55.0.0`. Each new submission needs a higher version than the
   last.

5. Pack, using MakeAppx from the Windows SDK:

   ```
   MakeAppx pack /v /h SHA256 /d msix /p PathOfLeashResistance-1.55.0.0.msix
   ```

   Do not sign it. The Store re-signs every package and replaces any existing
   signature. An unsigned `.msix` is a valid upload, and `.msixupload` is not
   needed.

## 4. Test the package locally

1. Install for testing. A local install does need a signature, so either
   sign a throwaway copy with a self-signed certificate whose subject equals
   the manifest `Publisher`, or register the unpacked folder with
   `Add-AppxPackage -Register msix\AppxManifest.xml` (needs Developer Mode).
   Upload the **unsigned** file, not the test-signed one.
2. Play one walk start to finish. Check that settings and records survive a
   restart.
   - Godot writes to `%APPDATA%\Godot\app_userdata\Path of Leash Resistance`.
     Under MSIX, new files in AppData are redirected to a private per-package
     folder and deleted on uninstall. The game sees the normal path.
   - Caveat on a dev machine: if that folder already exists from normal
     runs, the packaged build uses the real one, so a save that "works" may
     not be testing virtualization. Rename the folder while testing.
   - The install folder is read-only. Nothing may write next to the exe.
3. Run the Windows App Certification Kit (admin, interactive session):

   ```
   appcert.exe reset
   appcert.exe test -appxpackagepath PathOfLeashResistance-1.55.0.0.msix -reportoutputpath wack.xml
   ```

   Required passes for a desktop package: manifest resources (image sizes,
   no template images), package compliance (last version part 0), x64
   binaries in an x64 package, no elevation or UAC prompts, no `.pfx` or `.snk`
   files. "Unsigned PE files" is a warning only.

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

Per version tag that should reach the Store:

1. Download the tag's Windows zip, bump `Version` in the manifest to
   `X.Y.0.0`, pack, and run WACK (steps 3-4).
2. Create a new submission (Partner Center clones the previous one), replace
   the package, update "What's new", and submit.

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

That is a separate pipeline and would replace most of `ms-store-msix`, so do
not start it until the MSIX route has actually been refused.

## Still unconfirmed (as of 2026-09-23)

1. Whether "MSIX or PWA game" accepts a full-trust Win32 MSIX. The docs only
   route UWP and PWA games there. The first package upload answers this.
2. Whether the GDK route truly needs no ID@Xbox enrolment. One GDK packaging
   page still says it does; the June 2026 self-service page says it does not.
3. Whether `makemsix` on Linux produces packages Partner Center accepts.
4. Whether WACK runs on a GitHub-hosted Windows runner (it needs an
   interactive session).

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
