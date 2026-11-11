extends SceneTree

const DT := 1.0 / 60.0
var checks := 0
var failures: Array[String] = []

func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)

func _initialize() -> void:
	call_deferred("_run")

func _ticks(m: Node2D, secs: float) -> void:
	var n := int(secs / DT)
	for i in range(n):
		m.elapsed += DT
		m.drac.tick_state(DT)

func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "guell"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	m.set_physics_process(false)
	m.set_process(false)
	var BD: GDScript = load("res://systems/boss_drac.gd")
	var G: GDScript = load("res://systems/goals.gd")
	_check(m.drac != null, "El Drac is built")
	_check(m.drac.state == BD.State.IDLE, "asleep on the fountain")
	_check(m.drac.leg_indices.size() == 4, "four legs on the rope")
	var ids: Array = G.LEVEL_GOAL_IDS["guell"]
	_check(ids.size() == 15, "15 goals: %d" % ids.size())
	_check(ids.has("drac_dodge") and ids.has("drac_column") and ids.has("drac_trip"), "boss goals listed")
	_check(not ids.has("drink") and not ids.has("hi") and not ids.has("tofu"), "drink/hi/tofu removed")
	var defs: Dictionary = G.defs(m)
	for id: String in ids:
		_check(defs.has(id), "goal %s is defined" % id)
	var problems: Array = load("res://world/level_check.gd").check(m)
	_check(problems.is_empty(), "level check clean: %s" % str(problems))

	var dr = m.drac
	m.human.global_position = Vector2(640.0, BD.HOLD_Y - 400.0)
	m.dog.global_position = Vector2(640.0, BD.HOLD_Y - 500.0)
	_ticks(m, 0.5)
	_check(dr.state == BD.State.IDLE, "still asleep with the pair past him")

	m.human.global_position = Vector2(640.0, BD.HOLD_Y + 120.0)
	m.dog.global_position = Vector2(640.0, BD.WAKE_Y - 30.0)
	_ticks(m, 0.1)
	_check(dr.state == BD.State.AWAKEN, "wakes as she passes")
	_check(m.human.tut_hold_y == BD.HOLD_Y, "your human is held short of him")
	_check(dr.awake_for_draw(), "boss owns the salamander draw")
	_ticks(m, BD.AWAKEN_TIME + 0.1)
	_check(dr.state == BD.State.PROWL, "down off the fountain and prowling")

	# force PROWL after wake
	dr.face_dir = Vector2.DOWN
	dr.tail_cd = 0.0
	dr.jet_cd = 99.0
	var hits0: int = m.dog_hits
	m.dog.global_position = dr.pos + Vector2(0.0, -140.0)  # behind him
	m.dog.tumble_t = 0.0
	dr.card_t = BD.CARD_TIME + BD.CARD_FROM + 0.1
	_ticks(m, DT * 2.0)
	_check(dr.state == BD.State.TAIL_WHIP, "she is behind him: he whips")
	_ticks(m, BD.TAIL_WARN + 0.05)
	_check(m.dog_hits == hits0 + 1, "the whip knocks her in its rear cone")
	_ticks(m, BD.TAIL_STRIKE + 0.1)
	_check(dr.state == BD.State.PROWL, "and he prowls on")

	dr.face_dir = Vector2.DOWN
	dr.tail_cd = 0.0
	m.dog.tumble_t = 0.0
	var hp0: float = dr.hp
	m.dog.global_position = dr.pos + Vector2(0.0, -150.0)
	_ticks(m, DT * 2.0)
	_check(dr.state == BD.State.TAIL_WHIP, "a second whip")
	m.dog.global_position = dr.pos + Vector2(260.0, 0.0)
	_ticks(m, BD.TAIL_WARN + 0.05)
	_check(m.drac_dodges == 1 and dr.hp < hp0, "a dodged whip wears him down")

	dr.transition_to(BD.State.PROWL)
	dr.tail_cd = 99.0
	dr.jet_cd = 0.0
	dr.face_dir = Vector2.DOWN
	m.dog.global_position = dr.pos + Vector2(0.0, 180.0)
	m.human.global_position = dr.pos + Vector2(40.0, 200.0)
	var dog0: Vector2 = m.dog.global_position
	_ticks(m, DT * 2.0)
	_check(dr.state == BD.State.JET, "he lines up a jet")
	_ticks(m, BD.JET_WARN + 0.05)
	_check(m.dog.global_position.distance_to(dog0) > 8.0, "the jet pushes her")
	_check(dr.surface_at(dog0) == load("res://world/surfaces.gd").S.WATER, "soak puddle left behind")

	# part two: furious below half, slither, column bind, leash trip
	var LevelBuild: GDScript = load("res://world/level_build.gd")
	var Surfaces: GDScript = load("res://world/surfaces.gd")
	_ticks(m, BD.JET_TIME + 0.1)
	_check(dr.state == BD.State.PROWL, "jet done, he prowls")
	dr.damage(dr.hp - 45.0)
	_check(dr.phase == 2, "below half he is in part two")
	_ticks(m, DT)
	_check(dr.state == BD.State.ENRAGE, "he enrages first")
	_ticks(m, BD.ENRAGE_TIME + 0.1)
	_check(dr.state == BD.State.PROWL and dr.enraged, "then prowls, furious")

	dr.pos = Vector2(640.0, -1960.0)
	dr.face_dir = Vector2.RIGHT
	dr.slither_cd = 0.0
	dr.tail_cd = 99.0
	dr.jet_cd = 99.0
	m.dog.global_position = Vector2(640.0, -1900.0)
	m.human.global_position = Vector2(640.0, -1800.0)
	var col: Vector2 = Vector2(LevelBuild.MOSAIC_HALL_COLS[3], LevelBuild.MOSAIC_HALL_ROWS[3])
	_ticks(m, DT * 2.0)
	_check(dr.state == BD.State.SLITHER, "he slithers through the hall")
	_check(dr.status() == "WIND HIM ROUND A COLUMN", "slither banner")
	# taut mid-segment across him, rope already on a hall Doric column
	_lay_rope(m, Vector2(500.0, -1960.0), Vector2(780.0, -1960.0))
	_mark_touch(m, col)
	_check(dr.check_column_bind(), "column bind reads the wrapped taut leash")
	_ticks(m, DT)
	_check(m.drac_wound and dr.state == BD.State.STUNNED, "wound round a column")
	var shed_mud := false
	for z: Dictionary in dr.surface_zones:
		if int(z.get("kind", -1)) == Surfaces.S.MUD:
			shed_mud = true
			break
	_check(shed_mud, "slither sheds mud chips")

	dr.transition_to(BD.State.PROWL)
	dr.phase = 2
	dr.enraged = true
	dr.slither_cd = 0.0
	dr.tail_cd = 99.0
	dr.jet_cd = 99.0
	dr.pos = Vector2(640.0, -1960.0)
	m.drac_tripped = false
	# taut across his path, no column wrap required
	_lay_rope(m, Vector2(500.0, -1960.0), Vector2(780.0, -1960.0))
	_clear_touch(m)
	_check(dr.check_trip(), "a taut mid-segment is a trip")
	_check(not dr.check_column_bind(), "trip needs no column")
	_ticks(m, DT * 3.0)
	_check(m.drac_tripped, "tripped with the leash")

	print("test_drac: %d checks, %d failures" % [checks, failures.size()])
	for f in failures:
		print("  " + f)
	quit(1 if failures.size() > 0 else 0)


func _lay_rope(m: Node2D, a: Vector2, b: Vector2) -> void:
	var n: int = m.leash.pts.size()
	for i in range(n):
		var p: Vector2 = a.lerp(b, float(i) / float(n - 1))
		m.leash.pts[i] = p
		if i < m.leash.prev.size():
			m.leash.prev[i] = p
	m.leash.rest_len = a.distance_to(b) * 0.8


func _mark_touch(m: Node2D, col: Vector2) -> void:
	var n: int = m.leash.pts.size()
	m.leash._obs_pos = PackedVector2Array([col])
	m.leash._touch.resize(n)
	for i in range(n):
		m.leash._touch[i] = -1
	m.leash._touch[n / 2] = 0


func _clear_touch(m: Node2D) -> void:
	var n: int = m.leash.pts.size()
	m.leash._obs_pos = PackedVector2Array()
	m.leash._touch.resize(n)
	for i in range(n):
		m.leash._touch[i] = -1
