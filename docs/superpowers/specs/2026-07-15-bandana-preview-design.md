# Bandana visibility and wardrobe preview

## Context

Bandana selection, ownership, persistence, and equipped-state labels already
work. The visual does not: `dog.gd` places the bandana triangle forward toward
Millie's head, then draws the collar, neck, and head over it. Most of the
triangle is hidden and the remaining color reads like part of the collar.

The wardrobe also has no dog preview, so browsing gives no visual feedback
beyond text until a walk starts.

## Goal

- Equipped bandanas read as classic triangular neckerchiefs from the top-down
  view.
- The triangle trails backward over Millie's shoulders instead of pointing
  into her head.
- Navy and other dark bandanas remain legible against black fur.
- The wardrobe shows a live preview of the highlighted item before purchase
  or equip.
- Highlighting `No bandana` removes the bandana from the preview.
- Gameplay and wardrobe use the same dog renderer.

## Non-goals

- Do not change cosmetic prices, ownership, purchase, equip, persistence, or
  save format.
- Do not add new cosmetic items, textures, external assets, or animation.
- Do not redesign the full title menu.
- Do not split dog rendering into a new component in this focused fix.

## Dog preview mode

Add these fields and methods to `dog.gd`:

```gdscript
var preview_mode := false
var preview_collar := ""
var preview_bandana := ""


func set_cosmetic_preview(collar_key: String, bandana_key: String) -> void:
	preview_collar = collar_key
	preview_bandana = bandana_key
	queue_redraw()


func _cosmetic_collar_key() -> String:
	if preview_mode and Game.COLLARS.has(preview_collar):
		return preview_collar
	return Game.collar if Game.COLLARS.has(Game.collar) else "red"


func _cosmetic_bandana_key() -> String:
	if preview_mode and Game.BANDANAS.has(preview_bandana):
		return preview_bandana
	return Game.bandana if Game.BANDANAS.has(Game.bandana) else "none"
```

`preview_mode` uses all normal initialized pose and drawing state but skips
creation of the gameplay `CollisionShape2D` in `_ready`. It never receives
`tick()` calls and therefore performs no input, movement, or gameplay logic.
Its existing `_process` redraw keeps the rainbow collar animated.

Preview flecks use a locally seeded `RandomNumberGenerator` so constructing
the always-present hidden preview consumes no global RNG and cannot change
later traffic, events, or other gameplay randomness. The gameplay dog keeps
its existing global-random fleck generation unchanged when
`preview_mode == false`.

## Bandana geometry

Add a pure geometry helper:

```gdscript
func _bandana_points(shoulder: Vector2, forward: Vector2) -> PackedVector2Array:
	var side := forward.orthogonal()
	var base := shoulder - forward
	return PackedVector2Array([
		base + side * 7.0,
		base - side * 7.0,
		shoulder - forward * 15.0,
	])
```

The wide base sits just behind the collar and the point extends toward the
hips. Draw the filled polygon after the body and before the collar, then draw
all three edges in `bandana_color.darkened(0.35)` at 1.5px. The collar covers
the top seam while the outlined triangle remains visibly separate over the
fur.

Resolve collar and bandana keys through the preview-aware methods. A `none`
bandana draws no polygon. Rainbow animation uses the resolved collar key.

## Wardrobe layout and behavior

Keep the wardrobe title centered. Convert the body into two fixed columns:

- Left: a translucent 440x390 preview panel from x=60, with a
  `HIGHLIGHTED LOOK` caption and the real `dog.gd` node centered around
  `(280, 365)` at 3x scale.
- Right: move the existing item label to x=430 with an 800x460 area.

Create the preview dog before adding it to the HUD tree:

```gdscript
var preview := CharacterBody2D.new()
preview.set_script(load("res://dog.gd"))
preview.preview_mode = true
preview.position = Vector2(280.0, 365.0)
preview.scale = Vector2(3.0, 3.0)
hud.add_child(preview)
shop_preview = preview
```

The preview panel, caption, and dog are visible only while `in_shop`.

Every `_refresh_shop()` starts with the currently equipped collar and bandana,
then replaces only the highlighted item's category:

- highlighted collar: preview that collar with the equipped bandana;
- highlighted bandana: preview that bandana with the equipped collar;
- highlighted `none`: preview no bandana;
- unowned items are still previewable.

Buying and equipping remain press-to-confirm and unchanged.

## Regression test

Add `tests/test_bandana_preview.gd` using the lightweight `SceneTree` pattern.
Instantiate the real `dog.gd` in preview mode and verify:

- preview collar and bandana overrides resolve;
- `none` resolves and clears the preview bandana;
- preview mode creates no collision child;
- preview construction leaves the global RNG stream unchanged;
- the triangle has a nonzero area and a wide base;
- its point lies behind the base relative to the forward vector.

The test exits nonzero on failure and prints
`test_bandana_preview: OK` on success. Add it as a direct CI step after the
NPC-pair direction regression.

## Manual acceptance

1. Open the wardrobe and browse every collar and bandana without purchasing.
2. Confirm the left preview updates immediately and the item list remains
   readable.
3. Confirm `No bandana` removes the preview neckerchief.
4. Equip navy, begin a walk, and confirm a distinct outlined triangle trails
   over Millie's back.
5. Return, equip `No bandana`, and confirm it is absent on the next walk.
6. Confirm collar colors, purchases, equipped tags, and saved ownership still
   behave as before.

## Compatibility

The change adds no save keys, dependencies, scenes, textures, input actions,
or export changes. It preserves the existing procedural placeholder-art
approach and uses the same renderer for gameplay and preview.
