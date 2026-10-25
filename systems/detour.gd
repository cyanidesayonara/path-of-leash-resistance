extends RefCounted

const EventFeed := preload("res://hud/event_feed.gd")

# ARTSY DETOURS ("EXPOSICIÓ - ENTRADA LLIURE"):
# Hidden-in-plain-sight side rooms off major Barcelona walks.
# The first detour is "EL SOMNI" (Homage to Salvador Dalí's surrealist dreamscapes)
# located off Carrer del Gòtic (Walk 7: El Gòtic / "oldtown").
#
# Features:
# - Inviting street doorway on the Gòtic wall: carved stone arch, red carpet runner,
#   wrought-iron overhead banner ("EXPOSICIÓ - ENTRADA LLIURE" / "«EL SOMNI»"),
#   brass stanchions with velvet rope, and a gallery greeter.
# - Pocket gallery space at DETOUR_ORIGIN with desert sand floor, twilight gradient,
#   long raking metaphysical dream shadows, and distant stilt-legged silhouettes on the horizon.
# - 4 surreal melting bronze lampposts with droop elasticity and draped melting clocks:
#   tension from the leash bends the lampposts down elastically.
# - Floating secret Golden Dream Bone ("L'Os del Somni") on an obsidian & velvet plinth.
# - Exit portal arch marked "SORTIDA" returning pair smoothly back to Carrer del Gòtic
#   past the entrance with the leash neatly aligned.
# - The walk's timer and outside goals wait outside while inside the gallery.

const DETOUR_ORIGIN := Vector2(3600.0, -2200.0)
const ROOM_W := 760.0
const ROOM_H := 660.0
const ROOM_RECT := Rect2(DETOUR_ORIGIN, Vector2(ROOM_W, ROOM_H))

# Street entrance on El Gòtic (west wall near corner jink at y = -2150.0)
const STREET_DOOR_Y := -2150.0
const DOOR_TRIGGER_R := 46.0
const EXIT_TRIGGER_R := 44.0

# Room local coordinates (offset from DETOUR_ORIGIN)
const ROOM_ENTRY := Vector2(380.0, 530.0)
const ROOM_EXIT := Vector2(380.0, 95.0)
const BONE_POS := Vector2(380.0, 310.0)

# 4 Melting Lamppost offsets inside the gallery
const LAMP_OFFSETS: Array[Vector2] = [
	Vector2(230.0, 420.0),
	Vector2(530.0, 410.0),
	Vector2(270.0, 240.0),
	Vector2(490.0, 220.0),
]

static var droop_t: Array[float] = [0.0, 0.0, 0.0, 0.0]


static func _play_sfx(m: Node2D, sound: String, pitch := 1.0) -> void:
	if m != null and m.has_node("/root/Sfx"):
		m.get_node("/root/Sfx").play(sound, pitch)


# the melting lampposts in level space; world/level_build.gd registers them
# as rope poles with bodies, with the rest of the level's round posts
static func lamp_points() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for off: Vector2 in LAMP_OFFSETS:
		out.append(DETOUR_ORIGIN + off)
	return out


static func is_on(m: Node2D) -> bool:
	return m.lvl == "oldtown"


static func build_layer(m: Node2D) -> void:
	if not is_on(m):
		return
	var e: Vector2 = m.walk_edges(STREET_DOOR_Y)
	m.detour_door_pos = Vector2(e.x - 14.0, STREET_DOOR_Y)
	m.detour_return_pos = Vector2(e.x + 45.0, STREET_DOOR_Y - 70.0)
	m.detour_active = false
	m.detour_kind = "somni"
	m.detour_entered = false
	m.somni_bone_taken = false
	droop_t = [0.0, 0.0, 0.0, 0.0]

	# Build solid boundary walls for the detour gallery
	var walls := StaticBody2D.new()
	walls.name = "DetourWalls"
	walls.collision_layer = 1
	var defs := [
		# West wall
		Rect2(DETOUR_ORIGIN.x - 30.0, DETOUR_ORIGIN.y - 30.0, 30.0, ROOM_H + 60.0),
		# East wall
		Rect2(DETOUR_ORIGIN.x + ROOM_W, DETOUR_ORIGIN.y - 30.0, 30.0, ROOM_H + 60.0),
		# South wall
		Rect2(DETOUR_ORIGIN.x - 30.0, DETOUR_ORIGIN.y + ROOM_H, ROOM_W + 60.0, 30.0),
		# North wall (with opening for exit portal)
		Rect2(DETOUR_ORIGIN.x - 30.0, DETOUR_ORIGIN.y - 30.0, ROOM_W * 0.4, 30.0),
		Rect2(DETOUR_ORIGIN.x + ROOM_W * 0.6, DETOUR_ORIGIN.y - 30.0, ROOM_W * 0.4 + 30.0, 30.0),
	]
	for r: Rect2 in defs:
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = r.size
		cs.shape = sh
		cs.position = r.position + r.size * 0.5
		walls.add_child(cs)
	m.add_child(walls)

	# Add visual DetourLayer
	var layer := Node2D.new()
	layer.name = "DetourLayer"
	layer.set_script(load("res://world/detour_layer.gd"))
	# the gallery's floor and its props, under the pair (z 10) and the rope
	layer.z_index = 9
	m.add_child(layer)
	layer.setup(m)
	m.detour_layer = layer


