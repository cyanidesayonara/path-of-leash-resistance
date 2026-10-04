extends Node

# Procedural sound effects. Every sample is synthesised at startup from
# tones, sweeps and noise - there are no audio assets. A small pool of
# players lets sounds overlap. Autoloaded as `Sfx`, so it builds its
# library once and survives scene reloads.
#
# Synthesis uses a LOCAL RandomNumberGenerator so noise generation never
# touches the global seed (which the deterministic autowalk depends on).

const RATE := 22050
const POOL := 10

var players: Array[AudioStreamPlayer] = []
var next_player := 0
var lib := {}
var rng := RandomNumberGenerator.new()
var muted := false
var music_on := true

# --- the soundtrack (audio/music.gd) ---
# Each loop is synthesised when first wanted: on a thread on desktop, a few
# milliseconds a frame on the web (no threads there). Until it is ready the
# loop before it carries on. main.gd says every frame what should be playing,
# through music_tick(); nothing here knows about walks or menus.
const MUSIC_DB := -17.0          # loops sit under the effects
const MUSIC_FADE := 1.4          # seconds for a crossfade
const MUSIC_KEEP := 6            # loops kept in memory (about 1.6 MB each)
const MUFFLE_HZ := 650.0         # the pause menu hears the music through a door
const BUDGET_PLAY := 2000        # usec of synthesis a frame while walking (web)
const BUDGET_MENU := 7000        # ... and on menus and cards
const BUDGET_HEAVY := 800        # ... on a frame that already ran long
var music_player: AudioStreamPlayer       # the loop playing (or fading in)
var _music_out: AudioStreamPlayer         # the loop fading out
var _jingle: AudioStreamPlayer
var _music_cache := {}                    # name -> AudioStreamWAV
var _music_job: Music.Job
var _music_thread: Thread
var _music_cue := ""
var _music_want := ""                     # the loop that should be playing
var _music_now := ""                      # the loop that is
var _music_next := ""                     # the loop to have ready next
var _music_hold := 0.0                    # seconds a sting keeps the loop away
var _fade_in := 1.0
var _fade_out := 0.0
var _muffle_bus := -1
var _muffled := false
var _menu_budget := true
# no synthesis headless (CI, tests, tools) or while photographing
var music_enabled := DisplayServer.get_name() != "headless" and not "--shot" in OS.get_cmdline_user_args()


func _ready() -> void:
	rng.seed = 0x50FA5EED
	for i in range(POOL):
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		players.append(p)
	_build_library()
	if not music_enabled:
		return
	var bus := _music_bus()
	music_player = AudioStreamPlayer.new()
	_music_out = AudioStreamPlayer.new()
	_jingle = AudioStreamPlayer.new()
	for pl: AudioStreamPlayer in [music_player, _music_out, _jingle]:
		pl.bus = bus
		add_child(pl)


# the music's own bus, so the pause muffle leaves the effects alone
func _music_bus() -> String:
	var bus_name := "Music"
	_muffle_bus = AudioServer.get_bus_index(bus_name)
	if _muffle_bus < 0:
		AudioServer.add_bus()
		_muffle_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_muffle_bus, bus_name)
		AudioServer.set_bus_send(_muffle_bus, "Master")
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = MUFFLE_HZ
		AudioServer.add_bus_effect(_muffle_bus, lp)
		AudioServer.set_bus_effect_enabled(_muffle_bus, 0, false)
	return bus_name


func start_music() -> void:
	apply_music_volume()


func apply_music_volume() -> void:
	if music_player == null:
		return
	var base := MUSIC_DB + linear_to_db(clampf(Game.vol_music, 0.0001, 1.0)) + 6.0
	music_player.volume_db = base + linear_to_db(maxf(_fade_in, 0.0001))
	_music_out.volume_db = base + linear_to_db(maxf(_fade_out, 0.0001))
	_jingle.volume_db = base + 2.0


func toggle_music() -> void:
	music_on = not music_on
	if music_player == null:
		return
	if not music_on:
		music_player.stop()
		_music_out.stop()
		_jingle.stop()
		_music_now = ""


# Called by main every frame. `cue` is the loop that belongs on screen now:
# "" for silence, or "won" / "lost" for an end-of-walk sting, which then gives
# way to the title theme. `next` is the loop to have ready, `paused` muffles
# the music, and `playing` keeps synthesis to a small slice of the frame.
func music_tick(cue: String, next: String, paused: bool, playing: bool) -> void:
	if music_player == null:
		return
	_menu_budget = not playing
	_music_next = next
	if cue != _music_cue:
		_music_cue = cue
		if cue == "won" or cue == "lost":
			_music_want = "title"
			_play_sting(cue)
		else:
			_music_want = cue
			_music_hold = 0.0
			_jingle.stop()
	if _muffled != paused:
		_muffled = paused
		AudioServer.set_bus_effect_enabled(_muffle_bus, 0, paused)


