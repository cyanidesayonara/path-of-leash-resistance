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

Place references:

- Diputació de Barcelona, "El Plan de emergencia":
  https://parcs.diba.cat/es/web/fluvial/la-gestio/pla-d-emergencia
- Diputació de Barcelona, "La zona de uso público":
  https://parcs.diba.cat/es/web/fluvial/les-zones/la-zona-d-us-public
- Diputació de Barcelona, "The Besòs River Park":
  https://parcs.diba.cat/c/document_library/get_file?groupId=5280469&uuid=0260693a-c81c-453f-93b3-21c2ead11c0c

The playable route avoids the protected river mouth. It starts by the railway
bridge in Sant Adrià and runs upstream to a broad meadow near Pont de Can
Peixauet. The destination sign is:

    PRAT DEL BESÒS
    RIVER MEADOW

## Progression and special-walk cadence

The internal id is `besos`; its English gloss is "the floodable river park".
It sits between L'Estació and Les Obres in the campaign carousel and unlocks
at 14 stars. Every existing star gate remains unchanged, so an existing save
never loses access to a walk. It joins `Game.LEVELS`, the daily rotation,
inventory, screenshot, soak and behavior-snapshot lists. The changed daily
sequence after 1.62 is intentional.

El Besòs and La Neteja are separated by Les Obres, La Castanyada, La Ferralla
and El Mosaic. Future chase and boss walks target three or four ordinary walks
between major special setpieces, and never put a boss directly beside a
chase. This replaces the older PROJECT.md pitch of an incoming tide on
Passeig Marítim: El Besòs is the authored water chase; the beach remains an
ordinary walk.

## The walk out

The level is a clear, warm afternoon. The flood can originate upstream without
local rain, which keeps El Diluvi visually distinct and makes the alert feel
uncanny.

The corridor is asymmetric but bounded on both sides:

- concrete flood wall, warning equipment and access ramps;
- a paved walking and cycle route;
- a broad usable strip of grass;
- a shallow, swimmable river margin along the opposite edge, with riprap and
  the deep central channel beyond it as a solid world boundary.

The calm leg teaches the place before changing it. Repeating lamps, an OPEN
entrance board, gauges and the inflatable weir establish the warning system.
Sparse runners and bicycles use the paved lane. Bridge shadows, one reedier
stretch and the cable-stayed destination bridge break up the long view.
Hydrants are replaced by suitable markable lamps, signs and bridge supports.
Millie may wade or swim in the shallow margin and your human may wade at its
edge. Neither body can enter the deep central channel. Safe edge points may be
sniffed, but no goal encourages entering the river.

The destination is the usual off-leash reward in a broad river meadow.
`docs/LEVEL_DESIGN.md` gains the walk's design brief and signature: a calm
public park inside a flood channel whose real warning infrastructure becomes
the home-leg chase.

## Warning and head start

Leaving the destination for home captures the destination checkpoint. Then:

1. warning lamps flash in sequence down the walls;
2. a bicycle ranger clears people toward the access ramps;
3. the entrance board changes to an emergency closure message;
4. the evacuation announcement and siren sound;
5. your human initially assumes it is somebody else's problem.

Those cues overlap inside the shared 1.2-second warning; they are layers, not
six sequential waits. The normal three-second head start follows.

The flood cannot move, catch or create fear during the warning or head start.

## The flood home

The flood comes from upstream, behind the southbound pair.

The leading shallow edge is pale, visibly directional and recoverable. It
pushes both bodies south, reduces the dog's steering and wets them. For the
human it is an external push only: their motor and intended pace are never
reduced. Planting resists the current and moving with it helps. The leash
remains the real constraint.

The deep front follows a fixed distance behind the shallow edge. It is darker,
louder, foam-edged and is the actual loss boundary. It also swells laterally
from the river edge so the
comfortable route narrows without invisible walls. Floating branches, balls
and light park litter reveal direction before the water reaches the player.
Large debris is sparse, telegraphed, and never seals the whole escape lane or
spawns on either body. Light debris is visual or nudges a body. A branch uses
the existing dog tumble/human stumble response, never an instant loss and
never special phone damage.

A raised maintenance apron at the midpoint makes the second checkpoint
physical. The flood splits around it and is held there for the three-second
continue countdown, then spills across immediately. An unsafe checkpoint
keeps the destination snapshot under the same rules as La Neteja. "Unsafe"
means either body is in the shallow zone or behind it; both must be dry and
ahead of the shallow edge when the checkpoint is captured.

The final run climbs an emergency access ramp toward increasing world Y.
Reaching the dry top of that ramp ends the chase; the water stays below in the
channel.

Any home-leg loss with a checkpoint held offers continue. Restoration replaces
the checkpoint state exactly and never pays a pickup, goal or reward twice.
The flood checkpoint adds its deep-front position, lurch, band/jam state,
lateral-swell phase and deterministic debris cursor to the threat section.
The shallow edge and active current rectangles are derived from those values.
`human_soak` is already run state and is restored. Flood-owned loose debris is
cleared and deterministically rebuilt ahead of the restored front; ordinary
loose junk remains deliberately unrestored under the existing checkpoint
contract.

## Flood goals

El Besòs has the familiar mark, sniff, phone, paws, bag, fetch, Tofu, combo and
prize goals, plus:

- Keep the deep flood front a leash length away.
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
release; it never snaps during continuous play. A checkpoint restore keeps the
existing direct camera reset so the restored pair is immediately on screen,
then resumes the same easing.

