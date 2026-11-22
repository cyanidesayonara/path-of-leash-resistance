## 2026-11-22 - Cross-walk world draw perf

- Stopped world/sign_layer.gd from reallocating a sign's SubViewport on small rolling-piece bounds growth (ALLOC_STEP = 128 bucketed sizing with draw_texture_rect_region) and from repainting unchanged non-live signs in view.
- Added batched ShapeBatch.ellipse() and ShapeBatch.arc() so contact_shadow, cast_shadow, _broadleaf_ground, _draw_pilona, cafe tables, terrace chairs and manholes stay inside the single world ShapeBatch without draw_set_transform or draw_arc batch breaks.
- Turned circle LOD on for the world pass (_wc.lod = true), ground_layer.gd, _draw_section, _draw_ground and helper batches (keying cached sections by want_lod so lod = false tests keep full 64-segment parity), Y-culled parasols, terrace chairs and fountains in _draw_furniture, and cached _draw_ground_detail via _draw_section.
