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
  park-slot, pair-park-traffic, free-dog visual-variety, pair-dog appearance,
  human-appearance, and pair-owner-appearance regressions, followed by all four
  smoke tests and deterministic autowalk. The two owner-appearance tests run
  under Xvfb with the real GL Compatibility renderer so their `SubViewport`
  pixel readback is exercised; the other focused tests remain headless. The
  suite runs on every push to `main` and every pull request targeting `main`.

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
- `human_appearance.gd` — stateless reusable presentation boundary for generic
  NPC owners: six stable profile IDs, defensive lookup and signed-key
  selection, comprehensive validation, and one procedural renderer. It creates
  no nodes, stores no runtime state, consumes no randomness, and has no
  dependency on pair behavior, lifecycle, leashes, player-owner code, creator
  UI, or save data.
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

### Reusable NPC owner appearance architecture

`human_appearance.gd` exposes six persistence-facing IDs in stable order,
defensive profile lookup, positive-modulo signed-key selection, comprehensive
validation, and procedural owner drawing. The IDs are
`compact_short_cap`, `tall_long_glasses`, `broad_bun_sunglasses`,
`medium_bald_spot_glasses`, `narrow_short_beanie`, and `rounded_long_cap`.
Their order, exact schema, and meaning are persistence-facing API for possible
later creator reuse.

`otherpair.gd` owns one `owner_appearance_profile` dictionary for the complete
pair lifetime. Setup still consumes exactly velocity `randf_range`, animation
phase `randf`, raw owner `randi`, and raw dog `randi` in that order.
`owner_col` derives from the selected owner profile's `shirt_color`; the
existing dog profile and `dog_col` flow is unchanged. Both procedural
renderers draw on the pair parent while `npc_owner`, `npc_dog`, and `leash`
remain the real persistent gameplay nodes and endpoints.

No creator, selector, save, migration, unlock, progression, stat, or behavior
feature is part of this implementation. Future creator work may consume the
stable IDs, defensive profiles, validation, and renderer only through a
separately approved design.

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
- `test_free_dog_variety.gd` loads the real appearance and free-dog scripts
  and covers stable profile selection, defensive data, validation, RNG
  isolation, deterministic setup, preserved lifecycle movement/bounds, and a
  headless redraw of all six profiles including the zero-forward case.
- `test_pair_dog_appearance.gd` loads the real pair, leash, and appearance
  scripts and covers exact setup RNG cadence, stable profile identity through
  every park lifecycle state, preserved node/leash identity, and parent-Canvas
  redraw of all six profiles including the zero-forward case. Its obsolete
  three-color owner-palette assertion was removed after isolated review; every
  dog, RNG, lifecycle, identity, and renderer assertion remains.
- `test_human_appearance.gd` loads the real owner module and covers the exact
  public API, stable ID order, canonical values/schema/types, defensive copies,
  positive and negative key cycling, non-mutating malformed-data validation,
  finite/color/enum/primitive/radius safety, every visual trait branch, RNG
  isolation, zero/non-finite facing fallback, non-finite early return,
  malformed-profile fallback, both phone states, and rendered body/screen
  pixels for every canonical phone.
- `test_pair_owner_appearance.gd` loads the real pair, owner appearance, dog
  appearance, and leash scripts. It covers the exact four setup draws, raw
  third/fourth profile keys, following RNG value, compatibility colors, equal
  seeds, owner variety, dictionary identity through every lifecycle and
  initialization/interruption path, pair/owner/dog/leash identity, leash
  endpoint references, zero-velocity north fallback, parent-Canvas owner and
  dog drawing, held phones, and draw-time RNG isolation.
- The deterministic CI autowalk spends only about 4.9 seconds in freedom. It
  verifies whole-walk traversal, not a full NPC lifecycle, and does not
  guarantee that a live pair is encountered.

### NPC owner appearance repository state

Repository state captured on 2026-07-17:

