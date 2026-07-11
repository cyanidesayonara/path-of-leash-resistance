# AGENTS.md -- touch-grass

This file provides context and instructions for AI coding agents working on
this project. It follows the AGENTS.md open standard (https://agents.md).

## Project Overview

**Touch Grass** (tagline: "Take the Path of Leash Resistance") is a top-down
physics comedy game. You are a dog leashed to a phone-distracted human who
walks on autopilot. Get them to the park with their phone intact while
sneaking in as much dog business as possible.

Core design pillars, roadmap, and open questions live in `PROJECT.md`. Read it
before proposing features.

## Tech Stack

- Godot 4.7 (GDScript only, no C#)
- Renderer: GL Compatibility (required for the web export)
- No external assets yet: all art is placeholder vectors drawn in `_draw()`
- Web export ships to itch.io (draft page, secret URL for playtesters —
  never commit the secret URL to this repo)

## Project Structure

```
touch-grass/
  project.godot        # Godot project config
  main.tscn            # Single scene: a root Node2D running main.gd
  main.gd              # Level construction, game state, leash constraint, HUD
  dog.gd               # Player: move, plant (anchor), bark
  human.gd             # The payload: autopilot walking + telegraphed events
  leash.gd             # The verlet rope: visual AND gameplay constraint
  bike.gd              # Crossing hazard, self-managing
  PROJECT.md              # Design pillars, phased roadmap (reference doc)
  AGENTS.md            # This file (AI context, living document)
  CHANGELOG.md         # Append-only session history
  export_presets.cfg   # Web export preset (threads OFF: no SharedArrayBuffer)
  godot/               # Local portable Godot editor + console exe (gitignored)
  build/               # Export output (gitignored)
```

## How things work (non-obvious bits)

- **The rope IS the constraint** (`leash.gd`): the visible verlet rope is
  also the gameplay physics. It wraps poles via segment-vs-circle
  collision (point-only checks tunnel when stretched), winds up, cinches
  when taut, and slips off under hard tension via stick-slip friction
  (grip at low stretch, free slide when overstretched). There is NO
  separate wrap bookkeeping - three generations of pivot/angle tracking
  systems all desynced from the visual; do not reintroduce one.
  used_length() is the polyline length; dog_pull_dir()/human_pull_dir()
  are the rope's end tangents, which is why a wound human is flung in an
  arc. Regression test: tests/test_wrap.gd (runs in CI) - any change to
  rope physics must keep it green and should extend it.
- **Tug of war** (`main.gd/_apply_leash`): tension = LEASH_K * stretch
  excess, applied to both ends inversely to effective mass along the rope
  tangents. HUMAN_MASS is 4x DOG_MASS, so the human wins raw tugs; the
  dog wins via planting (x14), moving (x2), and winding poles (pole
  contacts shield both ends from raw tension while the geometry cap -
  15% stretch, corrections along tangents - still constrains: that cap
  is what whips a wound human along the arc). A taut leash saps the DOG's
  control authority (`dragged` flag in dog.gd; an idle dragged dog barely
  brakes) - never the human's motor. Leash length is dynamic: the HUMAN
  owns the retractable reel and fiddles with it on a timer ("click!").
- **Pole wraps** (`leash.gd`): a pivot chain, ordered dog side to human
  side. Only the two end segments can gain or lose pivots (interior pivots
  are static). The same pole can be wound repeatedly once the rope swings
  ~100 degrees past the previous contact point. The verlet rope is visual
  only; gameplay uses the pivot chain length.
- **Human events** are telegraphed with a speech bubble 0.8s before firing.
  Never add an untelegraphed hazard to the human - predictable-but-dumb is
  the design contract (see PROJECT.md pillars).
- **Frame order matters**: main.gd calls dog.tick, human.tick,
  _apply_leash, leash.tick explicitly. Do not move entity logic into
  _physics_process on the entities themselves (except bikes, which are
  self-managing and order-independent).
- Input actions are registered in code (`main.gd/_setup_input`), not in
  project.godot. Guarded against re-registration on scene reload.

## Commands

Run the game (local portable editor, gitignored):
```
godot\Godot_v4.7-stable_win64.exe --path .
```

Headless smoke test (what CI runs; catches parse and runtime script errors):
```
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 1800
```

Export the web build and zip it for itch.io:
```
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --export-release "Web" build/web/index.html
Compress-Archive -Path build\web\* -DestinationPath touch-grass-web.zip -Force
```
Requires export templates in `%APPDATA%\Godot\export_templates\4.7.stable\`
(web_*.zip + version.txt from the official tpz).

## Conventions

- No emoji anywhere (code, UI, docs, commits)
- Plain comments that state constraints, not narration
- Honest, incremental git history; imperative commit subjects
- Feel/tuning decisions are made by playtesting, not by argument. Tuning
  knobs live in named constants at the top of each script.
- Update CHANGELOG.md at the end of every working session
