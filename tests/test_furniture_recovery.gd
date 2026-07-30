extends SceneTree

# Round 2 geometry / furniture recovery. Production-layout regressions for the
# Boulevard terrace soft-lock, FUR-GONETA alignment, beach shoreline agreement,
# capped stick-slip, typed rope obstacles, and freedomlayer decay invalidation.
#
#   godot --headless --path . --script res://tests/test_furniture_recovery.gd

const DT := 1.0 / 60.0
const FURNITURE_MIN_SEP := 28.0
const STRETCH_CAP := 1.15

# Boulevard terrace coordinates from the soft-lock screenshot layout
# (authored Street cafe cluster; Street half-width keeps these values).
const TERRACE_TABLES: Array[Vector2] = [
	Vector2(760, -3560), Vector2(840, -3660), Vector2(700, -3700), Vector2(790, -3780),
]
const TERRACE_PARASOLS: Array[Vector2] = [
	Vector2(800, -3610), Vector2(745, -3740),
]

var failures := 0
var _level: Node2D = null


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _settle(leash: Node2D, frames: int) -> void:
	for _i in range(frames):
		leash.tick(DT)


func _make_leash(dog: Node2D, human: Node2D, poles: Array, rest: float) -> Node2D:
	var leash := Node2D.new()
	leash.set_script(load("res://leash.gd"))
	root.add_child(dog)
	root.add_child(human)
	root.add_child(leash)
	leash.setup(dog, human, poles, rest)
	return leash


func _free_node(n: Node) -> void:
	if n == null:
		return
	if n.get_parent() != null:
		n.get_parent().remove_child(n)
	n.free()


func _test_slip_constants_and_curves() -> void:
	var LeashScript = load("res://leash.gd")
	var probe := Node2D.new()
	probe.set_script(LeashScript)
	_check(probe.get("STATIC_SLIP_MIN") != null, "leash exposes STATIC_SLIP_MIN")
	_check(probe.get("FURNITURE_SLIP_MIN") != null, "leash exposes FURNITURE_SLIP_MIN")
	_check(probe.get("DYNAMIC_SLIP_MIN") != null, "leash exposes DYNAMIC_SLIP_MIN")
	_check(probe.get("STRETCH_CAP") != null, "leash exposes STRETCH_CAP")
	if probe.get("STRETCH_CAP") != null:
		_check(is_equal_approx(float(probe.STRETCH_CAP), STRETCH_CAP),
			"STRETCH_CAP matches the geometry hard cap (%.2f)" % STRETCH_CAP)
	_check(probe.has_method("slip_for"), "leash exposes slip_for(stretch, kind)")
	if probe.has_method("slip_for"):
		var static_at_cap: float = probe.slip_for(STRETCH_CAP, "furniture")
		_check(static_at_cap >= 0.95,
			"static/furniture slip approaches free at %.2fx (got %.2f)" % [STRETCH_CAP, static_at_cap])
		var pole_grip: float = probe.slip_for(1.0, "pole")
		_check(pole_grip <= 0.25,
			"intentional wraps still grip near rest length (slip %.2f)" % pole_grip)
		var furn_rest: float = probe.slip_for(1.0, "furniture")
		_check(furn_rest >= pole_grip,
			"furniture grips looser than poles at rest (%.2f vs %.2f)" % [furn_rest, pole_grip])
		var dyn_at_cap: float = probe.slip_for(STRETCH_CAP, "dynamic")
		_check(dyn_at_cap >= 0.95,
			"dynamic slip approaches free at %.2fx (got %.2f)" % [STRETCH_CAP, dyn_at_cap])
		_check(probe.slip_for(1.05, "dynamic") >= probe.slip_for(1.05, "pole"),
			"dynamic contacts slip at least as freely as poles at modest stretch")
		_check(probe.slip_for(1.05, "furniture") >= probe.slip_for(1.05, "pole"),
			"furniture contacts slip at least as freely as poles at modest stretch")
		# Poles are deliberately NOT on the furniture ramp. Pole grip is what
		# holds a wrap for the vault, what accumulates winding, and what
		# decides whether the fling gets right of way, so the soft-lock fix
		# stays scoped to the thing that was locking. If someone puts poles
		# back on the steep ramp, this fails.
		var pole_mid: float = probe.slip_for(1.10, "pole")
		_check(pole_mid <= 0.35,
			"a pole wrap still grips at 10%% stretch (slip %.2f)" % pole_mid)
		var furn_mid: float = probe.slip_for(1.10, "furniture")
		_check(furn_mid >= pole_mid + 0.25,
			"furniture frees far sooner than a pole at 10%% stretch (%.2f vs %.2f)"
				% [furn_mid, pole_mid])
		_check(probe.slip_for(STRETCH_CAP, "pole") < 0.5,
			"poles never reach free slip from tension alone - free_slip_t does that")

		# The solver runs ITER * (N-1) * near-obstacle times per rope per
		# frame. Typed scratch arrays are the reason that is affordable; a
		# dictionary per obstacle per frame was not.
		_check(probe.get("pole_kinds") is PackedInt32Array,
			"pole kinds are cached as packed ints, not resolved per frame")
		_check(not probe.has_method("_kind_at"),
			"pole kind is not recovered by a per-frame distance scan")
	_check(probe.get("KIND_POLE") != null, "leash exposes KIND_POLE")
	_check(probe.get("KIND_FURNITURE") != null, "leash exposes KIND_FURNITURE")
	_check(probe.get("KIND_DYNAMIC") != null, "leash exposes KIND_DYNAMIC")
	_free_node(probe)


