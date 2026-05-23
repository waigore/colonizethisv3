---
name: consolidate-prs
description: Collapses multiple open pull requests that target the same GitHub issue into one consolidated PR, unblocks any stalled contributor PRs via strict `fix-pr` first, then cancels in-progress GitHub Actions runs that are no longer attached to any open PR. Use when the user asks to consolidate, merge, or de-duplicate open PRs by issue and tidy CI usage.
---

# Consolidate open PRs by issue (ColonizeThis) — OpenCode

This OpenCode skill **defers** to the canonical Cursor skill to avoid drift.

## Read and follow

`.cursor/skills/consolidate-prs/SKILL.md` (same repository).

That file is normative. It defines:

- Discovery and grouping of open PRs by referenced issue.
- Canonical PR selection and the redundant-PR fold-in workflow.
- Strict use of `.cursor/skills/fix-pr/SKILL.md` for any stalled PR.
- Closing redundant PRs with a pointer comment (no remote branch deletion).
- Forcibly cancelling in-progress GitHub Actions runs that are no longer
  attached to any open PR.
- Output format and guardrails.

If `.cursor/skills/consolidate-prs/SKILL.md` is unavailable, stop and ask the
user how to proceed — do not improvise a consolidation workflow.
