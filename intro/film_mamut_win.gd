class_name FilmMamutWin
extends RefCounted

# The La Ciutadella victory film, "El Mamut de la Ciutadella":
# The celebratory payoff scene after settling the old park's stone mammoth.
# A bright park morning by the boating lake, side on:
# The boating lake behind, plane trees, the stone plinth, and the mammoth
# who has sat down on the lawn.
# The dog trots up, reaches out, and boops his lowered trunk with a bark!
# A burst of sparks: his amber eye opens wide. Contented, he stands, plods
# back to his plinth and steps up onto the stone.
# On the plinth, he curls his trunk high and trumpets triumphantly, spraying
# a celebratory rainbow fountain into the morning sunlight!
# In the lake, the rower drops oars and claps enthusiastically.
# Your human catches up, smiling warmly.
# Park blossoms drift down, and the celebratory title card slams in:
# EL MAMUT! / VICTÒRIA A LA CIUTADELLA / LA CIUTADELLA IS YOURS.

const LENGTH := FilmKit.LENGTH
const BG := Color(0.62, 0.80, 0.94)
const FEET := 640.0
const PLINTH_X := 160.0
const PLINTH_TOP := FEET - 120.0   # 520.0
const PLINTH_W := 280.0
const MAMUT_SIT_X := 490.0
const MAMUT_K := 0.88

# Timing beats
const BOOP_AT := 1.3
const STAND_AT := 2.0
const CLIMB_AT := 2.5
const ON_PLINTH_AT := 3.25
const TRUMPET_AT := 3.45
const HUMAN_STOP := 2.2
const TITLE_AT := FilmKit.TITLE_AT

# Colors
const INK := IntroKit.INK
const STONE := Color(0.53, 0.49, 0.45)
const STONE_DARK := Color(0.37, 0.34, 0.31)
const STONE_LIT := Color(0.68, 0.64, 0.59)
const FUR := Color(0.45, 0.41, 0.37)
const TUSK := Color(0.93, 0.89, 0.79)
const EYE_AMBER := Color(0.98, 0.80, 0.30)
const PLINTH := Color(0.74, 0.71, 0.65)
const PLINTH_DARK := Color(0.58, 0.55, 0.50)
const LAWN := Color(0.40, 0.60, 0.30)
const GRAVEL := Color(0.80, 0.71, 0.54)
const WATER := Color(0.36, 0.58, 0.70)
const S := 1.45

# Sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[0.2, "whoop", 1.0, -6.0],
	[BOOP_AT, "bark", 1.25, -2.0],
	[BOOP_AT + 0.05, "star", 1.1, -2.0],
	[STAND_AT, "snort", 1.0, -4.0],
	[2.8, "drum", 0.6, -5.0],
	[ON_PLINTH_AT, "drum", 0.4, -1.0],
	[TRUMPET_AT, "mamut_trumpet", 1.2, -2.0],
	[TRUMPET_AT + 0.15, "splash", 0.9, -6.0],
	[3.8, "whoop", 1.2, -3.0],
	[4.3, "whoop", 1.3, -4.0],
	[4.7, "bark", 1.35, -3.0],
	[TITLE_AT, "mamut_trumpet", 0.9, -2.0],
]


static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	var shake := Vector2(sin(t * 89.0), sin(t * 67.0)) * 10.0 * (1.0 - Anim.span(t, ON_PLINTH_AT, ON_PLINTH_AT + 0.35)) \
		if t >= ON_PLINTH_AT else Vector2.ZERO
	if t < STAND_AT:
		# Focused on the sitting mammoth, trunk reach and approaching dog
		return [Vector2(620.0, 460.0), 0.98]
	elif t < ON_PLINTH_AT:
		# Pan back toward the plinth as he climbs
		var f := Anim.span(t, STAND_AT, ON_PLINTH_AT)
		return [Vector2(lerpf(620.0, 480.0, f), lerpf(460.0, 390.0, f)) + shake, lerpf(0.98, 0.88, f)]
	else:
		# Wide celebratory framing: plinth, tall fountain, lake rower, dog and human
		var f := Anim.span(t, ON_PLINTH_AT, TITLE_AT)
		return [Vector2(lerpf(480.0, 500.0, f), 390.0) + shake, lerpf(0.88, 0.85, f)]


