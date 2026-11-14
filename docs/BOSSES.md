# The statue bosses

Four of the campaign's 41 walks are boss walks, at 11, 21, 31 and 41 (docs/ROADMAP.md).
Each boss is a statue of an animal that really stands in Barcelona, in public-domain
art only, waking up because a dog went past. They share one grammar, so a player who
has fought one knows how to read the next. Each one has its own signature moves and
its own way of fighting, and its own wake film.

| Walk | Boss | Where | Status |
|---|---|---|---|
| 11 | El Mamut, the stone mammoth (1907) | La Ciutadella, by the boating lake | 1.72 |
| 21 | El Drac, the mosaic dragon of the Park Güell steps | El Mosaic | 1.73 |
| 31 | Els Lleons, the bronze lions at the foot of the Columbus column (1888) | El Port | 1.73 |
| 41 | El Gat, the Raval's fat bronze cat | Rambla del Raval | shipped |

Only the stone, bronze and tile of the real statues are drawn, as cartoons of our own:
never a copy of a modern copyrighted sculpture.

## The shared grammar

1. **The wake film.** It plays the first time she passes the statue, in FilmKit's
   grammar: walking, she hears it, looks back, it wakes and gets down, she plants
   herself between it and your human, and the name card slams in. Then the walk's own
   wake: a crack, a roar or trumpet, the hop down, and a title card across the top
   (place, then name, then a gloss).
2. **Your human waits.** They will not walk past it (`tut_hold_y`, with a line like
   "Not past that cat."). The autowalk bot is never held and the boss is a ghost to
   it. Nothing else of the walk stops.
3. **Three parts.**
   - **Part one:** the boss's two basic attacks, each telegraphed about 0.85 s ahead
     (a filling ring, a lane or a sector drawn on the ground), as every hazard to the
     pair is. A near miss wears it down.
   - **Part two:** below half health it roars, its eyes go red and it adds its big
     move. This is where the counters that do real damage live.
   - **Part three, the last stand:** out of fight, it goes back to its plinth and
     still attacks while she ties it up: the leash round three of its four legs
     within a second and a half. It teeters and goes down. A bark on its nose settles
     it, to the crowd's cheers. Then a victory beat, and your human walks on.
4. **The same counters, each re-skinned:**
   - **Dodge:** a telegraphed attack that misses costs it health.
   - **Trip:** a taut leash across its path.
   - **Steer it into the place:** lure the big move into something of the walk's
     own, such as a palm, the lake or a column.
   - **Bowling:** your human flung into it by a whirl.
   - **Boop:** bark on its nose while it is dazed.
5. **The banner** always says what to do right now, in capitals
   ("WATCH THE TRUNK!", "TIE UP HIS LEGS  2/3"). The goals reward each counter.
6. **The look of the fight:** dust rings, chips of its material, slow motion on
   the big hits, the onlookers gasping and cheering, the camera leaning toward it.

## Each one's own style

### El Mamut (La Ciutadella): heavy, slow, wide

He fights with reach and weight, not speed. The danger is the area he covers.
- **Trunk swipe:** a wide arc in front of him, drawn as a sector of the ground
  filling. Get out of the sector or behind something solid.
- **Stomp:** he rears and lands, and a shockwave ring rolls outward. Be beyond it
  when it lands, or be in the air.
- **Part two, the tusk charge:** he paws the gravel, a lane appears, and he charges.
  Into the boating lake, he goes in up to his knees: SPLASH, a long daze and heavy
  damage. Into a plane tree, he bonks. Across a taut leash, he trips.
- **Trunk spray:** after a splash he comes up spraying lake water down a lane.
- **Last stand:** on his plinth by the lake, swiping. Three legs tied and he sits
  down hard. A boop on the trunk, and he trumpets a fountain with a rainbow in it.
- **Film:** the lake at morning, the rowing boats. The mammoth's ear twitches, he
  lifts his trunk and trumpets, then steps down. The boats rock.

### El Drac (El Mosaic): quick, low, slippery

A tiled dragon who moves like water, because he is a fountain.
- **Tail whip:** a fast arc behind him, so never stand at his back.
- **Fountain jet:** he spits a jet down a lane, which pushes and soaks.
- **Part two, the slither:** he races in an S along the hall of columns and sheds
  loose tile chips as he goes, slippery ground for a few seconds. Steer him round a
  column with the leash and he winds himself up.
- **Last stand:** on his steps, spitting. Three legs tied and he slides down the
  steps on his belly. A boop, and he fountains happily again.
- **Film:** the steps at noon, tourists. The water stops, the tiles ripple, an eye
  opens.

### Els Lleons (El Port): two at once, taking turns

A pair, so the fight is about where both of them are.
- **Pincer:** one circles wide to her far side while the other stalks in: two
  lanes close on her from either side. Step out late and they meet each other.
- **Roar:** a cone of wind that pushes her back, toward the other lion.
- **Part two, the double rush:** both rush with crossing lanes. Stand where the
  lanes cross and step out: they collide (HEAD BUMP, both dazed).
- **Last stand:** both back on their plinth corners. Tie the leash round a leg of
  each and they sit. A boop on each nose.
- **Film:** the harbour at dusk under the column. One lion yawns, the other blinks,
  and they look at each other, then at her.

### El Gat (Rambla del Raval): the finale, an ambush from above

A cat does not charge. He fights like a cat: still, then all at once.
- **Paw swat:** a ring fills where the paw will land (shipped).
- **Part two, the pounce (#504, replacing the charge):** he crouches
  low and wiggles his rear, a landing ring fills where she stands, and he leaps.
  He comes down on a taut leash and is tangled in it. He comes down on a
  terrace table and crashes through it, dazed. A miss leaves him skidding.
- **Bowling, the boop and the last stand** as shipped: three legs tied on his
  plinth, then the boop, then the plinth film.

The mammoth is the one who charges; no two bosses share a big move.
