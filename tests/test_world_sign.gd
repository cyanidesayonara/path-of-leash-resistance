extends SceneTree

# The walk's name is made of loose things on the ground (world/world_sign.gd):
# the letters are laid where they spell the name, a body moving through them
# shoves them, and each material behaves as it should - leaves scatter and
# stay scattered, cones go over when hit hard, suds pop, planted flowers
# spring back, puddles ring - while nothing about any of it pushes back on
# whoever went through. And the same name lies the same way twice.

const WorldSign := preload("res://world/world_sign.gd")

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	_run()
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_world_sign: OK")
		quit(0)
	else:
		quit(1)


# run a body straight up through the middle of the sign at `speed`
func _run_through(sg: Dictionary, speed: float, secs := 2.0) -> Array:
	var pos := Vector2(640.0, float(sg.bottom) + 60.0)
	var vel := Vector2(0.0, -speed)
	var toppled := 0
	var t := 0.0
	var dt := 1.0 / 60.0
	while t < secs:
		toppled += WorldSign.tick(sg, [[pos, vel, 15.0]], [], dt, t)
		pos += vel * dt
		t += dt
	# and let everything come to rest
	for i in range(240):
		WorldSign.tick(sg, [], [], dt, t)
		t += dt
	return [toppled, pos, vel]


func _moved(sg: Dictionary) -> int:
	var n := 0
	for pc: Dictionary in sg.pieces:
		if (pc.p as Vector2).distance_to(pc.home) > 4.0:
			n += 1
	return n


func _run() -> void:
	var at := Vector2(640.0, 0.0)
	var a := WorldSign.build("EL BARRI", at, 44.0, "leaves", 4.0, 600.0)
	var b := WorldSign.build("EL BARRI", at, 44.0, "leaves", 4.0, 600.0)
	_check(a.pieces.size() > 60, "the name is laid in plenty of leaves (%d)" % a.pieces.size())
	var same: bool = a.pieces.size() == b.pieces.size()
	for i in range(mini(a.pieces.size(), b.pieces.size())):
		same = same and (a.pieces[i].p as Vector2).is_equal_approx(b.pieces[i].p)
	_check(same, "the same name lies the same way twice")
	var inside := true
	for pc: Dictionary in a.pieces:
		var p: Vector2 = pc.p
		inside = inside and absf(p.x - 640.0) < 310.0 and p.y > float(a.top) - 5.0 and p.y < float(a.bottom) + 5.0
	_check(inside, "every leaf lies within the name's box")

	# leaves: run through, and they are scattered and stay that way
	var res := _run_through(a, 260.0)
	var moved := _moved(a)
	_check(moved >= 4, "a dog running through scatters leaves (%d moved)" % moved)
	_check((res[2] as Vector2).is_equal_approx(Vector2(0, -260.0)), "and nothing pushed back on the dog")
	_check(not bool(a.moving), "the leaves come to rest")
	_check(moved < a.pieces.size() / 2, "only the ones in the way move (%d of %d)" % [moved, a.pieces.size()])

	# cones: a walk past nudges, a sprint through bowls them over
	var cones := WorldSign.build("LES OBRES", at, 44.0, "cones", 1.0, 600.0)
	var slow := WorldSign.build("LES OBRES", at, 44.0, "cones", 1.0, 600.0)
	var fast_top: int = _run_through(cones, 360.0)[0]
	var slow_top: int = _run_through(slow, 60.0)[0]
	_check(fast_top > 0, "running into cones knocks them over (%d)" % fast_top)
	_check(slow_top == 0, "walking into them does not")

	# suds pop
	var suds := WorldSign.build("LA NETEJA", at, 44.0, "suds", 1.0, 600.0)
	_run_through(suds, 200.0)
	var popped := 0
	for pc: Dictionary in suds.pieces:
		if not bool(pc.alive):
			popped += 1
	_check(popped > 0, "running through the suds pops some (%d)" % popped)

	# a planted flowerbed springs back
	var bed := WorldSign.build("EL PARC", at, 44.0, "flowerbed", 1.0, 600.0)
	_run_through(bed, 260.0)
	_check(_moved(bed) == 0, "the flowerbed springs back once she is through (%d still out)" % _moved(bed))

	# fruit rolls further than leaves from the same shove
	var fruit := WorldSign.build("EL MERCAT", at, 44.0, "fruit", 1.0, 600.0)
	var lv := WorldSign.build("EL MERCAT", at, 44.0, "leaves", 1.0, 600.0)
	_run_through(fruit, 260.0)
	_run_through(lv, 260.0)
	_check(_far(fruit) > _far(lv), "fruit rolls further than leaves (%.0f vs %.0f)" % [_far(fruit), _far(lv)])

	# sticks are sticks: a shove turns them as well as moving them
	var sticks := WorldSign.build("EL BOSC", at, 44.0, "sticks", 1.0, 600.0)
	var rot0 := []
	for pc: Dictionary in sticks.pieces:
		rot0.append(float(pc.rot))
	_run_through(sticks, 260.0)
	var turned := false
	for i in range(sticks.pieces.size()):
		turned = turned or absf(float(sticks.pieces[i].rot) - float(rot0[i])) > 0.05
	_check(turned, "a stick knocked aside turns")

	# puddles do not move, but they ring
	var pud := WorldSign.build("EL DILUVI", at, 44.0, "puddle", 1.0, 600.0)
	var ringed := false
	var pos := Vector2(640.0, float(pud.bottom) + 40.0)
	var t := 0.0
	while t < 1.2:
		WorldSign.tick(pud, [[pos, Vector2(0, -200.0), 15.0]], [], 1.0 / 60.0, t)
		ringed = ringed or not (pud.rings as Array).is_empty()
		pos.y -= 200.0 / 60.0
		t += 1.0 / 60.0
	_check(ringed and pud.pieces.is_empty(), "a puddle rings when she runs through it")

	# the rope drags pieces too
	var rope_sign := WorldSign.build("EL BARRI", at, 44.0, "leaves", 2.0, 600.0)
	var rp := []
	for k in range(20):
		rp.append([Vector2(340.0 + k * 30.0, float(rope_sign.top) + (float(rope_sign.bottom) - float(rope_sign.top)) * 0.5), Vector2(0, -150.0)])
	for i in range(30):
		WorldSign.tick(rope_sign, [[Vector2(640.0, float(rope_sign.bottom) + 20.0), Vector2.ZERO, 15.0]], rp, 1.0 / 60.0, 0.0)
	_check(_moved(rope_sign) > 0, "a leash swept across the name drags pieces with it")

	_check(WorldSign.material_for("park", "snow") == "prints" and WorldSign.material_for("oldtown", "clear") == "",
		"snow writes in paw prints; a walk without a material keeps its drawn sign")


func _far(sg: Dictionary) -> float:
	var m := 0.0
	for pc: Dictionary in sg.pieces:
		m = maxf(m, (pc.p as Vector2).distance_to(pc.home))
	return m
