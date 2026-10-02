extends Node2D

const Clay := preload("res://entities/clay.gd")
const TofuScript := preload("res://entities/tofu.gd")

# A wall cat, the signature of El Gotic: a cat perched on a ledge above the
# alley, insufferably smug and just out of reach. As Millie passes it arches
# and hisses; a good BARK sends it leaping off with a yowl. Shooing them is a
# goal. Pure temptation - you can never actually get one (that is the joke).

const NOTICE_R := 100.0
# alley cats, picked by position so a wall keeps its cat: black, grey tabby,
# ginger tabby
const COATS := [
	{"base": Color(0.17, 0.16, 0.19), "tail": Color(0.17, 0.16, 0.19), "muzzle": Color(0.22, 0.21, 0.24),
		"eyes": Color(0.88, 0.86, 0.30)},
	{"base": Color(0.55, 0.55, 0.57), "stripe": Color(0.33, 0.33, 0.36), "tail": Color(0.55, 0.55, 0.57),
		"muzzle": Color(0.86, 0.85, 0.82), "eyes": Color(0.55, 0.85, 0.40)},
	{"base": Color(0.88, 0.56, 0.27), "stripe": Color(0.70, 0.38, 0.15), "tail": Color(0.88, 0.56, 0.27),
		"muzzle": Color(0.96, 0.86, 0.70), "eyes": Color(0.90, 0.72, 0.25)},
]

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
	var t := AnimClock.msec() / 1000.0
	if Clay.offscreen(self, main):
		return
	var b := ShapeBatch.new(self)
	# the top of the wall it lords over: coping stones, lit along the top edge
	var stone := Color(0.42, 0.37, 0.33)
	b.draw_rect(Rect2(-18, -7, 36, 15), Clay.rim_of(stone))
	b.draw_rect(Rect2(-18, -7, 36, 13), stone)
	b.draw_rect(Rect2(-18, -7, 36, 1.5), Clay.lit_of(stone))
	for k in range(3):
		b.draw_rect(Rect2(-7.0 + float(k) * 12.0, -7, 1, 13), Clay.rim_of(stone))
	var coat: Dictionary = COATS[int(seed_o * 10.0) % COATS.size()]
	var face := Vector2.DOWN
	if my_dog != null:
		var to := my_dog.global_position - global_position
		if to.length() > 1.0:
			face = to.normalized()
	if spooked:
		# leaping away: up towards the camera (bigger) and off over the wall
		var off := Vector2(side * 30.0, -46.0) * leap
		var lift := sin(leap * PI)
		var a := 1.0 - leap
		Clay.ground_shadow(b, Vector2(off.x * 0.6, 4.0), 7.0, 4.0, 2.0 + lift * 6.0, 0.22 * a)
		var faded := coat.duplicate()
		for key: String in ["base", "patch", "stripe", "tail", "eyes", "muzzle"]:
			if faded.has(key):
				faded[key] = Color(faded[key], a)
		TofuScript.draw_cat(b, off, Vector2(side, -0.6), faded, 1.0, 0.6, sin(t * 20.0), true, 1.15 + lift * 0.35)
		b.flush()
		draw_string(ThemeDB.fallback_font, Vector2(-6, -20), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.9, 0.5, a))
		return
	# perched: rises and arches as the dog closes in
	var rise := -arch * 1.5 + sin(t * 2.0 + seed_o) * 0.4
	Clay.ground_shadow(b, Vector2(0, 2), 7.0 + arch, 4.5, 2.5 + arch * 1.5, 0.26)
	TofuScript.draw_cat(b, Vector2(0, rise), face, coat, 0.0, arch, sin(t * 1.5 + seed_o), arch > 0.3, 1.15 + arch * 0.08)
	b.flush()
