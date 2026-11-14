class_name Furgoneta
extends RefCounted

# The FUR-GONETA (Walks 1, 2, 4, 29): a mobile dog grooming van dressed as a
# shaggy dog of our own.
#
# Facelift:
#   - Derpy bobbing pink tongue hanging out over the front bumper with a cleft tip
#   - Fine curving wire whiskers beside the big wet nose
#   - Expressive eyebrow windscreen wipers that angle and sweep
#   - Paw-print silver hubcaps on all four wheels
#   - Side grooming dutch door with warm interior glow and tool silhouette
#   - Brass cartoon horn / megaphone that squashes and honks on bark
#
# Gameplay:
#   - Honk on bark: barking near the van triggers an "AWOOGA!" horn, flashing
#     headlamps and a wiper wiggle; the first honk of a walk pays "van honk! +2",
#     later ones are only the horn
#   - Scent prize: sniffing the van awards the classic +12 bones and "four
#     hundred dogs have been in there"
#   - Style Dare: the groomer offers a 6-tricks-in-20s style dare; winning
#     awards bones, combo points, and the Fresh Coat Grooming Buff (sparkles,
#     bonus trick style points, and clean coat)

const ShapeBatch := preload("res://systems/shape_batch.gd")
const UiIcons := preload("res://hud/ui_icons.gd")
const EventFeed := preload("res://hud/event_feed.gd")


class GroomerGiver extends Node2D:
	var m: Node2D
	var who: String = "kid"

	func setup(main_ref: Node2D) -> void:
		m = main_ref
		position = m.furgoneta

	func dare_number() -> int:
		return 1

	func dare_count() -> int:
		return 1

	func display_name() -> String:
		return "the groomer"

	func has_another_go() -> bool:
		return false

	func resolve(win: bool) -> void:
		Furgoneta.resolve_dare(m, win)


static func tick(m: Node2D, delta: float) -> void:
	if m.furgoneta.x >= INF:
		return
	if m.furgoneta_flash_t > 0.0:
		m.furgoneta_flash_t = maxf(0.0, m.furgoneta_flash_t - delta)
	if m.furgoneta_wiper_t > 0.0:
		m.furgoneta_wiper_t = maxf(0.0, m.furgoneta_wiper_t - delta)
	if m.furgoneta_honk_cd > 0.0:
		m.furgoneta_honk_cd = maxf(0.0, m.furgoneta_honk_cd - delta)
	if m.fresh_coat_t > 0.0:
		m.fresh_coat_t = maxf(0.0, m.fresh_coat_t - delta)
		if m.wet_paws > 0.0:
			m.wet_paws = 0.0

	# Style dare offer (not during autowalk bot or active challenge)
	if m.get("auto_walk") == true:
		return
	if not m.furgoneta_dare_offered and not m.furgoneta_dare_won:
		if m.dog != null and m.challenge != null and not m.challenge.showing() and not m.challenge_offered:
			var d: float = m.dog.global_position.distance_to(m.furgoneta)
			if d < 130.0 and m.dog.velocity.length() < 120.0:
				m.furgoneta_dare_offered = true
				var giver := GroomerGiver.new()
				giver.setup(m)
				m.add_child(giver)
				m.float_text(m.furgoneta + Vector2(0.0, -72.0), "Looking scruffy, pup! Six tricks for a fresh coat?", Color(0.96, 0.94, 0.88), m.POP_SAY)
				m.start_challenge(giver, 6, 20.0)


static func resolve_dare(m: Node2D, win: bool) -> void:
	if win:
		m.furgoneta_dare_won = true
		m.fresh_coat_t = 35.0
		m.float_text(m.furgoneta + Vector2(0.0, -70.0),
			"Fresh and fabulous! Enjoy that sparkling coat!", Color(1.0, 0.95, 0.70), m.POP_SAY)
		m.feed.say("FRESH COAT GROOMED!", EventFeed.Tone.GOOD)
		if m.dog != null:
			m.dog.energy = 1.0
		Sfx.play("dare_won", 1.0, -2.0)
	else:
		m.float_text(m.furgoneta + Vector2(0.0, -70.0),
			"A bit tangled! Come back anytime.", Color(0.96, 0.94, 0.88), m.POP_SAY)


