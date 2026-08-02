extends SceneTree

# Moods (mood.gd) are "weather": they arrive from events and fade on their own,
# and there is deliberately no button to cancel one. That design choice is only
# safe if the fading is guaranteed, so most of this file is about the promise
# rather than the feature:
#
#   - a mood never starts by itself, only from something that happened
#   - one small event is not a mood; it takes real provocation
#   - EVERY mood ends on its own, within its own advertised fade
#   - when it ends, the picture lands back exactly on the authored grade, not
#     approximately near it
#   - no effect is ever bigger than the table says, so a mood cannot quietly
#     grow into something that plays the game for you
#
# Also checks the steering wobble is reproducible. It has to be: the CI leans
# on --autowalk being deterministic, so the zoomies veer on layered sines
# rather than on a random number.
#
#   godot --headless --path . --script res://tests/test_mood.gd

const Mood := preload("res://mood.gd")
const DT := 1.0 / 60.0
const EPS := 0.0001

var failures: Array[String] = []
var checks := 0


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures.append(msg)
		print("  FAIL  %s" % msg)


func _initialize() -> void:
	call_deferred("_run")


func _fresh() -> Node:
	var m: Node = Mood.new()
	m.reset()
	return m


func _run() -> void:
	_test_starts_neutral()
	_test_needs_provocation()
	_test_every_mood_ends()
	_test_grade_returns_home()
	_test_strongest_wins()
	_test_effects_bounded()
	_test_wobble()
	_test_voice()

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("MOOD OK")
		quit(0)
	else:
		print("MOOD FAIL")
		quit(1)


func _test_starts_neutral() -> void:
	print("\n--- a walk starts in no mood at all ---")
	var m := _fresh()
	_check(m.active == Mood.M.HAPPY, "starts HAPPY")
	_check(is_equal_approx(m.intensity, 0.0), "starts at zero intensity")
	# and stays there: a mood must never appear out of nowhere
	for i in range(60 * 30):
		m.tick(DT)
	_check(m.active == Mood.M.HAPPY, "thirty quiet seconds produce no mood on their own")
	_check(is_equal_approx(m.speed_mult(), 1.0), "no mood, no speed change")
	_check(is_equal_approx(m.accel_mult(), 1.0), "no mood, no accel change")
	_check(is_equal_approx(m.scent_mult(), 1.0), "no mood, no scent change")
	_check(is_equal_approx(m.pull_mult(), 1.0), "no mood, no pull change")
	_check(is_equal_approx(m.wobble(), 0.0), "no mood, no wobble")
	m.free()


func _test_needs_provocation() -> void:
	print("\n--- one startled pigeon is not a mood ---")
	var m := _fresh()
	# a single nudge below the onset threshold must not re-grade the screen
	m.bump(Mood.M.BARKY, Mood.ONSET * 0.5)
	m.tick(DT)
	_check(m.active == Mood.M.HAPPY, "a nudge under the threshold stays HAPPY")
	_check(is_equal_approx(m.speed_mult(), 1.0), "...and changes nothing")
	# but provocation that keeps coming does land
	m.bump(Mood.M.BARKY, 0.5)
	m.tick(DT)
	_check(m.active == Mood.M.BARKY, "enough provocation lands the mood")
	# intensity is rescaled across the part of the charge that counts, so a
	# mood that has only just landed is a WEAK mood, not a third of one
	m.reset()
	m.bump(Mood.M.BARKY, Mood.ONSET + 0.01)
	m.tick(DT)
	_check(m.intensity < 0.1, "a mood that just landed is weak (%.3f)" % m.intensity)
	m.reset()
	m.bump(Mood.M.BARKY, 1.0)
	m.tick(DT)
	_check(m.intensity > 0.95, "a mood provoked in full is strong (%.3f)" % m.intensity)
	m.free()


func _test_every_mood_ends() -> void:
	print("\n--- every mood ends on its own (there is no cancel button) ---")
	for mk: int in [Mood.M.SCARED, Mood.M.BARKY, Mood.M.ZOOMIES, Mood.M.FLAT]:
		var m := _fresh()
		m.bump(mk, 1.0)
		m.tick(DT)
		_check(m.active == mk, "%s lands when provoked in full" % m.badge())
		var fade: float = float(Mood.FADE[mk])
		var name: String = m.badge()
		var elapsed := 0.0
		# generous ceiling: if it has not ended in twice its own fade, the
		# promise this design rests on is broken
		while m.active != Mood.M.HAPPY and elapsed < fade * 2.0:
			m.tick(DT)
			elapsed += DT
		_check(m.active == Mood.M.HAPPY,
			"%s ends by itself (took %.1fs, fade %.1fs)" % [name, elapsed, fade])
		# FADE is meant to be readable as "how long this mood lasts", so hold
		# it to that in both directions rather than just as a ceiling
		_check(absf(elapsed - fade) < 0.2,
			"%s lasts the fade it advertises (%.2fs vs %.1fs)" % [name, elapsed, fade])
		m.free()


func _test_grade_returns_home() -> void:
	print("\n--- the picture lands back exactly where it started ---")
	var m := _fresh()
	var home: Dictionary = Mood.GRADE[Mood.M.HAPPY]
	m.bump(Mood.M.SCARED, 1.0)
	for i in range(60 * 2):
		m.tick(DT)
	# mid-mood the grade must actually have moved, or none of this is doing
	# anything at all
	_check(m.active == Mood.M.SCARED, "still mid-mood two seconds in")
	_check(absf(float(m.grade()["sat"]) - float(home["sat"])) > 0.05,
		"the grade really moves while a mood is on (sat %.3f vs %.3f)" % [
			float(m.grade()["sat"]), float(home["sat"])])
	# ...and then come all the way back
	for i in range(60 * 40):
		m.tick(DT)
	_check(m.active == Mood.M.HAPPY, "mood is over")
	for key: String in home:
		var now: Variant = m.grade()[key]
		var want: Variant = home[key]
		if want is Vector3:
			_check((now as Vector3).distance_to(want as Vector3) < 0.002,
				"grade.%s returns home (%s vs %s)" % [key, now, want])
		else:
			_check(absf(float(now) - float(want)) < 0.002,
				"grade.%s returns home (%.4f vs %.4f)" % [key, float(now), float(want)])
	m.free()


