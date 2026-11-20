# Tarragona Walk Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship walk `tarragona` (Roman city at dusk) with casteller soft-crowd event, gladiator dare-giver, tesserae sign, tests, and a Feel-card PR.

**Architecture:** One walk module `systems/tarragona.gd` with `HOOKS`, state on main, soft crawl via `human.walk_pace`. Wiring mirrors Sitges/Ronda.

**Tech Stack:** Godot 4.7 GDScript, ShapeBatch, Panot, Outdoors, Challenger cast, procedural music/SFX.

## Global Constraints

- GDScript only; vectors via ShapeBatch; panot on town paving; no emoji; "leash" / "your human"; Catalan place names
- Commits: Santtu Nykänen only; no Co-authored-by; no "claude" in messages; commit `.gd.uid`
- Changelog fragment in `changelog.d/`; never edit CHANGELOG.md top; Feel card on PR
- Tests in `tests/ci.d/tarragona.txt`; do not edit store/itch/README/site
- Editor: `C:\Users\SanttuNykänen\projects\path-of-leash-resistance\godot\...`; `--import` once before tests

---

### Task 1: Walk module + human crawl pace

- [ ] Add `walk_pace` on `entities/human.gd` (clamp 0.1–1.0 into walk speed)
- [ ] Create `systems/tarragona.gd` (+ `.uid` after import): edges, surfaces, solids, build, casteller tick, Balcó view, draws, HOOKS
- [ ] Commit

### Task 2: Campaign wiring

- [ ] Wire `game.gd`, `main.gd`, `level_build.gd`, `goals.gd`, `outdoors.gd`, `music.gd`, `challenger.gd`, `challenger_cast.gd`, `world_sign.gd`, i18n strings, shot/surface/behaviour lists, `test_npc_clear_of_solids.gd` if needed
- [ ] Commit

### Task 3: Tests + changelog

- [ ] `tests/test_tarragona.gd` + `tests/ci.d/tarragona.txt` + changelog fragment
- [ ] Run import, `run_tests.sh tarragona`, full suite, smoke, playtest, shots
- [ ] Commit; open PR with Feel card; do not merge
