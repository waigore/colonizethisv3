# Reference: implement-github-issue

## CONTRIBUTING (summary)

- PRs only; default base branch **`dev`**.
- Pre-PR: SPEC/ACs updated; tests aligned; logging annexes if logging changed; coverage gates (90% / 80%).

## PR body and auto-close

GitHub closes issues when the PR description or merge commit contains certain keywords **immediately before** the issue reference (e.g. `Fixes #123`, `Closes #123`). Prefer:

- `Refs #123`
- `Related: #123` (verify wording does not trigger close—when unsure, use `Refs`.)

## Example `gh` workflow

```bash
git fetch origin
git checkout dev
git pull origin dev
git checkout -b fix/issue-123-short-description

# … commit work …

git push -u origin fix/issue-123-short-description

gh pr create --base dev --head fix/issue-123-short-description \
  --title "fix: short imperative description (#123)" \
  --body "## Summary
…

## Acceptance criteria (this PR)
- …

## SPEC
- …

## Tests
- …

Refs #123"
```

For large issues, add commits to the **same open** branch and use `gh pr view` / `gh pr edit` to refresh the body. **Do not** open a **second simultaneous** PR for the same issue. If the first PR **merges early** while the issue still needs work, branch from current **`dev`** and `gh pr create` **one** successor PR for the remaining slices. Same rule if the user explicitly replaces a broken PR: only one open PR for that issue at a time.

Adjust flags if the repo uses a fork or different default remote.

## Testing pointers

- Follow **`colonizethis-testing.mdc`** and **`AGENTS.md`** for package-specific commands (`melos run …`, `flutter test` paths).
- Run the narrowest failing command first, then widen to gates the user or CI cares about.
