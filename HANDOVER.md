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

## In flight (unreleased, on `main` after v1.54): stabilization freeze

Started 2026-09-23: no new features, only verification tooling, bug fixes and
refactors. The board is https://github.com/users/cyanidesayonara/projects/4;
PROJECT.md stays the design source of truth.

**WIP limit (AGENTS.md "Change control"): `main` is over it.** Player-facing
changes merged but not yet accepted by hand: the eight pre-freeze changes
(#23) and the freeze fixes in the board's "Awaiting acceptance" column
(portrait prompt, idle knock, results card, A-stands, mood badge, title
prompt, results spacing, settings title, status banner, wardrobe preview).
Only hardening and tooling land until the count drops below 5.

What the freeze has added, so you can use it:
- **Verification:** `tools/shot_sweep.sh` (every walk + menus + phone
  shapes, contact sheets; `shots.yml` on PRs), `tools/idle_soak.sh` (no
  input, counts knocks/moods; `soak.yml`), `tools/behaviour_snapshot.sh`
  (51 fixed-seed runs; must be byte-identical for a refactor),
  `--perf` + `tools/perf_sweep.sh` (frame times). CI fails on any SCRIPT
  ERROR (`tools/godot_ci.sh`) and on files an import leaves untracked.
- **Layout:** main.gd split along its seams into `systems/`, `hud/`,
  `world/` (static functions over main's state, forwarders kept), and every
  other script moved into `autoload/`, `entities/`, `hud/`, `world/`,
  `systems/`. See AGENTS.md "Project Structure".
- **Determinism:** gameplay motion runs on game time (`main.elapsed`), never
  the wall clock, and visual randomness (weather particles, camera shake)
  has its own RNG. Keep it that way, or window size and machine speed leak
  back into play (#6).
- **Performance:** tracked in #45 with the baseline and the leads.

Still yours to do by hand: accept or reject the awaiting changes, the
level-by-level review (#21), the real-phone check (#13), mood readability on
pad and phone (#11), SCARED during the chase (#12), leash weight tuning (#14),
and the sweeper's own narrow level (#20, a new level: after the WIP count
drops).

**Dog moods** (`systems/mood.gd`, backlog item 9). Four moods - SCARED, BARKY,
ZOOMIES, TIRED - arriving from events and fading on their own. They are
**weather, not a menu**: nothing picks a mood and nothing cancels one, so the
bounds in the mood header are load-bearing rather than tuning. Never touch
the camera. Limit perception only. A fifth of speed either way at most. Read
that header before changing any number in it, and keep `tests/test_mood.gd`
green - most of it guards the promise, not the feature.

Microsoft Store: **live since 2026-09-23 at 1.54.0.0**
(https://apps.microsoft.com/detail/9p5d14v8rbqx), an "MSIX or PWA game",
Store ID 9P5D14V8RBQX. What was entered in Partner Center is in
`store/listing.md`. `store/msix/` plus `tools/pack_msix.ps1` build the
package, and `release.yml` attaches it to each tagged release. Full
procedure: `docs/MICROSOFT_STORE.md`. The next Store update is v1.55, once
the freeze fixes and the pre-freeze changes are accepted.

## State at v1.54 (the last release)

Hardening rounds shipped via PR #3:

- Progression boundaries (fresh saves, tutorial isolation, cosmetic
  ownership migration)
- Geometry / furniture recovery (FUR-GONETA fit, terrace chairs, stick-slip
  curves, beach shoreline agreement)
- NPC-leash tangle contacts (segment/capsule enter/exit, dynamic vs static
  snags, mercy release, curiosity suppress during mercy hold)
- Review follow-up: leash hot-path recovery, pole slip restored to the
  original curve (furniture/dynamic keep the free-at-cap ramp), gated
  manual release dispatch

Visual acceptance: Round 1 PASS; Round 2 native shots; Round 3 Web
PASS_WITH_GAPS (tangle scored; FX hard to frame in browser).

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
