extends SceneTree

# Each dog's skill goal (systems/dog_skills.gd): one per dog on every walk,
# outside the walk's own goals, met by her own skill, and the first time on a
# walk a training point for her.

var checks := 0
var failures: Array[String] = []
var DogSkills: GDScript


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _load(game: Node, lv: String, d: String) -> Node2D:
	game.dog = d
	game.level_id = lv
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.frozen = false
	m.phase = "out"
	return m


func _free(m: Node2D) -> void:
	m.queue_free()
	await process_frame


# a post for a gap: a solid circle the dog's body collides with
func _post(m: Node2D, at: Vector2, r: float) -> StaticBody2D:
	var b := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = r
	cs.shape = sh
	b.add_child(cs)
	b.collision_layer = m.dog.collision_mask
	m.add_child(b)
	b.global_position = at
	return b


func _run() -> void:
	DogSkills = load("res://systems/dog_skills.gd")
	var game: Node = root.get_node("Game")
	game.persist = false
	game.training = {}
	game.skills_done = {}
	game.finds_found = {}

	# every dog has a goal of her own, and it is not one of the walk's
	for d: String in game.DOG_KEYS:
		var m := await _load(game, "park", d)
		var q: Dictionary = m.skill_quest
		_check(not q.is_empty(), "%s has a skill goal on El Parc" % d)
		var ids: Array = []
		for wq: Dictionary in m.active_quests:
			ids.append(String(wq.id))
		_check(not ids.has(String(q.get("id", ""))), "%s's skill goal is not among the walk's own" % d)
		var card: Dictionary = m.Goals.card_data(m)
		_check(int(card.total) == m.active_quests.size(), "%s's skill goal is outside the walk's count" % d)
		await _free(m)

	# Millie: a buried find dug up meets it, a training point the first time only
	var m := await _load(game, "park", "millie")
	var before: int = game.training_points("millie")
	m.finds_dug = 1
	DogSkills.tick(m, 1.0 / 60.0)
	_check(bool(m.skill_done_run), "Millie meets hers by digging up a find")
	_check(game.training_points("millie") == before + 1, "and it is a training point")
	_check(game.skill_done("park", "millie"), "kept for El Parc")
	await _free(m)
	m = await _load(game, "park", "millie")
	m.finds_dug = 1
	DogSkills.tick(m, 1.0 / 60.0)
	_check(game.training_points("millie") == before + 1, "a second time on El Parc is no new point")
	await _free(m)

	# Pipa: flat out, past her own top speed, for long enough without a break
	m = await _load(game, "park", "pipa")
	var fast: float = float(m.dog.base_speed()) * (DogSkills.SPRINT_OVER + 0.05)
	m.dog.turbo_active = true
	m.dog.velocity = Vector2(0, -fast)
	for f in range(60):
		DogSkills._tick_sprint(m, 1.0 / 60.0)
	m.dog.velocity = Vector2(0, -float(m.dog.base_speed()))
	DogSkills._tick_sprint(m, 1.0 / 60.0)
	_check(float(m.skill_sprint_t) == 0.0, "slowing to her own top speed breaks the sprint")
	_check(DogSkills.progress(m) == 1, "a second flat out counts one (%d)" % DogSkills.progress(m))
	m.dog.velocity = Vector2(0, -fast)
	for f in range(130):
		DogSkills._tick_sprint(m, 1.0 / 60.0)
	DogSkills.tick(m, 1.0 / 60.0)
	_check(bool(m.skill_done_run), "two seconds flat out meets Pipa's")
	await _free(m)

	# Mochi: planted as the leash yanks, her human stumbles
	m = await _load(game, "park", "mochi")
	m.human.pull_cd = 0.0
	m.human.on_leash_yank(Vector2(0, 1), true, 200.0)
	_check(int(m.skill_stumbles) == 1, "a planted yank that makes your human stumble counts")
	m.human.pull_cd = 0.0
	m.human.state = m.human.HState.WALK
	m.human.on_leash_yank(Vector2(0, 1), false, 200.0)
	_check(int(m.skill_stumbles) == 1, "one she was not planted for does not")
	await _free(m)

	# Bruna: a steady pull across the path, while he walks on
	m = await _load(game, "park", "bruna")
	m.human.state = m.human.HState.WALK
	m.human.felt_pull = Vector2(float(m.human.GIVE_FULL) * 0.6, 0.0)
	for f in range(60 * 3):
		DogSkills._tick_herd(m, 1.0 / 60.0)
	_check(DogSkills.progress(m) == 3, "three seconds of herding counts three (%d)" % DogSkills.progress(m))
	m.human.felt_pull = Vector2(0.0, float(m.human.GIVE_FULL) * 0.6)
	for f in range(60 * 3):
		DogSkills._tick_herd(m, 1.0 / 60.0)
	_check(DogSkills.progress(m) == 3, "a pull along the path is not herding")
	await _free(m)

	# Tito: between two posts a bigger dog would touch, not beside one wall
	m = await _load(game, "park", "tito")
	var at: Vector2 = m.dog.global_position + Vector2(0, -400)
	m.dog.global_position = at
	var tr: float = float(m.dog.collision_radius())
	var normal: float = float(m.dog.BODY_RADIUS)
	var gap_half := (tr + normal) * 0.5
	var a := _post(m, at + Vector2(-(gap_half + 20.0), 0), 20.0)
	var b := _post(m, at + Vector2(gap_half + 20.0, 0), 20.0)
	await physics_frame
	await physics_frame
	_check(DogSkills.squeezed(m.dog, at), "Tito between two posts a bigger dog would touch is squeezing")
	b.queue_free()
	await physics_frame
	await physics_frame
	_check(not DogSkills.squeezed(m.dog, at), "beside one post alone she is not")
	a.queue_free()
	await _free(m)
	m = await _load(game, "park", "millie")
	m.dog.global_position = at
	var c := _post(m, at + Vector2(-(gap_half + 20.0), 0), 20.0)
	var e := _post(m, at + Vector2(gap_half + 20.0, 0), 20.0)
	await physics_frame
	await physics_frame
	_check(not DogSkills.squeezed(m.dog, at), "a normal-sized dog is never squeezing")
	c.queue_free()
	e.queue_free()
	await _free(m)

	# her gaps are counted along the walk, a few rows a frame, and her target
	# is what the walk has, up to three; none, and she has no skill goal there
	m = await _load(game, "station", "tito")
	var frames := 0
	while not bool(m.skill_gaps_scanned) and frames < 2000:
		DogSkills.tick(m, 1.0 / 60.0)
		frames += 1
	_check(bool(m.skill_gaps_scanned) and int(m.skill_quest.get("target", 0)) == 3, "L'Estació has three of Tito's gaps (%s)" % m.skill_quest)
	await _free(m)
	m = await _load(game, "barri", "tito")
	frames = 0
	while not bool(m.skill_gaps_scanned) and frames < 2000:
		DogSkills.tick(m, 1.0 / 60.0)
		frames += 1
	_check(bool(m.skill_gaps_scanned) and (m.skill_quest as Dictionary).is_empty(), "El Barri has none, so Tito has no skill goal there")
	await _free(m)

	# the tutorial has none
	m = await _load(game, "park", "millie")
	m.tutorial_mode = true
	DogSkills.build(m)
	_check((m.skill_quest as Dictionary).is_empty(), "the tutorial has no skill goal")
	m.tutorial_mode = false
	await _free(m)

	game.dog = "millie"
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("OK")
	quit(0 if failures.is_empty() else 1)
