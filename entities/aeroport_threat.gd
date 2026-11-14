extends Node2D

# The chase threat of L'Aeroport (Terminal 1): the airport security squad.
# Five officers in a line across the concourse, shoulder to shoulder, each
# holding out what a dog dreads in an airport: the travel crate with its door
# open, the catch net, a detector wand, a loudhailer, the flat hand and the
# whistle. A queue belt is pulled taut between the two on the ends. Drawn to
# its real catch zone (half * CATCH_SPAN either side), like El Veterinari's
# clinic staff (entities/vet_threat.gd), and the same five are in the film
# (intro/film_aeroport.gd).
#
# What sets them apart: confiscated suitcases.
# Every few seconds one of them boots a case up the polished floor at the
# pair. A ring on the floor fills where it will stop.
# Dodging clear counts toward the "luggage_dodge" goal; a hit is a tumble.
#
# They are a squad on foot (systems/chase_squad.gd): each officer runs for
# their place in the line and goes round anything solid, the walkway's rails
# included; they kick litter out of the way, and the line slows to wait for
# whoever is held up on something. The catch is theirs: an officer's body and
# what they hold out, and the belt while the line is together.
#
# Implements the standard chase threat interface (setup, advance, caught,
# gap_to, threat_boundary, sweep_junk) so systems/home_chase drives it.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Squad := preload("res://systems/chase_squad.gd")

const BEACON_AMBER := Color(1.0, 0.75, 0.15)
const WHEEL_RUBBER := Color(0.12, 0.12, 0.14)
const UNIFORM_NAVY := Color(0.14, 0.18, 0.28)
const HIVIS_YELLOW := Color(0.90, 0.95, 0.20)
const BELT_RED := Color(0.80, 0.14, 0.16)
const SUITCASE_RED := Color(0.85, 0.18, 0.15)
const SUITCASE_BLUE := Color(0.18, 0.40, 0.85)
const SUITCASE_HANDLE := Color(0.20, 0.20, 0.22)
# the line, west to east: [what they hold out, skin, a hi-vis vest over the
# uniform]
const SQUAD := [
	["wand", Color(0.80, 0.60, 0.44), true],
	["megaphone", Color(0.93, 0.76, 0.62), false],
	["crate", Color(0.56, 0.38, 0.26), true],
	["whistle", Color(0.97, 0.84, 0.72), false],
	["net", Color(0.86, 0.62, 0.48), true],
]
const SQUAD_BACK := 70.0          # the line, a stride behind the catch line
const OFFICER_R := 22.0           # an officer's body, for what they go round
const OFFICER_REACH := 40.0       # what they hold out, ahead of the body
# what an officer says, held up on something
const HELD_UP_LINES := ["Coming through!", "Out of the way!", "Excuse me!", "Hold that dog!", "Move it!"]

# Movement and tuning
const SPEED_DEFAULT := 136.0
const SURGE := 0.12
const CATCH_UP := 1.35
const CATCH_UP_GAP := 650.0
const JAM_SECS := 3.0
const SQUAD_DEPTH := 140.0
const CATCH_SPAN := 0.72

# what it is stuck in while jammed: the tape at the gate queue, or the perfume
const SNAG_TAPE := 1
const SNAG_PERFUME := 2
const TAPE_JAM_Y := -1900.0

# Tumbling suitcase hazards
const SUITCASE_FIRST := 1.8
const SUITCASE_EVERY := 2.6
const SUITCASE_JITTER := 0.5
const SUITCASE_WARN := 0.9
const SUITCASE_R := 42.0
const SUITCASE_DODGE_R := 110.0
const SUITCASE_LEAD := 0.5
const SUITCASE_MIN_AHEAD := 80.0
const MAX_SUITCASES := 3
const IMPACT_TIME := 0.4

var main: Node2D
var speed := SPEED_DEFAULT
var cur_speed := SPEED_DEFAULT
var front_y := 0.0
var cx := 640.0
var half := 260.0
var kind := "security"
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

# Sliding suitcases in flight: {"from": Vector2, "at": Vector2, "t": float, "color": Color}
var suitcases: Array[Dictionary] = []
# Impact ripples: {"at": Vector2, "t": float}
var impacts: Array[Dictionary] = []
var suitcase_t := SUITCASE_FIRST
var drop_count := 0
var hits := 0
var dodges := 0
var squad: Squad = Squad.new()
var _said := 0


