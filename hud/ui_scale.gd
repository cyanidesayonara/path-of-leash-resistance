extends RefCounted

# Small screens: the HUD, the menus and the lesson cards scale up, the walk
# keeps its framing.
#
# The game is composed for 1280x720 and stretched (canvas_items, expand), so a
# phone held sideways (844x390) draws everything at 0.54: 15px text lands at
# about 8px. Below MIN_FRAME the window's content scale factor grows to bring
# the frame back up to MIN_FRAME, which enlarges every canvas item - and the
# camera's zoom is divided by the same factor, so the world shows exactly what
# it did. Anchored HUD layout follows by itself: the viewport, in canvas units,
# is simply smaller.

const REF := Vector2(1280.0, 720.0)
# the frame scale below which the interface is enlarged, and the most it grows
const MIN_FRAME := 0.78
const MAX_FACTOR := 1.45

# override for headless tests; negative X means query OS/cmdline normally
static var test_safe_insets := Vector4(-1.0, -1.0, -1.0, -1.0)


# Safe-area insets (left, top, right, bottom) in viewport canvas coordinates,
# returning Vector4.ZERO on desktop/web when unclipped so desktop framing
# never shifts.
static func safe_insets(win: Window = null) -> Vector4:
	if test_safe_insets.x >= 0.0:
		return test_safe_insets
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--safe-area="):
			var parts := a.substr(12).split(",")
			if parts.size() >= 4:
				return Vector4(maxf(0.0, float(parts[0])), maxf(0.0, float(parts[1])),
					maxf(0.0, float(parts[2])), maxf(0.0, float(parts[3])))
	if DisplayServer.get_name() == "headless" or win == null:
		return Vector4.ZERO
	if not OS.has_feature("android") and not OS.has_feature("ios"):
		return Vector4.ZERO
	var wsize := Vector2(win.size)
	if wsize.x <= 0.0 or wsize.y <= 0.0:
		return Vector4.ZERO
	var sa := Rect2(DisplayServer.get_display_safe_area())
	if sa.size.x <= 0.0 or sa.size.y <= 0.0:
		return Vector4.ZERO
	var win_rect := Rect2(Vector2(win.position), wsize)
	if not sa.intersects(win_rect):
		return Vector4.ZERO
	var vp := win.get_viewport()
	var vs := vp.get_visible_rect().size if vp != null else wsize
	if vs.x <= 0.0 or vs.y <= 0.0:
		return Vector4.ZERO
	var sx := vs.x / wsize.x
	var sy := vs.y / wsize.y
	return Vector4(
		maxf(0.0, (sa.position.x - win_rect.position.x) * sx),
		maxf(0.0, (sa.position.y - win_rect.position.y) * sy),
		maxf(0.0, (win_rect.end.x - sa.end.x) * sx),
		maxf(0.0, (win_rect.end.y - sa.end.y) * sy))


# Keep top-corner HUD cards inside display cutouts / notches.
static func apply_safe_area(m: Node2D) -> void:
	var win: Window = m.get_window() if m.is_inside_tree() else null
	var ins := safe_insets(win)
	if m.panel != null:
		m.panel.position = Vector2(16.0 + ins.x, 12.0 + ins.y)
	if m.goals_card != null:
		m.goals_card.position.y = 8.0 + ins.y
		if ins.z > 0.0:
			var vw: float = m.get_viewport_rect().size.x if m.is_inside_tree() else REF.x
			var gw: float = m.goals_card.size.x if m.goals_card.size.x > 0.0 else 200.0
			m.goals_card.position.x = (vw if vw > 0.0 else REF.x) - 8.0 - ins.z - gw


# The content scale factor for a window of this size in logical pixels.
static func factor_for(logical: Vector2) -> float:
	var s := minf(logical.x / REF.x, logical.y / REF.y)
	if s <= 0.0 or s >= MIN_FRAME:
		return 1.0
	return clampf(MIN_FRAME / s, 1.0, MAX_FACTOR)


# The window in logical pixels: the browser reports device pixels, and the
# device pixel ratio is what screen_get_scale() returns there.
static func logical_size(win: Window) -> Vector2:
	return Vector2(win.size) / maxf(DisplayServer.screen_get_scale(), 1.0)


# Set the factor for the window as it is now, and undo it on the camera.
# --ui-scale=K forces a factor, for screenshots.
static func apply(m: Node2D) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var win: Window = m.get_window()
	var k := factor_for(logical_size(win))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ui-scale="):
			k = clampf(float(a.substr(11)), 0.5, 3.0)
	if is_equal_approx(k, float(m.ui_scale)) and is_equal_approx(win.content_scale_factor, k):
		apply_safe_area(m)
		return
	m.cam.zoom *= float(m.ui_scale) / k
	m.ui_scale = k
	win.content_scale_factor = k
	apply_safe_area(m)