- Feature branch: `npc-owner-appearances`.
- Upstream: `origin/npc-owner-appearances`.
- Pull request
  [#2](https://github.com/cyanidesayonara/path-of-leash-resistance/pull/2)
  is open against `main`.
- Isolated implementation checkpoint:
  `3aaed22602359da70f1ddd063ce2912ac5e2f7b9`
  (`Add reusable NPC owner appearances`).
- Integration checkpoint:
  `c7746256a74feaea28f63280ff4f0d55d56e3944`
  (`Integrate NPC owner appearance regressions`).
- CI hardening commit above the integration checkpoint:
  `f380ba8712e2adcb9840ddc94c199e6c2dd584bc`
  (`Harden owner appearance pixel CI`).
- Local `main` and `origin/main` remain at
  `4bca50ce1c1a5deacbd54ff854a639ad74b20997`
  (`Plan reusable NPC owner appearances`) until the pull request is merged.
- Final whole-branch review found no code defects. Its sole Important finding,
  Linux CI provisioning for the pixel tests, was fixed by `f380ba8`; focused
  re-review marked that finding resolved.

### NPC owner appearance automated evidence

Final integration verification ran on 2026-07-17 on Windows 10 with Godot 4.7.
The 15 non-pixel focused commands ran headless and the two owner appearance
commands ran with the real GL Compatibility renderer because Windows headless
uses dummy texture storage. Every command exited `0` and printed its marker:

- `test_wrap: OK`, `test_critter_chase: OK`, `test_tangle_latch: OK`,
  `test_freedom_traffic: OK`, `test_pair_direction: OK`,
  `test_bandana_preview: OK`, `test_owner_label: OK`,
  `test_bypasser_route: OK`, `test_rider_avoidance: OK`,
  `test_pair_pond_avoidance: OK`, `test_pair_park_lifecycle: OK`,
  `test_pair_park_slots: OK`, `test_pair_park_traffic: OK`,
  `test_free_dog_variety: OK`, and `test_pair_dog_appearance: OK`.
- `test_human_appearance: OK` and `test_pair_owner_appearance: OK` each
  reported `OpenGL API 3.3.0 ... Compatibility` on the NVIDIA renderer and
  completed their unconditional `SubViewport` phone body/screen pixel checks.
- Street, park, beach, and market smokes each exited `0` with no `SCRIPT ERROR`,
  `Parse Error`, or `Failed to load script`.
- Fixed-60-FPS street and park autowalks each exited `0`, logged no script/load
  errors, and printed `AUTOWALK FINISHED the whole walk at t=120.0`.

CI installs Xvfb explicitly and runs both owner appearance tests through
`xvfb-run -a` with `--rendering-method gl_compatibility` and no `--headless`,
so Linux CI exercises real pixel readback too. These automated results do not
establish manual visual acceptance.

GitHub Actions pull-request run
[29587175828](https://github.com/cyanidesayonara/path-of-leash-resistance/actions/runs/29587175828)
passed in 1m38s on Linux at `f380ba8`. The live run included the Xvfb/Mesa GL
Compatibility owner pixel tests, every focused workflow regression, all-level
smokes, and deterministic autowalk. It does not establish merge or manual
visual acceptance.

### Manual acceptance still required

No manual visual lifecycle acceptance is recorded for the post-v1.5 work.
Shared free-dog and pair-dog appearance readability, animation, local bounds,
and visual identity persistence also remain manually unverified. The six new
owner profiles have not been visually accepted by a human. Automated draw and
pixel tests do not establish bun/accessory layering, phone legibility,
silhouette or color readability, gait feel, local-scale quality, or visual
continuity through walking, arrival, parking, recall, re-leashing, departure,
and resumed walking.
Run these checks in priority order:

1. Inspect all six owner profiles in motion and at rest, checking hair,
   headwear, eyewear, bun/accessory layering, phone body and screen legibility,
   silhouette/color contrast, proportions, and gait.
2. Watch an upward walker enter through the gate leashed, with no speed snap,
   teleport, or invisible tangle.
3. Fill multiple slots and confirm owners wait at distinct fence-side spots
   away from the player bench while the same dogs roam inside the yard.
4. Confirm the parked leash is hidden, dogs stay bounded and greetable, and
   recall happens physically before the leash appears.
5. Confirm recalled pairs clear the gate, release their slots, and continue
   downward through ordinary obstacle routing.
6. Exercise three occupied slots and verify another upward walker passes
   through without stalling, stacking, or stealing/leaking a reservation.
7. Trigger freedom/home transitions around arrival and recall, checking for
   one-frame rope artifacts, double rewards, snaps, or stranded pairs.
8. Confirm each owner retains the same visible profile through walking,
   arrival, parking, recall, re-leashing, departure, and resumed walking.
9. Confirm bikes/scooters stay absent during freedom and assess whether
   ordinary leash tangles remain readable and recoverable on walking legs.

### Inference and residual risk

Headless tests establish state and motion invariants, not visual readability
or game feel. Because the automated freedom leg is short and encounter timing
is stochastic in normal play, successful autowalk is not evidence that the
arrival-to-departure sequence looks good. Optional deliberate pole-snag
behavior should remain deferred until coordinated avoidance and tangle feel
have been manually assessed.

## 7. Recommended next work

1. **Manual NPC owner and lifecycle acceptance first.** Record observed
   profile, renderer, gait, and lifecycle-continuity failures before tuning.
2. **Fix only observed appearance defects inside the appearance boundary.**
   Do not alter pair behavior to tune presentation.
3. **Keep future creator work separate.** It may consume stable IDs, defensive
   profiles, validation, and rendering, but requires its own approved design
   for player-owner integration, UI, and persistence.
4. **Then roadmap content:** richer NPC-owner props/conversation, a real
   owner-throw/return fetch loop, more off-leash dog interactions, the
   bring-Tofu-home quest, Rainy Day level, and a shareable daily results card.
   The reusable dog appearance profiles are now available to a future
   playable-dog selector without depending on either NPC caller.

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
