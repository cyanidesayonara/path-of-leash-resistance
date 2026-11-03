class_name LostTourist
extends RefCounted

# WALK 23: EL LABERINT D'HORTA - LOST MAZE TOURIST
# Signature live event for El Laberint d'Horta (the cypress maze):
# A bewildered tourist (el turista desorientat) wearing a safari bucket hat,
# tropical floral shirt, and binoculars rushes frantically across the maze
# cross aisle at y = -1740.0, eyes buried in a giant flapping paper map
# of the labyrinth while trying to find Eros.
#
# Gameplay contract:
# - 0.8 s warning telegraph: Tourist appears at the west cypress hedge archway
#   at x = 350.0, y = -1740.0, waving their fold-out labyrinth map and calling
#   out "On és la sortida?!" with a telegraphed speech bubble.
# - Soft failure / hazard: distracted human wandering into the tourist's path
#   gets bumped by the tourist and flapping paper map (-8 patience drop,
#   "Whoa! Watch the map!").
# - Dog trick: as the tourist sprints past the center aisle (x >= 620.0), a wrapped
#   traditional Catalan carquinyoli (crunchy almond biscuit) drops onto the sauló
#   gravel; pouncing or booping it awards "carquinyoli snatch! +2" (tourist: "El meu carquinyoli!").
# - Bark trick: barking near the passing tourist startles them into panic, flipping
#   their map upside down ("tourist bark! +2", "Per aquí no!").
# - Boop trick: booping the tourist directly awards "tourist boop! +2" ("Perdó!").
# - Dodge save: steering your human safely clear past the crossing trajectory
#   awards "maze dodge! +2" / "Whew, close one!".
# - Autowalk: timing naturally clears the central corridor before the autowalk
#   pair arrives at y = -1740.0, ensuring 100% reliable automated traversal and test stability.
# - Zero new draw calls: batched directly into El Laberint d'Horta's existing ShapeBatch.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const START_POS := Vector2(350.0, -1740.0)
const END_POS := Vector2(930.0, -1740.0)
const CROSSING_Y := -1740.0
const TRIGGER_Y := -1500.0

const WARN_DURATION := 0.8
const RUN_SPEED := 200.0
const BUMP_RADIUS := 30.0
const THREAT := 64.0
const SNATCH_RADIUS := 28.0
const BOOP_RADIUS := 26.0
const BARK_RADIUS := 140.0
const CARQUINYOLI_DROP_X := 620.0

enum State { IDLE, TELEGRAPH, RUNNING, SETTLED }

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var carquinyoli_dropped: bool = false
var carquinyoli_snatched: bool = false
var carquinyoli_pos: Vector2 = Vector2.ZERO
var carquinyoli_vel: Vector2 = Vector2.ZERO
var bark_reacted: bool = false
var dodge_awarded: bool = false
var threatened: bool = false


