extends SceneTree

# The off-leash name and its English gloss are painted just beyond the far
# fence. Tree crowns and the long sniffable props must not cover those words.

const LEVELS := ["street", "park", "beach", "rain", "market", "oldtown", "trail", "station",
	"besos", "site", "spook", "scrap", "guell", "barri", "neteja", "montjuic", "partit"]
const SIGN_W := 520.0
const SIGN_TOP := 58.0
const SIGN_BOTTOM := 16.0
const TREE_R := 40.0
const PROP_R := 28.0

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
	for lvl: String in LEVELS:
		game.level_id = lvl
		var m: Node2D = load("res://main.tscn").instantiate()
		root.add_child(m)
		if not m.is_node_ready():
			await m.ready
		var sign := Rect2(640.0 - SIGN_W * 0.5, m.freedom_lo - SIGN_TOP,
			SIGN_W, SIGN_TOP + SIGN_BOTTOM)
		for t: Vector2 in m.trees:
			_check(not sign.grow(TREE_R).has_point(t),
				"%s tree crown at %s is clear of %s" % [lvl, str(t), str(sign)])
		for p: Dictionary in m.park_props:
			if String(p.kind) in ["log", "driftwood"]:
				_check(not sign.grow(PROP_R).has_point(p.pos),
					"%s %s at %s is clear of %s" % [lvl, String(p.kind), str(p.pos), str(sign)])
		m.queue_free()
		await process_frame
	print("test_freedom_sign_clear: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
