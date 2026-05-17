---
name: verify-github-issue
description: Verifies one open GitHub issue against acceptance criteria, specs, tests, and CONTRIBUTING workflow; uses the gh CLI directly to read the issue and post a consolidated verification comment; proposes concrete gap fixes when work is incomplete. Use when the user gives an issue number or issue URL and wants verification or gap analysis aligned with dev-branch PRs.
---

# Verify a GitHub issue (ColonizeThis)

## When this applies

The user supplies an **issue reference**: issue **number** (e.g. `42`) and repo context if not obvious, or a **full issue URL**. If they only give a GitHub **username**, ask whether they meant an **issue number/URL** or assignee-based triage.

## Non-negotiables (repo policy)

Follow **[AGENTS.md](../../../AGENTS.md)** (Cursor rules under `.cursor/rules/`) and **[CONTRIBUTING.md](../../../CONTRIBUTING.md)** for all implementation and PR guidance.

**Hard failures to avoid** (treat as checklist, not suggestions):

- Skipping or hand-waving **acceptance criteria** from the issue (and linked **SPEC** ACs if referenced).
- Claiming “done” without **tests** that cover the change and meet coverage gates (**90%** logic/ai/map; **80%** elsewhere — see `colonizethis-testing.mdc` and CONTRIBUTING).
- Opening or describing a PR that does **not** target **`dev`** (default branch for PRs per CONTRIBUTING).

Also respect **SPEC-first** (`colonizethis-spec-required.mdc`): no behavior that contradicts GDD/TDD; extend SPEC before implementing unauthorized scope.

## GitHub CLI (`gh`) — required path

Use the **`gh`** binary **directly** from the workspace repo clone. Issue **read** uses **`gh issue view`**; posting the verification uses **`gh issue comment`**.

## Workflow

1. **Load the issue**  
   Run **`gh issue view <n> --json title,body,labels,state,url`** (add **`--repo owner/name`** when the issue is not on the clone’s default remote). Confirm state is **open**.

2. **Extract requirements**  
   From the issue body (and comments): goals, **acceptance criteria**, links to SPEC/files, edge cases. If ACs are missing or vague, **state that gap** and propose minimal AC text before claiming full verification.

3. **Trace to code and specs**  
   Search the repo for implementations, related PRs/commits, and SPEC sections. Map each AC item to: implemented / partial / missing / unknown.

4. **Verify tests and quality gates**  
   Identify or run relevant tests (`melos`, `flutter test` per project conventions in AGENTS/testing rule). Note coverage expectations from CONTRIBUTING; flag if tests are absent or clearly insufficient.

5. **Branch and PR posture**  
   Any fix must be described as a PR **into `dev`**, following CONTRIBUTING pre-PR checklist (SPEC/AC updates, logging alignment if applicable, coverage).

6. **Post the verification on GitHub**  
   **Always** publish the result as an **issue comment** on that issue (same number/repo as step 1) using **`gh issue comment`**: `gh issue comment <n> --body-file <path>` or `gh issue comment <n> --body "<markdown>"`. Use **`--repo owner/name`** when the issue is not on the clone’s default remote.

7. **Comment body**

   **If there are gaps**  
   - List each gap with severity (blocks “verified complete” vs follow-up).  
   - Propose a **concrete** remedy: files to touch, SPEC updates, test cases, and PR scope.

   **If fully addressed**  
   - Summarize evidence: AC → implementation → tests → target branch (`dev`).

   In both cases, use a neutral, factual tone. The **only** required GitHub write for this skill is the verification **comment**—not labels, milestones, or issue state.

## Verification comment template

Use a neutral, factual tone:

```markdown
**Verification** (ACs / SPEC / tests)

- [AC summary bullets tied to code/tests; mark partial/missing where applicable]

Implementation: [PR link or commit refs if known]. Tests: [what was run / added]. PR targets `dev` per CONTRIBUTING.

Outcome: [Complete | Gaps remain — see above].
```

If some work exists but is not merged yet, state that verification is **conditional on merge** and list what must land before a “complete” outcome.

## Tools

- **`gh`** for GitHub: `gh issue view`, **`gh issue comment`**.  
- Repo search and test commands per AGENTS/CONTRIBUTING; do not invent branch or review policy.

## Additional resources

- [reference.md](reference.md) — CONTRIBUTING/AGENTS excerpts and command hints
