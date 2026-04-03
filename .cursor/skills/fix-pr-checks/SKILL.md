---
name: fix-pr-checks
description: Diagnoses and unblocks a pull request by checking PR status, failing checks, and quality gates, then applying the minimal compliant fix and verifying results. Use when the user provides a PR URL or PR number and asks to fix or unblock the PR.
---

# Fix PR checks (ColonizeThis)

## When this applies

Apply this skill when the user gives a GitHub pull request reference:

- PR number (for example `123`)
- Full PR URL

If repo/owner are ambiguous, ask once for clarification before making changes.

## Non-negotiables (repo policy)

Follow project rules in `AGENTS.md`, `.cursor/rules/`, and `CONTRIBUTING.md`.

Hard constraints:

- Keep fixes minimal and scoped to failures that block checks.
- Do not introduce behavior outside SPEC authorization. If needed behavior is not specified, update specs first.
- Preserve architecture boundaries (Flutter UI vs Flame simulation, event bus usage, strict typing, logging policy).
- Do not bypass quality gates or test expectations to force green checks.

## Workflow

1. **Resolve PR context**
   - Read PR metadata, status, changed files, comments, and check runs.
   - Treat `.github/workflows/` as the source of truth for required checks and job names.
   - Prioritize failures in the quality workflows, especially `quality` and `quality_app_coverage` (`App coverage (merge shards)`), and identify exact failure reasons (lint, test, type, build, policy, merge-base drift).

2. **Reproduce locally (targeted)**
   - Run only the failing or closest equivalent local commands first.
   - Confirm root cause before editing.

3. **Apply minimal fix**
   - Prefer reusing existing patterns/utilities over adding new abstractions.
   - Touch the smallest set of files required to unblock failures.
   - Keep unrelated refactors out of scope.

4. **Verify fix addresses the PR issue**
   - Re-run the failing checks (or local equivalents derived from workflow steps) and confirm pass.
   - Run any directly impacted tests and static analysis.
   - Confirm no new failures were introduced.

5. **Report result clearly**
   - State what failed, root cause, and what changed.
   - Provide verification evidence (commands/tests/checks).
   - Call out any residual risk or checks that still need remote CI confirmation.

## Output format

Use this concise structure:

```markdown
PR: <number/url>

Failures found:
- <check>: <failure reason>

Fix applied:
- <minimal change summary>

Verification:
- <command/check> -> <result>
- <command/check> -> <result>

Status:
- <unblocked / partially unblocked>
- <remaining blockers, if any>
```

## Additional resources

- [reference.md](reference.md) for command patterns and a minimal-fix checklist
