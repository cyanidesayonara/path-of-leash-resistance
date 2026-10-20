# v1.62 — El Besòs and Better Arrivals

Approved by Santtu, 2026-10-20.

## Purpose

v1.62 adds El Besòs as the second authored chase walk and raises the
presentation standard across the game. The release proves that La Neteja's
round-trip chase foundation supports a threat that is not a vehicle, gives
every walk a readable ending place, and audits all seventeen walks against the
same quality bar.

The release has four player-facing groups:

1. shared chase framing, fear onset, catch animation and a redrawn sweeper;
2. apartment, transit and safe-exit arrival places;
3. El Besòs, its flood, and the shared current used by El Bosc;
4. scoped fixes from the seventeen-walk audit.

They land sequentially so no more than five changes wait for hand acceptance.

## Real place and fiction

The walk is the public-use stretch of Parc Fluvial del Besòs: an accessible
park built inside the floodable river channel. Its broad grass, paved
pedestrian and cycle route, concrete flood walls, access ramps, river gauges,
bridges and inflatable weirs are the level's visual language.

The real SAHBE hydrological warning system monitors weather and water levels.
The park's entrances have electronic signs; optical and acoustic warnings
repeat along both walls; public-use staff travel by bicycle; and the park is
evacuated and closed when flooding is imminent. Inflatable weirs are deflated
to restore hydraulic capacity. The game compresses the timescale, not the
logic: the warning system activates before the water arrives and points people
to the exits.

The playable route avoids the protected river mouth. It starts by the railway
bridge in Sant Adrià and runs upstream to a broad meadow near Pont de Can
Peixauet. The destination sign is:

    PRAT DEL BESÒS
    RIVER MEADOW

## Progression and special-walk cadence

The internal id is `besos`. It sits between L'Estació and Les Obres in the
campaign carousel and unlocks at 14 stars. Every existing star gate remains
unchanged, so an existing save never loses access to a walk.

El Besòs and La Neteja are separated by Les Obres, La Castanyada, La Ferralla
and El Mosaic. Future chase and boss walks use the same rule: at least four
ordinary walks between major special setpieces, and never a boss directly
beside a chase.

## The walk out

The level is a clear, warm afternoon. The flood can originate upstream without
local rain, which keeps El Diluvi visually distinct and makes the alert feel
uncanny.

The corridor is asymmetric:

- concrete flood wall, warning equipment and access ramps;
- a paved walking and cycle route;
- a broad usable strip of grass;
- the low-water river along the opposite edge.

The calm leg teaches the place before changing it. Repeating lamps, an OPEN
entrance board, gauges and the inflatable weir establish the warning system.
Sparse runners and bicycles use the paved lane. Bridge shadows, one reedier
stretch and the cable-stayed destination bridge break up the long view.
Hydrants are replaced by suitable markable lamps, signs and bridge supports.
Safe edge points may be sniffed, but no goal encourages entering the river.

The destination is the usual off-leash reward in a broad river meadow.

## Warning and head start

Leaving the destination for home captures the destination checkpoint. Then:

1. warning lamps flash in sequence down the walls;
2. a bicycle ranger clears people toward the access ramps;
3. the entrance board changes to an emergency closure message;
4. the evacuation announcement and siren sound;
5. your human initially assumes it is somebody else's problem;
6. the shared chase warning and three-second head start run.

The flood cannot move, catch or create fear during the warning or head start.

## The flood home

The flood comes from upstream, behind the southbound pair.

The leading shallow water is pale, visibly directional and recoverable. It
pushes both bodies south, reduces steering and wets them. Planting resists the
current and moving with it helps. The leash remains the real constraint.

The deep front follows behind. It is darker, louder, foam-edged and is the
actual loss boundary. It also swells laterally from the river edge so the
comfortable route narrows without invisible walls. Floating branches, balls
and light park litter reveal direction before the water reaches the player.
Large debris is sparse, telegraphed, and never seals the whole escape lane or
spawns on either body.

A raised maintenance apron at the midpoint makes the second checkpoint
physical. The flood splits around it and is held there for the three-second
continue countdown, then spills across immediately. An unsafe checkpoint
keeps the destination snapshot under the same rules as La Neteja.

The final run climbs an emergency access ramp. Reaching the upper boundary
ends the chase; the water stays below in the channel.

Any home-leg loss with a checkpoint held offers continue. Restoration replaces
the checkpoint state exactly and never pays a pickup, goal or reward twice.

## Flood goals

El Besòs has the familiar mark, sniff, phone, paws, bag, fetch, Tofu, combo and
prize goals, plus:

- Keep the flood a leash length away.
- Get your human home less than half soaked.

No goal rewards touching deep water or delaying inside the flood.

## Chase-only camera framing

The existing `chase_lean` remains the single camera mechanism. It is tuned to
shift the camera north earlier and more strongly as a threat approaches,
placing the pair lower in the frame and exposing the threat behind them.
Ordinary walks and non-chase legs remain pixel-identical.

