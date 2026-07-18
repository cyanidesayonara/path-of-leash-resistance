# Path of Leash Resistance — development plan

Tagline: "You are the dog. Go touch grass."
Retitled July 2026 after the trademark check found "Touch Grass" taken
on Steam (LionsHead Development, trademark claimed). "Path of Leash
Resistance" searched clear; verify at EUIPO/USPTO before the store page.

## The game

You are a dog. Your human is glued to their phone and walking on autopilot.
The leash connects you. Get them through the world in one piece while
sneaking in as much dog business as possible.

## Design pillars

Every feature must serve at least one. If it serves none, cut it.

1. **The comedy is the mechanic.** Physics and situations produce the jokes;
   nothing is funny by cutscene decree.
2. **Temptation vs duty.** Score and joy live on one side, safety on the
   other. Every level is a negotiation between them.
3. **The human is a payload, not an AI.** Dumb, heavy, predictable,
   telegraphed. Never unfair, never smart.
4. **Soft failure.** Slapstick consequences, dense checkpoints, instant
   retry. The phone breaks, nobody dies.
5. **The leash is an honest rope, exaggerated.** Winding, cinching,
   tetherballing and flinging the human in an arc are core verbs -
   realistic enough to be predictable, cartoonish enough to be funny.
   Doing it idly should be fun and give slightly different results every
   time; harder puzzles may REQUIRE a good fling.

## Release plan (living document, one theme per release)

- **v1.0 - shipped 2026-07-13.** Four walks (Boulevard, Park, Passeig
  Maritim, El Mercat), day/night, rope leash with tetherball whirl,
  rotating quests, chore chain, two owners, Millie and Tofu cameos,
  touch controls, itch web release.
- **v1.1 - shipped.** Presentation and persistence: onboarding menu,
  title marquee (later removed), local records + lifetime bones wallet,
  HUD overlay makeover, swimming, art mock 2.0.
- **v1.2 - shipped.** Progression and weather: star-gated walk unlocks
  (Tony Hawk style), selectable weather (clear/rain/wind), bigger menu
  type. Discoverable + timed quests still to come (next).
- **v1.3 - shipped.** The Walk Home: out -> off-leash freedom romp ->
  walk home round-trip structure. Turbo/zoomies energy meter. First
  discoverable timed quest (the fetch challenge). Attract/CI autowalk bot.
- **v1.4 - shipped.** The Dog Park: NPC dog-walker pairs on the path,
  leash-vs-leash TANGLING (emergent from rope-vs-rope collision), free
  dogs to romp with and greet in the off-leash area, tangle + say-hi
  quests.
- **v1.5 - shipped.** The Daily Walk (seeded, shared, daily best) and
  the cosmetics shop (collars + bandanas, spent from the bones wallet).
- **post-v1.5 hardening (shipped, on main).** NPC dog-park lifecycle
  (pairs persist into the park, reserve slots, recall home), shared
  bypasser routing, bridge steering, distinct tangle events, traffic-
  free freedom, mixed walker directions, visible bandanas + wardrobe
  preview, reusable NPC dog/owner appearance variety.
- **v1.6 - shipped.** Real fetch retrieve loop (owner throws, dog brings
  it back to the owner) and the off-leash area dressed as a proper dog
  park (fence, benches, gate, play patch).
- **v1.7 - shipped.** Tony Hawk-style per-level goal lists (~10,
  persistent, goal-milestone stars), the unique hazardous prize per
  level, and bring-Tofu-home.
