extends Node2D

# Loose junk that exists to be kicked. Dog, human and riders all send it
# skittering; it spins, slides and settles wherever physics leaves it,
# because nobody in history has ever put a cone back.
#
# One script, several KINDS, because the fun is in the variety of heft: a
# drink can rattles away twice as far as a cone, a rubbish sack barely
# shifts and kills your momentum, a lost ball fairly flies. Same physics,
# different mass and friction, and each one drawn so you can tell at a
# glance how heavy it is going to feel.

var main: Node2D
var dog: Node2D
var human: Node2D
var vel := Vector2.ZERO
var spin := 0.0
var kind := "cone"

# per-kind feel: how hard it launches, how fast it slows, how big it is
const KINDS := {
	"cone":   {"kick": 0.70, "drag": 300.0, "r": 9.0,  "min": 90.0},
	"can":    {"kick": 1.35, "drag": 150.0, "r": 6.0,  "min": 170.0},
	"bottle": {"kick": 1.10, "drag": 200.0, "r": 7.0,  "min": 130.0},
	"ball":   {"kick": 1.55, "drag": 110.0, "r": 8.0,  "min": 200.0},
	"sack":   {"kick": 0.30, "drag": 620.0, "r": 13.0, "min": 40.0},
	"crate":  {"kick": 0.38, "drag": 520.0, "r": 12.0, "min": 50.0},
}


func setup(m: Node2D, d: Node2D, h: Node2D, knd := "cone") -> void:
	add_to_group("cones")
	main = m
	dog = d
	human = h
	kind = knd if KINDS.has(knd) else "cone"
	rotation = randf() * TAU


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	var k: Dictionary = KINDS[kind]
	var hit_r: float = float(k.r) + 15.0
	_kick_by(dog.global_position, dog.velocity, hit_r)
	_kick_by(human.global_position, human.velocity, hit_r + 2.0)
	for b in main.riders_cache:
		_kick_by(b.global_position, b.vel, hit_r + 4.0)
	if vel.length_squared() > 1.0:
		position += vel * delta
		vel = vel.move_toward(Vector2.ZERO, float(k.drag) * delta)
		rotation += spin * delta
		spin = move_toward(spin, 0.0, 6.0 * delta)
		# anything punted into a hole is gone, and it is glorious
		for m in main.manholes:
			if global_position.distance_to(m) < 16.0:
				main.float_text(global_position, "plop", Color(0.8, 0.85, 0.9))
				queue_free()
				return
		for c in main.cellars:
			if (c as Rect2).has_point(global_position):
				main.float_text(global_position, "plop", Color(0.8, 0.85, 0.9))
				queue_free()
				return
		if main.pond.size.x > 0.0 and (main.pond as Rect2).has_point(global_position):
			main.float_text(global_position, "ploosh", Color(0.6, 0.8, 1.0))
			queue_free()
			return
		queue_redraw()


func _kick_by(p: Vector2, v: Vector2, r: float) -> void:
	var d := global_position - p
	var l := d.length()
	if l < r and l > 0.001:
		var k: Dictionary = KINDS[kind]
		vel = d / l * maxf(v.length() * float(k.kick), float(k.min))
		spin = randf_range(-8.0, 8.0)
		if main.has_method("on_junk_kicked"):
			main.on_junk_kicked(global_position, kind)


