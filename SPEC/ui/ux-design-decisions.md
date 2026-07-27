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
| **Free capacity (reminders OK in principle)** | Capacity that can be put to work at **zero marginal cost**. Example: **Spies** are free to assign (idle or counter-spy / missions that do not charge treasury)—unused spy capacity is almost always pure waste of a free action, so end-turn or panel reminders that they remain unassigned are **aligned** with this principle. |
| **Costly capacity (do not nag by default)** | Capacity whose use spends or commits scarce resources, or otherwise trades off against other decrees. Example: **research seats / funding** cost gold each turn—empty seats or **None** funding may preserve treasury for builds, recruits, diplomacy, or market; do **not** treat that as a mistake at Next turn (**UXD-001**). |
| **Test before proposing a reminder** | Ask: “If the player uses this capacity right now, do they pay something they might prefer to keep?” **Yes** → no default end-turn warn unless a future decision explicitly overrides P1. **No** → reminder may be product-appropriate (still need clear copy, optional mute, and not auto-orders). |
| **Related** | **UXD-001** (research); idle-civilian warn on `DLG60001` (unit action without a work order—unit-time waste, not a gold spend to queue free work; costly work targets remain player-chosen after go-to). |

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
| **Rationale** | Specialization of **P1**. Research funding spends treasury; leaving seats empty or on **None** is a **valid strategic choice** when gold has more pressing uses. A recurring end-turn nag treats deliberate thrift as a mistake and dilutes the warning surface. Benefit is **questionable** relative to false-positive friction. Contrast: free capacity such as unassigned **spies** may still deserve a reminder under P1. Idle **civilians** on `DLG60001` remain a different product case (see next-turn confirmation SPEC). |
| **Non-goals** | End-turn research readiness section; go-to Technology from `DLG60001` for empty/unfunded seats; Settings toggle for “warn idle research”; treating empty research slots as shell “readiness friction” in UX suggestion heuristics. |
| **What remains allowed** | In-panel research UI on `GAME40001` (slots, funding toggles, turn preview, debt-block clarity); post-resolution research-complete news/feed; player-initiated review of Technology before Next turn without a forced prompt. |
| **Related** | **P1**; `SPEC/ui/next-turn-confirmation.md`; `SPEC/ui/technology-panel.md`; `docs/manual/09-pursuit-of-knowledge.md`; `docs/manual/14-passage-of-turns.md` |

---

## Acceptance criteria

- **Given** a candidate player-UX improvement is a pre-commit or idle-capacity reminder, **when** `suggest-player-ux-improvements` or an implementer evaluates it, **then** they apply **P1** (free → may remind; costly → do not nag by default) and any matching `UXD-*` rows.
- **Given** a candidate matches a `rejected` decision’s non-goals (same surface intent), **when** `suggest-player-ux-improvements` runs, **then** it must not recommend that improvement; it must skip it and pick another gap (or note the binding decision if the domain has no other gap).
- **Given** `UXD-001` is `rejected`, **when** `DLG60001` is implemented or specified, **then** it must not add empty/unfunded research warnings while this decision holds.
- **Given** a product owner reopens research end-turn readiness, **when** the decision is reversed, **then** this file records supersession with a new ID before implementation proceeds (and must reconcile with **P1**).
