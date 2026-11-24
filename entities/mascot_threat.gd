extends Node2D

# The chase threat of Les Atraccions: the park's mascots. Five foam-headed
# characters of the park's own invention, hand in glove across the path, with
# fixed grins and eyes that never blink: the corsair gull, the cowboy sun, the
# prawn, the jungle lizard, and in the middle the biggest, a dog that is not a
# dog. They only want a hug.
#
# What sets them apart: the flop. Every few seconds one spreads its arms and a
# lane fills on the ground ahead of it (FLOP_WARN), then it throws itself down
# the lane on its belly. In the lane is a tumble; a step out of it is a dodge,
# and the mascot is left flat on its foam, getting up.
#
# They are a squad on foot (systems/chase_squad.gd): each runs for its place in
# the line and goes round anything solid. The catch is theirs: a mascot's body
# and gloves, and the linked gloves while the line is together. One that is
# flopping catches nobody: the flop is a knock, the line is the hug.
#
# Implements the standard chase threat interface (setup, advance, caught,
# gap_to, threat_boundary, sweep_junk) so systems/home_chase drives it.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Squad := preload("res://systems/chase_squad.gd")

# the line, west to east; the film draws the same five (intro/film_mascots.gd)
const CAST := ["gull", "sun", "dog", "prawn", "lizard"]
const BODY := {"gull": Color(0.95, 0.95, 0.92), "sun": Color(0.98, 0.74, 0.16), "dog": Color(0.62, 0.40, 0.24),
	"prawn": Color(0.96, 0.48, 0.42), "lizard": Color(0.34, 0.66, 0.32)}
const COSTUME := {"gull": Color(0.16, 0.24, 0.46), "sun": Color(0.50, 0.28, 0.16), "dog": Color(0.80, 0.16, 0.34),
	"prawn": Color(0.16, 0.56, 0.58), "lizard": Color(0.94, 0.62, 0.20)}
const GLOVE := Color(0.97, 0.97, 0.95)
const INK := Color(0.10, 0.08, 0.12)
const TEETH := Color(1.0, 0.99, 0.94)
const WARN := Color(1.0, 0.34, 0.50)

const LINE_BACK := 70.0
const MASCOT_R := 24.0
const MASCOT_REACH := 36.0
const HELD_LINES := ["Hug!", "Smile!", "Wait for me!", "Photo!", "Friends!"]

const SPEED_DEFAULT := 134.0
const SURGE := 0.12
const CATCH_UP := 1.35
const CATCH_UP_GAP := 650.0
const JAM_SECS := 3.0
const CATCH_SPAN := 0.72

const FLOP_FIRST := 2.0
const FLOP_EVERY := 2.8
const FLOP_JITTER := 0.5
const FLOP_WARN := 0.9
const FLOP_SPEED := 840.0          # a belly slide, which the squad's drag stops
const FLOP_LEN := 205.0            # in about this far
const FLOP_W := 60.0
const FLOP_SLIDE := 0.5            # how long of it can hurt
const FLOP_DOWN := 1.5             # flat on its foam, getting up
const FLOP_HIT_R := 40.0
const FLOP_DODGE_R := 120.0
const FLOP_LEAD := 0.45
const FLOP_TURN := 0.55            # how far off straight down the path it aims
const FLOP_NEAR := 40.0
const FLOP_FAR := 360.0

# what they stopped for, while jammed
const SNAG_CAROUSEL := 1
const SNAG_QUEUE := 2
const QUEUE_JAM_Y := -1850.0

var main: Node2D
var speed := SPEED_DEFAULT
var cur_speed := SPEED_DEFAULT
var front_y := 0.0
var cx := 640.0
var half := 260.0
var kind := "mascots"
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

# the flop being telegraphed or under way: {"i", "t", "from", "dir", "slid",
# "near", "hit_dog", "hit_human"}; empty between flops
var flop: Dictionary = {}
var flop_t := FLOP_FIRST
var flop_count := 0
var hits := 0
var dodges := 0
var squad: Squad = Squad.new()


