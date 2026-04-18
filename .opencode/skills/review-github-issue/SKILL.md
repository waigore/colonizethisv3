---
name: review-github-issue
description: |-
  Review a GitHub issue against existing code, specs, and tests to identify gaps, inconsistencies, and misalignments. Builds a consolidated comment highlighting each problem, priority, and suggested remedy. Use when user asks to review, audit, or triage an issue; to find gaps before implementation; or to prepare for a fix PR.

  Examples:
  - user: "Review issue #42" → load issue, trace ACs to code/specs/tests, output gap analysis with priorities
  - user: "Audit this bug report for inconsistencies" → identify what issue intends to solve, verify each item aligns
  - user: "Find gaps in issue before starting work" → rigorous review against existing implementation
  - user: "Triage this issue against our specs" → map issue items to SPEC sections, flag contradictions
---

# Review a GitHub Issue (ColonizeThis)

## When this applies

The user supplies a **GitHub issue number** (e.g. `42`) or **issue URL** and asks to review it against the codebase, specs, and tests. The goal is to produce a **consolidated comment** identifying gaps, inconsistencies, and misalignments—grounded in evidence from code, specs, and tests.

## Non-negotiables (repo policy)

Follow **[AGENTS.md](https://github.com/AnomalyCo/colonizethisv3_6/blob/dev/AGENTS.md)** (Cursor rules under `.cursor/rules/`) and **[CONTRIBUTING.md](https://github.com/AnomalyCo/colonizethisv3_6/blob/dev/CONTRIBUTING.md)**.

- **SPEC-first**: Every issue has an implicit or explicit **purpose** (what it intends to solve). Verify the issue actually addresses that purpose before reviewing individual items.
- **Gap grounding**: Every problem cited must be traceable to: code implementation, SPEC section, or test. Do not speculate without flagging as hypothesis.
- **Priority framing**: Distinguish **blocks resolution** (must fix) from **follow-up** (nice-to-have or deferred).

## Workflow

### 1. Load the issue

Run:
```bash
gh issue view <n> --json title,body,labels,state,url,comments
```
or use the web UI. Confirm state is **open**.

### 2. Identify the ultimate purpose

Ask: **"What is this issue intending to solve?"**

- Extract the **goal** from title + body (not just the symptoms or proposed solution)
- If the goal is unclear, state that the issue lacks a clear purpose statement and propose one
- This purpose is the **anchor** for all subsequent alignment checks

### 3. Trace each issue item to code, specs, and tests

For each item in the issue (requirements, acceptance criteria, proposed fix, edge cases):

| Check | How |
|-------|-----|
| **Implementation** | Search repo for relevant modules, types, functions. Map symptom → likely code path. |
| **Specs** | Quote or summarize specific files/sections from `SPEC/game/`, `SPEC/program/`, `SPEC/ai/`, `SPEC/ui/` that address or contradict the item. |
| **Tests** | Note existing tests that cover this scenario vs. missing tests. |

For each item, categorize:
- ✅ **implemented** — matches code + specs + tests
- ⚠️ **partial** — partially addressed but missing pieces
- ❌ **missing** — not addressed in code or specs
- 🔀 **contradicts** — item conflicts with existing SPEC or implementation
- ❓ **unknown** — insufficient info; flag as hypothesis

### 4. Identify gaps and inconsistencies

**Gaps** (items that don't address the purpose):
- Item exists in issue but does not contribute to the stated purpose → flag as out-of-scope or misaligned

**Inconsistencies** (internal contradictions):
- Title vs. body contradiction
- AC vs. proposed fix mismatch
- Labels/milestones vs. actual content mismatch

**Gaps vs. SPEC/code**:
- Item contradicts existing SPEC → spec bug vs. implementation bug vs. misunderstanding
- Item has no test coverage → note as testing gap

### 5. Assess priority for each problem

| Priority | Meaning |
|----------|---------|
| **P0 (blocks)** | Issue cannot be resolved without fixing this; prevents closure |
| **P1 (important)** | Significant misalignment; should be addressed but not blocking |
| **P2 (follow-up)** | Nice-to-have fix, deferred, or edge case that can be handled separately |

### 6. Build consolidated comment

Output a single structured comment with:

1. **Purpose statement** — one sentence stating what the issue intends to solve (from Step 2)
2. **Items** (for each issue item):
   - Status icon (✅/⚠️/❌/🔀/❓)
   - What the item says
   - Evidence (code paths, SPEC sections, test files)
   - Problem if any (misaligned, contradictory, missing)
   - Priority (P0/P1/P2)
   - **Suggested remedy** — concrete fix or SPEC/test update

Use a neutral, factual tone. Do not close the issue.

### 7. Present findings

- Paste the consolidated comment in chat for the user to post
- Include the issue URL and number
- If `gh` is available and user requests, offer to post as a comment:
  ```bash
  gh issue comment <n> --body "<comment>"
  ```

## Quality bar

- Every problem must be **grounded** in code, specs, or tests—not speculation
- If speculation is necessary, label as **hypothesis** and suggest how to verify
- Distinguish **what the issue intends to solve** from **how it proposes to solve it**; misaligned *how* items are still gaps
- Avoid dumping full investigation; keep to gap-level evidence

## Output template

```markdown
## Issue Purpose
[One sentence: what this issue intends to solve]

## Review

| Item | Status | Evidence | Problem | Priority | Remedy |
|------|--------|----------|---------|----------|--------|
| ...  | ...    | ...      | ...     | ...      | ...    |

## Summary
[P0 count] blocking, [P1 count] important, [P2 count] follow-up items.
```

## Related skills

- For **implementing a fix** after review: see `.cursor/skills/implement-github-issue-fix/SKILL.md`
- For **verifying or closing** an issue after gaps are fixed: see `.cursor/skills/verify-github-issue/SKILL.md`
- Tracing hints: see `.opencode/skills/review-github-issue/references/review-reference.md`
