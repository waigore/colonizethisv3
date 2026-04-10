# Contributing to ColonizeThis

## Contribution Process

All contributions must be submitted via a Pull Request (PR).

## Branching

- **Default target branch**: `dev`
- Unless explicitly required, PRs should target `dev` rather than `main` or other branches.

## Pre-PR Checklist

Before opening a pull request, ensure the following:

- [ ] **Specs and ACs updated**: I have updated the relevant SPEC documents and acceptance criteria to reflect the changes.
- [ ] **Implementation aligned**: I have aligned the implementation (and tests) with the updated specs and ACs.
- [ ] **Logging aligned**: If the change adds or alters logging (messages, levels, prefixes, or new emissions such as game events), I have checked it against **[SPEC/program/logging/logging.md](./SPEC/program/logging/logging.md)** and the relevant annexes ([map-generation](./SPEC/program/logging/map-generation.md), [turn-resolution](./SPEC/program/logging/turn-resolution.md), [ai-actions](./SPEC/program/logging/ai-actions.md), [events](./SPEC/program/logging/events.md)) and against host sink specs where applicable ([ctdev-logging.md](./SPEC/program/ctdev-logging.md), [debug-log-viewer.md](./SPEC/program/debug-log-viewer.md), [test-logging.md](./SPEC/program/test-logging.md)).
- [ ] **Coverage quality gate met**: I have ensured that test coverage meets the project's quality gate requirements (90% for logic/ai/map packages; 80% elsewhere).

## Repo convention lint

Repository-wide checks (beyond `dart analyze` / `custom_lint`) run through **`dart run tool/ct_repo_lint.dart`**, driven by **`tool/ct_repo_lint_manifest.yaml`**. When adding a new convention for CI, register a **stable `rule_id`** there and document it in **[SPEC/program/repo-lint.md](./SPEC/program/repo-lint.md)**—avoid new standalone `tool/check_*.dart` workflow steps without updating that manifest.

## Additional Resources

- [AGENTS.md](./AGENTS.md) — Agent instructions and cursor rules for this project
