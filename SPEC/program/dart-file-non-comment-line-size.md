# Dart file non-comment line size (repo lint)

**SPEC/program** — repository-wide gate on **non-comment** source lines in Dart
files. Umbrella policy: `SPEC/program/repo-lint.md` (**no violation allowlists**).

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_dart_file_non_comment_line_size.dart` | Walker, counter, CLI |
| `tool/ct_repo_lint_manifest.yaml` | Registers rule `repo.dart_file_non_comment_line_size` |

## Extraction shape (libraries, not part files)

When a file is split to stay under this gate (or the tighter domain/models caps),
the extracted unit MUST be a **standalone Dart library with explicit `import`
declarations**, not a `part` / `part of` fragment that inherits the host
library's private scope. Part fragments keep the extracted code implicitly
coupled to the host (shared imports and private members), which defeats the
testability and decoupling goal the size gate exists to encourage. The
`colonizethis_turn` (`repo.turn_no_part_directives`, Refs #3416) and
`colonizethis_diplomacy` (`repo.diplomacy_no_part_of`, Refs #3419) packages
already forbid `part` directives in their `lib/` trees; other packages SHOULD
prefer the same standalone-library shape when extracting for size, and MAY add an
equivalent no-`part` gate once their `lib/` tree is part-free.

## Scan scope

- The checker walks the repository tree from the repo root, skipping directory
  names such as `.git`, `.dart_tool`, `build`, `.pub-cache`, `.cursor`, and
  similar tooling trees (see checker source for the authoritative set).
- Only `*.dart` files are considered.

## Measurement contract

- **Non-comment lines:** a line contributes to the count when, after stripping
  `//` line comments, `/* … */` block comments, and string/comment state handling
  defined in the checker, the line still contains countable code (same algorithm
  as `countNonCommentLinesFromSource` in the checker implementation).
- **Failure threshold:** strictly **greater than 1000** non-comment lines fails
  the file (1000 inclusive passes).

## Generated and tooling outputs (scope-only exclusions)

Per `SPEC/program/repo-lint.md`, excluding **whole generated files** from this
rule is **scope wiring**, not a keyed violation waiver.

The checker skips any repo-relative path that:

- Ends with `.g.dart`, `.freezed.dart`, `.mocks.dart`, or `.gen.dart`, or
- Contains the substring `app/lib/l10n/app_localizations_`, or
- Contains the substring `app/lib/l10n/gen/app_l10n_flutter_gen_`.

There is **no** YAML or keyed table that raises the effective line cap for a
specific hand-written library file.

## Acceptance criteria

- Given a temporary workspace whose only Dart file is a hand-written
  `packages/example/lib/huge.dart` with more than 1000 non-comment lines, when
  the System runs `runCheckDartFileNonCommentLineSize` with that workspace root,
  then the checker exits non-zero and the error output names `huge.dart` and
  reports a line count strictly greater than 1000.

- Given a temporary workspace containing only a Dart file whose repo-relative
  path ends with `.gen.dart` and whose non-comment line count exceeds 1000,
  when the System runs `runCheckDartFileNonCommentLineSize`, then the checker
  exits zero and does not list that file as a violation.

- Given a temporary workspace containing only
  `app/lib/l10n/gen/app_l10n_flutter_gen_en.dart` with more than 1000 non-comment
  lines, when the System runs `runCheckDartFileNonCommentLineSize`, then the
  checker exits zero and does not list that path as a violation.

- Given the repository root as cwd, when CI runs
  `dart run tool/ct_repo_lint.dart` and rule `repo.dart_file_non_comment_line_size`
  is in scope for the job, then the rule uses the measurement and exclusions
  above and does not load keyed waiver data to waive failures for in-scope
  hand-written Dart files.

- Given a temporary workspace whose hand-written Dart file
  `packages/x/lib/big.dart` has more than 1000 non-comment lines, and a decoy
  file `tool/legacy_dart_ncl_waiver_table.yaml` shaped like historical keyed
  waiver YAML (for example listing `packages/x/lib/big.dart` under
  `exempt_files`), when the System runs `runCheckDartFileNonCommentLineSize`
  with that workspace root, then the checker still exits non-zero and reports
  `big.dart` as over the non-comment line limit, because no keyed waiver data is
  loaded.

## colonizethis_models 500 non-comment-line gate (Refs #3393)

`colonizethis_models` holds the shared value-model surface consumed by every
other package, so it carries a **tighter 500 non-comment-line cap** under a
dedicated rule, mirroring `repo.domain_package_source_file_size` (500 physical
lines) for the split domain packages.

| Artifact | Role |
|----------|------|
| `tool/check_models_file_size.dart` | Walker, counter (reuses `countNonCommentLinesFromSource`), CLI |
| `tool/ct_repo_lint_manifest.yaml` | Registers rule `repo.models_file_size` |

### Scan scope and measurement

- The checker walks `packages/colonizethis_models/lib/src/**` recursively and
  considers only `*.dart` files, skipping generated suffixes (`.g.dart`,
  `.freezed.dart`, `.mocks.dart`, `.gen.dart`).
- **Failure threshold:** strictly **greater than 500** non-comment lines fails
  the file (500 inclusive passes), using the same `countNonCommentLinesFromSource`
  algorithm as the repository-wide gate.

### Grandfathered baseline (scope wiring, not a per-line waiver)

- Phase 5 split the three largest hand-written offenders (`app_events.dart`,
  `world_market.dart`, `orders.dart`) into `part` files below the cap.
- `game.dart` (554 non-comment lines) is dominated by the single `Game`
  aggregate class, which cannot be reduced under the cap by simple `part`
  extraction; it is recorded in `modelsFileSizeGrandfatheredForTests` as a
  documented baseline pending a follow-up API-shaping split. The checker asserts
  each grandfathered path still exists so the allowlist cannot silently rot.

### Acceptance criteria

- Given the repository root as cwd, when the System runs
  `runCheckModelsFileSize`, then the checker exits zero because every
  non-grandfathered `colonizethis_models/lib/src` Dart file is at or below 500
  non-comment lines.

- Given a temporary workspace whose only models source file is a hand-written
  `packages/colonizethis_models/lib/src/huge.dart` with more than 500
  non-comment lines and an empty grandfather list, when the System runs
  `runCheckModelsFileSize`, then the checker exits non-zero and names
  `huge.dart` with a count strictly greater than 500.

- Given a temporary workspace whose only models source file ends with `.g.dart`
  and exceeds 500 non-comment lines with an empty grandfather list, when the
  System runs `runCheckModelsFileSize`, then the checker exits zero and does not
  list that file.

- Given a temporary workspace whose over-cap models file is listed in the
  grandfather allowlist, when the System runs `runCheckModelsFileSize`, then the
  checker exits zero and does not list that file.

- Given a grandfather allowlist entry that names a file which does not exist in
  the workspace, when the System runs `runCheckModelsFileSize`, then the checker
  exits non-zero and reports a stale grandfather entry for that path.