func _test_typed_contact_metadata() -> void:
	var dog := Node2D.new()
	var human := Node2D.new()
	dog.global_position = Vector2(40, 0)
	human.global_position = Vector2(-40, 0)
	var pole := Vector2.ZERO
	var poles: Array[Vector2] = [pole]
	var leash := _make_leash(dog, human, poles, 100.0)
	_check("furniture_poles" in leash or leash.get("furniture_poles") != null,
		"leash exposes furniture_poles metadata")
	if leash.get("furniture_poles") != null:
		var furn: Array[Vector2] = [pole]
		leash.furniture_poles = furn
	# wrap the furniture contact
	dog.global_position = Vector2(30, 0)
	_settle(leash, 30)
	for i in range(90):
		var a := float(i) / 90.0 * TAU
		dog.global_position = Vector2(26, 0).rotated(a)
		leash.tick(DT)
	_settle(leash, 30)
	_check(leash.contacts > 0, "furniture wrap produces contacts")
	_check(leash.get("contact_static") == true, "furniture contact is marked static")
	_check(str(leash.get("contact_kind")) == "furniture",
		"furniture contact kind is furniture (got %s)" % str(leash.get("contact_kind")))

	# dynamic-only snag must not claim pole-only contact_pole semantics.
	# Offset the obstacle and wind so contact is forced (a centre-line
	# drape can miss POLE_PAD's l > 0.001 guard and silently pass).
	var empty: Array[Vector2] = []
	leash.poles = empty
	if leash.get("furniture_poles") != null:
		leash.furniture_poles = empty
	var dyn_pos := Vector2(0, 8)
	var dyn: Array[Vector2] = [dyn_pos]
	leash.dynamic_obstacles = dyn
	human.global_position = Vector2(-40, 0)
	dog.global_position = Vector2(40, 0)
	leash.resnap()
	_settle(leash, 20)
	for i in range(120):
		var a := float(i) / 120.0 * TAU
		dog.global_position = dyn_pos + Vector2(28, 0).rotated(a)
		leash.tick(DT)
	_settle(leash, 30)
	_check(leash.contacts > 0, "dynamic snag produces contacts before metadata checks")
	_check(leash.get("contact_static") == false, "dynamic contact is not static")
	_check(
		leash.contact_pole.x >= INF,
		"dynamic contact does not populate pole-only contact_pole"
	)
	_free_node(leash)
	_free_node(dog)
	_free_node(human)