func setup(m: Node2D, start_front_y: float, corridor_cx: float, corridor_half: float, squad_speed: float) -> void:
	main = m
	front_y = start_front_y
	cx = corridor_cx
	half = corridor_half
	speed = squad_speed
	cur_speed = squad_speed
	suitcases.clear()
	impacts.clear()
	suitcase_t = SUITCASE_FIRST
	position = Vector2(cx, front_y)
	var slots: Array = []
	var mw := half * CATCH_SPAN
	for i in range(SQUAD.size()):
		slots.append(lerpf(-mw + 30.0, mw - 30.0, float(i) / float(SQUAD.size() - 1)))
	squad.setup(slots, Vector2(cx, front_y), OFFICER_R, OFFICER_REACH, SQUAD_BACK)


func advance(delta: float, gap := -1.0, aim := 0.0) -> void:
	rumble += delta
	jammed_now = false
	freed_now = false
	_tick_suitcases(delta)

	if jam_t > 0.0:
		jam_t -= delta
		cur_speed = 0.0
		if jam_t <= 0.0:
			freed_now = true
		_tick_squad(delta)
		queue_redraw()
		return

	var lurch := sin(rumble * 1.8) * 0.5
	var mult := 1.0 + SURGE * lurch
	if gap > CATCH_UP_GAP:
		mult = maxf(mult, CATCH_UP)
	# the line waits for whoever is held up on something
	cur_speed = speed * mult * squad.pace()
	front_y += cur_speed * delta

	for i in range(jams.size()):
		if front_y >= jams[i].y:
			jam_side = signf(jams[i].x - cx)
			jam_at = jams[i]
			jams.remove_at(i)
			jam_t = JAM_SECS
			jammed_now = true
			if Sfx != null:
				Sfx.play("crack", 0.9)
			break

	# Steer toward the dog/human
	var target_sway: float = clampf(aim, -half * 0.4, half * 0.4)
	sway_v += (target_sway - sway) * 2.2 * delta
	sway_v *= exp(-3.8 * delta)
	sway += sway_v * delta

	suitcase_t -= delta
	if suitcase_t <= 0.0 and suitcases.size() < MAX_SUITCASES:
		_drop_suitcase()
		suitcase_t = SUITCASE_EVERY + SUITCASE_JITTER * sin(float(drop_count) * 2.7)

	position = Vector2(cx + sway, front_y)
	_tick_squad(delta)
	queue_redraw()


func _tick_squad(delta: float) -> void:
	if main == null:
		return
	squad.slip_points.clear()
	if main.has_method("left_business"):
		var lb: Vector2 = main.left_business()
		if lb.x < INF:
			squad.slip_points.append(lb)
	squad.tick(main, delta, Vector2(cx + sway, front_y), cur_speed)
	var sl := squad.newly_slipped()
	if sl >= 0 and not bool(main.auto_walk) and main.has_method("float_text"):
		main.float_text(squad.members[sl]["pos"] + Vector2(0.0, -34.0), "Eww!", Color(0.92, 0.94, 1.0), main.POP_SAY)
		if Sfx != null:
			Sfx.play("squelch", 0.8, -6.0)
	var i := squad.newly_stuck()
	if i >= 0 and not bool(main.auto_walk) and main.has_method("float_text"):
		main.float_text(squad.members[i]["pos"] + Vector2(0.0, -34.0), String(HELD_UP_LINES[_said % HELD_UP_LINES.size()]),
			Color(0.92, 0.94, 1.0), main.POP_SAY)
		_said += 1


func jammed() -> bool:
	return jam_t > 0.0


# the reach of the frontmost officer: where the camera keeps them in view
func threat_boundary() -> float:
	return squad.front()


func caught(p: Vector2) -> bool:
	return squad.caught(p)


func gap_to(p: Vector2) -> float:
	return p.y - squad.front()


func sweep_junk(junk: Array) -> int:
	return squad.sweep_junk(junk)


# where a case is booted from: the officer in the middle of the line
func squad_pos() -> Vector2:
	if squad.members.is_empty():
		return Vector2(cx + sway, front_y - SQUAD_DEPTH * 0.4)
	return squad.members[squad.members.size() / 2]["pos"]


