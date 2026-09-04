---
name: verify-github-issue
description: Verifies one open GitHub issue against acceptance criteria, specs, tests, and CONTRIBUTING; posts a verification comment via gh. UI issues require passing widget goldens on latest dev with PNG proof uploaded to the issue (hard-fail if goldens cannot be captured or fix is not merged). Game-app UI also has a standing 1 s full-load surface budget + dispose check even when issue ACs omit it. Never relabels issues.
---

**Thin OpenCode shim.** Source of truth: `.cursor/skills/verify-github-issue/SKILL.md`

Read that file and follow it exactly.
Also read: `.cursor/skills/verify-github-issue/reference.md`.
