---
name: review-github-issue
description: |-
  Reviews a GitHub issue for coherence between its stated purpose and its proposed approach (design, scope, ACs). Produces a consolidated comment: primary focus is purpose↔method gaps and internal contradictions; code/spec/test evidence only when needed to show the proposed method cannot satisfy the purpose. Use before implementation; use verify-github-issue for AC↔implementation/SPEC/tests verification posted on the issue.

  Examples:
  - user: "Review issue #42" → state purpose, assess whether the proposed method plausibly achieves it, flag internal gaps; repo evidence only if method cannot satisfy purpose
  - user: "Audit this bug report" → extract goal vs proposed fix; flag mismatches, missing how, contradictions in the text
  - user: "Find gaps in issue before starting work" → purpose–method alignment and thin-issue contradictions first; defer full AC→code mapping to verify
  - user: "Triage this issue" → clarify purpose, scope, and whether the described approach hangs together
---

# Review a GitHub Issue (ColonizeThis)

This skill is maintained in sync with **[`.opencode/skills/review-github-issue/SKILL.md`](../../../.opencode/skills/review-github-issue/SKILL.md)**.

The unified skill body is duplicated below so Cursor agents load the full workflow from `.cursor/skills/` without resolving cross-folder links.

---

## When this applies

The user supplies a **GitHub issue number** (e.g. `42`) or **issue URL** and asks to **review**, **audit**, or **triage** the issue **before implementation**.

The goal is a **consolidated comment** whose **primary** analysis is:

- **Purpose ↔ method**: gaps or tensions between **what the issue purportedly addresses** (its purpose / outcome) and **how it proposes to get there** (design, steps, scope, dependencies, acceptance criteria as a solution shape).

This skill is **not** centered on re-deriving **“issue description vs current SPEC/implementation/tests”** as the main output. That reconciliation should already live in a well-written issue; **systematic** mapping of acceptance criteria to code, specs, and tests belongs in **`.cursor/skills/verify-github-issue/SKILL.md`** (posted as an issue comment).

## Boundary: review vs verify

| Skill | Primary question | Typical evidence |
|-------|------------------|------------------|
| **review-github-issue** (this) | Does the **purpose** align with the **proposed method**? Are there **internal** contradictions or missing “how”? | Issue text (quotes); repo/SPEC/tests **only** when needed to show the method **cannot** satisfy the purpose |
| **verify-github-issue** | Does the **work** satisfy the issue’s ACs against **implementation, SPEC, and tests**? | Code paths, SPEC sections, tests, CI/coverage |

## Non-negotiables (repo policy)

Follow **[AGENTS.md](../../../AGENTS.md)** (Cursor rules under `.cursor/rules/`) and **[CONTRIBUTING.md](../../../CONTRIBUTING.md)**.

- **SPEC-first**: The issue’s purpose must not imply behavior that contradicts GDD/TDD; if the **proposed method** would do so, that is **in scope** here (purpose–method feasibility), and may require SPEC updates before implementation.
- **Gap grounding**:
  - **Primary gaps** (purpose vs method, internal inconsistency, out-of-scope items) must be grounded in **the issue text** (short quotes or paraphrase with pointer to section).
  - **Repo/SPEC/test evidence** is required **only when** it directly supports the claim that the **proposed method cannot satisfy** the **stated purpose** (e.g. non-negotiable architecture boundary, impossible sequencing, missing hook that the method assumes). Label remaining uncertainty as **hypothesis** and how to verify.
- **Priority framing**: Distinguish **blocks drafting or implementing from this issue** from **follow-up** clarifications.

## Workflow

### 1. Load the issue

Run:

```bash
gh issue view <n> --json title,body,labels,state,url,comments
```

or use the web UI. Confirm state is **open** (unless the user explicitly asked about a closed issue).

### 2. Identify the purpose

Ask: **“What is this issue intending to solve or change?”**

- Extract the **goal / outcome** from title + body—not only symptoms or a single proposed patch.
- If the purpose is unclear or overloaded, state that and propose a **single-sentence purpose** the issue should adopt.