static func tick(m: Node2D, delta: float) -> void:
	if not is_on(m) or m.frozen or m.auto_walk:
		return
	var dp: Vector2 = m.dog.global_position

	# Check doorway on Carrer del Gòtic
	if not m.detour_active:
		if dp.distance_to(m.detour_door_pos) < DOOR_TRIGGER_R:
			enter(m)
		return

	# Inside the detour room
	# 1. Update melting lampposts droop physics
	var leash_pts: Array[Vector2] = m.leash.pts if m.leash != null else []
	for i in range(LAMP_OFFSETS.size()):
		var lp: Vector2 = DETOUR_ORIGIN + LAMP_OFFSETS[i]
		var near := false
		if dp.distance_to(lp) < 40.0:
			near = true
		elif m.human != null and m.human.global_position.distance_to(lp) < 45.0:
			near = true
		else:
			for p: Vector2 in leash_pts:
				if p.distance_to(lp) < 28.0:
					near = true
					break
		if near:
			droop_t[i] = minf(1.0, droop_t[i] + delta * 6.0)
		else:
			droop_t[i] = maxf(0.0, droop_t[i] - delta * 2.5)

	# 2. Check secret Golden Dream Bone collection
	var bp: Vector2 = DETOUR_ORIGIN + BONE_POS
	if not m.somni_bone_taken and dp.distance_to(bp) < 34.0:
		m.somni_bone_taken = true
		_play_sfx(m, "pickup", 1.25)
		m.float_text(bp + Vector2(0.0, -32.0), "dream bone!", Color(1.0, 0.88, 0.2))
		m.feed.say("THE DREAM BONE! FINDERS KEEPERS", EventFeed.Tone.GOOD)

	# 3. Check exit portal
	var ep: Vector2 = DETOUR_ORIGIN + ROOM_EXIT
	if dp.distance_to(ep) < EXIT_TRIGGER_R:
		exit(m)


static func enter(m: Node2D) -> void:
	m.detour_active = true
	m.detour_entered = true
	m.dog.velocity = Vector2.ZERO
	m.human.velocity = Vector2.ZERO

	# Move pair inside gallery
	m.dog.global_position = DETOUR_ORIGIN + ROOM_ENTRY
	m.human.global_position = DETOUR_ORIGIN + ROOM_ENTRY + Vector2(0.0, 56.0)
	if m.leash != null:
		m.leash.resnap()

	m.cam_x_now = DETOUR_ORIGIN.x + ROOM_W * 0.5
	m.cam.position = Vector2(m.cam_x_now, DETOUR_ORIGIN.y + ROOM_H * 0.5)
	m.cam.reset_smoothing()

	_play_sfx(m, "ui", 0.95)
	m.feed.say("EL SOMNI: THE DREAM GALLERY", EventFeed.Tone.LOUD)
	m.float_text(m.dog.global_position + Vector2(0.0, -36.0), "welcome to el somni", Color(1.0, 0.92, 0.7), m.POP_SAY)


static func exit(m: Node2D) -> void:
	m.detour_active = false
	m.dog.velocity = Vector2.ZERO
	m.human.velocity = Vector2.ZERO

	# Return to street outside gallery
	m.dog.global_position = m.detour_return_pos
	m.human.global_position = m.detour_return_pos + Vector2(0.0, 48.0)
	if m.leash != null:
		m.leash.resnap()

	m.cam_x_now = 640.0
	m.cam.position = m.dog.global_position
	m.cam.reset_smoothing()

	_play_sfx(m, "ui", 1.05)
	m.feed.say("BACK OUT ON EL GÒTIC", EventFeed.Tone.PLAIN)


static func cam_x(m: Node2D) -> float:
	var hw: float = m.get_viewport_rect().size.x / (2.0 * m.cam.zoom.x)
	var lo: float = DETOUR_ORIGIN.x + 40.0
	var hi: float = DETOUR_ORIGIN.x + ROOM_W - 40.0
	if hi - lo <= hw * 2.0:
		return (lo + hi) * 0.5
	return clampf(m.dog.global_position.x, lo + hw, hi - hw)


static func walk_edges(m: Node2D, y: float) -> Vector2:
	return Vector2(DETOUR_ORIGIN.x + 60.0, DETOUR_ORIGIN.x + ROOM_W - 60.0)