func aim_point(target: Vector2, vel: Vector2) -> Vector2:
	var p := target + vel * SUITCASE_LEAD
	p.x = clampf(p.x, cx - half + SUITCASE_R, cx + half - SUITCASE_R)
	p.y = maxf(p.y, front_y + SUITCASE_MIN_AHEAD)
	return p


func _drop_suitcase() -> void:
	if main == null:
		return
	var at: Vector2
	if drop_count % 2 == 0:
		at = aim_point(main.dog.global_position, main.dog.velocity)
	else:
		at = aim_point(main.human.global_position, main.human.velocity)
	drop_count += 1
	var col := SUITCASE_RED if drop_count % 2 == 0 else SUITCASE_BLUE
	suitcases.append({"from": squad_pos(), "at": at, "t": 0.0, "color": col})
	if Sfx != null:
		Sfx.play("whoop", 1.4, -6.0)


func _tick_suitcases(delta: float) -> void:
	for i in range(impacts.size() - 1, -1, -1):
		impacts[i]["t"] = float(impacts[i]["t"]) - delta
		if float(impacts[i]["t"]) <= 0.0:
			impacts.remove_at(i)

	for i in range(suitcases.size() - 1, -1, -1):
		var s: Dictionary = suitcases[i]
		s["t"] = float(s["t"]) + delta
		if float(s["t"]) >= SUITCASE_WARN:
			suitcases.remove_at(i)
			_land_suitcase(s["at"])


func _land_suitcase(at: Vector2) -> void:
	impacts.append({"at": at, "t": IMPACT_TIME})
	if Sfx != null:
		Sfx.play("crack", 1.2, -4.0)

	if main == null or main.auto_walk:
		return

	var dp: Vector2 = main.dog.global_position
	var hp: Vector2 = main.human.global_position
	var hit := false

	if at.distance_to(dp) <= SUITCASE_R:
		hit = true
		hits += 1
		main.aeroport_cart_hits += 1
		main.dog.knocked((dp - at).normalized() if dp.distance_to(at) > 1.0 else Vector2.DOWN, "suitcase")
		main.float_text(dp + Vector2(0, -30), "Oof!", Color(1.0, 0.4, 0.3))

	if at.distance_to(hp) <= SUITCASE_R:
		hit = true
		hits += 1
		main.aeroport_cart_hits += 1
		main.human.bumped((hp - at).normalized() if hp.distance_to(at) > 1.0 else Vector2.DOWN)
		main.float_text(hp + Vector2(0, -30), "Whoa! My ankle!", Color(1.0, 0.5, 0.3))

	if not hit:
		if at.distance_to(dp) <= SUITCASE_DODGE_R or at.distance_to(hp) <= SUITCASE_DODGE_R:
			dodges += 1
			main.aeroport_luggage_dodges += 1
			main.combo.add("SUITCASE DODGE", 1)
			main.award_points(1, "dodged! +1")


func suitcase_warning() -> bool:
	if main == null:
		return false
	var dp: Vector2 = main.dog.global_position
	var hp: Vector2 = main.human.global_position
	for s: Dictionary in suitcases:
		var at: Vector2 = s["at"]
		if at.distance_to(dp) < SUITCASE_DODGE_R or at.distance_to(hp) < SUITCASE_DODGE_R:
			return true
	return false


func _draw() -> void:
	var b := ShapeBatch.new(self)
	_draw_skids_and_suitcases(b)
	var snag := 0
	if jam_t > 0.0:
		snag = SNAG_TAPE if absf(jam_at.y - TAPE_JAM_Y) < 80.0 else SNAG_PERFUME
	var spots: Array[Vector2] = []
	var held: Array[bool] = []
	var belts: Array[bool] = []
	for i in range(squad.members.size()):
		spots.append((squad.members[i]["pos"] as Vector2) - global_position)
		held.append(float(squad.members[i]["stuck_t"]) > 0.4)
		belts.append(squad.belt_held(i))
	paint_squad(b, spots, held, belts, Vector2(cx + sway, front_y) - global_position, half * CATCH_SPAN, rumble, snag,
		clampf(jam_t / JAM_SECS, 0.0, 1.0))
	b.flush()


