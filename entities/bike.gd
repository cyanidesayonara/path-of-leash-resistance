extends Node2D

# A rider. Crossing bikes at intersections, bike-lane commuters, rollerbladers,
# skaters and kids on scooters all share this script. Art faces +x and the
# node turns smoothly toward the direction of travel.
#
# `kind` is how a rider behaves and what a hit does: "bike" (a commuter: at
# speed it knocks your human flat), "kid" and "roller" (a bump and a "Sorry!").
# `style` is who it is: a city bike, a Bicing, a road cyclist, a mountain
# biker, a delivery courier with the insulated box on their back, an electric
# scooter; a kid on a kick scooter or a little bike; a rollerblader or a
# skater; a parent pushing a pram. Each walk has its own mix (STYLE_MIX), the
# style is read from the rider's own draws, so a seeded walk replays, and
# Outdoors.rider_out says which styles are out in which sky.
#
# Riders ride like people: they hold their side of a lane, pedal or push in
# time with their speed, lean into a turn, ring or call out when someone is
# in their way, steer round them where the lane leaves room and brake where it
# does not. A rider that has slowed right down only bumps; one that could not
# stop in time still knocks your human over.

const Clay := preload("res://entities/clay.gd")
const GameScript := preload("res://autoload/game.gd")

const BypasserRouteScript := preload("res://systems/bypasser_route.gd")
const RIDER_CLEARANCE := 18.0
const RIDER_MAX_LATERAL_SPEED := 220.0
const RIDER_MINIMUM_LOOKAHEAD := 220.0
const RIDER_LOOKAHEAD_TIME := 1.35

# --- how riders ride (tuning) ---------------------------------------------------
const BRAKE_DECEL := 520.0      # px/s/s: the hardest a rider can stop
const BRAKE_PLAN := 0.75       # stops are planned on this share of it, leaving some in hand
const ACCEL := 240.0            # px/s/s: back up to cruising speed
const REACT_TIME := 0.35        # s: a rider's reaction, on top of their stopping distance
const NOTICE_MIN := 70.0        # px: how far ahead a rider watches at the least
const PATH_HALF := 16.0         # half the width a rider needs clear
const PERSON_R := 15.0          # how wide a person or a dog is, for that
const PASS_ROOM := 44.0         # centre to centre, going round someone (a touch is 38)
const STOP_SHORT := 50.0        # px: a stop leaves this much room (a touch is 38)
const DODGE_SLOW := 0.72        # cruising share while steering round someone
const STEER_SHARE := 0.45       # sideways speed per forward speed: no crabbing sideways at a stop
const STEER_MIN := 30.0
const STALL_T := 2.4            # s stopped before a rider looks for a way round off the lane
const STALL_WIDEN := 64.0       # how far off the lane they will go then
const FOLLOW_GAP := 64.0        # px behind the rider ahead in the same line
const SOFT_SPEED := 140.0       # px/s: slower than this a collision is a bump, never a fall
const DOG_SOFT_SPEED := 90.0    # and slower than this they stop against a dog without knocking her
const TURN_RATE := 7.0          # how fast the heading follows the travel
const LEAN_GAIN := 1.0 / 520.0  # lean per px/s/s of turning
const RING_RESET := 2.5         # s clear before the same rider rings again
const CROSS_DODGE := 26.0       # a crossing rider's room either side of its line

# how fast each style rides against what its lane asked for
const STYLE_PACE := {
	"city": 0.86, "bicing": 0.9, "road": 1.18, "mtb": 1.0, "courier": 1.06, "escooter": 0.92,
	"kick": 1.0, "kidbike": 0.95, "roller": 1.0, "skate": 0.95, "pram": 0.8,
}

# Who rides where. Every walk not listed takes "town". A style list is a
# share each; the rider's own hash picks one (style_for).
const STYLE_MIX := {
	"town": {"bike": [["city", 0.28], ["bicing", 0.22], ["courier", 0.24], ["escooter", 0.16], ["road", 0.10]],
		"kid": [["kick", 0.6], ["kidbike", 0.4]], "roller": [["roller", 0.6], ["skate", 0.4]]},
	"park": {"bike": [["city", 0.36], ["bicing", 0.2], ["road", 0.1], ["courier", 0.14], ["escooter", 0.2]],
		"kid": [["kick", 0.45], ["kidbike", 0.55]], "roller": [["roller", 0.7], ["skate", 0.3]]},
	"seafront": {"bike": [["city", 0.3], ["road", 0.26], ["bicing", 0.16], ["escooter", 0.16], ["courier", 0.12]],
		"kid": [["kick", 0.6], ["kidbike", 0.4]], "roller": [["roller", 0.55], ["skate", 0.45]]},
	"trail": {"bike": [["mtb", 0.8], ["road", 0.2]],
		"kid": [["kidbike", 1.0]], "roller": [["roller", 1.0]]},
	"hall": {"bike": [["courier", 1.0]],
		"kid": [["pram", 1.0]], "roller": [["roller", 1.0]]},
}
const WALK_MIX := {
	"park": "park", "ciutadella": "park", "beach": "seafront", "llevant": "seafront", "forum": "seafront",
	"aigues": "trail", "trail": "trail", "carmel": "trail", "horta": "trail", "market": "hall",
}

var vel := Vector2.ZERO
var kind := "bike"  # "bike" | "kid" | "roller"
var style := "city"
var main: Node2D
var dog: Node2D
var human: Node2D
var min_dist := 9999.0
var hit_done := false
var tint := Color(0.4, 0.5, 0.45)
var band_lo := 0.0
var band_hi := 0.0
var base_x := 0.0
var wob_seed := 0.0
var swerve_t := 0.0
var route: RefCounted
var desired_vertical_speed := 0.0
# the riding itself
var look := 0                 # the rider's looks, from their own draw
var cruise := 0.0             # the speed they ride at with the way clear
var speed := 0.0              # the speed they are riding at
var axis := Vector2.RIGHT     # the way along their line
var origin := Vector2.ZERO    # a point on that line (a crossing rider's lane)
var lat := 0.0                # a crossing rider's offset from its line
var heading := 0.0
var lean := 0.0               # -1 leaning left, 1 right, into the turn
var crank := 0.0              # pedal stroke (or stride, or push) phase
var braking := false
var stall_t := 0.0
var rang := false
var clear_t := 0.0
var dodge_x := NAN            # where a lane rider is steering to go round someone
var dodge_lat := NAN          # the same for a crossing rider
var lane_lo := 0.0            # the lane a lane rider was given, and their line in it
var lane_hi := 0.0
var lane_x := 0.0


func setup(m: Node2D, d: Node2D, h: Node2D, v: Vector2, k: String) -> void:
	add_to_group("bikes")
	main = m
	dog = d
	human = h
	vel = v
	desired_vertical_speed = v.y
	kind = k
	wob_seed = randf() * 10.0
	look = randi()
	if kind == "kid":
		tint = [Color(0.75, 0.55, 0.3), Color(0.5, 0.62, 0.5), Color(0.65, 0.5, 0.62)][look % 3]
	elif kind == "roller":
		tint = [Color(0.20, 0.64, 0.76), Color(0.90, 0.42, 0.48), Color(0.94, 0.72, 0.24)][look % 3]
	else:
		tint = [Color(0.42, 0.5, 0.46), Color(0.55, 0.42, 0.4), Color(0.42, 0.44, 0.56)][look % 3]
	var lv := String(m.get("lvl")) if m != null and m.get("lvl") != null else ""
	style = style_for(kind, lv, fmod(wob_seed * 7.31, 1.0))
	cruise = v.length() * float(STYLE_PACE.get(style, 1.0))
	speed = cruise
	desired_vertical_speed = signf(v.y) * cruise if absf(v.y) > absf(v.x) else v.y
	axis = v.normalized() if v.length() > 0.01 else Vector2.RIGHT
	origin = position
	heading = axis.angle()
	rotation = heading
	crank = wob_seed


