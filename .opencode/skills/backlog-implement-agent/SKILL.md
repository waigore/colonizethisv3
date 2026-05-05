---
name: backlog-implement-agent
description: Picks one open GitHub issue labeled backlog:implementation, applies implement-github-issue strictly to implement either full issue scope or a valid slice, opens a PR that clearly states implemented and deferred work, and relabels to backlog:verification only when nothing remains.
---

# Backlog Implement Agent (OpenCode)

## Source of truth

Use `.cursor/skills/backlog-implement-agent/SKILL.md` as the authoritative workflow, scope decision criteria, PR disclosure requirements, and label transition rules.

## OpenCode adaptation

When running in OpenCode:

- Keep the same one-issue-per-run behavior unless the user explicitly requests batching.
- Use `gh issue list` to select from open issues labeled `backlog:implementation`.
- Apply `.cursor/skills/implement-github-issue/SKILL.md` strictly for readiness gates, SPEC updates, implementation, tests, and PR flow.
- Decide full vs slice scope using issue-defined slicing first; otherwise follow implement-github-issue large-scope triage.
- Ensure the PR body explicitly states:
  - what was implemented in this PR
  - what was deferred (if anything)
  - why any deferred work remains
- Treat issue completion as blocked until all open PRs linked to the issue are merged. If any linked PR remains open (including draft), keep the issue in `backlog:implementation`.
- Relabel only when complete:
  - Complete: remove `backlog:implementation`, add `backlog:verification`
  - Partial: keep `backlog:implementation`
- Do not close issues in this workflow.

## Required references

Before execution, read:

- `.cursor/skills/backlog-implement-agent/SKILL.md`
- `.cursor/skills/implement-github-issue/SKILL.md`
