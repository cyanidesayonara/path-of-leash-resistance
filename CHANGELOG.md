# Changelog

Append-only session history, newest first.

## 2026-07-10 — playtest feedback round 3: winding for real

- Winding rewritten as a continuous accumulated angle per pivot: sign tests
  cannot count revolutions and dropped wraps at ~3/4 turn. Release on
  rotating back past the creation bearing, or on pulling nearly straight.
  Added tests/test_wrap.gd (3 revolutions each direction, full unwind);
  runs in CI before the smoke test.
- Tug of war rebalanced: removed the human motor sap (it double-counted
  the dog's advantage and killed the human's yanks); instead a taut leash
  saps the DOG's control authority. Planting softened x30 -> x14 so hard
  yanks visibly skid even a braced dog.
- The human now fiddles with the retractable leash on its own timer
  (every 4-8s, "click!"), on top of everything else they do.

## 2026-07-10 — playtest feedback round 2: tug of war

- Mass-based leash model: human 4x dog mass, one tension applied inversely
  to effective mass. The human now yanks the dog around; the dog wins via
  planting (x30 brace), movement (x2), and pole wraps (capstan 2.2^pivots)
- Fixed multi-wrap detaching: the unwrap sign test also fired when winding
  past a half turn (now requires the straightened side), and wrap/unwrap
  state freezes while the endpoint hugs the pole
- Retractable leash inverted per playtest feedback: the HUMAN owns the
  reel. "click!" event sets a random leash length (130-330), sometimes
  reeling the dog in against its will. Player reel input removed.

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
