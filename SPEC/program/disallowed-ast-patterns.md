# Disallowed AST patterns (CI)

## Purpose

Block a small, explicit set of Dart **structural** patterns that harm readability or mislead readers (for example pointless cascade segments on `void`-returning methods). Rules are config-driven so new patterns can be added without new executables.

## Source of truth

- Policy and rule kinds: this document.
- Concrete rules (IDs, messages, matchers): `tool/disallowed_ast_patterns.yaml`.

## Policy

### Cascaded `clear()` calls

In runtime domain code, a **cascade section** that invokes `.clear()` (`..clear()`) is disallowed. Prefer a standalone `.clear()` statement or replacing the collection with a new instance.

Rationale: `clear()` returns `void`; the cascade form suggests chaining a result and is easy to misread.

### Redundant `.where` + `is` + `.map` + `as` on `Stream` / `Iterable`

In runtime domain code, chaining **`.where((x) => x is SomeType).map((x) => x as SomeType)`** is disallowed. Prefer **`.whereType<SomeType>()`** on **`Iterable`** (`dart:core`). The Dart **`Stream`** API does not provide `whereType`; event buses and similar code should call the shared **`CtStreamWhereType`** extension in `colonizethis_models` (or an equivalent non-chained implementation), not the `where`+`map` chain.

Rationale: The filter-then-cast chain duplicates work and is harder to read than a single typed narrowing step.

Rule id: `stream_where_is_map_as` (`match.kind`: `stream_where_is_map_as`).

### `avoid_print` suppression comments

In runtime domain code, comments that suppress the `avoid_print` lint
(`// ignore: avoid_print`) are disallowed.

Rationale: logging policy requires package logger usage; suppressing `avoid_print`
masks policy violations instead of fixing them.

Rule id: `avoid_print_suppression` (`match.kind`: `comment_substring`,
`match.contains`: `ignore: avoid_print`).

### Coverage

Enforcement walks the same domain trees via `tool/ct_repo_lint_scan_contract.dart` (`collectRepoLintDomainDartFiles`), aligned with `SPEC/program/exception-enforcement.md` coverage:

- `packages/**/lib/**`
- `app/lib/**`
- `ctdev/lib/**`
- `tool/**/lib/**`

Generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) and tests (`**/test/**`, `*_test.dart`) are excluded.

## Implementation contract

- **Given** the repository root as the working directory, **when** CI runs `dart run tool/ct_repo_lint.dart` (rule `repo.disallowed_ast_patterns`; see [repo-lint.md](repo-lint.md)), **then** the orchestrator invokes `tool/check_disallowed_ast_patterns.dart`, which loads `tool/disallowed_ast_patterns.yaml`, parses each listed Dart file, and reports violations with file path and line number.
- **Given** a violation and an in-file suppression, **when** the offending line or the line above contains `ignore: disallowed_ast_<rule_id>`, or the file begins with `ignore_for_file: disallowed_ast_<rule_id>` for that rule, **then** the tool does not fail for that occurrence (`<rule_id>` matches the `id` field in YAML, e.g. `cascade_void_clear` → `disallowed_ast_cascade_void_clear`).
- **Given** a new disallowed pattern, **when** maintainers extend `tool/disallowed_ast_patterns.yaml` with a documented `match.kind`, **then** the checker implementation supports that kind or the change includes the corresponding visitor logic and SPEC update.

## Acceptance criteria

- **Given** runtime Dart source containing a cascaded method invocation `..clear()`, **when** the disallowed AST checker runs, **then** it reports at least one violation with the correct file and line.
- **Given** runtime Dart source that calls `.clear()` without a cascade, **when** the checker runs, **then** it does not report a violation for that call.
- **Given** runtime Dart source with `// ignore: disallowed_ast_cascade_void_clear` on the violating line or the line above, **when** the checker runs, **then** it does not report that violation.

- **Given** runtime Dart source that chains `.where((p) => p is T).map((p) => p as T)` on a receiver (for example a `Stream` or `Iterable`), **when** the disallowed AST checker runs, **then** it reports at least one violation for rule `stream_where_is_map_as` with the correct file and line (the `.map` invocation).

- **Given** runtime Dart source that uses `.whereType<T>()` instead of that chain, **when** the checker runs, **then** it does not report a violation for `stream_where_is_map_as`.

- **Given** runtime Dart source with `// ignore: disallowed_ast_stream_where_is_map_as` on the violating line or the line above, **when** the checker runs, **then** it does not report that violation for `stream_where_is_map_as`.

- **Given** runtime Dart source containing a comment `// ignore: avoid_print`,
  **when** the disallowed AST checker runs, **then** it reports at least one
  violation for `avoid_print_suppression` with the correct file and line.
