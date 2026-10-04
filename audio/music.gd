class_name Music
extends RefCounted

# THE SOUNDTRACK, synthesised like everything else: no audio files. A small
# tracker. One tune (sixteen bars, A and B), arranged per walk - the same
# melody dressed as a bossa on the seafront, a Spanish guitar piece in the old
# town, a rumba catalana in the Güell park, and so on - played on a handful of
# instruments built from first principles: plucked strings (Karplus-Strong)
# for guitar and bass, struck bars (damped resonators) for marimba, vibes and
# glockenspiel, a reed for the accordion and the pads, a whistle, and noise
# for the percussion. Mono, with a small room reverb, handed back as a
# seamless loop.
#
# A track takes a second or more to build, which the game cannot spend in one
# frame, so `Job` renders it a slice at a time: `step(budget_usec)` does as
# much as fits and returns true when the stream is ready. Everything is
# deterministic (no global RNG), so a style always sounds the same.

const RATE := 22050
const CHUNK := 1024          # samples rendered per slice; must be even
const TAIL := 3.0            # seconds rendered past the loop, folded onto its start
const TARGET_RMS := 0.15     # every track as loud as every other
const HUMAN_T := 0.006       # timing looseness, seconds
const HUMAN_V := 0.1         # velocity looseness

# the tune, in D major. Notes are [start beat, length in beats, MIDI note];
# chords are one per bar, as [root MIDI, quality].
const MELODY_A := [
	[0.0, 1.0, 78], [1.0, 0.5, 81], [1.5, 0.5, 78], [2.0, 1.0, 76], [3.0, 1.0, 74],
	[4.0, 1.5, 71], [5.5, 0.5, 74], [6.0, 2.0, 78],
	[8.0, 1.0, 79], [9.0, 0.5, 78], [9.5, 0.5, 76], [10.0, 1.0, 74], [11.0, 1.0, 71],
	[12.0, 1.0, 69], [13.0, 1.0, 73], [14.0, 2.0, 76],
	[16.0, 1.0, 78], [17.0, 0.5, 81], [17.5, 0.5, 78], [18.0, 1.0, 76], [19.0, 1.0, 74],
	[20.0, 1.0, 71], [21.0, 1.0, 74], [22.0, 1.0, 78], [23.0, 1.0, 83],
	[24.0, 1.0, 81], [25.0, 1.0, 79], [26.0, 1.0, 78], [27.0, 1.0, 76],
	[28.0, 3.0, 74],
]
const MELODY_B := [
	[0.0, 1.5, 83], [1.5, 0.5, 81], [2.0, 1.0, 79], [3.0, 1.0, 78],
	[4.0, 1.5, 76], [5.5, 0.5, 78], [6.0, 2.0, 81],
	[8.0, 1.0, 81], [9.0, 1.0, 78], [10.0, 2.0, 73],
	[12.0, 1.0, 74], [13.0, 1.0, 78], [14.0, 2.0, 83],
	[16.0, 1.0, 83], [17.0, 1.0, 81], [18.0, 1.0, 79], [19.0, 1.0, 78],
	[20.0, 1.0, 76], [21.0, 1.0, 78], [22.0, 1.0, 79], [23.0, 1.0, 81],
	[24.0, 2.0, 83], [26.0, 1.0, 86], [27.0, 1.0, 85],
	[28.0, 4.0, 81],
]
const CHORDS_A := [[62, "maj"], [59, "min"], [55, "maj"], [57, "maj"], [62, "maj"], [59, "min"], [64, "min"], [62, "maj"]]
const CHORDS_B := [[55, "maj"], [57, "maj"], [54, "min"], [59, "min"], [55, "maj"], [57, "maj"], [59, "min"], [57, "maj"]]

# how each walk wears the tune. key: semitones from D. lead2 doubles the
# melody through the B section (instrument, octave). swing: how late the
# off-beat quavers fall, as a fraction of a beat.
const STYLES := {
	"title": {"bpm": 104, "key": 0, "lead": "marimba", "lead2": ["glock", 12], "comp": "arp",
		"bass": "walk", "drums": "shaker", "verb": 0.22},
	"barri": {"bpm": 100, "key": -2, "lead": "whistle", "lead2": ["marimba", 0], "comp": "arp",
		"bass": "walk", "drums": "brush", "swing": 0.12, "verb": 0.2},
	"street": {"bpm": 112, "key": 3, "lead": "marimba", "comp": "skank", "bass": "root",
		"drums": "kickrim", "verb": 0.18},
	"park": {"bpm": 96, "key": 5, "lead": "glock", "lead2": ["whistle", -12], "comp": "arp",
		"bass": "root", "drums": "brush", "verb": 0.3},
	"beach": {"bpm": 96, "key": 0, "lead": "vibes", "comp": "bossa", "bass": "bossa",
		"drums": "rim", "verb": 0.28},
	"rain": {"bpm": 84, "key": 0, "minor": true, "lead": "vibes", "comp": "pad", "bass": "root",
		"drums": "brushsoft", "verb": 0.42},
	"market": {"bpm": 120, "key": 5, "lead": "accordion", "comp": "oompah", "bass": "oompah",
		"drums": "shaker", "verb": 0.18},
	"oldtown": {"bpm": 112, "key": 0, "minor": true, "lead": "guitar", "comp": "rasgueado",
		"bass": "root", "drums": "castanets", "verb": 0.3},
	"trail": {"bpm": 88, "key": 5, "lead": "glock", "lead2": ["whistle", -12], "comp": "arp",
		"bass": "root", "drums": "none", "verb": 0.4},
	"station": {"bpm": 124, "key": 2, "lead": "vibes", "comp": "skank", "bass": "walk",
		"drums": "train", "verb": 0.3},
	"site": {"bpm": 116, "key": -2, "lead": "marimba", "comp": "stab", "bass": "oompah",
		"drums": "kickrim", "verb": 0.16},
	"spook": {"bpm": 80, "key": 0, "minor": true, "lead": "glock", "comp": "pad", "bass": "root",
		"drums": "none", "verb": 0.5},
	"scrap": {"bpm": 108, "key": 3, "minor": true, "lead": "guitar", "comp": "stab", "bass": "walk",
		"drums": "kickrim", "verb": 0.2},
	"guell": {"bpm": 104, "key": 5, "lead": "guitar", "lead2": ["whistle", 0], "comp": "rumba",
		"bass": "root", "drums": "claps", "verb": 0.26},
	"neteja": {"bpm": 132, "key": 0, "minor": true, "lead": "marimba", "comp": "skank",
		"bass": "eighths", "drums": "drive", "verb": 0.16},
	"freedom": {"bpm": 120, "key": 5, "lead": "whistle", "lead2": ["glock", 12], "comp": "arp",
		"bass": "walk", "drums": "kickrim", "swing": 0.1, "verb": 0.22},
}

