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

## In flight (unreleased, on `main` after v1.54)

**Dog moods** (`mood.gd`, backlog item 9). Four moods - SCARED, BARKY,
ZOOMIES, FLAT - arriving from events and fading on their own. They are
**weather, not a menu**: nothing picks a mood and nothing cancels one, so the
bounds in `mood.gd`'s header are load-bearing rather than tuning. Never touch
the camera. Limit perception only. A fifth of speed either way at most. Read
that header before changing any number in it, and keep `tests/test_mood.gd`
green - most of it guards the promise, not the feature.

Also unreleased and untouched by me: branch `ms-store-msix` (Microsoft Store
MSIX packaging, 5 commits, never pushed) predates the two v1.54 commits and
needs a rebase onto `main` before it will build.

## Current state (v1.54 on `main`)

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
world-space noise, and every element built in `main.gd/_build_hud` — sixteen
centred lines, the bottom rule, the wardrobe cluster. In `_build_hud`, use
`_pin_wide` / `_pin_box` rather than literal coordinates; each element names
the rule it hangs off (top edge, middle, bottom edge).

Guarded by `tests/test_hud_anchoring.gd`, which reshapes a real viewport to
a landscape and a portrait phone and asserts the HUD follows (389 checks, in
CI). Native 1280x720 is asserted unchanged, so desktop cannot regress.

Verified locally via `--resolution WxH` and before/after screenshots at
844x390 — **not yet played on a real phone browser.** Touch acceptance
testing can proceed once that happens; it is the only part still unverified.

## Release ritual

1. Green CI on the commit you intend to ship
2. Update `CHANGELOG.md` and the in-game version label if needed
3. `git tag vX.Y && git push --tags`
4. CI runs again for the tag SHA; `release.yml` waits for that success,
   then exports and publishes to itch. Missing `BUTLER_API_KEY` fails the
   job (does not skip upload).

## Conventions

No emoji. Imperative commits. Tuning constants named at script tops.
Feel decisions from playtesting. Update CHANGELOG every session.
