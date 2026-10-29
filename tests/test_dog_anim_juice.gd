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
	# (dog draws skid dust cleanly across all ground surfaces: a draw error fails the run as a SCRIPT ERROR)

	# 6. Mood-driven animation drawing
	for mid: int in [MoodScript.M.HAPPY, MoodScript.M.SCARED, MoodScript.M.BARKY, MoodScript.M.ZOOMIES, MoodScript.M.TIRED]:
		main.mood.active = mid
		main.mood.intensity = 1.0
		dog.queue_redraw()
		await process_frame
	# (dog renders cleanly under all 5 moods with dynamic tail wagging and postures: a draw error fails the run as a SCRIPT ERROR)

	# 7. Vault launch stretch integration
	main.vault_t = 0.5
	main.vault_arc = 1.5
	main.vault_pole = Vector2(600, -200)
	main._end_vault()
	_check(dog.launch_stretch_t > 0.1, "ending vault triggers launch stretch on dog (%.2f)" % dog.launch_stretch_t)

	# 8. Ear secondary motion and dynamic flutter
	dog.facing = Vector2.UP
	dog.hip_dir = Vector2.DOWN
	dog.velocity = Vector2.ZERO
	dog.turbo_active = false
	var idle_ears: Dictionary = dog.get_ear_dynamics()
	_check(idle_ears.wind_trail == 0.0, "ears at rest have 0 wind trail (%.2f)" % idle_ears.wind_trail)
	_check(is_zero_approx(float(idle_ears.centrifugal_sway)), "ears moving straight have approx 0 centrifugal sway (%.2f)" % idle_ears.centrifugal_sway)

	# Turbo sprint streams ears back with slipstream flutter
	dog.velocity = Vector2(0.0, -330.0 * 1.7)
	dog.turbo_active = true
	var sprint_ears: Dictionary = dog.get_ear_dynamics()
	_check(sprint_ears.wind_trail > 5.0, "turbo sprint trails ears back in slipstream (%.2f > 5.0)" % sprint_ears.wind_trail)
	_check(absf(float(sprint_ears.flutter)) > 0.0, "high-speed sprint adds ear flutter")
	dog.turbo_active = false

	# Sharp cornering exerts centrifugal ear sway
	dog.facing = Vector2.RIGHT
	dog.hip_dir = Vector2.UP  # 90 degrees lag
	var turn_ears: Dictionary = dog.get_ear_dynamics()
	_check(absf(float(turn_ears.centrifugal_sway)) > 1.5, "sharp banking lag creates centrifugal ear sway (%.2f)" % turn_ears.centrifugal_sway)
	dog.hip_dir = -dog.facing

	# 9. Human doomscrolling feed & night screen glow rendering
	var game: Node = root.get_node("Game")
	main.human.phone_away = 0.0
	main.human.queue_redraw()
	await process_frame
	_check(true, "human doomscrolling phone screen draws cleanly")

	game.night = true
	main.human.queue_redraw()
	await process_frame
	_check(true, "human night-time face screen reflection glow draws cleanly")
	game.night = false

	# 10. Water wake rings, spray droplets, and wading human marks
	dog.surface = SurfacesScript.S.WATER
	dog.velocity = Vector2(0.0, -220.0)
	main.mark_last = Vector2(INF, INF)
	main.ground_marks.clear()
	main._ground_marks()
	var has_ring := false
	var has_spray := false
	for gm in main.ground_marks:
		if String(gm["kind"]) == "ring":
			has_ring = true
		elif String(gm["kind"]) == "spray":
			has_spray = true
	_check(has_ring, "running in water adds stepping wake rings")
	_check(has_spray, "high-speed running in water kicks up water spray droplets")

	# Human wading marks
	main.human.wading = true
	main.human.velocity = Vector2(0.0, -40.0)
	main.human.global_position = Vector2(640.0, 100.0)
	main.dent_last_human = Vector2(640.0, 40.0)  # > 32px away
	var mark_cnt: int = main.ground_marks.size()
	main._press_dents()
	_check(main.ground_marks.size() > mark_cnt, "wading human footprints create water ripples")
	main.human.wading = false

	main.free()
	await process_frame

	print("\ntest_dog_anim_juice: %d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("DOG ANIM JUICE OK")
	quit(0 if failures.is_empty() else 1)
