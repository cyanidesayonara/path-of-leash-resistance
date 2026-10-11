extends SceneTree

# Loose junk lies where loose junk could lie (LevelBuild.junk_spot_clear): on
# no walk does a crate, can, bottle, sack or ball start inside a stall, a van,
# a bench, a manhole, the pond or a solid block, or in a side street's
# traffic lane, or (on a walk whose path winds) off the path. And a market
# hall's drain gets wet-floor signs, not road cones.

const LEVELS := ["street", "park", "beach", "rain", "market", "oldtown", "trail", "station",
	"site", "spook", "scrap", "guell", "neteja", "barri", "montjuic"]
const JUNK := ["can", "bottle", "sack", "crate", "ball"]

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
	var lb: GDScript = load("res://world/level_build.gd")
	for lvl: String in LEVELS:
		root.get_node("Game").level_id = lvl
		var m: Node2D = load("res://main.tscn").instantiate()
		root.add_child(m)
		if not m.is_node_ready():
			await m.ready
		var bad: Array[String] = []
		var n := 0
		var wet := 0
		var road_cones := 0
		for c: Node2D in m.get_tree().get_nodes_in_group("cones"):
			var k := String(c.kind)
			if k == "wetfloor":
				wet += 1
			if JUNK.has(k):
				n += 1
				if not lb.junk_spot_clear(m, c.position):
					bad.append("%s at %s" % [k, c.position])
		if lvl == "market":
			for c: Node2D in m.get_tree().get_nodes_in_group("cones"):
				if String(c.kind) == "cone" and c.position.distance_to(lb.MERCAT_DRAIN) < 50.0:
					road_cones += 1
			_check(wet >= 2 and road_cones == 0, "market: wet-floor signs at the drain, no road cones (%d, %d)" % [wet, road_cones])
		_check(n > 0, "%s: there is some junk" % lvl)
		_check(bad.is_empty(), "%s: no junk inside anything, in the road or off the path: %s" % [lvl, bad])
		m.queue_free()
		await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_junk_placement: OK")
		quit(0)
	else:
		quit(1)
