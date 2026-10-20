# Reusable chase walks

**Date:** 2026-10-20
**Status:** approved design

## Purpose

Turn the existing La Neteja home chase into a reusable walk structure without
turning every pursuer into the same machine. A chase walk remains a complete
round trip: a calm outbound leg, its destination or freedom visit, a visible
warning, a short head start, and a chase home.

This supersedes the older `PROJECT.md` direction that dedicated chase walks
open by sending the player south. The destination earns the reversal, the
warning makes the threat fair, and the return through familiar ground makes
the chase leg readable.

## Ownership

`HomeChase` remains the orchestrator. Each chase walk supplies one small
profile containing:

- the threat script to instantiate;
- threat behavior and speed;
- warning, caught-dog, and caught-human copy;
- ordered chase bands, including trigger, respite, and checkpoint positions;
- optional threat-specific interaction hooks.

The profile describes differences between walks. Shared phase transitions,
checkpoint capture and restore, warning timing, head starts, catch handling,
and completion stay in `HomeChase`. Level builders continue to own geometry
and authored set pieces. A walk with no chase profile keeps the ordinary
round-trip behavior.

The optional hooks are limited to interactions the shared orchestrator cannot
express, such as a sweeper jamming on a dumpster or future flood water
interacting with riverbed surfaces. They do not replace shared phase or
checkpoint logic.

## Shared round-trip rhythm

A chase walk proceeds through these phases:

1. **Outbound:** the ordinary calm walk to the destination. No threat exists
   and chase state alone cannot create SCARED.
2. **Destination:** the ordinary freedom or destination visit completes.
3. **Warning:** the destination checkpoint is captured first, then the threat
   is visibly and audibly telegraphed.
4. **Head start:** the warning clears and a short, fixed grace period lets the
   pair start home before the threat can catch them.
5. **Chase home:** ordered bands alternate pressure with authored respites.
   The threat can catch the pair only in this phase.
6. **Complete:** reaching home ends the walk through the existing results
   flow.

SCARED remains proximity-driven. It rises only from the distance to a live,
advancing threat and falls when that threat is held or distant. Entering a
chase phase, restoring a checkpoint, or merely being on a chase walk does not
grant fear.

## La Neteja reference profile

La Neteja is the reference implementation. Every La Neteja run uses the slow
street sweeper and an oblivious human. It never randomly changes to `bolt` or
`both`; those existing variants remain test hooks or material for a future
profile, not La Neteja run variety.

The calm outbound leg and destination visit remain fully playable before the
warning. On the chase home, the existing dumpster jams are respites. The
later jam is also the midpoint checkpoint. Sweeper speed, rear kill-line
catching, junk sweeping, camera lean, close-shave reward, and separate dog
and human catch outcomes remain sweeper-specific behavior behind the profile.

La Neteja must not inherit generic market hazards that were not authored for
its chase lane. In particular, it has no open manholes or other instant-fail
holes. Its dumpsters, crates, puddles, scooters, lamps, washing, and chase
interactions remain intentional level content.

## Checkpoints and retry

La Neteja has exactly two chase checkpoints:

- **Destination:** captured immediately before the warning.
- **Midpoint:** captured when the pair reaches the later dumpster jam and the
  sweeper is held there.

Continuing after a catch restores the latest checkpoint. Explicitly choosing
restart discards checkpoint state and starts the full walk from the outbound
leg.

A destination continue repeats the warning and full head start. It does not
drop the player directly into motion. A midpoint continue restores the
sweeper held at the later jam, shows a short safe countdown, and only then
releases it. The countdown cannot advance catch physics or proximity fear.

Each checkpoint stores the transient run state needed to make continuation
fair:

- pee amount, poop state and progress, and dog energy;
- phone condition;
- bones, style score, and current combo state;
- run-goal progress;
- which one-run rewards and pickups have already been consumed;
- the current chase band and its held or advancing state;
- chase one-shots, including warnings, respites, close-shave state, and
  threat interactions already fired.

Restore replaces those values; it does not add to current values. World
reconstruction must agree with the restored consumed-reward set, so a pickup,
goal payout, or close-shave reward cannot be earned twice. Checkpoints are
run-local snapshots, not save-file shortcuts: they do not write completion,
records, stars, unlocks, or permanent wallet rewards before the walk ends.

## Future profiles

The future Besòs flood uses the same round-trip and checkpoint rhythm. A flood
siren sounds at the river park, a short head start follows, and rising water
moves along the riverbed on the way home. Its profile owns flood speed, copy,
bands, and water interactions; distinct swimming and current mechanics are a
later design and are not part of this foundation.

A steering pursuer, such as a scary dog, may reuse the warning, head start,
band, respite, and checkpoint structure. It must not be forced into the
rear-facing full-width kill-line physics used by the sweeper and flood.
Steering, turning, contact, and catch rules belong to that threat's behavior.

## Verification

Focused automated coverage must prove:

- a chase profile is absent from ordinary walks and La Neteja always selects
  its fixed sweeper profile;
- outbound and destination phases remain calm, warning precedes the head
  start, and catching is disabled until the chase begins;
- SCARED follows live threat proximity rather than phase or level identity;
- destination and midpoint checkpoints are captured at the specified events;
- destination continue repeats warning and head start, while midpoint
  continue holds the later jam through its safe countdown;
- continue restores every listed transient field exactly and cannot duplicate
  pickups, run-goal payouts, close-shave rewards, or permanent progress;
- explicit restart begins a fresh full walk;
- La Neteja has no manholes or unintended inherited market hazards;
- existing sweeper speed, jams, catches, camera lean, junk, and close-shave
  behavior remain covered by `tests/test_home_chase.gd`;
- La Neteja geometry and chase-lane content remain covered by
  `tests/test_neteja.gd`.

Add `tests/test_chase_walk.gd` for profile and phase behavior and
`tests/test_chase_checkpoint.gd` for snapshot and retry behavior rather than
expanding one integration test to cover every state. Run both together with
`test_neteja.gd`, `test_home_chase.gd`, the headless smoke test, and the full
CI test runner.

Scripted visible playtests must cover a complete La Neteja round trip, a catch
and continue from the destination checkpoint, a catch and continue from the
midpoint jam, and an explicit restart after reaching a checkpoint. Record the
warning, usable head start, held-jam countdown, restored resources and phone,
absence of duplicate rewards, proximity-driven fear, and the unobstructed
manhole-free chase lane. Repeat the complete run on keyboard and pad; verify
touch prompts and continue/restart selection with the touch device mode.
