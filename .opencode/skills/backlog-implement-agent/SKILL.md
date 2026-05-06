---
name: backlog-implement-agent
description: Picks one open GitHub issue labeled backlog:implementation, prefers merging existing open PRs for that issue (unblocking stalled ones via fix-pr first), otherwise applies implement-github-issue strictly; opens or advances PRs documenting implemented vs deferred work; relabels to backlog:verification only when no outstanding work remains.
---

# Backlog Implement Agent (OpenCode)

## Source of truth

Use `.cursor/skills/backlog-implement-agent/SKILL.md` as the authoritative workflow, scope decision criteria, PR disclosure requirements, label transition rules, **open-PR discovery (search), stall definition, fix-pr execution order, and merge-first priority**.

## OpenCode adaptation

When running in OpenCode:

- Keep the same one-issue-per-run behavior unless the user explicitly requests batching.
- Use `gh issue list` to select from open issues labeled `backlog:implementation`.
- **After the issue is selected:** search for **open PRs** that reference the issue in title/body (`gh pr list` + `--search`); sort matches **oldest first**; treat as **stalled** if the PR has **merge conflicts** or **failing checks**; for each stalled PR in order, read and follow `.cursor/skills/fix-pr/SKILL.md` before favoring new implementation work.
- **Merge-first:** prefer getting those PRs merge-ready and merged over opening new slices; full issue scope still ends in **`dev`**; the agent decides how much of the run is unblock/merge versus new implementation.
- Apply `.cursor/skills/implement-github-issue/SKILL.md` strictly for readiness gates, SPEC updates, implementation, tests, and PR flow when new work or follow-up slices are needed.
- Decide full vs slice scope using issue-defined slicing first; otherwise follow implement-github-issue large-scope triage (and do not duplicate work already present in open PRs when merge path is viable).
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
- `.cursor/skills/fix-pr/SKILL.md` (when any open PR for the issue is stalled)
