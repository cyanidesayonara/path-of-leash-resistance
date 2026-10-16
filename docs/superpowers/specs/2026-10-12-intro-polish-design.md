# Intro polish: Walkies?

Approved 2026-10-12. One player-facing change. The film stays "Walkies?"
(`intro/scene_walkies.gd`): same beats, same length, same clay drawing, same
title card. The unused storyboards stay unused.

## Problem

On a 16:9 window the film already fills the screen. On any other shape the
stage is fitted inside the expanded viewport and the leftover is a flat beige
rectangle, so a wide monitor and a tall phone show an empty margin instead of
the flat. The set is thin at that size: the window light is a stack of faint
strips, the sofa and the door sit flat on the wall, and the street is a row of
blocks. Two hard camera cuts, at the yank and at the street, read as clunky
when the picture is large.

The cues are gameplay synths borrowed for the wrong actions: a coin blip for
the hook, a UI beep for the loop on the knee, a tangle wobble for the nose,
a hiss for the sigh, a whoosh and a noise burst for the leash and the door,
and a reward arp for the title. The film is silent underneath. The title
theme is built during the film and starts from the top as the picture fades,
so the menu music arrives as a new piece.

## Picture

### Fit

`IntroPlayer._place` keeps the current contain fit: `k = min(viewport.x / 1280, viewport.y / 720)`. The staged frame stays fully visible on every window. A cover fit is the wrong reading of "fill the window": on a tall viewport it would crop the room to a strip too narrow for Millie and your human to share the opening shot.

The beige rectangle in `Stage._draw` stays only as a last resort, and its color matches the set. During the room it is the top wall color. From `TITLE_AT` it is the top sky color.

The room and the street paint out to the scene rect from `(-800, -1100)` to `(2200, 1800)`. That covers a viewport of about 2560 on the long side at zoom 1, which is the widest view. Wall, floor and sky continue into that rect with the same bands they already use. Above the wall, one rect of the top wall color. Below the floorboards, the floor color continues. The street's sky, fronts, pavement and kerb use the same horizontal span. No new scenery in the margin: it is more of the same flat and the same street.

On an exact 16:9 window the fit is unchanged. The set and the camera are what change there.

### Set

Same outlines, same palette.

- Window light is one polygon from the sill across the floor and the sofa's left side, alpha about 0.22. It replaces the floor light polygon in `_room` and the four stacked shafts in `_light`. The window frame and the edge shade stay.
- The sofa gains one shadow on the floor beneath the seat, drawn before the sofa: an ellipse about 316 by 18, the floor color darkened, alpha about 0.35. Its shape stays.
- The door frame grows from 12px to 18px, with a 6px inner lip, so the swing has a jamb. The daylight on the floor stays the one polygon already drawn through the opening.
- Each street front gains one balcony bar under its first window row: the width of that front minus its side margins, 8px tall. The kerb gains a 10px dark band along y = 640. The haze and the title's shade stay. The title wording, placement and swing stay.

### Camera

Every story beat stays. `END_AT` stays 14.4. `LENGTH` stays 15.0. Acting stays on twos. No new poses.

The push to the hook and the move back to the sofa stay as they are.

The cut at 9.25 becomes a move of 0.18 seconds. The close camera holds at (570, 455), zoom 1.75, through 9.04, then eases to (800, 420), zoom 1.12, arriving at 9.22. It holds there until the street. The bark at 9.22 lands on that wide frame.

The room-to-street change stays a cut at `TITLE_AT` (10.1). The white flash from 9.84 to 10.1 stays. Easing that cut would hold the title back.

## Sound

### Phrase

The film plays the opening of the title theme, not a new tune. `Music.job("intro")` arranges `STYLES["title"]` and then keeps only:

- lead events whose kind is `bar` and whose instrument is `marimba`
- drum events whose kind is `hit` and whose instrument is `shaker`, with velocity multiplied by 0.5

Everything else is dropped, including arp, bass and glock. Events whose start sample is at or past the nominal first sample of bar 7 are dropped. Bar length is `4 * 60 / 104` seconds, so seven bars is 16.15 seconds, which covers the film and the handoff. The stream does not loop, and its tail fades out the way a sting's tail does, so the end of bar 7 is not mixed back onto the downbeat. The loudness pass still uses the loop factor (0.8), not the sting factor (1.25). The phrase is then brought up to the same target as the menu theme. It is a thinner arrangement at the same loudness, and over the crossfade the marimba eases down as the band takes its share. It uses the title arrangement's event times and the title's reverb, so the marimba does not flam or change room when the band enters. `"intro"` is not a `STYLES` entry and not a `walk_style` result.

