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
| `colonizethis-lifecycle.mdc` | `app/lib/game/**/*.dart`, `app/lib/widgets/**/*.dart`, `app/lib/ui/**/*.dart`, `app/lib/screens/**/*.dart`, `app/lib/pages/**/*.dart` | Flame/Flutter lifecycle conventions |
| `colonizethis-assets.mdc` | `**/pubspec.yaml`, `**/assets/**`, targeted asset-loading Dart files | Asset structure, naming, loading |
| `colonizethis-acceptance-criteria.mdc` | `SPEC/ai/**`, `SPEC/game/**`, `SPEC/program/**`, `SPEC/ui/**` | Given–When–Then, testable AC quality |

## Rule interaction

Multiple context-specific rules may apply to a single file (e.g., a UI widget may match both `ui-design` and `component-structure`). All applicable rules are **additive**; when they conflict, the more specific rule takes precedence (e.g., testing rules override general code-review for test files).

## Routing reference

- Use `.cursor/rules/routing-index.md` to determine applicability and precedence.
- Treat `.cursor/rules/*.mdc` files as the only normative policy source.
- Keep this file and OpenCode references pointer-based; avoid duplicating normative rule text.

For complete details, read the relevant rule file(s) in `.cursor/rules/`.

## Project agent skills

Skills live under `.cursor/skills/<name>/SKILL.md`. When a skill matches the task, read and follow it.

| Skill | Use when |
|-------|----------|
| `create-github-issue` | Turn an informal bug/report into a structured GitHub issue after read-only SPEC/code analysis and mandatory numbered requirement clarifications with the user (read-only repo work; may use `gh`). UI-related issues should cite screen specs and point implementers to `document-app-ui`. OpenCode: `.opencode/skills/create-github-issue/`. |
| `refactoring-opportunity-github-issue` | Scan `app/` or one `packages/*` package on latest `origin/dev`, de-duplicate against open GitHub issues, match `.cursor/rules`, propose focused refactors + CI (extend existing AST/analyzer gates first), draft/file a structured issue. UI refactors note `document-app-ui` for spec/registry/Widgetbook. OpenCode: `.opencode/skills/refactoring-opportunity-github-issue/`. |
| `clean-local-branches` | Prune local branch refs, keeping `dev` and open-PR heads; never delete remote branches. |
| `consolidate-prs` | Collapse multiple open PRs that target the same issue into one PR (strict `fix-pr` first for stalled PRs), then forcibly cancel in-progress GitHub Actions runs no longer attached to any open PR. OpenCode copy under `.opencode/skills/` defers to the Cursor skill. |
| `fix-pr` | Unblock a PR by fixing failing checks and quality gates. |
| `manage-pr-agent` | One orderly pass over open PRs: enforce one PR per issue via `consolidate-prs` and maintain a running-CI quota of 2 PRs (both floor and ceiling) — pause excess via `[skip ci]` empty commits plus cancelling their in-flight runs, and when below quota, resume paused PRs or unblock stalled PRs (oldest first) via `fix-pr`. Never waits for CI/merges. |
| `implement-github-issue` | User gives an issue **#** or **URL**; validate problem/design/testable ACs, update **SPEC** if needed, implement, add positive/negative tests, open PR to **`dev`** with **`Refs #…`** (do **not** auto-close). Very large issues: one isolatable slice only. |
| `interpret-ai-traces` | Interpret full-AI turn-trace JSON (`run_observer_game` or app/ctdev exports) to explain deterministic AI behavior — phase, goal, phase plan, domain gates, emitted orders, resolver events — and to spot 15 s next-turn-budget regressions. Use when a user asks why the AI did/did not do X on turn N, or supplies a merged turn trace to diagnose. OpenCode: `.opencode/skills/interpret-ai-traces/`. |
| `merge-dev-into-android-build` | Merge `dev` into `build/app/android` for APK build workflows. |
| `backlog-implement-agent` | Optimize code throughput across open `backlog:implementation` issues; a run may touch multiple issues but each PR targets exactly one. Prefer unblocking stalled PRs (oldest first) via strict `fix-pr` before opening new work for that issue, then move on—**never wait** for CI, reviews, or merges. Apply strict `implement-github-issue` for new work; relabel to `backlog:verification` only when an issue is fully done and all its PRs are merged. |
| `backlog-review-agent` | Pick one open issue labeled `backlog:review`, run strict `review-github-issue` analysis, comment findings, then relabel to `backlog:implementation` (pass) or `backlog:refinement` (fail). |
| `backlog-refine-agent` | Pick one open issue labeled `backlog:refinement`, run strict `refine-github-issue` updates against comment feedback, then relabel to `backlog:review` (resolved) or `backlog:clarification` (uncertain). |
| `backlog-verify-agent` | Pick one open issue labeled `backlog:verification`, run strict `verify-github-issue` verification, post findings, then relabel to `backlog:acceptance` (complete) or `backlog:implementation` (gaps remain). |
| `plan-feature` | Scope a feature from SPEC/code (read-only), then open a capturing issue—no implementation. UI features plan screen-doc deliverables; implement via `document-app-ui`. OpenCode: `.opencode/skills/plan-feature/`. |
| `refine-github-issue` | Refine an open issue from comment feedback (repro, root cause, priorities); update the body or return numbered clarifications when feedback conflicts with SPEC. |
| `review-pr` | Review an open pull request against issue alignment, acceptance-criteria coverage, architecture conventions, and linting compliance; post all findings as a PR comment with strict YES/CONDITIONAL YES/NO outcomes. |
| `review-github-issue` | Review an issue for **purpose ↔ proposed method** coherence and internal consistency; repo/SPEC/test evidence only when needed to show the method cannot satisfy the purpose. Consolidated comment with priorities and remedies; use **`verify-github-issue`** for AC↔implementation closure. |
| `verify-github-issue` | Verify one open issue against ACs/specs/tests; post results as an issue comment; gap analysis when incomplete. |
| `document-app-ui` | Document player-app screens/UI changes per `colonizethis-ui-documentation.mdc` (stable 8-char IDs, layout/behavior/variants, Widgetbook, registry, `UiScreenIds`). OpenCode: `.opencode/skills/document-app-ui/`. |

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for contribution guidelines.
