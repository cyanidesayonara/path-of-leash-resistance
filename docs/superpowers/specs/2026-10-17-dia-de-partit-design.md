# Dia de Partit: the walk to the stadium on match day

Approved by Santtu, 2026-10-17. Release 1.61. His decisions are at the end
(Decisions) and are written into the sections below.

Level id `partit`, name **Dia de Partit**, subtitle "match day". It is the
sixteenth walk. It opens after Montjuïc, at 27 stars.

## The walk in one paragraph

It is match day in Les Corts. Your human is taking the dog out on the one
evening the whole neighborhood heads the same way. On the walk out the
streets fill with fans in blue and claret, all flowing north toward the
stadium. You thread the river, the vendors, the supporters' bar and the
mounted police, and you get your human clear of the away fans' march. Then
the referee blows for kick-off and the streets empty in a few seconds. You
come off the leash in the square by the stadium while the first half roars
over the wall. The walk home runs down empty streets full of dropped food,
with your human glued to the match on the phone. Then the final whistle
goes, and the whole stadium pours out behind you.

## How it fits the game

| Pillar | Here |
|---|---|
| The comedy is the mechanic | The crowd carries your human like a current. A taut leash across the river gets dragged. Your human celebrates a goal a second after the stadium does, because the phone stream lags. |
| Temptation vs duty | Dropped food everywhere once the streets empty, and the horses' droppings as the best sniff in town. Against that, the away march, horses and a crowd that does not look down. |
| The human is a payload | Your human never looks up. Every crowd event is telegraphed by sound you can hear coming: sirens, drums, the "ooooh" before a goal, the whistle. |
| Soft failure | Being swept along by the crowd costs ground and patience, not the walk. Only a horse's shoulder cracks the phone, the way a bike does. |
| The leash is an honest rope | Lampposts down the avenue's median to wind around, steel barriers to grind, a floodlight-style lamppost on the esplanade to fling from. The crowd parts around the leash. Nothing in the crowd becomes a rope contact (see Risks). |

It follows every rule in `docs/LEVEL_DESIGN.md`:
- Its own place. Nothing in it is borrowed from another layout.
- A signature line (below).
- Props in clusters that read as a thing: the bar terrace, the scarf stall,
  the police line, the ticket windows.
- The rhythm is a calm side street, the busy avenue, the set piece, then the
  esplanade before the gate.
- Substances in their real shapes.
- The off-leash space belongs to the walk.

## The place

Les Corts, northwest Barcelona, the residential grid between the Diagonal
and the Travessera de les Corts, walked north to a stadium that is never
named. The real streets are long, straight and lined with plane trees. Apartment
blocks have balconies, ground-floor bars and a few cut-through side streets.
On match day the police close the avenues to traffic, put out steel barriers
and park vans at the corners, and the neighborhood turns into one slow
procession.

### Branding: what keeps it generic

Santtu asked for no real club, crest, sponsor or player. The rules for every
piece of art and text in the walk:
- **No club is named.** Not the home side, not the visitors, not the
  stadium. Fans are "the home crowd" and "the away fans" in code and docs,
  and in game text "els nostres" or nothing at all. The stadium is
  "L'ESTADI" on its signs and nothing else.
- **No crest.** Scarves, flags and banners carry colors and invented words
  only. The one mark is a plain white five-pointed star, which no real
  Barcelona club uses as its crest.
- **Kits are never vertical stripes.** Blue-and-claret vertical stripes
  are one club's trade dress. Home shirts are halves (left blue, right
  claret). Scarves are bars of the two
  colors, which every club in the world has.
- **No chest rectangle.** No shirt has a sponsor-shaped panel, a name or a
  number on the back.
- **The away fans are invented:** orange and slate gray, a color pair no top
  Spanish side wears.
- **No real chant, anthem or motto.** Banners use invented lines:
  "FINS AL FINAL" (to the very end), "SEMPRE AMB TU" (always with you),
  "LES CORTS CANTA" (Les Corts sings). The chants in the music are invented
  call-and-response on the soundtrack's own scale.
- **A text test guards it.** `tests/test_partit_branding.gd` scans every
  string in the level's scripts against a deny list (club names and
  nicknames, the stadium's name, sponsor names, the real club motto) and
  fails on a hit, the way `test_prompts.gd` fails on a key name.

### Catalan names

