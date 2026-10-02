extends Node2D

const Clay := preload("res://entities/clay.gd")

# The "bring Tofu home" quest. Tofu the cat has escaped again (she does
# this in real life) and turns up loose on the walk home. You cannot grab
# her - she keeps her skittish distance - so you HERD her: get close and
# she bolts to the next hiding spot further south, and you press her along
# spot by spot until she is all the way home.

const FLEE_R := 145.0
const DART_SPEED := 330.0

var main: Node2D
var my_dog: Node2D
var spots: Array[Vector2] = []  # ordered north -> south, home last
var idx := 0
var darting := false
var home := false
var seed_o := 0.0
var alert_t := 0.0


func setup(m: Node2D, mine: Node2D, hide_spots: Array[Vector2]) -> void:
	add_to_group("tofu")
	main = m
	my_dog = mine
	spots = hide_spots
	seed_o = randf() * 10.0
	if spots.size() > 0:
		global_position = spots[0]


func _physics_process(delta: float) -> void:
	if main.frozen or home or spots.is_empty():
		return
	alert_t = maxf(0.0, alert_t - delta)
	if darting:
		var target: Vector2 = spots[idx]
		global_position = global_position.move_toward(target, DART_SPEED * delta)
		if global_position.distance_to(target) < 4.0:
			darting = false
			if idx >= spots.size() - 1:
				home = true
				main.on_tofu_home(global_position)
	else:
		# hiding: bolt to the next spot south when the dog closes in
		if my_dog.global_position.distance_to(global_position) < FLEE_R:
			alert_t = 0.4
			if idx < spots.size() - 1:
				idx += 1
				darting = true
			else:
				home = true
				main.on_tofu_home(global_position)
	if Engine.get_physics_frames() % 2 == 0:
		queue_redraw()


# Tofu's own coat: white, a brown tabby cap and saddle, a ringed brown tail
# and the pink harness she always manages to wriggle out of the house in
const TOFU_COAT := {
	"base": Color(0.95, 0.93, 0.89),
	"patch": Color(0.64, 0.46, 0.28),
	"stripe": Color(0.42, 0.29, 0.17),
	"tail": Color(0.64, 0.46, 0.28),
	"muzzle": Color(0.99, 0.98, 0.95),
	"eyes": Color(0.72, 0.88, 0.30),
	"harness": Color(0.93, 0.42, 0.62),
}


func _draw() -> void:
	var t := AnimClock.msec() / 1000.0
	if Clay.offscreen(self, main):
		return
	var wag := sin(t * (2.0 if home else (10.0 if darting else 5.0)) + seed_o) * (0.2 if home else 0.45)
	# she watches the dog from her hiding spot, and looks where she runs
	var face := Vector2.DOWN
	if darting and idx < spots.size():
		var to: Vector2 = spots[idx] - global_position
		if to.length() > 0.5:
			face = to.normalized()
	elif not home and my_dog != null:
		var to := my_dog.global_position - global_position
		if to.length() > 0.5:
			face = to.normalized()
	var b := ShapeBatch.new(self)
	Clay.ground_shadow(b, Vector2.ZERO, 9.0, 6.0, 4.0, 0.24)
	draw_cat(b, Vector2.ZERO, face, TOFU_COAT, 1.0 if darting else 0.0, 0.0, wag, alert_t > 0.0 or darting, 1.1)
	if home:
		for i in range(2):
			var a := t * 2.0 + i * 3.0
			_heart(b, Vector2(0, -14) + Vector2.from_angle(a) * 8.0, 2.2, Color(0.95, 0.5, 0.6, 0.85))
	b.flush()
	if not home and (alert_t > 0.0 or darting):
		draw_string(ThemeDB.fallback_font, Vector2(-4, -14), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.9, 0.5))


static func _heart(c: Object, at: Vector2, r: float, col: Color) -> void:
	c.draw_circle(at + Vector2(-r * 0.5, 0), r * 0.62, col)
	c.draw_circle(at + Vector2(r * 0.5, 0), r * 0.62, col)
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(-r * 1.08, r * 0.2), at + Vector2(r * 1.08, r * 0.2), at + Vector2(0, r * 1.3)]), col)