func _add_static_pole_body(at: Vector2, radius: float) -> StaticBody2D:
	var sb := StaticBody2D.new()
	sb.collision_layer = 1
	sb.position = at
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = radius
	cs.shape = sh
	sb.add_child(cs)
	root.add_child(sb)
	return sb


func _make_endpoint_body(pos: Vector2, radius: float) -> CharacterBody2D:
	var body := CharacterBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 1
	body.global_position = pos
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = radius
	cs.shape = sh
	body.add_child(cs)
	return body


func _test_collision_enabled_endpoint_recovery() -> void:
	# CharacterBody2D ends + StaticBody2D furniture. Headless script runners
	# do not reliably resolve CharacterBody2D.test_move against StaticBody2D
	# (direct space queries work; body motion does not), so collision is
	# enforced with the same circle radii the StaticBody uses. Motion is
	# still collision-constrained - never a teleport through the body -
	# and the escape-side settle must free the wrap inside the stretch cap.
	const POLE_R := 10.0
	const DOG_R := 14.0
	const HUMAN_R := 12.0
	var parasol := TERRACE_PARASOLS[0]
	var min_clear := POLE_R + DOG_R
	var statics: Array = [_add_static_pole_body(parasol, POLE_R)]
	var human := _make_endpoint_body(parasol + Vector2(-80, 0), HUMAN_R)
	var dog := _make_endpoint_body(parasol + Vector2(120, 0), DOG_R)
	var poles: Array[Vector2] = [parasol]
	var leash := _make_leash(dog, human, poles, 260.0)
	if leash.get("furniture_poles") != null:
		leash.furniture_poles = poles
	await process_frame
	await physics_frame
	# space query proves the StaticBody is in the physics world
	var space := dog.get_world_2d().direct_space_state
	var pq := PhysicsPointQueryParameters2D.new()
	pq.position = parasol
	pq.collision_mask = 1
	_check(space.intersect_point(pq, 4).size() > 0,
		"furniture StaticBody2D is registered in the physics space")
	_settle(leash, 40)
	for i in range(720):
		var t := float(i) / 720.0
		var r := lerpf(120.0, 30.0, t)
		var a := deg_to_rad(720.0 * t)
		dog.global_position = parasol + Vector2(r, 0).rotated(a)
		leash.tick(DT)
	_settle(leash, 30)
	dog.global_position = parasol + Vector2(0, 90)
	_settle(leash, 60)
	_check(leash.contacts >= 2,
		"collision fixture coils before recovery (%d contacts)" % leash.contacts)
	var waypoints: Array[Vector2] = [
		parasol + Vector2(min_clear + 40, 90),
		parasol + Vector2(min_clear + 80, 20),
		parasol + Vector2(min_clear + 80, -90),
		parasol + Vector2(-40, -min_clear - 80),
		parasol + Vector2(-200, -20),
		parasol + Vector2(-430, 320),
	]
	var penetrated := false
	# a constructed tunnel step would penetrate, and the walker refuses it
	var toward := parasol - dog.global_position
	var into := toward.normalized() * (toward.length() - min_clear + 8.0)
	_check((dog.global_position + into).distance_to(parasol) < min_clear,
		"constructed tunnel step would penetrate the furniture body")
	var refused_step := into
	if (dog.global_position + refused_step).distance_to(parasol) < min_clear:
		refused_step = Vector2.ZERO
	_check(refused_step == Vector2.ZERO,
		"collision-safe walker refuses a penetrating step")
	for wp in waypoints:
		for _i in range(300):
			var to_wp := wp - dog.global_position
			if to_wp.length() < 12.0:
				break
			var step := to_wp.limit_length(8.0)
			if (dog.global_position + step).distance_to(parasol) < min_clear:
				var perp := step.orthogonal().normalized() * 8.0
				if (dog.global_position + perp).distance_to(parasol) >= min_clear:
					step = perp
				elif (dog.global_position - perp).distance_to(parasol) >= min_clear:
					step = -perp
				else:
					step = Vector2.ZERO
			dog.global_position += step
			dog.velocity = step / DT
			dog.move_and_slide() # exercised even when headless body-motion is inert
			if dog.global_position.distance_to(parasol) < min_clear - 0.5:
				penetrated = true
		# tick the rope after each waypoint, not every substep, so walking
		# around does not add extra coils the teleport recovery never sees
		leash.tick(DT)
		_settle(leash, 8)
	_settle(leash, 1200)
	var used: float = leash.used_length()
	var chord := human.global_position.distance_to(dog.global_position)
	print("collision recovery: used %.0f chord %.0f contacts %d dog=%s" % [
		used, chord, leash.contacts, str(dog.global_position)])
	_check(not penetrated, "dog body never tunnels furniture colliders during recovery")
	_check(used < chord * STRETCH_CAP,
		"collision-constrained pull frees furniture wrap inside %.2fx (used %.0f chord %.0f)" % [
			STRETCH_CAP, used, chord])
	_check(dog.global_position.distance_to(parasol + Vector2(-430, 320)) < 40.0,
		"collision-safe walk reached the escape side without tunneling")
	_free_node(leash)
	_free_node(dog)
	_free_node(human)
	for sb in statics:
		_free_node(sb)