func _play_sting(sting: String) -> void:
	# the walk's loop gets out of the way
	_crossfade("")
	_music_hold = 1.5
	if music_on and _music_cache.has(sting):
		_jingle.stream = _music_cache[sting]
		_jingle.play()
		_music_hold = _jingle.stream.get_length() + 1.2


func _process(delta: float) -> void:
	if music_player == null:
		return
	_music_work(delta)
	if _music_hold > 0.0:
		_music_hold -= delta
	elif _music_want != _music_now and music_on:
		if _music_want == "" or _music_cache.has(_music_want):
			_crossfade(_music_want)
	_fade_in = minf(1.0, _fade_in + delta / MUSIC_FADE)
	_fade_out = maxf(0.0, _fade_out - delta / MUSIC_FADE)
	if _fade_out <= 0.0 and _music_out.playing:
		_music_out.stop()
	apply_music_volume()


# swap the players: the old loop fades out where it is, the new one fades in.
# Mid-crossfade, the quieter of the two is the one cut.
func _crossfade(loop_name: String) -> void:
	_music_now = loop_name
	if music_player.playing and not (_music_out.playing and _fade_out > _fade_in):
		var t := _music_out
		_music_out = music_player
		music_player = t
		_fade_out = _fade_in
	music_player.stop()
	_fade_in = 0.0
	if loop_name != "" and music_on:
		music_player.stream = _music_cache[loop_name]
		music_player.play()


# Keep one track rendering: the loop wanted now, then the next one, then the
# stings. Finished tracks go in the cache, which keeps the few in use.
func _music_work(delta: float) -> void:
	if _music_job != null:
		if _music_thread != null:
			if _music_job.done():
				_music_thread.wait_to_finish()
				_music_thread = null
				_music_finish()
			return
		var budget := BUDGET_MENU if _menu_budget else BUDGET_PLAY
		if delta > 1.0 / 40.0:
			budget = BUDGET_HEAVY
		if _music_job.step(budget):
			_music_finish()
		return
	for track: String in [_music_want, _music_next, "won", "lost"]:
		if track != "" and not _music_cache.has(track):
			_music_job = Music.job(track)
			if not OS.has_feature("web"):
				_music_thread = Thread.new()
				_music_thread.start(_music_job.run, Thread.PRIORITY_LOW)
			return


func _music_finish() -> void:
	_music_cache[_music_job.name] = _music_job.stream
	_music_job = null
	if _music_cache.size() > MUSIC_KEEP:
		for k: String in _music_cache.keys():
			if not k in [_music_want, _music_now, _music_next, "won", "lost"]:
				_music_cache.erase(k)
				break


func _exit_tree() -> void:
	if _music_thread != null:
		_music_job.cancel = true
		_music_thread.wait_to_finish()


func play(name: String, pitch := 1.0, vol_db := -6.0) -> void:
	if muted:
		return
	var s: AudioStreamWAV = lib.get(name)
	if s == null:
		return
	var p := players[next_player]
	next_player = (next_player + 1) % players.size()
	p.stream = s
	p.pitch_scale = clampf(pitch * rng.randf_range(0.96, 1.05), 0.5, 2.0)
	# the player's effects volume rides on top of whatever the caller asked
	# for, so a quiet sound stays relatively quiet
	p.volume_db = vol_db + linear_to_db(clampf(Game.vol_sfx, 0.0001, 1.0))
	p.play()


func _build_library() -> void:
	lib["bark"] = _bark()
	lib["pickup"] = _coin(880.0, 1320.0, 0.10)
	lib["mark"] = _coin(500.0, 680.0, 0.09)
	lib["snack"] = _coin(640.0, 480.0, 0.10)
	lib["fetch"] = _coin(700.0, 1050.0, 0.15)
	lib["fling"] = _whoosh(0.30)
	lib["crack"] = _noiseburst(0.14, 34.0)
	lib["splash"] = _splash(0.28)
	lib["combo"] = _arp([660.0, 880.0, 1100.0, 1320.0], 0.055)
	lib["star"] = _arp([880.0, 1320.0, 1760.0], 0.11)
	lib["save"] = _arp([1046.0, 1568.0], 0.10)
	lib["ui"] = _tone(560.0, 0.05, 40.0, 0.35)
	lib["tangle"] = _wobble(0.26)
	lib["hiss"] = _noiseburst(0.16, 22.0)
	lib["grunt"] = _grunt()
	lib["squawk"] = _squawk()
	# a paw going into mud: a short, low, wet suck
	lib["squelch"] = _squelch()
	# grass brushed through, and sand underfoot: short, soft noise
	lib["rustle"] = _noiseburst(0.20, 12.0)
	lib["grit"] = _noiseburst(0.07, 46.0)


