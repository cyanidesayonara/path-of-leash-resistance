extends Node2D

const DetourScript := preload("res://systems/detour.gd")

var main: Node2D

# Shared & Dalí ("El Somni") palette
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

# L'Estel primary palette (after Miró's general style)
const C_WHITE := Color(0.97, 0.97, 0.95)
const C_BLACK := Color(0.10, 0.10, 0.12)
const C_RED := Color(0.88, 0.18, 0.14)
const C_BLUE := Color(0.10, 0.30, 0.76)
const C_YELLOW := Color(0.98, 0.82, 0.12)

# El Colom analytical cubist palette (after Picasso's general style)
const C_OCHRE := Color(0.82, 0.64, 0.38)
const C_SLATE := Color(0.36, 0.40, 0.44)
const C_TERRACOTTA := Color(0.72, 0.34, 0.22)
const C_UMBER := Color(0.38, 0.26, 0.18)
const C_CREAM := Color(0.92, 0.88, 0.80)
const C_CHARCOAL := Color(0.18, 0.18, 0.20)

# Gaudí ("El Drac") Modernisme & Trencadís palette
const C_TRENCADIS_WHITE := Color(0.96, 0.95, 0.92)
const C_TRENCADIS_BLUE := Color(0.12, 0.32, 0.72)
const C_TRENCADIS_GREEN := Color(0.24, 0.58, 0.32)
const C_TRENCADIS_GOLD := Color(0.95, 0.78, 0.22)
const C_TRENCADIS_ORANGE := Color(0.92, 0.48, 0.18)
const C_TRENCADIS_RED := Color(0.82, 0.20, 0.22)
const C_WROUGHT_IRON := Color(0.16, 0.18, 0.18)
const C_SANDSTONE := Color(0.84, 0.78, 0.68)
const C_ROOF_TILE := Color(0.68, 0.42, 0.32)


func setup(m: Node2D) -> void:
	main = m


func _process(_delta: float) -> void:
	if main == null:
		return
	var cy: float = main.cam.position.y
	var door_y: float = main.detour_door_pos.y if main.detour_door_pos != Vector2.ZERO else DetourScript.STREET_DOOR_Y
	var near_door := absf(cy - door_y) < 650.0
	var o: Vector2 = DetourScript.origin_for(main)
	var near_room := absf(cy - (o.y + DetourScript.ROOM_H * 0.5)) < 700.0
	if main.detour_active or near_door or near_room:
		queue_redraw()


func _draw() -> void:
	if main == null:
		return
	var b := ShapeBatch.new(self)
	var t: float = AnimClock.msec() / 1000.0

	# 1. STREET ENTRANCE (El Gòtic or Montjuïc)
	_draw_street_doorway(b, t)

	# 2. INSIDE THE DETOUR GALLERY
	var o: Vector2 = DetourScript.origin_for(main)
	if main.detour_active or absf(main.cam.position.y - (o.y + DetourScript.ROOM_H * 0.5)) < 700.0:
		if main.detour_kind == "drac":
			_draw_drac_gallery(b, t)
		elif main.detour_kind == "colom":
			_draw_colom_gallery(b, t)
		elif main.detour_kind == "estel":
			_draw_estel_gallery(b, t)
		else:
			_draw_somni_gallery(b, t)

	b.flush()
	_draw_labels()


