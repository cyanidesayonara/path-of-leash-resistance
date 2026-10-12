extends SceneTree

# Two seeded market walks in one process, stepped by hand the way the owner
# path test steps them. For each second it prints how far the human and the
# dog moved against what their velocities account for, and the engine's
# process and physics deltas at that moment.
#   godot --headless --path . --script res://tools/walk_carryover.gd [-- --in-physics]
# Walk 2 resumes from `await process_frame`, outside a physics step, where
# CharacterBody2D.move_and_slide moves by the process delta (the wall time of
# the last frame) rather than the physics step: the dog and your human move
# several times further than their velocities say. --in-physics awaits a
# physics frame before stepping, as the tests now do, and both walks agree.

const STEP := 1.0 / 60.0
const SECONDS := 6


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.level_id = "market"
	for walk in range(2):
		seed(1)
		var m: Node2D = load("res://main.tscn").instantiate()
		root.add_child(m)
		if not m.is_node_ready():
			await m.ready
		if "--in-physics" in OS.get_cmdline_user_args():
			await physics_frame
		print("walk %d: in physics frame %s, process delta %.4f, physics delta %.4f" % [
			walk + 1, Engine.is_in_physics_frame(), m.get_process_delta_time(),
			m.get_physics_process_delta_time()])
		for s in range(SECONDS):
			var h0: Vector2 = m.human.global_position
			var d0: Vector2 = m.dog.global_position
			var hv := 0.0
			var dv := 0.0
			for i in range(60):
				m._physics_process(STEP)
				hv += m.human.velocity.length() * STEP
				dv += m.dog.velocity.length() * STEP
			print("  walk %d t=%d s: human moved %6.1f px (velocity %6.1f), dog moved %6.1f px (velocity %6.1f)" % [
				walk + 1, s + 1, m.human.global_position.distance_to(h0), hv,
				m.dog.global_position.distance_to(d0), dv])
		m.queue_free()
		await process_frame
	quit(0)
