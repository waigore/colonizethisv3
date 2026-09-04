# Agent instructions (ColonizeThis)

Cursor rules are the source of truth for implementation and review behavior.

## Rule location

- Path: `.cursor/rules/`
- Format: Markdown `.mdc` with front matter (`description`, optional `globs`, `alwaysApply`)
- Routing index: `.cursor/rules/routing-index.md` (applicability and precedence only)

## Always-applied rules

| Rule file | Focus |
|-----------|-------|
| `colonizethis-spec-required.mdc` | SPEC-first workflow and source-of-truth boundaries |
| `colonizethis-core-principles.mdc` | Dart/Flutter/Flame coding principles and architecture boundaries |
| `colonizethis-logging-file.mdc` | Required file logging approach (`basic_logger_file`) |
| `colonizethis-logic-ai-decoupling.mdc` | Enforces one-way architecture boundary between `colonizethis_logic` and `colonizethis_ai` |
| `colonizethis-turn-resolution-budget.mdc` | Hard 15-second next-turn resolution usability budget |
| `colonizethis-ui-surface-budget.mdc` | Hard 1-second game-app panel/dialog open budget + dispose unused UI |
| `colonizethis-agent-run-cleanup.mdc` | Delete logs/coverage/CLI artifacts after agent-run verbose commands |

## Context-specific rules

| Rule file | Applies to | Focus |
|-----------|------------|-------|
| `colonizethis-tools.mdc` | `tool/**` | Thin facades + Melos execution + docs |
| `colonizethis-testing.mdc` | `**/*_test.dart`, `**/test/**/*.dart`, `**/integration_test/**/*.dart` | Test layers, critical paths, coverage policy |
| `colonizethis-e2e-ui-stability.mdc` | `**/integration_test/**/*.dart`, `**/*_e2e_test.dart` | UI e2e stability: deterministic locators and visibility-first interactions |
| `colonizethis-ui-documentation.mdc` | `SPEC/ui/**`, screen/dialog Dart under `app/lib/features/**`, `ui_screen_ids.dart` | Definitive screen docs: stable IDs, layout/behavior/variants, Widgetbook contracts |
| `colonizethis-ui-design.mdc` | `SPEC/ui/**`, `**/lib/widgets/**`, `**/lib/ui/**` | UI style, mobile viewports, Widgetbook registration, pixel-art process (orthogonal to screen structure) |
| `colonizethis-component-structure.mdc` | `app/lib/**/*.dart`, `packages/*/lib/**/*.dart`, `tool/**/*.dart` | Folder conventions, extraction/reuse, naming |
| `colonizethis-code-review.mdc` | `app/lib/**/*.dart`, `packages/*/lib/**/*.dart`, `tool/**/*.dart` | Review checklist and quality gates |
| `colonizethis-lifecycle.mdc` | `app/lib/game/**/*.dart`, `app/lib/widgets/**/*.dart`, `app/lib/ui/**/*.dart`, `app/lib/screens/**/*.dart`, `app/lib/pages/**/*.dart`, `app/lib/features/**/*.dart` | Flame/Flutter lifecycle conventions |
| `colonizethis-assets.mdc` | `**/pubspec.yaml`, `**/assets/**`, targeted asset-loading Dart files | Asset structure, naming, loading |
| `colonizethis-acceptance-criteria.mdc` | `SPEC/ai/**`, `SPEC/game/**`, `SPEC/program/**`, `SPEC/ui/**` | Given–When–Then, testable AC quality |
| `colonizethis-game-manual.mdc` | `docs/manual/**`, `SPEC/game/**`, `SPEC/ui/**`, allowlisted `SPEC/program/` order/turn files | Player game manual: required when player UX/gameplay changes; issue planning, implementation, PR review |

## Rule interaction

Multiple context-specific rules may apply to a single file (e.g., a UI widget may match both `ui-design` and `component-structure`). All applicable rules are **additive**; when they conflict, the more specific rule takes precedence (e.g., testing rules override general code-review for test files).

## Routing reference

- Use `.cursor/rules/routing-index.md` to determine applicability and precedence.
- Treat `.cursor/rules/*.mdc` files as the only normative policy source.
- Keep this file and OpenCode references pointer-based; avoid duplicating normative rule text.

For complete details, read the relevant rule file(s) in `.cursor/rules/`.

## Project agent skills

Skills live under `.cursor/skills/<name>/SKILL.md` (source of truth). Shared conventions: `.cursor/skills/shared.md`. Grok and OpenCode use thin shims at `.grok/skills/<name>/` and `.opencode/skills/<name>/` that only point at the Cursor files — do not copy workflow into those shims. When a skill matches the task, read and follow the Cursor `SKILL.md` (and any `reference.md` or sibling it names).

| Skill | Use when |
|-------|----------|
| `create-github-issue` | Informal report → structured issue (read-only; numbered clarifications with the user first). |
| `refactoring-opportunity-github-issue` | Scan `app/` or one `packages/*` on `origin/dev`; de-dupe; file a focused refactor issue. |
| `refactor-analysis-agent` | Autonomously pick one target and run `refactoring-opportunity-github-issue`. |
| `clean-local-branches` | Prune local branches; keep `dev` and open-PR heads; never delete remotes. |
| `consolidate-prs` | Collapse multiple open PRs for the same issue; then cancel orphan PR workflow runs. |
| `fix-pr` | Unblock a PR (failing checks, conflicts). |
| `manage-pr-agent` | One pass: one PR per issue, CI quota of 2, never wait. |
| `implement-github-issue` | Implement an issue; tests; one PR to `dev` with `Refs #N` (does not auto-close). |
| `interpret-ai-traces` | Explain deterministic AI orders/perf from a merged turn-trace JSON. |
| `merge-dev-into-android-build` | Merge `dev` into `build/app/android` for APK workflows. |
| `backlog-implement-agent` | Throughput on `backlog:implementation` (multi-issue; never wait). |
| `backlog-review-agent` | One `backlog:review` issue → `review-github-issue` → relabel. |
| `backlog-refine-agent` | One `backlog:refinement` issue → `refine-github-issue` → relabel. |
| `backlog-verify-agent` | One `backlog:verification` issue → `verify-github-issue` → relabel. |
| `backlog-accept-agent` | One `backlog:acceptance` issue → `accept-github-issue` → relabel. |
| `plan-feature` | Scope a feature (read-only) and file a capturing issue. |
| `suggest-player-ux-improvements` | One player-UX improvement in chat; read-only; no filing. |
| `improve-ux-agent` | Autonomously suggest one UX improvement and file it (no clarifications). |
| `refine-github-issue` | Apply comment feedback to an issue body, or numbered questions if it conflicts with SPEC. |
| `review-pr` | Merge-readiness review with YES/CONDITIONAL YES/NO; post as a PR comment. |
| `review-github-issue` | Purpose↔method review before implementation (interactive posting). |
| `verify-github-issue` | AC/SPEC/test verification on merged `dev`; comment only. |
| `accept-github-issue` | Product acceptance on a named issue; comment only. |
| `document-app-ui` | Screen IDs, `SPEC/ui/`, Widgetbook, `UiScreenIds`. |
| `update-game-manual` | Player handbook chapters when UX/gameplay changes. |
| `review-game-manual-agent` | Review one handbook chapter; file an alignment issue. |
| `export-player-manual` | Regenerate `docs/manual/player-export/`. |
| `player-playthrough` | Bounded Marionette playtests against the player export. |

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for contribution guidelines.
