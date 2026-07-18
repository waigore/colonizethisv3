---
name: refactor-analysis-agent
description: Autonomously selects one ColonizeThis target (`app/` or a single `packages/<name>/` Melos package), then runs strict refactoring-opportunity-github-issue analysis and files one GitHub issue with clear refactor scope (deduplication, abstraction, performance, test streamlining, encapsulation), maximizing maintainability/testability and documenting PR slices when the work exceeds one PR. Use when the user asks to run refactor analysis, scout tech debt without naming a package, or produce a package-scoped refactoring issue without choosing the target themselves.
---

# Refactor Analysis Agent (ColonizeThis)

## When this applies

Use when the user asks to run refactor analysis / tech-debt scouting and wants the agent to **pick the target** and file a **single, implementable GitHub issue**—without asking which package to scan.

## Required dependencies

Read and apply strictly — do not invent a lighter substitute:

- `.cursor/skills/refactoring-opportunity-github-issue/SKILL.md` — analysis method, `origin/dev` baseline sync, open-issue de-duplication, CI/enforcement plan, issue template, and `gh` filing.
- `.cursor/skills/implement-github-issue/SKILL.md` § **Scope triage (large or multi-part issues)** — slicing strategy when proposed work exceeds one reviewable PR (document slices in the issue; do not implement here).

Also follow `AGENTS.md`, `CONTRIBUTING.md`, and repository rules.

## Operating principles

1. **Agent picks the target.** Choose exactly one eligible target from `app/` or `packages/<name>/` with **no human confirmation**. Do not ask which package to scan unless the eligible set is empty or git/`gh` hard-blocks progress.
2. **One package, one issue.** File **one** GitHub issue for the chosen target. Do not multi-root sweep `tool/`, `ctdev/`, `widgetbook_host/`, or `pytool/` as the primary target (same exclusions as `refactoring-opportunity-github-issue`).
3. **Maximize coherent scope.** Prefer the largest refactor plan that still improves **overall code quality, maintainability, and testability** for that target—not the smallest cosmetic tidy. Coherence beats laundry lists: themes must share a clear architectural or structural outcome.
4. **Refactoring directions (use all that apply with evidence):**
   - **Deduplication** — collapse repeated logic/patterns into one owner
   - **Abstraction building** — extract reusable modules/APIs where duplication or layering gaps justify it
   - **Performance tuning** — hot paths, allocations, redundant scans (respect turn-resolution budget rules when relevant)
   - **Test streamlining** — shared fixtures, fewer brittle tests, better seams without losing coverage intent
   - **Better encapsulation** — narrower public surfaces, clearer module boundaries, less cross-layer leakage
5. **Clear scope in the issue.** The filed issue must make **in-scope / out-of-scope / slices** unambiguous for a different implementer.
6. **Slice when larger than one PR.** If the proposed work would likely exceed one reviewable PR (rule of thumb from `implement-github-issue`: ~**20+ files** or multiple independent verticals), keep **one issue** and apply the **slicing strategy**: ordered, isolatable slices with dependencies, each mapping to a subset of acceptance criteria. Do **not** split into multiple issues unless de-duplication against open issues requires narrowing/referencing existing work.
7. **Read-only until filing.** Same as `refactoring-opportunity-github-issue`: analyze and file; do not refactor code in this pass unless the user explicitly switches to implementation.

## Workflow

### 1) Enumerate eligible targets

From repo root, build the candidate set:

| Kind | Path |
|------|------|
| App | `app/` (Flutter app package) |
| Melos packages | each `packages/<name>/` that contains a `pubspec.yaml` |

Exclude non-package trees under `packages/` (e.g. generated/coverage scratch without `pubspec.yaml`). Do not include `tool/`, `ctdev/`, `widgetbook_host/`, or `pytool/` as candidates.

### 2) Select one target (no human intervention)

Score candidates quickly (read-only heuristics; record the winning rationale in the issue):

