extends SceneTree

# How riders ride (entities/bike.gd): the styles each walk gets, keeping
# right in a two-way lane, stopping short of someone in a lane too narrow to
# go round them, going round where it is wide enough, still knocking your
# human over when they step out too late to stop for, following the rider
# ahead, pedalling only while not braking, and the skies each style is out in.

# loaded at run time: they read the Game autoload, which a test script
# compiled up front does not see yet
var Bike: GDScript
var Outdoors: GDScript
const DT := 1.0 / 60.0

var failures := 0
var checks := 0


class FakeMain:
	extends Node2D
	var elapsed := 0.0
	var phase := "out"
	var frozen := false
	var lvl := "street"
	var cam := Node2D.new()
	var riders_cache: Array = []
	var walk_mod: GDScript = null
	var said: Array[String] = []
	const POP_SAY := 0

	func _init() -> void:
		add_child(cam)

	func float_text(_p: Vector2, text: String, _c: Color, _k := -1) -> void:
		said.append(text)

	func close_call(_p: Vector2) -> void:
		pass


class FakeDog:
	extends Node2D

	func hit_by_rider(_d: Vector2) -> void:
		pass


class FakeHuman:
	extends Node2D
	var bumps := 0

	func fall(_r: String) -> bool:
		set_meta("falls", int(get_meta("falls", 0)) + 1)
		return true

	func bumped(_d: Vector2) -> void:
		bumps += 1


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + msg)


func _world() -> Dictionary:
	var m := FakeMain.new()
	var d := FakeDog.new()
	var h := FakeHuman.new()
	root.add_child(m)
	m.add_child(d)
	m.add_child(h)
	d.global_position = Vector2(5000, 5000)
	h.global_position = Vector2(5000, 5000)
	return {"main": m, "dog": d, "human": h}


func _rider(w: Dictionary, at: Vector2, v: Vector2, kind := "bike", style := "city") -> Node2D:
	var b := Node2D.new()
	b.set_script(Bike)
	b.visible = false
	b.position = at
	b.set_physics_process(false)
	(w.main as Node2D).add_child(b)
	b.setup(w.main, w.dog, w.human, v, kind)
	b.style = style
	b.cruise = v.length()
	b.speed = b.cruise
	return b


