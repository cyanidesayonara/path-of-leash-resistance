class_name Furgoneta
extends RefCounted

# The FUR-GONETA (Walks 1, 2, 4, 29): a mobile dog grooming van that is a
# great shaggy dog, asleep on its own wheels until you look at it.
#
# What you see from above, front to back: the bumper with its tongue out and
# a nose for a badge; the windscreen, where its eyes follow the dog, under
# wiper eyebrows and a combed fringe; ears down over the front wings; a
# turquoise collar with its gold tag; the freshly washed half of its coat,
# fluffy and cream, with the signwriting on a bone-shaped board; the half
# still to do, shaggy and brown; suds coming off the roof vent; a pompom tail
# on the back doors. The coat hangs past the body on both sides, all of it
# locks combed back from the face.
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

	# main plays a dare giver's own tune while the clock runs
	func tune() -> String:
		return "dare_" + who

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
				m.float_text(m.furgoneta + Vector2(0.0, -72.0), I18n.t("w_looking_scruffy_pup_six_tricks_for_a"), Color(0.96, 0.94, 0.88), m.POP_SAY)
				m.start_challenge(giver, 6, 20.0)


static func resolve_dare(m: Node2D, win: bool) -> void:
	if win:
		m.furgoneta_dare_won = true
		m.fresh_coat_t = 35.0
		m.float_text(m.furgoneta + Vector2(0.0, -70.0),
			I18n.t("w_fresh_and_fabulous_enjoy_that"), Color(1.0, 0.95, 0.70), m.POP_SAY)
		m.feed.say(I18n.t("w_fresh_coat_groomed"), EventFeed.Tone.GOOD)
		if m.dog != null:
			m.dog.energy = 1.0
		Sfx.play("dare_won", 1.0, -2.0)
	else:
		m.float_text(m.furgoneta + Vector2(0.0, -70.0),
			I18n.t("w_a_bit_tangled_come_back_anytime"), Color(0.96, 0.94, 0.88), m.POP_SAY)


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
	var honk_sayings: Array[String] = ["AWOOGA!", I18n.t("w_beep_beep"), I18n.t("w_honk")]
	var say_text: String = honk_sayings[int(AnimClock.msec() / 800.0) % honk_sayings.size()]
	m.float_text(m.furgoneta + Vector2(0.0, -74.0), say_text, Color(0.98, 0.96, 0.90), m.POP_SAY)
	# one paid honk a walk: the horn is a toy, not a points tap
	if not m.furgoneta_honk_paid:
		m.furgoneta_honk_paid = true
		m.combo.add("BARK", 2)
		m.award_points(2, I18n.t("w_van_honk_2"))
	return true


const COAT := Color(0.60, 0.40, 0.23)
const COAT_LIT := Color(0.78, 0.56, 0.34)
const COAT_DK := Color(0.38, 0.23, 0.13)
const CLEAN := Color(0.94, 0.86, 0.70)
const CLEAN_LIT := Color(1.0, 0.96, 0.86)
const CLEAN_DK := Color(0.76, 0.64, 0.47)
const COLLAR := Color(0.12, 0.62, 0.60)
const TAG := Color(0.97, 0.78, 0.28)
const NOSE := Color(0.11, 0.09, 0.11)
const GLASS := Color(0.16, 0.22, 0.30)
const PINK := Color(0.97, 0.58, 0.66)
const INK := Color(0.30, 0.17, 0.13)
const WASHED_Y := 30.0           # the coat is clean from the collar to here

static var _still := {}


static func _h(k: int) -> float:
	return fposmod(sin(float(k) * 127.1) * 43758.5453, 1.0)


# One lock of hair from its root, combed along `d`: a leaf with a lit side.
static func _lock(b: ShapeBatch, root: Vector2, d: Vector2, ln: float, w: float, base: Color, lit: Color, dk: Color) -> void:
	var n := d.orthogonal()
	var tip := root + d * ln + n * w * 0.35
	b.polygon(PackedVector2Array([root - n * w, root + n * w, root + d * ln * 0.55 + n * w * 0.95, tip, root + d * ln * 0.5 - n * w * 0.75]), dk)
	b.polygon(PackedVector2Array([root - n * w * 0.8, root + n * w * 0.7, root + d * ln * 0.5 + n * w * 0.65, tip - d * 1.6, root + d * ln * 0.46 - n * w * 0.6]), base)
	b.polygon(PackedVector2Array([root - n * w * 0.55, root + n * w * 0.05, root + d * ln * 0.62 + n * w * 0.1, root + d * ln * 0.42 - n * w * 0.45]), lit)