func _draw_skids_and_suitcases(b: ShapeBatch) -> void:
	for s: Dictionary in suitcases:
		var p_from: Vector2 = s["from"] - global_position
		var p_at: Vector2 = s["at"] - global_position
		var k: float = clampf(float(s["t"]) / SUITCASE_WARN, 0.0, 1.0)
		var cur: Vector2 = p_from.lerp(p_at, k)
		var dir := (p_at - p_from).angle()
		var f := Vector2.from_angle(dir)
		# where it will stop: a ring filling on the floor, hazard-dashed
		b.glow(p_at, SUITCASE_R * 1.5, Color(1.0, 0.72, 0.16, 0.22 + 0.22 * k), 0.2)
		b.circle(p_at, SUITCASE_R * k, Color(1.0, 0.80, 0.20, 0.28))
		for i in range(14):
			var a0 := float(i) * TAU / 14.0 + rumble * 1.6
			var a1 := a0 + TAU / 14.0 * 0.55
			b.line(p_at + Vector2.from_angle(a0) * SUITCASE_R, p_at + Vector2.from_angle(a1) * SUITCASE_R, Color(0.16, 0.10, 0.04, 0.8), 6.0)
			b.line(p_at + Vector2.from_angle(a0) * SUITCASE_R, p_at + Vector2.from_angle(a1) * SUITCASE_R, Color(1.0, 0.82, 0.22, 0.95), 3.4)
		# the skid it leaves on the polish
		b.line(p_from.lerp(p_at, maxf(0.0, k - 0.35)), cur, Color(1.0, 1.0, 1.0, 0.35), 12.0)
		b.line(p_from.lerp(p_at, maxf(0.0, k - 0.2)), cur, Color(1.0, 1.0, 1.0, 0.35), 5.0)
		# the case itself, spinning on its back, big enough to mean it
		_case(b, cur, dir + float(s["t"]) * 9.0, s["color"], 1.5)
		b.line(cur - f * 26.0, cur - f * 40.0, Color(1.0, 1.0, 1.0, 0.6), 2.0)

	for imp: Dictionary in impacts:
		var ip: Vector2 = imp["at"] - global_position
		var it: float = float(imp["t"]) / IMPACT_TIME
		b.glow(ip, SUITCASE_R * (1.1 + (1.0 - it) * 0.9), Color(1.0, 0.80, 0.36, 0.6 * it), 0.3)
		# it bursts: socks and shirts thrown out in a ring
		for i in range(8):
			var a := float(i) * TAU / 8.0 + 0.4
			var q := ip + Vector2.from_angle(a) * SUITCASE_R * (0.3 + (1.0 - it) * 1.0)
			b.circle(q, 4.0 * it + 1.5, [SUITCASE_RED, SUITCASE_BLUE, Color(0.96, 0.94, 0.88), HIVIS_YELLOW][i % 4])


# a suitcase from above: shell, ribs, the handle, wheels
static func _case(b: ShapeBatch, p: Vector2, dir: float, col: Color, k: float) -> void:
	var f := Vector2.from_angle(dir)
	var s := f.orthogonal()
	var q := func(a: float, c: float) -> Vector2: return p + f * a * k + s * c * k
	b.quad(q.call(-14.0, -9.0) + Vector2(3.0, 5.0), q.call(14.0, -9.0) + Vector2(3.0, 5.0), q.call(14.0, 9.0) + Vector2(3.0, 5.0), q.call(-14.0, 9.0) + Vector2(3.0, 5.0), Color(0.05, 0.05, 0.08, 0.25))
	b.quad(q.call(-14.0, -9.0), q.call(14.0, -9.0), q.call(14.0, 9.0), q.call(-14.0, 9.0), col.darkened(0.3))
	b.quad(q.call(-12.5, -7.5), q.call(12.5, -7.5), q.call(12.5, 7.5), q.call(-12.5, 7.5), col)
	for r: float in [-5.0, 5.0]:
		b.line(q.call(r, -7.5), q.call(r, 7.5), col.darkened(0.25), 1.6 * k)
	b.line(q.call(-10.0, -5.0), q.call(10.0, -5.0), col.lightened(0.3), 1.4 * k)
	b.line(q.call(14.0, -4.0), q.call(19.0, -4.0), SUITCASE_HANDLE, 2.0 * k)
	b.line(q.call(14.0, 4.0), q.call(19.0, 4.0), SUITCASE_HANDLE, 2.0 * k)
	b.line(q.call(19.0, -5.0), q.call(19.0, 5.0), SUITCASE_HANDLE, 2.6 * k)
	b.circle(q.call(-14.0, -7.0), 2.4 * k, WHEEL_RUBBER)
	b.circle(q.call(-14.0, 7.0), 2.4 * k, WHEEL_RUBBER)


