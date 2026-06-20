---
name: backlog-refine-agent
description: Picks one open GitHub issue labeled backlog:refinement, applies refine-github-issue strictly against all comment feedback, updates the issue body directly, and relabels to backlog:review when fully resolved or backlog:clarification when uncertainties remain.
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/backlog-refine-agent/SKILL.md`

Read that file in full, then follow its workflow and required dependency on refine-github-issue exactly (including all cross-references to other `.cursor/skills/` files).