# Which style a rider of this kind is on this walk, from a number in [0, 1)
# the rider drew anyway.
static func style_for(k: String, lv: String, h: float) -> String:
	var mix: Dictionary = STYLE_MIX[String(WALK_MIX.get(lv, "town"))]
	var list: Array = mix.get(k, [])
	if list.is_empty():
		return {"bike": "city", "kid": "kick", "roller": "roller"}.get(k, "city")
	var acc := 0.0
	for e: Array in list:
		acc += float(e[1])
		if h < acc:
			return String(e[0])
	return String(list[list.size() - 1][0])


# Riders keep to their own side of a two-way lane: in Spain, the right. A
# lane `lo`..`hi`, travelling up the screen (`up`), and a number in [0, 1):
# where in their half they ride.
static func keep_right(lo: float, hi: float, up: bool, h: float) -> float:
	var mid := (lo + hi) * 0.5
	var half := (hi - lo) * 0.5
	var inset := minf(8.0, half * 0.3)
	return lerpf(mid + inset * 0.5, hi - inset, h) if up else lerpf(lo + inset, mid - inset * 0.5, h)


func lane_keep(lo: float, hi: float) -> void:
	# kids weave inside a band instead of holding a line
	band_lo = lo
	band_hi = hi
	base_x = float(route.get("preferred_x")) if route != null else position.x
	swerve_t = randf_range(1.2, 2.8)


func configure_route(
	preferred_x: float,
	min_x: float,
	max_x: float,
	blockers: Array[Dictionary]
) -> bool:
	route = BypasserRouteScript.new(
		preferred_x,
		min_x,
		max_x,
		RIDER_CLEARANCE,
		RIDER_MAX_LATERAL_SPEED,
		RIDER_MINIMUM_LOOKAHEAD,
		RIDER_LOOKAHEAD_TIME
	)
	route.call("configure_blockers", blockers)
	var spawn: Dictionary = route.call(
		"find_clear_spawn_x",
		global_position.y,
		desired_vertical_speed
	)
	if not bool(spawn.found):
		route = null
		return false
	global_position.x = float(spawn.x)
	lane_lo = minf(min_x, max_x)
	lane_hi = maxf(min_x, max_x)
	lane_x = float(route.get("preferred_x"))
	axis = Vector2(0.0, signf(desired_vertical_speed)) if desired_vertical_speed != 0.0 else axis
	heading = axis.angle()
	rotation = heading
	return true


# how far past the view a rider still redraws: half a bike, its shadow, and
# a step of its travel and the camera's
const VIEW_MARGIN := 60.0


func _physics_process(delta: float) -> void:
	if main.phase == "freedom":
		queue_free()
		return
	if main.frozen:
		return
	if (kind == "kid" or kind == "roller") and band_hi > band_lo:
		swerve_t -= delta
		if swerve_t <= 0.0:
			swerve_t = randf_range(1.2, 2.8)
			base_x = clampf(base_x + randf_range(-70.0, 70.0), band_lo, band_hi)
		var t: float = main.elapsed
		var target_x := base_x + sin(t * 2.4 + wob_seed) * 24.0
		if route != null:
			var route_min := float(route.get("min_x"))
			var route_max := float(route.get("max_x"))
			route.set(
				"preferred_x",
				clampf(target_x, maxf(band_lo, route_min), minf(band_hi, route_max))
			)
	_ride(delta)
	var hp: Vector2 = human.global_position
	var dh := global_position.distance_to(hp)
	min_dist = minf(min_dist, dh)
	if not hit_done and dh < 38.0:
		if kind == "bike" and speed >= SOFT_SPEED:
			if human.fall("rider"):
				hit_done = true
		else:
			hit_done = true
			human.bumped((hp - global_position).normalized())
			main.float_text(global_position, sorry_line(), Color(1, 1, 1, 0.9), main.POP_SAY)
	if speed >= DOG_SOFT_SPEED and global_position.distance_to(dog.global_position) < 32.0:
		dog.hit_by_rider(vel.normalized())
	var gone_x := global_position.x < -320.0 or global_position.x > 1600.0
	var gone_y := absf(global_position.y - float(main.cam.position.y)) > 1150.0
	if gone_x or gone_y:
		if not hit_done and kind == "bike" and min_dist < 80.0:
			main.close_call(human.global_position)
		queue_free()
	if Clay.in_view(self, main, Rect2(global_position, Vector2.ZERO), VIEW_MARGIN):
		Redraw.later(self)


# What a rider says having bumped into your human.
func sorry_line() -> String:
	match style:
		"roller", "skate": return "Coming through!"
		"courier": return "Sorry! In a rush!"
		"road": return "Watch it!"
		"pram": return "Oops! Sorry!"
		"escooter": return "Whoa! Sorry!"
	return "Sorry!"


# The ride for one step: watch the way ahead, choose a speed and a line,
# move, and turn and lean with it.
func _ride(delta: float) -> void:
	var fwd := axis
	var want := minf(cruise, _clear_speed(fwd))
	braking = want < speed - 20.0
	speed = move_toward(speed, want, (BRAKE_DECEL if want < speed else ACCEL) * delta)
	stall_t = stall_t + delta if speed < 8.0 else 0.0
	var before := global_position
	if route != null:
		if not is_nan(dodge_x):
			route.set("preferred_x", dodge_x)
		route.set("max_lateral_speed", clampf(speed * STEER_SHARE, STEER_MIN, RIDER_MAX_LATERAL_SPEED))
		var sv := signf(fwd.y) * speed
		var result: Dictionary = route.call("step", before, sv, delta)
		global_position = Vector2(
			float(result.x),
			before.y if bool(result.blocked) else before.y + sv * delta
		)
	else:
		var side := fwd.orthogonal()
		var to_lat := 0.0 if is_nan(dodge_lat) else dodge_lat
		lat = move_toward(lat, to_lat, clampf(speed * STEER_SHARE, STEER_MIN, 160.0) * delta)
		var along := (before - origin).dot(fwd) + speed * delta
		global_position = origin + fwd * along + side * lat
	vel = (global_position - before) / delta if delta > 0.0 else Vector2.ZERO
	# turn toward the travel, never snap; lean with how hard the turn is
	var prev := heading
	if vel.length() > 6.0:
		heading = lerp_angle(heading, vel.angle(), 1.0 - exp(-TURN_RATE * delta))
	var turn := angle_difference(prev, heading) / delta if delta > 0.0 else 0.0
	var lean_to := clampf(turn * speed * LEAN_GAIN, -1.0, 1.0)
	lean = lerpf(lean, lean_to, 1.0 - exp(-6.0 * delta))
	rotation = heading
	# pedals go round with the road; a rider braking freewheels
	if not braking:
		crank += speed * delta * _cadence()
	clear_t += delta


# how many radians of pedal stroke (or stride, or push) per px travelled
func _cadence() -> float:
	match style:
		"road": return 0.034
		"mtb": return 0.030
		"kidbike": return 0.052
		"roller": return 0.022
		"kick", "skate": return 0.016
		"pram": return 0.05
		"escooter": return 0.0
	return 0.026


