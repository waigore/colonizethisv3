---
name: fix-pr
description: Diagnoses and unblocks a pull request by checking PR status, failing checks, quality gates, and merge conflicts, then applying the minimal compliant fix and verifying results. Use when the user provides a PR URL or PR number and asks to fix or unblock the PR.
---

# Fix PR checks (ColonizeThis)

PR number or URL. If repo/owner are ambiguous, ask once. Conventions: [shared.md](../shared.md). Commands: [reference.md](reference.md).

## Constraints

- Minimal fixes for failures that block checks. No opportunistic refactors. No quality-gate bypass. Do not weaken surface-budget tests.
- SPEC-first: unspecified behavior → update specs first.
- Conflicts: hunk-by-hunk. Prefer **base** for newer SPEC/policy/workflow; prefer **PR branch** for the issue’s intended behavior when still SPEC-compliant; combine when needed.

## Workflow

1. Read PR metadata, checks, comments, `.github/workflows/` (source of check names). Prioritize `quality` and `quality_app_coverage`.
2. Resolve merge conflicts if present (judgment above). No leftover conflict markers.
3. Reproduce locally (failing or closest command). Confirm root cause before editing.
4. Smallest file set that unblocks. Reuse existing patterns.
5. Re-run failing checks / local equivalents; confirm mergeable vs base.
6. Report:

```markdown
PR: <number/url>
Failures found:
- <check>: <reason>
Conflicts found:
- <file>: <why>
Fix applied:
- ...
Mergeability: <mergeable / still conflicting>
Verification:
- <command> -> <result>
Status:
- <unblocked / partially unblocked>
- <remaining blockers, if any>
```
