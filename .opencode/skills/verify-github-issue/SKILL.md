---
name: verify-github-issue
description: Verifies one open GitHub issue against acceptance criteria, specs, tests, and CONTRIBUTING; posts a verification comment via gh. UI issues require passing widget goldens on latest dev with PNG proof uploaded to the issue (hard-fail if goldens cannot be captured or fix is not merged). Never relabels issues.
---

# Verify a GitHub issue (OpenCode)

## Source of truth

Use **`.cursor/skills/verify-github-issue/SKILL.md`** and **`reference.md`** as the authoritative workflow, hard-fail rules, UI golden proof procedure, comment template, and command cookbook.

## OpenCode adaptation

When running in OpenCode:

- Read both Cursor files in full before verifying.
- Verify only on **latest `origin/dev`** (`git fetch && git checkout dev && git pull`). Local-only or unmerged fixes → **Gaps remain**.
- **Complete** only when the fix is **merged on `dev`**, ACs pass, tests pass, (for UI issues) widget golden PNGs are embedded in the issue comment via public gist, and (for game-app UI) the standing 1 s surface-budget + dispose row in the Cursor skill is pass or N/A.
- When the issue updates the player manual, apply `.cursor/skills/review-game-manual-agent/SKILL.md` § Style review and § Accuracy review to each updated chapter (STYLE_GUIDE + cited SPECs / screen-registry). Remaining findings → **Gaps remain**.
- Post **`gh issue comment` only** — never relabel, close, or change milestones (unlike `backlog-verify-agent`, which may relabel after applying this skill).