The tuning safety bound is at least 110 rendered pixels between the
southernmost body and the viewport bottom at every tested aspect ratio. Threat
visibility means its authored leading boundary is at least 48 rendered pixels
below the viewport top. These measurements use the world viewport itself; HUD
and touch controls do not change the geometry, and the required captures
separately reject a threat hidden by the banner or controls. The existing
90-world-unit maximum is a baseline, not a promise; the prototype may raise it
only while preserving the 110-pixel runway bound.

SCARED intensity still depends on distance to the deep/kill boundary, but its
internal amount cannot begin increasing until the shallow edge (for the flood)
or brushes (for the sweeper) meets the visibility rule above. Warning, head start and
checkpoint holds are fear-free; existing fear decays naturally.

This visibility rule belongs to the shared chase profile and applies to the
sweeper, flood and future scary-dog threats.

## Catch presentation

The existing 0.75-second catch delay becomes an authored deterministic beat.
The kill has already been decided, so gameplay body simulation and player
input freeze at the caught positions. The beat uses presentation-only draw
offsets and rotations for dog, human and the visible leash; it does not push
solver points, call `_leash_tug`, reduce the human motor during live gameplay,
or feed an animated pose back into physics. A continue restores the checkpoint
and resnaps the real leash as it does now.

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
immediately, but only after both dog and human have crossed, matching the
existing finish rule. Gameplay time and the time-record value freeze at that
threshold. Player input, hazards, phone damage and chase catches are disabled
during arrival; a chase threat stops at the safety line. Millie pulls toward
the exit as a presentation animation, your human looks up and pockets the
phone, Millie enters first, your human follows, the visible leash passes
through the aperture, then results appear. If one body arrives first, normal
play continues until the other crosses.

The opening half-second cannot be skipped; after it, confirm or back completes
the animation and opens results. Automated tests advance the state
deterministically. Rain leaves wet pawprints, night uses the entrance light and
snow gathers at the sill. Starting an apartment walk closes its door behind
the pair. Transit and safe-exit walks begin with the pair already outside their
entrance; they have no departure beat. Every aperture is clear of generated
props and collision. Walks without a threat simply enter the same terminal
arrival state.

## Shared current and El Bosc

Current is a small shared rule rather than Besòs-only physics. It acts on dog,
human and floating loose objects with consistent direction and strength.
Planting resists it.

El Bosc's stream gains a gentle version without changing its ordinary route.
On some seeded rainy runs the stream rises and carries a branch or abandoned
ball toward the footbridge. Intercepting and returning it is an optional
positive event; missing it has no penalty. The event appears on 20% of rainy
El Bosc runs. Main records the chosen run seed alongside the existing
`seed()` setup without consuming a draw; a stable hash of that seed, the level
id and the event id selects the event. It is deterministic under `--seed` and
daily seeds. An ordinary run takes one startup seed from
`Time.get_ticks_usec()`, records it, and seeds the global sequence before any
layout draw; ordinary runs remain random without consuming an extra draw.
Current acts on
the event's branch or ball only while it is loose, never while carried in
Millie's mouth. Dry-run behavior and random draws outside the event remain
unchanged. The existing crossing is called the footbridge in code and tests.

## Whole-roster quality pass

All seventeen campaign walks (the current sixteen plus El Besòs) receive:

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

The tutorial is outside the seventeen-walk roster audit, but its apartment
arrival and fresh-save progression still receive focused regression coverage.

"Clean" means every required automated command exits zero, scripted routes
report no unexplained dog/human stuck line, every goal is achievable, level
checks report no geometry/inventory problem, and screenshot review has no S1
or S2 defect. S3 logic/readability defects found in changed systems are fixed;
unrelated redesigns and S4 cosmetics become issues. Every intentional snapshot
or pixel diff is listed in its PR.

Before each player-facing group starts, both the project board's Awaiting
acceptance column and unticked entries in backlog issue #23 are counted. Work
does not start when that count is five.

## Verification and acceptance

New tests receive committed `.uid` files and CI registration. Coverage must
prove:

- shallow water cannot instantly lose and deep water can;
- both bodies and floating loose objects obey current consistently;
- destination and midpoint continues restore exactly;
- fear starts only when the threat is visible;
- catch animation precedes the end card and clears on continue;
- every arrival aperture is unobstructed;
- existing star gates do not change;
- the camera transform outside chase legs is pixel-identical (arrival art is
  an explicit world-pixel change);
- unaffected behavior snapshots are byte-identical.

The flood's shallow edge, deep front, foam, swell and debris are one batched
canvas with one `ShapeBatch` flush and no per-debris nodes. On the same
El Besòs fixture and machine, turning the flood on may not add more than one
draw call or regress frame time more than 15% over the flood-off scene without
investigation and an explicit decision. The El Bosc event test pins its 20%
hash rule, deterministic path, positive-only outcome and no-penalty miss.
Fresh-save play must prove both flood goals together while SCARED and current
are active.

Every player-facing PR has a three-to-five-step feel card with the shortest CLI
route. v1.62 is not tagged until the full audit is clean, CI is green and
Santtu has accepted every intended player-facing group.

`PROJECT.md` is updated when the walk lands: El Besòs replaces the old beach
tide pitch, and the chase cadence records the approved three-or-four-ordinary
spacing. Issue #170 records the same decision; #271 closes when visible fear
onset has been hand accepted.

## Explicitly later

- A boss fight. El Besòs first proves a second kind of chase.
- Camera rotation, perspective or a 3D tilt.
- Bespoke exits for every walk beyond the three shared families.
- A protected river-mouth route.
