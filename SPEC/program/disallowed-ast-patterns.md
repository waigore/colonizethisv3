# Disallowed AST patterns (CI)

## Purpose

Block a small, explicit set of Dart **structural** patterns that harm readability or mislead readers (for example pointless cascade segments on `void`-returning methods). Rules are config-driven so new patterns can be added without new executables.

## Source of truth

- Policy and rule kinds: this document.
- Concrete rules (IDs, messages, matchers): `tool/disallowed_ast_patterns.yaml`.
- Rule model and YAML parsing (`parseDisallowedAstRulesFromYaml`): `tool/disallowed_ast_pattern_rules.dart`.
- AST visitor and CLI entrypoint: `tool/check_disallowed_ast_patterns.dart`.

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

### Instant civilian work completion helper

In runtime domain code, references to **`completeInstantCivilianOrder`** (identifier substring match) are disallowed.

Rationale: `prospect` and `purchase_land` must use the normal **assign → tick → complete** civilian work path per [orders.md](orders.md) and [development-resolution.md](development-resolution.md); an assign-only instant completion bypass breaks treasury timing, `work.updatedPlayers`, and cancel semantics.

Rule id: `no_complete_instant_civilian_order` (`match.kind`: `comment_substring`,
`match.contains`: `completeInstantCivilianOrder`).

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
- `worldState.tryGetProvince('p1')` (receiver form: province id is argument index `0`)
- `worldState..tryGetProvince('p1')` (cascade segments are checked the same way)
- `ProvinceId.localIdFrom('p1')`

Allowed examples:

- `getProvince(world, 'oldWorld|p1')`
- `tryGetProvince(world, 'newWorld|n1')`
- `worldState.tryGetProvince('oldWorld|p1')`
- `ProvinceId.localIdFrom('oldWorld|p1')`

Rationale: full province ids are the canonical runtime identity. Unprefixed
string literals in lookup paths bypass that invariant and can reintroduce
cross-region ambiguity.

Rule ids:

- `province_lookup_unprefixed_literal` (`match.kind`:
  `unprefixed_province_id_string_literal_argument`,
  `match.method_names`: `getProvince|tryGetProvince|resolveToFullProvinceId`,
  `match.argument_index`: `1`)
- `province_world_state_lookup_unprefixed_literal` (`match.kind`:
  `unprefixed_province_id_string_literal_argument`,
  `match.method_names`: `getProvince|tryGetProvince|resolveToFullProvinceId`,
  `match.argument_index`: `0`) — covers extension/receiver calls and cascaded
  segments (see matcher in `tool/check_disallowed_ast_patterns.dart`).
- `province_local_id_from_unprefixed_literal` (`match.kind`:
  `unprefixed_province_id_string_literal_argument`,
  `match.method_names`: `localIdFrom`,
  `match.argument_index`: `0`)

### `localSegmentFromStoredGameState` disallowed in runtime domain code

In runtime domain code, `ProvinceId.localSegmentFromStoredGameState(...)` is
disallowed in all scanned files.

Rationale: this helper intentionally tolerates legacy bare local ids. Runtime
identity paths must use explicit prefixed-id handling at the call site instead
of this legacy compatibility helper.

Rule id: `province_local_segment_boundary_only` (`match.kind`:
`province_local_segment_boundary_only`).

### Debug-console imports must use logic contract entrypoints only

In debug-console runtime code, imports from `colonizethis_logic` are disallowed
unless the import URI appears in the rule's `allowed_imports` list (a scoped
closed contract, not a keyed violation waiver; see `SPEC/program/repo-lint.md`).

Configured policy:

- Scope: `packages/colonizethis_debug_console/lib/**`
- Package target: `package:colonizethis_logic/...`
- Allowed import: `package:colonizethis_logic/debug_console_api.dart`
- Disallowed: `package:colonizethis_logic/src/**`
- Disallowed: imports outside the closed contract set (including
  `package:colonizethis_logic/colonizethis_logic.dart`)

Rationale: preserve one-way architecture boundaries and keep debug console
decoupled from logic internals behind narrow contracts.

Rule id: `debug_console_logic_contract_boundary` (`match.kind`:
`scoped_package_import_contract`).

### List-as-queue `queue.removeAt(0)` in `colonizethis_logic` sources

In `packages/colonizethis_logic/lib/src/**`, a method invocation
**`queue.removeAt(0)`** (receiver is the simple identifier `queue`, method
`removeAt`, literal `0`) is disallowed.

Rationale: using a growable `List` as a FIFO frontier makes each dequeue **O(n)**
in the frontier size; **`dart:collection` `Queue.removeFirst()`** keeps
breadth-first expansion **O(1)** per tile.

Rule id: `logic_lib_list_queue_remove_at_zero` (`match.kind`:
`simple_receiver_remove_at_zero`, `match.receiver_identifier`: `queue`,
`match.relative_path_prefix`: `packages/colonizethis_logic/lib/src/`).

### Linear province lookups via `.provinces.where(...).firstOrNull`