# The fastest this rider can go now and still not run into anyone: your
# human and the dog in their path, the rider ahead in their line, and a walk's
# own stop lines (a walk module's rider_hold). Plans a way round where the
# lane has room for one.
func _clear_speed(fwd: Vector2) -> float:
	var limit := INF
	var side := fwd.orthogonal()
	# far enough ahead to stop for someone standing there, and a moment to react
	var notice := maxf(NOTICE_MIN, speed * speed / (2.0 * BRAKE_DECEL * BRAKE_PLAN) + speed * REACT_TIME + STOP_SHORT)
	var need := PATH_HALF + PERSON_R
	var seen := false
	var nearest := INF
	# everyone ahead or alongside, across the rider's line: x for a lane
	# rider, the offset from its line for a crossing one
	var people: Array[float] = []
	for who: Node2D in [human, dog]:
		if who == null:
			continue
		var rel: Vector2 = who.global_position - global_position
		var ahead := rel.dot(fwd)
		var off := rel.dot(side)
		if ahead < -20.0 or ahead > notice + 60.0:
			continue
		people.append(who.global_position.x if route != null else lat + off)
		if ahead >= 0.0 and ahead <= notice and absf(off) < need:
			seen = true
			nearest = minf(nearest, ahead)
	if seen:
		if _plan_dodge(people):
			limit = minf(limit, cruise * DODGE_SLOW)
		else:
			limit = minf(limit, sqrt(2.0 * BRAKE_DECEL * BRAKE_PLAN * maxf(0.0, nearest - STOP_SHORT)))
	elif people.is_empty() and (not is_nan(dodge_x) or not is_nan(dodge_lat)):
		# past them: back to the lane
		dodge_x = NAN
		dodge_lat = NAN
		_restore_lane()
	if seen:
		_ring()
		clear_t = 0.0
	elif clear_t > RING_RESET and rang:
		rang = false
		remove_meta("rang")
	# the rider ahead in the same line sets the pace
	var riders: Variant = main.get("riders_cache")
	if riders is Array:
		for r: Variant in riders:
			if r == self or not is_instance_valid(r) or not (r is Node2D):
				continue
			var o := r as Node2D
			var rv: Variant = o.get("axis")
			if not (rv is Vector2) or (rv as Vector2).dot(fwd) < 0.5:
				continue
			var rel2 := o.global_position - global_position
			var a2 := rel2.dot(fwd)
			if a2 <= 0.0 or a2 > FOLLOW_GAP + notice or absf(rel2.dot(side)) > 18.0:
				continue
			limit = minf(limit, float(o.get("speed")) + maxf(0.0, a2 - FOLLOW_GAP) * 2.0)
	# a walk's own stop lines: red lights, a crossing to give way at
	var wm: Variant = main.get("walk_mod")
	if wm != null and (wm as Object).has_method("rider_hold"):
		var d := float((wm as Object).call("rider_hold", main, global_position, fwd))
		if d >= 0.0:
			limit = minf(limit, sqrt(2.0 * BRAKE_DECEL * BRAKE_PLAN * maxf(0.0, d)))
	return limit


# A line past everyone ahead (`people`, across the rider's line) with room
# for each, inside the lane, or, stopped long enough, just off it: the
# nearest such line to where the rider is. False if there is none.
func _plan_dodge(people: Array[float]) -> bool:
	var lo := lane_lo if route != null else -CROSS_DODGE
	var hi := lane_hi if route != null else CROSS_DODGE
	var cur := global_position.x if route != null else lat
	if stall_t > STALL_T:
		lo -= STALL_WIDEN
		hi += STALL_WIDEN
	var best := NAN
	for p: float in people:
		for c: float in [p - PASS_ROOM, p + PASS_ROOM]:
			if c < lo or c > hi:
				continue
			var clear := true
			for q: float in people:
				if absf(c - q) < PASS_ROOM - 0.01:
					clear = false
					break
			if clear and (is_nan(best) or absf(c - cur) < absf(best - cur)):
				best = c
	if is_nan(best):
		return false
	if route != null:
		dodge_x = best
		route.set("min_x", lo)
		route.set("max_x", hi)
	else:
		dodge_lat = best
	return true


# back to the lane they were given
func _restore_lane() -> void:
	if route == null:
		return
	route.set("min_x", lane_lo)
	route.set("max_x", lane_hi)
	if band_hi <= band_lo:
		route.set("preferred_x", clampf(lane_x, lane_lo, lane_hi))


# The warning every hazard to your human gets: a bell, or a call.
# A walk may ring for a rider first (La Carretera de les Aigües rings them
# as they come up on your human); the meta is that bell, shared.
func _ring() -> void:
	if rang or has_meta("rang"):
		rang = true
		return
	rang = true
	set_meta("rang", true)
	var at := global_position + Vector2(0.0, -22.0)
	match style:
		"roller", "skate", "road":
			main.float_text(at, "On your left!", Color(1, 1, 1, 0.9), main.POP_SAY)
		"kick", "pram":
			main.float_text(at, "Excuse me!", Color(1, 1, 1, 0.9), main.POP_SAY)
		_:
			main.float_text(at, "ring ring!", Color(0.96, 0.94, 0.80))
			var sfx := get_node_or_null("/root/Sfx") if is_inside_tree() else null
			if sfx != null:
				sfx.play("bell", 1.0 + (float(look % 9) - 4.0) * 0.01, -9.0)


# --- drawing -------------------------------------------------------------------------

const HELMETS: Array[Color] = [Color(0.92, 0.30, 0.22), Color(0.98, 0.84, 0.26), Color(0.26, 0.56, 0.86),
	Color(0.94, 0.94, 0.92), Color(0.16, 0.17, 0.19), Color(0.36, 0.70, 0.46)]
const SKIN := Color(0.86, 0.70, 0.56)
const TYRE := Color(0.12, 0.12, 0.14)
const RIM := Color(0.30, 0.30, 0.33)
const STEEL := Color(0.24, 0.25, 0.28)
const GRIP := Color(0.10, 0.10, 0.10)
const SHADOW := Color(0.05, 0.05, 0.08, 0.22)
# everyday tops and trousers; sport tops are brighter
const TOPS: Array[Color] = [Color(0.30, 0.38, 0.52), Color(0.62, 0.30, 0.28), Color(0.40, 0.48, 0.36),
	Color(0.78, 0.74, 0.66), Color(0.22, 0.22, 0.25), Color(0.70, 0.56, 0.30), Color(0.52, 0.36, 0.52)]
const BOTTOMS: Array[Color] = [Color(0.22, 0.26, 0.38), Color(0.18, 0.18, 0.20), Color(0.45, 0.40, 0.32),
	Color(0.30, 0.34, 0.30)]
const SPORT: Array[Color] = [Color(0.95, 0.36, 0.20), Color(0.20, 0.62, 0.86), Color(0.86, 0.20, 0.42),
	Color(0.30, 0.74, 0.40), Color(0.98, 0.80, 0.20), Color(0.16, 0.18, 0.24)]
const FRAMES: Array[Color] = [Color(0.16, 0.36, 0.56), Color(0.62, 0.18, 0.18), Color(0.20, 0.42, 0.30),
	Color(0.85, 0.84, 0.80), Color(0.14, 0.14, 0.16), Color(0.86, 0.62, 0.20)]
# Bicing's bikes: white, with red
const BICING_WHITE := Color(0.93, 0.93, 0.91)
const BICING_RED := Color(0.84, 0.14, 0.16)
# the courier's insulated box: a deep violet, no company's colour
const BOX := Color(0.44, 0.24, 0.62)
const BOX_LID := Color(0.54, 0.32, 0.72)
const REFLECT := Color(0.86, 0.88, 0.90)
const HIVIS := Color(0.80, 0.95, 0.24)
const PONCHO := Color(0.30, 0.50, 0.70, 0.78)
const LAMP := Color(1.0, 0.96, 0.82)
const TAIL := Color(1.0, 0.18, 0.14)