func _test_capped_slip_furniture_recovery() -> void:
	# Same hard-pull geometry as test_wrap, centred on a terrace parasol so
	# furniture-kind slip must free inside the stretch cap.
	var dog := Node2D.new()
	var human := Node2D.new()
	var chair := Vector2(800, -3595)
	var parasol := Vector2(800, -3610)
	var poles: Array[Vector2] = [parasol]
	human.global_position = parasol + Vector2(-80, 0)
	dog.global_position = parasol + Vector2(120, 0)
	var leash := _make_leash(dog, human, poles, 260.0)
	if leash.get("furniture_poles") != null:
		leash.furniture_poles = poles
	_settle(leash, 40)
	for i in range(720):
		var t := float(i) / 720.0
		var r := lerpf(120.0, 26.0, t)
		var a := deg_to_rad(720.0 * t)
		dog.global_position = parasol + Vector2(r, 0).rotated(a)
		leash.tick(DT)
	_settle(leash, 30)
	dog.global_position = parasol + Vector2(0, 90)
	_settle(leash, 120)
	_check(leash.contacts >= 3, "furniture coil grips before the recovery pull")
	# hard pull to the human's side - a stuck wrap would hairpin and read long
	dog.global_position = parasol + Vector2(-430, 320)
	_settle(leash, 1200)
	var used: float = leash.used_length()
	var chord := human.global_position.distance_to(dog.global_position)
	print("furniture recovery: used %.0f chord %.0f contacts %d winding %.2f" % [
		used, chord, leash.contacts, leash.winding()])
	_check(used < chord * STRETCH_CAP,
		"sustained furniture tension frees inside %.2fx (used %.0f chord %.0f)" % [
			STRETCH_CAP, used, chord])
	_check(chair.distance_to(parasol) < FURNITURE_MIN_SEP,
		"regression fixture still names the historically nested chair/parasol pair")
	_free_node(leash)
	_free_node(dog)
	_free_node(human)


func _test_single_pole_still_winds() -> void:
	var dog := Node2D.new()
	var human := Node2D.new()
	dog.global_position = Vector2(120, 0)
	human.global_position = Vector2(-80, 0)
	var poles: Array[Vector2] = [Vector2.ZERO]
	var leash := _make_leash(dog, human, poles, 260.0)
	_settle(leash, 40)
	for i in range(720):
		var t := float(i) / 720.0
		var r := lerpf(120.0, 26.0, t)
		var a := deg_to_rad(720.0 * t)
		dog.global_position = Vector2(r, 0).rotated(a)
		leash.tick(DT)
	_settle(leash, 30)
	dog.global_position = Vector2(0, 90)
	_settle(leash, 120)
	_check(leash.contacts >= 3, "single-pole taut coil still grips (%d contacts)" % leash.contacts)
	_check(absf(leash.winding()) > 0.8, "single-pole winding survives slip retune (%.2f)" % leash.winding())
	_free_node(leash)
	_free_node(dog)
	_free_node(human)