func _test_strongest_wins() -> void:
	print("\n--- a real fright interrupts anything ---")
	var m := _fresh()
	m.bump(Mood.M.ZOOMIES, 0.6)
	m.tick(DT)
	_check(m.active == Mood.M.ZOOMIES, "zoomies running")
	# a bigger fright mid-zoomies takes over, because charges compete on merit
	# rather than on whichever fired most recently
	m.bump(Mood.M.SCARED, 0.9)
	m.tick(DT)
	_check(m.active == Mood.M.SCARED, "a bigger fright takes over")
	# and a smaller one does not
	m.reset()
	m.bump(Mood.M.ZOOMIES, 0.9)
	m.tick(DT)
	m.bump(Mood.M.BARKY, 0.45)
	m.tick(DT)
	_check(m.active == Mood.M.ZOOMIES, "a smaller provocation does not interrupt")
	m.free()


func _test_effects_bounded() -> void:
	print("\n--- no mood ever plays the game for you ---")
	# the table itself is the contract: nothing in it may exceed these, so a
	# later tuning pass cannot quietly turn a mood into an autopilot
	for mk: int in Mood.EFFECT:
		var e: Dictionary = Mood.EFFECT[mk]
		_check(float(e["speed"]) >= 0.75 and float(e["speed"]) <= 1.25,
			"speed effect stays within a quarter (%s -> %.2f)" % [Mood.BADGE[mk], float(e["speed"])])
		_check(float(e["accel"]) >= 0.5 and float(e["accel"]) <= 1.5,
			"accel effect stays reasonable (%s -> %.2f)" % [Mood.BADGE[mk], float(e["accel"])])
		# the nose may be dulled but never switched off: a mood makes the walk
		# harder to read, never impossible to finish
		_check(float(e["scent"]) >= 0.3,
			"scent is never fully blinded (%s -> %.2f)" % [Mood.BADGE[mk], float(e["scent"])])
		_check(float(e["pull"]) >= 0.7 and float(e["pull"]) <= 1.35,
			"pull effect stays within reason (%s -> %.2f)" % [Mood.BADGE[mk], float(e["pull"])])
	# the vignette must never close to a keyhole - the player keeps their frame
	for mk: int in Mood.GRADE:
		_check(float((Mood.GRADE[mk] as Dictionary)["vig"]) <= 0.60,
			"vignette never becomes a keyhole (%s)" % mk)
	# and the multipliers actually interpolate rather than snapping on
	var m := _fresh()
	m.bump(Mood.M.FLAT, 1.0)
	m.tick(DT)
	var full: float = m.speed_mult()
	_check(absf(full - float((Mood.EFFECT[Mood.M.FLAT] as Dictionary)["speed"])) < 0.02,
		"a full mood applies its full effect (%.3f)" % full)
	m.free()


func _test_wobble() -> void:
	print("\n--- the zoomies veer, reproducibly ---")
	var a := _fresh()
	var b := _fresh()
	a.bump(Mood.M.ZOOMIES, 1.0)
	b.bump(Mood.M.ZOOMIES, 1.0)
	var maxw := 0.0
	var same := true
	for i in range(60 * 5):
		a.tick(DT)
		b.tick(DT)
		if absf(a.wobble() - b.wobble()) > EPS:
			same = false
		maxw = maxf(maxw, absf(a.wobble()))
	_check(same, "two identical runs wobble identically (no RNG in the path)")
	_check(maxw > 0.05, "the wobble is actually doing something (%.3f rad)" % maxw)
	_check(maxw <= deg_to_rad(Mood.WOBBLE_DEG) + EPS,
		"the wobble stays inside its cap (%.3f rad <= %.3f)" % [maxw, deg_to_rad(Mood.WOBBLE_DEG)])
	# no other mood steers for you
	var c := _fresh()
	c.bump(Mood.M.SCARED, 1.0)
	for i in range(60):
		c.tick(DT)
	_check(is_equal_approx(c.wobble(), 0.0), "only the zoomies veer")
	a.free()
	b.free()
	c.free()


func _test_voice() -> void:
	print("\n--- the dog says it once ---")
	var m := _fresh()
	_check(m.badge() == "", "HAPPY wears no badge")
	m.bump(Mood.M.FLAT, 1.0)
	m.tick(DT)
	var first: String = m.take_onset()
	_check(first != "", "a mood arriving says its line: %s" % first)
	_check(m.take_onset() == "", "...and does not repeat it every frame")
	_check(m.badge() == "FLAT", "the badge names the mood")
	# every mood has both, or the HUD shows a blank
	for mk: int in [Mood.M.SCARED, Mood.M.BARKY, Mood.M.ZOOMIES, Mood.M.FLAT]:
		_check(String(Mood.SAID.get(mk, "")) != "", "mood %d has a line" % mk)
		_check(String(Mood.BADGE.get(mk, "")) != "", "mood %d has a badge" % mk)
		_check(Mood.FADE.has(mk) and Mood.EFFECT.has(mk) and Mood.GRADE.has(mk),
			"mood %d is fully described" % mk)
	m.free()
