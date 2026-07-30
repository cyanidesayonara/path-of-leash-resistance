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

## Current state (v1.53 hardening, branch `v153-hardening`)

Hardening rounds on this branch cover:

- Progression boundaries (fresh saves, tutorial isolation, cosmetic
  ownership migration)
- Geometry / furniture recovery (FUR-GONETA fit, terrace chairs, stick-slip
  curves, beach shoreline agreement)
- NPC-leash tangle contacts (segment/capsule enter/exit, dynamic vs static
  snags, mercy release, curiosity suppress during mercy hold)

Visual acceptance recorded for the rounds: Round 1 PASS; Round 2 native
shots; Round 3 Web PASS_WITH_GAPS (tangle scored; FX hard to frame in
browser). No production itch publish is implied by this sitrep.

## Known deferred gap

**Mobile Web canvas scaling:** on phone-sized Web the game can render as a
small fixed canvas with large black borders. Documented only — not a full
mobile overhaul in this closeout. Touch acceptance stays blocked until that
scaling issue is fixed.

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