static var _unit := PackedVector2Array()


static func _oval(at: Vector2, rx: float, ry: float) -> PackedVector2Array:
	if _unit.is_empty():
		for k in range(14):
			var a := TAU * float(k) / 14.0
			_unit.append(Vector2(cos(a), sin(a)))
	var pts := PackedVector2Array()
	pts.resize(_unit.size())
	for k in range(_unit.size()):
		pts[k] = at + Vector2(_unit[k].x * rx, _unit[k].y * ry)
	return pts


func _pick(list: Array, salt: int) -> Variant:
	return list[(look / salt) % list.size()]


func _skin() -> Color:
	return GameScript.HUMAN_SKINS[(look / 7) % GameScript.HUMAN_SKINS.size()]


func _hair() -> Color:
	return GameScript.HUMAN_HAIRS[(look / 11) % GameScript.HUMAN_HAIRS.size()]


func _helmet() -> Color:
	return HELMETS[(look / 13) % HELMETS.size()]


func _wet() -> bool:
	return Game.weather == "rain"


func _night() -> float:
	return Game.lamp_glow()


# Seen from directly above, facing +x. Lit from the upper left of the SCREEN,
# so the light is turned into the rider's own frame. Everything goes through
# one ShapeBatch: one draw call per rider.
func _draw() -> void:
	var b := ShapeBatch.new(self)
	var sh := Shade.light.rotated(-rotation)       # where shadows fall, in local space
	var hi := -sh                            # where the light comes from
	match style:
		"city", "bicing": _draw_city(b, sh, hi)
		"road": _draw_road(b, sh, hi)
		"mtb": _draw_mtb(b, sh, hi)
		"courier": _draw_courier(b, sh, hi)
		"escooter": _draw_escooter(b, sh, hi)
		"kidbike": _draw_kidbike(b, sh, hi)
		"roller": _draw_roller(b, sh, hi)
		"skate": _draw_skate(b, sh, hi)
		"pram": _draw_pram(b, sh, hi)
		_: _draw_kick(b, sh, hi)
	b.flush()


# --- the shared parts --------------------------------------------------------------

func _wheel(b: ShapeBatch, x: float, half: float, w: float, knobbly := false) -> void:
	b.line(Vector2(x - half, 0), Vector2(x + half, 0), TYRE, w)
	b.line(Vector2(x - half + 2.0, 0), Vector2(x + half - 2.0, 0), RIM, maxf(1.0, w * 0.32))
	if knobbly:
		var k := x - half + 1.5
		while k < x + half - 1.0:
			b.line(Vector2(k, -w * 0.62), Vector2(k, w * 0.62), TYRE, 1.1)
			k += 2.6


# Legs going round on the pedals, seen from above: the knees come forward and
# go back in turn either side of the top tube, the shoes on the pedals.
func _pedal_legs(b: ShapeBatch, hip_x: float, crank_x: float, spread: float, trouser: Color, shoe: Color,
		reach := 6.0) -> void:
	for s: float in [-1.0, 1.0]:
		var ph := crank + (0.0 if s > 0.0 else PI)
		var foot := Vector2(crank_x + cos(ph) * reach, s * (spread - 0.6))
		var knee := Vector2(crank_x + 3.0 + cos(ph) * reach * 0.7, s * (spread + 2.6))
		var hip := Vector2(hip_x, s * 3.4)
		b.line(hip, knee, trouser, 4.4)
		b.line(knee, foot, trouser.darkened(0.12), 3.4)
		b.polygon(_oval(foot + Vector2(1.0, 0), 2.6, 1.7), shoe)


func _arms(b: ShapeBatch, sh_x: float, sh_half: float, grip_x: float, grip_half: float, sleeve: Color,
		hand: Color, body: Vector2) -> void:
	for s: float in [-1.0, 1.0]:
		var from := Vector2(sh_x, s * sh_half) + body
		var to := Vector2(grip_x, s * grip_half)
		b.line(from, from.lerp(to, 0.5), sleeve, 3.6)
		b.line(from.lerp(to, 0.5), to, hand if sleeve.a < 0.5 else sleeve.darkened(0.08), 3.0)
		b.circle(to, 1.9, hand)


func _shoulders(b: ShapeBatch, at: Vector2, rx: float, ry: float, col: Color, sh: Vector2, hi: Vector2) -> void:
	b.polygon(_oval(at + sh * 1.6, rx + 0.6, ry + 0.6), SHADOW)
	b.polygon(_oval(at + sh * 0.6, rx + 0.5, ry + 0.5), col.darkened(0.35))
	b.polygon(_oval(at, rx, ry), col)
	b.polygon(_oval(at + hi * minf(rx, ry) * 0.42, rx * 0.45, ry * 0.42), col.lightened(0.18))


func _helmet_head(b: ShapeBatch, at: Vector2, rx: float, ry: float, col: Color, sh: Vector2, hi: Vector2,
		vents := 3) -> void:
	b.polygon(_oval(at + sh * 0.7, rx + 0.6, ry + 0.6), col.darkened(0.42))
	b.polygon(_oval(at, rx, ry), col)
	for i in range(vents):
		var vy := (float(i) - float(vents - 1) * 0.5) * ry * 0.42
		b.line(at + Vector2(-rx * 0.55, vy), at + Vector2(rx * 0.45, vy * 0.8), col.darkened(0.30), 1.0)
	b.circle(at + hi * rx * 0.42, rx * 0.3, col.lightened(0.45))


# a bare head seen from above: mostly hair, the face a sliver at the front
func _hair_head(b: ShapeBatch, at: Vector2, r: float, hair: Color, skin: Color, sh: Vector2, hi: Vector2,
		tail := false) -> void:
	b.circle(at + sh * 0.7, r + 0.5, SHADOW)
	b.circle(at + Vector2(0.9, 0), r * 0.92, skin)
	b.polygon(_oval(at + Vector2(-0.8, 0), r * 0.92, r), hair)
	if tail:
		b.polygon(_oval(at + Vector2(-r - 1.6, 0), 2.6, 1.8), hair.darkened(0.1))
	b.circle(at + hi * r * 0.45 + Vector2(-0.8, 0), r * 0.32, hair.lightened(0.22))


func _poncho_col() -> Color:
	var col := PONCHO
	col.h = fmod(col.h + float(look % 5) * 0.11, 1.0)
	return col


# The top half of an everyday rider: their top, or in the rain a poncho
# draped over the shoulders and arms, wet and shining.
func _dress(b: ShapeBatch, at: Vector2, rx: float, ry: float, top: Color, sh: Vector2, hi: Vector2) -> void:
	if not _wet():
		_shoulders(b, at, rx, ry, top, sh, hi)
		return
	var col := _poncho_col()
	col.a = 1.0
	b.polygon(_oval(at + sh * 1.8, rx + 3.4, ry + 2.6), SHADOW)
	b.polygon(_oval(at + Vector2(-1.2, 0), rx + 3.0, ry + 2.2), col.darkened(0.25))
	b.polygon(_oval(at + Vector2(-0.6, 0), rx + 2.2, ry + 1.6), col)
	b.polygon(_oval(at + hi * 3.0, rx * 0.5, ry * 0.4), Color(1, 1, 1, 0.30))


