extends Node2D

const DetourScript := preload("res://systems/detour.gd")

var main: Node2D

const C_SAND := Color(0.90, 0.80, 0.58)
const C_DUNE := Color(0.84, 0.72, 0.50)
const C_SHADOW := Color(0.18, 0.14, 0.32, 0.38)
const C_BRONZE := Color(0.38, 0.28, 0.20)
const C_BRONZE_HI := Color(0.62, 0.48, 0.32)
const C_CLOCK := Color(0.96, 0.94, 0.88)
const C_CLOCK_GOLD := Color(0.85, 0.70, 0.25)
const C_PLINTH := Color(0.20, 0.20, 0.24)
const C_VELVET := Color(0.14, 0.22, 0.45)
const C_GOLD := Color(1.0, 0.88, 0.25)
const C_CARPET := Color(0.72, 0.12, 0.18)
const C_CARPET_GOLD := Color(0.92, 0.78, 0.25)
const C_BANNER := Color(0.55, 0.10, 0.16)
const C_BRASS := Color(0.88, 0.74, 0.32)


func setup(m: Node2D) -> void:
	main = m


func _process(_delta: float) -> void:
	if main == null:
		return
	var cy: float = main.cam.position.y
	var near_door := absf(cy - DetourScript.STREET_DOOR_Y) < 650.0
	if main.detour_active or near_door:
		queue_redraw()


func _draw() -> void:
	if main == null:
		return
	var b := ShapeBatch.new(self)
	var t: float = AnimClock.msec() / 1000.0

	# 1. STREET ENTRANCE ON CARRER DEL GÒTIC
	_draw_street_doorway(b, t)

	# 2. INSIDE THE SURREAL DETOUR GALLERY ("EL SOMNI")
	if main.detour_active or absf(main.cam.position.y - (DetourScript.DETOUR_ORIGIN.y + DetourScript.ROOM_H * 0.5)) < 700.0:
		_draw_somni_gallery(b, t)

	b.flush()
	_draw_labels()


func _draw_street_doorway(b: ShapeBatch, t: float) -> void:
	var dp: Vector2 = main.detour_door_pos
	if dp == Vector2.ZERO:
		return

	# Stone arch doorway cutout in Gothic wall
	var door_rect := Rect2(dp.x - 32.0, dp.y - 48.0, 44.0, 96.0)
	b.rect(door_rect, Color(0.12, 0.10, 0.11))
	# Warm golden interior light spill
	var glow := PackedVector2Array([
		dp + Vector2(10.0, -44.0),
		dp + Vector2(58.0, -32.0),
		dp + Vector2(58.0, 32.0),
		dp + Vector2(10.0, 44.0),
	])
	b.polygon(glow, Color(1.0, 0.88, 0.55, 0.22))

	# Red carpet runner leading out onto pavement
	var carpet_rect := Rect2(dp.x + 8.0, dp.y - 18.0, 46.0, 36.0)
	b.rect(carpet_rect, C_CARPET)
	b.line(carpet_rect.position, carpet_rect.position + Vector2(carpet_rect.size.x, 0.0), C_CARPET_GOLD, 2.0)
	b.line(carpet_rect.position + Vector2(0.0, carpet_rect.size.y), carpet_rect.end, C_CARPET_GOLD, 2.0)

	# Brass stanchions and velvet rope
	for sy: float in [-24.0, 24.0]:
		var sp := dp + Vector2(48.0, sy)
		b.rect(Rect2(sp + Vector2(-3.0, -1.0), Vector2(7.0, 4.0)), Color(0.0, 0.0, 0.0, 0.25))
		b.circle(sp + Vector2(0.0, -12.0), 3.5, C_BRASS)
		b.line(sp + Vector2(0.0, -12.0), sp + Vector2(0.0, 2.0), C_BRASS, 2.4)
	# Velvety sag between stanchions
	b.line(dp + Vector2(48.0, -22.0), dp + Vector2(52.0, 0.0), C_CARPET, 2.2)
	b.line(dp + Vector2(52.0, 0.0), dp + Vector2(48.0, 22.0), C_CARPET, 2.2)

	# Sandwich board easel
	var easel_p := dp + Vector2(62.0, 38.0)
	b.rect(Rect2(easel_p + Vector2(-8.0, -12.0), Vector2(16.0, 24.0)), Color(0.24, 0.18, 0.12))
	b.rect(Rect2(easel_p + Vector2(-6.0, -10.0), Vector2(12.0, 20.0)), Color(0.10, 0.10, 0.12))

	# Gallery Greeter in stylish beret
	var gp := dp + Vector2(38.0, -38.0)
	b.circle(gp + Vector2(1.0, 2.0), 7.0, Color(0.0, 0.0, 0.0, 0.20))
	b.rect(Rect2(gp + Vector2(-5.0, -10.0), Vector2(10.0, 16.0)), Color(0.18, 0.22, 0.32)) # Navy blazer
	b.circle(gp + Vector2(0.0, -16.0), 5.5, Color(0.92, 0.78, 0.65)) # Face
	b.circle(gp + Vector2(0.0, -19.0), 6.5, Color(0.48, 0.12, 0.18)) # Burgundy beret
	# Pamphlet in hand
	b.rect(Rect2(gp + Vector2(4.0, -6.0), Vector2(6.0, 8.0)), Color(0.98, 0.96, 0.90))

	# Overhead hanging banner
	var bp := dp + Vector2(26.0, -56.0)
	b.rect(Rect2(bp + Vector2(-42.0, -14.0), Vector2(84.0, 28.0)), C_BANNER)
	b.rect(Rect2(bp + Vector2(-44.0, -15.0), Vector2(88.0, 2.0)), C_CARPET_GOLD)
	b.rect(Rect2(bp + Vector2(-44.0, 13.0), Vector2(88.0, 2.0)), C_CARPET_GOLD)


