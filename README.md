# Pull of Duty (working title)

Top-down leash physics prototype. You are the dog. Your human is glued to
their phone and walking on autopilot. Get them to the park with the phone
intact, and sniff everything worth sniffing along the way.

## Run

Open the project folder in Godot 4.x, or run directly:

```
godot\<Godot exe> --path .
```

## Controls

- Move: WASD / arrows / left stick
- Dig in (anchor yourself, stops the human via the leash): hold Space / A
- Bark (freezes the human for a beat): E / B
- Restart: R / Start

## What to feel for

- Plant yourself before bike lanes so the human strains against the leash
  and stops. Release when the lane is clear.
- A hard yank while planted makes the human stumble toward you. That is the
  save move.
- The human telegraphs events with a speech bubble: "ring ring" = stops,
  "typing..." = drifts sideways, "ooh!" = dashes somewhere stupid.
- Sniffing hydrants and eating dropped kebabs scores bones, but every second
  spent sniffing is a second the human spends unsupervised.

## Tuning knobs

- `main.gd`: `LEASH_LENGTH`, lane positions, spawn intervals, level length.
- `human.gd`: walk speed, event frequency and durations.
- `dog.gd`: dog speed, pull shares are in `main.gd/_apply_leash`.

The gameplay leash is a straight-line distance constraint; the visible rope
is a verlet chain that collides with poles (visual only, for now).
