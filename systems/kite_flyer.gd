class_name KiteFlyer
extends RefCounted

# PASSEIG MARÍTIM (level id "beach") - THE KITE OVER THE BOARDWALK
# A live event for Badalona's seafront, the second there beside the volleyball
# game (systems/volleyball.gd), and a conditional one:
# a local in a green-and-black Joventut shirt (la Penya, Badalona's basketball
# club) stands on the timber boardwalk north of the Pont del Petroli with a
# two-handed stunt kite, red and yellow like the senyera, flying over the sand.
# When the sea breeze drops the kite dives across the bike path onto the
# promenade, skids along the paving while he hauls it back, then climbs again.
#
# Conditions (flies_in): a kite flies in a breeze, so clear or wind, and in
# daylight, so dawn, day or dusk. In rain, snow or at night the flyer and his
# kite are not there at all and the walk is as it was before this event.
#
# Gameplay contract:
# - 0.8 s warning telegraph: the kite stalls and flutters, the flyer leans back
#   and calls out "Kite coming down!" in a speech bubble. Nothing can hurt
#   anyone until the telegraph is over.
# - Soft hazard: only a human who wanders into the dive's landing zone while
#   the kite is low gets tangled (a fraction of patience, a small stumble,
#   "Ow! Is that a kite?"). The kite is never a hazard while it is high.
# - Pounce trick: the dog reaches the skidding kite and pins it under her
#   paws for a moment: "kite pounce! +2" ("You caught it! Thanks!").
# - Bark trick: barking while the kite is stalling or diving startles the
#   flyer into a yank that pops the kite back up: "kite bark! +2"
#   ("Whoa! Easy there!"). A pop-up kite is no longer a hazard.
# - Dodge reward: stepping your human clear after a close pass of the low kite
#   awards "kite dodge! +2" ("Whew, close one!") through NearMiss. Walking the
#   promenade without coming close earns nothing.
# - Autowalk: the landing zone is 120 px off the promenade's centre line
#   (x = 770) and the event only fires once, on the outward leg, so the bot
#   passes it without a bump or a dodge. Deterministic: no RNG anywhere.
# - Zero new draw calls: drawn into the world's ShapeBatch, from Passeig's
#   draw_live hook; allocation-free per frame (tick reuses one result
#   dictionary, drawing builds no arrays).

const ShapeBatch := preload("res://systems/shape_batch.gd")

# where the flyer stands: the seaward edge of the boardwalk, clear of the palms
const FLYER_POS := Vector2(420.0, -4080.0)
# the kite on its line over the sand, and where it comes down on the promenade
const HOME_POS := Vector2(262.0, -4150.0)
const LAND_POS := Vector2(650.0, -4060.0)
# where he has hauled it back to along the paving before it climbs again
const HAUL_END := Vector2(470.0, -4072.0)
const HOME_Z := 130.0
# it starts once your human is 250 px south of the flyer (they walk north): the
# dog is ahead of them by then, so the flyer and his bubble are on screen, and
# at their pace the kite lands as they come level with it
const TRIGGER_Y := -3830.0

const WARN_DURATION := 0.8
const DIVE_DURATION := 1.7
const LOW_DURATION := 2.4
const CLIMB_DURATION := 1.3
const PIN_HOLD := 0.9
const SWOOP := 22.0

const HIT_R := 28.0
const HIT_Z := 22.0
const THREAT_R := 62.0
const THREAT_Z := 40.0
const PIN_R := 34.0
# the tail lies out east of the kite on the paving, and a paw on it holds it too
const TAIL_REACH := 52.0
const BARK_R := 150.0
const BUMP_PATIENCE := 0.08
# a kite's height drawn as lift on the screen, and as how far its shadow falls
const ALT_K := 0.7
const KITE_SCALE := 1.35
const FLYER_SCALE := 1.2

enum State { IDLE, TELEGRAPH, DIVE, LOW, CLIMB, DONE }

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = HOME_POS
var z: float = HOME_Z
var from_pos: Vector2 = HOME_POS
var from_z: float = HOME_Z
var pin_t: float = 0.0
var triggered: bool = false
var human_hit: bool = false
var pounced: bool = false
var bark_reacted: bool = false
var dodge_awarded: bool = false
var threatened: bool = false
# false when the weather or the hour is not one a kite flies in: nothing ticks
# and nothing is drawn (Passeig sets it from flies_in each frame)
var sky_ok: bool = true
var bump_dir: Vector2 = Vector2.RIGHT
# one result dictionary for the whole walk: tick runs every frame
var _out := {"warn": false, "bump": false, "pounce": false, "dodge": false}


# the kite flies in a breeze and in daylight, not in rain or snow or after dark
static func flies_in(weather: String, hour: String) -> bool:
	return (weather == "clear" or weather == "wind") and hour != "night"


# the kite is low enough to touch the ground and whoever is on it
func is_low() -> bool:
	return (state == State.DIVE or state == State.LOW) and z <= HIT_Z


