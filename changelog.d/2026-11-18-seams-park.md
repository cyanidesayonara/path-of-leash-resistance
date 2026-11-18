## 2026-11-18 - Blend El Parc's seams

- El Parc's off-leash threshold (`Parc.draw_threshold` and `Parc.draw_edge_layer`) now drops the hidden edge-layer undergrowth that poked above the fence, continues the mown lawn up to the chain-link line, returns the fence corners cleanly to the timber gateposts, and carries a continuous worn gravel tongue through a matching granite kerb into Pipicà.
- Path edging and the low iron hoop fence (`Parc.draw_path_edges`) now offset along true segment normals with mitered corners and world-locked posts, stop neatly at the gateposts and the south sidewalk kerb, and meet a stone footway apron along the apartment frontage with `Parc.grass_blocked` and `Parc.surface` updated to match.
- Mown grass stripes (`Parc._mown_stripes`) now follow the lake bends flush to the edging instead of leaving stair-stepped gaps, and the worn center track (`Parc.draw_over_walkway`) feathers smoothly at both ends.
- The lake shore (`Parc._lake_shore`) now samples `main.pond_outline()` wobble so reeds, lily pads, ducks, and the south timber jetty anchor to the actual shoreline, feathered into the gravel with a soft silt band and pebbles.
- Roadside flower borders (`Parc._borders`) now sit inside rounded clipped-box edging clear of the hoop fence, the kiosk bike rack sits clear of the bike lane kerb, and the east bike lane ends in a rounded turnaround cap.