# the end-of-walk stings: [beat, length, MIDI, instrument]; not loops
const JINGLES := {
	"won": {"bpm": 112, "verb": 0.25, "notes": [
		[0.0, 0.5, 74, "marimba"], [0.5, 0.5, 78, "marimba"], [1.0, 0.5, 81, "marimba"],
		[1.5, 2.5, 86, "marimba"], [1.5, 2.5, 86, "glock"],
		[1.5, 2.5, 62, "pluck"], [1.5, 2.5, 66, "pluck"], [1.5, 2.5, 69, "pluck"], [0.0, 1.5, 38, "bass"],
		[1.5, 2.5, 38, "bass"]]},
	"lost": {"bpm": 76, "verb": 0.3, "notes": [
		[0.0, 0.9, 69, "reed"], [1.0, 0.9, 68, "reed"], [2.0, 0.9, 67, "reed"], [3.0, 2.5, 66, "reed"],
		[3.0, 2.5, 50, "pluck"], [3.0, 2.5, 53, "pluck"], [3.0, 2.5, 57, "pluck"], [3.0, 2.5, 38, "bass"]]},
}


# --- the score: what plays when ---------------------------------------------

static func is_style(name: String) -> bool:
	return STYLES.has(name)


static func job(name: String) -> Job:
	var j := Job.new()
	j.name = name
	if JINGLES.has(name):
		_jingle(j, JINGLES[name])
	else:
		_arrange(j, STYLES.get(name, STYLES["title"]))
	j.events.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	return j


# the whole track in one call (tools, tests)
static func render_stream(name: String) -> AudioStreamWAV:
	var j := job(name)
	while not j.step(1000000):
		pass
	return j.stream


static func _hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


static func _chord_notes(root: int, quality: String) -> Array:
	match quality:
		"min": return [root, root + 3, root + 7]
		"maj7": return [root, root + 4, root + 7, root + 11]
		"min7": return [root, root + 3, root + 7, root + 10]
	return [root, root + 4, root + 7]


# D major to D minor: F# down to F, B down to Bb, keep C# (harmonic minor)
static func _minor_note(m: int) -> int:
	var pc := posmod(m - 62, 12)
	if pc == 4 or pc == 9:
		return m - 1
	return m


static func _minor_chord(ch: Array) -> Array:
	var r: int = ch[0]
	match posmod(r - 62, 12):
		0: return [r, "min"]            # D -> Dm
		9: return [r - 1, "maj"]        # Bm -> Bb
		5: return [r, "min"]            # G -> Gm
		7: return [r, "maj"]            # A stays A
		2: return [r + 3, "min"]        # Em -> Gm
		4: return [r - 1, "maj"]        # F#m -> F
	return ch


