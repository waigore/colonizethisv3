# Reference: verify-github-issue

## CONTRIBUTING (summary)

- PRs via Pull Request only; **default target branch: `dev`**.
- Pre-PR: SPEC/ACs updated; implementation and tests aligned; logging aligned if logging changed; coverage gates (90% / 80%).

Source: repo root `CONTRIBUTING.md`.

## AGENTS (summary)

- `.cursor/rules/*.mdc` are the implementation/review source of truth.
- SPEC-first; coverage and test commands per `colonizethis-testing.mdc`; acceptance criteria quality per `colonizethis-acceptance-criteria.mdc`.

Source: repo root `AGENTS.md`.

## Example `gh` commands

```bash
# View issue (JSON for scripting)
gh issue view 42 --json title,body,state,labels,url

# Post verification result as an issue comment (user must be logged in)
gh issue comment 42 --body-file verification.md
# or: gh issue comment 42 --body "$(cat verification.md)"
```

Replace `42` with the issue number; run from a clone of the repo with `gh auth login` completed. This skill’s GitHub write is the comment only.