func _pack(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	return s


func _tone(freq: float, dur: float, decay: float, amp := 0.5) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := float(i) / RATE
		out[i] = sin(TAU * freq * t) * exp(-t * decay) * amp
	return _pack(out)


func _coin(f0: float, f1: float, dur: float) -> AudioStreamWAV:
	# a two-note blip: the classic pickup ding
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var split := int(n * 0.35)
	for i in range(n):
		var t := float(i) / RATE
		var f := f0 if i < split else f1
		out[i] = sin(TAU * f * t) * exp(-t * 12.0) * 0.5
	return _pack(out)


func _arp(freqs: Array, note: float) -> AudioStreamWAV:
	# an ascending arpeggio - success / combo
	var per := int(note * RATE)
	var out := PackedFloat32Array()
	out.resize(per * freqs.size())
	for k in range(freqs.size()):
		var f: float = freqs[k]
		for i in range(per):
			var t := float(i) / RATE
			out[k * per + i] = sin(TAU * f * t) * exp(-t * 9.0) * 0.5
	return _pack(out)


func _squelch() -> AudioStreamWAV:
	var dur := 0.14
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	var noise := 0.0
	for i in range(n):
		var prog := float(i) / float(n)
		ph += TAU * lerpf(260.0, 120.0, prog) / RATE
		# filtered noise for the wet part, a falling tone for the suck
		noise = noise * 0.85 + (fmod(sin(float(i) * 12.9898) * 43758.5453, 1.0) - 0.5) * 0.15
		out[i] = (sin(ph) * 0.5 + noise * 1.6) * sin(PI * prog) * 0.35
	return _pack(out)


func _squawk() -> AudioStreamWAV:
	# a parakeet: a harsh up-and-down screech, clipped so it rasps
	var dur := 0.12
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	for i in range(n):
		var prog := float(i) / float(n)
		ph += TAU * (1700.0 + sin(PI * prog) * 1100.0) / RATE
		out[i] = clampf(sin(ph) * 2.2, -1.0, 1.0) * sin(PI * prog) * 0.3
	return _pack(out)


func _bark() -> AudioStreamWAV:
	# a short woof: a fast downward pitch with a little grit
	var dur := 0.16
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := float(i) / RATE
		var prog := t / dur
		var f := lerpf(420.0, 180.0, prog)
		var env := sin(PI * prog)  # swell in and out
		var grit := rng.randf_range(-0.15, 0.15)
		out[i] = (sin(TAU * f * t) * 0.7 + grit) * env * 0.6
	return _pack(out)


func _grunt() -> AudioStreamWAV:
	# a boar: a low throaty rasp that pulses, two short snorts
	var dur := 0.34
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := float(i) / RATE
		var prog := t / dur
		var pulse := maxf(0.0, sin(TAU * 2.9 * t)) # two snorts
		var f := lerpf(110.0, 80.0, prog)
		var rasp := rng.randf_range(-0.5, 0.5) * (0.5 + 0.5 * sin(TAU * 38.0 * t))
		out[i] = (sin(TAU * f * t) * 0.6 + rasp) * pulse * (1.0 - prog * 0.5) * 0.6
	return _pack(out)


func _whoosh(dur: float) -> AudioStreamWAV:
	# filtered noise that swells then fades - a fling/whip
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var prev := 0.0
	for i in range(n):
		var prog := float(i) / n
		var env := sin(PI * prog)
		var raw := rng.randf_range(-1.0, 1.0)
		prev = lerpf(prev, raw, 0.25)  # crude low-pass
		out[i] = prev * env * 0.5
	return _pack(out)


func _splash(dur: float) -> AudioStreamWAV:
	# a soft burst of low-passed noise with a quick decay
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var prev := 0.0
	for i in range(n):
		var t := float(i) / RATE
		var raw := rng.randf_range(-1.0, 1.0)
		prev = lerpf(prev, raw, 0.15)
		out[i] = prev * exp(-t * 14.0) * 0.6
	return _pack(out)


func _noiseburst(dur: float, decay: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := float(i) / RATE
		out[i] = rng.randf_range(-1.0, 1.0) * exp(-t * decay) * 0.5
	return _pack(out)


func _wobble(dur: float) -> AudioStreamWAV:
	# a boingy pitch wobble - the tangle
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := float(i) / RATE
		var f := 300.0 + sin(t * 40.0) * 120.0
		out[i] = sin(TAU * f * t) * exp(-t * 8.0) * 0.5
	return _pack(out)
