# La Ciutadella Arc and palms Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make La Ciutadella's promenade palms and Arc de Triomf crown read as finished top-down art.

**Architecture:** Edit only `systems/ciutadella.gd`. Palms call `main._palm_crown` through the walk's `m` node inside the existing edge batch. The Arc crown is polygons in the existing overhead batch.

**Tech Stack:** Godot 4.7 GDScript, `ShapeBatch`, existing palm helpers on `main.gd`.

---

### Task 1: Promenade palms

**Files:**
- Modify: `systems/ciutadella.gd` (palm loop in `draw_edge_layer`, ~642-658)

**Step 1:** Replace the seven stick fronds and small trunk disc with a larger shadow disc and `m._palm_crown(b, pp)`. Keep the kerb and soil pit.

**Step 2:** Commit.

### Task 2: Arc crown

**Files:**
- Modify: `systems/ciutadella.gd` (`draw_overhead`, ~1122-1143)

**Step 1:** Keep brick span and stone frieze. Replace the two discs and wing lines with a pointed gold shield, Sant Jordi's cross, four bars, and a bat with tapered wings.

**Step 2:** Commit.

### Task 3: Verify and changelog

**Files:**
- Create: `changelog.d/2026-11-27-ciutadella-arc-palms.md`

**Step 1:** Run `tests/test_ciutadella.gd` (and any walk-hook regression that picks this walk).

**Step 2:** Shot the Arc and the promenade; confirm by eye.

**Step 3:** Add the changelog fragment; open the PR with a feel card.
