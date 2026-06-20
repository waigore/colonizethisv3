# Contributing to ColonizeThis

## Process

- All contributions go through a Pull Request.
- **Default target branch:** `dev` (not `main`).

## Toolchain

Match CI: **Flutter `3.41.9`** stable, which bundles **Dart `3.11.5`**. For advisories handling, intentional dependency caps, and the workspace outdated audit see **[SPEC/program/pub-workspace-toolchain.md](./SPEC/program/pub-workspace-toolchain.md)**. For local macOS Flutter builds failing with `SwiftDriver.ModuleDependencyGraph.ReadError`, see **[SPEC/program/macos-flutter-build-recovery.md](./SPEC/program/macos-flutter-build-recovery.md)**.

## Pre-PR checklist

- [ ] **Specs and ACs updated** to reflect the change.
- [ ] **Implementation aligned** with the updated specs and ACs (including tests).
- [ ] **Logging aligned** with [SPEC/program/logging/logging.md](./SPEC/program/logging/logging.md) and the relevant annexes ([map-generation](./SPEC/program/logging/map-generation.md), [turn-resolution](./SPEC/program/logging/turn-resolution.md), [ai-actions](./SPEC/program/logging/ai-actions.md), [events](./SPEC/program/logging/events.md)) and host sink specs ([ctdev-logging](./SPEC/program/ctdev-logging.md), [debug-log-viewer](./SPEC/program/debug-log-viewer.md), [test-logging](./SPEC/program/test-logging.md)) when logging changes.
- [ ] **Coverage** meets the project quality gate (90% for logic / ai / map packages; 80% elsewhere).

## UI changes: verification screenshot

When a PR addresses a UI-related issue (anything user-visible — Flutter or Flame screens, map or tile rendering, dialogs, controls, typography, spacing, or pixel-art presentation), post a screenshot of the fixed or intended behavior on the **linked issue before it is closed**, or in the **PR description** if there is no linked issue. Reviewers may treat missing visual evidence as blocking when the change is not already covered by golden or e2e visual checks.

## Repo conventions

Repository-wide checks beyond `dart analyze` / `custom_lint` run via `dart run tool/ct_repo_lint.dart`. To register or change a rule, see **[SPEC/program/repo-lint.md](./SPEC/program/repo-lint.md)**.

## See also

- [AGENTS.md](./AGENTS.md) — Agent instructions and cursor rules for this project.
