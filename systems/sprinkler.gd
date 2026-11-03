class_name Sprinkler
extends RefCounted

# The rotary lawn sprinkler in El Parc (systems/parc.gd).
# Installed on the west lawn verge beside the first box-hedged flowerbed.
# Rhythmic impact brass sprinkler arm ratchets across an arc and sprays
# a fan of sparkling water droplets across the western edge of the gravel walk.
#
# 0.8 s telegraph before the pair enters the spray zone:
# Human looks up with speech bubble ("Watch the sprinkler!").
#
# Interactions:
# - Dog runs through spray: gets soaked ("splish! +2", +2 bones, +2 combo, advances drink goal).
# - Human walks into spray: phone hazard ("Whoa! My phone!"), shakes shoes, patience drops.
# - Dog pulls human clear: ("good dodge! +2", saves_done += 1, "Whew, nice save!").

const HEAD_POS := Vector2(390.0, -980.0)
const SPRAY_RADIUS := 160.0
const SWEEP_MIN := -0.65
const SWEEP_MAX := 0.65
const SWEEP_SPEED_FWD := 0.55
const SWEEP_SPEED_RET := 2.6
const WARN_DIST := 420.0
const WARN_S := 0.8
const CONE_HALF_ANGLE := 0.32

enum St { IDLE, WARN, SPRAYING }

var state: int = St.IDLE
var angle: float = SWEEP_MIN
var sweep_dir: float = 1.0
var ratchet_t: float = 0.0
var warn_t: float = 0.0
var active: bool = false
var warn_done: bool = false
var dog_cooldown: float = 0.0
var human_cooldown: float = 0.0
var human_soaked: bool = false
var dodge_done: bool = false
var was_near: bool = false


func tick(dt: float, dog_pos: Vector2, human_pos: Vector2) -> Dictionary:
	var cue := {
		"warn": false,
		"click": false,
		"dog_splash": false,
		"human_soaked": false,
		"dodge": false,
	}

	if dog_cooldown > 0.0:
		dog_cooldown = maxf(0.0, dog_cooldown - dt)
	if human_cooldown > 0.0:
		human_cooldown = maxf(0.0, human_cooldown - dt)

	# Track if human passes through the sprinkler's latitude zone
	if absf(human_pos.y - HEAD_POS.y) < 160.0:
		was_near = true

	# Dodge check: when human moves past to the north on the dry side
	if was_near and not human_soaked and not dodge_done and human_pos.y < HEAD_POS.y - 120.0:
		if human_pos.x > 500.0:
			dodge_done = true
			cue["dodge"] = true

	match state:
		St.IDLE:
			# Triggers when the pair approaches the sprinkler
			if not warn_done and dog_pos.distance_to(HEAD_POS) < WARN_DIST and dog_pos.y > HEAD_POS.y - 120.0:
				state = St.WARN
				warn_t = 0.0
				warn_done = true
				cue["warn"] = true
		St.WARN:
			warn_t += dt
			# Mechanical arming clicking during the 0.8s telegraph
			ratchet_t += dt
			if ratchet_t >= 0.15:
				ratchet_t = 0.0
				cue["click"] = true
			if warn_t >= WARN_S:
				state = St.SPRAYING
				active = true
				angle = SWEEP_MIN
				sweep_dir = 1.0
		St.SPRAYING:
			# Oscillate / sweep
			if sweep_dir > 0.0:
				angle += SWEEP_SPEED_FWD * dt
				ratchet_t += dt
				if ratchet_t >= 0.18:
					ratchet_t = 0.0
					cue["click"] = true
				if angle >= SWEEP_MAX:
					angle = SWEEP_MAX
					sweep_dir = -1.0
			else:
				angle -= SWEEP_SPEED_RET * dt
				if angle <= SWEEP_MIN:
					angle = SWEEP_MIN
					sweep_dir = 1.0

			# Dog interaction
			var to_dog := dog_pos - HEAD_POS
			var d_dist := to_dog.length()
			if d_dist <= SPRAY_RADIUS:
				var diff := absf(angle_difference(angle, to_dog.angle()))
				if diff <= CONE_HALF_ANGLE and dog_cooldown <= 0.0:
					dog_cooldown = 1.6
					cue["dog_splash"] = true

			# Human interaction
			var to_human := human_pos - HEAD_POS
			var h_dist := to_human.length()
			if h_dist <= SPRAY_RADIUS:
				var h_diff := absf(angle_difference(angle, to_human.angle()))
				if h_diff <= CONE_HALF_ANGLE and human_cooldown <= 0.0:
					human_cooldown = 3.5
					human_soaked = true
					cue["human_soaked"] = true

	return cue
