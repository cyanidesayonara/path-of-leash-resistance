# Microsoft Store listing

The record of what the Store says, and the source the Store submit workflow
copies from. Live at https://apps.microsoft.com/detail/9p5d14v8rbqx (first
submission 1.54.0.0, 2026-09-23). "Current listing" is the text for the next
submission; the rest records how the product is set up in Partner Center.
Each release, step by step: docs/MICROSOFT_STORE.md, step 7.

## Current listing

What the Store should say for the next submission. The Store submit workflow
(`.github/workflows/store-submit.yml`, mode `update_draft`) writes every field
below into the Partner Center draft, so Partner Center always matches this
section; never edit these fields in Partner Center by hand. CI checks them
against the Store's limits (`tools/store_listing.py --check`). Lists are one
item per line. After a submission goes live, copy its What's new into "Past
What's new" with the date.

### Description

```
Your human is glued to their phone and walking on autopilot. You are on the other end of the leash. Get them home in one piece, with the phone intact, while sneaking in as much dog business as you can get away with.

The leash is real rope physics. Your human outweighs you four to one and wins every straight tug, so you win the way a dog does: dig in at the right moment, wind the leash around a lamppost to hold them fast, and bark to stop them dead at the curb. Wind them around a pole and keep pulling, and they whirl off it like a tetherball. Get the timing right as a bike whizzes past and it counts as a save.

Your human answers the leash like a person. A steady pull leads them where you want to go. Haul on them constantly and their patience runs out: a glance up from the phone, a mutter, then "HEY!" and a shorter leash. Walk nicely and the reel lets you out. Everything they are about to do, they announce first: "ring ring", "selfie!", "ooh!". They are never smarter than that.

Twenty walks through a sunny, slightly chaotic Barcelona, each its own place: the neighborhood park, La Rambla with its crowds, the city park, the beachfront, a downpour, a covered market hall, old town alleys, a forest trail, the train station, a floodable river park, a work site, a chestnut festival, a junkyard, tiled terraces, the dawn cleanup sweeper, Montjuïc, match day in Les Corts, the fishing harbor at El Port, the arcaded Plaça Reial, and an indoor vet clinic escape in El Veterinari. Every walk ends off the leash, with an agility course, tug-of-war and a frisbee: a dog park, a dog beach, a clearing in the woods, a yard, or a plaça with a fountain to jump in.

What happens on a walk changes how you feel, and how you feel changes how you move. A fright leaves you jumpy and half blind to smells, a good bark-off makes you barky, time off the leash brings on the zoomies, and running yourself empty leaves you flat. The ground matters too: grass and mud slow you down but hold far more scent than sidewalk, sand drags at your paws, and wet ground and snow make you skid.

Other dogs have lives of their own. They sniff and mark the posts you pass, and you can read who was there; meet one nose to nose and it stops to sniff you back, unless it is the grumpy sort.

Every walk has its own list of goals: sniff the good spots, mark your territory, fetch, greet other dogs, herd a runaway friend home, and pull off tricks: swing around a pole on the leash, run a figure eight, thread the needle between two people, and ride ledges and handrails with the zoomies. Earn stars to unlock new walks and bones to spend on collars, bandanas and coats.

Three walks are chases: dragging your human home ahead of the street sweeper, racing the river surge on El Besòs, and escaping the vet clinic in El Veterinari with clinic assistants giving chase with giant cones of shame. Rain, wind, snow and night change how every walk plays, and everyone dresses for the weather. There is a two-part tutorial for anyone new.

Single player. No ads, no purchases, no account, and it plays offline. Keyboard or controller.
```

### Short description

```
A dog walk as a physics comedy. Your human walks on autopilot, glued to their phone, and the leash is real rope. Dig in, wrap lampposts and bark your way through twenty walks in Barcelona, and get them home with the phone intact.
```

### Product features