| In the world | Gloss |
|---|---|
| DIA DE PARTIT (the walk's name, written on the ground at the start) | match day |
| PLAÇA DEL GOL (the off-leash gate) | goal square, off leash |
| CARRER TALLAT (the barrier sign where the avenue closes) | street closed |
| BAR LA PENYA (the supporters' bar) | the supporters' club bar |
| BUFANDES (the scarf stall) | scarves |
| PIPES · AIGUA · REFRESCOS (the seed and drinks cart) | sunflower seeds, water, sodas |
| ENTREPANS (the sausage sandwich stand) | sandwiches |
| TAQUILLES (ticket windows) | box office |
| PORTA 7 ... PORTA 12 (the stadium gates) | gate 7 ... 12 |
| L'ESTADI (on the stadium wall) | the stadium |
| els tabalers (the drum group) | the drummers |
| la policia muntada (the mounted police) | mounted police |
| els visitants (the away fans) | the visitors |

The walk's name is written on the ground in **sunflower seed shells** (pipes).
At a Spanish ground the shells cover the floor of the stands. They behave
like El Barri's leaves: they scatter, spin and stay scattered. HOME at the
start line is written the same way.

## The layout

The walk runs from START_Y 260 to GATE_Y -5000, as every walk does. It gets
its own builder in `world/level_build.gd` and its constants and per-frame
logic in a new `systems/partit.gd` (class `Partit`), the way Montjuïc has
`systems/montjuic.gd`. The cross-section is sidewalk either side (the
avenue is the path, closed to traffic). It has its own `edge_nodes`:

| Stretch | y | Half-width | What it is |
|---|---|---|---|
| A. El carrer | 260 to -700 | 220 | A calm residential side street. Balconies with home flags overhead (cached on the overhead layer), a grandad in a scarf on a bench, the first few fans heading up early, a kid in a home shirt bouncing a ball, a fans' dog or two to greet. The calm opening. |
| B. The corner | -700 to -1000 | 220 to 380 | The street opens onto the avenue past CARRER TALLAT: barriers, a police van with its lights turning, two officers chatting. |
| C. L'Avinguda | -1000 to -2500 | 380 | The avenue, closed to traffic and filling with the crowd river. A median of plane trees and lampposts down the middle. Steel barriers along both kerbs. The scarf stall (east, -1300), the seed and drinks cart (west, -1650), BAR LA PENYA's terrace spilling over the west sidewalk (-1800 to -2100), the sausage sandwich stand smoking (east, -2200). The side street with the kids' kickabout opens east at -2350. |
| D. La Marxa | -2500 to -3400 | 380 | The avenue goes on. This is where the away march comes down (set piece 1). The police line stands here on the way home. |
| E. Les Portes | -3400 to -4600 | 420 | The stadium approach. The stadium's outer wall and ramps rise along the east side (edge layer), with gates PORTA 7 to 12, the TAQUILLES, crowd-control lanes funneling to the turnstiles, els tabalers on a low stand, and a ticket tout working the edge. Floodlight pylons tower overhead. Far off past the bowl, flare smoke drifts. |
| F. The gate | -4600 to -5000 | 420 to 260 | A pinch through the esplanade railings to the PLAÇA DEL GOL gate. |

The way home re-reads the same street backwards. What changes is the
crowd (below), not the props.

### What is marked, sniffed and eaten

- **Marks:** lamppost bases on the median, barrier feet, the scarf stall's
  leg (the seller shouts "eh! not the merch!"), a police van's tire (no
  reaction, which is funnier), the bollards at the corner. These stand where
  hydrants stand on a street walk.
- **Sniffs:** the sausage stand's smoke, the bar's crisps under the tables,
  the horses' droppings (once the police line has been there; "a very
  important sniff +4", counts as a sniff).
- **Dropped snacks** (the existing snack goal): a pipes spill, half a
  sandwich, a bag of crisps. Two are on the street before kick-off. After
  kick-off the empty street is strewn with about six (below).

### Substances

- **Spilled soda** near the drinks cart and under the bar terrace: sticky,
  in the shape spilled drinks take (small splashes with a cup beside each).
  It reuses the `icecream` substance (sticky paws). Its color is the only
  change.
- **Horse droppings** where the police line stood: a stinky substance. It
  is the one new entry in SUBSTANCES ("STINKY PAWS!"), in small piles, never
  a slab, and only after the march has passed.
- **Confetti** on the way home if the home side won. It reuses `confetti`,
  as scattered pieces.

### The signature line

Run the zoomies onto the steel barriers along the avenue kerb and ride them
(**BARRIER RUN**, a new entry in `systems/rails.gd`). Pole-swing off a median
lamppost to cut across the crowd river. Weave the scarf stall's hanging
poles without wrapping the stall. Then, on the esplanade, wind your human
around the floodlight-style lamppost and fling them out into the open space
in front of the gates. On the way home the same line runs backwards down
the empty avenue, which is where the barriers are easiest to grind.

## The crowd river

This is the system that makes the walk play differently. It is new, and it
is built so it can also give El Diluvi's umbrella crowd real movement (see
Pairing).

