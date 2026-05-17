# Contributing to ColonizeThis

## Contribution Process

All contributions must be submitted via a Pull Request (PR).

## Branching

- **Default target branch**: `dev`
- Unless explicitly required, PRs should target `dev` rather than `main` or other branches.

## Flutter and Dart (match CI)

GitHub Actions workflows that install Flutter (see `.github/workflows/quality.yml`, `app-android-release.yml`, and `widgetbook-release.yml`) pin **`flutter-version: '3.41.9'`** on the stable channel, which bundles **Dart 3.11.5**. Use the same Flutter stable locally so dependency resolution and pub.dev advisories decoding match CI.

Every workspace `pubspec.yaml` declares **`environment.sdk: '>=3.11.5 <4.0.0'`** so pure Dart packages are not advertised as compatible with a Dart older than the one shipped with that Flutter pin.

If `dart pub get` or `flutter pub get` fails while resolving hosted packages with **`FormatException: advisoriesUpdated must be a String`**, upgrade your Flutter/Dart install to at least this pair (or newer stable that remains compatible with the repo’s `environment.sdk` lower bound in each `pubspec.yaml`).

### `dart pub outdated` / “Latest” vs what the workspace resolves

`dart pub outdated` and `flutter pub outdated` compare the lockfile to **pub.dev “Latest”**; several rows often stay behind even on a healthy workspace. Common reasons in this repo:

- **`test` / `test_api` / `test_core`:** Flutter’s **`flutter_test`** (from the SDK) pins **`test_api`** to the version shipped with that Flutter release. The standalone **`test`** package may therefore sit **below** pub.dev “Latest” (for example when Latest needs a newer `test_api`) until a **newer Flutter stable** relaxes that pin. This is expected; do not “fix” it by forcing `dependency_overrides` on `test_api` for normal work. **Follow-up:** [#2541](https://github.com/waigore/colonizethisv3/issues/2541).
- **`analyzer` / `analyzer_plugin` / `_fe_analyzer_shared` / `custom_lint_visitor`:** **`colonizethis_exception_lint`** and **`custom_lint_builder`** must agree on an **`analyzer`** major. **`analyzer_plugin` 0.14.x** depends on **`analyzer` 13**, while today’s **`custom_lint_builder`** line stays on **`analyzer` 8.x**—so the workspace intentionally holds **`analyzer` 8.4.0** and **`analyzer_plugin` 0.13.10** until upstream `custom_lint` packages publish a compatible analyzer-13 stack. Treat that gap as an **intentional cap**, not a stale lockfile. **Follow-up:** [#2539](https://github.com/waigore/colonizethisv3/issues/2539).
- **`hardcoded_strings_lint`:** **1.0.4** stays on the analyzer-8 stack; **2.x** requires analyzer 13 and conflicts with **`custom_lint`** Latest until **#2539** lands. **Follow-up:** [#2540](https://github.com/waigore/colonizethisv3/issues/2540).
- **`meta`:** Direct **`meta` 1.17.0** in **`colonizethis_data`** matches the version pinned by SDK **`flutter_test`**; **1.18.x** is not jointly resolvable with Flutter workspace members until the Flutter pin moves.
- **Other transitives (`xml`, `vector_math`, `matcher`, `custom_lint_core`, …):** May lag “Latest” until a **direct** dependency raises its constraints; the solver picks the **newest jointly resolvable** graph across all workspace members.

When bumping dependencies, prefer **`dart pub upgrade`** / **`flutter pub upgrade`** (and coordinated `pubspec.yaml` edits) over overrides; if a row cannot move yet, note the **blocker** (SDK pin or shared dev-tool stack) in the PR or issue.

### Toolchain dependency pinning (GitHub #2532)

**Policy:** Toolchain-related **direct** and **dev** dependencies (`analyzer`, `test`, `custom_lint`, `custom_lint_builder`, `analyzer_plugin`, `hardcoded_strings_lint`, `meta` where declared) use **explicit pinned versions** in `pubspec.yaml` (exact `x.y.z`, not floating `^`). Deliberate upgrades happen via PR that refreshes pins and lockfiles together—routine `pub get` must not silently drift those versions.

**Predecessor:** [#2073](https://github.com/waigore/colonizethisv3/issues/2073) (Flutter pin, advisories path, `repo.workspace_outdated_*` rules). **Phase 1 (#2532):** pin at jointly resolvable Latest; **Phase 2:** [#2539](https://github.com/waigore/colonizethisv3/issues/2539), [#2540](https://github.com/waigore/colonizethisv3/issues/2540), [#2541](https://github.com/waigore/colonizethisv3/issues/2541).

### Workspace outdated audit command set (GitHub #2073)

Run this sequence from a clean checkout on the pinned Flutter/Dart toolchain:

```bash
dart pub outdated
python3 - <<'PY' | while IFS=$'\t' read -r tool pkg; do
import pathlib
root = pathlib.Path('.')
lines = (root / 'pubspec.yaml').read_text().splitlines()
members = []
in_workspace = False
for line in lines:
    stripped = line.strip()
    if not in_workspace:
        if stripped == 'workspace:':
            in_workspace = True
        continue
    if stripped.endswith(':') and not line.startswith(' '):
        break
    if stripped.startswith('- '):
        members.append(stripped[2:].strip())
for member in members:
    pubspec = root / member / 'pubspec.yaml'
    if not pubspec.exists():
        continue
    tool = 'flutter' if 'sdk: flutter' in pubspec.read_text() else 'dart'
    print(f"{tool}\t{member}")
PY
  (cd "$pkg" && "$tool" pub outdated)
done
```

Interpretation:

- If a package is below **Resolvable**, treat it as actionable implementation work (constraints/lockfile are lagging).
- If a package is at **Resolvable** but below **Latest**, verify it is covered by one of the intentional caps documented above before considering the issue complete.
- Record the audit result in the linked issue/PR so reviewers can distinguish solved vs deferred dependency gaps.
- CI-facing equivalent: `dart run tool/ct_repo_lint.dart --rule repo.workspace_outdated_resolvable` (fails when any audited package row has `current != resolvable`).
- CI-facing direct-latest guard: `dart run tool/ct_repo_lint.dart --rule repo.workspace_outdated_latest_direct` (fails when a direct/dev row is below `Latest` even though `Latest == Resolvable`).
- Optional temporary exclusion override for both rules: set `CT_WORKSPACE_OUTDATED_EXCLUDE` to a comma-separated package list (example: `export CT_WORKSPACE_OUTDATED_EXCLUDE="custom_lint_builder,analyzer_plugin"`). Keep this list minimal and always document the exact blocker in the linked issue/PR.

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
- **Workflows:** Today **`.github/workflows/quality.yml`** runs `ct_repo_lint`, domain `custom_lint`, and (in **`app_tests_cache`**) `flutter analyze` under `app/`. When adding workspace-wide analyze steps, document **which job** runs them and use **`dart analyze`** vs **`flutter analyze`** per package type; update this file and SPEC in the same PR.

**Workspace analyzer (GitHub #2014):** **`dart run tool/run_workspace_analyze_errors_only.dart`** or **`melos run workspace_analyze_errors_only`** (see root `pubspec.yaml` → `melos.scripts`) skips the **workspace host root** package, then runs **`flutter pub get`** then **`flutter gen-l10n`** for each Flutter workspace package that has **`l10n.yaml`**, then analyzes every other Pub workspace member with **`dart analyze`** or **`flutter analyze`**, failing only on **analyzer errors** (not warnings). CI runs this in the **`quality` job** of `.github/workflows/quality.yml` after `dart pub get`; **`tool/run_quality_gate_tests.sh`** runs the same command locally. See **[SPEC/program/repo-lint.md](./SPEC/program/repo-lint.md)** (*Phased roadmap* and *Workflow audit*) for the five-slice status and workflow parity.

**App l10n layout (GitHub #2074):** ARB inputs live under **`app/lib/l10n/arb/`**; **`flutter gen-l10n`** writes only under **`app/lib/l10n/gen/`** (gitignored). If you pull after an older layout and see **`git`** report deleted hand files under **`app/lib/l10n/`** after **`flutter run`**, run **`flutter clean`** once in **`app/`** (or remove stale **`app/.dart_tool/flutter_build/**/gen_localizations.stamp`**) so incremental build metadata matches **`app/l10n.yaml`**. Details: **[SPEC/program/localization.md](./SPEC/program/localization.md)**.

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