- **v1.7.1 - shipped.** Playtest fixes: Tofu redesigned to be herded
  home along a chain of hiding spots on the walk back (not a mat in the
  off-leash area, where she'd never wander); quest panel auto-sizes;
  the owner no longer wedges on a parked van during the poop-bag toss.
- **v1.8 - shipped.** Combo / multiplier meter (Tony Hawk Phase A):
  scored actions chain into a multiplier that banks style points + bonus
  bones; a hit bails the chain. See Future systems for Phase B (the
  triggered combo challenge).
- **v1.9 - shipped.** Outrun the street sweeper: a short chase that can
  strike on the walk home (slow devourer, oblivious owner, drag the dead
  weight to safety). The first cut of the chase mechanic; dedicated
  chase levels and feel tuning still to come (see Future systems).
- **v1.10 - shipped.** Rainy Day (El Aguacero: forced downpour, storm
  drains, umbrella crowd), other owners throw (intercept a neighbour's
  ball for "shared! +4"), and a shareable daily results card. Follow-ups
  noted in Future systems (bespoke rain geometry; NPC dogs fetching
  their own thrown ball).
- **v1.11 - shipped.** Combo challenge (Tony Hawk Phase B): a bystander
  dares you into a bounded trick window on the walk out; hit the target
  for bones + slow-mo, no penalty for missing. Combo system now complete
  (Phase A meter + Phase B challenge).
- **v1.12 - shipped.** The bolt chase: the fast, owner-panics threat
  variant (owner sprints for home dragging you; the leash flips from tool
  to tow-rope). Second cell of the threat grid proven. Home-leg chases
  now coin-flip sweeper/bolt.
- **v1.13 - shipped.** El Gotic (old town alley): tight pinched channel,
  laundry lines, lanterns, and the wall-cat signature (perched, smug,
  shooed with a bark - a temptation you can never actually catch).
  Reuses the market layout for now; bespoke geometry + stairs a later
  pass.
- **v1.14 - shipped.** Snow: a fourth weather with ice-slide physics
  (dog and owner both skate), selectable on any walk. Added a --weather=
  test hook. Winter as a cross-cutting mechanic rather than a one-off
  level; snow piles / salt patches / sledding kids remain level material.
- **v1.15 - shipped.** Carry / delivery missions: pick an item up in
  your mouth and tote it to a marked drop-off (boulevard newspaper, El
  Mercat oranges). A calm objective type to offset the chases. Follow-up:
  drop-on-hit tension, more levels, fragile items.
- **v1.16 - shipped.** "No signal" owner event: the phone addict loses
  their bars and stops to hold the phone aloft, rooting themselves - the
  owner's obsession as a gameplay beat. A cross-cutting rare event.
- **v1.17 - shipped.** Web-perf pass #1: decoupled the world redraw from
  the frame rate (world is drawn in world space, so camera scroll needs
  no redraw). World now redraws ~30fps for its animations; ~70% less draw
  CPU. Next: gate per-entity redraws, trim leash solver.
- **v1.18 - shipped.** The rescue chase (fast + scares both): a fire
  engine emergency where you and the owner sprint home together. Completes
  the chase threat grid (sweeper / bolt / rescue).
- **v1.19 - shipped.** Web-perf pass #2: gated entity redraws (freedogs,
  pairs, critters, Tofu) and NPC-pair leashes to ~30fps, keeping movement
  smooth via the transform and the player leash full-rate. Halves entity
  draw calls. Next perf: trim the leash solver; measure in-browser.
- **v1.20 - shipped.** El Bosc (forest trail): a no-signal woodland walk
  where the owner keeps stopping to hunt for bars, with mud, a stream and
  squirrels. Reuses the park layout for now.
- **v1.21 - shipped.** Web-perf pass #3: leash solver trim - skip the
  collision scan on open stretches, and 14->11 solver iterations (wrap +
  tangle tests still pass). Draw and physics hot paths all now trimmed;
  remaining perf work is in-browser measurement on the actual web build.
- **v1.22 - shipped.** L'Estacio (station concourse): a moving walkway
  that carries you toward the platforms (boost out, shove home) - the
  first "the ground moves you" mechanic. Reuses the boulevard layout.