This purpose is the **anchor** for all purpose–method checks.

### 3. Extract the proposed method

Identify **how** the issue says the purpose should be achieved:

- Proposed **design**, **steps**, **files/modules** mentioned, **API or event** shapes, **scope** (in/out), **dependencies**, **risks**, and **acceptance criteria** insofar as they define the solution—not as a checklist against the whole repo.

### 4. Primary analysis: purpose ↔ method and internal consistency

**Do this first** (mostly from the issue alone):

- **Alignment**: Does each major part of the proposed method **contribute** to the stated purpose? Flag **out-of-scope**, **under-specified**, or **misaligned** pieces.
- **Internal contradictions**: Title vs body; AC vs proposed fix; scope vs labels/milestone; duplicate or conflicting requirements.
- **Thin issues**: If purpose is somewhat clear but **how** is missing or self-contradictory, **flag that as the main finding**—do **not** substitute a full repository audit for missing method text.

### 5. Conditional deep trace (code, SPEC, tests)

Search the repo **only when** step 4 shows (or strongly suggests) that the **method cannot satisfy the purpose**, including:

- Hard **architecture** or **package-boundary** constraints (e.g. logic ↔ AI decoupling).
- **SPEC-first** violations implied by the method.
- Claims that a hook, type, or behavior **exists** when a quick check shows it does **not**—**if** that absence blocks the described approach.

Do **not** perform a full item-by-item ✅/⚠️/❌ inventory against the codebase as the default output of this skill; that is **verify** territory.

When repo evidence is used, cite **minimal** paths or SPEC sections—enough to justify the purpose–method conclusion.

### 6. Assess priority for each problem

| Priority | Meaning |
|----------|---------|
| **P0 (blocks)** | The issue, as written, cannot be implemented or agreed without resolving this (e.g. purpose–method contradiction, method impossible under repo rules). |
| **P1 (important)** | Material ambiguity or misalignment; should be fixed before or during implementation planning. |
| **P2 (follow-up)** | Clarifications, polish, or deferrable scope notes. |

### 7. Build consolidated comment

Output a single structured comment with:

1. **Purpose statement** — one sentence (from step 2; or your proposed sentence if the issue was unclear).
2. **Purpose–method review** — bullet or table: each problem, evidence (issue quote and, if applicable, minimal code/SPEC/test pointer), priority, **suggested remedy** (edit issue text, split issue, adjust design, or point to SPEC work).
3. **Optional**: One line pointing to **verify-github-issue** when the issue is internally coherent and the next step is AC↔implementation proof.

Use a neutral, factual tone. Do not close the issue.

### 8. Present findings

- Paste the consolidated comment in chat for the user to post.
- Include the issue URL and number.
- If `gh` is available and the user requests, offer to post as a comment:

  ```bash
  gh issue comment <n> --body "<comment>"
  ```

## Quality bar

- **Primary** findings are visible without reading the whole codebase: purpose–method and **in-issue** consistency.
- Repo/SPEC/test citations appear **only** where they **directly** support “this method cannot achieve this purpose” (per project policy: evidence type **B**).
- If speculation is necessary, label **hypothesis** and suggest how to verify (often via **verify** after a fix PR).

## Output template

```markdown
## Issue purpose
[One sentence]

## Purpose ↔ method
- [Gap or alignment note — quote issue where useful]
  - Evidence: [issue excerpt; optional minimal code/SPEC/test if feasibility]
  - Priority: P0|P1|P2
  - Remedy: [concrete issue/spec/plan edit]

## Internal consistency
- [Or “None noted.”]

## Summary
[P0/P1/P2 counts]. [If appropriate: next step is verify-github-issue against implementation/SPEC/tests.]
```

## Related skills

- **Implement**: `.cursor/skills/implement-github-issue/SKILL.md`
- **Verify** (issue vs implementation, SPEC, tests): `.cursor/skills/verify-github-issue/SKILL.md`
- Tracing hints (when step 5 applies): `.opencode/skills/review-github-issue/references/review-reference.md`