func _draw_somni_gallery(b: ShapeBatch, t: float) -> void:
	var o: Vector2 = DetourScript.DETOUR_ORIGIN
	var w: float = DetourScript.ROOM_W
	var h: float = DetourScript.ROOM_H

	# 1. Desert sand floor
	b.rect(Rect2(o, Vector2(w, h)), C_SAND)

	# Dunes & subtle diagonal surreal shadow bands
	for i in range(5):
		var dy := o.y + 120.0 + i * 110.0
		var pts := PackedVector2Array([
			Vector2(o.x, dy),
			Vector2(o.x + w * 0.4, dy + 25.0),
			Vector2(o.x + w, dy - 15.0),
			Vector2(o.x + w, dy + 6.0),
			Vector2(o.x + w * 0.4, dy + 32.0),
			Vector2(o.x, dy + 8.0),
		])
		b.polygon(pts, C_DUNE)

	# 2. Twilight horizon at the north end
	var sky_rect := Rect2(o, Vector2(w, 140.0))
	b.rect(sky_rect, Color(0.20, 0.15, 0.32)) # Twilight violet
	var dawn_band := Rect2(o + Vector2(0.0, 90.0), Vector2(w, 50.0))
	b.rect(dawn_band, Color(0.85, 0.55, 0.42, 0.55)) # Coral rose glow

	# 3. Distant Stilt Elephants walking along the horizon
	for ei in range(2):
		var ex: float = o.x + 140.0 + ei * 420.0 + sin(t * 0.4 + ei * 2.0) * 45.0
		var ey: float = o.y + 80.0
		_draw_stilt_creature(b, ex, ey, t + ei * 1.5)

	# 4. Long dramatic raking dream shadows for gallery elements
	var shadow_vec := Vector2(56.0, 34.0)

	# Plinth shadow
	var bp: Vector2 = o + DetourScript.BONE_POS
	b.rect(Rect2(bp + Vector2(-22.0, -8.0) + shadow_vec * 0.5, Vector2(44.0, 16.0) + shadow_vec), C_SHADOW)

	# 5. Obsidian plinth for the Golden Dream Bone
	b.rect(Rect2(bp + Vector2(-20.0, -14.0), Vector2(40.0, 28.0)), C_PLINTH)
	b.rect(Rect2(bp + Vector2(-16.0, -11.0), Vector2(32.0, 22.0)), C_VELVET)
	b.rect(Rect2(bp + Vector2(-14.0, -9.0), Vector2(28.0, 2.0)), C_CLOCK_GOLD)

	# Golden Dream Bone (if not taken)
	if not main.somni_bone_taken:
		var bob: float = sin(t * 3.2) * 5.0
		var bone_y: float = bp.y - 18.0 + bob
		# Golden glowing aura
		b.circle(Vector2(bp.x, bone_y), 18.0, Color(1.0, 0.88, 0.25, 0.28))
		b.circle(Vector2(bp.x, bone_y), 11.0, Color(1.0, 0.95, 0.55, 0.40))
		# Bone shafts and knobby ends
		b.line(Vector2(bp.x - 12.0, bone_y), Vector2(bp.x + 12.0, bone_y), C_GOLD, 4.5)
		b.circle(Vector2(bp.x - 13.0, bone_y - 4.0), 3.8, C_GOLD)
		b.circle(Vector2(bp.x - 13.0, bone_y + 4.0), 3.8, C_GOLD)
		b.circle(Vector2(bp.x + 13.0, bone_y - 4.0), 3.8, C_GOLD)
		b.circle(Vector2(bp.x + 13.0, bone_y + 4.0), 3.8, C_GOLD)
		# Sparkle twinkle
		var gl: float = sin(t * 5.0) * 6.0
		b.line(Vector2(bp.x - gl, bone_y), Vector2(bp.x + gl, bone_y), Color(1, 1, 1, 0.8), 1.5)
		b.line(Vector2(bp.x, bone_y - gl), Vector2(bp.x, bone_y + gl), Color(1, 1, 1, 0.8), 1.5)

	# 6. The 4 Melting Lampposts
	for i in range(DetourScript.LAMP_OFFSETS.size()):
		var lp: Vector2 = o + DetourScript.LAMP_OFFSETS[i]
		var droop: float = DetourScript.droop_t[i]
		_draw_melting_lamppost(b, lp, droop, t)

	# 7. Exit Portal Arch at the North wall
	var ep: Vector2 = o + DetourScript.ROOM_EXIT
	# Sunlight pouring in from city
	var exit_glow := PackedVector2Array([
		ep + Vector2(-36.0, -18.0),
		ep + Vector2(-70.0, 48.0),
		ep + Vector2(70.0, 48.0),
		ep + Vector2(36.0, -18.0),
	])
	b.polygon(exit_glow, Color(1.0, 0.94, 0.70, 0.30))
	# Arch surround
	b.rect(Rect2(ep + Vector2(-38.0, -22.0), Vector2(76.0, 44.0)), Color(0.94, 0.92, 0.86))
	b.rect(Rect2(ep + Vector2(-30.0, -16.0), Vector2(60.0, 36.0)), Color(1.0, 0.95, 0.82))


