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
- [ ] **OpenCode / help wanted**: I have read [OpenCode review and the help wanted label](#opencode-review-and-the-help-wanted-label) and applied the label when appropriate (see that section if I cannot add labels myself).

## UI issues: verification screenshot (quality gate)

When a pull request addresses a **UI-related GitHub issue** (anything user-visible: Flutter or Flame screens, map or tile rendering, dialogs, controls, typography, spacing, or pixel-art presentation in the app), treat a **verification screenshot** as part of the quality gate:

- Post a comment on the **linked issue** that includes an image showing the fixed or intended behavior (same or comparable view as the report), **before the issue is closed**.
- If there is **no** linked issue, put the screenshot in the **PR description** instead.

This complements automated tests and code review; reviewers may treat missing visual evidence as blocking when the change is not already covered by golden or e2e visual checks.

## OpenCode review and the help wanted label

The Quality workflow can run an **OpenCode** post–e2e PR review when the PR is in scope for that gate. To **request** that review, add the GitHub label **`help wanted`** (exact name). Heuristics—use your judgment; **when in doubt, add the label**:

- The PR **touches multiple packages** (or crosses major boundaries such as app + logic + map in one change set).
- The PR is a **large refactor** (wide renames, structural moves, or behavior changes across many call sites).

Apply **`help wanted` for any PR you consider sufficiently complex by the above**, **even if** the PR already changes **more than ten files** (the workflow may also run OpenCode on large diffs without the label; the label makes intent explicit).

**When to add the label:** Prefer adding **`help wanted` when you open the PR** so a passing run can pick up OpenCode without an extra cycle. If you add it later, the **Quality** workflow also runs on the **`labeled`** event, so adding `help wanted` after open will **re-run** checks and allow the gate to apply on the new run (subject to the same branch and path rules as always).

If your GitHub role **cannot add labels**, state in the PR description that you want the **`help wanted`** label applied for OpenCode review (or ask a maintainer during triage).

## Repo convention lint

Repository-wide checks (beyond `dart analyze` / `custom_lint`) run through **`dart run tool/ct_repo_lint.dart`**, driven by **`tool/ct_repo_lint_manifest.yaml`**. When adding a new convention for CI, register a **stable `rule_id`** there and document it in **[SPEC/program/repo-lint.md](./SPEC/program/repo-lint.md)**—avoid new standalone `tool/check_*.dart` workflow steps without updating that manifest.

### Tests and `integration_test/` in lint scope (phased)

**Authoritative detail:** **[SPEC/program/repo-lint.md](./SPEC/program/repo-lint.md)** — section *Test and `integration_test/` static analysis scope* (GitHub #2014).

Summary for contributors and CI authors:

- **`test/`** and **`integration_test/`** are **targets for parity** with `lib/` for static gates where the tool applies; **generated, golden, and fixture trees** stay excluded per SPEC.
- **Mergeable slices:** Work lands in **≤ 5** PRs; each must keep **`dev` required checks green**. Do not widen **fatal** test enforcement without **co-fixes** in the same PR or a **SPEC-documented** audit/baseline transition.
- **`dart analyze` / `flutter analyze` (error-only CI steps):** Fail only on **analyzer errors**, not warnings, unless policy changes.
- **`ct_repo_lint` and binary AST scripts:** **Pass/fail** on violations (not the same as “analyzer errors only”).
- **Workflows:** Today **`.github/workflows/quality.yml`** runs `ct_repo_lint`, domain `custom_lint`, and (in **`app_tests_cache`**) `flutter analyze` under `app/` plus `check_long_string_switches`. When adding workspace-wide analyze steps, document **which job** runs them and use **`dart analyze`** vs **`flutter analyze`** per package type; update this file and SPEC in the same PR.

**Workspace analyzer (GitHub #2014):** **`dart run tool/run_workspace_analyze_errors_only.dart`** or **`melos run workspace_analyze_errors_only`** (see root `pubspec.yaml` → `melos.scripts`) runs **`flutter pub get`** then **`flutter gen-l10n`** for each Flutter workspace package that has **`l10n.yaml`**, then analyzes every Pub workspace package with **`dart analyze`** or **`flutter analyze`**, failing only on **analyzer errors** (not warnings). CI runs this in the **`quality` job** of `.github/workflows/quality.yml` after `dart pub get`; **`tool/run_quality_gate_tests.sh`** runs the same command locally. See **[SPEC/program/repo-lint.md](./SPEC/program/repo-lint.md)** (*Phased roadmap* and *Workflow audit*) for the five-slice status and workflow parity.

## macOS Flutter build troubleshooting: Swift priors ReadError

If `flutter run -d macos` or `flutter build macos` intermittently fails while compiling CocoaPods plugins with output that includes:

- `SwiftDriver.ModuleDependencyGraph.ReadError error 14`
- `Could not read priors, will not do cross-module incremental builds`
- references to `*-primary.priors` under `app/build/macos/Build/Intermediates.noindex/...`

use the following recovery sequence from the repo root:

```bash
flutter clean
rm -rf app/build/macos
rm -rf ~/Library/Developer/Xcode/DerivedData/*Runner*
flutter pub get
cd app/macos
pod deintegrate
pod install
cd ..
flutter run -d macos
```

Notes:

- This issue is tied to stale/corrupted local incremental Swift metadata, not gameplay logic.
- If your checkout has a non-default app target name, adjust the `DerivedData` cleanup glob accordingly.
- Keep `flutter pub get` before `pod install`; `flutter clean` removes `Flutter-Generated.xcconfig`, and CocoaPods requires it.
- Use this as the single recommended recovery path for intermittent `SwiftDriver.ModuleDependencyGraph.ReadError` in local macOS builds.

## Additional Resources

- [AGENTS.md](./AGENTS.md) — Agent instructions and cursor rules for this project
