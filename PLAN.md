# Touch Grass — development plan

Tagline: "Take the Path of Leash Resistance."
Name pending the Phase 3 trademark/Steam collision check before anything
goes public.

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
- Leash upgrades (retractable, bungee) — wrap physics now exists, viable any time
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

## Process

Evenings/weekends project alongside job hunt. One mechanic or task per
session, every session ends with a runnable build. Claude implements,
Santtu directs, tunes, and playtests. Feel decisions are made by hands on
the controller, not in chat.
