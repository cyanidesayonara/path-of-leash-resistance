class_name Music
extends RefCounted

# THE SOUNDTRACK, synthesised like everything else: no audio files. A small
# tracker. One tune (sixteen bars, A and B), arranged per walk - the same
# melody dressed as a bossa on the seafront, a Spanish guitar piece in the old
# town, and so on - played on a handful of instruments built from first
# principles: plucked strings (Karplus-Strong) for guitar and bass, struck
# bars (inharmonic partials) for marimba and glockenspiel, a reedy pad for the
# accordion, filtered noise for brushes, shaker and castanets. Mixed mono
# with a small room reverb, and handed back as a seamless loop.
#
# Everything is deterministic (its own RNG), so a style always sounds the same.

const RATE := 22050

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

# how each walk wears the tune
const STYLES := {
	"title": {"bpm": 104, "lead": "marimba", "comp": "arp", "bass": "walk", "drums": "shaker", "minor": false, "verb": 0.22},
	"beach": {"bpm": 96, "lead": "vibes", "comp": "bossa", "bass": "bossa", "drums": "rim", "minor": false, "verb": 0.28},
	"oldtown": {"bpm": 112, "lead": "guitar", "comp": "rasgueado", "bass": "root", "drums": "castanets", "minor": true, "verb": 0.3},
	"market": {"bpm": 120, "lead": "accordion", "comp": "oompah", "bass": "oompah", "drums": "shaker", "minor": false, "verb": 0.18},
	"trail": {"bpm": 88, "lead": "glock", "comp": "arp", "bass": "root", "drums": "none", "minor": false, "verb": 0.4},
}


# --- the instruments ------------------------------------------------------

static func _hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


# a plucked string: a burst of noise in a delay line, averaged as it goes round
# (Karplus-Strong). `bright` (0..1) is how hard and near the bridge it is
# plucked; `damp` how quickly it dies.
static func pluck(buf: PackedFloat32Array, at: int, midi: float, dur: float, amp: float, bright: float,
		damp: float, rng: RandomNumberGenerator) -> void:
	var period := maxi(2, int(round(float(RATE) / _hz(midi))))
	var line := PackedFloat32Array()
	line.resize(period)
	var prev := 0.0
	for i in range(period):
		var nz := rng.randf_range(-1.0, 1.0)
		prev = lerpf(prev, nz, 0.25 + 0.75 * bright)
		line[i] = prev
	var n := int(dur * RATE)
	var idx := 0
	var decay := 0.4985 - damp * 0.004
	for i in range(n):
		var j := at + i
		if j >= buf.size():
			break
		var cur := line[idx]
		var nxt := line[(idx + 1) % period]
		line[idx] = (cur + nxt) * decay
		var env := 1.0 if i < n - 400 else float(n - i) / 400.0
		buf[j] += cur * amp * env
		idx = (idx + 1) % period


# a struck bar: a fundamental and inharmonic overtones that die fast (marimba
# 1 : 3.9 : 9.9; glockenspiel 1 : 2.76 : 5.4), a little vibrato for vibes
static func bar(buf: PackedFloat32Array, at: int, midi: float, dur: float, amp: float, kind: String) -> void:
	var f := _hz(midi)
	var partials := [[1.0, 1.0, 3.0], [3.9, 0.35, 12.0], [9.9, 0.12, 30.0]]
	if kind == "glock":
		partials = [[1.0, 1.0, 2.2], [2.76, 0.4, 5.0], [5.4, 0.2, 9.0]]
	elif kind == "vibes":
		partials = [[1.0, 1.0, 1.6], [4.0, 0.25, 8.0]]
	var n := int(minf(dur + 1.2, 3.0) * RATE)
	for i in range(n):
		var j := at + i
		if j >= buf.size():
			break
		var t := float(i) / RATE
		var trem := 1.0 if kind != "vibes" else 0.8 + 0.2 * sin(TAU * 5.5 * t)
		var s := 0.0
		for p: Array in partials:
			s += sin(TAU * f * float(p[0]) * t) * float(p[1]) * exp(-t * float(p[2]))
		var atk := minf(1.0, t * 400.0)
		buf[j] += s * amp * atk * trem


# a reedy pad (the accordion): three detuned saws through a soft filter, with
# the bellows' slow swell and a little shake
static func reed(buf: PackedFloat32Array, at: int, midi: float, dur: float, amp: float) -> void:
	var f := _hz(midi)
	var n := int(dur * RATE)
	var ph := [0.0, 0.33, 0.66]
	var det := [1.0, 1.004, 0.996]
	var lp := 0.0
	for i in range(n):
		var j := at + i
		if j >= buf.size():
			break
		var t := float(i) / RATE
		var s := 0.0
		for k in range(3):
			ph[k] = fmod(ph[k] + f * det[k] * (1.0 + 0.003 * sin(TAU * 6.0 * t)) / RATE, 1.0)
			s += ph[k] * 2.0 - 1.0
		lp = lerpf(lp, s / 3.0, 0.18)
		var env := minf(1.0, t * 14.0) * minf(1.0, float(n - i) / 900.0)
		buf[j] += lp * amp * env


