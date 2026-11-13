extends Node2D

# The chase threat of Montserrat: the wild goats (cabres salvatges) coming
# down the path line abreast, the big billy in the middle with his curled
# horns, the nannies and the young ones either side, grit flying behind them.
# The same animals are in the walk's film (intro/film_montserrat.gd), side on.
#
# What sets it apart: rolling conglomerate boulders.
# Every few seconds one of them kicks a boulder loose and it bounds down the
# path at the pair. Its landing is marked on the ground from the kick.
# Stepping clear awards the "boulder_dodge" goal; getting hit is a knockback
# and counts toward "montserrat_goat_hits".
#
# Implements the standard chase threat interface (setup, advance, caught,
# gap_to, threat_boundary, sweep_junk) so systems/home_chase drives it.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")

# The herd's colours; the film draws the same animals with them.
const GOAT_FUR := Color(0.60, 0.47, 0.36)
const GOAT_DARK := Color(0.34, 0.25, 0.20)
const GOAT_BELLY := Color(0.88, 0.82, 0.72)
const GOAT_HORN := Color(0.50, 0.44, 0.38)
const GOAT_HORN_TIP := Color(0.24, 0.21, 0.20)
const GOAT_HORN_RIDGE := Color(0.20, 0.17, 0.17, 0.75)
const GOAT_EYE := Color(0.98, 0.84, 0.16)
const DUST_COL := Color(0.84, 0.78, 0.70)
const INK := Color(0.05, 0.04, 0.06)
# the line, west to east: [place across the catch line (-1..1), scale, how
# far behind the line its nose runs, how dark its coat]. The big billy in the
# middle, a nanny either side of him, a young one on each flank.
const HERD := [[-1.0, 0.72, 10.0, 0.15], [-0.52, 1.0, 4.0, 0.45], [0.0, 1.5, 0.0, 0.8], [0.52, 0.95, 6.0, 0.3], [1.0, 0.76, 12.0, 0.0]]
const LEAD := 2

# Movement and tuning
const SPEED_DEFAULT := 138.0
const SURGE := 0.15
const CATCH_UP := 1.35
const CATCH_UP_GAP := 650.0
const JAM_SECS := 3.0
const GOAT_DEPTH := 90.0
const CATCH_SPAN := 0.70

# Rolling boulder hazards
const BOULDER_FIRST := 1.6
const BOULDER_EVERY := 2.5
const BOULDER_JITTER := 0.4
const BOULDER_WARN := 0.8
const BOULDER_R := 36.0
const BOULDER_DODGE_R := 120.0
const BOULDER_LEAD := 0.5
const BOULDER_MIN_AHEAD := 80.0
const MAX_BOULDERS := 3
const IMPACT_TIME := 0.4

var main: Node2D
var speed := SPEED_DEFAULT
var cur_speed := SPEED_DEFAULT
var front_y := 0.0
var cx := 640.0
var half := 260.0
var kind := "goat"
var rumble := 0.0
var sway := 0.0
var sway_v := 0.0
var heading := 0.0
var jams: Array[Vector2] = []
var jam_t := 0.0
var jam_side := 0.0
var jam_at := Vector2(INF, INF)
var kerb_blocks: Array[Rect2] = []
var jammed_now := false
var freed_now := false

# Rolling boulders in flight: {"from": Vector2, "at": Vector2, "target": Vector2, "t": float, "lead": float}
var boulders: Array[Dictionary] = []
# Dust impact puffs: {"at": Vector2, "t": float}
var dust_puffs: Array[Dictionary] = []
var boulder_t := BOULDER_FIRST
var drop_count := 0
var hits := 0
var dodges := 0


func setup(m: Node2D, start_front_y: float, corridor_cx: float, corridor_half: float, goat_speed: float) -> void:
	main = m
	front_y = start_front_y
	cx = corridor_cx
	half = corridor_half
	speed = goat_speed
	cur_speed = goat_speed
	boulders.clear()
	dust_puffs.clear()
	boulder_t = BOULDER_FIRST
	position = Vector2(cx, front_y)


