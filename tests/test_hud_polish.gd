extends SceneTree

# Tests HUD polish improvements:
# 1. UiIcons vector drawing functions (phone pip active/broken, droplet, bolt,
#    meter, bone, check, star).
# 2. HudPanel layout and point rects for phone, bladder, and sprint energy.
# 3. GoalsCard dimensions and constants.
# 4. EventFeed 4-tier communication architecture: banners, toasts, and shouts.

const UiIcons := preload("res://hud/ui_icons.gd")
const HudPanel := preload("res://hud/hud_panel.gd")
const GoalsCard := preload("res://hud/goals_card.gd")
const EventFeed := preload("res://hud/event_feed.gd")

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("  FAIL  " + what)


# A lightweight mock object for exercising vector draw functions
class MockCanvas extends RefCounted:
	var drawn_rects: Array[Rect2] = []
	var drawn_polys: int = 0
	var drawn_lines: Array[Dictionary] = []
	var drawn_circles: Array[Vector2] = []

	func draw_rect(r: Rect2, _col: Color, _filled: bool = true, _w: float = -1.0) -> void:
		drawn_rects.append(r)

	func draw_colored_polygon(_pts: PackedVector2Array, _col: Color, _uvs := PackedVector2Array(), _tex: Texture2D = null) -> void:
		drawn_polys += 1

	func draw_line(from: Vector2, to: Vector2, col: Color, w: float = -1.0, _antialiased: bool = false) -> void:
		drawn_lines.append({"from": from, "to": to, "col": col, "w": w})

	func draw_circle(pos: Vector2, _r: float, _col: Color) -> void:
		drawn_circles.append(pos)


func _initialize() -> void:
	print("--- testing UiIcons vector primitives ---")
	var mock := MockCanvas.new()

	# 1. Phone pips
	mock.drawn_rects.clear()
	mock.drawn_lines.clear()
	UiIcons.draw_phone_pip(mock, Vector2(10, 10), 24.0, true)
	_check(mock.drawn_rects.size() >= 2, "active phone pip draws chassis and screen")
	_check(mock.drawn_lines.size() >= 1, "active phone pip draws speaker slit")

	mock.drawn_rects.clear()
	mock.drawn_lines.clear()
	UiIcons.draw_phone_pip(mock, Vector2(10, 10), 24.0, false)
	_check(mock.drawn_rects.size() >= 2, "lost phone pip draws chassis and dark screen")
	_check(mock.drawn_lines.size() >= 4, "lost phone pip draws fracture crack lines")

	# 2. Droplet and Bolt glyphs
	mock.drawn_polys = 0
	UiIcons.draw_droplet(mock, Vector2(20, 80), 8.0, UiIcons.GOLD)
	_check(mock.drawn_polys == 1, "droplet draws a vector polygon")

	mock.drawn_polys = 0
	UiIcons.draw_bolt(mock, Vector2(40, 80), 8.0, UiIcons.GREEN)
	_check(mock.drawn_polys == 1, "bolt draws a vector polygon")

	# 3. Check and Meter
	mock.drawn_rects.clear()
	mock.drawn_lines.clear()
	UiIcons.draw_check(mock, Vector2(0, 0), 14.0, UiIcons.Check.OPEN)
	_check(mock.drawn_rects.size() >= 1, "check box draws border rect")

	mock.drawn_rects.clear()
	mock.drawn_lines.clear()
	UiIcons.draw_check(mock, Vector2(0, 0), 14.0, UiIcons.Check.DONE_NOW)
	_check(mock.drawn_lines.size() >= 2, "done check draws two tick strokes")

	mock.drawn_rects.clear()
	mock.drawn_lines.clear()
	UiIcons.draw_check(mock, Vector2(0, 0), 14.0, UiIcons.Check.DONE_BEFORE)
	_check(mock.drawn_lines.size() >= 2, "done before check draws two tick strokes")

	mock.drawn_rects.clear()
	mock.drawn_lines.clear()
	mock.drawn_circles.clear()
	UiIcons.draw_check(mock, Vector2(0, 0), 14.0, UiIcons.Check.PARTIAL)
	_check(mock.drawn_circles.size() == 1, "partial check draws center pip")

	mock.drawn_rects.clear()
	UiIcons.draw_meter(mock, Vector2(0, 0), 60.0, 8.0, 0.5)
	_check(mock.drawn_rects.size() >= 2, "meter draws background and progress fill")

	# 4. Bone and Star
	mock.drawn_lines.clear()
	mock.drawn_circles.clear()
	UiIcons.draw_bone(mock, Vector2(100, 20), 12.0)
	_check(mock.drawn_lines.size() == 1, "bone draws center shaft line")
	_check(mock.drawn_circles.size() == 4, "bone draws four corner knobs")

	mock.drawn_polys = 0
	UiIcons.draw_star(mock, Vector2(50, 50), 10.0, true)
	_check(mock.drawn_polys == 1, "star draws filled colored polygon")

	print("--- testing HudPanel POINT_RECTS ---")
	_check(HudPanel.POINT_RECTS.has("phone"), "hud panel defines phone focus rect")
	_check(HudPanel.POINT_RECTS.has("tank"), "hud panel defines bladder tank focus rect")
	_check(HudPanel.POINT_RECTS.has("zoomies"), "hud panel defines zoomies energy focus rect")

	var pr_phone: Rect2 = HudPanel.POINT_RECTS["phone"]
	_check(pr_phone.size.x >= 60.0 and pr_phone.size.y >= 24.0, "phone focus rect encloses the 3 pips")

	var pr_tank: Rect2 = HudPanel.POINT_RECTS["tank"]
	_check(pr_tank.has_point(Vector2(16, 42)) and pr_tank.has_point(Vector2(22, 84)),
		"tank focus rect encloses both tube and droplet glyph")

	var pr_zoomies: Rect2 = HudPanel.POINT_RECTS["zoomies"]
	_check(pr_zoomies.has_point(Vector2(34, 42)) and pr_zoomies.has_point(Vector2(40, 84)),
		"zoomies focus rect encloses both tube and bolt glyph")

	print("--- testing GoalsCard geometry ---")
	var gc: Control = GoalsCard.new()
	root.add_child(gc)
	_check(gc.W == 416.0, "goals card reference width is 416")
	_check(gc.GOALS_X == 856.0, "goals card reference position x is 856")
	_check(gc.ROW_H == 21.0, "goals card row height is 21")
	gc.free()

	print("--- testing EventFeed messaging hierarchy ---")
	var feed: Control = EventFeed.new()
	root.add_child(feed)

	feed.set_banner("FIND THE OFF-LEASH PARK")
	_check(feed.banner == "FIND THE OFF-LEASH PARK", "banner updates correctly")

	feed.say("VAULT!", EventFeed.Tone.GOOD)
	_check(feed.lines.size() == 1, "shout is queued")
	_check(String(feed.lines[0]["text"]) == "VAULT!", "shout text matches")

	feed.toast("goal", "SCARE 5 PIGEONS", "4/5 pigeons scattered", UiIcons.GOLD)
	_check(feed.toasts.size() == 1, "toast is queued")
	_check(String(feed.toasts[0]["side"]) == "goal", "toast side is goal")

	feed.toast("mood", "ZOOMIES", "Millie feels energetic!", UiIcons.GREEN)
	_check(feed.toasts.size() == 2, "second toast is queued")

	feed.clear()
	_check(feed.lines.is_empty(), "clear empties shouts")
	_check(feed.toasts.is_empty(), "clear empties toasts")
	feed.free()

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_hud_polish: OK")
		quit(0)
	else:
		print("test_hud_polish: FAILED")
		quit(1)
