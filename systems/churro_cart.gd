class_name ChurroCart
extends RefCounted

# LA RAMBLA DE BADALONA (Walk 36: La Cremada) - THE CHURRO CART
# A live event for La Cremada's palm-lined Rambla between the railway underpass
# and the beach. A traditional xurreria ambulant (mobile churro cart) is parked
# between the eastern palms and the promenade walking thoroughfare.
#
# Conditions (active_in):
# - Active during festival evening and night (dusk, night) in fair weather
#   (clear or wind).
# - Packed away in rain or snow, or in daylight hours, leaving the walk clean.
#
# Gameplay contract:
# - 0.8 s warning telegraph: as your human approaches down the Rambla, the vendor
#   rings the brass service bell ("Ding-ding!") and calls out
#   "Xurros calents! Fresh and hot!" in a speech bubble. Nothing can hurt
#   anyone during the telegraph.
# - Soft hazard: only a human who wanders into the cart's footprint bumps against
#   the wooden frame (losing 0.08 patience, a small stumble, "Ai, que crema!").
# - Snack trick: as fresh churros come out of the hot oil, a dropped golden churro
#   rolls onto the paving. If the dog pounces or reaches it:
#   "churro snatch! +2" ("Bon profit!").
# - Bark greeting: barking near the cart prompts a cheery greeting from the vendor:
#   "churro bark! +2" ("One for the doggie!").
# - Dodge reward: steering your human safely past the cart after a close brush
#   awards "churro dodge! +2" ("Whew, close one!") through NearMiss.
# - Autowalk safe: the cart is placed at x = 735.0, 95 px east of the centre line
#   (x = 640.0), so the bot passes without bump or dodge. Fully deterministic.
# - Zero new draw calls: drawn into the world's ShapeBatch from Cremada's
#   draw_live hook; allocation-free per frame.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const CART_POS := Vector2(735.0, -4180.0)
const CART_SIZE := Vector2(48.0, 32.0)
const TRIGGER_Y := -3960.0
const CHURRO_DROP_POS := Vector2(695.0, -4168.0)

const WARN_DURATION := 0.8
const DROP_DURATION := 2.5

const HIT_R := 28.0
const THREAT_R := 52.0
const SNACK_R := 26.0
const BARK_R := 140.0
const BUMP_PATIENCE := 0.08

const CART_WOOD := Color(0.36, 0.22, 0.14)
const CART_WHEEL := Color(0.20, 0.14, 0.10)
const AWNING_RED := Color(0.82, 0.18, 0.14)
const AWNING_CREAM := Color(0.95, 0.92, 0.84)
const CHURRO_GOLD := Color(0.86, 0.62, 0.28)
const CHURRO_CRUST := Color(0.68, 0.44, 0.18)
const FRYER_STEEL := Color(0.70, 0.68, 0.64)
const OIL_GOLD := Color(0.88, 0.72, 0.30)
const LANTERN_FRAME := Color(0.18, 0.14, 0.10)
const VENDOR_APRON := Color(0.94, 0.92, 0.88)
const VENDOR_CAP := Color(0.82, 0.16, 0.14)
const VENDOR_SKIN := Color(0.85, 0.68, 0.52)

enum State { IDLE, TELEGRAPH, ACTIVE, DONE }

var state: State = State.IDLE
var timer: float = 0.0
var triggered: bool = false
var human_hit: bool = false
var churro_eaten: bool = false
var bark_greeted: bool = false
var dodge_awarded: bool = false
var threatened: bool = false
var sky_ok: bool = true
var bump_dir: Vector2 = Vector2.LEFT

var _out := {"warn": false, "bump": false, "snatch": false, "dodge": false}


static func active_in(weather: String, hour: String) -> bool:
	return (weather == "clear" or weather == "wind") and (hour == "dusk" or hour == "night")


