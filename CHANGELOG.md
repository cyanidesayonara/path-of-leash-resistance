# Changelog

Append-only session history, newest first.

## 2026-07-18 — v1.12: the bolt chase (fast threat, owner drags you)

- A second chase flavour, the mirror of the sweeper. Where the sweeper is
  slow and the oblivious owner needs dragging to safety, the BOLT is a
  fast red truck that spooks the OWNER witless: they drop the phone and
  sprint for home, and now the leash is a tow-rope you are on the wrong
  end of. Keep up and don't snag, or you get left behind under the wheels.
- Inverts the core dynamic (owner-is-dead-weight becomes owner-drags-you)
  from the same rope, the whole point of the two-axis threat grid.
- A home-leg chase now coin-flips between sweeper and bolt (or force one
  with --chase / --bolt). Tuning knobs in main.gd: CHASE_SPEED_BOLT (205)
  and human.gd PANIC_SPEED (230).
- CI gains a --bolt full-walk traversal.

## 2026-07-18 — v1.11: combo challenge (Tony Hawk Phase B)

- A show-off kid lounging on a bench on the walk out dares you into a
  combo CHALLENGE: land N tricks inside a bounded window ("5 tricks -
  GO!"). Any scored action counts (sniff, mark, say-hi, fetch, boop,
  tangle, fling, save, close call - the same events that feed the combo
  meter).
- The walk stays time-free; only the challenge has a clock, shown as a
  top-centre banner ("COMBO CHALLENGE 3/5 tricks 8s") that warms to red
  as it closes. Hit the target and it pays out bones + a slow-mo flourish
  and the kid cheers; run out of time and it just shrugs - no penalty.
- One dare per walk. Built as a self-contained challenge module + a giver
  node, both kept off the global RNG so the deterministic autowalk stays
  in sync. New regression test; CI runs it, and the attract bot trips the
  dare on every traversal.

## 2026-07-18 — v1.10: Rainy Day + other owners throw + daily card

- New walk: El Aguacero, a permanent downpour (gate 5). Slick pavement,
  gaping storm drains down the middle of the road (lethal open holes),
  an umbrella crowd hunched across the walkway, and the hard-to-reach
  prize sits right on a drain. Reuses the boulevard layout for now;
  bespoke geometry is a later pass.
- Other owners throw: a parked NPC owner tosses a ball you can intercept
  and bring back to them for a shared-fetch bonus ("shared! +4"). One
  neighbour ball in play at a time, re-thrown on return, cleaned up when
  that owner leaves the park. The dog carries one ball at a time now.
- Daily results card: finishing the Daily Walk shows a compact,
  screenshot-friendly summary (date, walk, weather, stars, goals, bones,
  time, best combo) with a one-line share text you can copy to the
  clipboard (C / Y).

## 2026-07-17 — v1.9: outrun the street sweeper (short in-level chase)

- A chase can now strike on the walk home (homage to Crash Bandicoot's
  boulder runs): a street sweeper grinds down the corridor eating the
  path behind you. It's slower than a pulling dog but faster than the
  owner's phone-zombie dawdle, so it never scares the oblivious owner —
  it's on YOU to drag the dead weight south ahead of the brushes.
- Keep moving and you're fine; stop to sniff around (or milk a combo)
  and the gap closes. Get caught — dog or owner — and the walk is over
  (soft, silly game-over).
- Triggered on ~1 in 4 campaign walk-homes for now (mutually exclusive
  with the Tofu herding), or forced with the --chase flag. Tuning the
  feel and building dedicated chase levels come next.
- New self-contained sweeper module + regression test (advance, kill
  line, dawdler-caught vs hustler-safe); CI runs the test and a forced
  --chase full-walk traversal.

## 2026-07-17 — v1.8: combo / multiplier meter (Tony Hawk Phase A)

- Every scored bit of dog business — sniff, mark, say-hi, snack, fetch,
  boop, tangle, fling, nice save, close call — is now a "trick". Land
  another within a few seconds and they CHAIN; the multiplier is the
  number of links.
- A bottom-centre meter shows the running trick string, points and
  multiplier over a draining window bar (warms to red as it closes).
