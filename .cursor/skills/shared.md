# Shared skill conventions (ColonizeThis)

One home for facts that used to be copied into every skill. Skills point here instead of restating.

## Repo policy

Follow **[AGENTS.md](../../AGENTS.md)**, **[CONTRIBUTING.md](../../CONTRIBUTING.md)**, and the matching `.cursor/rules/*.mdc` files. Routing: [`.cursor/rules/routing-index.md`](../rules/routing-index.md).

Do not restate those files. In particular, do not copy SPEC-first layout, coverage numbers, the 1 s UI surface budget, logging policy, or architecture boundaries into a skill — name the rule or SPEC and move on.

## PRs and issues

- Default PR base is **`dev`** unless the skill or user says otherwise.
- At most **one open PR per GitHub issue**. Further slices are commits on that PR (or a successor PR only after the previous one merged).
- PR title: conventional-commit type prefix (`fix`, `feat`, `refactor`, `docs`, `chore`, `test`, `perf`, `ci`). Prefer `fix` for defects (not `bug:`).
- Do **not** auto-close issues. Use **`Refs #N`** in the PR body. Never `Fixes` / `Closes` / `Resolves #N`.
- Never close issues from a skill unless that skill’s job is explicitly to close redundant **PRs** (`consolidate-prs`).
- Never delete **remote** branches. Local pruning is `clean-local-branches`.
- Never bypass required checks. Never force-push to a branch this agent did not create.

## Follow-up skills (point, don’t copy)

| Concern | Skill / rule |
|---------|----------------|
| Player-app screen / dialog / overlay docs | `document-app-ui` + `colonizethis-ui-documentation.mdc` |
| Player UX / gameplay copy in `docs/manual/` | `update-game-manual` + `colonizethis-game-manual.mdc` |
| Game-app 1 s full-load + dispose | `colonizethis-ui-surface-budget.mdc`, `SPEC/program/ui-surface-budget.md` |
| UI visual style / Ct-* / palette | `colonizethis-ui-design.mdc`, `SPEC/ui/pixel-art-ui-catalog.md` |

## `gh` usage

- Run from the repository root.
- Write markdown bodies to a temp file; use `--body-file`.
- If `gh` is missing, unauthenticated, or fails: return the prepared title/body/commands for manual follow-up. Do not guess API results.

## Label edits

Re-read labels immediately before editing. Apply the intended final state idempotently. Never leave both the source label and the destination label on the issue.
