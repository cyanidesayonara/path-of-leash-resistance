# Sixteen-walk polish audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a ranked audit of all sixteen campaign walks, then fix each blocking or clearly rough finding in its own pull request.

**Architecture:** One audit document records inventory, screenshots, scripted play, severity and disposition. The audit changes no gameplay. Each later fix is a separate branch from `origin/main`, with the narrowest regression that fails before the fix.

**Tech Stack:** Godot 4.7, `tools/level_inventory.gd`, `tools/shot_sweep.sh`, `tools/playtest.gd`.

**Spec:** `docs/superpowers/specs/2026-10-19-walk-polish-audit-design.md`

## Global Constraints

- Campaign order is exactly `barri street park beach rain market oldtown trail station site spook scrap guell neteja montjuic partit`.
- Severities are only `blocking`, `clearly rough`, and `subjective`.
- Fix blocking and clearly rough findings. Record subjective findings without changing the game.
- A clean walk gets an explicit no-finding entry.
- No new walk, system, broad retune, store work, or controller/phone verification in this plan.
- The audit document is tooling. Each player-facing fix is its own pull request with a feel card.
- Behaviour-preserving work keeps `tools/behaviour_snapshot.sh` byte-identical.
- Commits are authored only by Santtu Nykänen, with no `Co-authored-by` trailer. Use `git commit-tree` with `core.hooksPath=NUL` when a hook injects one.
- Godot in this worktree is `C:\Users\SanttuNykänen\projects\path-of-leash-resistance\godot\Godot_v4.7-stable_win64.exe`. The console binary is the same name with `_console`. Run `--import --quit` once before the first script. Never run two Godot processes in this worktree at once.
- Do not commit `.godot/`, generated `.import` line-ending noise, screenshots, or playtest logs.

## File map

| File | Responsibility |
|---|---|
| `docs/WALK_POLISH_AUDIT.md` | The only audit record: one section per walk, then the ranked queue |
| later fix branches | One defect each; not created until a finding names them |

---

### Task 1: Create the audit record

**Files:**
- Create: `docs/WALK_POLISH_AUDIT.md`

**Interfaces:**
- Consumes: the sixteen ids in Global Constraints
- Produces: headings `## barri` through `## partit`, each with `Inventory`, `Shots`, `Play`, and `Findings`

- [ ] **Step 1: Write the record**

Use this document, with the same four subsections under every id. The body of each field starts as `pending`.

```markdown
# Walk polish audit

Target: v1.62. Evidence for the sixteen campaign walks. A finding is
blocking, clearly rough, or subjective. Subjective findings stay recorded
and unchanged until Santtu plays them.

## barri

- Inventory: pending
- Shots: pending
- Play: pending
- Findings: pending
```

Repeat that section for `street`, `park`, `beach`, `rain`, `market`, `oldtown`, `trail`, `station`, `site`, `spook`, `scrap`, `guell`, `neteja`, `montjuic`, and `partit`. End with:

```markdown
## Queue

No finding is ranked until every walk above has been looked at.
```

- [ ] **Step 2: Commit**

```powershell
git add docs/WALK_POLISH_AUDIT.md
git commit -m "Start the sixteen-walk polish audit"
```

### Task 2: Record the level inventory

**Files:**
- Modify: `docs/WALK_POLISH_AUDIT.md`

**Interfaces:**
- Consumes: `tools/level_inventory.gd` output, one `== id (Name)` block per walk
- Produces: each walk's `Inventory` line replaced with width, shape, gate, off-leash kind, prop counts, patches and goals

- [ ] **Step 1: Run the inventory**

```powershell
& "C:\Users\SanttuNykänen\projects\path-of-leash-resistance\godot\Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://tools/level_inventory.gd
```

Expected: seventeen blocks, the sixteen campaign ids plus `tutorial`. Exit 0 and no `SCRIPT ERROR`.

- [ ] **Step 2: Fill Inventory**

Replace each `Inventory: pending` with one sentence taken from that walk's block. Leave `tutorial` out of the audit. Do not infer a defect from a count.

- [ ] **Step 3: Commit**

```powershell
git add docs/WALK_POLISH_AUDIT.md
git commit -m "Record the walk inventory in the polish audit"
```

### Task 3: Photograph every walk

**Files:**
- Modify: `docs/WALK_POLISH_AUDIT.md`
- Evidence, untracked: `C:\tmp\walk-audit-shots`

**Interfaces:**
- Consumes: `tools/shot_sweep.sh`
- Produces: `walk-<id>.png` for every id, plus the menu and phone shots the sweep already takes

- [ ] **Step 1: Run the sweep**

```powershell
$env:GODOT="C:\Users\SanttuNykänen\projects\path-of-leash-resistance\godot\Godot_v4.7-stable_win64_console.exe"
$env:PYTHON="python"
bash tools/shot_sweep.sh C:/tmp/walk-audit-shots
```

Expected: `SWEEP OK` and a non-empty `walk-<id>.png` for all sixteen ids. A missing PNG or `SCRIPT ERROR` in its log is itself a blocking finding for that walk.

- [ ] **Step 2: Photograph the yard and the way home**

