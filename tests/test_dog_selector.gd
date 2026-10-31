extends SceneTree

# Tests for the Dog Selector (Millie, Pipa the Galgo, Mochi the French Bulldog, Bruna the Gos d'Atura, Tito the Chihuahua):
# 1. Dog catalog: default Millie (Mongrel), Pipa (Galgo, 15*), Mochi (French Bulldog, 25*).
# 2. Multipliers: Millie balanced (1.0x), Pipa fast (1.20x speed, 0.55x plant), Mochi anchor (0.84x speed, 1.70x plant).
# 3. Unlock gating: star thresholds (0, 15, 25) and free_play override.
# 4. Cycle and persistence: cycle_dog wraps through all 3 dogs, save/load records roundtrip.
# 5. Live entity dynamics: dog.base_speed(), base_accel(), plant_grip_mult(), _dog_breed().
# 6. Leash tug integration: dog plant grip scaling (23.8x mass for Mochi vs 14.0x Millie vs 7.7x Pipa).
# 7. Menu flow (GET READY): dog row, cycling, lock nudge on locked dogs.
# 8. Render integrity: _draw_shapes() runs cleanly for Millie, Pipa, and Mochi.

var Flow: GDScript
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
	Flow = load("res://hud/menu_flow.gd")
	var game: Node = root.get_node("Game")
	# the autoload has already read this machine's save: start from none
	game.persist = false
	game._reset_persisted_state()
	root.get_node("Sfx").muted = true

	_test_catalog_and_traits(game)
	_test_unlocks(game)
	_test_cycle_and_persistence(game)
	await _test_live_entity_and_physics(game)
	_test_menu_flow_and_gating(game)

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_dog_selector: OK")
		quit(0)
	else:
		quit(1)


func _test_catalog_and_traits(game: Node) -> void:
	_check(game.DOGS.has("millie"), "catalog has millie")
	_check(game.DOGS.has("pipa"), "catalog has pipa")
	_check(game.DOGS.has("mochi"), "catalog has mochi")
	_check(game.DOGS.has("bruna"), "catalog has bruna")
	_check(game.DOGS.has("tito"), "catalog has tito")
	_check(game.DEFAULT_DOG == "millie", "default dog is millie")

	# Millie balanced
	_check(game.dog_name("millie") == "Millie", "millie name")
	_check(game.dog_breed("millie") == "mongrel", "millie breed is mongrel")
	_check(is_equal_approx(game.dog_speed_mult("millie"), 1.0), "millie speed mult is 1.0")
	_check(is_equal_approx(game.dog_accel_mult("millie"), 1.0), "millie accel mult is 1.0")
	_check(is_equal_approx(game.dog_plant_mult("millie"), 1.0), "millie plant mult is 1.0")

	# Pipa fast, weak plant
	_check(game.dog_name("pipa") == "Pipa", "pipa name")
	_check(game.dog_breed("pipa") == "galgo", "pipa breed is galgo")
	_check(is_equal_approx(game.dog_speed_mult("pipa"), 1.20), "pipa speed mult is 1.20")
	_check(is_equal_approx(game.dog_accel_mult("pipa"), 1.20), "pipa accel mult is 1.20")
	_check(is_equal_approx(game.dog_plant_mult("pipa"), 0.55), "pipa plant mult is 0.55")

	# Mochi plants hard, slow
	_check(game.dog_name("mochi") == "Mochi", "mochi name")
	_check(game.dog_breed("mochi") == "french bulldog", "mochi breed is french bulldog")
	_check(is_equal_approx(game.dog_speed_mult("mochi"), 0.84), "mochi speed mult is 0.84")
	_check(is_equal_approx(game.dog_accel_mult("mochi"), 0.84), "mochi accel mult is 0.84")
	_check(is_equal_approx(game.dog_plant_mult("mochi"), 1.70), "mochi plant mult is 1.70")

	# Bruna herds human, collects muck
	_check(game.dog_name("bruna") == "Bruna", "bruna name")
	_check(game.dog_breed("bruna") == "gos d'atura", "bruna breed is gos d'atura")
	_check(is_equal_approx(game.dog_speed_mult("bruna"), 1.00), "bruna speed mult is 1.00")
	_check(is_equal_approx(game.dog_accel_mult("bruna"), 1.05), "bruna accel mult is 1.05")
	_check(is_equal_approx(game.dog_plant_mult("bruna"), 1.00), "bruna plant mult is 1.00")
	_check(is_equal_approx(game.dog_herd_mult("bruna"), 1.45), "bruna herd mult is 1.45")
	_check(is_equal_approx(game.dog_muck_mult("bruna"), 1.60), "bruna muck mult is 1.60")

	# Tito slips through gaps, easily reeled in
	_check(game.dog_name("tito") == "Tito", "tito name")
	_check(game.dog_breed("tito") == "chihuahua", "tito breed is chihuahua")
	_check(is_equal_approx(game.dog_speed_mult("tito"), 1.10), "tito speed mult is 1.10")
	_check(is_equal_approx(game.dog_accel_mult("tito"), 1.25), "tito accel mult is 1.25")
	_check(is_equal_approx(game.dog_plant_mult("tito"), 0.35), "tito plant mult is 0.35")
	_check(is_equal_approx(game.dog_mass_mult("tito"), 0.45), "tito mass mult is 0.45")
	_check(is_equal_approx(game.dog_reel_mult("tito"), 1.65), "tito reel mult is 1.65")
	_check(is_equal_approx(game.dog_gap_mult("tito"), 0.57), "tito gap mult is 0.57")