func _initialize() -> void:
	Bike = load("res://entities/bike.gd")
	Outdoors = load("res://systems/outdoors.gd")
	# 1. who rides where
	var seen := {}
	for i in range(200):
		var h := float(i) / 200.0
		seen[Bike.style_for("bike", "aigues", h)] = true
		_check(Bike.style_for("kid", "market", h) == "pram", "the market hall's slow riders are prams")
	_check(seen.keys().all(func(k: String) -> bool: return k in ["mtb", "road"]),
		"Les Aigues is mountain bikes and road bikes only (%s)" % str(seen.keys()))
	_check(seen.has("mtb"), "Les Aigues has mountain bikes")
	var town := {}
	for i in range(200):
		town[Bike.style_for("bike", "street", float(i) / 200.0)] = true
	for s: String in ["city", "bicing", "courier", "escooter", "road"]:
		_check(town.has(s), "the town mix has " + s)

	# 2. keeping right in a two-way lane
	for h: float in [0.0, 0.5, 0.99]:
		var up: float = Bike.keep_right(988.0, 1072.0, true, h)
		var down: float = Bike.keep_right(988.0, 1072.0, false, h)
		_check(up > 1030.0 and up <= 1072.0, "riding up keeps to the east half (%.1f)" % up)
		_check(down < 1030.0 and down >= 988.0, "riding down keeps to the west half (%.1f)" % down)

	# 3. someone standing in a lane too narrow to go round: stop short, ring
	var w := _world()
	(w.human as Node2D).global_position = Vector2(100, 0)
	var b := _rider(w, Vector2(100, 420), Vector2(0, -420))
	b.configure_route(100.0, 90.0, 110.0, [] as Array[Dictionary])
	var closest := 9999.0
	for i in range(240):
		b._physics_process(DT)
		closest = minf(closest, b.global_position.distance_to((w.human as Node2D).global_position))
		if i == 120:
			_check(b.speed < 5.0, "a rider stops for your human in a narrow lane (%.0f px/s)" % b.speed)
	_check(closest > 38.0, "short of them, and goes round them in the end without touching (%.0f px)" % closest)
	_check(int((w.human as Node2D).get_meta("falls", 0)) == 0, "your human is not knocked over")
	_check(b.has_meta("rang") and "ring ring!" in (w.main as FakeMain).said, "the rider rang the bell")
	(w.main as Node2D).queue_free()

	# 4. room to go round: steer past without stopping
	w = _world()
	(w.human as Node2D).global_position = Vector2(100, 0)
	b = _rider(w, Vector2(100, 420), Vector2(0, -400))
	b.configure_route(100.0, 20.0, 220.0, [] as Array[Dictionary])
	var slowest := 9999.0
	closest = 9999.0
	for i in range(120):
		b._physics_process(DT)
		slowest = minf(slowest, b.speed)
		closest = minf(closest, b.global_position.distance_to((w.human as Node2D).global_position))
	_check(b.global_position.y < -100.0, "a rider with room goes round and on (%.0f)" % b.global_position.y)
	_check(slowest > 400.0 * 0.6, "without stopping (%.0f px/s)" % slowest)
	_check(closest > 30.0, "and gives your human room (%.0f px)" % closest)
	(w.main as Node2D).queue_free()

	# 5. stepping out too late: no rider stops from speed in a few px
	w = _world()
	(w.human as Node2D).global_position = Vector2(5000, 5000)
	b = _rider(w, Vector2(100, 70), Vector2(0, -520))
	b.configure_route(100.0, 95.0, 105.0, [] as Array[Dictionary])
	(w.human as Node2D).global_position = Vector2(100, 0)
	for i in range(30):
		b._physics_process(DT)
	_check(int((w.human as Node2D).get_meta("falls", 0)) == 1, "a rider who cannot stop in time still knocks your human over")
	(w.main as Node2D).queue_free()

	# 6. the rider ahead in the same line sets the pace
	w = _world()
	var lead := _rider(w, Vector2(100, 0), Vector2(0, -150))
	var tail := _rider(w, Vector2(100, 160), Vector2(0, -450))
	lead.configure_route(100.0, 98.0, 102.0, [] as Array[Dictionary])
	tail.configure_route(100.0, 98.0, 102.0, [] as Array[Dictionary])
	(w.main as FakeMain).riders_cache = [lead, tail]
	var gap := 9999.0
	for i in range(240):
		lead._physics_process(DT)
		tail._physics_process(DT)
		gap = minf(gap, tail.global_position.y - lead.global_position.y)
	_check(gap > Bike.FOLLOW_GAP * 0.6, "a faster rider waits behind the one ahead (%.0f px)" % gap)
	(w.main as Node2D).queue_free()

	# 7. pedals go round while riding, not while braking
	w = _world()
	b = _rider(w, Vector2(100, 0), Vector2(0, -300))
	b.configure_route(100.0, 20.0, 220.0, [] as Array[Dictionary])
	var c0: float = b.get("crank")
	b._physics_process(DT)
	_check(b.crank > c0, "the pedals turn as a rider rides")
	(w.main as Node2D).queue_free()

	# 8. who is out in which sky
	_check(Outdoors.rider_out("bike", "courier", "rain", "night"), "couriers deliver in the rain at night")
	_check(Outdoors.rider_out("bike", "courier", "snow", "dawn"), "and in the snow")
	_check(not Outdoors.rider_out("bike", "road", "rain", "day"), "road cyclists stay in when it rains")
	_check(not Outdoors.rider_out("bike", "mtb", "clear", "night"), "no mountain biking in the dark")
	_check(not Outdoors.rider_out("bike", "escooter", "snow", "day"), "no electric scooters on snow")
	_check(not Outdoors.rider_out("kid", "pram", "clear", "night"), "no prams out at night")
	_check(Outdoors.rider_out("bike", "bicing", "snow", "night"), "Bicing in any sky")
	_check(not Outdoors.rider_out("roller", "skate", "rain", "day"), "skaters keep off a wet path")

	print("test_rider_ways: %d checks, %s" % [checks, "OK" if failures == 0 else "%d FAILED" % failures])
	quit(1 if failures > 0 else 0)