# percussion from filtered noise and short sines
static func hit(buf: PackedFloat32Array, at: int, kind: String, amp: float, rng: RandomNumberGenerator) -> void:
	var len := 0.12
	match kind:
		"shaker": len = 0.07
		"brush": len = 0.22
		"rim": len = 0.05
		"castanets": len = 0.06
		"kick": len = 0.25
	var n := int(len * RATE)
	var hp := 0.0
	var prev := 0.0
	for i in range(n):
		var j := at + i
		if j >= buf.size():
			break
		var t := float(i) / RATE
		var nz := rng.randf_range(-1.0, 1.0)
		var s := 0.0
		match kind:
			"shaker":
				hp = nz - prev
				prev = nz
				s = hp * exp(-t * 60.0) * 0.5
			"brush":
				s = nz * exp(-t * 18.0) * 0.35
			"rim":
				s = sin(TAU * 1700.0 * t) * exp(-t * 90.0) * 0.6 + nz * exp(-t * 120.0) * 0.2
			"castanets":
				s = (sin(TAU * 2300.0 * t) * 0.6 + nz * 0.4) * exp(-t * 110.0)
				if i > int(0.025 * RATE):
					s += (sin(TAU * 2100.0 * t) * 0.5 + nz * 0.3) * exp(-(t - 0.025) * 110.0)
			"kick":
				s = sin(TAU * (90.0 - 50.0 * minf(t * 8.0, 1.0)) * t) * exp(-t * 14.0)
		buf[j] += s * amp


# --- harmony helpers --------------------------------------------------------

static func _chord_notes(root: int, quality: String) -> Array:
	match quality:
		"min": return [root, root + 3, root + 7]
		"maj7": return [root, root + 4, root + 7, root + 11]
		"min7": return [root, root + 3, root + 7, root + 10]
	return [root, root + 4, root + 7]


# D major to D minor, the old town's way: F# down to F, B down to Bb, keep
# C# (harmonic minor), and the chords follow
static func _minor_note(m: int) -> int:
	var pc := posmod(m - 62, 12)
	if pc == 4 or pc == 9:      # F#, B
		return m - 1
	return m


static func _minor_chord(ch: Array) -> Array:
	var r: int = ch[0]
	var pc := posmod(r - 62, 12)
	match pc:
		0: return [r, "min"]            # D -> Dm
		9: return [r - 1, "maj"]        # Bm -> Bb
		5: return [r, "min"]            # G -> Gm
		7: return [r, "maj"]            # A stays A
		2: return [r + 3, "min"]        # Em -> Gm
		4: return [r - 1, "maj"]        # F#m -> F
	return ch


# --- the arrangement ----------------------------------------------------------