static func _arrange(j: Job, st: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(st))
	j.seed = rng.randi()
	var beat := 60.0 / float(st["bpm"])
	var bars := 16
	j.n = int(beat * 4.0 * float(bars) * RATE)
	j.n += j.n % 2
	j.total = j.n + int(TAIL * RATE)
	j.total += (4 - j.total % 4) % 4
	j.verb_wet = float(st["verb"])
	var key: int = st.get("key", 0)
	var minor: bool = st.get("minor", false)
	var swing: float = st.get("swing", 0.0)
	var chords: Array = []
	for ch in CHORDS_A + CHORDS_B:
		var c2: Array = _minor_chord(ch) if minor else ch
		chords.append([int(c2[0]) + key, c2[1]])
	# a beat position to a sample, swung and loosened
	var at := func(pos: float, loose := 1.0) -> int:
		var whole := floorf(pos)
		var frac := pos - whole
		if is_equal_approx(frac, 0.5):
			frac += swing
		var t := (whole + frac) * beat + rng.randf_range(-HUMAN_T, HUMAN_T) * loose
		return maxi(0, int(t * RATE))
	var vel := func(v: float) -> float:
		return v * rng.randf_range(1.0 - HUMAN_V, 1.0 + HUMAN_V)
	# the melody, and its double through the B section
	var lead: String = st["lead"]
	var lead2: Array = st.get("lead2", [])
	var mel: Array = []
	for nt in MELODY_A:
		mel.append([float(nt[0]), float(nt[1]), int(nt[2])])
	for nt in MELODY_B:
		mel.append([float(nt[0]) + 32.0, float(nt[1]), int(nt[2])])
	for nt: Array in mel:
		var m: int = (_minor_note(nt[2]) if minor else int(nt[2])) + key
		var s: int = at.call(nt[0])
		var d: float = nt[1] * beat
		_lead(j, lead, s, m, d, vel.call(1.0))
		if not lead2.is_empty() and nt[0] >= 32.0:
			_lead(j, lead2[0], s, m + int(lead2[1]), d, vel.call(0.55))
	for b in range(bars):
		var ch: Array = chords[b]
		var root: int = ch[0]
		var q: String = ch[1]
		var notes := _chord_notes(root, q)
		var b0 := float(b) * 4.0
		_comp(j, String(st["comp"]), b0, root, q, notes, beat, at, vel)
		_bass(j, String(st["bass"]), b0, root, q, beat, at, vel)
		_drums(j, String(st["drums"]), b, b0, at, vel)


static func _lead(j: Job, inst: String, s: int, m: int, d: float, v: float) -> void:
	match inst:
		"marimba", "glock", "vibes":
			j.add(s, "bar", [m, v * 0.3, inst])
		"guitar":
			j.add(s, "pluck", [m - 12, d + 0.35, v * 0.5, 0.85, 0.2])
		"accordion":
			j.add(s, "reed", [m, d * 0.95, v * 0.15, 0.02])
		"whistle":
			j.add(s, "whistle", [m, d * 0.92, v * 0.2])


static func _comp(j: Job, kind: String, b0: float, root: int, q: String, notes: Array, beat: float,
		at: Callable, vel: Callable) -> void:
	match kind:
		"arp":
			for k in range(8):
				var nm: int = notes[k % notes.size()] + (12 if k % 4 == 3 else 0)
				j.add(at.call(b0 + float(k) * 0.5), "pluck", [nm - 12, beat * 1.3, vel.call(0.24), 0.45, 0.6])
		"bossa":
			var bn := _chord_notes(root, "maj7" if q == "maj" else "min7")
			for pos: float in [0.0, 1.5, 2.5, 3.5]:
				var s0: int = at.call(b0 + pos)
				for k in range(1, bn.size()):
					j.add(s0 + k * 60, "pluck", [bn[k] - 12, beat * 0.9, vel.call(0.13), 0.35, 0.8])
		"rasgueado", "rumba":
			# the rumba's ventilador: down, down-up, the chop on the backbeat
			var pat: Array = [0.0, 1.0, 1.5, 2.0, 3.0, 3.5] if kind == "rasgueado" else [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5]
			for pos: float in pat:
				var strong := pos == 0.0 or pos == 2.0
				var chop := kind == "rumba" and (pos == 1.0 or pos == 3.0)
				var up := fmod(pos, 1.0) > 0.0
				var s1: int = at.call(b0 + pos)
				var cnt := notes.size() + 1
				for k in range(cnt):
					var kk := cnt - 1 - k if up else k
					var nm2: int = notes[kk % notes.size()] + (12 if kk >= notes.size() else 0)
					var dur := beat * (0.18 if chop else 0.8)
					j.add(s1 + k * (70 if up else 110), "pluck", [nm2 - 12, dur, vel.call(0.15 if strong else 0.1), 0.8, 0.5])
		"oompah":
			for pos: float in [1.0, 3.0]:
				var s2: int = at.call(b0 + pos)
				for k in range(notes.size()):
					j.add(s2, "reed", [notes[k], beat * 0.6, vel.call(0.06), 0.02])
		"skank":
			# off-beat chops, reggae-ish, bright and short
			for pos: float in [0.5, 1.5, 2.5, 3.5]:
				var s3: int = at.call(b0 + pos)
				for k in range(notes.size()):
					j.add(s3 + k * 25, "pluck", [notes[k], beat * 0.22, vel.call(0.14), 0.7, 0.3])
		"stab":
			for pos: float in [0.0, 1.5, 3.0]:
				var s4: int = at.call(b0 + pos)
				for k in range(notes.size()):
					j.add(s4 + k * 30, "pluck", [notes[k] - 12, beat * 0.3, vel.call(0.17), 0.75, 0.3])
		"pad":
			for k in range(notes.size()):
				j.add(at.call(b0, 0.0), "reed", [notes[k] - 12, beat * 4.0, 0.05, 0.6])


