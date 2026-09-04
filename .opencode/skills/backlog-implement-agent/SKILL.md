---
name: backlog-implement-agent
description: Optimizes code throughput across open issues labeled backlog:implementation. Each run does substantial work and never waits for CI, reviews, or merges. Unblocks stalled PRs (conflicts, failing checks, or open with checks not running) via strict fix-pr toward merge readiness, then moves on. Only PRs that reference those labelled issues. Applies strict implement-github-issue for new work. Each PR targets exactly one issue. Relabels to backlog:verification only when an issue is fully done.
---

**Thin OpenCode shim.** Source of truth: `.cursor/skills/backlog-implement-agent/SKILL.md`

Read that file and follow it exactly.
