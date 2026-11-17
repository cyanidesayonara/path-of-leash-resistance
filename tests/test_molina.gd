extends SceneTree

# Tests La Molina and the runaway groomer chase (systems/molina.gd,
# entities/groomer_threat.gd, intro/film_molina.gd):
# - registration in LEVELS, CAROUSEL, STAR_GATE, CHASE_GATE, CAMPAIGN_SKY, LEVEL_NAMES
# - goals, the chase profile, its respites and film
# - snow cannons: the whir telegraphs before any snow, a blast that comes by
#   the pair and touches neither pays a dodge, standing in it is one hit
# - snowballs: packed on the blade for the whole telegraph before they roll,
#   a body in the lane is knocked, one passing close is a dodge
# - the catch line, the checkpoint fields, the snowman's nose
# - solids are where they are drawn, and the piste is walkable end to end

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
	game.level_id = "molina"
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

	var M: GDScript = load("res://systems/molina.gd")
	var Threat: GDScript = load("res://entities/groomer_threat.gd")
	var Film: GDScript = load("res://intro/film_molina.gd")
	var G: GDScript = load("res://systems/goals.gd")
	var HC: GDScript = load("res://systems/home_chase.gd")
	var CC: GDScript = load("res://systems/chase_checkpoint.gd")

	# 1. registration
	_check(M != null and Threat != null and Film != null, "the walk, the threat and the film load")
	_check(game.LEVELS.has("molina"), "in LEVELS")
	var ci: int = game.CAROUSEL.find("molina")
	_check(ci != -1 and ci == game.CAROUSEL.find("horta") + 1, "in CAROUSEL straight after El Laberint d'Horta")
	_check(int(game.STAR_GATE["molina"]) == 42, "opens at 42 stars")
	_check(String(game.CHASE_GATE.get("molina", "")) == "aeroport", "after L'Aeroport")
	_check(String(game.LEVEL_NAMES["molina"]) == "La Molina", "named La Molina")
	_check(game.CAMPAIGN_SKY["molina"] == ["snow", "day"], "the first snow walk")

	# 2. goals
	var goals: Array = G.LEVEL_GOAL_IDS["molina"]
	_check(goals.size() == 15, "15 goals (has %d)" % goals.size())
	for g: String in ["cannon_dodge", "snowball_dodge", "groomer_clean", "snowman_bark", "jamon", "clock", "prize"]:
		_check(goals.has(g), "has the %s goal" % g)
	var defs: Dictionary = G.defs(m)
	for g: String in goals:
		_check(defs.has(g), "goal %s has a definition" % g)

	# 3. the chase profile
	var prof: Dictionary = HC.profile_for("molina")
	_check(String(prof.get("kind", "")) == "groomer", "groomer kind")
	_check(String(prof.get("script", "")) == "res://entities/groomer_threat.gd", "threat script")
	_check(String(prof.get("film", "")) == "res://intro/film_molina.gd", "its film")
	var bands: Array = prof.get("bands", [])
	_check(bands.size() == 2 and bool(bands[0].get("checkpoint", false)) and bool(bands[1].get("checkpoint", false)),
		"two respites, both checkpoints")
	_check(m.chase_jams.size() == 2, "two chase jams registered (got %d)" % m.chase_jams.size())
	_check(String(prof.get("snowball_banner", "")) != "", "a banner for a snowball coming")

	# 4. the snow cannons
	for i in range(M.CANNONS.size()):
		var blow_t := -1.0
		var t := 0.0
		while t < M.CANNON_CYCLE * 2.0:
			if M.cannon_state(i, t) == 2:
				blow_t = t
				break
			t += 0.01
		_check(blow_t > 0.0, "cannon %d blows once a cycle" % i)
		_check(M.cannon_state(i, blow_t - M.CANNON_WARN + 0.05) == 1, "cannon %d whirs before it blows" % i)
		_check(M.cannon_state(i, blow_t - M.CANNON_WARN - 0.05) == 0, "and is quiet before that")
		var nz: Vector2 = M.CANNONS[i][0]
		var dir: Vector2 = (M.CANNONS[i][1] as Vector2).normalized()
		_check(M.in_cone(i, nz + dir * 150.0), "cannon %d's cone covers the piste in front of it" % i)
		_check(not M.in_cone(i, nz - dir * 40.0), "and nothing behind it")
		var far: Vector2 = nz + dir * (float(M.CANNON_REACH) * 0.5)
		_check(far.x > M.PATH_L and far.x < M.PATH_R, "cannon %d blows onto the piste" % i)

	# a blast near the pair that touches neither is a dodge, paid once
	var nz0: Vector2 = M.CANNONS[0][0]
	m.molina_cannons = {}
	m.molina_cannon_dodges = 0
	m.molina_cannon_hits = 0
	# beside the cannon, out of its cone, near enough to count
	m.dog.global_position = Vector2(M.CX + 60.0, nz0.y + 210.0)
	m.human.global_position = Vector2(M.CX, nz0.y + 230.0)
	var t2 := 0.0
	while t2 < M.CANNON_CYCLE * 1.05:
		m.elapsed = t2
		M.tick(m, 0.05)
		t2 += 0.05
	_check(m.molina_cannon_dodges == 1, "keeping clear of a nearby blast is one dodge (got %d)" % m.molina_cannon_dodges)
	_check(m.molina_cannon_hits == 0, "and no hit")
	# standing in the cone: one hit for the blast, however long she stays
	m.molina_cannons = {}
	m.molina_cannon_dodges = 0
	m.molina_cannon_hits = 0
	var pat0: float = m.human.patience
	t2 = M.CANNON_CYCLE * 2.0
	while t2 < M.CANNON_CYCLE * 3.0:
		m.elapsed = t2
		m.human.global_position = nz0 + (M.CANNONS[0][1] as Vector2).normalized() * 120.0
		m.dog.global_position = Vector2(M.CX, nz0.y + 400.0)
		M.tick(m, 0.05)
		t2 += 0.05
	_check(m.molina_cannon_hits == 1, "standing in the cone is one hit a blast (got %d)" % m.molina_cannon_hits)
	_check(m.molina_cannon_dodges == 0, "and no dodge for it")
	_check(m.human.patience < pat0, "your human loses patience in the snow")

	# 5. the groomer and its snowballs
	var g = Threat.new()
	m.add_child(g)
	g.setup(m, -3000.0, M.CX, M.HALF, 128.0)
	_check(g.front_y == -3000.0 and g.threat_boundary() == -3000.0, "it starts where it is put")
	_check(g.caught(Vector2(M.CX, -3040.0)), "the blade catches what is in front of the cab")
	_check(not g.caught(Vector2(M.CX, -2800.0)), "but not what is still ahead of it")
	_check(g.caught(Vector2(M.PATH_L + 10.0, -3300.0)), "whoever it has passed went under a track")
	_check(is_equal_approx(g.gap_to(Vector2(M.CX, -2800.0)), 200.0), "the gap is measured down the piste")
	# packed on the blade for the whole telegraph, then it rolls
	m.auto_walk = false
	m.dog.velocity = Vector2.ZERO
	m.human.velocity = Vector2.ZERO
	m.dog.global_position = Vector2(M.CX, -2600.0)
	m.human.global_position = Vector2(M.PATH_L + 40.0, -2500.0)
	g.pack_t = 0.0
	g.advance(0.016, 400.0, 0.0)
	_check(g.snowballs.size() == 1, "a snowball packs on the blade")
	var lane: float = float(g.snowballs[0]["x"])
	_check(absf(lane - M.CX) < 40.0, "in the dog's lane (%.0f)" % lane)
	_check(g.snowball_warning(), "and the banner warns her it is coming")
	var steps := int(Threat.SNOWBALL_WARN / 0.016) - 2
	for k in range(steps):
		g._tick_snowballs(0.016)
	_check(g.snowballs.size() == 1 and not bool(g.snowballs[0]["rolling"]), "it waits on the blade through the telegraph")
	for k in range(4):
		g._tick_snowballs(0.016)
	_check(g.snowballs.size() == 1 and bool(g.snowballs[0]["rolling"]), "then it rolls")
	# rolling down her lane: she is knocked
	var hits0: int = m.molina_snowball_hits
	for k in range(300):
		g._tick_snowballs(0.016)
		if g.snowballs.is_empty():
			break
	_check(m.molina_snowball_hits == hits0 + 1, "a body in its lane is knocked")
	# out of its lane, close by: a dodge, paid when it bursts
	var dodges0: int = m.molina_snowball_dodges
	var bones0: int = m.bones
	g.snowballs.append({"x": M.CX, "y": -2700.0, "t": 2.0, "rolling": true, "hit": false, "from": -2700.0,
		"dog_near": false, "hum_near": false})
	m.dog.global_position = Vector2(M.CX + 70.0, -2400.0)
	m.human.global_position = Vector2(M.PATH_L + 30.0, -2200.0)
	for k in range(400):
		g._tick_snowballs(0.016)
		if g.snowballs.is_empty():
			break
	_check(m.molina_snowball_dodges == dodges0 + 1, "a snowball passing close is a dodge")
	_check(m.bones == bones0 + Threat.DODGE_BONES, "and pays a bone")
	_check(CC.MAIN_FIELDS.has("molina_snowball_dodges") and CC.MAIN_FIELDS.has("molina_snowball_hits"),
		"the checkpoint keeps the snowball counts")
	# the autowalk is never knocked
	m.auto_walk = true
	var hits1: int = m.molina_snowball_hits
	g.snowballs.append({"x": M.CX, "y": -2700.0, "t": 2.0, "rolling": true, "hit": false, "from": -2700.0,
		"dog_near": false, "hum_near": false})
	m.dog.global_position = Vector2(M.CX, -2500.0)
	for k in range(400):
		g._tick_snowballs(0.016)
		if g.snowballs.is_empty():
			break
	_check(m.molina_snowball_hits == hits1, "the autowalk pair is never knocked")
	m.auto_walk = false

	# 6. the snowman
	m.molina_snowman_barked = false
	M.on_bark(m, Vector2(M.CX, -500.0))
	_check(not m.molina_snowman_barked, "barking far from the snowman does nothing")
	M.on_bark(m, M.SNOWMAN + Vector2(-60.0, 30.0))
	_check(m.molina_snowman_barked, "barking at him knocks his nose off")

	# 7. solids where they are drawn, clear of the poles, on the piste
	for r: Rect2 in M.solids(m):
		_check(r.position.x >= M.PATH_L - 1.0 and r.end.x <= M.PATH_R + 1.0, "solid %s is on the piste" % str(r))
		for p: Vector2 in M.FIRS + M.GATES:
			_check(not r.grow(30.0).has_point(p), "solid %s stands clear of the pole at %s" % [str(r), str(p)])
	# a lane up the piste's middle is open all the way: nothing solid in it
	var y := float(m.START_Y)
	var blocked := 0
	while y > M.TERRACE_Y:
		for r: Rect2 in M.solids(m):
			if r.grow(24.0).has_point(Vector2(M.CX, y)):
				blocked += 1
		y -= 20.0
	_check(blocked == 0, "the middle of the piste is open from the start to the terrace")
	# the piste handles as packed snow, the banks as deep powder
	_check(M.surface(m, Vector2(M.CX, -2000.0)) == M.Surfaces.S.PAVEMENT, "the piste is packed")
	_check(M.surface(m, Vector2(M.PATH_L - 60.0, -2000.0)) == M.Surfaces.S.SAND, "the bank is deep powder")

	# 8. the film plays its length and draws
	_check(float(Film.LENGTH) > 5.0, "the film has a length")
	_check(Film.camera(1.0).size() == 2 and Film.camera(5.0).size() == 2, "the film has a camera throughout")
	_check(Film.ground_y(Film.CREST_X) < Film.ground_y(600.0), "the groomer starts up the slope from the pair")

	print("test_molina: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