func _draw() -> void:
	var k: Dictionary = KINDS[kind]
	var rr: float = float(k.r)
	# a contact shadow, so it sits on the ground instead of floating. Heavier
	# things get a bigger, darker one.
	var heft: float = clampf(620.0 / float(k.drag), 0.35, 1.5)
	main.contact_shadow(self, Vector2.ZERO, rr * 1.05, 4.0 + rr * 0.35, 0.14 + 0.10 * heft)
	match kind:
		"can":
			# a crushed drink can: bright metal, a dark rim, a pull tab
			draw_circle(Vector2.ZERO, rr, Color(0.78, 0.80, 0.83))
			draw_arc(Vector2.ZERO, rr * 0.72, 0, TAU, 10, Color(0.52, 0.55, 0.58), 2.0)
			draw_rect(Rect2(-rr * 0.9, -1.4, rr * 1.8, 2.8), Color(0.86, 0.24, 0.20))
			draw_circle(Vector2(rr * 0.3, -rr * 0.3), 1.4, Color(0.42, 0.44, 0.47))
		"bottle":
			# a plastic bottle on its side: body, neck, cap
			draw_rect(Rect2(-rr, -rr * 0.62, rr * 1.55, rr * 1.24), Color(0.62, 0.78, 0.80, 0.85))
			draw_rect(Rect2(rr * 0.55, -rr * 0.3, rr * 0.5, rr * 0.6), Color(0.68, 0.83, 0.85, 0.9))
			draw_circle(Vector2(rr * 1.1, 0.0), rr * 0.34, Color(0.30, 0.55, 0.85))
			draw_line(Vector2(-rr * 0.6, -rr * 0.5), Vector2(-rr * 0.6, rr * 0.5), Color(1, 1, 1, 0.35), 1.5)
		"ball":
			# a lost kids' ball, panelled so the spin reads
			draw_circle(Vector2.ZERO, rr, Color(0.90, 0.86, 0.78))
			draw_arc(Vector2.ZERO, rr * 0.98, 0.0, TAU, 14, Color(0.55, 0.52, 0.48), 1.2)
			for i in range(3):
				var a := TAU * float(i) / 3.0
				draw_line(Vector2.ZERO, Vector2.from_angle(a) * rr * 0.92, Color(0.40, 0.46, 0.62), 2.2)
			draw_circle(Vector2(-rr * 0.32, -rr * 0.34), rr * 0.26, Color(1, 1, 1, 0.45))
		"sack":
			# a tied rubbish sack: heavy, slumped, with a knot on top
			draw_circle(Vector2(0.0, rr * 0.16), rr, Color(0.17, 0.17, 0.20))
			draw_circle(Vector2(-rr * 0.3, -rr * 0.2), rr * 0.62, Color(0.24, 0.24, 0.28))
			draw_line(Vector2(-3.0, -rr * 0.9), Vector2(3.0, -rr * 1.25), Color(0.30, 0.30, 0.34), 3.0)
			draw_circle(Vector2(rr * 0.34, rr * 0.34), rr * 0.28, Color(0.12, 0.12, 0.15))
		"crate":
			# a wooden crate: slats and a visible rim, clearly a lump
			draw_rect(Rect2(-rr, -rr * 0.85, rr * 2.0, rr * 1.7), Color(0.55, 0.40, 0.24))
			draw_rect(Rect2(-rr, -rr * 0.85, rr * 2.0, rr * 1.7), Color(0.38, 0.27, 0.16), false, 2.0)
			for s in range(3):
				var sy := -rr * 0.5 + float(s) * rr * 0.5
				draw_line(Vector2(-rr * 0.92, sy), Vector2(rr * 0.92, sy), Color(0.40, 0.29, 0.17), 1.6)
			draw_rect(Rect2(-rr * 0.35, -rr * 0.3, rr * 0.7, rr * 0.6), Color(0.30, 0.22, 0.14, 0.5))
		_:
			# The traffic cone, which from above is a bullseye: square base
			# flange, then rings climbing to the tip, each one a little
			# brighter, with the reflective collar in white. Concentric
			# shading is the only way a cone reads as pointed from overhead.
			draw_rect(Rect2(-rr * 1.15, -rr * 1.15, rr * 2.3, rr * 2.3), Color(0.72, 0.36, 0.11))
			draw_rect(Rect2(-rr * 1.15, -rr * 1.15, rr * 2.3, rr * 2.3), Color(0.55, 0.27, 0.09), false, 1.5)
			draw_circle(Vector2.ZERO, rr, Color(0.80, 0.40, 0.12))
			draw_circle(Vector2(-rr * 0.05, -rr * 0.05), rr * 0.82, Color(0.94, 0.92, 0.86))
			draw_circle(Vector2(-rr * 0.10, -rr * 0.10), rr * 0.60, Color(0.93, 0.52, 0.17))
			draw_circle(Vector2(-rr * 0.15, -rr * 0.15), rr * 0.34, Color(0.99, 0.64, 0.26))
			draw_circle(Vector2(-rr * 0.18, -rr * 0.18), rr * 0.16, Color(1.0, 0.78, 0.44))