func _test_ball_throw_window_before_first_throw() -> void:
	var src := FileAccess.get_file_as_string("res://ball.gd")
	_check(src.contains("throw_x_lo") and src.contains("throw_x_hi"),
		"ball.setup accepts throw_x_lo/throw_x_hi window args")
	var setup_i := src.find("func setup(")
	var throw_i := src.find("_throw()", setup_i)
	var lo_i := src.find("x_lo", setup_i)
	_check(setup_i >= 0 and throw_i > setup_i and lo_i > setup_i and lo_i < throw_i,
		"throw window is assigned before the first _throw() in setup")
	var main_src := FileAccess.get_file_as_string("res://main.gd")
	var enter_i := main_src.find("func _enter_freedom")
	var beach_setup := main_src.find("ball.setup(self, dog, human, freedom_lo, GATE_Y - 30.0, -90.0", enter_i)
	_check(beach_setup > enter_i,
		"beach throw window is applied before the first ball.setup throw")


func _mute_sfx() -> void:
	var sfx = root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.muted = true
		sfx.music_on = false
		if sfx.music_player != null:
			sfx.music_player.stop()


func _load_level(level_id: String) -> Node2D:
	if _level != null:
		_free_node(_level)
		_level = null
	var game = root.get_node("Game")
	game.level_id = level_id
	game.daily = false
	game.weather = "clear"
	game.night = false
	game.menu_step = 2
	_mute_sfx()
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready
	main.frozen = true
	_level = main
	print("loaded level_id=%s lvl=%s tables=%d chairs=%d furgoneta=%.0f" % [
		level_id, main.lvl, main.tables.size(), main.chairs.size(), main.furgoneta.x])
	return main


func _test_furgoneta_alignment() -> void:
	var main: Node2D = await _load_level("market")
	_check(main.lvl == "market", "market level id sticks (got %s)" % main.lvl)
	_check(main.furgoneta.x < INF, "market places the FUR-GONETA")
	var body: Vector2 = main.furgoneta
	var flank_xs: Array[float] = []
	for p: Vector2 in main.poles:
		if absf(p.y - body.y) <= 52.5 and absf(p.x - body.x) < 1.0:
			flank_xs.append(p.x)
	_check(flank_xs.size() >= 5,
		"FUR-GONETA has five rope-contact flanks at the body (found %d)" % flank_xs.size())
	for fx in flank_xs:
		_check(is_equal_approx(fx, body.x),
			"rope flank x=%.1f matches fitted body x=%.1f" % [fx, body.x])
	var found_blocker := false
	for b in main.bypasser_blockers:
		if String(b.get("id", "")) == "furgoneta":
			found_blocker = true
			var rect: Rect2 = b.rect
			_check(rect.get_center().distance_to(body) < 0.5,
				"bypasser blocker centre matches fitted FUR-GONETA")
	_check(found_blocker, "FUR-GONETA registers a bypasser blocker")
	# scent list must use the same fitted centre as draw/blocker/rope flanks
	var scent_hit := false
	for src in main._build_scent_sources():
		if src.get("pos", Vector2(INF, INF)).distance_to(body) < 0.5:
			scent_hit = true
			break
	_check(scent_hit, "scent source position matches fitted FUR-GONETA centre")
	_check(not main.furgoneta_sniffed, "market FUR-GONETA starts unsniffed")


