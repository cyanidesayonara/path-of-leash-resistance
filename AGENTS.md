# AGENTS.md -- Path of Leash Resistance

This file provides context and instructions for AI coding agents working on
this project. It follows the AGENTS.md open standard (https://agents.md).

## Project Overview

**Path of Leash Resistance** (tagline: "You are the dog. Go touch grass.")
is a top-down physics comedy game. You are a dog leashed to a
phone-distracted human who walks on autopilot. Get them through the walk
with their phone intact while sneaking in as much dog business as
possible. (Retitled from Touch Grass in July 2026 after a trademark
collision; repo renamed to match.)

Core design pillars, roadmap, and open questions live in `PROJECT.md`. Read it
before proposing features.

## Tech Stack

- Godot 4.7 (GDScript only, no C#)
- Renderer: GL Compatibility (required for the web export)
- All art is vectors drawn in `_draw()`. The one file asset is `icon.png`,
  and even that is generated - see `tools/make_icon.gd`
- Two itch channels, both pushed by CI on a version tag: `html5` (played in
  the browser) and `windows` (the download the itch app installs)

## Project Structure

```
path-of-leash-resistance/
  project.godot, main.tscn   # config; the one scene, a Node2D running main.gd
  main.gd              # game state, frame order, leash/tug, pairs and traffic,
                       # world drawing, input; forwards to the modules below
  autoload/            # Game (records, settings, levels), Sfx (procedural audio)
  entities/            # dog, human, leash (the verlet rope), riders, NPC pairs,
                       # free dogs, critters, props, the sweeper, appearances
  systems/             # goals, home_chase, mood + mood_wiring, combo, challenge,
                       # teeter, grind, tutorial, swing/tangle geometry, routes
  hud/                 # hud_build (every HUD node, in draw order), menu_flow
                       # (title, wardrobe, settings), panels, cards, event feed,
                       # rotate prompt, touch controls, weather, grade shader
  world/               # level_build (corridor, level data, props, walls),
                       # edge/verge/freedom layers, surfaces, level_check
  tests/               # headless and render regression tests, all run by CI
  tools/               # shot sweep, idle soak, behaviour snapshot, perf, MSIX,
                       # icon and Store art generators
  store/               # Microsoft Store manifest, tile images, listing record
  docs/                # Store procedure, handover archive, plans
  PROJECT.md           # design pillars, roadmap
  CHANGELOG.md         # newest-first session history
  export_presets.cfg   # Web (threads off) and Windows presets
  godot/, build/       # local editor and export output (gitignored)
```

The split-out modules (`systems/goals.gd`, `hud/hud_build.gd`,
`world/level_build.gd`, ...) are static functions over main's state: the
state stays on main, and main.gd keeps a same-name forwarder for every
function another script or a test calls. A behaviour-preserving refactor of
main.gd must leave `tools/behaviour_snapshot.sh` output byte-identical. An
intentional behaviour change needs a fresh baseline comparison and must
explain every changed snapshot line; this does not relax the refactor rule.

## How things work (non-obvious bits)

- **The rope IS the constraint** (`entities/leash.gd`): the visible verlet rope is
  also the gameplay physics. It wraps poles via segment-vs-circle
  collision (point-only checks tunnel when stretched), winds up, cinches
  when taut, and slips off under hard tension via stick-slip friction
  (grip at low stretch, free slide when overstretched). There is NO
  separate wrap bookkeeping - three generations of pivot/angle tracking
  systems all desynced from the visual; do not reintroduce one.
  `setup()` always replaces the rope with exactly `N` current and previous
  points; repeated setup must never append another rope.
  `used_length()` is the solver polyline length. `visible_path()` is the
  public, fixed-size visual path: every solver point is pinned, spans beside
  contacts stay straight, and a curved midpoint is rejected if either new
  segment would enter an obstacle. Drawing must consume that path and reuse
  its fixed buffers. `dog_pull_dir()` / `human_pull_dir()` use a
  three-segment length-weighted chord on an open end; any contact in that run
  restores the first-segment tangent, preserving wound arcs. Regression tests:
  `test_wrap.gd`, `test_leash_setup.gd`, `test_leash_render_path.gd`,
  `test_leash_draw_buffers.gd`, `test_leash_weighted_tangent.gd`,
  `test_leash_taut_transition.gd`, `test_leash_taut_settling.gd` and
  `test_leash_tension_wiring.gd`. `test_wrap.gd` runs in CI; every rope
  physics change must keep it green and should extend it.
- **Tug of war** (`main.gd/_apply_leash`): `taut_amount()` eases continuously
  from zero to one over stretch ratio 1.00-1.05. `tension_force()` applies
  that amount to `LEASH_K * stretch excess`; separation damping and
  `dog.drag_amt` use the same amount, so force and loss of dog control begin
  together. The boolean `dragged` remains the state flag. HUMAN_MASS is 4x
  DOG_MASS, so the human wins raw tugs; the dog wins via planting (x14),
  moving (x2), and winding poles. Pole contacts shield both ends from raw
  tension while the 15% geometry cap still constrains along the tangents;
  that cap whips a wound human along the arc. The human's motor is never
  reduced. Leash length is dynamic: the HUMAN owns the retractable reel and
  fiddles with it on a timer ("click!").
- **Wraps and snags** (`entities/leash.gd`): still the same verlet rope - poles and
  authored furniture collide segment-vs-circle; stick-slip grips or frees
  by contact kind; static contacts own vault/shield metadata
  (`contact_pole`), while other-leash points are dynamic snags with their
  own slip. Do not reintroduce a separate pivot/angle bookkeeping layer.
- **The whirl** (entities/human.gd WHIRL state): when a wound human near a pole
  keeps getting pulled, main.gd starts a choreographed accelerating orbit
  instead of letting them jam against the pole. Arming averages one signed
  `leash.coil_winding()` measure over the 0.25-second window; `_commit_whirl`
  uses that same number for both the immutable direction and the local turn
  budget, clamped to the authored 0.6-4.0-turn range. `coil_reach_for()` is
  the pure hand-gap boundary helper (not
  the removed single-frame `unwind_bias()` wrapper); `unwind_bias_of()` and
  `human.orbit_sense()` settle the direction without mutating rope state.
  Only `human_contact_pole` with `human_contact_is_pole`, rechecked through
  `is_real_pole()`, may start and sustain an orbit: furniture and dynamic
  snags never whirl.
  `leash.free_slip_t` is refreshed throughout WHIRL so grip cannot arrest the
  unwind, and pull tension drives spin-up. Normal release is the pure tangent
  after it enters the dog-facing cone. A missed tangent gets one bounded extra
  arc and, only then, a capped dogward lean; `whirl_can_fling()` refuses a
  launch that would still point away. Timeout, lost-pole and refused-release
  paths call `bail_whirl()` for a controlled tangent stumble, not a fling.
  `whirl_bailed` keeps the entire bail frame shielded from raw tension,
  separation damping and the geometry cap even though `human.tick()` runs
  before `_apply_leash`; `_apply_leash` consumes both bail and fling one-shots
  after every `_leash_tug` path. Never call `_leash_tug` directly.
  Tests: `test_whirl.gd` and `test_whirl_guided.gd` cover the pole, starting
  continuity, signed measure and reach, one-way progress, local budget,
  pull-dependent speed, pure and forced releases, refusal, real-pole guard,
  bail shielding and one-shot consumption. The rope stays honest; the human's
  response is the cartoon. Whirl visuals use `AnimClock`, remain allocation-free
  inside the per-frame loops, and must not materially increase human draw time
  or draw calls. The 0.25-second arming telegraph adds two direct arcs;
  mid-tighten orbit adds five calls (one ghost batch, three speed arcs, one
  grit batch), and settled orbit adds four after the grit is gone. Keep
  focused sequence captures with performance evidence for any visual change.
- **The leash conversation** (`entities/human.gd`, `_converse`): your human
  answers the leash like a person. `_leash_tug` hands them the frame's pull
  (`feel_pull`: toward the dog along the rope, times tension); a steady,
  moderate pull LEADS them (their walk target moves across the path, their
  pace rises with a pull their way and drops with one back). Their motor is
  never weakened: the give changes where they mean to go, not how hard they
  walk. Hard hauling (over `PATIENCE_HARD`) drains `patience`; a slack leash
  refills it. Low patience shows (a glance at the dog, a temper cloud over
  their head, "oi..."); empty, it is a telegraphed "HEY!" (`CORRECT_WARN`,
  0.8 s like every owner event) and a correction: a step back and a shorter
  leash, then `CORRECT_GRACE` before patience drains again. A dog planted
  when it lands turns it into his stumble and a reward. They wait up to
  `WAIT_MAX` while she does her business, and the reel's random clicks are
  scaled by patience, so walking nicely earns slack. Test:
  `tests/test_leash_conversation.gd`.
- **Human events** are telegraphed with a speech bubble 0.8s before firing.
  Never add an untelegraphed hazard to the human - predictable-but-dumb is
  the design contract (see PROJECT.md pillars).
- **Frame order matters**: main.gd calls dog.tick, human.tick,
  _apply_leash, leash.tick explicitly. Do not move entity logic into
  _physics_process on the entities themselves (except bikes, which are
  self-managing and order-independent).
- Input actions are registered in code (`main.gd/_setup_input`), not in
  project.godot. Guarded against re-registration on scene reload.
- **Button prompts** (`hud/prompts.gd`) name ACTIONS for the device the
  player last used: `Prompts.key("plant")` is SPACE, A or DIG, and
  `Prompts.fill("{plant} dig in")` fills tokens. Never write a key name into
  UI text; one-shot labels go through `Prompts.set_text` so they re-fill when
  the device changes. `tests/test_prompts.gd` fails on a key name in a UI
  string. `--prompts=pad|touch` starts on that device, for screenshots.

## Commands

Run the game (local portable editor, gitignored):
```
godot\Godot_v4.7-stable_win64.exe --path .
```

Headless smoke test (what CI runs; catches parse and runtime script errors):
```
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 1800
```

Release (both platforms, both itch channels):
```
git tag v1.53 && git push --tags
```
That is the whole procedure. Tagging runs CI on the tagged SHA;
`.github/workflows/release.yml` waits for that CI to succeed, then exports
web and Windows, pushes each to its own itch channel with butler (which
uploads only changed blocks), and attaches zips to a GitHub release.
Missing `BUTLER_API_KEY` fails the release (it does not skip itch).

Export the web build locally:
```
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --export-release "Web" build/web/index.html
```
Requires export templates in `%APPDATA%\Godot\export_templates\4.7.stable\`
(web_*.zip + version.txt from the official tpz). The **Windows** preset needs
the full ~1GB template pack, which is why that export lives in CI only - a
local attempt fails with "No export template found" and nothing else.

Measure the web build (frame times and draw calls per level, in headless
Chrome on the real GPU; needs the web templates above):
```
GODOT=godot/Godot_v4.7-stable_win64_console.exe bash tools/web_perf.sh street park market
```

Regenerate the icon (after changing `tools/make_icon.gd`):
```
godot\Godot_v4.7-stable_win64_console.exe --rendering-method gl_compatibility --path . --script res://tools/make_icon.gd
python tools/make_ico.py
```

Photograph a screen without playing (writes `user://shot.png`):
```
godot\Godot_v4.7-stable_win64_console.exe --path . --quit-after 340 -- --shot --level=park
godot\Godot_v4.7-stable_win64_console.exe --path . --quit-after 340 -- --shot --shot-settings
```
`--shot-out=PATH` writes the PNG somewhere else and `--shot-quit` exits as
soon as it is written. Other shot flags: `--shot-title`, `--shot-results`,
`--shot-at=N`, `--shot-sweeper`, `--shot-home` (turns the pair for home at
`--shot-y`, so `--level=neteja --shot-y=-4300 --shot-home --shot-sweeper`
photographs the chase), and `--shot-y=N`, which starts the pair at that
point down the walk (`--shot-y=-2450 --shot-at=40` photographs El Bosc's stream;
give it 40 frames or so, a shot taken sooner can show the start line's ground).
`--shot-x=N` puts the pair at that x instead of mid-walk, `--shot-zoom=Z`
magnifies the shot, and `--shot-cam=X,Y` points the camera at a spot rather
than the pair, to judge how a prop or a person is drawn
(`--level=site --shot-y=-1200 --shot-zoom=2.5 --shot-cam=900,-1400` is the digger).
`--shot-menu=walk|details|shop|progress|pause|walkcard|confirm|notice` opens
that menu screen (`walkcard` is the pause menu's THIS WALK card, `confirm` its
EXIT GAME question). `--no-exit` shows the web menus on desktop: no EXIT GAME
on the title or in pause, and a five-cell pause grid.

EXIT GAME is desktop only (`MenuFlow.can_exit()`: never on web or under
`--no-exit`), always asks first, and leaves through `MenuFlow.quit_game`,
never a bare `get_tree().quit()`, so tests can swap in `quit_hook`.

Every menu screen is drawn by `hud/menu_screen.gd` from the model in
`hud/menu_flow.gd` (which screen is up, what it holds, what its prompt bar
offers), in the shared look of `hud/ui_kit.gd`: a card with the screen's own
accent, a heavy heading face, and the buttons as key caps in one bar along
the bottom of the screen. A new screen is a new case in all three.

Screenshot sweep (every walk, the title and each menu screen, settings,
results, street at 844x390 and 390x844) into `shots/`, plus labelled contact sheets `shots/sheet-*.png`.
Needs Pillow. `.github/workflows/shots.yml` runs the same thing on every PR and
push to main and uploads the sheets as an artifact; it does not gate CI:
```
GODOT=godot/Godot_v4.7-stable_win64_console.exe bash tools/shot_sweep.sh
```
Sweeps are deterministic on one machine (fixed frame rate and seed, and
cosmetic animation reads `AnimClock.msec()`, which shot mode pins to the frame
count), so a render refactor can prove it changed no pixel:
```
python tools/shot_diff.py shots-before shots-after diffs
```
Never read `Time.get_ticks_msec()` in a `_draw`; use `AnimClock.msec()`.

Draw calls are what the web build pays for, and every circle and polygon is
one in the Compatibility renderer. Draw runs of filled shapes through
`ShapeBatch` (`systems/shape_batch.gd`): the same pixels in one call.

Level inventory (what each walk contains: props by kind, patches, hazards,
goals) and the design brief every walk is being rebuilt to,
`docs/LEVEL_DESIGN.md`:
```
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tools/level_inventory.gd
```

Rope solver benchmark: time per `leash.tick()` in three fixed scenarios, plus
a hash of every solver output. A speed-up meant to change nothing must leave
all three hashes as they were (compare on one machine):
```
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tools/bench_leash.gd
```
Draw-path benchmark: time for `visible_path()` and `_draw_shapes()` in the
same fixtures, plus a geometry hash:
```
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tools/bench_leash_draw.gd
```
The leash stays at exactly four rope polylines plus the existing batched
circles. On the October 2026 Windows baseline, solver cost is about 58 / 129 /
254 microseconds and draw preparation 19 / 22 / 40 microseconds for free /
pole / tangle. Compare timings on one machine; investigate solver growth over
5% free or 15% contacted, any unexplained hash change, any added draw call, or
draw preparation materially above these figures.

The intro (`intro/`): a side-on film drawn in code like everything else,
played by `intro/intro_player.gd` on a plain launch only (no command-line
arguments, not headless), once a session. Render a scene to frames and a GIF:
```
godot\Godot_v4.7-stable_win64_console.exe --rendering-method gl_compatibility --path . --script res://tools/intro_render.gd -- walkies OUTDIR 24 640
python tools/frames_to_gif.py OUTDIR intro.gif 24
```

The title's version label is not in the source: `tools/stamp_version.sh`
writes the tag and short commit (`v1.55 (a1b2c3d)`) to the gitignored
`build_label.txt`, which each export preset packs. `release.yml` runs it
before exporting; a build without it says `dev`.

## Change control: the WIP limit

Changes reach `main` faster than they can be played by hand, so this limit
applies to every change, whoever makes it.

- **What counts:** a change is one merged PR, or one group of commits, that
  alters what the player sees, hears or feels (gameplay, levels, tuning,
  visuals, audio, UI text). Tests, tooling, CI and docs do not count.
- **Acceptance:** Santtu plays the change by hand and accepts it. Merging a
  PR is not acceptance. A merged player-facing PR stays in the "Awaiting
  acceptance" column of the project board
  (https://github.com/users/cyanidesayonara/projects/4) until Santtu accepts it,
  and only then moves to Done.
- **The limit:** at most **5** changes on `main` awaiting acceptance. At the
  limit, only hardening (bug fixes, tests, refactors with no player-facing
  effect) and tooling may land. No new player-facing change starts until the
  count drops below 5.
- **Check before starting:** count the player-facing items in "Awaiting
  acceptance" on the board. Changes older than the board are tracked in the
  acceptance backlog issue (#23); each unticked entry there counts as one.
- **Every change ships with a feel card:** a `## Feel card` section in the PR
  description, 3-5 numbered things to check by hand, each a concrete action
  and what should happen (for example "`--level=beach`: the sand drift reads
  as sand, not a puddle"). Include the command-line flags that get there
  fastest. Tooling and docs PRs get one too, even though they do not count
  against the limit.

## The game's voice (every player-facing string)

Dry, fond, from the dog's side of the leash; British spelling; short.
Each kind of text has one form, and its look comes from where it is drawn:
- **Goals**: sentence case, an instruction to the dog ("Mark 5 spots",
  "Get your human home less than half soaked"). `goals.quest_text`
  capitalises the first letter of every goal, wherever it was written.
- **Shouts** (`feed.say`): capitals, a few words, what she just did or what
  needs her now ("KERB RIDE!", "PICKPOCKET! WATCH HIS HANDS").
- **The banner** (`hud_status`): capitals, what is true right now, as an
  instruction ("FULL TANK! GO MARK A SPOT").
- **Speech** (`float_text(..., POP_SAY)`): lower case, as people talk.
- **Sounds**: whatever the noise is ("plop", "THUMP").
- **Scores**: a lower-case word and the amount last ("marked! +3"), which
  world/pops_layer.gd puts on a chip.
- **Menus**: headings in capitals; body text in plain sentences; button
  hints only through the prompt bar, never written into a sentence.
Say "leash" (never "lead"), "your human" for the owner, and name the place in Catalan, accents and all (PLAÇA, L'Estació; the
stroke letters in `world/sign_letters.gd` have them), with an English gloss
under it.

## Conventions

- No emoji anywhere (code, UI, docs, commits)
- Plain comments that state constraints, not narration
- Honest, incremental git history; imperative commit subjects
- Commits are authored only by Santtu Nykänen. Never add `Co-authored-by`
  trailers or AI/tool acknowledgements.
- Feel/tuning decisions are made by playtesting, not by argument. Tuning
  knobs live in named constants at the top of each script.
- Update CHANGELOG.md at the end of every working session
