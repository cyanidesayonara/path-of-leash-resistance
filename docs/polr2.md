# PoLR 2 - notes for a 3D follow-up

Parked on 2026-09-26: polish this game first. This file keeps the idea and
what was worked out about it, so it does not have to be rediscovered.

## The idea

The same game - you are the dog, the owner walks on autopilot, the leash is
real rope - with a 3D corridor presentation in the spirit of Crash Bandicoot
and Tony Hawk. Same mechanics, some levels reused, a complete visual
overhaul. Working title "PoLR 2" (or a subtitle, if the 3D version feels like
its own game rather than a sequel).

## What carries over

The game is mostly simulation on a flat plane: the verlet rope that wraps
poles (`entities/leash.gd`), the tug of war and whirl (`main.gd`), the route
planner (`systems/bypasser_route.gd`), goals, moods, surfaces, level data
(`world/level_build.gd`). A corridor game in 3D still plays on the ground
plane, so all of that can move across nearly unchanged, laid on XZ. So can
the verification habits: behaviour snapshots, CI, pixel tests, the WIP limit.

**Groundwork worth doing in this game whenever it is quiet:** keep
separating the simulation from the drawing, so nothing in the rope, tug,
route or goal logic depends on a CanvasItem. It is a refactor (the behaviour
snapshot proves nothing changed) and it is exactly the part PoLR 2 reuses.

## The hard parts

- **Characters and animation.** Props and buildings are easy; a dog and a
  human that move convincingly (running, digging in, being dragged, the
  owner staggering) are what separates a polished game from a demo.
- **The camera changes the game.** Top-down shows exactly how the leash is
  wound round a pole; a chase camera behind the dog hides it. Settle this
  with a playable prototype before anything else: a high three-quarter view,
  a camera that pulls back when the rope goes taut, a highlighted rope.
- **The browser.** 3D in WebGL is far heavier than this game's 2D. Plan on
  Windows and the Microsoft Store first; treat a web build as optional.

## Asset pipeline (for someone who does not do 3D)

- **Blender, driven by scripts.** `blender --background --python script.py`
  builds models from Python and exports glTF, which Godot imports directly -
  the same "art from code" approach as this game. Scripts can also render
  preview images, so models can be checked and iterated like screenshots.
  Good for props, buildings, street furniture, the sweeper.
- **The owner:** Mixamo (free, Adobe account) auto-rigs a humanoid and has a
  large animation library - walking while looking at a phone, stumbling,
  being yanked.
- **The dog:** CC0 animated animal packs (Quaternius has dogs with run, idle
  and jump cycles); Kenney has matching props and city kits.
- **Style:** low-poly, toon-shaded. Achievable, and closer to the Crash and
  Tony Hawk look than realism would be.

## Suggested order

1. Finish and polish this game (the current plan).
2. The simulation/drawing separation above, as refactors with snapshot proof.
3. A vertical slice: one street, the dog, the human and the rope in 3D, and
   three camera options - a few weeks, to answer "is it fun in 3D?" before
   committing to the rest.
