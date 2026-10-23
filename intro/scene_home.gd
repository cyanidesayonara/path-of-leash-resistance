class_name SceneHome
extends RefCounted

# Epilogue short: "Back on the Sofa".
# The narrative bookend to the opening film ("Walkies?", intro/scene_walkies.gd).
# Returning home from a walk: the door opens, Millie and her human come in,
# Millie hops up and hangs the leash loop back on the hook, human collapses
# onto the sofa with a sigh and puts the phone away, and Millie hops up to
# curl up asleep next to them in the afternoon sun.
#
# Reuses the living room, sofa, window light, and puppet rigs from SceneWalkies.

const LENGTH := 8.5
const S := 1.6                 # character scale
const MS := 1.52               # Millie's scale
const FLOOR := 610.0
const SOFA_X := 380.0
const DOOR := Rect2(1060, 250, 150, 360)
const HOOK := Vector2(1010, 320)
const LEASH_LEN := 300.0
const CARRY_LEN := 120.0


static func camera(t: float) -> Array:
	var cx: float = Anim.k(t, [[0.0, 800.0], [2.0, 760.0, "io"], [4.0, 530.0, "io"], [6.5, 490.0, "io"]])
	var cy: float = Anim.k(t, [[0.0, 435.0], [4.5, 450.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.15], [2.5, 1.18, "io"], [5.0, 1.32, "io"]])
	return [Vector2(cx, cy), z]