**What it is.** A flow of fans down the corridor. The walk-out flow goes
north (with you). The home-leg flow goes south (also with you) after the
final whistle. Both phases have counterflow: vendors walking the other way
with their trays, late stragglers running against you, and the away march.
Density is data: a curve over y for each match phase. It is thin in the
side street, packed on the avenue and thickest at the gates.

**Fans are not bodies.** They are like La Rambla's tourists (`entities/tourist.gd`):
- They step aside from the dog, your human and each other, so a dense crowd
  can never wedge the walk shut.
- They see solid things coming and walk around them.
- Nobody ever stands inside a stall, a van or a barrier.

**Fans and the leash.** Fans read the leash and never touch the rope solver:
- **Slack leash:** fans step over it. Some of the fans who step over say
  "hup", which is a cosmetic hop.
- **Taut leash across the flow:** each fan who meets it adds a small push
  along the flow to the dog and your human, through `Partit`'s crowd push
  (below). A taut leash strung across the river gets dragged with the
  current.
- **Taut leash along the flow:** nothing happens. Fans walk beside it.

So the verb is: keep slack in a crowd, or keep the leash pointing the way the
crowd goes.

**Your human in the river.** A human standing in the dense part of the
river is carried with it. The carry uses the same mechanism as the leash
conversation's lead: the crowd moves where they mean to go and adds to or
takes from their pace. Their motor is never reduced. A packed crowd going
your way gets them there faster. When the dog is trying to cross, the river
pulls your human downstream. When you pull against it, patience drains as
with any hard haul.

**Crowd mood.** The fans chant in waves from the music. Before a goal they
go "ooooh" and after one they cheer. Shirts, scarves, flags, a few kids on
shoulders and a few fans' dogs come from the shared person renderer
(`entities/human_appearance.gd`), simplified for distance (Risks).

## The kick-off clock

The walk has a match clock, as one small pure state machine
(`systems/match_day.gd`, testable headless):

| Phase | When | What happens |
|---|---|---|
| PREMATCH | from the start | The streets fill as you go north: crowd density follows y. |
| RUSH | the last 25 s before kick-off | The PA echoes over the rooftops ("falten cinc minuts", as speech with an English line under it). The drums speed up, and the crowd breaks into a jog. More fans pass close and fast. The banner says KICK-OFF SOON. |
| KICKOFF | at KICKOFF_T (210 s of walk), or as the pair go through the gate, whichever comes first | The referee's whistle sounds from the stadium. A roar follows. Over about 8 seconds the crowd peels off east into the gates and the turnstiles and is gone. |
| MATCH | after kick-off | The streets are empty, littered and quiet. A few stragglers run north late against your home direction. BAR LA PENYA's terrace is packed with fans watching the TV. Goals happen (set piece 2). Your human watches the match on the phone (below). |
| FULLTIME | on the way home, as the pair pass FULLTIME_Y (-3000) going south, and not before 60 s of MATCH | The final whistle sounds and the stadium empties behind you (set piece 3). |

**Why "whichever comes first".** A player who reaches the gate quickly
plays the full crowded walk out. A player who dawdles sees the streets
empty around them while still on the way out: a different, quieter walk out
full of food and stragglers, with nothing lost. The clock is announced by
sound you can hear coming and never punishes. KICKOFF_T is a named constant
for playtesting.

### Your human on the match

From kick-off the phone is showing the match: a green glow on the screen
and a little score in the corner of their bubble.
- They walk a little slower (MATCH_PACE 0.88, a constant).
- They mutter the way people watching football do. Speech is lower case:
  "come on...", "ref!", "no no no".
- **The bar's TV.** Passing BAR LA PENYA during the match, they say "ooh,
  the replay..." (the 0.8 s telegraph) and drift over to watch through the
  window for up to WAIT_MAX unless the dog hauls them away. This uses the
  existing DRIFT state. It is either free slack or a stop, depending on
  where you wanted to be.
- **Goals** (set piece 2): a celebration a second after the stadium's roar.

## The set pieces

### 1. La Marxa: the away fans' march (walk out)

An escorted column of away fans comes south down the east carriageway,
against the flow. They wear orange and slate gray, chant and drum, and are
boxed in by four mounted officers at the corners and a police motorbike in
front.

