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
		return
	m.cam.zoom *= float(m.ui_scale) / k
	m.ui_scale = k
	win.content_scale_factor = k