func advance(delta: float, gap := -1.0, aim := 0.0) -> void:
	rumble += delta
	jammed_now = false
	freed_now = false
	_tick_boulders(delta)

	if jam_t > 0.0:
		jam_t -= delta
		cur_speed = 0.0
		if jam_t <= 0.0:
			freed_now = true
		queue_redraw()
		return

	var leap := sin(rumble * 2.2) * 0.5
	var mult := 1.0 + SURGE * leap
	if gap > CATCH_UP_GAP:
		mult = maxf(mult, CATCH_UP)
	cur_speed = speed * mult
	front_y += cur_speed * delta

	for i in range(jams.size()):
		if front_y >= jams[i].y:
			jam_side = signf(jams[i].x - cx)
			jam_at = jams[i]
			jams.remove_at(i)
			jam_t = JAM_SECS
			cur_speed = 0.0
			jammed_now = true
			if main != null and main.has_node("/root/Sfx"):
				main.get_node("/root/Sfx").play("crack", 1.0)
			break

	var target_x := cx + aim * (half * 0.55)
	var steer: float = (target_x - position.x) * 2.2
	position.x += steer * delta
	position.y = front_y
	queue_redraw()


func _tick_boulders(delta: float) -> void:
	if jam_t > 0.0 or main == null:
		return

	boulder_t -= delta
	if boulder_t <= 0.0 and boulders.size() < MAX_BOULDERS:
		_spawn_boulder()
		boulder_t = BOULDER_EVERY + randf() * BOULDER_JITTER

	# Advance boulders
	var i := boulders.size() - 1
	while i >= 0:
		var b: Dictionary = boulders[i]
		var t: float = float(b.get("t", 0.0)) + delta
		b["t"] = t
		var progress := clampf(t / float(b.get("lead", 1.0)), 0.0, 1.0)
		var from_pos: Vector2 = b["from"]
		var to_pos: Vector2 = b["target"]
		var cur_pos := from_pos.lerp(to_pos, progress)
		b["at"] = cur_pos

		if progress >= 1.0:
			_resolve_boulder_impact(b)
			boulders.remove_at(i)
		i -= 1

	# Decay dust puffs
	var j := dust_puffs.size() - 1
	while j >= 0:
		var d: Dictionary = dust_puffs[j]
		d["t"] = float(d.get("t", 0.0)) + delta
		if float(d["t"]) > IMPACT_TIME:
			dust_puffs.remove_at(j)
		j -= 1


func _spawn_boulder() -> void:
	if main == null or main.dog == null:
		return
	var target_pos: Vector2 = main.dog.global_position
	# Don't throw backwards
	if target_pos.y < front_y + BOULDER_MIN_AHEAD:
		target_pos.y = front_y + BOULDER_MIN_AHEAD + 40.0

	var from_pos := Vector2(position.x, front_y + 20.0)
	var travel_dist := from_pos.distance_to(target_pos)
	var lead_time := clampf(travel_dist / 280.0, 0.7, 1.4)

	boulders.append({
		"from": from_pos,
		"at": from_pos,
		"target": target_pos,
		"t": 0.0,
		"lead": lead_time,
	})
	drop_count += 1
	if main.has_node("/root/Sfx"):
		main.get_node("/root/Sfx").play("bleat", 0.95)


func _resolve_boulder_impact(b: Dictionary) -> void:
	if main == null or main.dog == null:
		return
	var impact_pos: Vector2 = b.get("target", Vector2.ZERO)
	dust_puffs.append({"at": impact_pos, "t": 0.0})

	if main.has_node("/root/Sfx"):
		main.get_node("/root/Sfx").play("crack", 1.2)

	var dog_pos: Vector2 = main.dog.global_position
	var dist := impact_pos.distance_to(dog_pos)

	if dist < BOULDER_R:
		# Direct hit!
		hits += 1
		main.montserrat_goat_hits += 1
		if main.dog.has_method("knocked"):
			var knock_dir := (dog_pos - impact_pos).normalized()
			if knock_dir == Vector2.ZERO:
				knock_dir = Vector2.DOWN
			main.dog.knocked(knock_dir, "boulder")
		if main.feed != null:
			main.feed.say("BOULDER HIT!", EventFeed.Tone.LOUD)
	elif dist < BOULDER_DODGE_R:
		# Clean dodge!
		dodges += 1
		main.montserrat_boulder_dodges += 1
		main.award_points(2, "dodged! +2")
		if main.feed != null:
			main.feed.say("STEPPED CLEAR OF THE BOULDER!", EventFeed.Tone.GOOD)


