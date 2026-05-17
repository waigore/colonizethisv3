---
name: fix-pr
description: Diagnoses and unblocks a pull request by checking PR status, failing checks, quality gates, and merge conflicts, then applying the minimal compliant fix and verifying results. Use when the user provides a PR URL or PR number and asks to fix or unblock the PR.
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
- Resolve conflicts deliberately per hunk (not one global strategy). Use judgment to prefer either base (`dev`) or PR branch changes based on SPEC alignment, correctness, and lowest-risk unblock path.

## Workflow

1. **Resolve PR context**
   - Read PR metadata, status, changed files, comments, and check runs.
   - Treat `.github/workflows/` as the source of truth for required checks and job names.
   - Prioritize failures in the quality workflows, especially `quality` and `quality_app_coverage` (`App coverage (merge shards)`), and identify exact failure reasons (lint, test, type, build, policy, merge-base drift, merge conflicts).

2. **Check and resolve merge conflicts (when present)**
   - Determine whether the PR has merge conflicts before or alongside check failures.
   - Resolve conflicts hunk-by-hunk using engineering judgment:
     - Prefer **base (`dev`)** when it contains newer SPEC-authorized architecture/policy updates, logging/lint/test standards, or required workflow compatibility.
     - Prefer **PR branch** when it carries the intended issue fix/feature behavior and remains SPEC-compliant.
     - Combine both sides when needed to preserve behavior and compatibility.
   - After resolving each file, ensure code compiles logically (imports, symbols, null-safety, tests) and no conflict markers remain.
   - Keep conflict resolution minimal; avoid opportunistic refactors.

3. **Reproduce locally (targeted)**
   - Run only the failing or closest equivalent local commands first.
   - Confirm root cause before editing.

4. **Apply minimal fix**
   - Prefer reusing existing patterns/utilities over adding new abstractions.
   - Touch the smallest set of files required to unblock failures.
   - Keep unrelated refactors out of scope.

5. **Verify fix addresses the PR issue**
   - Re-run the failing checks (or local equivalents derived from workflow steps) and confirm pass.
   - Run any directly impacted tests and static analysis.
   - Confirm no new failures were introduced.
   - Confirm the branch is now mergeable (no remaining conflicts against base).

6. **Report result clearly**
   - State what failed, root cause, and what changed.
   - For conflicts, briefly justify why base vs PR changes were chosen.
   - Provide verification evidence (commands/tests/checks).
   - Call out any residual risk or checks that still need remote CI confirmation.

## Output format

Use this concise structure:

```markdown
PR: <number/url>

Failures found:
- <check>: <failure reason>

Conflicts found:
- <file>: <why conflict occurred>

Fix applied:
- <minimal change summary>
- <conflict resolution summary (base vs PR rationale)>

Mergeability:
- <mergeable / still conflicting>

Verification:
- <command/check> -> <result>
- <command/check> -> <result>

Status:
- <unblocked / partially unblocked>
- <remaining blockers, if any>
```

## Additional resources

- [reference.md](reference.md) for command patterns and a minimal-fix checklist
