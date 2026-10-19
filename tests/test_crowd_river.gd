extends SceneTree

# Dia de Partit's crowd river (systems/crowd_river.gd): a packed-array sim.
# Fans stay out of the dog, your human and anything solid, a slack leash is
# stepped over, a taut leash across the flow shoves the pair north and one
# along the flow does not, the same seed walks the same way, and your human's
# pace stays inside the band that never stops their motor. The layer flushes
# one batch however many fans are in it.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _edges(_y: float) -> Vector2:
	return Vector2(80.0, 1200.0)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var R: GDScript = load("res://systems/crowd_river.gd")
	_sim(R)
	await _live()
	await _live_rain()
	print("test_crowd_river: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)


func _sim(R: GDScript) -> void:
	var edges := Callable(self, "_edges")

	# density: thin on the side street, full at the gates
	var river: CrowdRiver = R.new()
	river.setup(1, CrowdRiver.CAP)
	_check(river.density(-200.0) < 0.3, "thin on the side street")
	_check(river.density(-2000.0) > river.density(-200.0), "the avenue is denser")
	_check(river.density(-4200.0) > 0.99, "full at the gates")
	_check(river.target_at(-200.0) < 50, "few fans on the side street")
	_check(river.target_at(-4200.0) == CrowdRiver.CAP, "150 fans at the gates")

	# carry changes pace, and never enough to stop the walk
	var side: Vector2 = river.carry(-200.0, false)
	var ave: Vector2 = river.carry(-2000.0, false)
	var home: Vector2 = river.carry(-2000.0, true)
	_check(ave.y > side.y and ave.y <= 1.18, "a packed crowd quickens the walk out (%.2f)" % ave.y)
	_check(home.y >= 0.92 and home.y < 1.0, "against the crowd they still walk (%.2f)" % home.y)
	_check(absf(ave.x) > absf(side.x), "the drift is stronger where it is packed")

	# the same seed, the same walk
	var a: CrowdRiver = R.new()
	var b: CrowdRiver = R.new()
	a.setup(99, CrowdRiver.CAP)
	b.setup(99, CrowdRiver.CAP)
	for k in 180:
		var vy := -180.0 - float(k) * 1.4
		var dog := Vector2(600.0, vy)
		var hum := Vector2(660.0, vy + 80.0)
		a.step(1.0 / 60.0, vy, dog, hum, PackedVector2Array(), 0.0, [], edges)
		b.step(1.0 / 60.0, vy, dog, hum, PackedVector2Array(), 0.0, [], edges)
	_check(a.fingerprint() == b.fingerprint(), "a seed walks the same way twice")
	_check(a.active_count() > 0, "the river has people in it")

	# vendors walk south, fans walk north
	var flow: CrowdRiver = R.new()
	flow.setup(4, CrowdRiver.CAP)
	flow.step(0.016, -2000.0, Vector2(600, -2000), Vector2(660, -1920), PackedVector2Array(), 0.0, [], edges)
	var fan_i := 40
	var vendor_i := 0
	var fan_y := flow.py[fan_i]
	var vendor_y := flow.py[vendor_i]
	for k in 20:
		flow.step(0.05, -2000.0, Vector2(600, -2000), Vector2(660, -1920), PackedVector2Array(), 0.0, [], edges)
	_check(flow.kind[vendor_i] == 2, "a vendor is in the river")
	_check(flow.py[fan_i] < fan_y, "fans walk north")
	_check(flow.py[vendor_i] > vendor_y, "vendors walk back south")

	# nobody ends inside a solid, the dog, or your human
	var bodies: CrowdRiver = R.new()
	bodies.setup(5, 40)
	bodies.manage = false
	for i in 12:
		bodies.on[i] = 1
		bodies.px[i] = 500.0 + float(i) * 18.0
		bodies.py[i] = -2000.0
	# one planted on the dog, one inside a stall
	bodies.px[0] = 640.0
	bodies.py[0] = -2000.0
	bodies.px[1] = 540.0
	bodies.py[1] = -2010.0
	var stall := Rect2(500, -2050, 80, 80)
	var dog_p := Vector2(640, -2000)
	var human_p := Vector2(700, -2060)
	for k in 30:
		bodies.step(1.0 / 60.0, -2000.0, dog_p, human_p, PackedVector2Array(), 0.0, [stall], edges)
	for i in 12:
		if bodies.on[i] == 0:
			continue
		var p := Vector2(bodies.px[i], bodies.py[i])
		_check(not stall.grow(4.0).has_point(p), "fan %d is out of the stall" % i)
		_check(p.distance_to(dog_p) > 20.0, "fan %d is off the dog" % i)
		_check(p.distance_to(human_p) > 20.0, "fan %d is off your human" % i)

	# a slack leash is stepped over
	var slack: CrowdRiver = R.new()
	slack.setup(3, 16)
	slack.manage = false
	var rope := PackedVector2Array([Vector2(300, -2000), Vector2(900, -2000)])
	for i in 8:
		slack.on[i] = 1
		slack.kind[i] = 0
		slack.px[i] = 420.0 + float(i) * 40.0
		slack.py[i] = -2000.0
	slack.step(0.05, -2000.0, Vector2(300, -2000), Vector2(900, -2000), rope, 0.0, [], edges)
	var hopped := false
	var still_on := false
	for i in 8:
		if slack.hop[i] > 0.0:
			hopped = true
		if absf(slack.py[i] + 2000.0) < 8.0 and slack.px[i] > 320.0 and slack.px[i] < 880.0:
			still_on = true
	_check(hopped, "someone hops a slack leash")
	_check(not still_on, "nobody stays standing on a slack leash")

	# taut across the flow shoves north; taut along it does not
	var across: CrowdRiver = R.new()
	across.setup(8, 16)
	across.manage = false
	for i in 6:
		across.on[i] = 1
		across.kind[i] = 0
		across.px[i] = 460.0 + float(i) * 36.0
		across.py[i] = -2000.0
	var cross := PackedVector2Array([Vector2(300, -2000), Vector2(900, -2000)])
	var push: Vector2 = across.step(0.05, -2000.0, Vector2(300, -1990), Vector2(900, -2010), cross, 1.0, [], edges)
	_check(push.y < -10.0, "a taut leash across the flow drags north (%.1f)" % push.y)

	var along: CrowdRiver = R.new()
	along.setup(8, 16)
	along.manage = false
	for i in 6:
		along.on[i] = 1
		along.kind[i] = 0
		along.px[i] = 500.0
		along.py[i] = -2060.0 + float(i) * 20.0
	var with_flow := PackedVector2Array([Vector2(500, -1900), Vector2(500, -2140)])
	var none: Vector2 = along.step(0.05, -2000.0, Vector2(500, -1900), Vector2(508, -2140), with_flow, 1.0, [], edges)
	_check(absf(none.y) < 1.0, "a taut leash along the flow does not drag (%.1f)" % none.y)

	# the step stays cheap at 150
	var stress: CrowdRiver = R.new()
	stress.setup(11, CrowdRiver.CAP)
	var t0 := Time.get_ticks_usec()
	for k in 240:
		stress.step(1.0 / 60.0, -2200.0, Vector2(640, -2200), Vector2(680, -2120), PackedVector2Array(), 0.0, [], edges)
	var us := float(Time.get_ticks_usec() - t0) / 240.0
	print("crowd step %.0f us" % us)
	_check(us < 1500.0, "150 fans step in %.0f us" % us)

	# El Diluvi: both ways, under the cover, and nobody is carried
	var shop: CrowdRiver = R.new()
	shop.setup_shuffle(3, CrowdRiver.SHOPPERS)
	_check(shop.shuffle and shop.count == CrowdRiver.SHOPPERS, "the stroll is the short crowd")
	_check(is_equal_approx(shop.density(-200.0), 1.0) and is_equal_approx(shop.density(-4200.0), 1.0),
		"a shopping street does not thin out or pack in")
	var stroll: Vector2 = shop.carry(-2000.0, false)
	_check(is_equal_approx(stroll.x, 0.0) and is_equal_approx(stroll.y, 1.0),
		"shoppers do not carry your human")
	shop.step(0.016, -2200.0, Vector2(640, -2200), Vector2(680, -2120), PackedVector2Array(), 0.0, [], edges)
	# mid-window people, so the check is their walk and not a recycle at the edge
	var north_i := 14
	var south_i := 15
	var north_y: float = shop.py[north_i]
	var south_y: float = shop.py[south_i]
	for k in 40:
		shop.step(0.05, -2200.0, Vector2(640, -2200), Vector2(680, -2120), PackedVector2Array(), 0.0, [], edges)
	_check(shop.py[north_i] < north_y - 30.0, "even shoppers walk north")
	_check(shop.py[south_i] > south_y + 30.0, "odd shoppers walk south")
	var mid_n := 0
	var edge_n := 0
	for i in shop.count:
		if shop.on[i] == 0:
			continue
		if absf(shop.px[i] - 640.0) < 80.0:
			mid_n += 1
		else:
			edge_n += 1
	_check(edge_n > mid_n and edge_n > 0, "they keep to the cover (%d in the middle)" % mid_n)


func _live() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "partit"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	for k in range(20):
		await physics_frame
	_check(m.solid_rects.size() > 10, "the avenue has its stalls (%d)" % m.solid_rects.size())
	_check(m.match_crowd != null and m.match_crowd.count == CrowdRiver.CAP, "the walk runs 150 fans")
	_check(m.match_crowd_layer.z_index < m.leash.z_index, "the leash draws over the crowd")
	_check(m.match_crowd_layer.z_index < m.dog.z_index, "the pair draws over the crowd")
	_check(m.match_crowd.active_count() < 90, "the side street is not the avenue (%d)" % m.match_crowd.active_count())
	_check(m.human.crowd_pace >= m.human.CROWD_PACE_MIN and m.human.crowd_pace <= m.human.CROWD_PACE_MAX,
		"pace stays in the motor's band (%.2f)" % m.human.crowd_pace)
	var y0: float = m.human.global_position.y
	for k in range(150):
		await physics_frame
	_check(m.human.global_position.y < y0 - 120.0, "your human still reaches up the street")
	_check(m.human.walk_intent.length() > 70.0, "the motor is still a walk (%.0f)" % m.human.walk_intent.length())
	_clear_of(m)

	# the avenue, where the stress case lives
	m.dog.global_position = Vector2(640, -2080)
	m.human.global_position = Vector2(660, -2000)
	m.leash.resnap()
	for k in range(8):
		await physics_frame
	_check(m.match_crowd.active_count() > 100, "the avenue holds the crowd (%d)" % m.match_crowd.active_count())
	_clear_of(m)
	var before: int = m.match_crowd_layer.flush_count
	m.match_crowd_layer._draw()
	_check(m.match_crowd_layer.flush_count == before + 1, "one batch for the avenue")
	for i in m.match_crowd.count:
		if i % 2 == 0:
			m.match_crowd.on[i] = 0
	m.match_crowd_layer._draw()
	_check(m.match_crowd_layer.flush_count == before + 2, "one batch however many fans")
	m.free()
	await process_frame


func _live_rain() -> void:
	var game = root.get_node("Game")
	game.level_id = "rain"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	for k in range(30):
		await physics_frame
	var river: CrowdRiver = m.match_crowd
	_check(river != null and river.shuffle and river.count == CrowdRiver.SHOPPERS,
		"El Diluvi strolls both ways")
	_check(m.match_crowd_layer.z_index < m.leash.z_index, "shoppers draw under the leash")
	_check(m.match_canopy_layer != null and m.match_canopy_layer.z_index > m.dog.z_index,
		"umbrellas draw over the pair")
	var north := 0
	var south := 0
	var y_at: PackedFloat32Array = river.py.duplicate()
	for i in river.count:
		if river.kind[i] == 0:
			north += 1
		else:
			south += 1
	_check(north > 0 and south > 0, "both directions are out")
	for k in range(90):
		await physics_frame
	var moved_n := false
	var moved_s := false
	for i in river.count:
		if river.kind[i] == 0 and river.py[i] < y_at[i] - 8.0:
			moved_n = true
		if river.kind[i] != 0 and river.py[i] > y_at[i] + 8.0:
			moved_s = true
	_check(moved_n and moved_s, "the umbrellas are walking, not standing")
	_check(m.human.crowd_pace >= m.human.CROWD_PACE_MIN and m.human.crowd_pace <= m.human.CROWD_PACE_MAX,
		"the stroll leaves the motor alone (%.2f)" % m.human.crowd_pace)
	_clear_of(m)
	var bodies: int = m.match_crowd_layer.flush_count
	var lids: int = m.match_canopy_layer.flush_count
	m.match_crowd_layer._draw()
	m.match_canopy_layer._draw()
	_check(m.match_crowd_layer.flush_count == bodies + 1, "the coats are one batch")
	_check(m.match_canopy_layer.flush_count == lids + 1, "the umbrellas are one batch")
	m.free()


func _clear_of(m: Node2D) -> void:
	var river: CrowdRiver = m.match_crowd
	for i in river.count:
		if river.on[i] == 0:
			continue
		var p := Vector2(river.px[i], river.py[i])
		if p.distance_to(m.dog.global_position) < 18.0:
			_check(false, "fan %d is inside the dog" % i)
			return
		if p.distance_to(m.human.global_position) < 18.0:
			_check(false, "fan %d is inside your human" % i)
			return
		for r: Rect2 in m.solid_rects:
			if r.grow(4.0).has_point(p):
				_check(false, "fan %d is inside %s" % [i, str(r)])
				return
	_check(true, "the crowd stands clear of the pair and the stalls")
