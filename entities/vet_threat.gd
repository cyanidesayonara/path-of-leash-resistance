extends Node2D

# The clinic pursuers for Walk 20: El Veterinari.
# A line of clinic staff in scrubs and masks, shoulder to shoulder across the
# corridor, each holding out something a dog dreads: a cone of shame, a
# giant syringe, the nail clippers, a catch net. The same line is in the
# walk's film (intro/film_vet.gd).
# They are on foot (systems/chase_squad.gd): each runs for their place in the
# line and goes round anything solid, kicks litter aside, skids in what she
# left lying, and the line waits for whoever is held up. The catch is theirs:
# a body and what it holds out, and the line while it holds together.
# Implements the standard chase threat interface (setup, advance, caught,
# gap_to, threat_boundary, sweep_junk) so systems/home_chase drives it.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Squad := preload("res://systems/chase_squad.gd")

const SCRUBS_TEAL := Color(0.20, 0.65, 0.60)
const COAT_WHITE := Color(0.94, 0.96, 0.98)
const GLOVES_BLUE := Color(0.30, 0.55, 0.90)
const MASK_CYAN := Color(0.60, 0.85, 0.90)
const HAIR_BROWN := Color(0.35, 0.22, 0.15)
const HAIR_BLONDE := Color(0.85, 0.72, 0.35)
const SKIN_TONE := Color(0.92, 0.76, 0.65)

const CONE_PLASTIC := Color(0.80, 0.90, 0.97, 0.85)
const CONE_INSIDE := Color(0.40, 0.55, 0.72, 0.9)
const CONE_RIM := Color(0.25, 0.45, 0.75)
const NET_MESH := Color(0.80, 0.82, 0.85, 0.55)
const POLE_ALUMINUM := Color(0.70, 0.72, 0.75)
const STETH_GREY := Color(0.2, 0.22, 0.25)
const ELL_N := 16
const SYRINGE_DOSE := Color(0.45, 0.85, 0.40)
const CLIPPER_GRIP := Color(0.85, 0.20, 0.22)
const STAFF_BACK := 70.0         # the line, a stride behind the catch line
# the line, west to east: [what they hold, cap or hair, coat]
const STAFF := [
	["clippers", Color(0.62, 0.30, 0.16), COAT_WHITE],
	["syringe", Color(0.13, 0.46, 0.43), COAT_WHITE],
	["cone", HAIR_BROWN, SCRUBS_TEAL],
	["syringe", HAIR_BLONDE, COAT_WHITE],
	["net", Color(0.16, 0.24, 0.42), COAT_WHITE],
]

const STAFF_R := 24.0
const STAFF_REACH := 54.0         # the cone's mouth, the needle, the net, ahead of the body
const HELD_LINES := ["Excuse us!", "Mind the cone!", "Coming through!", "Hold still, pup!"]
const SURGE := 0.24
const CATCH_UP := 1.35
const JAM_SECS := 3.0

var main: Node2D
var speed := 138.0
var cur_speed := 138.0
var front_y := 0.0
var cx := 640.0
var half := 280.0
var rumble := 0.0
var kind := "vet"
var sway := 0.0
var sway_v := 0.0
var heading := 0.0
var jams: Array[Vector2] = []
var jam_t := 0.0
var jam_side := 0.0
var jam_at := Vector2(INF, INF)
var kerb_blocks: Array[Rect2] = []
var jammed_now := false
var freed_now := false
var squad = Squad.new()


func setup(m: Node2D, start_front_y: float, corridor_cx: float, corridor_half: float, vet_speed: float) -> void:
	main = m
	front_y = start_front_y
	cx = corridor_cx
	half = corridor_half
	speed = vet_speed
	cur_speed = vet_speed
	var slots: Array = []
	var mw := half * 0.75
	for i in range(STAFF.size()):
		slots.append(lerpf(-mw + 30.0, mw - 30.0, float(i) / float(STAFF.size() - 1)))
	squad.setup(slots, Vector2(cx, front_y), STAFF_R, STAFF_REACH, STAFF_BACK)


