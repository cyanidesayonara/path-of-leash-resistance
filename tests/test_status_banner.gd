extends SceneTree

# The one-line status ("NEED A WEE!", "LOOSE LEASH!", "FETCH! ...", "RUN!")
# reaches the screen through the event feed's banner, during a walk only.
# From 2026-08-03 the call that set it sat after a return, so the banner was
# never set and none of those lines were shown anywhere (#29).

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	# deferred so the autoloads are registered before main.gd is compiled
	call_deferred("_run")


func _run() -> void:
	var main: Node2D = load("res://main.tscn").instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready
	main.started = true
	main.poop_state = 1
	main._update_hud()
	_check(String(main.hud_status).begins_with("NEED A WEE"), "the status names the need (got '%s')" % main.hud_status)
	_check(main.feed.banner == main.hud_status, "the banner shows the status (banner '%s')" % main.feed.banner)

	main.poop_state = 0
	main.phase = "freedom"
	main.romp_done = true
	main._update_hud()
	_check(main.feed.banner == "GO BACK DOWN TO HEAD HOME", "the banner follows the status as it changes (banner '%s')" % main.feed.banner)

	# on the title the status stays off the screen
	main.started = false
	main._update_hud()
	_check(main.feed.banner == "", "no banner on the title (banner '%s')" % main.feed.banner)

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("STATUS BANNER OK")
		quit(0)
	else:
		print("STATUS BANNER FAIL")
		quit(1)