- **v1.23 - polish + tuning.** Playtest feedback pass: chase/combo feel,
  level difficulty, and bespoke geometry for the reused-base walks
  (El Aguacero, El Gotic, El Bosc, L'Estacio).
- **v2.0 - The Product.** Watercolor art integration, sound and music
  pass, trademark verification, Steam page, Next Fest demo.
- Every release also ships: mechanics tuning from playtests, at least
  one new rare event, and a CHANGELOG entry. Tags on every release.

## Roadmap

### Phase 1 — Find the fun (now, 2-6 weeks of evenings)

Iterate the 2D prototype until the core loop is fun for 10 minutes.

- [x] git init, first commit of the prototype
- [x] Pole wrapping as a real constraint (leash pivots around poles, not
      just visually) — this is where the puzzle design opens up
- [ ] Leash weight tuning round 2 (after wrap physics changes the feel)
- [x] 2-3 more human event types (sits on bench, walks backwards filming,
      stops for selfie in the worst spot)
- [x] 1-2 more hazard types (open cellar door, cafe terrace)
- [x] Basic juice: slow-mo flash on a last-moment save, save streak counter
- [ ] Web export, unlisted itch.io page, watch 3-5 people play

**Exit criteria:** a friend plays unprompted, laughs at least once, and
retries after failing. If that doesn't happen, change mechanics, not art.

### Phase 2 — Vertical slice (2-3 months)

One level at shippable quality. Proves the production pipeline.

- [ ] 2D vs 3D decision: one-week Godot 3D spike (capsules, rail camera,
      ragdoll human) compared head-to-head against the 2D build
- [ ] Character art: style test with girlfriend first, then dog + human
      sheets (front/side/back, key poses). Written commission agreement.
- [ ] Environment style matched to her characters (asset packs recolored,
      or drawn)
- [ ] Sound pass: barks, yanks, phone noises, one music track
- [ ] One complete walk: intro, three setpieces, finish, star rating
- [ ] Main menu / walk-select screen (needed once there is a second walk;
      see Settings catalog)

**Exit criteria:** a 3-minute level someone would screenshot voluntarily.

### Phase 3 — Market test

- [ ] Real name locked (Steam search + USPTO/EUIPO + domain check)
- [ ] Steam page with GIF-first trailer ($100)
- [ ] Devlog clips / short-form video of the funniest physics moments
- [ ] Demo into Steam Next Fest

**Exit criteria:** wishlist numbers decide whether this goes to full
production or stays a beloved demo. Both outcomes are fine.

### Phase 4 — Production

15-25 levels, escalating settings (suburb, market, construction site,
festival, winter ice, night walk). The human's arc: gradually looks up from
the phone; final level the battery is dead and the walk is just a walk.

## Open questions

- 2D top-down forever, or low-poly 3D with rail camera (Phase 2 spike decides)
- Leash upgrades: retractable shipped as a HUMAN-owned hazard (random length
  changes); bungee and chain variants remain progression-phase material
- Dog breeds as difficulty/playstyle — production-phase question
- Difficulty identity: current build is easy. Leaning: casual to *finish*,
  hard to *master* (see Meta below) rather than picking one audience.

## Meta / retention (Phase 2+ leanings, not commitments)

- Casual vs puzzle: don't choose. Base walks stay forgiving (soft fail,
  dense checkpoints); challenge lives in optional layers — star ratings,
  par times, save streaks, "perfect walk" (phone untouched). Bespoke
  puzzle-heavy "trial walks" as a separate late-game track if wanted.
- Daily-walk hook: positive-only. A shared daily-seeded walk (same layout
  for everyone that day, compare scores) fits the fiction perfectly and is
  the modern comeback pattern. Explicitly avoid guilt mechanics: the dog is
  never sad/anxious because the player was away — punishing absence reads
  as F2P manipulation and poisons the cozy audience. The dog is always
  thrilled you came back. That IS the dog experience.
- Progression: mostly horizontal, not power. Bones buy cosmetics (collars,
  bandanas), new breeds (playstyle variants: pull strength / speed / size),
  leash types (retractable, bungee, chain), and a home/park hub that fills
  with trophies. A photo album of best saves doubles as share bait.

## The shape of a walk (design direction, July 2026 playtesting)

A dog walk is never A to B - you always come home. The eventual level
template, replacing the finish line:

1. **The walk out** - the corridor: hazards, temptations, quests.
2. **The destination as the reward** - dog park, dog beach, meadow at
   the corridor's end. Off-leash, let loose, run and bark with other
   dogs; soft minigames (smell every dog, ball catch, fetch).
3. **The walk home** - the same corridor southbound with fresh spawns,
   tired-dog pacing, end-of-walk light.

## Settings catalog

Twenty settings, each with a signature feature that only it has, drawing
from a shared obstruction library (bikes, scooters, crowds, tables,
poles, water, dropped food). Production picks the best ~15; new ideas
get appended, not squeezed in. Multiple settings imply a main menu /
walk-select screen (Phase 2 item).

Content tiers per setting (the walk-variety pattern): COMMONS every run
(traffic, bins, hydrants, squirrels), RARES some runs (the cat, pigeon
flocks, setting-appropriate visitors), and ONE UNIQUE signature per
setting. Every level should be packed; rarity is what makes runs
memorable.

1. **Quiet suburb** (tutorial) — sprinklers, garbage bins, one lone cyclist
2. **Busy city sidewalk** — crowds of fellow phone zombies, deliveries, cafe terraces
3. **Bike-lane boulevard** — marked bike lane running PARALLEL to the
   sidewalk (continuous hazard, not a crossing); fast commuters plus
   wobbly kids on slow scooters with erratic trajectories