func _test_terrace_separation() -> void:
	var main: Node2D = await _load_level("street")
	var cluster: Array[Vector2] = []
	for t: Vector2 in main.tables:
		cluster.append(t)
	for c: Vector2 in main.chairs:
		cluster.append(c)
	for p: Vector2 in main.parasols:
		cluster.append(p)
	var near_shot := 0
	var shot: Array[Vector2] = []
	shot.append_array(TERRACE_TABLES)
	shot.append_array(TERRACE_PARASOLS)
	for p2 in cluster:
		for s in shot:
			if p2.distance_to(s) < 120.0:
				near_shot += 1
				break
	_check(near_shot >= 4, "street still authors the Boulevard terrace cluster")
	var min_sep := 1e9
	var worst := ""
	for i in range(cluster.size()):
		for j in range(i + 1, cluster.size()):
			var d: float = cluster[i].distance_to(cluster[j])
			if d < min_sep:
				min_sep = d
				worst = "%.0f,%.0f vs %.0f,%.0f" % [
					cluster[i].x, cluster[i].y, cluster[j].x, cluster[j].y]
	print("terrace min separation: %.1f (%s)" % [min_sep, worst])
	_check(min_sep + 0.01 >= FURNITURE_MIN_SEP,
		"authored terrace furniture clears %.0fpx body/wrap separation (got %.1f at %s)" % [
			FURNITURE_MIN_SEP, min_sep, worst])
	for ch: Vector2 in main.chairs:
		for pa: Vector2 in main.parasols:
			_check(ch.distance_to(pa) + 0.01 >= FURNITURE_MIN_SEP,
				"chair at %s clears parasol at %s (%.1f)" % [str(ch), str(pa), ch.distance_to(pa)])


func _test_beach_shoreline_agreement() -> void:
	var main: Node2D = await _load_level("beach")
	_check(main.has_method("beach_shore_x"), "main exposes beach_shore_x(y)")
	if not main.has_method("beach_shore_x"):
		return
	var bend_y: float = main.GATE_Y - 300.0
	var gate_y: float = main.GATE_Y - 30.0
	var north: float = main.beach_shore_x(bend_y - 50.0)
	var mid: float = main.beach_shore_x((bend_y + gate_y) * 0.5)
	var south: float = main.beach_shore_x(gate_y)
	_check(is_equal_approx(north, main.BEACH_SEA_R),
		"north shore is BEACH_SEA_R (got %.1f)" % north)
	_check(is_equal_approx(south, 230.0), "gate shore is 230 (got %.1f)" % south)
	_check(mid < north and mid > south, "transition shore is between the ends")
	var probe := Vector2(mid - 8.0, (bend_y + gate_y) * 0.5)
	var wet := false
	for w: Rect2 in main.water:
		if w.has_point(probe):
			wet = true
	_check(wet, "gameplay water covers the diagonal transition shore")
	var dry_probe := Vector2(mid + 20.0, (bend_y + gate_y) * 0.5)
	var dry := true
	for w2: Rect2 in main.water:
		if w2.grow(-2.0).has_point(dry_probe):
			dry = false
	_check(dry, "sand just east of the shore stays dry")


func _test_freedomlayer_decay_dirty() -> void:
	var main: Node2D = await _load_level("park")
	main.phase = "freedom"
	var props: Array[Dictionary] = [
		{"pos": Vector2(200, -5200), "kind": "dig", "done": false, "prog": 0.55},
		{"pos": Vector2(400, -5200), "kind": "post", "done": false, "prog": 0.4},
	]
	main.park_props = props
	main.dog.global_position = Vector2(900, -4000)
	main.dog.velocity = Vector2(200, 0)
	if main.freedomlayer != null:
		main.freedomlayer.dirty = false
	main._pickups(0.1)
	_check(main.freedomlayer != null and main.freedomlayer.dirty,
		"abandoned interaction progress decay dirties freedomlayer")


func _run() -> void:
	_test_slip_constants_and_curves()
	_test_typed_contact_metadata()
	await _test_collision_enabled_endpoint_recovery()
	_test_capped_slip_furniture_recovery()
	_test_single_pole_still_winds()
	_test_ball_throw_window_before_first_throw()
	await _test_furgoneta_alignment()
	await _test_terrace_separation()
	await _test_beach_shoreline_agreement()
	await _test_freedomlayer_decay_dirty()

	if _level != null:
		_free_node(_level)
		_level = null

	if failures > 0:
		print("test_furniture_recovery: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_furniture_recovery: OK")
		quit(0)


func _initialize() -> void:
	call_deferred("_run")
