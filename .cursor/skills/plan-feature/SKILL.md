---
name: plan-feature
description: Plans a user-provided feature idea by reading SPEC and code (read-only), analyzing scope, proposing a design aligned with existing architecture, optionally clarifying underspecified requirements with focused questions, and opening a GitHub issue that documents requirements, assumptions, design, subtasks with dependencies, and acceptance criteria—without modifying the repository. Use when the user wants a feature scoped and filed as an issue before any implementation, spec edits, or PR work.
---

# Plan a feature and open a capturing GitHub issue (read-only)

## Scope (strict)

- **Do not** change the repository: no new/edited specs, code, tests, config, or tooling.
- **Do** read SPEC and implementation to ground the plan; **do** ask focused clarification questions when requirements are underspecified, ambiguous, or contradictory.
- **Do** attempt to **create one GitHub issue** with the full plan. If creation fails, output title and body for manual filing (same pattern as sibling skills).

If the user asks to implement the feature or update specs, stop following this skill and use normal workflow (**AGENTS.md**, **CONTRIBUTING.md**, SPEC-first rules).

## Architectural alignment (ColonizeThis)

When proposing design:

- **Reuse first:** Prefer extending existing modules, services, Flame components, and UI patterns over parallel structures or duplicated logic.
- **Authoritative docs:** Game/AI behavior → `SPEC/game/` (GDD); architecture → `SPEC/program/` (TDD); derive UI/AI sub-specs from those. Cite **file paths and sections** in the issue where they support or constrain the feature.
- **Stack boundaries:** Keep Flutter UI and Flame simulation concerns separated; cross-panel UI via **AppEventBus** (not ad hoc `Ref`/callback chains across panels)—see `.cursor/rules/` and `SPEC/program/app-ui-wiring.md`.
- **World model:** Province identity uses **(regionId, provinceId)** or prefixed ids—never a bare province id alone when relevant.
- **New abstractions:** If nothing fits, **suggest** a minimal new abstraction in the issue (name, responsibility, where it would live, what it replaces or sits beside) and flag **SPEC impact** (none / clarification / new section required before implementation).

## When this applies

The user provides a **feature idea** plus **initial requirements** and wants:

- Context from **specs and code** without edits
- A **broken-down plan** (subtasks, dependencies for non-trivial work)
- **Clear gaps** resolved via short Q&A in chat when needed
- A **single GitHub issue** as the handoff artifact (not implementation)

## Workflow

### 1. Capture the ask

From the user message(s), extract explicitly:

| Field | Notes |
|--------|--------|
| **Problem / outcome** | What success looks like for the user or player |
| **Constraints** | Performance, platforms, compatibility, deadlines, “must not” items |
| **Inputs** | Who triggers it, data sources, rulesets, save format, etc. |
| **Open questions** | Mark unknowns rather than guessing |

### 2. Clarify before deep research (if needed)

Ask **only** questions that unblock correct planning. For each question:

- **Why it matters** (one line)
- **Options or tradeoffs** when useful (e.g. “A: … implies …; B: … implies …”)

Skip speculation; do not invent product decisions. If requirements contradict each other, quote the contradiction and ask which path to document as primary.

### 3. Investigate (read-only)

- **Specs:** Map the feature to GDD/TDD (and `SPEC/ui/`, `SPEC/ai/` if applicable). Note gaps: missing spec, ambiguous behavior, or conflict with existing rules.
- **Code:** Find current owners of related behavior (services, components, packages). List **concrete paths** and key types/functions—enough for an implementer to start.
- **Tests:** Mention existing coverage that should extend vs new test areas (no new tests in this phase).

Use search/read tools; avoid mutating the working tree.

### 4. Analyze and design (issue content, not repo changes)

Produce sections for the issue:

- **Requirements:** Numbered, testable where possible; separate **must-have** vs **nice-to-have** if the user hinted prioritization.
- **Assumptions:** Explicit guesses the user confirmed or that remain to validate during implementation; label unconfirmed assumptions.
- **Non-goals:** What this feature intentionally does not do (prevents scope creep).
- **Design proposal:** How to implement **within existing patterns**—reuse points, new types/modules only if justified, data flow, UI entry points, events, save/load or ruleset touchpoints if relevant.
- **SPEC impact:** `none` / `clarification only` / `GDD` / `TDD` / `UI` / `AI` (list paths)—per project SPEC-first policy; no edits in this task.
- **Subtasks:** For complex work, a **dependency-aware** breakdown:
  - Order orDAG style: e.g. `1 → 2`, `1 → 3`, `2+3 → 4`
  - Each subtask: short title, one-line objective, **depends on:** ids
- **Risks / edge cases:** Technical and design risks.
- **Open follow-ups:** Only items still unclear **after** user clarification, if any.

### 5. Acceptance criteria

Write **Given / When / Then** (or checklists) that an implementer can verify without guessing. Tie criteria to requirements and to cited SPEC where applicable. Reference **CONTRIBUTING** / project testing expectations only at a high level (no new tests written here).

### 6. Build title and body

**Title:** Imperative, scoped (e.g. “Add …”, “Support …”); ≤ ~80 characters.

**Body** template:

```markdown
## Summary
[One or two sentences: outcome and scope]

## Requirements
1. ...
2. ...

## Assumptions
- ...

## Non-goals
- ...

## Spec and code context
- SPEC: [paths/sections and brief notes]
- Code: [paths, main types/hooks]
- Tests: [what exists / likely extensions]

## Design proposal
[Reuse, new abstractions, flow, integration points]

## Subtasks and dependencies
- [ ] **S1** — ... *(depends on: —)*
- [ ] **S2** — ... *(depends on: S1)*
...

## SPEC impact (planning only — no edits in this issue’s workflow)
- ...

## Risks and edge cases
- ...

## Acceptance criteria
- [ ] Given ..., when ..., then ...
```

Adjust sections if the feature is small (minimal subtasks; still keep acceptance criteria).

### 7. Create the issue (primary path)

From the **repository root**:

1. Write the body to a **temporary file** (e.g. under `/tmp`) to preserve markdown.
2. Run: `gh issue create --title "<title>" --body-file "<path>"`
3. On **success:** return the **issue URL** (and number) in chat.
4. On **failure:** explain briefly, suggest `gh auth login` / permissions if relevant, and paste the **full title and body** for manual creation.

Add labels only if the user requested or labels are obvious; otherwise suggest labels in chat.

### 8. Fallback

Same as sibling skill: always preserve the full draft if `gh` cannot create the issue.

## Quality bar

- **Facts vs inference:** Label hypotheses; do not present guesses as spec truth.
- **No duplication:** Call out existing APIs/components to **extend** before proposing new layers.
- **Focused clarification:** Few high-leverage questions; implications spelled out.
- **Issue is implementable:** Another developer could start from the issue without repeating full discovery.

## Related

- **Bug / gap reports → structured issue (read-only):** [.cursor/skills/create-github-issue/SKILL.md](../create-github-issue/SKILL.md)
- **Verify issues:** [.cursor/skills/verify-github-issue/SKILL.md](../verify-github-issue/SKILL.md)
- **After the issue exists:** implementation follows **AGENTS.md**, **CONTRIBUTING.md**, and `.cursor/rules/` (SPEC-first, testing, UI wiring).
