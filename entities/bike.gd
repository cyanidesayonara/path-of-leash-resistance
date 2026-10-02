extends Node2D

# A rider. Crossing bikes at intersections, bike-lane commuters, and
# wobbly kids on scooters all share this script. Art faces +x and the
# node rotates to the direction of travel.
# Commuters knock the human flat (phone risk); kids just bump ("sorry!").

const BypasserRouteScript := preload("res://systems/bypasser_route.gd")
const RIDER_CLEARANCE := 18.0
const RIDER_MAX_LATERAL_SPEED := 220.0
const RIDER_MINIMUM_LOOKAHEAD := 220.0
const RIDER_LOOKAHEAD_TIME := 1.35

var vel := Vector2.ZERO
var kind := "bike"  # "bike" | "kid"
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


func setup(m: Node2D, d: Node2D, h: Node2D, v: Vector2, k: String) -> void:
	add_to_group("bikes")
	main = m
	dog = d
	human = h
	vel = v
	desired_vertical_speed = v.y
	kind = k
	rotation = vel.angle()
	wob_seed = randf() * 10.0
	if kind == "kid":
		tint = [Color(0.75, 0.55, 0.3), Color(0.5, 0.62, 0.5), Color(0.65, 0.5, 0.62)][randi() % 3]
	else:
		tint = [Color(0.42, 0.5, 0.46), Color(0.55, 0.42, 0.4), Color(0.42, 0.44, 0.56)][randi() % 3]


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
	return true


func _physics_process(delta: float) -> void:
	if main.phase == "freedom":
		queue_free()
		return
	if main.frozen:
		return
	if kind == "kid" and band_hi > band_lo:
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
	if route != null:
		var before := global_position
		var result: Dictionary = route.call(
			"step",
			before,
			desired_vertical_speed,
			delta
		)
		global_position = Vector2(
			float(result.x),
			before.y if bool(result.blocked) else before.y + desired_vertical_speed * delta
		)
		vel = (global_position - before) / delta if delta > 0.0 else Vector2.ZERO
		if not vel.is_zero_approx():
			rotation = vel.angle()
	else:
		position += vel * delta
	var hp: Vector2 = human.global_position
	var dh := global_position.distance_to(hp)
	min_dist = minf(min_dist, dh)
	if not hit_done and dh < 38.0:
		if kind == "bike":
			if human.fall("rider"):
				hit_done = true
		else:
			hit_done = true
			human.bumped((hp - global_position).normalized())
			main.float_text(global_position, "sorry!", Color(1, 1, 1, 0.9), main.POP_SAY)
	if global_position.distance_to(dog.global_position) < 32.0:
		dog.hit_by_rider(vel.normalized())
	var gone_x := global_position.x < -320.0 or global_position.x > 1600.0
	var gone_y := absf(global_position.y - float(main.cam.position.y)) > 1150.0
	if gone_x or gone_y:
		if not hit_done and kind == "bike" and min_dist < 80.0:
			main.close_call(human.global_position)
		queue_free()
	queue_redraw()


# the direction shadows fall (main.LIGHT), repeated here so a rider drawn
# without a main (a test, the lineup) still lights the same way
const LIGHT := Vector2(0.5, 0.866)
const HELMETS: Array[Color] = [Color(0.92, 0.30, 0.22), Color(0.98, 0.84, 0.26), Color(0.26, 0.56, 0.86),
	Color(0.94, 0.94, 0.92)]
const SKIN := Color(0.86, 0.70, 0.56)


