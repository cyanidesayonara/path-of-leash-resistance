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
reference on the short axis instead of blanking it). touch_controls.gd,
goals_card.gd, results_panel.gd, settings_panel.gd, and the pause/settings
dim overlay all anchored against the 1280x720 reference rather than the
actual viewport and now use `get_viewport_rect().size`, recomputed on
resize. Verified locally via `--resolution WxH` at several phone landscape
shapes and one portrait shape — not yet played on a real phone browser.
Touch acceptance testing can proceed once that happens.

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
