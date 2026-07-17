# HANDOVER — Path of Leash Resistance

A complete brief for another AI agent (or human) picking up this project.
Read this first, then `AGENTS.md` (technical map), `PROJECT.md` (design +
release plan), and `CHANGELOG.md` (what changed when).

---

## 1. What this is

A top-down physics comedy game in **Godot 4.7 / GDScript**. You play a
dog. Your owner is glued to their phone and walks on autopilot. You are
joined by a **leash that is real verlet-rope physics** — the heart of
the game. A walk is a round trip: out to a destination, an off-leash
romp, then home.

- **Title:** Path of Leash Resistance. **Tagline:** "you are the dog. go
  touch grass." (Renamed from "Touch Grass" — that name is a trademarked
  Steam game. "touch grass" survives as flavor only.)
- **Repo:** github.com/cyanidesayonara/path-of-leash-resistance (public).
  Local: `c:\Users\Santtu\projects\path-of-leash-resistance`.
- **Ships to:** itch.io as a browser (HTML5) build for playtesting; the
  intended product is a premium Steam desktop release; mobile is a later
  port (touch controls already work).
- **Real pets are cameos:** the dog is **Millie** (scruffy black mutt,
  salt-and-pepper on head/muzzle, floppy ears, whippy tail, butt wiggle,
  red harness, white-tipped paws). The cat is **Tofu** (white with brown
  on top, pink harness, friendly but skittish, keeps a respectful
  distance — and in real life is an escape artist, which is why a
  "bring Tofu home" quest is planned).
- The owner (Santtu) is a Gofore full-stack dev in Barcelona; the
  passeig level is his actual daily walk (Passeig Marítim, Badalona).
  His girlfriend is a watercolor/oil artist who will do the real art.

## 2. Design pillars (do not violate)

1. The comedy is the mechanic — physics produces the jokes, not cutscenes.
2. Temptation vs duty — score/joy on one side, the owner's safety on the
   other; every level negotiates between them.
3. The human is a payload, not an AI — dumb, heavy, predictable,
   telegraphed. Never unfair.
4. Soft failure — slapstick, dense checkpoints, instant retry. The phone
   cracks (3 = over) or someone falls down a hole (instant over); nobody
   truly gets hurt.