# A bare head, or in the rain the poncho's hood up over it.
func _bare_head(b: ShapeBatch, at: Vector2, r: float, skin: Color, sh: Vector2, hi: Vector2, tail: bool) -> void:
	if not _wet():
		_hair_head(b, at, r, _hair(), skin, sh, hi, tail)
		return
	var col := _poncho_col()
	col.a = 1.0
	b.circle(at + Vector2(1.6, 0), r * 0.7, skin)
	b.polygon(_oval(at + Vector2(-1.0, 0), r * 1.05, r * 1.1), col.darkened(0.12))
	b.circle(at + hi * r * 0.45 + Vector2(-1.0, 0), r * 0.32, Color(1, 1, 1, 0.3))


# lights after dark: a lamp ahead and a red one behind
func _lights(b: ShapeBatch, front: Vector2, rear: Vector2) -> void:
	var g := _night()
	if g < 0.3:
		return
	b.glow(front + Vector2(18.0, 0), 26.0 * g, Color(LAMP.r, LAMP.g, LAMP.b, 0.28 * g))
	b.circle(front, 1.8, LAMP)
	b.glow(rear, 8.0, Color(TAIL.r, TAIL.g, TAIL.b, 0.5 * g * (1.6 if braking else 1.0)))
	b.circle(rear, 1.4, TAIL)


func _body_shift() -> Vector2:
	# leaning into the turn; sitting back on the brakes
	return Vector2(-1.6 if braking else 0.0, lean * 3.2)


# --- the styles ----------------------------------------------------------------------

# A city bike or a Bicing: sitting up, a basket on the front, everyday clothes.
func _draw_city(b: ShapeBatch, sh: Vector2, hi: Vector2) -> void:
	var bicing := style == "bicing"
	var frame: Color = BICING_WHITE if bicing else _pick(FRAMES, 3)
	var top: Color = _pick(TOPS, 5)
	var legs: Color = _pick(BOTTOMS, 17)
	var skin := _skin()
	var body := _body_shift()
	b.polygon(_oval(sh * 7.0 + Vector2(1, 0), 27.0, 9.0), SHADOW)
	_wheel(b, -17.0, 9.5, 4.6)
	_wheel(b, 18.0, 9.5, 4.6)
	# mudguards over the tyres, the frame and the chain guard
	b.line(Vector2(-25.0, 0), Vector2(-10.0, 0), frame.darkened(0.2), 2.0)
	b.line(Vector2(-17, 0), Vector2(15, 0), frame.darkened(0.42), 4.2)
	b.line(Vector2(-17, -0.7), Vector2(15, -0.7), frame.lightened(0.12), 1.6)
	if bicing:
		# the red down tube and the front carrier with its fairing
		b.line(Vector2(-6, 0), Vector2(12, 0), BICING_RED, 2.4)
		b.polygon(_oval(Vector2(22.0, 0), 5.0, 6.4), BICING_RED.darkened(0.2))
		b.polygon(_oval(Vector2(22.0, 0), 4.2, 5.6), BICING_RED)
		b.rect(Rect2(19.0, -4.6, 7.0, 9.2), BICING_WHITE)
		b.rect(Rect2(20.5, -1.0, 4.0, 2.0), BICING_RED)
	else:
		# a wicker basket on the front
		var wick := Color(0.66, 0.50, 0.30)
		b.rect(Rect2(19.0, -6.0, 9.0, 12.0), wick.darkened(0.3))
		b.rect(Rect2(19.8, -5.2, 7.4, 10.4), wick)
		for i in range(3):
			b.line(Vector2(20.0, -3.4 + i * 3.4), Vector2(27.0, -3.4 + i * 3.4), wick.darkened(0.22), 0.8)
		if look % 4 == 0:
			b.polygon(_oval(Vector2(23.4, 1.2), 2.8, 2.2), Color(0.86, 0.32, 0.22))   # a bag of something
	# swept-back bars
	b.line(Vector2(13.5, -9.0), Vector2(15.5, 0), STEEL, 2.2)
	b.line(Vector2(13.5, 9.0), Vector2(15.5, 0), STEEL, 2.2)
	b.circle(Vector2(13.5, -9.0), 1.8, GRIP)
	b.circle(Vector2(13.5, 9.0), 1.8, GRIP)
	_pedal_legs(b, -9.0 + body.x, 0.0, 5.6, legs, Color(0.20, 0.18, 0.18))
	# the saddle, then the rider sitting up on it
	b.polygon(_oval(Vector2(-10.0, 0), 4.0, 2.6), Color(0.14, 0.12, 0.10))
	_arms(b, -4.0, 6.6, 13.0, 8.6, top.darkened(0.06), skin, body)
	_dress(b, Vector2(-5.0, 0) + body, 5.6, 8.4, top, sh, hi)
	var head := Vector2(-3.4, 0) + body * 1.35
	if bicing and look % 4 != 0 or not bicing and look % 5 < 3:
		_bare_head(b, head, 4.5, skin, sh, hi, look % 3 == 0)
	else:
		_helmet_head(b, head, 5.0, 4.6, _helmet(), sh, hi)
	_lights(b, Vector2(26.0 if not bicing else 27.0, 0), Vector2(-26.0, 0))


# A road cyclist: down on the drops, long and low, skinny tyres, lycra.
func _draw_road(b: ShapeBatch, sh: Vector2, hi: Vector2) -> void:
	var jersey: Color = _pick(SPORT, 3)
	var frame: Color = _pick(FRAMES, 5)
	var body := _body_shift()
	var skin := _skin()
	b.polygon(_oval(sh * 6.0, 27.0, 7.0), SHADOW)
	_wheel(b, -19.0, 10.0, 3.0)
	_wheel(b, 19.0, 10.0, 3.0)
	b.line(Vector2(-19, 0), Vector2(17, 0), frame.darkened(0.4), 3.2)
	b.line(Vector2(-19, -0.5), Vector2(17, -0.5), frame.lightened(0.15), 1.2)
	# drop bars: narrow, the hoods forward
	b.line(Vector2(16.0, -6.6), Vector2(16.0, 6.6), STEEL, 2.2)
	for s: float in [-1.0, 1.0]:
		b.line(Vector2(16.0, s * 6.6), Vector2(19.5, s * 6.0), GRIP, 2.0)
	_pedal_legs(b, -10.0, -1.0, 5.0, Color(0.10, 0.10, 0.12), Color(0.94, 0.94, 0.92), 6.4)
	b.polygon(_oval(Vector2(-11.0, 0), 4.2, 2.0), Color(0.10, 0.10, 0.10))
	_arms(b, 4.0, 6.2, 18.0, 6.2, jersey, skin, body)
	# the back stretched along the top tube, a stripe down each side
	var back := Vector2(-3.0, 0) + body
	b.polygon(_oval(back + sh * 1.4, 11.0, 7.0), SHADOW)
	b.polygon(_oval(back + sh * 0.6, 10.6, 7.0), jersey.darkened(0.35))
	b.polygon(_oval(back, 10.0, 6.4), jersey)
	b.line(back + Vector2(-8.0, -4.6), back + Vector2(7.0, -4.6), jersey.lightened(0.45), 1.4)
	b.line(back + Vector2(-8.0, 4.6), back + Vector2(7.0, 4.6), jersey.darkened(0.25), 1.4)
	b.polygon(_oval(back + hi * 2.8 + Vector2(1, 0), 4.0, 2.4), jersey.lightened(0.22))
	# back pockets
	b.line(back + Vector2(-8.6, -2.4), back + Vector2(-8.6, 2.4), jersey.darkened(0.3), 1.2)
	# a long, low helmet with its tail
	_helmet_head(b, Vector2(9.5, 0) + body * 1.3, 6.4, 4.4, _helmet(), sh, hi, 3)
	if speed > 380.0:
		for i in range(3):
			var x := -(30.0 + i * 11.0)
			b.line(Vector2(x, -4 + i * 4), Vector2(x - 8.0, -4 + i * 4), Color(1, 1, 1, 0.22), 2.0)
	_lights(b, Vector2(21.0, 0), Vector2(-24.0, 0))


