---
name: create-github-issue
description: |-
  Turns an informal issue report into a structured GitHub issue with reproduction steps, expected vs actual behavior, read-only SPEC/code investigation, and a proposed fix scope—without modifying the repository.

  Always clarify requirements with the user first by reading relevant specs/code, analyzing the report against current behavior, and presenting requirement clarifications as a numbered list.

  Attempts to open the issue via GitHub CLI (gh); falls back to a paste-ready draft if gh is missing, unauthenticated, or creation fails.

  Use when the user describes a bug, regression, or gap and wants a filed issue, triage narrative, or fix direction before implementation.
---

# Create a GitHub issue from a user report (read-only)

## Scope (strict)

- **Do not** edit, create, or delete files in the repo: no code, specs, config, tests, or tooling changes.
- **Do** always clarify requirements in chat before drafting or filing the issue: **read** relevant specs/code, analyze against the user's stated problem/request, then present requirement clarifications in a **numbered list** and resolve unknowns with the user. After clarification, **try to create the issue on GitHub** (see below). If creation fails, **output** the full title and body so the user can file it manually.

If the user asks to implement the fix, stop following this skill and switch to normal implementation workflow (e.g. AGENTS.md, CONTRIBUTING.md).

## When this applies

The user provides a **narrative report** (bug, wrong behavior, missing feature, performance concern) and wants:

- A **clear issue** (repro, expected, actual), and/or
- **Investigation** against project specs and implementation, and/or
- A **proposed fix** (approach and likely touch points), **without** you changing the tree.

## Workflow

### 1. Normalize the report

From the user message(s), extract or explicitly mark as **unknown**:

| Field | Goal |
|--------|------|
| **Environment** | Platform, build/channel, version or commit if known |
| **Steps to reproduce** | Ordered, minimal steps; note gaps |
| **Expected behavior** | What should happen per user (and later cross-check with SPEC where relevant) |
| **Actual behavior** | What happens instead; errors, logs, screenshots described in text |

If any of these are ambiguous, ask **short** clarifying questions before finalizing the draft. Do not invent precise repro steps.

### 2. Requirement clarification (mandatory)

Before drafting issue content, do a targeted read-only investigation and then clarify requirements with the user:

1. Read the most relevant SPEC and code paths tied to the report.
2. Compare user-stated behavior/request vs current intended/implemented behavior.
3. Present a **numbered list** of requirement clarifications in chat (each item should be one requirement decision, ambiguity, or conflict).
4. Ask for user confirmation/corrections on that numbered list.

Do not proceed to draft/create the issue until this clarification step is completed.

### 3. Investigate (read-only)

- **Specs:** Trace the reported behavior to authoritative docs. For ColonizeThis: GDD under `SPEC/game/`, TDD under `SPEC/program/`, plus `SPEC/ai/` and `SPEC/ui/` as needed (see project SPEC-first rules). Quote or summarize **specific files/sections** that align or contradict the report.
- **Player-app UI:** When the report involves screens, dialogs, overlays, layout, or UI-triggered bus events, also read `SPEC/ui/screen-registry.md` and the relevant screen spec under `SPEC/ui/`. Screen structure is governed by `.cursor/rules/colonizethis-ui-documentation.mdc` (stable 8-char IDs, layout/behavior/variants, Widgetbook)—orthogonal to style in `colonizethis-ui-design.mdc`.
- **Implementation:** Search and read relevant modules. Map **symptoms -> likely code paths** (files, types, key functions). Stay factual; label inference as hypothesis when not proven.
- **Tests:** Note existing tests that would fail or are missing for this scenario (read-only).

Do not run destructive commands; optional **read-only** checks (e.g. search, `git show`, tests in read-only mode) are fine only if they do not require changing files—prefer static analysis when unsure.

### 4. Proposed fix (design only)

Output a **concrete but unapplied** plan:

- **Root cause / hypothesis** (one short paragraph)
- **Suggested change** (bullet list: logic, UI, data, config—at appropriate abstraction level)
- **Files / areas** likely to change (paths, not patches)
- **SPEC impact:** none, clarification only, or new/extended spec required before implementation (per project SPEC-first policy)
- **UI documentation follow-up:** If the fix adds or changes a player-app screen/dialog/overlay, note that implementation must use **`document-app-ui`** (`.cursor/skills/document-app-ui/SKILL.md`; OpenCode: `.opencode/skills/document-app-ui/SKILL.md`) for registry ID, `SPEC/ui/<screen>.md`, `UiScreenIds`, and Widgetbook—include as subtask or acceptance criterion; do not edit those artifacts in this read-only skill.
- **Risks / edge cases**
- **Suggested acceptance criteria** (testable bullets the implementer can paste into the issue)

### 5. Build title and body

Prepare a concise **title** (<=~80 chars, imperative or clear symptom) and **body** markdown. Use this structure:

```markdown
## Summary
[One or two sentences]

## Environment
- ...

## Steps to reproduce
1. ...
2. ...

## Expected behavior
...

## Actual behavior
...

## Investigation notes
- SPEC: [file/section references, what they say]
- Code: [relevant paths and behavior]
- Tests: [what exists / gaps]

## Proposed fix (not implemented)
- ...
- SPEC/tests follow-up: ...

## Suggested acceptance criteria
- [ ] ...
```

**Labels / milestones:** Add with `gh` only if the user asked or labels are obvious (`--label`); otherwise omit or suggest in chat after success.

### 6. Create the issue (primary path)

**Attempt to create the issue directly** after the draft is ready:

1. Run from the **repository root** (so `gh` resolves the correct default remote).
2. Prefer writing the body to a **temporary file** (e.g. under `/tmp`) and running:
   `gh issue create --title "<title>" --body-file "<path>"`
   Use `--body-file` so markdown and quotes are not mangled by the shell.
3. On **success**: paste the returned **issue URL** (and number) in chat. Keep the response short; the user can open the link.
4. On **failure**, do **not** stop after the error—apply **fallback** below.

Typical failure cases (non-exhaustive): `gh` not in PATH, `gh auth status` shows not logged in, rate limit, network error, missing `repo` scope, no permission to create issues on the repo.

### 7. Fallback when creation fails

If `gh issue create` does not succeed:

1. State **why** (quote or paraphrase the error when helpful).
2. Give **minimal recovery steps** when appropriate (e.g. install GitHub CLI, run `gh auth login`, fix token permissions).
3. Provide the full **title** and **body** in chat so the user can create the issue in the web UI or run `gh issue create` themselves once fixed.

Always preserve the complete draft on fallback; it is the backup deliverable.

## Quality bar

- Separate **facts** (from code/specs) from **hypotheses** and user report.
- Prefer **minimal repro**; avoid dumping unrelated investigation.
- If the report conflicts with SPEC, call that out explicitly (spec bug vs implementation bug vs misunderstanding).
- Requirement clarifications are always shown to the user as a **numbered list** and confirmed before issue drafting/filing.

## Related

- For **verifying** an existing issue: see [.cursor/skills/verify-github-issue/SKILL.md](../verify-github-issue/SKILL.md).
- For **player-app UI** spec/registry/Widgetbook work during implementation: [.cursor/skills/document-app-ui/SKILL.md](../document-app-ui/SKILL.md) (OpenCode: `.opencode/skills/document-app-ui/SKILL.md`).
- For **implementation** after the issue exists: **AGENTS.md**, **CONTRIBUTING.md**, and `.cursor/rules/` (testing, SPEC-required, etc.).
