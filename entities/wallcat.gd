extends Node2D

# A wall cat, the signature of El Gotic: a cat perched on a ledge above the
# alley, insufferably smug and just out of reach. As Millie passes it arches
# and hisses; a good BARK sends it leaping off with a yowl. Shooing them is a
# goal. Pure temptation - you can never actually get one (that is the joke).

const NOTICE_R := 100.0

var main: Node2D
var my_dog: Node2D
var spooked := false
var arch := 0.0     # 0..1 how arched-up it is as the dog nears
var leap := 0.0     # animates the bail after a bark
var seed_o := 0.0
var side := 1.0     # which way it bolts


func setup(m: Node2D, mine: Node2D, bolt_dir: float) -> void:
	add_to_group("wallcats")
	main = m
	my_dog = mine
	side = bolt_dir
	seed_o = fmod(absf(position.x) * 0.021, TAU)


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	if spooked:
		leap = minf(1.0, leap + delta * 2.2)
		queue_redraw()
		return
	var near := my_dog.global_position.distance_to(global_position) < NOTICE_R
	arch = move_toward(arch, 1.0 if near else 0.0, delta * 4.0)
	queue_redraw()


func scare() -> void:
	if spooked:
		return
	spooked = true
	main.on_wallcat_spooked(global_position)


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	# the ledge it lords over
	draw_rect(Rect2(-16, 6, 32, 5), Color(0.32, 0.29, 0.26))
	if spooked:
		# leaping away with an indignant yowl
		var off := Vector2(side * 30.0, -46.0) * leap
		var a := 1.0 - leap
		draw_string(ThemeDB.fallback_font, Vector2(-6, -20), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.9, 0.5, a))
		_cat(off, -0.5 * side, a)
		return
	# perched: rises and arches as the dog closes in
	var rise := -arch * 3.0 + sin(t * 2.0 + seed_o) * 0.6
	_cat(Vector2(0, rise), 0.0, 1.0)


func _cat(off: Vector2, tilt: float, a: float) -> void:
	var fur := Color(0.24, 0.22, 0.26, a)
	var back_lift := arch * 4.0
	# body: an arched loaf, higher at the shoulders when arched
	draw_circle(off + Vector2(0, -4 - back_lift * 0.5), 6.0, fur)
	draw_circle(off + Vector2(6, -6 - back_lift), 5.0, fur)
	# head + ears
	draw_circle(off + Vector2(9, -9 - back_lift), 3.5, fur)
	draw_line(off + Vector2(7, -12 - back_lift), off + Vector2(6, -15 - back_lift), fur, 1.5)
	draw_line(off + Vector2(11, -12 - back_lift), off + Vector2(12, -15 - back_lift), fur, 1.5)
	# tail: a question mark, higher when arched or spooked
	draw_arc(off + Vector2(-6, -4), 5.0, 0.4, 3.4 + arch * 1.5, 8, fur, 2.0)
	# eyes catch the light
	draw_circle(off + Vector2(10, -9 - back_lift), 1.0, Color(0.85, 0.9, 0.4, a))