func advance(delta: float, gap := -1.0, aim := 0.0) -> void:
	rumble += delta
	jammed_now = false
	freed_now = false
	if jam_t > 0.0:
		jam_t -= delta
		cur_speed = 0.0
		if jam_t <= 0.0:
			freed_now = true
		_run(delta)
		return

	var lurch := sin(rumble * 1.1) * 0.5 + sin(rumble * 2.5) * 0.3
	var mult := 1.0 + SURGE * lurch
	# Catch up if the pair is far ahead
	if gap > 680.0:
		mult = maxf(mult, CATCH_UP)
	cur_speed = speed * mult * squad.pace()
	front_y += cur_speed * delta

	# Check for jams (the cat carrier, the scale: a patient needs them)
	for i in range(jams.size()):
		if front_y >= jams[i].y:
			jam_side = signf(jams[i].x - cx)
			jam_at = jams[i]
			jams.remove_at(i)
			jam_t = JAM_SECS
			jammed_now = true
			break

	# Steer towards dog's x position
	var target_sway: float = clampf(aim, -half * 0.5, half * 0.5)
	sway_v += (target_sway - sway) * 5.0 * delta
	sway_v *= exp(-3.0 * delta)
	sway += sway_v * delta
	position = Vector2(cx + sway, front_y)
	_run(delta)
	queue_redraw()


func _run(delta: float) -> void:
	if main != null:
		squad.run(main, delta, Vector2(cx + sway, front_y), cur_speed if jam_t <= 0.0 else 0.0, true, HELD_LINES, true, "Eww!")


func jammed() -> bool:
	return jam_t > 0.0


func threat_boundary() -> float:
	return squad.front()


func caught(p: Vector2) -> bool:
	return squad.caught(p)


func gap_to(p: Vector2) -> float:
	return p.y - squad.front()


func sweep_junk(junk: Array) -> int:
	return squad.sweep_junk(junk)


func _draw() -> void:
	# home_chase keeps the node at (walk_cx, front_y); caught() reads the sway.
	# The line spans what caught() catches (half * 0.75 either side), the
	# staff a stride behind the catch line and what they hold out reaching it.
	# each where they really are (systems/chase_squad.gd): held up, they strain
	var b := ShapeBatch.new(self)
	for i in range(mini(STAFF.size(), squad.members.size())):
		var held: bool = float(squad.members[i]["stuck_t"]) > 0.4
		var bob := sin(rumble * (31.0 if held else 13.0) + float(i) * 1.7) * 3.0
		var at: Vector2 = (squad.members[i]["pos"] as Vector2) - global_position + Vector2(0.0, bob)
		b.circle(at + Vector2(4.0, 8.0), 24.0, Color(0.04, 0.05, 0.08, 0.20))
		var st: Array = STAFF[i]
		_draw_item(b, at + Vector2(0.0, 20.0), String(st[0]), float(i))
		_draw_staff(b, at, st[1], st[2])
	b.flush()


# one of the staff from above: shoulders in a white coat over scrubs, both
# arms out ahead holding the thing, the head with its cap or hair and the
# mask on the face's front (south, toward you)
func _draw_staff(b: ShapeBatch, pos: Vector2, cap: Color, coat: Color) -> void:
	_ellipse(b, pos, Vector2(24.0, 15.0), coat)
	_ellipse(b, pos + Vector2(0.0, 3.0), Vector2(12.0, 9.0), SCRUBS_TEAL)
	for s in [-1.0, 1.0]:
		b.line(pos + Vector2(s * 16.0, 2.0), pos + Vector2(s * 7.0, 20.0), coat, 8.0)
		b.circle(pos + Vector2(s * 7.0, 21.0), 5.0, GLOVES_BLUE)
	b.circle(pos + Vector2(0.0, -2.0), 12.0, SKIN_TONE)
	b.circle(pos + Vector2(0.0, -5.0), 11.0, cap)
	b.rect(Rect2(pos.x - 8.0, pos.y + 4.0, 16.0, 6.0), MASK_CYAN)
	b.line(pos + Vector2(-11.0, 4.0), pos + Vector2(11.0, 4.0), Color(0.95, 0.97, 0.98), 1.5)