static func _coat_at(y: float) -> Array:
	return [CLEAN, CLEAN_LIT, CLEAN_DK] if y < WASHED_Y else [COAT, COAT_LIT, COAT_DK]


# all of it that never moves, once per van and sun
static func _draw_still(b: ShapeBatch, m: Node2D, v: Vector2) -> void:
	var body := Rect2(v.x - 32.0, v.y - 66.0, 64.0, 132.0)
	m.box_shadow(b, body, 16.0, 26.0)
	# tyres and paw hubcaps, showing under the coat
	for w: Vector2 in [Vector2(-34, -44), Vector2(34, -44), Vector2(-34, 42), Vector2(34, 42)]:
		b.polygon(m.round_rect_pts(Rect2(v + w - Vector2(5, 12), Vector2(10, 24)), 4.0), Color(0.10, 0.10, 0.12))
	# the bumper, chrome, with its two round lamps
	b.polygon(m.round_rect_pts(Rect2(v.x - 30.0, v.y - 70.0, 60.0, 11.0), 5.0), Color(0.40, 0.41, 0.45))
	b.polygon(m.round_rect_pts(Rect2(v.x - 28.0, v.y - 69.0, 56.0, 4.0), 2.0), Color(0.80, 0.82, 0.86))
	# the body under the hair, and the skirt of locks past it, back to front
	b.polygon(m.round_rect_pts(body, 17.0), COAT_DK)
	var y := 58.0
	while y > -58.0:
		var c := _coat_at(y)
		for sx: float in [-1.0, 1.0]:
			var k := int(y) * 3 + int(sx)
			_lock(b, v + Vector2(sx * 25.0, y - 8.0), Vector2(sx * (0.42 + 0.2 * _h(k)), 0.9).normalized(), 18.0 + 5.0 * _h(k + 5), 5.2, c[0], c[1] if sx < 0.0 else c[0], c[2])
		y -= 8.0
	# the coat itself: rows of locks laid like tiles from the back door up
	b.polygon(m.round_rect_pts(body.grow(-4.0), 14.0), COAT)
	y = 60.0
	var row := 0
	while y > -32.0:
		var c := _coat_at(y)
		for i in range(6):
			var x := -27.0 + float(i) * 10.8 + (5.4 if row % 2 == 0 else 0.0)
			if absf(x) > 29.0:
				continue
			var k := row * 17 + i
			var lean := x * 0.012 + (_h(k) - 0.5) * 0.35
			var base: Color = (c[0] as Color).lerp(c[2], 0.20 * _h(k + 3))
			_lock(b, v + Vector2(x, y - 12.0), Vector2(lean, 1.0).normalized(), 17.0 + 4.0 * _h(k + 1), 6.2,
				base.darkened(0.10) if x > 14.0 else base, c[1] if x < 12.0 else c[0], c[2])
		y -= 8.5
		row += 1
	# where the wash has got to: a line of suds
	for i in range(9):
		var p := v + Vector2(-28.0 + float(i) * 7.0, WASHED_Y - 6.0 + 3.0 * sin(float(i) * 2.1))
		var r := 3.4 + 2.4 * _h(i + 40)
		b.circle(p, r + 0.8, Color(0.58, 0.72, 0.84))
		b.circle(p, r, Color(0.93, 0.97, 1.0))
		b.circle(p - Vector2(r, r) * 0.3, r * 0.36, Color(1, 1, 1))
	# the long light of a round back
	b.band(PackedVector2Array([v + Vector2(-30, -26), v + Vector2(-13, -26), v + Vector2(6, -26), v + Vector2(31, -26),
		v + Vector2(-30, 60), v + Vector2(-13, 60), v + Vector2(6, 60), v + Vector2(31, 60)]), 4, Color(1.0, 0.95, 0.82),
		PackedFloat32Array([0.16, 0.0]), PackedFloat32Array([0.0, 1.0, 0.0, 0.0]))
	b.band(PackedVector2Array([v + Vector2(8, -26), v + Vector2(34, -26), v + Vector2(8, 62), v + Vector2(34, 62)]), 2,
		Color(0.16, 0.07, 0.05), PackedFloat32Array([0.30, 0.0]), PackedFloat32Array([0.0, 1.0]))
	# the hood: a broad cream muzzle swelling out over the bumper
	for sx: float in [-1.0, 1.0]:
		b.ellipse(v + Vector2(sx * 12.0, -55.0), 17.0, 13.0, CLEAN_DK)
		b.ellipse(v + Vector2(sx * 11.4, -56.2), 15.6, 11.6, CLEAN)
		b.ellipse(v + Vector2(sx * 11.0 - 3.0, -59.0), 8.0, 5.0, CLEAN_LIT)
		for k in range(3):
			b.circle(v + Vector2(sx * (9.0 + 4.0 * float(k)), -53.0 + 2.0 * float(k % 2)), 1.0, CLEAN_DK.darkened(0.25))
	b.line(v + Vector2(0, -60), v + Vector2(0, -46), CLEAN_DK.darkened(0.30), 1.8)
	b.ellipse(v + Vector2(0, -61.5), 9.6, 7.4, NOSE)
	b.ellipse(v + Vector2(-0.6, -62.6), 7.6, 5.2, Color(0.22, 0.19, 0.22))
	b.ellipse(v + Vector2(-2.8, -64.2), 3.0, 1.6, Color(0.78, 0.78, 0.82))
	for sx: float in [-1.0, 1.0]:
		b.ellipse(v + Vector2(sx * 3.4, -59.6), 1.7, 1.2, Color(0.02, 0.02, 0.03))
	# the windscreen
	b.polygon(PackedVector2Array([v + Vector2(-27, -46), v + Vector2(27, -46), v + Vector2(25, -27), v + Vector2(-25, -27)]), Color(0.10, 0.12, 0.16))
	b.polygon(PackedVector2Array([v + Vector2(-25, -45), v + Vector2(25, -45), v + Vector2(23.5, -28), v + Vector2(-23.5, -28)]), GLASS)
	b.polygon(PackedVector2Array([v + Vector2(-24, -45), v + Vector2(-15, -45), v + Vector2(-20, -28), v + Vector2(-23.5, -28)]), Color(0.62, 0.74, 0.84, 0.40))
	# the ears, off the front corners of the roof and down over the doors
	for sx: float in [-1.0, 1.0]:
		var root := v + Vector2(sx * 23.0, -30.0)
		for k in range(5):
			var d := Vector2(sx * (0.95 - 0.16 * float(k)), 0.28 + 0.20 * float(k)).normalized()
			_lock(b, root + Vector2(sx * 1.5 * float(k), 2.0 * float(k)), d, 27.0 + 3.0 * float(k % 3), 7.4, COAT, COAT_LIT if sx < 0.0 else COAT, COAT_DK)
	# mirrors, out past them
	for sx: float in [-1.0, 1.0]:
		b.polygon(m.round_rect_pts(Rect2(v.x + sx * 34.0 - 3.5, v.y - 50.0, 7.0, 9.0), 3.0), Color(0.22, 0.22, 0.26))
		b.rect(Rect2(v.x + sx * 34.0 - 2.0, v.y - 48.5, 4.0, 3.0), Color(0.70, 0.80, 0.88))
	# the collar across the roof, its buckle and its tag
	b.polygon(m.round_rect_pts(Rect2(v.x - 31.0, v.y - 22.0, 62.0, 9.0), 4.0), COLLAR.darkened(0.45))
	b.polygon(m.round_rect_pts(Rect2(v.x - 31.0, v.y - 23.0, 62.0, 8.0), 4.0), COLLAR)
	b.rect(Rect2(v.x - 29.0, v.y - 22.2, 58.0, 2.0), COLLAR.lightened(0.28))
	for k in range(6):
		b.circle(v + Vector2(-25.0 + 10.0 * float(k), -18.6), 1.3, TAG)
	# the signwriting, on a bone
	var bone := Rect2(v.x - 25.0, v.y - 10.0, 50.0, 25.0)
	for pass_k in range(2):
		var col := INK if pass_k == 0 else Color(0.99, 0.96, 0.88)
		var g := 1.8 if pass_k == 0 else 0.0
		b.polygon(m.round_rect_pts(bone.grow(g), 4.0), col)
		for sx: float in [-1.0, 1.0]:
			for sy: float in [-1.0, 1.0]:
				b.circle(bone.get_center() + Vector2(sx * 25.0, sy * 8.0), 7.2 + g, col)
	var font: Font = m.font
	b.draw_string(font, Vector2(v.x - 30.0, v.y + 1.5), "FUR-", HORIZONTAL_ALIGNMENT_CENTER, 60.0, 11, Color(0.78, 0.22, 0.30))
	b.draw_string(font, Vector2(v.x - 30.0, v.y + 12.5), "GONETA", HORIZONTAL_ALIGNMENT_CENTER, 60.0, 12, INK)
	# the roof vent the suds come from
	b.circle(v + Vector2(0, 45), 7.5, COAT_DK)
	b.circle(v + Vector2(0, 44), 6.4, Color(0.66, 0.68, 0.72))
	b.circle(v + Vector2(0, 44), 4.2, Color(0.28, 0.30, 0.34))
	for k in range(3):
		b.line(v + Vector2(-3.6, 41.6 + 2.4 * float(k)), v + Vector2(3.6, 41.6 + 2.4 * float(k)), Color(0.66, 0.68, 0.72), 1.0)
	# the groomer's hatch on the pavement side, lit, a comb in it
	b.polygon(m.round_rect_pts(Rect2(v.x + 27.0, v.y + 16.0, 6.5, 24.0), 2.0), COAT_DK)
	b.rect(Rect2(v.x + 28.2, v.y + 18.0, 4.0, 20.0), Color(1.0, 0.90, 0.62))
	b.line(v + Vector2(30.2, 21), v + Vector2(30.2, 33), INK, 1.4)
	for k in range(5):
		b.line(v + Vector2(30.2, 22.0 + 2.4 * float(k)), v + Vector2(32.0, 22.0 + 2.4 * float(k)), INK, 0.9)