# The squad where they are (`spots`, local), each a stride behind their catch:
# five officers, each holding out what a dog dreads in an airport, and a queue
# belt pulled taut between neighbours while they hold the line (`belts[i]`:
# officer i and i + 1). Split round something, the belt hangs from one of them.
# `held[i]`: that officer is held up on something, and shows it. `o` is the
# line's anchor and `w` its half width, for what they are snagged in while
# jammed (`snag`, `snag_k` 1 just stuck, 0 about to pull free). The film draws
# the same five side on (intro/film_aeroport.gd).
static func paint_squad(b: ShapeBatch, spots: Array[Vector2], held: Array[bool], belts: Array[bool], o: Vector2, w: float,
		t: float, snag := 0, snag_k := 0.0) -> void:
	var n := spots.size()
	if n == 0:
		return
	var at_: Array[Vector2] = []
	for i in range(n):
		var bob := sin(t * 13.0 + float(i) * 1.7) * 3.0
		if held[i]:
			# straining at whatever is in the way
			bob = sin(t * 31.0 + float(i)) * 2.5
		at_.append(spots[i] + Vector2(0.0, bob))
	# their torches on the floor ahead
	var mid := (at_[0] + at_[n - 1]) * 0.5
	b.glow(mid + Vector2(0.0, 130.0), w * 0.9, Color(1.0, 0.96, 0.70, 0.16), 0.1)
	for p: Vector2 in at_:
		b.circle(p + Vector2(4.0, 8.0), 25.0, Color(0.04, 0.05, 0.08, 0.22))
	if snag != SNAG_TAPE:
		for i in range(n - 1):
			var l := at_[i] + Vector2(10.0, 30.0)
			var r := at_[i + 1] + Vector2(-10.0, 30.0)
			if belts[i]:
				var sag := l.lerp(r, 0.5) + Vector2(0.0, 14.0 + sin(t * 9.0 + float(i)) * 3.0)
				_belt(b, l, sag)
				_belt(b, sag, r)
			else:
				# let go: the end hangs off the one holding it, trailing
				var hang := l + Vector2(16.0, 26.0 + sin(t * 7.0 + float(i)) * 4.0)
				_belt(b, l, hang)
				b.circle(hang, 4.0, Color(0.80, 0.82, 0.86))
	for i in range(n):
		var st: Array = SQUAD[i % SQUAD.size()]
		_item(b, at_[i] + Vector2(0.0, 20.0), String(st[0]), float(i), t)
		_officer(b, at_[i], st[1], st[2], String(st[0]) == "whistle", t + float(i))
		if held[i]:
			# effort: sweat off them, and lines of strain
			var f := fposmod(t * 2.6 + float(i) * 0.3, 1.0)
			for s in [-1.0, 1.0]:
				b.circle(at_[i] + Vector2(s * (16.0 + f * 10.0), -12.0 - f * 8.0), 2.4 * (1.0 - f) + 0.8, Color(0.70, 0.88, 1.0, 1.0 - f))
				b.line(at_[i] + Vector2(s * 26.0, -4.0), at_[i] + Vector2(s * 34.0, -10.0), Color(1.0, 1.0, 1.0, 0.85), 2.0)
	if snag == SNAG_TAPE:
		_snag_tape(b, o, w, t, snag_k)
	elif snag == SNAG_PERFUME:
		_snag_perfume(b, o, w, t, snag_k)


static func _belt(b: ShapeBatch, a: Vector2, c: Vector2) -> void:
	b.line(a, c, BELT_RED.darkened(0.3), 9.0)
	b.line(a, c, BELT_RED, 6.0)
	b.circle(a.lerp(c, 0.5), 1.8, Color(1.0, 1.0, 1.0, 0.9))


