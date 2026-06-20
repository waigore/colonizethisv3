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
- `UI visual fidelity` may resolve to `CONDITIONAL YES` only for explicitly deferred per-screen visual polish that the PR comment links to a sibling alignment issue; Material-chrome violations and hardcoded light-theme colors are always `NO`.
- Lint allowlist additions/expansions are disallowed and count as linting non-compliance.

## Required checklist

Evaluate these criteria in order:

1. **Alignment with issue**
   - Does implementation satisfy the issue requirements and design constraints?
2. **AC coverage**
   - Do tests in the PR cover acceptance criteria defined by the issue?
3. **Architecture**
   - Does implementation align with existing coding and architecture conventions, especially `.cursor/rules/` constraints?
4. **Linting compliance**
   - Does the PR comply with all linting rules without adding/changing allowlists?
5. **UI visual fidelity** (apply only when the PR touches app UI — widgets, screens, dialogs, overlays, theme, or Widgetbook stories)
   - Do Widgetbook stories render under `AppThemes.editorialMonocle` without functional regressions (crashes, missing widgets, layout breakage)?
   - Are user-facing surfaces free of Material chrome (no `ElevatedButton`, `AlertDialog`, `Card`, `ChoiceChip`, etc. per `SPEC/ui/pixel-art-ui-catalog.md` § Material design ban) and built only from the Ct-* catalog?
   - Do color values match the canonical editorial-monocle palette in `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette — no hardcoded light-theme colors (parchment `#F5F5DC`, raw Material primaries) sneaking into theme/widget code?
   - Per-screen visual polish (washed-out text, contrast tuning, residual parchment-colored regions inside a specific widget) is **tracked in sibling per-screen alignment issues** and is **not** a blocker on this criterion; only crashes, functional regressions, Material-chrome violations, and hardcoded light-theme colors are.

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
   - For criteria eligible for conditional handling (`Alignment with issue`, `AC coverage`, and `UI visual fidelity` for deferred per-screen polish only), upgrade `NO` to `CONDITIONAL YES` only if the PR discussion explicitly and concretely documents the gap and follow-up.
   - Never apply conditional handling to `Architecture` or `Linting compliance`. For `UI visual fidelity`, never apply conditional handling to Material-chrome violations or hardcoded light-theme colors.
   - If the PR does **not** touch app UI, mark `UI visual fidelity` as `N/A` and explain briefly.

4. **Explain failures precisely**
   - For every `NO` or `CONDITIONAL YES`, list concrete evidence:
     - missing requirement/AC mapping
     - uncovered AC test scenario(s)
     - architecture rule or pattern conflict
     - lint rule failures or allowlist changes

5. **Return merge-readiness**
   - PR is fully compliant only when every applicable criterion is `YES` (treat `N/A` for `UI visual fidelity` on non-UI PRs as compliant).
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
- UI visual fidelity: YES | CONDITIONAL YES | NO | N/A
  - Evidence: <dark-theme adherence, Ct-* catalog use, palette match against `SPEC/ui/pixel-art-ui-catalog.md`, or `N/A: non-UI PR`>

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
