# Touch Grass

*Take the Path of Leash Resistance.*

A top-down physics comedy game. You are the dog. Your human is glued to
their phone and walking on autopilot. Get them to the park with the phone
intact — dodge the bikes, mind the manholes, and sneak in as much sniffing
as you can get away with.

Built in Godot 4.7, GDScript, currently all placeholder vector art.
Playtest builds ship to a private itch.io page.

## Controls

- Move: WASD / arrows / left stick
- Dig in (anchor yourself; the leash stops the human): hold Space / A
- Bark (freezes the human for a beat): E / B
- Restart: R / Start

## What to feel for

- It is a tug of war you lose on raw muscle: the human is four times your
  mass and will yank you around. You win by bracing (plant), leverage
  (pole wraps multiply your holding power like a capstan), and timing.
- Plant yourself before bike lanes so the human strains against the leash
  and grinds to a stop. Release when clear.
- A hard yank while anchored makes the human stumble toward you; doing it
  as a bike whizzes past is a NICE SAVE and builds your streak.
- The leash is a real rope. Wind it around a pole as many turns as you
  like - the coil cinches when taut, the pull curves around the pole
  (tetherball!), and a hard enough wrench slips the whole coil off.
  Winding the human up or flinging them across danger in an arc is a
  core move.
- The human owns the retractable leash. "click!" means they just changed
  its length on a whim — sometimes reeling you in against your will.
- The human telegraphs every event with a speech bubble: "ring ring" stops,
  "typing..." drifts, "ooh!" dashes, "selfie!" backs up blindly,
  "filming..." walks backwards, "tired..." heads for a bench.
- Sniffing hydrants and eating dropped kebabs scores bones, but every
  second sniffing is a second the human spends unsupervised.

## Development

Requires Godot 4.7. A portable copy lives in `godot/` locally (gitignored);
grab it from https://godotengine.org/download or the GitHub releases.

Run:
```
godot\Godot_v4.7-stable_win64.exe --path .
```

Headless smoke test (same as CI):
```
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 1800
```

Web export (needs export templates installed, see AGENTS.md):
```
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --export-release "Web" build/web/index.html
```

## Documentation

- `PROJECT.md` — design pillars, phased roadmap, meta/retention direction
- `AGENTS.md` — technical map and conventions (for AI agents and humans alike)
- `CHANGELOG.md` — append-only session history

All rights reserved. Source is public for reading and learning; the game
itself is a commercial work in progress.