# one officer from above, facing down the hall at you: navy shoulders under a
# hi-vis vest, both arms out ahead, a peaked cap with its badge, mirrored
# glasses under the peak, a radio clipped on one shoulder
static func _officer(b: ShapeBatch, pos: Vector2, skin: Color, vest: bool, whistling: bool, t: float) -> void:
	_ell(b, pos, Vector2(25.0, 15.0), UNIFORM_NAVY)
	if vest:
		_ell(b, pos + Vector2(0.0, 1.0), Vector2(19.0, 12.0), HIVIS_YELLOW)
		b.line(pos + Vector2(-17.0, 1.0), pos + Vector2(17.0, 1.0), Color(0.82, 0.86, 0.90), 3.0)
	else:
		# epaulettes
		for s: float in [-1.0, 1.0]:
			b.line(pos + Vector2(s * 12.0, -4.0), pos + Vector2(s * 21.0, -2.0), Color(0.96, 0.82, 0.30), 3.0)
	for s: float in [-1.0, 1.0]:
		b.line(pos + Vector2(s * 17.0, 2.0), pos + Vector2(s * 7.0, 20.0), UNIFORM_NAVY, 8.0)
		b.circle(pos + Vector2(s * 7.0, 21.0), 5.0, skin)
	# the radio and its curly lead
	b.rect(Rect2(pos.x + 15.0, pos.y - 9.0, 6.0, 9.0), Color(0.10, 0.10, 0.12))
	b.line(pos + Vector2(18.0, -9.0), pos + Vector2(20.0, -15.0), Color(0.10, 0.10, 0.12), 1.4)
	# the head: face to the south, cap over it, the peak out front
	b.circle(pos + Vector2(0.0, 0.0), 12.0, skin)
	b.quad(pos + Vector2(-11.0, 4.0), pos + Vector2(11.0, 4.0), pos + Vector2(9.0, 15.0), pos + Vector2(-9.0, 15.0), Color(0.08, 0.09, 0.12))
	b.circle(pos + Vector2(0.0, -3.0), 12.5, UNIFORM_NAVY)
	b.line(pos + Vector2(-11.0, 3.0), pos + Vector2(11.0, 3.0), Color(0.08, 0.09, 0.12), 2.0)
	b.circle(pos + Vector2(0.0, -2.0), 3.2, Color(0.96, 0.82, 0.30))
	# the mirrored glasses catching the light, just under the peak
	b.line(pos + Vector2(-7.0, 15.5), pos + Vector2(-1.5, 15.5), Color(0.60, 0.84, 0.96), 2.2)
	b.line(pos + Vector2(1.5, 15.5), pos + Vector2(7.0, 15.5), Color(0.60, 0.84, 0.96), 2.2)
	if whistling:
		var puff := fposmod(t * 3.0, 1.0)
		b.circle(pos + Vector2(0.0, 20.0), 3.0, Color(0.82, 0.84, 0.88))
		for i in range(3):
			var d := Vector2.from_angle(PI * 0.5 + (float(i) - 1.0) * 0.55)
			b.line(pos + Vector2(0.0, 20.0) + d * (7.0 + puff * 8.0), pos + Vector2(0.0, 20.0) + d * (14.0 + puff * 14.0), Color(1.0, 1.0, 1.0, 1.0 - puff), 2.2)