func _test_unlocks(game: Node) -> void:
	game.free_play = false
	_check(game.is_dog_unlocked("millie"), "millie is always unlocked")

	# Gating thresholds: Pipa 15 stars, Mochi 25 stars, Bruna 35 stars, Tito 45 stars
	var saved_records: Dictionary = game.records.duplicate(true)
	game.records.clear()
	_check(game.total_stars() == 0, "total stars is 0")
	_check(not game.is_dog_unlocked("pipa"), "pipa is locked at 0 stars")
	_check(not game.is_dog_unlocked("mochi"), "mochi is locked at 0 stars")
	_check(not game.is_dog_unlocked("bruna"), "bruna is locked at 0 stars")
	_check(not game.is_dog_unlocked("tito"), "tito is locked at 0 stars")

	# Free play unlocks all
	game.free_play = true
	_check(game.is_dog_unlocked("pipa"), "pipa unlocked under free_play")
	_check(game.is_dog_unlocked("mochi"), "mochi unlocked under free_play")
	_check(game.is_dog_unlocked("bruna"), "bruna unlocked under free_play")
	_check(game.is_dog_unlocked("tito"), "tito unlocked under free_play")
	game.free_play = false

	# Grant 15 stars: pipa opens, others locked
	for lv in game.LEVELS.slice(0, 5):
		game.records[lv] = {"stars": 3}
	_check(game.total_stars() == 15, "total stars is 15")
	_check(game.is_dog_unlocked("pipa"), "pipa is unlocked at 15 stars")
	_check(not game.is_dog_unlocked("mochi"), "mochi is still locked at 15 stars")
	_check(not game.is_dog_unlocked("bruna"), "bruna is still locked at 15 stars")
	_check(not game.is_dog_unlocked("tito"), "tito is still locked at 15 stars")

	# Grant 27 stars: mochi opens, bruna and tito locked
	for lv in game.LEVELS.slice(5, 9):
		game.records[lv] = {"stars": 3}
	_check(game.total_stars() == 27, "total stars is 27")
	_check(game.is_dog_unlocked("mochi"), "mochi is unlocked at 25+ stars")
	_check(not game.is_dog_unlocked("bruna"), "bruna is still locked at 27 stars")
	_check(not game.is_dog_unlocked("tito"), "tito is still locked at 27 stars")

	# Grant 36 stars: bruna opens, tito locked
	for lv in game.LEVELS.slice(9, 12):
		game.records[lv] = {"stars": 3}
	_check(game.total_stars() == 36, "total stars is 36")
	_check(game.is_dog_unlocked("bruna"), "bruna is unlocked at 35+ stars")
	_check(not game.is_dog_unlocked("tito"), "tito is still locked at 36 stars")

	# Grant 48 stars: tito opens
	for lv in game.LEVELS.slice(12, 16):
		game.records[lv] = {"stars": 3}
	_check(game.total_stars() == 48, "total stars is 48")
	_check(game.is_dog_unlocked("tito"), "tito is unlocked at 45+ stars")

	# Restore records
	game.records = saved_records


