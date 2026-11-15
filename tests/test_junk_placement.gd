extends SceneTree

# Loose junk lies where loose junk could lie (LevelBuild.junk_spot_clear): on
# no walk does a crate, can, bottle, sack or ball start inside a stall, a van,
# a bench, a manhole, the pond or a solid block, or in a side street's
# traffic lane, or (on a walk whose path winds) off the path. And a market
# hall's drain gets wet-floor signs, not road cones.

const LEVELS := ["street", "park", "beach", "rain", "market", "oldtown", "trail", "station",
	"besos", "site", "spook", "scrap", "guell", "neteja", "barri", "montjuic", "partit",
	"tibidabo", "aigues", "horta", "llevant", "montserrat", "vet"]
# where a traffic cone would not belong (LevelBuild.CONE_KINDS): none
const NO_CONES := ["park", "beach", "trail", "montjuic", "tibidabo", "aigues", "horta", "llevant", "montserrat", "vet"]
# roofed walks, where the floor is swept and mopped
const INDOORS := ["market", "vet", "station"]
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
		if lvl in NO_CONES:
			var cones := 0
			for c: Node2D in m.get_tree().get_nodes_in_group("cones"):
				if String(c.kind) == "cone":
					cones += 1
			_check(cones == 0, "%s: no traffic cones where there is no traffic (%d)" % [lvl, cones])
		if lvl == "vet":
			_check(wet >= 2, "vet: a wet-floor sign by each mopped spill (%d)" % wet)
		if lvl in INDOORS:
			# water on an indoor floor is a film (main._draw_spill), never the
			# lobed outdoor puddle
			var outdoor := 0
			for pt: Dictionary in m.patches:
				if String(pt["kind"]) == "puddle" and not pt.get("spill", false):
					outdoor += 1
			_check(outdoor == 0, "%s: no outdoor puddles on an indoor floor (%d)" % [lvl, outdoor])
		if lvl == "station":
			# a concourse has steel seating and its own bin, not a park bench
			# and a street bin
			_check(m.walk_mod != null and m.walk_mod.has_method("draw_bench") and m.walk_mod.has_method("draw_bin"),
				"station: the concourse draws its own seating and bin")
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
