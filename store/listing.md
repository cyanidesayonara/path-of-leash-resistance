# Microsoft Store listing

What was entered in Partner Center for the first submission (1.54.0.0, live
2026-09-23 at https://apps.microsoft.com/detail/9p5d14v8rbqx). Copy from here
for the next submission, and update this file whenever the live listing
changes, so it stays the record of what the Store says.

Everything below describes v1.54. When moods, El Mosaic and the rest of
`main` ship, the description and features need updating, and "What's new"
gets filled in.

## Properties

- Category: Games. Genres: Action + adventure, Family + kids.
- Privacy: collects no personal information. Policy text: see "Privacy
  policy" below.
- Product declarations: alternate drives on, OneDrive backup on, Game Bar
  recording on; everything else off. Accessibility stays off until there has
  been a real accessibility pass (remappable controls, #9).
- System requirements: Keyboard minimum, Xbox controller recommended,
  DirectX 11 minimum. Touch screen off: touch controls are untested on
  Windows. Memory, video memory and processor left unspecified (unmeasured).

## Age ratings

IARC questionnaire answered for this game (not imported). Result: ESRB E
(Mild Violence, Crude Humor), PEGI 3, USK 6, ACB PG, IARC 3+, Microsoft 3+.

Lessons from the first attempt:

- Never import another product's IARC ID (stemma's was offered first). A
  certificate belongs to one product.
- "Can innocent or defenseless characters be seriously injured or killed?"
  is **No**. The sweeper game-over is a joke card, and nothing is shown or
  said to be injured. Answering yes produced PEGI 16 / Strong Violence.
- "Violence against real-world animals" is **Yes** (the dog is a real
  species that gets knocked over). It is what makes Russia 16+.

## Packages and device families

Windows 10/11 Desktop only. "Let Microsoft decide future device families"
off. Xbox off: a full-trust Win32 package cannot run there.

## Store listing (English, United States)

Screenshots and logos are regenerated, not stored here:

- Screenshots: 1920x1080 from the shipped build via
  `--shot --shot-at=N --autowalk --fixed-fps 60 --resolution 1920x1080`
  (see `docs/MICROSOFT_STORE.md` step 5). First set: station, beach, market,
  park, street in snow, spook, old town, trail. Never the sweeper chase until
  #20 is fixed.
- Logos: `tools/make_store_art.gd` writes the 9:16 poster (1440x2160), 1:1
  box art (2160) and the 300/150/71 tiles into `build/store-art/`. No hero
  art, trailers or Xbox images.

### Description

```
You are the dog. Your human is glued to their phone and walking on autopilot. Get them home in one piece, with the phone intact, while sneaking in as much dog business as you can get away with.

The leash is real rope physics. Your human outweighs you four to one and wins every straight tug, so you win the way a dog does: dig in at the right moment, wrap the leash around a lamppost to hold them fast, and bark to stop them dead at the kerb. Get the timing right as a bike whizzes past and it counts as a save.

Eleven walks through a sunny, slightly chaotic Barcelona: the boulevard and its bike lane, the park and its pond, the seafront, a rainy day, the market, the old town's narrow alleys, a forest trail, the station concourse, roadworks with wet cement, a festival night, and a scrapyard with a guard dog you really should not wake.

Every walk has its own list of goals: sniff the good spots, mark your territory, fetch, greet other dogs, herd a runaway friend home, and land combo tricks like vaulting around a pole or grinding along a kerb. Earn stars to unlock new walks and bones to spend on leashes and bandanas.

Some walks turn into a chase, like outrunning a street sweeper with your oblivious human in tow. Weather and night change how every walk plays: rain, wind and snow, where the pavement turns to ice. There's a daily walk too, the same for everyone that day.

Single player. No ads, no purchases, no account, and it plays offline. Keyboard or controller.
```

### Short description

```
You are the dog. Your phone-distracted human walks on autopilot, and the leash is real rope physics. Dig in, wrap lampposts and bark your way through eleven walks in Barcelona, and get them home with the phone intact.
```

### Product features

```
The leash is real rope physics: wrap it around poles, plant yourself, win the tug of war
Eleven hand-built walks through Barcelona, plus a daily walk
Goal lists on every walk, with stars that unlock new walks
Combo tricks: leash-vaults, kerb grinds, near misses
Chase walks where you drag your oblivious human to safety
Rain, wind, snow and night change how each walk plays
Bones to spend on leashes and bandanas
A gentle first walk that teaches the basics
Full controller support
No ads, no purchases, no account, and it plays offline
```

### Other fields

| Field | Value |
|---|---|
| Short title | Leash Resistance |
| Keywords | dog, leash, physics comedy, top-down, casual, Barcelona, walking |
| Copyright and trademark info | © 2026 Santtu Nykänen |
| Developed by | Santtu Nykänen |
| Voice title, additional license terms | blank |

## Submission options

Publishing hold: "Don't publish until I select Publish now". Notes for
certification (Additional Testing Information page):

```
Path of Leash Resistance is a single-player Win32 desktop game built with the Godot engine (4.7), packaged as MSIX.

runFullTrust: required to run the packaged Win32 game executable. The game uses no other restricted capabilities, no network access, no accounts and no in-app purchases.

How to test: launch the game, press Space (or A on a controller) on the title screen to start a walk. Move with WASD/arrows or the left stick; hold Space/A to dig in against the leash, E/B to bark, Q/X to mark a spot. A walk takes about two minutes. Esc/Back opens the pause and settings menus.

Graphics: the game renders with OpenGL 3.3, and falls back automatically to Direct3D 11 through ANGLE on machines without OpenGL 3.3 drivers.

Saves and settings are stored locally in the app's own data folder. No sign-in or test account is needed.
```

## Privacy policy

```
Path of Leash Resistance Privacy Policy
Last updated: 2026-09-23

Summary

Path of Leash Resistance is a single-player game that runs entirely on your device.
We do not require account creation.
We do not operate any online service or backend for the game.
The game makes no network connections.

Data We Process

The game processes only:
your game progress, records and unlocked items;
your settings (audio volumes, display and control preferences);
log files the game engine writes for troubleshooting.

All of this stays on your device.

Data Collection and Sharing

We do not collect personal data.
We do not use analytics, advertising or tracking of any kind.
We do not sell or share personal data, because we do not have any.
Nothing is uploaded to us or to any third party.

The "share" button after a daily walk copies a short text summary of your result to your clipboard. It is not sent anywhere; what you do with it is up to you.

Local Storage

The game stores its data locally in your Windows user profile. For the Microsoft Store version this is inside the app's private package folder (under %LOCALAPPDATA%\Packages), including:
your save file (progress, records, unlocks and settings);
engine log files.

Uninstalling the game removes this data.

Security

We take reasonable steps to keep the game and its engine up to date, but no software can guarantee absolute security.

Children

The game collects no personal information from anyone, including children.

Changes to This Policy

We may update this policy. The latest version will be published with an updated Last updated date.

Contact

For privacy questions, open an issue on the project repository:
https://github.com/cyanidesayonara/path-of-leash-resistance/issues
```

If the game ever makes a network connection or collects anything, this
policy and the Partner Center privacy answer must change before that build
ships.