func boulder_warning() -> bool:
	for b in boulders:
		if float(b.get("t", 0.0)) < BOULDER_WARN:
			return true
	return false


func gap_to(p: Vector2) -> float:
	return p.y - front_y


func caught(p: Vector2) -> bool:
	if p.y <= front_y and p.y >= front_y - GOAT_DEPTH * 0.7:
		return absf(p.x - position.x) <= half * CATCH_SPAN
	return p.y < front_y - GOAT_DEPTH * 0.7


func jammed() -> bool:
	return jam_t > 0.0


func threat_boundary() -> float:
	return front_y


func sweep_junk(_junk: Array) -> int:
	# Bounding goat leaps over loose trash
	return 0


func _draw() -> void:
	# home_chase keeps the node at (walk_cx, front_y) and caught() spans
	# half * CATCH_SPAN either side of it: the herd fills that line, every
	# nose on it, the bodies running back into its depth.
	var b := ShapeBatch.new(self)
	var mw := half * CATCH_SPAN
	_draw_boulders(b)
	# the dust and grit they kick up, behind the whole line
	for i in range(14):
		var f := fposmod(rumble * 1.7 + float(i) * 0.31, 1.0)
		var dx := lerpf(-mw, mw, float(i) / 13.0) + sin(float(i) * 2.7) * 16.0
		b.circle(Vector2(dx, -104.0 - f * 74.0), 13.0 + f * 22.0, Color(DUST_COL, 0.42 * (1.0 - f)))
		if i % 3 == 0:
			b.coarse(Vector2(dx + 9.0, -96.0 - f * 120.0), 3.0 * (1.0 - f) + 1.0, Color(Montserrat.PEBBLES[i % 5], 1.0 - f))
	var stuck := jam_t > 0.0
	for i in range(HERD.size()):
		var g: Array = HERD[i]
		var x := float(g[0]) * (mw - 22.0)
		var lead := i == LEAD
		var nose := Vector2(x, -float(g[2]))
		if stuck and lead:
			# horns wedged: he heaves at it and goes nowhere
			nose += Vector2(sin(rumble * 34.0) * 3.0, -8.0 + absf(sin(rumble * 9.0)) * 5.0)
		_goat(b, nose, float(g[1]), rumble * (5.0 if stuck else 15.0) + float(i) * 1.7, lead, float(g[3]))
	b.flush()


# the boulders they kick loose: where each will land, marked on the ground
# from the moment it is kicked, and the stone itself bounding down to it
func _draw_boulders(b: ShapeBatch) -> void:
	for bl in boulders:
		var from_p: Vector2 = to_local(bl["from"])
		var target_p: Vector2 = to_local(bl["target"])
		var at_p: Vector2 = to_local(bl["at"])
		var f := clampf(float(bl.get("t", 0.0)) / float(bl.get("lead", 1.0)), 0.0, 1.0)
		# the landing: a shadow that darkens and a broken ring that closes on it
		b.glow(target_p, BOULDER_R * 1.5, Color(0.10, 0.06, 0.08, 0.20 + 0.34 * f), 0.5)
		var ring := BOULDER_R * (1.9 - 0.9 * f)
		for d in range(10):
			var a0 := TAU * float(d) / 10.0 + rumble * 2.0
			b.line(target_p + Vector2.from_angle(a0) * ring, target_p + Vector2.from_angle(a0 + 0.34) * ring,
				Color(0.86, 0.20, 0.14, 0.55 + 0.4 * f), 3.0)
		# its dust back up the path
		for d in range(5):
			var df := f - float(d + 1) * 0.07
			if df > 0.0:
				b.circle(from_p.lerp(target_p, df) + Vector2(0.0, -4.0), 9.0 + float(d) * 3.0, Color(DUST_COL, 0.34 - float(d) * 0.06))
		# the stone: two bounces on the way, turning as it comes
		var hop := absf(sin(f * PI * 2.0)) * (1.0 - f * 0.4)
		var r := BOULDER_R * 0.56 * (1.0 + 0.22 * hop)
		b.circle(at_p + Vector2(5.0, 6.0) * (1.0 + hop * 2.2), r * (1.0 - 0.2 * hop), Color(0.06, 0.05, 0.08, 0.34))
		var c := at_p + Vector2(0.0, -hop * 16.0)
		b.circle(c, r + 2.0, INK)
		b.circle(c, r, Montserrat.ROCK)
		b.circle(c + Vector2(-0.22, -0.28) * r, r * 0.72, Montserrat.ROCK_LIT)
		var spin := float(bl.get("t", 0.0)) * 7.0
		for d in range(6):
			var pa := spin + float(d) * 1.05
			var pd := r * (0.30 + 0.38 * fposmod(float(d) * 0.37, 1.0))
			b.coarse(c + Vector2.from_angle(pa) * pd, 2.2 + float(d % 3), Montserrat.PEBBLES[d % 5])
	for d in dust_puffs:
		var p: Vector2 = to_local(d["at"])
		var progress: float = float(d.get("t", 0.0)) / IMPACT_TIME
		for k in range(6):
			var dir := Vector2.from_angle(TAU * float(k) / 6.0 + 0.4)
			b.circle(p + dir * (10.0 + progress * 30.0), 12.0 + progress * 10.0, Color(DUST_COL, 0.5 * (1.0 - progress)))
			b.coarse(p + dir * (16.0 + progress * 54.0), 3.0, Color(Montserrat.PEBBLES[k % 5], 1.0 - progress))
		b.circle(p, 14.0 + progress * 16.0, Color(DUST_COL, 0.4 * (1.0 - progress)))