static func on_bark(m: Node2D, pos: Vector2) -> bool:
	if m.furgoneta.x >= INF:
		return false
	if pos.distance_to(m.furgoneta) > 150.0:
		return false
	if m.furgoneta_honk_cd > 0.0:
		return false
	m.furgoneta_honk_cd = 1.1
	m.furgoneta_flash_t = 0.35
	m.furgoneta_wiper_t = 0.65
	Sfx.play("van_horn", 1.0, -2.0)
	var honk_sayings: Array[String] = ["AWOOGA!", "BEEP-BEEP!", "HONK!"]
	var say_text: String = honk_sayings[int(AnimClock.msec() / 800.0) % honk_sayings.size()]
	m.float_text(m.furgoneta + Vector2(0.0, -74.0), say_text, Color(0.98, 0.96, 0.90), m.POP_SAY)
	# one paid honk a walk: the horn is a toy, not a points tap
	if not m.furgoneta_honk_paid:
		m.furgoneta_honk_paid = true
		m.combo.add("BARK", 2)
		m.award_points(2, "van honk! +2")
	return true


static func draw(m: Node2D, v: Vector2, wc: Object = null) -> void:
	if wc == null:
		wc = m.get("_wc")
	if wc == null:
		return
	var fur := Color(0.50, 0.33, 0.19)
	var fur_lit := Color(0.64, 0.45, 0.27)
	var fur_dark := Color(0.33, 0.21, 0.12)
	var cream := Color(0.92, 0.86, 0.74)
	var cream_dk := Color(0.76, 0.69, 0.57)
	var ink := Color(0.40, 0.20, 0.16)
	var body := Rect2(v.x - 32.0, v.y - 66.0, 64.0, 132.0)

	m.box_shadow(wc, body, 14.0, 26.0)

	# --- wheels with paw-print hubcaps ---
	for w: Vector2 in [Vector2(-35, -40), Vector2(29, -40), Vector2(-35, 26), Vector2(29, 26)]:
		wc.draw_colored_polygon(m.round_rect_pts(Rect2(v.x + w.x, v.y + w.y, 6.0, 18.0), 2.5), Color(0.10, 0.10, 0.12))
		var w_c := Vector2(v.x + w.x + 3.0, v.y + w.y + 9.0)
		wc.draw_circle(w_c, 2.5, Color(0.82, 0.84, 0.86))
		UiIcons.draw_paw(wc, w_c, 1.3, Color(0.35, 0.25, 0.18))

	# --- ears: big and floppy down the sides ---
	for sx: float in [-1.0, 1.0]:
		wc.draw_colored_polygon(PackedVector2Array([
			v + Vector2(24.0 * sx, -40.0), v + Vector2(48.0 * sx, -26.0),
			v + Vector2(46.0 * sx, 6.0), v + Vector2(38.0 * sx, 16.0),
			v + Vector2(27.0 * sx, 2.0),
		]), fur_dark)
		wc.draw_colored_polygon(PackedVector2Array([
			v + Vector2(26.0 * sx, -35.0), v + Vector2(42.0 * sx, -24.0),
			v + Vector2(40.0 * sx, 4.0), v + Vector2(36.0 * sx, 10.0),
			v + Vector2(28.0 * sx, -2.0),
		]), fur if sx > 0.0 else fur_lit)
		for tf in range(3):
			var tx := (32.0 + float(tf) * 4.5) * sx
			wc.draw_line(v + Vector2(tx, 6.0 + float(tf)), v + Vector2(tx - 1.5 * sx, 14.0 + float(tf) * 1.5), fur_dark, 2.2)

	# --- the body slab ---
	m.clay_slab(wc, body, 14.0, fur, 3.0)
	wc.draw_colored_polygon(m.round_rect_pts(Rect2(v.x - 31.0, v.y + 22.0, 18.0, 41.0), 9.0), cream_dk)

	# --- side grooming window (dutch door on sidewalk-facing right flank) ---
	wc.draw_colored_polygon(m.round_rect_pts(Rect2(v.x + 28.0, v.y - 14.0, 4.5, 28.0), 1.5), Color(0.24, 0.16, 0.10))
	wc.draw_rect(Rect2(v.x + 29.0, v.y - 12.0, 3.0, 24.0), Color(1.0, 0.92, 0.68, 0.92))
	# scissors & comb silhouette on the grooming sill
	wc.draw_line(Vector2(v.x + 29.5, v.y - 5.0), Vector2(v.x + 31.5, v.y + 1.0), ink, 1.1)
	wc.draw_line(Vector2(v.x + 31.5, v.y - 5.0), Vector2(v.x + 29.5, v.y + 1.0), ink, 1.1)
	wc.draw_line(Vector2(v.x + 30.0, v.y + 4.0), Vector2(v.x + 30.0, v.y + 10.0), ink, 1.2)

	# --- fur curls across roof ---
	for row in range(9):
		var ry := v.y - 26.0 + float(row) * 10.5
		for col in range(6):
			var rx := v.x - 26.0 + float(col) * 10.5 + (5.0 if row % 2 == 0 else 0.0)
			if absf(rx - v.x) < 25.0 and ry > v.y - 25.0 and ry < v.y + 26.0:
				continue
			var on_cream: bool = rx < v.x - 13.0 and ry > v.y + 22.0
			var tc: Color = cream if on_cream else (fur_lit if rx < v.x - 6.0 else fur_dark)
			wc.draw_line(Vector2(rx, ry), Vector2(rx - 3.0, ry + 5.0), tc, 2.0)
			wc.draw_line(Vector2(rx - 3.0, ry + 5.0), Vector2(rx + 1.0, ry + 7.5), tc, 1.6)

	# --- front face (bumper & headlamps) ---
	wc.draw_colored_polygon(m.round_rect_pts(Rect2(v.x - 30.0, v.y - 69.0, 60.0, 8.0), 4.0), Color(0.36, 0.34, 0.33))
	var is_flashing: bool = m.furgoneta_flash_t > 0.0
	var flash_intensity: float = clampf(m.furgoneta_flash_t / 0.35, 0.0, 1.0)
	for hx: float in [-21.0, 21.0]:
		wc.draw_circle(v + Vector2(hx, -64.0), 4.6, Color(0.30, 0.28, 0.26))
		wc.draw_circle(v + Vector2(hx, -64.0), 3.4, Color(0.98, 0.94, 0.78))
		wc.draw_circle(v + Vector2(hx - 1.0, -65.0), 1.2, Color(1, 1, 1))
		if is_flashing:
			wc.draw_circle(v + Vector2(hx, -64.0), 6.5 + flash_intensity * 3.0, Color(1.0, 1.0, 0.85, 0.75 * flash_intensity))
			# soft forward flash beam
			wc.draw_colored_polygon(PackedVector2Array([
				v + Vector2(hx - 4.0, -66.0),
				v + Vector2(hx + 4.0, -66.0),
				v + Vector2(hx * 1.6 + 18.0, -110.0),
				v + Vector2(hx * 1.6 - 18.0, -110.0),
			]), Color(1.0, 0.98, 0.80, 0.18 * flash_intensity))

	# --- muzzle, big wet nose & wire whiskers ---
	m.clay_slab(wc, Rect2(v.x - 17.0, v.y - 66.0, 34.0, 19.0), 9.0, cream, 2.0)
	wc.draw_circle(v + Vector2(0.0, -59.0), 7.5, Color(0.10, 0.09, 0.10))
	wc.draw_circle(v + Vector2(-0.6, -59.8), 6.0, Color(0.17, 0.15, 0.16))
	wc.draw_circle(v + Vector2(-2.6, -62.0), 2.2, Color(0.62, 0.60, 0.62))
	wc.draw_line(v + Vector2(0.0, -52.5), v + Vector2(0.0, -48.5), Color(0.30, 0.22, 0.18), 1.6)

	# Wire whiskers sprouting outwards
	var wcol := Color(0.24, 0.18, 0.14, 0.8)
	wc.draw_line(v + Vector2(-13.0, -59.0), v + Vector2(-25.0, -64.0), wcol, 1.1)
	wc.draw_line(v + Vector2(-14.0, -56.0), v + Vector2(-26.0, -57.0), wcol, 1.1)
	wc.draw_line(v + Vector2(-13.0, -53.0), v + Vector2(-24.0, -50.0), wcol, 1.1)
	wc.draw_line(v + Vector2(13.0, -59.0), v + Vector2(25.0, -64.0), wcol, 1.1)
	wc.draw_line(v + Vector2(14.0, -56.0), v + Vector2(26.0, -57.0), wcol, 1.1)
	wc.draw_line(v + Vector2(13.0, -53.0), v + Vector2(24.0, -50.0), wcol, 1.1)

	# --- The bobbing pink tongue sticking out from bumper ---
	var tongue_bob := sin(AnimClock.msec() / 160.0) * 2.5
	var tongue_tip_y := v.y - 74.0 + tongue_bob
	wc.draw_colored_polygon(PackedVector2Array([
		Vector2(v.x - 4.5, v.y - 67.0),
		Vector2(v.x + 4.5, v.y - 67.0),
		Vector2(v.x + 4.0, tongue_tip_y - 2.0),
		Vector2(v.x + 2.0, tongue_tip_y),
		Vector2(v.x - 2.0, tongue_tip_y),
		Vector2(v.x - 4.0, tongue_tip_y - 2.0),
	]), Color(0.96, 0.58, 0.66))
	# Tongue center cleft crease
	wc.draw_line(Vector2(v.x, v.y - 67.0), Vector2(v.x, tongue_tip_y - 1.0), Color(0.82, 0.42, 0.50), 1.2)
	# Saliva glint
	wc.draw_circle(Vector2(v.x - 1.2, tongue_tip_y - 2.0), 0.9, Color(1.0, 1.0, 1.0, 0.85))

	# --- windscreen & eyes ---
	wc.draw_colored_polygon(PackedVector2Array([v + Vector2(-27, -47), v + Vector2(27, -47),
		v + Vector2(25, -30), v + Vector2(-25, -30)]), Color(0.22, 0.29, 0.36))
	wc.draw_colored_polygon(PackedVector2Array([v + Vector2(-25, -46), v + Vector2(-13, -46),
		v + Vector2(-19, -31), v + Vector2(-24, -31)]), Color(0.58, 0.68, 0.76, 0.5))

	var look := Vector2.ZERO
	if m.dog != null and m.dog.global_position.distance_to(v) < 260.0:
		look = (m.dog.global_position - v).normalized() * 1.6
	for ex: float in [-10.5, 10.5]:
		var ep := v + Vector2(ex, -40.5)
		wc.draw_circle(ep, 6.0, Color(0.20, 0.16, 0.14))
		wc.draw_circle(ep, 5.0, Color(0.98, 0.97, 0.94))
		wc.draw_circle(ep + Vector2(0.4, 1.2) + look, 2.6, Color(0.12, 0.10, 0.10))
		wc.draw_circle(ep + Vector2(-0.6, 0.2) + look, 0.9, Color(1, 1, 1))

	# --- Expressive eyebrow wipers ---
	var wiper_sweep := sin(AnimClock.msec() * 0.028) * 0.35 if m.furgoneta_wiper_t > 0.0 else 0.0
	for sx: float in [-1.0, 1.0]:
		var w_root := v + Vector2(17.0 * sx, -32.0)
		var w_tip := v + Vector2((7.0 + wiper_sweep * 4.0) * sx, -45.0 + absf(wiper_sweep) * 2.0)
		wc.draw_line(w_root, w_tip, Color(0.15, 0.15, 0.18), 1.6)
		# wiper blade angle over the eye
		var blade_perp := (w_tip - w_root).orthogonal().normalized() * 3.5
		wc.draw_line(w_tip - blade_perp, w_tip + blade_perp, Color(0.22, 0.22, 0.25), 2.0)

	# --- fringe over eyes ---
	for i in range(10):
		var fx := v.x - 24.0 + float(i) * 5.4
		var fl := 6.0 + float((i * 7) % 4) * 1.4
		var fc: Color = fur_lit if fx < v.x - 6.0 else fur
		wc.draw_colored_polygon(PackedVector2Array([Vector2(fx - 3.4, v.y - 29.0),
			Vector2(fx + 3.4, v.y - 29.0), Vector2(fx - 1.0, v.y - 29.0 - fl)]), fc)

	# mirrors
	for mx: float in [-1.0, 1.0]:
		wc.draw_colored_polygon(m.round_rect_pts(Rect2(v.x + mx * 37.0 - 3.0, v.y - 47.0, 6.0, 8.0), 2.5), Color(0.28, 0.26, 0.25))

	# --- Cartoon roof brass megaphone / horn ---
	var horn_root := v + Vector2(-28.0, -18.0)
	var horn_pulse: float = 1.25 if is_flashing else 1.0
	wc.draw_circle(horn_root, 3.2 * horn_pulse, Color(0.88, 0.74, 0.28))
	wc.draw_colored_polygon(PackedVector2Array([
		horn_root + Vector2(-2.0, -2.0) * horn_pulse,
		horn_root + Vector2(2.0, -2.0) * horn_pulse,
		horn_root + Vector2(5.0, -12.0) * horn_pulse,
		horn_root + Vector2(-5.0, -12.0) * horn_pulse,
	]), Color(0.92, 0.78, 0.32))
	wc.draw_circle(horn_root + Vector2(0.0, -12.0) * horn_pulse, 4.0 * horn_pulse, Color(0.35, 0.25, 0.12))

	# --- wagging tail on back doors ---
	var wag := sin(AnimClock.msec() / 210.0) * 0.55
	var tail_dir := Vector2(0.0, 1.0).rotated(wag)
	var tail_root := v + Vector2(0.0, 62.0)
	wc.draw_line(tail_root, tail_root + tail_dir * 30.0, fur_dark, 11.0)
	wc.draw_line(tail_root, tail_root + tail_dir * 26.0, fur, 7.0)
	wc.draw_line(tail_root - tail_dir.orthogonal() * 1.5, tail_root + tail_dir * 22.0 - tail_dir.orthogonal() * 1.5, fur_lit, 2.0)
	wc.draw_circle(tail_root + tail_dir * 29.0, 5.5, cream_dk)
	wc.draw_circle(tail_root + tail_dir * 28.0 + Vector2(-1, -1), 4.2, cream)

	# --- roof livery panel ---
	var f_big := 16
	var f_small := 13
	var w_fur: float = m.font.get_string_size("FUR", HORIZONTAL_ALIGNMENT_LEFT, -1, f_big).x
	var w_gon: float = m.font.get_string_size("GONETA", HORIZONTAL_ALIGNMENT_LEFT, -1, f_small).x
	var pw: float = maxf(w_fur + 12.0, w_gon) + 12.0
	var panel := Rect2(v.x - pw * 0.5, v.y - 23.0, pw, 47.0)
	wc.draw_colored_polygon(m.round_rect_pts(panel.grow(1.5), 8.0), Color(0.44, 0.28, 0.17))
	m.clay_slab(wc, panel, 7.0, Color(0.95, 0.91, 0.82), 2.0)

	var bc := v + Vector2(0.0, 30.0)
	wc.draw_line(bc + Vector2(-8, 0), bc + Vector2(8, 0), Color(0.40, 0.26, 0.16), 6.0)
	for bx2: float in [-1.0, 1.0]:
		for by2: float in [-1.0, 1.0]:
			wc.draw_circle(bc + Vector2(9.0 * bx2, 3.2 * by2), 4.4, Color(0.40, 0.26, 0.16))
	wc.draw_line(bc + Vector2(-8, 0), bc + Vector2(8, 0), cream, 3.6)
	for bx2: float in [-1.0, 1.0]:
		for by2: float in [-1.0, 1.0]:
			wc.draw_circle(bc + Vector2(9.0 * bx2, 3.2 * by2), 3.2, cream)

	var fur_x := v.x - (w_fur + 11.0) * 0.5
	UiIcons.draw_paw(wc, Vector2(fur_x + w_fur + 5.5, v.y - 13.0), 4.2, Color(0.66, 0.30, 0.22))
	wc.draw_string(m.font, Vector2(fur_x, v.y - 6.0), "FUR", HORIZONTAL_ALIGNMENT_LEFT, -1,
		f_big, ink)
	wc.draw_string(m.font, Vector2(panel.position.x, v.y + 9.0), "GONETA",
		HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, f_small, ink)
	wc.draw_string(m.font, Vector2(panel.position.x, v.y + 19.0), "dog grooming",
		HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 8, Color(0.52, 0.36, 0.26))

	if not m.furgoneta_sniffed:
		var fg := 0.5 + 0.5 * sin(m.prize_glow * 0.8)
		wc.draw_arc(v, 74.0 + fg * 6.0, 0, TAU, 28, Color(1.0, 0.86, 0.5, 0.10 + fg * 0.07), 2.0)


static func draw_fresh_coat_sparkles(m: Node2D, wc: Object = null) -> void:
	if m == null or m.dog == null or m.fresh_coat_t <= 0.0:
		return
	if wc == null:
		wc = m.get("_wc")
	if wc == null:
		return
	var st: float = AnimClock.msec() * 0.006
	var dp: Vector2 = m.dog.global_position
	for i in range(4):
		var ang: float = st * 3.0 + float(i) * 1.5708
		var rad: float = 16.0 + sin(st * 4.0 + float(i)) * 4.0
		var sp := dp + Vector2(cos(ang), sin(ang) * 0.7) * rad
		var a: float = 0.5 + 0.5 * sin(st * 5.0 + float(i) * 2.0)
		if a > 0.2:
			var sc := Color(1.0, 0.95, 0.70, a * 0.9)
			wc.draw_line(sp - Vector2(3.0, 0), sp + Vector2(3.0, 0), sc, 1.4)
			wc.draw_line(sp - Vector2(0, 3.0), sp + Vector2(0, 3.0), sc, 1.4)
			wc.draw_circle(sp, 1.0, Color.WHITE)