4. **Beach boulevard** — sand side (slow going, digging bonus, sunbathers,
   sandcastles) vs restaurant side (tables, chairs, A-frames); seagulls
   steal unattended food
5. **City park** — pond (phone hazard supreme), bridge, a line of
   ducklings crossing (moving no-go zone), squirrels (maximum temptation),
   off-leash meadow where the rules invert
6. **Farmers market** — stalls, crates, dropped produce heaven, fishmonger
7. **Construction detour** — planks, cones, wet cement (paw print
   evidence), swinging crane loads, workers on kebab break
8. **Rainy day** — puddles, umbrella forest blocking sightlines, storm drains
9. **Winter ice** — sliding physics for both ends of the leash, snow
   piles, salt patches the dog refuses to walk on, sledding kids
10. **Night walk** — visibility limited to the phone's light cone,
    raccoons, weaving drunks (adult kid-scooters)
11. **Dog park social** — other dog+owner pairs = leash-tangle chaos,
    fetch crossfire, a rival retractable-leash owner
12. **Street festival** — parade, balloon vendors, stage cables, food stalls
13. **Old town alleys** — narrow, stairs, wall cats, laundry lines,
    scooters squeezing through
14. **Harbor marina** — piers, cleats and ropes (winding heaven), fish
    crates, gulls, gangplanks over water
15. **Schoolyard at recess** — kids everywhere on scooters and skates,
    balls bouncing through, crossing guard
16. **Shopping street on sale day** — shopping bags, sandwich boards,
    automatic doors, carried mannequins
17. **Forest trail** — roots, mud, streams, rabbits; the owner has NO
    SIGNAL and keeps stopping to hold the phone up for bars (setting-
    specific event)
18. **Halloween night** — trick-or-treaters, scary costumes, candy
    everywhere the dog must NOT eat (chocolate: the anti-snack)
19. **Station concourse** — rolling suitcases as moving tripwires,
    luggage carts, a moving walkway (conveyor physics), announcements
    stop the owner dead
20. **Christmas market** — mulled-wine crowds, ice patches, sausage
    stands, the tree lot (a forest of windable poles), fairy-light cables

## Future systems (noted, not scheduled)

- Other dog+owner pairs sharing the walk: two leash ropes that can
  TANGLE with each other, knotting both parties into a four-body
  physics argument. The rope is already a self-contained component;
  the tangle is rope-vs-rope collision plus a lot of playtesting.
  Likely the flagship mechanic of the dog park setting.
- Carry missions (SHIPPED v1.15): Millie holds an item in her mouth and
  totes it to a drop-off (newspaper on the boulevard, oranges at the
  market). Follow-ups: drop-on-hit tension, fragile items, a ball-catch
  minigame, more levels.
- Level editor: data-driven levels FIRST (due at setting four), which
  makes an internal editor nearly free and player-facing editing a
  realistic post-launch option. Not before.
- Character creator: two preset owners exist (HIM/HER); creator later.
- "Bring Tofu home" quest (shipped v1.7, redesigned v1.7.1): an inside
  joke - the real Tofu is an escape artist. She turns up loose on the
  walk home and you herd her south from hiding spot to hiding spot (she
  keeps her respectful distance and relocates; you press, you do not
  grab) until she reaches home. A repeating goal on every level.
- Combo / multiplier system (Tony Hawk lineage). Phase A SHIPPED v1.8:
  scored actions chain into a multiplier that banks style points + a
  bones bonus; taking a hit bails the chain. Phase B SHIPPED v1.11: a
  bystander dares you into a bounded trick window on the walk out; hit
  the target for bones + slow-mo, miss for nothing. Follow-ups: vary the
  dare per giver/level (a "tangle N walkers" variant, a squirrel dare),
  and a "land a x8 combo" / "beat the challenge" per-level goal to tie
  both into progression once playtested.
