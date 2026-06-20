---
name: consolidate-prs
description: Collapses multiple open pull requests that target the same GitHub issue into one consolidated PR, unblocks any stalled contributor PRs via strict `fix-pr` first, then cancels in-progress GitHub Actions runs that are no longer attached to any open PR. Use when the user asks to consolidate, merge, or de-duplicate open PRs by issue and tidy CI usage.
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/consolidate-prs/SKILL.md`

Read the full file (including its required dependencies section). Follow its non-negotiables, workflow (especially the mandatory use of fix-pr for stalled PRs and clean-local-branches), and output requirements exactly. Honor all `.cursor/skills/` cross-references inside it.
