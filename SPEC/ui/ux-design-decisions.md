# UX design decisions

**SPEC/ui** — Product and player-UX decisions that constrain what the game *should* surface, warn about, or leave to the sovereign’s judgment. These are not game-rule (GDD) changes; they document intentional UI product choices.

**Consumers:**

- Skill `suggest-player-ux-improvements` — **must** read this file every run and must **not** re-propose a `rejected` decision as a new improvement unless the user explicitly reopens that decision. Apply **Principles** when scoring new readiness / checklist ideas.
- Implementers and reviewers — treat `rejected` rows as non-goals for the named surfaces unless this file is updated first; use **Principles** when designing new end-turn or idle-capacity prompts.
- Player manual authors — keep player-facing prose consistent with accepted/rejected intent (especially end-turn readiness and research funding).

---

## How to maintain

| Field | Meaning |
|-------|---------|
| **ID** | Stable `UXD-NNN` (never reuse an ID for a different decision). |
| **Status** | `accepted` (do this / current product intent), `rejected` (do **not** build; do not re-suggest), `superseded` (replaced by another ID). |
| **Domains** | Skill domain ids (`turn-shell`, `research`, …) and/or screen IDs. |
| **Decision** | One-line product call. |
| **Rationale** | Why, in player terms. |
| **Non-goals** | What must not ship while this decision holds. |
| **Related** | SPEC/manual paths; open issue numbers if any. |

When adding a decision after a skill run or product discussion, append a new `UXD-NNN` section (do not silently rewrite history). To reverse a rejection, set status to `superseded` and add a new accepted decision that cites the old ID.

**Principles** (below) are standing product rules. Numbered `UXD-*` decisions apply or specialize them for a concrete surface. Prefer a new `UXD-NNN` when a principle is applied to a specific feature reject/accept.

---

## Principles

### P1 — Remind unused capacity only when using it is free

| Field | Value |
|-------|--------|
| **Status** | `accepted` (standing principle) |
| **Date** | 2026-07-27 |
| **Applies to** | Pre-commit readiness (`DLG60001`, shell checklists), idle-unit prompts, “you forgot to assign X” UX, and any skill heuristic that scores **idle / readiness friction** |
| **Principle** | It only makes sense to **remind** the player of **unused capacity** when putting that capacity to work has **no meaningful cost** (no treasury, materials, or other scarce spend required to use it this turn). If using the capacity has a cost or trade-off, leaving it unused can be **deliberate strategy**, and a recurring nag is false-positive friction. |
| **Free capacity (reminders OK in principle)** | Capacity that can be put to work at **zero marginal cost** (no treasury/materials spend) **and** without a meaningful strategic trade-off against other uses of that same unit. Example: an idle **Builder** with no work order wastes unit-time that could improve a tile at no assign-time gold cost. |
| **Costly capacity (do not nag by default)** | Capacity whose use spends or commits scarce resources, **or** whose use is a **portfolio trade-off** among mutually exclusive productive posts. Example: **research seats / funding** cost gold each turn (**UXD-001**). Example: **Spies** cost no gold to assign, but each body can only hold **one** post at a time (foreign intel vs rival research presence vs home counter-spy vs reserve)—see **UXD-002**. |
| **Test before proposing a reminder** | Ask: “If the player uses this capacity right now, do they pay something they might prefer to keep?” **Yes** → no default end-turn warn unless a future decision explicitly overrides P1. Also ask: “Is leaving it unused (or parked) a plausible deliberate strategy because reassignment trades off other benefits?” **Yes** → do not nag by default (**UXD-002** for Spies). **No** on both → reminder may be product-appropriate (still need clear copy, optional mute, and not auto-orders). |
| **Related** | **UXD-001** (research); **UXD-002** (Spy stationing / no idle-spy shell nag); idle-civilian warn on `DLG60001` (unit action without a work order for **work-order civilians**—not Spies as pure “unassigned capacity”). |

---

## Decisions

### UXD-001 — No end-turn warning for unused research capacity

| Field | Value |
|-------|--------|
| **Status** | `rejected` |
| **Date** | 2026-07-27 |
| **Domains** | `turn-shell`, `research` |
| **Surfaces** | `DLG60001` Next turn confirmation; `DLG90001` Settings; any pre-commit readiness checklist on `GAME10001` |
| **Decision** | Do **not** warn, list, or block the player at **Next turn** when research seats are empty or funding is **None**. |
| **Rationale** | Specialization of **P1**. Research funding spends treasury; leaving seats empty or on **None** is a **valid strategic choice** when gold has more pressing uses. A recurring end-turn nag treats deliberate thrift as a mistake and dilutes the warning surface. Benefit is **questionable** relative to false-positive friction. Idle **work-order civilians** on `DLG60001` remain a different product case (see next-turn confirmation SPEC). **Spies** are **not** a parallel free-capacity nag case—stationing is a strategic portfolio (**UXD-002**). |
| **Non-goals** | End-turn research readiness section; go-to Technology from `DLG60001` for empty/unfunded seats; Settings toggle for “warn idle research”; treating empty research slots as shell “readiness friction” in UX suggestion heuristics. |
| **What remains allowed** | In-panel research UI on `GAME40001` (slots, funding toggles, turn preview, debt-block clarity); post-resolution research-complete news/feed; player-initiated review of Technology before Next turn without a forced prompt. |
| **Related** | **P1**; `SPEC/ui/next-turn-confirmation.md`; `SPEC/ui/technology-panel.md`; `docs/manual/09-pursuit-of-knowledge.md`; `docs/manual/14-passage-of-turns.md` |

