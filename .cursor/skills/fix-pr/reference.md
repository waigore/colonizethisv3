# PR fix reference

```bash
gh pr view <number> --json number,title,url,state,baseRefName,headRefName,isDraft,mergeStateStatus
gh pr checks <number>
gh pr view <number> --json files,commits,statusCheckRollup
```

Map failing checks to `.github/workflows/` jobs. For this repo:

- `quality.yml` → `quality` → `melos run quality` (or workflow-equivalent)
- `quality.yml` → `quality_app_coverage` (`App coverage (merge shards)`) → `(cd app && flutter test --coverage --reporter=compact -j 1 --no-track-widget-creation)` then `tool/check_coverage_threshold.sh 80 app`

If both fail, fix `quality` first, then coverage. Re-run the failing gate after the fix.
