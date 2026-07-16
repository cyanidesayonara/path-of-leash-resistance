# Parallel Task: Free-Dog Visual Variety Foundation

## Purpose

Implement a reusable, deterministic vector-art appearance foundation for the
off-leash dogs in `freedog.gd`. The result should make the park population read
as several different generic dog types while preserving all existing movement,
greeting, group, and cleanup behavior.

This task is intentionally isolated from the concurrent NPC pair park-lifecycle
work. Follow the file ownership rules below even if a broader refactor looks
convenient.

## File ownership and conflict boundary

The implementation worker may change only these files:

- Modify `freedog.gd`.
- Create `dog_appearance.gd`.
- Create `tests/test_free_dog_variety.gd`.

Do not edit any other file. In particular, do not edit:

- `main.gd` or `otherpair.gd`; they are reserved for the concurrent
  park-lifecycle work.
- `bypasser_route.gd` or `bike.gd`.
- Any existing test, including lifecycle, traffic, route, and avoidance tests.
- `.github/workflows/ci.yml`.
- `CHANGELOG.md`, `HANDOVER.md`, this handoff, or any existing plan/spec file.

Before editing, inspect the working tree. Preserve unrelated changes. Do not
stage, revert, overwrite, or format files outside the three-file whitelist. If
`freedog.gd` has changed since this handoff was read, stop and coordinate rather
than resolving the overlap silently. Do not commit or push unless the parent
agent explicitly changes that instruction.

## Current contracts to preserve

`main.gd` currently creates a plain `Node2D`, attaches `freedog.gd`, assigns its
position, adds it to the tree, and calls:

```gdscript
setup(main, player_dog, freedom_y_lo, freedom_y_hi)
```

Keep that four-argument call compatible. No caller change is allowed.

`freedog.gd` currently:

- joins the `freedogs` group during `setup`;
- stores the main node, player dog, and vertical bounds;
- does no work while the game is frozen or the phase is not `freedom`;
- wanders, occasionally approaches the player dog, decelerates, and clamps
  itself to the existing x and y bounds while freedom is active;
- exposes its node position and `freedogs` membership to the existing greeting
  and cleanup code;
- draws only placeholder vector art in `_draw()`.

Do not move its logic to another process callback. Do not change movement
speeds, probabilities, timers, bounds, group names, greeting semantics, spawn
count, z-order, or cleanup ownership. Existing global random calls used when a
wander decision is due must retain their current order and cadence. This task
changes appearance only.

## Required design

### Reusable appearance boundary

Create `dog_appearance.gd` as a focused, stateless profile/data and vector
renderer module. It must not know about `main.gd`, freedom phases, greetings,
movement, leashes, or NPC ownership. It must use no external assets and no
global or local random-number generator. This separate module is justified
because it keeps profile definitions and their rendering independent of
free-dog lifecycle, allowing future playable-dog code to reuse them directly.

Use this public boundary so a future playable-dog selector can reuse the same
profiles without depending on `freedog.gd`:

```gdscript
class_name DogAppearance
extends RefCounted

const MAX_LOCAL_RADIUS := 40.0

static func profile_ids() -> PackedStringArray
static func get_profile(profile_id: String) -> Dictionary
static func profile_id_for_key(key: int) -> String
static func profile_for_key(key: int) -> Dictionary
static func validation_errors(profile: Dictionary) -> PackedStringArray
static func draw_dog(
	canvas: CanvasItem,
	profile: Dictionary,
	origin: Vector2,
	forward: Vector2,
	bob: float,
	wag_phase: float
) -> void
```

Requirements for this boundary:

- `profile_ids()` returns this exact stable order:
  `compact_point_ear`, `long_low_drop_ear`, `tall_narrow_rose_ear`,
  `stocky_fold_ear`, `fluffy_curl_tail`, `shaggy_drop_ear`.
- `get_profile()` returns profile data without exposing mutable shared state;
  use a deep duplicate so callers cannot mutate the canonical profile table.
- An unknown ID is handled deterministically by returning the first profile.
- `profile_id_for_key()` uses integer arithmetic and positive modulo only. The
  same key always selects the same profile, including negative keys.
- Selection, lookup, validation, and drawing must not call `seed`, `randf`,
  `randf_range`, `randi`, `randi_range`, `randomize`, or
  `RandomNumberGenerator`.