static func mamut_at(t: float) -> Vector2:
	if t < CLIMB_AT:
		return Vector2(MAMUT_SIT_X, FEET)
	elif t < ON_PLINTH_AT:
		var f := Anim.span(t, CLIMB_AT, ON_PLINTH_AT)
		var x := lerpf(MAMUT_SIT_X, PLINTH_X, f)
		var y := lerpf(FEET, PLINTH_TOP, f * f) - sin(f * PI) * 36.0
		return Vector2(x, y)
	else:
		return Vector2(PLINTH_X, PLINTH_TOP)


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var t := Anim.twos(t_real)
	_park(c, t_real)
	_plinth(c, t)
	_rower(c, t_real)

	# Mammoth animation parameters
	var sit := 1.0 - Anim.span(t, STAND_AT, CLIMB_AT) if t >= STAND_AT else 1.0
	var awake := Anim.span(t, BOOP_AT, BOOP_AT + 0.25)
	var walking := t >= CLIMB_AT and t < ON_PLINTH_AT
	var trunk := 0.0
	if t >= ON_PLINTH_AT:
		trunk = Anim.span(t, ON_PLINTH_AT, TRUMPET_AT + 0.2)
	elif t >= BOOP_AT:
		trunk = Anim.span(t, BOOP_AT, BOOP_AT + 0.3) * 0.25 * (1.0 - Anim.span(t, STAND_AT, CLIMB_AT))
	var ear := sin(t_real * 24.0) * Anim.span(t, BOOP_AT, BOOP_AT + 0.5)

	var mpos := mamut_at(t)
	var trunk_tip := mamut(c, mpos, MAMUT_K, t_real, awake, walking, trunk, ear, sit)

	# Step dust when climbing onto plinth
	if t >= ON_PLINTH_AT and t < ON_PLINTH_AT + 0.55:
		var f := Anim.span(t, ON_PLINTH_AT, ON_PLINTH_AT + 0.55)
		for k in range(8):
			var a := float(k) / 7.0 * PI
			IntroKit.puff(c, Vector2(PLINTH_X + cos(a) * (140.0 + f * 90.0), PLINTH_TOP - sin(a) * 16.0),
				22.0 * (1.0 - f), 1.0 - f)

	# Celebratory water fountain & rainbow
	if t_real >= TRUMPET_AT:
		_fountain(c, t_real, trunk_tip)
		_rainbow(c, t_real, trunk_tip)

	_dog(c, t_real, trunk_tip)
	_human(c, t_real)

	# Boop spark ring at the trunk tip, drawn over dog and mammoth
	if t_real >= BOOP_AT and t_real < BOOP_AT + 0.6:
		_boop_spark(c, t_real, trunk_tip)

	if t_real >= TRUMPET_AT:
		_petals(c, t_real)

	FilmKit.fades(c, t_real)


# The Ciutadella park in the morning: pale blue sky, far trees, boating lake, lawn and path
static func _park(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-1600, -900.0, 4600, 1000.0 + 200.0), Color(0.62, 0.80, 0.94), Color(0.96, 0.90, 0.78))
	# The far tree line
	for i in range(16):
		var tx := -1500.0 + float(i) * 280.0
		var ty := 170.0 + sin(float(i) * 1.7) * 30.0
		c.draw_circle(Vector2(tx, ty), 150.0, Color(0.30, 0.48, 0.30))
		c.draw_circle(Vector2(tx + 60.0, ty - 50.0), 100.0, Color(0.36, 0.56, 0.34))
	# The boating lake
	c.draw_rect(Rect2(-1600, 300.0, 4600, 170.0), WATER)
	for i in range(30):
		var wx := -1500.0 + float(i) * 150.0 + sin(t * 0.8 + float(i)) * 10.0
		c.draw_line(Vector2(wx, 340.0 + float(i % 3) * 40.0), Vector2(wx + 60.0, 340.0 + float(i % 3) * 40.0),
			Color(0.70, 0.86, 0.94, 0.6), 4.0)

	# The lawn and gravel path
	c.draw_rect(Rect2(-1600, 470.0, 4600, FEET - 470.0 + 10.0), LAWN)
	c.draw_rect(Rect2(-1600, FEET - 40.0, 4600, 600.0), GRAVEL)
	for px in range(-20, 40):
		c.draw_circle(Vector2(float(px) * 77.0 + float(px % 3) * 13.0, FEET + 20.0 + float(px % 4) * 26.0),
			4.0, GRAVEL.darkened(0.15))

	# Plane tree at the far right
	c.draw_line(Vector2(1180.0, FEET), Vector2(1170.0, 60.0), Color(0.62, 0.58, 0.48), 46.0)
	for k in range(5):
		c.draw_circle(Vector2(1170.0 + float(k % 2) * 10.0, 160.0 + float(k) * 90.0), 12.0, Color(0.80, 0.78, 0.66))
	c.draw_circle(Vector2(1170.0, 0.0), 230.0, Color(0.34, 0.54, 0.30))