The sweep frames the opening. For each id, also shoot the off-leash yard and the corridor on the way home. `GATE_Y` is -5000, so the yard shot is `--shot-y=-5600` and the home shot is `--shot-y=-2500 --shot-home`.

```powershell
$G = "C:\Users\SanttuNykänen\projects\path-of-leash-resistance\godot\Godot_v4.7-stable_win64_console.exe"
foreach ($lv in @("barri","street","park","beach","rain","market","oldtown","trail","station","site","spook","scrap","guell","neteja","montjuic","partit")) {
  & $G --path . --rendering-method gl_compatibility --quit-after 340 -- --shot --shot-quit --level=$lv --shot-y=-5600 --shot-out="C:/tmp/walk-audit-shots/yard-$lv.png"
  & $G --path . --rendering-method gl_compatibility --quit-after 340 -- --shot --shot-quit --level=$lv --shot-y=-2500 --shot-home --shot-out="C:/tmp/walk-audit-shots/home-$lv.png"
}
```

Expected: 32 more non-empty PNGs. These Godot calls stay serial.

- [ ] **Step 3: Review each walk image**

Open `walk-<id>.png`, `yard-<id>.png`, `home-<id>.png`, and `sheet-*.png`. Record only what is visible: overlap, a sign through scenery, a prop off the path, an illegible heading, or a broken silhouette. Put the shot paths in `Shots`. A walk with none of these gets `Findings: no finding` only after Task 4 also finds nothing.

- [ ] **Step 4: Commit the notes**

```powershell
git add docs/WALK_POLISH_AUDIT.md
git commit -m "Record the walk-shot review"
```

### Task 4: Play each walk out and home

**Files:**
- Modify: `docs/WALK_POLISH_AUDIT.md`
- Evidence, untracked: `C:\tmp\walk-audit\<id>`

**Interfaces:**
- Consumes: `tools/playtest.gd`
- Produces: one log per walk. `DOG STUCK`, `HUMAN STUCK`, and `NPC IN SOLID` are candidate findings. The closing `PLAYTEST done` line is the evidence summary.

- [ ] **Step 1: Play one walk**

Dog speed is 330. The gate is `y = -5000` and home is `y = 320`, so one turbo pass in each direction covers the corridor. Repeat with every campaign id:

```powershell
& "C:\Users\SanttuNykänen\projects\path-of-leash-resistance\godot\Godot_v4.7-stable_win64.exe" --path . --rendering-method gl_compatibility --script res://tools/playtest.gd -- --level=barri --steps="turbo+up:25;shot;turbo+up:25;shot;turbo+up:25;shot;down:8;shot;turbo+down:25;shot;turbo+down:25;shot;turbo+down:20;shot" --out=C:/tmp/walk-audit/barri
```

Expected: the log ends with `PLAYTEST done`. Reaching freedom prints phase `freedom` or `home` in that line. A run that never gets the dog above `y = -4500` is incomplete and must be rerun with another `turbo+up:25`, not marked clean.

- [ ] **Step 2: Record Play and Findings**

For each reported stuck or solid intersection, copy the log line, the screenshot number, and the positions. Severity is blocking when the pair cannot continue, or when an NPC is inside a solid. Severity is clearly rough when the pair slips past but the contact is visibly wrong. Do not treat a player-held wall press as stuck: the tool already excludes it.

- [ ] **Step 3: Commit**

```powershell
git add docs/WALK_POLISH_AUDIT.md
git commit -m "Record the scripted play of every walk"
```

### Task 5: Rank the queue

**Files:**
- Modify: `docs/WALK_POLISH_AUDIT.md`

**Interfaces:**
- Consumes: every walk section completed by Tasks 2-4
- Produces: `## Queue`, blocking findings first, then clearly rough, then subjective

- [ ] **Step 1: Write the queue**

Each row names the walk, severity, one-sentence symptom, and disposition `open`. A walk with no defect stays in its section as `Findings: no finding` and does not appear in the queue.

- [ ] **Step 2: Commit and open the audit PR**

```powershell
git push -u origin HEAD
gh pr create --title "Audit all sixteen walks for v1.62" --body-file PR_BODY.md
```

The pull request body states that this changes nothing a player sees, lists how many walks were clean, and names the first open finding.

### Task 6: Fix the first open finding

**Files:**
- Determined by the first `open` row in `## Queue`
- Test: the narrowest existing test file, or a new `tests/test_<finding>.gd` plus its `.uid` and a step in `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: that row's reproduce command
- Produces: the defect gone, the audit disposition changed to the fixing PR number

- [ ] **Step 1: Write the failing check**

Reproduce the recorded command and assert the broken observation. Run it and confirm it fails for that observation.

- [ ] **Step 2: Make the smallest change that removes it**

Stay inside the walk or system the finding names. Do not retune a neighbouring walk.

- [ ] **Step 3: Prove it**

The new check passes. Run the playtest command from the finding and confirm the log line is gone. Update the audit disposition to the PR. Commit, push, and open that fix as its own pull request with a feel card. Repeat Task 6 for the next open row only after this pull request is up.