# A mountain biker: fat knobbly tyres, wide flat bars, a trail helmet with a
# peak and a hydration pack.
func _draw_mtb(b: ShapeBatch, sh: Vector2, hi: Vector2) -> void:
	var jersey: Color = _pick(SPORT, 5)
	var frame: Color = _pick(FRAMES, 7)
	var body := _body_shift()
	var skin := _skin()
	b.polygon(_oval(sh * 6.5, 27.0, 10.0), SHADOW)
	_wheel(b, -18.0, 9.6, 6.0, true)
	_wheel(b, 18.0, 9.6, 6.0, true)
	b.line(Vector2(-18, 0), Vector2(15, 0), frame.darkened(0.42), 4.6)
	b.line(Vector2(-18, -0.8), Vector2(15, -0.8), frame.lightened(0.12), 1.6)
	# suspension fork crown, wide bars
	b.rect(Rect2(14.0, -3.0, 4.0, 6.0), STEEL)
	b.line(Vector2(14.5, -12.0), Vector2(14.5, 12.0), Color(0.16, 0.16, 0.18), 2.6)
	b.circle(Vector2(14.5, -12.0), 2.0, GRIP)
	b.circle(Vector2(14.5, 12.0), 2.0, GRIP)
	_pedal_legs(b, -7.0, 1.0, 6.4, Color(0.16, 0.17, 0.20), Color(0.28, 0.24, 0.20), 6.2)
	# attack position: out of the saddle, weight forward
	var up := Vector2(1.5, 0) + body
	_arms(b, 1.0, 7.4, 14.5, 11.0, jersey, skin, body)
	_shoulders(b, up, 7.0, 8.4, jersey, sh, hi)
	# the hydration pack on the back
	b.rect(Rect2(up.x - 8.0, up.y - 3.6, 6.0, 7.2).grow(0.6), Color(0.10, 0.10, 0.12))
	b.rect(Rect2(up.x - 8.0, up.y - 3.6, 6.0, 7.2), Color(0.26, 0.30, 0.28))
	b.line(up + Vector2(-5.0, 4.6), up + Vector2(2.0, 6.4), Color(0.10, 0.10, 0.12), 1.0)
	var head := Vector2(5.5, 0) + body * 1.3
	var hel := _helmet()
	_helmet_head(b, head, 5.6, 5.0, hel, sh, hi, 2)
	b.line(head + Vector2(5.0, -4.0), head + Vector2(6.4, 0), hel.darkened(0.5), 1.8)
	b.line(head + Vector2(6.4, 0), head + Vector2(5.0, 4.0), hel.darkened(0.5), 1.8)


# A food-delivery courier on an e-bike: the big insulated box on their back,
# reflective strips, a phone on the bars.
func _draw_courier(b: ShapeBatch, sh: Vector2, hi: Vector2) -> void:
	var jacket := Color(0.17, 0.18, 0.21)
	var body := _body_shift()
	var skin := _skin()
	b.polygon(_oval(sh * 7.0, 27.0, 10.0), SHADOW)
	_wheel(b, -17.0, 9.6, 5.0)
	_wheel(b, 18.0, 9.6, 5.0)
	b.line(Vector2(-17, 0), Vector2(15, 0), Color(0.16, 0.16, 0.18), 4.6)
	# the battery on the down tube
	b.rect(Rect2(-1.0, -2.6, 11.0, 5.2), Color(0.08, 0.08, 0.09))
	b.rect(Rect2(0.5, -1.2, 3.0, 2.4), Color(0.30, 0.86, 0.46) if _night() > 0.3 else Color(0.26, 0.26, 0.28))
	b.line(Vector2(14.0, -9.0), Vector2(14.0, 9.0), STEEL, 2.4)
	b.circle(Vector2(14.0, -9.0), 1.8, GRIP)
	b.circle(Vector2(14.0, 9.0), 1.8, GRIP)
	# the phone in its mount, lit
	b.rect(Rect2(15.5, -2.6, 3.6, 5.2), Color(0.06, 0.06, 0.08))
	b.rect(Rect2(16.0, -2.1, 2.6, 4.2), Color(0.55, 0.78, 0.95))
	if _night() > 0.3:
		b.glow(Vector2(17.3, 0), 9.0, Color(0.55, 0.78, 0.95, 0.35))
	_pedal_legs(b, -8.0, 0.0, 5.8, Color(0.14, 0.14, 0.16), Color(0.92, 0.92, 0.90))
	b.polygon(_oval(Vector2(-10.0, 0), 4.0, 2.4), Color(0.12, 0.12, 0.12))
	_arms(b, -1.0, 7.0, 13.5, 8.8, jacket, skin, body)
	_shoulders(b, Vector2(-2.0, 0) + body, 6.0, 8.6, jacket, sh, hi)
	# reflective bands on the sleeves
	for s: float in [-1.0, 1.0]:
		b.line(Vector2(5.0, s * 7.6) + body * 0.5, Vector2(6.5, s * 8.0) + body * 0.5, REFLECT, 2.0)
	# the box: tall, so its shadow falls further; violet sides, the lid lighter
	var bx := Vector2(-10.0, 0) + body * 0.8
	var box := Rect2(bx.x - 10.0, bx.y - 11.0, 20.0, 22.0)
	b.rect(Rect2(box.position + sh * 6.0, box.size), SHADOW)
	b.rect(Rect2(box.position + sh * 2.2, box.size).grow(0.6), BOX.darkened(0.45))
	b.rect(box, BOX)
	b.rect(box.grow(-2.2), BOX_LID)
	b.rect(Rect2(box.position.x + 2.2, box.position.y + 2.2, box.size.x - 4.4, 3.0), BOX_LID.lightened(0.18))
	# the lid's seam and a reflective strip round the top
	b.line(Vector2(box.position.x + 2.2, bx.y), Vector2(box.end.x - 2.2, bx.y), BOX.darkened(0.25), 1.0)
	b.line(Vector2(box.position.x, box.position.y + 0.8), Vector2(box.end.x, box.position.y + 0.8), REFLECT, 1.4)
	b.line(Vector2(box.position.x, box.end.y - 0.8), Vector2(box.end.x, box.end.y - 0.8), REFLECT, 1.4)
	if _wet():
		b.rect(Rect2(box.position + Vector2(3.0, 3.0), Vector2(6.0, 5.0)), Color(1, 1, 1, 0.22))
	_helmet_head(b, Vector2(3.5, 0) + body * 1.3, 5.0, 4.7, Color(0.18, 0.19, 0.22), sh, hi)
	b.line(Vector2(0.0, -3.8) + body * 1.3, Vector2(0.0, 3.8) + body * 1.3, HIVIS, 1.4)
	_lights(b, Vector2(23.0, 0), Vector2(-26.0, 0))


