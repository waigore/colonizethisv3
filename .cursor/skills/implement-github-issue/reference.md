# Reference: implement-github-issue

Conventions: [shared.md](../shared.md). Testing commands: `colonizethis-testing.mdc` / AGENTS.md.

```bash
git fetch origin
git checkout dev
git pull origin dev
git checkout -b fix/issue-123-short-description
# … commit …
git push -u origin fix/issue-123-short-description

gh pr create --base dev --head fix/issue-123-short-description \
  --title "fix: short imperative description (#123)" \
  --body-file /tmp/pr-body.md
```

PR body must include `Refs #123`. Later slices: push to the same branch; `gh pr edit` to refresh the body. After an early merge, one successor PR from current `dev`.