func setup(m: Node2D, start_front_y: float, corridor_cx: float, corridor_half: float, squad_speed: float) -> void:
	main = m
	front_y = start_front_y
	cx = corridor_cx
	half = corridor_half
	speed = squad_speed
	cur_speed = squad_speed
	flop = {}
	flop_t = FLOP_FIRST
	position = Vector2(cx, front_y)
	var slots: Array = []
	var mw := half * CATCH_SPAN
	for i in range(CAST.size()):
		slots.append(lerpf(-mw + 30.0, mw - 30.0, float(i) / float(CAST.size() - 1)))
	squad.setup(slots, Vector2(cx, front_y), MASCOT_R, MASCOT_REACH, LINE_BACK)


func advance(delta: float, gap := -1.0, aim := 0.0) -> void:
	rumble += delta
	jammed_now = false
	freed_now = false

	if jam_t > 0.0:
		jam_t -= delta
		cur_speed = 0.0
		if jam_t <= 0.0:
			freed_now = true
		_tick_flop(delta)
		_tick_squad(delta)
		return

	var mult := 1.0 + SURGE * sin(rumble * 1.8) * 0.5
	if gap > CATCH_UP_GAP:
		mult = maxf(mult, CATCH_UP)
	# the line waits for whoever is held up, or flat on the ground
	cur_speed = speed * mult * squad.pace()
	front_y += cur_speed * delta

	for i in range(jams.size()):
		if front_y >= jams[i].y:
			jam_side = signf(jams[i].x - cx)
			jam_at = jams[i]
			jams.remove_at(i)
			jam_t = JAM_SECS
			jammed_now = true
			# nobody flops from a ride
			if not flop.is_empty() and not bool(flop["slid"]):
				flop = {}
			break

	var target_sway: float = clampf(aim, -half * 0.4, half * 0.4)
	sway_v += (target_sway - sway) * 2.2 * delta
	sway_v *= exp(-3.8 * delta)
	sway += sway_v * delta

	if not jammed():
		flop_t -= delta
		if flop_t <= 0.0 and flop.is_empty():
			_start_flop()
	_tick_flop(delta)
	position = Vector2(cx + sway, front_y)
	_tick_squad(delta)


func _tick_squad(delta: float) -> void:
	if main != null:
		squad.run(main, delta, Vector2(cx + sway, front_y), cur_speed, true, HELD_LINES, true, I18n.t("w_eww"))
	queue_redraw()


func jammed() -> bool:
	return jam_t > 0.0


# the member who is off its feet, out of the line and catching nobody
func flopped() -> int:
	return int(flop["i"]) if not flop.is_empty() and bool(flop["slid"]) else -1


func _front() -> float:
	var y := -INF
	var out := flopped()
	for i in range(squad.members.size()):
		if i != out:
			y = maxf(y, (squad.members[i]["pos"] as Vector2).y + MASCOT_REACH)
	return y


func threat_boundary() -> float:
	return _front()


func gap_to(p: Vector2) -> float:
	return p.y - _front()


func caught(p: Vector2) -> bool:
	var out := flopped()
	if out < 0:
		return squad.caught(p)
	for i in range(squad.members.size()):
		if i == out:
			continue
		var q: Vector2 = squad.members[i]["pos"]
		if Geometry2D.get_closest_point_to_segment(p, q, q + Vector2(0.0, MASCOT_REACH)).distance_to(p) < MASCOT_R + 6.0:
			return true
		if i + 1 < squad.members.size() and i + 1 != out and squad.belt_held(i):
			var a := q + Vector2(0.0, MASCOT_REACH * 0.6)
			var b := (squad.members[i + 1]["pos"] as Vector2) + Vector2(0.0, MASCOT_REACH * 0.6)
			if Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) < Squad.BELT_REACH:
				return true
	return p.y < squad.rear() - Squad.BEHIND


func sweep_junk(junk: Array) -> int:
	return squad.sweep_junk(junk)


# a continue put the line back: nobody is mid-flop
func continued() -> void:
	flop = {}
	flop_t = FLOP_FIRST


# --- the flop -------------------------------------------------------------------