func _draw_street_doorway(b: ShapeBatch, _t: float) -> void:
	var dp: Vector2 = main.detour_door_pos
	if dp == Vector2.ZERO:
		return

	var is_drac: bool = main.detour_kind == "drac" or main.lvl == "street"
	var is_colom: bool = main.detour_kind == "colom" or main.lvl == "reial"
	var is_estel: bool = main.detour_kind == "estel" or main.lvl == "montjuic"

	if is_drac:
		# Parabolic catenary stone archway on La Rambla building wall
		var door_rect := Rect2(dp.x - 34.0, dp.y - 48.0, 48.0, 96.0)
		b.rect(door_rect, C_SANDSTONE)
		# Modernisme undulating curved sandstone trim
		b.rect(Rect2(dp.x - 34.0, dp.y - 48.0, 6.0, 96.0), C_TRENCADIS_GOLD)
		b.rect(Rect2(dp.x - 28.0, dp.y - 48.0, 4.0, 96.0), C_TRENCADIS_GREEN)
		b.rect(Rect2(dp.x - 24.0, dp.y - 48.0, 4.0, 96.0), C_TRENCADIS_BLUE)
		b.rect(Rect2(dp.x - 20.0, dp.y - 46.0, 32.0, 92.0), Color(0.12, 0.12, 0.14))

		# Wrought-iron serpentine gate scrolls
		for gy: float in [-32.0, -12.0, 8.0, 28.0]:
			b.line(dp + Vector2(-18.0, gy), dp + Vector2(10.0, gy + 4.0), C_WROUGHT_IRON, 1.8)
			b.circle(dp + Vector2(-4.0, gy + 2.0), 3.0, C_WROUGHT_IRON)

		# Warm amber lantern light spill
		var glow := PackedVector2Array([
			dp + Vector2(10.0, -44.0),
			dp + Vector2(62.0, -32.0),
			dp + Vector2(62.0, 32.0),
			dp + Vector2(10.0, 44.0),
		])
		b.polygon(glow, Color(1.0, 0.90, 0.65, 0.28))

		# Trencadís mosaic tiled carpet runner with diamond mosaic shards
		var carpet_rect := Rect2(dp.x + 8.0, dp.y - 18.0, 48.0, 36.0)
		b.rect(carpet_rect, C_SANDSTONE)
		b.line(carpet_rect.position, carpet_rect.position + Vector2(carpet_rect.size.x, 0.0), C_TRENCADIS_BLUE, 2.2)
		b.line(carpet_rect.position + Vector2(0.0, carpet_rect.size.y), carpet_rect.end, C_TRENCADIS_BLUE, 2.2)
		for mx in range(3):
			var cx := carpet_rect.position.x + 10.0 + float(mx) * 14.0
			b.circle(Vector2(cx, carpet_rect.position.y + 10.0), 3.2, C_TRENCADIS_GOLD)
			b.circle(Vector2(cx, carpet_rect.position.y + 26.0), 3.2, C_TRENCADIS_GREEN)

		# Brass stanchions and emerald/gold cord
		for sy: float in [-24.0, 24.0]:
			var sp := dp + Vector2(50.0, sy)
			b.rect(Rect2(sp + Vector2(-3.0, -1.0), Vector2(7.0, 4.0)), Color(0.0, 0.0, 0.0, 0.25))
			b.circle(sp + Vector2(0.0, -12.0), 3.5, C_BRASS)
			b.line(sp + Vector2(0.0, -12.0), sp + Vector2(0.0, 2.0), C_BRASS, 2.4)
		b.line(dp + Vector2(50.0, -22.0), dp + Vector2(54.0, 0.0), C_TRENCADIS_GREEN, 2.4)
		b.line(dp + Vector2(54.0, 0.0), dp + Vector2(50.0, 22.0), C_TRENCADIS_GREEN, 2.4)

		# Easel displaying mosaic dragon study artwork
		var easel_p := dp + Vector2(64.0, 38.0)
		b.rect(Rect2(easel_p + Vector2(-8.0, -12.0), Vector2(16.0, 24.0)), C_SANDSTONE)
		b.rect(Rect2(easel_p + Vector2(-7.0, -11.0), Vector2(14.0, 22.0)), C_TRENCADIS_BLUE)
		_draw_dragon_icon(b, easel_p + Vector2(0.0, 1.0), 5.5)

		# Gallery host in 1900s newsboy cap & brown modernisme vest
		var gp := dp + Vector2(40.0, -38.0)
		b.circle(gp + Vector2(1.0, 2.0), 7.0, Color(0.0, 0.0, 0.0, 0.20))
		b.rect(Rect2(gp + Vector2(-5.0, -10.0), Vector2(10.0, 16.0)), C_CREAM)
		b.rect(Rect2(gp + Vector2(-4.0, -9.0), Vector2(8.0, 14.0)), Color(0.38, 0.26, 0.18)) # Brown vest
		b.circle(gp + Vector2(0.0, -16.0), 5.5, Color(0.92, 0.78, 0.65)) # Face
		b.circle(gp + Vector2(0.0, -19.0), 6.5, Color(0.24, 0.22, 0.20)) # Newsboy cap
		b.rect(Rect2(gp + Vector2(4.0, -6.0), Vector2(6.0, 8.0)), C_TRENCADIS_GOLD) # Exhibition brochure

		# Overhead modernisme curved banner
		var bp := dp + Vector2(26.0, -56.0)
		b.rect(Rect2(bp + Vector2(-44.0, -14.0), Vector2(88.0, 28.0)), C_SANDSTONE)
		b.rect(Rect2(bp + Vector2(-46.0, -15.0), Vector2(92.0, 2.2)), C_TRENCADIS_GOLD)
		b.rect(Rect2(bp + Vector2(-46.0, 13.0), Vector2(92.0, 2.2)), C_WROUGHT_IRON)
	elif is_colom:
		# Neoclassical portico archway in Plaça Reial arcade
		var door_rect := Rect2(dp.x - 34.0, dp.y - 48.0, 48.0, 96.0)
		b.rect(door_rect, C_CREAM)
		# Cubist fragmented frame accents
		b.rect(Rect2(dp.x - 34.0, dp.y - 48.0, 6.0, 96.0), C_TERRACOTTA)
		b.rect(Rect2(dp.x - 28.0, dp.y - 48.0, 4.0, 96.0), C_OCHRE)
		b.rect(Rect2(dp.x - 24.0, dp.y - 48.0, 4.0, 96.0), C_SLATE)
		b.rect(Rect2(dp.x - 20.0, dp.y - 46.0, 32.0, 92.0), Color(0.14, 0.12, 0.12))

		# Warm golden interior light spill
		var glow := PackedVector2Array([
			dp + Vector2(10.0, -44.0),
			dp + Vector2(62.0, -32.0),
			dp + Vector2(62.0, 32.0),
			dp + Vector2(10.0, 44.0),
		])
		b.polygon(glow, Color(1.0, 0.92, 0.75, 0.26))

		# Terracotta runner with charcoal borders
		var carpet_rect := Rect2(dp.x + 8.0, dp.y - 18.0, 48.0, 36.0)
		b.rect(carpet_rect, C_TERRACOTTA)
		b.line(carpet_rect.position, carpet_rect.position + Vector2(carpet_rect.size.x, 0.0), C_CHARCOAL, 2.2)
		b.line(carpet_rect.position + Vector2(0.0, carpet_rect.size.y), carpet_rect.end, C_CHARCOAL, 2.2)

		# Brass stanchions and blue cord
		for sy: float in [-24.0, 24.0]:
			var sp := dp + Vector2(50.0, sy)
			b.rect(Rect2(sp + Vector2(-3.0, -1.0), Vector2(7.0, 4.0)), Color(0.0, 0.0, 0.0, 0.25))
			b.circle(sp + Vector2(0.0, -12.0), 3.5, C_BRASS)
			b.line(sp + Vector2(0.0, -12.0), sp + Vector2(0.0, 2.0), C_BRASS, 2.4)
		b.line(dp + Vector2(50.0, -22.0), dp + Vector2(54.0, 0.0), C_BLUE, 2.4)
		b.line(dp + Vector2(54.0, 0.0), dp + Vector2(50.0, 22.0), C_BLUE, 2.4)

		# Easel displaying a faceted pigeon
		var easel_p := dp + Vector2(64.0, 38.0)
		b.rect(Rect2(easel_p + Vector2(-8.0, -12.0), Vector2(16.0, 24.0)), C_CREAM)
		b.rect(Rect2(easel_p + Vector2(-7.0, -11.0), Vector2(14.0, 22.0)), C_TERRACOTTA)
		_draw_dove_icon(b, easel_p + Vector2(0.0, 1.0), 5.5)

		# Greeter in striped blue/white Breton sailor shirt (marinière) & dark beret
		var gp := dp + Vector2(40.0, -38.0)
		b.circle(gp + Vector2(1.0, 2.0), 7.0, Color(0.0, 0.0, 0.0, 0.20))
		b.rect(Rect2(gp + Vector2(-5.0, -10.0), Vector2(10.0, 16.0)), C_WHITE)
		for si in range(4):
			b.line(gp + Vector2(-5.0, -9.0 + float(si) * 4.0), gp + Vector2(5.0, -9.0 + float(si) * 4.0), C_BLUE, 1.6)
		b.circle(gp + Vector2(0.0, -16.0), 5.5, Color(0.92, 0.78, 0.65)) # Face
		b.circle(gp + Vector2(0.0, -19.0), 6.5, C_CHARCOAL) # Dark artist beret
		b.rect(Rect2(gp + Vector2(4.0, -6.0), Vector2(6.0, 8.0)), C_OCHRE) # Catalogue

		# Overhead banner
		var bp := dp + Vector2(26.0, -56.0)
		b.rect(Rect2(bp + Vector2(-44.0, -14.0), Vector2(88.0, 28.0)), C_CREAM)
		b.rect(Rect2(bp + Vector2(-46.0, -15.0), Vector2(92.0, 2.2)), C_TERRACOTTA)
		b.rect(Rect2(bp + Vector2(-46.0, 13.0), Vector2(92.0, 2.2)), C_CHARCOAL)
	elif is_estel:
		# Crisp white modernist pavilion gateway on Montjuïc terrace
		var door_rect := Rect2(dp.x - 34.0, dp.y - 48.0, 48.0, 96.0)
		b.rect(door_rect, C_WHITE)
		b.rect(Rect2(dp.x - 34.0, dp.y - 48.0, 4.0, 96.0), C_RED)
		b.rect(Rect2(dp.x - 30.0, dp.y - 48.0, 4.0, 96.0), C_YELLOW)
		b.rect(Rect2(dp.x - 26.0, dp.y - 48.0, 4.0, 96.0), C_BLUE)
		b.rect(Rect2(dp.x - 22.0, dp.y - 46.0, 34.0, 92.0), Color(0.12, 0.12, 0.14))

		# Warm golden interior light spill
		var glow := PackedVector2Array([
			dp + Vector2(10.0, -44.0),
			dp + Vector2(62.0, -32.0),
			dp + Vector2(62.0, 32.0),
			dp + Vector2(10.0, 44.0),
		])
		b.polygon(glow, Color(1.0, 0.95, 0.80, 0.26))

		# Red carpet runner with black border
		var carpet_rect := Rect2(dp.x + 8.0, dp.y - 18.0, 48.0, 36.0)
		b.rect(carpet_rect, C_RED)
		b.line(carpet_rect.position, carpet_rect.position + Vector2(carpet_rect.size.x, 0.0), C_BLACK, 2.2)
		b.line(carpet_rect.position + Vector2(0.0, carpet_rect.size.y), carpet_rect.end, C_BLACK, 2.2)

		# Brass stanchions and ultramarine blue velvet rope
		for sy: float in [-24.0, 24.0]:
			var sp := dp + Vector2(50.0, sy)
			b.rect(Rect2(sp + Vector2(-3.0, -1.0), Vector2(7.0, 4.0)), Color(0.0, 0.0, 0.0, 0.25))
			b.circle(sp + Vector2(0.0, -12.0), 3.5, C_BRASS)
			b.line(sp + Vector2(0.0, -12.0), sp + Vector2(0.0, 2.0), C_BRASS, 2.4)
		b.line(dp + Vector2(50.0, -22.0), dp + Vector2(54.0, 0.0), C_BLUE, 2.4)
		b.line(dp + Vector2(54.0, 0.0), dp + Vector2(50.0, 22.0), C_BLUE, 2.4)

		# Sandwich board easel
		var easel_p := dp + Vector2(64.0, 38.0)
		b.rect(Rect2(easel_p + Vector2(-8.0, -12.0), Vector2(16.0, 24.0)), C_WHITE)
		b.rect(Rect2(easel_p + Vector2(-7.0, -11.0), Vector2(14.0, 22.0)), C_BLACK)

		# Gallery Greeter in stylish black coat & white artist beret
		var gp := dp + Vector2(40.0, -38.0)
		b.circle(gp + Vector2(1.0, 2.0), 7.0, Color(0.0, 0.0, 0.0, 0.20))
		b.rect(Rect2(gp + Vector2(-5.0, -10.0), Vector2(10.0, 16.0)), C_BLACK)
		b.circle(gp + Vector2(0.0, -16.0), 5.5, Color(0.92, 0.78, 0.65)) # Face
		b.circle(gp + Vector2(0.0, -19.0), 6.5, C_WHITE) # White artist beret
		b.rect(Rect2(gp + Vector2(4.0, -6.0), Vector2(6.0, 8.0)), C_YELLOW) # Catalogue

		# Overhead hanging banner
		var bp := dp + Vector2(26.0, -56.0)
		b.rect(Rect2(bp + Vector2(-44.0, -14.0), Vector2(88.0, 28.0)), C_WHITE)
		b.rect(Rect2(bp + Vector2(-46.0, -15.0), Vector2(92.0, 2.2)), C_RED)
		b.rect(Rect2(bp + Vector2(-46.0, 13.0), Vector2(92.0, 2.2)), C_BLUE)
	else:
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
		b.rect(Rect2(gp + Vector2(4.0, -6.0), Vector2(6.0, 8.0)), Color(0.98, 0.96, 0.90))

		# Overhead hanging banner
		var bp := dp + Vector2(26.0, -56.0)
		b.rect(Rect2(bp + Vector2(-42.0, -14.0), Vector2(84.0, 28.0)), C_BANNER)
		b.rect(Rect2(bp + Vector2(-44.0, -15.0), Vector2(88.0, 2.0)), C_CARPET_GOLD)
		b.rect(Rect2(bp + Vector2(-44.0, 13.0), Vector2(88.0, 2.0)), C_CARPET_GOLD)


