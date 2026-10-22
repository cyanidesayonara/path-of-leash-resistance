# Walk polish audit

Recorded 2026-10-19, before El Besòs. Evidence for the sixteen campaign
walks that existed then. A finding is blocking, clearly rough, or
subjective. Subjective findings stay recorded and unchanged until Santtu
plays them.

El Besòs was checked on 2026-10-22 (selftest, autowalk, freedom bounds,
terrain, and a desktop mid-walk shot). That pass is in the changelog, not
in these entries. The two rough findings below were fixed before the 1.62
tag: #264 (Montjuïc hill rim) and #265 (march droppings).

Scripted play is one turbo run out and back, about 75 seconds, logged by
`tools/playtest.gd`. A walk that ends still on the way out ran out of
script, which is not a stuck actor.

## barri

- Inventory: El Barri, 480 wide, straight, gate PIPICÀ, off-leash yard. 155 poles, 14 trees, 7 benches, a fountain, 18 park props. One sand patch. Goals: mark, sniff, phone, paws, bag, fetch, tofu, hi, drink, combo, prize. No authored cross-section.
- Shots: `C:/tmp/walk-audit-shots/walk-barri.png`. EL BARRI reads.
- Play: no stuck dog, human, or person in a solid. Ended home.
- Findings: no finding

## street

- Inventory: La Rambla, 680 wide, bends, gate PIPICÀ, off-leash yard. 390 poles, 14 trees, 8 stalls, café tables and chairs, 3 crossings, 3 cellars. One ice-cream patch. Goals add thief, wallet, fling and carry.
- Shots: `walk-street.png`. LA RAMBLA reads at frame 45. By the default frame 320 the flowers have a gap through the middle, which is the pieces being walked through.
- Play: no stuck actor. Ended still on the way out, dog at y=-3397. The script ran out before the gate.
- Findings: no finding

## park

- Inventory: El Parc, 460 wide, bends, gate PIPICÀ, off-leash yard. 139 poles, 14 trees, a pond, ducks, 16 park props. One sand patch. Goals add hi and drink. No authored cross-section.
- Shots: `walk-park.png`. EL PARC reads; the flowerbed springs back.
- Play: no stuck actor. Ended home.
- Findings: no finding

## beach

- Inventory: Passeig Marítim, 420 wide, straight, gate PLATJA DELS GOSSOS, off-leash beach. 145 poles, 29 palms, 5 towels, a terrace of tables. Six sand patches. Goals add snack and save. No authored cross-section.
- Shots: `walk-beach.png` is frame 320, after the shells have been walked through. `beach-f45.png` and `beach-f120.png` still read PASSEIG MARÍTIM.
- Play: no stuck actor. Ended home.
- Findings: no finding

## rain

- Inventory: El Diluvi, 460 wide, straight, gate EL PORXO, off-leash yard. 57 poles, 14 trees, 8 puddles, 2 crossings. Goals add dry and splash.
- Shots: `walk-rain.png`. EL DILUVI reads; the puddles are fixed.
- Play: no stuck actor. Ended home.
- Findings: no finding

## market

- Inventory: El Mercat, 540 wide, bends, gate PLAÇA, off-leash plaça. 340 poles, 10 stalls, 2 fish patches, 2 puddles. Goals add snack, zoom and carry.
- Shots: `walk-market.png` is after the fruit has been walked through. `market-f45.png` reads EL MERCAT. The yard is PLAÇA DELS GOSSOS, the name those squares were given.
- Play: no stuck actor. Ended back past the start, still on the way out.
- Findings: no finding

## oldtown

- Inventory: El Gòtic, 450 wide, bends, gate PLAÇA, off-leash plaça. 54 poles, 6 wall cats, 5 laundry lines, 9 trees. Goals add cats and snack.
- Shots: `walk-oldtown.png`. The painted EL GÒTIC sign reads.
- Play: no stuck actor. Ended back past the start, still on the way out.
- Findings: no finding

## trail

- Inventory: El Bosc, 400 wide, bends, gate LA CLARIANA, off-leash clearing. 90 poles, 24 trees, 9 mud patches, no signal. Goals add chase and drink. No authored cross-section.
- Shots: `walk-trail.png` is after the sticks have been walked through. `trail-f45.png` reads EL BOSC.
- Play: no stuck actor. Ended home.
- Findings: no finding

## station