# a wild goat from above, its nose at `nose`, coming south: the shaggy body
# and the dark stripe down its spine, legs at a gallop, ears out, the long
# face down to a pale muzzle and a beard, yellow eyes with a slot of a pupil
# under a scowl, and the horns: ridged, swept out and curled back round
func _goat(b: ShapeBatch, nose: Vector2, k: float, phase: float, lead: bool, tone: float) -> void:
	var fur := GOAT_FUR.lerp(GOAT_DARK, tone)
	var c := nose + Vector2(0.0, -50.0 * k)
	b.circle(c + Vector2(6.0, 8.0) * k, 30.0 * k, Color(0.05, 0.05, 0.08, 0.26))
	# hooves, two pairs, galloping
	var g := sin(phase) * 7.0 * k
	for s: float in [-1.0, 1.0]:
		b.circle(c + Vector2(s * 16.0 * k, 16.0 * k + g * s), 5.4 * k, INK)
		b.circle(c + Vector2(s * 15.0 * k, -28.0 * k - g * s), 5.4 * k, INK)
	# the scut, up
	b.line(c + Vector2(0, -38) * k, c + Vector2(sin(phase * 0.6) * 3.0, -47.0) * k, INK, 6.0 * k)
	b.line(c + Vector2(0, -38) * k, c + Vector2(sin(phase * 0.6) * 3.0, -46.0) * k, GOAT_BELLY, 3.0 * k)
	# the body: rump, barrel and the heavier shoulders, outlined
	_oval(b, c + Vector2(0, -8) * k, Vector2(21, 34) * k, INK)
	_oval(b, c + Vector2(0, -8) * k, Vector2(18.5, 31.5) * k, fur)
	_oval(b, c + Vector2(0, 8) * k, Vector2(23, 17) * k, INK)
	_oval(b, c + Vector2(0, 8) * k, Vector2(20.5, 14.5) * k, fur)
	# the coat: a dark stripe down the spine, shag along the flanks
	b.line(c + Vector2(0, -36) * k, c + Vector2(0, 14) * k, GOAT_DARK.darkened(0.35), 5.0 * k)
	for m in range(5):
		for s: float in [-1.0, 1.0]:
			var fp := c + Vector2(s * 15.0, -30.0 + float(m) * 10.0) * k
			b.line(fp, fp + Vector2(s * 6.0, -5.0) * k, fur.lightened(0.16), 2.4 * k)
	# ears out to the sides
	for s: float in [-1.0, 1.0]:
		b.polygon(PackedVector2Array([c + Vector2(s * 9, 20) * k, c + Vector2(s * 25, 15) * k,
			c + Vector2(s * 12, 27) * k]), INK)
		b.polygon(PackedVector2Array([c + Vector2(s * 11, 21) * k, c + Vector2(s * 22, 17) * k,
			c + Vector2(s * 13, 25) * k]), fur.lightened(0.12))
	# the long face, narrowing to the muzzle
	b.polygon(PackedVector2Array([c + Vector2(-14, 18) * k, c + Vector2(14, 18) * k, c + Vector2(9, 48) * k,
		c + Vector2(0, 53) * k, c + Vector2(-9, 48) * k]), INK)
	b.polygon(PackedVector2Array([c + Vector2(-11.5, 20) * k, c + Vector2(11.5, 20) * k, c + Vector2(7, 46.5) * k,
		c + Vector2(0, 50.5) * k, c + Vector2(-7, 46.5) * k]), fur)
	b.line(c + Vector2(0, 22) * k, c + Vector2(0, 40) * k, GOAT_DARK.darkened(0.35), 5.0 * k)
	b.circle(nose + Vector2(0, -5) * k, 6.6 * k, GOAT_BELLY)
	b.circle(nose + Vector2(-2.6, -3.0) * k, 1.5 * k, INK)
	b.circle(nose + Vector2(2.6, -3.0) * k, 1.5 * k, INK)
	# the beard, blown about under the chin
	var bw := sin(phase * 0.5) * 2.0 * k
	b.polygon(PackedVector2Array([nose + Vector2(-4, 0) * k, nose + Vector2(4, 0) * k,
		nose + Vector2(bw, 13.0 * k)]), GOAT_DARK.darkened(0.3) if lead else GOAT_BELLY.darkened(0.12))
	# the horns, over everything: every outline first, then the horn
	var hk := k * (1.25 if lead else 1.0)
	for s: float in [-1.0, 1.0]:
		_horn(b, c + Vector2(s * 6.0, 20.0) * k, s, hk, true)
	for s: float in [-1.0, 1.0]:
		_horn(b, c + Vector2(s * 6.0, 20.0) * k, s, hk, false)
	# the eyes: yellow, a black slot across each, the brows down toward the nose
	for s: float in [-1.0, 1.0]:
		var e := c + Vector2(s * 8.5, 33.0) * k
		b.circle(e, 4.4 * k, INK)
		b.circle(e, 3.4 * k, GOAT_EYE)
		b.line(e + Vector2(-2.6, 0) * k, e + Vector2(2.6, 0) * k, INK, 1.7 * k)
		b.line(c + Vector2(s * 14.5, 27.0) * k, c + Vector2(s * 4.0, 31.5) * k, INK, 2.8 * k)
	# a snort off the nose now and then
	var sn := fposmod(phase * 0.07 + tone, 1.0)
	if sn < 0.4:
		for s: float in [-1.0, 1.0]:
			b.circle(nose + Vector2(s * (4.0 + sn * 16.0), 6.0 + sn * 26.0) * k, (3.0 + sn * 12.0) * k,
				Color(0.96, 0.96, 0.96, 0.5 * (1.0 - sn / 0.4)))


