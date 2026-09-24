extends SceneTree

# World labels ("FULL!", "hello? ...oh hi", "click!") spawn at the owner or
# the dog, near the middle of the screen, which is where the feed draws (#66).
# main.clear_of_feed lifts a label that would cross a feed line at any point
# of its rise. This spawns labels across the feed's band on a real main scene
# and checks that none of them ever shares screen space with a feed line, and
# that a label nowhere near the feed stays exactly where it was put.

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
	await process_frame
	var feed: Control = main.feed
	feed.banner = "GET THE CAT HOME! FOLLOW HER"
	feed.lines = Array([
		{"text": "HE'S TEXTING! HE'S NOT LOOKING", "tone": 0, "t": 0.6},
		{"text": "YOU TANGLED THEM! +3", "tone": 1, "t": 0.1},
	], TYPE_DICTIONARY, &"", null)
	var vs: Vector2 = main.get_viewport_rect().size
	var rects: Array[Rect2] = feed.ink_rects(vs)
	_check(rects.size() == 3, "the feed reports where its three lines are")
	var xf: Transform2D = main.get_viewport().get_canvas_transform()
	var zoom := xf.get_scale().y
	var inv := xf.affine_inverse()
	var size := Vector2(120.0, 28.0)
	var clear := true
	var moved := 0
	# labels spawned across the whole band the feed covers, left to right
	var top := rects[0].position.y - 40.0
	var bottom := rects[rects.size() - 1].end.y + 40.0
	var sy := top
	while sy < bottom:
		for sx: float in [vs.x * 0.3, vs.x * 0.5, vs.x * 0.62]:
			var at: Vector2 = inv * Vector2(sx, sy)
			var got: Vector2 = main.clear_of_feed(at, size)
			if got != at:
				moved += 1
			var s: Vector2 = xf * got
			var span := Rect2(s.x, s.y - main.FLOAT_RISE * zoom, size.x * zoom, (size.y + main.FLOAT_RISE) * zoom)
			for r in rects:
				if span.intersects(r):
					clear = false
		sy += 6.0
	_check(clear, "no label crosses a feed line at any point of its rise")
	_check(moved > 0, "labels spawned on the feed were moved (%d)" % moved)
	var far: Vector2 = inv * Vector2(vs.x * 0.5, 40.0)
	_check(main.clear_of_feed(far, size) == far, "a label nowhere near the feed stays where it was put")
	feed.banner = ""
	feed.lines = Array([], TYPE_DICTIONARY, &"", null)
	var mid: Vector2 = inv * (vs * 0.5)
	_check(main.clear_of_feed(mid, size) == mid, "with the feed empty nothing moves")
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_float_text: OK")
		quit(0)
	else:
		quit(1)