static func _plinth(c: CanvasItem, _t: float) -> void:
	var r := Rect2(PLINTH_X - PLINTH_W * 0.5, PLINTH_TOP, PLINTH_W, FEET - PLINTH_TOP + 10.0)
	c.draw_rect(r.grow(4.0), INK)
	c.draw_rect(r, PLINTH)
	c.draw_rect(Rect2(r.position, Vector2(r.size.x, 18.0)), PLINTH.lightened(0.12))
	c.draw_rect(Rect2(Vector2(r.position.x - 8.0, FEET - 18.0), Vector2(r.size.x + 16.0, 22.0)), PLINTH_DARK)
	# Inscribed bronze plaque
	var plaque := Rect2(PLINTH_X - 55.0, PLINTH_TOP + 40.0, 110.0, 36.0)
	c.draw_rect(plaque, Color(0.38, 0.28, 0.16))
	c.draw_rect(plaque.grow(-3.0), Color(0.64, 0.50, 0.28))


# The rower in the lake boat: calmly floating, then clapping vigorously when the mammoth is back up!
static func _rower(c: CanvasItem, t: float) -> void:
	var clapping := t >= ON_PLINTH_AT
	var rock := sin(t * 2.0) * 2.5
	if clapping:
		rock += sin((t - ON_PLINTH_AT) * 7.0) * 4.0
	var bx := 680.0
	var by := 390.0 + rock

	# Gentle water ripple under the boat
	c.draw_line(Vector2(bx - 110, by + 22), Vector2(bx + 115, by + 22), Color(0.70, 0.86, 0.94, 0.65), 3.0)

	# Boat hull
	c.draw_colored_polygon(PackedVector2Array([Vector2(bx - 95, by - 14), Vector2(bx + 105, by - 14),
		Vector2(bx + 72, by + 24), Vector2(bx - 72, by + 24)]), Color(0.52, 0.30, 0.18))
	c.draw_rect(Rect2(bx - 95, by - 20, 200, 7), Color(0.66, 0.42, 0.24))

	var jump := absf(sin((t - ON_PLINTH_AT) * 11.0)) * 5.0 if clapping else 0.0
	var body_top := by - 68.0 - jump

	# Torso (red jacket with white collar)
	c.draw_rect(Rect2(bx - 14, body_top, 28, 48), Color(0.86, 0.32, 0.28))
	c.draw_rect(Rect2(bx - 8, body_top, 16, 8), Color(0.96, 0.94, 0.92))
	# Head and cap
	c.draw_circle(Vector2(bx, body_top - 14), 14.0, Color(0.92, 0.76, 0.62))
	c.draw_circle(Vector2(bx, body_top - 20), 13.0, Color(0.36, 0.22, 0.12))
	# Smiling face dot
	c.draw_circle(Vector2(bx - 4, body_top - 14), 2.0, INK)

	if not clapping:
		# Holding oars resting in the water
		c.draw_line(Vector2(bx + 10, by - 40), Vector2(bx + 115, by + 12), Color(0.72, 0.58, 0.36), 5.5)
		c.draw_line(Vector2(bx - 10, by - 40), Vector2(bx - 115, by + 12), Color(0.72, 0.58, 0.36), 5.5)
	else:
		# Oars rest flat across gunwales
		c.draw_line(Vector2(bx - 105, by - 12), Vector2(bx + 115, by - 12), Color(0.72, 0.58, 0.36), 4.5)
		# Clapping hands together energetically
		var clap_cycle := absf(sin((t - ON_PLINTH_AT) * 15.0))
		var hands := Vector2(bx, body_top + 18.0 - clap_cycle * 8.0)
		var sh_l := Vector2(bx - 13, body_top + 10)
		var sh_r := Vector2(bx + 13, body_top + 10)
		var elb_l := Vector2(bx - 22, body_top + 20)
		var elb_r := Vector2(bx + 22, body_top + 20)
		c.draw_polyline(PackedVector2Array([sh_l, elb_l, hands]), INK, 8.0)
		c.draw_polyline(PackedVector2Array([sh_l, elb_l, hands]), Color(0.86, 0.32, 0.28), 6.0)
		c.draw_polyline(PackedVector2Array([sh_r, elb_r, hands]), INK, 8.0)
		c.draw_polyline(PackedVector2Array([sh_r, elb_r, hands]), Color(0.86, 0.32, 0.28), 6.0)
		c.draw_circle(hands, 5.0, Color(0.92, 0.76, 0.62))
		# Applause star burst when hands strike
		if clap_cycle < 0.25:
			for k in range(4):
				var a := float(k) * (TAU / 4.0) + PI * 0.25
				c.draw_line(hands + Vector2.from_angle(a) * 5.0,
					hands + Vector2.from_angle(a) * 15.0, Color(1.0, 1.0, 0.8), 2.5)


