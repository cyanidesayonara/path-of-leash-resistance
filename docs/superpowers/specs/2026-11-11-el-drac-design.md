# El Drac (Boss 2) design

## Context

Walk 21 of the campaign is El Mosaic (`guell`): Park Güell's dragon stair,
hypostyle hall, and serpentine plaza (`systems/mosaic.gd`,
`world/level_build.gd`). A decorative trencadís salamander already sits on the
stair fountain at `LevelBuild.MOSAIC_SALAMANDER`. `docs/BOSSES.md` names that
statue as Boss 2, El Drac — quick, low, slippery — still marked "later".

Boss 1, El Mamut (`systems/boss_mamut.gd`, `tests/test_ciutadella.gd`,
`intro/film_mamut.gd`, `intro/film_mamut_win.gd`), is the template for the
shared statue-boss grammar: wake film, human hold, three parts, real-rope
counters, last-stand leg tie, nose bark, victory film.

## Goal

Ship El Drac on El Mosaic so a player who has fought the mammoth can read the
fight, while the dragon's own moves feel like a fountain: fast rear whip,
soaking jet, a column-hall slither, a belly slide down the steps, and a happy
clear fountain when settled.

## Decisions already locked

- The existing salamander **is** El Drac. Decorative draw remains until wake;
  the boss then owns him.
- Goals stay at exactly 15. Drop `drink`, `hi`, `tofu`. Add `drac_dodge`,
  `drac_column`, `drac_trip`. Keep `spell`, `jamon`, `clock`. Slide, boop, and
  settle end the fight and are **not** goals (same as Mamut).
- Column bind uses the **real rope**: a taut wrap on a hypostyle Doric pole
  across his path cinches him. No separate pivot bookkeeping.
- Architecture mirrors Mamut: `systems/boss_drac.gd` as a `RefCounted` state
  machine on `main.drac`; `systems/mosaic.gd` keeps the walk and hooks hold /
  tick / draw / surfaces. There is no `systems/bosses.gd` in the tree —
  registration follows Mamut's real hooks.

## Non-goals

- Els Lleons or any other boss.
- Moving El Mosaic in `CAROUSEL` / star gates.
- Rewriting the walk's scenery beyond what the fight needs (hide static
  salamander when awake; surface overrides for puddles and tile chips).
- Inventing a new boss registry file.
- Copyrighted Gaudí likeness beyond the project's existing cartoon salamander.

## Architecture

### Files

**Create**

| File | Role |
|---|---|
| `systems/boss_drac.gd` | Fight state machine, counters, draw, banners |
| `intro/film_drac.gd` | Wake film: *The Steps at Noon* |
| `intro/film_drac_win.gd` | Victory film: happy fountain + rainbow mist |
| `tests/test_drac.gd` | Headless fight + registration coverage |

**Modify**

| File | Role |
|---|---|
| `main.gd` | `drac` instance; counter flags; tick / draw / leg / in-fight hooks beside Mamut |
| `systems/mosaic.gd` | Hold line; tick/draw forward; skip static salamander when boss is awake |
| `systems/goals.gd` | Replace three goals; define the three new defs |
| `world/level_build.gd` | Build `main.drac`, `register_legs`, prize if needed |
| `autoload/sfx.gd` | Ceramic tile click; jet spit (procedural) |
| Film / chase registries | Same places Mamut is listed (`tools/intro_render.gd`, `tests/test_chase_film.gd`, etc.) |
| `docs/BOSSES.md` | Status column for El Drac: `later` → branch name / PR when shipping |

Track any new `.gd.uid` files Godot writes.

### Main state

```gdscript
var drac: RefCounted = null
var drac_dodges := 0
var drac_wound := false   # column bind
var drac_tripped := false
var drac_bowled := false
var drac_booped := false
var drac_slid := false
var drac_settled := false
```

Frame order stays: `dog.tick` → `human.tick` → `_apply_leash` → `leash.tick`,
then the walk / boss `tick_state` from main (never `_physics_process` on the
boss).

### Arena (reuse authored geometry)

| Constant | Source / meaning |
|---|---|
| Plinth | `LevelBuild.MOSAIC_SALAMANDER` |
| Stairs | `MOSAIC_STAIR_Y0` … `MOSAIC_STAIR_Y1` |
| Hall | `MOSAIC_HALL_Y0` … `MOSAIC_HALL_Y1`, `MOSAIC_HALL_COLS` / `ROWS` |
| `HOLD_Y` | Just short of the salamander; `tut_hold_y` until `CONTENT` |
| `WAKE_Y` | Dog crosses this to start `AWAKEN` |

Autowalk is never held; the boss is a ghost to it (Mamut/Gat contract).

## State machine

```
IDLE → AWAKEN → PROWL ↔ TAIL_WHIP | JET
         ↓ (hp < 50)
       ENRAGE → PROWL ↔ TAIL_WHIP | JET | SLITHER
         ↓ (hp ≤ 0)
       RETREAT → STAND → WRAPPED → SLIDE → CONTENT
```

Also: `STUNNED` after column bind, trip, or bowl (boop available while dazed
in fight; last-stand boop after the slide).

Telegraphs are ~0.8 s, drawn as a rear sector (tail) or lane (jet), matching
the owner-event telegraph contract.

### Part one

- **Tail whip:** fast arc behind him. Standing in the rear cone when it
  strikes costs a hit. A clear miss awards dodge damage and increments
  `drac_dodges`.