# the next one, by turns at the dog and at your human, from whoever in the line
# is nearest across the path
func _start_flop() -> void:
	flop_t = 0.4
	if main == null or squad.members.is_empty():
		return
	var who: Node2D = main.dog if flop_count % 2 == 0 else main.human
	var at: Vector2 = who.global_position + (who.velocity as Vector2) * FLOP_LEAD
	var best := -1
	for i in range(squad.members.size()):
		var mb: Dictionary = squad.members[i]
		if float(mb["stuck_t"]) > 0.3 or float(mb["slip_t"]) > 0.0 or squad.clambering(i):
			continue
		if best < 0 or absf((mb["pos"] as Vector2).x - at.x) < absf((squad.members[best]["pos"] as Vector2).x - at.x):
			best = i
	if best < 0:
		return
	# the line runs on while it winds up: the lane starts where it will be
	var from := (squad.members[best]["pos"] as Vector2) + Vector2(0.0, cur_speed * FLOP_WARN)
	var to := at - from
	if to.y < FLOP_NEAR or to.length() > FLOP_FAR:
		return
	var ang := clampf(wrapf(to.angle() - PI * 0.5, -PI, PI), -FLOP_TURN, FLOP_TURN)
	flop = {"i": best, "t": 0.0, "from": from, "dir": Vector2.DOWN.rotated(ang), "slid": false,
		"near": INF, "hit_dog": false, "hit_human": false}
	flop_count += 1
	if Sfx != null:
		Sfx.play("whoop", 0.7, -5.0)


func _tick_flop(delta: float) -> void:
	if flop.is_empty():
		return
	flop["t"] = float(flop["t"]) + delta
	var mb: Dictionary = squad.members[int(flop["i"])]
	if not bool(flop["slid"]):
		if float(flop["t"]) < FLOP_WARN:
			return
		flop["slid"] = true
		flop["t"] = 0.0
		# carried on its belly by the squad's own skid, round nothing, over nothing
		mb["vel"] = (flop["dir"] as Vector2) * FLOP_SPEED
		mb["slip_t"] = FLOP_DOWN
		mb["said"] = true
		if Sfx != null:
			Sfx.play("squelch", 0.6, -3.0)
		return
	var p: Vector2 = mb["pos"]
	if float(flop["t"]) <= FLOP_SLIDE:
		_flop_touch(p)
	elif float(flop["near"]) < INF:
		_end_slide()
	if float(flop["t"]) >= FLOP_DOWN:
		flop = {}
		flop_t = FLOP_EVERY - FLOP_DOWN + FLOP_JITTER * sin(float(flop_count) * 2.7)


func _flop_touch(p: Vector2) -> void:
	if main == null or bool(main.auto_walk):
		return
	var dp: Vector2 = main.dog.global_position
	var hp: Vector2 = main.human.global_position
	flop["near"] = minf(float(flop["near"]), minf(dp.distance_to(p), hp.distance_to(p)))
	if not bool(flop["hit_dog"]) and dp.distance_to(p) <= FLOP_HIT_R:
		flop["hit_dog"] = true
		_count_hit()
		main.dog.knocked(_shove(dp, p), "mascot")
		main.float_text(dp + Vector2(0.0, -30.0), I18n.t("w_oof"), Color(1.0, 0.4, 0.3))
	if not bool(flop["hit_human"]) and hp.distance_to(p) <= FLOP_HIT_R:
		flop["hit_human"] = true
		_count_hit()
		main.human.bumped(_shove(hp, p))
		main.float_text(hp + Vector2(0.0, -30.0), I18n.t("w_no_photos_please"), Color(1.0, 0.94, 0.90), main.POP_SAY)


# bowled on down the path, away from the line rather than back into it
func _shove(at: Vector2, from: Vector2) -> Vector2:
	var away := (at - from).normalized() if at.distance_to(from) > 1.0 else Vector2.ZERO
	return (away + (flop["dir"] as Vector2) * 1.5).normalized()


func _count_hit() -> void:
	hits += 1
	main.atraccions_flop_hits += 1


func _end_slide() -> void:
	var near: float = flop["near"]
	flop["near"] = INF
	if bool(flop["hit_dog"]) or bool(flop["hit_human"]) or near > FLOP_DODGE_R:
		return
	dodges += 1
	main.atraccions_flop_dodges += 1
	main.combo.add("HUG DODGE", 1)
	main.award_points(1, I18n.t("w_dodged_1"))


func flop_end() -> Vector2:
	return (flop["from"] as Vector2) + (flop["dir"] as Vector2) * FLOP_LEN