static func _bass(j: Job, kind: String, b0: float, root: int, q: String, beat: float, at: Callable,
		vel: Callable) -> void:
	var r := root
	while r > 50:
		r -= 12
	r -= 12
	var bs := func(pos: float, m: int, dur: float, v: float) -> void:
		j.add(at.call(b0 + pos), "pluck", [m, beat * dur, vel.call(v), 0.25, 0.9])
	match kind:
		"walk":
			var third := 4 if q == "maj" else 3
			var steps := [r, r + third, r + 7, r + 9]
			for k in range(4):
				bs.call(float(k), steps[k], 0.95, 0.5)
		"bossa":
			bs.call(0.0, r, 1.4, 0.55)
			bs.call(1.5, r + 7, 0.5, 0.42)
			bs.call(2.0, r + 7, 1.4, 0.48)
			bs.call(3.5, r, 0.5, 0.42)
		"root":
			bs.call(0.0, r, 1.8, 0.5)
			bs.call(2.0, r + 7, 1.8, 0.45)
		"oompah":
			bs.call(0.0, r, 0.9, 0.55)
			bs.call(2.0, r + 7, 0.9, 0.5)
		"eighths":
			for k in range(8):
				bs.call(float(k) * 0.5, r + (12 if k % 4 == 3 else 0), 0.45, 0.5 if k % 2 == 0 else 0.36)


static func _drums(j: Job, kind: String, b: int, b0: float, at: Callable, vel: Callable) -> void:
	var hit := func(pos: float, what: String, v: float) -> void:
		j.add(at.call(b0 + pos, 0.4), "hit", [what, vel.call(v)])
	match kind:
		"shaker":
			for k in range(8):
				hit.call(float(k) * 0.5, "shaker", 0.4 if k % 2 == 0 else 0.25)
		"brush", "brushsoft":
			var g := 1.0 if kind == "brush" else 0.55
			for k in range(8):
				hit.call(float(k) * 0.5, "shaker", (0.26 if k % 2 == 0 else 0.16) * g)
			hit.call(1.0, "brush", 0.5 * g)
			hit.call(3.0, "brush", 0.5 * g)
		"rim":
			for pos: float in [0.0, 1.5, 3.0]:
				hit.call(pos, "rim", 0.3)
			for k in range(8):
				hit.call(float(k) * 0.5, "shaker", 0.14)
		"castanets":
			for pos: float in [0.0, 0.5, 1.0, 2.0, 2.5, 3.0, 3.5]:
				hit.call(pos, "castanets", 0.26 if pos == 0.0 or pos == 2.0 else 0.16)
		"kickrim":
			hit.call(0.0, "kick", 0.8)
			hit.call(2.0, "kick", 0.7)
			if b % 2 == 1:
				hit.call(2.5, "kick", 0.45)
			hit.call(1.0, "rim", 0.32)
			hit.call(3.0, "rim", 0.32)
			for k in range(8):
				hit.call(float(k) * 0.5, "shaker", 0.28 if k % 2 == 1 else 0.16)
		"train":
			hit.call(0.0, "kick", 0.7)
			hit.call(2.0, "kick", 0.6)
			for k in range(16):
				hit.call(float(k) * 0.25, "shaker", 0.34 if k % 4 == 2 else (0.2 if k % 2 == 0 else 0.12))
			hit.call(1.0, "brush", 0.4)
			hit.call(3.0, "brush", 0.4)
		"claps":
			hit.call(1.0, "clap", 0.5)
			hit.call(3.0, "clap", 0.5)
			for pos: float in [0.0, 0.75, 1.5, 2.0, 2.75, 3.5]:
				hit.call(pos, "bongo", 0.32 if pos == 0.0 or pos == 2.0 else 0.22)
		"drive":
			for k in range(4):
				hit.call(float(k), "kick", 0.75)
			hit.call(1.0, "clap", 0.35)
			hit.call(3.0, "clap", 0.35)
			for k in range(8):
				hit.call(float(k) * 0.5 + 0.0, "shaker", 0.3 if k % 2 == 1 else 0.18)


static func _jingle(j: Job, jg: Dictionary) -> void:
	j.loop = false
	j.verb_wet = float(jg["verb"])
	var beat := 60.0 / float(jg["bpm"])
	var last := 0.0
	for nt: Array in jg["notes"]:
		var s := int(float(nt[0]) * beat * RATE)
		var d: float = float(nt[1]) * beat
		last = maxf(last, float(nt[0]) + float(nt[1]))
		match String(nt[3]):
			"marimba", "glock":
				j.add(s, "bar", [int(nt[2]), 0.3 if nt[3] == "marimba" else 0.16, String(nt[3])])
			"pluck":
				j.add(s, "pluck", [int(nt[2]), d, 0.22, 0.5, 0.5])
			"bass":
				j.add(s, "pluck", [int(nt[2]), d, 0.55, 0.25, 0.9])
			"reed":
				j.add(s, "reed", [int(nt[2]), d * 0.95, 0.16, 0.03])
	j.n = int((last * beat + 1.6) * RATE)
	j.n += (4 - j.n % 4) % 4
	j.total = j.n


# --- the render job ---------------------------------------------------------