# A cat seen from straight above, shared by Tofu, the critter cat and the
# wall cats. `run` (0..1) stretches her from a sitting loaf into a dash;
# `arch` (0..1) bunches her up with her fur on end and her tail a
# bottlebrush. Only filled shapes and wide lines, so a ShapeBatch keeps her
# in one draw call.
static func draw_cat(c: Object, at: Vector2, face: Vector2, coat: Dictionary, run: float,
		arch: float, swish: float, alert: bool, s := 1.0) -> void:
	var fwd := face.normalized() if face.length() > 0.01 else Vector2.DOWN
	var side := fwd.orthogonal()
	var base: Color = coat["base"]
	var tail_col: Color = coat.get("tail", base)
	var patch: Variant = coat.get("patch", null)
	var stripe: Variant = coat.get("stripe", null)
	var body_half := Vector2(lerpf(6.4, 8.6, run), lerpf(5.8, 4.4, run)) * s * (1.0 + arch * 0.12)
	var body_c := at - fwd * (1.0 * s)
	var head_c := at + fwd * lerpf(5.2, 8.4, run) * s
	var hr := 4.4 * s
	# the tail: wrapped round her feet sitting, streaming out running
	var tail := PackedVector2Array()
	var tw := (2.2 + arch * 2.4) * s
	var wrap := 1.0 if swish >= 0.0 else -1.0
	for k in range(6):
		var f := float(k) / 5.0
		var sit_p := body_c + (-fwd).rotated(f * 1.5 * wrap) * (body_half.x * 0.8 + f * 6.0 * s)
		var run_p := body_c - fwd * (body_half.x * 0.85 + f * 11.0 * s) + side * sin(swish * 3.0 + f * 2.5) * f * 3.0 * s
		tail.append(sit_p.lerp(run_p, maxf(run, arch * 0.8)))
	Clay.stroke(c, tail, tw * 1.25, tw * 1.05, Clay.rim_of(tail_col))
	Clay.stroke(c, tail, tw * 0.85, tw * 0.75, tail_col)
	if stripe != null:
		for k in [1, 3, 5]:
			c.draw_circle(tail[k] - Clay.LIGHT * 0.3, tw * 0.40, stripe)
	if run > 0.3:
		# paws reaching out front and back
		for k in range(4):
			var front := k < 2
			var sd := 1.0 if k % 2 == 0 else -1.0
			var lp := body_c + fwd * (body_half.x * (0.75 if front else -0.7)) + side * sd * body_half.y * 0.85
			c.draw_circle(lp + fwd * sd * (1.6 if front else -1.6) * s, 1.5 * s, base.darkened(0.12))
	# the body, fur on end all round when arched
	if arch > 0.05:
		for k in range(9):
			var ang := TAU * float(k) / 9.0
			var rp := at - fwd + fwd * cos(ang) * body_half.x + side * sin(ang) * body_half.y
			c.draw_circle(rp, 2.0 * s * arch, Clay.rim_of(base))
	Clay.blob(c, body_c, body_half, fwd, base)
	if patch != null:
		Clay.patch(c, body_c - fwd * body_half.x * 0.15 + side * body_half.y * 0.12, body_half * Vector2(0.55, 0.62), fwd, patch)
	if stripe != null:
		for k in range(4):
			var x := body_half.x * (0.40 - float(k) * 0.30)
			var hy := body_half.y * 0.62 * sqrt(maxf(0.0, 1.0 - pow(x / body_half.x, 2.0)))
			c.draw_line(body_c + fwd * x - side * hy, body_c + fwd * (x - 0.9 * s) + side * hy, stripe, 1.1 * s)
	var harness: Variant = coat.get("harness", null)
	if harness != null:
		var sh := body_c + fwd * body_half.x * 0.45
		c.draw_line(sh - side * body_half.y * 0.95, sh + side * body_half.y * 0.95, harness, 1.7 * s)
		c.draw_line(sh, body_c - fwd * body_half.x * 0.25, harness, 1.5 * s)
		c.draw_circle(body_c - fwd * body_half.x * 0.25, 1.1 * s, Color(0.85, 0.85, 0.80))
	# the head: the ears first, so the skull sits over their bases
	var ear_col: Color = patch if patch != null else base
	var ear_tips: Array[Vector2] = []
	for sd: float in [-1.0, 1.0]:
		var e0 := head_c + fwd * 1.6 * s + side * sd * hr * 0.40
		var e1 := head_c - fwd * 2.2 * s + side * sd * hr * 0.70
		var tip := head_c + side * sd * (hr + 2.8 * s) * (1.0 - arch * 0.2) - fwd * (0.4 + arch * 1.5) * s
		ear_tips.append(tip)
		c.draw_colored_polygon(PackedVector2Array([e0, tip, e1]), Clay.rim_of(ear_col))
	Clay.ball(c, head_c, hr, base)
	if patch != null:
		# the cap over her crown
		c.draw_colored_polygon(Clay.ellipse_pts(head_c - fwd * hr * 0.32, Vector2(hr * 0.60, hr * 0.84), fwd, 14), patch)
		if stripe != null:
			for k in range(3):
				var sx := head_c - fwd * hr * (0.05 + 0.25 * float(k))
				c.draw_line(sx - side * hr * 0.22, sx + side * hr * 0.22, stripe, 0.9 * s)
	for i in range(2):
		var sd := -1.0 if i == 0 else 1.0
		var inner := head_c + side * sd * hr * 0.80 - fwd * 0.3 * s
		c.draw_colored_polygon(PackedVector2Array([
			inner + fwd * 1.0 * s, inner.lerp(ear_tips[i], 0.75), inner - fwd * 1.2 * s]), Color(0.90, 0.62, 0.62))
	c.draw_colored_polygon(Clay.ellipse_pts(head_c + fwd * hr * 0.55, Vector2(hr * 0.42, hr * 0.55), fwd, 12), coat.get("muzzle", base.lightened(0.12)))
	c.draw_circle(head_c + fwd * hr * 0.88, 0.75 * s, Color(0.88, 0.50, 0.55))
	var eye: Color = coat.get("eyes", Color(0.85, 0.85, 0.35))
	for sd: float in [-1.0, 1.0]:
		var ep := head_c + fwd * hr * 0.30 + side * sd * hr * 0.42
		c.draw_circle(ep, (1.2 if alert else 1.0) * s, eye)
		c.draw_line(ep - fwd * 0.75 * s, ep + fwd * 0.75 * s, Color(0.06, 0.05, 0.05), (0.9 if alert else 0.5) * s)