# the banner's cue: a lane is filling on one of the pair
func flop_warning() -> bool:
	if main == null or flop.is_empty() or bool(flop["slid"]):
		return false
	for who: Node2D in [main.dog, main.human]:
		var q := Geometry2D.get_closest_point_to_segment(who.global_position, flop["from"], flop_end())
		if q.distance_to(who.global_position) < FLOP_DODGE_R:
			return true
	return false


# --- drawing ---------------------------------------------------------------------

func _draw() -> void:
	var b := ShapeBatch.new(self)
	if not flop.is_empty() and not bool(flop["slid"]):
		_draw_lane(b)
	var snag := 0
	if jam_t > 0.0:
		snag = SNAG_QUEUE if absf(jam_at.y - QUEUE_JAM_Y) < 80.0 else SNAG_CAROUSEL
	var spots: Array[Vector2] = []
	var moods: Array[float] = []
	var links: Array[bool] = []
	var winding := int(flop["i"]) if not flop.is_empty() and not bool(flop["slid"]) else -1
	var out := flopped()
	for i in range(squad.members.size()):
		spots.append((squad.members[i]["pos"] as Vector2) - global_position)
		moods.append(1.0 if i == winding else (2.0 if i == out or squad.slipping(i) else 0.0))
		links.append(squad.belt_held(i) and i != out and i + 1 != out)
	var out_dir: Vector2 = flop["dir"] if out >= 0 else Vector2.DOWN
	paint_line(b, spots, moods, links, out_dir, rumble, snag)
	b.flush()