- **Fountain jet:** pressurized lane. Hit pushes dog and human back and
  leaves a soak puddle (`Surfaces.S.WATER` override) for a few seconds.

### Part two (below half HP)

- Enrage (eyes go fierce; banner updates).
- **Slither:** S-curve through the hypostyle columns; sheds trencadís chips
  that leave brief slippery patches (`MUD` feel).
- **Column bind:** during `SLITHER` only — if the leash is already wrapped on
  a hall Doric column and a taut segment crosses his path, he winds himself
  up: stun, damage, `drac_wound = true`. He has no separate charge move (the
  mammoth owns charging; see `docs/BOSSES.md`).
- **Leash trip** across his path while he is moving in part two:
  `drac_tripped` (goal). Same real-rope taut check as Mamut's trip, without
  requiring a column wrap.
- Bowling (human flung into him) remains a counter, not a goal.

### Part three (last stand)

- Retreat to the steps / fountain plinth; defensive jets while she ties
  three of four legs within `LEG_MEMORY` (Mamut's leg-pole furniture pattern).
- Three legs → `WRAPPED` → **SLIDE**: he slides down the grand steps on his
  belly (`drac_slid`).
- Bark on the nose → happy clear fountain with a rainbow arc; `drac_booped`,
  `drac_settled`; release `tut_hold_y`; play win film once via
  `FilmPlayer.should_play`.

## Look and audio

- Draw with `ShapeBatch` only: batched trencadís polygons/quads for body and
  shed chips; no unbatched per-shard circle spam.
- Time-based visuals use `AnimClock.msec()`, never `Time.get_ticks_msec()`.
- Banner capitals: e.g. `WATCH THE TAIL!`, `WATCH THE JET!`,
  `WIND HIM ROUND A COLUMN`, `TIE UP HIS LEGS  2/3`.
- Sfx: ceramic clicking on wake ripple; jet spit; existing splash / bark /
  whoop where they fit.

## Films

### Wake — `intro/film_drac.gd` (*The Steps at Noon*)

Monumental stairs and balustrades; tourists; fountain water sputters and
stops; tiles ripple with ceramic click; amber mosaic eye opens and blinks;
FilmKit pair grammar (hear it, look back, plant between human and statue,
title card). Clean skips; no hang headless.

### Victory — `intro/film_drac_win.gd`

He rests happily on the plinth fountain, clear water and soft rainbow mist;
the pair continues up the terrace; title card. Triggered from `CONTENT` once.

Register both in the same film lists Mamut uses (`tools/intro_render.gd`,
`tests/test_chase_film.gd`).

## Goals

`systems/goals.gd` `LEVEL_GOAL_IDS["guell"]` becomes:

```
mark, sniff, phone, paws, bag, fetch,
drac_dodge, drac_column, drac_trip,
fling, combo, prize, spell, jamon, clock
```

Exact 15. Proposed defs (must pass `tests/test_goal_text_fits.gd`):

| Id | Text | Target | Source |
|---|---|---|---|
| `drac_dodge` | `Dodge the dragon %d times` | 4 | `m.drac_dodges` |
| `drac_column` | `Wind the dragon round a column` | 1 | `m.drac_wound` |
| `drac_trip` | `Trip the dragon with the leash` | 1 | `m.drac_tripped` |

Voice: sentence case instructions from the dog's side; "leash", "your human",
Catalan place names elsewhere unchanged.

## Testing

`tests/test_drac.gd` follows `tests/test_ciutadella.gd`:

1. Registration: `guell` goals size 15, defs present, level check clean,
   `main.drac` built, four leg poles registered.
2. Wake: dog past `WAKE_Y` → `AWAKEN`; human `tut_hold_y == HOLD_Y`; after
   awaken → `PROWL` and static salamander suppressed.
3. Tail whip: hit in rear cone increments hits; clear dodge increments
   `drac_dodges` and lowers HP.
4. Jet: hit pushes / soaks; puddle surface override present for a duration.
5. Phase 2: damage below half → `ENRAGE`; column wrap + taut path during
   slither → `drac_wound` and stun.
6. Last stand: force retreat; tie three legs → slide → boop → `CONTENT`,
   hold cleared, settle flags set.

Run:

```
godot/Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_drac.gd
```

Expect 0 failures. Also keep `test_goal_text_fits` green for the new strings.

## Implementation notes

- Prefer copying Mamut's public surface (`tick_state`, `in_fight`,
  `register_legs`, `is_leg_index`, draw helpers, film constants) and renaming
  moves, rather than inventing a parallel API.
- Slippery chips and jet puddles are temporary surface overrides queried from
  the boss (or mosaic `surface` hook), not new permanent patches in
  `level_build`.
- WIP: player-facing; needs a Feel card on the PR. Acceptance board was clear
  when this design was written; re-check before merge if the limit is near 5.

## Feel card (for the eventual PR)

1. `--level=guell`: walk up to the salamander; wake film plays once; your
   human will not pass until he is settled.
2. Stay behind him through a telegraphed tail whip — get hit; dodge clear —
   dodge counts.
3. Eat a fountain jet — pushed and soaked; puddle lingers briefly.
4. Below half: slither in the hall; wrap the leash on a Doric column and let
   him run into it — he binds and dazes.
5. Last stand on the steps: tie three legs, watch the belly slide, bark the
   nose — happy fountain, win film, human walks on.