- Chase / outrun mechanic (homage to Crash Bandicoot's boulder runs and
  Indiana Jones): something CONSUMES the path behind you and you have to
  keep ahead of it. First cut SHIPPED v1.9 as a short home-leg chase
  (the street sweeper). Two tiers going forward:
    - DEDICATED chase levels designed around it, with their own quests
      (survive, save the owner, grab X while fleeing, beat a ghost).
    - SHORT in-level chases (shipped form) triggered by an in-world
      cause - for now a seeded chance; better would be a real trigger
      (you knock over a barrier, a siren starts, the tide turns).
  The threat is a 2-axis grid - SPEED (slow/fast) x WHO IT SCARES (you /
  the owner / both) - and mixing those gives distinct feels from one
  mechanic:
    - slow + scares only you (the sweeper, shipped): owner dawdles
      oblivious, you drag the dead weight south. Owner-is-payload turned
      lethal.
    - fast + scares the owner (SHIPPED v1.12 as the "bolt": a red truck):
      the owner bolts and drags YOU - the leash flips from tool to
      problem, you're water-skiing behind a panicking human.
    - both (SHIPPED v1.12... v1.18 as the "rescue": a fire engine): a
      brief cooperative sprint, the one time you and the owner want the
      same thing. The threat grid is now complete.
  In-fiction devourers by setting: street sweeper (city), incoming tide
  (beach), snowplough (winter), runaway parade float (festival). Own
  failure mode (caught = eaten, soft slapstick), not the usual soft-fail.
- Swimming (shipped v1.1 in the park pond, expandable): Millie loves
  water and paddles happily; the owner is dragged in to wade reluctantly
  with the phone held high; Tofu will not go near it. Beach sea and any
  future water get the same treatment.
- 3D version (the "GTA: Chickenbone V online" north star): a rebuild,
  not a port. Staying in Godot keeps the engine, GDScript, and - most
  importantly - the design and systems (walk loop, quest/goal framework,
  Game save/economy, tuning knowledge) transferable. Almost nothing else
  is: the _draw() vector art, the 2D verlet rope, and the 2D physics all
  get rewritten, and the rope's wrap/tangle bookkeeping is genuinely
  harder in 3D. It also needs actual 3D models (the watercolor art plan
  is 2D). So it is a sequel-scale effort that only begins AFTER the 2D
  game is a finished, shipped product - not a near-term milestone. The
  Phase 2 one-week 3D spike (capsules, rail camera, ragdoll human) is
  the cheap experiment that tells us whether the leash even reads in 3D
  before any of that is committed.
- Rainy Day follow-ups (shipped v1.10 on the boulevard layout): give
  El Aguacero its own bespoke geometry (a plaza / arcade that reads as
  distinct from The Boulevard), make the storm drains a signature
  interaction beyond "lethal hole" (a current that drags the ball/prize
  toward them, puddles the dog wants to splash), and let the umbrella
  crowd actually shuffle and jostle rather than stand still.
- Other-owners-throw follow-up (shipped v1.10, main-side): the NPC's own
  dog should visibly fetch its owner's ball when the player does not, so
  interception feels like stealing the fetch rather than the only fetch.
  Deferred to avoid coupling the delicate parked-pair lifecycle.
- Performance / engine ceiling (profiled July 2026): natively the game
  holds ~100fps with no drops even at peak entity counts, and the leash
  verlet costs ~0.1ms/frame - the physics and algorithms are NOT the
  bottleneck. The choppiness seen in play is the WASM web build (itch),
  which runs GDScript and Godot's renderer 2-5x slower than native.
  Godot 2D itself can take this game far; the practical ceiling is the
  web export's CPU budget. Levers when we invest in a web-perf pass
  (measure in-browser first): cut per-frame GDScript work in _draw and
  the entity draws, coarser leash sampling / fewer solver iterations,
  pooling, and possibly enabling web thread_support (needs COOP/COEP
  headers on the host). Native/Steam has ample headroom; a desktop build
  sidesteps the ceiling entirely. Renderer is already gl_compatibility.
- UI/UX + art to "professional": the biggest lift-per-effort is a real
  art + HUD pass - consistent type scale and spacing, a cohesive palette,
  eased transitions and juice (screen shake, hit-stop, particles are
  partly there), and the girlfriend's watercolor characters/backgrounds
  replacing the procedural vector art. The systems are in place; it is a
  presentation layer, best done once the mechanic set is frozen so art
  is not redrawn. Tracked for the v2.0 "The Product" milestone.
- Uniqueness rule (from playtesting): shared asset library for
  efficiency, but every setting must earn its own look AND at least one
  interaction that exists nowhere else - it gets dull otherwise.
- Onboarding (from a real non-gamer playtest): step-by-step menu
  screens, one instruction each (Tony Hawk style), shipped v1.1. Levels
  intentionally open calm before the chaos - keep that.

## Process

Evenings/weekends project alongside job hunt. One mechanic or task per
session, every session ends with a runnable build. Claude implements,
Santtu directs, tunes, and playtests. Feel decisions are made by hands on
the controller, not in chat.
