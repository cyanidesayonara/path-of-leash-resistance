extends SceneTree

# La Diagonal's riders (systems/diagonal.gd, entities/bike.gd): they ride in
# the two bike lanes inside the tree lines, stop at the line when the lights
# at a crossing are red, ride on when they turn green, and the lamps drawn
# are the lights they obey (the walk's own clock).

const DT := 1.0 / 60.0

var D: GDScript
var Bike: GDScript
var failures := 0
var checks := 0


class FakeMain:
	extends Node2D
	var elapsed := 0.0
	var phase := "out"
	var frozen := false
	var lvl := "diagonal"
	var cam := Node2D.new()
	var riders_cache: Array = []
	var walk_mod: GDScript = null
	const POP_SAY := 0

	func _init() -> void:
		add_child(cam)

	func float_text(_p: Vector2, _t: String, _c: Color, _k := -1) -> void:
		pass

	func close_call(_p: Vector2) -> void:
		pass


class FakeWho:
	extends Node2D

	func hit_by_rider(_d: Vector2) -> void:
		pass

	func fall(_r: String) -> bool:
		return false

	func bumped(_d: Vector2) -> void:
		pass


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + msg)


func _initialize() -> void:
	D = load("res://systems/diagonal.gd")
	Bike = load("res://entities/bike.gd")
	# 1. the lanes
	for i in range(60):
		var rl: Dictionary = D.rider_lane(null, i % 2 == 0)
		var x := float(rl.x)
		var in_l: bool = x > D.BIKE_L and x < D.BIKE_L + D.BIKE_W
		var in_r: bool = x > D.BIKE_R and x < D.BIKE_R + D.BIKE_W
		_check(in_l or in_r, "a rider starts in one of the bike lanes (%.0f)" % x)
		_check(float(rl.lo) >= D.BIKE_L and float(rl.hi) <= D.BIKE_R + D.BIKE_W, "and keeps to it")

	# 2. the light cycle on the walk's clock
	var m := FakeMain.new()
	m.walk_mod = D
	root.add_child(m)
	m.elapsed = 1.0
	_check(D.light(m) == 2, "green at the start of the cycle")
	m.elapsed = D.GREEN_T + 0.5
	_check(D.light(m) == 1, "then amber")
	m.elapsed = D.GREEN_T + D.AMBER_T + 1.0
	_check(D.light(m) == 0, "then red")
	var y0: float = D.CROSSINGS[0]
	var line: float = y0 + D.CROSS_HALF + D.STOP_BACK
	_check(absf(D.rider_hold(m, Vector2(430, line + 200.0), Vector2.UP) - 200.0) < 0.01,
		"on red, the stop line is the distance to hold")
	_check(D.rider_hold(m, Vector2(430, y0), Vector2.UP) < 0.0, "a rider in the crossing rides on")
	_check(D.rider_hold(m, Vector2(430, line + 200.0), Vector2.RIGHT) < 0.0, "only riders along the lanes")

	# 3. a rider coming up to a red light stops at the line, then goes on green
	var who := FakeWho.new()
	m.add_child(who)
	who.global_position = Vector2(5000, 5000)
	var b := Node2D.new()
	b.set_script(Bike)
	b.visible = false
	b.set_physics_process(false)
	b.position = Vector2(440, line + 520.0)
	m.add_child(b)
	b.setup(m, who, who, Vector2(0, -340), "bike")
	b.configure_route(440.0, D.BIKE_L + 7.0, D.BIKE_L + D.BIKE_W - 7.0, [] as Array[Dictionary])
	var red_t: float = D.GREEN_T + D.AMBER_T + 0.1
	m.elapsed = red_t
	for i in range(300):
		m.elapsed = red_t   # held on red
		b._physics_process(DT)
	_check(b.global_position.y > line - D.OVERRUN, "a rider stops at the red light (%.0f, line %.0f)" % [b.global_position.y, line])
	_check(b.global_position.y < line + 40.0, "close up to the line (%.0f)" % (b.global_position.y - line))
	_check(b.speed < 5.0, "and is stopped")
	m.elapsed = 0.5
	for i in range(120):
		m.elapsed += DT
		b._physics_process(DT)
	_check(b.global_position.y < y0 - D.CROSS_HALF, "on green the rider crosses (%.0f)" % b.global_position.y)

	print("test_diagonal_riders: %d checks, %s" % [checks, "OK" if failures == 0 else "%d FAILED" % failures])
	quit(1 if failures > 0 else 0)