```
The leash is real rope physics: wrap it around poles, dig in, win the tug of war
A human who answers the leash: a steady pull leads them, constant hauling runs out their patience
Twenty hand-built walks through Barcelona, in any weather, by day or at night
Every walk ends off the leash, with agility, tug-of-war and a frisbee
Goal lists on every walk, with stars that unlock new walks
Leash tricks: pole swings, figure eights, threading the needle, ledge and handrail rides
Three chase walks: the street sweeper, the river flood, and the clinic escape
Dog moods: scared, barky, zoomies and flat, each changing how you move and what you notice
Ground you can feel: grass and mud hold scent, sand drags, wet ground and snow skid
Other dogs and their people with lives of their own: they sniff, mark, greet and tangle
Rain, wind, snow and night change how each walk plays
Bones to spend on collars, bandanas and coats
A two-part tutorial and first-time tips for new players
Full controller support
No ads, no purchases, no account, and it plays offline
```

### Keywords

```
dog
leash
physics comedy
top-down
rope physics
Barcelona
dog walking
```

### What's new in this version

```
- A new walk, El Veterinari: the 20th Barcelona campaign walk and 4th major chase sequence, open at 33 stars or in Free Play mode.
- The Clinic Escape: Millie reluctantly enters the vet clinic, but when she reaches the examination door and smells rubbing alcohol, she panics and bolts south!
- Veterinary assistants with giant cones of shame and butterfly nets give chase while your human dawdles on the leash; weave around support pillars and time your run through automatic sliding doors to get away.
- Step onto the digital pet scale to weigh in, bark at nervous cats in waiting room carriers, and snatch the liver treat jar prize from the reception desk.
- Quayside waste bins added along the boardwalk in El Port for the bag chore, and Three Graces fountain registered in Plaça Reial.
- High-tempo clinic chamber groove with staccato marimba and upright bass.
```

### Notes for certification

```
Update 1.64: a new walk (El Veterinari) with clinic escape chase mechanics, digital pet scale interaction, quayside bins on El Port, and level audit polish. No change to capabilities, network use, data handling or controls since 1.55.

Path of Leash Resistance is a single-player Win32 desktop game built with the Godot engine (4.7), packaged as MSIX.

runFullTrust: required to run the packaged Win32 game executable. The game uses no other restricted capabilities, no network access, no accounts and no in-app purchases.

How to test: launch the game; any key skips the short intro. On the main menu choose PLAY with Space (or A on a controller), then pick a walk and press Space again. Move with WASD/arrows or the left stick; hold Space/A to dig in against the leash, E/B to bark, Q/X to mark a spot, Shift for the zoomies. A walk takes about two minutes. Esc/Back opens the pause menu and goes back from any menu.

Graphics: the game renders with OpenGL 3.3, and falls back automatically to Direct3D 11 through ANGLE on machines without OpenGL 3.3 drivers.

Saves and settings are stored locally in the app's own data folder. No sign-in or test account is needed.
```

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
  rebuilt walks (see "Screenshots for 1.57" below). The chase can be shot
  since #20 (`--level=neteja --shot-y=-4300 --shot-home --shot-sweeper`),
  and pick frames where no two feed lines overlap.
- Logos: `tools/make_store_art.gd` writes the 9:16 poster (1440x2160), 1:1
  box art (2160) and the 300/150/71 tiles into `build/store-art/`. No hero
  art, trailers or Xbox images.

### Screenshots for 1.60

Ten 1920x1080 images from a checkout of the v1.60 tag
(`tools/stamp_version.sh` first, so the corner reads v1.60), uploaded in this
order with these captions:

1. La Rambla: crowds, cafe parasols and a kid with a dare
   (`--level=street --autowalk --fixed-fps 60 --shot-at=900`)
2. El Mercat: the market hall, its stalls and the fish counter
   (`--level=market --shot-y=-2000 --shot-at=60`)
3. Off the leash: an agility course, fetch and a frisbee
   (`--level=park --at-freedom --autowalk --fixed-fps 60 --shot-at=300`)
