# Changelog

Append-only session history, newest first.

## 2026-07-12 — the slipping regression, props that make sense

- The perf pass's pole filter computed its bounding box from the rope's
  ENDPOINTS only; a partial wind puts both endpoints on one side of the
  pole, the pole got excluded from collision, and the rope ghosted
  through - the slipping-off regression. The box now covers every rope
  point. (Lesson repeated: fast and wrong is still wrong.)
- Environmental storytelling pass, because "why is there an open manhole
  in the middle of the walkway": manholes now have work cones nobody
  moved, cellar doors are propped open next to a delivery crate and a
  cone, mid-walkway poles on the Boulevard are street TREES in grates
  (that is why they stand there), lampposts grew a lamp head so they
  stop reading as bins, bins got a lid, mouth and handle - the green
  lidded thing is the only thing the owner bags into. The beach lost
  its inexplicable mid-pavement palm.
- PROJECT.md: "the shape of a walk" direction - walk out, DESTINATION
  as the off-leash reward (dog park / beach / meadow, other dogs,
  minigames), then the walk home. Replaces the finish line eventually.
- Name check result: "Touch Grass" is TAKEN on Steam (LionsHead
  Development, trademark claimed) plus a cluster of similar titles.
  "Path of Leash Resistance" checked clear. Decision pending.

## 2026-07-12 — touch controls, performance pass, two owners, beach palette

- The web build is playable on phones: a floating virtual joystick on
  the left half of the screen and DIG/BARK/PEE/R buttons on the right.
  They feed the same input actions as keyboard and gamepad, so there is
  no second control scheme to maintain. Only visible on touch devices.
- Performance (the browser stutter): the leash now collision-checks only
  poles near the rope's bounding box (was every pole on the level, per
  point, per iteration - the single biggest per-frame cost), and the
  level draw culls detail lines, tufts, and poles to the camera window
  instead of redrawing 5500px of them every frame.
- Two selectable owners on the title screen (up/down): HIM and HER -
  different hair, ponytail, palette. A proper character creator is a
  future-systems note.
- Passeig Maritim palette and proportions corrected against the
  reference photos: wider pale sand, narrower pale-wood boardwalk, dark
  brick bike path, pale pavement.

## 2026-07-12 — PASSEIG MARITIM (level three), free roaming

- Level three, modeled on the family's real daily walk in Badalona: sea
  with rolling foam, sand with towels and sunbathers (step on a towel:
  "hey!"), parasols (poles with ambition: windable, markable), a wooden
  boardwalk, the little bike path, the pavement where the owner walks,
  and palm trees plus canopied cafe terraces on the far side. Seagulls
  instead of pigeons. Sand slows the dog down; it is worth it.
- The dog roams free now: walls moved to the LEVEL edges on every walk,
  so grass, sand, and shoulders are all Millie's. The human stays on
  the walkway by inclination, not invisible fences - and an undistracted
  owner eventually tuts "come on!" and reels the leash in a notch when
  the dog lingers off-path. Corridors widened throughout; the human's
  autopilot band is now per-level data.
- CI smoke-tests all three levels. PROJECT.md gains the future-systems
  note for other dog+owner pairs with leash tangling.

## 2026-07-12 — THE PARK (level two), level select, Millie for real

- Second level: The Park. Dirt path instead of sidewalk, trees instead
  of lampposts (same physics, different soul - and yes, they wind), a
  POND that bites into the path with bridge planks squeezing past it
  (phones and ponds are natural enemies; dogs get dunked too), duck
  families crossing in a line (disturbing them is quest material, not
  points - park-only quest: "let the ducklings pass"), no bike lane, no
  manholes, slower path traffic that is mostly kids, extra pigeons,
  slightly better cat odds.
- Level select on the title screen (left/right cycles The Boulevard /
  The Park, the world rebuilds live behind the title). Selection
  survives restarts via a tiny Game autoload. CI now smoke-tests both
  levels. Branch-based for two levels; extract data-driven when the
  third setting arrives.
- Millie, from the reference photos: big floppy ears that swing with
  her stride, THE BUTT WIGGLE (rump swings with the gait), red collar
  and red Julius K9-style harness, white-tipped paws.
- Pigeons scatter from bikes and scooters too, not just mammals.

## 2026-07-12 — chore chain polish, rare visitors

- The poop leaves the sidewalk when the owner BAGS it, not when they
  reach the bin (playtest bug). It also looks the cartoon part now
  (soft-serve stack, nothing gross), and the delivery got an animation:
  the owner stops short of the bin, winds up ("toss..."), and lobs the
  bag in a curving arc - "swish! responsible +2" on the bucket. If the
  chain breaks while they are already carrying the bag, they resume
  toward a bin instead of going back for nothing.