# An electric scooter: standing on the narrow deck, one foot ahead of the
# other, both hands on the bar.
func _draw_escooter(b: ShapeBatch, sh: Vector2, hi: Vector2) -> void:
	var top: Color = _pick(TOPS, 3)
	var legs: Color = _pick(BOTTOMS, 7)
	var body := _body_shift()
	var skin := _skin()
	b.polygon(_oval(sh * 5.0, 20.0, 7.0), SHADOW)
	_wheel(b, -15.0, 4.0, 4.0)
	_wheel(b, 14.0, 4.0, 4.0)
	# the deck, its grip mat, the stem and bars
	b.line(Vector2(-16.0, 0), Vector2(11.0, 0), Color(0.14, 0.14, 0.16), 7.4)
	b.line(Vector2(-13.0, 0), Vector2(8.0, 0), Color(0.24, 0.25, 0.27), 5.0)
	b.line(Vector2(-18.0, 0), Vector2(-14.0, 0), Color(0.18, 0.18, 0.2), 4.0)
	b.line(Vector2(12.5, -9.0), Vector2(12.5, 9.0), Color(0.18, 0.18, 0.20), 2.2)
	b.circle(Vector2(12.5, -9.0), 1.7, GRIP)
	b.circle(Vector2(12.5, 9.0), 1.7, GRIP)
	b.rect(Rect2(10.8, -2.0, 3.4, 4.0), Color(0.10, 0.10, 0.12))
	# the feet, one ahead of the other
	b.polygon(_oval(Vector2(3.0, 0.8), 4.2, 2.2), Color(0.92, 0.92, 0.90))
	b.polygon(_oval(Vector2(-6.5, -0.8), 4.2, 2.2), Color(0.92, 0.92, 0.90))
	b.line(Vector2(-1.0, 1.6) + body * 0.5, Vector2(3.0, 0.8), legs, 3.2)
	b.line(Vector2(-3.0, -1.6) + body * 0.5, Vector2(-6.5, -0.8), legs, 3.2)
	_arms(b, -1.0, 6.8, 12.5, 8.8, top, skin, body)
	_dress(b, Vector2(-2.0, 0) + body, 5.4, 8.2, top, sh, hi)
	if look % 10 < 3:
		_helmet_head(b, Vector2(-1.0, 0) + body * 1.35, 5.0, 4.6, _helmet(), sh, hi)
	else:
		_bare_head(b, Vector2(-1.0, 0) + body * 1.35, 4.5, skin, sh, hi, look % 4 == 1)
	_lights(b, Vector2(14.5, 0), Vector2(-18.5, 0))


# A kid on a kick scooter: one foot on the deck, the other pushing along.
func _draw_kick(b: ShapeBatch, sh: Vector2, hi: Vector2) -> void:
	var body := _body_shift()
	var skin := _skin()
	b.polygon(_oval(sh * 4.0, 15.0, 6.5), SHADOW)
	for wx: float in [-12.5, 12.5]:
		b.line(Vector2(wx - 3.5, 0), Vector2(wx + 3.5, 0), TYRE, 3.4)
	b.line(Vector2(-11, 0), Vector2(11, 0), tint.darkened(0.40), 6.5)
	b.line(Vector2(-10, -1.2), Vector2(10, -1.2), tint.darkened(0.10), 2.0)
	b.line(Vector2(11, -6.5), Vector2(11, 6.5), Color(0.24, 0.24, 0.26), 2.0)
	b.circle(Vector2(11, -6.5), 1.6, tint.lightened(0.2))
	b.circle(Vector2(11, 6.5), 1.6, tint.lightened(0.2))
	# the standing foot, and the pushing one: down and back, then up and forward
	var shoe := Color(0.86, 0.30, 0.30) if look % 2 == 0 else Color(0.30, 0.46, 0.80)
	b.polygon(_oval(Vector2(1.0, 1.4), 3.4, 2.0), shoe)
	var push := sin(crank)
	var pf := Vector2(-2.0 - push * 9.0, -5.6 if push > -0.2 else -3.8)
	b.line(Vector2(-1.0, -2.6) + body * 0.4, pf, Color(0.30, 0.34, 0.52), 3.0)
	b.polygon(_oval(pf, 3.2, 1.9), shoe)
	for sy: float in [-1.0, 1.0]:
		b.line(Vector2(0, 4.5 * sy) + body, Vector2(10.5, 6.0 * sy), tint.darkened(0.15), 2.8)
		b.circle(Vector2(10.5, 6.0 * sy), 1.6, skin)
	_shoulders(b, Vector2(-1.5, 0) + body, 4.8, 6.2, tint, sh, hi)
	_kid_helmet(b, Vector2(3.0, 0) + body * 1.3, sh, hi)


func _kid_helmet(b: ShapeBatch, at: Vector2, sh: Vector2, hi: Vector2) -> void:
	var hel := _helmet()
	b.circle(at + sh * 0.5, 4.9, hel.darkened(0.40))
	b.circle(at, 4.4, hel)
	# stickers: dots on a kid's helmet
	b.circle(at + Vector2(-1.5, -2.0), 1.0, Color(1, 1, 1, 0.8))
	b.circle(at + Vector2(1.2, 2.0), 0.9, Color(1, 0.9, 0.3, 0.9))
	b.circle(at + hi * 1.8, 1.3, hel.lightened(0.45))


# A kid on a little bike, with stabilisers.
func _draw_kidbike(b: ShapeBatch, sh: Vector2, hi: Vector2) -> void:
	var body := _body_shift()
	var skin := _skin()
	var frame := tint.lightened(0.15)
	b.polygon(_oval(sh * 4.5, 18.0, 8.0), SHADOW)
	_wheel(b, -11.0, 6.0, 3.8)
	_wheel(b, 11.0, 6.0, 3.8)
	# stabilisers either side of the back wheel
	for s: float in [-1.0, 1.0]:
		b.line(Vector2(-11.0, 0), Vector2(-12.0, s * 7.0), STEEL, 1.2)
		b.line(Vector2(-14.0, s * 7.0), Vector2(-10.0, s * 7.0), TYRE, 2.4)
	b.line(Vector2(-11, 0), Vector2(9, 0), frame.darkened(0.3), 3.6)
	b.line(Vector2(-11, -0.6), Vector2(9, -0.6), frame.lightened(0.2), 1.2)
	b.line(Vector2(9.0, -6.5), Vector2(9.0, 6.5), STEEL, 2.0)
	# streamers off the grips
	for s: float in [-1.0, 1.0]:
		b.circle(Vector2(9.0, s * 6.5), 1.6, frame.lightened(0.3))
		b.line(Vector2(8.0, s * 6.5), Vector2(4.0, s * (8.0 + sin(crank * 2.0 + s) * 1.2)), Color(1, 0.4, 0.7, 0.8), 0.9)
	_pedal_legs(b, -6.0, 0.0, 4.4, Color(0.30, 0.36, 0.56), Color(0.86, 0.30, 0.30), 4.2)
	_arms(b, -2.0, 4.8, 9.0, 6.5, tint, skin, body)
	_shoulders(b, Vector2(-3.0, 0) + body, 4.4, 6.0, tint, sh, hi)
	_kid_helmet(b, Vector2(-1.0, 0) + body * 1.3, sh, hi)


