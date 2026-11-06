extends RefCounted

const EventFeed := preload("res://hud/event_feed.gd")
const Gotic := preload("res://world/gotic.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const LevelBuild := preload("res://world/level_build.gd")

# ARTSY DETOURS ("EXPOSICIÓ - ENTRADA LLIURE"):
# Hidden-in-plain-sight side rooms off major Barcelona walks.
# 1. "EL SOMNI" (Homage to Salvador Dalí's surrealist dreamscapes)
#    located off Carrer del Gòtic (Walk 7: El Gòtic / "oldtown").
# 2. "L'ESTEL" (Homage to Joan Miró's primary shapes, constellations and starry ladders)
#    located off Montjuïc (Walk 16: Montjuïc / "montjuic").
#
# Features:
# - Inviting street doorway on the walk's wall:
#   - El Gòtic: carved stone arch, red carpet runner, wrought-iron overhead banner
#     ("EXPOSICIÓ - ENTRADA LLIURE" / "«EL SOMNI»"), brass stanchions, velvet rope, and greeter.
#   - Montjuïc: crisp white modernist pavilion arch, primary red/blue/yellow accents,
#     banner ("EXPOSICIÓ - ENTRADA LLIURE" / "«L'ESTEL»"), brass stanchions, and greeter.
# - Pocket gallery spaces at isolated level coordinates:
#   - El Somni (DETOUR_ORIGIN): desert sand floor, twilight horizon, stilt-legged silhouettes,
#     4 surreal melting lampposts with droop elasticity and melting clocks, and Golden Dream Bone.
#   - L'Estel (ESTEL_ORIGIN): white modernist floor with primary yellow/blue/red field insets,
#     thick black calligraphic wall murals (asterisks, crescent moons, eyes), 4 biomorphic
#     primary-shape sculptures wrapped by the leash, 3 Starry Ladders ("L'Escala de l'Evasió"),
#     and the secret Golden Star Bone ("L'Os de l'Estel") on a modernist cube pedestal.
# - Exit portal arch marked "SORTIDA" returning pair smoothly back to the walk.
# - The walk's timer and outside goals wait outside while inside the gallery.

const DETOUR_ORIGIN := Vector2(3600.0, -2200.0)
const ESTEL_ORIGIN := Vector2(5400.0, -3400.0)
const ROOM_W := 760.0
const ROOM_H := 660.0
const ROOM_RECT := Rect2(DETOUR_ORIGIN, Vector2(ROOM_W, ROOM_H))
const ESTEL_RECT := Rect2(ESTEL_ORIGIN, Vector2(ROOM_W, ROOM_H))

# Street entrances
const STREET_DOOR_Y := -2150.0
const ESTEL_DOOR_Y := -3350.0
const DOOR_TRIGGER_R := 46.0
const EXIT_TRIGGER_R := 44.0

# Room local coordinates (offset from room origin)
const ROOM_ENTRY := Vector2(380.0, 530.0)
const ROOM_EXIT := Vector2(380.0, 95.0)
const BONE_POS := Vector2(380.0, 310.0)

# 4 Melting Lamppost offsets inside El Somni gallery
const LAMP_OFFSETS: Array[Vector2] = [
	Vector2(230.0, 420.0),
	Vector2(530.0, 410.0),
	Vector2(270.0, 240.0),
	Vector2(490.0, 220.0),
]

# 4 Biomorphic Sculpture offsets inside L'Estel gallery (rope poles)
const SCULPTURE_OFFSETS: Array[Vector2] = [
	Vector2(240.0, 420.0), # Solar Disc: Vermilion red disc with black horn
	Vector2(520.0, 410.0), # Celestial Droplet: Ultramarine blue droplet with yellow star
	Vector2(260.0, 240.0), # Orbital Cylinder: Cadmium yellow column with black ring
	Vector2(500.0, 220.0), # Calligraphic Totem: Deep black totem with eye motif
]

# 3 Starry Ladders ("L'Escala de l'Evasió") inside L'Estel gallery
const LADDER_OFFSETS: Array[Vector2] = [
	Vector2(170.0, 320.0),
	Vector2(590.0, 320.0),
	Vector2(380.0, 180.0),
]

static var droop_t: Array[float] = [0.0, 0.0, 0.0, 0.0]
static var ladder_cooldown: Array[float] = [0.0, 0.0, 0.0]


static func _play_sfx(m: Node2D, sound: String, pitch := 1.0) -> void:
	if m != null and m.has_node("/root/Sfx"):
		m.get_node("/root/Sfx").play(sound, pitch)


static func origin_for(m: Node2D) -> Vector2:
	if m != null and (m.detour_kind == "estel" or m.lvl == "montjuic"):
		return ESTEL_ORIGIN
	return DETOUR_ORIGIN


static func room_rect_for(m: Node2D) -> Rect2:
	return Rect2(origin_for(m), Vector2(ROOM_W, ROOM_H))


# the poles in level space; world/level_build.gd registers them
# as rope poles with bodies, with the rest of the level's round posts
static func lamp_points(m: Node2D = null) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if m != null and m.lvl == "montjuic":
		for off: Vector2 in SCULPTURE_OFFSETS:
			out.append(ESTEL_ORIGIN + off)
		return out
	for off: Vector2 in LAMP_OFFSETS:
		out.append(DETOUR_ORIGIN + off)
	return out


static func is_on(m: Node2D) -> bool:
	return m.lvl == "oldtown" or m.lvl == "montjuic"


static func build_layer(m: Node2D) -> void:
	if not is_on(m):
		return
	var is_estel: bool = m.lvl == "montjuic"
	var door_y: float = ESTEL_DOOR_Y if is_estel else STREET_DOOR_Y
	var o: Vector2 = ESTEL_ORIGIN if is_estel else DETOUR_ORIGIN
	var e: Vector2 = m.walk_edges(door_y)

	m.detour_door_pos = Vector2(e.x - 14.0, door_y)
	m.detour_return_pos = Vector2(e.x + 45.0, door_y - 70.0)
	m.detour_active = false
	m.detour_kind = "estel" if is_estel else "somni"
	m.detour_entered = false
	if is_estel:
		m.estel_bone_taken = false
		m.estel_ladders_climbed = 0
		ladder_cooldown = [0.0, 0.0, 0.0]
	else:
		m.somni_bone_taken = false
		droop_t = [0.0, 0.0, 0.0, 0.0]

	# Build solid boundary walls for the detour gallery
	var walls := StaticBody2D.new()
	walls.name = "DetourWalls"
	walls.collision_layer = 1
	var defs := [
		# West wall
		Rect2(o.x - 30.0, o.y - 30.0, 30.0, ROOM_H + 60.0),
		# East wall
		Rect2(o.x + ROOM_W, o.y - 30.0, 30.0, ROOM_H + 60.0),
		# South wall
		Rect2(o.x - 30.0, o.y + ROOM_H, ROOM_W + 60.0, 30.0),
		# North wall (with opening for exit portal)
		Rect2(o.x - 30.0, o.y - 30.0, ROOM_W * 0.4, 30.0),
		Rect2(o.x + ROOM_W * 0.6, o.y - 30.0, ROOM_W * 0.4 + 30.0, 30.0),
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
	var is_estel: bool = m.detour_kind == "estel" or (not m.detour_active and m.lvl == "montjuic")

	# Check doorway on street
	if not m.detour_active:
		if dp.distance_to(m.detour_door_pos) < DOOR_TRIGGER_R:
			enter(m)
		return

	var o: Vector2 = origin_for(m)

	if is_estel:
		# L'Estel gallery tick
		# 1. Update Starry Ladders ("L'Escala de l'Evasió")
		for i in range(LADDER_OFFSETS.size()):
			if ladder_cooldown[i] > 0.0:
				ladder_cooldown[i] = maxf(0.0, ladder_cooldown[i] - delta)
			var lp: Vector2 = o + LADDER_OFFSETS[i]
			if dp.distance_to(lp) < 36.0 and ladder_cooldown[i] <= 0.0:
				ladder_cooldown[i] = 1.0
				m.estel_ladders_climbed += 1
				_play_sfx(m, "star", 1.25 + i * 0.15)
				m.float_text(dp + Vector2(0.0, -22.0), "ladder to the stars!", Color(1.0, 0.9, 0.3))

		# 2. Check secret Golden Star Bone collection
		var bp: Vector2 = o + BONE_POS
		if not m.estel_bone_taken and dp.distance_to(bp) < 34.0:
			m.estel_bone_taken = true
			_play_sfx(m, "pickup", 1.30)
			m.float_text(bp + Vector2(0.0, -32.0), "star bone!", Color(1.0, 0.88, 0.2))
			m.feed.say("L'ESTEL: THE STAR BONE! TO THE STARS", EventFeed.Tone.GOOD)

		# 3. Check exit portal
		var ep: Vector2 = o + ROOM_EXIT
		if dp.distance_to(ep) < EXIT_TRIGGER_R:
			exit(m)
	else:
		# El Somni gallery tick
		# 1. Update melting lampposts droop physics
		var leash_pts: Array[Vector2] = m.leash.pts if m.leash != null else []
		for i in range(LAMP_OFFSETS.size()):
			var lp: Vector2 = o + LAMP_OFFSETS[i]
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
		var bp: Vector2 = o + BONE_POS
		if not m.somni_bone_taken and dp.distance_to(bp) < 34.0:
			m.somni_bone_taken = true
			_play_sfx(m, "pickup", 1.25)
			m.float_text(bp + Vector2(0.0, -32.0), "dream bone!", Color(1.0, 0.88, 0.2))
			m.feed.say("THE DREAM BONE! FINDERS KEEPERS", EventFeed.Tone.GOOD)

		# 3. Check exit portal
		var ep: Vector2 = o + ROOM_EXIT
		if dp.distance_to(ep) < EXIT_TRIGGER_R:
			exit(m)


static func enter(m: Node2D) -> void:
	m.detour_active = true
	m.detour_entered = true
	m.dog.velocity = Vector2.ZERO
	m.human.velocity = Vector2.ZERO

	var o: Vector2 = origin_for(m)
	var is_estel: bool = m.detour_kind == "estel"

	# Move pair inside gallery
	m.dog.global_position = o + ROOM_ENTRY
	m.human.global_position = o + ROOM_ENTRY + Vector2(0.0, 56.0)
	if m.leash != null:
		m.leash.resnap()

	m.cam_x_now = o.x + ROOM_W * 0.5
	m.cam.position = Vector2(m.cam_x_now, o.y + ROOM_H * 0.5)
	m.cam.reset_smoothing()

	_play_sfx(m, "ui", 0.95)
	if is_estel:
		m.feed.say("L'ESTEL: THE STAR GALLERY", EventFeed.Tone.LOUD)
		m.float_text(m.dog.global_position + Vector2(0.0, -36.0), "Welcome to L'Estel!", Color(1.0, 0.92, 0.7), m.POP_SAY)
	else:
		m.feed.say("EL SOMNI: THE DREAM GALLERY", EventFeed.Tone.LOUD)
		m.float_text(m.dog.global_position + Vector2(0.0, -36.0), "Welcome to El Somni!", Color(1.0, 0.92, 0.7), m.POP_SAY)


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
	if m.detour_kind == "estel":
		m.feed.say("BACK OUT ON MONTJUÏC", EventFeed.Tone.PLAIN)
	else:
		m.feed.say("BACK OUT ON EL GÒTIC", EventFeed.Tone.PLAIN)


static func cam_x(m: Node2D) -> float:
	var o: Vector2 = origin_for(m)
	var hw: float = m.get_viewport_rect().size.x / (2.0 * m.cam.zoom.x)
	var lo: float = o.x + 40.0
	var hi: float = o.x + ROOM_W - 40.0
	if hi - lo <= hw * 2.0:
		return (lo + hi) * 0.5
	return clampf(m.dog.global_position.x, lo + hw, hi - hw)


static func walk_edges(m: Node2D, _y: float) -> Vector2:
	var o: Vector2 = origin_for(m)
	return Vector2(o.x + 60.0, o.x + ROOM_W - 60.0)


# --- main's walk hooks (main.WALK_MODULES): El Gòtic's picture, in world/gotic.gd

# the alley, up to the gate
static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.scooter:
		m.scooter.draw(m, wc, vt, vb)
	Gotic.draw_street(m, maxf(vt, m.GATE_Y - 30.0), vb)


# the Pont del Bisbe over the alley, above everyone
static func draw_overhead(m: Node2D, c: CanvasItem) -> void:
	var by: float = LevelBuild.GOTIC_BRIDGE_Y
	var e: Vector2 = m.walk_edges(by)
	var b := ShapeBatch.new(c)
	Gotic.draw_bridge(b, by, e)
	b.flush()


# El Gòtic's plaça sits in the same roofscape as the alleys
static func draw_freedom(m: Node2D, c: Object) -> void:
	Gotic.draw_roofs_round_placa(m, c)
	m._draw_placa(c)


# the posts down the alley are the old town's cast-iron bollards
static func draw_column(m: Node2D, _wc: ShapeBatch, p: Vector2) -> void:
	m._draw_bollard(p)


# the plaça's fountain draws with the plaça
static func draw_fountain(_m: Node2D, _f: Vector2) -> void:
	pass