1. **De-duplication signal (strong):** Prefer targets **not** already covered by an open refactor / tech-debt / encapsulation issue for that path (use `gh issue list` / search as in `refactoring-opportunity-github-issue` §1c). Skip or demote targets whose highest-value themes are already open.
2. **Leverage:** Prefer larger or more central packages when signals are similar (`app`, `colonizethis_logic`, `colonizethis_ai`, turn/orders/economy, etc.), using quick size/hotspot cues (file counts, oversized files, repeated patterns, rule-boundary smells)—not a full second analysis.
3. **Opportunity density:** Prefer targets where a short scan shows clear hits in one or more of the five directions above.
4. **Tie-break:** Prefer the candidate with the oldest “last refactor-related issue activity” for that path; if still tied, prefer lexicographically first path (`app` before `packages/...`).

**Lock the choice** in chat in one line (target + one-sentence why), then proceed—do not wait for approval.

If the user **already named** `app` or a `packages/<name>` in the same request, use that target and skip selection scoring (still run the full analysis skill).

### 3) Run strict refactoring-opportunity-github-issue

Apply `.cursor/skills/refactoring-opportunity-github-issue/SKILL.md` end-to-end for the locked target:

- Sync/analyze against latest `origin/dev` (§1b)
- De-duplicate against open issues (§1c)
- Load governance rules + evidence-based analysis (§2–3)
- CI / enforcement plan (§4)
- Draft and file via `gh issue create --body-file` (§5)

**Overrides / additions relative to that skill:**

| Topic | This agent |
|-------|------------|
| Scope lock | Agent-chosen; do not ask which package |
| Issue focus | Maximize coherent package-level impact; still reject drive-by unrelated trees |
| Directions | Explicitly cover applicable items among the five directions; omit only when unsupported by evidence |
| Oversized work | Document **Implementation slices** (see below) instead of artificially shrinking the opportunity |

### 4) Shape the issue for clear scope and slices

When drafting the issue body, extend the `refactoring-opportunity-github-issue` template with:

```markdown
## Scope
- **Target:** `app` | `packages/<name>`
- **Selected because:** [agent selection rationale]
- **In scope:** [directories, modules, themes — be concrete]
- **Non-goals:** [explicit exclusions]
- **Refactoring directions:** [which of: deduplication | abstraction | performance | test streamlining | encapsulation]

## Implementation slices
<!-- Include when work may exceed one PR; otherwise state "Single PR — no slices." -->
- [ ] **Slice A** — … *(depends on: —; approx. files/areas; ACs covered)*
- [ ] **Slice B** — … *(depends on: A; …)*
```

Slice rules (from `implement-github-issue` scope triage):

- Prefer boundaries already natural in the codebase (module, layer, feature folder).
- Each slice should be an **isolatable vertical** with testable acceptance criteria.
- Order slices by dependency; note that implementers keep **at most one open PR per issue**, stacking slice commits on that PR (or a follow-up PR only after an early merge).

Suggested labels in chat (do not require unless user asked): e.g. `backlog:review` or maintenance/refactor labels used by the repo.

### 5) Output in chat

Report:

- **Target selected** and one-line rationale
- **Issue** number / title / URL (or full draft if `gh` failed)
- **Directions** covered
- Whether the issue is **single-PR** or **sliced** (slice count)
- Any targets skipped due to open-issue overlap

## Guardrails

- Never ask the user to pick among `app` / `packages/*` when selection can proceed.
- Never file an issue without a locked single target and explicit in-scope / non-goals.
- Never implement refactors in this skill’s pass.
- Never expand the primary target beyond one of `app` or a single `packages/<name>`.
- If `gh` or git sync fails, follow the child skill’s stop/fallback behavior; preserve the full issue draft.

## Related

- Analysis + filing: `.cursor/skills/refactoring-opportunity-github-issue/SKILL.md`
- PR slicing semantics: `.cursor/skills/implement-github-issue/SKILL.md`
- Issue body/`gh` patterns: `.cursor/skills/create-github-issue/SKILL.md`
- OpenCode shim: `.opencode/skills/refactor-analysis-agent/SKILL.md`
