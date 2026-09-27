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
- Is: a tree-lined promenade, lawn on one side, bike lane and traffic on the
  other, café terrace, human statues, the Canaletes-style drinking fountain.
- Signature line: vault round the plane trees of the slalom, grind the
  planter kerbs, dodge the riders at the crossings, fling the owner off a
  lamppost into the terrace.
- Keep: slalom, terrace, crossings, the FUR-GONETA, the lawn and picnics.
- Add: a newspaper kiosk and a flower stall as landmarks; planter kerbs
  worth grinding; the fountain as the drink stop.

### El Parc (park) - the city park
- Is: open lawns, flowerbeds, the pond with its bridge and ducks, a
  bandstand, a playground.
- Signature line: grind the flowerbed edging, cross the bridge (the pond is
  the gap), loop the owner round the bandstand posts.
- Keep: pond, bridge, ducks, lawn verge, tree slalom.
- Add: low hedged flowerbeds (grind), a bandstand landmark, a playground
  corner (temptation), pigeons at the benches.
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

### La Neteja (neteja) - the back street at dawn
- Is: a narrow street at street-cleaning time: dumpsters, parked scooters,
  shutters down, delivery crates, wet streaks where the water truck went.
- Add: wet streaks and puddles, dumpsters, scooters, shutters, dawn light.

### First Walk (tutorial)
- Follows La Rambla's restyle, calm by construction.

## Order

1. Footprints and tracked sand/snow (shared by every walk).
2. El Bosc and El Parc: make them two places.
3. The La Rambla clones: El Diluvi, L'Estacio, Les Obres, La Ferralla - cut
   the borrowed terrace and crossings, give each its own furniture and its
   substances in their real shapes.
4. The market clones: El Gotic, La Castanyada, then El Mercat itself.
5. El Mosaic, La Neteja, the beach additions, La Rambla's additions.
6. The off-leash areas, each to its walk.
