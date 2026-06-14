---
name: verify-github-issue
description: Verifies one open GitHub issue against acceptance criteria, specs, tests, and CONTRIBUTING workflow; uses the gh CLI directly to read the issue and post a consolidated verification comment; proposes concrete gap fixes when work is incomplete. Use when the user gives an issue number or issue URL and wants verification or gap analysis aligned with dev-branch PRs.
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/verify-github-issue/SKILL.md` (plus its sibling `reference.md`).

Read the SKILL.md and reference.md in full. Enforce the hard failures to avoid, gh-direct usage, full workflow (load → extract → trace → verify tests/gates → post comment), and verification comment template exactly. This is a core dependency for backlog-verify-agent and many related-skill pointers.
