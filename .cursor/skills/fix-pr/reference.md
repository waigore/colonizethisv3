# PR fix reference

Use these as defaults; adapt to the repository state and failing check names.

## PR inspection commands

```bash
gh pr view <number> --json number,title,url,state,baseRefName,headRefName,isDraft,mergeStateStatus
gh pr checks <number>
gh pr view <number> --json files,commits,statusCheckRollup
```

If the user provided a URL, extract the PR number first.

## Workflow-first gate resolution

Do not hardcode check names from memory. Read `.github/workflows/` and map failing PR checks to workflow jobs.

For this repository, pay special attention to:

- `quality.yml` -> `quality` job
- `quality.yml` -> `quality_app_coverage` job (`App coverage (merge shards)`)

Use workflow steps to derive the closest local verification commands.

## Fast path: copy/paste checks

Use this sequence first for quick PR triage:

```bash
# 1) Inspect failing checks on the PR
gh pr checks <number>

# 2) If quality failed, run the main local quality gate
melos run quality

# 3) If app coverage failed, run app tests with coverage and threshold gate
(cd app && flutter test --coverage --reporter=compact -j 1 --no-track-widget-creation)
tool/check_coverage_threshold.sh 80 app
```

If step 2 is unavailable in local scripts, derive equivalent commands from `.github/workflows/quality.yml` job steps.

## Decision tree (quality vs app coverage)

1. `gh pr checks <number>`  
2. If failing check maps to `quality`:
   - Run local quality gate (`melos run quality` or workflow-equivalent commands).
   - Fix only the failing gate root cause.
   - Re-run the same gate.
3. If failing check maps to `quality_app_coverage` (`App coverage (merge shards)`):
   - Regenerate app coverage locally.
   - Run `tool/check_coverage_threshold.sh 80 app`.
   - If below threshold, add/adjust the minimal tests needed to lift covered lines.
4. If both fail:
   - Fix `quality` first, then app coverage, then re-run both.

## Local triage order

1. Reproduce the failing check locally (preferred).
2. If check command is unknown, inspect `.github/workflows/` and infer the closest local command from the failing job steps.
3. Fix only what is required for the failing gate.
4. Re-run the failing check and impacted tests.

## Minimal-fix checklist

- Root cause is identified and confirmed.
- Only necessary files changed.
- No speculative refactor.
- Spec alignment preserved.
- Tests/analysis relevant to the failing gate are green locally.
- Final summary explicitly states whether PR is fully unblocked.