class Job extends RefCounted:
	var name := ""
	var loop := true
	var seed := 1
	var n := 0                 # samples in the loop
	var total := 0             # samples rendered (the loop plus its ringing tail)
	var verb_wet := 0.2
	var events: Array = []     # [start sample, kind, params], sorted by start
	var stream: AudioStreamWAV
	var _ev := 0
	var _voices: Array = []
	var _buf := PackedFloat32Array()
	var _pos := 0
	var _stage := 0
	var _verb: Reverb
	var _sumsq := 0.0
	var _gain := 1.0
	var _bytes := PackedByteArray()

	func add(start: int, kind: String, params: Array) -> void:
		events.append([start, kind, params])

	func done() -> bool:
		return _stage == 4

	# Render for about `budget_usec` microseconds; true when the stream is ready.
	func step(budget_usec: int) -> bool:
		var t_end := Time.get_ticks_usec() + budget_usec
		while _stage < 4 and Time.get_ticks_usec() < t_end:
			match _stage:
				0:
					_buf.resize(total)
					_verb = Reverb.new(verb_wet)
					_pos = 0
					_stage = 1
				1:
					var b := mini(_pos + CHUNK, total)
					_voices_into(_pos, b)
					_verb.process(_buf, _pos, b)
					_pos = b
					if _pos >= total:
						_voices.clear()
						# the tail rings on into the loop's start, as it would the
						# second time round
						if loop:
							for i in range(total - n):
								_buf[i] += _buf[n + i]
						else:
							for i in range(mini(4000, n)):
								_buf[n - 1 - i] *= float(i) / 4000.0
						_pos = 0
						_stage = 2
				2:
					var b2 := mini(_pos + CHUNK * 8, n)
					var acc := 0.0
					for i in range(_pos, b2):
						acc += _buf[i] * _buf[i]
					_sumsq += acc
					_pos = b2
					if _pos >= n:
						var rms := sqrt(_sumsq / float(maxi(n, 1)))
						# a jingle is short and sparse; match its peaks to a loop's
						_gain = TARGET_RMS / maxf(rms, 0.0001) * (0.8 if loop else 1.25)
						_bytes.resize(n * 2)
						_pos = 0
						_stage = 3
				3:
					var b3 := mini(_pos + CHUNK * 8, n)
					var g := _gain
					for i in range(_pos, b3):
						var x := _buf[i] * g
						# soft ceiling (a tanh shape): loud peaks round off, never clip
						if x > 3.0:
							x = 1.0
						elif x < -3.0:
							x = -1.0
						else:
							x = x * (27.0 + x * x) / (27.0 + 9.0 * x * x)
						_bytes.encode_s16(i * 2, int(x * 32000.0))
					_pos = b3
					if _pos >= n:
						stream = AudioStreamWAV.new()
						stream.format = AudioStreamWAV.FORMAT_16_BITS
						stream.mix_rate = RATE
						stream.stereo = false
						stream.data = _bytes
						if loop:
							stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
							stream.loop_begin = 0
							stream.loop_end = n
						_buf = PackedFloat32Array()
						_bytes = PackedByteArray()
						_stage = 4
		return _stage == 4

	func _voices_into(a: int, b: int) -> void:
		while _ev < events.size() and int(events[_ev][0]) < b:
			var e: Array = events[_ev]
			_voices.append(Voice.make(int(e[0]), String(e[1]), e[2], seed + _ev * 7919))
			_ev += 1
		var keep: Array = []
		for v: Voice in _voices:
			if v.render(_buf, a, b):
				keep.append(v)
		_voices = keep


# A small room at quarter rate (a reverb tail is all low end anyway): four
# combs into two allpasses (Schroeder), state kept between slices. Works on
# runs of four samples, so slices start and end on multiples of four.
class Reverb extends RefCounted:
	var wet := 0.2
	var c0 := PackedFloat32Array()
	var c1 := PackedFloat32Array()
	var c2 := PackedFloat32Array()
	var c3 := PackedFloat32Array()
	var a0 := PackedFloat32Array()
	var a1 := PackedFloat32Array()
	var i0 := 0
	var i1 := 0
	var i2 := 0
	var i3 := 0
	var j0 := 0
	var j1 := 0
	var l0 := 0.0
	var l1 := 0.0
	var l2 := 0.0
	var l3 := 0.0
	var last := 0.0

	func _init(w: float) -> void:
		wet = w
		c0.resize(279)
		c1.resize(297)
		c2.resize(319)
		c3.resize(339)
		a0.resize(56)
		a1.resize(139)

	func process(buf: PackedFloat32Array, a: int, b: int) -> void:
		if wet <= 0.0:
			return
		var dry := 1.0 - wet * 0.5
		var i := a
		while i < b:
			var x := (buf[i] + buf[i + 1] + buf[i + 2] + buf[i + 3]) * 0.25
			var y0 := c0[i0]
			l0 = y0 + (l0 - y0) * 0.3
			c0[i0] = x + l0 * 0.8
			i0 += 1
			if i0 == 279:
				i0 = 0
			var y1 := c1[i1]
			l1 = y1 + (l1 - y1) * 0.3
			c1[i1] = x + l1 * 0.8
			i1 += 1
			if i1 == 297:
				i1 = 0
			var y2 := c2[i2]
			l2 = y2 + (l2 - y2) * 0.3
			c2[i2] = x + l2 * 0.8
			i2 += 1
			if i2 == 319:
				i2 = 0
			var y3 := c3[i3]
			l3 = y3 + (l3 - y3) * 0.3
			c3[i3] = x + l3 * 0.8
			i3 += 1
			if i3 == 339:
				i3 = 0
			var s := (y0 + y1 + y2 + y3) * 0.25
			var z0 := a0[j0]
			var u0 := s + z0 * 0.5
			a0[j0] = u0
			s = z0 - u0 * 0.5
			j0 += 1
			if j0 == 56:
				j0 = 0
			var z1 := a1[j1]
			var u1 := s + z1 * 0.5
			a1[j1] = u1
			s = z1 - u1 * 0.5
			j1 += 1
			if j1 == 139:
				j1 = 0
			# back up to rate along a straight line from the last value
			var dv := (s - last) * 0.25 * wet
			var w := last * wet
			buf[i] = buf[i] * dry + w + dv
			buf[i + 1] = buf[i + 1] * dry + w + dv * 2.0
			buf[i + 2] = buf[i + 2] * dry + w + dv * 3.0
			buf[i + 3] = buf[i + 3] * dry + w + dv * 4.0
			last = s
			i += 4