4. El Gòtic: washing lines over the old town's alleys
   (`--level=oldtown --shot-y=-3420 --shot-at=300`)
5. El Mosaic: the tiled terraces and the mosaic salamander
   (`--level=guell --shot-y=-760 --shot-at=300`)
6. Montjuïc: the climb up the hill, and a dare against the clock
   (`--level=montjuic --autowalk --fixed-fps 60 --shot-at=2600`)
7. El Parc: a slack leash and a tree to wind your human around
   (`--level=park --shot-y=-300 --shot-at=300`)
8. La Castanyada: the chestnut festival at night
   (`--level=spook --autowalk --fixed-fps 60 --shot-at=1200`)
9. Passeig Marítim: sand, sea and a dog beach at the end
   (`--level=beach --shot-y=-2850 --shot-at=300`)
10. L'Estació: the moving walkway and the station
    (`--level=station --autowalk --fixed-fps 60 --shot-at=1500`)

All with `--rendering-method gl_compatibility --resolution 1920x1080` and
`-- --shot --shot-quit --shot-out=FILE`. A `--shot-y` shot needs
`--shot-at=300` or so: sooner, the menu's prompt bar is still fading out. The
sweeper chase is left out: no frame had the chase on and the walk not lost.

The Store logos for 1.60 are the refreshed art from #230 (googly eyes),
written by `tools/make_store_art.gd`: the 9:16 poster, the 1:1 box art and the
300/150/71 tiles.

### Other fields

| Field | Value |
|---|---|
| Short title | Leash Resistance |
| Copyright and trademark info | © 2026 Santtu Nykänen |
| Developed by | Santtu Nykänen |
| Voice title, additional license terms | blank |

## Past What's new

As submitted, newest first. The current one is in "Current listing".

### What's new in 1.63 (live by 2026-10-24)

```
- Two new walks:
  - El Port: Barceloneta's working wharf along Moll dels Pescadors, with wooden boardwalk timber, quayside mooring bollards, fish market crate stacks, flapping seagulls, and Plaça del Far lighthouse.
  - Plaça Reial: Barcelona's grand neoclassical arcaded square in the Gothic Quarter, with Antoni Gaudí's six-armed dragon lampposts, the Three Graces central fountain, outdoor tapas terraces, and a Spanish guitar busker.
- Free Play (Demo) mode in Settings: choose any walk in the game freely without star gates. Career saves and stats are safely bypassed during practice.
- Artsy Detours: the first secret-in-plain-sight side gallery, «El Somni» (homage to Salvador Dalí) hidden along Carrer del Gòtic, featuring melting elastic lampposts and a floating golden dream bone.
- HUD vitals & iconography polish: redesigned smartphone HP pips with hairline cracked glass, liquid bladder and sprint energy tubes with vector droplet and lightning glyphs, arcade combo streak badge, and concentric territory mark target rings.
- Dynamic mood-driven tail wagging, crisp kerb skid juice, and smoother menu typography across all screen resolutions.
```

### What's new in 1.62 (tagged 2026-10-23)

```
- A new walk, El Besòs: a river park between L'Estació and Les Obres, open at 14 stars. The way out is dry. The way home is the flood.
- Shallow water pushes you south and wets your human. Plant to hold a spot. The deep channel, and the swell from the river, ends the walk. A raised apron stays dry until the water spills.
- The flood warns you, then gives a head start, the same as the sweeper. Your human hears the siren and decides it is not their problem.
- Every walk comes home to its own door. Your human looks up, pockets the phone, and follows you in.
- Rain, wind, snow, night and dawn each have their own light. Lamps stay warm after dark.
- Walk names sit in plain type, and a lost walk's title keeps its last letter.
- The Daily Walk is gone. A walk's own weather stays on that walk.
- Bring Tofu home works: she only hides where you can reach her.
- The leash runs round a stall, a van or a bench instead of through it.
- Caught by the sweeper, the two of you go up into the brooms. Fear waits until the threat is on screen.
- On a rainy El Bosc, one run in five raises the stream. Carry the branch or the ball to the bank.
- Visual polish across all seventeen walks: Doric columns and Jujol medallions in El Mosaic, travelator handrail grinds in L'Estació, Pont del Bisbe in El Gòtic, wave paving and Miró's mosaic on La Rambla, riprap banks and inflatable weir on El Besòs, and new landmarks across the city.
```

