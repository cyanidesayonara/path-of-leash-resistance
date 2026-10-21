# Changelog

Append-only session history, newest first.

## 2026-10-21 - The leash goes round a stall

- A leash pulled across a stall, a van or a bench could settle inside the body. It drew straight over the counter, and the pull held your human on the face they could not walk through. The strap now runs round the outside, and that pull walks them round the end.
- `tests/test_leash_height_geometry.gd` checks a strap laid across a body stays out of it.

## 2026-10-21 - El Besòs, the floodable river park

- A new walk between L'Estació and Les Obres, open at 14 stars. Every older gate is unchanged. The way out is a warm afternoon: flood wall, paved path, grass, a margin you can wade, and a deep channel you cannot enter. The meadow at the far end is off the leash.
- The way home is the river. Shallow water pushes you south, wets your human and loosens your steering; planting holds a spot and lets the deep front close. The deep front, and the swell reaching in from the river, is the loss. A raised apron stays dry while the water is held, then spills. No Tofu.
- The flood uses the same chase as the sweeper: warning, head start, camera, checkpoint, continue. Your human hears the siren and decides it is not their problem.

## 2026-10-21 - Every walk ends at its own door

- The loose HOME letters are gone. Crossing the home line with both of you starts a short arrival instead of the card: Millie pulls toward the way in, your human looks up and pockets the phone, she goes through, they follow, and the leash goes with them. The first half-second plays out; after that, confirm or back brings the card. The walk clock stops at the line. Nothing else moves: no input, no hazard, no phone damage, and a chase threat holds at the line.
- Most walks come home to the green street door from the intro (tiles, shutters, geraniums, an intercom, a warm hall). It stands open behind you and shuts once the walk starts. L'Estació, Montjuïc and Dia de Partit come home down stairs under a canopy. El Bosc comes home through the trailhead gate, and El Besòs will come up the emergency ramp. Rain leaves wet pawprints, snow sits on the sill, and night lights the way in.
- An autowalk still finishes on the frame it crosses, at the same time.
- New `tests/test_arrival.gd`, in CI.

## 2026-10-21 - Weather, hour and lamplight

- Rain, wind, snow, night and La Neteja's dawn now each have their own light. The world tint, the grade over the mood, and the lamps agree: night is a deep blue with a closer vignette, and a lamp is drawn bright enough that the tint does not turn it grey. Rain darkens the mids and adds a wet sheen; snow is bright and cold; wind is a warm haze. A clear day is exactly the picture it was.
- Lamps along the walk (the posts, and a lamp on the wall where a post is far) pool on the ground under the trees, and stay warm after dark. Rain breaks a little of that light on the wet. The phone does the same. A chalk stroke or a lit board stays the colour it was painted, and the line under a walk's name stays light on its dark chip.
- New `tests/test_sky.gd`, in CI.

## 2026-10-21 - Loss titles keep their last letter; walk names read in plain type

- A lost walk's title was drawn clipped to the card. "YOUR HUMAN WENT DOWN THE MANHOLE" lost the last stroke of its last letter, and any longer title would too. A heading now shrinks until the words and their outline sit inside the card, and the card itself stays on a narrow window. The body wraps instead of being cut.
- Choosing a walk no longer depends on reading the name out of leaves, sand or chalk. The plaque under it says the name and the English line in large light type on the dark card, and YOUR WALKS, pause and THIS WALK use the same. The line under the name as a walk begins sits on a dark chip that stays light-on-dark at night.

## 2026-10-21 - No more Daily Walk; a walk's own sky stays on that walk

- The Daily Walk is gone. The walk select is the first walk, then the campaign walks. Every walk can be played in any weather, day or night, from GET READY. Its share card, the SHARE touch button and the daily best go with it. An old save's daily section is ignored and dropped on the next save.
- Browsing the walk select past a walk with its own sky no longer leaves that sky on every walk after it. El Diluvi, La Castanyada and the first walk wrote their rain, their dark and their clear day over the player's GET READY choice, and so did the daily. Now `Game.apply_walk_sky` sets the walk's own sky for that walk only and gives the player's choice back on the next one. On GET READY the row the walk decides is fixed; the other row is still yours, and that choice carries on.
- Store listing, privacy text, itch page, README and LEVEL_DESIGN no longer mention a daily walk.
- New `tests/test_walk_sky.gd`, in CI.

## 2026-10-21 - Tofu only hides where Millie can reach her

- "Bring Tofu the cat home" could not be finished on most walks. Her seven hiding spots were fixed offsets from the walk's centre line, so where a walk bends or has furniture they landed off the path, in El Parc's pond, or inside a solid prop. Her darts between them ran through stalls, benches and buildings, so she seemed to jump into the side of the street and vanish. Her last spot was past the home line, so the walk could end while she was still running to it.
- She now hides only on open path at her own point down the walk. Each spot is checked against the walls, water and anything solid, and each dart is clear: straight where it can be, round the obstacle through one or two waypoints where it cannot. Where a wall runs down the middle of the path (L'Estació), she stays on one side of it. Her last spot is short of the home line.
- New `tests/test_tofu_spots.gd`, in CI: on every walk with the goal, every spot and every dart is reachable, open ground. El Barri is herded with the real dog, and the goal banks to the record.

## 2026-10-21 - The sweeper scoops you up instead of parking on you

- Caught by the sweeper, Millie and your human no longer stand on top of the machine until the card comes up. The one who reached the brooms first is lifted up into them and tumbles to the side; the other is dragged in after, a beat later, turning the other way. The leash follows both, the handle staying in his tossed fist.
- The catch is decided at once and the walk freezes for the beat: bodies, rope, walk clock, bikes and every other walker stop, and pause and restart wait for the card. Only the drawing moves.
- The machine itself has more to look at: tyre tracks and comb marks in its wake, bristle tips and hubs on the brooms, wheel hubs, a council fleet panel, a bigger windscreen with a divider and glint, a darker bumper and two headlamps. It is still one draw call.
- Continue clears every part of the catch pose.
- Tests: the catch is now also checked with real frames and a real pause press.

## 2026-10-20 - Chase framing shows the danger before fear

- Chase-only framing now leans toward an approaching threat earlier while preserving at least 110 rendered pixels of escape runway across desktop, landscape-phone and portrait framing. The cap accounts for leash separation, camera smoothing, shake and live southward speed, including turbo.
- SCARED cannot begin building until the threat's authored leading edge is at least 48 rendered pixels into the view. The sweeper explicitly identifies its brush line; the same shared hook is ready for El Besòs's shallow flood edge.
- Current, moderate and strong framing were compared in deterministic desktop, landscape-phone and portrait captures. The strong curve was selected, then bounded by the viewport-aware safety rule.

## 2026-10-20 - 1.61 notes include the chase, the dare and the browser sound

- The itch and Store notes for 1.61 now mention La Neteja's warning, head start and continue, the dare kid clear of the trees, and the browser build having sound again.

## 2026-10-20 - La Neteja's chase gets a head start and checkpoints

- Leaving the destination now takes a checkpoint, then gives the warning (1.2 s) and a 3-second head start. The sweeper does not move, catch or scare the dog until both are over, and the banner counts the head start down. Held or jammed, the machine adds no fear; what the dog already has fades on its own.
- The sweeper held at the later dumpster jam (near y -1900) takes the midpoint checkpoint. The first jam is a respite only.
- Lost on the way home with a checkpoint held, to the sweeper, a smashed phone or a fall, the end card offers continue instead of try again. Continuing puts the walk back in place: business, leash, phone, bones, goal counters, pickups, combo, the kid's dare, both walkers and the machine come back as they were, so nothing is paid twice or lost. From the destination the warning and head start repeat; from the midpoint the machine sits at its jam for a 3-second countdown and rolls the moment it ends. The walk clock keeps running, and nothing reaches the save.
- Pause START AGAIN, a fresh restart, the walk select and any other walk drop the checkpoint. A loss on the way out is still try again.
- `--at-home` starts the selected walk already turned for home, past the star gate, and writes nothing to the save.
- New `tests/test_chase_checkpoint.gd`, registered in CI.
- Review fixes:
  - The midpoint is never taken while a catch is rolling or with either of you at the brooms. Such a jam keeps the earlier checkpoint.
  - A continue ends any teeter, grind or pole swing in progress without paying or failing it, and keeps their cooldowns.
  - The test now plays real frames after each kind of continue.
  - Continuing clears the catch's shouts, so "SWEPT!" does not hang over the new warning.

## 2026-10-20 - La Neteja gets a chase profile

- The chase now has a profile per walk (`systems/home_chase.gd`): threat script, fixed behavior and speed, warning and caught copy, and an empty list of bands for the checkpoint work to fill. La Neteja's is the street sweeper, every run, with an oblivious human; the kind draw is still made so seeded walks replay unchanged, and its result is ignored. `--chase`, `--bolt` and `--rescue` still force their named behavior.
- La Neteja stops carrying the market skeleton's four bins; it has two of its own at the kerbs. Its pee posts and snacks are listed in its own builder, in the same places as before.
- New `tests/test_chase_walk.gd`, registered in CI.
- Review fixes: the chase holds the profile it began with (`main.chase_profile`) and reads its catch copy from it. The two bins really stand at the kerbs now (the corridor fit had pulled them in towards the middle of the street), and the sweeper's brooms swing in round them like the dumpsters and scooters. `hook_kind` is now `kind_behavior`. The bins' solid and rope-wrap copies in the poles list are put back at the kerb after the corridor fit, so the collider, the rope and the drawing agree.

## 2026-10-20 - The browser build has sound again

- Godot 4.7's web sample mixer inserts a bus added at runtime before Master, then disconnects Master from the speakers. The procedural soundtrack added its Music bus that way, silencing both music and effects in every browser. The bus now takes the web-safe append path. Native audio is unchanged.

## 2026-10-20 - The dare kid sits out from under the trees

- El Barri put the kid's bench directly under a plane-tree crown. The dare now tries the other side of the walk, then the nearby clear spots, whenever its usual place is under a tree. All sixteen walks check the clearance.

## 2026-10-20 - What's new for 1.61

- The Store and itch notes now describe everything since v1.60: Dia de Partit, the redrawn walks, the leash catching what you can see, and the finished intro. Nothing is tagged.

## 2026-10-20 - Horse droppings are a real substance

- The away march leaves something on the avenue, and the world draw looked that kind up every frame. `stinky` was not one of the substances, so Dia de Partit logged an error for as long as a dropping was there. It is one now: a dark patch, and stinky paws if she stands in it.

## 2026-10-20 - Montjuïc's esplanade stops drawing an empty hill rim

- Looking at the castle square asked the hill outline for a line with no points. A view that does not include the climb now skips that stroke. The rim on the climb itself still draws.

## 2026-10-19 - Dia de Partit, the goals and the words

- The twelfth goal is to keep your human out of the away march. It completes once the column has gone by and they were never carried. The results card shows the score the phone was watching.
- The match-day arrangement answers itself: bongos one bar, claps the next, under the whistle. No chant has words.
- A text test rejects a real club, stadium, sponsor, player or motto in the walk's scripts. The Store and itch listings count sixteen walks.

## 2026-10-19 - Keep the off-leash signs clear

- Tree crowns and long sniffable props now keep out of the two-line place sign beyond every off-leash space's far fence. El Bosc and El Mosaic no longer put three trees through the words.
- A regression checks every tree, log and piece of driftwood on all sixteen walks.

## 2026-10-19 - Dia de Partit, the corners

- The side street east of the avenue has three kids and two jackets. A yell comes first, then the ball rolls across. Bring it back, or drop it between the jackets for gol! +5. At kick-off the kids go inside and the jackets stay.
- Before kick-off a kid on her dad's shoulders loses her scarf. Wind takes it; a calm day it slips. It lands at the edge of the river, they wait by a lamppost, and bringing it back is good dog! +6.
- Two pickpockets work the avenue before kick-off, and none after. The man by the gates looking shifty is selling tickets. Three fans' dogs walk down in home shirts. The bar leaves a water bowl by its door.

## 2026-10-19 - Dia de Partit, El Xiulet Final

- Passing -3000 on the way home, once the match has been going a minute, is full time. Three whistles, then four seconds of noise from the stadium, and the banner says FULL TIME! THE CROWD IS COMING. Then the whole crowd pours south. A win is faster than your human walks, with confetti and a drum. A draw murmurs. A loss is a slow crowd, and the easy walk home. The score is on the phone.
- A slack human against a median lamppost or the barriers is not carried. A taut leash across the flow still drags. Two fans' dogs come out with the crowd. Nothing about it is a chase.
- Beat the crowd home if no fan of that outflow gets past the dog before home.

## 2026-10-19 - Dia de Partit, La Marxa

- An away column comes south down the east side of the avenue. A siren and a drum start at least four seconds before it arrives, the banner says AWAY FANS, and the crowd shifts west to let it through. Your human steps wide of it. Walking into it turns them around and carries them back; it costs patience and does not crack the phone.
- Four mounted officers box the column in. A horse is a solid body, not a rope contact, and a shoulder is one crack, the way a bike is. On the way home they stand in a line and the sausage is under them. A snort and a tail swish come first, and a dog underneath gets bumped.
- The horses leave droppings. They are a slow patch and the best sniff on the street. The unattended walk waits by the median until the column has gone by.

## 2026-10-19 - Dia de Partit, El Gol

- Goals come on a seeded schedule once the match is on: the first no sooner than 25 seconds after kick-off, then at least 35 apart, and at most three. One of them can be the other side, and one can be waved off.
- The stadium goes "ooooh" for a second and a half, the floodlights flicker, and then it roars. Beside your human, she gets the zoomies. Anywhere else it is a fright, louder near the bowl. A second later your human celebrates ("gooool!", two hops, planted) or slumps ("no...") or says "WHAT?" when it is disallowed. A whirl is never planted.
- The bar's chairs jump and a few crisps land on the pavement. Now and then a flare climbs off the east side, hiss then bang, and the free dogs in the square flinch and run a lap. `--goal-in=S` forces the next one.

## 2026-10-19 - Honest waist-high leash collisions

- Cars, vans, stalls, benches, dumpsters, barriers and the train now catch the leash on a close outline of the body you can see, rather than a few oversized invisible points. Furniture still slips free under a sustained pull, standing in for the owner lifting the strap over it.
- Low clutter stays out of the leash plane: hydrants, cones, manholes and A-stands do not become anchors. Parked scooters clatter over under a body or a taut strap instead of holding the pair fast. People and moving bikes remain non-anchors; other leashes remain the intentional tangle.
- New regression coverage in `tests/test_leash_height_geometry.gd`.

## 2026-10-19 - El Diluvi's umbrella crowd walks

- The shopping street is no longer four people standing in the rain. Twenty-eight shoppers stroll both ways along the covered edges, on the same crowd list as the match-day river, and they leave the middle of the street clear. They jostle past each other and step around the pair. They are not rope contacts.
- A taut leash across them is a small shove, not the stadium's carry, and your human's pace is unchanged. Their umbrellas are the filled canopies, drawn above the leash.
- The four-person huddle is still there, clogging its two spots.

## 2026-10-19 - Dia de Partit, the kick-off clock

- The walk has a match clock. Kick-off is 210 seconds along, or the moment the pair reach the gate, whichever comes first. The last 25 seconds before the clock wins, the PA says "falten cinc minuts" with "five minutes left" under it, the banner says KICK-OFF SOON, and the crowd breaks into a jog.
- The whistle comes from the stadium, then a roar, and over eight seconds the crowd peels off east into the gates. What they drop is left on the avenue. After that the street is a few late runners and the bar's terrace, and your human's phone is the match: a green screen, the score in the corner, a slower pace, and the odd "come on...". Passing BAR LA PENYA, they say "ooh, the replay..." and drift over to the window, unless the dog hauls them off.
- New test `tests/test_match_day.gd` (in CI).

## 2026-10-18 - Dia de Partit, the crowd river

- The avenue fills as you walk north. Fans are data, not people: up to 150 of them in one list, drawn together in one batch at 30 fps, darker and smaller than the pair so the two of you still read. A fan is a coarse dot, not a full circle, so the crowd stays under a millisecond on top of the street. The side street stays thin; the gates are the thickest. A few vendors walk back through them.
- They step aside for the dog and your human, and they walk round stalls and barriers. They are not rope contacts, so the leash solver is unchanged. A slack leash gets a hop and a little "hup". A taut leash laid across the flow drags the pair along with it, and your dog can dig in against that. A taut leash that already runs with the flow does nothing.
- Where the street is packed, your human is carried: the crowd shifts where they mean to go and adds to their pace on the way out (or takes a little off it on the way home). How hard they walk does not change, and they still get there.
- New test `tests/test_crowd_river.gd` (in CI).

## 2026-10-18 - La Neteja audit fixes (#161)

- The dumpsters are steel bins: castors, two ribbed lids with grab handles,
  a handlebar at each end, and the bag that did not fit. They are still
  solid, and the street is still runnable past them.
- The roofs no longer repeat one air-conditioning unit every module. Each
  lot is its own pantiles or terrace, the way the old town's roofs are, and
  the shutters along the kerb are slatted, tagged and padlocked. One bakery
  near the top of the street is half open, with its light across the setts,
  and the low sun lies in soft bands down the street.
- The water truck's wet streaks feather out at the edges instead of ending
  in a hard line. The washing overhead was already shirts, sheets and socks
  on a sagging line; that finding did not need another pass.
- The posts down the middle are the lamppost slalom. They had been drawing
  as street trees, crown and grate, in the middle of the alley.
- What sits by each dumpster is a stack of delivery crates. It had been a
  warning cone on top of a crate. The market layout's open manholes, and
  the four cones round each of them, are gone: one of them was in the lane,
  and your human walked straight down it. A hydrant the east dumpster had
  been parked over is up the kerb, clear of the bin.

## 2026-10-18 - the dog slides along what she touches, and stays out of your human

- The v1.60 playtest kept logging DOG STUCK at the same spots. Most were the scripted steps holding a direction straight into something: El Mercat's first stall block and its corner column, El Gòtic's bin by the east wall, a south face in La Ferralla's yard, the mosaic fountain block in El Mosaic, and L'Estació's ticket barrier and the train's end. A player pressing into a wall does not move, and that is right.
- One was a real snag. The dog was a grounded CharacterBody2D, the platformer mode, in a top-down game. It took every south-facing face for a ceiling and, while she touched one, threw away any speed that was not upward. Against a stall block with its column beside her, holding sideways moved her at 5 px a second instead of sliding her round. North faces were floors, with slope stops on round props. She now moves in floating mode with no minimum slide angle, so she slides along any face and round any post at the angle she meets it, and the speed she had into a face is dropped instead of kept.
- Walking dead on into a pole beside your human, she ended up on top of them: the two bodies do not collide, so the leash physics owns every pull between them. Now a soft push parts them each frame they overlap. She takes most of it while she is on the move; standing still or dug in, she is not pushed at all. Your human takes the rest, as a step back and to the side. When a wall holds her, they start the usual sidestep round her. It is not a collision, so the rope and the tug of war are untouched, and it stands off during an orbit and off leash.
- `tools/playtest.gd` reports DOG STUCK only for a stall a player would not expect: a second within 4 px of where it began (not one that happens to end there), with a direction held toward open ground for at least half of it. Held straight into a face, into a corner (a block and its column, a bin by a wall) or into your human, or dug in, squatting, tumbling or dragged, is not a stall. Held along a face and not sliding still is. The line now says what she meant, her velocity, what she is against, the leash and where your human is.
- New test `tests/test_dog_bodies.gd` (in CI): she slides along the underside and top of a block, round El Mercat's corner column, and round a pole pressed nearly dead on from above or below; walked into from behind against a pole she is never inside your human, they step round her, and a walled-in dog makes them sidestep.
- `tests/test_mercat.gd` pushes her at each drawn wall to prove nothing invisible stands inside it. Floating, she now slides along the street's slanting walls toward the arch instead of stopping, so it measures the gap to the wall where she stops, not where she set off.
- Playtest, market, oldtown, scrap, guell and station, three scripts each: 22 DOG STUCK before with the old check, 17 with the old check after the fix (all pressing into faces), 0 with the new check, before or after.

## 2026-10-17 - Dia de Partit, part 1: the streets to the stadium (#238)

- A new walk, DIA DE PARTIT ("match day"), opening at 27 stars after
  Montjuïc: the walk through Les Corts to a stadium that is never named. This
  first piece is the corridor and its set dressing; the crowd, the kick-off
  clock, the three set pieces and the walk's own goals come next (the plan is
  in docs/superpowers/specs/2026-10-17-dia-de-partit-design.md).
- A calm side street to start: plane trees, parked cars, a drinking fountain,
  a grandad out early in his scarf, SEMPRE AMB TU strung across the street,
  home flags (blue and claret halves, a plain white star) on the balconies.
- The corner where the police have closed the avenue: CARRER TALLAT on the
  barriers, a navy van with its blue lights turning, two officers chatting,
  a zebra crossing.
- The avenue: four lanes closed to traffic, lampposts on islands down the
  painted median (wind your human round them), blue-zone parking bays, plane
  trees in grates on the sidewalks, bunting overhead, and steel crowd barriers
  along both kerbs that grind with the zoomies (BARRIER RUN). Along it the
  scarf stall (BUFANDES), the seed and water cart (PIPES I AIGUA) with seed
  shells round it, BAR LA PENYA's terrace out on its deck in the parking lane,
  and the sausage stand (ENTREPANS).
- The stadium approach: the road ends at a kerb and the stadium's granite
  paving begins, FINS AL FINAL strung across it; the ticket windows
  (TAQUILLES) with their queue belts, the drummers on their stand, floodlight
  standards, and down the east side the stadium itself: its wall, gates PORTA
  9 to 11 with barrier lanes into them, stair towers, and L'ESTADI on the
  roof.
- Off the leash in PLAÇA DEL GOL, "goal square, off leash", with the bowl
  past its top edge: the outer wall and stair towers, the roof and its ribs,
  the stands, and the floodlights' glow at night. The same agility course,
  rope tug and frisbee as everywhere.
- The walk's name is written on the ground in sunflower seed shells, the
  litter of every Spanish stand. The city's cast-iron bollards are what she
  marks here.
- A first arrangement of the soundtrack for it (claps and a driving bass
  under the whistle), until the match-day mix.
- Goals for now: the staples and the prize, a sausage fallen off the grill
  (it moves under the police horses with the march). No Tofu on this walk.
- The ground, the stalls and the blocks are drawn onto the cached edge layer
  in one batch, and the walk's name is laid in seed shells drawn without a
  transform per shell, so the whole name is one batch too. Over a 40-second
  autowalk on Windows: 109 draw calls a frame at the median (228 at worst)
  against La Rambla's 181 (258), world draw 1.2 ms against 6.9 ms. In headless
  Chrome (tools/web_perf.sh, on a busy machine, so only the comparison
  counts): 93 calls against 172, frame p50 27 ms against 62 ms.
- Behaviour snapshot: every other walk is byte-identical; the new lines are
  Dia de Partit's own (autowalk finishes at 120.0 s, both soaks clean,
  selftest OK).
- `systems/partit.gd`; `tests/test_partit.gd` in CI; in every level list (the
  CI selftest and smoke sweeps, the soak matrix, the shot, perf and idle-soak
  sweeps, the behaviour snapshot, the terrain and off-leash audits, the junk
  and NPC placement tests). The stroke letters gain the figures 0 to 9 for
  the gate numbers.

## 2026-10-18 - La Castanyada audit fixes

- The street between the festival points is never bare paving: three more stalls in the gaps (chestnuts near the start, sweets before the plaça, sweet potatoes after it), every stall lit with a warm pool off its counter and a string of bulbs along its front, and the fronts lamp-lit all the way along, with doorways and shop windows glowing out across the pavement and a wall lantern now and then. The lights are on the overhead layer, with their colour divided by the night's tint so they come out warm instead of grey under it.
- The roaster is the plaça's landmark: a castanyera's cart half as big again, on two big wheels with its shafts out the front, the brazier drum glowing under its chestnuts, a stovepipe chimney pouring smoke, sacks and paper cones on the counter, a lamp at each corner, and its fire lighting the plaça. Six people queue for it off its south-west corner, facing the cart. It stands a little east of the middle, and the bench moved further off, so walkers keep their lane past it.
- The off-leash plaça is the festival's own yard, not El Gòtic's square again: a timber dance floor laid on the paving, three lantern strings overhead from wall to wall, lit windows all round, chestnut shells, paper cones and confetti everywhere, and the planters are castanyeres' braziers with sacks of chestnuts by them. Its sign reads "the festival square, off leash".
- No crate on the chestnut PLAÇA letters: the walk's background litter could step past the gate into the off-leash space, and on La Castanyada it no longer does.

## 2026-10-18 - El Mosaic audit fixes

- The serpentine bench reads as a bench, not bunting: the seat is tiled edge to edge in two courses of broken tile over white, the mortar showing between, with a rolled white backrest along its outside and its shadow falling off it. The plaza has people in it: a pair or one in each of the bench's bays, photographing the view out over the city, on top of the crowd and the fan seller.
- The hypostyle hall is a forest: six columns across and nine deep (54, was 20), the owner's lane still clear down the middle. Its shade thins out gradually at each end instead of stopping at a hard line. The columns, with their shadows, no longer break the world batch (their contact shadow was a transform, which flushed it).
- The viaduct is a covered walk: a colonnade of rubble columns like palm trunks down its east side, the outer row leaning into the hill and an inner row staggered behind it, the road's shade over the walk between them. The slope on its west is one smooth bank of dry grass with scrub, stones and a rubble kerb, tapering at both ends, instead of a row of green blobs.
- The calvary is a heap of rubble stone with steps up its south face and three stone crosses on it, the middle one tallest, each throwing a long shadow. It sits inside the path now rather than half in the wall.
- The salamander climbs out of the dragon stair's stepped grotto fountain, three ragged tiers with a trickle down each, into a basin with a trencadis rim, instead of sitting on a flat slab. The dragon stair has its steps all the way up.
- The off-leash space past El Calvari is a dry hilltop, not a lawn: packed ochre earth worn pale in the middle, bleached grass, stones and scrub between the pines, and the wood beyond it in dusty olive. Its sign reads "the hilltop, off leash".
- Gameplay: the extra columns in the hall and the viaduct are real poles. The behaviour snapshot's autowalk reaches freedom at 28.7 s instead of 30.1 s and the home leg at 44.8 s instead of 46.6 s; idle soaks and the self-test are unchanged.

## 2026-10-18 - El Bosc and First Walk audit fixes

- El Bosc's pinch at -2000 is crowded with trunks on both edges at once, about one every 80 px, staggered, so the trail narrows between them like a gateway and there is a trunk to wind the leash round at every step. Before, one tree stood on alternate sides every 80 to 100 px. The autowalk, soaks and selftest are unchanged, and a playtest through the pinch found no problems.
- The First Walk's quiet lessons (the leash, marking, sniffing, the nose, barking, the zoomies, business and the vault) each have a park bench mid-path, and your human waits sat on it, on the phone, as the design brief says. The dog cannot walk through a bench. The tetherball, ledge and brink lessons keep your human standing where the lesson needs them.
- No grass tufts grow on the brink lesson's pond.
- "Move on" is a key cap in a prompt bar under the lesson card, for whichever device is in hand, instead of "(C to move on)" written into the lesson's sentence.
- The grind lesson already had its stone ledge (the kerb the finding missed), so that finding no longer reproduces.

## 2026-10-17 - El Barri audit fixes

- El Barri's props are authored where they stand instead of being squeezed into the path, which had pushed the petanca players onto their pitch's edge, the ping-pong table off its prize and the trees into a ruled line on both edges at the same heights.
- The plane trees stand in two rows that do not mirror, with uneven gaps, set in far enough that their shadows lie on the gravel instead of being cut by the lawn's edge.
- The petanca pitch lies on the gravel, raked, in a timber edging. The three old men are on it: one throwing from his circle, one waiting with his boules, one bent over the jack with the boules gathered round it. No litter lands on the pitch.
- The playground is on the lawn beside the path, not across it. Its swings are seen from above (the bar, the splayed legs, the seats swinging under it), and the spring rider is a blue horse, no longer a red post that read as a hydrant. El Parc's playground shares the drawing and gets the same swings and horse.
- The drinking fountain is a green cast-iron column with its spout over a grate, a dog's bowl at its foot and wet gravel round it, at the west edge, instead of a small grey bowl in the middle of the path.
- People picnic and shrubs grow on the lawns either side, where the walk had long empty stretches.
- The pipicà is a pipicà: sauló with paw prints inside a green steel mesh fence on all four sides, the run along the walk's end drawn on the line its collider takes, an iron gate as wide as the path, plane trees, sniff posts, planters, a bag dispenser and a bin. No fallen logs. The city-block roof that showed as a grey slab inside the gate is gone (the edge layer draws nothing on this walk, which was hidden under the lawn everywhere else).
- The autowalk reaches the pipicà a second sooner (27.7 s, was 28.7) and home at 34.7 s (was 36.1), from the moved trees and benches; its soaks and selftest are unchanged.

## 2026-10-18 - L'Estació audit fixes (#155)

- The concourse floor is polished terrazzo instead of the street's tan paving: pale grey panels with brass divider strips, marble chips set in them, and the roof lights' reflections lying across the polish. No drain grates, road repairs, cracks or damp stains indoors.
- The ticket barriers are a row of steel gate cabinets, each with a black glass top, a card reader with a yellow ring and a green arrow light. At each gap the glass paddles are swung open, with a yellow line on the floor where you tap. The pillars are round iron columns standing on square granite plinths instead of plain squares.
- The two strips that read as mismatched walkways are now plainly two things. The moving walkway is a steel travelator: grooved treads with joints moving the carry way, arrows in the tread, black handrails on glass balustrades, and comb plates with a yellow edge at each end. The white strip was the train, and now it looks like one from above: a dark grey roof with air-conditioning pods, a pantograph on every other car, black gangway bellows between the cars, the white and red Rodalies livery down its sides, and the cab's windscreen and headlamps at the front.
- PIPICÀ is the station's old goods yard instead of a lawn: big concrete slabs with a rusted siding still set into them, running to a buffer stop, brick walls, and bike stands by the gate. Past the far wall are the running lines, with ballast, sleepers, two tracks and the catenary, and the station's sheds on either side.

