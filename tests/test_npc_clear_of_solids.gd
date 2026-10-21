extends SceneTree

# Nobody else stands in a solid body. Tourists, and the owners and dogs of the
# other dog-walking pairs, must never be inside one of main.solid_rects (the
# stalls, vans, the train, the salamander, the dumpsters, the roaster...).
# They used to: La Rambla's and El Mosaic's tourists walked straight through
# stalls and the salamander, and the pairs' routes did not know about
# L'Estació's train or La Castanyada's roaster, so they walked through those.
#
# 1. Every solid rect on every walk has a bypasser blocker covering it, so
#    pairs and riders steer round it.
# 2. Each affected walk is visited in hops: the pair is put down every HOP px
#    from the start to the gate and left to walk for HOP_FRAMES (your human
#    on autopilot, towing the dog), and every frame each tourist, pair owner
#    and pair dog is checked against the solid rects, shrunk by 4 px as
#    tools/playtest.gd does.
#
# Run with --fixed-fps 60, as CI does, so the walk is the same every time.

const ALL_LEVELS: Array[String] = ["barri", "street", "park", "beach", "rain", "market", "oldtown",
	"trail", "station", "besos", "site", "spook", "scrap", "guell", "neteja", "montjuic", "partit"]
const WALKS: Array[String] = ["street", "guell", "station", "spook", "neteja"]
const HOP := 700.0
const HOP_FRAMES := 360
const SHRINK := 4.0

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _load(level: String) -> Node2D:
	var game: Node = root.get_node("Game")
	game.persist = false
	game.level_id = level
	seed(1)
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	return m


func _covered(m: Node2D, r: Rect2) -> bool:
	for b: Dictionary in m.bypasser_blockers:
		if b.has("rect") and Rect2(b["rect"]).grow(0.5).encloses(r):
			return true
	return false


func _watch(m: Node2D, level: String, frame: int, seen: Dictionary, bad: Dictionary) -> void:
	var bodies: Array = []
	for tw: Node in get_nodes_in_group("tourists"):
		bodies.append(["tourist", tw])
	for pr: Node in get_nodes_in_group("pairs"):
		bodies.append(["pair owner", pr.get("npc_owner")])
		bodies.append(["pair dog", pr.get("npc_dog")])
	for b: Array in bodies:
		var n = b[1]
		if not (n is Node2D) or not is_instance_valid(n) or not (n as Node2D).is_inside_tree():
			continue
		seen[b[0]] += 1
		var p: Vector2 = (n as Node2D).global_position
		for ri in range(m.solid_rects.size()):
			var r: Rect2 = m.solid_rects[ri]
			var key := "%s:%d" % [b[0], ri]
			if r.grow(-SHRINK).has_point(p) and not bad.has(key):
				bad[key] = true
				_check(false, "%s: a %s inside solid rect %d %s at %s, frame %d" % [
					level, b[0], ri, r, p, frame])


func _run() -> void:
	for level: String in ALL_LEVELS:
		var m: Node2D = await _load(level)
		for i in range(m.solid_rects.size()):
			var r: Rect2 = m.solid_rects[i]
			_check(_covered(m, r), "%s: solid rect %d %s has a bypasser blocker" % [level, i, r])
		m.queue_free()
		await process_frame

	for level: String in WALKS:
		var m: Node2D = await _load(level)
		for k in range(3):
			await physics_frame
		m._skip_title()
		var seen := {"tourist": 0, "pair owner": 0, "pair dog": 0}
		var bad := {}
		var hop_y: float = float(m.START_Y) - 200.0
		var frame := 0
		while hop_y > float(m.GATE_Y) + 300.0:
			var at := Vector2(m.walk_edges(hop_y).x * 0.5 + m.walk_edges(hop_y).y * 0.5, hop_y)
			m.dog.global_position = at
			m.human.global_position = at + Vector2(0, 60)
			m.leash.resnap()
			for f in range(HOP_FRAMES):
				await physics_frame
				frame += 1
				if m.phase != "out":
					break
				_watch(m, level, frame, seen, bad)
			hop_y -= HOP
		_check(bad.is_empty(), "%s: no tourist, pair owner or pair dog inside a solid rect" % level)
		print("%s: visited to y=%.0f; %d tourist, %d owner, %d dog samples" % [level,
			m.human.global_position.y, seen["tourist"], seen["pair owner"], seen["pair dog"]])
		# the test has to have watched someone
		_check(seen["tourist"] + seen["pair owner"] > 0, "%s: tourists or pairs were out to watch" % level)
		m.queue_free()
		await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_npc_clear_of_solids: OK")
		quit(0)
	else:
		quit(1)
