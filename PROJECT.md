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
- **v1.1 - next.** Presentation and persistence: title marquee, local
  records + lifetime bones (the wallet), HUD overlay makeover, art
  mock 2.0 handoff to the watercolor pipeline.
- **v1.2 - The Walk Home.** The shape-of-a-walk structure: destination
  zones at the corridor's end (off-leash romp), the return leg,
  tired-dog pacing. Level five (Rainy Day).
- **v1.3 - The Dog Park.** Other dog+owner pairs, leash-vs-leash
  tangling prototype, ball catch, smell-every-dog. Tofu's expanded role.
- **v1.4 - The Daily Walk.** Seeded daily run shared by all players,
  results card for sharing, lifetime-bones spending (first cosmetics:
  collars and bandanas). Level six (Old Town).
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
- Carry missions: Millie can hold things in her mouth - fetch quests
  per level (take X from here to there), a ball-catch minigame, the
  newspaper delivery. Mouth slot + item nodes; quest pool entries.
- Level editor: data-driven levels FIRST (due at setting four), which
  makes an internal editor nearly free and player-facing editing a
  realistic post-launch option. Not before.
- Character creator: two preset owners exist (HIM/HER); creator later.
- "Bring Tofu home" quest: an inside joke - the real Tofu is an
  escape artist. In the a->b->FREEDOM->b->a walk-home structure, a
  special walk can task the player with coaxing a runaway Tofu back
  (she keeps her respectful distance and relocates; you herd, you do
  not grab). Ties the cat cameo into a real objective.
- Swimming (shipped v1.1 in the park pond, expandable): Millie loves
  water and paddles happily; the owner is dragged in to wade reluctantly
  with the phone held high; Tofu will not go near it. Beach sea and any
  future water get the same treatment.
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
