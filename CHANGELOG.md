# Changelog

Append-only session history, newest first.

## 2026-07-10 — GitHub setup, retractable leash

- Repo published to GitHub with CI (headless smoke test on push/PR)
- Added AGENTS.md, CHANGELOG.md, PR template; PLAN.md renamed to PROJECT.md
  to match stemma/hire-ground conventions
- Retractable leash: hold Shift / RB to reel the human in (new core verb;
  min length 110px, auto-extends back to 260px)

## 2026-07-10 — playtest feedback round 1

- Leash winds around the same pole repeatedly (multi-wrap, up to 24 pivots);
  wraps stiffen the spring so wound-up flings accelerate (tetherball)
- Dog pulls much harder; a taut leash saps the human's walking motor so
  sustained pulling visibly drags them
- First web build exported (threads off, no SharedArrayBuffer needed) and
  published to a draft itch.io page for playtesting
- Meta/retention direction captured in PROJECT.md: casual to finish, hard
  to master; daily-seeded walk instead of guilt mechanics; horizontal
  progression

## 2026-07-10 — named Touch Grass, content batch

- Renamed from working title Pull of Duty; tagline "Take the Path of Leash
  Resistance"
- Human events: selfie (backs up blindly), filming (walks backwards),
  bench sit; all telegraphed
- Hazards: open cellar doors, cafe terrace (tables snag the leash)
- Juice: slow-mo on last-moment saves, save streak multiplier

## 2026-07-10 — leash physics

- Weight pass: human carries momentum, spring zone + hard cap at 15%
  stretch, stiffness scales with dog anchoring
- Pole wrapping as a real constraint: pivot chain, effective length, pull
  redirection; three mid-sidewalk poles added

## 2026-07-10 — first prototype

- Top-down prototype in Godot 4.7: dog (move/plant/bark), phone-zombie
  human with telegraphed events, verlet leash, bike lanes, manholes,
  hydrant/kebab pickups, phone-crack fail state, park gate goal
- All placeholder art drawn with _draw(), no assets