In `packages/colonizethis_logic/lib/src/**`, chaining a `.where(...)` filter on
a `.provinces` collection followed by the `.firstOrNull` getter is disallowed.
This includes nested receivers such as `region.provinces.where(...).firstOrNull`
or `game.worldState.oldWorld.provinces.where(...).firstOrNull`.

Rationale: scanning the full province list to find one entry is **O(P)** per
lookup and easily becomes **O(P·N)** inside hot loops. Use the O(1) province
lookup helpers in `world/province_lookup.dart` (`tryGetProvince`,
`getProvince`, `tryGetProvinceByRegion`, `tryGetProvinceByRegion`) keyed by the
canonical full province id (`regionId|localId`) instead. See
`SPEC/program/world-model.md` and the world-state lookup helpers.

Rule id: `prohibited_linear_province_lookup` (`match.kind`:
`linear_collection_where_first_or_null`, `match.collection_names`:
`provinces`, `match.relative_path_prefix`:
`packages/colonizethis_logic/lib/src/`).

### Linear unit/army/fleet lookups via `.units`/`.armies`/`.fleets` + `.where(...).firstOrNull`

In `packages/colonizethis_logic/lib/src/**`, chaining a `.where(...)` filter on
a `.units`, `.armies`, or `.fleets` collection followed by the `.firstOrNull`
getter is disallowed (same structural match as province linear scans).