## 2026-10-17 - El Diluvi audit fixes (#152)

- The open storm drains no longer read as a cafe table with its chairs out in the rain: four cones evenly round a dark disc did exactly that. Each drain now has a striped works board along each side and one cone ahead of it and one behind, the way the street walks.
- The terrace the brief cuts is now on the walk the way a terrace is in a downpour: two stacks of rattan bistro chairs and the folded tables by the east kerb, chained to the lamp standard at y -2800 with a padlock, rain standing on the top seats, and the cafe's sandwich board out beside them. The stack is solid and your human aims wide of it.
- The roofs either side were flat grey with the odd skylight. Now they are wet pantile roofs and tiled terrats with water tanks, parapets, chimneys, rain standing round the roof drains, brick party walls, and zinc gutters running full along the eaves. The arcade's roof is pantile too, with its gutter running over the columns.
- Umbrellas are filled canopies from above, eight panels in light and shade, the ribs out to their tips, the ferrule in the middle and drops running off the rim, instead of an arc that read as a horseshoe magnet. Buskers on any walk in the rain carry the same one.
- EL PORXO is a porch yard instead of the sunny dog park: a court of wet sauló with puddles and the grove's trees, a covered porch round three sides (terracotta tile in the roof's shade, stone columns along its open edge, a drip line where the eaves shed), stone walls and gateposts, downpipes into the court, and the porch roofs and the block's water tanks past the walls.

## 2026-10-17 - La Ferralla audit fixes

- The wreck stacks are four kinds of car - a saloon, a hatchback, an estate van and a stack of crushed bales - in faded paint gone to rust, each car in a stack turned its own way and the top one changing kind and colour down the lane. The tops have rust patches, dents, a door missing or a wheel left lying on the roof, and the glassless windows show the seats. Same spots, same colliders.
- The crane is a crawler crane: two tracks, the house slewed toward the jib with a striped counterweight, grille and exhaust, the glazed cab on its front corner, and a tapering lattice jib with pendant ropes out to the sheave and a striped hook block on its falls. The jib and hook are drawn overhead, above the dog and your human, and their shadows lie across the lane.
- The strips along the fences are oily gravel: grit, oil soaked into it, a lost bolt, and only now and then a weed or a thistle. No lawn and no flowers. They play as before.
- Rust streaks down the shed roofs from the ridge, every roof its own; some have a patch rusted through. No more grid of rust discs.
- EL PATI is the scrapyard's back lot. Where a park has trees there are tyre stacks and groups of oil drums, on the same spots and as solid as the trunks were. Lengths of steel pipe lie where logs were, and a wheelless car on blocks sits in the north-west corner over its oil stain (solid, tucked into the corner so there is no gap to get stuck in). The behaviour snapshot for the walk is unchanged.
- The laser and the camera shouted "THE THE LASER SAW YOU!": the name already carries its "the".

## 2026-10-17 - Les Obres audit fixes

- The building line on Les Obres is a run of Heras fencing: mesh panels between concrete feet (the odd black rubber one), a coupler at each joint, a sandbag here and there, and now and then a contractor's banner. From straight above the mesh is the lattice of its shadow lying out beside it, solid under a banner. It is drawn on the verge canvas, above the sidewalk its shadow falls on.
- Behind the fence is the works compound, not scaffolded roofs with flat blue rectangles: skips full of rubble, stacks under blue and green tarps with their creases, ridge and ropes and tyres on the corners, pallets of blocks, rebar bundles with orange caps, and spoil heaps with a shovel stuck in. Each is placed at its own y so a bend never pushes it through the fence.
- The footway's dirt has the digger's track marks curving up to where it is parked, survey spray lines in yellow, blue and pink, and gravel, offcuts, a cement bag and planks lying about. All flat; nothing new is solid.
- The two pours are at different stages. The first is just placed: timber shuttering on stakes, dark wet concrete with a sheen, fanned trowel marks and the bull float left on it. The second is screeded: steel forms pinned down, paler and broomed, a wetter band still being worked, starter bars along one edge, the screed bar across it and the barrow beside it.
- Cone lettering no longer clots. Where two strokes meet, one cone stands for both; the cones are a little smaller, letters get more space between them (an optional letter gap in `world/sign_letters.gd`, used only by cones), the foot only peeks out round each cone, and the gate's words are bigger, so EL SOLAR and OFF LEASH read at a glance. The behaviour snapshot for the walk is unchanged.

## 2026-10-17 - a title theme with get-up-and-go, and the intro scored to the picture

- Santtu found the title theme too tranquil ("doodly-doo"). It is the same tune, arranged with drive: 130 bpm and up a step to E, a whistle lead with a glockenspiel over it all the way, chord stabs pushed ahead of the beat, a bouncing octave bass, and a groove (kick, claps on the backbeat, sixteenth shakers) with a bongo fill every fourth bar.
- The intro film has its own score, bar by bar against the picture: a calm pad and the tune's first phrase on vibes while Millie stares at the leash, a glockenspiel sparkle as she grabs it, a light groove for the trot, back to the pad while she waits and sighs, a kick on every beat, a clap roll and a rising bass through the crouch, and the full title theme dropping in on the bark (at 130 bpm the fifth bar ends at 9.23 s), with a stab as the title lands on its leash. When the film ends the title theme takes over from the same point in the music.
- The score renders in about a second and a half, so the film now holds on black until it is ready (four seconds at most) and the two start together; before, the opening played silent while the music built. A press during the wait still skips. The intro is as loud as the title theme after the drop, so the handoff does not dip.

## 2026-10-16 - the intro, redrawn as a finished film

- Santtu's verdict on the Walkies film was that the idea is solid but it looked like a prototype. Everything in it is redrawn to shipped-game quality, and it is cheaper to play than the prototype: fewer draw calls (a room frame about 140 instead of 185, the street about 165 instead of 480) and about half the CPU a frame. The static backgrounds go up once as meshes, and the characters cache their shapes per pose instead of clipping polygons every frame.
- Millie matches the Store box art: big googly eyes, a light grey freckled muzzle, grey brow spots, ears perked up and folding over at the tips, a sturdy rounded body, a pink collar with a silver D-ring, a bold warm-black outline and cel shading with one glossy highlight. She is one draw call.
- Your human is a real cartoon character: a profile with a nose, a lidded eye, brows and a quiff; arms that hang from the shoulder; hands that cup the phone and grip the leash; a T-shirt, trousers with creases and sneakers; and the phone's cool light on the face. One draw call.
- The flat is a Barcelona apartment: vaulted ceiling and beams, striped wallpaper, a window onto balconies across the street with curtains, hard-edged morning sun on the boards and the wall, a kilim rug, the sofa with cushions and a throw, a lamp, a side table, a bookshelf, pictures, the hook rail, the raincoat, her bowl and bed, and a panelled door onto a sunny street. The street is a row of Eixample fronts with persianes, iron balconies and shops with awnings, plane trees, a lamppost, panot paving, and the Sagrada Família in the haze. Both reach the edge of any landscape window.
- The title is the Store logo's: PATH OF small and spaced, LEASH big in red, RESISTANCE under it, each a sticker with a stepped brown drop and a cream keyline. The O is Millie's pink collar, with the leash's snap clip hooked through its D-ring. It drops, bounces, squashes, swings to rest and keeps a slow sway.
- A skip hint (SPACE, A or TAP, for the device in hand) fades in at the bottom right after a second and breathes with a soft gold glow.
- Out through the door: Millie and your human run out through the doorway at full size, against the sunny street, and pass behind its right jamb, instead of shrinking into the doorway and being swallowed by a flood of light (it read as a portal, Santtu said). The portrait over the sofa is Millie face on, as on the box art; the old one read as a walrus.
- Millie as she really is, from Santtu's photos: ears set high and folded over so the pointed tips fall forward, a longer head with a soft wiry beard and brows, silver grizzle on the crown, a grey-brown face, long legs, dark feet with white toes, a white blaze, and her red collar with its grey lining and yellow tag. The portrait over the sofa is Millie face on, head and shoulders, drawn in the film puppet's own design (its googly eyes, folded ears, grey muzzle and beard, wiry brows, palette, outline and cel shading) so it is plainly her; an earlier face-on portrait from the photos read as an older relative keeping an eye on her. Your human walks forward on planted feet instead of moonwalking, leans back less, holds the phone up to his face, and sits flat on the sofa. The pharmacy cross hangs in front of the balconies instead of behind one.
- More life in the animation: the opening creeps in toward her, she wags and breathes while she stares at the leash, your human breathes, dust drifts down a beam of sun, and the bark shakes the frame with a WOOF! burst as she bolts.

## 2026-10-16 - El Mercat wedge scenarios stepped at the physics rate

- `tests/test_mercat_owner_path.gd` failed once on Linux CI on a pull that touched no game code ("below block 2's end, west of its east aisle: he goes round and on up (193 px; wedged at (inf, inf))"). It was not a wedge. The six wedge scenarios stepped `_physics_process` straight after a `process_frame`, outside any physics step, so `move_and_slide` moved the dog and your human by the wall time of the last frame instead of 1/60 s. How far he got in 480 steps depended on how fast the machine ran frames: locally 344-382 px for that start, up to 2700 px for others, and 193 px on a CI runner with short frames.
- The scenarios now await a physics frame (and check they are inside one) before stepping, as the seeded walks and the aisle checks already did, and hold patience full alongside the call and selfie timer. Every run now gives the same numbers: 412-557 px up, no wedge, against the same 300 px check.

## 2026-10-16 - handover after the intro

- The sitrep in `HANDOVER.md` matches main after v1.60. The intro polish is pull request 234, waiting on a play. The next job is the playtest's DOG STUCK spots.

## 2026-10-12 - the intro fills the window

- The Walkies film keeps its frame fitted inside the window, and the flat and the street paint out to the edges, so a wide or tall window shows more of the room instead of beige. The window throws one patch of light, the sofa sits on a shadow, the door has a jamb, and the street has balconies and a kerb shadow.
- The cut into the yank is a short move that arrives on the bark. The white flash still cuts to the street.
- The film plays the opening of the title theme, marimba and a soft shaker. As it fades, the rest of the band joins at that beat. A skip starts the theme from the top.
- The hook, the landing, the loop, the nose, the sigh, the leash and the door have their own sounds. The title card has no sting.
- The volume keys do not skip the film. They still change the system volume.
- Review fixes before landing: the film's phrase renders on the music worker like any loop and starts in step with the picture, instead of a blocking render that stalled the first frame (0.6 s on desktop, longer on the web) and jumped the film past its fade-in. A frame hitch now holds the film instead of skipping it. The title takes over from wherever the phrase has got to. A walk picked before the title finished rendering no longer leaves the whole session silent.
- The opening frames the lamp, the window and the door (no ghost of the lamp's glow, no sliver of her bed), the yank is a cut on the bark again (the 0.18 s zoom read as a lurch), the window's light is a patch of sun on the rug instead of a wedge through the sofa, the room's edge shade runs out to the margin with no step, and the airbrushed smudges on your human's shirt and Millie's haunch are gone.

## 2026-10-12 - rope tug tests stand clear of the live park

- `tests/test_rope_tug_backing.gd` and `tests/test_freedom_games_live.gd` failed on rerun ("moves away from it every frame (37/40)", "her mouth is full while she tugs") on pulls that did not touch the game. The park around the tug is still live. Trunks and logs are solid, and the grove is placed with the unseeded roll, so a backing run that clips one stops her for a few frames. A ball brought back clears `dog_carrying`. The agility pass teleports along the lane and grabs the rope if that dog spawned on it, and the tug check then continues that tug with an empty mouth.
- Both tests now park the balls, the frisbee, the other free dogs and Brutus, and move solids out of the tug. The live test holds the rope dog off the lane until the tug it means to start. The ball stays in the tree: the frisbee check still reads it.

## 2026-10-12 - the playtest's HUMAN STUCK, checked over the whole window

- The v1.60 release playtest flagged your human stuck on a slack leash in El
  Mercat (east aisle of the first stall block), La Ferralla (two spots in the
  open lane) and El Gòtic. None was a wedge. The watch compared where he was
  1.5 s apart but checked his state and the leash on the last frame only, so
  it fired the moment a stop ended: right after a "ring ring" or a call, a
  selfie, a fall, or a leash that had held him taut round a column while the
  dog pressed into the block's south end and then went slack on a reel click.
- `tools/playtest.gd` now reports HUMAN STUCK only when every frame of the
  window was plain walking (or drifting) on a slack leash, with no squat being
  waited for: the rule `tests/test_mercat_owner_path.gd` already uses. The
  line says what he meant, what he is against and where the dog is.
- 16 walks, 2 runs each: 6 HUMAN STUCK before, 0 after. A sweep of 100 walks
  each straight into La Ferralla's floodlight mast and El Gòtic's first
  bollard found no wedge: he bumps one dead on and sidesteps round in under
  a second, which is the existing unstick.

## 2026-10-12 - logo refresh: a readable Millie, and a set title

- Millie's face read as a black smudge. The coat is now three values (ears
  darkest, head a step lighter, shoulders between), with a lit crescent on
  the upper left and a warm rim on the right, and the salt and pepper is
  where it shows: a light grey muzzle with a blaze up the bridge, flecked
  whisker pits, a chin beard and two grizzled brow tufts.
- Floppy ears set on top of her head, folding over the crown and hanging
  beside her face, so the silhouette at 16 px is still a dog.
- Two eye styles, switched by `EYE_STYLE` in `tools/make_icon.gd` (or
  `-- --eyes=dog|googly`): dog eyes (dark brown irises filling the eye, a
  catchlight, a heavy upper lid and a sliver of white as she side-eyes the
  leash) and refined googly eyes (outlined whites, pupils rolled toward the
  leash). The googly eyes are the default: Santtu picked them for popping more
  cartoonishly than realistic dog eyes.
- The head tilts away from the pull, the collar wraps the neck with the ring
  at the front, and the leash is the in-game taut-leash red.
- The poster title is set as a logo: the game's heavy face, stacked and
  fitted to one measure, PATH OF small and tracked out, LEASH the biggest
  word in the leash's color, on a cream keyline with a hard shadow, tilted
  up toward the pull. Still no subtitle or tagline.
- Ellipses get more sides at large sizes, so the 2160 px box art and the
  poster have no facets. icon.png, icon.ico and the MSIX tiles regenerated.
## 2026-10-12 - the Store listing in one place, sent by the workflow

- store/listing.md has a "Current listing" section: description, short
  description, product features, keywords, What's new in this version and the
  notes for certification, one fenced block each. The Store submit workflow
  (mode update_draft) now writes all of them into the Partner Center draft,
  not just What's new, through tools/store_listing.py (replaces
  tools/store_whats_new.py). Its old What's new heading never matched the
  per-version headings, so 1.60's update_draft would have failed.
- CI checks the section against the Store's limits on every PR.
- The listing text is brought up to 1.60: fifteen walks (Montjuïc), the
  trick rework (no curb grinds), the off-leash games, the two-part tutorial,
  and certification notes for the new main menu.
- docs/MICROSOFT_STORE.md step 7 is the whole per-release procedure.

## 2026-10-12 - hand-stepped tests step inside a physics frame

- A market walk stepped by hand reached the gate in 214 s the first time
  in a process and 39 s the next, same seed, nobody steering. Not state
  carried between walks: `CharacterBody2D.move_and_slide` moves by the
  physics step only inside an engine physics step, and by the process
  delta (the wall time of the last frame, about 0.12 s headless) outside
  one. A test's first walk runs from the deferred `_run`, inside a physics
  step; everything after an `await process_frame` runs outside one, so the
  dog and your human moved about seven times further than their velocities.
- The game is not affected: the dog and your human move only from
  `main._physics_process`, which only the engine calls, and a walk
  restarted through `MenuFlow.restart_walk` moves exactly by its velocities
  (`tools/walk_carryover_restart.gd`).
- The four tests that stepped bodies after a `process_frame` now
  `await physics_frame` first: `test_mercat_owner_path` (which also checks
  it), `test_plant_skid` (whose hauls varied run to run because of it),
  `test_boar` and `test_cross_section`. Found by a probe on every
  `move_and_slide` across the whole suite; no other test does it.
- `tools/walk_carryover.gd` shows the two walks side by side; with
  `-- --in-physics` they agree to the pixel.
## 2026-10-12 - your human stops wedging in El Mercat

