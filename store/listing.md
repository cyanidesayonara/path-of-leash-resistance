# Microsoft Store listing

What was entered in Partner Center. First submission 1.54.0.0, live
2026-09-23 at https://apps.microsoft.com/detail/9p5d14v8rbqx; 1.55.0.0
submitted 2026-09-24; 1.56.0.0 prepared 2026-09-27; 1.57.0.0 prepared
2026-10-02 with the listing below (fourteen walks, every one rebuilt as its
own place, the new icon and Store art).
Copy from here for the next submission, and update this file whenever the
live listing changes, so it stays the record of what the Store says.

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
  park, street in snow, spook, old town, trail. 1.55 added El Mosaic
  (`--level=guell --shot-at=3100`, with `tools/stamp_version.sh` run first so
  the corner says the version, not "dev"), captioned "El Mosaic: the winding
  terrace and its broken-tile mosaic". 1.57 replaces the set with the
  rebuilt walks (see "Screenshots for 1.57" below). Never the sweeper chase
  until #20 is fixed, and pick frames where no two feed lines overlap (#59).
- Logos: `tools/make_store_art.gd` writes the 9:16 poster (1440x2160), 1:1
  box art (2160) and the 300/150/71 tiles into `build/store-art/`. No hero
  art, trailers or Xbox images.

### Screenshots for 1.57

Shot at 1920x1080 from a checkout of the v1.57 tag (`tools/stamp_version.sh`
first, so the corner reads the version): La Rambla's crowd and the Fur-Goneta,
El Mercat's hall, La Castanyada's plaça at night, El Mosaic's salamander, the
square off the leash, El Bosc's boars, the seafront in the sun, a rainy walk
in raincoats, and the walk select with a name laid out on the ground.

### Description

```
You are the dog. Your human is glued to their phone and walking on autopilot. Get them home in one piece, with the phone intact, while sneaking in as much dog business as you can get away with.

The leash is real rope physics. Your human outweighs you four to one and wins every straight tug, so you win the way a dog does: dig in at the right moment, wrap the leash around a lamppost to hold them fast, and bark to stop them dead at the kerb. Get the timing right as a bike whizzes past and it counts as a save.

Fourteen walks through a sunny, slightly chaotic Barcelona, each its own place: the little park at the end of your street, La Rambla with its crowds, street sellers and pickpockets, the city park and its lake, the seafront, a rainy shopping street, a covered market hall, the old town's narrow alleys, a wood with wild boar in it, the station and its train, roadworks with wet cement, a chestnut festival at night, a scrapyard with a guard dog you really should not wake, a hilltop park of gingerbread gatehouses and a mosaic salamander, and a narrow back street at dawn, just as the street sweeper comes through. Every walk ends off the leash: a dog park, a dog beach, a clearing in the woods, or a town square with a fountain to jump in.

What happens on a walk changes how you feel, and how you feel changes how you move. A fright leaves you jumpy and half blind to smells, a good bark-off makes you barky, time off the leash brings on the zoomies, and running yourself empty leaves you flat. Moods fade on their own. The ground matters too: grass and mud slow you down but hold far more scent than pavement, sand drags at your paws, and wet ground and snow make you skid.

Other dogs have lives of their own. They sniff and mark the posts you pass, and you can read who was there; meet one nose to nose and it stops to sniff you back, unless it is the grumpy sort.

Every walk has its own list of goals: sniff the good spots, mark your territory, fetch, greet other dogs, herd a runaway friend home, and land combo tricks like vaulting around a pole or grinding along a kerb. Earn stars to unlock new walks and bones to spend on leashes and bandanas.

One walk is a chase: a street sweeper fills the lane behind you, and you have to drag your oblivious human home ahead of it. Weather and night change how every walk plays: rain, wind and snow, where the pavement turns to ice. There's a daily walk too, the same for everyone that day.

Single player. No ads, no purchases, no account, and it plays offline. Keyboard or controller.
```