# --- INSIDE L'ESTEL GALLERY (Joan Miró Homage) ---
func _draw_estel_gallery(b: ShapeBatch, t: float) -> void:
	var o: Vector2 = DetourScript.ESTEL_ORIGIN
	var w: float = DetourScript.ROOM_W
	var h: float = DetourScript.ROOM_H

	# 1. Modernist white gallery floor
	b.rect(Rect2(o, Vector2(w, h)), C_WHITE)

	# 2. Geometric primary field insets
	# Cadmium yellow rectangular field
	b.rect(Rect2(o + Vector2(60.0, 150.0), Vector2(210.0, 190.0)), C_YELLOW)
	# Ultramarine blue organic trapezoid field
	var blue_pts := PackedVector2Array([
		o + Vector2(490.0, 130.0),
		o + Vector2(710.0, 160.0),
		o + Vector2(670.0, 390.0),
		o + Vector2(460.0, 330.0),
	])
	b.polygon(blue_pts, C_BLUE)
	# Vermilion red curved band
	b.rect(Rect2(o + Vector2(220.0, 450.0), Vector2(320.0, 110.0)), C_RED)

	# Bold calligraphic black dividing lines
	b.line(o + Vector2(60.0, 150.0), o + Vector2(270.0, 150.0), C_BLACK, 3.5)
	b.line(o + Vector2(270.0, 150.0), o + Vector2(270.0, 340.0), C_BLACK, 3.5)
	b.line(o + Vector2(490.0, 130.0), o + Vector2(460.0, 330.0), C_BLACK, 3.5)
	b.line(o + Vector2(220.0, 450.0), o + Vector2(540.0, 450.0), C_BLACK, 3.5)

	# 3. Perimeter Calligraphic Murals & Constellations
	# Asterisks / Stars
	_draw_miro_star(b, o + Vector2(130.0, 80.0), 16.0, C_RED)
	_draw_miro_star(b, o + Vector2(640.0, 85.0), 18.0, C_YELLOW)
	_draw_miro_star(b, o + Vector2(100.0, 480.0), 14.0, C_BLUE)
	_draw_miro_star(b, o + Vector2(660.0, 490.0), 15.0, C_RED)

	# Biomorphic Eyes
	_draw_miro_eye(b, o + Vector2(280.0, 85.0), 22.0, t)
	_draw_miro_eye(b, o + Vector2(480.0, 80.0), 20.0, t + 1.2)
	_draw_miro_eye(b, o + Vector2(140.0, 260.0), 18.0, t * 0.8)

	# Crescent Moon
	var moon_p := o + Vector2(650.0, 270.0)
	b.circle(moon_p, 16.0, C_YELLOW)
	b.circle(moon_p + Vector2(6.0, -3.0), 14.0, C_BLUE)

	# 4. 4 Biomorphic Sculptures (wrapped as rope poles)
	for i in range(DetourScript.SCULPTURE_OFFSETS.size()):
		var sp: Vector2 = o + DetourScript.SCULPTURE_OFFSETS[i]
		_draw_miro_sculpture(b, sp, i, t)

	# 5. 3 Hop Trails (chimes)
	for i in range(DetourScript.LADDER_OFFSETS.size()):
		var lp: Vector2 = o + DetourScript.LADDER_OFFSETS[i]
		_draw_starry_ladder(b, lp, i, t)

	# 6. Central Modernist Cube Pedestal & Golden Star Bone
	var bp: Vector2 = o + DetourScript.BONE_POS
	b.rect(Rect2(bp + Vector2(-22.0, -16.0), Vector2(44.0, 32.0)), C_WHITE)
	b.rect(Rect2(bp + Vector2(-20.0, -14.0), Vector2(40.0, 28.0)), Color(0.92, 0.92, 0.90))
	b.line(bp + Vector2(-22.0, -16.0), bp + Vector2(22.0, -16.0), C_BLACK, 2.5)
	b.line(bp + Vector2(-22.0, 16.0), bp + Vector2(22.0, 16.0), C_BLACK, 2.5)
	b.line(bp + Vector2(-22.0, -16.0), bp + Vector2(-22.0, 16.0), C_BLACK, 2.5)
	b.line(bp + Vector2(22.0, -16.0), bp + Vector2(22.0, 16.0), C_BLACK, 2.5)
	# Primary insets
	b.rect(Rect2(bp + Vector2(-16.0, -8.0), Vector2(8.0, 16.0)), C_RED)
	b.rect(Rect2(bp + Vector2(-4.0, -8.0), Vector2(8.0, 16.0)), C_YELLOW)
	b.rect(Rect2(bp + Vector2(8.0, -8.0), Vector2(8.0, 16.0)), C_BLUE)

	# Golden Star Bone
	if not main.estel_bone_taken:
		var bob: float = sin(t * 3.2) * 5.0
		var bone_y: float = bp.y - 18.0 + bob
		# Celestial aura
		b.circle(Vector2(bp.x, bone_y), 19.0, Color(1.0, 0.88, 0.25, 0.28))
		b.circle(Vector2(bp.x, bone_y), 12.0, Color(1.0, 0.96, 0.60, 0.45))
		# Star bone shaft and knobby ends
		b.line(Vector2(bp.x - 12.0, bone_y), Vector2(bp.x + 12.0, bone_y), C_GOLD, 4.5)
		b.circle(Vector2(bp.x - 13.0, bone_y - 4.0), 3.8, C_GOLD)
		b.circle(Vector2(bp.x - 13.0, bone_y + 4.0), 3.8, C_GOLD)
		b.circle(Vector2(bp.x + 13.0, bone_y - 4.0), 3.8, C_GOLD)
		b.circle(Vector2(bp.x + 13.0, bone_y + 4.0), 3.8, C_GOLD)
		# Surrounding starlets
		_draw_miro_star(b, Vector2(bp.x - 22.0, bone_y - 8.0), 7.0, C_RED)
		_draw_miro_star(b, Vector2(bp.x + 22.0, bone_y + 6.0), 7.0, C_BLUE)

	# 7. Exit Portal Arch at North wall
	var ep: Vector2 = o + DetourScript.ROOM_EXIT
	var exit_glow := PackedVector2Array([
		ep + Vector2(-36.0, -18.0),
		ep + Vector2(-70.0, 48.0),
		ep + Vector2(70.0, 48.0),
		ep + Vector2(36.0, -18.0),
	])
	b.polygon(exit_glow, Color(1.0, 0.96, 0.85, 0.28))
	b.rect(Rect2(ep + Vector2(-38.0, -22.0), Vector2(76.0, 44.0)), C_BLACK)
	b.rect(Rect2(ep + Vector2(-32.0, -16.0), Vector2(64.0, 36.0)), C_WHITE)


func _draw_miro_star(b: ShapeBatch, p: Vector2, r: float, dot_col: Color) -> void:
	# an original lopsided five-point star: a filled primary blob with a thick
	# off-centre black outline. Deliberately NOT an asterisk with a coloured
	# hub (that reads as a specific foundation logo).
	var pts := PackedVector2Array()
	for k in range(10):
		var ang: float = -PI * 0.5 + float(k) * PI * 0.2 + 0.18
		var rad: float = r * (1.0 if k % 2 == 0 else 0.46) * (1.0 + 0.12 * sin(float(k) * 2.3))
		pts.append(p + Vector2(cos(ang), sin(ang)) * rad)
	b.polygon(pts, dot_col)
	for k in range(10):
		b.line(pts[k], pts[(k + 1) % 10], C_BLACK, 1.8)


