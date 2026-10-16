# Intro polish implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Walkies intro fill a wide or tall window with the flat, ease the yank camera, and play the opening of the title theme with cues that belong to the picture.

**Architecture:** The film stays `intro/scene_walkies.gd` inside the current contain fit. The set paints out to a fixed scene rect. `Music.job("intro")` is the title arrangement filtered to marimba and a quiet shaker. `Sfx.handoff` starts the full title loop at the beat the film reached. Gameplay synth names stay out of the cue list.

**Tech Stack:** Godot 4.7, GDScript only, procedural audio in `audio/music.gd` and `autoload/sfx.gd`. No audio files.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-10-12-intro-polish-design.md`. One player-facing change.
- Keep "Walkies?". Do not switch to `intro/scene_rooftops.gd` or any other storyboard.
- `END_AT` stays 14.4. `SceneWalkies.LENGTH` stays 15.0. `SceneWalkies.TITLE_AT` stays 10.1. Acting stays on twos. Do not add pose keys or move the ones already there.
- `IntroPlayer._place` keeps `k = minf(vs.x / 1280.0, vs.y / 720.0)`. Do not switch it to `maxf`.
- Scene paint covers the rect from `(-800, -1100)` to `(2200, 1800)`.
- The yank camera holds `(570, 455)` zoom `1.75` through `9.04`, eases to `(800, 420)` zoom `1.12` at `9.22`, and holds until the street cut at `10.1`.
- `"intro"` is not added to `Music.STYLES` and `Music.walk_style` must not return it.
- Intro stream does not loop. Its tail fades like a sting. Loudness uses the loop factor `0.8`, not the sting factor `1.25`.
- `Sfx.MUSIC_FADE` stays `1.4`. The intro handoff fade is `0.45`.
- No audio files. New cue names are only used by the intro.
- American English. Say "leash". No emoji. Commits are authored by Santtu Nykänen with no `Co-authored-by` trailer. From this environment, commit with `git -c alias.cm=commit cm -F commit-msg.txt` so the shell does not append a trailer. Do not amend.
- A new script gets the `.gd.uid` Godot writes. If a Godot run dirties `assets/*.import` or `icon.png.import`, restore those with `git checkout -- assets icon.png.import` before committing.
- The behaviour snapshot stays byte-identical. Do not record a new baseline.
- Tests, from the worktree, with the editor from the main checkout:

```
$env:GODOT = (Resolve-Path ..\path-of-leash-resistance\godot\Godot_v4.7-stable_win64_console.exe).Path
& $env:GODOT --headless --path . --script res://tests/test_music.gd
```

Expected success line is `test_music: OK` and exit code 0, unless a step says otherwise.

## File structure

- `audio/music.gd` — `job("intro")`, `Job.loud_as_loop`. The title loop is unchanged.
- `autoload/sfx.gd` — intro synths, `prepare_intro()`, `handoff()`, handoff fade length.
- `main.gd` — `_music_cue()` returns `"intro"` while `intro_playing`.
- `intro/intro_player.gd` — cue table, skip cuts unplayed cues, calls `prepare_intro` and `handoff`, stage clear color.
- `intro/scene_walkies.gd` — margin paint, set, yank camera.
- `tests/test_music.gd` — intro arrangement and render.
- `tests/test_intro_polish.gd` — cues, handoff, camera. New file, plus its `.gd.uid`, plus a step in `.github/workflows/ci.yml`.
- `CHANGELOG.md` — one newest-first entry.

Do not split the film into new scripts.

## Before Task 1

Implement on a fresh worktree of `origin/main`, branch `intro-polish`, directory `pol-intro` next to the main checkout. Do not implement on `tug-flake`.

From `C:\Users\SanttuNykänen\projects`:

```
git -C path-of-leash-resistance fetch origin
git -C path-of-leash-resistance worktree add ..\pol-intro -b intro-polish origin/main
```

Copy these two files from the tug-flake checkout into that worktree, then do the rest of the work there:

- `docs/superpowers/specs/2026-10-12-intro-polish-design.md`
- `docs/superpowers/plans/2026-10-12-intro-polish.md`

The first Godot run in the new worktree needs a class-cache import or `class_name` scripts fail to parse:

```
& $env:GODOT --headless --path . --import --quit
git checkout -- assets icon.png.import
```

---

### Task 1: Intro phrase

**Files:**
- Modify: `audio/music.gd` (`job`, `Job`, the gain line)
- Test: `tests/test_music.gd`

**Interfaces:**
- Consumes: `Music.STYLES["title"]`, `Music._arrange`, `Music.RATE` (22050), `Music.TAIL` (3.0)
- Produces: `Music.job("intro") -> Music.Job`. `Job.loud_as_loop: bool` (default false). Cut sample is `int(7.0 * 4.0 * (60.0 / 104.0) * Music.RATE)`. Stream length in samples is that cut plus `int(Music.TAIL * Music.RATE)`, then rounded up to a multiple of 4. Events are `[start: int, kind: String, params: Array]`. Marimba params are `[midi, velocity, "marimba"]`. Shaker params are `["shaker", velocity]`.

- [ ] **Step 1: Write the failing test**

In `tests/test_music.gd`, add this before the final `print` in `_initialize`. It needs `levels["title"]`, so it stays after the style loop.

```gdscript
	var cut := int(7.0 * 4.0 * (60.0 / 104.0) * Music.RATE)
	var title_job := Music.job("title")
	var intro_job := Music.job("intro")
	_check(not intro_job.loop, "intro job does not loop")
	_check(intro_job.loud_as_loop, "intro uses loop loudness")
	var want_mel: Array = []
	var want_shake: Array = []
	for ev in title_job.events:
		if int(ev[0]) >= cut:
			continue
		if String(ev[1]) == "bar" and String(ev[2][2]) == "marimba":
			want_mel.append(ev)
		elif String(ev[1]) == "hit" and String(ev[2][0]) == "shaker":
			want_shake.append(ev)
	var got_mel: Array = []
	var got_shake: Array = []
	for ev in intro_job.events:
		_check(String(ev[1]) != "pluck", "intro has no pluck")
		if String(ev[1]) == "bar":
			_check(String(ev[2][2]) == "marimba", "intro bars are marimba")
			got_mel.append(ev)
		elif String(ev[1]) == "hit":
			_check(String(ev[2][0]) == "shaker", "intro hits are the shaker")
			got_shake.append(ev)
	_check(got_mel.size() == want_mel.size() and got_mel.size() > 0, "intro keeps the early marimba")
	for i in range(mini(got_mel.size(), want_mel.size())):
		_check(int(got_mel[i][0]) == int(want_mel[i][0]), "marimba time %d" % i)
	_check(got_shake.size() == want_shake.size() and got_shake.size() > 0, "intro keeps the shaker")
	for i in range(mini(got_shake.size(), want_shake.size())):
		_check(int(got_shake[i][0]) == int(want_shake[i][0]), "shaker time %d" % i)
		_check(is_equal_approx(float(got_shake[i][2][1]), float(want_shake[i][2][1]) * 0.5), "shaker is half")
	var whole := Music.render_stream("intro")
	var sliced := Music.job("intro")
	while not sliced.step(300):
		pass
	_check(whole.data == sliced.stream.data, "a sliced intro matches a whole one")
	_check(Music.render_stream("intro").data == whole.data, "intro renders repeat")
	_check(whole.loop_mode == AudioStreamWAV.LOOP_DISABLED, "intro stream does not loop")
	var expect := cut + int(Music.TAIL * Music.RATE)
	expect += (4 - expect % 4) % 4
	_check(whole.data.size() / 2 == expect, "intro length is seven bars plus the tail")
	var n := whole.data.size() / 2
	var peak := 0
	var sumsq := 0.0
	for i in range(n):
		var v := absi(whole.data.decode_s16(i * 2))
		peak = maxi(peak, v)
		sumsq += float(v * v)
	var intro_rms := sqrt(sumsq / float(n)) / 32767.0
	_check(peak < 32500, "intro does not clip (peak %d)" % peak)
	_check(intro_rms > 0.05, "intro is not silent")
	var ratio := intro_rms / float(levels["title"])
	if ratio < 1.0:
		ratio = 1.0 / ratio
	# 1.25 rejects the sting loudness factor (1.25 / 0.8 = 1.56) while a loop-matched phrase passes
	_check(ratio < 1.25, "intro loudness matches the title (ratio %s)" % ratio)
```

- [ ] **Step 2: Run the test to verify it fails**

```
& $env:GODOT --headless --path . --script res://tests/test_music.gd
```

Expected: exit code 1, and a `FAIL:` line. Today `job("intro")` falls through to the full title arrangement, so the no-pluck check fails.

- [ ] **Step 3: Build the phrase**

In `audio/music.gd`, replace `job`:

```gdscript
static func job(name: String) -> Job:
	var j := Job.new()
	j.name = name
	if name == "intro":
		_intro(j)
	elif JINGLES.has(name):
		_jingle(j, JINGLES[name])
	else:
		_arrange(j, STYLES.get(name, STYLES["title"]))
	j.events.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	return j


# the film's opening: the title arrangement's marimba and a quieter shaker,
# seven bars, ringing out without folding back onto the downbeat
static func _intro(j: Job) -> void:
	var full := Job.new()
	_arrange(full, STYLES["title"])
	var cut := int(7.0 * 4.0 * (60.0 / 104.0) * RATE)
	for ev in full.events:
		if int(ev[0]) >= cut:
			continue
		var kind := String(ev[1])
		var params: Array = ev[2]
		if kind == "bar" and String(params[2]) == "marimba":
			j.add(int(ev[0]), kind, params.duplicate())
		elif kind == "hit" and String(params[0]) == "shaker":
			var p: Array = params.duplicate()
			p[1] = float(p[1]) * 0.5
			j.add(int(ev[0]), kind, p)
	j.loop = false
	j.loud_as_loop = true
	j.verb_wet = float(STYLES["title"]["verb"])
	j.n = cut + int(TAIL * RATE)
	j.n += (4 - j.n % 4) % 4
	j.total = j.n
```

On `Job`, next to `var loop := true`:

```gdscript
var loud_as_loop := false
```

In the gain line inside `step`, replace the factor so a non-looping intro still aims at a loop's loudness:

```gdscript
_gain = TARGET_RMS / maxf(rms, 0.0001) * (0.8 if loop or loud_as_loop else 1.25)
```

Leave the sting tail fade (`loop` false) as it is. `total == n` means that fade runs on the end of the buffer and the tail is not mixed onto sample 0.

- [ ] **Step 4: Run the test to verify it passes**

```
& $env:GODOT --headless --path . --script res://tests/test_music.gd
```

Expected: `test_music: OK`, exit code 0.

- [ ] **Step 5: Commit**

```
git add audio/music.gd tests/test_music.gd
```

`commit-msg.txt`:

```
Add the intro's opening of the title theme

The film needs the same tune, thin, so the menu band can join it instead of starting another song.
```

```
git -c alias.cm=commit cm -F commit-msg.txt
```

---

### Task 2: Intro cues

**Files:**
- Modify: `autoload/sfx.gd` (`_build_library` and new synths)
- Modify: `intro/intro_player.gd` (`CUES`)
- Create: `tests/test_intro_polish.gd`
- Modify: `.github/workflows/ci.yml` (after the Soundtrack test step)

**Interfaces:**
- Consumes: `Sfx._pack`, `Sfx.RATE`
- Produces: library keys `intro_hook`, `intro_paws`, `intro_loop`, `intro_tap`, `intro_sigh`, `intro_taut`, `intro_door`. `IntroPlayer.CUES` rows are `[time: float, name: String, pitch: float, db: float]`.

- [ ] **Step 1: Write the failing test**

Create `tests/test_intro_polish.gd`:

```gdscript
extends SceneTree

# Intro cues, the handoff into the title theme, and the yank camera.
#   godot --headless --path . --script res://tests/test_intro_polish.gd

var failures := 0


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


func _initialize() -> void:
	_cues()
	print("test_intro_polish: %s" % ("OK" if failures == 0 else "%d FAILED" % failures))
	quit(1 if failures > 0 else 0)


func _cues() -> void:
	var want: Array = [
		[3.12, "intro_hook", 1.0, -10.0],
		[3.34, "intro_paws", 1.0, -12.0],
		[5.30, "intro_loop", 1.0, -10.0],
		[6.92, "intro_tap", 1.0, -12.0],
		[7.65, "intro_sigh", 1.0, -14.0],
		[9.22, "bark", 1.0, -3.0],
		[9.30, "intro_taut", 1.0, -8.0],
		[9.44, "intro_door", 1.0, -8.0],
	]
	_check(IntroPlayer.CUES == want, "intro cue list")
	for row in IntroPlayer.CUES:
		var t := float(row[0])
		var name := String(row[1])
		_check(t >= 0.0 and t <= IntroPlayer.END_AT, "cue time %s" % name)
		_check(Sfx.lib.has(name), "library has %s" % name)
		if name == "bark":
			continue
		var dur := float(Sfx.lib[name].data.size()) / 2.0 / float(Sfx.RATE)
		var limit := 0.6 if name == "intro_sigh" else 0.4
		_check(dur > 0.02 and dur < limit, "%s lasts %s s" % [name, dur])
	for old in ["pickup", "ui", "tangle", "hiss", "fling", "crack", "star"]:
		var found := false
		for row in IntroPlayer.CUES:
			if String(row[1]) == old:
				found = true
		_check(not found, "%s is not an intro cue" % old)
```

In `.github/workflows/ci.yml`, immediately after the Soundtrack test step, add:

```yaml
      - name: Intro polish test
        run: bash tools/godot_ci.sh ./Godot_v4.7-stable_linux.x86_64 --headless --path . --script res://tests/test_intro_polish.gd
```

- [ ] **Step 2: Run the test to verify it fails**

```
& $env:GODOT --headless --path . --script res://tests/test_intro_polish.gd
```

Expected: exit code 1, `FAIL: intro cue list`. Restore dirtied imports if the run wrote any. Keep the `.gd.uid` Godot writes beside the new script.

- [ ] **Step 3: Add the synths and the cue list**

In `autoload/sfx.gd`, inside `_build_library`, after `lib["grit"]`:

```gdscript
	lib["intro_hook"] = _intro_hook()
	lib["intro_paws"] = _intro_paws()
	lib["intro_loop"] = _intro_loop()
	lib["intro_tap"] = _intro_tap()
	lib["intro_sigh"] = _intro_sigh()
	lib["intro_taut"] = _intro_taut()
	lib["intro_door"] = _intro_door()
```

Add these methods. They use hashed noise so they do not advance `rng` or depend on call order.

```gdscript
func _hash_noise(i: int, salt: float) -> float:
	return fmod(sin((float(i) + salt) * 12.9898) * 43758.5453, 1.0) - 0.5


func _intro_hook() -> AudioStreamWAV:
	var dur := 0.12
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	for i in range(n):
		var t := float(i) / RATE
		var tick := sin(TAU * 1400.0 * t) * exp(-t * 80.0) * 0.4
		ph += TAU * lerpf(420.0, 180.0, clampf(t / dur, 0.0, 1.0)) / RATE
		out[i] = tick + sin(ph) * exp(-t * 14.0) * 0.25
	return _pack(out)


func _intro_paws() -> AudioStreamWAV:
	var dur := 0.18
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := float(i) / RATE
		var env := exp(-t * 60.0)
		if t >= 0.08:
			env += exp(-(t - 0.08) * 60.0)
		out[i] = _hash_noise(i, 3.0) * env * 0.45
	return _pack(out)


func _intro_loop() -> AudioStreamWAV:
	var dur := 0.16
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := float(i) / RATE
		out[i] = (sin(TAU * 180.0 * t) * 0.3 + _hash_noise(i, 9.0) * 0.2) * exp(-t * 18.0)
	return _pack(out)


func _intro_tap() -> AudioStreamWAV:
	var dur := 0.05
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := float(i) / RATE
		out[i] = _hash_noise(i, 1.0) * exp(-t * 90.0) * 0.5
	return _pack(out)


func _intro_sigh() -> AudioStreamWAV:
	var dur := 0.45
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var prev := 0.0
	for i in range(n):
		var prog := float(i) / float(n)
		prev = lerpf(prev, _hash_noise(i, 5.0), 0.08)
		out[i] = prev * sin(PI * prog) * 0.35
	return _pack(out)


func _intro_taut() -> AudioStreamWAV:
	var dur := 0.28
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := float(i) / RATE
		out[i] = (sin(TAU * 110.0 * t) * 0.45 + sin(TAU * 220.0 * t) * 0.15) * exp(-t * 10.0)
	return _pack(out)


func _intro_door() -> AudioStreamWAV:
	var dur := 0.22
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var prev := 0.0
	for i in range(n):
		var t := float(i) / RATE
		prev = lerpf(prev, _hash_noise(i, 7.0), 0.35)
		var latch := sin(TAU * 900.0 * t) * exp(-t * 70.0) * 0.35
		out[i] = latch + prev * exp(-t * 12.0) * 0.3
	return _pack(out)
```

Replace `IntroPlayer.CUES` with:

```gdscript
const CUES := [
	[3.12, "intro_hook", 1.0, -10.0],
	[3.34, "intro_paws", 1.0, -12.0],
	[5.30, "intro_loop", 1.0, -10.0],
	[6.92, "intro_tap", 1.0, -12.0],
	[7.65, "intro_sigh", 1.0, -14.0],
	[9.22, "bark", 1.0, -3.0],
	[9.30, "intro_taut", 1.0, -8.0],
	[9.44, "intro_door", 1.0, -8.0],
]
```

- [ ] **Step 4: Run the test to verify it passes**

```
& $env:GODOT --headless --path . --script res://tests/test_intro_polish.gd
```

Expected: `test_intro_polish: OK`, exit code 0.

- [ ] **Step 5: Commit**

```
git add autoload/sfx.gd intro/intro_player.gd tests/test_intro_polish.gd tests/test_intro_polish.gd.uid .github/workflows/ci.yml
```

`commit-msg.txt`:

```
Give the intro cues that match the picture

The hook, the landing, the sigh, the leash and the door were gameplay blips.
```

```
git -c alias.cm=commit cm -F commit-msg.txt
```

---

### Task 3: Handoff into the title theme

**Files:**
- Modify: `autoload/sfx.gd` (`handoff`, `prepare_intro`, `_process`, `_crossfade`)
- Modify: `main.gd` (`_music_cue`)
- Modify: `intro/intro_player.gd` (`_ready`, `_process`, `_input`)
- Test: `tests/test_intro_polish.gd`

**Interfaces:**
- Consumes: `Music.job("intro")`, `IntroPlayer.END_AT` (14.4), `main.intro_playing`
- Produces:
  - `Sfx.prepare_intro() -> void` renders `"intro"` into `_music_cache` if it is missing.
  - `Sfx.handoff(from_sec: float, fade_sec: float) -> void` latches `_handoff_on`, `_handoff_from`, `_handoff_fade`. A `from_sec` of 0 stops the current music players when they exist. Music off returns without latching.
  - While `intro_playing`, `main._music_cue()` returns `"intro"`. `_music_next()` still returns `"title"`.

- [ ] **Step 1: Write the failing test**

In `tests/test_intro_polish.gd`, call `_handoff()` from `_initialize` after `_cues()`, and add:

```gdscript
func _handoff() -> void:
	Sfx.prepare_intro()
	_check(Sfx._music_cache.has("intro"), "the phrase is rendered")
	var stream: AudioStreamWAV = Sfx._music_cache["intro"]
	_check(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "cached phrase does not loop")
	Sfx.handoff(14.4, 0.45)
	_check(Sfx._handoff_on, "a finished film waits to hand off")
	_check(is_equal_approx(Sfx._handoff_from, 14.4), "the title continues at 14.4")
	_check(is_equal_approx(Sfx._handoff_fade, 0.45), "the handoff fade is 0.45")
	Sfx.handoff(0.0, 0.45)
	_check(is_equal_approx(Sfx._handoff_from, 0.0), "a skip starts the title at the top")
	Sfx._handoff_on = false
```

- [ ] **Step 2: Run the test to verify it fails**

```
& $env:GODOT --headless --path . --script res://tests/test_intro_polish.gd
```

Expected: exit code 1, because `Sfx.prepare_intro` does not exist. Parse errors fail the script the same way.

- [ ] **Step 3: Wire the phrase and the handoff**

In `autoload/sfx.gd`, next to the other music state:

```gdscript
var _fade_len := MUSIC_FADE
var _handoff_on := false
var _handoff_from := 0.0
var _handoff_fade := MUSIC_FADE
```

Add:

```gdscript
# the film's phrase, finished before the first frame so the marimba is already playing
func prepare_intro() -> void:
	if _music_cache.has("intro"):
		return
	var j := Music.job("intro")
	j.run()
	_music_cache["intro"] = j.stream


# from_sec 0 is a skip: silence now, title from the top once it is ready.
# any other value keeps the phrase going and seeks the title loop there.
func handoff(from_sec: float, fade_sec: float) -> void:
	if not music_on:
		return
	_handoff_on = true
	_handoff_from = from_sec
	_handoff_fade = fade_sec
	if from_sec <= 0.0 and music_player != null:
		music_player.stop()
		_music_out.stop()
		_music_now = ""
		_fade_in = 0.0
		_fade_out = 0.0
```

In `_process`, replace the block that crossfades when `_music_want != _music_now` with:

```gdscript
	elif _music_want != _music_now and music_on:
		if _handoff_on and _music_want != "title":
			pass
		elif _music_want == "" or _music_cache.has(_music_want):
			var from := 0.0
			var fade := -1.0
			if _handoff_on and _music_want == "title":
				from = _handoff_from
				fade = _handoff_fade
				_handoff_on = false
			_crossfade(_music_want, from, fade)
```

Replace the two fade steps that divide by `MUSIC_FADE`:

```gdscript
	_fade_in = minf(1.0, _fade_in + delta / _fade_len)
	_fade_out = maxf(0.0, _fade_out - delta / _fade_len)
```

Replace `_crossfade` so the handoff can seek and can use its own fade. `fade_sec < 0` means `MUSIC_FADE`.

```gdscript
func _crossfade(loop_name: String, from_sec := 0.0, fade_sec := -1.0) -> void:
	_music_now = loop_name
	if music_player.playing and not (_music_out.playing and _fade_out > _fade_in):
		var t := _music_out
		_music_out = music_player
		music_player = t
		_fade_out = _fade_in
	music_player.stop()
	_fade_in = 0.0
	_fade_len = fade_sec if fade_sec > 0.0 else MUSIC_FADE
	if loop_name != "" and music_on:
		music_player.stream = _music_cache[loop_name]
		music_player.play(from_sec)
```

`_play_sting` calls `_crossfade("")`. That still matches the default arguments.

In `main.gd`, change the intro branch of `_music_cue`:

```gdscript
	if intro_playing:
		return "intro"
```

Leave `_music_next` returning `"title"` during the intro. Update its comment to say the phrase is playing and the full title theme is the one being built.

In `intro/intro_player.gd`:

Add `var skipped := false`.

At the end of `_ready`, after `intro_playing` is set:

```gdscript
	Sfx.prepare_intro()
```

In `_input`, when a press skips, before `done_t = t`:

```gdscript
		skipped = true
		cued = CUES.size()
```

In `_process`, replace the block that clears `intro_playing` with:

```gdscript
	if done_t < 0.0 and t >= END_AT:
		done_t = t
	if done_t >= 0.0 and bool(main.get("intro_playing")):
		main.set("intro_playing", false)
		Sfx.handoff(0.0 if skipped else END_AT, 0.45)
```

The cue `while` stays above this block, so a skip that already set `cued` to `CUES.size()` plays nothing further.

- [ ] **Step 4: Run the tests**

```
& $env:GODOT --headless --path . --script res://tests/test_intro_polish.gd
& $env:GODOT --headless --path . --script res://tests/test_music.gd
```

Expected: both print `OK` and exit 0.

- [ ] **Step 5: Commit**

```
git add autoload/sfx.gd main.gd intro/intro_player.gd tests/test_intro_polish.gd
```

`commit-msg.txt`:

```
Continue the title theme out of the intro

The film plays the opening, and the menu band joins that beat instead of restarting the tune.
```

```
git -c alias.cm=commit cm -F commit-msg.txt
```

---

### Task 4: Yank camera

**Files:**
- Modify: `intro/scene_walkies.gd` (`camera`)
- Test: `tests/test_intro_polish.gd`

**Interfaces:**
- Consumes: `Anim.k` key lists `[time, value, ease]`
- Produces: `SceneWalkies.camera(t) -> [Vector2, float]`

- [ ] **Step 1: Write the failing test**

In `tests/test_intro_polish.gd`, call `_camera()` from `_initialize`, and add:

```gdscript
func _camera() -> void:
	var close: Array = SceneWalkies.camera(9.04)
	_check((close[0] as Vector2).is_equal_approx(Vector2(570, 455)), "close on the crouch")
	_check(is_equal_approx(float(close[1]), 1.75), "close zoom")
	var wide: Array = SceneWalkies.camera(9.22)
	_check((wide[0] as Vector2).is_equal_approx(Vector2(800, 420)), "wide on the yank")
	_check(is_equal_approx(float(wide[1]), 1.12), "wide zoom")
	var held: Array = SceneWalkies.camera(9.5)
	_check((held[0] as Vector2).is_equal_approx(Vector2(800, 420)), "the wide frame holds")
	var street: Array = SceneWalkies.camera(10.1)
	_check((street[0] as Vector2).is_equal_approx(Vector2(640, 360)), "the street is still a cut")
	_check(is_equal_approx(float(street[1]), 1.0), "street zoom")
```

- [ ] **Step 2: Run the test to verify it fails**

```
& $env:GODOT --headless --path . --script res://tests/test_intro_polish.gd
```

Expected: exit code 1. At 9.04 the current camera is still on the move back toward the sofa, and at 9.22 the hard cut has not happened yet (`t >= 9.25`).

- [ ] **Step 3: Ease into the wide frame**

Replace `camera`. The street cut stays first. The `t >= 9.25` branch goes away. The three tracks hold the close values until 9.04 and arrive at the wide values at 9.22.

```gdscript
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return [Vector2(640, 360), 1.0]
	var cx: float = Anim.k(t, [[0.0, 720.0], [2.2, 720.0], [2.7, 930.0, "io"], [3.45, 930.0], [4.9, 620.0, "io"],
		[8.55, 620.0], [8.95, 570.0, "io"], [9.04, 570.0], [9.22, 800.0, "io"]])
	var cy: float = Anim.k(t, [[0.0, 430.0], [2.2, 430.0], [2.7, 445.0, "io"], [4.9, 450.0, "io"], [8.55, 450.0],
		[8.95, 455.0, "io"], [9.04, 455.0], [9.22, 420.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [2.2, 1.2], [2.7, 1.6, "io"], [3.45, 1.6], [4.9, 1.45, "io"], [8.55, 1.45],
		[8.95, 1.75, "io"], [9.04, 1.75], [9.22, 1.12, "io"]])
	return [Vector2(cx, cy), z]
```

Update the comment above `camera` so it describes the ease into the yank and the cut to the street.

- [ ] **Step 4: Run the test to verify it passes**

```
& $env:GODOT --headless --path . --script res://tests/test_intro_polish.gd
```

Expected: `test_intro_polish: OK`, exit code 0.

- [ ] **Step 5: Commit**

```
git add intro/scene_walkies.gd tests/test_intro_polish.gd
```

`commit-msg.txt`:

```
Ease the intro camera into the yank

The bark lands in the wide frame, and the street is still the white flash.
```

```
git -c alias.cm=commit cm -F commit-msg.txt
```

---

### Task 5: Set and margin

**Files:**
- Modify: `intro/scene_walkies.gd` (`_room`, `_sofa`, `_light`, `_street`, and the draw order)
- Modify: `intro/intro_player.gd` (`Stage._draw`)
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: `SceneWalkies.camera` from Task 4, `SceneWalkies.TITLE_AT`, `MillieSide.ellipse(center, radii)`
- Produces: no new functions other than `_house` and `_window_light` inside `scene_walkies.gd`. `Stage._draw` clears to the top wall color before `TITLE_AT` and the top sky color from then on.

There is no headless pixel test. Drawing from outside `_draw` errors, and the render tests need a real context. This task's check is the frame render below, then the feel card on a plain launch.

- [ ] **Step 1: Extend the room**

Near the other consts:

```gdscript
const MARGIN := Rect2(-800, -1100, 3000, 2900) # (-800, -1100) to (2200, 1800)
```

In `_room`, replace the wall loop, delete the floor-light polygon (the `draw_colored_polygon` from `(150, 360)` to `(560, FLOOR + 60)`), and widen the skirting, floor and floorboard lines to `MARGIN`. Above the wall, one rect of the top wall color. Below the floorboards, the floor color runs to `MARGIN.end.y`. Keep the eight floorboard lines.

```gdscript
	var wall_top := Color(0.86, 0.78, 0.66)
	var wall_bot := Color(0.95, 0.88, 0.76)
	c.draw_rect(Rect2(MARGIN.position.x, MARGIN.position.y, MARGIN.size.x, -MARGIN.position.y), wall_top)
	for i in range(8):
		var f := float(i) / 7.0
		c.draw_rect(Rect2(MARGIN.position.x, f * FLOOR, MARGIN.size.x, FLOOR / 7.0 + 1.0), wall_top.lerp(wall_bot, f))
```

The window frame under that loop stays. Then the picture, then:

```gdscript
	c.draw_rect(Rect2(MARGIN.position.x, FLOOR - 18, MARGIN.size.x, 18), Color(0.96, 0.93, 0.86))
	c.draw_rect(Rect2(MARGIN.position.x, FLOOR, MARGIN.size.x, MARGIN.end.y - FLOOR), Color(0.62, 0.44, 0.29))
	for k in range(8):
		var y := FLOOR + 8.0 + float(k) * 20.0
		c.draw_line(Vector2(MARGIN.position.x, y), Vector2(MARGIN.end.x, y), Color(0.52, 0.36, 0.23), 2.0)
```

Replace `c.draw_rect(DOOR.grow(12.0), ...)` with the jamb, outer then inner lip. The swinging panel below it is unchanged.

```gdscript
	c.draw_rect(DOOR.grow(18.0), Color(0.52, 0.36, 0.24))
	c.draw_rect(DOOR.grow(6.0), Color(0.44, 0.30, 0.20))
```

- [ ] **Step 2: Seat shadow and one window light**

At the start of `_sofa`, before the legs:

```gdscript
	c.draw_colored_polygon(MillieSide.ellipse(Vector2(SOFA_X + 40.0, FLOOR - 2.0), Vector2(158, 9)),
		Color(0.42, 0.28, 0.16, 0.35))
```

`ellipse` takes radii, so `Vector2(158, 9)` is 316 wide and 18 tall.

Replace `_light` with the edge shade only. The shade stays on the old room sides and grows to the margin's height. The four stacked shafts go away.

```gdscript
static func _light(c: CanvasItem) -> void:
	for i in range(6):
		var w := 40.0 + float(i) * 40.0
		c.draw_rect(Rect2(-200, MARGIN.position.y, w, MARGIN.size.y), Color(0.20, 0.12, 0.08, 0.035))
		c.draw_rect(Rect2(1480 - w, MARGIN.position.y, w, MARGIN.size.y), Color(0.20, 0.12, 0.08, 0.035))


static func _window_light(c: CanvasItem) -> void:
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(150, 360), Vector2(360, 360), Vector2(SOFA_X + 40, FLOOR + 70), Vector2(SOFA_X - 118, FLOOR),
	]), Color(1.0, 0.95, 0.78, 0.22))
```

In `draw`, call `_window_light(c)` immediately after `_sofa(c)`, before the characters, so the light lands on the sofa and the floor and the dog is drawn over it.

- [ ] **Step 3: Extend the street without moving the houses in frame**

Replace `_street`. Houses that start at x = -120 with k = 0 stay on that sequence. Houses to the left use negative k and `posmod`, so the row inside the frame does not shift. Each house gets one balcony bar under its first window row.

```gdscript
static func _street(c: CanvasItem) -> void:
	var sky_top := Color(0.62, 0.80, 0.92)
	c.draw_rect(Rect2(MARGIN.position.x, MARGIN.position.y, MARGIN.size.x, -MARGIN.position.y), sky_top)
	for i in range(10):
		var f := float(i) / 9.0
		c.draw_rect(Rect2(MARGIN.position.x, f * 420.0, MARGIN.size.x, 420.0 / 9.0 + 1.0),
			sky_top.lerp(Color(0.94, 0.92, 0.84), f))
	var fronts := [Color(0.90, 0.78, 0.60), Color(0.86, 0.66, 0.52), Color(0.92, 0.86, 0.72), Color(0.84, 0.72, 0.60)]
	var lx := -120.0
	var lk := 0
	while lx > MARGIN.position.x:
		lk -= 1
		var lw := 230.0 + float(posmod(lk * 37, 60))
		lx -= lw
		_house(c, lx, lk, fronts)
	var x := -120.0
	var k := 0
	while x < MARGIN.end.x:
		x += _house(c, x, k, fronts)
		k += 1
	c.draw_rect(Rect2(MARGIN.position.x, 0, MARGIN.size.x, 640), Color(0.98, 0.95, 0.88, 0.25))
	for i in range(5):
		var hh := 200.0 - float(i) * 34.0
		c.draw_rect(Rect2(MARGIN.position.x, 330.0 - hh * 0.5, MARGIN.size.x, hh), Color(0.26, 0.16, 0.10, 0.03))
	for tx: float in [110.0, 1170.0]:
		c.draw_rect(Rect2(tx - 6, 470, 12, 170), Color(0.42, 0.34, 0.26))
		for blob: Vector2 in [Vector2(0, -20), Vector2(-46, 6), Vector2(46, 6), Vector2(-22, 34), Vector2(26, 34)]:
			c.draw_circle(Vector2(tx, 470) + blob, 52.0, Color(0.48, 0.64, 0.38))
		c.draw_circle(Vector2(tx - 20, 440), 30.0, Color(0.58, 0.74, 0.44))
	c.draw_line(Vector2(960, 640), Vector2(960, 430), Color(0.22, 0.24, 0.26), 6.0)
	c.draw_circle(Vector2(960, 424), 12.0, Color(0.98, 0.94, 0.78))
	c.draw_rect(Rect2(MARGIN.position.x, 640, MARGIN.size.x, MARGIN.end.y - 640), Color(0.80, 0.76, 0.70))
	c.draw_rect(Rect2(MARGIN.position.x, 700, MARGIN.size.x, 40), Color(0.62, 0.60, 0.58))
	c.draw_rect(Rect2(MARGIN.position.x, 640, MARGIN.size.x, 10), Color(0.45, 0.42, 0.38))
	c.draw_line(Vector2(MARGIN.position.x, 640), Vector2(MARGIN.end.x, 640), IntroKit.INK, 3.0)


static func _house(c: CanvasItem, x: float, k: int, fronts: Array) -> float:
	var w := 230.0 + float(posmod(k * 37, 60))
	var top := 150.0 + float(posmod(k * 53, 70))
	var col: Color = fronts[posmod(k, fronts.size())]
	c.draw_rect(Rect2(x, top, w, 640.0 - top), col)
	c.draw_rect(Rect2(x, top, w, 10), col.darkened(0.12))
	var wy := top + 40.0
	var first := true
	while wy < 560.0:
		var wx := x + 30.0
		while wx < x + w - 50.0:
			c.draw_rect(Rect2(wx, wy, 34, 54), Color(0.46, 0.60, 0.54))
			c.draw_line(Vector2(wx - 6, wy + 56), Vector2(wx + 40, wy + 56), col.darkened(0.35), 3.0)
			wx += 66.0
		if first:
			c.draw_rect(Rect2(x + 16.0, wy + 62.0, w - 32.0, 8.0), col.darkened(0.28))
			first = false
		wy += 96.0
	return w
```

A house in the left loop may start left of `-800` and still cover the edge. The forward loop still starts at x = -120, k = 0, so the houses inside the frame stay on the old sequence. `posmod` matches `%` for those non-negative indexes.

- [ ] **Step 4: Match the clear color to the set**

In `IntroPlayer.Stage._draw`:

```gdscript
	func _draw() -> void:
		var col := Color(0.62, 0.80, 0.92) if t >= SCENE.TITLE_AT else Color(0.86, 0.78, 0.66)
		draw_rect(Rect2(-4000, -4000, 9280, 8720), col)
		scene.draw(self, t)
```

Do not change `_place`.

- [ ] **Step 5: Render frames**

Use the windowed editor, not the console build. This needs a display.

```
$env:GODOTW = (Resolve-Path ..\path-of-leash-resistance\godot\Godot_v4.7-stable_win64.exe).Path
& $env:GODOTW --rendering-method gl_compatibility --path . --script res://tools/intro_render.gd -- walkies $env:TEMP\intro-polish 8 640
```

Expected: frames written, no script error. Look at a room frame and a street frame. The margin past the staged action is wall and floor, then sky and street. The houses behind the title still begin where they did.

Then run the headless tests again:

```
& $env:GODOT --headless --path . --script res://tests/test_intro_polish.gd
& $env:GODOT --headless --path . --script res://tests/test_music.gd
```

Expected: both `OK`.

- [ ] **Step 6: Changelog**

Add at the top of `CHANGELOG.md`, under the title:

```markdown
## 2026-10-12 - the intro fills the window

- The Walkies film keeps its frame fitted inside the window, and the flat and the street paint out to the edges, so a wide or tall window shows more of the room instead of beige. The window throws one patch of light, the sofa sits on a shadow, the door has a jamb, and the street has balconies and a kerb shadow.
- The cut into the yank is a short move that arrives on the bark. The white flash still cuts to the street.
- The film plays the opening of the title theme, marimba and a soft shaker. As it fades, the rest of the band joins at that beat. A skip starts the theme from the top.
- The hook, the landing, the loop, the nose, the sigh, the leash and the door have their own sounds. The title card has no sting.
```

- [ ] **Step 7: Commit**

```
git add intro/scene_walkies.gd intro/intro_player.gd CHANGELOG.md docs/superpowers/specs/2026-10-12-intro-polish-design.md docs/superpowers/plans/2026-10-12-intro-polish.md
```

`commit-msg.txt`:

```
Dress the intro out to the edge of the window

A wide or tall window was a beige margin around a thin set.
```

```
git -c alias.cm=commit cm -F commit-msg.txt
```

- [ ] **Step 8: Feel card, on a plain launch**

Any command-line argument skips the film. Launch with the windowed editor and an empty argument list.

1. A 16:9 window: the film fills the window, the opening still shows Millie by the door and your human on the sofa, and the marimba is already playing before she jumps for the hook.
2. A wide window: the extra space is wall and floor, then sky and street, and both of them stay in the opening shot.
3. A tall window: the extra space is more ceiling and more floor, and the opening shot still holds both of them.
4. The yank is a short move into the wide frame, then the white flash still cuts to the street and the title.
5. The hook, the landing, the sigh, the leash catching and the door are each their own sound. As the film fades, the rest of the title band joins the melody already playing. Skipping drops onto the menu with the theme from the top.

The pull request body carries this feel card. Push `intro-polish` and open the PR against `main`. Do not push `main`.
