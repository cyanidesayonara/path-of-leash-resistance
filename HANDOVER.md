# HANDOVER — Path of Leash Resistance

Thin current sitrep for the next agent or human. Details live in the
canonical docs; do not treat archived handover notes as current truth.

## Read first

1. `AGENTS.md` — tech map, rope architecture, commands, conventions
2. `PROJECT.md` — design pillars and living release plan
3. `CHANGELOG.md` — newest-first session history
4. `.github/workflows/ci.yml` + `release.yml` — what must stay green to ship

Historical sitrep (NPC owner appearances / post-v1.5 lifecycle era,
2026-07-17): `docs/handover/ARCHIVE-2026-07-17-npc-owner-appearances.md`.

## What this is

Top-down physics comedy in Godot 4.7 / GDScript. You are the dog; the
phone-distracted human walks on autopilot; the leash is real verlet-rope
physics (visual and gameplay constraint — see AGENTS.md). Ships to itch
(`html5` + `windows`) on a version tag after green CI.

## Where things stand (2026-10-03)

**Released: v1.57** on itch (web + Windows) and submitted to the Microsoft
Store as 1.57.0.0 on 2026-10-03 (listing record: `store/listing.md`). Its
Store submission uses the ten current screenshots in `store/screenshots/`.

**On `main`, awaiting hand acceptance** (board column "Awaiting acceptance",
https://github.com/users/cyanidesayonara/projects/4):
- #127 leash overhaul: smooth collision-aware drawing over the same physical
  verlet rope, adaptive stabilisation and weighted end control.
- #128 guided whirl overhaul (below).

**In review, not yet merged:** branch `menu-shell-tutorial-reach`, the first
of the two passes in `docs/superpowers/specs/2026-10-03-menu-terrain-design.md`
(plan: `docs/superpowers/plans/2026-10-03-menu-shell-tutorial-reach.md`). The
tutorial's nose snack is reachable again (El Barri lost its accidental edge
walls, held lessons stand the owner by the right edge with the reel pinned
long); pause is a two-column grid with THIS WALK, confirmed START AGAIN and
EXIT GAME, and EXIT GAME on the desktop title. Its PR is player-facing: once
merged it makes 3 of 5 awaiting acceptance. The second pass (terrain audit
and surface looks) has not started.

