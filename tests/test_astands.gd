extends SceneTree

# A-stands (the toppleable sandwich boards) stand once, at level start, one per
# entry in the level's astands list, and kicking junk never adds more (#30:
# the spawn loop lived in on_junk_kicked, so none stood at the start and every
# kick stacked a fresh set).

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


func _count_astands(main: Node) -> int:
	var n := 0
	for c in main.get_children():
		var sc: Script = c.get_script()
		if sc != null and sc.resource_path.ends_with("/astand.gd"):
			n += 1
	return n


func _run() -> void:
	var game = root.get_node("Game")
	for lv: String in ["street", "market", "oldtown"]:
		game.level_id = lv
		var main: Node2D = load("res://main.tscn").instantiate()
		root.add_child(main)
		if not main.is_node_ready():
			await main.ready
		var want: int = main.astands.size()
		_check(_count_astands(main) == want, "%s: %d A-stands stand at level start (found %d)" % [lv, want, _count_astands(main)])
		for i in range(3):
			main.on_junk_kicked(Vector2(640, 0), "can")
		_check(_count_astands(main) == want, "%s: kicking junk adds no A-stands (found %d)" % [lv, _count_astands(main)])
		main.queue_free()
		await process_frame
	game.level_id = "street"

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("ASTANDS OK")
		quit(0)
	else:
		print("ASTANDS FAIL")
		quit(1)