# The mammoth side on: domed body, column legs, high head, tusks, trunk and ear.
# `sit` blends from standing (0.0) to sitting on haunches (1.0).
# Returns the world coordinates of the trunk tip.
static func mamut(c: CanvasItem, at: Vector2, k: float, t: float, awake: float, walking: bool,
		trunk: float, ear := 0.0, sit := 0.0) -> Vector2:
	var p := func(v: Vector2) -> Vector2: return at + v * k
	c.draw_colored_polygon(MillieSide.ellipse(at + Vector2(0, 4) * k, Vector2(230, 16) * k), Color(0, 0, 0, 0.35))

	# Legs: hind legs fold on the ground when sitting; front legs stay planted
	for i in range(4):
		var hip: Vector2
		var foot: Vector2
		if i == 0 or i == 2:
			# Rear legs
			var hip_stand := Vector2(-130, -100) if i == 0 else Vector2(-96, -100)
			var hip_sit := Vector2(-130, -50) if i == 0 else Vector2(-96, -50)
			hip = hip_stand.lerp(hip_sit, sit)
			var swing := sin(t * 5.0 + float(i) * 1.6) * 0.18 if walking else 0.0
			var foot_stand := hip_stand + Vector2.from_angle(PI * 0.5 + swing) * 96.0
			var foot_sit := Vector2(-70.0 if i == 0 else -50.0, -4.0)
			foot = foot_stand.lerp(foot_sit, sit)
		else:
			# Front legs
			var hip_stand := Vector2(90, -100) if i == 1 else Vector2(124, -100)
			var hip_sit := Vector2(90, -70) if i == 1 else Vector2(124, -70)
			hip = hip_stand.lerp(hip_sit, sit)
			var swing := sin(t * 5.0 + float(i) * 1.6) * 0.18 if walking else 0.0
			var foot_stand := hip_stand + Vector2.from_angle(PI * 0.5 + swing) * 96.0
			var foot_sit := hip_sit + Vector2(0.0, 66.0)
			foot = foot_stand.lerp(foot_sit, sit)

		var col := STONE_DARK if i < 2 else STONE
		c.draw_line(p.call(hip), p.call(foot), INK, 100.0 * k)
		c.draw_line(p.call(hip), p.call(foot), col, 92.0 * k)
		c.draw_colored_polygon(MillieSide.ellipse(p.call(foot), Vector2(50, 16) * k), col.darkened(0.1))
		for n in range(3):
			c.draw_circle(p.call(foot + Vector2(-24.0 + float(n) * 24.0, -6.0)), 8.0 * k, TUSK.darkened(0.15))

	# The body: domed back, lowered and tilted back slightly when sitting
	var bc_stand := Vector2(-10, -230)
	var bc_sit := Vector2(-25, -180)
	var bc := bc_stand.lerp(bc_sit, sit)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(bc), Vector2(226, 156) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(bc), Vector2(220, 150) * k), STONE)
	# Shaggy fringe hanging at the bottom of the body
	for i in range(16):
		var fx := -200.0 + float(i) * 27.0
		var fy := -100.0 + absf(float(i) - 7.5) * 5.0 + sit * 50.0
		c.draw_colored_polygon(PackedVector2Array([p.call(Vector2(fx - 18, fy - 40)),
			p.call(Vector2(fx + 18, fy - 40)),
			p.call(Vector2(fx + 4, fy + 8 + float(i % 3) * 8.0))]), FUR.darkened(0.08))
	c.draw_colored_polygon(MillieSide.ellipse(p.call(bc + Vector2(-40, -70)), Vector2(130, 56) * k), STONE_LIT)
	for i in range(7):
		var sx := -150.0 + float(i) * 45.0
		c.draw_line(p.call(bc + Vector2(sx, -60)), p.call(bc + Vector2(sx + 10, 40)), FUR.darkened(0.15), 4.0 * k)
	c.draw_circle(p.call(bc + Vector2(70, -40)), 14.0 * k, Color(0.40, 0.52, 0.30, 0.6))

	# The head: high and domed, slightly lowered when sitting
	var hc_stand := Vector2(200, -320)
	var hc_sit := Vector2(185, -270)
	var hc := hc_stand.lerp(hc_sit, sit)
	c.draw_circle(p.call(hc), 104.0 * k, INK)
	c.draw_circle(p.call(hc), 98.0 * k, STONE)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(hc + Vector2(-10, -50)), Vector2(70, 40) * k), STONE_LIT)
	var ec := hc + Vector2(-50, 10)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(ec), Vector2(34, 46 + ear * 6.0) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(ec), Vector2(28, 40 + ear * 6.0) * k), FUR)

	# The eye: shut stone lid, opening wide to bright amber at the boop
	var eye := hc + Vector2(40, -14)
	if awake <= 0.0:
		c.draw_line(p.call(eye + Vector2(-14, 0)), p.call(eye + Vector2(14, 2)), INK, 5.0 * k)
	else:
		c.draw_circle(p.call(eye), 24.0 * k * awake, Color(1.0, 0.78, 0.3, 0.25))
		c.draw_colored_polygon(MillieSide.ellipse(p.call(eye), Vector2(13, 11 * awake) * k), INK)
		c.draw_colored_polygon(MillieSide.ellipse(p.call(eye), Vector2(10, 8 * awake) * k), EYE_AMBER)
		c.draw_circle(p.call(eye + Vector2(2, 0)), 4.0 * k, INK)
		c.draw_line(p.call(eye + Vector2(-18, -20)), p.call(eye + Vector2(18, -12)), INK, 6.0 * k)

	# The trunk: hanging down towards the lawn, reaching forward when sitting, or curled high to trumpet
	var trunk_pts := PackedVector2Array()
	for i in range(12):
		var f := float(i) / 11.0
		var hang_stand := Vector2(80.0 + f * 40.0 + sin(f * PI) * 20.0, 60.0 + f * 220.0 - f * f * 40.0)
		var hang_sit := Vector2(80.0 + f * 180.0, 60.0 + f * 150.0 - sin(f * PI * 0.8) * 25.0)
		var hang := hang_stand.lerp(hang_sit, sit)
		var up := Vector2(80.0 + f * 160.0, 40.0 - f * 260.0 + f * f * 60.0)
		trunk_pts.append(p.call(hc + hang.lerp(up, trunk)))
	c.draw_polyline(trunk_pts, INK, 50.0 * k)
	c.draw_polyline(trunk_pts, STONE, 42.0 * k)
	for i in range(2, 11, 2):
		c.draw_circle(trunk_pts[i], 6.0 * k, STONE_DARK)

	# The tusk: curving out and curling up, on the near side over the trunk
	var tusk := PackedVector2Array()
	for i in range(10):
		var f := float(i) / 9.0
		tusk.append(p.call(hc + Vector2(60.0 + f * 150.0, 60.0 + sin(f * PI * 0.9) * 90.0 - f * f * 150.0)))
	c.draw_polyline(tusk, INK, 26.0 * k)
	c.draw_polyline(tusk, TUSK, 18.0 * k)

	return trunk_pts[11]


