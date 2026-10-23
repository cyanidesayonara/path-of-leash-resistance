extends SceneTree

# El Besos: the floodable river park between L'Estacio and Les Obres.
# Calm on the way out (a path, grass, a shallow margin, a solid channel).
# On the way home the shallow water pushes and wets; the deep front loses.

var HomeChase: GDScript
var LevelBuild: GDScript
var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _load() -> Node2D:
	var game: Node = root.get_node("Game")
	game.persist = false
	game.level_id = "besos"
	game.weather = "clear"
	game.night = false
	seed(1)
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	return m


func _run() -> void:
	HomeChase = load("res://systems/home_chase.gd")
	LevelBuild = load("res://world/level_build.gd")
	var game: Node = root.get_node("Game")
	_check(int(game.STAR_GATE["besos"]) == 14, "El Besos opens at 14 stars")
	_check(int(game.STAR_GATE["station"]) == 13, "L'Estacio stays at 13")
	_check(int(game.STAR_GATE["site"]) == 15, "Les Obres stays at 15")
	_check(int(game.STAR_GATE["neteja"]) == 23, "La Neteja stays at 23")
	var carousel: Array = game.CAROUSEL
	_check(carousel.find("besos") == carousel.find("station") + 1, "it sits after L'Estacio")
	_check(carousel.find("site") == carousel.find("besos") + 1, "and before Les Obres")
	var kept := {"barri": 0, "street": 1, "park": 2, "beach": 3, "rain": 4, "market": 7,
		"oldtown": 9, "trail": 11, "spook": 17, "scrap": 19, "guell": 21, "montjuic": 25, "partit": 27}
	for id: String in kept:
		_check(int(game.STAR_GATE[id]) == int(kept[id]), "%s keeps its star gate" % id)

	var prof: Dictionary = HomeChase.profile_for("besos")
	_check(String(prof.get("kind", "")) == "flood", "the home leg is the flood")
	_check(is_equal_approx(float(prof.get("speed", 0.0)), HomeChase.FLOOD_SPEED), "slower than a running dog, faster than your human")
	_check(not bool(prof.get("flee", true)), "your human does not bolt")
	var bands: Array = prof.get("bands", [])
	_check(bands.size() == 2, "El Besos has two respites (weir and apron)")
	_check(String(bands[0].get("id", "")) == "weir" and not bool(bands[0].get("checkpoint", false)), "first respite is the inflatable weir")
	_check(is_equal_approx(float(bands[0].get("jam_y", 0.0)), LevelBuild.BESOS_WEIR_JAM_Y), "weir jam is at BESOS_WEIR_JAM_Y")
	_check(String(bands[1].get("id", "")) == "midpoint" and bool(bands[1].get("checkpoint", false)), "second respite is the apron checkpoint")
	_check(is_equal_approx(float(bands[1].get("jam_y", 0.0)), LevelBuild.BESOS_JAM_Y), "apron jam is at BESOS_JAM_Y")
	_check(String(HomeChase.profile_for("neteja").get("kind", "")) == "sweeper", "La Neteja is still the sweeper")
	_check(HomeChase.profile_for("street").is_empty(), "an ordinary walk still has no chase profile")

	var m: Node2D = await _load()
	_check(m.chase_active and String(m.chase_kind) == "flood", "the walk rolls the flood, not a vehicle")
	_check(not m.tofu_quest_active, "no Tofu on a chase walk")
	var ids: Array = m.LEVEL_GOAL_IDS["besos"]
	_check("floodgap" in ids and "dry" in ids, "the flood goals are on the list")
	_check(not ("tofu" in ids), "bringing Tofu home is not a goal here")
	_check(m.lane_ys.is_empty(), "no traffic on the river path")
	_check(m.freedom_kind == "clearing", "the destination is an open meadow")
	_check(m.water.size() >= 1, "the margin is water")
	var wet: Vector2 = LevelBuild.besos_water_rect(m).get_center()
	_check(m.surface_at(wet) == m.Surfaces.S.WATER, "standing in the margin is a swim")
	var channel: Rect2 = LevelBuild.besos_deep_rect(m)
	var blocked := false
	for r: Rect2 in m.solid_rects:
		if r.encloses(Rect2(channel.get_center(), Vector2(2, 2))):
			blocked = true
	_check(blocked, "the deep channel is solid")
	var covered := false
	for b: Dictionary in m.bypasser_blockers:
		if b.has("rect") and Rect2(b["rect"]).grow(0.5).encloses(channel):
			covered = true
	_check(covered, "walkers steer round the channel")

	await physics_frame
	HomeChase.begin(m)
	HomeChase.release(m)
	var flood: Node2D = m.chase_sweeper
	_check(flood != null and flood.has_method("threat_boundary"), "the chase spawned the flood")
	flood.front_y = 0.0
	flood.rumble = 0.0
	_check(is_equal_approx(flood.threat_boundary(), flood.SHALLOW_LEAD), "the shallow edge leads the deep front")
	m.dog.global_position = Vector2(m.walk_cx, 40.0)
	m.dog.velocity = Vector2.ZERO
	m.dog.planted = false
	var dog_y: float = m.dog.global_position.y
	flood.touch(m, 0.1, true)
	var ran: float = m.dog.global_position.y - dog_y
	_check(ran > 15.0, "the shallow water carries a loose dog south (%.1f)" % ran)
	m.dog.global_position = Vector2(m.walk_cx, 40.0)
	m.dog.velocity = Vector2.ZERO
	m.dog.planted = true
	var planted_y: float = m.dog.global_position.y
	flood.touch(m, 0.1, true)
	var held: float = m.dog.global_position.y - planted_y
	_check(held > 0.5 and held < ran * 0.4, "planting resists the same push (%.1f vs %.1f)" % [held, ran])
	m.dog.global_position = Vector2(m.walk_cx, 40.0)
	m.dog.velocity = Vector2(0.0, -80.0)
	m.dog.planted = false
	var upstream_y: float = m.dog.global_position.y
	flood.touch(m, 0.1, true)
	var upstream: float = m.dog.global_position.y - upstream_y
	_check(upstream > 28.0, "a dog heading upstream is still carried at the push (%.1f)" % upstream)
	m.human.global_position = Vector2(m.walk_cx, 40.0)
	m.human.velocity = Vector2(0.0, 92.0)
	m.human_soak = 0.0
	var pace: Vector2 = m.human.velocity
	flood.touch(m, 0.5, true)
	_check(m.human.velocity.is_equal_approx(pace), "the push does not slow your human's motor")
	_check(m.human.global_position.y > 40.0, "and it still carries them south")
	_check(m.human_soak > 0.0, "standing in it wets them")
	_check(not flood.caught(Vector2(m.walk_cx, 40.0)), "the shallow is not a loss")
	_check(flood.caught(Vector2(m.walk_cx, -5.0)), "the deep front is")
	flood.rumble = PI * 0.5 / 0.55
	_check(is_equal_approx(flood.swell(), flood.SWELL_MAX), "the swell tops out at a lane's edge, not a wall")
	_check(flood.in_deep(Vector2(m.walk_cx + m.walk_half - 10.0, 20.0)), "the swell from the river is deep water")
	_check(not flood.in_deep(Vector2(m.walk_cx - m.walk_half + 30.0, 20.0)), "the wall side of the path stays open")
	# Respite 1: Inflatable rubber weir hold
	flood.front_y = LevelBuild.BESOS_WEIR_JAM_Y
	flood.jam_t = 3.0
	flood.jam_at = Vector2(m.walk_cx, LevelBuild.BESOS_WEIR_JAM_Y)
	flood.queue_redraw()
	_check(flood.jammed(), "flood is held at the inflatable weir")
	_check(HomeChase.banner(m) == "WEIR HOLDING! RUN!", "banner warns weir is holding (got %s)" % HomeChase.banner(m))

	# Respite 2: Maintenance apron hold and midpoint checkpoint
	flood.front_y = LevelBuild.BESOS_JAM_Y
	flood.jam_t = 3.0
	flood.jam_at = Vector2(LevelBuild.BESOS_APRON.get_center().x, LevelBuild.BESOS_JAM_Y)
	var on_apron := Vector2(LevelBuild.BESOS_APRON.position.x + 40.0, LevelBuild.BESOS_JAM_Y + 40.0)
	_check(LevelBuild.BESOS_APRON.has_point(on_apron), "the sample stands on the apron")
	_check(not flood.in_shallow(on_apron) and not flood.in_deep(on_apron), "the apron stays dry while the flood is held")
	_check(HomeChase.banner(m) == "IT'S HOLDING! CROSS THE APRON", "banner guides crossing the apron")

	# Standing on the northern portion of the apron safely captures the midpoint checkpoint
	m.dog.global_position = on_apron
	m.human.global_position = on_apron + Vector2(20.0, 10.0)
	var apron_jam := Vector2(LevelBuild.BESOS_APRON.get_center().x, LevelBuild.BESOS_JAM_Y)
	flood.jams.clear()
	flood.jams.append(apron_jam)
	flood.front_y = LevelBuild.BESOS_JAM_Y - 0.5
	flood.jam_t = 0.0
	HomeChase.tick(m, 0.016)
	_check(flood.jammed(), "flood hit the apron jam")
	_check(not (m.chase_checkpoint as Dictionary).is_empty(), "chase checkpoint is captured while standing on apron")
	_check(String((m.chase_checkpoint as Dictionary).get("id", "")) == "midpoint", "checkpoint id is midpoint (got " + String((m.chase_checkpoint as Dictionary).get("id", "")) + ")")

	flood.jam_t = 0.0
	_check(flood.in_shallow(on_apron), "when the hold ends, the water spills across it")

	flood.front_y = 0.0
	flood.heading = 100.0
	flood.branch_who = ""
	flood.branch_warn = 0.0
	var at: Vector2 = flood._branch_pos()
	m.dog.global_position = at + Vector2(400.0, 0.0)
	m.human.global_position = at
	m.human.state = m.human.HState.WALK
	m.human.bubble.visible = false
	m.human.telegraph_t = 0.0
	m.human.correct_t = 0.0
	m.human.reel_pending_t = 0.0
	m.human.external_warning_t = 0.0
	flood._branch(m.dog, m.human, 0.05)
	_check(m.human.state != m.human.HState.STUMBLE, "a branch warns before it stumbles your human")
	_check(m.human.bubble != null and m.human.bubble.visible, "the warning is a speech bubble")
	m.human.event_timer = -1.0
	m.human._events(0.1)
	_check(m.human.bubble.text == "watch it", "an owner event cannot overwrite the branch warning")
	flood.cancel_branch_warning()
	_check(flood.branch_who == "" and flood.branch_warn <= 0.0 \
		and m.human.external_warning_t <= 0.0, "a checkpoint restore can cancel a pending branch")
	flood._branch(m.dog, m.human, 0.05)
	m.human.state = m.human.HState.WHIRL
	flood._branch(m.dog, m.human, 0.8)
	_check(m.human.state == m.human.HState.WHIRL and m.human.external_warning_t <= 0.0,
		"an orbit can refuse the stumble without keeping the warning reserved")
	m.human.state = m.human.HState.WALK
	m.human.bubble.visible = false
	flood._branch(m.dog, m.human, 0.05)
	flood._branch(m.dog, m.human, 0.1)
	_check(m.human.state != m.human.HState.STUMBLE, "the warning beat is not cut short")
	flood._branch(m.dog, m.human, 0.8)
	_check(m.human.state == m.human.HState.STUMBLE, "the stumble lands when the warning ends")

	m.dog.global_position = Vector2(m.walk_cx, -800.0)
	m.dog.velocity = Vector2.ZERO
	m.dog.flooded = true
	m.dog.slick = true
	m.dog.auto = true
	m.dog.auto_move = Vector2.RIGHT
	m.dog.energy = 1.0
	for _i in 30:
		m.dog.tick(1.0 / 60.0)
	_check(m.dog.velocity.x > 80.0, "shallow water loosens steering without pinning her (%.1f)" % m.dog.velocity.x)
	m.dog.auto = false
	m.dog.flooded = false
	m.dog.slick = false

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_besos: OK")
		quit(0)
	else:
		quit(1)