func tick(delta: float, dog_pos: Vector2, human_pos: Vector2, outward: bool) -> Dictionary:
	_out["warn"] = false
	_out["bump"] = false
	_out["snatch"] = false
	_out["dodge"] = false
	if not sky_ok:
		return _out

	match state:
		State.IDLE:
			if outward and not triggered and human_pos.y <= TRIGGER_Y and human_pos.y > CART_POS.y:
				triggered = true
				state = State.TELEGRAPH
				timer = WARN_DURATION
				_out["warn"] = true

		State.TELEGRAPH:
			timer -= delta
			if timer <= 0.0:
				state = State.ACTIVE
				timer = 0.0

		State.ACTIVE:
			timer += delta
			if timer >= DROP_DURATION and (human_pos.y < CART_POS.y - 120.0 or not outward):
				state = State.DONE

		State.DONE:
			pass

	if state == State.ACTIVE:
		# Soft hazard: bumping the wooden cart
		if not human_hit and human_pos.distance_to(CART_POS) <= HIT_R:
			human_hit = true
			bump_dir = (human_pos - CART_POS).normalized() if human_pos != CART_POS else Vector2.LEFT
			_out["bump"] = true

		# Dropped churro snack
		if not churro_eaten and dog_pos.distance_to(CHURRO_DROP_POS) <= SNACK_R:
			churro_eaten = true
			_out["snatch"] = true

	if state >= State.ACTIVE:
		var close := human_pos.distance_to(CART_POS) <= THREAT_R
		var step := NearMiss.consider(close, human_hit, threatened, dodge_awarded)
		threatened = bool(step["threatened"])
		if bool(step["dodge"]):
			dodge_awarded = true
			_out["dodge"] = true

	return _out


func on_bark(dog_pos: Vector2) -> bool:
	if not sky_ok or bark_greeted:
		return false
	if state == State.IDLE or state == State.DONE:
		return false
	if dog_pos.distance_to(CART_POS) > BARK_R:
		return false
	bark_greeted = true
	return true