static func render(style_name: String) -> PackedFloat32Array:
	var st: Dictionary = STYLES.get(style_name, STYLES["title"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(style_name)
	var beat := 60.0 / float(st["bpm"])
	var bars := 16
	var n := int(beat * 4.0 * float(bars) * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var minor: bool = st["minor"]
	var chords: Array = []
	for ch in CHORDS_A + CHORDS_B:
		chords.append(_minor_chord(ch) if minor else ch)
	# the melody
	var mel: Array = []
	for nt in MELODY_A:
		mel.append([float(nt[0]), float(nt[1]), int(nt[2])])
	for nt in MELODY_B:
		mel.append([float(nt[0]) + 32.0, float(nt[1]), int(nt[2])])
	for nt: Array in mel:
		var m: int = _minor_note(nt[2]) if minor else int(nt[2])
		var at := int(nt[0] * beat * RATE)
		var d: float = nt[1] * beat
		match String(st["lead"]):
			"marimba", "glock", "vibes":
				bar(buf, at, m, d, 0.16, String(st["lead"]))
			"guitar":
				pluck(buf, at, m - 12, d + 0.4, 0.42, 0.85, 0.2, rng)
			"accordion":
				reed(buf, at, m, d * 0.95, 0.13)
	# the accompaniment and the bass, bar by bar
	for b in range(bars):
		var ch: Array = chords[b]
		var notes := _chord_notes(int(ch[0]), String(ch[1]))
		var bar0 := float(b) * 4.0
		match String(st["comp"]):
			"arp":
				for k in range(8):
					var nm: int = notes[k % notes.size()] + (12 if k % 4 == 3 else 0)
					pluck(buf, int((bar0 + float(k) * 0.5) * beat * RATE), nm - 12, beat * 1.2, 0.2, 0.45, 0.6, rng)
			"bossa":
				var q := "maj7" if String(ch[1]) == "maj" else "min7"
				var bn := _chord_notes(int(ch[0]), q)
				for pos: float in [0.0, 1.5, 2.5, 3.5]:
					for k in range(1, bn.size()):
						pluck(buf, int((bar0 + pos) * beat * RATE) + k * 60, bn[k] - 12, beat * 0.9, 0.11, 0.35, 0.8, rng)
			"rasgueado":
				for pos: float in [0.0, 1.0, 1.5, 2.0, 3.0, 3.5]:
					var strength := 1.0 if pos == 0.0 or pos == 2.0 else 0.65
					for k in range(notes.size() + 1):
						var nm2: int = notes[k % notes.size()] + (12 if k >= notes.size() else 0)
						pluck(buf, int((bar0 + pos) * beat * RATE) + k * 110, nm2 - 12, beat * 0.8, 0.13 * strength, 0.8, 0.5, rng)
			"oompah":
				for pos: float in [1.0, 3.0]:
					for k in range(notes.size()):
						reed(buf, int((bar0 + pos) * beat * RATE), notes[k], beat * 0.7, 0.06)
		match String(st["bass"]):
			"walk":
				var steps := [int(ch[0]), int(ch[0]) + 4 if String(ch[1]) == "maj" else int(ch[0]) + 3, int(ch[0]) + 7, int(ch[0]) + 9]
				for k in range(4):
					pluck(buf, int((bar0 + float(k)) * beat * RATE), steps[k] - 24, beat * 0.95, 0.42, 0.25, 0.9, rng)
			"bossa":
				pluck(buf, int(bar0 * beat * RATE), int(ch[0]) - 24, beat * 1.4, 0.45, 0.25, 0.9, rng)
				pluck(buf, int((bar0 + 1.5) * beat * RATE), int(ch[0]) - 17, beat * 0.5, 0.35, 0.25, 0.9, rng)
				pluck(buf, int((bar0 + 2.0) * beat * RATE), int(ch[0]) - 17, beat * 1.4, 0.4, 0.25, 0.9, rng)
				pluck(buf, int((bar0 + 3.5) * beat * RATE), int(ch[0]) - 24, beat * 0.5, 0.35, 0.25, 0.9, rng)
			"root":
				for k in range(2):
					pluck(buf, int((bar0 + float(k) * 2.0) * beat * RATE), int(ch[0]) - 24 + (7 if k == 1 else 0), beat * 1.8, 0.42, 0.25, 0.9, rng)
			"oompah":
				for pos: float in [0.0, 2.0]:
					pluck(buf, int((bar0 + pos) * beat * RATE), int(ch[0]) - 24 + (7 if pos == 2.0 else 0), beat * 0.9, 0.45, 0.3, 0.9, rng)
		match String(st["drums"]):
			"shaker":
				for k in range(8):
					hit(buf, int((bar0 + float(k) * 0.5) * beat * RATE), "shaker", 0.35 if k % 2 == 0 else 0.22, rng)
			"rim":
				for pos: float in [0.0, 1.5, 3.0]:
					hit(buf, int((bar0 + pos) * beat * RATE), "rim", 0.25, rng)
				for k in range(8):
					hit(buf, int((bar0 + float(k) * 0.5) * beat * RATE), "shaker", 0.12, rng)
			"castanets":
				for pos: float in [0.0, 0.5, 1.0, 2.0, 2.5, 3.0, 3.5]:
					hit(buf, int((bar0 + pos) * beat * RATE), "castanets", 0.22 if pos == 0.0 or pos == 2.0 else 0.14, rng)
	_reverb(buf, float(st["verb"]))
	# a gentle limiter, and the loop's ends faded together so it is seamless
	var peak := 0.0
	for v in buf:
		peak = maxf(peak, absf(v))
	var g := 0.85 / maxf(peak, 0.001)
	for i in range(buf.size()):
		var x := buf[i] * g
		buf[i] = x / (1.0 + absf(x) * 0.25)
	return buf


# a small room: four combs into two allpasses (Schroeder), mixed in. The tail
# wraps round to the start, so the loop point does not cut the reverb off.
static func _reverb(buf: PackedFloat32Array, wet: float) -> void:
	if wet <= 0.0:
		return
	var n := buf.size()
	var out := PackedFloat32Array()
	out.resize(n)
	for dl: int in [1116, 1188, 1277, 1356]:
		var line := PackedFloat32Array()
		line.resize(dl)
		var idx := 0
		var lp := 0.0
		for pass_ in range(2):
			for i in range(n):
				var y := line[idx]
				lp = lerpf(y, lp, 0.25)
				line[idx] = buf[i] + lp * 0.80
				if pass_ == 1:
					out[i] += y * 0.25
				idx = (idx + 1) % dl
	for dl: int in [225, 556]:
		var line2 := PackedFloat32Array()
		line2.resize(dl)
		var idx2 := 0
		for i in range(n):
			var y2 := line2[idx2]
			var x2 := out[i] + y2 * 0.5
			line2[idx2] = x2
			out[i] = y2 - x2 * 0.5
			idx2 = (idx2 + 1) % dl
	for i in range(n):
		buf[i] = buf[i] * (1.0 - wet * 0.5) + out[i] * wet


static func to_stream(buf: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in range(buf.size()):
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = buf.size()
	return s