func _draw_stilt_creature(b: ShapeBatch, x: float, y: float, t: float) -> void:
	var col := Color(0.12, 0.09, 0.20, 0.85)
	# Spindly legs walking
	for li in range(4):
		var phase: float = t * 1.8 + float(li) * 1.57
		var foot_x: float = x - 18.0 + float(li) * 12.0 + sin(phase) * 8.0
		var foot_y: float = y + 54.0 - maxf(0.0, sin(phase) * 6.0)
		var knee_x: float = (x + foot_x) * 0.5 + sin(phase * 0.5) * 4.0
		var knee_y: float = y + 26.0
		b.line(Vector2(x - 12.0 + float(li) * 8.0, y), Vector2(knee_x, knee_y), col, 1.4)
		b.line(Vector2(knee_x, knee_y), Vector2(foot_x, foot_y), col, 1.2)
	# Elephant body and head
	b.circle(Vector2(x, y), 9.0, col)
	b.circle(Vector2(x - 8.0, y + 2.0), 6.5, col) # Head
	b.line(Vector2(x - 12.0, y + 4.0), Vector2(x - 16.0, y + 14.0), col, 2.0) # Trunk
	# Obelisk monument on back
	var obelisk := PackedVector2Array([
		Vector2(x - 4.0, y - 6.0),
		Vector2(x, y - 32.0),
		Vector2(x + 4.0, y - 6.0),
	])
	b.polygon(obelisk, col)