**The telegraph, layered from far to near:**
- 4 s out, a police siren "whoop" and the motorbike's blue light at the top
  of the screen.
- The away fans' drum, heard before they are seen.
- The home crowd parting to the west carriageway and the sidewalks. The
  river splits, which you can see coming.
- The banner: AWAY FANS! GET YOUR HUMAN CLEAR.

**The play.** The column is a moving keep-out, 150 wide and 360 long,
walking south at 55 px/s. Your human, phone up, walks straight on. Anyone
inside its footprint is turned around and carried back south ("whoa whoa
whoa"), which costs ground and patience but not the phone. The horses are
bigger and slower than bikes and visible from far off. A horse's shoulder
that catches your human is one phone crack, as a bike's would be, and a dog
it catches tumbles.

**The counterplay:**
- Lead your human west across the median with the leash conversation.
- Or wind them around a median lamppost and let the march go by. The
  crowd-control barriers and the median trees give you anchors.
- Or dig in at the kerb.

**Dog business.** The horses leave droppings behind. They are the best
sniff in town and the start of the stinky substance. Marking a horse is not
allowed (the dog is never cruel). A dog who barks at a horse gets a snort
and a tail swish, and nothing worse.

**Goal:** "Keep your human out of the away march".

**Both directions.** The march only comes on the walk out. On the way home
the officers stand their horses in a still line along the esplanade railing
(D/E boundary). The horses are solid bodies, and the line is where the walk's
prize is (below). The way home has its own set piece, the final whistle, so
LEVEL_DESIGN rule 4 holds as "each direction has one".

### 2. El Gol: the roar (after kick-off, anywhere)

During the match, goals come on a seeded schedule: the first no sooner than
25 s after kick-off, then at least 35 s apart, and at most three a walk.
Some of them are the other side's goals. One might be disallowed.

**The telegraph.** The stadium goes "ooooh", a rising swell of about 1.5 s.
The floodlight haze flickers with camera flashes and the bar's terrace
fans half-stand. Then the ROAR.

**The dog.** The roar is a fright: SCARED, bumped by how close she is to
the stadium (loudest in the off-leash square). The one exception is a dog
right beside her human (within 70 px) when they celebrate. She joins in
and gets ZOOMIES instead. The player can see the swell coming and choose to
be at her human's side, so the mood still arrives from what happened and is
answered by what she did (mood.gd's rule). Santtu kept this rule; its
distance is a constant for the playtest.

**Your human.** One second after the roar, because the phone stream lags,
your human celebrates ("gooool!"): both arms up, two hops on the spot,
rooted for 1.6 s. The stadium's roar is their telegraph, longer than the
0.8 s every owner event needs. Rooted means they are a pole for 1.6 s:
free slack, and a moment to swing around them. If the away side scores,
they slump instead ("no..."), walk slowly for 3 s and never root.
A disallowed goal is a long groan from the stadium and a "WHAT?" from your
human.

**The bar terrace.** At BAR LA PENYA the fans leap up, chairs shove back
(the chairs move a little, like the terrace furniture they are) and a
shower of crisps lands on the sidewalk. That is a snack on any goal.

**Off leash.** In the square the free dogs flinch at the roar and then run
a lap. The agility clock does not stop.

**Far-off flares.** Now and then over the bowl a flare's smoke rises red or
purple, and a firecracker bangs. It is telegraphed by a hiss and a spark
line climbing for 0.8 s, and gives a small SCARED bump. Never on the path,
always far off.

### 3. El Xiulet Final: the final whistle (walk home)

As the pair pass FULLTIME_Y going south (and at least 60 s into the
match), the stadium blows for full time.

**The telegraph.** Three whistle blasts from the stadium. Then a growing
noise from behind for 4 s before the front of the crowd arrives at the top
of the screen. The banner says FULL TIME! THE CROWD IS COMING.

**The play.** The whole crowd river pours south behind you, at fan pace,
faster than your human walks:
- A slack leash and a human against a lamppost or the barriers lets the
  river flow past.
- A taut leash across it gets dragged.
- A human in its middle is carried, faster than they meant, toward home,
  which is mostly good, until the dog wants to stop for a mark.

It is not a chase. Nothing catches you and nothing ends the walk. It is the
home leg's crowd and the reason the way home is not just the way out
backwards. HomeChase keeps its chase on La Neteja only, so the two never
meet.

**Goal:** "Beat the crowd home". It is ticked if no fan of the outflow
passes the dog before she reaches HOME, so you have to keep ahead the
whole way. It is the walk's skill goal.

**The result.** It is seeded and shown on your human's phone and on the
crowd. A home win means chants, scarves twirling and confetti thrown. A
draw means a murmur. A loss means a slow, quiet, grumbling crowd, which is
easier to beat home: losing makes it the easy walk.

## The corners: dog business off the main line

- **The kickabout** (the side street east at -2350). Three kids play with
  two rolled-up jackets as goalposts. Now and then the ball gets away and
  rolls across the avenue, telegraphed by a kid's yell, "ball!". The dog can
  pick it up and bring it back. She can also carry it and drop it between
  the jackets, which gets "GOL!", the kids cheering and +5. This uses the
  carry system, with a drop-off that is a goal mouth. **Goal:** "Score a goal
  in the kids' street game". After kick-off the kids are gone, inside
  watching, and the jackets lie in the street.
- **The lost scarf.** Before kick-off, a kid on her dad's shoulders in the
  crowd loses her scarf. In wind a gust takes it, like Montjuïc's sunhat.
  On a calm day it slips off. It lands at the edge of the river. The kid
  and her dad stop by a lamppost a little way north ("my scarf!") and
  wait. Bring it back: "good dog!", 6 bones and the kid's whole section
  applauding. **Goal:** "Bring the lost scarf back".
- **Pickpockets.** A packed crowd is what they work (`docs/LEVEL_DESIGN.md`,
  Pickpockets). Two appear in PREMATCH and none after kick-off. The tout at
  the gates is a decoy who looks shifty and is not a thief, which is the
  joke. The system is already built, so this only turns it on here.
- **Fans' dogs.** Two or three NPC pairs walk to the bar in shirts and
  bandanas, and two more pairs come out at full time. The existing "hi"
  goal.
- **The prize** (each walk's hazardous prize): a whole sausage dropped
  under the police horses in their line on the way home. The horses shift
  their weight now and then, telegraphed by a snort and a tail swish 0.8 s
  before, and a dog under a horse that shifts gets bumped. **Goal text:**
  "snatch the sausage from under the police horses".

## Mood and weather

**Moods:**
- SCARED: the roar, the far-off firecrackers, and a horse's tumble.
- ZOOMIES: celebrating beside your human, as above.
- BARKY: the drums. Bark at els tabalers and they play louder, which feeds
  it, as mood.gd's rule says.
- TIRED is answered by the bar's water bowl (a drink spot by its door).

There are no new moods and no new rules. Every new bump is bounded by
mood.gd's existing limits, and `tests/test_mood.gd` stays the guard.

**Weather** (all four are selectable, as on every walk):
- **Clear:** the default.
- **Rain:** ponchos and umbrellas in the river. An umbrella makes a fan
  wider, so the river is denser for the same count. The avenue is slick
  and the bar's parasols are up. This shares its umbrella art with El
  Diluvi's fix (Pairing).
- **Wind:** flags stream from the balconies, banners ripple, and the lost
  scarf blows away rather than slipping off.
- **Snow:** rare in Barcelona and funny on match day. Fans in big coats
  and bobble hats, and ice-slide physics for both ends of the leash in a
  crowd.

**Night:** the floodlights light a haze over the bowl and pools of light
fall on the esplanade. It reads as an evening kick-off. Day and night
follow the existing system.

**Sound:** a match-day arrangement of the soundtrack (procedural, as
Montjuïc's): tabal drums, a crowd bed that rises and falls with density,
and the invented chant. New SFX are synthesized like the rest:
- the whistle
- the roar (band-passed noise swelling and bursting)
- the "ooooh"
- the groan
- the siren whoop
- the horse snort
- the firecracker

## The off-leash space: PLAÇA DEL GOL

A paved square beside the stadium, signed PLAÇA DEL GOL ("goal square, off
leash"). It uses the existing `placa` mechanics: the agility course, the
rope tug, frisbee and the fountain. Its look is its own:
- plane trees in grates
- benches
- the closed club-shop shutters (blank, no logo)
- a row of scooters
- litter from the crowd that just went in

Past its top edge is the stadium itself, drawn on the freedom-beyond layer:
the curved concrete bowl, the ramps, the floodlight pylons, and the roof
edge glowing at night. The roar comes from right there, so this is where
goals are loudest. The agility course, rope tug and frisbee are the same as
everywhere, as Santtu asked.

## Goals

There are twelve, in sentence case, as instructions to the dog. They are
the staples plus the walk's own:

1. Mark 5 spots (`mark`)
2. Have 4 good long sniffs (`sniff`)
3. Get the phone home without a scratch (`phone`)
4. Get yourself home without a bump (`paws`)
5. Get your business bagged (`bag`)
6. Bring the ball back 3 times (`fetch`)
7. Scarf down 2 dropped snacks (`snack`)
8. Keep your human out of the away march (new: `march`)
9. Bring the lost scarf back (new: `scarf`)
10. Score a goal in the kids' street game (new: `kickabout`)
11. Beat the crowd home (new: `fulltime`)
12. Snatch the sausage from under the police horses (`prize`)

`combo` ("Land an x3 trick combo") and `hi` ("Say hello to 3 dogs") are
not on the list: twelve goals, no thirteenth. The barrier grind still
feeds the combo meter. **Tofu is left out.** The way
home belongs to the final whistle, and herding a cat through a stadium's
worth of fans is one thing too many. La Neteja set the precedent.

## Pairing

**Unlock:** after Montjuïc, at 27 stars (STAR_GATE), last in LEVELS and
CAROUSEL. Appending keeps every other walk's seeded sequence and behaviour
snapshot unchanged. The Daily Walk rotation, `LEVELS[seed % size]`, does
reshuffle which walk falls on which day. Montjuïc's addition did the same.

**The paired upgrade: El Diluvi (#152).** It is already on the 1.61
milestone, and it pairs best:
- PROJECT.md has asked since v1.10 for El Diluvi's umbrella crowd to
  "actually shuffle and jostle rather than stand still". The crowd river
  built here is exactly that system.
- The audit's "umbrellas read as horseshoe magnets" fix (a filled canopy
  with ribs) is art this walk needs too, for rain on match day.
- It shares the rest of #152 (stacked and chained terrace chairs, the
  rooftops, the porch yard) only as timing: one release, one crowd
  system, two walks better for it.

Alternatives if Santtu prefers:
- **La Rambla:** the river would give its tourists real flow. It was
  audited in #149, so this would be new work rather than an audit.
- **L'Estació (#155):** the fans could arrive by train in a later pass.

## Build plan

The plan has nine player-facing PRs, each reviewable on its own and each
with a feel card. **The WIP limit applies:** at most five player-facing
changes awaiting acceptance. Check the board before starting each. PRs 2
and 3 can merge as one if the count is tight, and the branding test can
land early as hardening. Every PR keeps the tree green: level_check,
selftest, the autowalk bot taught about each new thing, and
`tools/behaviour_snapshot.sh` unchanged for every other walk. Each PR commits
the `.gd.uid` for every new script.

### PR 1: corridor and set dressing (no crowd yet)

**Changes:**
- `Game`: LEVELS, names, subtitle, STAR_GATE 27, CAROUSEL.
- `LevelBuild.partit` with `Partit` constants.
- `edge_nodes` and the cross-section.
- Props:
  - the median trees and lampposts (poles)
  - the barriers with BARRIER RUN in `rails.gd`
  - the scarf stall, the cart and the sausage stand (stalls, solid)
  - BAR LA PENYA's terrace (tables, chairs, parasols)
  - police vans
  - the TAQUILLES and gates
  - the stadium wall and ramps on the edge layer
  - balconies and flags on the overhead layer, cached
- PLAÇA DEL GOL (`FREEDOM_KINDS` placa) with the stadium beyond.
- The gate sign, and the name in pipes shells (`world_sign.gd` material).
- Staple goals only.
- Every level list Montjuïc joined: CI selftest and smoke sweeps, the soak
  matrix, shot, perf and idle-soak sweeps, the snapshot, the terrain and
  off-leash bounds audits, and the junk placement test.
- `tests/test_partit.gd` started: corridor continuity, props clear of the
  path where they should be, barriers are rails.

**Check:**
- `--level=partit --shot` at the start and at `--shot-y=-1800`, `-3000` and
  `-4200`.
- `level_inventory` lists it.
- `--drawcost` against La Rambla on one machine: world draw at or under
  La Rambla's.
- A playtest script (`--level=partit --steps="up:6;shot;turbo+up:4;shot"`):
  no "HUMAN STUCK", nobody inside a solid.

**Feel card:** the avenue reads as a closed street on match day from one
screenshot. The barriers grind only with the zoomies.

### PR 2: the crowd river, the budget proved first

**Changes:**
- `systems/crowd_river.gd`: a pure data simulation in packed arrays,
  headless-testable.
- `world/crowd_layer.gd`: one canvas drawing every visible fan in one
  `ShapeBatch`, redrawn at 30 fps like the NPC pairs.
- **Stress case first:** 150 fans with `--drawcost` and
  `tools/web_perf.sh partit street`, before any dressing.
- Then:
  - north flow and density by y
  - counterflow vendors
  - parting around the dog, your human and the leash
  - stepping over a slack leash
  - the taut-leash drag
  - your human carried with the flow through the give
- Tests in `tests/test_crowd_river.gd`:
  - no fan inside a solid, the dog or your human
  - the leash respected
  - deterministic for a seed
  - the crowd's draw calls constant with fan count
  - the human's motor never reduced, only their target and pace

**Check:**
- Draw calls and world draw time at 150 fans against La Rambla.
- The rope bench hashes unchanged (`tools/bench_leash.gd`). The crowd never
  touches the solver.
- A playtest crossing the river in both directions.

**Feel card:** threading the river with slack is easy and with a taut leash
across it is a tug. Your human drifts with the crowd but never stops
walking.

### PR 3: the kick-off clock and your human on the match

**Changes:**
- `systems/match_day.gd`: the phases, the PA telegraph, the RUSH, and the
  drain through the gates.
- The empty-street litter and snacks.
- Stragglers against the flow.
- Your human's match behaviour: pace, mutters, and the bar TV drift with
  its telegraph.
- `tests/test_match_day.gd`:
  - phases in order
  - kick-off on whichever comes first
  - every human event telegraphed
  - streets empty within the drain time

**Check:**
- A fast walk (gate first) and a slow one (clock first). The slow one shows
  an empty walk out.

**Feel card:** the whistle empties the streets in a few seconds and it is
funny, not jarring.

### PR 4: set piece, El Gol

**Changes:**
- The goal schedule.
- The "ooooh" swell, the roar, and the human's delayed celebration and
  slump (a new short human state, rooted, telegraphed by the roar).
- The SCARED or ZOOMIES rule.
- The bar terrace eruption.
- The disallowed groan.
- Far-off flares and firecrackers.
- Whistle, roar, ooooh, groan and firecracker SFX.
- Extends `test_match_day.gd`: the telegraph always precedes, bumps are
  bounded, and it never roots during a whirl.
- `test_mood.gd` stays green.

**Check:**
- `--level=partit` with a debug flag to force a goal (`--goal-in=S`).

**Feel card:**
- Standing beside your human at the swell gives zoomies.
- Away from them, a fright.
- Your human always celebrates a beat after the stadium.

### PR 5: set piece, La Marxa

**Changes:**
- The away column as a moving keep-out on the human's existing keep-out
  logic.
- The mounted officers: horses are solid bodies, not rope contacts.
- The motorbike, siren and drum telegraph.
- The river splitting.
- The droppings (sniff, and the stinky substance).
- The still police line on the way home.
- The prize under it, with the horse's weight-shift telegraph.
- The autowalk taught to wait by the median.
- `tests/test_partit.gd` grows:
  - the column is telegraphed at least 4 s before it reaches the pair
  - a human inside it is carried, not cracked
  - a horse bump is one crack

**Check:**
- `--shot-y=-2600 --shot-at=120` to photograph the column.
- A playtest anchoring on a median lamppost.

**Feel card:** you hear the march before you see it. Winding your human
round a median lamppost lets it pass.

### PR 6: set piece, El Xiulet Final

**Changes:**
- The full-time trigger.
- The outflow behind the pair at fan pace.
- The result-flavored crowd: win, draw or loss, and confetti on a win.
- Two fans' dogs coming out.
- The "fulltime" goal's measure.

**Check:**
- `--level=partit --shot-home --shot-y=-3200` and a playtest of the home
  leg, both holding ahead and being overtaken.

**Feel card:** the whistle and the noise behind you give time to choose. A
human against the barriers lets the crowd pass.

### PR 7: the corners

**Changes:**
- The kickabout: the kids, the ball across the avenue with its yell, the
  carry-to-goal drop-off.
- The lost scarf: the kid and dad, the gust or slip, the return.
- Pickpockets on for this walk (`crowded()`).
- The fans' NPC pairs.
- The bar's water bowl.

**Check:**
- Shots at the side street.
- A playtest carrying the ball into the jackets.

**Feel card:** the ball rolling out is always called first. Scoring in the
jackets is a little celebration.

### PR 8: goals, words and sound

**Changes:**
- The twelve goals in `LEVEL_GOAL_IDS` and `defs`.
- The prize text.
- Results card lines.
- `tests/test_partit_branding.gd`. This can land earlier as hardening.
- The match-day music arrangement.
- CHANGELOG, PROJECT.md (release list, New walks) and LEVEL_DESIGN.md
  (the walk's entry, the writing-on-the-ground row, the path shape row).
- The Store and itch listing count: fifteen walks to sixteen.

**Check:**
- Every goal ticked once in a playtest.
- The branding test fails on a planted deny-list word.

**Feel card:** the goals read as instructions to the dog. Nothing names a
real club.

### Paired PR: El Diluvi (#152)

**Changes:**
- The audit list.
- The umbrella crowd moving on `crowd_river.gd`: a slow two-way shuffle
  along the shopping street, jostling under the awnings.
- It lands after PR 2.

## Risks

**Draw calls on the web build.** This is the biggest risk. Fans drawn as
tourists are drawn today would be one node, one redraw every frame and at
least one draw call each. Today's crowd is 14 tourists. Match day wants
80-150 visible. The plan:
- Fans are data, not nodes, and one layer draws them all in one
  `ShapeBatch`, culled to the visible band, at 30 fps.
- A distance fan is 5-6 shapes: shadow, shoulders in the shirt color, head,
  hair, and a scarf bar or flag. The full person renderer is kept for the
  few interactive people (vendors, the scarf kid, kickabout kids,
  pickpockets, the tout), which stay nodes.
- Static scenery goes on the cached canvases: the balconies, banners,
  stadium wall and barriers.
- Prove the budget with a stress case before dressing (PR 2), measured
  with `--drawcost` natively and `tools/web_perf.sh` in the browser against
  La Rambla.
- If the budget fails, cut density before cutting the river: the river
  reads with 60 fans if they move together.

**Crowd pathing with the leash.**
- **Rope contacts.** If fans were rope contacts they would add dynamic
  snags to the solver, break the bench hashes and risk wedges. They are
  not. Fans read the leash polyline and react (step over, part, push along
  the flow on a taut leash), the way pickpockets already read it to trip.
  The rope solver, `test_wrap.gd` and the bench hashes are untouched.
- **Fans wedging the pair.** Fans are not bodies, so a crowd can never
  wedge the walk. The carry acts on your human's target and pace, never
  their motor, and is capped. A test pins that a human in the densest crowd
  still reaches the gate.
- **The column wedging your human against a barrier.** The keep-out pushes
  along the column's own direction first and sideways second. The barriers
  stop short of the median so there is always a gap. `level_check` gets a
  rule that a keep-out path never ends inside a solid.
- **Horses and the rope.** Horses are solid bodies but not poles. The rope
  passes them without wrapping, for now. A moving wrappable body is
  the dynamic-snag work the AGENTS.md rope rules warn about, and it is out
  of scope here.

**Physics cost.** Fans' avoidance is local and binned by y:
- no all-pairs work
- lane spacing instead of fan-to-fan pushes
- solids from the existing bypasser blockers

The PR 2 stress test watches the physics step as well as the draw.

**The autowalk and CI.** Each set piece needs the bot taught about it in
the same PR, or CI goes red on a half-built walk (the lesson from La
Neteja). The bot:
- waits at the median for the march
- holds the barrier line at full time
- never takes the scarf or the ball

**Readability.** A wall of blue and claret could swallow the dog and your
human. The fans are drawn a step darker and a step smaller than the player
pair, the pair's shadow is kept, and the leash always draws above the crowd.
Check at 844x390 in the shot sweep.

**Branding drift.** Covered by the rules above and the text test. Art is
checked by eye in each PR's feel card.

**Scope.** Nine PRs is more than Montjuïc's first version. If 1.61 is
tight, the cut line is after PR 6. The corners (PR 7) can ship in 1.62 and
the walk still has its three set pieces and its own goals, minus two.

## Decisions (2026-10-17)

Santtu approved the design with these answers:

1. **Kick-off:** on the clock (210 s) or on reaching the gate, whichever
   comes first.
2. **Kits:** home shirts in blue and claret halves, no chest panel. Away
   fans in orange and slate. Flags carry a plain white star.
3. **The roar:** SCARED, or ZOOMIES when she is right beside her human.
4. **The result:** seeded, and it changes the walk home. A win is a
   jubilant surge, a loss a quiet, easy walk, a draw in between.

Defaults taken on the rest:

5. **Horses:** solid bodies the rope does not wrap, for now.
6. **Tofu:** left out of this walk.
7. **Goals:** twelve, no thirteenth.
8. **Name on the ground:** sunflower seed shells.
9. **Signage:** no beer signage anywhere. The bar is a generic bar terrace
   and the cart sells water and soda.
10. **Names:** naming Les Corts and the Travessera is fine; the stadium and
    the club are never named.
11. **Pairing:** El Diluvi (#152).
12. **Unlock:** 27 stars, after Montjuïc.