func tick(delta: float, dog_pos: Vector2, dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out := {
		"warn": false,
		"bump": false,
		"snatch": false,
		"boop": false,
		"dodge": false,
	}

	match state:
		State.IDLE:
			if not triggered and human_pos.y <= TRIGGER_Y and human_pos.y > CROSSING_Y:
				triggered = true
				state = State.TELEGRAPH
				timer = WARN_DURATION
				pos = START_POS
				out["warn"] = true

		State.TELEGRAPH:
			timer -= delta
			if timer <= 0.0:
				state = State.RUNNING
				timer = 0.0

		State.RUNNING:
			timer += delta
			var dir := (END_POS - START_POS).normalized()
			var dist := RUN_SPEED * delta
			pos += dir * dist

			# Drop carquinyoli pastry when crossing past middle aisle
			if not carquinyoli_dropped and pos.x >= CARQUINYOLI_DROP_X:
				carquinyoli_dropped = true
				carquinyoli_pos = pos + Vector2(-6.0, 4.0)
				carquinyoli_vel = Vector2(-25.0, 15.0)

			# Check distracted human collision
			if not human_hit and human_pos.distance_to(pos) <= BUMP_RADIUS:
				human_hit = true
				out["bump"] = true

			# Reached opposite hedge wall
			if pos.x >= END_POS.x:
				pos = END_POS
				state = State.SETTLED

		State.SETTLED:
			pass

	# Carquinyoli physics & snatch check
	if carquinyoli_dropped and not carquinyoli_snatched:
		if carquinyoli_vel.length_squared() > 1.0:
			carquinyoli_pos += carquinyoli_vel * delta
			carquinyoli_vel = carquinyoli_vel.move_toward(Vector2.ZERO, 90.0 * delta)

		if dog_pos.distance_to(carquinyoli_pos) <= SNATCH_RADIUS:
			carquinyoli_snatched = true
			out["snatch"] = true

	# Dog boop check
	if not booped and (state == State.RUNNING or state == State.TELEGRAPH):
		if dog_pos.distance_to(pos) <= BOOP_RADIUS:
			booped = true
			out["boop"] = true

	if state == State.RUNNING or state == State.SETTLED:
		var close := state == State.RUNNING and pos.distance_to(human_pos) <= THREAT
		var step := NearMiss.consider(close, human_hit, threatened, dodge_awarded)
		threatened = bool(step["threatened"])
		if bool(step["dodge"]):
			dodge_awarded = true
			out["dodge"] = true

	return out


func on_bark(dog_pos: Vector2) -> bool:
	if bark_reacted:
		return false
	if state != State.RUNNING and state != State.TELEGRAPH:
		return false
	if dog_pos.distance_to(pos) <= BARK_RADIUS:
		bark_reacted = true
		return true
	return false


func draw(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if state == State.IDLE:
		return

	# Draw dropped carquinyoli
	if carquinyoli_dropped and not carquinyoli_snatched:
		if carquinyoli_pos.y >= vt - 30.0 and carquinyoli_pos.y <= vb + 30.0:
			_draw_carquinyoli(m, wc, carquinyoli_pos)

	if pos.y < vt - 50.0 or pos.y > vb + 50.0:
		return

	var t: float = AnimClock.msec() / 1000.0
	var run_anim: float = sin(t * 14.0) if state == State.RUNNING else 0.0

	# Contact shadow
	m.contact_shadow(wc, pos + Vector2(0.0, 6.0), 16.0, 7.0, 0.26)

	# Running legs with shorts
	var leg_l := pos + Vector2(-4.0 + run_anim * 4.0, 6.0 + absf(run_anim) * 2.0)
	var leg_r := pos + Vector2(4.0 - run_anim * 4.0, 6.0 + absf(run_anim) * 2.0)
	# Khaki shorts
	wc.rect(Rect2(pos.x - 7.0, pos.y, 14.0, 7.0), Color(0.76, 0.70, 0.52))
	# Legs
	wc.circle(leg_l, 2.5, Color(0.88, 0.74, 0.60))
	wc.circle(leg_r, 2.5, Color(0.88, 0.74, 0.60))
	# Trekking sandals & white socks
	wc.circle(leg_l + Vector2(0.0, 2.0), 2.0, Color(0.95, 0.95, 0.95))
	wc.circle(leg_r + Vector2(0.0, 2.0), 2.0, Color(0.95, 0.95, 0.95))
	wc.circle(leg_l + Vector2(0.0, 3.0), 1.8, Color(0.38, 0.28, 0.20))
	wc.circle(leg_r + Vector2(0.0, 3.0), 1.8, Color(0.38, 0.28, 0.20))

	# Torso: tropical floral shirt (coral/tropical red with floral speckles)
	var shirt_col := Color(0.92, 0.42, 0.35)
	wc.circle(pos + Vector2(0.0, -1.0), 8.5, shirt_col)
	# Floral speckles
	wc.circle(pos + Vector2(-3.0, -2.0), 1.6, Color(0.98, 0.88, 0.50))
	wc.circle(pos + Vector2(3.0, 1.0), 1.6, Color(0.98, 0.88, 0.50))
	wc.circle(pos + Vector2(1.0, -4.0), 1.4, Color(0.40, 0.78, 0.60))

	# Camera strap diagonally across chest
	wc.line(pos + Vector2(-6.0, -5.0), pos + Vector2(5.0, 4.0), Color(0.20, 0.20, 0.20), 1.4)
	# Vintage compact camera
	wc.rect(Rect2(pos.x + 3.0, pos.y + 1.0, 5.0, 4.0), Color(0.28, 0.28, 0.30))
	wc.circle(pos + Vector2(5.5, 3.0), 1.4, Color(0.70, 0.72, 0.75))

	# Head & neck
	wc.circle(pos + Vector2(0.0, -6.0), 4.5, Color(0.88, 0.74, 0.60))

	# Safari bucket hat (straw/khaki brim with dark olive band)
	var hat_col := Color(0.86, 0.80, 0.62)
	wc.circle(pos + Vector2(0.0, -7.0), 9.0, hat_col)
	wc.circle(pos + Vector2(0.0, -7.0), 6.0, hat_col.darkened(0.12))
	# Olive hatband
	wc.draw_arc(pos + Vector2(0.0, -7.0), 5.5, 0.0, TAU, 16, Color(0.35, 0.42, 0.28), 1.5)

	# Labyrinth paper map held out in front
	_draw_map(wc, pos, run_anim)


func _draw_map(wc: ShapeBatch, p: Vector2, run_anim: float) -> void:
	var wobble: float = sin(AnimClock.msec() / 80.0) * 1.5 if state == State.RUNNING else 0.0
	var map_center := p + Vector2(12.0, -2.0 + wobble)
	var map_w := 16.0
	var map_h := 12.0
	var map_rect := Rect2(map_center.x - map_w * 0.5, map_center.y - map_h * 0.5, map_w, map_h)

	# Paper map body
	wc.rect(map_rect, Color(0.96, 0.95, 0.90))
	wc.rect(map_rect.grow(-0.8), Color(0.98, 0.97, 0.94))

	# Blue labyrinth grid lines printed on the map
	var blue_line := Color(0.25, 0.48, 0.75, 0.8)
	wc.line(map_rect.position + Vector2(2.0, 3.0), map_rect.position + Vector2(14.0, 3.0), blue_line, 0.9)
	wc.line(map_rect.position + Vector2(2.0, 6.0), map_rect.position + Vector2(14.0, 6.0), blue_line, 0.9)
	wc.line(map_rect.position + Vector2(2.0, 9.0), map_rect.position + Vector2(14.0, 9.0), blue_line, 0.9)
	wc.line(map_rect.position + Vector2(5.0, 2.0), map_rect.position + Vector2(5.0, 10.0), blue_line, 0.9)
	wc.line(map_rect.position + Vector2(10.0, 2.0), map_rect.position + Vector2(10.0, 10.0), blue_line, 0.9)

	# Red "YOU ARE HERE" dot
	wc.circle(map_rect.position + Vector2(8.0, 6.0), 1.2, Color(0.92, 0.22, 0.20))

	# Arms holding map
	wc.line(p + Vector2(4.0, -3.0), map_rect.position + Vector2(2.0, 6.0), Color(0.88, 0.74, 0.60), 1.8)
	wc.line(p + Vector2(4.0, 1.0), map_rect.position + Vector2(2.0, 10.0), Color(0.88, 0.74, 0.60), 1.8)


func _draw_carquinyoli(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	m.contact_shadow(wc, p + Vector2(1.0, 2.0), 7.0, 3.0, 0.22)
	# Translucent bakery paper
	wc.rect(Rect2(p.x - 7.0, p.y - 4.0, 14.0, 8.0), Color(0.96, 0.95, 0.90, 0.85))
	# Golden toasted almond biscuit
	wc.rect(Rect2(p.x - 5.0, p.y - 2.5, 10.0, 5.0), Color(0.82, 0.60, 0.32))
	# Embedded almond slices
	wc.circle(p + Vector2(-2.0, -0.5), 1.2, Color(0.96, 0.92, 0.80))
	wc.circle(p + Vector2(2.0, 0.5), 1.2, Color(0.96, 0.92, 0.80))
	# Sparkle
	var glint: float = 0.5 + 0.5 * sin(AnimClock.msec() / 140.0)
	wc.circle(p + Vector2(-3.5, -2.0), 1.0 * glint, Color(1.0, 1.0, 0.85, 0.8 * glint))