func _draw_melting_lamppost(b: ShapeBatch, p: Vector2, droop: float, t: float) -> void:
	# Long raking shadow cast down-right
	var s_len := 58.0 + droop * 12.0
	var s_end := p + Vector2(1.6, 0.9).normalized() * s_len
	b.line(p, s_end, C_SHADOW, 5.0)

	# Bronze base
	b.circle(p + Vector2(1.0, 1.0), 9.0, Color(0, 0, 0, 0.25))
	b.circle(p, 8.0, C_BRONZE)
	b.circle(p, 5.0, C_BRONZE_HI)

	# Slender upright pole that bends with droop
	var bend_x: float = sin(p.y + t) * 2.0 + droop * 16.0
	var head_y: float = -38.0 + droop * 14.0
	var mid := p + Vector2(bend_x * 0.5, head_y * 0.5)
	var top := p + Vector2(bend_x, head_y)
	b.line(p, mid, C_BRONZE, 3.8)
	b.line(mid, top, C_BRONZE, 3.2)

	# Curved arm crossbar
	b.line(top, top + Vector2(-16.0, 4.0), C_BRONZE_HI, 2.8)
	b.line(top, top + Vector2(16.0, 4.0), C_BRONZE_HI, 2.8)

	# Melting clock draped over the horizontal arm
	var cp := top + Vector2(4.0, 6.0 + droop * 4.0)
	# Soft sagging clock silhouette (warped rounded rectangle / ellipse)
	var clock_pts := PackedVector2Array([
		cp + Vector2(-12.0, -8.0),
		cp + Vector2(12.0, -6.0),
		cp + Vector2(14.0, 12.0 + droop * 6.0),
		cp + Vector2(6.0, 16.0 + droop * 10.0),
		cp + Vector2(-8.0, 14.0 + droop * 8.0),
		cp + Vector2(-14.0, 4.0),
	])
	b.polygon(clock_pts, C_CLOCK)
	b.line(clock_pts[0], clock_pts[1], C_CLOCK_GOLD, 1.8)
	b.line(clock_pts[1], clock_pts[2], C_CLOCK_GOLD, 1.8)
	b.line(clock_pts[2], clock_pts[3], C_CLOCK_GOLD, 1.8)
	b.line(clock_pts[3], clock_pts[4], C_CLOCK_GOLD, 1.8)
	b.line(clock_pts[4], clock_pts[5], C_CLOCK_GOLD, 1.8)
	b.line(clock_pts[5], clock_pts[0], C_CLOCK_GOLD, 1.8)

	# Clock hands (bent)
	b.line(cp + Vector2(0.0, 2.0), cp + Vector2(1.0, -4.0), Color(0.15, 0.15, 0.15), 1.8)
	b.line(cp + Vector2(0.0, 2.0), cp + Vector2(6.0, 4.0), Color(0.15, 0.15, 0.15), 1.6)
	b.circle(cp + Vector2(0.0, 2.0), 1.4, C_CLOCK_GOLD)


func _draw_labels() -> void:
	var f := ThemeDB.fallback_font

	# Street entrance banner labels
	var dp: Vector2 = main.detour_door_pos
	if dp != Vector2.ZERO:
		var bp := dp + Vector2(26.0, -56.0)
		draw_string(f, bp + Vector2(-40.0, -1.0), "EXPOSICIÓ - ENTRADA LLIURE", HORIZONTAL_ALIGNMENT_CENTER, 80, 8, Color.WHITE)
		draw_string(f, bp + Vector2(-40.0, 9.0), "«EL SOMNI»", HORIZONTAL_ALIGNMENT_CENTER, 80, 9, C_CARPET_GOLD)

		var easel_p := dp + Vector2(62.0, 38.0)
		draw_string(f, easel_p + Vector2(-8.0, 0.0), "GALERIA", HORIZONTAL_ALIGNMENT_CENTER, 16, 7, Color.WHITE)

	# Detour gallery labels
	if main.detour_active or absf(main.cam.position.y - (DetourScript.DETOUR_ORIGIN.y + DetourScript.ROOM_H * 0.5)) < 700.0:
		var o: Vector2 = DetourScript.DETOUR_ORIGIN
		var ep: Vector2 = o + DetourScript.ROOM_EXIT
		draw_string(f, ep + Vector2(-40.0, -26.0), "SORTIDA - A LA CIUTAT", HORIZONTAL_ALIGNMENT_CENTER, 80, 9, Color(0.20, 0.16, 0.12))

		var bp: Vector2 = o + DetourScript.BONE_POS
		if main.somni_bone_taken:
			draw_string(f, bp + Vector2(-30.0, 2.0), "COL·LECCIONAT", HORIZONTAL_ALIGNMENT_CENTER, 60, 8, C_CLOCK_GOLD)