- `draw_dog()` is the only appearance module function that issues CanvasItem
  draw calls. Profile lookup and validation remain headless-testable pure data
  operations.
- A zero-length `forward` vector must use a stable fallback direction and must
  not produce invalid geometry.

`freedog.gd` should preload this module, retain its current gameplay state, and
store the selected profile in `var appearance_profile: Dictionary = {}` so the
focused real-script test can exercise every renderer profile. During `setup`,
derive a stable integer appearance key from the already assigned spawn position
and the supplied y bounds. Use rounded integer coordinates and fixed integer
arithmetic; do not consume randomness for profile choice, color choice, or
animation phase. The same position and bounds must produce the same profile and
animation phase across fresh instances and runs. Different representative
spawn inputs must cover more than one profile.

The existing random color assignment becomes profile-driven. The existing
`seed_o` animation offset becomes deterministic from the same appearance key.
Do not add an appearance argument to `setup`; future explicit profile selection
can call `DogAppearance.get_profile()` directly and is outside this task.

### Profile vocabulary

Profiles are generic visual archetypes, not claims that the placeholder circles
and lines accurately depict real breeds. The six canonical types are:

- compact point-ear (`compact_point_ear`);
- long low drop-ear (`long_low_drop_ear`);
- tall narrow rose-ear (`tall_narrow_rose_ear`);
- stocky fold-ear (`stocky_fold_ear`);
- fluffy curl-tail (`fluffy_curl_tail`);
- shaggy drop-ear (`shaggy_drop_ear`).

Do not label a profile as a specific real breed in code, comments, tests, or UI.

Every profile must use this exact schema:

- `id: String` and neutral `name: String`;
- `size_scale: float`;
- `body_size: Vector2`, interpreted as local half-extents before scale;
- `head_radius: float`;
- `muzzle_size: Vector2`, carrying length and half-width;
- `ear_style: String`, `ear_size: Vector2`, and `ear_offset: Vector2`;
- `tail_style: String`, `tail_length: float`, `tail_thickness: float`, and
  `tail_carriage: float`;
- `base_color: Color`, `secondary_color: Color`, and `marking_color: Color`;
- `marking_style: String`, `marking_offset: Vector2`, and
  `marking_scale: Vector2`.

Supported style values are exact: ears use `point`, `drop`, `rose`, or `fold`;
tails use `straight`, `whip`, `curl`, or `plume`; markings use `solid`, `patch`,
`blaze_points`, or `brindle`. Renderer branches and validation must use these
same strings.

The profile set must visibly exercise at least:

- three ear styles;
- three tail styles;
- four marking styles;
- four distinct base-coat colors;
- three meaningfully different body aspect/size combinations.

Include solid, patched, blazed/pointed, and striped or brindled treatment across
the set. Keep every shape legible at the current small top-down scale. The
renderer must actually use size, body aspect, ear, muzzle, tail, color, and
marking fields; data that does not affect drawing does not satisfy the task.
Preserve the current happy bob and wag animation intent.

### Data validity

`validation_errors()` must reject malformed profile data without mutating it.
The complete built-in set must meet all of these rules:

- IDs and names are non-empty and IDs are unique.
- Numeric dimensions and scales are finite and greater than zero.
- Placement vectors are finite.
- Ear, tail, and marking styles belong to documented supported sets.
- Colors are valid `Color` values with finite channels in the inclusive
  `[0.0, 1.0]` range.
- Any renderer-specific point list has enough finite points to draw safely.
- The dimensions, offsets, and scales guarantee all generated draw geometry
  remains within `DogAppearance.MAX_LOCAL_RADIUS` of `origin`.

Do not add resource files, scenes, textures, SVGs, plugins, or dependencies.
Keep all art procedural through `_draw()` and CanvasItem drawing primitives.

## Required focused test

Create `tests/test_free_dog_variety.gd` as a `SceneTree` test that loads and
executes the real `dog_appearance.gd` and `freedog.gd` scripts. Do not copy
production formulas into a fake implementation and do not inspect source text
as the primary assertion.

The test must fail with exit code `1` and `FAIL:` messages on assertion failure,
and print `test_free_dog_variety: OK` before exiting `0` on success. It must
cover all of the following:

1. The profile ID list has at least six unique, stable IDs.
2. Repeated positive and negative keys select the same expected IDs, and the
   selection cycles predictably by profile-count modulo.
3. Repeated lookup returns equal values but independent mutable dictionaries.
4. Every built-in profile has zero validation errors and all required fields.
5. The full set meets the minimum variety counts for ear, tail, marking, coat,
   and silhouette categories.
6. Invalid synthetic profiles produce validation errors rather than a crash.
7. Appearance selection has no global RNG side effect:
   seed the global RNG, record the next value, reseed identically, call profile
   selection/lookup/validation, and confirm the next global value is unchanged.
8. `freedog.gd` setup has no global RNG side effect using the same
   seed/expected/reseed/setup/actual pattern.
9. Two real free-dog instances with identical position and setup bounds receive
   equal profiles and deterministic animation offsets; representative different
   positions select more than one profile.
10. Real `freedog.gd` instances still join `freedogs`, retain setup references
    and bounds, remain stationary while frozen, remain stationary outside
    `freedom`, move while active when given a non-expired wander timer and fixed
    velocity, and clamp to the existing x and y bounds.
11. A headless draw smoke assigns each profile in turn to a real free-dog node,
    requests a redraw, and advances one frame. It includes a coincident
    player-dog position to exercise the zero-forward fallback and completes
    without draw errors. Profile validation separately guarantees finite
    geometry inputs and the maximum-radius bound.

Use a minimal fake main with only `phase` and `frozen`, plus a real `Node2D` as
the player-dog reference. Set `wander_t` above zero before lifecycle movement
assertions so the test does not trigger the intentionally preserved random
wander decision.

## Out of scope

- Playable breed/profile selection, menus, saves, progression, stats, or
  difficulty differences.
- Changes to Millie in `dog.gd`.
- New behaviors, interactions, sounds, names, collars, harnesses, or bandanas.
- NPC owner-dog pair visuals or lifecycle.
- Spawn orchestration, population balancing, greeting scoring, and cleanup.
- Replacing placeholder vector art with production art.
- CI workflow, changelog, handover, or roadmap edits.

## Implementation sequence

1. Write `tests/test_free_dog_variety.gd` against the public boundary and
   confirm it fails because `dog_appearance.gd` does not exist.
2. Add profile data, deterministic lookup, defensive copies, and validation in
   `dog_appearance.gd`; run the focused test.
3. Add vector rendering for every supported feature and profile; run the
   focused test.
4. Integrate deterministic profile selection and rendering into `freedog.gd`
   without changing its gameplay branch; run the focused test.
5. Run the existing regression and smoke commands below.
6. Inspect `git diff -- freedog.gd dog_appearance.gd
   tests/test_free_dog_variety.gd` and `git status --short`. Confirm no file
   outside the whitelist was changed.

## Commands

Run from the repository root in PowerShell.

Focused test:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_free_dog_variety.gd
```

Existing freedom traffic regression:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_freedom_traffic.gd
```

Rope regression, to catch unrelated parse/runtime fallout:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_wrap.gd
```

Park headless smoke:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 1800 -- --level=park
```

Full freedom lifecycle traversal:

```powershell
godot\Godot_v4.7-stable_win64_console.exe --headless --fixed-fps 60 --path . --quit-after 12000 -- --level=park --autowalk
```

Expected results: each focused/regression command exits `0` with its `OK`
marker, the smoke command has no parse or runtime errors, and the traversal log
contains `AUTOWALK FINISHED`.

## Acceptance criteria

The task is complete only when:

- The git diff contains changes only to the three whitelisted files.
- `freedog.gd` keeps its existing setup signature and all gameplay constants,
  branches, group membership, movement, greeting integration, and cleanup
  contract.
- At least six neutral generic profiles produce recognizably different
  procedural silhouettes and coats using every required appearance dimension.
- Profile choice and setup are deterministic and consume no global RNG state;
  random wander behavior retains its existing cadence.
- The appearance module is independent of free-dog lifecycle and exposes the
  exact reusable public boundary above.
- No real-breed claim, external asset, dependency, player selector, or gameplay
  stat is added.
- The new test uses the real scripts and covers deterministic selection, RNG
  isolation, profile/geometry validity, rendering smoke, and the preserved
  free-dog lifecycle.
- Every required command passes with the expected result.
- No commit or push has been made.
