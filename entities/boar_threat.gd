extends Node2D

# The wild boar stampede pursuers for Walk 20: Els Senglars (Collserola).
# The sounder charging down the trail line abreast: the mama in the middle,
# a big boar on each flank and the striped piglets between, dust kicked up
# behind them. The same animals are in the walk's film (intro/film_boars.gd),
# seen side on.
# They run as a herd of bodies (systems/chase_squad.gd): each boar charges for
# its place in the line and goes round anything solid, scattering litter, and
# the line slows for whoever is held up. Muck does not bother a boar: they
# run straight through what she left. The catch is theirs: a snout and the
# line while it holds together.
# Implements the standard chase threat interface (setup, advance, caught,
# gap_to, threat_boundary, sweep_junk) so systems/home_chase drives it.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const FUR_DARK := Color(0.18, 0.16, 0.15)
const FUR_BRISTLE := Color(0.28, 0.24, 0.22)
const SNOUT_PINK := Color(0.72, 0.52, 0.50)
const TUSK_WHITE := Color(0.95, 0.94, 0.88)
const EYE_RED := Color(0.85, 0.20, 0.15)
const HOOF_DARK := Color(0.12, 0.10, 0.09)

# Piglet colours (striped rayones)
const PIG_BASE := Color(0.48, 0.38, 0.28)
const PIG_STRIPE := Color(0.75, 0.65, 0.48)
# the sow's coat, as the film has it (intro/film_boars.gd)
const SOW_FUR := Color(0.23, 0.18, 0.15)
const SOW_GRIZZLE := Color(0.44, 0.37, 0.31)
const SOW_BELLY := Color(0.13, 0.10, 0.09)
const SOW_CREST := Color(0.52, 0.44, 0.36)
# half the body's width down its length, rump (top) to shoulders and neck
const BODY_W: Array[Vector2] = [Vector2(3, -50), Vector2(9, -47), Vector2(13, -40), Vector2(16, -28),
	Vector2(20, -12), Vector2(25, 2), Vector2(29, 14), Vector2(27, 22), Vector2(18, 29)]
const SOW_HAIR: Array[Vector2] = [Vector2(12, -30), Vector2(16, -16), Vector2(19, -2), Vector2(21, 10),
	Vector2(9, -20), Vector2(13, 4)]

const INK := Color(0.05, 0.04, 0.06)
const DUST := Color(0.62, 0.50, 0.36)
# the line, west to east: [scale, piglet, how far ahead of the line it runs]
const SOUNDER := [[0.95, false, 0.0], [0.55, true, 6.0], [1.2, false, 10.0], [0.55, true, 4.0], [0.95, false, 0.0]]

const Squad := preload("res://systems/chase_squad.gd")
const BOAR_R := 22.0
const BOAR_REACH := 46.0          # the snout and tusks, ahead of the body
const BOAR_BACK := 50.0
const HELD_SOUNDS := ["SNORT", "squeal", "GRUNT"]
const SURGE := 0.26
const CATCH_UP := 1.35
const JAM_SECS := 3.0

var main: Node2D
var speed := 142.0
var cur_speed := 142.0
var front_y := 0.0
var cx := 640.0
var half := 280.0
var rumble := 0.0
var kind := "boars"
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


func setup(m: Node2D, start_front_y: float, corridor_cx: float, corridor_half: float, boar_speed: float) -> void:
	main = m
	front_y = start_front_y
	cx = corridor_cx
	half = corridor_half
	speed = boar_speed
	cur_speed = boar_speed
	var slots: Array = []
	var mw := half * 0.72
	for i in range(SOUNDER.size()):
		slots.append(lerpf(-mw + 26.0, mw - 26.0, float(i) / float(SOUNDER.size() - 1)))
	squad.setup(slots, Vector2(cx, front_y), BOAR_R, BOAR_REACH, BOAR_BACK)


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

	var lurch := sin(rumble * 1.3) * 0.5 + sin(rumble * 3.1) * 0.3
	var mult := 1.0 + SURGE * lurch
	if gap > 680.0:
		mult = maxf(mult, CATCH_UP)
	cur_speed = speed * mult * squad.pace()
	front_y += cur_speed * delta

	# Check for jams (acorn piles, picnic benches)
	for i in range(jams.size()):
		if front_y >= jams[i].y:
			jam_side = signf(jams[i].x - cx)
			jam_at = jams[i]
			jams.remove_at(i)
			jam_t = JAM_SECS
			jammed_now = true
			break

	# Steer towards dog's x position with heavier inertia
	var target_sway: float = clampf(aim, -half * 0.55, half * 0.55)
	sway_v += (target_sway - sway) * 4.2 * delta
	sway_v *= exp(-2.8 * delta)
	sway += sway_v * delta
	position = Vector2(cx + sway, front_y)
	_run(delta)
	queue_redraw()


func _run(delta: float) -> void:
	if main != null:
		squad.run(main, delta, Vector2(cx + sway, front_y), cur_speed if jam_t <= 0.0 else 0.0, false, HELD_SOUNDS, false, "")


