extends Node2D

# The combo-challenge giver (Combo Phase B): a show-off kid on a bench who
# dares you into a bounded trick window as you pass. One offer per walk;
# after that they just cheer (or commiserate). Pure flavour + a proximity
# trigger - the challenge logic and reward live in challenge.gd / main.

const NOTICE_R := 240.0

var main: Node2D
var my_dog: Node2D
var trick_target := 5
var window := 12.0
var fired := false
var result := ""  # "", "win", "lose" once resolved
var seed_o := 0.0


func setup(m: Node2D, mine: Node2D, target: int, seconds: float) -> void:
	add_to_group("challengers")
	main = m
	my_dog = mine
	trick_target = target
	window = seconds
	# derived from position, never the global RNG - spawning this must not
	# desync the deterministic autowalk traversal
	seed_o = fmod(absf(position.x) * 0.017, TAU)


func _physics_process(_delta: float) -> void:
	if main.frozen or fired:
		return
	# only offer while walking out - not mid off-leash romp or the way home
	if main.phase != "out":
		return
	if my_dog.global_position.distance_to(global_position) < NOTICE_R:
		fired = true
		main.start_challenge(self, trick_target, window)


func resolve(win: bool) -> void:
	result = "win" if win else "lose"
	queue_redraw()


func _facing() -> Vector2:
	# they are sitting at the side of the path watching it, so they face the
	# middle of the corridor rather than always east
	if main == null:
		return Vector2.RIGHT
	return Vector2.RIGHT if position.x < main.walk_cx else Vector2.LEFT


func _draw() -> void:
	# Drawn from ABOVE, like every other person in this game. The old version
	# was a side-on cartoon - circle head, rectangle torso, one stick arm -
	# dropped into a top-down world, with no shadow at all, so it read as a
	# sticker rather than as somebody sitting there. Same anatomy language as
	# human.gd now: feet, a body disc, a head with hair on the back of it, all
	# oriented by which way they are facing.
	var t := Time.get_ticks_msec() / 1000.0
	var fd := _facing()
	var side := fd.orthogonal()
	var skin := Color(0.88, 0.73, 0.58)
	var shirt := Color(0.82, 0.28, 0.33)
	var jeans := Color(0.28, 0.34, 0.48)

	# --- the bench, seen from above ---------------------------------------
	# long axis across the path, seat slats visible, back rail on the outside
	var seat_l := 62.0
	if main != null:
		main.cast_shadow(self, -fd * 4.0, 20.0, 16.0, 0.18)
	# back rail, behind the sitter
	draw_colored_polygon(_bar(-fd * 20.0, side, seat_l, 7.0), Color(0.40, 0.29, 0.19))
	# the seat itself
	draw_colored_polygon(_bar(-fd * 6.0, side, seat_l, 22.0), Color(0.54, 0.40, 0.26))
	# slats: three planks with a dark gap between them, which is what stops a
	# bench reading as one brown blob from above
	for s: float in [-7.0, 0.0, 7.0]:
		draw_colored_polygon(_bar(-fd * 6.0 + fd * s, side, seat_l - 4.0, 2.4),
			Color(0.31, 0.22, 0.14, 0.85))
	# legs, tucked under the ends
	for e: float in [-1.0, 1.0]:
		draw_colored_polygon(_bar(side * e * (seat_l * 0.42) - fd * 6.0, side, 7.0, 20.0),
			Color(0.33, 0.24, 0.16))

	# --- the kid ----------------------------------------------------------
	var bob := sin(t * 3.0 + seed_o) * 1.2
	# sat ON the seat rather than perched off its front edge
	var sit := -fd * 7.0 + fd * bob * 0.3
	# legs out in front, feet on the pavement
	for e: float in [-1.0, 1.0]:
		draw_line(sit + side * e * 5.0, sit + side * e * 6.5 + fd * 17.0, jeans, 6.0)
		draw_circle(sit + side * e * 6.5 + fd * 19.0, 3.6, Color(0.22, 0.22, 0.26))
	# body
	draw_circle(sit, 12.5, shirt)
	# the far arm resting along the bench back, the near one up mid-dare
	draw_line(sit + side * 9.0, sit + side * 15.0 - fd * 9.0, skin, 4.5)
	var wave := sit - side * 9.0 + fd * 4.0
	var tip := wave - side * (9.0 + sin(t * 6.0 + seed_o) * 3.0) + fd * 13.0
	draw_line(wave, tip, skin, 4.5)
	draw_circle(tip, 3.2, skin)
	# head, hair on the back of it, cap peak pointing the way they look
	var head := sit + fd * 5.0 + fd * bob * 0.4
	draw_circle(head, 8.0, skin)
	var back := (-fd).angle()
	draw_arc(head, 8.0, back - 1.0, back + 1.0, 12, Color(0.24, 0.17, 0.12), 5.0)
	draw_arc(head, 8.4, back - 1.9, back + 1.9, 16, Color(0.20, 0.36, 0.62), 5.0)
	draw_colored_polygon(_bar(head + fd * 9.0, side, 13.0, 6.0), Color(0.17, 0.31, 0.55))

	# --- what they are shouting -------------------------------------------
	var line := "bet you can't!" if result == "" else ("nice!!" if result == "win" else "heh, next time")
	var col := Color(0.16, 0.15, 0.18)
	var bg := Color(0.97, 0.95, 0.88, 0.95)
	if result == "win":
		bg = Color(0.86, 0.98, 0.86, 0.95)
	_bubble(fd * 26.0 + Vector2(0.0, -40.0), line, bg, col)


func _bar(at: Vector2, side: Vector2, length: float, depth: float) -> PackedVector2Array:
	# an oriented rectangle, so the bench and the cap turn with the sitter
	var fwd := side.orthogonal()
	var h := side * (length * 0.5)
	var d := fwd * (depth * 0.5)
	return PackedVector2Array([at - h - d, at + h - d, at + h + d, at - h + d])


func _bubble(at: Vector2, text: String, bg: Color, fg: Color) -> void:
	# A real speech bubble. The old code had a comment promising one and then
	# drew bare text on the pavement, which is why the dare never looked like
	# somebody saying it.
	var f := ThemeDB.fallback_font
	var w: float = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var box := Rect2(at.x - w * 0.5 - 8.0, at.y - 13.0, w + 16.0, 22.0)
	# a tail down toward whoever is talking, drawn before the body so the
	# join is hidden under it
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(at.x - 5.0, box.end.y - 2.0), Vector2(at.x + 6.0, box.end.y - 2.0),
			Vector2(at.x - 2.0, box.end.y + 9.0),
		]), bg)
	draw_rect(Rect2(box.position.x + 5.0, box.position.y, box.size.x - 10.0, box.size.y), bg)
	draw_rect(Rect2(box.position.x, box.position.y + 5.0, box.size.x, box.size.y - 10.0), bg)
	for c: Vector2 in [
		Vector2(box.position.x + 5.0, box.position.y + 5.0),
		Vector2(box.end.x - 5.0, box.position.y + 5.0),
		Vector2(box.position.x + 5.0, box.end.y - 5.0),
		Vector2(box.end.x - 5.0, box.end.y - 5.0),
	]:
		draw_circle(c, 5.0, bg)
	draw_string(f, Vector2(box.position.x + 8.0, at.y + 5.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, fg)