# what one of them holds out ahead, from `at` (their hands) toward you
func _draw_item(b: ShapeBatch, at: Vector2, item: String, seed: float) -> void:
	match item:
		"cone":
			b.polygon(PackedVector2Array([at + Vector2(-9, 0), at + Vector2(9, 0), at + Vector2(26, 34), at + Vector2(-26, 34)]),
				CONE_PLASTIC)
			b.line(at + Vector2(-9, 0), at + Vector2(-26, 34), CONE_RIM, 2.5)
			b.line(at + Vector2(9, 0), at + Vector2(26, 34), CONE_RIM, 2.5)
			_ellipse(b, at + Vector2(0, 34), Vector2(26, 8), CONE_INSIDE)
			_ring(b, at + Vector2(0, 34), Vector2(26, 8), CONE_RIM, 4.0)
		"syringe":
			b.rect(Rect2(at.x - 3.0, at.y - 12.0, 6.0, 12.0), Color(0.85, 0.87, 0.90))
			b.rect(Rect2(at.x - 10.0, at.y - 3.0, 20.0, 4.0), Color(0.85, 0.87, 0.90))
			b.rect(Rect2(at.x - 8.0, at.y, 16.0, 40.0), Color(0.92, 0.96, 1.0, 0.85))
			b.rect(Rect2(at.x - 6.0, at.y + 16.0, 12.0, 22.0), SYRINGE_DOSE)
			for k in range(4):
				b.line(Vector2(at.x - 8.0, at.y + 8.0 + float(k) * 8.0), Vector2(at.x - 2.0, at.y + 8.0 + float(k) * 8.0),
					STETH_GREY, 1.2)
			b.line(at + Vector2(0, 40), at + Vector2(0, 62), Color(0.75, 0.78, 0.82), 2.0)
			var drip := fposmod(rumble * 0.8 + seed * 0.3, 1.0)
			b.circle(at + Vector2(0, 64.0 + drip * 8.0), 2.5, Color(SYRINGE_DOSE, 1.0 - drip))
		"clippers":
			var snip := absf(sin(rumble * 9.0 + seed)) * 0.5
			for s in [-1.0, 1.0]:
				b.line(at + Vector2(s * 6.0, -4.0), at + Vector2(0, 14), CLIPPER_GRIP, 6.0)
				b.line(at + Vector2(0, 14), at + Vector2(0, 14) + Vector2.from_angle(PI * 0.5 + s * snip) * 26.0,
					Color(0.80, 0.82, 0.86), 4.0)
			b.circle(at + Vector2(0, 14), 3.5, STETH_GREY)
		"net":
			var hoop := at + Vector2(14.0 + sin(rumble * 6.0 + seed) * 6.0, 46.0)
			b.line(at, hoop, POLE_ALUMINUM, 4.0)
			_ellipse(b, hoop + Vector2(0, 4), Vector2(20, 14), NET_MESH)
			for k in range(3):
				var f := (float(k) + 0.5) / 3.0
				b.line(hoop + Vector2(lerpf(-18.0, 18.0, f), -8.0), hoop + Vector2(lerpf(-10.0, 10.0, f), 16.0),
					Color(0.55, 0.58, 0.62), 1.2)
			_ring(b, hoop, Vector2(20, 10), Color(0.30, 0.35, 0.40), 3.0)


# a filled ellipse, as one polygon
func _ellipse(b: ShapeBatch, at: Vector2, r: Vector2, col: Color) -> void:
	b.polygon(_ell_pts(at, r), col)


# an ellipse's outline, as a run of lines
func _ring(b: ShapeBatch, at: Vector2, r: Vector2, col: Color, w: float) -> void:
	var p := _ell_pts(at, r)
	for i in range(p.size()):
		b.line(p[i], p[(i + 1) % p.size()], col, w)


func _ell_pts(at: Vector2, r: Vector2) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in range(ELL_N):
		p.append(at + Vector2.from_angle(TAU * float(i) / ELL_N) * r)
	return p
