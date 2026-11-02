extends Control

# The word she is spelling (systems/tony_hawk.gd), Tony Hawk style: a row of
# tiles under the banner. A letter she picks up flies from where it lay into
# its tile and lands with a pop; the rest of the word waits faint in its
# tiles. It shows while she is collecting and fades out after.

const Kit := preload("res://hud/ui_kit.gd")

const TILE := 44.0
const GAP := 8.0
const FLY_S := 0.38
const POP_S := 0.22
const HOLD_S := 2.6
const FADE_S := 0.45
# where it sits, as a share of the screen's height
const Y_SHARE := 0.25
const GOLD := Color(1.0, 0.84, 0.26)

var main: Node2D
var t := 99.0
# the letter in flight: its index in the word, where it set off (screen), and
# how long it has flown
var fly_i := -1
var fly_from := Vector2.ZERO
var fly_t := 0.0


func setup(m: Node2D) -> void:
	main = m


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


# A letter was picked up at world position at: it flies into its tile.
func collect(index: int, at: Vector2) -> void:
	fly_i = index
	fly_t = 0.0
	t = 0.0
	fly_from = Vector2(get_viewport_rect().size.x * 0.5, get_viewport_rect().size.y * 0.5)
	if main != null and main.is_inside_tree():
		var screen: Vector2 = main.get_viewport().get_canvas_transform() * at
		fly_from = get_global_transform_with_canvas().affine_inverse() * screen
	queue_redraw()


func showing() -> bool:
	return t < HOLD_S + FADE_S


func _process(delta: float) -> void:
	if not showing():
		return
	t += delta
	fly_t += delta
	queue_redraw()


func tile_rect(i: int, n: int, vs: Vector2) -> Rect2:
	var w := float(n) * TILE + float(n - 1) * GAP
	return Rect2(vs.x * 0.5 - w * 0.5 + float(i) * (TILE + GAP), vs.y * Y_SHARE, TILE, TILE)


func _draw() -> void:
	if main == null or not showing():
		return
	var letters: Array = main.word_letters
	var n := letters.size()
	if n == 0:
		return
	var vs := get_viewport_rect().size
	var a := clampf((HOLD_S + FADE_S - t) / FADE_S, 0.0, 1.0)
	var f := Kit.display()
	var flying := fly_i >= 0 and fly_t < FLY_S
	for i in range(n):
		var l: Dictionary = letters[i]
		var c := tile_rect(i, n, vs).get_center()
		var got := bool(l.collected) and not (flying and i == fly_i)
		# a just-landed coin pops: bigger, then settles
		var k := 0.0
		if i == fly_i and fly_t >= FLY_S:
			k = clampf(1.0 - (fly_t - FLY_S) / POP_S, 0.0, 1.0)
		var r := TILE * 0.5 * (1.0 + 0.16 * k)
		if got:
			coin(self, f, c, r, String(l.letter), a)
			if k > 0.0:
				draw_arc(c, r + 3.0 + 4.0 * (1.0 - k), 0.0, TAU, 32, Color(1, 1, 1, 0.7 * k * a), 3.0, true)
		else:
			draw_circle(c + Vector2(0, 3), r, Color(0, 0, 0, 0.22 * a))
			draw_circle(c, r, Color(0.07, 0.075, 0.09, 0.72 * a))
			draw_arc(c, r, 0.0, TAU, 32, Color(1, 1, 1, 0.22 * a), 1.5, true)
			_letter(f, c, r, String(l.letter), Color(1, 1, 1, 0.22 * a))
	if flying:
		var e := 1.0 - pow(1.0 - fly_t / FLY_S, 3.0)
		var dest := tile_rect(fly_i, n, vs).get_center()
		var c := fly_from.lerp(dest, e) + Vector2(0, -60.0 * sin(e * PI))
		coin(self, f, c, lerpf(TILE * 0.35, TILE * 0.5, e), String((letters[fly_i] as Dictionary).letter), a)


# A gold letter coin, the same as the ones lying on the walk
# (systems/tony_hawk.gd): a dark rim, the gold face, a glint, the letter.
static func coin(c: CanvasItem, f: Font, at: Vector2, r: float, ch: String, a := 1.0) -> void:
	c.draw_circle(at + Vector2(0, r * 0.15), r, Color(0, 0, 0, 0.28 * a))
	c.draw_circle(at, r, Color(0.62, 0.44, 0.08, a))
	c.draw_circle(at, r * 0.88, Color(GOLD.r, GOLD.g, GOLD.b, a))
	c.draw_circle(at + Vector2(-r * 0.32, -r * 0.36), r * 0.2, Color(1.0, 0.98, 0.72, a))
	var px := int(round(r * 1.3))
	var w := Kit.text_w(f, ch, px)
	c.draw_string(f, Vector2(at.x - w * 0.5, at.y + float(px) * 0.36), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px,
		Color(0.20, 0.12, 0.03, a))


func _letter(f: Font, at: Vector2, r: float, ch: String, col: Color) -> void:
	var px := int(round(r * 1.3))
	var w := Kit.text_w(f, ch, px)
	draw_string(f, Vector2(at.x - w * 0.5, at.y + float(px) * 0.36), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)