static func _oval(at: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in range(12):
		var a := TAU * float(k) / 12.0
		pts.append(at + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


# Seen from directly above, facing +x: wheels are thin tyres seen edge on, the
# rider is a hunched back, two arms out to the bars and a helmet. Lit from the
# upper left of the SCREEN, so the light is turned into the rider's own frame.
# Everything goes through one ShapeBatch: one draw call per rider.
func _draw() -> void:
	var b := ShapeBatch.new(self)
	var sh := LIGHT.rotated(-rotation)       # where shadows fall, in local space
	var hi := -sh                            # where the light comes from
	var helmet: Color = HELMETS[int(wob_seed * 7.0) % HELMETS.size()]
	var tyre := Color(0.12, 0.12, 0.14)
	if kind == "bike":
		b.polygon(_oval(sh * 7.0, 26.0, 8.0), Color(0.05, 0.05, 0.08, 0.20))
		# the tyres and the frame between them
		for wx: float in [-18.0, 18.0]:
			b.line(Vector2(wx - 8.5, 0), Vector2(wx + 8.5, 0), tyre, 4.2)
			b.line(Vector2(wx - 6.0, 0), Vector2(wx + 6.0, 0), Color(0.30, 0.30, 0.33), 1.4)
		b.line(Vector2(-18, 0), Vector2(14, 0), tint.darkened(0.45), 3.6)
		b.line(Vector2(-18, -0.6), Vector2(14, -0.6), tint.lightened(0.15), 1.4)
		# the bars, with grips
		b.line(Vector2(13, -8.5), Vector2(13, 8.5), Color(0.20, 0.20, 0.22), 2.4)
		b.circle(Vector2(13, -8.5), 1.8, Color(0.10, 0.10, 0.10))
		b.circle(Vector2(13, 8.5), 1.8, Color(0.10, 0.10, 0.10))
		# arms out to the bars
		for sy: float in [-1.0, 1.0]:
			b.line(Vector2(0, 6.5 * sy), Vector2(12.5, 8.0 * sy), tint.darkened(0.25), 3.6)
			b.circle(Vector2(12.5, 8.0 * sy), 2.0, SKIN)
		# the back, hunched over the bars, a ball of jersey lit on one side
		b.polygon(_oval(Vector2(-2, 0) + sh * 0.8, 9.5, 9.0), tint.darkened(0.35))
		b.polygon(_oval(Vector2(-2, 0), 8.8, 8.3), tint)
		b.polygon(_oval(Vector2(-2, 0) + hi * 3.5, 3.6, 3.0), tint.lightened(0.25))
		# the helmet, long and vented, with its sheen
		b.polygon(_oval(Vector2(5.5, 0) + sh * 0.6, 6.6, 5.6), helmet.darkened(0.40))
		b.polygon(_oval(Vector2(5.5, 0), 6.0, 5.0), helmet)
		for vy: float in [-2.2, 0.0, 2.2]:
			b.line(Vector2(2.5, vy), Vector2(8.0, vy * 0.8), helmet.darkened(0.30), 1.0)
		b.circle(Vector2(5.5, 0) + hi * 2.6, 1.6, helmet.lightened(0.45))
		for i in range(3):
			var x := -(30.0 + i * 11.0)
			b.line(Vector2(x, -4 + i * 4), Vector2(x - 8.0, -4 + i * 4), Color(1, 1, 1, 0.25), 2.0)
	else:
		b.polygon(_oval(sh * 4.0, 15.0, 6.0), Color(0.05, 0.05, 0.08, 0.20))
		# the deck, the little wheels at either end, the T-bar up front
		for wx: float in [-12.5, 12.5]:
			b.line(Vector2(wx - 3.5, 0), Vector2(wx + 3.5, 0), tyre, 3.4)
		b.line(Vector2(-11, 0), Vector2(11, 0), tint.darkened(0.40), 6.5)
		b.line(Vector2(-10, -1.2), Vector2(10, -1.2), tint.darkened(0.10), 2.0)
		b.line(Vector2(11, -6.5), Vector2(11, 6.5), Color(0.24, 0.24, 0.26), 2.0)
		for sy: float in [-1.0, 1.0]:
			b.line(Vector2(0, 4.5 * sy), Vector2(10.5, 6.0 * sy), tint.darkened(0.15), 2.8)
			b.circle(Vector2(10.5, 6.0 * sy), 1.6, SKIN)
		# a small kid, mostly coat and helmet
		b.polygon(_oval(Vector2(-1.5, 0) + sh * 0.6, 7.0, 6.6), tint.darkened(0.35))
		b.polygon(_oval(Vector2(-1.5, 0), 6.4, 6.0), tint)
		b.polygon(_oval(Vector2(-1.5, 0) + hi * 2.6, 2.6, 2.2), tint.lightened(0.25))
		b.circle(Vector2(3.5, 0) + sh * 0.5, 5.4, helmet.darkened(0.40))
		b.circle(Vector2(3.5, 0), 4.8, helmet)
		b.circle(Vector2(3.5, 0) + hi * 2.0, 1.4, helmet.lightened(0.45))
	b.flush()