# The dog: trots in from the right, reaches snout up to boop his trunk, then stands proud barking
static func _dog(c: CanvasItem, t: float, trunk_tip: Vector2) -> void:
	var mx: float
	var my := FEET
	var face := -1.0
	var trot := 0.0
	var boop_stretch := 0.0
	var proud := 0.0

	var dog_target_x := trunk_tip.x + 114.0

	if t < BOOP_AT:
		mx = Anim.k(t, [[0.0, 1020.0], [BOOP_AT - 0.2, dog_target_x + 10.0, "io"], [BOOP_AT, dog_target_x]])
		trot = 1.0 - Anim.span(t, BOOP_AT - 0.3, BOOP_AT)
		face = -1.0
	elif t < STAND_AT:
		mx = dog_target_x
		boop_stretch = Anim.span(t, BOOP_AT, BOOP_AT + 0.18) * (1.0 - Anim.span(t, BOOP_AT + 0.35, STAND_AT))
		face = -1.0
	else:
		mx = lerpf(dog_target_x, 700.0, Anim.span(t, STAND_AT, CLIMB_AT))
		proud = 1.0
		face = -1.0

	var yap := absf(sin(t * 14.0)) if (proud > 0.0 and t >= TRUMPET_AT) or boop_stretch > 0.5 else 0.0
	var pose := {
		"gait": trot,
		"phase": mx * TAU / (48.0 * S),
		"crouch": 0.15 * boop_stretch,
		"lean": -0.25 * boop_stretch + 0.1 * proud,
		"reach": 0.55 * boop_stretch + 0.1 * trot,
		"push": 0.35 * boop_stretch + 0.1 * trot,
		"head_up": 0.45 * boop_stretch + 0.65 * proud,
		"ear": 1.2 * proud + 0.9 * boop_stretch,
		"tail": 0.7 * proud + sin(t * 18.0) * 0.35 * proud + sin(t * 12.0) * 0.3 * trot,
		"mouth": 0.3 + 0.6 * yap if (proud > 0.0 or boop_stretch > 0.0) else 0.0,
		"brow": 0.7 * proud + 0.5 * boop_stretch,
	}

	var sq := Anim.squash(1.0 + 0.15 * boop_stretch)
	IntroKit.millie(c, Vector2(mx, my), S * 1.05, face, sq, pose, FEET)


