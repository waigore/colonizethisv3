# Logging — AI actions

**SPEC/program/logging** — Annex to [logging.md](logging.md). Applies to **colonizethis_ai** and **logic** helpers that implement AI-facing suggestion or heuristic paths.

---

## Info (decisions and outcomes)

- **Strategic entry:** **Info** when order generation starts: `nationId` (or `playerId`), `turn`.
- **Goals:** **Info** when a **primary goal** (or equivalent) is **selected**, with goal id/name and any **major** constraint that changed the choice.
- **Planners (build/move/naval/diplomacy/economy):** **Info** when a **concrete action** is **chosen** (unit type, target province where allowed, diplomacy action class, cargo preference summary). Include **turn** and **nationId**.
- **Economy plan:** **Info** summary: `cargoPreference`, assignment **count**, `playerId`/`nationId` (per [economy-planner.md](../../ai/economy-planner.md) intent).
- **Full AI civilian work (Refs #2082):** **Info** only; prefix `ai:` (package logger). One line per emitted civilian `WorkOrder`: tag **`civilian_work_assigned`** with `nationId`, `unitId`, `unitType`, `target`, `targetTileKey`. One line per idle civilian land unit that received **no** new work this pass: tag **`civilian_work_idle`** with `nationId`, `unitId`, `unitType`, `reason` (e.g. `no_suggestions` when `W(u)` / Explorer `C(e)` had no selectable row). Do **not** replace per-unit lines with a single summary line.

---

## Debug (options considered)

- **Candidates:** **Debug** lines listing **alternatives** with **scores** / weights / thresholds that explain ranking. If the list is long, log **top N** plus `totalCandidates=` **or** aggregate statistics (min/max/mean score).
- **Perception / dossier:** **Debug** only; **truncate** large snapshots (max characters or field allowlist documented in code comments referencing this spec).
- **Skipped work:** **Debug** when a planner exits early (e.g. weight below threshold), with the **numeric** reason.

---

## Volume

- Never log **full** `PlayerView` or game state at info. **Info** = decisions + compact summaries; **debug** = structured but bounded per [logging.md](logging.md).

---

## Acceptance criteria

- **Given** a full AI order pass for a nation, **when** generation completes, **then** there is at least one **info** line recording the **chosen** high-level outcome (goal and/or representative orders) with `turn` and nation/player id.
- **Given** a planner that scores multiple candidates, **when** it selects a non-empty action, **then** **debug** logs include either **per-candidate** scores for the top N or an explicit **summary** that lists runner-up scores.
- **Given** Full AI civilian work runs for a nation with **K** emitted civilian `WorkOrder`s and **N** idle work-capable civilians without new work, **when** logging at **info**, **then** the system emits exactly **K** `civilian_work_assigned` lines and **N** `civilian_work_idle` lines for that pass (Refs #2082, § Info above).
