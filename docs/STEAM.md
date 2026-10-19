# Publishing to Steam

How a version tag gets the Windows build onto Steam, once the app exists.
The itch channels stay the release. This upload runs after them and cannot
hold them back. Written 2026-10-19. Nothing here is a credential, an app id,
or a depot id: those live in GitHub and in Steamworks, not in the repo.

What already exists:

- `release.yml` builds `build/win/PathOfLeashResistance.exe` on every version
  tag. The pck is embedded (`binary_format/embed_pck` in `export_presets.cfg`),
  so that one file is the whole Windows game. Itch gets it on the `windows`
  channel, and the GitHub release gets `leash-resistance-windows.zip`.
- The `steam` job in `release.yml` downloads that same exe and runs
  `tools/steam_upload.sh`. It runs only on a tag, and only after itch has
  already been pushed.
- With none of the four settings below, the script logs that Steam is not
  configured and exits 0. A tag still publishes itch.
- With some of them set and others missing, the script exits 1. A half-set
  login must not look like a successful upload.
- `STEAM_REQUIRED=1 tools/steam_upload.sh` fails when nothing is configured.
  CI runs that, and the unconfigured success, on every pull request.

## 1. Create the app

Santtu does this once, in a browser, on the Steamworks account.

1. Pay the Steam Direct fee and create the app for Path of Leash Resistance.
2. Add a Windows depot. Note the app id and the depot id. Both are numbers.
3. Set the depot's launch option to `PathOfLeashResistance.exe`. There is no
   installer and no separate pck.

Linux and Steam Deck are a later depot. This path is Windows only.

## 2. Tell the repository

Repository variables (Settings > Secrets and variables > Actions >
Variables), not secrets. They are ids, not a login:

| Variable | Value |
|---|---|
| `STEAM_APP_ID` | the app id from Steamworks |
| `STEAM_DEPOT_ID` | the Windows depot id |

Repository secrets:

| Secret | Value |
|---|---|
| `STEAM_USERNAME` | the Steamworks account name that may upload builds |
| `STEAM_CONFIG_VDF` | base64 of that account's steamcmd `config.vdf` |

The config file is the saved login, including Steam Guard. Make it once, on
a machine you control:

```
steamcmd +login YOURNAME
```

Finish the guard prompt. Then base64 the `config.vdf` steamcmd wrote (on
Linux, `~/.steam/steam/config/config.vdf` or `~/Steam/config/config.vdf`) and
paste that into the secret. Delete your shell history if it kept the
password. Do not commit the file, do not put it in a pull request, and do
not paste it into chat.

## 3. What a tag does

`git tag v1.61 && git push --tags` is still the release. CI must be green
for that commit. Then `release.yml`:

1. Exports web and Windows and pushes both itch channels. Missing
   `BUTLER_API_KEY` fails the release.
2. Attaches the zips to the GitHub release.
3. The `steam` job, in parallel with the Microsoft Store package, downloads
   the exe and runs the upload script.

The script writes a temporary app build that maps every file in the export
directory onto the depot, logs in with the saved config, and runs
`run_app_build`. It looks for steamcmd's line `Successfully finished AppID`.
Anything else fails the job. The itch push has already happened by then.

The upload creates a build in Steamworks. It does not set that build live.
In Steamworks, set it on a beta branch first. Launch it through the Steam
client, and only then move it to the default branch.

To try the script on a machine that already has the four settings and an
exported exe:

```
bash tools/steam_upload.sh build/win
```

## 4. The store page

Steamworks does not read `store/listing.md`. Copy the current listing's
description into About this game, and the short description into Steam's
short description. The short description in that file is under Steam's 300
character limit. The product features are the capsule bullet list.

Capsules and screenshots are the existing Store art and the shot sweep.
There is no Steam submit workflow in this repo: the page is filled in by
hand, the same way the first Partner Center page was, until an upload of
the page itself is worth automating.

The page stays hidden until Santtu has launched one build through Steam.
