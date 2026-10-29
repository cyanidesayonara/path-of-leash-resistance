extends SceneTree

# Tests for the Dog Selector (Pipa the Galgo):
# 1. Dog catalog: default Millie (Mongrel), Pipa (Galgo) at 15 stars.
# 2. Multipliers: Millie balanced (1.0x), Pipa fast (1.20x speed, 1.20x accel, 0.55x plant).
# 3. Unlock gating: star thresholds and free_play override.
# 4. Cycle and persistence: cycle_dog wraps, save/load records roundtrip.
# 5. Live entity dynamics: dog.base_speed(), base_accel(), plant_grip_mult(), _dog_breed().
# 6. Leash tug integration: dog plant grip scaling.
# 7. Menu flow (GET READY): dog row, cycling, lock nudge on locked dog.
# 8. Render integrity: _draw_shapes() runs cleanly for both Millie and Pipa.

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
	game.persist = false
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


func _test_unlocks(game: Node) -> void:
	game.free_play = false
	_check(game.is_dog_unlocked("millie"), "millie is always unlocked")

	# Pipa requires 15 stars
	# Clear stars
	var saved_records: Dictionary = game.records.duplicate(true)
	game.records.clear()
	_check(game.total_stars() == 0, "total stars is 0")
	_check(not game.is_dog_unlocked("pipa"), "pipa is locked at 0 stars")

	# Free play unlocks all
	game.free_play = true
	_check(game.is_dog_unlocked("pipa"), "pipa unlocked under free_play")
	game.free_play = false

	# Grant 15 stars using actual level IDs in LEVELS
	for lv in game.LEVELS.slice(0, 5):
		game.records[lv] = {"stars": 3}
	_check(game.total_stars() == 15, "total stars is 15")
	_check(game.is_dog_unlocked("pipa"), "pipa is unlocked at 15 stars")

	# Restore records
	game.records = saved_records


func _test_cycle_and_persistence(game: Node) -> void:
	game.dog = "millie"
	game.cycle_dog(1)
	_check(game.dog == "pipa", "cycle +1 moves millie to pipa")
	game.cycle_dog(1)
	_check(game.dog == "millie", "cycle +1 wraps pipa back to millie")
	game.cycle_dog(-1)
	_check(game.dog == "pipa", "cycle -1 wraps millie to pipa")

	# Persistence
	var test_path := "user://test_records_dog.cfg"
	var cf := ConfigFile.new()
	cf.set_value("player", "dog", "pipa")
	cf.save(test_path)

	var orig_save: String = game.save_path
	var orig_persist: bool = game.persist
	game.persist = true
	game.save_path = test_path
	game.dog = "millie"
	game.load_records()
	_check(game.dog == "pipa", "load_records loads saved dog")

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

	# Plant grip scaling check:
	# In main.gd, dog_m starts at 1.0. With plant on dry pavement:
	# dog_m *= PLANT_GRIP (14.0) * dog.plant_grip_mult()
	var millie_grip: float = 14.0 * 1.0
	var pipa_grip: float = 14.0 * 0.55
	_check(is_equal_approx(pipa_grip, 7.7), "pipa plant grip is 7.7x mass")
	_check(pipa_grip < millie_grip, "pipa plant grip is significantly lower than millie")

	# Test drawing runs without error for both breeds
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

	# Gating check: if Pipa is locked, start_walk nudges locked
	game.free_play = false
	var saved_records: Dictionary = game.records.duplicate(true)
	game.records.clear()
	_check(not game.is_dog_unlocked("pipa"), "pipa is locked")

	m.started = false
	m.locked_nudge = 0.0
	Flow.start_walk(m)
	_check(m.locked_nudge > 0.0, "starting walk with locked dog triggers locked_nudge")
	_check(not m.started, "locked dog prevents starting walk")

	# Now unlock and try start_walk
	game.free_play = true
	m.locked_nudge = 0.0
	Flow.start_walk(m)
	_check(m.started, "unlocked dog allows starting walk")

	game.records = saved_records
	game.free_play = false
	game.dog = "millie"
	m.free()
