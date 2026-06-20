---
name: fix-pr
description: Diagnoses and unblocks a pull request by checking PR status, failing checks, quality gates, and merge conflicts, then applying the minimal compliant fix and verifying results. Use when the user provides a PR URL or PR number and asks to fix or unblock the PR.
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/fix-pr/SKILL.md` (plus its sibling `reference.md`).

Read both the SKILL.md and reference.md from the .cursor location. Follow the non-negotiables, workflow (context, conflicts, reproduce, minimal fix, verify), and output format exactly. This is a core dependency for consolidate-prs, manage-pr-agent, and backlog agents.
