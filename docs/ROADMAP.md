# Roadmap to the finish line

Written 2026-11-07, after 1.69. This is the working plan: PROJECT.md keeps the
design pillars and the release history, this file keeps what is left and in
what order. Update it when a release ships or a decision changes; the board
(https://github.com/users/cyanidesayonara/projects/4) carries the same items
as issues.

## Where the game stands

- 31 walks plus the tutorial, five chase walks (La Neteja, El Besòs, El
  Veterinari, Els Senglars, Festa de Gràcia), El Gat as the finale boss with
  its victory film on the plinth, four artsy detours (El Somni, L'Estel,
  El Colom, El Drac).
- Five dogs, a wardrobe, a campaign with fixed skies, FREE WALK after a
  finished walk, four hours of day (dawn, day, dusk, night), weather.
- A signature live event on every walk, true near-miss saves, a story film for
  every chase.
- Everything on the board is Done (accepted) except two groundwork items.

## The target: the 41-walk campaign

Decided 2026-11-02 (see PROJECT.md and the planner artifact for order):

- Chases at walks 5, 10, 15, 20, 25, 30, 35 and 40; bosses at 11, 21, 31 and
  41. Statue animals, public-domain art only. El Gat is the final boss, a
  boss arena rather than a chase. Dia de Partit is not a chase.
- Still to build (ten walks): L'Eixample, Els Àngels (MACBA plaza), La Cremada
  (Badalona's Nit del Dimoni, a chase), La Ciutadella (the mammoth as mid
  boss), El Poble Espanyol, Montserrat (a chase, the goats), L'Aeroport (a
  chase), and three more from the bench: Sarrià, Carrer de Blai, Sant Pau,
  Sitges. El Delta is rejected.
- Every new walk ships with an upgrade to an existing one, and its own
  signature live event. A chase walk ships with its film (a story film is
  part of the walk, not a later task).

## Release train

### 1.70 - Hardening and light (tagged 2026-11-07)

No new walks. What is in it since 1.69: the four-hour sky with a real dawn
and dusk, campaign skies, squared roofs and walkable yards on winding
streets, shader edge smoothing, Superilla, Els Búnquers, El Fòrum, Plaça
d'Espanya, three detour galleries, the Raval victory film, the live events.

The release gate. Tagged with the hand-playtest (item 4) and the phone check (item 7) still owed; fix what they find first in 1.71:

1. Full local test suite green, and CI green on main.
2. Shot sweep reviewed walk by walk for the sky, roof and yard changes; every
   walk that reads as unfinished is fixed or recorded.
3. Web build performance measured (frame times and draw calls per walk, the
   FXAA pass included) on a quiet machine, against the last numbers.
4. Playtest the new walks and every changed edge by hand, as a player.
5. Behaviour snapshot comparison explained line by line.
6. Release notes written: Store "What's new", itch notes, walk list and
   count, README walks table, CHANGELOG.
7. Real-device check on a phone browser (the open board item).
8. Santtu says tag.

### 1.71 - Three walks and the first new boss

L'Eixample, Els Àngels, El Poble Espanyol; the mammoth mid boss waits for
1.72. Each with its upgrade and live event.

### 1.72 - La Ciutadella and La Cremada

The mammoth boss and its walk (walk 11, built: El Mamut, his wake film, El
Parc's bronze dog in his old place), and La Cremada as a chase with its
correfoc film. Every boss is designed against `docs/BOSSES.md`; El Gat's
pounce, replacing his charge, belongs here too.

### 1.73 - Airport and mountain

L'Aeroport (service dog, cabin havoc, security chase film) and Montserrat
(goats chase her down, film).

### 1.74 - Close the campaign

The last three walks, the remaining statue bosses, and the order, star
gates and chase gates reset to the final 41 in `Game` (CAROUSEL, STAR_GATE,
CHASE_GATE) through the planner.

### 1.8 - The finishing pass

City-map walk select, postcards, full Catalan and Spanish translation,
credits, a pass on the controls and accessibility (remapping exists; the
Store accessibility declaration waits on a real pass), balance of stars and
bones over 41 walks.

### 2.0 - The product

Steam groundwork (name check, page, GIF-first trailer), the music pass,
browser portals (CrazyGames, Poki), a paid Steam and Store listing later. No
ads, no in-app purchases.

## Videos

The story films are part of each chase walk (sweeper, flood, vet, boars,
Gràcia, La Cremada and the cat are done). Still owed: L'Aeroport and
Montserrat each get a film with their walk, and each boss gets a short
wake-up film. A trailer and devlog clips belong to the 2.0 Steam groundwork,
cut from the playtest tool's captures.

## Standing rules

- Never push to main; a PR for everything, a feel card in each, CHANGELOG
  every session.
- The WIP limit in AGENTS.md: at most five player-facing changes awaiting
  acceptance. Santtu plays and accepts; Done on the board means accepted.
- Bugs come before features. Each version polishes every walk and object it
  touches to a finished standard.
- Tag only when Santtu says, and only once the Store and itch notes describe
  the release.
