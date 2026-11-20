# Tarragona walk — design

Walk id `tarragona`, 47th campaign walk. Roman city above the sea at dusk.
No chase, no boss. Module: `systems/tarragona.gd` with `const HOOKS`.

## Placement

- Append `tarragona` to `Game.LEVELS` (assert present, never that it is last)
- `CAROUSEL` after `montserrat` (`encants` absent)
- `STAR_GATE` 50; `CHASE_GATE` same as `scrap` (`"boars"`)
- `CAMPAIGN_SKY` `["clear", "dusk"]`; add to `WALKS_SINCE_GATES`
- Name `Tarragona`; gloss "Roman stones above the sea" (+ CA/ES)

## Route (south → north)

| Zone | Content |
|------|---------|
| Balcó del Mediterrani | Start; railing; sea east; dusk sun; view goal |
| Amphitheatre rim | Oval stone tiers; path on rim only |
| Rambla Nova | Wide panot, plane trees, benches, lamps (`lamp_glow`), casteller monument (original), gladiator dare |
| Casteller plaça | Soft-crowd live event before the walls |
| Roman walls / old town | Huge blocks, narrow streets, arches; markable stones |
| Cathedral square | Off-leash finish |

## Live event (soft crowd crawl)

1. Telegraph ≥0.8 s: gralla tune + crowd hush (banner / speech)
2. Tower rises in steps; crowd packs plaça centre
3. Human in pack: `walk_pace` crawl; edge lanes stay clear
4. Reward on crowning if dog pulled them round the edge or planted clear
5. Nobody falls; tower never a hazard

## Goals

- Shared mark/sniff/etc. plus:
- `tarragona_mark` — Mark the Roman stones
- `tarragona_castell` — Earn the crowning reward
- `tarragona_balco` — Balcó view (stand still with human until they look up)

## Cast & sign

- Dare-giver `gladiator` (Roman kit, wooden sword & shield): FOOTPRINT, LINES×5, NAMES, cast draw, `dare_gladiator` + walk tune `tarragona`
- World sign piece `tesserae` (new drawer)

## Outdoors

Dusk: walkers, bench sitters, a few cyclists. Spawners keep RNG draws and filter afterwards.

## Tests & release hygiene

- `tests/test_tarragona.gd` + `tests/ci.d/tarragona.txt`
- Changelog fragment; Feel card on PR
- Do not edit store/itch/README/site
