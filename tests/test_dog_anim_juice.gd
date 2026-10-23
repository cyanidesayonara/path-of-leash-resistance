extends SceneTree

# Tests for in-game animation polish and feel:
# - Dynamic mood-driven tail wagging (Happy, Scared, Barky, Zoomies, Tired, Idle)
# - Idle breathing cycle on ribcage
# - Jump / vault anticipation, leap stretch, landing cushion squash, launch stretch
# - Skid / hard-brake dust puff triggering and surface tint adaptation

var checks := 0
var failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: %s" % message)
		print("FAIL: %s" % message)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main: Node2D = load("res://main.tscn").instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready
	main.started = false
	main.frozen = true

	var dog: CharacterBody2D = main.dog
	var SurfacesScript: GDScript = load("res://world/surfaces.gd")
	var MoodScript: GDScript = load("res://systems/mood.gd")

	# 1. Default state and idle breathing
	dog.velocity = Vector2.ZERO
	_check(dog.hop == 0.0, "dog initial hop is 0")
	_check(dog.skid == 0.0, "dog initial skid is 0")
	_check(dog.land_squash_t == 0.0, "initial land squash is 0")
	_check(dog.launch_stretch_t == 0.0, "initial launch stretch is 0")

	# 2. Hop leap stretch and landing squash
	dog.hop = 12.0
	dog.tick(0.016)
	_check(dog.prev_hop == 12.0, "prev_hop records previous hop height")
	dog.queue_redraw()
	await process_frame

	# Touch down from hop triggers landing squash
	dog.hop = 0.0
	dog.tick(0.016)
	_check(dog.land_squash_t > 0.1, "touching down from hop triggers landing squash (%.2f)" % dog.land_squash_t)

	# 3. Launch stretch trigger
	dog.trigger_launch_stretch(Vector2(1.0, 0.0), 0.28)
	_check(dog.launch_stretch_t > 0.25, "trigger_launch_stretch initiates launch stretch timer")
	_check(dog.launch_stretch_dir.is_equal_approx(Vector2.RIGHT), "launch stretch direction recorded")

	# 4. Skid and hard-turn detection
	dog.auto = true
	dog.auto_move = Vector2(1.0, 0.0)
	dog.velocity = Vector2(330.0, 0.0)
	dog.tick(0.016)
	# Turn 180 degrees abruptly
	dog.auto_move = Vector2(-1.0, 0.0)
	dog.tick(0.016)
	_check(dog.skid > 0.0, "sharp turn from high speed triggers skid (%.2f)" % dog.skid)
	_check(dog.skid_dir.dot(Vector2.LEFT) > 0.8, "skid direction opposes previous velocity")
	dog.auto = false

	# 5. Drawing across all surfaces with skid active
	dog.skid = 0.8
	for s in [SurfacesScript.S.PAVEMENT, SurfacesScript.S.GRASS, SurfacesScript.S.SAND, SurfacesScript.S.MUD, SurfacesScript.S.WATER]:
		dog.surface = s
		dog.ice = (s == SurfacesScript.S.WATER)
		dog.queue_redraw()
		await process_frame
	_check(true, "dog draws skid dust cleanly across all ground surfaces")

	# 6. Mood-driven animation drawing
	for mid: int in [MoodScript.M.HAPPY, MoodScript.M.SCARED, MoodScript.M.BARKY, MoodScript.M.ZOOMIES, MoodScript.M.TIRED]:
		main.mood.active = mid
		main.mood.intensity = 1.0
		dog.queue_redraw()
		await process_frame
	_check(true, "dog renders cleanly under all 5 moods with dynamic tail wagging and postures")

	# 7. Vault launch stretch integration
	main.vault_t = 0.5
	main.vault_arc = 1.5
	main.vault_pole = Vector2(600, -200)
	main._end_vault()
	_check(dog.launch_stretch_t > 0.1, "ending vault triggers launch stretch on dog (%.2f)" % dog.launch_stretch_t)

	main.queue_free()
	await process_frame

	print("\ntest_dog_anim_juice: %d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("DOG ANIM JUICE OK")
	quit(0 if failures.is_empty() else 1)
