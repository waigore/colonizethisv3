---
name: create-github-issue
description: |-
  Turns an informal issue report into a structured GitHub issue with reproduction steps, expected vs actual behavior, read-only SPEC/code investigation, and a proposed fix scope—without modifying the repository.

  Always clarify requirements with the user first by reading relevant specs/code, analyzing the report against current behavior, and presenting requirement clarifications as a numbered list.

  Attempts to open the issue via GitHub CLI (gh); falls back to a paste-ready draft if gh is missing, unauthenticated, or creation fails.

  Use when the user describes a bug, regression, or gap and wants a filed issue, triage narrative, or fix direction before implementation.
---

# Create a GitHub issue from a user report (read-only)

Conventions: [shared.md](../shared.md).

## Scope

- **Do not** edit the repo (code, specs, tests, config).
- **Do** clarify with the user before drafting or filing: read relevant SPEC/code, then present a **numbered list** of requirement decisions/ambiguities/conflicts and wait for confirmation. Autonomous wrappers (`improve-ux-agent`, `review-game-manual-agent`) skip this step by design.
- Then create the issue (`gh issue create --body-file`). On failure, output the full title and body.

If the user asks to implement, stop this skill and use [implement-github-issue](../implement-github-issue/SKILL.md).

## Workflow

### 1. Normalize the report

Extract or mark **unknown**: environment, repro steps, expected, actual. Ask short questions for gaps. Do not invent precise repro steps.

### 2. Requirement clarification (mandatory unless a wrapper skips it)

Read SPEC/code, compare to the request, numbered list, wait for confirmation.

### 3. Investigate (read-only)

Cite SPEC files/sections (GDD `SPEC/game/`, TDD `SPEC/program/`, plus `SPEC/ai/` and `SPEC/ui/` as needed). For player-app UI, also `SPEC/ui/screen-registry.md` and the screen spec. Map symptoms → likely code paths; label inference as hypothesis. Note existing tests. Follow-ups: [document-app-ui](../document-app-ui/SKILL.md), [update-game-manual](../update-game-manual/SKILL.md) — name them as subtasks/ACs; do not run them here.

### 4. Proposed fix (design only)

Root cause / hypothesis; suggested change; likely files; SPEC impact; UI-docs and manual follow-ups; risks; testable ACs.

### 5. Title and body

Title ≤ ~80 chars. Body:

```markdown
## Summary
[One or two sentences]

## Environment
- ...

## Steps to reproduce
1. ...

## Expected behavior
...

## Actual behavior
...

## Investigation notes
- SPEC: ...
- Code: ...
- Tests: ...

## Proposed fix (not implemented)
- ...
- SPEC/tests follow-up: ...
- Manual follow-up: [chapter(s) or N/A with justification]

## Suggested acceptance criteria
- [ ] ...
- [ ] Manual: Given player-visible behavior changes, when implementation merges, then `docs/manual/` chapter(s) [list] are updated (or non-update is justified in the PR).
```

Labels only if the user asked or they are obvious.

### 6–7. Create or fall back

`gh issue create --title "..." --body-file "..."` from repo root. Success → paste the URL. Failure → why, recovery hint, full draft. See [shared.md](../shared.md) `gh` usage.