# what one of them holds out ahead, from `at` (their hands) toward you
static func _item(b: ShapeBatch, at: Vector2, item: String, seed: float, t: float) -> void:
	match item:
		"crate":
			# the travel crate, door open, mouth toward you: where dogs go
			# when dogs fly
			var r := Rect2(at.x - 28.0, at.y - 4.0, 56.0, 46.0)
			b.rect(Rect2(r.position + Vector2(4.0, 6.0), r.size), Color(0.04, 0.05, 0.08, 0.22))
			b.rect(r, Color(0.52, 0.55, 0.60))
			b.rect(r.grow(-3.0), Color(0.74, 0.76, 0.80))
			for k in range(4):
				b.rect(Rect2(r.position.x + 8.0 + float(k) * 11.0, r.position.y + 6.0, 6.0, 3.0), Color(0.30, 0.32, 0.36))
			b.rect(Rect2(r.position.x + 5.0, r.end.y - 16.0, r.size.x - 10.0, 16.0), Color(0.06, 0.06, 0.08))
			# the wire door, swinging
			var sw := sin(t * 5.0 + seed) * 0.5 + 0.9
			var hinge := Vector2(r.end.x - 4.0, r.end.y)
			var tip := hinge + Vector2.from_angle(PI * 0.5 - sw) * 40.0
			b.line(hinge, tip, Color(0.84, 0.86, 0.90), 4.0)
			for k in range(1, 4):
				var q := hinge.lerp(tip, float(k) / 4.0)
				b.line(q + Vector2(-3.0, -3.0), q + Vector2(3.0, 3.0), Color(0.60, 0.62, 0.66), 1.4)
			# its sticker
			b.rect(Rect2(r.position.x + 16.0, r.position.y + 14.0, 24.0, 12.0), BEACON_AMBER)
			b.rect(Rect2(r.position.x + 20.0, r.position.y + 18.0, 16.0, 4.0), Color(0.10, 0.10, 0.12))
		"wand":
			# the detector wand, sweeping, bleeping red
			var a := PI * 0.5 + sin(t * 6.0 + seed) * 0.6
			var tip := at + Vector2.from_angle(a) * 44.0
			b.line(at, at + Vector2.from_angle(a) * 14.0, Color(0.10, 0.10, 0.12), 7.0)
			b.line(at + Vector2.from_angle(a) * 12.0, tip, Color(0.10, 0.10, 0.12), 11.0)
			b.line(at + Vector2.from_angle(a) * 16.0, tip - Vector2.from_angle(a) * 3.0, BEACON_AMBER, 5.0)
			var bl := fposmod(t * 2.5 + seed * 0.3, 1.0)
			b.circle(tip, 5.0, Color(0.98, 0.20, 0.16))
			b.circle(tip, 8.0 + bl * 16.0, Color(0.98, 0.20, 0.16, 0.30 * (1.0 - bl)))
		"megaphone":
			# a loudhailer, and what it is saying
			b.quad(at + Vector2(-7.0, 0.0), at + Vector2(7.0, 0.0), at + Vector2(19.0, 30.0), at + Vector2(-19.0, 30.0), Color(0.92, 0.93, 0.95))
			b.quad(at + Vector2(-19.0, 30.0), at + Vector2(19.0, 30.0), at + Vector2(21.0, 36.0), at + Vector2(-21.0, 36.0), Color(0.86, 0.20, 0.18))
			b.rect(Rect2(at.x - 6.0, at.y - 8.0, 12.0, 9.0), Color(0.16, 0.17, 0.20))
			var ph := fposmod(t * 2.2 + seed * 0.4, 1.0)
			for k in range(3):
				var f := fposmod(ph + float(k) / 3.0, 1.0)
				var y := at.y + 42.0 + f * 34.0
				var hw := 16.0 + f * 22.0
				b.line(Vector2(at.x - hw, y - 4.0), Vector2(at.x, y), Color(1.0, 1.0, 1.0, 0.85 * (1.0 - f)), 2.6)
				b.line(Vector2(at.x, y), Vector2(at.x + hw, y - 4.0), Color(1.0, 1.0, 1.0, 0.85 * (1.0 - f)), 2.6)
		"whistle":
			# one hand up flat: STOP. The other points at you.
			b.circle(at + Vector2(-9.0, 12.0), 9.0, Color(0.96, 0.96, 0.94))
			for k in range(4):
				b.line(at + Vector2(-15.0 + float(k) * 4.0, 12.0), at + Vector2(-15.0 + float(k) * 4.0, 24.0), Color(0.96, 0.96, 0.94), 3.4)
			b.line(at + Vector2(9.0, 4.0), at + Vector2(12.0, 30.0), Color(0.96, 0.96, 0.94), 4.0)
		"net":
			var hoop := at + Vector2(sin(t * 6.0 + seed) * 12.0, 54.0)
			b.line(at, hoop, Color(0.50, 0.36, 0.22), 5.0)
			b.circle(hoop + Vector2(4.0, 6.0), 26.0, Color(0.04, 0.05, 0.08, 0.18))
			b.circle(hoop, 26.0, Color(0.50, 0.36, 0.22))
			b.circle(hoop, 22.0, Color(0.92, 0.94, 0.90, 0.40))
			for k in range(-2, 3):
				var off := float(k) * 9.0
				var hl := sqrt(maxf(0.0, 22.0 * 22.0 - off * off))
				b.line(hoop + Vector2(off, -hl), hoop + Vector2(off, hl), Color(1.0, 1.0, 1.0, 0.75), 1.3)
				b.line(hoop + Vector2(-hl, off), hoop + Vector2(hl, off), Color(1.0, 1.0, 1.0, 0.75), 1.3)