5. The leash is an honest rope, exaggerated — winding, cinching,
   tetherball, flinging are core verbs. THE ROPE IS THE SINGLE SOURCE OF
   TRUTH: never reintroduce separate wrap/pivot bookkeeping (three past
   attempts all desynced from the visual rope — see CHANGELOG "the rope
   IS the constraint"). Physics claims get a headless test BEFORE
   shipping.

## 3. How to run / test / release (Windows, PowerShell + Bash tools)

Godot 4.7 lives portably in `godot/` (gitignored). Key commands:

- **Play it:** `godot\Godot_v4.7-stable_win64.exe --path .`
- **Focused regression example — production pair-park orchestration:**
  `godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_pair_park_traffic.gd`
- **Per-level smoke test:**
  `godot\Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 1800 -- --level=park`
  Run `street`, `park`, `beach`, and `market`; add `--daily` only when
  specifically testing the daily.
- **Full-loop attract/CI bot (out→freedom→home→finish):**
  `godot\Godot_v4.7-stable_win64_console.exe --headless --fixed-fps 60 --path . --quit-after 12000 -- --level=street --autowalk`
  `--fixed-fps 60` is mandatory. Require no script/parse errors and an
  `AUTOWALK FINISHED` marker.
- **Web export + zip for itch:**
  `godot\Godot_v4.7-stable_win64_console.exe --headless --path . --export-release "Web" build/web/index.html`
  then `Compress-Archive -Path build\web\* -DestinationPath leash-resistance-web.zip -Force`
  (templates live in `%APPDATA%\Godot\export_templates\4.7.stable\`).
- **CI source of truth:** `.github/workflows/ci.yml`. It runs focused rope,
  critter, tangle, freedom-traffic, pair-direction, bandana, owner-label,
  bypasser-route, rider-avoidance, pair-obstacle, pair-park-lifecycle,
  park-slot, and pair-park-traffic regressions, followed by all four smoke
  tests and deterministic autowalk. The suite runs on every push to `main`
  and every pull request targeting `main`.

**Release ritual each version:** implement → run all automated tests → launch
and perform the relevant manual acceptance → update `CHANGELOG.md` and the
version label in `main.gd` (`version_l`) → commit and tag → push with tags →
re-export the zip. Santtu uploads the zip to itch manually.

**Gotcha:** renaming the project folder tends to hit a Windows directory
lock; use robocopy `/MOVE` as a fallback.

## 4. Architecture and ownership

Single gameplay scene `main.tscn` is one Node2D running `main.gd` (roughly
2,500 lines). Everything is procedural vector art drawn in `_draw()`; there
are no production art assets yet.

- `game.gd` — **autoload `Game`**: session and save state (level, owner,
  night/weather, records, stars, bones wallet, cosmetics, daily seed).
  Save file: `user://records.cfg`.
- `main.gd` — world construction, the explicit frame loop, walk phase machine
  (`out|freedom|home`), HUD/menu, spawners, interactions, and world drawing.
  For NPC park traffic, main owns the three fence-side slot definitions and
  reservation dictionary, configures pair routes and park bounds, qualifies
  gate arrivals, applies the global three-pair cap, mixes arrival/departure
  freedom spawns, initiates home recall, and clears rope obstacles immediately
  on freedom entry.
- `otherpair.gd` — owns each persistent NPC owner, dog, real leash, route
  planner, slot handle, and lifecycle state machine:
  `WALKING → ARRIVING → PARKED → RECALLING → DEPARTING → WALKING`. It owns
  bounded transition movement, parked dog roaming, physical recall, re-leash,
  gate clearance, route resumption, and exactly-once slot release on clearance
  or tree exit. Main starts lifecycle events; `otherpair.gd` executes them.
- `dog.gd` — Millie: movement, plant, pee, turbo, swimming, cosmetics, and
  `auto`/`auto_move` bot support.
- `human.gd` — player owner payload: autopilot, telegraphed events, whirl,
  chore chain, wading, and freedom parking.
- `leash.gd` — visible verlet rope and gameplay constraint. It owns pole
  collision, stick-slip/capstan behavior, `detached`, `resnap()`, and dynamic
  rope obstacles used by leash tangling.
- Other entities: `bike.gd`, `squirrel.gd`, `pigeon.gd`, `duckling.gd`,
  `cone.gd`, `astand.gd`, `ball.gd`, and `freedog.gd`.
- Presentation/support: `weather_overlay.gd`, `touch_controls.gd`,
  `hud_panel.gd`; concept guides are under `assets/concept/`.

**Performance constraint:** entities must not query scene-tree groups per
frame. Main builds rider/critter/bird caches once per physics tick. `_draw`
culls to the camera window and HUD strings rebuild at about 7 Hz.

## 5. Released baseline versus current main

### Released v1.5

Tag `v1.5` contains four campaign walks plus the seeded Daily Walk, selectable
day/night/weather, records/stars/bones, cosmetics shop, round-trip walk with
freedom romp and fetch, turbo, quests, chores, bodily-needs systems, two player
owners, touch/controller support, and deterministic autowalk. The v1.4
NPC-pair baseline — path walkers, real second leashes, tangle events, and free
dogs in the park — is also in v1.5.

The full NPC arrival/park/recall/departure lifecycle is **not** part of the
`v1.5` tag.

### Post-v1.5 current `main`

Current `main` adds hardened fixed-obstacle routing and the persistent NPC
dog-park lifecycle. Three pairs can be active and three distinct park slots
exist away from the player bench. Existing upward walkers can reserve a slot
at the gate; freedom traffic can also spawn arrivals or already-parked
departures. The same dog and owner persist through parking, recall, re-leash,
gate exit, slot release, and shared route resumption.

The off-leash yard has a perimeter fence, a waiting bench, and a defined gate.
This post-v1.5 work has strong automated coverage but still requires manual
lifecycle acceptance before calling it visually accepted or released.

## 6. Current sitrep, evidence, and residual risk

### Evidence in the repository

- The production-path regressions exercise real `main.gd` orchestration for
  arrival qualification, freedom spawn policy/fallback, active cap, slot
  ownership, transition cleanup, home entry, and exhausted-slot walkers
  continuing across the gate.
- Real `otherpair.gd`, route planner, and leash fixtures cover bounded
  arrival, parked identity/bounds, suspended rope state, recall/re-leash,
  gate exit, route reset, tangle latching, and exactly-once cleanup.
- `test_freedom_traffic.gd` separately proves riders leave freedom while a
  park-configured pair persists.
- The deterministic CI autowalk spends only about 4.9 seconds in freedom. It
  verifies whole-walk traversal, not a full NPC lifecycle, and does not
  guarantee that a live pair is encountered.

### Manual acceptance still required

No manual visual lifecycle acceptance is recorded for the post-v1.5 work.
Run these checks in priority order:

1. Watch an upward walker enter through the gate leashed, with no speed snap,
   teleport, or invisible tangle.
2. Fill multiple slots and confirm owners wait at distinct fence-side spots
   away from the player bench while the same dogs roam inside the yard.
3. Confirm the parked leash is hidden, dogs stay bounded and greetable, and
   recall happens physically before the leash appears.
4. Confirm recalled pairs clear the gate, release their slots, and continue
   downward through ordinary obstacle routing.
5. Exercise three occupied slots and verify another upward walker passes
   through without stalling, stacking, or stealing/leaking a reservation.
6. Trigger freedom/home transitions around arrival and recall, checking for
   one-frame rope artifacts, double rewards, snaps, or stranded pairs.
7. Confirm bikes/scooters stay absent during freedom and assess whether
   ordinary leash tangles remain readable and recoverable on walking legs.

### Inference and residual risk

Headless tests establish state and motion invariants, not visual readability
or game feel. Because the automated freedom leg is short and encounter timing
is stochastic in normal play, successful autowalk is not evidence that the
arrival-to-departure sequence looks good. Optional deliberate pole-snag
behavior should remain deferred until coordinated avoidance and tangle feel
have been manually assessed.

## 7. Recommended next work

1. **Manual NPC lifecycle acceptance first.** Record observed failures before
   tuning timing, movement, or presentation.
2. **Then isolated free-dog visual variety.** Follow
   `docs/PARALLEL_TASK_FREE_DOG_VARIETY.md`; keep ownership to `freedog.gd`, a
   reusable appearance module, and its focused regression so it stays
   independent from pair lifecycle code.
3. **Then roadmap content:** richer NPC-owner props/conversation, a real
   owner-throw/return fetch loop, more off-leash dog interactions, the
   bring-Tofu-home quest, Rainy Day level, and a shareable daily results card.
   Distinct dog appearances should be reusable by a future playable-breed
   selector rather than becoming one-off NPC art.

## 8. Then v2.0 — The Product

Watercolour art integration (girlfriend's paintings replacing the vector
placeholders; keep a consistent hand on Millie/Tofu/owners, recolour
asset-pack environments to match). Sound + music pass. Trademark
verification at EUIPO/USPTO ("Path of Leash Resistance" searched clear;
verify before the store page). Steam page (GIF-first trailer). Next Fest
demo. Also unresolved: the 2D-vs-3D question — a one-week Godot 3D spike
(low-poly, rail camera) was always meant to happen before committing
art; the 2D loop has proven itself, so this is a real fork to weigh.

## 9. Conventions

No emoji anywhere. Plain comments stating constraints, not narration.
Honest incremental git history, imperative commit subjects, a tag per
release. Feel/tuning decisions are made by playtesting, not argument —
tuning constants live named at the top of scripts. Update CHANGELOG.md
every session. Never commit the itch secret URL. The repo is public but
has no LICENSE on purpose (all rights reserved, commercial WIP).
