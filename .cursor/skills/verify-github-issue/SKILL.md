---
name: verify-github-issue
description: Verifies one open GitHub issue is fully satisfied against acceptance criteria, specs, tests, and CONTRIBUTING workflow; proposes concrete gap fixes or drafts a closing comment and close steps. Use when the user gives an issue number or issue URL and wants verification, gap analysis, or issue closure aligned with dev-branch PRs.
---

# Verify and close a GitHub issue (ColonizeThis)

## When this applies

The user supplies an **issue reference**: issue **number** (e.g. `42`) and repo context if not obvious, or a **full issue URL**. If they only give a GitHub **username**, ask whether they meant an **issue number/URL** or assignee-based triage.

## Non-negotiables (repo policy)

Follow **[AGENTS.md](../../../AGENTS.md)** (Cursor rules under `.cursor/rules/`) and **[CONTRIBUTING.md](../../../CONTRIBUTING.md)** for all implementation and PR guidance.

**Hard failures to avoid** (treat as checklist, not suggestions):

- Skipping or hand-waving **acceptance criteria** from the issue (and linked **SPEC** ACs if referenced).
- Claiming “done” without **tests** that cover the change and meet coverage gates (**90%** logic/ai/map; **80%** elsewhere — see `colonizethis-testing.mdc` and CONTRIBUTING).
- Opening or describing a PR that does **not** target **`dev`** (default branch for PRs per CONTRIBUTING).

Also respect **SPEC-first** (`colonizethis-spec-required.mdc`): no behavior that contradicts GDD/TDD; extend SPEC before implementing unauthorized scope.

## Workflow

1. **Load the issue**  
   Use authenticated GitHub access when available (e.g. `gh issue view <n> --json title,body,labels,state,url` or the web UI). Confirm state is **open**.

2. **Extract requirements**  
   From the issue body (and comments): goals, **acceptance criteria**, links to SPEC/files, edge cases. If ACs are missing or vague, **state that gap** and propose minimal AC text before claiming full resolution.

3. **Trace to code and specs**  
   Search the repo for implementations, related PRs/commits, and SPEC sections. Map each AC item to: implemented / partial / missing / unknown.

4. **Verify tests and quality gates**  
   Identify or run relevant tests (`melos`, `flutter test` per project conventions in AGENTS/testing rule). Note coverage expectations from CONTRIBUTING; flag if tests are absent or clearly insufficient.

5. **Branch and PR posture**  
   Any fix must be described as a PR **into `dev`**, following CONTRIBUTING pre-PR checklist (SPEC/AC updates, logging alignment if applicable, coverage).

6. **Output**

   **If there are gaps**  
   - List each gap with severity (blocks closure vs follow-up).  
   - Propose a **concrete** remedy: files to touch, SPEC updates, test cases, and PR scope.  
   - Do **not** close the issue.

   **If fully addressed**  
   - Summarize evidence: AC → implementation → tests → target branch (`dev`).  
   - Draft a **short closing comment** for GitHub (what shipped, where, how ACs are met).  
   - Instruct the user to **close via** `gh issue close <n> --comment "<draft>"` (or web UI) using their credentials; do not assume the agent has permission to close on their behalf.

## Closing comment template

Use a neutral, factual tone:

```markdown
Verified against the stated acceptance criteria:

- [AC summary bullets tied to code/tests]

Implementation: [PR link or commit refs if known]. Tests: [what was run / added]. PR targets `dev` per CONTRIBUTING.

Closing as complete.
```

Adjust if some work landed without a merged PR yet — then **do not** recommend closure until merge criteria are met.

## Tools

- Prefer **`gh`** when installed and authenticated for viewing issues and closing with a comment.  
- Use repo search and test commands as in AGENTS/CONTRIBUTING; do not invent branch or review policy.

## Additional resources

- [reference.md](reference.md) — CONTRIBUTING/AGENTS excerpts and command hints