func _draw_miro_eye(b: ShapeBatch, p: Vector2, w: float, t: float) -> void:
	var h := w * 0.52
	# Almond eye contour
	var pts := PackedVector2Array([
		p + Vector2(-w, 0.0),
		p + Vector2(0.0, -h),
		p + Vector2(w, 0.0),
		p + Vector2(0.0, h),
	])
	b.polygon(pts, C_WHITE)
	b.line(pts[0], pts[1], C_BLACK, 2.2)
	b.line(pts[1], pts[2], C_BLACK, 2.2)
	b.line(pts[2], pts[3], C_BLACK, 2.2)
	b.line(pts[3], pts[0], C_BLACK, 2.2)

	# Pupil looking subtly
	var px: float = sin(t * 1.5) * (w * 0.25)
	b.circle(p + Vector2(px, 0.0), h * 0.45, C_BLACK)

	# Radiating eyelashes
	for i in range(-2, 3):
		var ex: float = float(i) * (w * 0.35)
		b.line(p + Vector2(ex, -h), p + Vector2(ex * 1.2, -h - 8.0), C_BLACK, 1.8)


func _draw_miro_sculpture(b: ShapeBatch, sp: Vector2, idx: int, t: float) -> void:
	# Cast round ground shadow
	b.circle(sp + Vector2(2.0, 2.0), 16.0, Color(0.0, 0.0, 0.0, 0.22))
	# Base pole anchor (LevelBuild.POST_R = 14.0)
	b.circle(sp, 14.0, C_BLACK)

	match idx:
		0:
			# Solar Disc: Vermilion red circular body, black crescent horn
			b.circle(sp, 20.0, C_RED)
			b.circle(sp, 20.0, C_BLACK)
			b.circle(sp, 17.0, C_RED)
			# Black crescent horn curving overhead
			b.line(sp + Vector2(-16.0, -10.0), sp + Vector2(-22.0, -28.0), C_BLACK, 3.5)
			b.line(sp + Vector2(-22.0, -28.0), sp + Vector2(-8.0, -36.0), C_BLACK, 3.0)
			# Center eye
			b.circle(sp + Vector2(2.0, -2.0), 5.5, C_YELLOW)
			b.circle(sp + Vector2(2.0, -2.0), 2.5, C_BLACK)
		1:
			# Celestial Droplet: Ultramarine blue droplet with yellow star finial
			var drop := PackedVector2Array([
				sp + Vector2(0.0, -32.0),
				sp + Vector2(18.0, 8.0),
				sp + Vector2(0.0, 20.0),
				sp + Vector2(-18.0, 8.0),
			])
			b.polygon(drop, C_BLUE)
			b.line(drop[0], drop[1], C_BLACK, 2.5)
			b.line(drop[1], drop[2], C_BLACK, 2.5)
			b.line(drop[2], drop[3], C_BLACK, 2.5)
			b.line(drop[3], drop[0], C_BLACK, 2.5)
			_draw_miro_star(b, sp + Vector2(0.0, -32.0), 10.0, C_YELLOW)
		2:
			# Orbital Cylinder: Cadmium yellow column with black ring
			b.circle(sp, 16.0, C_YELLOW)
			b.circle(sp, 16.0, C_BLACK)
			b.circle(sp, 13.5, C_YELLOW)
			# Tilted elliptical Saturnian ring
			b.line(sp + Vector2(-26.0, 8.0), sp + Vector2(26.0, -8.0), C_BLACK, 3.2)
			# Red satellite sphere on stem
			var sat_p := sp + Vector2(cos(t * 1.8) * 28.0, sin(t * 1.8) * 16.0)
			b.line(sp, sat_p, C_BLACK, 1.6)
			b.circle(sat_p, 4.5, C_RED)
		3:
			# Calligraphic Totem: Deep black totem with eye motif
			b.circle(sp, 16.0, C_BLACK)
			b.line(sp + Vector2(0.0, -14.0), sp + Vector2(0.0, -38.0), C_BLACK, 4.0)
			b.circle(sp + Vector2(0.0, -38.0), 10.0, C_BLACK)
			b.circle(sp + Vector2(0.0, -38.0), 6.0, C_WHITE)
			b.circle(sp + Vector2(0.0, -38.0), 3.0, C_BLACK)
			# Vermilion teardrop on right
			b.circle(sp + Vector2(14.0, -22.0), 5.0, C_RED)


func _draw_starry_ladder(b: ShapeBatch, lp: Vector2, idx: int, t: float) -> void:
	# "Hop Trail" (original): a wavy black line with five primary stepping blobs
	# and a bobbing yellow bead. Same spot and role as the old ladders (a
	# proximity chime), but not a ladder and not a star ladder.
	var dir := -1.0 if idx == 1 else 1.0
	var prev := lp + Vector2(-30.0 * dir, 30.0)
	for k in range(5):
		var f: float = float(k) / 4.0
		var pos := lp + Vector2((-30.0 + 60.0 * f) * dir, 30.0 - 60.0 * f + sin(f * TAU + float(idx)) * 9.0)
		b.line(prev, pos, C_BLACK, 2.2)
		prev = pos
		var col: Color = [C_RED, C_YELLOW, C_BLUE][(k + idx) % 3]
		var rad: float = 6.5 - 0.7 * float(k % 3)
		b.circle(pos + Vector2(1.5, 2.0), rad, Color(0.0, 0.0, 0.0, 0.16))
		b.circle(pos, rad + 1.4, C_BLACK)
		b.circle(pos, rad, col)
	var spk := lp + Vector2(sin(t * 3.5 + float(idx)) * 14.0, -38.0 + cos(t * 2.5 + float(idx)) * 6.0)
	b.circle(spk, 2.4, C_YELLOW)


# --- INSIDE EL SOMNI GALLERY (Salvador Dalí Homage) ---
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
	var exit_glow := PackedVector2Array([
		ep + Vector2(-36.0, -18.0),
		ep + Vector2(-70.0, 48.0),
		ep + Vector2(70.0, 48.0),
		ep + Vector2(36.0, -18.0),
	])
	b.polygon(exit_glow, Color(1.0, 0.94, 0.70, 0.30))
	b.rect(Rect2(ep + Vector2(-38.0, -22.0), Vector2(76.0, 44.0)), Color(0.94, 0.92, 0.86))
	b.rect(Rect2(ep + Vector2(-30.0, -16.0), Vector2(60.0, 36.0)), Color(1.0, 0.95, 0.82))


func _draw_stilt_creature(b: ShapeBatch, x: float, y: float, t: float) -> void:
	var col := Color(0.12, 0.09, 0.20, 0.85)
	for li in range(4):
		var phase: float = t * 1.8 + float(li) * 1.57
		var foot_x: float = x - 18.0 + float(li) * 12.0 + sin(phase) * 8.0
		var foot_y: float = y + 54.0 - maxf(0.0, sin(phase) * 6.0)
		var knee_x: float = (x + foot_x) * 0.5 + sin(phase * 0.5) * 4.0
		var knee_y: float = y + 26.0
		b.line(Vector2(x - 12.0 + float(li) * 8.0, y), Vector2(knee_x, knee_y), col, 1.4)
		b.line(Vector2(knee_x, knee_y), Vector2(foot_x, foot_y), col, 1.2)
	b.circle(Vector2(x, y), 9.0, col)
	b.circle(Vector2(x - 8.0, y + 2.0), 6.5, col)
	b.line(Vector2(x - 12.0, y + 4.0), Vector2(x - 16.0, y + 14.0), col, 2.0)
	var obelisk := PackedVector2Array([
		Vector2(x - 4.0, y - 6.0),
		Vector2(x, y - 32.0),
		Vector2(x + 4.0, y - 6.0),
	])
	b.polygon(obelisk, col)


