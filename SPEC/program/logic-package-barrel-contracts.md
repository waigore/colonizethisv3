# Logic package barrel contracts

**SPEC/program** — Public barrel contract for the split logic-domain packages and the narrow `colonizethis_logic` contract libraries. Companion to `SPEC/program/logic-package-split-phase0.md` (epic #3290) and `SPEC/program/repo-and-packages.md`. Phase 3 of the barrel-refactor umbrella (Refs #3393).

## Principle: consume siblings through barrels

Each domain package (`world`, `combat`, `economy`, `diplomacy`, `orders`, `turn`, `setup`) exposes its public surface through its top-level barrel `package:colonizethis_<domain>/colonizethis_<domain>.dart`. Files under `lib/src/**` that the barrel does **not** re-export are package-internal.

Consumers (sibling domains, the thin `colonizethis_logic` core, the AI contract libraries) MUST import a sibling symbol through that sibling's barrel whenever the barrel already publishes the owning file. A deep `package:colonizethis_<domain>/src/...` import/export is permitted only for a symbol the domain barrel does not yet publish; promoting such a file into its barrel (a future Phase 1 barrel-bypass slice) is preferred over widening deep-import usage.

## AI narrow contract (`ai_api.dart`)

`packages/colonizethis_logic/lib/ai_api.dart` is the explicit, narrow logic surface consumed by `colonizethis_ai` (`colonizethis-logic-ai-decoupling.mdc`). It deliberately avoids re-exporting the broad `colonizethis_logic.dart` barrel.

Contract:

- Sibling-domain symbols are re-exported through the domain barrel
  (`package:colonizethis_<domain>/colonizethis_<domain>.dart show ...`), never
  through a deep `src/` path that the barrel already re-exports.
- The package-local `src/constants.dart` is owned by the thin `colonizethis_logic`
  core itself (no sibling barrel exists), so it remains a package-relative export.
- The remaining deep `src/` exports are grouped under an in-code justification
  block and are permitted **only** because the owning domain barrel does not
  publish those files. As of Phase 3 these are:
  `orders/feedstock_bootstrap_cost.dart`,
  `orders/feedstock_extraction_targets.dart`, and
  `world/sea_reachable_provinces.dart`.
- The exported **symbol set** consumed by `colonizethis_ai` is unchanged by the
  Phase 3 narrowing; only the export routing (deep `src/` → domain barrel)
  changes, so AI planner behaviour and tests are preserved.

## Enforcement: `repo.ai_api_narrow_surface`

`tool/check_ai_api_narrow_surface.dart` (rule `repo.ai_api_narrow_surface`) scans `ai_api.dart`. For every `export 'package:colonizethis_<domain>/src/<file>'` directive it resolves the owning domain barrel's transitive `export` closure (following `package:` and relative `export` directives within that package's `lib/`). The directive is a **violation** when the barrel's closure already contains `<file>` — i.e. a barrel re-export alternative exists.

The predicate is derived purely from the live barrel contents; the rule loads **no keyed waiver / allowlist data** (`SPEC/program/repo-lint.md` § Policy: no violation allowlists). Deep exports of files the barrel does not publish are not flagged because no barrel alternative exists.

The rule is registered in `tool/ct_repo_lint_manifest.yaml` and dispatched in-process by `tool/ct_repo_lint_lib.dart`; the repository test `test/check_ai_api_narrow_surface_test.dart` asserts the real workspace stays green and exercises positive/negative fixtures.

### Acceptance criteria (`repo.ai_api_narrow_surface`)

- **Given** the post-Phase-3 `packages/colonizethis_logic/lib/ai_api.dart` on `dev`, **when** `repo.ai_api_narrow_surface` resolves each domain barrel's transitive export closure, **then** no `export 'package:colonizethis_<domain>/src/<file>'` directive targets a file already published by that domain barrel and the rule exits `0`.
- **Given** an `ai_api.dart` that deep-exports `package:colonizethis_world/src/world/ai_control.dart` while the `colonizethis_world` barrel already re-exports that file, **when** `runCheckAiApiNarrowSurface` scans the workspace, **then** it returns exit code `1` and lists the offending `ai_api.dart:<line>` with a "bypasses the colonizethis_world barrel" message.
- **Given** an `ai_api.dart` that re-exports a symbol through `package:colonizethis_<domain>/colonizethis_<domain>.dart show ...`, **when** `runCheckAiApiNarrowSurface` scans the workspace, **then** that directive is not flagged.
- **Given** an `ai_api.dart` deep export of a file the owning domain barrel does **not** re-export (e.g. `world/sea_reachable_provinces.dart`), **when** `runCheckAiApiNarrowSurface` scans the workspace, **then** that directive is not flagged (no barrel alternative exists).
- **Given** a deep export whose file is reachable only transitively through a sub-barrel (e.g. `orders/orders.dart` re-exporting it), **when** `runCheckAiApiNarrowSurface` scans the workspace, **then** the directive is flagged as a barrel bypass.
- **Given** the `packages/colonizethis_logic/lib/ai_api.dart` file is missing, **when** `runCheckAiApiNarrowSurface` runs, **then** it returns exit code `1` and reports `Missing AI contract file`.
- **Given** a domain referenced by an `ai_api.dart` deep export whose barrel file `lib/<domain>.dart` is missing, **when** `runCheckAiApiNarrowSurface` runs, **then** it returns exit code `1` and reports the missing barrel.

## Cross-cutting

- The broad `colonizethis_logic.dart` barrel continues to re-export the full domain barrels for `app/`, `ctdev/`, and package tests; narrowing `ai_api.dart` does not change that surface.
- Because the AI package is forbidden from importing the broad `colonizethis_logic.dart` barrel in `lib/**` (`colonizethis-logic-ai-decoupling.mdc`), symbols genuinely required by AI stay published by `ai_api.dart`; the Phase 3 work re-routes them through domain barrels rather than removing them.