---

### UXD-002 — Spy stationing is strategic; no end-turn “idle spy” nag; relocate must surface leave cost

| Field | Value |
|-------|--------|
| **Status** | `accepted` |
| **Date** | 2026-07-31 |
| **Domains** | `civilian-work`, `turn-shell` (readiness only as non-goal) |
| **Surfaces** | `UNIT10001` Civilian units panel; map/work-target (or relocate) selection; optional province shortcuts; **not** `DLG60001` spy readiness lists |
| **Decision** | Treat **Spy placement** as a **strategic portfolio**, not as unused free capacity. Product UX must (1) let the player **relocate/station** Spies where rules allow (civilian `MoveOrder` path), (2) show **what post a Spy currently holds** in plain language, (3) when relocating would leave a foreign province with **no remaining own Spy**, warn that **full intel on that province will fog after end-of-turn** (current product: **immediate EoT decay, no grace timer** per spy overhaul / `civilian-units` + turn end-of-turn), and (4) **not** add end-turn / shell warnings that treat idle or unassigned Spies as mistakes. |
| **Rationale** | GDD: a Spy in a **non-owner** province grants **full visibility** (including garrison intel Explorers do not give); when the **last** own Spy leaves that province, visibility **reverts to fogged at end-of-turn**. Passive research boost needs presence in a **rival GP**. **Counter-spy** is a separate free work order on **owned** land (empire defense). Spies are scarce; each body can hold only one of these posts at a time. Idle at capital can be deliberate **reserve** for next redeploy. Relocating is not “fill free capacity”—it is **choosing which intel/RP/defense post to keep**. Shell nags that imply every Spy must be “busy” create false-positive friction (same class of error as **UXD-001**, even though treasury cost is zero). |
| **Non-goals** | End-turn / `DLG60001` lists or blocks for “idle Spy” / “no work order” / “unassigned spy capacity”; Settings toggle for spy readiness; auto-stationing or auto counter-spy; inventing new spy mission types; changing fog/RP/kill GDD formulas in the name of UX; treating foreign idle presence as a defect. |
| **What remains allowed / required for ship** | Human **Relocate / Station** (or equivalent) that stages a validated civilian `MoveOrder` for Spies; status copy for foreign hold / counter-spy / home reserve; **leave-intel** consequence on relocate when last Spy vacates a foreign province; existing **Assign → counter-spy** on owned provinces; in-panel clarity only (no forced Next-turn spy checklist). |
| **Skill / heuristic note** | `suggest-player-ux-improvements` must **not** score “end-turn unassigned spy reminder” as P1-aligned free-capacity work while this decision holds. Prefer relocate + hold/leave decision support. Idle-civilian end-turn warn remains for **work-order** civilians; do not extend it to Spy portfolio nags. |
| **Related** | **P1** (trade-off test); **UXD-001** (parallel: do not nag strategic non-use); `SPEC/game/civilian-units.md` § Spy; `SPEC/game/fog-and-exploration.md` / `SPEC/program/fog-and-exploration-resolution.md` / end-of-turn spy fog decay; `SPEC/game/research-state.md` (spy RP boost); `SPEC/program/orders.md` (`MoveOrder`, `counter_spy`); `SPEC/ui/civilian-units-panel.md`; `SPEC/ui/next-turn-confirmation.md` (research non-goals; spy shell reminder deferred—superseded as non-goal by this decision); `docs/manual/09-pursuit-of-knowledge.md`; `docs/manual/16-appendix-actions.md` (civilian Move entry gap) |

---

## Acceptance criteria

- **Given** a candidate player-UX improvement is a pre-commit or idle-capacity reminder, **when** `suggest-player-ux-improvements` or an implementer evaluates it, **then** they apply **P1** (free → may remind **only if** no meaningful spend **and** no meaningful strategic trade-off; costly or portfolio trade-off → do not nag by default) and any matching `UXD-*` rows.
- **Given** a candidate matches a `rejected` decision’s non-goals (same surface intent), **when** `suggest-player-ux-improvements` runs, **then** it must not recommend that improvement; it must skip it and pick another gap (or note the binding decision if the domain has no other gap).
- **Given** `UXD-001` is `rejected`, **when** `DLG60001` is implemented or specified, **then** it must not add empty/unfunded research warnings while this decision holds.
- **Given** `UXD-002` is `accepted`, **when** end-turn readiness or idle-capacity UX is designed, **then** it must not add Spy “idle / unassigned” shell warnings; Spy UX must treat stationing as strategic (hold/leave intel) and may add relocate + leave-fog decision support.
- **Given** a product owner reopens research end-turn readiness, **when** the decision is reversed, **then** this file records supersession with a new ID before implementation proceeds (and must reconcile with **P1**).
- **Given** a product owner reopens Spy end-turn readiness, **when** the decision is reversed, **then** this file records supersession of **UXD-002** (or a new ID that supersedes it) before shell spy nags ship.