# The human: strolls up behind the dog, pauses and smiles at the good mammoth
static func _human(c: CanvasItem, t: float) -> void:
	var hx: float = Anim.k(t, [[0.0, 1260.0], [HUMAN_STOP, 1080.0, "io"], [LENGTH, 1080.0]])
	var walking := t < HUMAN_STOP
	var proud_human := Anim.span(t, TRUMPET_AT, TRUMPET_AT + 0.5)

	var hpose := {
		"stride": t * 7.5 if walking else 0.0,
		"stride_amp": 0.7 if walking else 0.0,
		"phone": 1.0,
		"glow": 0.4 if t < HUMAN_STOP else 0.1,
		"reach": 0.35 + 0.3 * proud_human,
		"lean": 0.1 * proud_human,
		"head": -0.25 * proud_human,
		"mouth": 0.8 * proud_human,
	}

	IntroKit.human(c, Vector2(hx, FEET), S, -1.0, Vector2.ONE, hpose, 0.0, FEET)


static func _boop_spark(c: CanvasItem, t: float, boop_pos: Vector2) -> void:
	var dt := t - BOOP_AT
	var f := clampf(dt / 0.55, 0.0, 1.0)

	# Expanding star and golden glow ring
	var r := 48.0 * sin(f * PI * 0.5)
	c.draw_arc(boop_pos, r, 0.0, TAU, 24, Color(1.0, 0.90, 0.35, (1.0 - f) * 0.85), 3.0)
	for i in range(8):
		var a := float(i) * (TAU / 8.0)
		var pt := boop_pos + Vector2.from_angle(a) * r
		c.draw_circle(pt, 3.5 * (1.0 - f), Color(1.0, 1.0, 0.85, 1.0 - f))