static func draw(m: Node2D, v: Vector2, wc: Object = null) -> void:
	if wc == null:
		wc = m.get("_wc")
	if wc == null:
		return
	var own := not (wc is ShapeBatch)
	var b: ShapeBatch = ShapeBatch.new(wc) if own else wc
	var t := AnimClock.msec()
	# the tail first: a pompom on the back doors, wagging harder as she comes
	var near: bool = m.dog != null and m.dog.global_position.distance_to(v) < 260.0
	var wag := sin(t / (110.0 if near else 230.0)) * (0.7 if near else 0.35)
	var root := v + Vector2(0.0, 60.0)
	var dir := Vector2(0.0, 1.0).rotated(wag)
	b.capsule(root, root + dir * 20.0, 5.5, COAT_DK)
	b.capsule(root, root + dir * 20.0, 4.2, COAT)
	var pom := root + dir * 28.0
	b.circle(pom + Shade.light * 5.0, 12.0, Color(0.05, 0.05, 0.08, 0.18))
	for k in range(9):
		var a := float(k) * TAU / 9.0 + wag
		b.circle(pom + Vector2.from_angle(a) * 7.0, 5.6, CLEAN_DK)
	for k in range(9):
		var a := float(k) * TAU / 9.0 + wag
		b.circle(pom + Vector2.from_angle(a) * 6.2 - Vector2(0.8, 1.0), 5.0, CLEAN)
	b.circle(pom - Vector2(2.4, 3.0), 5.4, CLEAN_LIT)
	# the tongue, out over the bumper, panting
	var pant := sin(t / 150.0)
	var tip := v + Vector2(5.0 + pant * 0.8, -80.0 - pant * 2.0)
	b.capsule(v + Vector2(4.0, -66.0), tip, 6.0, Color(0.70, 0.28, 0.38))
	b.capsule(v + Vector2(4.0, -66.0), tip, 4.9, PINK)
	b.line(v + Vector2(4.2, -68.0), tip + Vector2(0.0, 1.0), Color(0.84, 0.42, 0.52), 1.3)
	b.circle(tip + Vector2(-1.8, 0.6), 1.2, Color(1, 1, 1, 0.85))
	# everything that stays put
	var key := [m.get_instance_id(), v, Shade.light]
	var still: ShapeBatch = _still.get(key)
	if still == null:
		if _still.size() > 4:
			_still.clear()
		still = ShapeBatch.new()
		_draw_still(still, m, v)
		_still[key] = still
	still.append_to(b)
	# the tag on its collar swings
	var tagp := v + Vector2(sin(t / 300.0) * 1.4, -11.0)
	b.circle(tagp, 4.4, TAG.darkened(0.4))
	b.circle(tagp - Vector2(0.3, 0.5), 3.7, TAG)
	UiIcons.draw_paw(b, tagp, 2.6, TAG.darkened(0.5))
	# eyes behind the glass, on her when she is near, shut now and then
	var look := Vector2(sin(t / 1900.0) * 1.2, 0.6)
	if near:
		look = (m.dog.global_position - v).normalized() * 2.3
	var blink := fmod(t, 3700.0) < 130.0
	for sx: float in [-1.0, 1.0]:
		var e := v + Vector2(sx * 10.5, -37.0)
		if blink:
			b.line(e - Vector2(6, 0), e + Vector2(6, 0), COAT_LIT, 2.4)
			continue
		b.circle(e, 7.6, Color(0.08, 0.08, 0.10))
		b.circle(e, 6.8, Color(0.99, 0.98, 0.95))
		b.circle(e + look, 3.7, Color(0.36, 0.20, 0.11))
		b.circle(e + look, 2.4, Color(0.06, 0.05, 0.06))
		b.circle(e + look + Vector2(-1.2, -1.2), 1.1, Color(1, 1, 1))
	# the wipers are its eyebrows
	var sweep := sin(t * 0.028) * 5.0 if m.furgoneta_wiper_t > 0.0 else sin(t / 900.0) * 0.8
	for sx: float in [-1.0, 1.0]:
		var base := v + Vector2(sx * 20.0, -45.0)
		b.line(base, v + Vector2(sx * 5.0, -46.5 + sweep * 0.6), Color(0.12, 0.10, 0.10), 3.2)
	# the fringe, combed over the top of the screen
	for k in range(9):
		var fx := -24.0 + 6.0 * float(k)
		_lock(b, v + Vector2(fx, -24.0), Vector2(-fx * 0.010 + sin(t / 700.0 + float(k)) * 0.04, -1.0).normalized(), 9.0 + 3.0 * _h(k + 70), 4.6,
			COAT, COAT_LIT if k < 6 else COAT, COAT_DK)
	# suds off the vent, drifting downwind and popping
	for k in range(4):
		var u := fposmod(t / 2600.0 + float(k) * 0.25, 1.0)
		var p := v + Vector2(sin(u * 5.0 + float(k) * 2.0) * 6.0 + u * 14.0, 44.0 - u * 34.0)
		var r := (1.6 + 2.6 * u) * (1.0 if u < 0.94 else 1.4)
		var al := 0.75 * (1.0 - u * u)
		b.circle(p, r + 0.7, Color(0.55, 0.74, 0.90, al * 0.7))
		b.circle(p, r, Color(0.94, 0.98, 1.0, al * 0.55))
		b.circle(p - Vector2(r, r) * 0.35, r * 0.32, Color(1, 1, 1, al))
	# the headlamps, and the flash of them when it honks
	var flashes_on := true
	var loop := Engine.get_main_loop()
	var game: Node = loop.root.get_node_or_null("Game") if loop is SceneTree else null
	if game != null:
		flashes_on = bool(game.flashes)
	var lit: float = clampf(m.furgoneta_flash_t / 0.35, 0.0, 1.0) if flashes_on else 0.0
	for sx: float in [-1.0, 1.0]:
		var lamp := v + Vector2(sx * 25.0, -65.0)
		b.circle(lamp, 5.0, Color(0.30, 0.29, 0.32))
		b.circle(lamp, 3.9, Color(1.0, 0.95, 0.74))
		b.circle(lamp - Vector2(1.2, 1.2), 1.3, Color(1, 1, 1))
		if lit > 0.0:
			b.glow(lamp, 26.0, Color(1.0, 0.97, 0.75, 0.85 * lit))
			b.band(PackedVector2Array([lamp + Vector2(-4, -2), lamp + Vector2(4, -2), lamp + Vector2(sx * 12.0 - 20.0, -62), lamp + Vector2(sx * 12.0 + 20.0, -62)]),
				2, Color(1.0, 0.97, 0.78), PackedFloat32Array([0.45 * lit, 0.0]))
	if not m.furgoneta_sniffed:
		var fg := 0.5 + 0.5 * sin(m.prize_glow * 0.8)
		b.arc(v, 80.0 + fg * 6.0, 0.0, TAU, 40, Color(1.0, 0.86, 0.5, 0.10 + fg * 0.07), 2.0)
	if own:
		b.flush()


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