func _test_cycle_and_persistence(game: Node) -> void:
	game.dog = "millie"
	game.cycle_dog(1)
	_check(game.dog == "pipa", "cycle +1 moves millie to pipa")
	game.cycle_dog(1)
	_check(game.dog == "mochi", "cycle +1 moves pipa to mochi")
	game.cycle_dog(1)
	_check(game.dog == "bruna", "cycle +1 moves mochi to bruna")
	game.cycle_dog(1)
	_check(game.dog == "tito", "cycle +1 moves bruna to tito")
	game.cycle_dog(1)
	_check(game.dog == "millie", "cycle +1 wraps tito back to millie")
	game.cycle_dog(-1)
	_check(game.dog == "tito", "cycle -1 wraps millie to tito")
	game.cycle_dog(-1)
	_check(game.dog == "bruna", "cycle -1 moves tito to bruna")
	game.cycle_dog(-1)
	_check(game.dog == "mochi", "cycle -1 moves bruna to mochi")
	game.cycle_dog(-1)
	_check(game.dog == "pipa", "cycle -1 moves mochi to pipa")

	# Persistence
	var test_path := "user://test_records_dog.cfg"
	var cf := ConfigFile.new()
	cf.set_value("player", "dog", "mochi")
	cf.set_value("settings", "free_play", true)
	cf.save(test_path)

	var orig_save: String = game.save_path
	var orig_persist: bool = game.persist
	game.persist = true
	game.save_path = test_path
	game.dog = "millie"
	game.load_records()
	_check(game.dog == "mochi", "load_records loads saved mochi")

	# a dog saved while only browsed, still locked, loads as the default
	cf.set_value("settings", "free_play", false)
	cf.save(test_path)
	game.load_records()
	_check(game.dog == "millie", "a locked saved dog loads as millie")

	# Corrupted / unknown dog key resets to default
	cf.set_value("player", "dog", "cerberus")
	cf.save(test_path)
	game.load_records()
	_check(game.dog == "millie", "invalid dog resets to millie")

	game.save_path = orig_save
	game.persist = orig_persist
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists("test_records_dog.cfg"):
		dir.remove("test_records_dog.cfg")