- A 25-seed sweep of `tests/test_mercat_owner_path.gd` found your human
  still wedged in about one walk in five, two ways:
  - Meeting a stall block's end face while still across it (late crossing
    over to the next block's aisle), he slid along the face into its
    corner column and stuck in the corner between the two. Islands may now
    say `"face": true` (El Mercat's blocks do): within `human.FACE_CLEAR`
    of the end of the island he is making for and still across it, he only
    crosses, and nearer than `FACE_BACK` he backs off as he crosses.
  - Nothing steered him round the wall stalls (the fish and jamon stalls
    sit at the mouth of a block's west aisle) or what stands by the walls
    between them: his weave or the dog drew him into their ends, and his
    sidestep ran him into the corner with the wall. They are now
    `main.owner_keepouts`; from `KEEPOUT_LEAD` before one until he is past
    it, he aims at least `KEEPOUT_GAP` clear of it.
- Other walks are unchanged: no other island has a face, and only El
  Mercat has keep-outs.
- The test walks seeds 1-10 (was 1-3) and adds six fixed cases, five of
  which wedged before: below three block ends on the wrong side, below the
  west wall's fish and jamon stalls, and below the crates on the east wall,
  with the dog keeping near him by her own movement.

## 2026-10-11 - nobody walks through the stalls

- Tourists stepped aside for the dog and your human but not for anything
  solid, so La Rambla's crowd walked through the stalls and vans and El
  Mosaic's through the salamander. An ambling tourist now sees a solid
  body (`main.solid_rects`) coming up to 120 px ahead and steps round its
  nearer side that fits the walk, and no tourist is ever left inside
  one: a crowd spawn that lands on a stall starts beside it, and the dog
  or your human shoving one aside cannot push them in.
- The other dog-walkers' routes (`bypasser_blockers`) did not know about
  the solid bodies built in `build_walls`, so a pair walked through
  L'Estació's train and La Castanyada's roaster. `LevelBuild.level_solid_rects`
  now gives every one of them a blocker: the seafront bars, the train,
  the park's mammoth, the salamander, La Neteja's dumpsters, and the
  roaster and stage.
- `tools/playtest.gd` logs HUMAN STUCK only while the leash is slack (a
  human held by a dog pushing into something is not stuck), and each NPC
  IN SOLID line names who it was and which rect.
- `tests/test_npc_clear_of_solids.gd` in CI: every solid rect on every walk
  has a blocker, and on La Rambla, El Mosaic, L'Estació, La Castanyada and
  La Neteja no tourist, pair owner or pair dog is ever inside one.
## 2026-10-11 - she walks under what hangs overhead, and the leash over the junk

- A draw-order sweep of every walk after the tree crowns (#208). Overhead
  things were drawn in the ground pass, so Millie, your human and the
  leash drew on top of them. They are now pieces of the canopy layer
  (`world/canopylayer.gd`, z 13; `main.overhead_pieces`), above the dog,
  your human, the rope, every NPC and the riders, and faded over whoever
  is under them like the crowns: the terrace parasols (La Rambla, the
  seafront), the seafront terraces' canopies, El Diluvi's awnings and
  arcade roof, the washing lines and wall lanterns over El Gòtic and La
  Neteja, L'Estació's departures board, the park bandstand's roof, the ice
  cream cart's umbrella, the performers' umbrellas in the rain, the dog
  beach's parasols, and El Mercat's shop awnings on the approach street.
  Lamppost heads go overhead too (the rope wound on the
  column runs under the arms) but never fade. Shadows, posts and plinths
  stay on the ground.
- The dog beach's lifeguard cabin joins the seafront's on the overhead
  layer; its legs and ladder stay on the sand.
- Cones and loose junk (`level_build.JUNK_Z`, was 11, now 4) lie under the
  rope, the dog and your human: the leash drew under every can and crate
  it crossed.
- `tests/test_zorder_overhead.gd` in CI.
## 2026-10-11 - slack curls beside poles too

- The leash's bending stiffness (slack in curves, not zigzags) switched off
  for the whole rope whenever any pole or snag was within 120 px of it, so
  near trees and lampposts the slack went back to an accordion. Now only
  joints within 70 px of an obstacle (`BEND_NEAR`) keep the unbent shape;
  the rest of the rope curls as it does on open ground.
- 70 px, not less: the wrap and the whirl's winding probe read the rope's
  shape as it comes round a pole, and at 45 px the probe's choice of which
  way unwinds the rope disagreed with the rope (test_whirl_guided). The kink
  right at a trunk stays for now.
- test_leash_slack checks the new case (a pole by the hand, slack out by
  the dog curves; the old whole-rope rule folds it to 0.36 segments).
  Solver cost is unchanged within noise; the free bench hash is identical,
  the pole and tangle hashes change because far joints now bend.

## 2026-10-11 - the flaky fence test, explained

- test_freedom_fixes "the bottom fence holds beside the gate" failed now and
  then in CI (#203, #213). The fence was fine: a rope tug Millie had grabbed
  on autopilot earlier in the test was still running, and a tug moves her only
  part way from where it last had her, so it dragged her from the test's spot
  back to the gate mouth and out through it. The test now ends any tug before
  the fence check, and checks she starts where it put her (20 of 20 runs pass).

## 2026-10-11 - the game speaks American English

- Player-facing text is American English from now on; the voice section of
  AGENTS.md says so (its example shout is "CURB RIDE!" now).
- Spelling: neighborhood, gray, practice, around (for "round"), farther,
  cleanup.
- Words: a trash can, not a bin; a fire truck; the store side and a cellar
  door; candy, not sweets; a wiener dog and a pit bull among the other
  walkers' dogs; "a big gray boy" off the leash.
- Idiom: "proper" sniffs and drinks are good long ones, "see off" is chase
  off, "hoover up" is scarf down, "another go" is another try, "go on then"
  is go ahead, "oi..." is "ugh...", "fancy a game?" is "wanna play?", "not
  today, mate" is buddy, "the game's up" is the jig is up, "he'll be ages"
  is a while, "home time" is time to head home, the MUCKY combo is MESSY.
- Clarity: the home chase's bolt shout says YOUR HUMAN, not "the owner";
  GET READY's button says "let's go"; the tutorial opens with "Walk time."
  and ends with "That's everything... go play"; the dog-park lesson says
  loose dirt rather than turned earth.
- Walk glosses: the beachfront, the train station, the work site, the
  junkyard, the dawn cleanup.
- Catalan signs get their accents: BACALLÀ, ESPÈCIES, LA FÀBRICA.
- The Store description and the itch page body follow (curb, sidewalk,
  around, the new glosses). Save keys, goal ids and level ids are unchanged.
## 2026-10-10 - Millie backs up to win a rope tug

- In the off-leash rope tug Millie faces the other dog along the rope the
  whole time. Pushing away from it backs her up, rump first, instead of
  turning her round to run with the rope trailing over her back; the rope
  now runs mouth to mouth. Scoring and controls are unchanged: pushing
  away still pulls, digging in still holds.
- She braces while she tugs: front paws planted out ahead, back paws
  spread. Her stride runs the way she is actually going, so backing up
  (here, or dragged backwards anywhere) steps backwards.
- tests/test_rope_tug_backing.gd: while she pulls she faces the toy every
  frame, moves away from it every frame, her stride runs in reverse and she
  braces; when the tug ends the stick turns her again.
## 2026-10-10 - Other walkers' dogs walk ahead on a short leash

- Another walker's dog goes a little ahead of its owner and to one side of
  the line, wanders about that spot, stops to sniff, gets towed on when the
  owner walks past, and trots to catch up again. It used to walk level
  with the owner, or behind them when the pair walked up the screen: its
  place was a fixed offset down and to the right, whichever way they went.
- Their leash runs from the owner's fist (beside the phone, on the dog's
  side) to the dog's collar with a gentle droop, and goes taut when the dog
  pulls out to the end of it or a sniff holds it back. It used to be a
  150 px rope between two ends about 40 px apart, so 110 px of slack piled
  up and dragged behind the pair. The owner now takes in what the dog is
  not using (never while the leash is caught on anything) and lets out up
  to 92 px.
- Round an obstacle the dog keeps a little ahead on the detour's side
  instead of falling in level with its owner, and when the way ahead is
  shut it waits at its owner's side instead of standing on their feet.
- The owner eases to three quarters of their pace while the dog has its nose
  down; a dog towed off a sniff gives it up and trots back in front.
- The pair's wander rolls on the pair's own dice, so how often it rolls
  (which depends on the route) no longer moves the walk's shared random
  sequence.
- tests/test_pair_walk.gd: over 30 seconds of walking either way, the dog is
  ahead of or level with its owner most of the time, the leash never carries
  more than a hand's worth of slack or bulges off the fist-to-collar line,
  and the dog stays on its leash.
## 2026-10-10 - El Mercat: stall blocks, walls and a wedged owner (#153)

- The other dog-walkers and the riders go round the stall blocks down the
  middle of the hall. The blocks were solid but never in the list the
  passers-by route round, so a pair spawned mid-hall walked straight over
  the food.
- She reaches the hall's walls. The straight wall every walk has at the
  edge of its corridor stood 130 px inside each hall wall (the hall is far
  wider than the corridor); the building line along the walls does that
  job now, and the straight wall only closes the stretch past the far door.
- Your human no longer wedges in the hall. The iron columns stood 26 px off
  each block's corner, a slot just too narrow for him; they are set into
  the corners now. And he starts across to the next block's side as soon
  as he is past the last one, cutting across more steeply, so he is there
  before its end face instead of walking into it.
- `tests/test_mercat.gd` checks the blocks are blockers, a pair from any
  lane keeps off them, she reaches every clear stretch of wall, and no two
  solids leave a gap he could wedge in; `tests/test_mercat_owner_path.gd`
  (CI) walks him up the hall on three seeds with nobody steering and
  fails if he stands stuck while walking.

## 2026-10-09 - El Mercat: audit fixes (#153)

- The wall stalls stand with their backs against the hall's walls instead
  of a gap's width off them, and the fish counter is a counter: steel, a
  bed of crushed ice, whole fish heads to the customer, red mullet, a tray
  of prawns, a tray of mussels, lemon, price cards and the scale. Its
  meltwater lies on the floor past the customers, not over the counter.
- The street manhole in the middle aisle is a floor drain: a steel grate,
  the floor damp round it, the wet-floor signs still out. Nothing to fall
  down indoors; the churro by it is "off the wet floor" now.
- The side aisles have things in them: crate stacks, parked tartan
  shopping trolleys, a porter's sack truck and shoppers stopped for a chat,
  all along the walls and all solid, clear of the stalls and the crates
  she marks.
- The street before the arch has the shops' striped awnings, the
  greengrocer's delivery van at the kerb with its back doors open, and
  crate stacks by the doors.
- `world/mercat.gd`; `tests/test_mercat.gd` checks the stalls, the drain,
  the dressing and the van. The market autowalk still finishes (leg times
  shift by a second or so round the new solids).
## 2026-10-10 - playtest a walk through its real inputs

- `tools/playtest.gd` plays a walk from a script of steps through the same
  input actions a player's keys press, photographs it as it goes, and logs
  what a player would notice: DOG STUCK (a direction held and no headway,
  nothing to explain it), HUMAN STUCK (walking and going nowhere), NPC IN
  SOLID (a walker, their dog or a tourist inside a solid). Its first run on
  El Mercat found the pinches between the stall blocks and the bins that
  Santtu hit by hand.
- Driving the web build in the app's browser pane was tried first: with the
  app window hidden the page barely renders, inputs go missing and the dog
  hardly moves, so it cannot stand in for play. AGENTS.md says so.

## 2026-10-10 - the tutorial keeps you at the lesson

- Santtu got lost in the tutorial's last section, and a playtest showed
  why: at a lesson your human stands still, but the leash still towed them,
  so a dog pulling ahead dragged them past the lamppost, the post and the
  ledge and out into the dog park with the swing lesson still on the card.
- Now, waiting at a lesson, your human plants their feet as she does (8x
  heavier in the tug of war, `main.TUT_BRACE`), and if they have been towed
  past their spot anyway they walk back to it. The lesson stays beside
  them; once it is done or skipped they walk on as before.
- `tests/test_tutorial_brace.gd` in CI.
## 2026-10-10 - your human steps round things instead of pinning on them

- Pulled toward a pole the leash is over, your human used to press into it
  and stick. The part of the pull aimed into the pole now becomes a step
  round it, the way that unwinds the rope (the same probe the whirl uses),
  within 48 px of it (`main.round_pole_dir`).
- Walking into a bin, a stall or a post, they no longer press on for ever:
  blocked for 0.3 s while meaning to walk, they sidestep along it, and keep
  going while it still blocks them (up to 2 s), keeping to the side they
  chose if blocked again soon after (`human._check_stuck`).
- `tests/test_owner_unstick.gd` in CI.
## 2026-10-10 - a slack leash lies in curves, not an accordion

- The rope had no stiffness against bending, so spare length folded into a
  regular zigzag. A bending constraint (`entities/leash.gd`, BEND_MIN): two
  points one apart may come no closer than 1.55 segments, so a joint never
  folds back on itself and slack lies in loose curves and loops on the
  ground.
- Run once, before the length passes, so it can never stretch the rope
  into a false pull (the moving walkways caught that).
- Only with no pole or obstacle within 120 px of the rope: wraps, the
  whirl's winding measures and its unwinding all read the rope's shape near
  a pole, so there the solver is exactly as it was (the pole and tangle
  benchmark hashes are unchanged). Slack near trees still folds; that is
  the next step.
- `tests/test_leash_slack.gd` in CI.
## 2026-10-10 - under the trees, not over them

- Tree crowns draw above Millie, your human and the leash, on their own
  layer (`world/canopylayer.gd`, z 13, under what hangs overhead): she and
  the rope go round the trunk under the leaves instead of over them. The
  ground pass keeps what lies on the ground: the crown's shadow, the pit or
  grate, the roots, and the trunk itself.
- A crown someone is under turns see-through, as one sheet (a CanvasGroup,
  so the overlapping leaf clumps do not blotch), and its trunk stays solid.
- Every kind: El Parc's and El Barri's trees, El Bosc's oaks and pines, the
  palms, the street trees in their grates, El Gòtic's plaça tree, and the
  groves in the off-leash spaces. One shared rule (`main.pole_tree`) says
  which posts are trees, for both passes. The crowns are one batch.
- Drawing only: the behavior snapshot is identical. `tests/test_canopy.gd`
  in CI.

## 2026-10-10 - the kid's dare says what it wants, and you can try again

- The dare is offered before its clock starts: the kid says "bet you can't
  do 5 tricks in 12 seconds!" and a card under the banner spells it out for
  2.6 seconds - what counts ("swing around a pole, grind a ledge, fling
  your human", with the turbo button named for the device in hand), what it
  pays, and a bar filling up to GO. Tricks landed while it is being read do
  not count.
- While it runs the card counts tricks and drains the clock ("2 / 5",
  "11 seconds left") and the kid counts down ("3 more! go go go!").
- It says how it ended, for a few seconds: DARE WON! +35, or DARE LOST with
  how many of the 5 tricks she landed.
- A lost dare can be tried again: stay near the bench for 5 seconds after
  it ends, or walk off and come back, and the kid offers it again ("heh.
  want another go?"). Two retries at most; a retry pays 25 instead of 35, so
  the first go is still the one to land. A won dare is done. The autowalk
  never gets a retry.
- New strings are in American English. `tests/test_dare_retry.gd` in CI;
  `tests/test_challenge.gd` covers the offer and the result card.

## 2026-10-10 - a main menu, and one way back from everywhere

- The title is a main menu now: PLAY, TUTORIAL, WARDROBE, YOUR WALKS,
  SETTINGS and EXIT GAME, a list at the left under the name, picked with
  up/down and the plant action. Quitting no longer means starting a walk
  to reach the pause menu.
- One rule on every screen: plant confirms, and bark or pause is BACK.
  BACK closes the wardrobe, YOUR WALKS and settings to whichever screen
  opened them, steps back from GET READY to the walk select and from there
  to the main menu, cancels a question, resumes from the pause menu, and on
  the main menu asks EXIT GAME (desktop only; on the web it does nothing).
  The prompt bar shows it as one BACK key everywhere. Keys no longer mean
  different things on different screens: bark used to open the wardrobe on
  the walk select and pause opened settings; now the walk select opens the
  wardrobe on pee and everything else is on the main menu.
- PLAY's first-time question is a list of its two answers (learn the
  ropes, straight to the walks), so bark can be BACK there too.
- Plant on a switch in settings flips it; it no longer closes the screen.
  Plant no longer closes YOUR WALKS or the pause menu's THIS WALK card.
- Touch: the stick picks, DIG confirms, BARK is back; the MENU button is
  only for pausing and resuming a walk.
- `tests/test_menu_tree.gd` in CI walks the whole tree with real presses:
  every screen from the main menu and back again with BACK alone, EXIT GAME
  only on desktop and only after the yes. `--shot-menu=main` photographs the
  main menu, and the shot sweep includes it. The behaviour snapshot is
  unchanged.
## 2026-10-09 - Passeig Marítim: audit fixes (#151)

- The palms come in runs now, not one every 300px all the way: a tight
  three by the volleyball court, four in a row past the lifeguard tower,
  a pair flanking each chiringuito, and long gaps between.
- On the walk itself: two showers at the top of the sand (columns on a
  slatted footplate, a puddle beside), a volleyball court with its net
  across the middle, and a lifeguard tower on stilts that she runs under
  (its cabin is on the overhead layer). The shower columns and the net
  posts are poles: solid, markable, and the rope wraps them. The dog
  beach's shower and lifeguard chair use the same drawing.
- Each chiringuito stands on a timber deck under a reed pergola, with
  oleanders in planters along the back and its bar hut at the end of the
  terrace (thatched at one, blue and white canvas at the other, stools at
  the counter). The huts are solid.
- Behind the terraces, where a sideways phone saw one flat grey, the
  blocks' flat roofs: tiled terraces, stairwells, water tanks, a washing
  line or an awning, a narrow street between.
- The walk's sea and the dog beach's sea are one sea: the same colours,
  the same width of shallows, and a strip of wet sand with foam down the
  whole walk. The tinted box laid over the walk's sand (which stopped in a
  hard line at the gate) is gone; the sand underfoot plays as before.
- `tests/test_passeig.gd` in CI.
## 2026-10-09 - El Gòtic audit fixes (#154)

- The washing over the alley is washing: shirts with their sleeves out and
  a collar, sheets folded over the line with their creases, jeans by the
  waistband, socks in pairs and striped towels, every piece pegged to a
  line that sags between the walls, batched and culled to the view (La
  Neteja shares it).
- Past the alley's own roofs the frame was bare masonry, flat grey over
  two fifths of the view. Now the old town goes on from above: pantile
  roofs with their ridges either way, terrats with stair huts, water tanks,
  pots and washing, courtyards and light wells, the odd zinc roof, on a
  grid fixed in the world and slid row by row so it never reads as a grid.
  It runs on round the plaça at the top, where the plain rows of tiles were.
  All of it in the edge layer's one batch.
- The parked scooters are Vespas: rear cowls wider than the saddle, the
  floorboard, the curved leg shield, the mudguard and the headlamp in the
  handlebars. Red, cream and mint.
- The posts down the alley were drawing as trees growing out of the
  paving; they are the cast-iron bollards the level always called them.
  The plaça's plane tree stands in a stone-kerbed pit with its grate.
- The off-leash plaça turns away a prop that would land on another, a
  tree's pit, the trough or the fountain, so pits no longer overlap and no
  planter sits on a dig (all four plaça walks). The plaça's house fronts
  have cornices, shuttered windows on iron balconies and doors in stone
  surrounds.

## 2026-10-09 - every CI test, locally, the way CI runs it

- `tools/run_tests.sh` reads the test list from `.github/workflows/ci.yml`
  and runs each one as CI does, through `tools/godot_ci.sh` (so a SCRIPT
  ERROR fails it). The six render tests (appearance, HUD anchoring, touch,
  rotate prompt, ShapeBatch) get a real rendering context: run headless,
  they fail or hang, which had read as local failures that CI did not see.
  All 102 pass on main. A filter picks tests by path; failures are listed
  at the end.

## 2026-10-06 - paper bags on Montjuïc's wind (#146)

- A gust on the hill lifts a paper bag upwind of her and sends it
  skittering along the path in hops; every gust shoves it on, and between
  gusts it creeps and settles. Pounce on it at speed: "got it! +2". One
  loose at a time, three a walk, never for the autowalk (the snapshot is
  unchanged). White paper with an inked edge, so it reads on the sand.
- `entities/litter.gd`; `tests/test_litter.gd` in CI.

## 2026-10-06 - your human's sunhat on Montjuïc (#146)

- On Montjuïc your human climbs in a straw sunhat, and once a walk, high
  up, a gust takes it ("my hat!"). It tumbles off downwind and fetches up
  at the path's edge. She can pick it up and take it back: it goes back on,
  6 bones, and your human's patience is full again ("my hat! good girl").
  Or leave it; nothing is lost but the hat, which stays behind.
- A hat carried into the esplanade is dropped at the gate. Never for the
  autowalk, so the behaviour snapshot is unchanged.
- `entities/sunhat.gd`; `tests/test_sunhat.gd` in CI.
## 2026-10-06 - saves that save the phone, and teaching the tricks (#193, part 4)

- A stumble save (she digs in and yanks your human back) scores only when
  it saved the phone: a bike or the road train was really coming at them
  in the next second. A bike already past, riding away or passing wide no
  longer turns any yank into a save, and the road train now counts.
- The brink save pays 2 bones (was 4): nearly falling in is not worth what
  a real save is.
- The tutorial teaches the leash tricks first (the pole swing, then the
  fling) and the grind last, on its ledge.
- First-time tips: a wrap at pace without the zoomies says to hold them to
  swing round the post; running along a ledge without them says to hold
  them to ride it.
- `tests/test_saves.gd` in CI.

## 2026-10-06 - leash tricks lead (#193, part 3)

- The pole swing takes the zoomies to start, like a grind, so a wrap at a
  trot is just a wrap and never an accidental trick. Holding the zoomies
  keeps the swing going (up to 2.4 s) for more turns, and it pays for the
  pace she carried round as well as the turns (up to 1.6x).
- FIGURE EIGHT: swing one post, then the next the other way round, within
  3 s. 60 points and 8 bones on top of the swing.
- THREAD THE NEEDLE: dash between two people walking close together
  (tourists, or two other walkers). Not between an owner and their own dog:
  that is their leash, and a tangle. 25 points and 3 bones.
- No clothesline: knocking people over is not who she is.
- The tutorial's swing lesson says to hold the zoomies.
- `tests/test_leash_tricks.gd` in CI.

## 2026-10-06 - combos count tricks, and golden zoomies (#193, part 2)

- Only tricks start a combo and raise its multiplier: the grindables, the
  pole swing, the fling and slingshot, saves (balance, save, braced), air
  catches, agility, close shaves, a walkway ride. Business (sniffs, marks,
  hellos, snacks) adds its points and keeps a running chain alive but never
  multiplies it, so walking about is no longer a combo. The window is 4 s
  (was 3.2). The kid's dare counts tricks only. "Land an x3 trick combo" is
  the goal (was x5 of anything).
- Points rebalanced toward the leash: fling 8 -> 30 (and +6 bones),
  slingshot 8 -> 20, pole swing 8 + 40/turn -> 14 + 50/turn (its combo name
  is POLE SWING now, as shouted), grind rate 9 -> 6 a second, a brink save
  6 -> 4.
- GOLDEN ZOOMIES: the zoomies were a single reserve that never refilled.
  Now every trick refills them by what it was worth; filling them that way
  turns them golden for 6 s: tricks score double, the grind's wobble eases,
  and the green tube glows gold. "GOLDEN ZOOMIES!"
- Each walk keeps its best style (the banked combos, summed) as a record;
  beating it says BEST STYLE on the results card.
- `tests/test_combo.gd` rewritten for tricks-only chains;
  `tests/test_golden_zoomies.gd` in CI.

## 2026-10-06 - grinds on grindables, not the edge of the path (#193, part 1)

- No more kerb ride: the path's edges were rails, so any run along the
  border of path and grass at normal speed started a "trick". Grinds now
  happen only on things built to be ridden (`systems/rails.gd`): El Parc's
  clipped hedge edging (HEDGE RUN), El Mosaic's serpentine bench (BENCH
  GRIND), Montjuïc's terrace walls (WALL WALK) and escalator handrails
  (HANDRAIL), and a stone ledge at the tutorial's grind lesson (LEDGE RUN).
- Getting up is deliberate: run onto one along its length with the zoomies
  held. With the zoomies on, the grindables near her show themselves.
- Once up she is held to its line, so the stick only works the balance, and
  the balance follows the rail whichever way it runs. Rails are polylines in
  any direction now, each with the name she shouts and the combo scores (the
  same word in both places).
- The tutorial's lesson is "Ride the ledge.": hold the zoomies and run along
  the stone ledge. `tests/test_rails.gd` in CI.

## 2026-10-06 - L'Esplanada: the castle at the top of Montjuïc (#146)

- The off-leash space at the top of the climb is the castle's esplanade, no
  longer a borrowed town plaça: gravel inside low stone parapets with old
  cannons trained over them, planters round its trees, a stone cistern for
  the fountain, and past its top edge the castle itself (the rampart and its
  crenellations, a bastion's point, the gate, and the flag, four red stripes
  on gold). The sea lies past the west parapet, the city's haze past the
  east. Signed L'ESPLANADA, "the castle esplanade, off leash".
- Kites ride the wind over it: four, each on a sagging string down to its
  flyer at the edge, bobbing, leaning downwind (harder in a gust), tails
  streaming, their shadows on the gravel.
- Mechanics are the plaça's (agility lane, frisbee, tug, the fountain's water).
- Fixed: the hill and the city below were drawn on past the gate, so most of
  the old off-leash space was buried under rooftops; both now stop there.

## 2026-10-06 - el trenet, Montjuïc's road train (#146)

- A hill road crosses the path at y -2850, asphalt with a striped crossing
  and a post either side with two red lights. While the pair are near it,
  the little tourist road train (a green loco and two striped carriages of
  bobbing tourists) trundles across every 14-20 seconds, alternating sides,
  on its own seeded clock.
- 1.4 seconds before its nose reaches the path it rings ("ding ding!") and
  the crossing lights flash until it is past. It is slow (72 px/s) but long:
  a human it catches goes over and the phone cracks, as a bike would; a dog
  it catches tumbles. Dig in at the crossing and let it by.
- `entities/road_train.gd` (self-managing, like the bikes);
  `tests/test_montjuic.gd` gains the train: it comes while the pair are near,
  rings before it reaches the path, and bowls over a human in its way.

## 2026-10-06 - Montjuïc's cactus garden (#146)

- JARDÍ DE CACTUS: a pale gravel bed on the terrace right of the path below
  the -2100 wall, clear of the telefèric's pylons, with a great barrel cactus
  (ribs, spines, a crown of yellow flowers) and four column cacti with arms.
- The cacti are posts the leash wraps, solid to walk into. Running into one
  at speed is a prick: she bounces off, "OW! CACTUS", and the combo breaks.
- Standing still beside the barrel cactus for a moment is "a very careful
  sniff +4", which counts as one of the walk's sniffs, once.
- The cacti are added after the corridor fit (which would have pulled them
  onto the path) with bodies of their own; grass tufts keep off the bed and
  the Font Màgica.

## 2026-10-05 - L'Estació's walkway carries you

- The moving walkway now moves whoever stands on it outright, as Montjuïc's
  escalators do. Before, it pushed the body's velocity, and a dog or human
  standing still eased that straight back to nothing, so a still dog barely
  moved on it. The `outright` per-level switch is gone; every conveyor
  behaves the same way.
- `tests/test_estacio.gd`: a still dog at the bottom of the walkway rises
  over 40 physics frames, and the same dog beside it stays put.
- Behaviour snapshot (station): only the bot's leg times move, FREEDOM
  31.1 to 31.5 s and HOME leg 38.1 to 38.5 s. The pair clear the walkway
  about 1.5 s sooner, then the bot takes longer to find a ticket-barrier gap.

## 2026-10-05 - the Font Màgica at the foot of Montjuïc (#146)

- A great stone-rimmed basin beside the path at the foot of the hill: a ring
  of ten small jets round a central plume, calm, then rising into a show in
  waves every 16 seconds (on the walk's own clock), spray falling round the
  plume; by night the water glows in slow-turning colours.
- It is water (`m.water`): she can swim in it, wobble at its edge, and your
  human wades out after her. In it while the show is on, once a walk:
  "THE MAGIC FOUNTAIN!" and +5.
- `tests/test_montjuic.gd` gains the fountain: water, beside the path, a show
  that comes and goes, the treat only during the show and only once.

## 2026-10-05 - Montjuïc's escalators (#146)

- The last straight up to the castle (y -4560 to -4900) is the outdoor
  escalators: two steel runs up the middle with black rubber handrails and
  treads scrolling up, comb plates at either end, stone stairs filling the
  rest of the path either side.
- Whoever stands on them is carried up outright (main's conveyor, moving the
  body rather than nudging its velocity, which a still dog or human eased
  straight back to nothing): your human rides past the slow last climb, and
  the dog can race them on the stairs. Going home, the bot takes the stairs
  beside them; a dog can try running down the up escalator.
- `tests/test_montjuic.gd` in CI: the slope (slower up, quicker down,
  nothing off the hill), the escalators on the path, clear of the last
  terrace's steps and carrying a still dog while the stairs do not, and every
  gust telegraphed before it shoves.

## 2026-10-05 - Montjuïc's telefèric, the hidden way up (#146)

- A tourist has dropped a telefèric ticket out on a terrace below the first
  bend, off the path (it glints now and then). Pick it up and take your human
  to the low station, on the inside of the first big bend: the pair ride a
  cabin up the cable, straight over the zigzag, to the top station by the
  last bend. On the way home the same ticket rides them back down.
- The ride is a 6.5-second cinematic: the walk holds still, the camera
  follows the cabin with two heads at its window, and at the far station the
  leash is laid straight again. "what a view! +5".
- A new Montjuïc goal: "Find a ticket and ride the telefèric". The price is
  everything on the stretch it flies over.
- `systems/cable_car.gd`, `world/cable_layer.gd`; `tests/test_cable_car.gd`
  (16 checks) in CI. The autowalk bot never takes the ticket.

## 2026-10-05 - readable on a small screen (#169 audit)

- A sideways phone (844x390) drew the 1280x720 composition at 0.54, so 15px
  text landed at about 8px. Below a 0.78 frame scale the window's content
  scale factor now grows (up to 1.45) to bring it back to 0.78, and the
  camera's zoom is divided by the same factor: the HUD, menus and lesson
  cards get bigger, the walk shows exactly what it did. Measured in logical
  pixels (the browser's device pixel ratio), re-applied on resize, never in
  headless runs. `--ui-scale=K` forces it for screenshots.
- On a narrow screen the open goal list can reach the middle, so the banner
  pill moves into the gap beside it rather than under it; and with the
  enlarged interface the open list shows four rows, the rest as "+ N more".
- The results card (900 wide) shrinks to fit a narrow or short viewport,
  keeping the side margins the touch buttons stand in; at desktop sizes it
  is exactly as before.
- Desktop sizes (frame scale 0.78 and up) are untouched.
- `tests/test_ui_scale.gd` in CI.
## 2026-10-05 - no riders on walks without a rider lane

- `_vlane` only had rider cases for street, park, beach and market. Every
  other walk fell through the match and spawned a motionless "bike" at x=0,
  off screen, every 2-4 seconds (up to the cap of seven): invisible, but full
  riders ticked every frame, counted by the critters' scatter checks. Now it
  runs on those four walks only (`VLANE_LEVELS`).
- `test_barri` drives El Barri for 900 frames and checks no rider appears
  (it saw 3 before the fix).
## 2026-10-05 - the tutorial names the meters and the phone (#169 audit)

- The pee lesson names the yellow bar ("Your tank is the yellow bar") and
  the zoomies lesson the green one, and while each is up the HUD card
  outlines that meter with a slow gold pulse (`hud_point`, from the step's
  new "meter" key).
- THAT'S THE BASICS, the card before the first real walk, now says the one
  rule nothing else had taught: "One rule: keep your human on their feet.
  Three cracks and the phone is gone." The phone's pips are outlined behind
  it. Confirm cards take more than one line of body text.

## 2026-10-05 - the first minutes, worded right (#169 audit)

From the fresh-eyes audit of a new player's first ten minutes:
- The urge banner said "NEED A WEE! ... HOLD {plant}" for what is a poo; the
  wee is a different key, so a new player pressed it at a hydrant and nothing
  happened. Now "NATURE CALLS! STAND STILL, HOLD {plant}", the tutorial's own
  name for it, and the bagging lesson says "hold {plant} to squat" to match
  GET READY's legend.
- One word per key: GET READY calls the run key "zoomies", as the tutorial does.
- Loss cards say "your human" (YOUR HUMAN WENT DOWN THE MANHOLE, ...).
- FIRST TIME? draws its "Don't ask me again" box on the card, empty or
  ticked; the bar's label no longer flips to "ask me again", which read as a
  new choice.
- The nose lesson is shorter (it ran into the HUD), and the last card no
  longer claims "every trick in the book" in a park full of untaught agility
  gear: "That is the lot. The park is yours: go and play."

## 2026-10-05 - a gentler lost walk (#169)

- The card a lost walk ends on keeps its joke and now adds one plain line on
  how to avoid that loss next time: bikes (dig in at a crossing, keep out of
  the bike lane), open manholes, cellar hatches, the brink of a hole or an
  edge, and the sweeper (pull steadily for home).
- It says how many new goals the walk ticked, since those stay ticked even
  on a lost walk.
- A player's very first lost walk adds "Everyone loses a walk now and then.
  It starts fresh every time." `Game.walks_lost` is saved under `[global]`;
  headless runs and screenshots never write it.
- Try again stays one press away. Every loss now goes through `_death(msg,
  cause)` and `systems/losses.gd`; `tests/test_losses.gd` is in CI.

## 2026-10-05 - Montjuïc, the climb (a first version)

- A new walk, MONTJUÏC ("the hill"), opening at 25 stars: a narrow path
  winding up the hill between stone terraces, a flight of steps where it cuts
  each retaining wall (handrail posts the leash catches on), Aleppo pines,
  agaves and prickly pears on the terraces, and stone posts counting the
  metres up to 173.
- The hill narrows as you climb, and past its rim the city falls away: the
  Eixample's chamfered blocks below, smaller and hazier the higher you get,
  and near the top the sea.
- Your human walks slower uphill (and slower again on the steps) and quicker
  coming home; lead them on the leash and they keep up better. The dog feels
  half of it.
- Wind: from a little way up, gusts every few seconds, more often and harder
  higher up, each telegraphed by leaves and streaks across the view and a
  whoosh before it shoves you sideways.
- Its own arrangement of the soundtrack (whistle and vibes, brushes). The
  off-leash space at the top is a plaça for now; the cable car, the
  escalators, the castle esplanade and the rest come next (#146).
- In every level list: CI's selftest and smoke sweeps, the soak matrix, the
  screenshot, perf and idle-soak sweeps, the behaviour snapshot, the terrain
  and off-leash bounds audits, the junk placement test.

## 2026-10-05 - the web frame times, measured again: the machine, then the signs

`tools/web_perf.sh` on main read street at 11 fps (frame p50 72.7 ms), park
20 and beach 16. Most of that was the machine: XCOM 2 and a busy browser
were sharing its CPU and GPU, and the same build swung from 15 to 60 ms over
twenty minutes without a change. A first bisect run through those twenty
minutes blamed the leash overhaul (#127), wrongly. On a quiet machine,
alternating builds, street reads:

| build | frame p50 |
|---|---|
| v1.55 | 11-12 ms (75 fps) |
| v1.57, #127 and its parent, eeba92e | 17-22 ms |
| main | 22-24 ms (41-44 fps) |

Nothing since v1.57 slowed the browser build, so 1.58 shipped as it was.
Between v1.55 and v1.57 street grew from 290 to 461 nodes and its world draw
from 1.3 to 3.2 ms (native), mostly in the restyle (#76) and La Rambla's
boulevard (#87): new things to draw, not a slow path.

Profiling the world pass by section found one: the loose-piece signs (the
walk's name, HOME, the gate's words, #99 and #116). A sign of about ninety
carnations cost 3.5-4.5 ms of every 30 fps world redraw natively, to repeat a
picture that had not changed. They now live on their own canvas,
`world/sign_layer.gd`, which redraws only when a piece moves (a sign's new
`rev`, bumped by `WorldSign.tick` only when something drawn changed), a sign
enters or leaves view, the signs are rebuilt or hidden, or one animates
(puddles, suds, rings). It is main's first child at main's z, so it draws
exactly where the signs were. Over street's whole autowalk, native and fixed
step: world draw mean 6.9 -> 4.6 ms, p95 16.6 -> 5.9 ms, worst 22.2 -> 9.3
ms, and the walk takes 5% less wall time. In the browser over 75 seconds
the world draw's p95 halves (13.3 and 14.9 ms against 7.3 and 7.9), but
whole frames stay within this machine's run-to-run noise (19.5-25.8 ms p50
before, 20.4-28.6 after), so this alone does not bring street back to
60 fps: the rest is the spread-out cost of the new content. The
behaviour snapshot is byte-identical and all 56 sweep shots are
pixel-identical. `tests/test_sign_layer.gd` pins when the canvas must and
must not redraw.

`tools/web_perf.sh` now prints every PERF line (the physics-step split and
the worst frames as well as the summary), takes probe flags in PERF_ARGS,
keeps Chrome's log with LOGDIR, and says in its header how background load
wrecks a comparison.

## 2026-10-05 - First-time tips (#169, part 3)

- The first time something non-obvious happens, the banner says what to do
  about it, once, for six seconds, and never again (saved): the first walk
  for a player who skipped the tutorial ("{plant} DIGS IN WHEN THEY PULL.
  {pee} MARKS A SPOT"), a cracked phone ("KEEP YOUR HUMAN ON THEIR FEET. THREE
  CRACKS AND THE PHONE IS GONE"), a wobble at an edge ("WOBBLING! STEER AWAY
  FROM THE EDGE"), a "HEY!" from your human ("PULL GENTLY AND YOUR HUMAN
  FOLLOWS. HAUL AND THEY SNAP") and your human wound round a post ("WOUND
  ROUND A POST! PULL AWAY TO SPIN THEM OFF"). Not in the tutorial, and not
  for the autowalk.
- `systems/tips.gd`; `tests/test_tips.gd` in CI.
## 2026-10-05 - The tutorial in two parts (#169, part 2)

- THE BASICS first: walking, the leash going tight, digging in, business,
  a sniff, the nose, the bark, the zoomies and bagging it, about three
  minutes. Then the walk stops on THAT'S THE BASICS ("Enough for any walk. The
  tricks are a bonus."): on to El Barri straight away (the tutorial counts as
  done and its bones are banked), or teach me the tricks.
- THE TRICKS for whoever wants them: riding the kerb, the vault, tetherball
  and the brink, then digging in the dog park, where the tutorial now ends by
  itself a moment after the last card. No more walking home with nothing left
  to learn.
- The title's FIRST TIME? card can say three minutes now, and does.
- `tests/test_tutorial_checkpoint.gd` in CI; `--level=tutorial
  --shot-menu=basics` photographs the card.

## 2026-10-05 - A way in for new players (#169, part 1)

- The title asks a new player first: pressing start on a fresh save opens
  FIRST TIME? "A short walk that shows you the ropes", with learn the ropes on
  the main button (straight into the tutorial), straight to the walks on the
  second, and don't ask again on a third (it says so on the card, and it is
  saved). It stops asking once the tutorial has been walked to the end.
- The tutorial ends by leading on: its result card offers "on to El Barri",
  which goes straight into the first real walk with no menu in between, and
  the bones earned in it are banked rather than thrown away as practice.
- The first walks open sooner: La Rambla at 1 star, El Parc at 2, the
  seafront at 3, El Diluvi at 4 (were 2, 3, 4 and 5).
- `--shot-menu=first` photographs the question.

## 2026-10-04 - El Parc: audit fixes (#150)

- The flowerbeds are gardens: a low clipped box hedge round each (soft
  corners, a lit top, leafy texture) and the planting in drifts, a run of one
  colour, a foliage mound, a few lavender spikes, then the next colour,
  instead of a grid of dots.
- The bandstand's floor is stone, not lawn: no grass tufts drawn on it.
- The playground: poured rubber with soft corners and a darker kerb, a
  hopscotch let into it, a timber fence round it with a gate on the path side,
  the slide with its ladder, platform, rail posts and a chute widening into
  its run-out, a spring rider, and the sandpit in rounded timber with corner
  seats and a bucket and spade left in it.
- The lake has a shore: clumps of reeds and bulrushes round the bank, a
  timber jetty on the south side with two rowing boats tied up for hire, and
  ducks resting on the east bank. The path round it stays clear.
- Drawing only: the behaviour snapshot is identical.
## 2026-10-04 - La Rambla: audit fixes (#149)

- The promenade is fuller: the plane trees down both edges stand every 180 px
  instead of 270 (a lamp standard every fourth instead of every third), and
  every stall has two or three people browsing at its counter, pressed up to
  the front so nobody walks through them.
- The cellar hatches are drawn as what they are: a stone kerb, the two steel
  leaves folded back flat with tread plate and hinges, a stair going down
  into the dark, the crates waiting on a sack truck. All three are set back
  from the kerb, and the one by the cross street no longer runs into it.
- The stalls are spread out: the three flower stalls in a huddle are now two,
  far apart, with a painter's pitch (framed views of the city, an easel)
  where the third stood; the second souvenir stall at the end of the walk is
  a second-hand book stall.
- The sellers' blankets lay out real goods, by hand and not quite in a grid:
  folded sunglasses in four frames, handbags with straps and clasps, and
  footballs, light-up spinners and plush bears; cords run from the corners
  toward the seller, ready to pull it all into a bundle.
- Drain grates and repairs in the paving keep clear of café tables, chairs
  and parasols.

## 2026-10-04 - Games in the off-leash space

- The same three games in every off-leash space (yard, lot, clearing, plaça,
  beach), as Santtu asked:
  - **Agility**: a course along a lane across the space (green flags, a jump,
    five weave poles, a tunnel, a second jump, the chequered finish), run left
    to right against the clock. She hops the jumps, vanishes into the tunnel,
    and each pole woven on the wrong side or element skipped is two seconds.
    The best time is kept (`Game.agility_best`, one record for every space,
    since it is the same course) and beating it pays extra.
  - **Tug-of-war**: one free dog carries a little rope toy and brings it over
    to offer an end. Take it and the two of you haul: running away gains
    ground, digging in holds (it still gives), standing about loses it, turbo
    is a heave. Win it and she parades it, then drops it for the other dog to
    fetch back; lose and it trots off with it.
  - **Frisbee**: once fetch is over and the ball is back, your human throws
    a frisbee long ("ready...?" first, every time), three throws. Snatch it
    out of the air for an air catch; off the grass it still counts, just.
- The banner says what is on (the agility clock and the next element, the
  tug's balance, catch it in the air) and the hints after fetch point at the
  course and the rope.
- Props, digs and trees are nudged off the lane rather than re-rolled, so the
  random numbers that placed everything are unchanged; on the beach the
  parasols are spaced round it. The behaviour snapshot is identical to main:
  the autowalk never gets a rope or a frisbee, and the course only watches.
- The two drawing layers redraw only what moves (the flags at half rate, the
  rope while one is in play).
- `systems/agility.gd`, `systems/rope_tug.gd` (pure rules), `entities/frisbee.gd`,
  `systems/freedom_games.gd` (the glue), `world/games_layer.gd`;
  `tests/test_freedom_games.gd` (rules) and `tests/test_freedom_games_live.gd`
  (in a level) in CI; `tools/games_shots.gd` photographs the games' moments.
## 2026-10-04 - A new soundtrack

- One tune, sixteen bars in D, arranged for every walk on synthesised
  instruments (`audio/music.gd`): a marimba title theme, a whistled barri, a
  bossa on the seafront, El Gòtic in D minor on Spanish guitar with
  castanets, an accordion oompah in the market, a rumba catalana in the Güell
  park, a music-box spook walk, a driving minor chase for the street
  cleaners, and so on, fifteen loops in all. The off-leash space has its own
  loop, and a walk ends on a short sting (a fanfare, or a sad trombone)
  before the title theme comes back.
- Loops crossfade, and the pause menu hears the music as if through a door.
  The intro plays without music; the title theme starts on the title screen.
- Each loop is synthesised when first wanted (about 1.4 s of work on
  desktop): on a thread on desktop, so it costs no frame time; in small
  slices on the web, about 2 ms a frame while walking and less when a frame
  is already heavy. The loop playing carries on until the next is ready. No
  music is built headless or in screenshot mode.
- `tools/render_music.gd` writes any style to a WAV; `tests/test_music.gd`
  checks every walk has an arrangement, that a sliced render is identical
  to a whole one, and that loops are healthy and equally loud.

## 2026-10-04 - An intro: "Walkies?" (nine rounds of polish)

- After four frame-by-frame critiques and Santtu's notes: the leash is a
  simulated rope (settled at rest, carried gathered, draped, taut when
  pulled); shadows stay on the floor; Millie glances with her eyes, sits for
  real, arcs her jump to the hook, drops the loop on the knee and bumps the
  phone from below; your human is absorbed in the phone, takes the loop
  without looking, tips forward on the yank and flies out; both go through
  the door, shrinking with distance into its light; the title's O is a red
  collar on a leash hanging from the top of the screen; on a daylight street
  she tows your human, leaning back and skidding, out of frame.
## 2026-10-04 - An intro: "Walkies?"

- The game opens on a short animated film (about 14 seconds), in a new side-on
  look: soft clay forms with a thin dark outline, animated on twos with a
  little boil. Morning in the flat; your human on the sofa, lit by the phone;
  Millie fetches the leash off its hook, drops it at their feet, waits,
  nudges the phone ("..."), sighs, and once they take the loop without looking
  up, crouches and yanks them off the sofa and out of the door into the sun.
  The title swings down on its leash and she tows them past along the bottom.
- It plays on a plain launch, once a session, with sound on its beats, and any
  key, click, tap or pad button skips it into the title screen. Never
  headless and never with command-line arguments, so screenshots, the
  autowalk, the soak and tests never wait on it (`intro/intro_player.gd`).
- Side-on puppets for Millie and your human (`intro/millie_side.gd`,
  `intro/human_side.gd`), a keyframe and easing toolkit (`intro/anim.gd`),
  and the title card (`intro/title_card.gd`), reusable for more animation
  later (an end-of-walk scene, unlocks).
- Tooling: `tools/intro_render.gd` renders a scene frame by frame to PNGs and
  `tools/frames_to_gif.py` joins them into a GIF; `tools/intro_style.gd`
  draws the three looks that were compared. The two other storyboards,
  "Down from the rooftops" and "The title fights back", are kept as
  renderable scenes.
## 2026-10-04 - The README, Store listing and itch page say what the game is now

- No tagline any more. "You are the dog. Go touch grass." is gone from the
  README, the Store manifest's description and the Windows export's file
  description (now just "Path of Leash Resistance").
- **README.md** rewritten for the GitHub page: what the game is, what you do,
  the features as they stand (the leash conversation, the off-leash ends, moods,
  terrain, weather outfits), the fourteen walks with their glosses, controls,
  links to itch and the Store, and the build commands.
- **store/listing.md**: a new description, short description, feature list and
  keywords for the next submission, recorded as not yet live (the 1.57 text is
  in the file's history).
- **docs/itch-page.md**: ready-to-paste itch page text (short description, body,
  controls, a "what's new" draft from the changes since v1.57), and the GitHub
  About line and suggested topics for the repo settings.
- In-game text is unchanged: the start line's "you are the dog" gloss, the
  tutorial's first title and the Store poster's tag line still say it.

## 2026-10-04 - No subtitle

- "you are the dog" is gone from under the title on the title screen and from
  the Store poster art, and "You are the dog. Go touch grass." from the
  Windows file description and the Store package description. The title
  stands alone (Santtu: tired of it, and it was not needed).
- The First Walk's opening card is headed "Walkies." instead.
- The README, AGENTS.md, PROJECT.md and the Store listing record follow.
## 2026-10-04 - The off-leash break, part 1: fixed, walled in, explained

An audit of every off-leash space (#21) found it leaky and quietly broken.

- **She stays on screen.** The camera's x was fixed at 640, and the space is
  wider than the view, so she could run off either side (and swim out of
  sight at the dog beach). Past the gate line the camera now follows her
  sideways, clamped to the space (`main._cam_x`). `tools/freedom_bounds.gd`
  drives her flat out in eight directions on every walk and reports any
  escape or loss of sight.
- **The bottom fence holds.** It was drawn only, so she could leave anywhere
  along it and the leash re-snapped across the gap. It is solid either side
  of the gate mouth now, and on the dog beach a breakwater of rocks (an
  espigó) carries the line across the water.
- **Brutus no longer ends fetch.** A ball he ran off with, or that was taken
  back off him, was never replaced. Your human throws another ("here, another
  one!").
- **A bone taken back off Brutus is kept.** He could steal the same bone
  again and again, worth +9 each time.
- **Brutus goes home with everyone else.** He stayed behind and went on
  stealing bones off-screen for the rest of the walk.
- **Nobody in the sea.** On the dog beach two benches, two parked pairs,
  Brutus and the free dogs could all start in the water; they start on the
  sand now.
- **The bag survives a sit-down.** Your human parking on the bench made the
  bag vanish, so after the break the bag chore could never finish.
- **The trough answers.** Drinking laps, and a proper long drink says so,
  +2 (it was silent: nothing told her the drink goal had been met). Logs can
  be sniffed like posts.
- **What else is here.** After fetch, the banner takes turns suggesting what
  is left (digging, a drink, sniffing round) before pointing home, and
  heading for the gate mid-fetch warns "LEAVING ALREADY? FETCH ISN'T DONE".
- New test: `tests/test_freedom_fixes.gd` (11 checks), in CI in place of a
  duplicated step.
## 2026-10-04 - El Bosc's floor, edges and spring (level audit, #21)

- The trail had a kerb: a pale ruled line down both edges, as in town. A
  forest path frays instead: a trodden band just inside each edge, loose dirt
  spilling out into the floor, and now and then a root across the edge
  (`main._draw_trail_edges`).
- The forest floor grows ferns and has fallen leaves among its tufts.
- The clearing's water is a stone spring, a font: a stone back with a pipe,
  water falling into a round mossy basin, rings spreading, instead of a
  galvanised trough.
## 2026-10-04 - How every walk ends (level audit, #21)

- **The gate** was a dark bar across the path over a dashed line, which read
  as a road to cross on every walk, the forest included. It is now the gate
  the place would have (`main._draw_gate`): timber posts and no sill where a
  walk ends in nature, stone gateposts and a stone sill into a plaça, and an
  iron dog-park gate with both leaves swung open everywhere else, at the
  path's real edges.
- **Past the far fence** the off-leash spaces stopped in a ruled line onto
  flat grey. Now there is a place beyond (`main._draw_freedom_beyond`): a
  clipped hedge and trees behind a dog park, a block wall and shed roofs
  behind a yard, more forest round a clearing, terracotta roofs behind a
  plaça's houses, and the sea and sand going on at the beach.
- **Names in Catalan** over every gate, with OFF LEASH as the gloss: PIPICÀ,
  LA CLARIANA, PLATJA DELS GOSSOS, EL PATI, EL PORXO, EL SOLAR (was PARK, DOG
  PARK, CLEARING, DOG BEACH, BACK GATE, SHELTER, DETOUR). The signs inside
  say the same with an English line under them, and a gate without a
  lettering material writes "off leash" under its name.
- The dune row along the top of the dog beach no longer stands out in the
  sea: dunes only on the sand.
## 2026-10-04 - L'Estació's departures board says something

- The departures board over the way in was a black slab with yellow and
  cream bars standing for text. It is a steel-cased board with a blue
  SORTIDES strip (glossed "departures") and four rows in amber, time, where to
  and platform, the way Rodalies boards read: Sitges, Girona, Vic, and the
  Mataró train, CANCEL·LAT in red, as one always is.
## 2026-10-04 - Les Obres' digger, and close-up screenshots

- The parked digger was a yellow disc on two black bars. It is drawn from
  above as a digger is: rubber tracks on their rollers, the house with its
  lit deck, engine louvres and exhaust, a hazard-striped counterweight, the
  cab with its glass roof, and the boom and dipper folded forward on their
  rams, the bucket's teeth down on a heap of spoil. Same footprint, one batch.
- Tooling: `--shot-zoom=Z` magnifies a screenshot, `--shot-cam=X,Y` points
  the camera at a spot rather than the pair, and `--shot-x=N` puts the pair
  at that x, so a prop or a person can be judged at a size where the drawing
  shows (the play zoom is too far out to tell).
## 2026-10-04 - Parasols and café tables

- The parasols over La Rambla's terrace and along the seafront were a flat
  disc with six white lines. They are drawn the way the dog beach's already
  were: eight panels in two tones, a scalloped hem, the lit side and their
  shade on the ground, still see-through so she shows under them, and batched
  into one draw call each (`main._draw_parasol`).
- The café tables read as faces: a grey top the colour of the paving with a
  highlight disc and a round cup on it. Each is now a pale marble top in a
  dark metal rim, with a small coffee (handle and all) and a croissant or a
  glass of water.
## 2026-10-04 - Beach towels with someone on them

- Passeig Marítim's towels were flat rectangles with a circle and a box for a
  bather. Now each is striped across both ends and fringed, and the bather
  lies on it properly: legs, arms, a swimsuit, hair and sunglasses, drawn with
  the same head and shoulders as everyone else (`main._draw_towel`).
- The empty towels have what their owner left: flip-flops, a paperback and
  the sun cream.
- Nobody sunbathes in the rain, in the snow or at night: the towels are left
  out, darker when wet and dusted white in snow.
- Drawing only: where a towel is and what happens when your human walks over
  it are unchanged.
## 2026-10-04 - Drains and repairs only where they belong

- The drain grates and repair patches from the last terrain pass landed on
  every walk alike, so the same grey square sat beside each walk's name at the
  start, and drains turned up on the park's gravel path, the forest trail and
  the seafront's brick bike path. They now appear only in made ground
  (`LevelBuild.works_ground_at`: not El Barri, El Parc, El Bosc, La Ferralla
  or El Mosaic, and on the seafront only on the promenade), and never under
  the signs at either end of the walk.
- A repair patch is now an uneven six-sided patch with its seam showing on
  one side, not an outlined box.
## 2026-10-04 - She walks differently on different ground (terrain pass 2, part 2)

- **Gait by surface** (`dog._cadence`, `_stride`): quick, short steps on sand,
  where there is no purchase; slow, heavy, long ones in mud, with her paws
  sunk brown to the ankles; a slightly higher step through grass. Drawing
  only: nothing else reads her gait.
- **Kicked sand**: running on sand throws grains up behind her (the same
  pooled, capped marks as the grass and mud).
- **Quiet sounds on the way in**: a rustle into grass and grit onto sand,
  alongside the squelch into mud and the existing splash into water; at a
  run only, and never more than one a second.
- **Pavement** now and then has a drain grate or an old repair patch among its
  cracks and grit (chosen by position in the list, so no other detail moves).
## 2026-10-04 - Two level review leftovers (#21)

- The HOME sign no longer sits under the prompt bar on the title and the walk
  select: it means nothing before she has set off, so it shows once the walk
  starts (the line it labels is still drawn).
- El Mosaic's viaduct slope tapers in and out at each end of the viaduct
  instead of stopping in a straight edge.
## 2026-10-04 - Natural ground looks and moves like itself (terrain pass 2, part 1)

The terrain spec (`docs/superpowers/specs/2026-10-03-menu-terrain-design.md`,
pass 2) asks for grass, sand, mud and water that are open to walk into and
recognisable in motion. Part 1:
- **Access, audited.** `tools/terrain_audit.gd` samples every walk's grass,
  sand, mud and water and reports anything inside static collision. Nothing
  invisible blocks natural ground any more (#129 removed the last of it, on
  El Barri); what remains is the outer level edge and things solid on purpose
  (La Ferralla's fence and wrecks, El Parc's bandstand, beach huts).
- **Grass** has tufts in two greens, seed heads and the odd flower, wherever
  `surface_at()` says grass (so the look can never disagree with the
  handling), on the cached verge canvas: a redraw every 150 px of camera, never
  a frame. Kept off roofs, flowerbeds, playgrounds and the petanca pitch; the
  forest floor is browner and has no meadow flowers.
- **Mud** has ruts, brown water standing in its hollows with a glint of sky,
  a wet sheen on the lit side, and suction rings; one batch a patch.
- **El Bosc's stream** has a deeper band down the middle, foam along both
  banks and current lines that run quicker in the deep water.
- **Her paws mark it**: grass she runs over is flattened and springs back,
  mud flies up at a run (with a quiet squelch on the way in), and a step into
  water rings out. Pooled and capped at 24, deterministic, cosmetic only.
- Not in this part: the spec's mosaic-tile item (El Mosaic has had no tile
  floor since its rebuild), gait by surface, and the other sounds.
- `tests/test_terrain.gd`: no wall across natural ground on the walks that
  have it, and the marks (kinds, cap, expiry).
## 2026-10-04 - The leash conversation

Your human used to answer the leash only as physics: a heavy body walking its
own line, with the leash pulling against it, and a reel that shortened at
random. Now they answer it like a person (`human.gd`, `_converse`):
- **Led by a steady pull.** A moderate, sustained pull draws them across the
  path (up to about 150 px), quickens them if it is the way they are going,
  and slows them, waiting, if it is back. You steer with tension instead of
  fighting their weight.
- **Patience.** Hard, constant hauling wears it down; a slack leash builds it
  back. Low, they glance up from the phone at you, a temper cloud scribbles
  over their head, and they mutter "oi...". Empty, it is a telegraphed "HEY!"
  (with "HE'S HAD ENOUGH! DIG IN" by the dog) and a correction: a step back
  and the leash cut short ("HEEL"). Dug in when it lands, it is him that
  lurches: "held firm! +3". After a correction there is a grace before
  patience drains again. Measured on the bot, which pulls flat out the whole
  walk: two to four corrections a walk; an idle dog never gets one.
- **They wait while she does her business**, up to four seconds ("go on
  then").
- **The reel follows their mood**: the random clicks are scaled by patience,
  so walking nicely earns a longer leash and pulling earns a short one.
- `tests/test_leash_conversation.gd`.
## 2026-10-03 - The pause grid, and a tutorial snack in reach

The first of the two passes below. The tutorial's nose lesson could not be
finished: the snack sat out of reach. Three causes stacked up. El Barri, a
green walk, was never in the no-wall list of `LevelBuild.build_walls`, so it
got the default invisible 120 px solids along both path edges (x 280-400 and
880-1000), which even swallowed its own plane trees and benches; the held
owner waited about 420 px from the snack, past the leash's stretch of about
391 px; and the owner kept re-reeling to random lengths (170-430) and weaving
across the path. Now:

- `"barri"` joins the no-wall list, so on the regular El Barri walk too the
  dog can reach the verge grass.
- A tutorial step can give a `stand` side (the nose lesson west, the teeter
  east), and the waiting owner shuffles over to that edge
  (`main.tut_hold_point`, `TUT_STAND_IN`, `human.tut_hold_x`).
- While a lesson holds the owner, the reel is pinned at full length and they
  stop fiddling with it.
- The snack lies on the grass beside the west spot, inside a full leash but
  still off the path, so the nose finds it.

The pause menu is a two-column grid you move through in both directions:
RESUME, THIS WALK, START AGAIN, SETTINGS, WALK SELECT and EXIT GAME. THIS
WALK opens a card with the walk's name, its gloss, the time and each goal
with its progress (the lesson in the tutorial). START AGAIN and EXIT GAME ask
first ("Start this walk again?", "Quit the game?"). EXIT GAME is also on the
title's prompt bar, on bark. It is desktop only: on the web the grid has five
cells and the title offers no exit. Every exit goes through
`MenuFlow.quit_game`.

`--no-exit` shows the web menus on desktop; `--shot-menu=` gains `walkcard`
and `confirm`, and the shot sweep photographs both.
`tests/test_tutorial_stations.gd` now checks that every held lesson's target
is in reach of where the owner waits, that the snack is on grass, and drives
the dog to eat it; `tests/test_menu_flow.gd` covers the grid's moves, both
questions, the title's exit and the walk card.

## 2026-10-03 - Menu, tutorial reach, and terrain design

The next current-game work is specified as two passes. The first turns pause
into a two-column grid, adds a confirmed desktop exit on the title and pause
screens, and makes every held tutorial target reachable without taking the
nose snack off the grass. The second audits every walk so grass, sand, mud,
puddles and water are traversable, then gives each surface a procedural look
and gait while keeping the existing feel table and the web frame budget.

## 2026-10-03 - The whirl commits to one way round

The tetherball now reads one signed measure of the human-end coil over its
quarter-second arming window. That one mean chooses the direction and the exact
local-coil turn measure, clamped to the authored 0.6-4.0-turn budget, so
winding elsewhere on the leash cannot buy another lap and a contested window
is worth only what it nets. The committed direction cannot flip in flight.
Pull harder and the pulley still spins the orbit up faster.

An ordinary release is the pure orbit tangent after it points at the dog. A
missed tangent gets only the bounded extra arc and a dogward lean; if no
non-reversing dogward fling exists, the human staggers out instead. Timeouts,
lost poles and furniture posing as poles use the same controlled bail, with
the bail frame still shielded from raw tension and the geometry cap. No false
FLING is scored.

The quarter-second take-up rings, orbit ghosts, speed lines, tightening grit
and fling streaks make the motion readable. `tests/test_whirl_guided.gd`
pins the signed coil and its reach, one-way progress, pull response,
pure-tangent and forced releases, refusal, real-pole guard, bail shielding,
one-shot handling and deterministic arming; it is registered in CI beside
`test_whirl.gd`. The rope solver and draw path are unchanged, all six leash
benchmark hashes still match the merged leash overhaul, and the new drawing
builds no per-frame geometry arrays in the whirl branches: two calls while
arming, five while tightening and four once settled, with renderer-time
differences inside measurement spread.

## 2026-10-03 - Smoother leash, continuous tug

The verlet rope remains the one physical leash, but its open spans now draw
with a contact-safe curve: solver points stay on the path, bends beside a
contact stay straight, and curved samples that would cut an obstacle fall back
to the rope chord. Pull direction uses a three-segment length-weighted tangent
on open ends and the original first segment near a contact, preserving wrapped
flings. Repeated leash setup now replaces the existing solver points instead
of appending a second rope, keeping setup idempotent and plant-grip tests on
the current endpoints.

The first 5% of stretch now eases in the spring force, separation damping,
drawn strap weight and the dog's loss of control together. Taut, unwrapped
ropes also damp small settled oscillations. Regression tests cover the public
path, fixed draw buffers, weighted tangents, settling, onset and caller wiring.
The solver benchmark remains within its same-machine guardrails; draw
preparation is about 19 / 22 / 40 microseconds for free, pole and tangle
fixtures, with the same four rope polylines and existing batched circles.
Behaviour snapshots change intentionally where the softer onset changes walk
timing.

## 2026-10-03 - v1.57 submitted to the Microsoft Store

Version 1.57.0.0 was submitted with the listing, What's new text and
certification notes prepared on 2026-10-02. The uploaded screenshot set
contained ten 1920x1080 images in the documented order. El Parc's dog park
replaced the planned square off the leash because the daytime El Gòtic square
duplicated La Castanyada's night plaça too closely.

## 2026-10-02 - v1.57

Everything accepted since v1.56 (#76 to #123): every walk rebuilt as its own
place (El Bosc, El Parc, La Rambla in three steps, Les Obres, El Barri first,
the First Walk, El Diluvi, L'Estació, La Ferralla, El Gòtic, El Mercat, La
Castanyada, La Neteja, El Mosaic in two rounds), the walk names made of each
walk's stuff, the menu cards and prompt bar, the message feed, the game's text
in one voice, the reel and whirl fixes, the dragged owner, the planted skid,
other dogs marking and greeting, the town squares off the leash, the level
review fixes, the Catalan accents, the new logo and the facelift. Then La
Neteja's sweeper as a careening machine that chases you (#125), played before
the tag.
`store/listing.md` has the 1.57 Store text: fourteen walks, the rebuilt places,
the other dogs, the sweeper chase (now photographable, so a tenth screenshot),
and "What's new". 1.56 was never submitted to the Store, so 1.57's "What's new"
covers both, starting with the two new walks.
CI's smoke job gets 20 minutes instead of 10: a green run takes 8 to 9.5, and
half of the day's runs were cancelled at the limit, which would have blocked
the tag's release.

## 2026-10-02 - La Neteja: a sweeper that comes after you

The chase as a Crash boulder run with some Tony Hawk in it, from the August
chase-level brief (PROJECT.md, fun-mechanic backlog item 10).
- **A real street sweeper**, not a wall: a compact road sweeper with the cab
  at the front and the driver in hi-vis behind the windscreen, the hopper
  behind, and a gutter broom on a swing arm at each front corner, out at the
  kerbs. The spray between the brooms marks the kill line, which still
  spans the street. The brooms swing in round the scooters and dumpsters
  parked at the kerb.
- **It careens**: the body swerves about the street, leaning at the dog,
  and lurches faster and slower round its old speed. When it drops back far
  enough to leave the screen it guns it and comes roaring back, so it
  looms at the top of the screen instead of rumbling behind the camera; it
  is never quicker up close than its lurch. The camera leans back up the
  street (at most 90) to keep its front in shot.
- **Junk comes at you**: anything loose the brooms reach (the crates by the
  dumpsters, bottles, sacks) is flung down the street, and a hit knocks the
  dog over. What comes back under the brooms is swallowed.
- **Two respites**: a broom snags a dumpster (at -3600 and -1900), it stalls
  for 2.2s with sparks and steam ("IT'S JAMMED!", the banner says catch your
  breath), then VRRROOM. The one safe moment to stop for dog business.
- **CLOSE SHAVE**: let the brooms within a whisker of the rearmost of you
  and get clear again for +2 bones and a combo trick. The "outrun" goal
  (never within a leash length) pulls the other way, on purpose.
- `--shot-home` turns the pair for home at `--shot-y`, so a chase can be
  photographed without walking out first.
- Tests: `test_sweeper.gd` rewritten for the motion (the lurch averages to
  the set speed, catch-up only when far, jams once, junk flung then
  swallowed, the brooms round parked things, the body inside the street);
  `test_home_chase.gd` gains the jams still ahead, the close shave, the lean
  and the knock.
- The behaviour snapshot is byte-identical: it records when the bot reaches
  each leg, and the chase runs after the last of them.

## 2026-10-02 - A facelift for everyone on the walk

Every character and most of the street got a going-over, in the game's soft,
cartoonish, plasticine style: seen from above, bold silhouettes, light from
the upper left with a lighter top and a darker rim.
- **People** (`human_appearance.gd`, now one renderer for everyone): a head
  of hair seen from above (your human looked bald: the hair was a thin strip
  round the back of a skin circle), a crescent of face, ears, haircuts
  (short, long, bun, curly, the bald spot that is meant to show), caps with a
  peak, beanies with a bobble, shoulders, hands and shoes. Your human, the
  other walkers, the tourists, the pickpocket (hood up now) and the "bet you
  can't" kid all use it.
- **Dressed for the weather**: raincoats with the hood up in the rain, a coat,
  a scarf and a woolly hat in the snow, a scarf in the wind, sunglasses and
  now and then a sunhat on the seafront.
- **Millie**: a shaped, shaded body instead of a thick line, a proper muzzle,
  eyes with the brows from the icon, ears that hang back and flap, a shiny
  nose.
- **Animals**: the other walkers' and the off-leash dogs are real breeds
  now (a dachshund, a poodle, a pug, a dalmatian, a greyhound...), the boar
  is shaped like a boar, the duck, pigeons, gulls and parakeets read as birds,
  and the cats, the wall cats and Tofu are told apart (`clay.gd` shades them).
- **The street**: the Fur-Goneta reads as a dog-grooming van, the buskers
  have guitars and cases with coins, the statues stand on boxes, stalls,
  benches, bins, hydrants and A-boards have their detail, the cyclists wear
  helmets, and the sweeper is shaded like the rest.
- **The walk's subtitle** ("the crowded promenade") is set plainly in the
  menus' face, no wobble, and fades with the rest of the menu.
- Fixes: junk no longer lands on a seller's blanket; a pickpocket whose
  tourist is cleared off screen mid-lift gives up instead of erroring.
- `tools/entity_lineup.gd`: every character and loose prop, big, side by
  side (`cells=K,N` to zoom, `weather=`, `level=`), for judging looks.
## 2026-10-02 - The town walks end in a square

El Mercat, El Gòtic, La Castanyada and La Neteja have PLAÇA over their gates,
and behind them was the same fenced green dog park every walk ends in. Now
they end in a square (`main._draw_placa`, `FREEDOM_KINDS` "placa"):
- Paving in big squares, house fronts round three sides instead of a fence,
  and a sign: PLAÇA DELS GOSSOS.
- Plane trees in rows along the top and down both sides, in their pits (the
  trees are still rope-wrap posts), never in the middle where the fetching
  happens.
- A stone fountain off to one side that is real water: drink, or get in.
- Iron bollards and stone planters to sniff and mark, and the dig spots are in
  squares of earth, not through the paving.
- A flock of pigeons.
Also, on every walk: the street's buildings and each walk's own ground (La
Neteja's wet streaks and slabs, El Gòtic's setts...) used to carry on past the
gate and cover the sides and middle of the off-leash space. They stop at the
gate now. `tests/test_placa_freedom.gd`.
## 2026-10-02 - A lighter logo

The icon and Store art had Millie on a dark green that swallowed both the
black dog and the title. Same Millie, same mid-yank, now on a warm, light sky
with a green hill behind her shoulders, three yank lines at the collar ring,
and the Store poster's title in dark brown on a thick cream outline
(`tools/make_icon.gd`, `tools/make_store_art.gd`). The icon still reads at
16px. Regenerated: icon.png, icon.ico, the MSIX tiles (the wide tile now sits
on the sky colour).
## 2026-10-02 - Catalan with its accents

The Catalan names were written without their accents, because the stroke
letters the ground signs are made of had none. They have them now (À È É Í Ï
Ò Ó Ú Ü and Ç: the base letter and one more stroke, `SignLetters.ACCENTED`),
and the names are spelt properly: PLAÇA over the gates and El Mercat's far
arch, PIPICÀ, Passeig Marítim, El Gòtic, L'Estació. The voice rules in
AGENTS.md now say so.
## 2026-10-02 - Meeting another dog takes two

Your dog going nose to nose with another walker's dog used to be a "sniff! hi"
and nothing else: the other dog walked on as if she were not there. Now it is
a meeting (`main._greet_pair`, `otherpair.greet`):
- The other dog stops and turns to sniff her back, and its owner waits for it
  (1.4 s), then they walk on.
- Its owner says something ("aw, hello", "he loves other dogs").
- About one dog in five is not keen: it holds its tail still, there is a
  "grrr", and its owner apologises ("sorry! he's grumpy"). It still counts as
  a hello.
- `tests/test_pair_greet.gd`.
## 2026-10-02 - La Castanyada's chestnut letters read at night

The walk's name, HOME and the gate sign at La Castanyada are spelt in roast
chestnuts, and the festival is always at night: dark nuts on dark ground
under the night tint were hard to read, the gate sign on the grass hardest.
Each nut now sits in a pale paper-cone rim (`WorldSign._chestnuts`), so the
letters read at a glance and still look like chestnuts.
## 2026-10-02 - Level review, round 1: things where they cannot be

A screenshot pass along every walk (a frame every 700px, issue #21) turned up
things placed where they could not be:
- **Loose junk on top of things.** Crates scattered round a stall, a van or a
  wrecked car landed on top of it: on La Rambla's flower stalls and kiosk,
  El Mercat's stall blocks, La Ferralla's wrecks. Junk now looks for a clear
  spot (off every stall, van, bench, manhole, pond and solid block, off the
  side streets) or is not dropped (`LevelBuild.junk_spot_clear`).
- **Junk on the roofs.** On walks whose path winds (El Gotic, El Bosc, El
  Mosaic, L'Estacio), the background litter was scattered over the old
  straight corridor and landed on rooftops and in the trees. It stays on the
  path now.
- **A cone in the road**: the cone at a cellar hatch by a side street stood
  in the traffic lane. Not any more.
- **El Mercat's drain** had road cones round it inside the market hall; it
  has yellow wet-floor signs now (a new kickable kind).
- **Gate names**: El Parc's and the Passeig's off-leash gates said HOME, which
  is where the walk ends, not the dog park; they say DOG PARK and DOG BEACH.
  L'Estacio's said PLATFORM over a patch of grass; it says PIPICA.
- **Ducks at El Mosaic**, which has no pond, waddling along the terrace wall:
  gone.
## 2026-09-30 - OFF LEASH over the gate, in the walk's own stuff

The gate into the off-leash area had its name painted on in the plain font,
the one piece of ground writing left that was not made of anything. On a
walk with a material (`WorldSign.MATERIALS`) the gate now spells where it
goes and, over that, OFF LEASH, in the same loose pieces as the walk's name
at the start (`main.build_signs`): carnations on La Rambla, trencadis at El
Mosaic, traffic cones (bigger, so they read) on the building site. They can
be bumped and scattered like the name. Walks without a material keep the
painted name. `tests/test_gate_sign.gd`.
## 2026-09-30 - Other people's dogs mark posts

The dogs out on the walk with their people used to stop to sniff at random,
in the middle of nowhere. Now a sniff stop goes where a dog would go
(`entities/otherpair.gd`):
- If a hydrant, lamppost or tree is coming up by its line, the dog pulls
  over to it, nose down at its foot.
- A good sniff there usually gets a reply: it stands side on to the post a
  moment and leaves a mark, in its own colour, at most two a walk each.
- Those marks are the same ones the off-leash dogs leave: your dog can read
  them ("a beagle was here +2") and over-mark them. So a street other dogs
  have walked has messages on it.
- Towed off a post by its human before it is done, a dog gives up on it.
- `tests/test_pair_marks.gd`.
## 2026-09-30 - The station bot walks home beside the walkway

The autowalk bot stalled twice on L'Estacio's home leg, walking down the
middle of the concourse against the moving walkway that carries up it. Going
home it now walks beside the walkway, on its human's side
(`main._auto_drive`). Station's bot finishes at 120 s instead of 162 s with
two stalls; every other snapshot line is unchanged. Bot only: nothing a
player sees.
## 2026-09-30 - A planted dog skids

Planting and getting hauled anyway used to slide the dog along the ground
like a hockey puck, with nothing to show for it. Now it is a skid
(`main._skid`, `entities/dog.gd`):
- She braces facing whoever is hauling her, leaning back on the collar, and
  her front paws throw dust ahead of her.
- Her paws leave a pair of furrows that suit the ground: scuffs on paving,
  deeper ones in sand, dark in mud, torn earth on grass, blue-grey in snow,
  none in water. They fade over eight seconds.
- A low scrape while it lasts.
- A plant grips less on wet ground and least on packed snow
  (`PLANT_GRIP`, `PLANT_GRIP_WET`, `PLANT_GRIP_ICE`): the same haul drags
  her about a fifth further in the rain and nearly twice as far in snow.
- `tests/test_plant_skid.gd`.
## 2026-09-30 - El Mosaic gets its people and parakeets (round 2)

Round 1 built the park's pieces; this round puts the life in them
(`main._tick_mosaic_groups`, `entities/tourist.gd`, `entities/pigeon.gd`):
- **The gate queue**: nine people standing up the west side of the
  forecourt between the gatehouses, edging forward now and then, stepping
  aside for the dog and her human and back into line.
- **The salamander's photographers**: five tourists posing round it with
  cameras and selfie sticks, on its west and south, clear of your human's
  way round the east side. They turn to photograph a dog who comes close,
  and the first time she comes up to drink one of them says so.
- **Pickpockets**: El Mosaic now has La Rambla's crowd rules (fewer people
  walking, since most stand). They start at the gate, and the first steps
  out of the queue to go for your human's wallet.
- **Parakeets**: the flocks here are monk parakeets, green with grey faces,
  feeding under the palms at the foot of the terrace walls; scared, they go
  up over the wall they were under, and one squawk goes up with them.
- **The fan seller** on the plaza with a tray of paper fans and one open in
  hand, waving; **the guitarist** in the viaduct has a guitar now.
- `tests/test_mosaic_life.gd`: the queue clear of your human's line, the
  posers out only as the salamander comes into view and clear of the way
  round, the coo, the pickpocket from the queue, the parakeets' flight.

## 2026-09-30 - El Mosaic is walked through Park Guell's pieces (round 1)

El Mosaic was El Parc's layout on a serpentine with patches of slippery
mosaic floor: in your words, a proof of concept. Now the walk goes through
the park's pieces in order, uphill, on sandy gravel between rubble-stone
terrace walls with palms and agaves; the colour is only where Gaudi put it
(`LevelBuild.mosaic`, `main._draw_mosaic`):
- **The gatehouses** either side of the start: gingerbread walls, wavy roofs
  iced white with trencadis caps, and the red mushroom spire with its cross.
- **The dragon stair**: steps at its foot and head, dripping grotto stone
  along its sides, and on the landing the **salamander** in trencadis, head
  down the stair and tail curling up it. Solid; your human walks round it;
  the drink is the water from its mouth.
- **The hypostyle hall**: a 4 by 5 forest of fat columns with mosaic
  medallions on their capitals, in the shade under the plaza, with a lane
  left through the middle for your human. Wind, whirl and tangle here.
- **The plaza** opens out beyond it, edged the whole way by the
  **serpentine bench**: the plaza's edges wave, the bench is finished in
  trencadis, and since the path's edges are what a grind rides, the whole
  bench grinds end to end ("BENCH GRIND!").
- **The viaduct**: a covered walk with leaning rubble columns down one side,
  their lean read in their long shadows, and the slope on the other.
- **The calvary** at the top: three crosses on a heap of stones.
- No pond, no mosaic floor, no city frontage.

The life comes next round (tourists photographing the salamander, the queue
at the gate, the fan seller, parakeets, pickpockets). `tests/test_mosaic.gd`
(11 checks); the cross-section test now expects the terrace walls at the
path's edge.

## 2026-09-30 - La Neteja becomes a back street at dawn

La Neteja was the old market layout with the stalls taken out. Now its own
(`LevelBuild.neteja`, `main._draw_neteja`), still the narrowest walk and
still runnable for the sweeper chase:
- **Dumpsters** out at alternate kerbs, solid, their corners catching the
  rope, with delivery crates stacked beside them and a bag that did not fit.
- **Scooters** parked up at the kerbs (solid, drawn as El Gotic's are).
- The water truck's **wet streaks** down the street and **puddles** in the
  gutters, on grey setts rather than the market's pale paving.
- The shops' **shutters** still down along the frontage, tagged, with no
  awnings out yet.
- A low **pink-gold dawn light** over the whole walk.
- Washing overhead and the lamppost slalom, as before.

`tests/test_neteja.gd` (8 checks, including a runnable gap past every
dumpster). No walk uses the old market layout any more.

## 2026-09-30 - La Castanyada becomes a night festival in a plaça

La Castanyada was El Mercat's old stall-lined sidewalk with sweets on it.
Now its own (`LevelBuild.castanyada`, `main._draw_castanyada`):
- **An old-town street opening into the plaça** where the festival is, and
  narrowing again beyond it.
- **The chestnut roaster** in the middle of the plaça as the landmark: a
  castanyera's stand with the drum glowing and flickering, chestnuts on the
  grille, paper cones, smoke drifting up, and its warm light on the setts.
  Solid; your human walks round its east side.
- **A stage** on the plaça's west side with the band on it, speakers at the
  corners, and confetti thrown across the setts in front of it. Plane trees
  round the plaça to wind the leash on.
- **Festival stalls** along the street: chestnut barrows, trays of panellets,
  roast sweet potatoes on a griddle, sweets.
- **Paper-lantern strings** from balcony to balcony over the street, sagging,
  lit and glowing, drawn over everyone, with their light on the ground.
- **Chocolate underfoot** as before (steer past it), chestnut shells and
  confetti all along, hessian sacks of chestnuts to mark, and the panellet
  prize off the roaster's tray.

`tests/test_castanyada.gd` (10 checks). La Neteja is the last walk on the old
market layout.

## 2026-09-30 - El Mercat becomes a market hall

El Mercat was eight stalls on a sidewalk with lampposts and a grooming van.
Now a covered market hall, the Boqueria kind (`LevelBuild.mercat`):
- **In under the arch**: off the street through an iron span with a fan of
  stained glass and MERCAT on its board, drawn over everyone, into a hall
  twice the street's width, and out at the far end under a second arch
  into the plaça.
- **Stall blocks down the middle**: four of them, solid, each with counters
  facing both aisles and its trade signed in Catalan (VERDURES, FORMATGES,
  BACALLA, XARCUTERIA...). The owner keeps to alternate aisles round them;
  the dog takes either. A **green iron column** at every corner to wind the
  leash on.
- **Stalls along the walls**: fruit in tipped crates, a juice stand, jamon
  legs, the **fish counter** on crushed ice with meltwater and scales on the
  floor in front, olives in tubs, pick-and-mix sweets. Crates stacked behind
  the fruit, sawdust by the fish and the ham.
- **Orange-crate stacks** by the wall are what gets marked; dropped produce
  in the aisles; the churro prize by the drain in the middle aisle; the
  oranges run from the stall by the door to the far one.
- A **terrazzo** floor under a glazed roof on red iron trusses. The grooming
  van parks on La Rambla only.
- The strollers and delivery scooters go down the two aisles, not through
  the middle where the blocks are.

La Castanyada and La Neteja still use the old market layout.
`tests/test_mercat.gd` (10 checks).

## 2026-09-30 - The scrapyard autowalk finishes at the same time every run

`--level=scrap --autowalk` finished at t=120.0 on some runs and t=121.7 on
others, on one commit. Two causes:
- The camera shake's RNG was unseeded. The shake goes into `cam.offset`,
  which `get_screen_center_position()` includes, and the pair spawner reads
  that for where a walker pair appears. Getting caught on the way home (the
  cameras, lasers and guard dogs) shakes the screen, so pair spawns moved by
  a few pixels at random and the walk forked from there. It now has a fixed
  seed (`SHAKE_SEED` in main.gd); the shake looks the same as before.
- `--autowalk` read and wrote `user://records.cfg`. A finished walk marked
  "bring Tofu home" done, so the next run on the same machine skipped Tofu
  and walked a different home leg (and the bot was ticking goals in the
  player's own save). The bot now runs from a blank in-memory save and
  never writes it (`Game.persist`).
The behaviour snapshot is otherwise unchanged; the scrap finish now reads
t=120.0 every run.
## 2026-09-30 - The autowalk bot keeps to the owner's side of the train

On L'Estacio the bot took 78 s to reach FREEDOM (107 s with the other
walkers' changes, and then never finished within 12000 frames); other walks
take 30-40 s. The bot has no collision (`--autowalk` zeroes the dog's and the
owner's masks so it can glide through clutter), and its weave pulls it to the
middle of the path, which on L'Estacio is the middle of the train. It walked
into the train, dragged the owner in after it, and the rope - which still
collides - wound through the wrap points down the train's sides, one whirl
after another, for the length of the platform.
- The bot now keeps to the owner's side of any island (the train, El Parc's
  lake, El Gotic's plaça), the same rule `human._walk` follows.
- L'Estacio: FREEDOM at t=29.5 (was 78.3); on top of the other walkers'
  change, t=31.3 (was 107.5, unfinished). El Parc 33.8 -> 34.3, El Gotic
  29.4 -> 26.7. No other walk has an island, so nothing else changes.
- A real player's owner does not get caught: with collision left on, the bot
  reaches FREEDOM at t=29.8 down the east platform and t=28.9 down the west
  one (the rope round the train's south end), with no whirls. The level is
  left as it is.
## 2026-09-30 - One voice for the game's text

A pass over the player-facing text, and the rules written down in AGENTS.md
("The game's voice") so it stays consistent:
- **Goals** are sentence-case instructions to the dog, and clearer about
  what to do: "Mark 5 spots", "Say hello to 3 dogs", "Run yourself tired",
  "Scrape past traffic 3 times", "Keep the sweeper a leash length away",
  "Get yourself home without a knock". Every goal, including the per-walk
  prize and delivery ones, is capitalised where it is formatted.
- **Scores** are all a lower-case word and the amount ("nice save +4",
  "bleh, not for dogs -3"), where some shouted in capitals.
- **Dares** read as dares: "DARE: 5 TRICKS, GO!", "DARE DONE!", "DARE
  MISSED: 3 OF 5". Other shouts tightened ("PHWEET! THE SELLERS BOLT",
  "BUSY DOG! 4 THINGS", "THE CALL'S OVER").
- **The tutorial** says "leash" throughout ("Off the leash."), stops
  shouting "SLOW DOWN" mid-sentence, and tells you to walk up the path
  rather than "north".
- **La Castanyada's prize** is a panellet among the sweets, not a pumpkin
  treat among the candy: it is the chestnut festival, not Halloween.
- **Glosses** say a little more: the city park, the seafront, the market
  hall, the old town alleys, the railway station, the tiled terraces.

## 2026-09-30 - You can see the owner being dragged

A dragged owner was drawn exactly like a walking one: facing the way they
were moving, legs stepping, so being hauled across the path by the dog looked
like strolling cheerfully towards her, with a small "!" the only sign. Now,
when the leash is taut and they are moving somewhere other than where they
are walking (`human._track_drag`), they turn to face the pull, brace their
feet wide and stop stepping, lean back against it, reach along the leash
with their free hand, and scuff dust up at their heels while they slide.
Presentation only; `tests/test_owner_drag.gd` (4 checks).

## 2026-09-30 - A tangle with another walker no longer borrows the pole's pulley

A rope wound round a pole amplifies the dog's pull on the owner (the pulley).
It measured winding round ANY contact, so a rope draped over another
walker's leash hauled the owner up to 2.2 times harder, as if it were a
pole, against the rule that tangles do not get pole behaviour. The pulley
now reads `leash.static_winding()`, turning only where the rope touches poles
and furniture.

The leash audit also suggested a wrap's shield depended on reel length (it
counts rope points touching the pole). Measured, the same one-turn wrap
touches 6 points on a 170 px reel and on a 430 px one, so the shield is left
as it is, and `tests/test_wrap.gd` now holds both facts: the same wrap reads
alike on a short and a long reel, and a tangle has no static winding.

Also fixed: a pickpocket stopped after the tourist he robbed had walked off
screen passed the freed tourist to `main.on_pickpocket_stopped`, a script
error (seen in La Rambla's bolt-chase bot walk). He passes no mark now.

## 2026-09-30 - The reel warns first, and the whirl swings round the right pole

- **The reel is telegraphed.** "click!" comes 0.8 s before the leash length
  changes, like every other owner event; it used to change on the same frame.
- **A reel no longer yanks.** It winds slack in briskly, but against a taut
  rope its spring only draws in gently (45 px/s instead of 150), so a click
  never drags the dog away from what she was doing, yet a dog being towed is
  still slowly brought in. (With no give at all the leash only ever
  lengthened, and the idle soak's dog trailed out into El Mercat's bike lane.)
  The owner's deliberate haul when she roams off the path still pulls a taut
  rope in, and now also comes 0.8 s after the tut.
- **The whirl orbits the pole the rope is actually wound on** at the owner's
  end, and only a real pole. It used to pick the nearest thing in the pole
  list, café tables and chairs included, which on La Rambla's terrace held an
  owner in a whirl-stumble loop that never unwound.
- **The whirl starts where the owner stands** and tightens onto its orbit in
  a fraction of a second, instead of snapping them up to 40 px onto it.

`tests/test_reel.gd` (6 checks) and `tests/test_whirl.gd` (5 checks), both in
CI. The behaviour snapshot shifts on most walks; most get home sooner.

## 2026-09-30 - The other walkers look alive

The other owners and their dogs were drawn from the speed they were given,
not from where they went, so a rooted owner walked on the spot and faced down
their lane through a sideways detour, and their dog glided at one speed,
stared at yours from across the park and wagged like a metronome. Now
(`entities/otherpair.gd`):
- Both are drawn from their actual movement: the owner's legs go only when
  the owner moves, and they face where they are going.
- The dog eases up to speed, stops now and then with its nose down for a
  sniff (the leash tows it on if it lingers), faces where it is heading, and
  looks at your dog only once it is close. It wags slowly on a sniff, and
  hard when your dog is right there.
- Sniff stops roll their own dice, so the shared seed is untouched; the
  behaviour snapshot shifts where the dogs now stand when ropes meet.

## 2026-09-30 - Every kind of message gets its own place and look

In a walk everything was said the same way: outlined capitals in the middle
of the screen for goals, moods, the owner stopping and tricks alike, and one
small white label in the world for a stranger's apology, a splash and a +3.
Now each kind has a place:
- **In the world** (`world/pops_layer.gd`): speech is a white bubble at the
  speaker, sounds are tilted comic lettering, scores are a word and a gold
  chip with a bone on it (red for a loss). A new pop stacks clear of a live
  one. The owner's telegraph bubble is a real bubble too.
- **The banner** (what is true right now) is a pill at the top centre. The
  owner's news ("HE'S TEXTING! HE'S NOT LOOKING") takes it over for a moment
  instead of shouting.
- **Toasts**: a goal slides in under the goal list (gold the first time,
  green when it was done on an earlier walk); a mood arrives under the vitals
  in its own colour.
- **Cards**: a tutorial lesson and a bystander's dare are cards under the
  banner; the dare has a count and a timer bar.
- **Shouts** in the middle are only for what she just did or what needs her
  now, in the heavy face; a score for a shout already up lands in that line
  ("POLE SWING!" then "POLE SWING! 14") instead of stacking a copy.
- The tutorial hides the banner, so the lesson is the only instruction, and
  its ground sign says FIRST WALK.
- Two banner lines rewritten: "FULL!" is "FULL TANK! GO MARK A SPOT", and
  "GO BACK DOWN TO HEAD HOME" is "BACK OUT THROUGH THE GATE, THEN HOME".

## 2026-09-29 - Each walk's name is made of the walk, and you can kick it about

The walk's name was one font in a few inks. Now twelve walks spell it out of
their own stuff, as loose pieces lying at the start (`world/world_sign.gd`,
stroke letters in `world/sign_letters.gd`): leaves on El Barri, carnations on
La Rambla, a flowerbed in El Parc, heaped sand on the passeig, puddles in El
Diluvi, fruit at El Mercat, sticks in El Bosc, traffic cones at Les Obres,
chestnuts at La Castanyada, rusty plate at La Ferralla, trencadis on El
Mosaic, soap suds on La Neteja, and paw prints on any walk in snow.
- The walk starts right on top of it. The dog, the human and the rope shove
  the pieces: leaves scatter, fruit and chestnuts roll away, cones go over
  when hit at a run, suds pop, the flowerbed springs back, sand scuffs flat,
  puddles ring. Bodies kick things aside rather than bulldozing them; the
  rope only brushes.
- The pieces stay where they end up, and HOME at the start line is spelled
  the same way, so you come home past what you did to the name.
- The line under the name fades as the walk begins; the name stays.
- Nothing pushes back: the behaviour snapshot is unchanged.
- Locked walks show the browse arrows too.

`tests/test_world_sign.gd` (16 checks).

## 2026-09-29 - Every menu screen gets its own card, and one prompt bar

Every screen off the title was a stack of plain labels in one size and
colour, so the walk select, the owner choice, the wardrobe, a game-over and
the pause text all read as the same wall of text, and each put its button
hints somewhere different. The wardrobe listed every item in one column that
ran off the bottom of the screen, over the chalked walk name, with no clear
way out. Now (`hud/menu_flow.gd` the model, `hud/menu_screen.gd` the view,
`hud/ui_kit.gd` the shared look):
- **One prompt bar** along the bottom of every screen: the buttons as key
  caps for the device in hand, and a verb for each. The title has only that.
- **The walk select** has the two title steps across the top (CHOOSE A WALK,
  GET READY) with the current one lit, your stars and bones in the corner,
  dots above the name for where this walk sits in the list, and a plaque
  under it: stars, goals, best, or what it takes to open.
- **Getting ready** is a card beside the pair: your human, time and weather
  as rows you move through and change with left and right, and the controls
  once, before you set off. Back returns to the walk select.
- **The wardrobe** takes the screen: Millie on a spotlight wearing what is
  highlighted, tabs for collars, bandanas and coats, a swatch and a price
  for each, and back on the bar.
- **Progress** is one table of every walk. **Pause** is a short menu you move
  through (resume, start again, settings, quit to walk select). A game-over is
  a card with a title, and offers trying again or the walk select.
- **Try again means the same walk again**, straight in; R used to drop you
  on the walk select to press through the title twice more.
- The line under the start ("To the park and back...") is gone.
- Headings use an emboldened face of the built-in font, and each screen has
  its own accent colour.

`--shot-menu=walk|details|shop|progress|pause|notice` photographs each
screen, and the shot sweep takes them all. `tests/test_menu_flow.gd` is
rewritten for the new screens (34 checks); the owner-label test went with
the label.

## 2026-09-29 - El Gotic becomes the old town

El Gotic was El Mercat's layout with walls: eight market stalls in a
medieval alley. Now its own (`LevelBuild.gotic`):
- **Alleys that jink** left and right round the old blocks (half 170, eased
  under the slope limit), cobbled in staggered setts that follow them, and
  one opening into **the plaça**: a plane tree, benches, a guitarist, and a
  round stone fountain. The basin is solid; the owner walks round its east
  side (an island), and the drink is at its rim.
- **The bridge** between two buildings over the alley, carved stone with
  pointed windows, on a new **overhead layer** drawn above everyone
  (`world/overheadlayer.gd`), with its shadow on the setts below.
- **Steps** across one alley, **scooters** parked against the walls (solid,
  the rope catches them), **flowerpots** of geraniums at the doors where a
  street has hydrants, bollards where the alley pinches, cats on the ledges.
- The laundry and the lanterns follow the alley's walls now, and La Neteja's
  laundry, which it always defined, is drawn at last.

`tests/test_gotic.gd` (9 checks). The snapshot changes only El Gotic's lines.

## 2026-09-29 - La Ferralla becomes a scrapyard

La Ferralla was La Rambla's layout with guard dogs, café terrace and hydrant
grid included. Now its own (`LevelBuild.ferralla`):
- **A lane that shifts** side to side between the stacks as they were dumped
  (edge nodes, half 250), weeds up to the fence.
- **Wreck stacks** down both sides: three rusted, windowless cars skewed on
  top of each other, solid, the rope wrapping their ends. **Oil** pooled on
  the lane side of five of them.
- **The crane**: its tracks and cab off the east side, the lattice boom out
  over the lane with the magnet hanging, and their long shadow across it.
- **Kennels** beside the sleeping guard dogs, chains run out to them; the
  bone prize is right by the second one. Tyre stacks where a street has
  hydrants, a rain barrel to drink from, floodlight masts.
- The lasers now span the lane where it actually is. No terrace, benches,
  crossings or drains.

`tests/test_ferralla.gd` (9 checks). Only La Ferralla's snapshot lines change.

## 2026-09-29 - L'Estacio becomes a station

L'Estacio was La Rambla's layout indoors, café terrace, bike crossings and
drains included. Now its own (`LevelBuild.estacio`), and a path with a shape:
in off the street through the doors, out into a concourse twice as wide,
through the ticket barriers, and down the platforms either side of a train.
- **The concourse**: big polished tiles, the departures board hung over the
  way in, two rows of fat pillars (they wrap the rope), bench rows, rows of
  nested luggage trolleys, a busker, potted palms where a street has
  hydrants, and the moving walkway up the middle.
- **The ticket barriers**: a line of cabinets across the concourse, solid
  except at three gaps. The owner lines up for the middle one; the dog can
  take either side, and the rope goes where she went.
- **The train** stands between two platforms (path shapes, stage 2: an
  island). It is solid, the rope wraps it, and the owner keeps to the east
  platform. Yellow lines along both edges.
- New goal: "ride the moving walkway end to end", in place of the traffic
  near-misses there is no traffic for.
- The owner lines up for a narrow (the plank, the gate) only on the way up to
  it and across it; once past, the path is theirs again, which is what lets
  them round the train's end straight after the gate.

`tests/test_estacio.gd` (10 checks); `test_obres` checks the plank on the
approach and across. The snapshot changes L'Estacio's lines, and Les Obres'
autowalk times with the narrow change.

## 2026-09-29 - El Diluvi becomes a rainy shopping street

El Diluvi was La Rambla's layout, wet, café terrace and lawn included. Now its
own (`LevelBuild.diluvi`):
- **A narrow shopping street** (half 230), shopfronts straight onto the
  paving, the gutters running down both sides, two side streets with traffic,
  three storm drains gaping open, umbrellas clogging the way.
- **The arcade** down the west side for 2000 px: a covered walk behind a row
  of square stone pillars (they wrap the rope). **Awnings** over the east
  side, striped and dripping.
- **Shelter matters now**: under the arcade or an awning her paws are not
  slick, and the owner dries off. Out in it the owner soaks through
  (`human_soak`, 150 s to wet through, 40 s under cover to dry, a drip meter
  over their head), and says so at half. New goal: "bring your human home
  less than half soaked", so dragging them under the arcade is the walk.
- **Puddles** in the dips of the paving (a new "puddle" substance: wet paws,
  not slow going). Splash through one at a run for a SPLASH trick; the owner
  close by gets splashed too. New goal: "splash through 4 puddles at speed".
  Both replace the traffic near-misses.

`tests/test_diluvi.gd` (10 checks). Only El Diluvi's snapshot lines change.

## 2026-09-28 - The First Walk, rebuilt as quiet stations

Santtu: the tutorial should let the player "learn each trick & mechanic
individually and in peace, without all the distractions of normal levels."
It ran on La Rambla's boulevard with the lessons as a list of cards over a
normal walk. Now it is El Barri emptied out and laid out as **stations**, one
per lesson, 400 px apart so only one is on screen, each holding exactly what
its lesson needs (`TutorialSteps.STEPS` gives each lesson its "at" and
whether the owner waits):

walk, the rope going tight (the owner has stopped), dig in (plant while the
rope is tight), mark (one hydrant), sniff (the next hydrant), the nose (a
snack out on the grass, found by going slow), bark (a flock of pigeons),
the zoomies, ride the kerb, swing round the lamppost, tetherball (the owner
waits by the second lamppost), the brink (a pond off the path's edge),
nature calls (the urge comes at the station, a bin beside it), and in the dog
park: dig.

- **The owner waits** at a lesson that wants them still (`human.tut_hold_y`):
  they walk up, stop short of the station on the phone, and walk on when the
  lesson lands or is skipped. Nothing is rushed.
- **Nothing else turns up**: no random squirrels, no cat, no ducks, no
  crowd, no other walkers, none of El Barri's petanca or ping-pong.
- New lesson checks for dig in, tetherball, the brink and the poop bag.
- `--level=tutorial` (and `--level=daily`) now work from the command line,
  so the tutorial can be shot and self-tested; CI self-tests and smokes it.

`tests/test_tutorial_stations.gd` (15 checks); `test_tutorial_isolation`
and `test_rambla` updated for the tutorial's new home.

## 2026-09-28 - El Barri, the everyday walk, comes first

Santtu: La Rambla should not be the first walk; that should be a generic walk
in the park, a neighbourhood park, nothing distinctly Barcelona. **El Barri**
("the neighbourhood park") is a new walk, first in the list after the
tutorial and the Daily Walk and open from the start; La Rambla now needs 2
stars and El Parc 3. The Daily Walk still rotates through every walk.

A gravel square under rows of plane trees, benches facing each other, a
concrete ping-pong table (the prize ball is under it), the petanca pitch with
its old men in flat caps, a playground with a sandpit, a drinking fountain,
and the fenced dog park at the top ("PIPICA"). No traffic, no crowd, no
pickpockets. The playground is now one drawing shared with El Parc.

Added to CI's self-test, smoke and soak lists and to the snapshot, sweep,
soak and perf tools. `tests/test_barri.gd`; the unlock check in
`test_fresh_save_progression` now looks at La Rambla's gate. The snapshot
only gains El Barri's lines.

## 2026-09-28 - Les Obres becomes a roadworks

Les Obres was La Rambla's layout with cement blobs and a pink paint blob on
it, café terrace included. Now its own (`LevelBuild.obres`):
- **A chicane**: the footway swings one way past the first pour and back past
  the second (edge nodes), under scaffolded frontage.
- **Wet cement poured in formwork**: two rectangular slabs, half the footway
  each on alternate sides, in timber forms with float marks, a cone off every
  corner and red-and-white tape between them. Still slow going and still
  prints her paws; the trowel prize is in the second pour.
- **A freshly painted zebra** across the footway: wet paint to carry off on
  her paws, cones at both ends.
- **A trench** across the footway with a plank over it. The trench is open
  ground (a hole, like a cellar: the dog teeters, the owner must not fall
  in), so the owner lines up for the plank early and keeps to it
  (`main.narrows`, `human._walk`, a dash is held to it too).
- **A parked digger** where the van was, **workers in hi-vis** on their
  shovels where the buskers were, DESVIAMENT signs, two side streets with
  traffic, open manholes at the ends of the works. No terrace, no benches.

`tests/test_obres.gd` (10 checks). Only Les Obres' snapshot lines change.

## 2026-09-28 - La Rambla, step 3: the whistle, the shell game, a dropped ice cream

- **The whistle** (first after 24 s, then every 42 s, only when a blanket is
  in view): "PHWEEET!" and the sellers near the camera pull the cords, carry
  the whole stall off in a sheet to the edge of the promenade, wait there,
  and come back and lay it out again. On the move, each seller is a snag for
  the rope like another lead (`leash.dynamic_obstacles`), and a thief running
  into one goes down tripped. No shouting for walking where a blanket was.
- **The shell game** on a cardboard box with its shills leaning in. Plough
  through it at a run or bark at it and the game's up: cups everywhere, the
  lot of them gone, +6 and a RIGGED trick, the crowd claps.
- **A dropped ice cream** by the cart: a new "icecream" substance (sticky
  pink paws), a mess on the paving rather than a surface, and a thief who
  runs over it slips.

`test_rambla` 26 checks, `test_pickpocket` 15. The snapshot is identical.

## 2026-09-28 - La Rambla, step 2: the crowd and the pickpockets (#80)

- **The crowd** (`entities/tourist.gd`): fourteen tourists kept round the
  camera, ambling up and down the promenade with maps, cameras and selfie
  sticks, stopping for photos. They step aside rather than block, so the
  crowd is dense without wedging the walk. Their own RNG, so nothing else's
  randomness shifts.
- **Pickpockets** (`entities/pickpocket.gd`), from the brief: a readable
  tell (cap low, glancing, "..." over him) for at least 1.6 s while he
  sidles up behind his mark, then the lift. The first one of the walk goes
  for the owner; the rest for tourists. With the wallet (drawn in his hand)
  he runs for the nearest side street at 190, well under her sprint.
- **Stopping him**, all slapstick: the dog at a run bowls him over, the
  leash across his legs trips him, a seller's blanket trips him, something
  slippery drops him, the owner flung into him flattens him. He sits up
  with stars round his head and slinks off; the wallet goes back (+8, +15
  for the owner's, a THIEF trick) and the crowd round about claps. A bark
  or a charge while he is still stalking busts him (+4). Down beside an
  open manhole: "...plop", the wallet is gone and the stop earns nothing.
- **Goals**: "stop 2 pickpockets" and "keep your human's wallet" replace the
  traffic near-misses on La Rambla.

`tests/test_pickpocket.gd` (14 checks). The behaviour snapshot is identical.

## 2026-09-28 - La Rambla, step 1: the boulevard itself

The flagship walk, first pass from `docs/LEVEL_DESIGN.md` (the crowd and the
pickpockets come next). La Rambla shares its layout with the First Walk,
which keeps everything it had (lawn, picnics, calm).
- **No lawn.** The west strip is a traffic lane with a narrow pavement by
  the buildings (a new "road" strip kind); the picnics went with the lawn.
- **Plane trees in a row down both edges** of the promenade, in grates,
  every third one a lamp standard, in place of lampposts on alternate sides.
- **Stalls by kind** (`stall_kinds`): the newspaper kiosk, flower stalls
  (three together, as on the real one), souvenir stands, an ice cream cart,
  a caricaturist. Same bodies and rope points as the market's stalls.
- **Sellers' blankets** with sunglasses, bags or toys laid out. Soft ground:
  walk across one and the seller shouts ("eh! EH!").
- **Human statues** on their boxes, solid. Stand still and watch one for a
  second and it bows (+2 bones, a STATUE trick in the combo).
- **The square**: the promenade opens out halfway down round a round
  pavement mosaic of flat primary shapes.
- **The Canaletes fountain** is the drink stop, drawn as the black cast-iron
  column with its four taps and lamp.
- `--shot-y` now redraws the world after the jump.

`tests/test_rambla.gd` (19 checks); `test_surfaces` checks the lawn on El
Parc now. Only La Rambla's snapshot lines change.

## 2026-09-28 - El Parc becomes its own park

El Parc was a 600 px dirt road with a pond biting into one side and a strip
of planks past it. Now, from `docs/LEVEL_DESIGN.md`:
- **The lake is an island** (path shapes, stage 2): a sandy gravel path
  (half 230) opens out to half 400 round it, with a shore to walk either
  side. `main.islands` names the side the owner keeps to (east), and
  `human._walk` crosses over early enough to be there before the water. Wrap
  points round the shore make the lake the biggest pole on the walk. A
  rowing boat drifts on it.
- **Flowerbeds** hedged with box on the lawns. Their long edges are grind
  rails: the grind now takes `main.rails` as well as the path's edges, and
  the path's edges are followed round a bend (`rail_x`); they were fixed at
  the nominal line before, which was wrong on El Bosc and El Mosaic.
- **The bandstand**, eight solid posts under a green copper roof, for
  looping the owner round.
- **The Ciutadella mammoth** on its plinth; the rope catches its legs, and
  her front foot can be marked like a hydrant.
- **A playground** with a slide, swings and a sandpit. The sandpit is real
  sand, and any sand or mud underfoot on any walk now takes footprints
  (wet cement too, which is sand to `surface_at`).
- The A-board is gone, and the picnics are set from the path's edge.

`tests/test_parc.gd` (11 checks). Only El Parc's snapshot lines change.

## 2026-09-28 - El Bosc's boars, fallen trunks, and an owner who follows the bends

- **The boars** (`entities/boar.gd`): a sow and four striped piglets come out
  of the trees as the stretch at -3250 comes into view ("WILD BOAR! GIVE THEM
  ROOM") and cross the trail, piglets first. They take nothing. Crowd the
  piglets, get between her and them, or bark at her, and she snorts and
  scrapes for 0.7 s, then charges; the charge knocks the dog over (a hit, like
  a rider). The owner, phone up, gets a "...is that a pig?" bubble when she is
  near and is only shoved after it has been up for 0.8 s. A bark near the
  owner still halts them, so barking can stop the owner walking into her, at
  the price of provoking her. New "grunt" sound.
- **Fallen trunks** lie out of the wood across part of the trail at -2640
  (from the left) and -3440 (from the right). They are on a new collision
  layer that only the dog collides with, so the owner steps over them and the
  dog goes round the end, where the rope catches.
- **The owner's weave follows the path** (`human._walk`): it was centred on
  the level's nominal line, so on El Bosc's narrowed pinch the owner could
  drift up to 36 px off the trail. It now follows `walk_edges` at the owner's
  height, as does the dash. This also changes El Mosaic's serpentine.

`tests/test_boar.gd` (14 checks: the snort always comes before the charge,
the bubble before the shove, the trunk blocks her and not him, the weave stays
on the trail through the pinch). The snapshot changes only the autowalk times
on El Bosc and El Mosaic.

## 2026-09-27 - El Bosc becomes a wood

Planning first: `docs/LEVEL_DESIGN.md` now has Santtu's La Rambla (crowded,
stalls, blanket sellers, pickpockets), pickpockets as a system with
slapstick stops, Park Guell piece by piece for El Mosaic, Collserola's boars,
a path shape per walk, and art rooms as detours off the walks (#79, #81,
#82, #83).

Then El Bosc, the first walk rebuilt to the brief. It was El Parc's layout
with a bend: the pond, four park benches, six bins, lampposts along the
trail, hydrants and kebabs. Now it has its own layout
(`LevelBuild.TRAIL_TREES`):
- a narrower trail (half 200, 150 at the pinch) crowded by stone pines and
  holm oaks, with roots running out across it
- a solid wood line 130 px out from the trail on both sides, drawn as
  undergrowth and canopy to the edge of the frame; the forest floor between
  is still hers to nose about in, and squirrels spawn there
- a stream across the wood under a plank footbridge whose four posts wrap
  the rope; she can jump in off the bank, the drink is at the bank, and mud
  is churned up where feet come off the bridge
- waymarker posts with red-and-white bands where the town has hydrants, a
  dropped bocadillo where it has kebabs, one bench at the viewpoint, bins
  only at the trailhead and the viewpoint

`--shot-y=N` starts the pair at that point down a walk, for photographing
one stretch. `tests/test_bosc.gd`. The snapshot changes only El Bosc's
autowalk (it reaches the clearing 1.6 s sooner on the narrower trail).

## 2026-09-27 - footprints in sand and snow

The level design brief (`docs/LEVEL_DESIGN.md`, from Santtu's "design every
element to be fun and make sense") starts with the surfaces. Beach sand, the
dog beach, and any ground under snow now take footprints - hers and the
owner's boots - pressed in as a shadowed hollow with a lit lip, filling back
in over 40 s (`main._press_dents`, at most 240 kept). Sandy paws last 3.2 s
instead of 1.8, long enough to see the sand tracked onto the boardwalk.
`tests/test_footprints.gd`; the behaviour snapshot is identical.

## 2026-09-27 - the buildings come back (#65, restyle step 1)

Every built-up walk's frontage - shopfronts, stone walls, roofs, hoardings,
chain-link - had been drawn under a full-width lawn since v1.51. Each walk
now has a cross-section per side, pavement | strip | building line, from
`LevelBuild.CROSS_SECTIONS`: a lawn, a sidewalk, or nothing where the real
place puts its walls straight onto the paving (El Gotic, La Neteja). The
ground is drawn only as those strips, so the edge layer's buildings show
beyond them; the frontage follows the building line, in slices, so it bends
with El Mosaic's serpentine. The building line is solid (the dog could walk
out over the roofs before), with gaps where a road crosses and short of the
gate. Sidewalk strips are pavement underfoot, grass strips grass; the
off-leash area keeps its own ground, and the bike lane band is La Rambla's
alone. `tests/test_cross_section.gd` checks all ten built walks; the
behaviour snapshot is identical. Next: restyle each walk to look like its
real counterpart, one per PR.

## 2026-09-27 - v1.56

Everything accepted since v1.55: La Neteja and the chase on its own walk
(#64), touch controls (#71), prompts that follow the last device (#63), the
feed and label overlap fixes (#61, #68), snow following the path (#70), the
organic spills (#74) and the ground past the finish (#69). `store/listing.md`
has the 1.56 Store text: thirteen walks, the new chase line, and "What's new".

## 2026-09-26 - the last rectangles underfoot are patches

Five substance zones were still translucent rectangles with an outline:
Les Obres' wet paint, El Mercat's fish, La Ferralla's oil, La Castanyada's
confetti and El Bosc's big mud. They are organic patches now, like the
puddles, cement and sand, placed by the same settling pass. Paint, fish, oil
and confetti stay a mess to carry (they never slowed the dog, and patches
now only slow her for mud, cement and sand). Self-tests pass on all five
walks, and the behaviour snapshot is identical.

## 2026-09-26 - merges, a handover refresh, and a rope idea dropped

#71 (touch controls, finished off with SKIP and SHARE) and #64 (La Neteja)
merged; #20 closed. The behaviour-snapshot baseline was rebuilt on main now
that the chase has moved, and HANDOVER.md rewritten for the state after
v1.55. Tried and dropped: sleeping NPC walker ropes far off camera. The gain
was within noise and the snapshot changed (two walks finished 0.6 s and
8.2 s later), so it is recorded on #45 rather than merged.

## 2026-09-24 - La Neteja: the sweeper chase gets its own walk (#20)

A thirteenth walk, and the chase's new home. La Neteja ("the dawn
clean-up") is a narrow back street, 370 px wide where the boulevard is 680,
so the sweeper - 276 wide, brush head the full width - fills it and reads as
a machine bearing down rather than a slab across a road. It is built on the
market's cross-section with the stalls and buskers cleared out (the home leg
is a run), a slalom of lampposts to snag the leash on, washing overhead, a
fountain in the square. Unlocks at 23 stars. Its goals swap Tofu (who never
shares a home leg with a chase) for "never let the sweeper within a leash
length", which judges the chase run well rather than merely survived.

- The chase now rolls only here, every time; the other walks never get one.
  Their random sequence is untouched: the old roll is still drawn and
  ignored, so dailies and --seed replays play out as before (the chase test
  checks it for 60 seeds).
- The machine draws behind the dog and the human, so it can never paint over
  them or the leash; the brushes reach 46 px past the kill line, which is
  what #20 saw. When it catches someone it comes to the front and rolls over
  them for 0.75 s, with a "SWEPT!" shout, before the game-over card.
- Fixed on the way: a walk that rolled a chase was SCARED from the first
  step of the way OUT, because the dread read chase_active, which is set at
  level start. It now needs the machine on the road. With a chase forced on
  street, the autowalk reached the park at 35.5 s instead of 30.3 s; now 30.3.

The behaviour snapshot differs from main exactly there: the three forced
chase autowalks, and five idle soaks whose seed used to roll a chase.
Not yet: the dawn light, and the grass that shows beyond the pavement at the
start of the market-based walks (El Gotic has it too; #21).

## 2026-09-25 - the missing touch actions get buttons (#62)

Touch now has context-sensitive controls for the actions missing in #62:
RUN during a walk, MENU on the title and while walking or paused, SKIP during
tutorial lessons, SHARE on daily results, and the goals card itself opens the
goal list. Restart only appears once a walk has stopped, away from the goals
card, instead of sitting one tap from an accidental reset throughout the walk.
The controls are checked at three landscape window shapes in
`tests/test_touch_controls.gd`.

## 2026-09-24 - snow follows the path on the walks that bend

Second level-review pass (#21): every walk in rain, wind, snow and at night,
and at 844x390. Night, wind and rain read on every walk and the phone
landscape fits. Snow did not, on El Bosc and El Mosaic: its slush was a
rectangle between the corridor's nominal edges, so the bending path ran out
from under it (bare dirt beside the snow) and slush lay on the grass, over El
Bosc's pond too. The slush is a band that follows `walk_edges()` now, using
the band helpers the patches already had, and it draws only the stretch on
screen. `tests/test_snow_slush.gd` checks the whole length of three walks and
fails on the old rectangle. Also new: `--night`, for screenshots and reviews.

## 2026-09-24 - the ground reaches the bottom of the finish (#67)

The world's ground was painted down to 320 px past the start line. The south
wall stops the dog about 110 px past it, and the camera on her there sees
280 px further (375 at 1280x960), so the finish showed a strip of bare
background along the bottom of the frame on every walk. It is painted to
560 px past the start now.

## 2026-09-24 - world labels keep clear of the feed (#66)

World labels ("FULL!", "hello? ...oh hi", "click!") are drawn at their
object, and the owner and the dog sit near the middle of the screen, which
is where the feed is. A label that would cross a feed line at any point of
its rise now spawns above it instead (`main.clear_of_feed`, using the feed's
new `ink_rects`). `tests/test_float_text.gd` spawns labels across the feed's
band and checks none ever shares screen space with a line. A feed line that
arrives after a label has spawned is not avoided; labels last 0.9 s.

First level-review pass (#21): every walk at five points of the autowalk.
Filed #65 (the built-up walks' frontage is hidden under grass since v1.51,
a design call), #66 (this), and #67 (the beach finish shows flat grey).

## 2026-09-24 - prompts follow the player's hands (#9)

Button prompts used to pick keyboard or controller names by whether a pad
was PLUGGED IN, some strings named keys directly (the settings hint, a
results prompt, the tutorial's WASD, Q, E and SHIFT), and phones got
keyboard keys they do not have. New `hud/prompts.gd` names actions for the
device last used - keyboard, controller or touch (touch names are the touch
buttons: DIG, BARK, PEE, R) - switching on a key press, a pad button, a
stick pushed past half way, or a touch. A drifting stick and the mouse
clicks a touch screen emulates do not count. One-shot text (the pause menu,
the death cards, the daily share card) is re-filled when the device changes,
unless the label has been rewritten since; the title is rebuilt.

For keyboard players nothing changes: the screenshot sweep matches main on
every shot outside the version label. `tests/test_prompts.gd` (71 checks)
covers the switching and the re-fill, and fails on any key name written into
a UI string or any {token} that is not an action. Touch has no button for
settings, pause, turbo, share or the goal list, so those prompts fall back
to the keyboard name on a phone (#62).

## 2026-09-24 - the feed no longer writes over itself (#59)

The status banner came back in #43, and nobody had seen it and the feed at
once since: the first feed line sat 31 px under the banner, then rose 17 px
over its life and landed 28% oversized, so its capitals climbed straight
into the banner's ("GET THE CAT HOME! FOLLOW HER" under "YOU TANGLED THEM!").
`hud/event_feed.gd` now gives every line a slot tall enough for everything
it will do (its capitals and outline at the biggest punch, and at the top of
its rise), and the layout is a function that `tests/test_event_feed.gd`
checks at every pair of ages: no two lines ever share a row of ink. With a
banner up, the feed sits about 25 px lower. With no banner it starts where
it always did.

World labels such as the reel's "FULL!" are drawn at their object, not in
the feed, and can still land behind a feed line.

## 2026-09-24 - the 1.55 Store update

Santtu uploaded PathOfLeashResistance-1.55.0.0.msix to Partner Center.
`store/listing.md` now holds what goes with it: "What's new in this version",
the description and short description at twelve walks with moods and
surfaces, two new product features, a note for certification, and a new
El Mosaic screenshot (`--level=guell --shot-at=3100`, stamped v1.55). Taking
the screenshots turned up #59: the status banner and the feed lines draw on
top of each other.

## 2026-09-24 - what is left on street in the browser is GPU fill

On street in headless Chrome the script is small (physics step 0.6 ms, world
draw 2 ms, renderer CPU 0.6 ms) while frames take 12-16 ms, so the rest is
GPU work WebGL cannot time. The new `--perf-no-grade` diagnostic switches
off the full-screen grade pass (hud/grade.gdshader, which also forces a copy
of the whole screen). Three alternating runs each: grade on 55-75 fps
(frame p50 11.8-16.5 ms), off 74-93 fps (9.5-12.1 ms), about 3-4 ms a frame
on the integrated Intel GPU, with a lot of run-to-run noise. Making the pass
cheaper changes the picture, so it waits for a decision rather than landing
under the WIP limit.

## 2026-09-24 - v1.55, and the browser measured

v1.55 is tagged: everything since v1.54, including the freeze fixes awaiting
acceptance and all of the performance work above.

The web build was finally measured rather than inferred. `tools/web_perf.sh`
exports it, serves it locally and plays each level's autowalk in headless
Chrome on the laptop's integrated Intel GPU (through ANGLE, and not
throttled like a background tab). Two runs each, before any batching against
v1.55:

| level | before | v1.55 |
|---|---|---|
| street | 9 fps, frame p50 93-100 ms | 45-51 fps, 18 ms |
| park | 7-13 fps, 66-133 ms | 40-71 fps, 13-22 ms |
| market | 9-16 fps, 50-95 ms | 91-101 fps, 9 ms |

Every frame of the old build was over 16 ms in the browser. Street is still
under 60 fps and is the next thing to look at.

## 2026-09-24 - the hitch at the gate was a script compile

The probe now names the three biggest parts of main's physics step in each
spike frame, which pointed straight at the walk's phase changes: stepping
into the off-leash area cost 36-49 ms in one frame, the way home 14-22 ms.
Most of it was GDScript compiling ball.gd, freedog.gd and rival.gd (and
tofu.gd, the sweeper) the first time they were load()ed, mid-walk. `_ready`
now loads every script spawned after the level is built (MIDWALK_SCRIPTS),
while the level is loading anyway; the later load() calls hit the cache. The
worst headless frame on street fell from 46 to 25 ms, on park from 65 to
19 ms, and the behaviour snapshot is identical.

What was left at the phase changes was the autowalk bot's own "AUTOWALK
reached ..." print: printing to a piped console on Windows costs 2-16 ms,
against 0.03 ms when nothing reads it. Real play prints nothing. The
physics-step marks are also corrected: in the off-leash phase the romp and
fetch had no mark and were billed to "goals, progress", now "goals" and
"progress" apart.

## 2026-09-24 - the layers and the busiest entities batched too

The freedom and verge layers draw through a ShapeBatch like the edge layer,
and so do the cones, the dog, the human, the NPC pairs, the free dogs, the
leash and the HUD card (each `_draw` hands a stand-in batch to what used to
be its body, so an early return can never skip the flush). The dog and human
appearance drawers and main's shadow helpers take either a canvas or the
stand-in; the tests' fake mains follow suit.

Windowed at 1280x720, calls per frame p50 (max), after the world batch ->
now: street 264 (537) -> 190 (299), market 202 -> 140, site 227 -> 167,
park 154 (426) -> 98 (209), beach 159 (548) -> 123 (307). Against the build
before any batching street is 833 -> 190. The worst frames fell most: the
off-leash area's layer was the spike. The screenshot sweep is identical on
all 17 shots.

## 2026-09-24 - main's whole world draw through one batch

Every draw call main.gd makes on its own canvas now goes through a ShapeBatch
standing in for the canvas (made fresh in `_draw`): runs of shapes become one
draw call, and text, arcs and polylines flush the queue and pass straight
through, so the order is kept. Helpers handed main as their canvas
(`cast_shadow`, `contact_shadow`, the tree and palm drawers, `draw_patch`,
`UiIcons.draw_paw`) take the batch instead, and a helper's own batch flushed
into it joins the queue. Rects are placed with one native transform of a unit
quad, so the batch costs no more script time than the plain calls.

Windowed at 1280x720 (calls p50, renderer CPU p50, main's draw p50), against
the build before any batching:
street 833 -> 264 calls, 3.65 -> 1.57 ms render, 2.29 -> 2.37 ms draw;
market 669 -> 202, 3.32 -> 1.31, 1.56 -> 1.45; site 572 -> 228,
2.30 -> 1.17, 2.92 -> 2.45; park 409 -> 154, 2.12 -> 0.97, 1.20 -> 1.01.
The screenshot sweep is identical on all 17 shots, and test_shape_batch now
also covers a batch flushed into the stand-in.

## 2026-09-24 - fewer draw calls, same pixels

`systems/shape_batch.gd` merges runs of filled circles, rects, wide lines and
polygons into one draw call. It rebuilds each shape's vertices exactly as
Godot does, in the same float32 operations and order, so the picture is the
same pixel for pixel. Lines needed one extra step: the renderer stores a
line's colour as half floats, so the batch rounds it the same way.
`tests/test_shape_batch.gd` renders 240 mixed shapes both ways and compares
exactly, and the screenshot sweep is identical on all 17 shots. It also works
as a stand-in canvas: a drawing function that takes `c` can be handed the
batch, and anything it cannot reproduce (outlined rects, 1px lines, text)
flushes and goes straight to the canvas.

Used so far on the edge layer (shopfronts and walls, which alternated rects
and lines and were 316 of street's 781 calls), tree canopies, palm trunks,
scent motes and cone rings. Windowed at 1280x720, calls per frame (p50):
park 408 -> 228, market 672 -> 359, street 833 -> 479, site 576 -> 459.
Renderer CPU time falls 20-40%. Headless frame and draw times are unchanged,
because each circle is placed by one native transform, not a script loop.

## 2026-09-24 - screenshots that match pixel for pixel

Two screenshot sweeps of one build used to differ almost everywhere, so the
sweep could not show that a render refactor left the picture alone. Three
causes: shots ran on the wall clock (the camera sat somewhere different each
time), layouts and spawns were random, and cosmetic animation (tail wags,
flicker, blinking prompts, rain) read the wall clock or an unseeded RNG. The
sweep now passes `--fixed-fps 60 --seed=1`, cosmetic animation reads the new
`AnimClock.msec()`, which shot mode pins to the frame count, and the weather
overlay seeds its own RNG in shot mode. Two sweeps now match exactly on all
17 shots. In play `AnimClock.msec()` is the wall clock, as before.

## 2026-09-24 - where the draw calls go

The Compatibility renderer gives every circle, polygon and thick line its own
draw call; only rects and thin lines batch. A windowed site walk at 1280x720
makes about 574 calls a frame (837 at most). `--perf-hide=` hides one kind of
entity and shows its share: cones and junk 85, the edge layer 54, the dog 25,
NPC pairs 22, the HUD card 19, the human 12, the leash 11. Everything else,
about 340, is main.gd's own world draw.

The probe now also reads the renderer's CPU and GPU time, which, unlike frame
time, does not stretch when Windows throttles a background window. On the
laptop the renderer's CPU time is 3.6 ms a frame and the GPU 0.7 ms. Hiding
the cones' 85 calls saves 0.31 ms, about 3.6 us a call. WebGL pays far more
per call, which fits the browser build being much choppier than the Windows
one: fewer draw calls is the lever for the web. `tools/shot_diff.py`
pixel-compares two screenshot sweeps, so merging shapes into fewer calls can
be shown not to change the picture.

## 2026-09-24 - the NPC route planner: shared geometry and a broad phase

Every NPC walker and rider built its own copy of the level's blocker clusters
when it spawned, an O(n^2) pass that took about 2 ms per spawn on site and
street (55 blockers) and would take about 26 ms at 200. The planner
(`systems/bypasser_route.gd`) now builds it once per blocker list and
clearance and shares it: later spawns take about 25 us. The list is compared
by value, so a rebuilt level gets fresh geometry.

The per-frame corridor tests also skip a cluster whose bounding box is clear of
the corridor before testing its members. Route cost per frame: site
0.31 -> 0.27 ms, street 0.17 -> 0.12 ms. Both changes leave every result the
same: the behaviour snapshot is identical, and test_bypasser_route has a
new sharing check.

## 2026-09-24 - a faster rope solver, same numbers

`entities/leash.gd`'s solve loops do less interpreter work: the rope ends are
read once per tick instead of once per iteration, each point is read once per
constraint pass, and the collision pass skips obstacles outside a segment's
padded bounding box before the exact test (inlined). Same arithmetic in the
same order, so the output is bit-identical: `tools/bench_leash.gd` hashes
every solver output over three scenarios and the hashes match, and the
behaviour snapshot is identical. Per tick: free rope 64 -> 58 us, wrapping
poles 174 -> 132 us, tangled with another leash 640 -> 280 us.

The profile also shows the NPC route planner (`bypasser_route.step`) costing
more than the NPC ropes on site: about 0.65 ms a frame against 0.26 ms.

## 2026-09-24 - correction: measure frame time, not Godot's time monitors

The entry below says "headless script time is 11-15 ms per frame". That came
from Godot's TIME_PROCESS monitor, which does not mean per-frame cost here:
headless it read 12.5 ms while whole frames took 2.8 ms of wall-clock time.
Measured properly, all game logic plus physics is about 2.3-3.2 ms per frame
on the laptop, so the browser's choppiness is more likely rendering
(800-1,150 draw calls a frame) than script. On site, NPC walker pairs cost
about 1.2 ms of that and cones and junk about 0.9 ms. The probe now prints the
monitors as mon_proc/mon_phys and says what to compare instead; #45 has the
corrected baseline.

The probe also splits main's physics step by subsystem (wall-clock marks):
0.4-0.7 ms, most of it the rope solve. `--perf-disable=` and
`--perf-disable-process=` switch off one kind of entity's physics or redraw,
to measure what it costs.

## 2026-09-24 - freeze fixes, and the first performance numbers

Bug fixes, each with a test that fails on the old code where one is possible:

- **Wardrobe preview dog (#33):** never given `main`, so every draw errored
  before the body was drawn. Now set up like the real dog.
- **CI fails on any script error (#32):** `tools/godot_ci.sh` wraps every
  test step. Its first run found no other hidden errors.
- **A-stands (#30):** the spawn loop sat in `on_junk_kicked`, so none stood at
  the start and every kick stacked a full set - 350 to 510 physics nodes per
  walk by the one-minute mark. Now spawned once with the other furniture.
  Physics median down about 25-35% on rain and site.
- **Status banner (#29, S2):** the call that shows NEED A WEE, LOOSE LEASH,
  FETCH, GO SLOW, THIRSTY and RUN sat after a `return` since 2026-08-03, so
  none of them reached the screen. `_update_hud` sets it now, during a walk.
- **Mood badge (#7):** moved off the third phone pip to the card's bottom row.
- **Title prompt (#8):** moved below the dog.
- **Results card (#31):** room under the rating line.
- **Settings over the title (#10):** the chalked title is no longer drawn
  behind the panel.
- **CI queue:** the 12-job idle soak runs on PRs only when gameplay code
  changes; every push to main still soaks.

Performance (tracked in #45): the new `--perf` probe and `tools/perf_sweep.sh`.
Headless script time is 11-15 ms per frame on every walk - the likely cause
of the browser's choppiness, since GDScript runs several times slower there.
Physics spikes line up with five or more NPC walkers on screen. Windowed
sweeps on Windows are only valid with the game window in front: background
windows get throttled to 30 fps, which is what eight walks showed in the
first sweep. Tried and dropped: sleeping off-camera cones (identical
behaviour, no measurable gain).

## 2026-09-24 - scripts moved into folders (freeze task 5, part 2)

Every script except `main.gd` now lives in a folder: `autoload/` (Game, Sfx),
`entities/` (20 scripts), `hud/`, `world/` and `systems/`, next to the modules
split out of main.gd. One folder per commit, each script moved with its .uid,
and every `res://` path rewritten in the same commit (project.godot's
autoloads, main.gd, the modules and 30-odd tests). Each commit passed the
full ci.yml test list and an identical behaviour snapshot. AGENTS.md's project
structure is rewritten to match (#15).

## 2026-09-24 - main.gd split along its seams (freeze task 5)

`main.gd` goes from 8,029 to 5,818 lines. Six seams move out verbatim, one
commit each, as static functions over main's state:

- `systems/mood_wiring.gd`: how the walk feeds the dog's moods
- `systems/home_chase.gd`: the home-leg chase roll, start and tick
- `systems/goals.gd`: goal lists, crediting, the goal card, the end of the walk
- `hud/hud_build.gd`: every HUD node, in draw order
- `hud/menu_flow.gd`: title steps, wardrobe, settings, progress screen
- `world/level_build.gd`: corridor, level data, props, walls, entities

main.gd keeps a same-name forwarder for everything the rest of the game and
the tests call, so no caller changed. Every commit passed the whole ci.yml
test list and a new `tools/behaviour_snapshot.sh`, which records 51
fixed-seed runs (autowalks, idle soaks, self-tests) and must match
byte-for-byte. It now runs four at a time, each with its own save, in about
three minutes.

Two new tests cover what CI could not reach: `test_home_chase.gd` (the chase
catching someone and ending the walk) and `test_menu_flow.gd` (title steps,
wardrobe and settings). The menu test found #33, the wardrobe preview dog
erroring on every draw, which predates the split.

Left in main.gd on purpose: world drawing (about 2,400 lines), the leash and
tug, pairs and traffic, the dev modes and the input handling in `_process`.
They are too coupled, or too pinned by tests, to split safely during the
freeze.

## 2026-09-23 - the idle knock was the wall clock (#6)

An idle dog got knocked by bikes on some machines and window sizes and not
others. The cause: the owner's sideways weave across the path read
`Time.get_ticks_msec()`, the time since the program started. So where the
owner walked, and where a dragged dog ended up relative to the bike lane,
depended on boot time, time spent on the title and render speed. A bigger
window renders slower, which is why it looked like window shape. The weave,
the owner's phone-event movement, the scooter kid's wobble, a spooked cat's
zigzag, duckling bobbing and the scrapyard cameras now run on `main.elapsed`.
Drawing-only animation keeps the wall clock.

New idle soak to measure it: `--soak[=SECONDS]` plays a walk with no input
and prints knocks by cause, mood arrivals, phone cracks and any early end;
`--seed=N` makes a run replayable. `tools/idle_soak.sh` covers every walk at
1280x720, 1920x1080 and 844x390 over three seeds, and `soak.yml` runs it on
PRs and main without gating CI. After the fix, a seed gives identical results
at every window size, and no idle dog is knocked before 19 seconds on street
or market.

## 2026-09-23 - WIP limit on unaccepted changes

AGENTS.md gains a change-control rule: at most 5 player-facing changes on
`main` awaiting acceptance by hand, and only hardening and tooling at the
limit. Merging is not acceptance; the board's "Awaiting acceptance" column
is. Every PR carries a feel card, 3-5 concrete things to check by hand.

`main` starts over the limit: eight player-facing changes from 2026-08-02/03
were never accepted. They are listed with feel cards in the acceptance
backlog (#23).

## 2026-09-23 - portrait windows get a rotate prompt (#5)

A window taller than it is wide cannot hold the layout: the world rendered at
about a third of its size, the HUD was unreadable, and the camera showed the
street behind the start line. `rotate_prompt.gd` now covers a portrait
window with "Turn your phone sideways" ("Make the window wider" without a
touchscreen) and pauses the walk until the window is landscape again. On the
web it also requests the browser's landscape lock, which only Android Chrome
offers, and only in fullscreen. `tests/test_rotate_prompt.gd` (in CI) checks
the prompt follows the window shape, pauses only while it is up, never
releases someone else's pause, and keeps its text at least 14px on a
390x844 phone. Under `--shot` it shows without pausing, so the sweep can
photograph it.

## 2026-09-23 - live on the Microsoft Store

v1.54 went live on the Microsoft Store as 1.54.0.0
(https://apps.microsoft.com/detail/9p5d14v8rbqx), packaged by `store/msix/` and
certified on the first real submission. The v1.54 build was chosen over
`main` because `main` holds 17 gameplay commits not yet accepted by hand.

- `store/listing.md` records everything entered in Partner Center: the
  listing text, properties, the age-rating answers, and the privacy policy.
  Two things went wrong the first time and are written down there. The first
  upload used the wrong identity spelling ("Nykanen"; Partner Center writes
  "Nyknen"). The first IARC pass answered that innocents can be seriously
  injured, which got PEGI 16.
- `tools/make_store_art.gd` draws the poster, box art and tiles from the icon's
  own drawing code, with the title in the game's font.
- Settled: "MSIX or PWA game" accepts a full-trust Win32 MSIX.

## 2026-09-23 - Microsoft Store packaging (unreleased)

The game now has a Partner Center product, "MSIX or PWA game", Store ID
9P5D14V8RBQX. The packaging is rebuilt from scratch on `main`; the unpushed
`ms-store-msix` branch is superseded.

- `store/msix/AppxManifest.xml` holds the product's identity and describes a
  full-trust desktop game. `tools/make_msix_assets.py` derives the tile
  images from `icon.png`. `store/.gdignore` keeps Godot from importing or
  packing any of it.
- `tools/pack_msix.ps1` turns an exported exe into an unsigned MSIX,
  versioned from the tag (`v1.55` becomes `1.55.0.0`). The Store signs it.
- `tools/verify_msix.ps1` installs the package with a throwaway certificate,
  launches it packaged, and reads Godot's log from the package's private
  AppData.
- `release.yml` gains an `msix` job after the itch publish: pack, verify, and
  attach the MSIX to the GitHub release. `msix.yml` runs pack, verify and
  WACK on PRs that touch the packaging.

## 2026-09-23 - stabilization freeze: screenshot sweep tooling (unreleased)

No features until verification catches up with 138 commits in 25 days. This
session adds tooling only.

- `--shot-out=PATH` and `--shot-quit` for `--shot` mode. Without them nothing
  changes: the PNG still lands in `user://shot.png` and the run still ends on
  `--quit-after`.
- `tools/shot_sweep.sh` photographs all 12 walks, the title, settings and
  results screens, and the street at 844x390 and 390x844 (xvfb and software GL
  on Linux, as the appearance tests in ci.yml do). `tools/contact_sheet.py`
  tiles them into two labelled sheets.
- `.github/workflows/shots.yml` runs the sweep on every PR and push to
  main and uploads the sheets. It is a separate workflow, so it never gates ci.yml or
  the release.
- The title's hardcoded "v1.54" is gone. `tools/stamp_version.sh` writes the
  tag and short commit into `build_label.txt` during export, and a build
  without the file says "dev".

The first sweep already shows problems logged for triage rather than fixed:
the portrait street renders tiny and shows the area behind the start line;
the settings panel lets the title show through above it; the title dog sits
on "press SPACE to begin".

## 2026-08-02 - dog moods, first pass (unreleased)

Backlog item 9, the one the plan calls the strongest idea in the pile. A mood
is not a screen tint: it changes what the level IS to you, and the handling
moves with the picture so you feel it in your hands before you read it on the
screen. New `mood.gd`, pure logic like teeter.gd so it tests headless.

Design decision taken this session: moods are **weather, not a menu**. They
only ever arrive from something that HAPPENED and they fade on their own.
There is no key to pick one and no key to cancel one. What the player controls
is what they DO about it, and doing what a mood wants feeds it - barking while
barky keeps you barky, running while the zoomies are on keeps them going.

Having no cancel button is only safe if the fading is guaranteed, so the
bounds are part of the design rather than tuning:

- nothing here touches the camera or the zoom. The frame you play in is the
  one thing a mood never takes.
- SCARED shortens what you can SMELL, not what you can see. It only limits
  perception - nothing becomes unfindable, so a mood makes a walk harder to
  read and never impossible to finish.
- the biggest speed change is a fifth either way, and the vignette closes part
  way, never to a keyhole.
- the longest mood is fifteen seconds and the HUD names it the whole time,
  with a draining bar: the promise that this passes on its own, visible.

Four moods. SCARED (a guard dog, a knock, something eating the pavement behind
you): cold, drained, closing in, fast and stupid, and the street stops telling
you anything. BARKY (a cat seen off, a chase, Brutus taking your things, your
own barking): everything vivid and too close, and you lunge hard enough to tow
the human off his line. ZOOMIES (rested and off the leash): wide open and
bright, all legs and no steering - it adds a veer on top of wherever you
pointed. FLAT (running yourself empty, or a whole kebab off the pavement):
washed out, heavy going, and easy for the human to simply tow.

The zoomies veer on layered sines rather than a random number, because the CI
leans on `--autowalk` being deterministic and a mood in the movement path
would otherwise take that with it.

Two things the build caught that were worth catching:

- `FADE` did not mean what it said. Decaying at a flat 1/FADE, a mood dropped
  under the onset threshold at 66% of its stated time - SCARED lasted 5.9s
  with a 9.0 constant. Now scaled so the number reads as "how long this mood
  lasts", and the test holds it to that in both directions.
- FLAT was a trap. It was fed every frame the tank was low AND fed again for
  moving slowly, which is a spiral: slow makes you flat, flat makes you
  slower. Autowalk found it as a hard stall on the home leg (the bot holds
  turbo permanently, so its energy sits at zero and FLAT pinned on). Feeding a
  mood for DOING something is right for the zoomies and exactly wrong for the
  one mood you most need to come out of. Now an edge trigger with hysteresis:
  hitting empty is a moment, not a condition.

New `tests/test_mood.gd`, 79 checks, in CI. Most of it guards the promise
rather than the feature: no mood starts by itself, one small event is not a
mood, every mood ends within its own advertised fade, the grade lands back
exactly on the authored values, and no entry in the effect tables may exceed
its bounds - so a later tuning pass cannot quietly grow a mood into something
that plays the game for you.

Still open: how a mood should read on a controller or a phone, where there is
no room for a sentence; and whether SCARED during the sweeper chase is one
mood too many at the tensest moment of the walk. Both want playtesting rather
than more design.

## 2026-08-01 - v1.54: mobile web canvas scaling

The known-deferred gap from the v1.53 closeout: on a phone-shaped browser
window the game rendered as a small fixed canvas with large black borders.
Root cause was `window/stretch/aspect="keep"`, which letterboxes to the
1280x720 reference frame instead of filling a window of a different aspect
ratio - measured at a simulated 390x844 portrait window, only 219 of 844
vertical pixels were game, the rest black. Switched to `"expand"`, which
fills the window and reveals more or less than the reference frame on the
short axis instead of blanking it - a strict improvement at every window
shape tested (native 1280x720 unchanged, wider and narrower landscape, and
portrait).

That alone would have shipped a scaling fix with unusable touch controls:
`touch_controls.gd` positioned its stick/button split and every button
centre against literal 1280x720 coordinates. Under `expand`, a phone's real
landscape aspect (e.g. 844x390, much wider than 16:9) reveals a visible
width past 1280, so the buttons drifted away from the true corner and the
old `touch.x < 620` stick-vs-button threshold stopped matching the screen's
actual midpoint - a real "dead zone" that responded to neither. Buttons and
the split now derive from `get_viewport_rect().size`, recomputed on resize;
verified pixel-identical to the original layout at 1280x720 and correctly
corner-anchored at 844x390.

Same root cause, smaller stakes, fixed alongside: the goals card and the
results/settings modals were positioned against the 1280x720 reference
rather than the actual viewport, so they drifted off-centre or away from
the true corner on any other aspect ratio; the pause/settings dim overlay
was a fixed 1280x720 rect that left the newly-revealed edges of a wide or
tall window undimmed during pause. Also fixed while in the same file: the
settings panel's height was a fixed constant sized for 4 rows, so adding
the "GOAL LIST" toggle row made it overlap the control-hint text at every
resolution, including native - it now sizes to however many rows the
current platform actually shows.

Verified locally by launching with `--resolution WxH` at several phone
landscape shapes (667x375, 844x390, 932x430, 915x412) and a portrait shape
(390x844), full logic + render test suites, `--selftest` across all twelve
walks, and autowalk (plain + all three chase variants). Not yet confirmed
on a real device/browser - the auto-rotate-to-landscape behaviour some
phones show is the browser's own orientation lock, not something this
project requests, and its availability varies by browser (notably absent
on iOS Safari), so a phone that stays in portrait is a real case, not an
edge case.

**Second pass, before tagging: the sweep above was incomplete.** It fixed
the four separate panel scripts and missed every element built inside
`main.gd/_build_hud`, which is most of the HUD. Shipping it as it stood
would have replaced letterboxing with something worse-looking on exactly
the devices it was meant to help:

- `grade_rect` was a fixed 1280x720 rect, so the strip that `expand`
  reveals on a wide window went completely ungraded - no vignette, no
  grain, visibly brighter, with a hard vertical seam down the picture.
  Screenshots at 844x390 before and after confirm both the fault and the
  fix. The grade's world-locked surface noise also derived world position
  from a hardcoded frame (`uv * vec2(1280, 720) + cam_off`, with `cam_off`
  half of the reference frame), which would have scaled the asphalt
  aggregate with the window and slid it against the ground; the shader now
  takes a `view_px` uniform and the camera offset uses half the real
  viewport.
- Sixteen `HORIZONTAL_ALIGNMENT_CENTER` labels held `size.x = 1280`, so
  every centred line - the title, the level carousel, owner and weather
  callouts, messages, the pause and tutorial text - sat 139px left of
  centre on a 1558px-wide viewport.
- The bottom rule (hint line, version, combo meter) and the wardrobe
  cluster measured in from the reference frame, so they drifted inward on
  a wide window and floated up the picture on a tall one.

These now go through two helpers, `_pin_wide` and `_pin_box`, which anchor
against the live viewport and re-solve on rotation with nothing listening
for a resize. Each element declares which rule it hangs off (top edge,
middle of the screen, bottom edge) so stacks keep the spacing they were
composed with. The wardrobe's preview dog is a Node2D and cannot anchor, so
it reads the panel's rect when the screen opens.

New CI test `tests/test_hud_anchoring.gd` reshapes a real viewport to
1280x720, 844x390 and 390x844 and asserts the five invariants: the grade
covers the viewport, full-width lines span it, bottom-rule elements hold
their distance from the true bottom edge, the combo meter stays centred,
and nothing hangs off any edge. 389 checks. It was confirmed to fail on the
first-pass commit before being kept - a test that cannot fail is not a
guard. Native 1280x720 is asserted unchanged, so the desktop layout is
pinned too.

## 2026-07-31 - v1.53 release

In-game version label bumped to v1.53. Tag `v1.53` publishes web and
Windows to itch after green CI on the tagged SHA.

## 2026-07-30 - v1.53 closeout: release gates and docs

Release publish is gated on a successful CI run for the exact tagged SHA:
`ci.yml` also runs on `v*` tags, and `release.yml` polls that result before
export or itch upload. Manual `workflow_dispatch` remains only as a gated
escape hatch (CI wait by default; `skip_ci_gate` is explicit and emergency).
Missing `BUTLER_API_KEY` fails the release instead of skipping itch with
success. Godot export steps keep failing exit codes (`set -euo pipefail`).

Docs: AGENTS.md drops the stale pivot-chain / "verlet visual only" wrap
paragraph so it matches the rope-is-the-constraint architecture; HANDOVER.md
is a thin current sitrep with the 2026-07-17 history archived under
`docs/handover/`; PROJECT.md notes v1.53 hardening and the shipped tangle
path. Known deferred: mobile Web canvas scaling (phone-sized browser still
shows a small fixed canvas with large black borders); Round 3 Web visual
acceptance was PASS_WITH_GAPS for FX framing. No production itch publish
was performed in this closeout.

## 2026-07-30 - v1.53 hardening: NPC-leash tangle contacts

Leash-vs-leash tangles use visible segment/capsule contact with separate
enter/exit thresholds instead of sampled point proximity. Dynamic rope
obstacles refresh before the player leash solve, and broad-phase uses rope
bounds rather than dog-to-owner distance alone. Only static contacts shield,
vault, or anchor; dynamic snags keep their own slip, a visible contact mark,
and a warmer taut presentation. NPC owners pause only up to a named bound,
curiosity is suppressed while snagged, and a mercy ramp frees every supported
single-pair encounter inside 300 frames at 60 Hz with the same cancel rules on
park/recall/detach/despawn paths. Rising-edge rewards stay one-per-encounter.
Focused regression: tests/test_tangle_hardening.gd.

## 2026-07-30 - v1.53 hardening: geometry and furniture recovery

FUR-GONETA body, draw, blocker, scent and rope flanks now share one fitted
centre - wrap contacts are appended after the corridor fit instead of being
remapped without the van. The Boulevard terrace chairs no longer nest inside
parasol wrap circles. Stick-slip uses named static/dynamic curves that can
reach free slip inside the 1.15x geometry cap, with typed obstacle metadata so
furniture and other leashes do not share pole-only contact_pole semantics.
Dog-beach visual, animated and gameplay shorelines share beach_shore_x; the
first beach throw gets the surf window; abandoned dig/sniff progress dirties
freedomlayer again. Focused production-layout regression covers the terrace,
FUR-GONETA alignment, capped-slip recovery, collision-enabled endpoint
recovery under move_and_slide, and shoreline agreement.

## 2026-07-28 - v1.53 hardening: progression boundaries

Fresh profiles now initialize complete records for every campaign walk, so a
goal earned before the first result persists, awards milestone stars, and
unlocks the next walk. Loading a missing or malformed save starts from one
canonical persisted-state baseline instead of retaining wallet, cosmetics, or
settings from an earlier profile.

The tutorial now remains practice from start to finish. It has no campaign
goals or quest callbacks, cannot bank its local bone feedback, and says so on
the result card. Cosmetic ownership is category-aware, so identically named
items such as the gold collar and gold coat can be bought and equipped
independently; old saves migrate ambiguous raw ownership without discarding
unknown entries.

Three persistence regressions cover fresh progression, tutorial isolation, and
cosmetic ownership and migration. The full focused suite, rendering checks,
all structural selftests, tutorial and Street smokes, and exported desktop Web
flow pass. Phone-sized Web acceptance exposed a separate fixed-size canvas bug
that currently makes the game render as a small box with large black borders;
touch acceptance remains blocked until that Web scaling issue is fixed.

## 2026-07-28 - v1.52: the FUR-GONETA

A mobile dog-grooming van with fur on it. Shaggy two-tone brown and cream,
floppy ears on the front corners, a fringe with small dark eyes peering out
from under it, a black nose where the grille goes, a tail wagging on the back
doors, and FUR-GONETA painted on the roof in two lines with a paw print for
the hyphen - the roof being the only surface you can read from directly
overhead. Parked on El Mercat, doing a trade in nervous poodles, and on the
boulevard.

An homage, not a copy: our own name and livery, because the van it tips its
hat to belongs to somebody else. FURGONETA is Spanish for van and it begins
with FUR, which is the entire joke.

The first attempt was a dog costume - tongue out, pink collar, a light box the
size of the vehicle. The van it is nodding to is subtler than that: it reads
as a work van that happens to be furry, so no tongue, no collar, a grey
bumper, and the name painted on rather than mounted above.

To a dog it is the most interesting object in the city, so sniffing it is the
biggest one-off payout on a walk - twelve bones and a FUR-GONETA combo tag,
once, captioned "four hundred dogs have been in there". It smells from across
the street so the nose leads you to it, it is solid, and the rope wraps its
flanks like any other van.

## 2026-07-28 - v1.51: the freedom spaces, and a frame that is 6x cheaper

The off-leash space at the top of every walk used to be one municipal field,
which is a large part of why twelve levels still felt like one walk redressed.
Each walk ends somewhere of its own now, and the places are designed rather
than dressed:

- **The dog beach** at the end of the passeig: dry sand, wet sand, dunes with
  marram grass in place of chain-link, palms along the BACK of the beach where
  palms actually grow, parasols, a shower, and open sea. The sea is real
  water - she swims, the ball is thrown into the surf, the owner wades in
  holding the phone above his head - and the bay opens diagonally out of the
  seafront's own coastline, so walking through the gate reads as rounding a
  headland instead of the sea abruptly getting wider.
- **The clearing** in the woods, with no fence, because nothing out there is
  fenced. Its ring of trees is REAL trees: placed at build time so they have
  collision and the rope wraps them. Decoration you can walk through is worse
  than no decoration.
- **A gravel compound** for the works and the scrapyard.
- The seafront's water comes properly inshore now. At this camera zoom a band
  at x<90 was a five-pixel sliver at the edge of the frame and usually off it,
  so the sea was invisible for the whole walk it is named after.

**Everything in the off-leash space has to be somewhere sensible**, and now it
is: nothing is placed in water, the beach digs in dry sand, the dunes are
solid, and --selftest fails a level that puts a prop, a tree, a towel or a
snack in the sea. That check immediately found a roadworks cone standing in
the middle of the pond on El Bosc, which reuses the park's geometry - so
there is a build step that pushes anything wet to the nearest shore.

### Performance: 9ms to 0.5ms

Measured with a new --drawcost flag rather than guessed at, which is the only
way this has ever gone well. The freedom view cost 3.3ms on the park and
**9.0ms in the woods**, against 0.7ms for the corridor - and the clearing's
ring of trees alone was 5.7ms of it, redrawn thirty times a second to produce
an identical picture, because trees do not move.

The off-leash space is a fixed scene, so it now lives on its own canvas
(freedomlayer.gd) exactly like the building frontage did in v1.49, redrawn
only when the camera reveals new ground or the furniture changes. The grove
was drawn every frame in the world with its own near-duplicate tree renderer;
it uses the one renderer and sits on the layer. The corridor's cross-section
stops at the gate instead of being painted the length of the level. The
beach's detail loops start at the visible window instead of walking all 5800
pixels to draw the forty lines on screen.

Result: park 3331 -> 546us, woods 9050 -> 514us, beach 4864 -> 1433us,
boulevard 4002 -> 1216us. Which is the headroom the visual work needed.

### Voice and text

The death cards are in her voice throughout now - "NOBODY WAITED FOR YOU",
"THEY GOT YOUR HUMAN", "THE HUMAN FELL IN THE CELLAR" - and the results card
is titled GOOD DOG. (or VERY GOOD DOG. for a clean sweep). Two world-space
strings that were nudged left by an eyeballed 40px are centred properly.

## 2026-07-28 - v1.50: something you can download

The first release that is not just a web page. There is now a Windows
Desktop export preset, CI exports it alongside the web build and pushes it
to its own itch channel, so the game appears in the itch app as a real
download rather than a browser toy. It is built in CI rather than locally
because the full export template pack is ~1GB and CI downloads it anyway
for the web build, with a size check so a stub can never ship as a game.

A download that cannot set its own volume is not finished, so:

- **A settings screen**, reachable with the pause key from either the title
  screen or a paused walk: master, effects and music volume, and a
  fullscreen toggle. Saved to records.cfg with everything else. Before this
  you could mute the music with M and that was the entire audio interface.
- `Sfx.play()` scales by the effects setting on top of whatever volume the
  caller asked for, so a quiet sound stays relatively quiet, and the music
  bed scales from its own ambient level rather than jumping to the front.
- It is drawn (settings_panel.gd) rather than assembled out of Labels. The
  rows need a name, a slider and a value lining up in columns, and the
  game's font is proportional - the first attempt, with padded text, looked
  like a ragged shopping list.
- The browser gets no fullscreen row. The browser owns the window, so the
  toggle would be a button that lies.
- `--selftest` now checks that the rows agree with the keys used to index
  them, and that the values survive a save/load round trip: a typo in a
  ConfigFile key fails silently, reverting to the default on next launch,
  which is the kind of bug you find six weeks later.

### An icon, and a name without "(prototype)" in it

The download would otherwise arrive wearing the Godot logo, titled "Path of
Leash Resistance (prototype)" - a fine way to tell someone not to bother.

`tools/make_icon.gd` draws the icon from the game's own palette and writes
icon.png; icon.ico is that PNG at seven sizes for the Windows exporter. The
web export takes config/icon for the favicon for free, so the browser tab
stops being a Godot tab. The pose is head-on rather than the game's
top-down view: a black dog seen from above is a dark smudge at 32px,
whereas a face with two eyes reads as a dog immediately.

Renaming the project moves the desktop save directory, which costs nothing
today - every save that exists is in a browser, where user:// is IndexedDB
keyed by origin and does not care what the project is called.

## 2026-07-26 — v1.49: what she stood in comes home with you (+ a big perf win)

Any dog owner knows a walk does not end at the door: whatever she stood in
comes home, on the floor, on the furniture, and on you. One tracking system,
EIGHT substances, so each walk offers whatever it would plausibly have lying
about:

- **mud** (woods, and any level's puddly patches), **wet cement** (the
  works), **wet paint** (also the works), **beach sand**, **fish** (the
  market's fishmonger patch - everyone will know), **oil** (the scrapyard),
  **festival confetti** (La Castanyada), and **slush**, which appears on ANY
  walk when the weather is snow.
- She leaves paw prints in the colour of whatever she is tracking, which
  means prints on sand come free - stand in it and it comes with you.
- The joke is the payoff: lean on your human while mucky and you leave a
  print on their nice trousers, with its own indignant caption per
  substance. It stacks over the whole walk, they never notice, and it feeds
  the combo.

### Performance: the frame audit that mattered

All the recent visual work had quietly tripled the world draw, from ~750us
at v1.31 to 1844us - and smooth beats pretty, so I measured instead of
guessing. The result was blunt: the edge treatment alone was **1007us of
1844us**, over half the frame, redrawn thirty times a second to produce an
identical picture, because buildings do not move.

- Buildings, roofs and verge foliage now live on their own canvas that only
  redraws when the camera has actually scrolled far enough to reveal new
  frontage - the same insight that fixed the world draw in v1.17.
- The park is back to its old baseline (1844us -> ~800us, a 57% cut).
- Also: the off-leash props were being drawn in full with no view culling at
  all, and the scent source list was being rebuilt - allocating a dictionary
  per source, plus a group query - on every single redraw. Both fixed.
- Known follow-up, measured rather than assumed: the remaining ~1.2ms on El
  Gotic is the many static prop loops, which want the same cached-canvas
  treatment as the edges. Paving is only 120us of it, so that is where to
  look next rather than at the slabs.

## 2026-07-26 — v1.48: Brutus, the park thief

A recurring character, because one of those does more for a game's
personality than three more levels. Brutus is the dog at the park having a
lovely time at your expense.

- He is not a hazard and he cannot hurt you - he is a THIEF. He waits for
  you to EARN something (a ball you went and fetched, a bone you dug up),
  helps himself, and legs it looking extremely pleased. Which is the point:
  the fetch and dig systems now have something pushing back.
- Get it back by barking him out of it (always works, no dice rolls) or by
  catching him. Recovering is worth MORE than the thing was, because taking
  it off him is the better story - and it feeds the combo.
- He is faster than you in a straight line but turns like a bus, so the
  counterplay is cutting corners rather than out-running him. Rules he obeys
  so he stays funny rather than infuriating: never steals out of your mouth,
  only off the ground; a close bark always beats him; and he never appears
  on the tutorial walk, which is no place to meet him.
- **He pays nothing if you ignore him.** The first cut rewarded you when he
  simply got bored and wandered off, which meant doing nothing earned bones
  and the same bone could be farmed in a loop. Now only a genuine recovery
  pays, and if he escapes with your bone it is gone for good - so a thief
  who is ignored actually costs you something.

## 2026-07-26 — v1.47: The First Walk - a tutorial

We had accumulated a lot of verbs - some obvious (walk, pee), some that
nobody would ever guess (the grind, the vault, the nose, the teeter) - and
nothing taught any of them. This is the fix, and it is the calm walk it
ought to be rather than a wall of text.

- A new walk at the front of the carousel, always unlocked, deliberately
  SAFE BY CONSTRUCTION: no traffic, no chase, no other walkers, no manholes
  or cellars, bright clear day. Nothing here can end your walk, so you can
  fail a lesson as often as you like.
- Eleven lessons, one at a time, ordered from "you already know this" to
  "nobody would guess this": walk, feel the rope go tight, mark a hydrant,
  have a proper sniff, USE YOUR NOSE (slow down and the world opens up),
  dig something up, bark, the zoomies, ride the kerb, and vault a lamppost.
  Each waits as long as you like and pays a couple of bones when it lands.
- Every lesson is SKIPPABLE (C / Y). A tutorial that traps a player who
  cannot do the thing is worse than no tutorial at all.
- The lesson checks are written against what the game already tracks, so it
  teaches the real mechanics rather than a scripted imitation - if the
  grind changes, the grind lesson changes with it.
- It sits outside the campaign level list entirely, so it has no star gate,
  earns no stars, and cannot pollute your records. The goal card is hidden
  on it too: a first walk has lessons, not goals.
- Two ordering bugs found and fixed while building it: the calm-level setup
  emptied lane_ys AFTER its parallel lane_state had been built (an
  out-of-bounds every frame), and set the hydrant list AFTER it had already
  been consumed. Both now run before the shared setup, and CI smoke-tests
  the tutorial build.

## 2026-07-26 — v1.46: the scent trail - the world through a nose

A dog's strongest sense finally IS one, rather than a marker on a map.
Scent drifts off a source toward Millie, thickening as she nears it, and
she can smell things far outside what she can see - which is what makes
wandering off the direct line pay.

- **Her nose reaches further the slower she goes.** Barrel along and you
  smell almost nothing; drop to an amble and the whole street opens up.
  Being a dog rewards taking your time, which is rather the point of a
  walk - and because it needs no extra button it works identically on
  keyboard, pad and touch.
- Colour carries the meaning, so a nose-led player learns to read the air:
  warm amber for food, pale bone for something buried, pink for Tofu, blue
  for a job to do, and a sickly green for the chocolate she must NOT eat -
  smelling wonderful while being bad for you is the whole joke of that
  level.
- The motes drift FROM the source TO her nose, so it reads as something
  arriving on the air rather than a line pointing at a waypoint, with a
  soft bloom at the source once she is nearly on top of it.

### The stall watchdog, corrected

Adding all this made the autowalk report stalls, and diagnosing them (with
real numbers rather than guesses) found the watchdog was wrong, not the
game. Both causes were legitimate: the owner rooted mid-phone-call, where
the dog simply cannot out-travel the rope; and the owner mid-tetherball
WHIRL while the dog vaults - both orbiting a pole, which is the funniest
thing in the game and emphatically not a bug. Those beats are now exempt
and the window is wider, so the watchdog still catches genuine wedging
(it has already caught two real bugs) without failing CI for features
working exactly as designed.

## 2026-07-26 — v1.45: the leash-vault

The rope is the best thing in the game, so it should be a way to MOVE and
not only a way to be held back. Catch the leash on a pole and keep running
and the pole becomes a pivot: Millie carves a fast arc around it and
slingshots out along the exit tangent.

- It STEERS her velocity rather than teleporting her, so the verlet rope
  stays the source of truth and holds the radius honestly - the swing is
  the rope doing its job, not an animation played over the top.
- Needs real pace and a rope under tension, so a gentle wrap is not a
  vault. The payoff scales with how much arc she actually carved: a
  committed swing throws her much further than a clipped one, and pays
  combo points to match.
- The swing geometry is pulled out into its own module (swing.gd) and
  pinned by tests: always perpendicular to the rope, always following her
  existing travel, mirrored correctly from either side, and NaN-safe when
  she is standing exactly on the pole. A flipped sign there would have
  flung her backwards INTO the pole.
- One vault per approach: she has to leave a pole before it gives her
  another swing. The autowalk stall watchdog caught the bot sitting in a
  single lamppost's orbit re-triggering forever - which would also have
  been a score exploit, farming unlimited combo points off one pole. Good
  argument for that watchdog existing.

## 2026-07-26 — v1.44: the phone call

The premise of the whole game, turned into a gift. Once a walk the owner
takes a call and roots themselves for the better part of twenty seconds -
and for once their obliviousness is YOUR window rather than your problem.

- The leash goes right out for the duration (nobody reels a dog in
  mid-natter), so the dog gets the widest radius in the game and the run of
  the place: mark, sniff, dig, grind, chase, whatever you fancy.
- The HUD counts the window down, so you know exactly how much freedom is
  left and can plan a route rather than flail.
- It PAYS by what you actually did with it: every trick landed during the
  call counts toward a haul that cashes out when they hang up ("GOOD CALL!
  4 things, +11"). Waste it and it tells you so. That turns a free window
  into a little optimisation puzzle rather than a pause.
- Rare and once per walk, so it stays a treat, and it never interrupts the
  poo-bag chore chain.

## 2026-07-26 — v1.43: the kerb grind

The teeter turned a hazard into a skill you could survive. This turns the
same idea into a skill you go LOOKING for - the first of the agreed
fun-mechanic backlog, and the most Tony Hawk thing in the game.

- Run along a kerb at a clip and Millie gets up on it. The rail lights up
  under her and a centred balance needle shows which way she is tipping;
  counter-steer to hold it. It pays by the second and the rate GROWS the
  longer you ride, so a long grind is worth far more than several short
  ones. Stepping off cleanly banks it as a combo trick plus bones; bailing
  costs the trick and your combo and nothing else, because this is a thing
  you seek out rather than a hazard to survive.
- Both corridor edges are rails on every walk, so it is available
  everywhere rather than being a level gimmick.
- Balancing on a kerb is an INVERTED PENDULUM, and the first attempt got
  that wrong: it only wobbled around centre, so an unattended grind never
  fell off and there was no skill in it. Now any lean feeds on itself.
- The disturbance ramps as well as the instability, and that is deliberate:
  with divergence alone a perfect rider could pin the lean at zero and
  grind forever for unbounded points. A growing wobble eventually
  out-muscles the nudge however well you ride, so every grind ends and the
  skill is in how long you stretch it.
- The test pins the feel so it survives future retuning: ignoring the
  wobble bails briskly, a competent rider holds it a good while, the ramp
  ends even a perfect grind, later seconds pay more than earlier ones, and
  landing banks exactly once.

## 2026-07-26 — v1.42: four bugs from real browser play

All four found by actually playing the web build, and all four were real.

- **Mangled characters in the goal card.** The ticks and circles rendered
  fine in the desktop build but as empty tofu boxes in the browser: the
  desktop has system font fallbacks covering geometric shapes, and the web
  export ships none. The HUD is now pure ASCII ([x] / [ ], and a #---- bar
  for progress), and the whole codebase is swept clean of non-ASCII in
  drawn text.
- **Dying after escaping the teeter.** On a "fell" result the manhole death
  fired unconditionally, so if the balance meter filled while Millie had
  already WALKED CLEAR of the hole, she died standing visibly past it. Now
  physical escape beats the meter: out of range means out. Momentum counts
  toward the save too, not just held input - if travel is carrying her
  clear, that IS escaping.
- **Snow stuck on the screen after choosing a clear day.** The weather
  overlay only queued a redraw while weather was active, so switching TO
  clear left the last painted frame of snow on the canvas forever. `mode`
  is now a setter that forces one final redraw to clear it.
- **You could walk on the rooftops.** Two causes, both fixed. The roof was
  drawn flush against the pavement so it read as ground you could stroll
  onto - the roof is now inset from its footprint and the gap is a visible
  WALL FACE, graded dark at the base to light at the cap, with a hard kerb
  line and the existing cast shadow: a clear storey of height. And the
  buildings are now SOLID, on the sides that really are buildings and only
  along the walking legs. The boulevard and El Aguacero keep their right
  side open, because that is the bike lane and the shoulder where the
  frisbee prize deliberately sits, and the green walks and beach have no
  buildings at all.
- PROJECT.md now records the agreed fun-mechanic backlog (kerb grind,
  leash-vault, scent trail, rival dog, the phone call, mud stacking, two
  dogs, mid-walk weather) with the design rule that every mechanic must
  work on keyboard, pad and touch.

## 2026-07-26 — v1.41: the teeter - the moment before you fall in

Walking into a hole used to be instant and unreadable: you were simply
punished. A brink now starts a BALANCE moment, borrowed from the
manual/grind in the Tony Hawk games - you are tipping, and a scramble the
other way saves you. A hazard becomes something you lean into on purpose
instead of something you resent.

- A tipping bar appears over Millie with an arrow showing which way to
  fight; scrambling away pushes back, and turbo counts as a panic scrabble.
  It redraws every frame (the rest of the world runs at 30) because a reflex
  moment has to be responsive.
- Deliberately forgiving, since a fiddly version would be a pain rather
  than a thrill: the pull starts gently and only bites as you tip further,
  the correction outmuscles the pull, and simply staying upright for 1.25s
  recovers you. A save scores bones, feeds the combo and adds to your save
  streak. Momentum counts too - clip the edge at a clip and you sail past.
- **The consequence depends on what you fell into**, which is the point:
  a manhole or cellar is still a hole and still ends the walk, but WATER
  never does. Millie loves water, so the wobble at the edge never gates her
  getting in - falling in just means swimming, and costs nothing but your
  run of tricks (the combo bails). It only triggers when she arrives at a
  proper clip, so it reads as a stumble rather than a toll gate.
- Built as a reusable module with the balance maths testable headless, so
  any future brink (a quay, a cellar hatch, a kerb) can use it.
- Tuning note: the first attempt double-integrated with damping, which
  quietly capped the pull so far below the threshold that standing still
  SAVED you. Rebuilt as a direct rate that can be tuned by arithmetic, and
  the test now pins the difficulty band: no input loses, a token scramble
  loses, a real one wins, and a late committed one can still rescue a deep
  lean.

## 2026-07-26 — v1.40: the off-leash area is somewhere now

The one place in the game where the dog is actually free was a bare green
field, which was a waste of it. It is now furnished, and deliberately
furnished AWAY from the straight line between gate and meadow, so nosing
about off the direct route is what finds things.

- **Dig patches** - hold still over turned earth and keep digging (a
  progress ring shows you are getting somewhere) to unearth a buried bone.
  Three are guaranteed and spread across the width; the rest are scattered.
- **Solid furniture with real mass**: fallen logs, driftwood, stacked tyres,
  all with collision, so you go round them rather than through them.
- **Sniffables that read as sniffable**: shrubs, sniff posts, rocks and
  driftwood all reward a nose, and while Millie works on one a soft scent
  bloom rises off it - so the affordance is visible rather than guessed at.
- **A water trough** by the owner's bench, because a romp is thirsty work
  (it counts for the "have a good long drink" goal).
- Flavoured per walk: driftwood and rockpools at the beach, tyres and logs
  in the yard and the works, shrubs and posts in the park and woods.
- The sanity sweep now also fails a walk whose off-leash area is bare, has
  fewer than two dig patches, or has nothing solid to navigate around - and
  it immediately caught the works and the scrapyard rolling only one dig
  patch, which is why the essentials are now placed rather than diced for.

## 2026-07-18 — v1.38: Millie's coat is data now (+ one-command releases)

- **The first working piece of the dog creator.** Millie's colours were
  hardcoded into her renderer; they are now DATA (`Game.COATS`) - base fur,
  shaded underside, muzzle/chest markings and how much grizzle shows. So
  adding a breed later means adding a row of parameters, not editing the
  drawing code. Six coats to start (Millie black, chocolate, golden, grey
  weimaraner, cream, blue merle), bought with bones like any cosmetic, and
  the wardrobe previews the highlighted coat on the preview dog before you
  buy it. Millie's own look is the default and always owned.
- The wardrobe grew a third category, and its buy/equip path collapsed from
  duplicated if/else branches into one lookup - so a fourth category (ears,
  tails, sizes) is now a couple of lines rather than a refactor.
- **Releases publish themselves.** New workflow: push a version tag and CI
  exports the web build and pushes it to itch with `butler`, which uploads
  only the changed blocks (a few hundred KB instead of a 10MB re-upload)
  and keeps every version rollback-able on itch's side. The zip is still
  produced and attached to the GitHub release as a manual fallback.
  One-time setup: add an itch API key as the BUTLER_API_KEY repo secret.

## 2026-07-18 — v1.37: things with mass, and litter that belongs somewhere

A fair hit landed: v1.36 added trees you could walk straight through. If
something is in the world it should have heft, not be a picture on the floor.

- **The grove is solid.** The trees in the off-leash area now have real
  collision AND are leash-wrap geometry, so you can bump into a trunk and
  wind the rope around one like any lamppost. (Appended to the pole list
  after the corridor fit on purpose - the grove stands in the open
  full-width area, so clamping it to the walkway would have dragged it out
  of place.)
- **Six kinds of kickable junk**, not just cones - and the point is that
  they FEEL different: a drink can rattles away twice as far as a cone, a
  plastic bottle skitters, a lost ball fairly flies, and a rubbish sack or
  a wooden crate barely budges and kills your momentum. Each is drawn so
  you can read its weight at a glance, each has a contact shadow scaled to
  its heft, and each makes its own noise when punted.
- **Litter is placed by AREA, not sprinkled evenly.** Rubbish accumulates
  around whatever produced it: crates pile up behind market stalls, cans
  and bottles collect around cafe tables and buskers, sacks slump by the
  bins, crates and cones litter the works. Plus a level-specific background
  palette for the quiet stretches. Each stretch of a walk now looks like
  somewhere in particular rather than like a random sprinkle.
- The sanity sweep now also fails a level that is short of kickable junk or
  sniffable spots, so "this walk feels bare" is a CI failure now.

## 2026-07-18 — v1.36: roofs, not facades - and real paving

Visual inspection of v1.33 showed the edge buildings were wrong in concept,
not just in detail: I had drawn shop windows and doors, which from directly
overhead just read as pale mats lying flat on the pavement. From above you
do not see a facade at all - you see the ROOF.

- **The verge is now roofscape.** Terracotta pantiles in courses with
  chimney stacks for El Gotic / La Castanyada; flat felt-and-gravel roofs
  with air-conditioning units (each casting its own little shadow), vents
  and rooflights for the city blocks; a glazed platform canopy with steel
  trusses for L'Estacio; scaffold decking and lashed tarps for Les Obres;
  ribbed corrugated iron with rust blooms for El Desguas.
- **Buildings read as tall** through three cues instead of drawn walls: a
  lit parapet cap along the roof edge, a hard shadow thrown out across the
  pavement (light is up-and-left, matching every other shadow in the game),
  and ambient darkening where wall meets ground.
- **Only things that genuinely exist in the ground plane are drawn there:**
  awnings that project out over the pavement (with their own shadow) and
  doorsteps at the wall base.
- **Fixed a real bug found by looking:** every roof feature used
  `inner_x - side * dist`, which moves INWARD on both sides - so skylights
  and AC units were being painted onto the pavement. Hence the "laid flat
  on the pavement" look. Sign corrected.
- **Real paving.** A single flat fill with a seam line every 150px was the
  main reason the ground read as a colour swatch. There are now actual
  slabs with joints, a brick bond, a light chamfer catching the light, and
  a stable per-slab tone wobble - and the slab size changes per level, so
  the alley's small cobbled setts do not look like the concourse's big
  square tiles. Broken ground (works, scrapyard) and dirt (park, trail)
  correctly have no paving pattern at all.
- **Trees are trees.** Two flat green discs read as a blob; a canopy now has
  a cast shadow, overlapping lobes to break the outline, a lit crown up and
  to the left, and trunk and limbs glimpsed through the gaps.

## 2026-07-18 — v1.35: the goal card, rebuilt

The goals list had two real defects and not much pizzazz. Both fixed:

- **It overflowed its own card.** Long goal names ("steal the sardine
  under the cat's ledge") ran straight out past the shaded background,
  because the card was a fixed 348px and nothing measured the text. The
  card is now 416px wide and its height comes from the rendered content,
  so it always wraps its contents exactly instead of guessing a line
  height.
- **The row count wobbled between runs** because goals earned on a
  PREVIOUS walk were hidden entirely. Now nothing disappears: finished
  goals stay in place with a tick and dim out, open goals sort to the top
  so the live ones are always on screen, and anything past seven rows
  collapses into "+ N more". The list is stable and the count finally
  matches the header.
- **Pizzazz.** Rebuilt as rich text so rows can style themselves: amber
  circles for open goals, green ticks for done, and multi-step goals get a
  little inline meter (filled/hollow pips) next to their x/y - so you can
  see momentum at a glance. Goals banked *this run* read brighter than
  ones banked on a past walk, and the header turns green with ALL CLEAR
  when a walk is fully cleaned out. Card is more opaque so dimmed rows
  stay legible over pale pavement.

## 2026-07-18 — v1.34: content tests that catch real bugs

Two new CI checks aimed at the class of mistake the old suite could not
see - and they found live bugs immediately.

- **Structural sanity sweep (`--selftest`, every walk).** Validates each
  level inside the real runtime: the corridor is sane, every placed prop
  sits on its own pavement, the goal list is well formed (length, no
  unknown ids, no duplicates), and - the important one - the level can
  actually SATISFY the goals it sets.
  It immediately caught that **El Mercat, El Gotic and La Castanyada each
  asked for "4 good sniffs" while containing only 3 hydrants**, so that
  goal was impossible and those walks could never be 100%%ed. Fixed by
  adding two more hydrants to that layout. It also flagged the beach's
  off-centre walkway, which is by design and is now documented as an
  explicit exemption rather than an accident.
  (Autoloads do not exist under a bare `--script` run, which is why this
  lives behind a runtime flag instead of in tests/.)
- **Autowalk stall watchdog.** "The walk finished" was a weak assertion -
  the bot could crawl, wedge on a prop and still squeak home inside the
  frame budget. Travelling legs must now make real corridor progress or
  the run prints AUTOWALK STALL, which CI treats as a failure. The freedom
  romp is exempt, since milling about after a ball is the point there.
  Wired into all four full-walk traversals.

## 2026-07-18 — v1.33: per-level edge treatment

What flanks the corridor is what actually gives a walk its identity, so
every level now has its own verge instead of the same green grass:

- **Boulevard / El Aguacero / El Mercat** - city shopfronts: masonry,
  plate glass (lit from inside after dark), doorways, striped awnings.
- **El Gotic / La Castanyada** - old stone, close and high, with shuttered
  windows, stone sills, and warm lamplight spilling from the lit ones.
- **El Bosc / The Park** - no wall at all: undergrowth and trunks crowd
  in on the path, so the green walks stay green.
- **L'Estacio** - tiled interior wall, pillars, signage strips.
- **Les Obres** - plywood hoarding with hazard stripes.
- **El Desguas** - chain-link fence with heaps of junk piled behind it.
- Built-up walks fill the whole verge with masonry, so no stray grass
  shows past the buildings. Combined with v1.32's width dial, the alley
  now genuinely reads as a narrow alley between buildings.
- Purely a draw layer (no new collision), culled to the view, with
  per-module variation derived from position rather than the global rng.

## 2026-07-18 — v1.32: every walk gets its own proportions

The levels all felt like the same street redressed, and the root cause was
structural: the walkable corridor was two fixed constants, so every walk was
identically 680px wide no matter how it was dressed.

- The corridor is now derived from ONE width dial per level, moving the
  pavement and the gameplay bounds together. El Gotic is a genuinely tight
  alley (450 wide), L'Estacio a genuinely open concourse (780), with the
  rest spread between - and narrow corridors are mechanically harder,
  since there is less room to thread a distracted owner past a lamppost.
- Props were all authored for the old fixed width, so a new corridor-fit
  pass remaps every placed prop (poles, stalls, bins, benches, vans,
  cones, manholes, hydrants, snacks, wall cats, guard posts, candy) into
  whatever corridor its level declares, keeping each on its own side of
  the path. The beach is exempt - its sand/boardwalk/bike-path
  cross-section deliberately puts things outside the walkway.
- Verified: all 11 levels still complete an unattended autowalk, including
  the tightest, and all 22 regression tests pass.

Still to come per level: bespoke EDGE treatment (walls for the alley,
shopfronts for the boulevard), which is what will finish the personality
job that proportions start.

## 2026-07-18 — v1.31: the look pass #1 — grade, shadows, light, texture

First pass at the presentation, aimed squarely at "it looks like a 2010
browser game". Diagnosis: the problem was never the top-down projection,
it was that everything was flat untextured fills, floating (no shadows),
uniformly lit, and framed too far out. All four are addressed:

- **Colour grade (new post-process shader).** Split-toning (cool shadows,
  warm light), gentle contrast and saturation, a soft vignette and a
  black-lift so night stays readable. Sits over the world, under the HUD,
  so the interface stays crisp.
- **Surface texture, in the shader.** World-locked grain and soft
  blotches, keyed to the camera offset so it sits on the ground like
  aggregate in asphalt instead of sliding like a film overlay. This is
  what kills the "flat colour swatch" read - and being GPU work it costs
  the CPU-bound web build nothing.
- **Contact shadows** under the dog, the owner, free dogs and NPC pairs,
  all with one consistent light direction (up and to the left). Nothing
  sells "solid thing standing on ground" faster.
- **Night lighting.** Warm pools spilling from the lampposts (smooth
  11-ring falloff, faint flicker) and - the joke of the game, finally lit
  - the owner's phone throwing a cold blue-white pool on the pavement.
- **Ground detail layer.** Hairline cracks, grit, litter and damp stains
  scattered down every walk, so paved corridors stop reading as empty.
  Built with a LOCAL rng so the deterministic autowalk seed is untouched.
- **Framing.** The walkway is only ~680px of a 1280px frame, so half the
  screen was empty verge and the characters read as specks. Camera now
  pushes in (CAM_ZOOM 1.28): the frame fills, and the animation and the
  rope become legible. Trade-off is less warning time on hazards, so it's
  a feel dial.
- **The leash reads as webbing**, not a debug gizmo: a dropped shadow, a
  dark body, a lit top edge, and a visible handle loop in the owner's
  fist. It cinches thinner and hotter when taut.
- Dev tooling: a `--shot` flag that skips the title and writes a PNG, so
  the look can actually be reviewed instead of guessed at.

## 2026-07-18 — v1.30: El Desguas (the scrapyard) — a stealth walk

- An eleventh walk (gate 19), and a whole new verb: STEALTH. Sneak the
  shortcut through a junkyard past three kinds of trouble:
  - **Sleeping guard dogs** — chained and dozing. They wake to NOISE: a
    fast mover nearby, a bark, or the killer — the owner's phone ringing
    within earshot. Slow is silent; creep and they snore right through it.
  - **Sweeping security cameras** — a panning vision cone; step into it
    and you're spotted.
  - **Laser tripwires** — beams that slide up and down their stretch;
    time your crossing.
- The unique bit only this game can do: your stealth partner is a
  glowing, ringing phone-zombie roped to you. When their phone goes off
  next to a guard, THEY blow it. Escort-stealth where the escort is
  hopeless. Getting caught is never lethal (soft-fail pillar) — a bark,
  −2 bones, a startled owner — but the "ghost the yard" and "dodge every
  camera and laser" goals want a clean run. The prize is a bone right
  under a sleeping guard's nose.
- New guard-dog module + regression test; CI runs both. Reuses the
  boulevard layout for now.

## 2026-07-18 — v1.29: La Castanyada (festival night) + forbidden candy

- A tenth walk (gate 17): Barcelona's autumn festival, after dark. The
  cruel twist - chocolate is poison to dogs, so the thing you crave most
  is the thing you must NOT eat. Sweets are strewn right across your path;
  the dog scoops up anything it walks over, so you have to actively STEER
  PAST the candy while your real snacks stay fair game. Eat a sweet and
  you get a queasy "BLEH!", -3 bones, and a blown clean-tummy goal.
  Temptation-vs-duty in its purest form.
- Forced night, festival stalls, trick-or-treaters on the walkway, and a
  dog-safe pumpkin-treat prize ringed by candy. New "resist the chocolate"
  goal. Reuses the market layout for now.

## 2026-07-18 — v1.28: Les Obres (roadworks) + wet cement

- A ninth walk (gate 15): a construction detour. Wet cement is laid
  across the walkway - slog through it and it slows you AND your paws come
  out wet, leaving a trail of prints that follows you down the sidewalk
  for a few seconds (the evidence). Cones, barriers and a parked works
  van clutter the route; the hard-to-reach prize is a trowel dropped in
  the middle of the wet cement.
- Reuses the boulevard layout as a base for now; bespoke geometry later.

## 2026-07-18 — v1.27: music (procedural ambient loop)

- A gentle looping soundtrack, synthesised at startup like the SFX (no
  files): a soft sine bass and quiet fifth pad under a sparse C-pentatonic
  melody, over a calm I-vi-IV-V progression that breathes bar by bar.
  Kept deliberately low and unobtrusive so it sits under the effects and
  never grates on the loop.
- Plays through the menu and the walk, survives scene reloads (it's on the
  `Sfx` autoload). Toggle it with M (or LB on a pad); the pause menu
  advertises it.

## 2026-07-18 — v1.26: sound (procedural SFX)

- The game has a voice at last. Every sound is SYNTHESISED at startup from
  tones, sweeps and noise - no audio assets, no files. A woof for barks, a
  ding for marks/sniffs/snacks, a fetch chirp, a whoosh for flings, a
  crack for the phone, a splash for the pond, an ascending arpeggio for
  combos, a chime for stars/prizes/deliveries/Tofu, a save ding, a hiss
  for the wall cats, a boing for tangles, and a UI blip.
- Autoloaded as `Sfx` (built once, survives scene reloads) with a 10-voice
  pool so sounds overlap; light random pitch variation keeps repeats from
  grating. Synthesis uses a LOCAL RNG so it never touches the global seed
  the deterministic autowalk depends on.
- Web note: browsers gate audio until the first input; pressing a key to
  start the walk unlocks it.

## 2026-07-18 — v1.25: records / progress screen

- A proper career overview: from the walk-select screen, press Q (or X on
  a pad) to see YOUR WALKS - every walk's stars, goals x/N, and best run
  (bones + time), or "locked (N stars)" for the ones still ahead, plus
  your total stars and lifetime bones. Back with E/B. Very Tony Hawk, and
  it makes the whole 8-walk progression legible at a glance.

## 2026-07-18 — v1.24: combo quest + more cosmetics

- The combo meter finally feeds progression: every walk now has a "land a
  x5 trick combo" goal, so stringing tricks together counts toward your
  stars, not just bones. It's a master-tier goal (the x5 target is one
  constant to tune). The HUD shows your best-so-far as x/5 progress.
- Two new collars (Teal, Violet) and two new bandanas (Crimson, Plum) in
  the wardrobe - more to spend those bones on.

## 2026-07-18 — v1.23: pause menu

- A real pause, at last: ESC (or the Back button) mid-walk freezes the
  game behind a dim overlay - resume, restart, or quit to the walk-select
  menu without losing your session to a hard restart. Only arms while
  actually walking (not on the title, a death, or the results). The
  controls hint now advertises it.

## 2026-07-18 — v1.22: L'Estacio (station concourse) + moving walkway

- An eighth walk (gate 13) built around a NEW mechanic: a moving walkway.
  Stand on the metal band and it carries you toward the platforms (north)
  - a free boost on the way out, a shove you have to fight on the way
  home. Chevrons scroll in the carry direction. Luggage carts clutter the
  concourse floor.
- The hard-to-reach prize is a dropped sandwich sitting mid-walkway, so
  grabbing it means getting carried while you try.
- First cross-cutting "the ground moves you" mechanic; reuses the
  boulevard layout as a base for now.

## 2026-07-18 — v1.21: web-perf pass #3 — leash solver trim

- On open stretches (no poles or other ropes in the rope's bounding box)
  the collision scan is now skipped entirely - it was running N-1 empty
  inner loops per solver iteration, every frame, for nothing.
- Solver iterations trimmed 14 -> 11 (~20% fewer passes). The wrap and
  tangle regression tests both still pass, so the behaviour holds; the
  rope is marginally softer. ITER is one constant in leash.gd - bump it
  back toward 14 if the wind/tetherball feel wants more stiffness.
- Targets the "tangling gets choppy" case on the web build specifically.
  Guardrails: test_wrap + test_tangle_latch.

## 2026-07-18 — v1.20: El Bosc (the forest trail)

- A seventh walk (gate 11): a woodland trail with a stop-start rhythm all
  its own. Out here there are NO BARS, so the owner is forever freezing
  mid-step to hold the phone aloft hunting for a signal (the "no signal"
  event, cranked way up on this level) - you spend the walk stuck on a
  rooted owner, tugging to get them moving again.
- Muddy patches slow the going, a stream to drink from, squirrels to
  chase. The hard-to-reach prize is a pinecone off in the muddy brush.
- Reuses the park's layout as a base for now; bespoke geometry later.

## 2026-07-18 — v1.19: web-perf pass #2 — gate entity redraws

- Same principle as #1, applied to the entities: an entity moves via its
  node transform every frame (so movement stays perfectly smooth), while
  its procedurally-drawn POSE only needs ~30fps. Gated the multi-instance
  entities to redraw every other physics frame - freedogs, NPC pairs,
  squirrels, pigeons, ducklings, Tofu - exactly halving their draw calls.
- NPC-pair leashes (line-heavy rope draws) also gated to 30fps via a
  `hero` flag; the PLAYER's leash stays full-rate (it's the hero element).
- Measured earlier: entities cost real CPU (native ~424fps at 8 entities
  vs ~600 at 6). Halving their draw frequency recovers ~half of that,
  which matters most on the WASM web build. Native was already smooth;
  verified movement stays smooth (transform updates every frame) and all
  regressions pass.

## 2026-07-18 — v1.18: the rescue chase (completes the threat grid)

- The third and final cell of the chase threat grid: a fast threat that
  scares BOTH of you. A crimson fire engine comes barrelling down (lights
  flashing) and, for once, you and the owner want the same thing - they
  panic-sprint for home AND you're right there with them. A committed
  co-op dash: don't fight the leash, just GO. Faster than the sweeper or
  the bolt, so there's no time to dawdle.
- The grid is now complete: slow+scares-you (sweeper, drag the owner),
  fast+scares-owner (bolt, dragged by them), fast+scares-both (rescue,
  sprint together). A home-leg chase rolls sweeper/bolt/rescue.
- Force it with --rescue; CI runs a --rescue traversal. Kind-aware
  vehicle skin, HUD, and game-over text.

## 2026-07-18 — v1.17: web-perf pass #1 — decouple world redraw

- Measured the frame cost (windowed, in microseconds): the full-world
  _draw was the single biggest cost (~750us, running ~100x/sec = ~75ms of
  CPU per second), dwarfing physics (~24ms/sec, leash the biggest chunk).
- Fix: the world is drawn in WORLD space, so scrolling the camera does
  not require re-running _draw - Godot re-renders the persisted canvas
  items from the new camera position for free. So the per-frame world
  redraw was almost entirely wasted. Now the world redraws at ~30fps (for
  its own glints/blinks), while the camera still scrolls every frame.
  ~70% less draw CPU (~75ms/sec -> ~22ms/sec), and the scroll is
  visually identical.
- This targets exactly the web (WASM) build's bottleneck; native was
  already smooth. Next perf increments (measured in-browser): gate the
  per-entity redraws the same way, and trim leash solver cost.

## 2026-07-18 — v1.16: "no signal" owner event

- A new rare owner behaviour, and maybe the most on-theme one yet: the
  phone addict loses their bars, stops dead, and thrusts the phone
  skyward hunting for a signal ("no signal..."), rooted for a few
  seconds while you, the dog, are stuck on the other end of the leash.
  The owner's phone obsession finally becomes a gameplay beat.
- Added to the shared random-event pool, so it can strike on any walk
  (~1 in 8 owner events). Zero new entities - deliberately cheap, since
  the current jank is the web build's CPU headroom, not native.

### Note on performance / the engine ceiling

Profiled this session: natively the game holds ~100fps with no drops
even at peak entity counts, and the leash physics costs ~0.1ms/frame -
so the choppiness reported in play is the WASM web build (2-5x slower
than native), not a native or algorithmic problem. Renderer is already
gl_compatibility. A dedicated web-perf pass (measured in-browser) is the
right next step when we choose to spend on it.

## 2026-07-18 — v1.15: carry / delivery missions

- A new objective type, a calm counterpoint to the chaos: pick an item up
  in your mouth on the walk and tote it to a marked drop-off. Reuses the
  mouth-carry from fetch; the parcel rides at Millie's nose while she
  carries it, and a "DROP" marker shows where it goes.
- Two to start: the boulevard (deliver the newspaper to a stoop) and El
  Mercat (run the crate of oranges to the far stall). Each is a per-level
  goal worth bones + a slow-mo on delivery, and it feeds the combo meter.
- Pickup and drop are placed on opposite sides so it's a real detour with
  the owner in tow, not a straight line.

## 2026-07-18 — v1.14: snow (ice-slide weather)

- A fourth weather, SNOW, selectable on any walk. Falling flakes, a cold
  bright tint, and - the point - ICE underfoot: both the dog and the
  heavy owner lose grip and skate, momentum carrying them past where they
  meant to stop. Turns every leash yank into a slide and makes the poles
  genuinely hazardous. A cross-cutting mechanic rather than a one-off
  level, so it recolours the whole game.
- New --weather= cmdline hook (like --level=) for testing:
  `--level=park --weather=snow`. CI smoke-tests the ice-physics path.
- Default weather is unchanged, so the deterministic autowalk traversal
  is unaffected.

## 2026-07-18 — v1.13: El Gotic (the old town alley) + wall cats

- New sixth walk: El Gotic (gate 9), a tight medieval alley. Extra poles
  pinch the channel so threading the oblivious owner through is the real
  work; laundry strung overhead and lanterns down one wall for the look.
  Reuses the market's stall-lined layout as a base for now; bespoke
  geometry is a later pass.
- Signature: WALL CATS. Cats perched on ledges up both walls, smug and
  just out of reach. Millie can never catch one (that's the joke) - they
  arch and hiss as she nears, and a good BARK sends them leaping off with
  a yowl. Shooing them is a per-level goal ("shoo 3 wall cats"), scores
  bones, and feeds the combo meter. The hard-to-reach prize is a sardine
  tucked under a cat's ledge.
- New wall-cat regression test; CI smoke-tests the new level and runs the
  test.

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
