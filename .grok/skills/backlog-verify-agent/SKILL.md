---
name: backlog-verify-agent
description: Picks one open GitHub issue labeled backlog:verification, applies verify-github-issue strictly to confirm implementation completeness, posts a verification comment, and relabels to backlog:acceptance when complete or backlog:implementation when gaps remain.
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/backlog-verify-agent/SKILL.md`

Read the full authoritative file and apply its workflow + strict dependency on verify-github-issue exactly.