- When the window lapses the chain BANKS: a style score (points ×
  multiplier) plus a bones bonus that scales with the multiplier
  (capped). Single tricks don't count — you need a real chain.
- Taking a hit is a wipeout: it bails the whole chain. Bank-it-safe vs
  push-your-luck for a fatter multiplier is the tension. Existing
  per-event bones rewards are untouched; the combo is bonus on top.
- The results screen reports your best multiplier and total style score.
- New regression test (combo chain/bank/bail/bonus math); CI runs it.

## 2026-07-17 — v1.7.1: fixes from playtest screenshots

- Tofu herding redesigned. She no longer sits on a mat in the off-leash
  area (she'd never wander in there). Instead she's loose on the walk
  HOME: skittish, hiding, and every time you close in she bolts to the
  next hiding spot further south — you press her down the whole chain,
  spot by spot, until she's home. Off-leash mat and its HUD line removed.
- Quest panel no longer overflows its background: the box auto-sizes to
  the number of goals shown.
- The owner no longer gets wedged against a parked van while carrying the
  poop bag to the bin — if she can't make progress for a beat, she just
  lobs it from where she's standing.

## 2026-07-17 — v1.7: Tony Hawk-style goal lists + bring Tofu home

- Each walk now has a fixed list of ~10 goals (up from 3 drawn per run).
  Completing a goal on any run marks it done for that level FOREVER
  (persisted). A repeating core (mark, sniff, phone, paws, bag, fetch,
  Tofu) plus a couple of per-level flavours and the unique prize.
- Stars are earned from goal milestones (3 / 6 / 9 goals = 1 / 2 / 3
  stars), and those stars still gate the next walk. Legacy saved stars
  are never regressed.
- Unique hazardous collectible per level (the "hard-to-reach prize"): a
  glinting pickup somewhere costly — the frisbee across the bike lane
  (street), the ball in the middle of the pond (park), the ball at the
  water's edge (beach), the churro by the open drain (market).
- Bring Tofu home (shipped): the runaway cat turns up lost in the
  off-leash area; herd her onto her mat by the bench (she keeps her
  skittish distance — you push, never grab). A repeating goal on every
  walk.
- HUD shows lifetime "GOALS x/10" plus the goals still open this run;
  the results screen lists what you cleared this run, lifetime total,
  new stars, and any walk unlocked. The daily scores goals per-run
  without touching campaign progress.
- New regressions: bring-Tofu-home herding, and the goal/star math. CI
  runs both.

## 2026-07-17 — v1.6: real fetch + a proper dog park

- Fetch is a real retrieve loop now: the parked owner THROWS the ball
  out ("go get it!"), the dog runs to it, carries it in her mouth, and
  brings it back to the owner to score ("good girl! +3"), then the owner
  throws again. The 30s FETCH goal is now "bring it back N times".
- The return handler already rewards delivering ANY owner's ball
  ("shared! +4"), so neighbourly fetch is wired for when other owners
  start throwing (next step).
- The off-leash area is dressed as an actual dog park: chain-link fence
  with posts and corner poles, an open entrance gate, human benches
  along the fence, a worn dirt play patch in the middle, and an
  "OFF-LEASH DOG PARK" sign.
- The attract/CI bot carries the ball back to the owner too, so the full
  loop still completes deterministically.
- Cuts the release with all the post-v1.5 hardening: NPC dog-park
  lifecycle, shared bypasser avoidance, bridge steering, distinct tangle
  events, traffic-free freedom, mixed walker directions, visible
  bandanas + wardrobe preview, consistent owner label, and reusable
  NPC dog/owner appearance variety.

## 2026-07-17 — reusable NPC owner appearances

- Added six neutral procedural NPC owner profiles with distinct proportions,
  hair, headwear, eyewear, palettes, and phone treatments behind a reusable
  stateless appearance boundary.
- NPC pairs reuse their existing owner-color random draw as the raw profile key,
  preserving exact setup RNG cadence, downstream randomness, and the existing
  dog appearance selection.
- The same defensive owner profile now persists through walking, arrival,
  parking, recall, re-leashing, departure, and resumed walking while the real
  owner, dog, and leash nodes remain unchanged.
- Added real-script catalog, validation, renderer, phone-pixel, RNG, lifecycle,
  node-identity, and parent-Canvas regressions.

## 2026-07-17 — shared NPC dog visual variety

- Added six neutral procedural dog profiles with distinct silhouettes, ears,
  muzzles, tails, coats, and markings shared by free dogs and NPC pair dogs.
- Free-dog profile and animation selection now derive deterministically from
  spawn inputs without consuming global RNG or changing wander behavior.
- Pair dogs reuse their existing dog-color random draw as the profile key,
  preserving setup RNG cadence and appearance through the full park lifecycle.
- Added real-script coverage for profile validation, both caller renderers,
  RNG contracts, lifecycle persistence, bounds, and every profile.

## 2026-07-17 — NPC dog-park lifecycle hardening

- Smoothed bounded arrival, park, recall, re-leash, gate-exit, and route-resume
  transitions while keeping lifecycle state in the persistent NPC pair.
- Integrated reservation, freedom spawning, active-pair caps, arrival
  qualification, home recall, and cleanup through the production `main.gd`
  orchestration path.
- Entering freedom now immediately clears player and NPC rope obstacles, so
  detached leashes cannot leave a one-frame invisible tangle.
- Added production-path coverage for fallback spawning, the three-pair cap,
  three park slots, reservation cleanup, and slot-exhausted walkers continuing
  through the gate without stalling or leaking a slot.

## 2026-07-16 — NPC dog-park traffic lifecycle

- NPC dog-walker pairs now persist through the freedom transition instead of
  disappearing at the gate.
- Arriving pairs reserve distinct fence-side spots, enter with their real leash
  attached, then detach it while the same dog roams inside the park.
- Parked owners wait in place while their dogs mill or investigate Millie
  within hard yard bounds, with no hidden rope samples or tangle collisions.
- Recall is physical: the dog returns before the leash resnaps and becomes
  visible, then the pair walks through a bounded gate waypoint before shared
  obstacle routing resumes.
- Freedom traffic now spawns a sparse mix of arrivals and already-parked
  departures; bikes and scooters remain paused.
- Slots remain held until a departing owner clears the gate and are released
  exactly once on normal departure, unparenting, or deletion.
- Added real pair/leash lifecycle, main slot/orchestration, and updated freedom
  traffic regressions to CI.

## 2026-07-16 — shared bypasser avoidance

- One stateful local route planner now steers vertical riders and NPC
  dog-walker pairs around fixed hazards.
- The fixed catalog includes the park pond and bridge, path poles and
  furniture, benches, hydrants and fountains, performers, vans and stalls,
  manholes, and cellars.
- Each NPC dog and owner take one coordinated side so their honest leash does
  not routinely wrap or slip over trees.
- Connected furniture/tree clusters route around their outer expanded bounds
  instead of trapping bypassers on occupied per-blocker edges.
- Fast bikes, scooters, and pairs use bounded steering, forward-sweep-safe
  spawn placement, stable detours, lane return, and brake or hesitate only
  when genuinely boxed in.
- Pair runtime routing checks the actual owner/dog formation, while immutable
  blocker descriptors are normalized once per route configuration.
- The exact park tree slalom now extends or replans navigation across
  non-touching trees; explicit current, detour, and clear formation paths keep
  the commanded dog transition inside route bounds without extra clearance
  hysteresis.
- Clear-return release now checks every configured blocker and route bounds;
  pair clear targets preserve wander/curiosity while steering to the nearest
  valid route edge.
- Non-daily CI autowalk uses a named pre-construction seed and a fixed-fps
  completion gate, producing a repeatable 120.0-second finish marker.
- Added deterministic planner, rider, and real-pair cluster regressions.

## 2026-07-16 — NPC bridge steering

- NPC dog-walker pairs now steer across the park bridge instead of walking
  through the pond on outbound or homebound routes.
- Their dogs keep wander and curiosity targets on the bridge side near the
  pond, then both return to their original lane after clearing it.
- Added a deterministic real-script regression for both travel directions,
  dog targeting, and levels without ponds.

## 2026-07-16 — consistent owner label

- The walk-details owner label now remains `WALKING:  HIM/HER` after toggling.
- Added a real-script regression for canonical casing and spacing.

## 2026-07-15 — visible bandanas and wardrobe preview

- Bandanas now read as outlined neckerchiefs trailing over Millie's back
  instead of disappearing beneath her head and collar.
- The wardrobe now previews every highlighted collar and bandana on the real
  dog renderer before purchase or equip.
- Added a real-renderer regression for preview overrides, `No bandana`, and
  backward-pointing geometry.

## 2026-07-15 — mixed NPC walker directions

- NPC dog-walker pairs now spawn as an even random mix of head-on encounters
  and ambient same-direction walkers on both legs of the walk.
- Spawn positions shorten to the viewport edge near route ends while preserving
  unbiased oncoming/same-direction selection.
- Added a real-script headless regression covering outbound and home routes.

## 2026-07-15 — traffic-free freedom phase

- Entering the off-leash area now removes active bikes, scooters and leashed
  NPC pairs immediately; rider spawners pause until the home leg.
- Added a real-script headless regression for freedom-phase traffic cleanup.

## 2026-07-15 — distinct leash tangle events

- A continuous NPC leash crossing now triggers one apology, quest increment
  and `TANGLED! +3` reward instead of repeating during the same snag.
- A pair rearms only after half a second fully separated, with a headless
  regression covering sustained crossings, geometry flicker and recrossing.

## 2026-07-15 — critter chase scoring restored

- Squirrels, rats and Tofu now award their chase or boop reward on first
  contact even after they start fleeing; the same critter cannot score twice.
- Added a headless regression test for fleeing contact, Tofu relocation and
  scare-without-contact behavior.

## 2026-07-14 — v1.5: The Daily Walk & Millie's wardrobe

- Daily Walk: first entry in the walk carousel, always unlocked. Its
  level, weather and time are seeded from the date, so everyone gets the
  same walk each day; the RNG is seeded to match layouts. One best per
  day, wiped when the date rolls over. Bones earned still fill the wallet.
- Cosmetics shop ("Millie's wardrobe", open with bark from the walk-
  select screen): spend bones on collars (blue, pink, gold, shimmering
  rainbow) and bandanas (navy, forest, sunny). Equipped items recolour
  her harness/collar and add a bandana at the throat. Owned and equipped
  choices persist. Bones are a spendable wallet now.
- Records file gained cosmetics and a daily-best section.
- Weather/time are locked on the daily (fair for everyone); still free
  to pick on the campaign walks.

## 2026-07-14 — v1.4: The Dog Park (other dogs, tangling leashes)

- Other dog-walkers now share the path: an NPC owner and dog joined by
  their own real leash (a second leash.gd rope), ambling the other way.
- LEASH TANGLING, the long-promised flagship: when their rope and yours
  cross, each becomes an obstacle for the other, so the two ropes drape
  and snarl for real - emergent from the shared verlet+capstan physics,
  no bespoke knot solver. They fuss ("oh - sorry!"), you get gummed up,
  "TANGLED! +3", and you walk it out. New quest: tangle with another
  walker.
- The off-leash area is social now: three free dogs romp there, bolting
  after you to play. Say hi (nose to nose) to any dog - free or leashed -
  for the "say hi to 3 dogs" quest.
- Autowalk/CI still traverses the whole loop clean with pairs on the path.

## 2026-07-14 — v1.3: The Walk Home, turbo, the fetch romp

- A walk is a round trip now. Reaching the gate is halfway: you spill
  into an OFF-LEASH area (leash drops, the owner parks on a bench and
  scrolls), then you turn around and walk HOME - the full corridor
  again, fresh traffic, the owner now heading south. Finish is back at
  HOME, not the gate.
- The freedom romp is the first discoverable timed quest: a FETCH
  challenge (catch the ball 3 times before the 30s timer) with bonus
  bones and a slow-mo on completion. Off-leash, no leash to fight.
- TURBO / the zoomies (hold Shift / RB): a green energy meter beside the
  pee tube. Burn it for a burst of speed - best spent running laps in
  the off-leash area. A walk should always shed some, like pee and poop;
  "burn off the zoomies" is a new quest. Energy does not refill mid-walk.
- Attract/CI bot: --autowalk drives the dog through all three legs
  unattended (unbreakable phone, glides through clutter). CI now asserts
  the whole out->freedom->home->finish loop completes (deterministic via
  --fixed-fps).
- Weather from v1.2 pays off here: rain-slick pavement makes the home
  leg genuinely harder.

## 2026-07-13 — v1.2: progression and weather

- Star-gated progression (Tony Hawk style): each walk awards up to 3
  stars (one per quest completed), saved as a per-walk high-water mark.
  Total stars unlock the next walk - Park at 2, Passeig at 4, Mercat at
  7. Locked walks show on the select screen with their requirement.
  Results screen announces new stars and any walk unlocked.
- Weather is a menu choice now: CLEAR, RAIN, WIND. Rain greys the light
  and makes the pavement slick (less grip); wind tints it dusty and
  shoves everyone gently downwind (the dead-weight owner catches more).
  A screen-space overlay draws the rain streaks / blown grit.
- Menu makeover from playtest notes: bigger, more readable lettering,
  one choice per screen; the left-to-right walker on the title is gone.
  Weather sits alongside owner and time-of-day on the Get Ready screen.
- Logged for next: discoverable in-world quests, some timed (a timer on
  the challenge, never on the walk itself).

## 2026-07-13 — v1.1: presentation, persistence, swimming

- Step-by-step title menu (Tony Hawk style) after a real non-gamer
  playtest got stuck on the option-wall: splash -> choose walk ->
  ready, one instruction per screen. First run sees the splash; later
  runs land on walk-select. A little Millie-tows-owner marquee trots
  across the title.
- Local records + lifetime bones wallet (game.gd, user://records.cfg):
  best bones and time per walk, perfect-walk count, saved between runs.
  Results screen calls out new records; title shows your best.
- HUD overlay makeover: the vitals live in one quiet translucent card
  (phone pips, bone count, pee tube, 5 mark dots, a pulsing status
  line) and the quests in another. The world is chaotic on purpose;
  the UI is calm now. Old scattered labels removed (pee_tube.gd gone).
- Swimming: Millie loves the water and dog-paddles across the park pond
  (wake rings, slower, blissful); whatever is on the leash comes too,
  so the owner wades in reluctantly toward the nearest bank, phone held
  high. No more phone-cracking pond. New park quest: "take a dip". Tofu
  keeps well clear of water.
- Concept art mocks upgraded to v2: gradients, shaped anatomy, paper
  grain, motion arcs, a lost shoe, and Tofu supervising both.
- Release plan added to PROJECT.md (one theme per version through v2.0).
- Logged for the walk-home structure: a "bring runaway Tofu home" quest.

## 2026-07-13 — v1.0.1: Tofu, properly

- Tofu lost the ominous shadow (she likes shade; she is not made of it).
- Spooked, she now skitters in a zigzag to a NEW hiding spot - beside a
  tree, a stall, a parasol, away from the threat - and resettles there.
  Cats relocate; they do not exit. She and Millie are not enemies:
  contact is a friendly "boop! +4" and a dignified relocation.
- Millie's instinct is properly magnetic and tiered now: Tofu pulls
  hardest (500), squirrels and rats hard (420), grounded birds a gentle
  tug (200) - and yes, birds pull now too.
- The passeig has no squirrels. It has RATS (grey, quick, long naked
  tail), and Millie is not picky.
- Tofu cameos in both concept art mocks, supervising from the margins.

## 2026-07-13 — v1.0, the first major version

- Tofu joins the cast: the cat is now white with brown on top, pink
  harness, her own patch of shade, friendly but professionally skittish.
  "Tofu got away +4."
- Every control hint is controller-aware now, including the results,
  game-over, and GOTTA GO prompts (finishing on a pad no longer tells
  you to press R).
- Bigger silhouettes where it counts: park canopies, beach palm fronds,
  street tree crowns, lamp halos, and umbrellas all grew.
- Performance deep scan: one shared riders/critters query per physics
  tick replaces ~30 per-entity scene-tree queries per frame (the
  remaining stutter); HUD strings rebuild at most every 0.15s instead
  of every frame; flattened A-stands stop processing entirely.
- Riders now also steer around parked vans and market stalls; market
  traffic keeps to the middle aisle between the stall rows.
- Full-codebase sweep: no stale references, all four levels pass
  extended 60-second headless runs plus the rope regression suite.

## 2026-07-13 — polish round from playtest

- Street performers have mass now: you walk around a person, not
  through them.
- Market stall wrap circles moved to the stall ENDS - the mid circle
  made the leash snake weirdly across the tabletop. A dragged leash now
  simply lies across the produce, as it would.
- Market lampposts check stall footprints before planting themselves
  (one grew out of a fish stand).
- Terrace glow-up: umbrellas are wide and sit OVER the tables (furled to
  a spike at night, as umbrellas are), beach canopies roll up at night,
  chairs got round seats, legs and backrests, tables got a plate and a
  coffee.
- Pee puddle size now reflects the length of the break. Commitment is
  visible.
- Control hints show keyboard only until a controller is attached
  (listens for connect/disconnect live).

## 2026-07-13 — EL MERCAT (level four), day/night, the realism batch

- Level four: El Mercat. Market stalls with striped awnings line both
  edges (solid bodies, leash-wrappable), dropped produce everywhere
  (eight snacks), stroller crowds and delivery scooters, two performers,
  a fountain in the middle, and the cat is practically guaranteed (fish).
- DAY/NIGHT for every level: toggle with E / B on the title screen. A
  canvas tint does the mood; lampposts now have four bulbs on cross
  arms and a warm halo that earns its keep after dark.
- A-stands are entities now: light, toppleable - bodies knock them over
  and a TAUT LEASH sweeps them flat ("clatter"). Nobody stands them up.
- Vans and stalls are solid rectangles: no more walking over the roof;
  the wrap circles remain so the leash still rounds the whole vehicle.
- Riders (even wobbly kids) now steer around open manholes; dog and
  owner fall in a little less easily (death radius trimmed).
- The pee tank no longer refills for free: drink at fountains, bowls or
  the beach shower, standing still. New quest: "have a good long drink".
- Ducklings flee dogs, humans, and traffic alike; squirrels spook at
  passing riders (cats merely disapprove until nearly run over).

## 2026-07-12 — two tiers of danger, repo renamed

- Repo and folder renamed to path-of-leash-resistance for the fresh
  start (itch page already updated by Santtu).
- Danger now has two honest tiers. Bumps (kids, towels, cones) hurt a
  little; bikes crack the phone; but OPEN HOLES END THE WALK - dog or
  owner going down a manhole or cellar is game over, with an epitaph.
  The pond stays mid-tier (wet, embarrassing, survivable).
- Manholes are guarded by FOUR cones each (cellars two), and cones
  punted into a manhole, cellar, or pond disappear with a "plop" - so
  you can strip a hole of its warnings and then live with what you did.
- Fixed two A-stands that had been placed INSIDE crossing lanes (the
  mystery "grate in the bike path" that the leash kept wrapping).
- Logo mock: fixed overlapping title lettering (the OEEASH incident).

## 2026-07-12 — retitled PATH OF LEASH RESISTANCE, the liveliness pass

- The game is now PATH OF LEASH RESISTANCE ("Touch Grass" is a
  trademarked Steam game). New tagline: "You are the dog. Go touch
  grass." - the meme lives on inside. Repo slug stays touch-grass.
- Kickable traffic cones (cone.gd): bigger, high-contrast, and REAL -
  dog, owner, and riders all send them skittering with spin. Placed at
  every manhole and cellar work site plus loose ones; nobody ever puts
  them back.
- Liveliness pass, all placements with urban logic: a slalom line of
  grated street trees on the Boulevard and a tree slalom in the Park;
  terrace chairs and umbrellas making the cafe properly awful to thread
  a dog through (street and beach); A-stands with today's specials
  ("dogs must be leashed" in the park); parked delivery vans half on
  the walkway (three-circle colliders - the leash wraps around a whole
  van); street performers with hats, coins, and rising music notes.
- Concept art mocks in assets/concept/: logo-mock.svg (title lettering
  with leash spiral and grass baseline) and keyart-mock.svg (the pond
  splash, itch cover proportions) - composition guides for the
  watercolor finals.

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
