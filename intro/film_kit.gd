class_name FilmKit
extends RefCounted

# What every chase film shares (intro/film_*.gd, played by
# intro/film_player.gd): one grammar, so each reads as the telegraph to run.
# The two of them heading home side on, your human on the phone; at HEAR_AT
# she hears it (ears up, a jolt over her head) and stops; at LOOK_AT she
# turns to look back at it; at STARE_AT the camera is on her stare; she
# crouches and at BOLT_AT digs in and goes, the leash snapping taut and your
# human yanked off after her; at TITLE_AT the card slams in. Each film draws
# its own place and threat around pair(), and its own camera on these beats.
# The finale's film stands instead of bolting (pair's `stand`): at BOLT_AT she
# dashes back past your human and plants herself between him and it, barking,
# and he is jerked to a stop, still on the phone.

const HEAR_AT := 1.3
const LOOK_AT := 1.6
const STARE_AT := 3.9
const CROUCH_AT := 4.4
const BOLT_AT := 4.85
const TITLE_AT := 5.55
const LENGTH := 6.6
const S := 1.45                  # the pair's scale
const INK := IntroKit.INK


# Your human and her, their feet at `feet`, walking right; returns her
# position (for the threat to aim at and the card to follow).
static func pair(c: CanvasItem, t_real: float, feet: float, stand := false) -> Vector2:
	var t := Anim.twos(t_real)
	var go := Anim.span(t, BOLT_AT, BOLT_AT + 0.1)
	# your human: an oblivious stroll, phone up, then yanked off after her. She
	# goes first and he stays planted until the leash snaps taut, then he is
	# hauled after her a full leash length behind, the leash long and low
	# between them: being dragged, not walking at her heel
	var hx: float = Anim.k(t, [[0.0, 380.0], [BOLT_AT, 560.0], [BOLT_AT + 0.14, 572.0], [TITLE_AT, 1480.0, "in"]])
	var hpose := {
		"stride": t_real * 8.0, "stride_amp": 0.6 * (1.0 - go) + go,
		"phone": 1.0, "glow": 0.5, "reach": 0.4 + 0.6 * go,
		"lean": 0.85 * go, "lift": 0.5 * go, "head": 0.3 * go, "mouth": go,
	}
	var hsq := Vector2(1.2, 0.88) if go > 0.0 else Vector2.ONE
	if stand:
		hx = Anim.k(t, [[0.0, 380.0], [BOLT_AT, 560.0], [BOLT_AT + 0.16, 600.0, "snap"], [TITLE_AT, 600.0]])
		hpose = {
			"stride": t_real * 8.0, "stride_amp": 0.6 * (1.0 - go), "phone": 1.0, "glow": 0.5,
			"reach": 0.4 + 0.3 * go, "lean": -0.25 * go, "phone_jolt": go,
		}
		hsq = Vector2.ONE
	var hand := IntroKit.human(c, Vector2(hx, feet), S, 1.0, hsq, hpose, 0.0, feet)
	# her: trotting ahead, stopped by the sound, looking back at it, the
	# stare, and the spin and dig into the bolt
	var mx: float = Anim.k(t, [[0.0, 600.0], [1.35, 720.0, "out"], [BOLT_AT, 720.0], [BOLT_AT + 0.14, 900.0, "out"],
		[TITLE_AT, 2000.0, "in"]])
	if stand:
		mx = Anim.k(t, [[0.0, 600.0], [1.35, 720.0, "out"], [BOLT_AT, 720.0], [BOLT_AT + 0.22, 400.0, "out"],
			[TITLE_AT, 390.0]])
	var trot := 1.0 - Anim.span(t, 1.2, 1.4)
	var look := Anim.span(t, LOOK_AT, LOOK_AT + 0.15) * (1.0 - Anim.span(t, CROUCH_AT - 0.1, CROUCH_AT))
	var crouch := Anim.span(t, CROUCH_AT, CROUCH_AT + 0.35) * (1.0 - go)
	var stare := Anim.span(t, STARE_AT, STARE_AT + 0.2) * (1.0 - Anim.span(t, CROUCH_AT - 0.1, CROUCH_AT))
	var pose := {
		"lean": 0.22 * crouch + 0.12 * go,
		"crouch": crouch,
		"head_up": Anim.k(t, [[HEAR_AT, 0.0], [HEAR_AT + 0.2, 0.7, "out"], [STARE_AT, 0.5], [STARE_AT + 0.2, 0.2, "io"]]),
		"reach": sin(t_real * 14.0) * 0.6 * trot + go,
		"push": -sin(t_real * 14.0) * 0.6 * trot + 0.4 * crouch + 0.9 * go,
		"ear": Anim.k(t, [[HEAR_AT, 0.0], [HEAR_AT + 0.15, 1.1, "snap"], [STARE_AT, 0.9], [STARE_AT + 0.1, 1.3, "snap"],
			[CROUCH_AT, -0.4, "out"], [BOLT_AT, -0.4], [BOLT_AT + 0.1, 1.2, "snap"]]),
		"tail": sin(t_real * 14.0) * 0.4 * (1.0 - Anim.span(t, HEAR_AT, HEAR_AT + 0.2)) - 0.5 * stare,
		"mouth": 0.6 * stare + 0.8 * go,
		"brow": 1.0 * stare - 1.0 * crouch,
	}
	var face := -1.0 if look > 0.5 else 1.0
	var barking := stand and t > BOLT_AT
	if barking:
		# planted between him and it, low, hackles and tail up, barking
		face = -1.0
		var yap := absf(sin(t_real * 12.0))
		pose["crouch"] = 0.6
		pose["lean"] = 0.25
		pose["reach"] = 0.3
		pose["push"] = 0.5
		pose["ear"] = 1.2
		pose["brow"] = 1.0
		pose["tail"] = 0.7
		pose["mouth"] = 0.4 + 0.5 * yap
	var sq := Anim.squash(Anim.k(t, [[HEAR_AT, 1.0], [HEAR_AT + 0.15, 1.15, "snap"], [LOOK_AT, 1.0, "io"],
		[CROUCH_AT, 1.0], [CROUCH_AT + 0.35, 0.8, "io"], [BOLT_AT, 0.8], [BOLT_AT + 0.08, 1.35, "snap"]]))
	if t > BOLT_AT + 0.05:
		sq = Vector2(1.1, 0.92) if stand else Vector2(1.35, 0.8)
	var mpos := Vector2(mx, feet) + Anim.boil(t_real, 2.0, 0.5)
	var m := IntroKit.millie(c, mpos, S * 0.95, face, sq, pose, feet)
	IntroKit.leash(c, m["ring"], hand, Anim.k(t, [[0.0, 46.0], [BOLT_AT, 40.0], [BOLT_AT + 0.08, 0.0, "snap"]]))
	# the startle: a jolt of lines over her head
	var jolt := Anim.span(t, HEAR_AT, HEAR_AT + 0.3)
	if jolt > 0.0 and jolt < 1.0:
		_jolt(c, mpos + Vector2(10.0 * face, -120.0), jolt)
	if barking:
		# the barks, thrown at it in bursts
		var f := fposmod(t_real * 2.0, 1.0)
		for k in range(3):
			var d := Vector2.from_angle(PI + (float(k) - 1.0) * 0.4)
			var o := mpos + Vector2(-150.0, -110.0)
			c.draw_line(o + d * (10.0 + f * 40.0), o + d * (36.0 + f * 50.0), Color(INK, 1.0 - f), 5.0)
	elif t > BOLT_AT:
		IntroKit.speed_lines(c, mpos + Vector2(-60, -60), Vector2.RIGHT, 170.0)
		IntroKit.speed_lines(c, Vector2(hx, feet - 150.0), Vector2.RIGHT, 120.0, 3)
	return mpos