# --- the instruments --------------------------------------------------------
# Each voice renders itself into whatever slice of the buffer it overlaps and
# says whether it is still sounding.

class Voice extends RefCounted:
	var start := 0
	var len := 0
	var done := 0
	var noise := 1

	static func make(s: int, kind: String, p: Array, sd: int) -> Voice:
		var v: Voice
		match kind:
			"pluck": v = Pluck.new(p, sd)
			"bar": v = Bar.new(p)
			"reed": v = Reed.new(p)
			"whistle": v = Whistle.new(p)
			_: v = Hit.new(p)
		v.start = s & ~1
		v.noise = sd | 1
		return v

	# render [a, b) of the buffer; false once finished
	func render(buf: PackedFloat32Array, a: int, b: int) -> bool:
		var j0 := maxi(a, start + done)
		var j1 := mini(b, start + len)
		if j1 > j0:
			_run(buf, j0, j1, j0 - start)
			done = j1 - start
		return done < len

	func _run(_buf: PackedFloat32Array, _a: int, _b: int, _k0: int) -> void:
		pass

	# a cheap, repeatable noise source (-1..1)
	func _nz() -> float:
		noise = (noise * 1103515245 + 12345) & 0x7fffffff
		return float(noise) / 1073741824.0 - 1.0


# a plucked string: a burst of noise in a delay line, averaged as it goes
# round (Karplus-Strong), tuned between samples by an allpass. bright: how
# hard and near the bridge; damp: how quickly it dies.
class Pluck extends Voice:
	var line := PackedFloat32Array()
	var p := 2
	var idx := 0
	var decay := 0.498
	var amp := 0.3
	var ap_c := 0.0
	var ap_x := 0.0
	var ap_y := 0.0
	var body := 0.0
	var rel := 400
	var half := false          # low strings: run at half rate, write each value twice

	func _init(pr: Array, sd: int) -> void:
		var midi: float = pr[0]
		half = midi < 67.0
		var dur: float = pr[1]
		amp = pr[2]
		var bright: float = pr[3]
		var damp: float = pr[4]
		noise = sd | 1
		var period := float(RATE) / Music._hz(midi) / (2.0 if half else 1.0) - 0.5
		p = maxi(2, int(floor(period)))
		var frac := period - float(p)
		if frac < 0.1:
			p -= 1
			frac += 1.0
		ap_c = (1.0 - frac) / (1.0 + frac)
		line.resize(p)
		var prev := 0.0
		var k := 0.25 + 0.75 * bright
		for i in range(p):
			prev = lerpf(prev, _nz(), k)
			line[i] = prev
		decay = 0.4985 - damp * 0.004
		len = int(dur * RATE)
		len += len % 2
		rel = maxi(2, mini(400, len / 2))

	func _run(buf: PackedFloat32Array, a: int, b: int, k0: int) -> void:
		var k := k0
		var tail := len - rel
		if half:
			_run_half(buf, a, b, k0)
			return
		for j in range(a, b):
			var cur := line[idx]
			var nx := idx + 1
			if nx == p:
				nx = 0
			var avg := (cur + line[nx]) * decay
			var y := ap_c * avg + ap_x - ap_c * ap_y
			ap_x = avg
			ap_y = y
			line[idx] = y
			idx = nx
			body += (cur - body) * 0.6
			var env := 1.0 if k < tail else float(len - k) / float(rel)
			buf[j] += body * amp * env
			k += 1

	func _run_half(buf: PackedFloat32Array, a: int, b: int, k0: int) -> void:
		var k := k0
		var tail := len - rel
		var j := a
		var last := body
		while j < b:
			var cur := line[idx]
			var nx := idx + 1
			if nx == p:
				nx = 0
			var avg := (cur + line[nx]) * decay
			var y := ap_c * avg + ap_x - ap_c * ap_y
			ap_x = avg
			ap_y = y
			line[idx] = y
			idx = nx
			body += (cur - body) * 0.84
			var env := (1.0 if k < tail else float(len - k) / float(rel)) * amp
			buf[j] += (last + body) * 0.5 * env
			buf[j + 1] += body * env
			last = body
			j += 2
			k += 2


