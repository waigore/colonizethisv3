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

Interactive by default: paste the comment in chat; post with `gh` only if the user asks. [backlog-review-agent](../backlog-review-agent/SKILL.md) posts autonomously. Conventions: [shared.md](../shared.md).

Not [verify-github-issue](../verify-github-issue/SKILL.md) (AC ↔ implementation/SPEC/tests). Repo/SPEC/test evidence only to show the **method cannot satisfy the purpose**.

## Workflow

1. `gh issue view <n> --json title,body,labels,state,url,comments`. Confirm open unless the user asked about a closed issue.
2. **Purpose** — one-sentence goal/outcome from title+body. If unclear, propose a sentence.
3. **Method** — design, steps, files, APIs, scope, dependencies, ACs-as-solution-shape.
4. **Primary analysis** (issue text first): alignment, internal contradictions, thin “how”, missing manual/`document-app-ui` deliverables when player UX or screens change.
5. **Conditional repo trace** only if step 4 shows the method cannot work (architecture/SPEC-first/missing assumed hook). Cite minimal paths. Do not inventory the whole codebase.
6. Priority: **P0** blocks implementing from this issue; **P1** material ambiguity; **P2** follow-up.
7. One comment:

```markdown
## Issue purpose
[One sentence]

## Purpose ↔ method
- [Gap or alignment — quote issue where useful]
  - Evidence: [issue excerpt; optional minimal code/SPEC/test]
  - Priority: P0|P1|P2
  - Remedy: [issue/spec/plan edit]

## Internal consistency
- [Or “None noted.”]

## Summary
[P0/P1/P2 counts]. [If coherent: next step is verify-github-issue.]
```

Label remaining uncertainty as **hypothesis**. Do not close the issue.