func tick(delta: float, dog_pos: Vector2, human_pos: Vector2, outward: bool) -> Dictionary:
	_out["warn"] = false
	_out["bump"] = false
	_out["pounce"] = false
	_out["dodge"] = false
	if not sky_ok:
		return _out

	match state:
		State.IDLE:
			if outward and not triggered and human_pos.y <= TRIGGER_Y and human_pos.y > FLYER_POS.y:
				triggered = true
				state = State.TELEGRAPH
				timer = WARN_DURATION
				_out["warn"] = true

		State.TELEGRAPH:
			timer -= delta
			if timer <= 0.0:
				state = State.DIVE
				timer = 0.0

		State.DIVE:
			timer += delta
			var t := clampf(timer / DIVE_DURATION, 0.0, 1.0)
			pos = HOME_POS.lerp(LAND_POS, t)
			pos.y += sin(t * TAU) * SWOOP
			z = HOME_Z * (1.0 - t * t)
			if t >= 1.0:
				state = State.LOW
				timer = 0.0
				pos = LAND_POS
				z = 3.0

		State.LOW:
			if pin_t > 0.0:
				pin_t -= delta
				z = 3.0
			else:
				timer += delta
				var h := clampf(timer / LOW_DURATION, 0.0, 1.0)
				pos = LAND_POS.lerp(HAUL_END, h)
				z = 3.0 + absf(sin(timer * 8.0)) * 5.0
				if h >= 1.0:
					state = State.CLIMB
					timer = 0.0
					from_pos = pos
					from_z = z

		State.CLIMB:
			timer += delta
			var c := smoothstep(0.0, 1.0, clampf(timer / CLIMB_DURATION, 0.0, 1.0))
			pos = from_pos.lerp(HOME_POS, c)
			z = lerpf(from_z, HOME_Z, c)
			if timer >= CLIMB_DURATION:
				state = State.DONE
				pos = HOME_POS
				z = HOME_Z

		State.DONE:
			pass

	if state == State.DIVE or state == State.LOW:
		# soft hazard: only while the kite is low, and only once
		if not human_hit and z <= HIT_Z and human_pos.distance_to(pos) <= HIT_R:
			human_hit = true
			bump_dir = (human_pos - pos).normalized() if human_pos != pos else Vector2.RIGHT
			_out["bump"] = true
		# pounce: the dog gets to the skidding kite and pins it
		if state == State.LOW and not pounced and (dog_pos.distance_to(pos) <= PIN_R or dog_pos.distance_to(pos + Vector2(TAIL_REACH, 0.0)) <= PIN_R):
			pounced = true
			pin_t = PIN_HOLD
			_out["pounce"] = true

	if state >= State.DIVE:
		var close := is_low() and pos.distance_to(human_pos) <= THREAT_R and z <= THREAT_Z
		var step := NearMiss.consider(close, human_hit, threatened, dodge_awarded)
		threatened = bool(step["threatened"])
		if bool(step["dodge"]):
			dodge_awarded = true
			_out["dodge"] = true

	return _out


# a bark while the kite is stalling or diving makes the flyer yank it back up
func on_bark(dog_pos: Vector2) -> bool:
	if not sky_ok or bark_reacted:
		return false
	if state != State.TELEGRAPH and state != State.DIVE:
		return false
	if dog_pos.distance_to(FLYER_POS) > BARK_R and dog_pos.distance_to(pos) > BARK_R:
		return false
	bark_reacted = true
	state = State.CLIMB
	timer = 0.0
	from_pos = pos
	from_z = z
	return true


func draw(m: Node2D, wc: ShapeBatch, vt: float, vb: float, windy := false) -> void:
	if not sky_ok:
		return
	var t: float = AnimClock.msec() / 1000.0
	var breeze: float = 1.0 if windy else 0.6
	var kp := pos + Vector2(0.0, -z * ALT_K)
	var flutter := 0.0
	var tilt := sin(t * 1.3) * 0.16 * breeze
	match state:
		State.IDLE, State.DONE:
			kp += Vector2(sin(t * 0.9) * 10.0 * breeze, sin(t * 1.7) * 5.0 * breeze)
		State.TELEGRAPH:
			flutter = sin(t * 22.0)
			kp += Vector2(flutter * 4.0, 10.0 + sin(t * 9.0) * 3.0)
			tilt = flutter * 0.35
		State.DIVE:
			tilt = sin(timer * 11.0) * 0.55
		State.LOW:
			tilt = -1.25 + sin(timer * 8.0) * 0.1 * (0.0 if pin_t > 0.0 else 1.0)
		State.CLIMB:
			tilt = sin(timer * 6.0) * 0.3
	var near_flyer := FLYER_POS.y > vt - 90.0 and FLYER_POS.y < vb + 90.0
	var near_kite := kp.y > vt - 90.0 and kp.y < vb + 90.0
	if not near_flyer and not near_kite:
		return
	_draw_flyer(wc, kp)
	_draw_kite(wc, kp, tilt, t)