# a struck bar: damped resonators, one per partial (marimba 1 : 3.9 : 9.9,
# glockenspiel 1 : 2.76 : 5.4, vibes 1 : 4 with its motor tremolo)
class Bar extends Voice:
	var kind := "marimba"
	var amp := 0.3
	var n_p := 3
	var cf := PackedFloat32Array()   # 2 r cos w
	var r2 := PackedFloat32Array()   # r squared
	var y1 := PackedFloat32Array()
	var y2 := PackedFloat32Array()

	func _init(pr: Array) -> void:
		var midi: float = pr[0]
		amp = pr[1]
		kind = pr[2]
		var f := Music._hz(midi)
		var parts := [[1.0, 1.0, 3.0], [3.9, 0.35, 12.0], [9.9, 0.12, 30.0]]
		if kind == "glock":
			parts = [[1.0, 1.0, 2.2], [2.76, 0.4, 5.0], [5.4, 0.2, 9.0]]
		elif kind == "vibes":
			parts = [[1.0, 1.0, 1.4], [4.0, 0.25, 8.0]]
		n_p = 0
		for q: Array in parts:
			var w := TAU * f * float(q[0]) / float(RATE)
			if w >= PI * 0.9:
				continue
			var r := exp(-float(q[2]) / float(RATE))
			cf.append(2.0 * r * cos(w))
			r2.append(r * r)
			y2.append(0.0)
			y1.append(float(q[1]) * r * sin(w))
			n_p += 1
		# rings until -48 dB, at most 2.4 s; past that it is under the mix
		len = int(minf(log(250.0) / float(parts[0][2]), 2.4) * RATE)

	func _run(buf: PackedFloat32Array, a: int, b: int, k0: int) -> void:
		var vib := kind == "vibes"
		var k := k0
		var ca := cf[0]
		var ra := r2[0]
		var p1 := y1[0]
		var p2 := y2[0]
		var cb := cf[1] if n_p > 1 else 0.0
		var rb := r2[1] if n_p > 1 else 0.0
		var q1 := y1[1] if n_p > 1 else 0.0
		var q2 := y2[1] if n_p > 1 else 0.0
		var cc := cf[2] if n_p > 2 else 0.0
		var rc := r2[2] if n_p > 2 else 0.0
		var s1 := y1[2] if n_p > 2 else 0.0
		var s2 := y2[2] if n_p > 2 else 0.0
		var trem := 1.0
		for j in range(a, b):
			var s := p2 + q2 + s2
			var np := ca * p1 - ra * p2
			p2 = p1
			p1 = np
			var nq := cb * q1 - rb * q2
			q2 = q1
			q1 = nq
			var ns := cc * s1 - rc * s2
			s2 = s1
			s1 = ns
			if vib and (k & 63) == 0:
				trem = 0.8 + 0.2 * sin(TAU * 5.5 * float(k) / float(RATE))
			var atk := 1.0 if k > 55 else float(k) / 55.0
			buf[j] += s * amp * atk * trem
			k += 1
		y1[0] = p1
		y2[0] = p2
		if n_p > 1:
			y1[1] = q1
			y2[1] = q2
		if n_p > 2:
			y1[2] = s1
			y2[2] = s2


# a reed (the accordion, and the pads): three detuned saws through a soft
# filter, with the bellows' swell. attack: seconds to full.
class Reed extends Voice:
	var f := 440.0
	var amp := 0.1
	var atk := 0.02
	var ph0 := 0.0
	var ph1 := 0.33
	var ph2 := 0.66
	var lp := 0.0
	var lp2 := 0.0
	var step := 1              # 2: a low reed, worked out every other sample

	func _init(pr: Array) -> void:
		f = Music._hz(float(pr[0]))
		len = int(float(pr[1]) * RATE)
		len += len % 2
		amp = pr[2]
		atk = maxf(float(pr[3]), 0.005)
		step = 2 if float(pr[0]) < 64.0 else 1

	func _run(buf: PackedFloat32Array, a: int, b: int, k0: int) -> void:
		if step == 2:
			_run_half(buf, a, b, k0)
			return
		var k := k0
		var inc := f / float(RATE)
		var d0 := inc
		var d1 := inc * 1.004
		var d2 := inc * 0.996
		var a_n := atk * float(RATE)
		var rel := minf(900.0, float(len) * 0.3)
		for j in range(a, b):
			if (k & 63) == 0:
				var shake := 1.0 + 0.003 * sin(TAU * 6.0 * float(k) / float(RATE))
				d0 = inc * shake
				d1 = inc * 1.004 * shake
				d2 = inc * 0.996 * shake
			ph0 += d0
			if ph0 >= 1.0:
				ph0 -= 1.0
			ph1 += d1
			if ph1 >= 1.0:
				ph1 -= 1.0
			ph2 += d2
			if ph2 >= 1.0:
				ph2 -= 1.0
			var s := (ph0 + ph1 + ph2) * 0.6667 - 1.0
			lp += (s - lp) * 0.2
			lp2 += (lp - lp2) * 0.35
			var env := minf(1.0, float(k) / a_n) * minf(1.0, float(len - k) / rel)
			buf[j] += lp2 * amp * env
			k += 1

	func _run_half(buf: PackedFloat32Array, a: int, b: int, k0: int) -> void:
		var k := k0
		var inc := 2.0 * f / float(RATE)
		var d0 := inc
		var d1 := inc * 1.004
		var d2 := inc * 0.996
		var a_n := atk * float(RATE)
		var rel := minf(900.0, float(len) * 0.3)
		var j := a
		var last := lp2
		while j < b:
			if (k & 63) == 0:
				var shake := 1.0 + 0.003 * sin(TAU * 6.0 * float(k) / float(RATE))
				d0 = inc * shake
				d1 = inc * 1.004 * shake
				d2 = inc * 0.996 * shake
			ph0 += d0
			if ph0 >= 1.0:
				ph0 -= 1.0
			ph1 += d1
			if ph1 >= 1.0:
				ph1 -= 1.0
			ph2 += d2
			if ph2 >= 1.0:
				ph2 -= 1.0
			var s := (ph0 + ph1 + ph2) * 0.6667 - 1.0
			lp += (s - lp) * 0.36
			lp2 += (lp - lp2) * 0.58
			var env := minf(1.0, float(k) / a_n) * minf(1.0, float(len - k) / rel) * amp
			buf[j] += (last + lp2) * 0.5 * env
			buf[j + 1] += lp2 * env
			last = lp2
			j += 2
			k += 2