### What's new in 1.61 (tagged 2026-10-20)

```
- A new walk, Dia de Partit: match day in Les Corts, opening at 27 stars. The avenue fills with fans. Kick-off is on the clock, or when you reach the gate.
- Keep your human out of the away march. After the final whistle the crowd comes home the other way, fast after a win and slow after a loss. The score is on their phone.
- Off the avenue, a lost scarf and a kickabout. Off the leash is PLAÇA DEL GOL, goal square.
- The leash catches a car, a stall or a bench on the shape you see. She slides along a wall instead of sticking to it.
- El Diluvi's shoppers stroll the covered street. El Barri, El Bosc, L'Estació, Les Obres, La Ferralla, El Mosaic, La Castanyada and La Neteja are redrawn.
- La Neteja gives a warning and a head start, then the sweeper. Lost on the way home, continue from the destination or the halfway point.
- The dare kid sits clear of the trees, and the browser build has sound again.
- The opening film is finished, and the title theme has some get-up-and-go.
```

### What's new in 1.59 (live by 2026-10-09)

```
- A new walk, Montjuïc: the climb up the hill, with a hidden cable car, escalators, the Font Màgica and the castle at the top.
- A way in for new players: a two-part tutorial, gentler first walks and first-time tips.
- A lost walk says how to avoid it next time, and keeps the goals you ticked.
- Readable on small screens: the menus and HUD grow, the walk keeps its view.
- Tricks reworked: ride ledges and handrails with the zoomies, new leash tricks, and golden zoomies for stringing tricks together.
- Clearer words throughout, and many smaller fixes.
```

### What's new in 1.58 (submitted 2026-10-05, live 2026-10-05)

```
- A short animated intro, and a new soundtrack with its own arrangement for every walk.
- Games off the leash: an agility course against the clock, tug-of-war over a rope toy, and frisbee.
- Your human answers the leash: lead them nicely and they give you slack; haul and they lose patience.
- A smoother leash, footsteps that change with the ground, and every walk ending at its own gate.
- La Rambla and El Parc upgraded, the off-leash spaces fenced in properly, and many smaller fixes.
```

### What's new in 1.57 (submitted 2026-10-03)

```
- Two new walks. El Barri, the everyday walk, comes first. La Neteja is a narrow back street at dawn: a street sweeper careens after you, flinging junk, and you drag your human home ahead of it. It is the only walk with a chase now.
- Every walk rebuilt as its own place: La Rambla's crowds, sellers and pickpockets, the park's lake, a wood with wild boar, a rainy shopping street, the station and its train, roadworks, a scrapyard, a covered market hall, a chestnut festival at night, and a hilltop park with a mosaic salamander.
- Each walk's name is laid out on the ground in its own stuff (flowers, fruit, sand, cones, chestnuts, tiles) and you can kick it about.
- The town walks end off the leash in a square with a fountain to jump in.
- New menus: a clear screen for each step, and every message on the walk in its own place.
- Other dogs sniff and mark posts you can read, stop to say hello (some grumble), and their people look alive.
- The leash: the reel warns before it changes, plant and get hauled and you skid, and a dragged human leans back.
- A facelift for everyone, with outfits for the weather, and a brighter icon.
- A gentler first walk, and the Catalan names spelt properly.
- Button prompts show whatever you last used, keyboard or controller.
```

### What's new in 1.56 (prepared, never submitted)

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

## Submission options

Publishing hold: "Don't publish until I select Publish now". The notes for
certification are in "Current listing" above; the Store submit workflow sends
them.

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