- Rare visitors, the start of the commons/rares/unique content pattern:
  a CAT appears on ~30% of walks - pulls at Millie harder and from
  farther than any squirrel, stands its ground until nearly touched,
  +4 when chased ("the cat got away"). Pigeon flocks (1-2 per walk)
  waddle around the sidewalk and scatter when anyone gets close; barking
  scatters them too, obviously.

## 2026-07-12 — rotating per-walk quests

- Every walk draws three objectives from a ten-quest pool (chase
  squirrels, close calls, marks, sniffs, snacks, nice saves, fling the
  owner, phone unscratched, paws clean, business bagged). Live checklist
  on the HUD ("TODAY'S WALK"), "quest done!" pops mid-walk, +5 bones per
  completed quest at the gate, and the GOOD DOG rating now counts
  completed quests - all three earns PERFECT WALK, zero earns
  "...still a good dog." (because every dog is).
- Maintain-type quests (phone unscratched, paws clean) start checked and
  can be LOST, which reads exactly as menacing as intended.

## 2026-07-12 — squirrels: the temptation that tugs at the dog

- Squirrels lounge near the sidewalk edges and, most cruelly, on the far
  shoulder across the bike lane. A nearby one physically PULLS Millie
  toward it (a real velocity bias the player fights or indulges, with a
  temptation marker over her head). Touching one pays +2 "almost got
  it!" - but it always escapes at the last second, as nature demands.
  They outrun the dog in a straight line, zigzag when fleeing, and a
  bark scares them off (bark's second job: clearing your head).
- Skipped while planted, tumbling, or mid-pee. The pull can absolutely
  drift you into the bike lane; that is the point.

## 2026-07-12 — game flow: title, results, rating

- Title screen ("press SPACE / A to go walkies") holds the world until
  the player starts; headless CI runs auto-start.
- The walk ends with a results screen: quest checklist (phone without a
  scratch, territory secured, business bagged), bones, time, and a
  rating of one to three GOOD DOGs. First step of turning the demo into
  a full game loop per the gamification direction.

## 2026-07-12 — the chore chain, button consolidation

- Bagging is a real quest beat now: after the dog goes, the owner's
  autopilot is hijacked - they walk to the spot ("ugh, hold on"), bend
  down and bag it (2s, visible bag animation), then carry the bag to the
  nearest trash bin ("where's a bin...") and deposit it (+2 responsible
  bones). Falls, whirls and dog sabotage interrupt the chain; they
  resume when back on their feet. Six trash bins line the route - they
  block bodies, snag the leash, and can be marked, obviously.
- Buttons consolidated for a normal Xbox pad: A dig in (doubles as the
  squat during GOTTA GO - the separate squat button felt identical to
  digging in), X pee, B bark, Start restart. The pee velocity gate was
  the "X doesn't really pee" bug: being gently towed by the walking
  human kept the dog above the stationary threshold; the gate is loose
  now and only a hard yank interrupts.

## 2026-07-12 — dedicated buttons, continuous pulley, the owner faces forward

- Pee (Q / X) and squat (C / Y) are their own buttons; plant is purely
  for bracing again. Stopping to go is a vulnerability, not a brace: a
  yank that gets the dog moving interrupts it. Puddles are bigger, marked
  spots pool properly, and marking 5 spots completes the walk's territory
  quest (+10, "MARKS x/5" on the HUD).
- The pulley works along the whole leash now: with the rope wound and the
  dog working its end, the pull on the human is amplified continuously
  (up to ~2.2x at 3 wraps), not only during the whirl. Wraps still shield
  the dog from raw yanks.
- Whirl trigger lowered to 0.55 turns so a 270-degree partial wind whirls
  instead of jamming awkwardly against the pole.
- The owner faces their walking direction (smoothed), with stepping feet,
  a slight walking sway, arms reaching to the phone held out front - and
  correctly walks BACKWARDS while filming or backing up for a selfie.

## 2026-07-11 — whirl v4 (consistency), 5m leash, Millie refined

- Single-wind flings stuck because the 1.25-lap minimum OVER-unwound
  short winds, re-wrapping the rope the other way and arresting the
  launch. The orbit now runs exactly the wound amount; launch speed
  comes from a faster spin-up instead of extra laps. Aim-wait capped at
  0.6 turn; free-slip extends 1.2s after release so residual wraps can
  never arrest a fling.
- Spurious whirls (walking past a pole) fixed: the trigger must hold for
  0.25s with tighter thresholds, and the unwind direction is averaged
  over that window. A mid-whirl wrong-way detector flips the spin once
  if the rope is observed winding tighter.
- The leash is 5 meters now (340px, reel range 170-430) - room to
  actually wind up and fling.
- Millie refined: skinny street-dog frame, long nose, whippy three-
  segment tail with a traveling wave, grey concentrated on the crown
  and face instead of scattered over the body.

## 2026-07-11 — Millie

- The default dog is now Millie: a medium mutt, black coat with salt-
  and-pepper flecks and a graying muzzle. Procedural body upgrade: two-
  segment torso with hips that trail the shoulders (she visibly bends
  mid-turn), four legs in a trot gait (diagonal pairs, speed-scaled
  stride), tail that wags slower when concentrating.
- Pee/squat posture: rump drops, legs tuck, discreet drops (Millie is
  female: she squats, no leg lift).
- Note on looks: procedural flourishes polish the prototype; the Crash-
  ish visual ambition is the Phase 2 track (3D spike + real art), not
  more vectors.

## 2026-07-11 — the parallel bike lane (settings catalog no. 3, in the base walk)

- The world got wider: sidewalk, curb, a marked bike lane running the
  whole route, and a narrow far shoulder holding two hydrants and a kebab
  - crossing the lane is now a voluntary risk/reward decision, and a bad
  fling can deposit the human into bicycle traffic.
- bike.gd generalized into a rider that travels any direction (crossing
  bikes, lane commuters, scooter kids share it; art rotates to heading).
- Fast commuters hold their line and knock the human flat. Wobbly kids
  on slow scooters weave inside their band, swerve at random, and
  sometimes ride on the sidewalk itself; they bump ("sorry!") instead of
  wrecking. Kids never award close-call bones, commuters still do.

## 2026-07-11 — whirl v3 (pure tangent), pee anywhere, the test tube

- Fixed the stuck-behind-the-pole fling: launching "toward the dog" often
  meant launching through the pole (the dog is usually on its far side).
  Release is now along the PURE tangent, which geometrically cannot hit
  the pole; aiming comes entirely from release timing (the orbit holds
  until the tangent sweeps toward the dog). Minimum 1.25 laps so even
  single-wind whirls build speed. Removed the early-release path that
  produced randomly aimed flings.
- Pee rework: pee anywhere by planting with a slack leash (bracing a taut
  leash is not peeing). Spots (hydrants/poles) score +3 via the same pie
  timer as sniffing; stray breaks just leave a puddle. The tank lasts
  ~9 breaks and refills very slowly; a FULL bladder makes the dog waddle
  12% slower - empty it. New test-tube meter widget (pee_tube.gd).

## 2026-07-11 — whirl v2 (pulley + bungee), dog holes, the life of a dog

- Whirl reworked per playtest: it releases reliably now. The orbit runs
  for exactly as many turns as the rope was wound (the rope free-slips
  underneath so grip can never arrest the unwind - the old bug where the
  first whirl left the human half-wound and un-flung). Pulling harder
  spins it up faster (leash as pulley). Release waits for the tangent to
  swing toward the dog, then launches at them, floor 320 px/s, up to
  900 - fast flings sail PAST the dog, whose turn it is to get yanked
  along (the bungee). Screen shake on release.
- Dogs are not exempt from open holes: manholes and cellar doors now
  swallow the dog too (tumble in place, scramble out, brief immunity).
- Bodily functions as mechanics, kept family friendly: PEE meter on the
  HUD - hold plant beside an unmarked hydrant or pole to mark it (+3
  bones, costs a third of the tank, slowly refills). Once per walk the
  urge strikes ("GOTTA GO!"): find a safe moment and hold plant 2.5s to
  squat (+5 bones, the human stops to bag it); ignore it for 35s and the
  dog decides for you at whatever moment fate picks.

## 2026-07-11 — the whirl (Bugs Bunny physics)

- A human wound around a nearby pole who keeps getting pulled no longer
  jams against it: they WHIRL - a choreographed accelerating orbit with
  spin animation, speed lines and a "wheee!" bubble. The rope honestly
  unwinds as they orbit; the moment it runs out they are flung along the
  tangent with an exaggerated boost ("AAAA"). Timeout fling at 2.5s as a
  safety valve. The rope stays honest; the human's RESPONSE is the cartoon.
- Signed winding plus a human-end winding measure in leash.gd decide when
  to whirl and which direction unwinds.

## 2026-07-11 — the rope IS the constraint

- Threw out wrap bookkeeping entirely (three generations of pivot/angle
  tracking all desynced from the visual rope, producing detached-but-
  magnetic poles). The visible verlet rope is now the gameplay physics:
  segment-vs-circle pole collision (point checks tunneled under stretch),
  stick-slip friction (coils grip at low tension, slip off under hard
  pulls), forces along the rope's end tangents so a wound human flings
  in an arc. Tetherball is now a real, tested mechanic.
- tests/test_wrap.gd rewritten for the rope model: stretch measurement,
  spiral-in winding, taut coil cinching with curved pull, slip-off
  regression guard (the magnetic-owner bug), NaN guard.
- Idle dragged dog barely brakes (braking was silently cancelling the
  human's drag forces - the "owner can't move me" complaint).
- New design pillar: the leash is an honest rope, exaggerated. Fling as
  a core verb.
- Settings catalog: 20 settings with signature features in PROJECT.md
  (bike-lane boulevard, beach boulevard, park with ducklings, forest
  trail with no signal, station concourse...). Main menu added to
  Phase 2.

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