func _draw_melting_lamppost(b: ShapeBatch, p: Vector2, droop: float, t: float) -> void:
	var s_len := 58.0 + droop * 12.0
	var s_end := p + Vector2(1.6, 0.9).normalized() * s_len
	b.line(p, s_end, C_SHADOW, 5.0)

	b.circle(p + Vector2(1.0, 1.0), 9.0, Color(0, 0, 0, 0.25))
	b.circle(p, 8.0, C_BRONZE)
	b.circle(p, 5.0, C_BRONZE_HI)

	var bend_x: float = sin(p.y + t) * 2.0 + droop * 16.0
	var head_y: float = -38.0 + droop * 14.0
	var mid := p + Vector2(bend_x * 0.5, head_y * 0.5)
	var top := p + Vector2(bend_x, head_y)
	b.line(p, mid, C_BRONZE, 3.8)
	b.line(mid, top, C_BRONZE, 3.2)

	b.line(top, top + Vector2(-16.0, 4.0), C_BRONZE_HI, 2.8)
	b.line(top, top + Vector2(16.0, 4.0), C_BRONZE_HI, 2.8)

	var cp := top + Vector2(4.0, 6.0 + droop * 4.0)
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

	b.line(cp + Vector2(0.0, 2.0), cp + Vector2(1.0, -4.0), Color(0.15, 0.15, 0.15), 1.8)
	b.line(cp + Vector2(0.0, 2.0), cp + Vector2(6.0, 4.0), Color(0.15, 0.15, 0.15), 1.6)
	b.circle(cp + Vector2(0.0, 2.0), 1.4, C_CLOCK_GOLD)




func _draw_dragon_icon(b: ShapeBatch, p: Vector2, s: float) -> void:
	# Stylized trencadís mosaic dragon silhouette
	b.circle(p + Vector2(-s * 0.4, 0.0), s * 0.6, C_TRENCADIS_GREEN)
	b.circle(p + Vector2(s * 0.2, -s * 0.2), s * 0.5, C_TRENCADIS_BLUE)
	b.circle(p + Vector2(s * 0.7, s * 0.3), s * 0.4, C_TRENCADIS_GOLD)
	b.circle(p + Vector2(-s * 0.8, -s * 0.3), s * 0.35, C_TRENCADIS_GREEN)
	b.circle(p + Vector2(-s * 0.7, -s * 0.4), s * 0.15, C_TRENCADIS_GOLD)


func _draw_drac_gallery(b: ShapeBatch, t: float) -> void:
	var o: Vector2 = DetourScript.origin_for(main)
	var rw: float = DetourScript.ROOM_W
	var rh: float = DetourScript.ROOM_H

	# 1. Gallery Room Backdrop (warm Catalan sandstone rooftop courtyard)
	b.rect(Rect2(o, Vector2(rw, rh)), Color(0.18, 0.16, 0.15))

	# 2. Sandstone Paved Floor with undulating mosaic ribbons
	var cols := 6
	var rows := 5
	var tw := rw / float(cols)
	var th := rh / float(rows)
	for cy in range(rows):
		for cx in range(cols):
			var tr := Rect2(o.x + float(cx) * tw, o.y + float(cy) * th, tw - 1.5, th - 1.5)
			var base_c := C_SANDSTONE.lerp(C_CREAM, float((cx + cy) % 2) * 0.15)
			b.rect(tr, base_c)

	# Serpentine trencadís mosaic ribbon across floor
	for mi in range(12):
		var mf := float(mi) / 11.0
		var mx := o.x + 80.0 + mf * (rw - 160.0)
		var my := o.y + 360.0 + sin(mf * 4.2 + t * 0.5) * 45.0
		var col_idx := mi % 4
		var mcol: Color = [C_TRENCADIS_BLUE, C_TRENCADIS_GREEN, C_TRENCADIS_GOLD, C_TRENCADIS_RED][col_idx]
		b.circle(Vector2(mx, my), 14.0, mcol)
		b.circle(Vector2(mx + 6.0, my - 4.0), 9.0, C_TRENCADIS_WHITE)

	# 3. Parabolic Catenary Stone Arches along Walls
	for ax in range(5):
		var arch_x := o.x + 70.0 + float(ax) * 155.0
		b.rect(Rect2(arch_x - 14.0, o.y + 4.0, 28.0, 32.0), C_SANDSTONE)
		b.line(Vector2(arch_x - 12.0, o.y + 36.0), Vector2(arch_x + 12.0, o.y + 36.0), C_TRENCADIS_GOLD, 2.4)
		b.rect(Rect2(arch_x - 14.0, o.y + rh - 36.0, 28.0, 32.0), C_SANDSTONE)
		b.line(Vector2(arch_x - 12.0, o.y + rh - 36.0), Vector2(arch_x + 12.0, o.y + rh - 36.0), C_TRENCADIS_GOLD, 2.4)

	# 4. 4 Fantastical Chimney-Pot Sculptures (Rope Poles)
	for i in range(DetourScript.DRAC_SCULPTURE_OFFSETS.size()):
		var sp: Vector2 = o + DetourScript.DRAC_SCULPTURE_OFFSETS[i]
		# Soft ground shadow
		b.circle(sp + Vector2(6.0, 8.0), 22.0, Color(0.0, 0.0, 0.0, 0.28))
		# Main cylindrical chimney shaft with fluted terracotta ribs
		b.circle(sp, 16.0, C_ROOF_TILE)
		b.circle(sp, 13.5, C_SANDSTONE)

		if i == 0:
			# Spiral Helix Chimney with glazed emerald mosaic cap
			b.circle(sp, 11.0, C_TRENCADIS_GREEN)
			for sa in range(4):
				var ang := float(sa) * 1.57 + t * 0.8
				b.line(sp, sp + Vector2(cos(ang), sin(ang)) * 14.0, C_TRENCADIS_GOLD, 2.0)
			b.circle(sp, 4.5, C_TRENCADIS_WHITE)
		elif i == 1:
			# Mushroom-Cap Chimney with sunflower yellow & cobalt mosaic
			b.circle(sp, 12.0, C_TRENCADIS_GOLD)
			b.circle(sp, 8.5, C_TRENCADIS_BLUE)
			b.circle(sp, 5.0, C_TRENCADIS_WHITE)
		elif i == 2:
			# Conical Pyramid Chimney with terracotta & cream mosaic
			b.circle(sp, 11.5, C_TERRACOTTA)
			var poly := PackedVector2Array([
				sp + Vector2(0.0, -14.0),
				sp + Vector2(12.0, 10.0),
				sp + Vector2(-12.0, 10.0),
			])
			b.polygon(poly, C_CREAM)
			b.circle(sp, 4.0, C_TRENCADIS_RED)
		else:
			# Dragon-Spine Totem Chimney with crimson & gold crest
			b.circle(sp, 12.0, C_TRENCADIS_RED)
			b.circle(sp, 8.0, C_TRENCADIS_GOLD)
			for da in range(5):
				var dang := float(da) * 1.256
				b.circle(sp + Vector2(cos(dang), sin(dang)) * 13.0, 3.2, C_TRENCADIS_GOLD)
			b.circle(sp, 4.0, C_WROUGHT_IRON)

	# 5. Serpentine Trencadís Bench & El Drac (The Mosaic Dragon / Salamander)
	var drac_center: Vector2 = o + DetourScript.DRAC_SALAMANDER_POS
	var bench_poly := PackedVector2Array([
		drac_center + Vector2(-80.0, 24.0),
		drac_center + Vector2(-30.0, -18.0),
		drac_center + Vector2(30.0, -18.0),
		drac_center + Vector2(80.0, 24.0),
		drac_center + Vector2(74.0, 42.0),
		drac_center + Vector2(24.0, 6.0),
		drac_center + Vector2(-24.0, 6.0),
		drac_center + Vector2(-74.0, 42.0),
	])
	b.polygon(bench_poly, C_SANDSTONE)
	for bi in range(6):
		var bf := float(bi) / 5.0
		var bx := drac_center.x - 60.0 + bf * 120.0
		var by := drac_center.y + sin(bf * 3.14) * -12.0 + 10.0
		var bcol: Color = [C_TRENCADIS_BLUE, C_TRENCADIS_GOLD, C_TRENCADIS_GREEN, C_TRENCADIS_RED][bi % 4]
		b.circle(Vector2(bx, by), 6.5, bcol)

	# El Drac: The iconic mosaic salamander basking on the bench
	var drac_breath := sin(t * 3.2) * 1.8
	var dp := drac_center + Vector2(0.0, -2.0)
	b.circle(dp + Vector2(4.0, 6.0), 18.0, Color(0.0, 0.0, 0.0, 0.22))
	b.circle(dp + Vector2(-22.0, 4.0), 8.5 + drac_breath * 0.3, C_TRENCADIS_GREEN)
	b.circle(dp + Vector2(-10.0, 0.0), 10.5 + drac_breath * 0.5, C_TRENCADIS_BLUE)
	b.circle(dp + Vector2(4.0, -2.0), 11.5 + drac_breath * 0.5, C_TRENCADIS_GREEN)
	b.circle(dp + Vector2(18.0, 2.0), 9.5 + drac_breath * 0.3, C_TRENCADIS_GOLD)
	b.circle(dp + Vector2(-32.0, 6.0), 7.5, C_TRENCADIS_GREEN)
	b.circle(dp + Vector2(-38.0, 8.0), 5.0, C_TRENCADIS_GOLD)
	b.circle(dp + Vector2(-31.0, 3.0), 2.8, C_TRENCADIS_WHITE)
	b.circle(dp + Vector2(-31.0, 3.0), 1.6, C_WROUGHT_IRON)
	b.circle(dp + Vector2(28.0, 8.0), 6.5, C_TRENCADIS_BLUE)
	b.circle(dp + Vector2(34.0, 16.0), 4.5, C_TRENCADIS_GOLD)
	b.circle(dp + Vector2(32.0, 23.0), 3.0, C_TRENCADIS_GREEN)
	for si in range(4):
		var sx := dp.x - 18.0 + float(si) * 10.0
		var sy := dp.y - 7.0 + float(si % 2) * 2.0
		b.circle(Vector2(sx, sy), 2.8, C_TRENCADIS_RED)

	# 6. Central Plinth & Golden Dragon Bone
	var bp: Vector2 = o + DetourScript.BONE_POS
	b.circle(bp + Vector2(4.0, 6.0), 24.0, Color(0.0, 0.0, 0.0, 0.28))
	b.circle(bp, 20.0, C_SANDSTONE)
	for pi in range(8):
		var pang := float(pi) * 0.785
		var pcol: Color = [C_TRENCADIS_BLUE, C_TRENCADIS_GOLD, C_TRENCADIS_GREEN][pi % 3]
		b.circle(bp + Vector2(cos(pang), sin(pang)) * 14.0, 5.0, pcol)
	b.circle(bp, 10.0, C_TRENCADIS_WHITE)

	# Secret Golden Dragon Bone (floating & shimmering)
	if not main.drac_bone_taken:
		var bone_bob: float = sin(t * 3.4) * 4.5
		var bone_y: float = bp.y - 20.0 + bone_bob
		b.circle(Vector2(bp.x, bone_y), 16.0 + sin(t * 5.0) * 3.0, Color(1.0, 0.88, 0.25, 0.24))
		var bc := Vector2(bp.x, bone_y)
		b.line(bc + Vector2(-10.0, 0.0), bc + Vector2(10.0, 0.0), C_GOLD, 5.5)
		b.circle(bc + Vector2(-10.0, -3.5), 3.8, C_GOLD)
		b.circle(bc + Vector2(-10.0, 3.5), 3.8, C_GOLD)
		b.circle(bc + Vector2(10.0, -3.5), 3.8, C_GOLD)
		b.circle(bc + Vector2(10.0, 3.5), 3.8, C_GOLD)
		var spark_a := fmod(t * 2.8, 1.0) * 3.14159
		b.line(bc + Vector2(cos(spark_a), sin(spark_a)) * 7.0, bc - Vector2(cos(spark_a), sin(spark_a)) * 7.0, Color.WHITE, 1.8)

	# 7. Exit Portal (North Wall - Rooftop Balustrade Exit)
	var ep: Vector2 = o + DetourScript.ROOM_EXIT
	var arch_poly := PackedVector2Array([
		ep + Vector2(-38.0, 22.0),
		ep + Vector2(-38.0, -18.0),
		ep + Vector2(-22.0, -32.0),
		ep + Vector2(22.0, -32.0),
		ep + Vector2(38.0, -18.0),
		ep + Vector2(38.0, 22.0),
	])
	b.polygon(arch_poly, C_SANDSTONE)
	b.rect(Rect2(ep.x - 28.0, ep.y - 14.0, 56.0, 36.0), Color(0.12, 0.12, 0.14))
	for bi in range(5):
		var bx := ep.x - 22.0 + float(bi) * 11.0
		b.line(Vector2(bx, ep.y + 12.0), Vector2(bx, ep.y + 22.0), C_TRENCADIS_GOLD, 2.0)
	var exit_glow := PackedVector2Array([
		ep + Vector2(-26.0, 20.0),
		ep + Vector2(-42.0, 55.0),
		ep + Vector2(42.0, 55.0),
		ep + Vector2(26.0, 20.0),
	])
	b.polygon(exit_glow, Color(1.0, 0.95, 0.85, 0.22))


