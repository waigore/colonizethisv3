---
name: refine-github-issue
description: |-
  Refines an open GitHub issue using feedback in issue comments: tightens reproduction steps and root-cause analysis, resolves internal inconsistencies, and clarifies subtask priorities and dependencies. Works each feedback item explicitly—updates the issue body when the point is accurate and reasonable, otherwise returns numbered clarification questions for the user. Use when the user asks to address issue feedback, refine an issue from reviewer comments, reconcile comments with the description, or refresh an issue after triage discussion.

  Examples:
  - user: "Apply the feedback on #88" → map each comment to concrete edits or numbered pushbacks
  - user: "Update the issue from the last three comments" → merge non-conflicting clarifications into the body
  - user: "Comments say repro is wrong—fix the issue text" → verify against thread, edit body or ask numbered questions if ambiguous
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/refine-github-issue/SKILL.md`

Read the full file and follow its non-negotiables, feedback inventory/evaluation, body update rules, reporting, and quality bar exactly. Related skills noted inside point to review-github-issue and verify-github-issue.