static func _ell(b: ShapeBatch, at: Vector2, r: Vector2, col: Color) -> void:
	var p := PackedVector2Array()
	for i in range(16):
		p.append(at + Vector2.from_angle(TAU * float(i) / 16.0) * r)
	b.polygon(p, col)


# stuck in the gate queue: belts wound round ankles and arms, the posts
# dragged over, the whistle doing nothing about it
static func _snag_tape(b: ShapeBatch, o: Vector2, w: float, t: float, k: float) -> void:
	for i in range(6):
		var x0 := -w + 20.0 + float(i) * (w * 2.0 - 40.0) / 5.0
		var x1 := x0 + sin(float(i) * 2.3) * 90.0
		var y1 := -40.0 - float(i % 3) * 30.0 + sin(t * 9.0 + float(i)) * 3.0 * k
		b.line(o + Vector2(x0, 10.0), o + Vector2(x1, y1), BELT_RED.darkened(0.25), 6.0)
		b.line(o + Vector2(x0, 10.0), o + Vector2(x1, y1), BELT_RED, 4.0)
	b.line(o + Vector2(-w, -56.0), o + Vector2(w, -70.0 + sin(t * 8.0) * 3.0), BELT_RED.darkened(0.25), 6.0)
	b.line(o + Vector2(-w, -56.0), o + Vector2(w, -70.0 + sin(t * 8.0) * 3.0), BELT_RED, 4.0)
	for i in range(5):
		var p := o + Vector2(-w + 30.0 + float(i) * (w * 2.0 - 60.0) / 4.0, 16.0 + float(i % 2) * 14.0)
		var lean := Vector2.from_angle(1.2 + float(i) * 1.1) * 20.0
		b.line(p + Vector2(3.0, 4.0), p + lean + Vector2(3.0, 4.0), Color(0.05, 0.05, 0.08, 0.25), 6.0)
		b.circle(p, 8.0, Color(0.16, 0.16, 0.18))
		b.line(p, p + lean, Color(0.70, 0.72, 0.76), 5.0)
		b.circle(p + lean, 4.0, Color(0.92, 0.92, 0.94))


# into the perfume pyramid: a pink reek spreading, bottles everywhere, the
# whole line sneezing
static func _snag_perfume(b: ShapeBatch, o: Vector2, w: float, t: float, k: float) -> void:
	for i in range(5):
		var p := o + Vector2(-w * 0.8 + float(i) * w * 0.4, -30.0 + sin(float(i) * 1.9) * 16.0)
		b.glow(p, 80.0 + sin(t * 2.0 + float(i)) * 8.0, Color(0.98, 0.56, 0.80, 0.32), 0.3)
	for i in range(16):
		var p := o + Vector2(-w + 12.0 + fposmod(float(i) * 61.0, w * 2.0 - 24.0), -20.0 + fposmod(float(i) * 37.0, 70.0))
		var tint: Color = [Color(0.94, 0.46, 0.72), Color(0.98, 0.80, 0.36), Color(0.60, 0.50, 0.90), Color(0.50, 0.82, 0.86)][i % 4]
		var a := float(i) * 1.3
		b.capsule(p, p + Vector2.from_angle(a) * 7.0, 4.0, tint)
		b.circle(p + Vector2.from_angle(a) * 10.0, 2.0, Color(0.92, 0.78, 0.30))
	# the reek, rising in curls, and a sneeze going off somewhere in it
	for i in range(6):
		var f := fposmod(t * 0.7 + float(i) * 0.17, 1.0)
		var p := o + Vector2(-w * 0.7 + float(i) * w * 0.28 + sin(f * 9.0 + float(i)) * 10.0, -40.0 - f * 80.0)
		b.circle(p, 7.0 + f * 9.0, Color(0.98, 0.70, 0.88, 0.5 * (1.0 - f) * (0.4 + 0.6 * k)))
	var sn := fposmod(t * 1.3, 1.0)
	var who := o + Vector2(-w * 0.5 + float(int(t * 1.3) % 4) * w * 0.33, -40.0)
	for i in range(5):
		var d := Vector2.from_angle(PI * 0.5 + (float(i) - 2.0) * 0.3)
		b.line(who + d * (20.0 + sn * 16.0), who + d * (30.0 + sn * 34.0), Color(1.0, 1.0, 1.0, 0.9 * (1.0 - sn)), 2.4)