Before final values are chosen, deterministic captures compare current,
moderate and strong curves at desktop, landscape-phone and portrait framing.
The selected curve must show the threat before fear begins while retaining
enough southern runway to steer. It eases at warning, checkpoint, continue and
release; it never snaps.

SCARED intensity still depends on distance, but charge cannot begin until the
threat's visible boundary enters the usable viewport. Warning, head start and
checkpoint holds are fear-free; existing fear decays naturally.

This visibility rule belongs to the shared chase profile and applies to the
sweeper, flood and future scary-dog threats.

## Catch presentation

The existing catch delay becomes an authored deterministic beat. Ordinary
motor intent is disabled during it, but frame order and leash physics remain
honest.

For the sweeper, the brushes scoop the first body to cross the line. The leash
response pulls the other into a quick tumble. Both land sprawled in the wake;
only then does the loss card appear.

For the flood, shallow contact remains recoverable. Deep contact stumbles the
first body and carries both into foam before the card.

Dog-first and human-first catches are both covered. A continue begins only
after the card and clears every catch visual and one-shot.

## Sweeper redesign

La Neteja's machine keeps its compact municipal silhouette but gains a clearer
cab and glass, lamps, wheels, articulated broom arms, visibly spinning
bristles, grime wake and contact shadow. The brushes define the gameplay line
that catches the pair.

The drawing stays allocation-free in its frame loop, uses `ShapeBatch`, adds no
draw calls and is measured in the web build against the pre-1.62 baseline.

## Better arrivals

The loose HOME letters are removed. Every level declares one of three finish
families, all driven by one arrival state:

### Apartment

The default for the First Walk, El Barri, La Rambla, El Parc, Passeig Marítim,
El Diluvi, El Mercat, El Gòtic, Les Obres, La Castanyada, La Ferralla,
El Mosaic and La Neteja.

It is the exterior established by the intro: green Barcelona street door,
shutters, geraniums, tiled threshold, intercom and warm hall light. Weather and
time dress it without changing its identity.

### Transit

L'Estació uses a station entrance, Montjuïc the funicular and Dia de Partit the
metro. They share stairs, railings, canopy and descent animation; signs and
paving identify the place.

### Safe exit

El Bosc uses its trailhead gate. El Besòs uses the emergency ramp out of the
channel.

### Arrival contract

Crossing the safe threshold starts a short arrival instead of showing results
immediately. The threat stops at safety. Millie pulls toward the exit; your
human looks up and pockets the phone; Millie enters first; your human follows;
the leash passes through the aperture; then results appear.

The readable opening half-second may be skipped. Automated tests advance the
state deterministically. Rain leaves wet pawprints, night uses the entrance
light and snow gathers at the sill. Starting a walk closes the apartment door
behind the pair. Every aperture is clear of generated props and collision.

## Shared current and El Bosc

Current is a small shared rule rather than Besòs-only physics. It acts on dog,
human and carried loose objects with consistent direction and strength.
Planting resists it.

El Bosc's stream gains a gentle version without changing its ordinary route.
On some seeded rainy runs the stream rises and carries a branch or abandoned
ball toward the log bridge. Intercepting and returning it is an optional
positive event; missing it has no penalty. Dry-run behavior and random draws
outside the event remain unchanged.

## Whole-roster quality pass

All seventeen walks receive:

1. scripted play through the outward leg, destination and home leg with stuck
   reporting;
2. goal feasibility and progression checks from a fresh save;
3. geometry, collision, leash-contact, inventory and freedom-bound audits;
4. desktop, landscape-phone, portrait, pad and touch screenshot review;
5. idle soak, headless tests, behavior snapshots and representative web
   performance;
6. a design review for unique identity, logical placement, readable
   telegraphs, fair hazards, honest drawing/collision and a worthwhile home
   leg.

Clear bugs and contradictions are fixed in v1.62. Larger redesigns become
scoped follow-ups rather than silently expanding the release.

## Verification and acceptance

New tests receive committed `.uid` files and CI registration. Coverage must
prove:

- shallow water cannot instantly lose and deep water can;
- both bodies and carried objects obey current consistently;
- destination and midpoint continues restore exactly;
- fear starts only when the threat is visible;
- catch animation precedes the end card and clears on continue;
- every arrival aperture is unobstructed;
- existing star gates do not change;
- non-chase framing is pixel-identical;
- unaffected behavior snapshots are byte-identical.

Every player-facing PR has a three-to-five-step feel card with the shortest CLI
route. v1.62 is not tagged until the full audit is clean, CI is green and
Santtu has accepted every intended player-facing group.

## Explicitly later

- A boss fight. El Besòs first proves a second kind of chase.
- Camera rotation, perspective or a 3D tilt.
- Bespoke exits for every walk beyond the three shared families.
- A protected river-mouth route.
