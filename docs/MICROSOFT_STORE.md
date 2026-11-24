# Publishing to the Microsoft Store

How to get the Windows build of Path of Leash Resistance into the Microsoft
Store through Partner Center. Written 2026-09-23 against Partner Center's
"Apps and games" page as it stood then. The game went live this way on
2026-09-23 (1.54.0.0, https://apps.microsoft.com/detail/9p5d14v8rbqx).
Everything entered in Partner Center for it is recorded in
`store/listing.md`; this doc is the procedure, that file is the content.

v1.67 is the last tag (2026-10-31), on itch and submitted to the Store. Its
What's new covers everything since 1.64 (1.65 and 1.66 went out with 1.64's
notes, because the notes were not updated before tagging). Once 1.67 is live
in the Store, move its What's new into the past list and start the next
version's. Before any tag: the What's new in `store/listing.md` describes
that version, the description's walk count and list match the game, and
`docs/itch-page.md` has the same notes. Do not move the notes into the past
list until the submission is live.

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
"GDK game", but "MSIX or PWA game" does accept a full-trust Win32 MSIX: this
game passed ingestion and certification that way. GDK game is only needed for
Xbox features or a console release (see the end of this doc).

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
3. **Age ratings:** complete the IARC questionnaire for this game. Only import
   an existing IARC ID if it was issued for this same game; never another
   product's. Answer from what the game shows, not its tone.
   `store/listing.md` has the answers that got an accurate all-ages result,
   and the two that went wrong on the first attempt.
4. **Packages:** upload the `.msix` from step 3; ingestion validates it here.
   "Invalid package identity name" means the manifest's `Identity Name` does
   not match Product identity exactly. Tick only **Windows 10/11 Desktop**.
5. **Store listings (English):**
   - Text: copy the description, short description, features, keywords and
     the other fields from `store/listing.md`, updated for what the build
     actually contains.
   - Screenshots: PNG, at least **1366x768** (up to 3840x2160), at least 1,
     4 or more recommended, 10 at most. They are the ordered list in
     `store/screenshots.txt`: a file name and the game's `--shot` flags per
     line. The Store submit workflow (step 7) renders each at 1920x1080
     from the tag being submitted and stages them; nobody uploads them by
     hand. To see them before a run, render them from a checkout of the tag
     (`git worktree add ../pol-vX.Y vX.Y`, then `--import` it once):

     ```
     python tools/store_images.py render --godot godot/Godot_v4.7-stable_win64_console.exe --project ../pol-vX.Y --out build/store-listing
     ```

     Each shot is `--fixed-fps 60 --rendering-method gl_compatibility
     --resolution 1920x1080 -- --shot --shot-quit --shot-out=... --seed=1`
     plus the line's flags (`--level=`, `--shot-y=`, `--shot-at=N`,
     `--at-freedom`, `--shot-home --shot-sweeper` for a chase; see
     AGENTS.md's shot flags).
   - Store logos: the same command renders them with
     `tools/make_store_art.gd`, which writes the 9:16 poster (1440x2160),
     1:1 box art (2160x2160) and the 300/150/71 tiles into
     `build/store-art/`, drawn from the same code as the app icon. The
     listing uses the poster (StoreLogo9x16), the box art (StoreLogoSquare)
     and the 300 tile (Icon).
   - A trailer is optional. If you add one, 16:9 hero art at 1920x1080 becomes
     required.
6. **Submission options:** choose the publishing hold ("Don't publish until I
   select Publish now" lets you pick the moment). The workflow reports it
   (TargetPublishMode) in its run summary and warns when it is Manual: a
   certified release then waits for that click. The `runFullTrust`
   justification and test instructions go on the **Additional Testing
   Information** page; the text is in `store/listing.md`. A Partner Center
   bug reported in April 2026 can leave a section showing "Incomplete" after
   it is filled. Re-save it, or ask support if it persists.
7. **Submit to the Store.** Certification takes up to three business days.
   Once it passes, the listing appears in about 15 minutes.

## 6. Each release after the first

Use the Store submit workflow (step 7). It sends the package, the text and
the images; Partner Center by hand is only for the fields it does not send
(pricing, properties, age ratings, the publishing hold).

## 7. The Store submit workflow

`.github/workflows/store-submit.yml` (Actions > Store submit (manual) > Run
workflow) puts a release's MSIX, the whole listing text, the screenshots and the
Store logos into a Partner Center **draft**, then commits it when asked. Ported from Stemma's workflow,
which works with the same seller account.

One-time setup: the `store` environment (Settings > Environments, deploying
from `main` only; docs/release-secrets.md), with these environment secrets,
the same values as Stemma's of the same names (GitHub never shows a saved
secret again, so copy them from wherever you keep them, or make a new client
secret for the Entra app in the Azure portal and update both repos). Run the
workflow from `main`; mode `configure` checks them and changes nothing:

- `PARTNER_CENTER_TENANT_ID`
- `PARTNER_CENTER_SELLER_ID`
- `PARTNER_CENTER_CLIENT_ID`
- `PARTNER_CENTER_CLIENT_SECRET`

The Store ID is public and set in the workflow (`9P5D14V8RBQX`).

What it sends: everything under "## Current listing" in `store/listing.md`
(description, short description, product features, keywords, What's new in
this version, notes for certification), read by `tools/store_listing.py`.
CI runs `tools/store_listing.py --check store/listing.md` on every PR, so the
text is always inside the Store's limits before a release. The workflow
checks out main, so it always sends main's `store/listing.md`.

The images: `update_draft` checks the tag out beside main (in `rel/`, as
`pages.yml` does), renders every shot in main's `store/screenshots.txt` and
the three Store logos from it with Godot under xvfb (`tools/store_images.py
render`), and keeps them as the run's `store-listing-images` artifact. A
render that fails stops the run before the draft is touched. Then
`tools/store_images.py stage` marks the draft's images of those four types
`PendingDelete` (other art added in Partner Center is left alone), adds the
rendered ones as `PendingUpload` (Screenshot, StoreLogo9x16,
StoreLogoSquare, Icon), and builds one zip: the release MSIX under the
draft's pending package name, plus the images. The workflow PUTs that zip
to the draft's FileUploadUrl, replacing the upload `msstore publish
--noCommit` made, and sends the JSON with `msstore submission
updateMetadata`. A rerun drops the entries an earlier run staged instead of
adding more. The run fails unless the read-back lists as many entries
pending upload as were staged (the package plus every image). msstore's
image model has no description field, so screenshot captions are not sent.
A shot's walk must exist at the tag: a list naming a newer walk fails the
render for an older tag.

`update_draft` refuses while a submission is in certification or
publishing (`check-draftable`): staging would touch the one in progress.
`submit` commits only when the status is PendingCommit, the draft's pending
package is this tag's (`PathOfLeashResistance-X.Y.0.0.msix`), and its
What's new is main's `store/listing.md` What's new in this version. Every
mode reports the draft's TargetPublishMode in the run summary; Manual means
a release that passes certification still waits for someone to select
Publish now.

**Keep the upload link private.** A draft's FileUploadUrl is a
write-capable Azure blob SAS link: anyone holding it can replace the
package and images the Store ingests when the draft is committed, and this
repository's Actions logs and artifacts are public. So the workflow never
runs `msstore publish`, `submission get` or `submission publish` with
`--verbose` (msstore then logs the link, wrapped across several lines,
where no mask or pattern catches all of it); every msstore output goes to a
file and reaches the log only through `tools/store_images.py redact`, which
drops FileUploadUrl and any blob link, and any line holding a piece of one;
and the link and its signature are masked with `::add-mask::` as soon as
they are known. Keep it that way in any change to the workflow, never paste
a draft's JSON anywhere public, and if a link does reach a log, delete that
run (`gh run delete <id>`) and start a fresh draft before committing.

Each release:

1. Before tagging, the release-notes PR updates "## Current listing": the
   What's new in this version block, the notes for certification's first
   line, and any other field the release makes untrue.
2. Tag it. `release.yml` attaches `PathOfLeashResistance-<version>.msix`.
3. Run the workflow with the tag and mode `update_draft` (run `configure`
   once first if the credentials are new). It stages the package, the text
   and the images; the run's log ends with the draft as staged, and its
   summary with the images per listing and the publish mode. Look at the
   `store-listing-images` artifact. Partner Center's own
   page keeps saying "Unchanged" until commit: the Store only ingests an
   API-uploaded package when the submission is committed.
4. Run it again with mode `submit`. That commits the draft: the package and
   images are ingested and certification starts. Do not click Partner Center's Submit
   button for an API-staged draft; it does not carry the staged package.
   If the package brought in a new listing language, run `update_listing`
   with the same tag once it is live, and `submit` again: a draft that
   replaces the package cannot add its languages.
5. When it is live, copy that What's new into "## Past What's new" in
   `store/listing.md` with the date.

New screenshots: every release's are rendered fresh from its tag, so they
always show the build players get. To change which moments are shown, edit
`store/screenshots.txt` (on main, before step 3) and render it locally as
step 5 describes to check the framing. Do not upload images in Partner
Center into an API-staged draft: its page shows the old listing until
commit, and saving it there can overwrite what was staged. `msstore
publish` is documented for free products only, which this game is.

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

Settled by the first submission: "MSIX or PWA game" accepts a full-trust
Win32 MSIX, and WACK runs on GitHub's hosted Windows runners.

1. Whether the GDK route truly needs no ID@Xbox enrolment. One GDK packaging
   page still says it does; the June 2026 self-service page says it does not.
2. Whether `makemsix` on Linux produces packages Partner Center accepts.

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
