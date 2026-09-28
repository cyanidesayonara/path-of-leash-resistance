extends SceneTree

# El Bosc's boars (entities/boar.gd) and fallen trunks. The sow and her
# piglets cross the trail, piglets first. Crowd the piglets or bark at her
# and she snorts before she charges (never a charge without the snort), and
# the charge knocks the dog over. The owner gets the warning bubble before
# the shove, never the shove first. A fallen trunk stops the dog; the owner
# steps over it. And the owner's weave follows the trail through its pinch.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _family(m: Node2D) -> Node2D:
	var LevelBuild: GDScript = load("res://world/level_build.gd")
	var e: Vector2 = m.walk_edges(LevelBuild.TRAIL_BOAR_Y)
	var bo := Node2D.new()
	bo.set_script(load("res://entities/boar.gd"))
	m.add_child(bo)
	bo.setup(m, m.dog, m.human, LevelBuild.TRAIL_BOAR_Y, e.x - 40.0, e.y + 80.0)
	return bo


func _step(bo: Node2D, secs: float) -> void:
	var n := int(secs * 60.0)
	for i in range(n):
		bo._physics_process(1.0 / 60.0)
		bo.main.elapsed += 1.0 / 60.0


func _run() -> void:
	var LevelBuild: GDScript = load("res://world/level_build.gd")
	var game: Node = root.get_node("Game")
	game.level_id = "trail"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.frozen = false
	var dog: CharacterBody2D = m.dog
	var human: CharacterBody2D = m.human
	var far := Vector2(m.walk_cx, -600.0)

	# the crossing: piglets ahead, and the family leaves at the far side
	var bo := _family(m)
	dog.global_position = far
	human.global_position = far + Vector2(40, 0)
	_check(bo.piglet_pos(0).x > bo.global_position.x, "the piglets cross ahead of her")
	var x0: float = bo.global_position.x
	_step(bo, 2.0)
	_check(bo.global_position.x > x0 + 50.0 and bo.state == bo.S.CROSS, "left alone, the family keeps crossing")
	_step(bo, 40.0)
	_check(not is_instance_valid(bo) or bo.is_queued_for_deletion(), "and goes off into the wood on the far side")
	await process_frame

	# crowding the piglets: a snort first, then the charge, then she knocks the dog
	bo = _family(m)
	_step(bo, 3.0)
	dog.global_position = bo.piglet_pos(1) + Vector2(0, 30)
	_step(bo, 1.0 / 60.0)
	_check(bo.state == bo.S.ALARM, "crowding a piglet makes her snort")
	_step(bo, bo.ALARM_T * 0.8)
	_check(bo.state == bo.S.ALARM, "she scrapes for the whole warning before she goes")
	var hits_before: int = m.dog_hits
	_step(bo, bo.ALARM_T * 0.3 + bo.CHARGE_T)
	_check(bo.charges == 1, "then she charges")
	_check(m.dog_hits == hits_before + 1, "and the charge knocks the dog over")
	bo.queue_free()
	await process_frame

	# barking at her sets her off too
	bo = _family(m)
	dog.global_position = far
	_step(bo, 3.0)
	m.on_bark(bo.global_position + Vector2(0, 120))
	_check(bo.state == bo.S.ALARM, "barking at a boar provokes her")
	bo.queue_free()
	await process_frame

	# the owner: warned first, shoved only after the warning has been up
	bo = _family(m)
	dog.global_position = far
	_step(bo, 3.0)
	human.global_position = bo.global_position + Vector2(0, 100)
	_step(bo, 1.0 / 60.0)
	_check(bo.owner_warn_t >= 0.0 and human.bubble.visible, "the owner gets a bubble when she is close")
	human.global_position = bo.global_position + Vector2(0, 20)
	_step(bo, 0.2)
	_check(bo.shoves == 0, "no shove before the warning has been up for OWNER_WARN_T")
	for i in range(60):
		human.global_position = bo.global_position + Vector2(0, 20)
		_step(bo, 1.0 / 60.0)
	_check(bo.shoves == 1, "then the owner walks into her and is shoved")
	bo.queue_free()
	await process_frame

	# the fallen trunk: the dog cannot go through it, the owner steps over
	var lr: Rect2 = LevelBuild.trail_logs(m)[0]
	var below := Vector2(lr.get_center().x - 20.0, lr.end.y + 30.0)
	dog.global_position = below
	for i in range(40):
		dog.velocity = Vector2(0.0, -500.0)
		dog.move_and_slide()
	_check(dog.global_position.y > lr.position.y, "the dog cannot walk through a fallen trunk")
	human.global_position = below
	for i in range(40):
		human.velocity = Vector2(0.0, -500.0)
		human.move_and_slide()
	_check(human.global_position.y < lr.position.y, "the owner steps over it")

	# the owner's weave follows the trail through the pinch
	var inside := true
	for y in [-1800.0, -1950.0, -2000.0, -2100.0, -2200.0]:
		var e: Vector2 = m.walk_edges(y)
		human.global_position = Vector2((e.x + e.y) * 0.5, y)
		human.velocity = Vector2.ZERO
		# a minute of weaving, held at this height
		for f in range(1800):
			m.elapsed += 1.0 / 30.0
			human._walk(1.0 / 30.0)
			human.global_position.y = y
			inside = inside and human.global_position.x > e.x and human.global_position.x < e.y
	_check(inside, "the owner's weave stays on the trail through the pinch")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_boar: OK")
		quit(0)
	else:
		quit(1)
