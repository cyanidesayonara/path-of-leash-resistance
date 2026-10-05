extends SceneTree

# Natural ground is open ground (docs/superpowers/specs/2026-10-03-menu-terrain-design.md):
# grass, sand, mud and water are places the dog can go, blocked only by
# things that are solid on purpose. For every walk this samples the ground
# inside the level edge, keeps the points surface_at() calls natural, and
# reports any that sit inside static collision, grouped by what they hit.
#   godot --headless --path . --script res://tools/terrain_audit.gd [-- level ...]

const Surfaces := preload("res://world/surfaces.gd")
const LEVELS := ["barri", "street", "park", "beach", "rain", "market", "oldtown", "trail",
	"station", "site", "spook", "scrap", "guell", "neteja", "montjuic", "tutorial"]
const STEP := Vector2(24.0, 40.0)


func _initialize() -> void:
	call_deferred("_run")


func _natural(k: int) -> bool:
	return k == Surfaces.S.GRASS or k == Surfaces.S.SAND or k == Surfaces.S.MUD or k == Surfaces.S.WATER


func _run() -> void:
	var levels: Array = LEVELS
	if not OS.get_cmdline_user_args().is_empty():
		levels = Array(OS.get_cmdline_user_args())
	var total_bad := 0
	for lvl: String in levels:
		var game: Node = root.get_node("Game")
		game.level_id = lvl
		var m: Node2D = load("res://main.tscn").instantiate()
		root.add_child(m)
		if not m.is_node_ready():
			await m.ready
		m.frozen = true
		for k in range(3):
			await physics_frame
		var space: PhysicsDirectSpaceState2D = m.get_world_2d().direct_space_state
		var q := PhysicsPointQueryParameters2D.new()
		q.collision_mask = 1
		q.collide_with_areas = false
		var natural := 0
		var hits := {}
		var y: float = m.START_Y - 20.0
		while y > m.GATE_Y + 20.0:
			var x := 0.0
			while x < 1280.0:
				var p := Vector2(x, y)
				var k: int = m.surface_at(p)
				if _natural(k):
					natural += 1
					q.position = p
					for r: Dictionary in space.intersect_point(q, 4):
						var c: Object = r["collider"]
						if c is CharacterBody2D:
							continue
						var shape_owner := ""
						var body := c as CollisionObject2D
						if body != null:
							var sid: int = int(r["shape"])
							var own := body.shape_find_owner(sid)
							var sh: Shape2D = body.shape_owner_get_shape(own, 0)
							shape_owner = sh.get_class()
							var xf: Transform2D = body.global_transform * body.shape_owner_get_transform(own)
							if sh is RectangleShape2D:
								shape_owner += " %s at %s" % [(sh as RectangleShape2D).size, xf.origin.round()]
						var key := "%s %s on %s" % [c.get_class(), shape_owner, ["PAVEMENT", "GRASS", "SAND", "MUD", "WATER", "TILE"][k]]
						if not hits.has(key):
							hits[key] = []
						(hits[key] as Array).append(p)
				x += STEP.x
			y -= STEP.y
		var bad := 0
		for key in hits:
			bad += (hits[key] as Array).size()
		total_bad += bad
		print("%-9s natural samples %5d, inside collision %4d" % [lvl, natural, bad])
		for key in hits:
			var pts: Array = hits[key]
			print("    %4d  %s  e.g. %s" % [pts.size(), key, pts.slice(0, 4)])
		m.queue_free()
		await process_frame
	print("TERRAIN AUDIT: %d natural samples inside collision" % total_bad)
	quit(0)
