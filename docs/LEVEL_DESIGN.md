# Level design pass (2026-09-27)

Santtu: "we should go over each element of each level, to design them in a
way that is fun and makes sense. I guess the levels in Tony Hawk didn't always
make sense either, but at least they were designed to be 100% fun." Plus: the
sticky substances in real-world shapes and places, sand that takes footprints
and gets tracked onto the paving, and every walk restyled to look like a real
place (#65 did the cross-sections).

This is the plan for that pass: the rules every walk follows, what each walk
is and needs, and the order. Each walk is built in its own PR and played by
hand before the next (the WIP limit applies). Edit this file when a decision
changes; it is the brief, not a record.

## Where things stand

`tools/level_inventory.gd` prints every walk's contents. What it shows:

- **Five walks are La Rambla's layout redressed.** El Diluvi, L'Estacio,
  Les Obres, La Ferralla and the First Walk inherit its props wholesale, café
  terrace included (four tables, six chairs, two parasols in a scrapyard, a
  roadworks and a station concourse), plus its bins, hydrants, manholes,
  cellars and three road crossings.
- **Three walks are El Mercat's.** El Gotic and La Castanyada carry its eight
  stalls; La Neteja its stall-free skeleton.
- **El Bosc and El Mosaic are El Parc's.** Both carry the park's pond and
  its 14-tree grove, which is why El Parc and El Bosc read as one walk with a
  bent path.
- **Every walk ends in the same off-leash yard** with the same 16 props,
  except the beach, the clearings and the lots.

## The rules

1. **Every walk is its own place.** Nothing is inherited that the real place
   would not have. A base layout is scaffolding, not content: each walk
   authors its own props.
2. **Every walk has a signature line.** Like a Tony Hawk line: a route
   through the walk that chains the game's verbs - vault round a pole, grind
   a kerb or bench, fling the owner off a post, thread a tangle - laid out on
   purpose, with a landmark marking it. A player who finds it should feel the
   walk was built for it.
3. **Every prop earns its place,** as scenery that sells the place or as
   play (a pole to wrap, an edge to grind, a temptation, a hazard), ideally
   both. Props come in clusters that read as a thing (a café terrace, a bus
   stop, a works compound), not as scatter.
4. **Rhythm:** a calm opening, a busy stretch, a set piece, a breather
   before the gate. The way home re-reads the same street backwards, so the
   set pieces must work from both directions.
5. **Substances go where they would really be,** in the shape they really
   take:
   - wet cement: a poured rectangular section in its formwork, with cones
     and tape round it
   - wet paint: fresh road markings (a zebra crossing, a stop line, a
     painted kerb) with cones at the ends
   - mud: puddles of mixed sizes in the low spots - the edges of a dirt
     path, round a tree, at a stream bank - never a slab mid-pavement
   - fish: meltwater and ice chips round the fish counter
   - oil: stains under and behind vehicles and machinery
   - confetti: scattered pieces round the festivities, not a puddle
6. **Surfaces behave like themselves.** Sand takes footprints (hers and his)
   that fade slowly, and sandy paws track it onto the boardwalk and paving.
   The same for snow. Grass holds scent, tile is slick (surfaces.gd).
7. **The off-leash area belongs to its walk:** a dog park, a forest clearing,
   the dog beach, a plaça, a works yard, the scrapyard's back lot - not one
   yard with the same furniture everywhere.
8. **Readable at a glance, top-down.** Silhouettes and colour say what a
   thing is; the path and the hazards on it must read against the ground.

## The walks

Signature line = the intended fun route. Keep = what already works.
Cut = what is borrowed and wrong. Add = what the place needs.

### La Rambla (street) - the boulevard
The flagship walk; it has to be nailed. Santtu: "it should be busy, with all
kinds of stalls selling their wares, people selling stuff on the ground too,
with pickpockets and shenanigans happening around."
- Is: the promenade down the middle, trees either side, one lane of traffic
  and a pavement past the building fronts on each side. Crowded: tourists
  with maps and selfie sticks, groups following a guide's umbrella, locals
  cutting through.
- Stalls along the promenade: the newspaper and postcard kiosk, the flower
  stalls, souvenir stands (football shirts, fans, fridge magnets), an ice
  cream cart, a caricature artist with an easel. Each stall is furniture the
  leash can wrap and a place the crowd bunches up.
- On the ground: sellers with their wares on a blanket (bags, sunglasses,
  toys). A blanket is a soft obstacle, not a wall: the dog can run across it
  (the seller shouts), and when a whistle goes the sellers pull the blanket's
  cords and walk off with the whole bundle, a moving obstacle for a moment.
  They are part of the scene, never the villains.
- Shenanigans: the human statues (who move when you are not looking), a
  shell game on a cardboard box with a crowd round it, a mime, pigeons being
  fed. Pickpockets working the crowd (see Pickpockets below); La Rambla has
  the most.
- Signature line: vault round the plane trees, grind the planter kerbs,
  weave the stalls without wrapping the flower stall, trip a pickpocket
  running the other way with the leash, fling the owner off a lamppost past
  the statue.
- Keep: the tree slalom, the FUR-GONETA, the crossings, the drinking
  fountain.
- Cut: the lawn and picnics (they belong to El Parc). The café terrace
  stays in the middle of the promenade: that is where La Rambla's terraces
  really are.
- Add: the stalls, blankets, statues and crowd above; planter kerbs worth
  grinding; the Canaletes fountain as the drink stop.

### El Parc (park) - the city park
- Is: open lawns, flowerbeds, the pond with its bridge and ducks, a
  bandstand, a playground.
- Signature line: grind the flowerbed edging, cross the bridge (the pond is
  the gap), loop the owner round the bandstand posts.
- Keep: pond, bridge, ducks, lawn verge, tree slalom.
- Add: low hedged flowerbeds (grind), a bandstand landmark, a playground
  corner (temptation), pigeons at the benches, and the Ciutadella mammoth
  statue as the landmark you can mark. The path opens out round the lake so
  it is an island with a shore either side (path shapes, stage 2).
- Off-leash: the dog park (as now).

### El Bosc (trail) - the forest
- Is: woodland, not a park with a bent path: trees crowding the path, roots,
  fallen logs, a stream, leaf litter, no signal.
- Signature line: wind the leash round the trunks where the path pinches,
  hop the fallen log, cross the stream at the ford.
- Cut: the park's pond, benches and bins (one bench at a viewpoint at most),
  the lawn verge.
- Add: a stream across the path with a ford or stepping stones, mud round
  its banks and in the ruts; fallen logs; roots; trees right up to the edge;
  a waymarker post as landmark; forest floor instead of lawn beside the path.
- Off-leash: the clearing (as now), with a log pile and a stream pool.
- Wild boar: Collserola's boars. A sow and her striped piglets root along
  the path edge and cross it at their own pace; they steal nothing, but
  get between one and her piglets and she bumps the dog (and the owner)
  flat. Telegraphed: grunting and the piglets crossing first. A walk
  where the owner, phone up, walks into a boar is the forest's big
  slapstick moment.

### Passeig Maritim (beach) - the seafront
- Is: largely right already.
- Add: footprints in the sand, sand tracked onto the boardwalk; a lifeguard
  tower and beach showers (rinse the paws); a chiringuito bar with its
  tables; a volleyball net on the sand.
- Built (2026-10-09, #151): palms in runs between landmarks
  (`LevelBuild.BEACH_PALMS_*`); two showers and a volleyball court on the
  sand, their columns and net posts solid poles; a lifeguard tower whose
  cabin is overhead; each chiringuito on a deck under a reed pergola with
  a solid bar hut; the blocks' roofs behind; one sea palette shared with
  the dog beach.

### El Diluvi (rain) - the rainy shopping street
- Is: a narrow shopping street in a downpour, not La Rambla wet.
- Signature line: shop-awning to shop-awning in the dry, splash through the
  puddles for the zoomies, drag the owner under the arcade.
- Cut: café terrace (a terrace in a downpour is chairs stacked and chained),
  the lawn.
- Add: real puddles on the paving (splash, reflections), running gutters,
  shop awnings and an arcade as shelter, pedestrians with umbrellas.

### El Mercat (market) - the market hall
- Is: inside a covered market: stall rows as aisles, iron columns, the fish
  counter, fruit crates, sawdust.
- Signature line: weave the aisles, wrap the leash on the hall's columns,
  snatch from the crates.
- Add: iron columns (wrap), fish counter with meltwater and ice, crate
  stacks, an entrance arch as landmark.
- Built (2026-09-30, `LevelBuild.mercat`): in off the street under an iron
  and stained-glass arch (MERCAT) into a hall 800 wide; four stall blocks
  down the middle, solid, the owner keeping to alternate aisles round them,
  a green iron column at each corner; wall stalls (fruit, juice, jamon,
  fish on ice, olives, sweets) with meltwater and scales in front of the fish
  and sawdust by the fish and ham; orange-crate stacks to mark; a terrazzo
  floor under a glazed roof on red trusses; out through the far door (PLACA).
  No van indoors.

### El Gotic (oldtown) - the medieval alleys
- Is: alleys with walls at the paving (done in #76), laundry overhead,
  cats on the ledges, a small plaça with a fountain.
- Signature line: cats on the ledges, pinch points between the walls where
  a fling off a post is the only way through quickly.
- Cut: the market's stalls.
- Add: an overhead bridge between buildings (a landmark you pass under),
  steps, doorway flowerpots, parked scooters.

### L'Estacio (station) - the concourse
- Is: inside a station: departures board, ticket barriers, pillars, bench
  rows, the moving walkway, luggage trolleys.
- Signature line: ride the walkway, wrap round the pillars, squeeze the
  owner through the ticket barriers.
- Cut: café terrace, bike crossings, manholes, lawn - it is indoors.
- Add: pillars (wrap), barriers (a gap), bench rows, trolleys, the board as
  landmark.

### Les Obres (site) - the roadworks
- Is: a works detour: cement pours in formwork with cones and tape, fresh
  road markings, a trench with a plank bridge, Heras fencing, a parked
  digger.
- Signature line: thread the cones, cross the trench on the plank, keep the
  owner out of the wet cement.
- Cut: café terrace, the organic cement blobs, the pink paint blob.
- Add: cement slabs with formwork and cones, a freshly painted zebra
  crossing with cones, the trench and plank, fencing, the digger as
  landmark.

### La Castanyada (spook) - the chestnut festival at night
- Is: a plaça festival: the chestnut roaster's stall, lantern strings,
  sweets on the ground (the dog must not eat the chocolate), confetti,
  a small stage.
- Keep: candy, the stalls (festival stalls belong here), performers.
- Add: confetti as scattered pieces, lanterns, the roaster as landmark.
- Built (2026-09-30, `LevelBuild.castanyada`): an old-town street opening
  into a plaça; the chestnut roaster in its middle (solid, the owner walks
  round its east side), drum glowing and smoking, its light on the setts; a
  stage on the west side with the band; plane trees; festival stalls
  (chestnuts, panellets, roast sweet potatoes, sweets); paper-lantern strings
  over the street, lit; confetti thrown from the stage and chestnut shells
  underfoot; chocolate to steer past; hessian sacks of chestnuts to mark.

### La Ferralla (scrap) - the scrapyard
- Is: stacked wrecks, a crane, oil, the guard dog, cameras and lasers.
- Signature line: sneak between the wreck stacks out of the cameras' view.
- Cut: café terrace, benches, the hydrant grid, road crossings.
- Add: wreck stacks as the walls and poles of the route, oil stains behind
  them, the crane as landmark, the guard dog's kennel.

### El Mosaic (guell) - the terraces
Santtu: "doesn't actually look much like it really should, it just seems
like a POC at this point. The mosaic texture looks nice but how to decorate
the level with it still needs a few rounds of polish." The goal is a walk
that reads as Park Guell from one screenshot. The mosaic is the finish on
the landmarks, never wallpaper: most of the ground is sandy gravel and
rubble stone, and the colour comes in where Gaudi put it.
- Is, walked uphill from the gate:
  1. **The entrance:** the two gingerbread gatehouses either side of the
     start (wavy roofs, mosaic caps, one with the mushroom-and-cross
     spire), the gravel forecourt between them.
  2. **The dragon stair:** the double staircase splitting round the middle,
     the mosaic salamander on its landing (the drink stop and the
     landmark), the dripping-stone grotto walls either side.
  3. **The hypostyle hall:** a grid of fat Doric columns under the plaza,
     the best pole forest in the game. Wind, whirl and tangle here.
  4. **The plaza and the serpentine bench:** the open sandy terrace on top,
     edged the whole way by the wavy mosaic bench. The bench is the grind
     line; its bays are where tourists sit.
  5. **The viaducts:** the leaning rubble-stone colonnades along the hill,
     columns like palm trunks, a covered walk with the pillars on one side
     and the slope on the other; then the path climbs to the calvary cross
     as the finish.
- Signature line: vault the salamander, wind the owner through the
  hypostyle columns and fling them out onto the plaza, grind the whole
  serpentine bench, carve the viaduct's lean.
- Life: tourists photographing the salamander and queueing at the gate, a
  guitarist in the viaduct, a seller of fans, parakeets in the palms,
  pickpockets in the queue.
- Cut: the park pond carry-over, city frontage, flat mosaic floor as the
  default ground.
- Add: the five pieces above in order; rubble-stone terrace walls as the
  frontage, palms and agaves along them; gravel and sand underfoot (takes
  footprints), mosaic only on the bench, salamander, gatehouse roofs and
  column medallions.
- Rounds: expect several. First the layout and the pieces as shapes, then
  the mosaic finish, then the life.
- Round 1 built (2026-09-30, `LevelBuild.mosaic`): the five pieces in
  order on sandy gravel between rubble-stone terrace walls with palms and
  agaves - the gatehouses either side of the start (gingerbread walls, iced
  wavy roofs, mosaic caps, the red mushroom spire with its cross); the dragon
  stair with steps at foot and head, grotto stone along its sides, and the
  trencadis salamander on its landing (solid, walked round, the drink at its
  mouth); the hypostyle hall's 4x5 columns with mosaic medallions and a lane
  through the middle, in the shade under the plaza; the plaza, its edges
  waving as the serpentine bench, finished in trencadis, and the bench
  grinds end to end ("BENCH GRIND!"); the viaduct with leaning rubble
  columns and the slope beside it; the calvary's three crosses at the top.
  Still to come: the life (tourists at the salamander, the queue at the gate,
  the fan seller, parakeets, pickpockets in the queue) and a second finish
  pass.
- Round 2 built (2026-09-30, `main._tick_mosaic_groups`): the life - the
  gate queue up the forecourt's west side, tourists posing round the
  salamander (west and south, off the owner's way round) who photograph a
  dog who comes close, La Rambla's crowd and pickpockets with the first
  pickpocket stepping out of the queue, monk parakeets under the palms who
  go up over their wall, the fan seller on the plaza and the guitarist in
  the viaduct.

### La Neteja (neteja) - the back street at dawn
- Is: a narrow street at street-cleaning time: dumpsters, parked scooters,
  shutters down, delivery crates, wet streaks where the water truck went.
- Add: wet streaks and puddles, dumpsters, scooters, shutters, dawn light.
- Built (2026-09-30, `LevelBuild.neteja`): still the narrowest walk and
  still runnable for the sweeper chase; dumpsters out at alternate kerbs
  (solid, their corners catch the rope) with crates stacked by them, scooters
  parked up, the lamppost slalom, washing overhead, the water truck's wet
  streaks and puddles on grey setts, the shops' shutters down and tagged, and
  a low pink-gold dawn light. No market left in it.

### El Barri - the neighbourhood park (the first walk)
Santtu: "la rambla shouldn't be the primary walk... that should be just a
generic walk in the park, without anything distinctly barcelonian", and "the
park could be just a neighborhood park in bcn."
- Is: the little park at the end of your street. A gravel square under plane
  trees, benches, a drinking fountain, a fenced dog area (the pipicà), a
  playground, a ping-pong table, old men playing petanca. Nothing a tourist
  would photograph; the walk you do every day.
- Where: open from the start and first in the list; La Rambla moves back and
  needs a couple of stars. The Daily Walk still rotates through every walk.
- Signature line: nothing fancy. Wind the owner round a plane tree, mark
  every bench leg, sneak through the petanca game.
- Built from El Parc's green layout (not the boulevard), kept small and
  calm: a short walk, few hazards, the off-leash area is the pipicà.

### First Walk (tutorial) - learn each trick in peace
Santtu: "we should really upgrade the tutorial too, so that the user can
learn each trick & mechanic individually and in peace, without all the
distractions of normal levels."
- Is: El Barri, emptied out and laid out as a row of **stations**, one per
  lesson, far enough apart that only one is on screen. Each station holds
  exactly what its lesson needs (one hydrant, one kerb, one lamppost, one
  patch of turned earth) and nothing else: no crowd, no traffic, no riders,
  no critters except the one the lesson is about.
- **The owner waits.** At each station the owner stops (on a bench, on the
  phone) until the lesson is done or skipped, so nothing is ever rushed.
  Then they get up and walk on to the next station.
- **One card per lesson**: the title, one line of what to do with the
  button for the device in use, and a ghost of the move where it helps (a
  dotted arc round the lamppost for the vault). A tick and a chime when it
  lands; the skip button always works.
- **The lessons**, in order from "you already know this" to "nobody would
  guess this":
  1. Walk. 2. The leash is rope (walk until it goes tight). 3. Dig in
  (plant and win the tug). 4. Mark (pee on the hydrant). 5. Sniff.
  6. The nose (go slow, follow the scent). 7. Dig (the turned earth).
  8. Bark (it stops your human). 9. The zoomies (turbo). 10. Ride the kerb
  (grind). 11. Swing round the lamppost (vault). 12. Tetherball the owner
  (wind them round the pole and fling). 13. The brink (the teeter, at a
  safe fountain edge). 14. Business (the poop, and the owner bagging it).
  Then the pipicà: off the lead, fetch.
- A lesson a player has done on a real walk can still be practised; the
  tutorial is replayable from the menu.

## Writing on the ground (each walk's name, in its own stuff)

The walk's name is not a label over the level; it lies on the ground at the
start, made of whatever that place has to hand, as loose pieces
(`world/world_sign.gd`, letters as strokes in `world/sign_letters.gd`):

| Walk | Material | How it behaves |
|---|---|---|
| El Barri | fallen plane leaves | scatter, spin, stay scattered |
| La Rambla | cut carnations from the stalls | scatter |
| El Parc | a planted flowerbed | shoved plants spring back |
| Passeig Maritim | heaped sand in a dug trench | heaps scuff flat under a paw |
| El Diluvi | puddles | do not move; ring when run through |
| El Mercat | oranges, lemons, apples | roll a long way |
| El Bosc | sticks | knocked aside and turned |
| Les Obres | traffic cones | go over when hit at a run |
| La Castanyada | chestnuts | roll |
| La Ferralla | torch-cut rusty plate | heavy; shift and turn a little |
| El Mosaic | trencadis | set in; stays |
| La Neteja | soap suds | pop |
| any walk in snow | her own paw prints | pressed in; stay |

The dog, the human and the rope all move pieces (the rope only brushes);
nothing pushes back, so gameplay is unchanged. HOME at the start line is
written the same way, so you come home past whatever you did to the name on
the way out. The walks without a material (El Gotic's tile plaque, the
station board, the chalked First Walk and daily) keep their drawn signs.

More writing on the path, sparingly, where a real place would have it: a
message worth sending is one the place would carry anyway (HOME, an OFF
LEASH board at the gate), never a tutorial line painted on the pavement.

## Path shapes (each walk its own)

Santtu: "the shape the path takes should vary a bit more level by level
too. right now only the windy path on mosaic is any different from the
straight path... each level should have its own idiosyncratic shape." And
the Escher walk (PROJECT.md, the art-walks list): "you would walk down one
pathway, across a bridge and then appear out of a door somewhere else."

**What the engine can do today.** The path is one corridor that runs up
the screen: `walk_edges(y)` gives one left and one right edge for each
height, shaped by `edge_nodes` (centre and half-width at points down the
walk, slope capped at 0.85 so it can be run). That buys bends, pinches and
bulges, and nothing else: no fork, no right-angle turn, no crossing, no
door. The vocabulary grows in stages, each one a PR with its own test:

1. **Bends, pinches and bulges, used properly (no engine work).** Today
   only El Mosaic and El Bosc use them. Every walk gets its own rhythm:
   where it narrows to single file, where it opens into a plaça, where it
   doglegs.
2. **Islands (small engine work).** The path splits round something and
   rejoins: a pond, a kiosk block, a fountain, a row of stalls. Built as a
   wide stretch with a solid island in it, so `walk_edges` stays one pair;
   `surface_at`, props and the self-test learn that the island is not path.
   The leash makes it a game: dog one side, owner the other, and the
   island is the biggest pole on the walk.
3. **Crossings and level changes (medium).** Stairs as bands you climb, a
   ramp, a bridge over a cross-street or a stream, an underpass you walk
   through in shadow. The path stays one corridor; what changes is what
   lies across it and what it looks like.
4. **A path that is not bound to "up the screen" (large).** A centreline
   polyline with widths instead of one edge pair per height, so an alley
   can turn a right angle, run sideways, double back. `walk_edges(y)`
   becomes a query over it; everything that asks it keeps working. This
   is what El Gotic's alleys really need.
5. **Doors between places (see Detours).** A door that leads into a
   different room is a scene change, which the engine can already do: the
   dog and the owner go through together, so the leash never has to span
   two places. A door inside one place that the rope runs through while
   the dog and the owner are on different sides is the hard version, and
   is not planned.

**Each walk's shape:**

| Walk | Shape |
|---|---|
| La Rambla | Dead straight, as the real one is: the straightness is the joke under the crowd. It bulges at the Pla de la Boqueria (Miro's pavement mosaic set in the middle, a free landmark) and pinches at the kiosks and stalls. |
| El Parc | Splits round the pond and rejoins (stage 2); a looping side path round the bandstand. |
| El Bosc | The winding trail it is now, with harder pinches between trunks, the ford as a narrow crossing (stage 3). |
| Passeig Maritim | Long and straight along the sea, with the boardwalk splitting off across the sand and back (stage 2). |
| El Diluvi | Arcades: a covered side walk behind pillars that runs alongside the open street and rejoins it, dry against wet (stage 2). |
| El Mercat | The hall's aisles: two or three parallel aisles between stall rows, cross-aisles between them (stage 2, then 4). |
| El Gotic | Narrow alleys with doglegs now (stage 1), tight plaça bulges, then real right-angle turns and an arch you pass under (stage 4). |
| L'Estacio | Opens from the street into the wide concourse, then narrows to the platforms: pick one of two, the train between them (stage 2). |
| Les Obres | The path diverted by the works: a chicane through barriers, a plank bridge over the trench (stages 1 and 3). |
| La Castanyada | Round the square: the path circles the chestnut roaster's bonfire (stage 2). |
| La Ferralla | A lane between scrap piles that shifts left and right, a crane's reach overhead. |
| El Mosaic | The serpentine as now, the dragon stair splitting round the salamander (stage 2), the hypostyle grid, the viaduct's lean (see El Mosaic). |
| La Neteja | Straight and narrow: the chase needs a straight. |

## Detours (art rooms off the main walks)

Santtu: "easter egg-like detours from the main walks, like you enter through
a secret door... say there's an entrance to a museum on the side of some
level, and when you enter, it's a little secret level in the style of Dali,
Picasso, Miro, maybe Joan Cornella... the levels don't have to be so secret,
just more of a detour, like you walk past a Gaudi house and there's a big
advertisement saying come in." Chosen over a separate art walk: the art
walks list in PROJECT.md becomes these rooms.

- **The door.** A doorway on the side of a walk with a banner over it
  ("EXPOSICIO - ENTRADA LLIURE"), and a queue or a greeter. Walk the dog
  in and the owner follows without looking up. Missing it costs nothing.
- **The room.** A short scene, well under a minute, with its own rules and
  its own look, then a door out onto the walk just past where you went in.
  It gives dog business and one goal of its own; the walk's timer and
  goals wait outside.
- **One per walk at most**, placed where the real city would have it: the
  modernist house on a La Rambla-like street, the gallery in El Gotic, the
  museum on the hill above El Mosaic.
- **Rooms, each an idea rather than a copy:**
  - Melting (after Dali): lampposts that droop when you lean the leash on
    them, long raking shadows that hide things, elephants on stilt legs on
    the horizon.
  - Primary shapes (after Miro): flat colours, heavy outlines, stars and
    eyes and ladders as the things to collect, so the level and the goal
    speak the same language.
  - Many sides (after Picasso): kept to the walls and faces around a plain
    floor, since a cubist floor would read as broken, not as art.
  - Impossible stairs (after Escher): greyscale pencil, stairs that tile,
    a loop that brings you back to the start one floor up, the owner
    dragged round it.
  - Deadpan (after Cornella): flat bright colours, blank smiles, one dark
    joke that plays out whatever the dog does.
  - Gaudi's house: curved walls, the mosaic, a chimney-pot roof garden as
    the exit.
- **Homage, not imitation.** The rooms borrow a way of seeing, never a
  specific work or a character. The artists' names stay out of the game:
  estates guard them (Picasso and Dali both as trademarks), and this game
  has already been renamed once over a trademark. Banners name the show
  ("EL SOMNI", "LA LINIA"), not the artist. Cornella is alive and working;
  his style is the most distinctive and the easiest to cross the line
  with, so that room waits until the others show how close is too close.
- **Order.** After the walks themselves: one room first, as a test of the
  door, the scene change and the way back out, then the rest.

## Pickpockets (a system for most walks)

Santtu: "pickpockets would really suit many levels, if not all of them, and
stopping pickpocket should be a big goal too. there could be many ways to
stop one, like tangling, bumping (wallet lost if falling into a manhole tho),
slipping, all pretty slapstick of course, nothing too violent."

- **The tell.** A pickpocket is readable before he strikes (the design
  contract: predictable, never a surprise): cap pulled low, sidling up behind
  a mark, a tiptoe walk, a glance over the shoulder. The lift gets a beat:
  the hand goes in, a small "!" over the mark.
- **The mark.** Anyone in the crowd, and the owner above all: a human who
  never looks up from the phone is the perfect mark. He takes wallets, never
  the phone (the phone is the walk's fail state and stays the owner's
  problem).
- **The getaway.** With the wallet he runs, weaving the crowd toward a side
  street. The wallet is drawn in his hand so the player can follow it.
- **Stopping him.** Every stop is slapstick; he falls over, drops the
  wallet, sits up dazed and slinks off. Nobody gets hurt.
  - Tangle: the leash across his path wraps his legs; he hops and falls.
  - Bump: the dog charging at run speed bowls him over.
  - Slip: fish meltwater, oil, wet paint, a dropped ice cream, a banana
    skin from the fruit stall.
  - Trip: a seller's blanket pulled at the right moment, a chair, a kerb.
  - The owner: flung by the whirl into him, phone still up.
  - The manhole: knocked over next to an open manhole, the wallet drops in.
    He is stopped, but the wallet is gone ("...plop"): a stop that earns
    nothing.
- **The return.** The wallet pops into the air and lands; its owner picks it
  up, and a crowd near by applauds the dog. Returning the owner's own
  wallet is worth the most.
- **The goal.** A big goal on the walks that have pickpockets ("Stop a
  pickpocket", "Stop 3", "Stop one without the leash touching him", "Save
  your human's wallet"). If a pickpocket gets away with the owner's wallet,
  the results card says so.
- **Where.** Every crowded walk: La Rambla the most, then El Mercat, El
  Gotic, L'Estacio, La Castanyada and the beach. On walks with no crowd, a
  local stand-in with the same verbs: a squirrel lifting a picnic sandwich
  in El Parc, a magpie taking something shiny in El Bosc, a seagull taking
  a chip at the beach.

## Order

1. Footprints and tracked sand/snow (shared by every walk).
2. El Bosc and El Parc: make them two places.
3. Pickpockets: the thief, his tell, the stops and the goal, first on
   La Rambla, with La Rambla's stalls, blankets and crowd.
4. The La Rambla clones: El Diluvi, L'Estacio, Les Obres, La Ferralla - cut
   the borrowed terrace and crossings, give each its own furniture and its
   substances in their real shapes.
5. The market clones: El Gotic, La Castanyada, then El Mercat itself.
6. El Mosaic, La Neteja, the beach additions; pickpockets and their
   stand-ins on the other walks.
7. The off-leash areas, each to its walk.
8. El Barri as the first walk, then the tutorial rebuilt on it as stations.

Path shapes run alongside: stage 1 comes with each walk's own PR; stage 2
(islands) before El Parc's pond split; stage 3 with Les Obres; stages 4 and
5 are their own projects, El Gotic's turns first.

Detours come after the walks: one room to prove the door, then the rest.