func _draw_dove_icon(b: ShapeBatch, p: Vector2, s: float) -> void:
	# tiny faceted street pigeon (original): slate wing facet, ochre breast, no
	# olive sprig and no white dove silhouette
	b.polygon(PackedVector2Array([p + Vector2(-s * 0.9, s * 0.3), p + Vector2(s * 0.5, -s * 0.7), p + Vector2(s * 0.9, s * 0.5)]), C_SLATE)
	b.polygon(PackedVector2Array([p + Vector2(-s * 0.9, s * 0.3), p + Vector2(s * 0.9, s * 0.5), p + Vector2(-s * 0.2, s * 0.9)]), C_OCHRE)
	b.circle(p + Vector2(-s * 0.7, -s * 0.2), s * 0.4, C_CHARCOAL)


func _draw_colom_gallery(b: ShapeBatch, t: float) -> void:
	var o: Vector2 = DetourScript.origin_for(main)
	var rw: float = DetourScript.ROOM_W
	var rh: float = DetourScript.ROOM_H

	# 1. Gallery Room Backdrop
	b.rect(Rect2(o, Vector2(rw, rh)), Color(0.16, 0.14, 0.13))

	# 2. Faceted Analytical Cubist Floor Tiles
	var tile_cols := [C_CREAM, C_OCHRE, C_SLATE, C_TERRACOTTA, C_UMBER]
	var cols := 6
	var rows := 5
	var tw := rw / float(cols)
	var th := rh / float(rows)
	for rx in range(cols):
		for ry in range(rows):
			var tp := o + Vector2(float(rx) * tw, float(ry) * th)
			var ci := (rx * 3 + ry * 2) % tile_cols.size()
			var c1: Color = tile_cols[ci]
			var c2: Color = tile_cols[(ci + 1) % tile_cols.size()]
			# Diagonal split facet triangles
			var t1 := PackedVector2Array([tp, tp + Vector2(tw, 0.0), tp + Vector2(0.0, th)])
			var t2 := PackedVector2Array([tp + Vector2(tw, 0.0), tp + Vector2(tw, th), tp + Vector2(0.0, th)])
			b.polygon(t1, c1)
			b.polygon(t2, c2)
			b.line(tp, tp + Vector2(tw, th), C_CHARCOAL, 1.2)
			b.line(tp, tp + Vector2(tw, 0.0), C_CHARCOAL.darkened(0.2), 1.0)
			b.line(tp, tp + Vector2(0.0, th), C_CHARCOAL.darkened(0.2), 1.0)

	# 3. Wall Collaged Newsprint & Sheet Music Murals
	# West wall: «LE JOURNAL» cubist headlines
	var j_pos := o + Vector2(50.0, 180.0)
	b.rect(Rect2(j_pos, Vector2(72.0, 96.0)), C_CREAM)
	b.line(j_pos + Vector2(6.0, 16.0), j_pos + Vector2(66.0, 16.0), C_CHARCOAL, 3.2)
	for li in range(6):
		var ly: float = j_pos.y + 26.0 + float(li) * 11.0
		b.line(Vector2(j_pos.x + 8.0, ly), Vector2(j_pos.x + 64.0, ly), C_SLATE, 1.4)

	# East wall: Sheet music stave & notes
	var m_pos := o + Vector2(rw - 120.0, 180.0)
	b.rect(Rect2(m_pos, Vector2(72.0, 96.0)), C_CREAM.darkened(0.05))
	for si in range(5):
		var sy: float = m_pos.y + 20.0 + float(si) * 8.0
		b.line(Vector2(m_pos.x + 6.0, sy), Vector2(m_pos.x + 66.0, sy), C_CHARCOAL, 1.2)
	for ni in range(4):
		var nx: float = m_pos.x + 16.0 + float(ni) * 14.0
		var ny: float = m_pos.y + 28.0 + (ni % 3) * 8.0
		b.circle(Vector2(nx, ny), 3.2, C_CHARCOAL)
		b.line(Vector2(nx + 2.5, ny), Vector2(nx + 2.5, ny - 16.0), C_CHARCOAL, 1.5)

	# 4. 4 Cubist Faceted Sculptures (wrapped as rope poles)
	for i in range(DetourScript.COLOM_SCULPTURE_OFFSETS.size()):
		var sp: Vector2 = o + DetourScript.COLOM_SCULPTURE_OFFSETS[i]
		_draw_colom_sculpture(b, sp, i, t)

	# 5. 3 Barcelona Pigeons ("Els Coloms")
	for i in range(DetourScript.COLOM_DOVE_OFFSETS.size()):
		var dp: Vector2 = o + DetourScript.COLOM_DOVE_OFFSETS[i]
		_draw_peace_dove(b, dp, i, t)

	# 6. Central Faceted Pedestal & Golden Cubist Bone
	var bp: Vector2 = o + DetourScript.BONE_POS
	# Hexagonal faceted pedestal
	var ped_pts := PackedVector2Array([
		bp + Vector2(-22.0, -14.0),
		bp + Vector2(0.0, -22.0),
		bp + Vector2(22.0, -14.0),
		bp + Vector2(22.0, 14.0),
		bp + Vector2(0.0, 22.0),
		bp + Vector2(-22.0, 14.0),
	])
	b.polygon(ped_pts, C_SLATE)
	# Facet divisions
	b.line(bp, ped_pts[0], C_CHARCOAL, 2.0)
	b.line(bp, ped_pts[1], C_CHARCOAL, 2.0)
	b.line(bp, ped_pts[2], C_CHARCOAL, 2.0)
	b.line(bp, ped_pts[3], C_CHARCOAL, 2.0)
	b.line(bp, ped_pts[4], C_CHARCOAL, 2.0)
	b.line(bp, ped_pts[5], C_CHARCOAL, 2.0)
	b.circle(bp, 6.0, C_OCHRE)

	# Golden Cubist Bone
	if not main.colom_bone_taken:
		var bob: float = sin(t * 3.2) * 5.0
		var bone_y: float = bp.y - 18.0 + bob
		# Warm cubist aura
		b.circle(Vector2(bp.x, bone_y), 19.0, Color(1.0, 0.88, 0.25, 0.28))
		b.circle(Vector2(bp.x, bone_y), 12.0, Color(1.0, 0.96, 0.60, 0.45))
		# Faceted bone body (angular polygons)
		var b_shaft := PackedVector2Array([
			Vector2(bp.x - 12.0, bone_y - 3.0),
			Vector2(bp.x, bone_y - 4.5),
			Vector2(bp.x + 12.0, bone_y - 3.0),
			Vector2(bp.x + 12.0, bone_y + 3.0),
			Vector2(bp.x, bone_y + 4.5),
			Vector2(bp.x - 12.0, bone_y + 3.0),
		])
		b.polygon(b_shaft, C_GOLD)
		b.line(Vector2(bp.x - 12.0, bone_y), Vector2(bp.x + 12.0, bone_y), Color(1.0, 0.98, 0.8), 1.5)
		# Knobs
		b.rect(Rect2(Vector2(bp.x - 16.0, bone_y - 7.0), Vector2(6.0, 6.0)), C_GOLD)
		b.rect(Rect2(Vector2(bp.x - 16.0, bone_y + 1.0), Vector2(6.0, 6.0)), C_GOLD)
		b.rect(Rect2(Vector2(bp.x + 10.0, bone_y - 7.0), Vector2(6.0, 6.0)), C_GOLD)
		b.rect(Rect2(Vector2(bp.x + 10.0, bone_y + 1.0), Vector2(6.0, 6.0)), C_GOLD)
		# Glimmer
		var gl: float = sin(t * 5.0) * 6.0
		b.line(Vector2(bp.x - gl, bone_y), Vector2(bp.x + gl, bone_y), Color(1, 1, 1, 0.8), 1.5)
		b.line(Vector2(bp.x, bone_y - gl), Vector2(bp.x, bone_y + gl), Color(1, 1, 1, 0.8), 1.5)

	# 7. Exit Portal Arch at North wall
	var ep: Vector2 = o + DetourScript.ROOM_EXIT
	var exit_glow := PackedVector2Array([
		ep + Vector2(-36.0, -18.0),
		ep + Vector2(-70.0, 48.0),
		ep + Vector2(70.0, 48.0),
		ep + Vector2(36.0, -18.0),
	])
	b.polygon(exit_glow, Color(1.0, 0.94, 0.76, 0.28))
	b.rect(Rect2(ep + Vector2(-38.0, -22.0), Vector2(76.0, 44.0)), C_CHARCOAL)
	b.rect(Rect2(ep + Vector2(-32.0, -16.0), Vector2(64.0, 36.0)), C_CREAM)