func jammed() -> bool:
	return jam_t > 0.0


func threat_boundary() -> float:
	return squad.front()


# a snout, the line while it holds, or behind the whole herd (whoever slipped
# by went under it, rather than the boars running on home without them)
func caught(p: Vector2) -> bool:
	return squad.caught(p)


func gap_to(p: Vector2) -> float:
	return p.y - squad.front()


func sweep_junk(junk: Array) -> int:
	return squad.sweep_junk(junk)


func _draw() -> void:
	# home_chase keeps the node at (walk_cx, front_y); caught() reads the sway.
	# The line spans what caught() catches (half * 0.72 either side), every
	# snout at the catch line and the bodies running back into its depth.
	var b := ShapeBatch.new(self)
	# the dust they raise, behind each of them
	for i in range(mini(SOUNDER.size(), squad.members.size())):
		var at: Vector2 = (squad.members[i]["pos"] as Vector2) - global_position
		for k in range(3):
			var f := fposmod(rumble * 1.6 + float(i * 3 + k) * 0.31, 1.0)
			b.circle(at + Vector2(sin(float(i * 3 + k) * 2.7) * 18.0, -60.0 - f * 70.0), 14.0 + f * 22.0, Color(DUST, 0.45 * (1.0 - f)))
	# each where it really is (systems/chase_squad.gd); held up, it scrabbles
	for i in range(mini(SOUNDER.size(), squad.members.size())):
		var st: Array = SOUNDER[i]
		var held: bool = float(squad.members[i]["stuck_t"]) > 0.4
		var at: Vector2 = (squad.members[i]["pos"] as Vector2) - global_position
		boar(b, at + Vector2(0.0, BOAR_BACK - 14.0 + float(st[2])), float(st[0]),
			rumble * (30.0 if held else 16.0) + float(i) * 1.3, bool(st[1]))
	b.flush()


