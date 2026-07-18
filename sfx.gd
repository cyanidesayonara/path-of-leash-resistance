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
var music_player: AudioStreamPlayer
var music_on := true


func _ready() -> void:
	rng.seed = 0x50FA5EED
	for i in range(POOL):
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		players.append(p)
	_build_library()
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -16.0  # ambient, well under the SFX
	music_player.stream = _build_music()
	add_child(music_player)


func start_music() -> void:
	if music_on and music_player != null and not music_player.playing:
		music_player.play()


func toggle_music() -> void:
	music_on = not music_on
	if music_on:
		music_player.play()
	else:
		music_player.stop()


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
	p.volume_db = vol_db
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


# --- music -------------------------------------------------------------

func _build_music() -> AudioStreamWAV:
	# a gentle, looping ambient bed: soft sine bass + a quiet fifth pad
	# under a sparse C-pentatonic melody, over an I-vi-IV-V progression.
	# Deliberately calm so it never grates on repeat.
	var beat := 60.0 / 80.0        # 80 BPM
	var bar := beat * 4.0
	var bars := 8
	var n := int(bar * bars * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	# roots for C - Am - F - G, twice
	var roots := [130.81, 110.0, 87.31, 98.0, 130.81, 110.0, 87.31, 98.0]
	var pent := [261.63, 293.66, 329.63, 392.0, 440.0]  # C D E G A
	for b in range(bars):
		var root: float = roots[b]
		var base := int(b * bar * RATE)
		var bn := int(bar * RATE)
		for i in range(bn):
			var idx := base + i
			if idx >= n:
				break
			var t := float(i) / RATE
			var swell: float = sin(PI * clampf(t / bar, 0.0, 1.0))  # breathe per bar
			var bass := sin(TAU * root * t) * 0.16 * (0.6 + 0.4 * swell)
			var pad := (sin(TAU * root * 1.5 * t) + sin(TAU * root * 2.0 * t)) * 0.03 * swell
			out[idx] += bass + pad
		# sparse melody: a soft pentatonic note on a couple of beats
		for nb in [0, 2, 3]:
			if rng.randf() < 0.55:
				var mf: float = pent[rng.randi() % pent.size()]
				var mbase := base + int(nb * beat * RATE)
				var mn := int(beat * 0.9 * RATE)
				for i in range(mn):
					var idx := mbase + i
					if idx >= n:
						break
					var t := float(i) / RATE
					out[idx] += sin(TAU * mf * t) * exp(-t * 3.2) * 0.14
	var s := _pack(out)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = n
	return s


# --- synthesis helpers -------------------------------------------------

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
