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

### Strict raw generic core types

In runtime domain code, raw generic core types are disallowed when used without
explicit type arguments. This includes `List`, `Map`, `Set`, `Iterable`,
`Future`, and `Stream`.

Rationale: raw generic types silently permit implicit `dynamic`, which weakens
type safety and hides intent in APIs and state declarations.

Rule id: `strict_raw_types` (`match.kind`: `raw_named_type`,
`match.type_names`: `List|Map|Set|Iterable|Future|Stream`).

### Widget `build()` body line span

In runtime domain code, a widget class `build()` method body is disallowed when
its physical line span exceeds **60** lines.

Rationale: oversized build methods hide UI intent, make reviews harder, and
encourage cross-concern coupling instead of extracting sub-widgets.

Rule id: `widget_build_method_too_long` (`match.kind`:
`method_body_line_span`, `match.function_name`: `build`,
`match.max_body_line_span`: `60`,
`match.require_widget_class_extends`: `true`).

### Sea-zone local-id extraction via `ProvinceId.localIdFrom`

In runtime domain code, extracting a local id from a sea-zone id using
`ProvinceId.localIdFrom(...)` is disallowed for sea-zone identity logic.
Sea-zone comparisons and lookups must use canonical prefixed ids
(`regionId|localSeaZoneId`).

Rationale: stripping to local ids reintroduces ambiguous cross-region matches.

Rule id: `sea_zone_local_id_extraction` (`match.kind`:
`sea_zone_local_id_extraction`).

### Sea-zone tile bucket lookup without canonical key helper

In runtime domain code, indexing `tileKeysByRegionAndProvince[regionId][...]`
with sea-zone identity is disallowed unless the key is produced by canonical
sea-zone key helpers (`canonicalSeaZoneTileBucketKey` or
`canonicalizeSeaZoneId`).

Rationale: local sea-zone key lookups silently bypass canonical identity
invariants and can mask save/load compatibility bugs.

Rule id: `sea_zone_bucket_lookup_without_canonical_key` (`match.kind`:
`sea_zone_bucket_lookup_without_canonical_key`).

### Unprefixed province-id string literals in lookup helpers

In runtime domain code, passing unprefixed province-id string literals to
province lookup/helper APIs is disallowed.

Disallowed examples:

- `getProvince(world, 'p1')`
- `tryGetProvince(world, 'p1')`
- `resolveToFullProvinceId(world, 'p1')`
- `ProvinceId.localIdFrom('p1')`

Allowed examples:

- `getProvince(world, 'oldWorld|p1')`
- `tryGetProvince(world, 'newWorld|n1')`
- `ProvinceId.localIdFrom('oldWorld|p1')`

Rationale: full province ids are the canonical runtime identity. Unprefixed
string literals in lookup paths bypass that invariant and can reintroduce
cross-region ambiguity.

Rule ids:

- `province_lookup_unprefixed_literal` (`match.kind`:
  `unprefixed_province_id_string_literal_argument`,
  `match.method_names`: `getProvince|tryGetProvince|resolveToFullProvinceId`,
  `match.argument_index`: `1`)
- `province_local_id_from_unprefixed_literal` (`match.kind`:
  `unprefixed_province_id_string_literal_argument`,
  `match.method_names`: `localIdFrom`,
  `match.argument_index`: `0`)

### `localSegmentFromStoredGameState` disallowed in runtime domain code

In runtime domain code, `ProvinceId.localSegmentFromStoredGameState(...)` is
disallowed in all scanned files.

Rationale: this helper intentionally tolerates legacy bare local ids. Runtime
identity paths must use explicit prefixed-id handling at the call site instead
of a grandfathered compatibility helper.

Rule id: `province_local_segment_boundary_only` (`match.kind`:
`province_local_segment_boundary_only`).
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

- **Given** runtime Dart source containing a raw generic declaration such as
  `List values = [];`, **when** the disallowed AST checker runs, **then** it
  reports at least one violation for `strict_raw_types` with the correct file
  and line.

- **Given** runtime Dart source using explicit type arguments such as
  `List<int> values = <int>[];`, **when** the disallowed AST checker runs,
  **then** it does not report a `strict_raw_types` violation for that
  declaration.

- **Given** runtime Dart source with a class extending `StatelessWidget` or
  `StatefulWidget` where the `build()` method body spans more than 60 physical
  lines, **when** the disallowed AST checker runs, **then** it reports at least
  one violation for `widget_build_method_too_long` with the correct file and
  line.

- **Given** runtime Dart source with a class extending `StatelessWidget` or
  `StatefulWidget` where the `build()` method body spans 60 physical lines or
  fewer, **when** the disallowed AST checker runs, **then** it does not report
  a `widget_build_method_too_long` violation for that method.

- **Given** runtime Dart source containing
  `ProvinceId.localIdFrom(seaZoneId)` or equivalent sea-zone local-id
  extraction, **when** the disallowed AST checker runs, **then** it reports at
  least one violation for `sea_zone_local_id_extraction` with the correct file
  and line.

- **Given** runtime Dart source indexing
  `tileKeysByRegionAndProvince[regionId][seaZoneId]` (or equivalent local
  sea-zone key expression), **when** the disallowed AST checker runs, **then**
  it reports at least one violation for
  `sea_zone_bucket_lookup_without_canonical_key` with the correct file and
  line.

- **Given** runtime Dart source indexing sea-zone tile buckets via
  `canonicalSeaZoneTileBucketKey(...)` or `canonicalizeSeaZoneId(...)`,
  **when** the disallowed AST checker runs, **then** it does not report a
  `sea_zone_bucket_lookup_without_canonical_key` violation for that lookup.

- **Given** runtime Dart source that passes an unprefixed province-id string
  literal to `getProvince`, `tryGetProvince`, or `resolveToFullProvinceId`,
  **when** the disallowed AST checker runs, **then** it reports at least one
  violation for `province_lookup_unprefixed_literal` with the correct file and
  line.

- **Given** runtime Dart source that passes a prefixed province-id string
  literal (for example `oldWorld|p1`) to those same lookup APIs, **when** the
  disallowed AST checker runs, **then** it does not report a
  `province_lookup_unprefixed_literal` violation.

- **Given** runtime Dart source that passes an unprefixed province-id string
  literal to `ProvinceId.localIdFrom`, **when** the disallowed AST checker
  runs, **then** it reports at least one violation for
  `province_local_id_from_unprefixed_literal` with the correct file and line.

- **Given** runtime Dart source that passes a prefixed province-id string
  literal to `ProvinceId.localIdFrom`, **when** the disallowed AST checker
  runs, **then** it does not report a
  `province_local_id_from_unprefixed_literal` violation.

- **Given** runtime Dart source that calls
  `ProvinceId.localSegmentFromStoredGameState(...)`, **when** the disallowed
  AST checker runs, **then** it reports at least one violation for
  `province_local_segment_boundary_only` with the correct file and line.