### Short description

```
You are the dog. Your phone-distracted human walks on autopilot, and the leash is real rope physics. Dig in, wrap lampposts and bark your way through fourteen walks in Barcelona, and get them home with the phone intact.
```

### Product features

```
The leash is real rope physics: wrap it around poles, plant yourself, win the tug of war
Fourteen hand-built walks through Barcelona, plus a daily walk
Goal lists on every walk, with stars that unlock new walks
Combo tricks: leash-vaults, kerb grinds, near misses
A chase walk: stay ahead of the street sweeper with your oblivious human in tow
Dog moods: scared, barky, zoomies and flat, each changing how you move and what you notice
Ground you can feel: grass and mud hold scent, sand drags, wet ground skids
Other dogs and their people with lives of their own: they sniff, mark, greet and tangle
Rain, wind, snow and night change how each walk plays
Bones to spend on leashes and bandanas
A gentle first walk that teaches the basics
Full controller support
No ads, no purchases, no account, and it plays offline
```

### What's new in this version (1.57)

```
- Every walk rebuilt as its own place: La Rambla's crowds, sellers and pickpockets, the park's lake, a wood with wild boar, a rainy shopping street, the station and its train, roadworks, a scrapyard, a covered market hall, a chestnut festival at night, a hilltop park with a mosaic salamander, a back street at dawn, and El Barri, the everyday walk, first.
- Each walk's name is laid out on the ground in its own stuff (flowers, fruit, sand, cones, chestnuts, tiles) and you can kick it about.
- The town walks end off the leash in a square with a fountain to jump in.
- New menus: a clear screen for each step, and every message on the walk in its own place.
- Other dogs sniff and mark posts you can read, stop to say hello (some grumble), and their people look alive.
- The leash: the reel warns before it changes, plant and get hauled and you skid, and a dragged human leans back.
- A facelift for everyone, with outfits for the weather, and a brighter icon.
- A gentler first walk, and the Catalan names spelt properly.
```

### What's new in 1.56 (for the record)

```
- A thirteenth walk: La Neteja, a narrow back street at dawn. The street sweeper comes through every time, it fills the lane, and you have to drag your human home ahead of it. Keep more than a leash length clear the whole way for a new goal.
- The chase lives on its own walk now, so the other walks no longer end in one.
- On-screen prompts show the buttons of whatever you last used: keyboard, controller or touch.
- Touch controls on phones and tablets: RUN, MENU, SKIP and SHARE buttons, tap the goals card to open it, and the restart button only appears once the walk has stopped.
- Messages no longer write over each other, and labels at the dog keep clear of them.
- Snow now lies along the path on the walks that bend, and paint, oil, fish and confetti spills look like spills.
- Fixes: a walk with a chase no longer leaves you scared from the very first step, the sweeper no longer draws over your human, and the ground reaches the bottom of the screen at the finish.
```

### What's new in 1.55 (for the record)

```
- A twelfth walk: El Mosaic, a winding terrace path paved in broken glazed tile. The tile is the fastest footing in the game and the slipperiest, and it holds no scent at all.
- Dog moods. What happens on a walk can leave you scared, barky, full of zoomies or flat, and each one changes how you move and what you notice. Moods fade on their own, and the HUD shows how long is left.
- The ground matters: grass and mud slow you a little but hold far more scent than pavement.
- A rebuilt seafront, sand drifting across the promenade, and picnics, stumps and bushes along the verges.
- The street sweeper is a proper machine now.
- Much smoother, especially in the browser: far fewer draw calls per frame, and no more stutter when you step into the off-leash area.
- Fixes: the walk status (NEED A WEE, LOOSE LEASH, FETCH and more) shows again, the mood badge no longer covers the phone, the results card is easier to read, and a dog standing still no longer gets knocked over for no reason.
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
Update 1.55: a new level, new gameplay systems and performance work. No change to capabilities, network use, data handling or controls since 1.54.

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
