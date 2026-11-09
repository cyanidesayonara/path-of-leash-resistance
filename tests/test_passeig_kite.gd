extends SceneTree

# Passeig Marítim's kite flyer (systems/kite_flyer.gd): the 0.8 s telegraph
# comes first and nothing can hurt anyone before it ends; the soft hazard only
# while the kite is low and only for a human who wanders into it; the pounce,
# bark and dodge rewards, each once; the conditions (clear or wind, dawn, day
# or dusk; never rain, snow or night, when the walk is as it was); the real
# hooks through main (points, patience, the speech bubbles); and the autowalk
# bot passing the whole event without a bump.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


# a kite already in the given state, as a fresh instance
func _kite(st: int, at: Vector2, height: float) -> KiteFlyer:
	var k := KiteFlyer.new()
	k.triggered = true
	k.state = st as KiteFlyer.State
	k.pos = at
	k.z = height
	return k


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "beach"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	# 1. The conditions: a kite flies in a breeze and in daylight
	for wx: String in ["clear", "wind"]:
		for hr: String in ["dawn", "day", "dusk"]:
			_check(KiteFlyer.flies_in(wx, hr), "a kite flies in %s at %s" % [wx, hr])
	for hr: String in ["dawn", "day", "dusk", "night"]:
		_check(not KiteFlyer.flies_in("rain", hr), "no kite in rain at %s" % hr)
		_check(not KiteFlyer.flies_in("snow", hr), "no kite in snow at %s" % hr)
	for wx: String in ["clear", "wind"]:
		_check(not KiteFlyer.flies_in(wx, "night"), "no kite at night in %s" % wx)

	_check(m.kite_flyer != null, "the kite flyer is on Passeig Marítim")
	var k: KiteFlyer = m.kite_flyer
	_check(k.state == KiteFlyer.State.IDLE, "starts idle, the kite aloft")
	_check(not k.triggered, "starts untriggered")

	# 2. The walk is as it was where it is not a kite's weather or hour
	var far_dog := Vector2(770.0, -3300.0)
	var at_trigger := Vector2(770.0, -3900.0)
	var mute := KiteFlyer.new()
	mute.sky_ok = false
	var out_mute: Dictionary = mute.tick(0.016, far_dog, at_trigger, true)
	_check(not bool(out_mute["warn"]) and mute.state == KiteFlyer.State.IDLE, "nothing starts when the sky is wrong")
	_check(not mute.on_bark(KiteFlyer.FLYER_POS), "a bark finds no kite when the sky is wrong")
	var quiet := ShapeBatch.new()
	mute.draw(m, quiet, -5000.0, -3000.0)
	_check(quiet._points.size() == 0, "nothing is drawn when the sky is wrong")
	var live := ShapeBatch.new()
	k.sky_ok = true
	k.draw(m, live, -5000.0, -3000.0)
	_check(live._points.size() > 0, "the flyer and his kite are drawn in a kite's sky")
	var away := ShapeBatch.new()
	k.draw(m, away, -2000.0, -1000.0)
	_check(away._points.size() == 0, "nothing is drawn when the view is elsewhere on the walk")

	# 3. Far away does nothing; the home leg never starts it
	var out_far: Dictionary = k.tick(0.016, far_dog, Vector2(770.0, -3000.0), true)
	_check(not bool(out_far["warn"]) and k.state == KiteFlyer.State.IDLE, "stays idle while the pair is far south")
	var home_leg := KiteFlyer.new()
	var out_home: Dictionary = home_leg.tick(0.016, far_dog, at_trigger, false)
	_check(not bool(out_home["warn"]) and home_leg.state == KiteFlyer.State.IDLE, "never starts on the home leg")
	var past := KiteFlyer.new()
	var out_past: Dictionary = past.tick(0.016, far_dog, Vector2(770.0, -4300.0), true)
	_check(not bool(out_past["warn"]), "a pair already past the flyer does not start it")

	# 4. The telegraph comes first, 0.8 s, and nothing hurts before it ends
	var out_warn: Dictionary = k.tick(0.016, far_dog, at_trigger, true)
	_check(bool(out_warn["warn"]), "crossing the trigger line starts the warning")
	_check(k.state == KiteFlyer.State.TELEGRAPH, "telegraph state")
	_check(k.timer <= KiteFlyer.WARN_DURATION and k.timer > 0.7, "timer is 0.8 s (%.2f)" % k.timer)
	_check(is_equal_approx(KiteFlyer.WARN_DURATION, 0.8), "telegraph duration is 0.8 s")
	# the human right under the kite, the dog right on it, mid-telegraph
	var under: Dictionary = k.tick(0.3, k.pos, k.pos, true)
	_check(not bool(under["bump"]) and not bool(under["pounce"]) and not bool(under["warn"]),
		"nothing happens to anyone during the telegraph")
	_check(k.state == KiteFlyer.State.TELEGRAPH, "still telegraphing at 0.3 s")
	var again: Dictionary = k.tick(0.2, far_dog, at_trigger, true)
	_check(not bool(again["warn"]), "the warning fires once")
	k.tick(0.35, far_dog, at_trigger, true)
	_check(k.state == KiteFlyer.State.DIVE, "dives after 0.8 s")

	# 5. The dive: high is harmless, then it comes down on the promenade
	k.tick(0.2, far_dog, KiteFlyer.HOME_POS, true)
	_check(k.z > KiteFlyer.HIT_Z, "early in the dive the kite is still high")
	var high := KiteFlyer.new()
	high.triggered = true
	high.state = KiteFlyer.State.DIVE
	var out_high: Dictionary = high.tick(0.2, far_dog, high.pos, true)
	_check(not bool(out_high["bump"]), "a high kite is no hazard to a human under it")
	var steps := 0
	while k.state == KiteFlyer.State.DIVE and steps < 200:
		k.tick(0.016, far_dog, far_dog, true)
		steps += 1
	_check(k.state == KiteFlyer.State.LOW, "lands and skids")
	_check(k.pos.is_equal_approx(KiteFlyer.LAND_POS), "lands at the landing zone")
	_check(k.pos.x - 770.0 < -100.0, "the landing zone is well off the promenade's centre line")

	# 6. Pounce: the dog pins the skidding kite, once
	var pin_dog := k.pos + Vector2(6.0, 0.0)
	var out_pin: Dictionary = k.tick(0.016, pin_dog, far_dog, true)
	_check(bool(out_pin["pounce"]), "the dog pounces on the low kite")
	_check(k.pounced and k.pin_t > 0.0, "the kite is pinned for a moment")
	var tail_kite := _kite(KiteFlyer.State.LOW, KiteFlyer.LAND_POS, 4.0)
	var out_tail_far: Dictionary = tail_kite.tick(0.016, KiteFlyer.LAND_POS + Vector2(0.0, 120.0), far_dog, true)
	_check(not bool(out_tail_far["pounce"]), "a dog across the paving does not pounce")
	var out_tail: Dictionary = tail_kite.tick(0.016, KiteFlyer.LAND_POS + Vector2(KiteFlyer.TAIL_REACH, 6.0), far_dog, true)
	_check(bool(out_tail["pounce"]), "a paw on the kite's tail holds the kite")
	var held := k.pos
	k.tick(0.2, pin_dog, far_dog, true)
	_check(k.pos == held, "a pinned kite does not move")
	var out_pin2: Dictionary = k.tick(0.016, pin_dog, far_dog, true)
	_check(not bool(out_pin2["pounce"]), "a pounce pays once")
	var skid := 0
	while k.state == KiteFlyer.State.LOW and skid < 600:
		k.tick(0.016, far_dog, far_dog, true)
		skid += 1
	_check(k.state == KiteFlyer.State.CLIMB, "the flyer hauls it in and it climbs again")
	_check(k.pos.x < KiteFlyer.LAND_POS.x - 100.0, "hauled back west along the paving")
	var climb := 0
	while k.state == KiteFlyer.State.CLIMB and climb < 200:
		k.tick(0.016, far_dog, far_dog, true)
		climb += 1
	_check(k.state == KiteFlyer.State.DONE, "back on its line, done")
	_check(k.z == KiteFlyer.HOME_Z, "back at full height")
	var out_done: Dictionary = k.tick(0.016, far_dog, at_trigger, true)
	_check(not bool(out_done["warn"]), "it never starts twice")

	# 7. The hazard: a human who wanders into the low kite is tangled, once
	var low := _kite(KiteFlyer.State.LOW, KiteFlyer.LAND_POS, 4.0)
	var wanderer := KiteFlyer.LAND_POS + Vector2(10.0, 0.0)
	var out_hit: Dictionary = low.tick(0.016, far_dog, wanderer, true)
	_check(bool(out_hit["bump"]), "a human in the kite's way is bumped")
	_check(low.human_hit, "human_hit is set")
	_check(low.bump_dir.x > 0.0, "the shove is away from the kite")
	var out_hit2: Dictionary = low.tick(0.016, far_dog, wanderer, true)
	_check(not bool(out_hit2["bump"]), "one bump per event")
	var calm := _kite(KiteFlyer.State.LOW, KiteFlyer.LAND_POS, 4.0)
	var out_calm: Dictionary = calm.tick(0.016, far_dog, Vector2(770.0, KiteFlyer.LAND_POS.y), true)
	_check(not bool(out_calm["bump"]), "a human on the promenade's centre line is not bumped")
	_check(KiteFlyer.BUMP_PATIENCE < 0.5, "a bump costs a fraction of patience")

	# 8. Bark: stalling or diving, within reach, once; then the kite climbs
	var stall := _kite(KiteFlyer.State.TELEGRAPH, KiteFlyer.HOME_POS, KiteFlyer.HOME_Z)
	_check(not stall.on_bark(Vector2(800.0, -2000.0)), "a bark from far away does nothing")
	_check(stall.on_bark(KiteFlyer.FLYER_POS + Vector2(60.0, 0.0)), "a bark near the flyer startles him")
	_check(stall.state == KiteFlyer.State.CLIMB, "the kite pops back up")
	_check(not stall.on_bark(KiteFlyer.FLYER_POS), "a bark pays once")
	var diving := _kite(KiteFlyer.State.DIVE, Vector2(500.0, -4090.0), 60.0)
	_check(diving.on_bark(Vector2(520.0, -4060.0)), "a bark in the dive pops the kite up")
	var skidding := _kite(KiteFlyer.State.LOW, KiteFlyer.LAND_POS, 4.0)
	_check(not skidding.on_bark(KiteFlyer.LAND_POS), "too late to bark once it is on the ground")
	var poppedup := _kite(KiteFlyer.State.DIVE, KiteFlyer.LAND_POS, 10.0)
	poppedup.on_bark(KiteFlyer.LAND_POS)
	var out_pop: Dictionary = poppedup.tick(0.016, far_dog, KiteFlyer.LAND_POS, true)
	_check(not bool(out_pop["bump"]), "a kite that popped up is not a hazard")

	# 9. Dodge: a close pass, then clear. Walking past without one earns nothing
	var near := _kite(KiteFlyer.State.LOW, KiteFlyer.LAND_POS, 4.0)
	var beside := KiteFlyer.LAND_POS + Vector2(KiteFlyer.HIT_R + 14.0, 0.0)
	var out_close: Dictionary = near.tick(0.0, far_dog, beside, true)
	_check(not bool(out_close["bump"]) and not bool(out_close["dodge"]), "close is not yet a save, nor a bump")
	_check(near.threatened, "a close pass is a threat")
	var out_clear: Dictionary = near.tick(0.0, far_dog, KiteFlyer.LAND_POS + Vector2(0.0, 140.0), true)
	_check(bool(out_clear["dodge"]), "stepping clear of a close pass is a save")
	_check(near.dodge_awarded, "dodge_awarded is set")
	var out_clear2: Dictionary = near.tick(0.0, far_dog, KiteFlyer.LAND_POS + Vector2(0.0, 140.0), true)
	_check(not bool(out_clear2["dodge"]), "a save pays once")
	var passer := _kite(KiteFlyer.State.LOW, KiteFlyer.LAND_POS, 4.0)
	passer.tick(0.016, far_dog, Vector2(770.0, KiteFlyer.LAND_POS.y), true)
	var out_passer: Dictionary = passer.tick(0.016, far_dog, Vector2(770.0, KiteFlyer.LAND_POS.y - 300.0), true)
	_check(not bool(out_passer["dodge"]), "walking clear without coming close is not a save")

	# 10. The same through main's hooks: points, patience, bubbles, the sky
	var Passeig: GDScript = load("res://systems/passeig.gd")
	m.started = true
	m.paused = false
	m.phase = "out"
	m.human.patience = 1.0
	m.human.global_position = at_trigger
	m.dog.global_position = far_dog
	var hk: KiteFlyer = KiteFlyer.new()
	m.kite_flyer = hk
	game.weather = "rain"
	game.hour = "day"
	Passeig.tick(m, 0.016)
	_check(hk.state == KiteFlyer.State.IDLE and not hk.sky_ok, "rain: no kite, the walk is as it was")
	game.weather = "clear"
	game.hour = "night"
	Passeig.tick(m, 0.016)
	_check(hk.state == KiteFlyer.State.IDLE and not hk.sky_ok, "night: no kite, the walk is as it was")
	game.weather = "snow"
	game.hour = "day"
	Passeig.tick(m, 0.016)
	_check(hk.state == KiteFlyer.State.IDLE and not hk.sky_ok, "snow: no kite")
	game.weather = "wind"
	game.hour = "dawn"
	Passeig.tick(m, 0.016)
	_check(hk.sky_ok and hk.state == KiteFlyer.State.TELEGRAPH, "wind at dawn, the campaign's own sky: the kite starts")
	Passeig.tick(m, 0.85)
	_check(hk.state == KiteFlyer.State.DIVE, "the dive follows the telegraph")

	# pounce and dodge through the hook, with the score
	hk.state = KiteFlyer.State.LOW
	hk.pos = KiteFlyer.LAND_POS
	hk.z = 3.0
	m.dog.global_position = KiteFlyer.LAND_POS + Vector2(4.0, 0.0)
	m.human.global_position = Vector2(770.0, KiteFlyer.LAND_POS.y + 400.0)
	var bones0: int = m.bones
	Passeig.tick(m, 0.016)
	_check(m.bones == bones0 + 2, "the pounce pays 2 bones")
	# a bump through the hook costs patience
	m.dog.global_position = Vector2(770.0, -2000.0)
	hk.pin_t = 0.0
	m.human.global_position = hk.pos + Vector2(6.0, 0.0)
	var patience0: float = m.human.patience
	Passeig.tick(m, 0.0)
	_check(m.human.patience < patience0 and m.human.patience >= patience0 - 0.1, "the bump costs a fraction of patience")
	# a bark through the hook
	var bk := KiteFlyer.new()
	m.kite_flyer = bk
	bk.state = KiteFlyer.State.DIVE
	bk.triggered = true
	bk.pos = Vector2(520.0, -4080.0)
	bk.z = 60.0
	m.dog.global_position = Vector2(500.0, -4060.0)
	var bones1: int = m.bones
	Passeig.on_bark(m, m.dog.global_position)
	_check(m.bones == bones1 + 2, "the bark pays 2 bones")
	_check(bk.state == KiteFlyer.State.CLIMB, "the bark pops the kite up")
	# a dodge through the hook
	var dk := _kite(KiteFlyer.State.LOW, KiteFlyer.LAND_POS, 4.0)
	m.kite_flyer = dk
	m.human.global_position = KiteFlyer.LAND_POS + Vector2(KiteFlyer.HIT_R + 14.0, 0.0)
	m.dog.global_position = Vector2(770.0, -2000.0)
	Passeig.tick(m, 0.0)
	var saves0: int = m.saves_done
	var bones2: int = m.bones
	m.human.global_position = KiteFlyer.LAND_POS + Vector2(0.0, 140.0)
	Passeig.tick(m, 0.0)
	_check(m.saves_done == saves0 + 1 and m.bones == bones2 + 2, "the dodge is a save and pays 2 bones")

	# 11. Other walks have no kite
	m.free()
	game.weather = "wind"
	game.hour = "dawn"
	game.level_id = "llevant"
	var ll: Node2D = load("res://main.tscn").instantiate()
	root.add_child(ll)
	if not ll.is_node_ready():
		await ll.ready
	_check(ll.kite_flyer == null, "Platja de Llevant keeps its surfer and has no kite")
	ll.free()

	# 12. The autowalk bot, in the campaign's own sky, passes the whole event
	game.level_id = "beach"
	game.weather = "wind"
	game.hour = "dawn"
	var am: Node2D = load("res://main.tscn").instantiate()
	root.add_child(am)
	if not am.is_node_ready():
		await am.ready
	game.weather = "wind"
	game.hour = "dawn"
	am.auto_walk = true
	am.dog.collision_mask = 0
	am.human.collision_mask = 0
	am.started = true
	am.frozen = false
	am.dog.global_position = Vector2(780.0, -3330.0)
	am.human.global_position = Vector2(770.0, -3280.0)
	am.leash.resnap()
	var ak: KiteFlyer = am.kite_flyer
	var frames := 0
	var nearest := INF
	while ak.state != KiteFlyer.State.DONE and frames < 1800:
		await physics_frame
		frames += 1
		if ak.is_low():
			nearest = minf(nearest, am.human.global_position.distance_to(ak.pos))
	print("autowalk: kite done in %d frames, nearest low pass %.0f px, pounced %s" % [frames, nearest, ak.pounced])
	_check(ak.triggered, "the autowalk pair set the event off")
	_check(ak.state == KiteFlyer.State.DONE, "the event ran its whole course (%d frames)" % frames)
	_check(not ak.human_hit, "the autowalk bot is never bumped")
	_check(not ak.dodge_awarded, "walking clear is not a save")
	_check(nearest > KiteFlyer.THREAT_R, "the bot never comes close to the low kite (%.0f px)" % nearest)
	am.free()

	print("test_passeig_kite: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
