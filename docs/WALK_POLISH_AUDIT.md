# Walk polish audit

Target: v1.62. Evidence for the sixteen campaign walks. A finding is
blocking, clearly rough, or subjective. Subjective findings stay recorded
and unchanged until Santtu plays them.

## barri

- Inventory: El Barri, 480 wide, straight, gate PIPICÀ, off-leash yard. 155 poles, 14 trees, 7 benches, a fountain, 18 park props. One sand patch. Goals: mark, sniff, phone, paws, bag, fetch, tofu, hi, drink, combo, prize. No authored cross-section.
- Shots: `C:/tmp/walk-audit-shots/walk-barri.png`. EL BARRI reads.
- Play: pending
- Findings: no opening-name defect. Yard and home shots are in `C:/tmp/walk-audit-shots/`.

## street

- Inventory: La Rambla, 680 wide, bends, gate PIPICÀ, off-leash yard. 390 poles, 14 trees, 8 stalls, café tables and chairs, 3 crossings, 3 cellars. One ice-cream patch. Goals add thief, wallet, fling and carry.
- Shots: `walk-street.png` reads LA RAMBLA. `street-844x390.png` has kicked a gap through the middle of the flowers.
- Play: pending
- Findings: see the shared opening-name finding. Yard and home shots are in `C:/tmp/walk-audit-shots/`.

## park

- Inventory: El Parc, 460 wide, bends, gate PIPICÀ, off-leash yard. 139 poles, 14 trees, a pond, ducks, 16 park props. One sand patch. Goals add hi and drink. No authored cross-section.
- Shots: `walk-park.png`. EL PARC reads; the flowerbed springs back.
- Play: pending
- Findings: no opening-name defect

## beach

- Inventory: Passeig Marítim, 420 wide, straight, gate PLATJA DELS GOSSOS, off-leash beach. 145 poles, 29 palms, 5 towels, a terrace of tables. Six sand patches. Goals add snack and save. No authored cross-section.
- Shots: `walk-beach.png`. PASSEIG MARÍTIM is scuffed apart and does not read.
- Play: pending
- Findings: see the shared opening-name finding

## rain

- Inventory: El Diluvi, 460 wide, straight, gate EL PORXO, off-leash yard. 57 poles, 14 trees, 8 puddles, 2 crossings. Goals add dry and splash.
- Shots: `walk-rain.png`. EL DILUVI reads; the puddles are fixed.
- Play: pending
- Findings: no opening-name defect

## market

- Inventory: El Mercat, 540 wide, bends, gate PLAÇA, off-leash plaça. 340 poles, 10 stalls, 2 fish patches, 2 puddles. Goals add snack, zoom and carry.
- Shots: `walk-market.png`. EL MERCAT's fruit has rolled out of the letters.
- Play: pending
- Findings: see the shared opening-name finding

## oldtown

- Inventory: El Gòtic, 450 wide, bends, gate PLAÇA, off-leash plaça. 54 poles, 6 wall cats, 5 laundry lines, 9 trees. Goals add cats and snack.
- Shots: `walk-oldtown.png`. The painted EL GÒTIC sign reads.
- Play: pending
- Findings: no opening-name defect

## trail

- Inventory: El Bosc, 400 wide, bends, gate LA CLARIANA, off-leash clearing. 90 poles, 24 trees, 9 mud patches, no signal. Goals add chase and drink. No authored cross-section.
- Shots: `walk-trail.png`. EL BOSC's sticks are kicked off the letters.
- Play: pending
- Findings: see the shared opening-name finding

## station

- Inventory: L'Estació, 780 wide, bends, gate PIPICÀ, off-leash yard. 452 poles, 14 trees, 2 vans, a moving walkway. Goals add walkway and snack.
- Shots: `walk-station.png`. The painted L'ESTACIÓ sign reads.
- Play: pending
- Findings: no opening-name defect

## site

- Inventory: Les Obres, 590 wide, bends, gate EL SOLAR, off-leash lot. 66 poles, 12 cone spots, 2 cellars, 2 crossings. Goals add close and snack.
- Shots: `walk-site.png`. LES OBRES is a scatter of cones, not a name.
- Play: pending
- Findings: see the shared opening-name finding

## spook

- Inventory: La Castanyada, 550 wide, bends, gate PLAÇA, off-leash plaça. 329 poles, 11 stalls, 9 candy spots. Goals add tummy and snack.
- Shots: `walk-spook.png`. LA CASTANYADA's chestnuts have rolled out of the word.
- Play: pending
- Findings: see the shared opening-name finding

## scrap

- Inventory: La Ferralla, 500 wide, bends, gate EL PATI, off-leash lot. 380 poles, 10 vans, 4 guard posts, 2 cameras, 2 lasers, 5 oil patches. Goals add ghost and unseen.
- Shots: `walk-scrap.png`. LA FERRALLA's plates are kicked off the letters.
- Play: pending
- Findings: see the shared opening-name finding

## guell

- Inventory: El Mosaic, 600 wide, bends, gate EL CALVARI, off-leash clearing. 111 poles, 24 trees, 16 park props. Goals add hi, drink and fling.
- Shots: `walk-guell.png`. EL MOSAIC reads; the tiles are fixed.
- Play: pending
- Findings: no opening-name defect

## neteja

- Inventory: La Neteja, 370 wide, straight, gate PLAÇA, off-leash plaça. 160 poles, 8 kebabs, 10 cone spots, 5 laundry lines, 5 puddles, a chase. Goals add hi, snack and outrun. No tofu goal.
- Shots: `walk-neteja.png`. LA NETEJA reads.
- Play: pending
- Findings: no opening-name defect

## montjuic

- Inventory: Montjuïc, 350 wide, bends, gate EL CASTELL, off-leash plaça. 112 poles, 9 trees, 3 benches, a moving walkway. Goals add hi, drink and cable. No authored cross-section.
- Shots: `walk-montjuic.png`. The painted MONTJUÏC sign reads. `yard-montjuic.png` is the esplanade, signed L'ESPLANADA.
- Play: pending
- Findings: with the camera north of the gate, `Montjuic.draw_hill` asks for a polyline with fewer than two points (`systems/montjuic.gd` around line 700). The esplanade shot itself still reads. The error repeated through that shot.

## partit

- Inventory: Dia de Partit, 800 wide, bends, gate PLAÇA DEL GOL, off-leash plaça. 393 poles, 9 trees, a terrace of tables, 2 fountains. Goals: mark, sniff, phone, paws, bag, fetch, snack, march, scarf, kickabout, fulltime, prize. No tofu, hi or combo.
- Shots: `walk-partit.png`. The shells read at the start and are kicked once your human walks through them.
- Play: the scripted pass reached full time and home with no stuck actor. Every frame of the draw logged `Invalid access to property or key 'stinky'`.
- Findings: the march drops horse leavings as substance `stinky`, and `SUBSTANCES` has no such kind, so the world draw fails while those leavings are on the ground.

## Queue

Scripted play of all sixteen walks reported no stuck dog, no stuck human, and no person inside a solid.

1. Open, in #264. Montjuïc's esplanade asks `draw_hill` for a rim with fewer than two points.
2. Open. Dia de Partit's march droppings use `stinky`, which is not in `SUBSTANCES`. The draw errors on every frame they exist.

The loose place-names are not a defect. At frame 45, PASSEIG MARÍTIM, EL MERCAT, EL BOSC and LA RAMBLA all read. The default sweep frame is 320, which is after your human has walked through the letters. Scattering them is what those pieces are for. `PLAÇA DELS GOSSOS` on the town squares is the name those yards were given, not the beach's `PLATJA DELS GOSSOS`.
