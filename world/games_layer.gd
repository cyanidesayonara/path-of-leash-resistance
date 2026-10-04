extends Node2D

# Draws the off-leash games (systems/freedom_games.gd) in two layers: the
# ground layer under the dogs (the course's lane, flags, jumps, poles) and the
# cover layer over them (the tunnel's tube, which she disappears into, and the
# rope between two dogs in a tug).

var main: Node2D
var cover := false
var _b: ShapeBatch


func setup(m: Node2D, is_cover: bool) -> void:
	main = m
	cover = is_cover


var _was_rope := true


# Redraw only what moves: the flags wave (half rate is plenty), and over the
# dogs only a rope in play moves - the tunnel itself stands still.
func _process(_delta: float) -> void:
	if not visible or main == null:
		return
	if cover:
		var rope: bool = main.tug != null or main.rope_carry_t > 0.0
		if rope or rope != _was_rope:
			queue_redraw()
		_was_rope = rope
	elif Engine.get_process_frames() % 2 == 0:
		queue_redraw()


# a dropped rope appears or is picked up: one redraw
func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	if main == null or main.agility == null:
		return
	_b = ShapeBatch.new(self)
	if cover:
		main.agility.draw_cover(_b)
		var fd: Node2D = main.tug_dog
		if main.tug != null and is_instance_valid(fd):
			var a: Vector2 = main.dog.global_position + main.dog.facing * 18.0
			var b: Vector2 = fd.global_position + fd.face * 15.0
			FreedomGames.draw_rope(_b, a, b)
		elif main.rope_carry_t > 0.0:
			var m0: Vector2 = main.dog.global_position + main.dog.facing * 16.0
			FreedomGames.draw_rope(_b, m0, m0 + main.dog.facing.rotated(0.6) * 24.0)
		elif main.rope_loose.x < INF:
			var p: Vector2 = main.rope_loose
			FreedomGames.draw_rope(_b, p + Vector2(-11, 3), p + Vector2(11, -3))
	else:
		main.agility.draw_ground(_b, AnimClock.msec() / 1000.0)
	_b.flush()