# a startle: three short strokes fanned over her head
static func _jolt(c: CanvasItem, at: Vector2, f: float) -> void:
	var a := 1.0 - f
	for k in range(3):
		var d := Vector2.from_angle(-PI * 0.5 + (float(k) - 1.0) * 0.55)
		c.draw_line(at + d * (14.0 + f * 10.0), at + d * (34.0 + f * 16.0), Color(INK, a), 4.0)


# the card's word, slammed in big and settling, with a ring of dust under it
static func slam(c: CanvasItem, t: float, word: String, centre: Vector2) -> void:
	var px := int(190.0 * (1.0 + 0.4 * (1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.18))))
	IntroTitle.word(c, word, centre, px, -0.06)
	for k in range(6):
		var a := float(k) / 5.0 * PI
		var f := Anim.span(t, TITLE_AT + 0.1, TITLE_AT + 0.7)
		if f > 0.0 and f < 1.0:
			IntroKit.puff(c, centre + Vector2(0, 80) + Vector2(cos(a) * (280.0 + f * 120.0), sin(a) * 26.0 + 40.0),
				18.0 * (1.0 - f), 1.0 - f)


# the shake as the card lands
static func card_camera(t: float) -> Array:
	var k := 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.3)
	return [Vector2(640, 360) + Vector2(sin(t * 91.0), sin(t * 67.0)) * 9.0 * k * k, 1.0]


# the fade in from the walk and the white flash into the card
static func fades(c: CanvasItem, t_real: float) -> void:
	IntroKit.fade(c, 1.0 - Anim.span(t_real, 0.0, 0.35))
	IntroKit.fade(c, Anim.span(t_real, TITLE_AT - 0.15, TITLE_AT), Color(1.0, 0.95, 0.85))