# A rollerblader: an inline-skate push-off stride, arms swinging against it.
func _draw_roller(b: ShapeBatch, sh: Vector2, hi: Vector2) -> void:
	var stride := sin(crank)
	var helmet := _helmet()
	var skin := _skin()
	var body := _body_shift()
	b.polygon(_oval(sh * 4.5, 13.5, 8.5), SHADOW)
	var pad_col := Color(0.16, 0.17, 0.21)
	var wheel_col := Color(0.96, 0.44, 0.26)
	# alternating push-off stride: 4 urethane wheels on a rail under each boot
	for sy: float in [-1.0, 1.0]:
		var push := stride * sy
		var foot := Vector2(-4.5 - push * 5.5, sy * (5.2 + maxf(0.0, push) * 3.8))
		var dir := Vector2(1.0, sy * (0.18 + maxf(0.0, push) * 0.22)).normalized()
		b.line(foot - dir * 6.8, foot + dir * 6.8, Color(0.24, 0.25, 0.28), 2.6)
		for wi in range(4):
			var wp := foot + dir * (-5.1 + float(wi) * 3.4)
			b.circle(wp, 1.5, wheel_col)
		b.polygon(_oval(foot, 4.4, 2.5), Color(0.92, 0.93, 0.95))
		b.circle(foot + dir * 1.4, 1.8, tint.darkened(0.15))
		var knee := Vector2(1.5 - push * 2.0, sy * 4.2)
		b.line(Vector2(-1.0, sy * 3.6), foot, skin, 3.2)
		b.circle(knee, 2.2, pad_col)
	# swinging arms with wrist guards
	for sy: float in [-1.0, 1.0]:
		var arm_f := -stride * sy
		var hand := Vector2(3.5 + arm_f * 5.2, sy * (7.8 + absf(arm_f) * 1.4))
		b.line(Vector2(0.5, sy * 5.8) + body, hand, skin, 2.8)
		b.circle(hand, 1.9, pad_col)
	var c := Vector2(0.0, stride * 1.1) + body
	b.polygon(_oval(c + sh * 0.6, 7.6, 7.2), tint.darkened(0.35))
	b.polygon(_oval(c, 7.0, 6.6), tint)
	b.line(c + Vector2(-5.5, 0), c + Vector2(5.0, 0), Color(0.96, 0.96, 0.94, 0.85), 2.0)
	b.polygon(_oval(c + hi * 2.6, 2.8, 2.4), tint.lightened(0.25))
	var head := Vector2(4.2, stride * 0.8) + body * 1.3
	b.circle(head + sh * 0.5, 5.5, helmet.darkened(0.40))
	b.circle(head, 4.9, helmet)
	b.line(head + Vector2(3.6, -2.8), head + Vector2(3.6, 2.8), Color(0.12, 0.14, 0.18), 1.8)
	b.circle(head + hi * 2.0, 1.5, helmet.lightened(0.45))


# A skater: stood sideways on the board, pushing off with the back foot now
# and then, arms out for balance.
func _draw_skate(b: ShapeBatch, sh: Vector2, hi: Vector2) -> void:
	var deck := Color(0.20, 0.18, 0.18)
	var art: Color = _pick(SPORT, 3)
	var hood: Color = _pick(TOPS, 5)
	var skin := _skin()
	var body := _body_shift()
	b.polygon(_oval(sh * 4.0, 17.0, 8.0), SHADOW)
	for wx: float in [-10.0, 10.0]:
		for s: float in [-1.0, 1.0]:
			b.circle(Vector2(wx, s * 4.6), 1.7, Color(0.95, 0.92, 0.82))
	b.polygon(_oval(Vector2(0, 0), 16.0, 4.6), deck)
	b.polygon(_oval(Vector2(0, 0), 14.4, 3.6), Color(0.12, 0.12, 0.13))
	b.line(Vector2(-15.0, 0), Vector2(-12.0, 0), art, 3.0)
	b.line(Vector2(12.0, 0), Vector2(15.0, 0), art, 3.0)
	# the front foot across the board; the back on the tail, or pushing
	var push := sin(crank)
	var shoe := Color(0.90, 0.90, 0.88) if look % 2 == 0 else Color(0.20, 0.20, 0.22)
	b.polygon(_oval(Vector2(7.0, 0.5), 2.2, 3.8), shoe)
	var back := Vector2(-9.0, 0.5)
	if push > 0.2:
		back = Vector2(-2.0 - push * 12.0, 8.0)
	b.polygon(_oval(back, 2.2, 3.8) if push <= 0.2 else _oval(back, 3.6, 2.2), shoe)
	b.line(Vector2(3.0, 1.0) + body * 0.5, Vector2(7.0, 0.5), Color(0.20, 0.24, 0.34), 3.2)
	b.line(Vector2(-3.0, 1.0) + body * 0.5, back, Color(0.20, 0.24, 0.34), 3.2)
	# shoulders along the board, arms out
	var c := Vector2(0.0, 1.5) + body
	for s: float in [-1.0, 1.0]:
		var hand := c + Vector2(s * 11.0, 2.0 + lean * 4.0 * s)
		b.line(c + Vector2(s * 6.0, 0), hand, hood, 3.0)
		b.circle(hand, 1.8, skin)
	_shoulders(b, c, 7.6, 4.8, hood, sh, hi)
	# a cap on backwards
	var head := c + Vector2(0.0, 0.6)
	b.circle(head + sh * 0.5, 4.6, SHADOW)
	b.circle(head, 4.2, art.darkened(0.2))
	b.polygon(_oval(head + Vector2(0.0, -4.0), 3.2, 1.8), art.darkened(0.35))
	b.circle(head + hi * 1.6, 1.2, art.lightened(0.3))


# A parent pushing a pram ahead of them, walking.
func _draw_pram(b: ShapeBatch, sh: Vector2, hi: Vector2) -> void:
	var top: Color = _pick(TOPS, 3)
	var legs: Color = _pick(BOTTOMS, 7)
	var pram: Color = [Color(0.22, 0.30, 0.42), Color(0.46, 0.52, 0.48), Color(0.62, 0.38, 0.42),
		Color(0.24, 0.24, 0.26)][(look / 5) % 4]
	var skin := _skin()
	var body := _body_shift()
	b.polygon(_oval(sh * 4.0 + Vector2(8.0, 0), 22.0, 10.0), SHADOW)
	# the pram: four wheels, the carrycot, the hood at the handle end
	for wx: float in [6.0, 24.0]:
		for s: float in [-1.0, 1.0]:
			b.line(Vector2(wx - 3.0, s * 8.0), Vector2(wx + 3.0, s * 8.0), TYRE, 2.6)
	b.polygon(_oval(Vector2(16.0, 0) + sh * 0.6, 11.0, 7.4), pram.darkened(0.4))
	b.polygon(_oval(Vector2(16.0, 0), 10.4, 6.8), pram)
	b.polygon(_oval(Vector2(18.0, 0), 5.0, 4.0), Color(0.94, 0.90, 0.84))   # the blanket
	b.polygon(_oval(Vector2(10.0, 0), 4.6, 7.0), pram.darkened(0.22))        # the hood
	b.polygon(_oval(Vector2(10.0, 0) + hi * 1.6, 2.0, 3.6), pram.lightened(0.16))
	b.line(Vector2(3.0, -6.4), Vector2(3.0, 6.4), Color(0.16, 0.16, 0.18), 2.0)
	# the parent: a walk, hands on the handle
	var stride := sin(crank)
	for s: float in [-1.0, 1.0]:
		var foot := Vector2(-8.0 + stride * s * 5.0, s * 3.4)
		b.line(Vector2(-8.0, s * 3.0), foot, legs, 3.4)
		b.polygon(_oval(foot + Vector2(1.2, 0), 2.8, 1.8), Color(0.18, 0.16, 0.14))
	_arms(b, -7.0, 6.4, 3.0, 5.6, top, skin, body)
	_dress(b, Vector2(-8.0, 0) + body, 5.0, 7.8, top, sh, hi)
	_bare_head(b, Vector2(-7.0, 0) + body * 1.3, 4.4, skin, sh, hi, look % 3 != 0)
