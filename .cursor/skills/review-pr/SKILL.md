---
name: review-pr
description: Reviews an open pull request against issue alignment, acceptance-criteria test coverage, architecture conventions, and linting compliance with strict YES/NO outcomes. Use when the user asks to review, audit, or gate a PR for merge readiness.
---

# Review PR (ColonizeThis)

## When this applies

Apply this skill when the user asks to review an open PR (by number or URL) and determine whether it is merge-ready under strict repository standards.

## Non-negotiables

Follow `AGENTS.md`, `CONTRIBUTING.md`, and applicable rules in `.cursor/rules/`.

Hard constraints:

- Every criterion must resolve to exactly one of: `YES`, `CONDITIONAL YES`, or `NO`.
- `YES` requires full compliance for the criterion.
- Any gap, inconsistency, or violation resolves to `NO`, except the conditional policy below.
- `CONDITIONAL YES` is allowed only when the PR is partially complete **and** the PR comment explicitly documents remaining gaps and planned follow-up.
- `Architecture` and `Linting compliance` are non-negotiable: if violations exist, they must resolve to `NO` (never `CONDITIONAL YES`).
- Lint allowlist additions/expansions are disallowed and count as linting non-compliance.

## Required checklist

Evaluate these four criteria in order:

1. **Alignment with issue**
   - Does implementation satisfy the issue requirements and design constraints?
2. **AC coverage**
   - Do tests in the PR cover acceptance criteria defined by the issue?
3. **Architecture**
   - Does implementation align with existing coding and architecture conventions, especially `.cursor/rules/` constraints?
4. **Linting compliance**
   - Does the PR comply with all linting rules without adding/changing allowlists?

## Review workflow

1. **Resolve scope**
   - Load PR metadata, description, changed files, commits, checks, and discussion.
   - Resolve linked issue(s) and extract requirements, design constraints, and ACs.

2. **Collect evidence**
   - Inspect changed code and tests.
   - Verify CI/check outputs for lint/test/quality signals.
   - Cross-check architecture choices against project rules and established patterns.

3. **Score each criterion strictly**
   - Start each criterion at `YES`.
   - Downgrade to `NO` on any detected gap/violation.
   - For criteria eligible for conditional handling (`Alignment with issue`, `AC coverage` only), upgrade `NO` to `CONDITIONAL YES` only if the PR discussion explicitly and concretely documents the gap and follow-up.
   - Never apply conditional handling to `Architecture` or `Linting compliance`.

4. **Explain failures precisely**
   - For every `NO` or `CONDITIONAL YES`, list concrete evidence:
     - missing requirement/AC mapping
     - uncovered AC test scenario(s)
     - architecture rule or pattern conflict
     - lint rule failures or allowlist changes

5. **Return merge-readiness**
   - PR is fully compliant only when all four criteria are `YES`.
   - Any `NO` means not merge-ready.
   - `CONDITIONAL YES` means intentionally partial and documented, but not full compliance.

6. **Post findings to the PR**
   - Post the full review output as a PR comment (do not keep findings only in local/chat output).
   - Use GitHub CLI, e.g. `gh pr comment <number-or-url> --body "$(cat <<'EOF' ... EOF )"`.
   - The PR comment must include every criterion result, all evidence bullets, all violations/gaps, and the final merge-readiness conclusion.

## Output format

Use this exact structure:

```markdown
PR: <number/url>
Issue: <number/url or "not linked">

Checklist:
- Alignment with issue: YES | CONDITIONAL YES | NO
  - Evidence: <concise proof or violation list>
- AC coverage: YES | CONDITIONAL YES | NO
  - Evidence: <concise proof or violation list>
- Architecture: YES | NO
  - Evidence: <rule/pattern alignment or violation list>
- Linting compliance: YES | NO
  - Evidence: <lint status and confirmation no allowlist changes>

Violations / Gaps:
- <clear, specific item>
- <clear, specific item>

Conclusion:
- Merge readiness: READY | NOT READY
- Rationale: <1-3 lines>
```

After generating this output, publish it as a PR comment verbatim (or with only minimal formatting adjustments that preserve all findings).

## Quality bar

- Do not infer compliance from intent; require concrete evidence.
- Prefer explicit requirement/AC-to-code-and-test mapping.
- Treat undocumented partial work as `NO`, not `CONDITIONAL YES`.
- When uncertain, resolve to `NO` and state what evidence is missing.