Rationale: id-keyed lookups on world-state entity lists belong in **O(1) maps**
built once per outward scope (see `SPEC/program/order-suggestions.md` throughput
bounds and issue #2394 Category C). Reintroducing `.where(...).firstOrNull` on
those collections in hot paths risks **O(n)** per probe inside nested loops.

Rule id: `prohibited_linear_units_armies_fleets_lookup` (`match.kind`:
`linear_collection_where_first_or_null`, `match.collection_names`: `units`,
`armies`, `fleets`, `match.relative_path_prefix`:
`packages/colonizethis_logic/lib/src/`).

### Incremental validator construction inside loops (`colonizethis_logic`)

In `packages/colonizethis_logic/lib/src/**`, calling
`IncrementalCandidateValidator.forPlayer(...)` or
`buildIncrementalCandidateValidator(...)` inside a `for` / `for-in` / `while` /
`do-while` loop body is disallowed.

Rationale: each construction pays a full `buildPlayerView` / units index /
membership setup. Hot suggestion paths must build **one** validator per pass
(or hoist before the loop) and rebind with `forBasePrefix` when the trial
`Orders` prefix changes. See `SPEC/program/order-suggestions.md` § Throughput
bounds (Refs #2394).

Rule id: `prohibited_incremental_validator_per_item` (`match.kind`:
`incremental_validator_for_player_in_loop`, `match.relative_path_prefix`:
`packages/colonizethis_logic/lib/src/`).

### Redundant `.where(...).toList().where(...)` chains

In runtime domain code, chaining `.where(...).toList().where(...)` is
disallowed. The intermediate `.toList()` allocates a `List` that the trailing
`.where(...)` only re-iterates lazily; collapsing into one combined predicate
(`.where((x) => predA(x) && predB(x))`) or a single-pass accumulator
eliminates the wasted allocation **and** the duplicate scan.

The check matches the direct chained form only: a `MethodInvocation` whose
`methodName` is `where` and whose target is `<expr>.where(...).toList()`.
Statement-level reassignment (`ys = ys.where(...).toList(); ys = ys.where(...).toList();`)
and lazy `.where(...).where(...)` chains without an intermediate `.toList()`
are intentionally **not** flagged by this rule.

Rationale: an Expando-style audit of `app/lib/` hot paths (Refs #2575
Phase 5) found that direct `.where(...).toList().where(...)` chains were the
worst case for `build()`-time wasted iteration — the consolidation work in
#2575 Phases 1–4 removed every then-extant chain, and this rule prevents
silent regression. Statement-level reassignment patterns remain on the
follow-up list because they require flow-sensitive analysis to distinguish
legitimate “narrow then partition” patterns from genuine redundant filtering.

Rule id: `redundant_where_to_list_where_chain` (`match.kind`:
`redundant_where_to_list_where_chain`).

### Coverage

Enforcement walks the same domain trees via `tool/ct_repo_lint_scan_contract.dart` (`collectRepoLintDomainDartFiles`), aligned with `SPEC/program/exception-enforcement.md` coverage:

- `packages/**/lib/**`
- `app/lib/**`
- `ctdev/lib/**`
- `tool/**/lib/**`

Generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) and tests (`**/test/**`, `*_test.dart`) are excluded.

## Implementation contract

- **Given** the repository root as the working directory, **when** CI runs `dart run tool/ct_repo_lint.dart` (rule `repo.disallowed_ast_patterns`; see [repo-lint.md](repo-lint.md)), **then** the orchestrator invokes `tool/check_disallowed_ast_patterns.dart`, which loads `tool/disallowed_ast_patterns.yaml`, builds rules via `tool/disallowed_ast_pattern_rules.dart`, parses each listed Dart file, and reports violations with file path and line number.
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
- **Given** runtime Dart source in
  `packages/colonizethis_debug_console/lib/**` that imports only
  `package:colonizethis_logic/debug_console_api.dart`, **when** the disallowed
  AST checker runs, **then** it does not report a
  `debug_console_logic_contract_boundary` violation.

- **Given** runtime Dart source in
  `packages/colonizethis_debug_console/lib/**` that imports
  `package:colonizethis_logic/src/...`, **when** the disallowed AST checker
  runs, **then** it reports at least one
  `debug_console_logic_contract_boundary` violation with the correct file and
  line.

- **Given** runtime Dart source in
  `packages/colonizethis_debug_console/lib/**` that imports a logic entrypoint
  outside the closed contract set, such as
  `package:colonizethis_logic/colonizethis_logic.dart`,
  **when** the disallowed AST checker runs, **then** it reports at least one
  `debug_console_logic_contract_boundary` violation with the correct file and
  line.

- **Given** runtime Dart source under
  `packages/colonizethis_logic/lib/src/` that calls `queue.removeAt(0)`,
  **when** the disallowed AST checker runs, **then** it reports at least one
  violation for `logic_lib_list_queue_remove_at_zero` with the correct file
  and line.

- **Given** runtime Dart source under
  `packages/colonizethis_logic/lib/src/` that dequeues with
  `queue.removeFirst()` on a `Queue`, **when** the disallowed AST checker runs,
  **then** it does not report a `logic_lib_list_queue_remove_at_zero`
  violation for that call.

- **Given** runtime Dart source outside
  `packages/colonizethis_logic/lib/src/` that calls `queue.removeAt(0)`,
  **when** the disallowed AST checker runs, **then** it does not report a
  `logic_lib_list_queue_remove_at_zero` violation for that call.

- **Given** runtime Dart source under
  `packages/colonizethis_logic/lib/src/` that chains
  `<receiver>.provinces.where((p) => ...).firstOrNull` (where `<receiver>` is
  a `RegionData`, `WorldState`, or any expression whose `.provinces` getter
  returns a province list), **when** the disallowed AST checker runs, **then**
  it reports at least one violation for `prohibited_linear_province_lookup`
  with the correct file and line.

- **Given** runtime Dart source under
  `packages/colonizethis_logic/lib/src/` that uses
  `tryGetProvince(world, fullId)` or another O(1) province lookup helper
  instead of `.provinces.where(...).firstOrNull`, **when** the disallowed AST
  checker runs, **then** it does not report a
  `prohibited_linear_province_lookup` violation for that lookup.

- **Given** runtime Dart source outside
  `packages/colonizethis_logic/lib/src/` that chains
  `.provinces.where(...).firstOrNull`, **when** the disallowed AST checker
  runs, **then** it does not report a `prohibited_linear_province_lookup`
  violation for that chain.

- **Given** runtime Dart source under
  `packages/colonizethis_logic/lib/src/` that filters provinces but consumes
  the result as an `Iterable` (for example
  `region.provinces.where((p) => p.ownerId == playerId)` without
  `.firstOrNull`), **when** the disallowed AST checker runs, **then** it does
  not report a `prohibited_linear_province_lookup` violation for that
  expression.

- **Given** runtime Dart source under
  `packages/colonizethis_logic/lib/src/` that chains
  `<receiver>.units.where((u) => ...).firstOrNull`,
  `<receiver>.armies.where((a) => ...).firstOrNull`, or
  `<receiver>.fleets.where((f) => ...).firstOrNull`, **when** the disallowed
  AST checker runs, **then** it reports at least one violation for
  `prohibited_linear_units_armies_fleets_lookup` with the correct file and
  line.

- **Given** runtime Dart source under
  `packages/colonizethis_logic/lib/src/` that resolves a unit, army, or fleet
  by id via a map or other O(1) structure (not `.where(...).firstOrNull` on
  `.units`/`.armies`/`.fleets`), **when** the disallowed AST checker runs,
  **then** it does not report a
  `prohibited_linear_units_armies_fleets_lookup` violation for that lookup.

- **Given** runtime Dart source that chains
  `<expr>.where(...).toList().where(...)` (the trailing `.where(...)` is the
  receiver call after the intermediate `.toList()`), **when** the disallowed
  AST checker runs, **then** it reports at least one violation for
  `redundant_where_to_list_where_chain` with the correct file and line.

- **Given** runtime Dart source that chains `<expr>.where(...).where(...)`
  with **no** intermediate `.toList()` between the two `.where(...)` calls,
  **when** the disallowed AST checker runs, **then** it does not report a
  `redundant_where_to_list_where_chain` violation for that chain.

- **Given** runtime Dart source that reassigns a list across statements via
  `ys = ys.where(...).toList();` followed by `ys = ys.where(...).toList();`,
  **when** the disallowed AST checker runs, **then** it does not report a
  `redundant_where_to_list_where_chain` violation (this rule targets the
  direct expression chain only).

- **Given** runtime Dart source that includes
  `// ignore: disallowed_ast_redundant_where_to_list_where_chain` on the
  violating line or the line above, **when** the disallowed AST checker
  runs, **then** it does not report that violation for
  `redundant_where_to_list_where_chain`.