func draw(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if not sky_ok:
		return
	if CART_POS.y < vt - 80.0 or CART_POS.y > vb + 80.0:
		return

	var t: float = AnimClock.msec() * 0.001
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.28)
	var cp := CART_POS

	# 1. Cart shadow
	var r := Rect2(cp.x - CART_SIZE.x * 0.5, cp.y - CART_SIZE.y * 0.5, CART_SIZE.x, CART_SIZE.y)
	wc.rect(Rect2(r.position + m.LIGHT * 8.0, r.size), sh)

	# 2. Wheels
	var wy := cp.y + CART_SIZE.y * 0.5 - 2.0
	for wx: float in [cp.x - CART_SIZE.x * 0.4, cp.x + CART_SIZE.x * 0.4]:
		wc.circle(Vector2(wx, wy), 7.0, CART_WHEEL)
		wc.circle(Vector2(wx, wy), 4.0, CART_WOOD)
		wc.circle(Vector2(wx, wy), 1.5, CART_WHEEL)

	# 3. Wooden cart body
	wc.rect(r, CART_WOOD.darkened(0.2))
	wc.rect(r.grow(-2.0), CART_WOOD)

	# 4. Fryer vat and hot oil
	var fryer_c := Vector2(cp.x - 10.0, cp.y)
	wc.circle(fryer_c, 8.0, FRYER_STEEL)
	wc.circle(fryer_c, 6.0, OIL_GOLD)
	# Little simmer bubble
	var bubble_off := Vector2(sin(t * 7.0) * 2.5, cos(t * 8.3) * 2.5)
	wc.circle(fryer_c + bubble_off, 1.5, CHURRO_GOLD.lightened(0.2))

	# 5. Paper cone and stacked churros on counter
	var cone_p := Vector2(cp.x + 12.0, cp.y + 2.0)
	wc.polygon(PackedVector2Array([cone_p + Vector2(-5, -4), cone_p + Vector2(5, -4), cone_p + Vector2(0, 6)]), AWNING_CREAM)
	for d: float in [-2.5, 0.0, 2.5]:
		wc.line(cone_p + Vector2(d, -3), cone_p + Vector2(d * 1.5, -10), CHURRO_GOLD, 2.0)

	# 6. Striped awning over the cart
	var aw_y := r.position.y - 2.0
	var aw_h := 14.0
	var sx := r.position.x
	var k := 0
	while sx < r.end.x - 0.5:
		var sw := minf(8.0, r.end.x - sx)
		wc.rect(Rect2(sx, aw_y, sw, aw_h), AWNING_RED if k % 2 == 0 else AWNING_CREAM)
		sx += sw
		k += 1
	# Awning edge scallop
	sx = r.position.x + 4.0
	while sx < r.end.x - 2.0:
		wc.circle(Vector2(sx, aw_y + aw_h), 3.0, AWNING_RED if int((sx - r.position.x) / 8.0) % 2 == 0 else AWNING_CREAM)
		sx += 8.0

	# 7. Warm glowing lantern
	var lamp_p := Vector2(r.position.x + 3.0, aw_y + aw_h + 3.0)
	wc.circle(lamp_p, 4.0, LANTERN_FRAME)
	wc.circle(lamp_p, 2.5, Color(1.0, 0.88, 0.50))
	wc.glow(lamp_p, 36.0, Color(1.0, 0.82, 0.44, 0.45), 0.2)

	# 8. Service bell on front counter corner
	var bell_p := Vector2(r.end.x - 4.0, cp.y + 8.0)
	wc.circle(bell_p, 3.0, Color(0.92, 0.78, 0.24))
	wc.circle(bell_p + Vector2(0.0, -1.0), 1.5, Color(1.0, 0.90, 0.40))

	# 9. Vendor (standing behind/beside cart at north edge)
	var vp := Vector2(cp.x + 4.0, cp.y - 18.0)
	wc.circle(vp + m.LIGHT * 4.0, 6.0, sh)
	# Body / Apron
	wc.capsule(vp + Vector2(-4.0, 0.0), vp + Vector2(4.0, 0.0), 5.0, VENDOR_APRON)
	# Head & Red cap (barretina)
	wc.circle(vp + Vector2(0.0, -5.0), 4.5, VENDOR_SKIN)
	wc.circle(vp + Vector2(1.0, -7.0), 3.5, VENDOR_CAP)
	# Arm / Tongs
	var arm_swing := sin(t * 4.0) * 2.0 if state == State.ACTIVE else 0.0
	wc.line(vp + Vector2(-4.0, 0.0), fryer_c + Vector2(0.0, -3.0 + arm_swing), FRYER_STEEL, 1.5)

	# 10. Dropped churro on paving (if not eaten)
	if state >= State.ACTIVE and not churro_eaten:
		var ch_p := CHURRO_DROP_POS
		wc.capsule(ch_p + m.LIGHT * 3.0, ch_p + Vector2(12.0, 5.0) + m.LIGHT * 3.0, 3.2, sh)
		wc.capsule(ch_p, ch_p + Vector2(12.0, 5.0), 3.0, CHURRO_CRUST)
		wc.capsule(ch_p + Vector2(0.8, 0.6), ch_p + Vector2(11.2, 4.4), 2.2, CHURRO_GOLD)
		# A few tiny golden crumbs
		wc.circle(ch_p + Vector2(-3.0, 2.0), 1.2, CHURRO_GOLD)
		wc.circle(ch_p + Vector2(14.0, 7.0), 1.0, CHURRO_GOLD)
		# A soft wisp of steam rising into the night air
		var steam_y := sin(t * 5.0) * 2.0
		wc.circle(ch_p + Vector2(6.0, -4.0 + steam_y), 2.0, Color(1.0, 1.0, 1.0, 0.35))
		wc.circle(ch_p + Vector2(8.0, -8.0 + steam_y * 1.2), 2.8, Color(1.0, 1.0, 1.0, 0.2))