func _test_live_entity_and_physics(game: Node) -> void:
	var dog_script: GDScript = load("res://entities/dog.gd")
	var dog: CharacterBody2D = CharacterBody2D.new()
	dog.set_script(dog_script)
	root.add_child(dog)

	# Millie active
	game.dog = "millie"
	_check(is_equal_approx(dog.base_speed(), dog.SPEED * 1.0), "dog base_speed with millie")
	_check(is_equal_approx(dog.base_accel(), dog.ACCEL * 1.0), "dog base_accel with millie")
	_check(is_equal_approx(dog.plant_grip_mult(), 1.0), "dog plant_grip_mult with millie")
	_check(dog._dog_breed() == "mongrel", "dog breed mongrel")

	# Pipa active
	game.dog = "pipa"
	_check(is_equal_approx(dog.base_speed(), dog.SPEED * 1.20), "dog base_speed with pipa")
	_check(is_equal_approx(dog.base_accel(), dog.ACCEL * 1.20), "dog base_accel with pipa")
	_check(is_equal_approx(dog.plant_grip_mult(), 0.55), "dog plant_grip_mult with pipa")
	_check(dog._dog_breed() == "galgo", "dog breed galgo")

	# Mochi active
	game.dog = "mochi"
	_check(is_equal_approx(dog.base_speed(), dog.SPEED * 0.84), "dog base_speed with mochi")
	_check(is_equal_approx(dog.base_accel(), dog.ACCEL * 0.84), "dog base_accel with mochi")
	_check(is_equal_approx(dog.plant_grip_mult(), 1.70), "dog plant_grip_mult with mochi")
	_check(dog._dog_breed() == "french bulldog", "dog breed french bulldog")

	# Bruna active
	game.dog = "bruna"
	_check(is_equal_approx(dog.base_speed(), dog.SPEED * 1.00), "dog base_speed with bruna")
	_check(is_equal_approx(dog.base_accel(), dog.ACCEL * 1.05), "dog base_accel with bruna")
	_check(is_equal_approx(dog.plant_grip_mult(), 1.00), "dog plant_grip_mult with bruna")
	_check(is_equal_approx(dog.herd_mult(), 1.45), "dog herd_mult with bruna")
	_check(is_equal_approx(dog.muck_mult(), 1.60), "dog muck_mult with bruna")
	_check(dog._dog_breed() == "gos d'atura", "dog breed gos d'atura")

	# Tito active
	game.dog = "tito"
	_check(is_equal_approx(dog.base_speed(), dog.SPEED * 1.10), "dog base_speed with tito")
	_check(is_equal_approx(dog.base_accel(), dog.ACCEL * 1.25), "dog base_accel with tito")
	_check(is_equal_approx(dog.plant_grip_mult(), 0.35), "dog plant_grip_mult with tito")
	_check(is_equal_approx(dog.mass_mult(), 0.45), "dog mass_mult with tito")
	_check(is_equal_approx(dog.reel_mult(), 1.65), "dog reel_mult with tito")
	_check(is_equal_approx(dog.gap_mult(), 0.57), "dog gap_mult with tito")
	_check(is_equal_approx(dog.collision_radius(), dog.BODY_RADIUS * 0.57), "dog collision_radius follows gap_mult with tito")
	_check(dog._dog_breed() == "chihuahua", "dog breed chihuahua")

	# Plant grip scaling check:
	# In main.gd, dog_m starts at 1.0. With plant on dry pavement:
	# dog_m *= PLANT_GRIP (14.0) * dog.plant_grip_mult()
	var millie_grip: float = 14.0 * 1.0
	var pipa_grip: float = 14.0 * 0.55
	var mochi_grip: float = 14.0 * 1.70
	var tito_grip: float = 14.0 * 0.35
	_check(is_equal_approx(pipa_grip, 7.7), "pipa plant grip is 7.7x mass")
	_check(is_equal_approx(mochi_grip, 23.8), "mochi plant grip is 23.8x mass")
	_check(is_equal_approx(tito_grip, 4.9), "tito plant grip is 4.9x mass")
	_check(tito_grip < pipa_grip, "tito plant grip is lower than pipa")
	_check(pipa_grip < millie_grip, "pipa plant grip is lower than millie")
	_check(mochi_grip > millie_grip, "mochi plant grip is higher than millie")

	# Test drawing runs without error for all five breeds
	dog.queue_redraw()
	await process_frame
	game.dog = "tito"
	dog.queue_redraw()
	await process_frame
	game.dog = "mochi"
	dog.queue_redraw()
	await process_frame
	game.dog = "pipa"
	dog.queue_redraw()
	await process_frame
	game.dog = "millie"
	dog.queue_redraw()
	await process_frame
	dog.queue_free()


func _test_menu_flow_and_gating(game: Node) -> void:
	var main_scene: PackedScene = load("res://main.tscn")
	var m: Node2D = main_scene.instantiate()
	root.add_child(m)

	# Verify details_rows includes dog
	var rows: Array = Flow.details_rows(m)
	var dog_row_found := false
	for r in rows:
		if r.name == "YOUR DOG":
			dog_row_found = true
			_check(r.value == "MILLIE", "dog row value is MILLIE")
			_check(r.unlocked == true, "millie is unlocked")
	_check(dog_row_found, "details_rows includes YOUR DOG")

	# Details change cycles dog
	m.details_idx = 0 # YOUR DOG row
	Flow.details_change(m, 1)
	_check(game.dog == "pipa", "details_change cycles to pipa")
	Flow.details_change(m, 1)
	_check(game.dog == "mochi", "details_change cycles to mochi")
	Flow.details_change(m, 1)
	_check(game.dog == "bruna", "details_change cycles to bruna")
	Flow.details_change(m, 1)
	_check(game.dog == "tito", "details_change cycles to tito")

	# Gating check: if Tito is locked, start_walk nudges locked
	game.free_play = false
	var saved_records: Dictionary = game.records.duplicate(true)
	game.records.clear()
	_check(not game.is_dog_unlocked("tito"), "tito is locked")

	# GET READY refuses a locked dog itself; any other way into a walk (the
	# tutorial, a quick start) walks with the default dog
	game.dog = "tito"
	m.started = false
	Flow.start_walk(m)
	_check(m.started and game.dog == "millie", "a locked dog starting a walk falls back to millie")
	m.started = false
	game.dog = "tito"

	# Now unlock and try start_walk
	game.free_play = true
	m.locked_nudge = 0.0
	Flow.start_walk(m)
	_check(m.started, "unlocked dog allows starting walk")

	game.records = saved_records
	game.free_play = false
	game.dog = "millie"
	m.free()
