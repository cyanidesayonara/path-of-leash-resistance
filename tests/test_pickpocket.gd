extends SceneTree

# La Rambla's pickpockets (entities/pickpocket.gd). The tell is on screen for
# STALK_MIN before any lift; a bark while he is stalking busts him; once he
# runs, the dog at speed, the leash across his legs and a seller's blanket all
# put him down and the wallet goes back (and pays); going down by an open
# manhole loses the wallet and earns nothing; and a thief who takes the
# owner's wallet and gets away fails the "keep your human's wallet" goal.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _step(pp: Node2D, secs: float) -> void:
	for i in range(int(secs * 60.0)):
		if not is_instance_valid(pp):
			return
		pp._physics_process(1.0 / 60.0)
		pp.main.elapsed += 1.0 / 60.0


func _tourist(m: Node2D, at: Vector2) -> Node2D:
	var tw := Node2D.new()
	tw.set_script(load("res://entities/tourist.gd"))
	m.add_child(tw)
	var r := RandomNumberGenerator.new()
	r.seed = 7
	tw.setup(m, r, at, -1.0)
	tw.speed = 0.0
	tw.next_photo = 999.0
	return tw


func _thief(m: Node2D, at: Vector2, mark: Node2D, is_owner: bool) -> Node2D:
	var pp := Node2D.new()
	pp.set_script(load("res://entities/pickpocket.gd"))
	m.add_child(pp)
	pp.setup(m, at, mark, is_owner, 1.0)
	return pp


# stalk and lift, so he is running with the wallet
func _running(m: Node2D, mark: Node2D, is_owner: bool) -> Node2D:
	var pp := _thief(m, mark.global_position + Vector2(0, 40), mark, is_owner)
	_step(pp, pp.STALK_MIN + pp.LIFT_T + 0.3)
	_step(pp, 0.5)
	return pp


