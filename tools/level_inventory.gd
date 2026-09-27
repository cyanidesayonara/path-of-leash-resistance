extends SceneTree

# Level inventory: builds every walk and prints what is in it - width, the
# base layout it borrows, props by kind, patches, hazards, landmarks, goals -
# one block per walk. For design passes (#21), and to see at a glance where
# two walks have ended up the same walk redressed.
#
#   godot --headless --path . --script res://tools/level_inventory.gd

const COUNTED := [
	"poles", "trees", "benches", "bins", "hydrants", "kebabs", "tables", "chairs",
	"parasols", "canopies", "astands", "vans", "performers", "cone_spots", "stalls",
	"fountains", "manholes", "cellars", "lane_ys", "wallcat_spots", "laundry_lines",
	"candy_spots", "guard_posts", "cameras", "lasers", "palm_spots", "towels",
	"verge_items", "park_props", "duck_ys", "flock_ys",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	var levels: Array = Array(game.LEVELS) + ["tutorial"]
	for lv: String in levels:
		game.level_id = lv
		var m: Node2D = load("res://main.tscn").instantiate()
		root.add_child(m)
		if not m.is_node_ready():
			await m.ready
		var name: String = String(game.LEVEL_NAMES.get(lv, lv))
		print("== %s (%s)" % [lv, name])
		var bends: String = "bends" if not (m.edge_nodes as Array).is_empty() else "straight"
		print("  width %d, %s, gate %s, off-leash %s, built %s" % [
			int(m.walk_half * 2.0), bends, m.gate_text, m.freedom_kind, m.built])
		var counts := []
		for key: String in COUNTED:
			var n := 0
			var v: Variant = m.get(key)
			if v is Array:
				n = (v as Array).size()
			if n > 0:
				counts.append("%s %d" % [key, n])
		print("  " + ", ".join(counts))
		var kinds := {}
		for pt: Dictionary in m.patches:
			kinds[String(pt["kind"])] = int(kinds.get(String(pt["kind"]), 0)) + 1
		var extra := []
		if not kinds.is_empty():
			extra.append("patches %s" % str(kinds))
		if m.pond.size.x > 0.0:
			extra.append("pond")
		if m.conveyor_zone.size.y > 0.0:
			extra.append("moving walkway")
		if bool(m.signal_prone):
			extra.append("no signal")
		if bool(m.chase_active):
			extra.append("chase")
		if not extra.is_empty():
			print("  " + ", ".join(extra))
		var goals: Array = m.LEVEL_GOAL_IDS.get(lv, [])
		print("  goals: " + ", ".join(goals))
		m.queue_free()
		await process_frame
	quit()