func _draw_peace_dove(b: ShapeBatch, p: Vector2, i: int, t: float) -> void:
	# "Barcelona pigeon" (original replacement for the old peace dove): a plump
	# faceted plaza pigeon in slate, ochre and terracotta, a teal neck facet,
	# and a bobbing head. No olive branch, no white dove.
	b.rect(Rect2(p + Vector2(-16.0, 10.0), Vector2(32.0, 6.0)), C_UMBER)
	b.line(p + Vector2(0.0, 16.0), p + Vector2(0.0, 24.0), C_CHARCOAL, 2.0)
	var bob: float = sin(t * 4.0 + float(i) * 1.7) * 2.0
	b.polygon(PackedVector2Array([p + Vector2(-8.0, -2.0), p + Vector2(14.0, -8.0), p + Vector2(18.0, 8.0), p + Vector2(0.0, 11.0)]), C_SLATE)
	b.polygon(PackedVector2Array([p + Vector2(-8.0, -2.0), p + Vector2(0.0, 11.0), p + Vector2(-12.0, 8.0)]), C_OCHRE)
	b.polygon(PackedVector2Array([p + Vector2(14.0, -8.0), p + Vector2(18.0, 8.0), p + Vector2(26.0, 12.0)]), C_UMBER)
	b.line(p + Vector2(-8.0, -2.0), p + Vector2(18.0, 8.0), C_CHARCOAL, 1.2)
	b.polygon(PackedVector2Array([p + Vector2(2.0, -4.0), p + Vector2(16.0, -6.0), p + Vector2(10.0, 6.0)]), C_TERRACOTTA)
	# head: two facets (front and side, a cubist nod) with a teal collar
	var hp := p + Vector2(-12.0, -8.0 + bob)
	b.circle(hp, 6.0, C_CREAM)
	b.polygon(PackedVector2Array([hp + Vector2(0.0, -6.0), hp + Vector2(6.0, 0.0), hp + Vector2(0.0, 6.0)]), C_SLATE)
	b.polygon(PackedVector2Array([hp + Vector2(-5.0, 5.0), hp + Vector2(5.0, 5.0), hp + Vector2(3.0, 9.0), hp + Vector2(-3.0, 9.0)]), Color(0.18, 0.55, 0.52))
	b.circle(hp + Vector2(-2.0, -1.0), 1.5, C_TERRACOTTA)
	b.polygon(PackedVector2Array([hp + Vector2(-5.0, 0.0), hp + Vector2(-12.0, 2.0), hp + Vector2(-5.0, 3.0)]), C_UMBER)