- Inventory: L'Estació, 780 wide, bends, gate PIPICÀ, off-leash yard. 452 poles, 14 trees, 2 vans, a moving walkway. Goals add walkway and snack.
- Shots: `walk-station.png`. The painted L'ESTACIÓ sign reads.
- Play: no stuck actor. Ended home.
- Findings: no finding

## site

- Inventory: Les Obres, 590 wide, bends, gate EL SOLAR, off-leash lot. 66 poles, 12 cone spots, 2 cellars, 2 crossings. Goals add close and snack.
- Shots: `walk-site.png`. LES OBRES is cones laid as the name, and they scatter once walked through.
- Play: no stuck actor. Ended home.
- Findings: no finding

## spook

- Inventory: La Castanyada, 550 wide, bends, gate PLAÇA, off-leash plaça. 329 poles, 11 stalls, 9 candy spots. Goals add tummy and snack.
- Shots: `walk-spook.png`. The chestnuts scatter once walked through. The yard is PLAÇA DELS GOSSOS.
- Play: no stuck actor. Ended home.
- Findings: no finding

## scrap

- Inventory: La Ferralla, 500 wide, bends, gate EL PATI, off-leash lot. 380 poles, 10 vans, 4 guard posts, 2 cameras, 2 lasers, 5 oil patches. Goals add ghost and unseen.
- Shots: `walk-scrap.png`. The plates scatter once walked through.
- Play: no stuck actor. Ended home.
- Findings: no finding

## guell

- Inventory: El Mosaic, 600 wide, bends, gate EL CALVARI, off-leash clearing. 111 poles, 24 trees, 16 park props. Goals add hi, drink and fling.
- Shots: `walk-guell.png`. EL MOSAIC reads; the tiles are fixed.
- Play: no stuck actor. Ended home.
- Findings: no finding

## neteja

- Inventory: La Neteja, 370 wide, straight, gate PLAÇA, off-leash plaça. 160 poles, 8 kebabs, 10 cone spots, 5 laundry lines, 5 puddles, a chase. Goals add hi, snack and outrun. No tofu goal.
- Shots: `walk-neteja.png`. LA NETEJA reads. The yard is PLAÇA DELS GOSSOS.
- Play: no stuck actor. Ended home.
- Findings: no finding

## montjuic

- Inventory: Montjuïc, 350 wide, bends, gate EL CASTELL, off-leash plaça. 112 poles, 9 trees, 3 benches, a moving walkway. Goals add hi, drink and cable. No authored cross-section.
- Shots: `walk-montjuic.png`. The painted MONTJUÏC sign reads. `yard-montjuic.png` is the esplanade, signed L'ESPLANADA.
- Play: no stuck actor. Ended home. The log is thousands of `p_points.size() < 2` from the hill rim once the camera is north of the gate.
- Findings: clearly rough. `Montjuic.draw_hill` builds a rim with fewer than two points when the view does not include the climb. Disposition: #264.

## partit

- Inventory: Dia de Partit, 800 wide, bends, gate PLAÇA DEL GOL, off-leash plaça. 393 poles, 9 trees, a terrace of tables, 2 fountains. Goals: mark, sniff, phone, paws, bag, fetch, snack, march, scarf, kickabout, fulltime, prize. No tofu, hi or combo.
- Shots: `walk-partit.png`. The shells read at the start and are kicked once your human walks through them.
- Play: no stuck actor. Reached full time and home. Every frame of the draw logged `Invalid access to property or key 'stinky'`.
- Findings: clearly rough. The march leaves horse droppings as substance `stinky`, and `SUBSTANCES` has no such kind, so the world draw fails while they are on the ground. Disposition: #265.

## Queue

Fourteen walks had no finding. Two were clearly rough. Nothing in this pass was blocking, and nothing was left as subjective. Both rough findings are merged.

1. Fixed, #264. Montjuïc. The esplanade asked `draw_hill` for a rim with fewer than two points.
2. Fixed, #265. Dia de Partit. The march droppings used `stinky`, which was not in `SUBSTANCES`.

The loose place-names are not a defect. At frame 45, PASSEIG MARÍTIM, EL MERCAT, EL BOSC and LA RAMBLA all read. The default sweep frame is 320, which is after your human has walked through the letters. Scattering them is what those pieces are for. `PLAÇA DELS GOSSOS` on the town squares is the name those yards were given, not the beach's `PLATJA DELS GOSSOS`.
