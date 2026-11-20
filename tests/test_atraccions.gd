extends SceneTree

# Tests Les Atraccions (systems/atraccions.gd):
# - registration in LEVELS, CAROUSEL (after sitges), STAR_GATE, CHASE_GATE, CAMPAIGN_SKY
# - goals, dare-giver, music, sign material
# - flume splash telegraphs before it soaks, dodge awards when clear
# - solids where they are drawn, middle of the path walkable start to finish

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

	var A: GDScript = load("res://systems/atraccions.gd")
	var G: GDScript = load("res://systems/goals.gd")
	var Challenger: GDScript = load("res://entities/challenger.gd")
	var Music: GDScript = load("res://audio/music.gd")
	var WorldSign: GDScript = load("res://world/world_sign.gd")
	var Outdoors: GDScript = load("res://systems/outdoors.gd")
	var HC: GDScript = load("res://systems/home_chase.gd")

	# 1. registration (assert present, never that it is last)
	_check(A != null, "the walk module loads")
	_check(game.LEVELS.has("atraccions"), "in LEVELS")
	var ci: int = game.CAROUSEL.find("atraccions")
	_check(ci != -1 and ci == game.CAROUSEL.find("sitges") + 1, "in CAROUSEL straight after Sitges")
	_check(int(game.STAR_GATE["atraccions"]) == 47, "opens at 47 stars")
	_check(String(game.CHASE_GATE.get("atraccions", "")) == "cremada", "same chase gate as Sitges")
	_check(String(game.LEVEL_NAMES["atraccions"]) == "Les Atraccions", "named Les Atraccions")
	_check(game.CAMPAIGN_SKY["atraccions"] == ["clear", "day"], "bright day campaign sky")
	_check(String(game.LEVEL_SUBTITLES.get("atraccions", "")).length() <= game.GLOSS_MAX, "EN gloss fits")
	_check(String(game.LEVEL_SUBTITLES_CA.get("atraccions", "")).length() <= game.GLOSS_MAX_LONG, "CA gloss fits")
	_check(String(game.LEVEL_SUBTITLES_ES.get("atraccions", "")).length() <= game.GLOSS_MAX_LONG, "ES gloss fits")

	# no chase profile yet (mascots come later)
	var prof: Dictionary = HC.profile_for("atraccions")
	_check(prof.is_empty() or String(prof.get("kind", "")) == "", "no HomeChase profile yet")

	# 2. goals
	var goals: Array = G.LEVEL_GOAL_IDS["atraccions"]
	_check(goals.size() == 15, "15 goals (has %d)" % goals.size())
	for g: String in ["mark", "sniff", "dry", "flume_dodge", "churro_bark", "ride_bark", "prize"]:
		_check(goals.has(g), "has the %s goal" % g)
	var defs: Dictionary = G.defs(m)
	for g: String in goals:
		_check(defs.has(g), "goal %s has a definition" % g)

	# 3. dare-giver, music, sign
	_check(String(Challenger.WHO.get("atraccions", "")) == "balloon", "dare-giver is balloon")
	_check(Challenger.LINES.has("balloon") and Challenger.NAMES.has("balloon"), "balloon lines and name")
	_check(Challenger.FOOTPRINT.has("balloon"), "balloon footprint")
	_check(Music.STYLES.has("atraccions"), "walk tune")
	_check(Music.DARES.has("balloon"), "dare_balloon tune")
	_check(String(WorldSign.MATERIALS.get("atraccions", "")) == "stubs", "sign pieces are stubs")
	_check(WorldSign.FEEL.has("stubs"), "stubs feel")

	# 4. outdoors
	_check(Outdoors.theme_park("clear", "day"), "theme park crowd on a clear day")
	_check(not Outdoors.theme_park("rain", "day"), "and not in the rain")

	# 5. flume: climb telegraphs before splash, soak / dodge
	m.atraccions_flume = {"state": "wait", "t": 0.0, "cooldown": 0.0, "hit": false, "threatened": false, "warned": false}
	m.atraccions_flume_dodges = 0
	m.human_soak = 0.0
	# put the pair in the splash band
	m.dog.global_position = Vector2(A.CX, -2920.0)
	m.human.global_position = Vector2(A.CX - 40.0, -2920.0)
	m.auto_walk = false
	var saw_climb := false
	var saw_splash := false
	var climb_t := -1.0
	var splash_t := -1.0
	var t := 0.0
	while t < 4.0:
		A.tick(m, 0.05)
		var st: String = str(m.atraccions_flume.get("state", ""))
		if st == "climb" and not saw_climb:
			saw_climb = true
			climb_t = t
		if st == "splash" and not saw_splash:
			saw_splash = true
			splash_t = t
			break
		t += 0.05
	_check(saw_climb, "flume climbs (telegraph) before it plunges")
	_check(saw_splash, "flume plunges into splash")
	_check(splash_t - climb_t >= A.FLUME_WARN - 0.05, "telegraph lasts at least %.1fs (got %.2f)" % [A.FLUME_WARN, splash_t - climb_t])
	# soak while standing in the wash
	while str(m.atraccions_flume.get("state", "")) == "splash":
		A.tick(m, 0.05)
	_check(m.human_soak > 0.0, "human in the splash gets soaked (%.2f)" % m.human_soak)

	# dodge: threatened on the dry (left) side, never hit
	m.atraccions_flume = {"state": "wait", "t": 0.0, "cooldown": 0.0, "hit": false, "threatened": false, "warned": false, "paid": false}
	m.atraccions_flume_dodges = 0
	m.human_soak = 0.0
	m.dog.global_position = Vector2(A.FLUME_DRY_X - 10.0, -2920.0)
	m.human.global_position = Vector2(A.FLUME_DRY_X - 20.0, -2920.0)
	m.dog.planted = true
	t = 0.0
	while t < 5.0:
		A.tick(m, 0.05)
		t += 0.05
	_check(m.atraccions_flume_dodges >= 1, "pulling clear / planting dry awards a flume dodge (%d)" % m.atraccions_flume_dodges)
	m.dog.planted = false

	# flume pool is off the corridor; path past it is walkable and dry side is not water
	_check(A.FLUME_POOL.position.x >= A.PATH_R + 40.0, "flume pool sits well beside the path (x >= PATH_R + 40)")
	_check(A.FLUME_POOL.end.x > A.PATH_R, "pool is entirely east of the corridor")
	_check(A.surface(m, Vector2(A.CX, -2920.0)) == A.Surfaces.S.PAVEMENT, "path past the flume is pavement, not water")
	_check(A.surface(m, Vector2(A.PATH_R - 20.0, -2920.0)) != A.Surfaces.S.WATER, "corridor edge by the pool is not water")
	_check(A.surface(m, Vector2(A.FLUME_DRY_X - 10.0, -2920.0)) != A.Surfaces.S.WATER, "dry side is not water")
	_check(A.surface(m, A.FLUME_POOL.get_center()) == A.Surfaces.S.WATER, "pool itself is water")
	_check(A.surface(m, Vector2(A.CX, -2600.0)) == A.Surfaces.S.MUD, "selva packed earth is mud")
	# middle lane past the pool stays walkable (no solid, no water surface)
	var mid_ok := true
	for yy in [-3060.0, -2980.0, -2920.0, -2860.0]:
		if A.surface(m, Vector2(A.CX, yy)) == A.Surfaces.S.WATER:
			mid_ok = false
		for r: Rect2 in A.solids(m):
			if r.grow(16.0).has_point(Vector2(A.CX, yy)):
				mid_ok = false
	_check(mid_ok, "path past the pool is walkable without wading")

	# 6. bark goals
	m.atraccions_churro_barked = false
	m.atraccions_carousel_spins = 0
	A.on_bark(m, A.CHURRO + Vector2(20.0, 0.0))
	_check(m.atraccions_churro_barked, "barking at the churro cart begs one")
	A.on_bark(m, A.CAROUSEL + Vector2(10.0, 0.0))
	_check(m.atraccions_carousel_spins >= 1, "barking at the carousel spins it")

	# 7. solids where drawn, middle open
	for r: Rect2 in A.solids(m):
		_check(r.position.x >= A.PATH_L - 40.0 and r.end.x <= A.PATH_R + 40.0, "solid %s is on the park path" % str(r))
		_check(not r.grow(20.0).has_point(Vector2(A.CX, r.get_center().y)), "solid %s leaves the middle lane" % str(r))
	var y := float(m.START_Y)
	var blocked := 0
	while y > A.PICNIC_Y:
		for r: Rect2 in A.solids(m):
			if r.grow(24.0).has_point(Vector2(A.CX, y)):
				blocked += 1
		y -= 20.0
	_check(blocked == 0, "the middle of the path is open from the start to the picnic lawn")

	# surfaces: pavement at the gates, water in the harbour, grass on the lawn
	_check(A.surface(m, Vector2(A.CX, -100.0)) == A.Surfaces.S.PAVEMENT, "gates are pavement")
	_check(A.surface(m, A.HARBOUR.get_center()) == A.Surfaces.S.WATER, "harbour is water")
	_check(A.surface(m, Vector2(A.CX, -4600.0)) == A.Surfaces.S.GRASS, "picnic lawn is grass")

	# queue posts are poles
	var posts_ok := 0
	for p: Vector2 in A.QUEUE_POSTS:
		for pole: Vector2 in m.poles:
			if pole.distance_squared_to(p) < 4.0:
				posts_ok += 1
				break
	_check(posts_ok == A.QUEUE_POSTS.size(), "all queue posts are poles (%d/%d)" % [posts_ok, A.QUEUE_POSTS.size()])

	var hooks: Array = A.HOOKS
	_check(hooks.has("tick") and hooks.has("draw_live") and hooks.has("surface"), "HOOKS lists tick, draw_live, surface")

	print("test_atraccions: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
