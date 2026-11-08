class_name EixampleTour
extends RefCounted

# L'EIXAMPLE's live event: a tour group follows its guide's raised umbrella
# across the last cross street, from the far side of the grid towards the
# basilica. A line of people crossing at a steady walk is a moving wall: let
# your human walk into it with their phone up and they lose patience; steer them
# clear of it and it counts as a save.
#
# Contract (AGENTS.md, human events): the guide calls the group 0.8 s before
# it steps off the kerb, as a speech bubble over the umbrella. The group is a
# fixed line on a fixed path at a fixed speed, so it is the same crossing
# every walk. A bark makes the whole group turn and photograph her, once; a
# boop of the guide gets a laugh; the last tourist drops a pastry she can
# have. Drawn into the walk's live batch: no draw calls of its own.

const NearMiss := preload("res://systems/near_miss.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")

enum State { IDLE, TELEGRAPH, CROSSING, GONE }

const CROSS_Y := -4280.0        # the cross street the group uses
const TRIGGER_Y := -3930.0      # your human this far up the walk calls it
const START_X := 150.0          # the guide steps out from behind the left corner
const END_X := 1180.0           # and the last of them is gone past the right one
const SPEED := 92.0             # an unhurried tour group's walk
const WARN := 0.8
const COUNT := 9                # tourists behind the guide
const GAP := 30.0               # between them, along the line
const SWAY := 9.0               # how far a tourist drifts off the line

const BUMP_R := 24.0
const THREAT_R := 70.0
const BOOP_R := 26.0
const BARK_R := 170.0
const SNATCH_R := 24.0
const PATIENCE_COST := 0.12

var state: State = State.IDLE
var timer := 0.0
var lead_x := START_X           # the guide's x; the line trails to her left
var walk_t := 0.0
var human_hit := false
var booped := false
var photographed := false
var photo_t := 0.0              # how long the cameras are still up
var dodged := false
var threatened := false
var pastry_dropped := false
var pastry_taken := false
var pastry_pos := Vector2.ZERO

const SHADOW := Color(0.04, 0.05, 0.07, 0.22)
const UMBRELLA := Color(0.92, 0.32, 0.18)
const UMBRELLA_PANEL := Color(0.98, 0.78, 0.24)
const GUIDE_SHIRT := Color(0.16, 0.38, 0.58)
const HAIR := [Color(0.22, 0.16, 0.12), Color(0.78, 0.62, 0.36), Color(0.12, 0.10, 0.10), Color(0.62, 0.62, 0.60), Color(0.46, 0.28, 0.16)]
const SHIRTS := [Color(0.86, 0.86, 0.82), Color(0.80, 0.40, 0.42), Color(0.36, 0.56, 0.42), Color(0.92, 0.72, 0.30), Color(0.42, 0.48, 0.72), Color(0.70, 0.52, 0.70)]
const HAT := Color(0.90, 0.86, 0.70)
const LANYARD := Color(0.96, 0.84, 0.20)
const CAMERA := Color(0.14, 0.14, 0.16)
const FLASH := Color(1.0, 1.0, 0.92, 0.85)
const PASTRY := Color(0.88, 0.70, 0.40)
const SUGAR := Color(0.98, 0.96, 0.92)


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	lead_x = START_X
	walk_t = 0.0
	human_hit = false
	booped = false
	photographed = false
	photo_t = 0.0
	dodged = false
	threatened = false
	pastry_dropped = false
	pastry_taken = false
	pastry_pos = Vector2.ZERO


# where tourist k stands (0 is the guide): a line trailing back along the
# street, each swaying off it at their own pace
func member_pos(k: int) -> Vector2:
	var x := lead_x - float(k) * GAP
	var y := CROSS_Y + sin(walk_t * 2.2 + float(k) * 1.7) * SWAY * (0.0 if k == 0 else 1.0) \
		+ (float(k % 3) - 1.0) * 14.0
	return Vector2(x, y)


func active() -> bool:
	return state == State.CROSSING