# a whistle: a sine with a touch of its octave, scooping up into the note,
# the vibrato arriving late, a breath on the attack
class Whistle extends Voice:
	var f := 880.0
	var amp := 0.2
	var x := 0.0
	var y := 0.0
	var c := 1.0
	var s := 0.0

	func _init(pr: Array) -> void:
		f = Music._hz(float(pr[0]))
		len = int(float(pr[1]) * RATE)
		amp = pr[2]
		x = 1.0

	func _run(buf: PackedFloat32Array, a: int, b: int, k0: int) -> void:
		var k := k0
		var rel := minf(700.0, float(len) * 0.25)
		for j in range(a, b):
			if (k & 31) == 0:
				var t := float(k) / float(RATE)
				var scoop := -0.35 * maxf(0.0, 1.0 - t / 0.05)
				var vib := 0.18 * minf(1.0, maxf(0.0, (t - 0.15) / 0.2)) * sin(TAU * 5.2 * t)
				var w := TAU * f * pow(2.0, (scoop + vib) / 12.0) / float(RATE)
				c = cos(w)
				s = sin(w)
				# keep the oscillator on the unit circle
				var m := sqrt(x * x + y * y)
				x /= m
				y /= m
			var nx := x * c - y * s
			y = x * s + y * c
			x = nx
			var tone := y + 0.12 * (2.0 * x * y)
			var env := minf(1.0, float(k) / 330.0) * minf(1.0, float(len - k) / rel)
			var breath := _nz() * (0.25 * maxf(0.0, 1.0 - float(k) / 1300.0) + 0.02)
			buf[j] += (tone + breath) * amp * env
			k += 1


# percussion from filtered noise and short sines. Envelopes decay by a fixed
# factor per sample (no exp() in the loop); pitched hits keep a phase.
class Hit extends Voice:
	var kind := "shaker"
	var amp := 0.3
	var prev := 0.0
	var ph := 0.0
	var e1 := 1.0       # the main envelope
	var e2 := 1.0       # a second (pitch sweep, the room after a clap)
	var d1 := 1.0
	var d2 := 1.0

	func _init(pr: Array) -> void:
		kind = pr[0]
		amp = pr[1]
		var secs := 0.12
		var k1 := 60.0
		var k2 := 30.0
		match kind:
			"shaker": secs = 0.07; k1 = 60.0
			"brush": secs = 0.22; k1 = 16.0
			"rim": secs = 0.05; k1 = 90.0; k2 = 120.0
			"castanets": secs = 0.06; k1 = 110.0
			"kick": secs = 0.25; k1 = 13.0; k2 = 30.0
			"clap": secs = 0.16; k1 = 140.0; k2 = 22.0
			"bongo": secs = 0.14; k1 = 28.0; k2 = 60.0
		len = int(secs * RATE)
		d1 = exp(-k1 / float(RATE))
		d2 = exp(-k2 / float(RATE))

	func _run(buf: PackedFloat32Array, a: int, b: int, k0: int) -> void:
		var k := k0
		var inv := 1.0 / float(RATE)
		match kind:
			"shaker":
				for j in range(a, b):
					var nz := _nz()
					buf[j] += (nz - prev) * e1 * 0.5 * amp
					prev = nz
					e1 *= d1
			"brush":
				for j in range(a, b):
					prev += (_nz() - prev) * 0.5
					buf[j] += prev * e1 * 0.45 * amp
					e1 *= d1
			"rim":
				for j in range(a, b):
					ph += 1700.0 * inv
					buf[j] += (sin(TAU * ph) * e1 * 0.6 + _nz() * e2 * 0.2) * amp
					e1 *= d1
					e2 *= d2
			"castanets":
				# two clicks 25 ms apart
				var second := int(0.025 * RATE)
				for j in range(a, b):
					ph += 2300.0 * inv
					var nz := _nz()
					var v := (sin(TAU * ph) * 0.6 + nz * 0.4) * e1
					if k == second:
						e2 = 1.0
					if k >= second:
						v += (sin(TAU * ph * 0.913) * 0.5 + nz * 0.3) * e2
						e2 *= d1
					buf[j] += v * amp
					e1 *= d1
					k += 1
			"kick":
				for j in range(a, b):
					ph += (55.0 + 70.0 * e2) * inv
					buf[j] += sin(TAU * ph) * e1 * 1.1 * amp
					e1 *= d1
					e2 *= d2
			"clap":
				# three quick slaps, then the room after them
				var gap := int(0.011 * RATE)
				for j in range(a, b):
					if k == gap or k == gap * 2:
						e1 = 1.0
					var nz := _nz()
					prev += (nz - prev) * 0.7
					buf[j] += (nz - prev) * maxf(e1, 0.3 * e2) * 1.2 * amp
					e1 *= d1
					e2 *= d2
					k += 1
			"bongo":
				for j in range(a, b):
					ph += (330.0 + 140.0 * e2) * inv
					buf[j] += sin(TAU * ph) * e1 * 0.8 * amp
					e1 *= d1
					e2 *= d2