The older acceptance backlog (#23) is closed with every entry ticked. The
board and that issue are the source of truth for the WIP count.

**Needs Santtu:**
- #65 (S2, decision): the built-up walks' frontage has been hidden under
  full-width grass since v1.51. Three options in the issue.
- Play #127, #128 and, once merged, the menu and tutorial PR (its feel
  card); the real-phone check (#13) now includes the
  touch controls; #11, #12, #14.

**Level review (#21):** two automated passes done (every walk at five points;
every walk in rain, wind, snow, night and at 844x390). Findings filed and
mostly fixed; what is left needs play.

**Performance (#45):** see the CHANGELOG. Levers that are left change the
picture (the full-screen grade costs 3-4 ms a frame on an integrated GPU in
the browser) or the behaviour (walker ropes; tried and dropped 2026-09-26).

**Guided whirl overhaul (built, not yet accepted):** the owner now commits to
one direction and the exact local human-end coil measured over the arming
window. Normal release is the pure tangent; the bounded missed-tangent path
leans dogward only when it can still preserve the orbit, otherwise it bails
into a controlled stumble. Timeout, lost-pole and furniture cases bail too,
with their exit frame still shielded from the tug. The anticipation rings,
orbit ghosts, speed lines, grit and fling streaks are procedural and
deterministic. `tests/test_whirl_guided.gd` is the exhaustive guard.

Hand-play only the final commit. At the shortest reel, measurable coils fall
under the 0.6-turn minimum, so every short-reel orbit uses that floor. A coil
still tightening through the 0.25-second arming window is slightly under-read
by its mean. A safe refusal deliberately loses the old FLING reward. The
dogward lean on the forced path remains a tuning point; do not retune any of
these without play evidence and a failing regression where appropriate.

## Tools and rules added since the freeze began

- Verification: `tools/shot_sweep.sh` (deterministic: fixed frame rate,
  seed, `AnimClock`), `tools/shot_diff.py` (pixel diff of two sweeps),
  `tools/behaviour_snapshot.sh` (59 fixed-seed runs over 14 walks;
  byte-identical for a refactor, line-by-line explained for intentional
  handling changes), `tools/idle_soak.sh`, `--perf` with
  `--perf-hide=`, `--perf-no-grade`, per-spike `physics_top`,
  `tools/perf_sweep.sh`, `tools/web_perf.sh`, `tools/bench_leash.gd`,
  `tools/bench_leash_draw.gd`.
  Flags for screenshots: `--night`, `--weather=`, `--prompts=pad|touch`,
  `--touch`, `--shot-at=N`, `--shot-menu=walkcard|confirm`, and `--no-exit`
  for the web menus on desktop.
- Rendering: draw runs of filled shapes through `ShapeBatch`
  (`systems/shape_batch.gd`, pixel-exact, test in CI). Cosmetic animation
  reads `AnimClock.msec()`, never the wall clock.
- UI text: button names through `Prompts` (`hud/prompts.gd`); a key name
  written into a UI string fails `tests/test_prompts.gd`.
- Determinism: gameplay runs on game time (`main.elapsed`); visual
  randomness has its own RNG. Keep it that way (#6).
- Layout: main.gd split into `systems/`, `hud/`, `world/` modules (static
  functions over main's state, forwarders kept); scripts live in folders.
- Change control: the WIP limit and feel cards (AGENTS.md).

**Dog moods** (`systems/mood.gd`, backlog item 9). Four moods - SCARED, BARKY,
ZOOMIES, TIRED - arriving from events and fading on their own. They are
**weather, not a menu**: nothing picks a mood and nothing cancels one, so the
bounds in the mood header are load-bearing rather than tuning. Never touch
the camera. Limit perception only. A fifth of speed either way at most. Read
that header before changing any number in it, and keep `tests/test_mood.gd`
green - most of it guards the promise, not the feature.

Microsoft Store: live since 2026-09-23 (https://apps.microsoft.com/detail/9p5d14v8rbqx),
Store ID 9P5D14V8RBQX. `store/msix/` plus `tools/pack_msix.ps1` build the
package and `release.yml` attaches it to each tagged release; the Store
submission itself is manual (`docs/MICROSOFT_STORE.md`).

## Known deferred gap

**Mobile Web canvas scaling (fixed in v1.54, unconfirmed on a real device):**
stretch aspect switched from "keep" (letterboxed hard on any non-16:9 window)
to "expand" (fills the window, revealing more/less than the 1280x720
reference on the short axis instead of blanking it). Everything that had
anchored against the 1280x720 reference now anchors against the live
viewport: the four panel scripts (touch_controls, goals_card, results_panel,
settings_panel), the dim and weather overlays, the colour-grade rect and its
world-space noise, and every element built by `hud/hud_build.gd` — sixteen
centred lines, the bottom rule, the wardrobe cluster. In `HudBuild.build`, use
`pin_wide` / `pin_box` rather than literal coordinates; each element names
the rule it hangs off (top edge, middle, bottom edge).

Guarded by `tests/test_hud_anchoring.gd`, which reshapes a real viewport to
a landscape and a portrait phone and asserts the HUD follows (389 checks, in
CI). Native 1280x720 is asserted unchanged, so desktop cannot regress.

Verified locally via `--resolution WxH` and before/after screenshots at
844x390 — **not yet played on a real phone browser.** Touch acceptance
testing can proceed once that happens; it is the only part still unverified.

## Release ritual

1. Green CI on the commit you intend to ship
2. Update `CHANGELOG.md` (the in-game version label is stamped from the
   tag by `release.yml`; there is nothing to bump by hand)
3. `git tag vX.Y && git push --tags`
4. CI runs again for the tag SHA; `release.yml` waits for that success,
   then exports and publishes to itch. Missing `BUTLER_API_KEY` fails the
   job (does not skip upload).

## Conventions

No emoji. Imperative commits. Tuning constants named at script tops.
Feel decisions from playtesting. Update CHANGELOG every session.