# The celebratory fountain spraying from the raised trunk on the plinth
static func _fountain(c: CanvasItem, t: float, tip: Vector2) -> void:
	var dt := t - TRUMPET_AT

	for i in range(32):
		var seed := float(i) * 0.10
		var life := fmod(dt + seed, 1.25)
		if dt >= seed:
			var spd := 240.0 + sin(float(i) * 2.3) * 45.0
			var ang := -PI * 0.40 + sin(float(i) * 1.7) * 0.20
			var drop_pos := tip + Vector2(cos(ang) * spd * life, sin(ang) * spd * life + 190.0 * life * life)
			var drop_alpha := clampf((1.0 - life / 1.25) * 0.95, 0.0, 1.0)
			c.draw_circle(drop_pos, 4.5 * (1.0 - life * 0.4), Color(0.60, 0.84, 0.98, drop_alpha))
			c.draw_circle(drop_pos + Vector2(1, -1), 2.0 * (1.0 - life * 0.4), Color(1.0, 1.0, 1.0, drop_alpha * 0.8))


# A shimmering rainbow arc over the water fountain
static func _rainbow(c: CanvasItem, t: float, tip: Vector2) -> void:
	var dt := t - TRUMPET_AT
	var f := clampf(Anim.span(dt, 0.2, 0.6) * (1.0 - Anim.span(t, TITLE_AT - 0.2, TITLE_AT)), 0.0, 1.0) * 0.32
	var arc_center := tip + Vector2(70.0, 50.0)

	var r_colors: Array[Color] = [
		Color(0.96, 0.30, 0.30), Color(0.96, 0.62, 0.22), Color(0.96, 0.90, 0.24),
		Color(0.28, 0.82, 0.40), Color(0.22, 0.68, 0.96), Color(0.62, 0.32, 0.92)
	]
	for i in range(r_colors.size()):
		var col: Color = r_colors[i]
		c.draw_arc(arc_center, 120.0 + float(i) * 7.0, -PI * 0.88, -PI * 0.12, 32,
			Color(col.r, col.g, col.b, f), 5.0)


# Park blossom petals drifting in the sun
static func _petals(c: CanvasItem, t: float) -> void:
	var dt := t - TRUMPET_AT
	var cols := [Color(0.98, 0.82, 0.86), Color(0.98, 0.92, 0.50), Color(0.72, 0.88, 0.98), Color(0.85, 0.96, 0.75)]
	for i in range(32):
		var seed_i := float(i) * 113.7
		var cx := fmod(seed_i * 17.1, 1280.0)
		var cy := fmod(seed_i * 29.3 + dt * (120.0 + sin(seed_i) * 40.0), 720.0)
		var rot := dt * 3.5 + seed_i
		var col: Color = cols[i % 4]
		var sz := Vector2(8.0, 5.0)
		c.draw_set_transform(Vector2(cx, cy), rot, Vector2.ONE)
		c.draw_rect(Rect2(-sz * 0.5, sz), col)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 824.0), Color(0.95, 0.98, 0.88), Color(0.48, 0.64, 0.42))
	var d := t - TITLE_AT
	# Offset further to the left so text is completely unobstructed
	mamut(c, Vector2(-480.0 + d * 50.0, 1240.0), 1.8, t, 1.0, false, 1.0, 0.0, 0.0)
	FilmKit.slam(c, t, "EL MAMUT!", Vector2(640, 210))
	IntroTitle.word(c, "VICTORIA A LA CIUTADELLA", Vector2(640, 410), 46)
	IntroTitle.word(c, "LA CIUTADELLA IS YOURS", Vector2(640, 480), 30)
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.25), Color(1.0, 0.98, 0.90))
