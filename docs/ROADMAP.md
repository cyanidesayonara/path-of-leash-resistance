# Roadmap to the finish line

Written 2026-11-07, after 1.69. This is the working plan: PROJECT.md keeps the
design pillars and the release history, this file keeps what is left and in
what order. Update it when a release ships or a decision changes; the board
(https://github.com/users/cyanidesayonara/projects/4) carries the same items
as issues.

## Where the game stands

- The whole campaign, on main since 2026-11-24: 51 walks plus the tutorial, ten
  chases (every fifth walk, Les Atraccions' mascots the last to land), five
  statue bosses (El Mamut, El Drac, Els Lleons, La Lleona and El Gat, each with
  its films), four artsy detours. Progress from before it starts over.
- Seven dogs with skills and training, a wardrobe, a campaign with fixed skies,
  FREE WALK after a finished walk, nine skies and six times of day, English,
  Catalan and Spanish.
- A signature live event on every walk, true near-miss saves, a story film for
  every chase.
- Every tag through 1.76 shipped to itch.io and the Microsoft Store; Android
  export groundwork is in, a static site on GitHub Pages is up.

## The target: the 51-walk campaign

Decided 2026-11-16 with Santtu (replaces the 41-walk plan of 2026-11-02).
Exactly 51 walks, no more, no less:

- Chases at 5, 10, 15 ... 50 (ten) and a statue boss after every second
  chase, at 11, 21, 31, 41 and 51 (five). The other 36 are walks.
- Variety over clusters: no runs of hill, indoor or water walks, and the
  campaign skies spread over dawn, dusk, rain, wind, snow and fog rather than
  mostly clear days.
- Festa de Gràcia is the last chase (50); El Gat the final boss (51), a boss
  arena rather than a chase. Dia de Partit is not a chase. No two chases share
  a threat, and every boss fights differently (three are cats, which is fine:
  she is a dog).
- Bosses are statue animals, public-domain art only (Gaudí, the mammoth, the
  1888 lions, the Romanesque lioness); El Gat stays a cartoon cat of our own.
- Every new walk ships with an upgrade to an existing one and its own
  signature live event. A chase walk ships with its film.

### Still to build (twelve walks)

| Walk | Kind | Sky | The idea |
|---|---|---|---|
| Sarrià | walk | dawn | the village inside the city, the morning walk |
| El Metro | walk | rain | underground: platforms, escalators, one train ride; no operator branding |
| Carrer de Blai | walk | night | Poble-sec's pintxos street, terraces and dropped food |
| Sant Pau | walk | dusk | the modernista hospital's pavilions and gardens |
| Sitges | walk | wind | the seafront and the church on the rock |
| Els Encants | walk | rain | the flea market under the mirrored canopy at Glòries |
| Camí de Ronda | walk | wind (tramuntana) | a Costa Brava cliff path, the first east-west scroller |
| Tarragona | walk | dusk | the Roman amphitheatre over the sea |
| Vic | walk | fog | the market square in winter fog; fog is a new weather |
| La Molina | chase | snow | the first snow walk; a snow groomer chases her downhill |
| A theme park | chase | day | an original Costa Daurada park, not a copy of a real one; the mascots chase her |
| Girona | boss | rain, dusk | the Onyar houses and old-town steps; La Lleona de Girona pounces from her column |

Dropped on 2026-11-16: La Revetlla, Els Terrats, Les Tortugues as a boss.
Bench: Vallvidrera's funicular. El Delta stays rejected.

### The order

Applied to `Game.CAROUSEL` on 2026-11-23 (gates version 5), with walk 41 left
for Girona, which landed with La Lleona on 2026-11-24 (#702 to #704). Les Atraccions'
mascot chase and film, the tenth chase, followed the same day, and the save
reset with it.

New walks in bold; (C) chase, (B) boss.

- 1-5: El Barri, La Rambla, El Parc, Passeig Marítim, La Neteja (C)
- 6-11: El Gòtic, Montjuïc, El Mercat, El Diluvi, El Besòs (C), La Ciutadella (B)
- 12-15: Platja de Llevant, L'Eixample, El Tibidabo, El Veterinari (C)
- 16-21: **Sarrià**, El Bosc, Els Àngels, La Castanyada, Els Senglars (C), El Mosaic (B)
- 22-25: La Superilla, **El Metro**, Els Búnquers, La Cremada (C)
- 26-31: L'Estació, Plaça Reial, El Fòrum, La Carretera de les Aigües, L'Aeroport (C), El Port (B)
- 32-35: La Diagonal, **Carrer de Blai**, El Laberint d'Horta, **La Molina** (C)
- 36-41: Plaça d'Espanya, **Sant Pau**, El Poble Espanyol, **Sitges**, **the theme park** (C), **Girona** (B)
- 42-45: Les Obres, **Camí de Ronda**, Dia de Partit, Montserrat (C)
- 46-51: **Els Encants**, **Tarragona**, **Vic**, La Ferralla, Festa de Gràcia (C), Rambla del Raval (B)

Proposed re-skies for existing walks, not
yet confirmed: El Tibidabo in snow, La Carretera de les Aigües at dawn, El
Bosc in rain, Les Obres at dawn, La Diagonal at dusk.

### Saves

Progress resets with the finished campaign (`Game.SAVE_VERSION`, landed
2026-11-24): one save-version bump that starts everyone fresh, instead of more gate grandfathering (Santtu,
2026-11-16). Nothing earned is kept, the wardrobe and trained stats included: a
clean fresh game (Santtu, 2026-11-24). Settings (controls, language) survive. The
old gate tables and grandfathering went with it. The old file is kept beside the
new one (`records_before_campaign.cfg`).

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

### 1.71 - Three walks and the first new boss (tagged 2026-11-09)

L'Eixample, Els Àngels, El Poble Espanyol, night grade shaders and softer
lighting; each with its upgrade and live event.

### 1.72 - La Ciutadella and La Cremada (tagged 2026-11-11)

The mammoth boss and its walk (El Mamut, his wake and victory films, El
Parc's bronze dog in his old place), and La Cremada as a chase with its
Dimoni float and Correfoc film. Castellers de Gràcia and Castellers de
Barcelona, Fur-goneta facelift across four walks, and illuminated night fronts.

### 1.73 - Airport and mountain (tagged)

L'Aeroport and Montserrat as chases, each with its film.

### 1.74 - Polish and Android groundwork (tagged 2026-11-16)

El Drac's serpentine bench, El Gat's awnings, the bespoke NPCs on
`NpcFigure`, camera tricks for chases and bosses, El Gòtic's retractable
bollards, late-campaign chase spacing, web performance work, and Android
readiness.

### 1.75 - Three walks and the core upgrades (tagged 2026-11-17)

Sarrià, El Metro, Carrer de Blai; the Trencadís look; El Barri, Plaça Reial
and L'Estació rebuilt; a dare-giver with a tune on every walk; readable
dares; the whirl and the leash upgraded.

### 1.76 - Eight walks, two dogs, three languages (tagged 2026-11-22)

La Molina (chase and film), Sant Pau, Sitges, Les Atraccions, Camí de Ronda,
Els Encants, Tarragona and Vic; Perla and Duna; skills, buried finds and
training; Catalan and Spanish.

### 1.77 - The whole campaign (next; Santtu says when)

Girona with La Lleona and her films, Les Atraccions' mascot chase and film, the
roadmap's order, and the fresh start. Before the tag: Santtu plays what awaits
acceptance, and the release text PR lands.

### 1.78

Google Play, maybe: it waits on Santtu's developer account.

### 1.8 - The finishing pass

City-map walk select, postcards, full Catalan and Spanish translation,
credits, a pass on the controls and accessibility (remapping exists; the
Store accessibility declaration waits on a real pass), balance of stars and
bones over 51 walks.

### 2.0 - The product

Steam groundwork (name check, page, GIF-first trailer), the music pass,
browser portals (CrazyGames, Poki), a paid Steam and Store listing later. No
ads, no in-app purchases.

## Videos

The story films are part of each chase walk (every chase through
Montserrat has one, and every boss has its wake and victory films). Still
owed: La Molina and the theme park each get a chase film, Girona's La Lleona
her wake and victory films. A trailer and devlog clips belong to the 2.0 Steam groundwork,
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