# lay the whole rope along a line (it must keep its points: the game reads it)
func _rope(m: Node2D, a: Vector2, b: Vector2) -> void:
	var n: int = m.leash.pts.size()
	for i in range(n):
		m.leash.pts[i] = a.lerp(b, float(i) / float(maxi(n - 1, 1)))


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.level_id = "street"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.frozen = false
	var ids: Array = []
	for q: Dictionary in m.active_quests:
		ids.append(q.id)
	_check("thief" in ids and "wallet" in ids, "La Rambla has the pickpocket goals")
	var dog: CharacterBody2D = m.dog
	var human: CharacterBody2D = m.human
	var here := Vector2(640.0, -2300.0)
	human.global_position = Vector2(640.0, -600.0)
	dog.global_position = Vector2(640.0, -700.0)
	dog.velocity = Vector2.ZERO
	_rope(m, Vector2(-4000, 0), Vector2(-4000, 40))
	for tw: Node2D in m.get_tree().get_nodes_in_group("tourists"):
		tw.queue_free()
	m.blankets.clear()
	m.manholes.clear()
	# and nothing slippery lying about (La Rambla's dropped ice cream)
	m.patches.clear()

	# the tell comes first: no lift before STALK_MIN, however close he is
	var tw := _tourist(m, here)
	var pp := _thief(m, here + Vector2(8, 24), tw, false)
	_step(pp, pp.STALK_MIN * 0.7)
	_check(pp.state == pp.S.STALK and tw.has_wallet, "no lift before the tell has been up for STALK_MIN")
	_step(pp, pp.STALK_MIN * 0.5 + pp.LIFT_T + 0.1)
	_check(pp.state == pp.S.RUN and not tw.has_wallet, "then the lift, and he runs with the wallet")
	# the dog at a run bowls him over and the wallet goes back
	var bones0: int = m.bones
	dog.global_position = pp.global_position
	dog.velocity = Vector2(0, -300)
	_step(pp, 1.0 / 60.0)
	_check(pp.state == pp.S.DOWN and pp.down_why == "bump", "the dog at a run bowls him over")
	_check(m.thieves_stopped == 1 and tw.has_wallet and m.bones > bones0, "and the wallet goes back, and pays")
	_step(pp, pp.DOWN_T + 0.1)
	_check(pp.state == pp.S.SLINK, "he gets up and slinks off")
	pp.queue_free()
	tw.queue_free()
	dog.global_position = Vector2(640.0, -700.0)
	dog.velocity = Vector2.ZERO
	await process_frame

	# a bark while he stalks busts him before the lift
	tw = _tourist(m, here)
	pp = _thief(m, here + Vector2(8, 60), tw, false)
	_step(pp, 0.5)
	m.on_bark(pp.global_position + Vector2(0, 60))
	_check(pp.state == pp.S.SLINK and tw.has_wallet and m.thieves_stopped == 2, "a bark during the stalk busts him")
	pp.queue_free()
	tw.queue_free()
	await process_frame

	# the leash across his legs
	tw = _tourist(m, here)
	pp = _running(m, tw, false)
	var at: Vector2 = pp.global_position + pp.run_dir * 10.0
	_rope(m, at + Vector2(-60, 0), at + Vector2(60, 0))
	_step(pp, 0.2)
	_check(pp.state == pp.S.DOWN and pp.down_why == "tangle", "the leash across his path trips him")
	_rope(m, Vector2(-4000, 0), Vector2(-4000, 40))
	pp.queue_free()
	tw.queue_free()
	await process_frame

	# a seller's blanket underfoot
	tw = _tourist(m, here)
	pp = _running(m, tw, false)
	var bat: Vector2 = pp.global_position + pp.run_dir * 12.0
	m.blankets.append({"rect": Rect2(bat - Vector2(40, 30), Vector2(80, 60)), "goods": "bags", "cd": 0.0})
	_step(pp, 0.2)
	_check(pp.state == pp.S.DOWN and pp.down_why == "blanket", "a seller's blanket trips him")
	m.blankets.clear()
	pp.queue_free()
	tw.queue_free()
	await process_frame

	# a dropped ice cream underfoot
	tw = _tourist(m, here)
	pp = _running(m, tw, false)
	var iat: Vector2 = pp.global_position + pp.run_dir * 10.0
	m.patches.append({"y": iat.y, "at": 0.0, "rx": 24.0, "ry": 18.0, "seed": 1.0, "kind": "icecream", "pin": iat})
	_step(pp, 0.2)
	_check(pp.state == pp.S.DOWN and pp.down_why == "slip", "he slips on a dropped ice cream")
	m.patches.clear()
	pp.queue_free()
	tw.queue_free()
	await process_frame

	# down by an open manhole: stopped, but the wallet is gone
	tw = _tourist(m, here)
	pp = _running(m, tw, false)
	var stopped_before: int = m.thieves_stopped
	m.manholes.append(pp.global_position)
	dog.global_position = pp.global_position
	dog.velocity = Vector2(0, -300)
	_step(pp, 1.0 / 60.0)
	_check(pp.state == pp.S.DOWN and pp.wallet_lost, "going down by an open manhole loses the wallet")
	_check(m.thieves_stopped == stopped_before and not tw.has_wallet, "and earns nothing")
	m.manholes.clear()
	pp.queue_free()
	tw.queue_free()
	dog.global_position = Vector2(640.0, -700.0)
	dog.velocity = Vector2.ZERO
	await process_frame

	# the owner's wallet: taken, and he gets away with it
	var wallet_goal: Callable = Callable()
	for q: Dictionary in m.active_quests:
		if q.id == "wallet":
			wallet_goal = q.fn
	_check(int(wallet_goal.call()) == 1, "the human's wallet goal holds at the start")
	human.global_position = here
	pp = _thief(m, here + Vector2(0, 60), human, true)
	_step(pp, pp.STALK_MIN + pp.LIFT_T + 0.3)
	_check(m.owner_wallet_taken and int(wallet_goal.call()) == 0, "a lift from the owner fails the wallet goal while he has it")
	pp.run_to = pp.global_position + Vector2(0, -30)
	_step(pp, 0.5)
	_check(m.owner_wallet_lost and pp.state == pp.S.GONE, "he gets away, and the human's wallet is gone")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_pickpocket: OK")
		quit(0)
	else:
		quit(1)