func tick(m: Node2D, delta: float) -> void:
	var dog_p: Vector2 = m.dog.global_position
	var human_p: Vector2 = m.human.global_position
	photo_t = maxf(0.0, photo_t - delta)
	if pastry_dropped and not pastry_taken and dog_p.distance_to(pastry_pos) < SNATCH_R:
		pastry_taken = true
		m.kebabs_eaten += 1
		m.award_points(2, "pastry! +2")
		_sfx(m, "snack", 1.1)
	match state:
		State.IDLE:
			# only on the way out, so the crossing is the same one every walk
			if m.phase == "out" and human_p.y < TRIGGER_Y and human_p.y > CROSS_Y - 300.0:
				state = State.TELEGRAPH
				timer = WARN
				m.float_text(Vector2(START_X + 60.0, CROSS_Y - 54.0), "Stay with the umbrella!", Color(0.98, 0.92, 0.80), m.POP_SAY)
				m.feed.say("TOUR GROUP CROSSING!", EventFeed.Tone.LOUD)
				_sfx(m, "whistle", 1.3)
		State.TELEGRAPH:
			timer -= delta
			if timer <= 0.0:
				state = State.CROSSING
		State.CROSSING:
			walk_t += delta
			lead_x += SPEED * delta
			var last := member_pos(COUNT)
			if not pastry_dropped and last.x > 640.0:
				pastry_dropped = true
				pastry_pos = last + Vector2(-6.0, 22.0)
			if not human_hit:
				for k in range(COUNT + 1):
					if human_p.distance_to(member_pos(k)) < BUMP_R:
						human_hit = true
						m.human.bumped((human_p - member_pos(k)).normalized())
						m.human.patience = maxf(0.0, m.human.patience - PATIENCE_COST)
						m.float_text(human_p + Vector2(0.0, -34.0), "Sorry, sorry. Excuse me.", Color(1.0, 0.55, 0.45), m.POP_SAY)
						m.float_text(member_pos(k) + Vector2(0.0, -30.0), "Oh! Pardon!", Color(0.98, 0.92, 0.80), m.POP_SAY)
						_sfx(m, "grunt", 0.95)
						break
			if not booped and dog_p.distance_to(member_pos(0)) < BOOP_R:
				booped = true
				m.award_points(2, "boop! +2")
				m.float_text(member_pos(0) + Vector2(0.0, -40.0), "Ha! Someone wants the tour.", Color(0.98, 0.92, 0.80), m.POP_SAY)
				_sfx(m, "whoop", 1.2)
			if member_pos(COUNT).x > END_X:
				state = State.GONE
		State.GONE:
			pass
	if state == State.CROSSING or state == State.GONE:
		var close := false
		if state == State.CROSSING:
			for k in range(COUNT + 1):
				if human_p.distance_to(member_pos(k)) < THREAT_R:
					close = true
					break
		var step: Dictionary = NearMiss.consider(close, human_hit, threatened, dodged)
		threatened = bool(step["threatened"])
		if bool(step["dodge"]):
			dodged = true
			m.saves_done += 1
			m.award_points(2, "dodged the tour! +2")
			_sfx(m, "save", 1.0)


func on_bark(m: Node2D) -> bool:
	if photographed or state != State.CROSSING:
		return false
	var dog_p: Vector2 = m.dog.global_position
	for k in range(COUNT + 1):
		if dog_p.distance_to(member_pos(k)) < BARK_R:
			photographed = true
			photo_t = 1.2
			m.award_points(3, "photographed! +3")
			m.float_text(member_pos(0) + Vector2(0.0, -40.0), "Everyone, look! A local!", Color(0.98, 0.92, 0.80), m.POP_SAY)
			_sfx(m, "ooooh", 1.1)
			return true
	return false


static func _sfx(m: Node2D, name: String, pitch: float) -> void:
	var sfx: Node = m.get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"):
		sfx.play(name, pitch, -3.0)


func draw(b: ShapeBatch, vt: float, vb: float, dog_p: Vector2) -> void:
	if CROSS_Y + 80.0 < vt or CROSS_Y - 80.0 > vb:
		return
	if pastry_dropped and not pastry_taken:
		b.circle(pastry_pos + Vector2(2.0, 2.0), 6.0, SHADOW)
		b.circle(pastry_pos, 6.0, PASTRY.darkened(0.15))
		b.circle(pastry_pos, 4.6, PASTRY)
		b.circle(pastry_pos, 1.8, PASTRY.darkened(0.3))
		b.circle(pastry_pos + Vector2(-1.5, -1.5), 1.4, SUGAR)
	if state == State.IDLE or state == State.GONE:
		return
	# back to front, so the guide's umbrella is drawn over everyone
	for k in range(COUNT, -1, -1):
		var p := member_pos(k)
		b.circle(p + Vector2(4.0, 6.0), 10.0, SHADOW)
		if k == 0:
			b.circle(p, 10.0, GUIDE_SHIRT)
			b.circle(p + Vector2(1.0, 0.0), 6.2, Color(0.30, 0.20, 0.14))
			# the umbrella, closed and held straight up: from above, a tight
			# rosette of panels with the tip in the middle
			var u := p + Vector2(10.0, -8.0)
			b.line(p + Vector2(4.0, -2.0), u, Color(0.20, 0.18, 0.16), 2.0)
			for i in range(8):
				var a := TAU * float(i) / 8.0 + walk_t * 0.6
				b.quad(u, u + Vector2.from_angle(a) * 11.0, u + Vector2.from_angle(a + TAU / 16.0) * 12.5, u + Vector2.from_angle(a + TAU / 8.0) * 11.0, UMBRELLA if i % 2 == 0 else UMBRELLA_PANEL)
			b.circle(u, 1.8, Color(0.20, 0.18, 0.16))
			continue
		var shirt: Color = SHIRTS[k % SHIRTS.size()]
		var hair: Color = HAIR[(k * 3) % HAIR.size()]
		b.circle(p, 9.0, shirt)
		b.line(p + Vector2(-6.0, -3.0), p + Vector2(0.0, 4.0), LANYARD, 1.4)
		if k % 3 == 1:
			b.circle(p, 7.0, HAT)
			b.circle(p, 4.4, HAT.darkened(0.12))
		else:
			b.circle(p + Vector2(1.0, 0.0), 5.6, hair)
		# cameras up: everyone turned to her, a flash or two going off
		if photo_t > 0.0:
			var to_dog := (dog_p - p).normalized()
			b.rect(Rect2(p + to_dog * 9.0 - Vector2(3.0, 2.5), Vector2(6.0, 5.0)), CAMERA)
			if (k + int(photo_t * 10.0)) % 4 == 0:
				b.circle(p + to_dog * 12.0, 4.0, FLASH)
