---
name: verify-github-issue
description: Verifies one open GitHub issue against acceptance criteria, specs, tests, and CONTRIBUTING; posts a verification comment via gh. UI issues require passing widget goldens on latest dev with PNG proof uploaded to the issue (hard-fail if goldens cannot be captured or fix is not merged). Never relabels issues.
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/verify-github-issue/SKILL.md` (plus `reference.md`). OpenCode: `.opencode/skills/verify-github-issue/SKILL.md`.

Read the SKILL.md and reference.md in full. Enforce latest-`dev` verification, merged fix required for Complete, UI widget golden + gist proof, standing game-app 1 s surface-budget + dispose check (even when issue ACs omit it), hard-fail rules, `gh issue comment` only (no relabels), and the handbook style + accuracy audit (same two checks as `review-game-manual-agent`) when the issue updates the manual.
