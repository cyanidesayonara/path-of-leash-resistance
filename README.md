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
lamppost to hold them fast, and bark to stop them dead at the kerb. Wind
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
  ("ring ring", "selfie!", "ooh!") and is never smarter than that.
- **Fourteen walks through Barcelona**, each built as its own place, plus a
  first walk that teaches one trick at a time and a daily walk that is the
  same for everyone that day.
- **Off the leash at the end**: a dog park, a dog beach, a clearing in the
  woods, a yard, or a plaça with a fountain to jump in.
- **Goals on every walk**, stars that unlock the next walk, and bones to
  spend on collars, bandanas and coats.
- **Combo tricks**: vaulting round a pole, grinding along a kerb, near misses.
- **One chase**: a street sweeper careens down a back street at dawn, and you
  drag your oblivious human home ahead of it.
- **Moods**: a fright, a bark-off or a run off the leash leaves her jumpy,
  barky, full of zoomies or flat, and each changes how she moves.
- **Ground you can feel**: grass and mud slow her but hold scent, sand drags
  at her paws, wet ground and snow make her skid.
- **Weather and night**: rain, wind and snow on any walk, with everyone
  dressed for it.
- **Other dogs with lives of their own**: they sniff and mark the posts you
  pass, and stop to sniff you back, unless they are the grumpy sort.
- No ads, no purchases, no account. Plays offline.

## The walks

| Walk | |
|---|---|
| El Barri | the neighbourhood park |
| La Rambla | the crowded promenade |
| El Parc | the city park |
| Passeig Marítim | the seafront |
| El Diluvi | the downpour |
| El Mercat | the market hall |
| El Gòtic | the old town alleys |
| El Bosc | the forest |
| L'Estació | the railway station |
| Les Obres | the roadworks |
| La Castanyada | the chestnut festival |
| La Ferralla | the scrapyard |
| El Mosaic | the tiled terraces |
| La Neteja | the dawn clean-up |

## Controls

Keyboard, controller or touch. The on-screen prompts show the buttons of
whatever you used last.

| Action | Keyboard | Controller |
|---|---|---|
| Move | WASD or arrows | left stick |
| Dig in (hold): brace against the leash, and squat when nature calls | Space | A |
| Mark a spot (hold) | Q | X |
| Bark: stops your human for a beat, scares off squirrels | E | B |
| Run | Shift | RB |
| Goals | Tab | d-pad up |
| Pause | Esc | Back |
| Start again | R | Start |

On a phone or tablet: a stick on the left, DIG, PEE, BARK and RUN on the
right, and MENU at the top.

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

Releasing is a tag: `git tag v1.58 && git push --tags` builds web and Windows
and pushes each to its own itch channel. AGENTS.md has the rest: tests,
screenshots and benchmarks.

## Documentation

- `PROJECT.md`: design pillars and roadmap
- `AGENTS.md`: technical map and conventions, for people and agents alike
- `CHANGELOG.md`: session history, newest first

## Credits

Made by Santtu Nykänen. The default dog is Millie, a distinguished
salt-and-pepper mutt who squats like a lady.

All rights reserved. The source is public for reading and learning; the game
itself is a commercial work.
