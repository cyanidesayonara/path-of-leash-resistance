# Path of Leash Resistance

A top-down physics comedy about a dog walk. You play the dog. Your human is
glued to their phone and walking on autopilot, and the only thing between
them and the bike lane is you, on the other end of a leash. Get them home
with the phone in one piece, and sneak in as much dog business on the way as
you can get away with.

Play it in the browser or download it for Windows on
[itch.io](https://cyanidesayonara.itch.io/path-of-leash-resistance), or get
it from the [Microsoft Store](https://apps.microsoft.com/detail/9p5d14v8rbqx).

## What you do

Your human is four times your weight and wins every straight tug. So you win
the way a dog does: dig in at the right moment, wind the leash round a
lamppost to hold them fast, and bark to stop them dead at the curb. Wind
them round a pole and keep pulling, and they whirl off the coil like a
tetherball. In between there are posts to sniff, spots to mark, balls to
fetch, other dogs to meet and squirrels you will never catch.

Your human answers the leash like a person. A steady pull leads them where
you want to go; constant hauling wears their patience down until they say
"HEY!" and cut the leash short. Walk nicely and the reel lets you out.

## Features

- **The leash is real rope.** The one you see is the one doing the physics:
  it wraps poles, cinches when taut, slips off under a hard wrench, and
  tangles with other people's leashes.
- **A human with patience**, who telegraphs everything they are about to do
  ("Ring ring!", "Ooh!") and is never smarter than that.
- **Thirty-six walks in and around Barcelona**, each built as its own place, plus a
  first walk that teaches one trick at a time. Every walk can be played in
  any weather, by day or at night.
- **Off the leash at the end**: a dog park, a dog beach, a clearing in the
  woods, a yard, or a plaça with a fountain to jump in.
- **Goals on every walk**, stars that unlock the next walk, and bones to
  spend on collars, bandanas and coats.
- **Combo tricks**: swing around a pole, grind a ledge, fling your human,
  near misses.
- **Dares**: a dare-giver on every walk, each with their own tune. Bark to
  take a dare, then land the tricks before the music runs out.
- **Six chases.** A street sweeper careens down a back street at dawn, and
  you drag your oblivious human home ahead of it. On El Besòs the river
  comes home with you, in El Veterinari you bolt from the vet's, wild boars
  come down Els Senglars after you, the correfoc's fire devils chase
  you through Gràcia, and the Dimoni's rolling firework float pursues you in
  La Cremada.
- **Five dogs**, each with a knack of their own, opened with stars, and bones
  to train them.
- **Two statue bosses**: El Mamut the stone mammoth in La Ciutadella, and on
  the Rambla del Raval, El Gat, a fat bronze cat who climbs off his plinth.
- **Moods**: a fright, a bark-off or a run off the leash leaves her jumpy,
  barky, full of zoomies or flat, and each changes how she moves.
- **Ground you can feel**: grass and mud slow her but hold scent, sand drags
  at her paws, wet ground and snow make her skid.
- **Weather and night**: rain, wind and snow on any walk, with everyone
  dressed for it.
- **Other dogs with lives of their own**: they sniff and mark the posts you
  pass and come over to say hello, unless they are the grumpy sort, who
  lunge and bark at the end of the leash. Their owners are people too: on a
  call, carrying a coffee, stopping to type, watching your dog go by.
- No ads, no purchases, no account. Plays offline.

## The walks

| Walk | |
|---|---|
| El Barri | the neighborhood park |
| La Rambla | the crowded promenade |
| El Parc | the city park |
| Passeig Marítim | Badalona's seafront |
| La Neteja | the dawn cleanup |
| El Gòtic | the old town alleys |
| Montjuïc | the climb |
| El Mercat | the market hall |
| El Diluvi | the downpour |
| El Besòs | the river park |
| La Ciutadella | the waterfall cascade and El Mamut |
| Platja de Llevant | the dog beach at the far end of the coast |
| L'Eixample | the grid of cut corners round the basilica |
| El Tibidabo | the mountain road |
| El Veterinari | the clinic escape |
| El Bosc | the forest |
| Els Àngels | the skate plaza |
| La Castanyada | the chestnut festival |
| Els Senglars | the wild boar trail |
| El Mosaic | the tiled terraces |
| La Superilla | the superblock play streets |
| L'Estació | the train station |
| Els Búnquers | the overlook above the city |
| Plaça Reial | the arcaded square |
| La Cremada | Badalona's devil night and the Dimoni float |
| El Fòrum | the seaside esplanade |
| La Carretera de les Aigües | the hillside hike |
| El Laberint d'Horta | the cypress maze |
| El Port | the fishing wharf |
| Plaça d'Espanya | the fountain avenue |
| El Poble Espanyol | the walled village of copied towns |
| Les Obres | the work site |
| Dia de Partit | match day |
| La Ferralla | the junkyard |
| Festa de Gràcia | the decorated festival street |
| Rambla del Raval | the finale, with El Gat, a bronze cat |

## Controls

Keyboard, controller or touch. The on-screen prompts show the buttons of
whatever you used last.

| Action | Keyboard | Controller |
|---|---|---|
| Move | WASD or arrows | left stick |
| Dig in (hold): brace against the leash | Space | A |
| Mark a spot (hold) | Q | X |
| Squat when nature calls (hold) | F | Y |
| Pick up | G | LB |
| Bark: stops your human for a beat, scares off squirrels | E | B |
| Run | Shift | RB |
| Goals | Tab | d-pad up |
| Pause | Esc | Back |
| Start again | R | Start |

On a phone or tablet: a stick on the left, DIG, PEE, BARK and RUN on the
right (PEE says POOP when nature calls, and GRAB comes up beside them when
there is something to pick up), and MENU at the top.

## Building and running

Godot 4.7, GDScript only. A portable editor lives in `godot/` locally
(gitignored); get it from https://godotengine.org/download.

Run:
```
godot\Godot_v4.7-stable_win64.exe --path .
```

Headless smoke test (what CI runs):
```
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 1800
```

Web export (needs the web export templates, see AGENTS.md):
```
godot\Godot_v4.7-stable_win64_console.exe --headless --path . --export-release "Web" build/web/index.html
```

Releasing is a tag. v1.71 is the last one. The next tag builds web and
Windows and pushes each to its own itch channel. AGENTS.md has the rest:
tests, screenshots and benchmarks.

## Documentation

- `PROJECT.md`: design pillars and roadmap
- `AGENTS.md`: technical map and conventions, for people and agents alike
- `CHANGELOG.md`: session history, newest first

## Credits

Made by Santtu Nykänen. The default dog is Millie, a distinguished
salt-and-pepper mutt who squats like a lady.

All rights reserved. The source is public for reading and learning; the game
itself is a commercial work.