func _draw_flyer(wc: ShapeBatch, kp: Vector2) -> void:
	var s := FLYER_SCALE
	var p := FLYER_POS
	var to_kite := (kp - p).normalized()
	var side := Vector2(-to_kite.y, to_kite.x)
	if state == State.TELEGRAPH or state == State.LOW:
		p -= to_kite * 2.0
	var skin := Color(0.84, 0.66, 0.50)
	var green := Color(0.10, 0.46, 0.30)
	var black := Color(0.10, 0.10, 0.11)
	wc.capsule(p + Vector2(-7.0, 7.0) * s, p + Vector2(7.0, 7.0) * s, 3.5 * s, Color(0.0, 0.0, 0.0, 0.2))
	# legs, then the shirt: green with two black bands
	wc.circle(p + Vector2(-3.0, 6.0) * s, 2.6 * s, Color(0.20, 0.24, 0.34))
	wc.circle(p + Vector2(3.0, 6.0) * s, 2.6 * s, Color(0.20, 0.24, 0.34))
	wc.circle(p, 7.5 * s, green)
	wc.line(p + Vector2(-2.5, -5.0) * s, p + Vector2(-2.5, 5.0) * s, black, 2.2 * s)
	wc.line(p + Vector2(2.5, -5.0) * s, p + Vector2(2.5, 5.0) * s, black, 2.2 * s)
	# both hands out on the control bar, toward the kite
	var hand_l := p + to_kite * 9.0 * s + side * 4.0 * s
	var hand_r := p + to_kite * 9.0 * s - side * 4.0 * s
	wc.line(p + side * 5.0 * s, hand_l, skin, 2.2 * s)
	wc.line(p - side * 5.0 * s, hand_r, skin, 2.2 * s)
	wc.line(hand_l, hand_r, Color(0.80, 0.18, 0.16), 1.8 * s)
	# head, cap and its green brim toward the kite
	wc.circle(p + Vector2(0.0, -8.5) * s + to_kite * 1.5 * s, 4.2 * s, skin)
	wc.circle(p + Vector2(0.0, -9.2) * s + to_kite * 1.5 * s, 4.0 * s, black)
	wc.line(p + Vector2(0.0, -9.2) * s + to_kite * 3.0 * s, p + Vector2(0.0, -9.2) * s + to_kite * 6.5 * s, green, 2.4 * s)
	# the line, bar to kite
	wc.line((hand_l + hand_r) * 0.5, kp + Vector2(0.0, 2.0), Color(0.96, 0.95, 0.90, 0.55), 0.9)

func _draw_kite(wc: ShapeBatch, kp: Vector2, tilt: float, t: float) -> void:
	var lift := clampf(z / HOME_Z, 0.0, 1.0)
	# its shadow on the ground: tighter and darker the lower it is
	var shadow_at := pos + Vector2(14.0, 8.0) * (0.4 + lift * 0.6) + Vector2(0.0, 4.0)
	wc.capsule(shadow_at + Vector2(-9.0, 0.0), shadow_at + Vector2(9.0, 0.0), 4.0 + lift * 2.0, Color(0.0, 0.0, 0.0, 0.26 - lift * 0.12))
	var k := KITE_SCALE * (0.8 if state == State.LOW else 1.0)
	var top := kp + Vector2(0.0, -20.0 * k).rotated(tilt)
	var left := kp + Vector2(-15.0 * k, -4.0 * k).rotated(tilt)
	var right := kp + Vector2(15.0 * k, -4.0 * k).rotated(tilt)
	var bottom := kp + Vector2(0.0, 24.0 * k).rotated(tilt)
	var cen := kp + Vector2(0.0, -4.0 * k).rotated(tilt)
	# the tail first, so the sail covers its root: bows down and away
	var down := Vector2(0.0, 1.0).rotated(tilt)
	if state == State.LOW:
		down = Vector2(1.0, 0.0)
	var tail := bottom
	for i in range(6):
		tail += down * 7.0 * k + Vector2(sin(t * 5.0 + float(i) * 0.9) * 3.0, 0.0) * (0.0 if state == State.LOW else 1.0)
		wc.circle(tail, 2.3 * k, Color(0.86, 0.18, 0.16) if i % 2 == 0 else Color(0.98, 0.80, 0.14))
	# four panels meeting at the crossing, red and yellow as the senyera
	wc.quad(top, right, cen, cen, Color(0.86, 0.18, 0.16))
	wc.quad(right, bottom, cen, cen, Color(0.98, 0.80, 0.14))
	wc.quad(bottom, left, cen, cen, Color(0.86, 0.18, 0.16))
	wc.quad(left, top, cen, cen, Color(0.98, 0.80, 0.14))
	# the spars
	wc.line(top, bottom, Color(0.24, 0.18, 0.12), 1.0)
	wc.line(left, right, Color(0.24, 0.18, 0.12), 1.0)
