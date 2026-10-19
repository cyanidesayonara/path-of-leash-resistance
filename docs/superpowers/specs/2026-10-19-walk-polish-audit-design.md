# Sixteen-walk polish audit

**Date:** 2026-10-19
**Target:** v1.62
**Status:** approved design

## Purpose

Make the next release a walk-by-walk polish pass. It adds no walk and no
system. It finds concrete rough edges in the sixteen existing walks, fixes
the ones a player can plainly see or feel, and leaves subjective tuning for
Santtu to decide by hand.

The audit serves the design pillars by removing moments where authored
geometry, traffic, framing or feedback obscures the leash comedy. It does
not add detail merely to make a busy screen busier.

## Scope

Audit every ordinary walk in campaign order. For each walk inspect:

- the outbound leg, off-leash area and home leg;
- the signature set piece and the level's hazardous prize;
- authored solids, moving actors and bypasser routes;
- place-name signs, goals, banners and event telegraphs;
- representative clear weather, plus forced weather or time where the walk
  owns it;
- obvious visual overlaps, weak silhouettes, stuck actors, unreachable
  items, unfair contact and misleading feedback.

Cross-game systems are in scope only when an audit finding demonstrates a
problem in a walk. New mechanics, new walks, broad retuning, store work and
the existing controller/phone verification cards are out of scope.

## Audit method

Use three sources of evidence in this order:

1. Run the level inventory and the deterministic screenshot sweep. Review
   every walk sheet for layout, framing, overlaps and readability.
2. Script a short representative playtest for every walk: outbound through
   its signature section, then home through the same area where practical.
   Save screenshots and the playtest log.
3. For a suspected defect, reproduce it with the narrowest existing test or
   shot hook before changing code.

The browser pane is not playtest evidence. Use the Godot playtest script so
the game receives real input actions and advances as a visible build.

The audit itself produces `docs/WALK_POLISH_AUDIT.md`, ordered by campaign
walk. Each finding records the location, reproduction command, player-visible
symptom, evidence path, severity and disposition.

## Triage

Every observation has one of three severities:

- **Blocking:** progression can fail, an actor gets stuck, a required item is
  unreachable, or an untelegraphed hazard causes failure.
- **Clearly rough:** visible overlap, broken staging, illegible feedback,
  implausible route, or a signature beat that plainly fails to read.
- **Subjective:** timing, difficulty, density or feel that can reasonably be
  preferred either way.

Fix blocking and clearly rough findings. Record subjective findings without
changing the game until Santtu plays them. A clean walk gets an explicit
“no finding” entry rather than an invented change.

## Change control

The audit document is tooling and does not count against the player-facing
WIP limit. Each independent player-facing fix is its own small pull request
with a feel card and stays in Awaiting acceptance until Santtu plays it.
Related symptoms with one root cause may share a pull request.

Do not collect unrelated cleanup into a finding. Behavior-preserving work
must keep the behavior snapshot byte-identical. Intentional behavior changes
need focused regression coverage and an explanation of every changed
snapshot line.

## Verification

Each fix gets the narrowest regression that can fail before the fix and pass
after it. Player-facing fixes also get a scripted playtest at the exact
location, with before/after screenshots when the defect is visual.

Before v1.62 is eligible for a tag:

- all sixteen walks have an audit entry;
- every blocking finding is resolved;
- every clearly rough finding is resolved or explicitly deferred with a
  reason;
- focused tests and the full CI smoke suite are green;
- the screenshot sweep is reviewed after the last fix;
- accepted player-facing cards are Done and no unaccepted fix is hidden by
  the release.

The release is not blocked by the separate controller, phone, SCARED or Steam
cards unless Santtu explicitly moves one into v1.62.
