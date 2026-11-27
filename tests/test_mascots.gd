extends SceneTree

# Les Atraccions' chase (entities/mascot_threat.gd, systems/home_chase.gd):
# - the profile, its film, two respites each with a jam placed, the gates of
#   the walks after it
# - the flop is telegraphed FLOP_WARN in a lane that does not move, knocks
#   whoever is in it, pays whoever stepped out of it, and catches nobody; the
#   mascot is left down and the line gets on without it
# - the line catches with its bodies; a flop aimed out of reach is not thrown
# - the counters are in the checkpoint

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


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "atraccions"
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
	m.auto_walk = false
	var T: GDScript = load("res://entities/mascot_threat.gd")
	var HC: GDScript = load("res://systems/home_chase.gd")
	var A: GDScript = load("res://systems/atraccions.gd")
	var G: GDScript = load("res://systems/goals.gd")
	var CC: GDScript = load("res://systems/chase_checkpoint.gd")

	# 1. registration
	_check(game.CHASE_WALKS.has("atraccions") and game.CHASE_WALKS.size() == 10, "the tenth chase (%d)" % game.CHASE_WALKS.size())
	for i in [5, 10, 16, 21, 27, 32, 38, 43, 49, 54]:
		_check(game.CHASE_WALKS.has(game.CAROUSEL[i]), "walk %d, %s, is a chase" % [i, game.CAROUSEL[i]])
	for w in ["girona", "site", "ronda", "santacoloma", "partit", "montserrat"]:
		_check(String(game.CHASE_GATE[w]) == "atraccions", "%s opens after it" % w)
	var prof: Dictionary = HC.profile_for("atraccions")
	_check(String(prof.kind) == "mascots" and ResourceLoader.exists(String(prof.film)) and ResourceLoader.exists(String(prof.script)), "its profile, script and film")
	_check(m.chase_jams.size() == prof.bands.size(), "a jam for every respite")
	for i in range(prof.bands.size()):
		_check(absf(A.CHASE_JAMS[i].y - float(prof.bands[i].jam_y)) < 1.0 and bool(prof.bands[i].checkpoint), "respite %d is at its jam, and a save" % i)
	_check(absf(T.QUEUE_JAM_Y - A.CHASE_JAMS[1].y) < 1.0, "the queue they stop for is the queue's jam")
	_check(m.chase_active and String(m.chase_kind) == "mascots", "the walk rolled its chase")
	for g in ["flop_dodge", "mascot_clean"]:
		_check((G.LEVEL_GOAL_IDS["atraccions"] as Array).has(g) and G.defs(m).has(g), "the %s goal" % g)
	_check((G.LEVEL_GOAL_IDS["atraccions"] as Array).size() == 15, "15 goals")
	_check(CC.MAIN_FIELDS.has("atraccions_flop_dodges") and CC.MAIN_FIELDS.has("atraccions_flop_hits"), "the checkpoint keeps its counters")

	# 2. the flop, on a dog who stays and on one who steps out
	_check(T.FLOP_WARN >= 0.8, "telegraphed %.2f s" % T.FLOP_WARN)
	for dodge: bool in [false, true]:
		var t: Node2D = T.new()
		root.add_child(t)
		t.setup(m, -2400.0, m.walk_cx, m.walk_half, 134.0)
		m.human.global_position = Vector2(820.0, -1700.0)
		m.dog.tumble_t = 0.0
		m.dog.velocity = Vector2.ZERO
		m.dog.global_position = Vector2(640.0, -2150.0)
		t.flop_count = 0
		t.flop_t = 0.0
		t.advance(DT, 200.0, 0.0)
		_check(not t.flop.is_empty() and not bool(t.flop.slid), "a lane fills on her")
		if t.flop.is_empty():
			break
		_check(t.flop_warning(), "and the banner says so")
		var from: Vector2 = t.flop.from
		var who: int = t.flop.i
		var hits: int = m.atraccions_flop_hits
		var dodges: int = m.atraccions_flop_dodges
		var knocks: int = m.dog_hits
		for i in range(int((T.FLOP_WARN - 0.1) / DT)):
			t.advance(DT, 200.0, 0.0)
		_check(t.flop.from == from and m.dog_hits == knocks, "the lane stays put and nothing lands before it has filled")
		if dodge:
			m.dog.global_position.x += 95.0
		var caught := false
		var start: Vector2 = t.squad.members[who].pos
		for i in range(int((0.1 + T.FLOP_SLIDE + 0.15) / DT)):
			t.advance(DT, 200.0, 0.0)
			if t.flopped() == who and t.caught(t.squad.members[who].pos + Vector2(0.0, 10.0)):
				caught = true
		var slid: float = (t.squad.members[who].pos as Vector2).distance_to(start)
		_check(slid > 120.0 and slid < T.FLOP_LEN + 60.0, "it slides about its lane (%.0f)" % slid)
		_check(not caught, "a flopping mascot hugs nobody")
		if dodge:
			_check(m.atraccions_flop_hits == hits and m.atraccions_flop_dodges == dodges + 1, "stepped out of: a dodge")
		else:
			_check(m.atraccions_flop_hits == hits + 1 and m.dog_hits == knocks + 1 and m.atraccions_flop_dodges == dodges, "in the lane: one knock, no dodge")
			_check(m.dog.velocity.y > 0.0, "bowled on down the path, not back into the line")
		for i in range(int(T.FLOP_DOWN / DT)):
			t.advance(DT, 200.0, 0.0)
		_check(t.flopped() < 0, "and it is up again")
		t.queue_free()

	# 3. out of reach: no flop
	var far: Node2D = T.new()
	root.add_child(far)
	far.setup(m, -3400.0, m.walk_cx, m.walk_half, 134.0)
	m.dog.global_position = Vector2(640.0, -2000.0)
	m.human.global_position = Vector2(640.0, -1960.0)
	for i in range(90):
		far.advance(DT, 900.0, 0.0)
	_check(far.flop.is_empty(), "nobody flops at a dog out of reach")

	# 4. the line catches, a gap does not
	var mb: Vector2 = far.squad.members[2].pos
	_check(far.caught(mb + Vector2(0.0, 20.0)), "a mascot's arms are a hug")
	_check(not far.caught(mb + Vector2(0.0, 160.0)), "well ahead of them is clear")
	_check(far.caught(Vector2(640.0, far.squad.rear() - 120.0)), "behind the whole line is caught")

	# 5. the jams hold them, and nobody flops off a ride
	far.jams.append(Vector2(480.0, far.front_y + 5.0))
	for i in range(8):
		far.advance(DT, 300.0, 0.0)
	_check(far.jammed(), "a jam holds them")
	far.flop_t = 0.0
	for i in range(60):
		far.advance(DT, 300.0, 0.0)
	_check(far.flop.is_empty(), "and nobody flops off a ride")

	# 6. a continue puts the line back where the checkpoint had it, at once
	far.queue_free()
	m.start_at_home()
	var sw: Node2D = m.chase_sweeper
	var y0: float = sw.front_y
	HC.release(m)
	for i in range(240):
		sw.advance(DT, 300.0, 0.0)
	_check(sw.squad.members[2].pos.y > y0 + 300.0, "the line has come on")
	sw.flop = {"i": 1, "t": 0.0, "from": Vector2.ZERO, "dir": Vector2.DOWN, "slid": true, "near": INF, "hit_dog": false, "hit_human": false}
	HC.continue_run(m)
	_check(absf(sw.front_y - y0) < 1.0, "the checkpoint puts the line back")
	for mbr: Dictionary in sw.squad.members:
		_check(absf((mbr.pos as Vector2).y - (y0 - T.LINE_BACK)) < 120.0, "with its mascot in it, before the countdown (%s)" % mbr.pos)
	_check(sw.flop.is_empty(), "and nobody mid-flop")

	print("test_mascots: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
