---
name: review-pr
description: Reviews an open pull request with strict YES/CONDITIONAL YES/NO scoring across issue alignment, AC test coverage, architecture conventions, and linting compliance. Use when auditing PR merge readiness.
---

# Review PR (OpenCode)

## Source of truth

Use `.cursor/skills/review-pr/SKILL.md` as the authoritative rule set for process, scoring, non-negotiables, and output format.

## OpenCode adaptation

When running in OpenCode:

- Follow the same four mandatory criteria and strict scoring semantics from the Cursor skill.
- Preserve the same non-negotiables:
  - `Architecture` cannot be `CONDITIONAL YES`.
  - `Linting compliance` cannot be `CONDITIONAL YES`.
  - Any lint allowlist creation/expansion is an automatic `NO`.
- Produce the same output structure defined in the Cursor skill.
- Post a PR comment containing the complete review findings (all criterion outcomes, evidence, violations/gaps, and conclusion), not just local/chat output.
- Use GitHub CLI to publish the comment, e.g. `gh pr comment <number-or-url> --body "$(cat <<'EOF' ... EOF )"`.

## Required reference

Before reviewing, read and apply:

- `.cursor/skills/review-pr/SKILL.md`
