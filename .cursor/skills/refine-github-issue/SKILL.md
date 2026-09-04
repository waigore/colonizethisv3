---
name: refine-github-issue
description: |-
  Refines an open GitHub issue using feedback in issue comments: tightens reproduction steps and root-cause analysis, resolves internal inconsistencies, and clarifies subtask priorities and dependencies. Works each feedback item explicitly—updates the issue body when the point is accurate and reasonable, otherwise returns numbered clarification questions for the user. Use when the user asks to address issue feedback, refine an issue from reviewer comments, reconcile comments with the description, or refresh an issue after triage discussion.

  Examples:
  - user: "Apply the feedback on #88" → map each comment to concrete edits or numbered pushbacks
  - user: "Update the issue from the last three comments" → merge non-conflicting clarifications into the body
  - user: "Comments say repro is wrong—fix the issue text" → verify against thread, edit body or ask numbered questions if ambiguous
---

# Refine a GitHub issue from comment feedback (ColonizeThis)

Issue number/URL. Align the **body** with **comment feedback** — not greenfield drafting. Interactive when a comment is wrong, speculative, or contradicts SPEC: numbered questions, do not silently rewrite. Conventions: [shared.md](../shared.md).

Related: [review-github-issue](../review-github-issue/SKILL.md) (fresh purpose–method); [verify-github-issue](../verify-github-issue/SKILL.md) (implementation vs ACs).

## Workflow

1. `gh issue view <n> --json title,body,state,labels,url,comments`. Chronological comments; include review threads if they matter.
2. Inventory **F1, F2, …** (quote, author, theme: repro / RCA / consistency / subtask deps). Merge duplicates; keep conflicting comments as separate items.
3. Per item: accurate → planned body edit; partly right → partial edit + uncertainty; wrong or SPEC-contradicting → numbered clarification, do not adopt; needs repo check → read-only only as far as needed, else escalate.
4. Minimal `gh issue edit <n> --body-file`. Re-fetch to confirm. Optional short comment listing incorporated threads.
5. Report: every inventoried item in **Body updated** or **Needs your input** (numbered). Do not invent requirements comments did not imply.