The phrase is rendered to completion before the film's first frame. The title loop keeps building in slices during the film, as `_music_next` already does. There is no loading screen. While `intro_playing` is true, `_music_cue()` returns `"intro"`.

### Handoff

`IntroPlayer`, in the frame it clears `intro_playing`, tells `Sfx` where the title theme should start and how long the crossfade is.

- Played to `END_AT`: start the title loop at 14.4 seconds, crossfade 0.45 seconds. The glock, arp and bass arrive under the melody already playing. When that loop ends, the theme repeats from the top, fully arranged, as it does now.
- Skipped: start the title loop at 0, crossfade 0.45 seconds.

`MUSIC_FADE` (1.4 seconds) is unchanged for every other transition. If the title stream is not ready, hold the phrase on a natural end, or stay quiet on a skip, and start it at the chosen position once it is cached. Music off still plays nothing.

### Cues

New synths in `Sfx._build_library`. No audio files, and these names are not used by gameplay. Each is under 0.4 seconds, except the sigh, which is under 0.6. They sit under the phrase. `IntroPlayer.CUES` becomes:

| time | name | pitch | dB | what |
|---:|---|---:|---:|---|
| 3.12 | intro_hook | 1.0 | -10 | wood tick and a short slide, the leash off the hook |
| 3.34 | intro_paws | 1.0 | -12 | two taps about 0.08 seconds apart, the landing |
| 5.30 | intro_loop | 1.0 | -10 | leather on cloth, the loop on the knee |
| 6.92 | intro_tap | 1.0 | -12 | one dry tap, the nose on the phone |
| 7.65 | intro_sigh | 1.0 | -14 | a short breath |
| 9.22 | bark | 1.0 | -3 | her yank; the loudest cue |
| 9.30 | intro_taut | 1.0 | -8 | a low string pluck, the leash catching |
| 9.44 | intro_door | 1.0 | -8 | a latch and a short wooden swing |

The title card has no sting. A skip cuts the phrase and any cue not yet played. Muted effects still mute these.

3.34 is the landing key (`air` ends at 3.34), in place of the round 3.40 from the design conversation.

## Tests

`tests/test_music.gd` gains checks for `"intro"`:

- a sliced render matches a whole one, and a second whole render matches the first
- the stream does not loop
- its length is seven bars plus the existing tail
- it does not clip
- its marimba events are the title job's marimba events whose start sample is before bar 7
- it contains no `pluck` events and no glock `bar` events
- its RMS is within 4 dB of the title theme, and it is not silent

A headless check on `IntroPlayer.CUES`: every name exists in the library, every time is inside `0 .. END_AT`, `bark` is present, and `pickup`, `ui`, `tangle`, `hiss`, `fling`, `crack` and `star` are absent.

`SceneWalkies.camera` at 9.04 is still the close shot, at 9.22 is (800, 420) at zoom 1.12, and at 10.1 is the street camera (640, 360) at zoom 1.0.

The behaviour snapshot stays byte-identical. The intro does not play under its arguments, and the cue change is inside the `intro_playing` branch.

The window shapes are a feel check, not a pixel test. Draw calls stay in the same clay language: the new light replaces stacked shafts, and the margin is longer versions of the bands already drawn.

## Feel card

Plain launch, no command-line arguments. Any argument, including `--level`, skips the film.

1. A 16:9 window: the film fills the window, the opening still shows Millie by the door and your human on the sofa, and the marimba is already playing before she jumps for the hook.
2. A wide window: the extra space is wall and floor, then sky and street, and both of them stay in the opening shot.
3. A tall window: the extra space is more ceiling and more floor, and the opening shot still holds both of them.
4. The yank is a short move into the wide frame, then the white flash still cuts to the street and the title.
5. The hook, the landing, the sigh, the leash catching and the door are each their own sound. As the film fades, the rest of the title band joins the melody already playing. Skipping drops onto the menu with the theme from the top.