# one horn from its root on the brow: out to the side, back along the neck
# and curled round on itself, thick and ridged at the root, down to a point
func _horn(b: ShapeBatch, root: Vector2, s: float, k: float, outline: bool) -> void:
	var centre := root + Vector2(s * 15.0, -9.0) * k
	var prev := root
	var n := 11
	for i in range(1, n + 1):
		var f := float(i) / float(n)
		# from the root round the outside and back in: most of a turn
		var a := 0.54 - f * PI * 1.55
		var r := (17.5 - f * 9.5) * k
		var p := centre + Vector2(-s * cos(a), sin(a)) * r
		var w := (9.0 - f * 6.5) * k
		if outline:
			b.line(prev, p, INK, w + 3.4 * k)
			b.circle(p, (w + 3.4 * k) * 0.5, INK)
		else:
			var col := GOAT_HORN.lerp(GOAT_HORN_TIP, f)
			b.line(prev, p, col, w)
			b.circle(p, w * 0.5, col)
			if i % 2 == 1 and i < n - 1:
				var dir := (p - prev).normalized().orthogonal()
				b.line(p - dir * w * 0.5, p + dir * w * 0.5, GOAT_HORN_RIDGE, 1.5 * k)
		prev = p


func _oval(b: ShapeBatch, at: Vector2, r: Vector2, col: Color) -> void:
	var p := PackedVector2Array()
	for i in range(14):
		p.append(at + Vector2.from_angle(TAU * float(i) / 14.0) * r)
	b.polygon(p, col)