static func draw(c: CanvasItem, t: float) -> void:
	# 1. Door opening and closing as they enter
	var door_open: float = Anim.k(t, [
		[0.0, 0.0], [0.35, 1.05, "out"], [0.8, 0.95, "io"],
		[1.4, 0.95], [2.2, 0.0, "io"]
	])
	SceneWalkies._room(c, t, door_open)
	SceneWalkies._dressing(c)

	# ---------------------------------------------------------------- Millie
	# Positions & timings
	# 0.0..1.8: Trot in from doorway (1160 -> 840), mouth holding leash loop
	# 1.8..2.2: Turn to face hook (face: -1 -> 1)
	# 2.2..2.8: Jump up to hook, hang loop, land with dust puffs
	# 2.8..3.4: Turn towards sofa (face: 1 -> -1)
	# 3.4..5.0: Trot across floorboards toward sofa (840 -> 520)
	# 5.0..5.6: Jump onto sofa cushion (520, FLOOR -> SOFA_X + 90, FLOOR - 108)
	# 5.6..8.5: Turn, curl up, rest chin, sleep
	var mx: float = Anim.k(t, [
		[0.0, 1160.0], [1.7, 860.0, "io"], [2.1, 980.0, "io"],
		[2.2, 980.0], [2.7, 980.0], [3.2, 940.0, "io"],
		[3.4, 940.0], [4.9, 520.0, "io"], [5.5, SOFA_X + 90.0, "io"]
	])

	var face_raw: float = Anim.k(t, [
		[0.0, -1.0], [1.75, -1.0], [2.05, 1.0, "io"],
		[2.8, 1.0], [3.1, -1.0, "io"],
		[5.7, -1.0], [6.0, 1.0, "io"], [6.3, -1.0, "io"]
	])
	var face := signf(face_raw) * maxf(absf(face_raw), 0.75) if face_raw != 0.0 else -0.75
	var turn_dip := maxf(1.0 - absf(face_raw), 0.0)

	var trot: float = Anim.span(t, 0.1, 0.3) * (1.0 - Anim.span(t, 1.5, 1.7)) \
		+ Anim.span(t, 3.4, 3.6) * (1.0 - Anim.span(t, 4.7, 4.9))

	var air_hook: float = Anim.span(t, 2.25, 2.45) * (1.0 - Anim.span(t, 2.45, 2.68))
	var air_sofa: float = Anim.span(t, 5.0, 5.25) * (1.0 - Anim.span(t, 5.25, 5.55))
	var on_sofa: float = Anim.span(t, 5.5, 5.8)
	var curled: float = Anim.span(t, 6.3, 7.0)

	var pose := {
		"sit": clampf(on_sofa * 0.5 + curled * 0.5, 0.0, 1.0),
		"gait": trot,
		"phase": mx * TAU / (56.0 * MS),
		"crouch": maxf(curled * 0.65, 0.3 * turn_dip),
		"lean": float(Anim.k(t, [
			[2.2, 0.0], [2.4, -0.45, "out"], [2.65, 0.25, "io"], [2.8, 0.0, "io"],
			[5.0, -0.3], [5.3, 0.2], [5.6, 0.0]
		])) - 0.15 * curled,
		"push": air_hook * 0.7 + air_sofa * 0.8,
		"reach": air_hook * 0.7 + air_sofa * 0.8,
		"head_up": float(Anim.k(t, [
			[0.0, 0.2], [1.7, 0.35], [2.35, 0.85, "out"], [2.7, 0.1, "io"],
			[3.5, 0.2], [4.8, 0.1], [5.8, -0.1], [6.5, -0.38, "io"]
		])),
		"ear": 0.25 * trot * sin(t * 14.0) + (0.35 if air_hook > 0.0 else 0.0) - 0.3 * curled,
		"tail": (0.42 * sin(t * 15.0) if t < 2.3 else (0.35 * sin(t * 12.0) if t < 5.2 else (0.22 * sin(t * 6.0) * (1.0 - curled)))),
		"mouth": (0.42 if t < 2.4 else 0.0),
		"brow": (0.6 if t < 2.4 else (-0.4 * curled)),
		"blink": (1.0 if t >= 6.8 or (t > 1.1 and t < 1.18) else 0.0),
	}

	var stretch: float = Anim.k(t, [
		[2.2, 1.0], [2.25, 0.72, "io"], [2.35, 1.22, "snap"], [2.48, 1.05, "out"],
		[2.65, 0.82, "snap"], [2.8, 1.0, "back"],
		[5.0, 0.8], [5.2, 1.15], [5.5, 0.88], [5.8, 1.0]
	])
	var sq: Vector2 = Anim.squash(stretch)

	var ground_y := FLOOR if on_sofa <= 0.0 else lerpf(FLOOR, FLOOR - 108.0, Anim.curve("io", on_sofa))
	var mpos := Vector2(mx, ground_y)
	if air_hook > 0.0:
		var probe := IntroKit.millie_points(Vector2.ZERO, MS, face, sq, pose)
		var peak: Vector2 = HOOK + Vector2(0, 10) - (probe["mouth"] as Vector2)
		var up: float = Anim.curve("out", Anim.span(t, 2.25, 2.45)) * (1.0 - Anim.curve("in", Anim.span(t, 2.45, 2.68)))
		mpos = Vector2(mx, FLOOR).lerp(peak, up)
	elif air_sofa > 0.0:
		var jump_up := sin(Anim.span(t, 5.0, 5.55) * PI) * 55.0
		mpos.y -= jump_up

	var mp := IntroKit.millie_points(mpos, MS, face, sq, pose)

	# --------------------------------------------------------------- Human
	# 0.0..1.8: Walk through door (1300 -> 980)
	# 1.8..3.4: Walk to sofa (980 -> 480)
	# 3.4..4.2: Flop into sofa seat (sit: 0 -> 1, lean, sigh)
	# 4.2..8.5: Sitting comfortably on sofa, phone lowered/away
	var hx: float = Anim.k(t, [
		[0.0, 1300.0], [1.8, 980.0, "io"], [3.4, 460.0, "io"], [3.8, SOFA_X + 20.0, "out"]
	])
	var off_sofa := 1.0 - Anim.span(t, 3.4, 4.0)
	var hy := FLOOR if off_sofa > 0.0 else FLOOR - 18.0

	var hpose := {
		"sit": 1.0 - off_sofa,
		"lean": lerpf(0.12, -0.06, 1.0 - off_sofa) + (0.02 * sin(t * 1.8) if off_sofa <= 0.0 else 0.0),
		"stride": t * 14.0 * off_sofa,
		"phone": lerpf(0.7, 0.0, 1.0 - off_sofa),
		"glow": lerpf(0.6, 0.0, 1.0 - off_sofa),
		"reach": 0.0,
		"blink": (1.0 if fposmod(t, 2.9) < 0.12 else 0.0),
		"mouth": (0.2 if t > 3.8 and t < 4.8 else 0.0),
	}
	var hsq := Vector2.ONE

	# ------------------------------------------------------------------ Draw layers
	SceneWalkies._light(c)
	SceneWalkies._sofa(c)
	SceneWalkies._window_light(c)

	# Human (drawn on sofa or walking in)
	var hand := IntroKit.human(c, Vector2(hx, hy), S, -1.0 if off_sofa > 0.0 else 1.0, hsq, hpose, 0.0, FLOOR)

	# Leash rope
	var hook_pt := HOOK + Vector2(0, 8)
	if t < 2.4:
		# Held in mouth
		IntroKit.rope(c, t, mp["ring"], mp["mouth"], true, CARRY_LEN, FLOOR - 4.0)
	else:
		# Hanging on hook
		IntroKit.rope(c, t, hook_pt, hook_pt + Vector2(5, 0), true, LEASH_LEN, FLOOR - 4.0)

	# Millie puppet
	IntroKit.millie(c, mpos, MS, face, sq, pose, FLOOR if on_sofa <= 0.0 else FLOOR - 108.0)

	# Dust puffs on landing
	if t > 2.65 and t < 3.0:
		IntroKit.puff(c, Vector2(980, FLOOR - 6), 9.0, 1.0 - Anim.span(t, 2.65, 3.0))
		IntroKit.puff(c, Vector2(955, FLOOR - 6), 7.0, 1.0 - Anim.span(t, 2.65, 3.0))
	if t > 5.45 and t < 5.8:
		IntroKit.puff(c, Vector2(SOFA_X + 90, FLOOR - 106), 7.0, 1.0 - Anim.span(t, 5.45, 5.8))

	# Human breath sigh as they collapse into sofa
	if t > 3.8 and t < 4.8:
		IntroKit.breath(c, Vector2(hx + 12, hy - 170), Anim.span(t, 3.8, 4.8), 1.0)

	# Sleeping "Zzz" after curled up
	if t > 7.0:
		var z_t := t - 7.0
		var z_alpha := clampf(z_t * 0.8, 0.0, 0.85)
		var f := ThemeDB.fallback_font
		for zi in range(3):
			var z_age := fmod(z_t * 0.75 + float(zi) * 0.33, 1.0)
			var zp := Vector2(SOFA_X + 60.0 + z_age * 18.0, FLOOR - 130.0 - z_age * 36.0)
			var z_sz := 14 + zi * 3
			c.draw_string(f, zp, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, z_sz, Color(1, 1, 1, z_alpha * (1.0 - z_age)))

	SceneWalkies._sunbeam(c, t)

	# Front door frame jamb when passing through
	if door_open > 0.05:
		SceneWalkies._door_front(c)

	# Smooth scene fade-in at the beginning
	IntroKit.fade(c, 1.0 - Anim.span(t, 0.0, 0.45))