func _draw_colom_sculpture(b: ShapeBatch, p: Vector2, idx: int, _t: float) -> void:
	# Cast shadow & circular base contact (rope wrap pole)
	b.circle(p + Vector2(1.5, 2.5), 10.0, Color(0, 0, 0, 0.26))
	b.circle(p, 8.0, C_CHARCOAL)
	b.circle(p, 5.0, C_CREAM)

	match idx:
		0:
			# Sculpture 0: Guitar & Mandolin
			# Faceted angular body
			var g_pts := PackedVector2Array([
				p + Vector2(-18.0, -8.0),
				p + Vector2(-8.0, -34.0),
				p + Vector2(14.0, -28.0),
				p + Vector2(18.0, 6.0),
				p + Vector2(0.0, 14.0),
			])
			b.polygon(g_pts, C_OCHRE)
			b.line(p + Vector2(-8.0, -34.0), p + Vector2(0.0, 14.0), C_UMBER, 2.0)
			# Soundhole
			b.circle(p + Vector2(0.0, -12.0), 6.0, C_CHARCOAL)
			# Strings
			for si in range(3):
				var sx: float = -3.0 + float(si) * 3.0
				b.line(p + Vector2(sx, -32.0), p + Vector2(sx, 10.0), C_WHITE, 1.2)
		1:
			# Sculpture 1: Harlequin
			# Lozenge diamond body
			var h_pts := PackedVector2Array([
				p + Vector2(0.0, -38.0),
				p + Vector2(16.0, -16.0),
				p + Vector2(0.0, 12.0),
				p + Vector2(-16.0, -16.0),
			])
			b.polygon(h_pts, C_TERRACOTTA)
			# Harlequin diamond facets
			var inner_diamond := PackedVector2Array([
				p + Vector2(0.0, -26.0),
				p + Vector2(8.0, -16.0),
				p + Vector2(0.0, -4.0),
				p + Vector2(-8.0, -16.0),
			])
			b.polygon(inner_diamond, C_CREAM)
			b.line(p + Vector2(-16.0, -16.0), p + Vector2(16.0, -16.0), C_CHARCOAL, 2.0)
			b.line(p + Vector2(0.0, -38.0), p + Vector2(0.0, 12.0), C_CHARCOAL, 2.0)
			# Bicorne hat
			b.line(p + Vector2(-12.0, -36.0), p + Vector2(12.0, -36.0), C_CHARCOAL, 3.2)
		2:
			# Sculpture 2: Cubist Hound (original; replaces the old horned bull head).
			# One face seen from two sides: a front facet and a profile facet.
			b.polygon(PackedVector2Array([p + Vector2(-14.0, -12.0), p + Vector2(-2.0, -34.0), p + Vector2(0.0, 10.0), p + Vector2(-10.0, 4.0)]), C_SLATE)
			b.polygon(PackedVector2Array([p + Vector2(-2.0, -34.0), p + Vector2(16.0, -22.0), p + Vector2(22.0, -4.0), p + Vector2(0.0, 10.0)]), C_OCHRE)
			b.polygon(PackedVector2Array([p + Vector2(-14.0, -12.0), p + Vector2(-24.0, -4.0), p + Vector2(-12.0, 2.0)]), C_UMBER)
			b.rect(Rect2(p + Vector2(14.0, -8.0), Vector2(9.0, 8.0)), C_CHARCOAL)
			b.line(p + Vector2(-2.0, -34.0), p + Vector2(0.0, 10.0), C_CHARCOAL, 2.0)
			b.circle(p + Vector2(-7.0, -16.0), 2.4, C_CREAM)
			b.circle(p + Vector2(-7.0, -16.0), 1.1, C_CHARCOAL)
			b.circle(p + Vector2(9.0, -16.0), 2.2, C_TERRACOTTA)
		3:
			# Sculpture 3: Pitcher & Palette
			# Pitcher body
			var pit := PackedVector2Array([
				p + Vector2(-10.0, -28.0),
				p + Vector2(10.0, -28.0),
				p + Vector2(14.0, -6.0),
				p + Vector2(-14.0, -6.0),
			])
			b.polygon(pit, C_TERRACOTTA)
			# Palette intersecting
			var pal := PackedVector2Array([
				p + Vector2(-16.0, -4.0),
				p + Vector2(16.0, -10.0),
				p + Vector2(18.0, 12.0),
				p + Vector2(-12.0, 14.0),
			])
			b.polygon(pal, C_CREAM)
			b.circle(p + Vector2(10.0, 4.0), 3.0, C_CHARCOAL) # Thumbhole
			b.circle(p + Vector2(-8.0, 2.0), 2.2, C_RED)
			b.circle(p + Vector2(-2.0, 0.0), 2.2, C_YELLOW)
			b.circle(p + Vector2(4.0, -2.0), 2.2, C_BLUE)


func _draw_labels() -> void:
	var f := ThemeDB.fallback_font
	var is_drac: bool = main.detour_kind == "drac" or main.lvl == "street"
	var is_estel: bool = main.detour_kind == "estel" or main.lvl == "montjuic"
	var is_colom: bool = main.detour_kind == "colom" or main.lvl == "reial"

	# Street entrance banner labels
	var dp: Vector2 = main.detour_door_pos
	if dp != Vector2.ZERO:
		var bp := dp + Vector2(26.0, -56.0)
		if is_drac:
			draw_string(f, bp + Vector2(-40.0, -1.0), "EXPOSICIÓ - ENTRADA LLIURE", HORIZONTAL_ALIGNMENT_CENTER, 80, 8, C_WROUGHT_IRON)
			draw_string(f, bp + Vector2(-40.0, 9.0), "«EL DRAC»", HORIZONTAL_ALIGNMENT_CENTER, 80, 9, C_TRENCADIS_GOLD)
			var easel_p := dp + Vector2(64.0, 38.0)
			draw_string(f, easel_p + Vector2(-8.0, 0.0), "«EL DRAC»", HORIZONTAL_ALIGNMENT_CENTER, 16, 7, C_WHITE)
		elif is_colom:
			draw_string(f, bp + Vector2(-40.0, -1.0), "EXPOSICIÓ - ENTRADA LLIURE", HORIZONTAL_ALIGNMENT_CENTER, 80, 8, C_CHARCOAL)
			draw_string(f, bp + Vector2(-40.0, 9.0), "«EL COLOM»", HORIZONTAL_ALIGNMENT_CENTER, 80, 9, C_TERRACOTTA)
			var easel_p := dp + Vector2(64.0, 38.0)
			draw_string(f, easel_p + Vector2(-8.0, 0.0), "«EL COLOM»", HORIZONTAL_ALIGNMENT_CENTER, 16, 7, C_WHITE)
		elif is_estel:
			draw_string(f, bp + Vector2(-40.0, -1.0), "EXPOSICIÓ - ENTRADA LLIURE", HORIZONTAL_ALIGNMENT_CENTER, 80, 8, C_BLACK)
			draw_string(f, bp + Vector2(-40.0, 9.0), "«L'ESTEL»", HORIZONTAL_ALIGNMENT_CENTER, 80, 9, C_RED)
			var easel_p := dp + Vector2(64.0, 38.0)
			draw_string(f, easel_p + Vector2(-8.0, 0.0), "«L'ESTEL»", HORIZONTAL_ALIGNMENT_CENTER, 16, 7, C_WHITE)
		else:
			draw_string(f, bp + Vector2(-40.0, -1.0), "EXPOSICIÓ - ENTRADA LLIURE", HORIZONTAL_ALIGNMENT_CENTER, 80, 8, Color.WHITE)
			draw_string(f, bp + Vector2(-40.0, 9.0), "«EL SOMNI»", HORIZONTAL_ALIGNMENT_CENTER, 80, 9, C_CARPET_GOLD)
			var easel_p := dp + Vector2(62.0, 38.0)
			draw_string(f, easel_p + Vector2(-8.0, 0.0), "GALERIA", HORIZONTAL_ALIGNMENT_CENTER, 16, 7, Color.WHITE)

	# Detour gallery labels
	var o: Vector2 = DetourScript.origin_for(main)
	if main.detour_active or absf(main.cam.position.y - (o.y + DetourScript.ROOM_H * 0.5)) < 700.0:
		var ep: Vector2 = o + DetourScript.ROOM_EXIT
		var bp: Vector2 = o + DetourScript.BONE_POS
		if is_drac:
			draw_string(f, ep + Vector2(-40.0, -26.0), "SORTIDA - A LA RAMBLA", HORIZONTAL_ALIGNMENT_CENTER, 80, 9, C_WROUGHT_IRON)
			if main.drac_bone_taken:
				draw_string(f, bp + Vector2(-30.0, 2.0), "COL·LECCIONAT", HORIZONTAL_ALIGNMENT_CENTER, 60, 8, C_TRENCADIS_GOLD)
		elif is_colom:
			draw_string(f, ep + Vector2(-40.0, -26.0), "SORTIDA - A PLAÇA REIAL", HORIZONTAL_ALIGNMENT_CENTER, 80, 9, C_CHARCOAL)
			if main.colom_bone_taken:
				draw_string(f, bp + Vector2(-30.0, 2.0), "COL·LECCIONAT", HORIZONTAL_ALIGNMENT_CENTER, 60, 8, C_TERRACOTTA)
		elif is_estel:
			draw_string(f, ep + Vector2(-40.0, -26.0), "SORTIDA - A MONTJUÏC", HORIZONTAL_ALIGNMENT_CENTER, 80, 9, C_BLACK)
			if main.estel_bone_taken:
				draw_string(f, bp + Vector2(-30.0, 2.0), "COL·LECCIONAT", HORIZONTAL_ALIGNMENT_CENTER, 60, 8, C_RED)
		else:
			draw_string(f, ep + Vector2(-40.0, -26.0), "SORTIDA - A LA CIUTAT", HORIZONTAL_ALIGNMENT_CENTER, 80, 9, Color(0.20, 0.16, 0.12))
			if main.somni_bone_taken:
				draw_string(f, bp + Vector2(-30.0, 2.0), "COL·LECCIONAT", HORIZONTAL_ALIGNMENT_CENTER, 60, 8, C_CLOCK_GOLD)