func _draw_lane(b: ShapeBatch) -> void:
	var k := clampf(float(flop["t"]) / FLOP_WARN, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(rumble * 14.0)
	var from := (flop["from"] as Vector2) - global_position
	var to := flop_end() - global_position
	var side := (flop["dir"] as Vector2).orthogonal() * FLOP_W * 0.5
	b.line(from, to, Color(WARN, 0.16 + 0.08 * pulse), FLOP_W)
	b.line(from, from.lerp(to, maxf(k, 0.02)), Color(WARN, 0.30), FLOP_W)
	b.circle(to, FLOP_W * 0.5, Color(WARN, 0.16 + 0.16 * k))
	for sd: float in [-1.0, 1.0]:
		b.line(from + side * sd, to + side * sd, Color(1.0, 0.86, 0.92, 0.85), 2.5)
	# a heart, where it means to land
	_heart(b, to, 11.0 + 5.0 * k, Color(1.0, 0.36, 0.52, 0.5 + 0.4 * k))


static func _heart(b: ShapeBatch, at: Vector2, r: float, col: Color) -> void:
	for s: float in [-1.0, 1.0]:
		b.circle(at + Vector2(s * r * 0.5, -r * 0.3), r * 0.58, col)
	b.polygon(PackedVector2Array([at + Vector2(-r, -r * 0.1), at + Vector2(r, -r * 0.1), at + Vector2(0.0, r * 1.1)]), col)


# The line where it is (`spots`, local): `moods` 0 running, 1 winding up with
# its arms wide, 2 flat on its belly; `links[i]` gloves linked between i and
# i + 1; `snag` what they have stopped for.
static func paint_line(b: ShapeBatch, spots: Array[Vector2], moods: Array[float], links: Array[bool], out_dir: Vector2,
		t: float, snag := 0) -> void:
	var at_: Array[Vector2] = []
	for i in range(spots.size()):
		var p := spots[i]
		if snag == SNAG_CAROUSEL:
			# up and down, as on the horses
			p += Vector2(sin(t * 2.6 + float(i) * 1.3) * 5.0, sin(t * 4.0 + float(i) * 1.6) * 8.0)
		elif snag == SNAG_QUEUE:
			p += Vector2(0.0, absf(sin(t * 6.0 + float(i))) * -2.0)
		elif moods[i] < 2.0:
			p += Vector2(sin(t * 6.5 + float(i) * 1.7) * 3.5, absf(sin(t * 13.0 + float(i) * 1.7)) * -5.0)
		at_.append(p)
	for i in range(at_.size() - 1):
		if links[i] and snag == 0:
			var l := at_[i] + Vector2(20.0, 14.0)
			var r := at_[i + 1] + Vector2(-20.0, 14.0)
			b.line(l, r, INK, 12.0)
			b.line(l, r, GLOVE, 8.0)
	for i in range(at_.size()):
		var who := String(CAST[i % CAST.size()])
		if moods[i] >= 2.0:
			paint_flat(b, at_[i], who, out_dir, t)
		else:
			paint_mascot(b, at_[i], who, t + float(i) * 0.7, moods[i], 1.16 if who == "dog" else 1.0)
	if snag == SNAG_QUEUE and not at_.is_empty():
		# the rope they would never dream of stepping over
		var y := at_[at_.size() / 2].y + 44.0
		var x0 := at_[0].x - 24.0
		var x1 := at_[at_.size() - 1].x + 24.0
		for k in range(6):
			var px := lerpf(x0, x1, float(k) / 5.0)
			if k < 5:
				var nx := lerpf(x0, x1, float(k + 1) / 5.0)
				b.line(Vector2(px, y), Vector2((px + nx) * 0.5, y + 10.0), Color(0.70, 0.18, 0.20), 5.0)
				b.line(Vector2((px + nx) * 0.5, y + 10.0), Vector2(nx, y), Color(0.70, 0.18, 0.20), 5.0)
			b.circle(Vector2(px, y), 7.0, INK)
			b.circle(Vector2(px, y), 5.0, Color(0.90, 0.74, 0.30))
	elif snag == SNAG_CAROUSEL:
		for i in range(at_.size()):
			var p := at_[i]
			b.line(p + Vector2(0.0, -34.0), p + Vector2(0.0, -70.0), Color(0.94, 0.78, 0.34), 5.0)
			for q in range(2):
				var f := fposmod(t * 0.9 + float(i) * 0.23 + float(q) * 0.5, 1.0)
				b.circle(p + Vector2(18.0 - float(q) * 34.0 + sin(f * 8.0) * 6.0, -40.0 - f * 34.0), 3.4, Color(1.0, 0.92, 0.50, 1.0 - f))


# one mascot from above, running south at you. `arms` 0 linked, 1 flung wide.
static func paint_mascot(b: ShapeBatch, p: Vector2, who: String, t: float, arms: float, k := 1.0) -> void:
	var body: Color = BODY[who]
	var cos_: Color = COSTUME[who]
	b.circle(p + Vector2(6.0, 10.0) * k, 28.0 * k, Color(0.04, 0.05, 0.10, 0.26))
	# big shoes slapping along
	for s: float in [-1.0, 1.0]:
		var step := sin(t * 13.0 + s * PI * 0.5) * 9.0
		_ell(b, p + Vector2(s * 10.0, 18.0 + step) * k, Vector2(8.0, 12.0) * k, INK)
		_ell(b, p + Vector2(s * 10.0, 18.0 + step) * k, Vector2(6.0, 10.0) * k, Color(0.86, 0.20, 0.24))
	_ell(b, p + Vector2(0.0, -2.0) * k, Vector2(28.0, 18.0) * k, INK)
	_ell(b, p + Vector2(0.0, -2.0) * k, Vector2(25.5, 15.5) * k, cos_)
	for s: float in [-1.0, 1.0]:
		var wave := sin(t * 9.0 + s) * 3.0
		var hand := p + Vector2(s * lerpf(22.0, 46.0, arms), lerpf(16.0, 12.0, arms) + wave) * k
		b.line(p + Vector2(s * 18.0, 0.0) * k, hand, INK, 13.0 * k)
		b.line(p + Vector2(s * 18.0, 0.0) * k, hand, cos_, 9.5 * k)
		b.circle(hand, 9.5 * k, INK)
		b.circle(hand, 7.5 * k, GLOVE)
		for f in range(3):
			var d := Vector2.from_angle(PI * 0.5 + (float(f) - 1.0) * 0.6)
			b.circle(hand + d * 8.0 * k, 3.6 * k, GLOVE)
	_head(b, p + Vector2(0.0, 2.0) * k, who, body, t, k * (1.0 + 0.08 * arms))


# flat on its belly, sliding or lying there, arms out ahead, feet kicking
static func paint_flat(b: ShapeBatch, p: Vector2, who: String, dir: Vector2, t: float) -> void:
	var f := dir
	var s := f.orthogonal()
	var cos_: Color = COSTUME[who]
	b.circle(p + Vector2(3.0, 5.0), 30.0, Color(0.04, 0.05, 0.10, 0.26))
	for sd: float in [-1.0, 1.0]:
		var kick := sin(t * 16.0 + sd) * 6.0
		b.capsule(p - f * 22.0 + s * sd * 9.0, p - f * (42.0 + kick) + s * sd * 12.0, 7.0, INK)
		b.capsule(p - f * 22.0 + s * sd * 9.0, p - f * (41.0 + kick) + s * sd * 12.0, 5.0, cos_)
		b.circle(p - f * (46.0 + kick) + s * sd * 12.0, 8.0, Color(0.86, 0.20, 0.24))
		var hand := p + f * 34.0 + s * sd * (24.0 + sin(t * 12.0 + sd) * 4.0)
		b.line(p + f * 6.0 + s * sd * 16.0, hand, INK, 12.0)
		b.line(p + f * 6.0 + s * sd * 16.0, hand, cos_, 8.5)
		b.circle(hand, 9.0, INK)
		b.circle(hand, 7.0, GLOVE)
	b.capsule(p - f * 20.0, p + f * 4.0, 21.0, INK)
	b.capsule(p - f * 20.0, p + f * 4.0, 18.5, cos_)
	_head(b, p + f * 24.0, who, BODY[who], t, 1.0)


# the foam head: too big, too round, the grin stitched on, the eyes wide
static func _head(b: ShapeBatch, p: Vector2, who: String, body: Color, t: float, k: float) -> void:
	var r := 25.0 * k
	match who:
		"sun":
			for i in range(12):
				var d := Vector2.from_angle(float(i) * TAU / 12.0 + sin(t * 2.0) * 0.06)
				var n := d.orthogonal()
				b.polygon(PackedVector2Array([p + d * r * 0.9 + n * 7.0 * k, p + d * (r + 13.0 * k), p + d * r * 0.9 - n * 7.0 * k]), INK)
				b.polygon(PackedVector2Array([p + d * r * 0.9 + n * 5.0 * k, p + d * (r + 9.5 * k), p + d * r * 0.9 - n * 5.0 * k]), Color(0.98, 0.56, 0.14))
		"dog":
			for s: float in [-1.0, 1.0]:
				var flap := sin(t * 11.0 + s) * 4.0
				b.capsule(p + Vector2(s * 20.0, -12.0) * k, p + Vector2(s * (33.0 + flap), 10.0) * k, 12.0 * k, INK)
				b.capsule(p + Vector2(s * 20.0, -12.0) * k, p + Vector2(s * (33.0 + flap), 10.0) * k, 9.5 * k, Color(0.40, 0.24, 0.15))
		"prawn":
			for s: float in [-1.0, 1.0]:
				var sway := sin(t * 5.0 + s) * 8.0
				b.line(p + Vector2(s * 8.0, -16.0) * k, p + Vector2(s * 24.0 + sway, -44.0) * k, INK, 5.0 * k)
				b.line(p + Vector2(s * 24.0 + sway, -44.0) * k, p + Vector2(s * 40.0 + sway, -50.0) * k, INK, 4.0 * k)
				b.line(p + Vector2(s * 8.0, -16.0) * k, p + Vector2(s * 24.0 + sway, -44.0) * k, body, 2.6 * k)
				b.line(p + Vector2(s * 24.0 + sway, -44.0) * k, p + Vector2(s * 40.0 + sway, -50.0) * k, body, 2.0 * k)
		"lizard":
			for i in range(5):
				var a := -PI * 0.5 + (float(i) - 2.0) * 0.42
				var d := Vector2.from_angle(a)
				var n := d.orthogonal()
				b.polygon(PackedVector2Array([p + d * r * 0.8 + n * 8.0 * k, p + d * (r + 17.0 * k), p + d * r * 0.8 - n * 8.0 * k]), INK)
				b.polygon(PackedVector2Array([p + d * r * 0.8 + n * 6.0 * k, p + d * (r + 13.0 * k), p + d * r * 0.8 - n * 6.0 * k]), Color(0.90, 0.30, 0.46))
	b.circle(p, r + 2.5, INK)
	b.circle(p, r, body)
	b.circle(p - Vector2(6.0, 8.0) * k, r * 0.55, body.lightened(0.18))
	# what each wears on it
	match who:
		"gull":
			b.polygon(PackedVector2Array([p + Vector2(-31.0, -4.0) * k, p + Vector2(0.0, -34.0) * k, p + Vector2(31.0, -4.0) * k, p + Vector2(0.0, -12.0) * k]), INK)
			b.polygon(PackedVector2Array([p + Vector2(-27.0, -6.0) * k, p + Vector2(0.0, -30.0) * k, p + Vector2(27.0, -6.0) * k, p + Vector2(0.0, -14.0) * k]), Color(0.14, 0.20, 0.40))
			b.line(p + Vector2(-24.0, -7.0) * k, p + Vector2(0.0, -15.0) * k, Color(0.96, 0.78, 0.24), 2.0 * k)
			b.line(p + Vector2(0.0, -15.0) * k, p + Vector2(24.0, -7.0) * k, Color(0.96, 0.78, 0.24), 2.0 * k)
		"sun":
			_ell(b, p + Vector2(0.0, -12.0) * k, Vector2(30.0, 13.0) * k, INK)
			_ell(b, p + Vector2(0.0, -12.0) * k, Vector2(27.0, 10.5) * k, Color(0.50, 0.30, 0.16))
			_ell(b, p + Vector2(0.0, -15.0) * k, Vector2(14.0, 10.0) * k, Color(0.62, 0.38, 0.20))
		"dog":
			_ell(b, p + Vector2(0.0, 10.0) * k, Vector2(16.0, 12.0) * k, Color(0.88, 0.72, 0.52))
			_ell(b, p + Vector2(0.0, 5.0) * k, Vector2(7.0, 5.0) * k, INK)
		"prawn":
			for i in range(3):
				b.line(p + Vector2(-14.0 + float(i) * 2.0, -8.0 - float(i) * 5.0) * k, p + Vector2(14.0 - float(i) * 2.0, -8.0 - float(i) * 5.0) * k, body.darkened(0.22), 2.4 * k)
		"lizard":
			for i in range(4):
				b.circle(p + Vector2(-12.0 + float(i) * 8.0, -12.0 + float(i % 2) * 5.0) * k, 3.0 * k, body.darkened(0.25))
	# the eyes: white saucers, the pupils tiny and fixed on you
	var up := 0.0 if who == "dog" else 2.0
	for s: float in [-1.0, 1.0]:
		var e := p + Vector2(s * 9.5, -1.0 + up * 0.5) * k
		b.circle(e, 8.6 * k, INK)
		b.circle(e, 7.0 * k, Color.WHITE)
		b.circle(e + Vector2(-s * 1.2, 2.0) * k, 2.4 * k, INK)
	if who == "gull":
		b.polygon(PackedVector2Array([p + Vector2(-9.0, 7.0) * k, p + Vector2(9.0, 7.0) * k, p + Vector2(0.0, 29.0) * k]), INK)
		b.polygon(PackedVector2Array([p + Vector2(-6.5, 8.5) * k, p + Vector2(6.5, 8.5) * k, p + Vector2(0.0, 25.0) * k]), Color(0.98, 0.66, 0.16))
		b.line(p + Vector2(-13.0, 12.0) * k, p + Vector2(13.0, 12.0) * k, INK, 2.4 * k)
		return
	# the grin, ear to ear, every tooth showing
	var y := 13.0 if who == "dog" else 11.0
	var grin := PackedVector2Array()
	for i in range(9):
		var u := float(i) / 8.0 * 2.0 - 1.0
		grin.append(p + Vector2(u * 16.0, y + 5.0 - u * u * 6.0) * k)
	for i in range(8, -1, -1):
		var u := float(i) / 8.0 * 2.0 - 1.0
		grin.append(p + Vector2(u * 15.0, y + 12.0 - u * u * 11.0) * k)
	b.polygon(grin, INK)
	for i in range(6):
		var u := (float(i) + 0.5) / 6.0 * 2.0 - 1.0
		var q := p + Vector2(u * 12.5, y + 8.0 - u * u * 8.0) * k
		b.rect(Rect2(q - Vector2(1.9, 2.4) * k, Vector2(3.8, 4.8) * k), TEETH)


static func _ell(b: ShapeBatch, at: Vector2, r: Vector2, col: Color) -> void:
	b.ellipse(at, r.x, r.y, col)