# one of the sounder from above, its snout at `snout`, running along `fwd`
# (south, for the stampede), the way
# the film draws the sow side on (intro/film_boars.gd): a heavy wedge, all
# shoulders, the hackles up in a ragged crest down the spine, grizzled flanks,
# ears flat back, the long head ending in the pink snout disc. An adult has
# curved tusks hooking out of the jaw and red eyes glowing under a scowl; a
# piglet has stripes and a piglet's eyes.
static func boar(b: ShapeBatch, snout: Vector2, k: float, phase: float, piglet: bool, fwd := Vector2.DOWN) -> void:
	var fur := PIG_BASE if piglet else SOW_FUR
	# her own frame: x across her, y along her toward the snout, in her units
	var c := snout - fwd * 50.0 * k
	var X := Transform2D(fwd.orthogonal() * k, fwd * k, c)
	var sn := Vector2(0.0, 50.0)
	b.circle(c + Vector2(5.0, 6.0) * k, 30.0 * k, Color(0.05, 0.06, 0.08, 0.24))
	# legs, two pairs, galloping
	var g := sin(phase) * 6.0
	for s in [-1.0, 1.0]:
		b.circle(X * Vector2(s * 20.0, 16.0 + g * s), 6.0 * k, HOOF_DARK)
		b.circle(X * Vector2(s * 15.0, -30.0 - g * s), 5.5 * k, HOOF_DARK)
	# the tail, flicking, a tassel at its end
	var te := X * Vector2(sin(phase * 0.7) * 5.0, -57.0)
	b.line(X * Vector2(0, -47), te, INK, 2.0 * k)
	for s in [-1.0, 0.0, 1.0]:
		b.line(te, te + X.basis_xform(Vector2(s * 2.5, -4.0)), INK, 1.4 * k)
	# the body: a wedge, broad at the shoulders and tapering to the rump
	var ink := PackedVector2Array()
	var body := PackedVector2Array()
	for side in [1.0, -1.0]:
		for i in range(BODY_W.size()):
			var j: int = i if side > 0.0 else BODY_W.size() - 1 - i
			var v: Vector2 = BODY_W[j]
			ink.append(X * Vector2(side * (v.x + 3.0), v.y))
			body.append(X * Vector2(side * v.x, v.y))
	b.polygon(ink, INK)
	b.polygon(body, fur)
	# the light along the near flank, and the dark belly side
	b.polygon(PackedVector2Array([X * Vector2(-6, -40), X * Vector2(-13, -26), X * Vector2(-20, 4),
		X * Vector2(-20, 18), X * Vector2(-8, 4)]), fur.lightened(0.06))
	b.polygon(PackedVector2Array([X * Vector2(8, -40), X * Vector2(15, -26), X * Vector2(24, 6),
		X * Vector2(24, 20), X * Vector2(11, 4)]), fur.darkened(0.22))
	if piglet:
		for sx in [-8.0, 0.0, 8.0]:
			b.line(X * Vector2(sx * 0.6, -40), X * Vector2(sx, 18), PIG_STRIPE, 3.0 * k)
	else:
		# grizzled hair swept back along the flanks
		for i in range(SOW_HAIR.size()):
			var h: Vector2 = SOW_HAIR[i]
			for s in [-1.0, 1.0]:
				var a := X * Vector2(s * h.x, h.y)
				b.line(a, a + X.basis_xform(Vector2(s * 3.0, -9.0)), SOW_GRIZZLE, 1.6 * k)
		# the hackles: a dark ridge down the spine, bristling in spikes that
		# lift and settle with her stride
		var lift := 0.8 + 0.2 * sin(phase * 2.0)
		b.polygon(PackedVector2Array([X * Vector2(-6, 24), X * Vector2(6, 24), X * Vector2(2, -42),
			X * Vector2(-2, -42)]), SOW_BELLY)
		for i in range(9):
			var y := 24.0 - float(i) * 7.4
			var reach := (15.0 - float(i) * 1.1) * lift
			for s in [-1.0, 1.0]:
				var off := 0.0 if s > 0.0 else 3.6
				var tip := X * Vector2(s * reach, y - 7.0 + off)
				b.polygon(PackedVector2Array([X * Vector2(s * 1.0, y + 1.0 + off), tip,
					X * Vector2(s * 0.5, y - 6.0 + off)]), SOW_BELLY)
				# the bristles' pale, grizzled tips catch the light
				b.line(X * Vector2(s * reach * 0.5, y - 3.5 + off), tip, SOW_CREST, 1.6 * k)
	# ears flat back, pointed: she means it
	for s in [-1.0, 1.0]:
		b.polygon(PackedVector2Array([X * Vector2(s * 9, 26), X * Vector2(s * 24, 12),
			X * Vector2(s * 15, 28)]), INK)
		b.polygon(PackedVector2Array([X * Vector2(s * 11, 25), X * Vector2(s * 21, 15),
			X * Vector2(s * 14, 26)]), fur.darkened(0.15))
	# the long head down to the snout, outlined
	b.polygon(PackedVector2Array([X * Vector2(-18, 20), X * Vector2(18, 20), X * Vector2(11, 47),
		X * Vector2(-11, 47)]), INK)
	b.polygon(PackedVector2Array([X * Vector2(-15, 22), X * Vector2(15, 22), X * Vector2(9, 45),
		X * Vector2(-9, 45)]), fur)
	b.circle(X * (sn + Vector2(0, -2)), 9.0 * k, INK)
	b.circle(X * (sn + Vector2(0, -2)), 7.5 * k, SNOUT_PINK)
	b.circle(X * (sn + Vector2(-3, -2)), 1.8 * k, INK)
	b.circle(X * (sn + Vector2(3, -2)), 1.8 * k, INK)
	if piglet:
		for s in [-1.0, 1.0]:
			b.circle(X * Vector2(s * 7, 33), 2.6 * k, Color.WHITE)
			b.circle(X * Vector2(s * 7, 34), 1.5 * k, INK)
		return
	# the tusks: curved, hooking out of the jaw and back, pointed
	for s in [-1.0, 1.0]:
		_tusk(b, X, sn + Vector2(s * 6.0, -9.0), s, 1.25, INK)
		_tusk(b, X, sn + Vector2(s * 6.0, -9.0), s, 1.0, TUSK_WHITE)
	# small red eyes glowing under a heavy scowl, the brows down toward the snout
	for s in [-1.0, 1.0]:
		var e := X * Vector2(s * 8, 33)
		b.glow(e, 9.0 * k, Color(EYE_RED, 0.55), 0.2)
		b.circle(e, 3.2 * k, EYE_RED)
		b.circle(e + X.basis_xform(Vector2(-0.8, 0.8)), 1.0 * k, Color(1.0, 0.85, 0.6))
		b.polygon(PackedVector2Array([X * Vector2(s * 16, 26), X * Vector2(s * 3, 31),
			X * Vector2(s * 4, 34), X * Vector2(s * 15, 30)]), INK)
	# a snort of steam off the snout now and then
	var puff := fposmod(phase * 0.08, 1.0)
	if puff < 0.4:
		b.circle(X * (sn + Vector2(0.0, 10.0 + puff * 30.0)), (4.0 + puff * 14.0) * k, Color(0.95, 0.95, 0.95, 0.5 * (1.0 - puff / 0.4)))




# a tusk from its root at the jaw, in the boar's frame X: out to the side and
# hooking back toward the shoulders, tapering to a point (side on in the
# film, this is the curve seen from above). `grow` past 1 draws its outline.
static func _tusk(b: ShapeBatch, X: Transform2D, root: Vector2, s: float, grow: float, col: Color) -> void:
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in range(7):
		var u := float(i) / 6.0
		var p := root + Vector2(s * u * 13.0, u * 4.0 - u * u * 15.0) * grow
		var d := Vector2(s * 13.0, 4.0 - 30.0 * u).normalized()
		var n := Vector2(-d.y, d.x) * (1.0 - u) * 2.6 * grow
		outer.append(X * (p + n))
		inner.append(X * (p - n))
	inner.reverse()
	outer.append_array(inner)
	b.polygon(outer, col)
