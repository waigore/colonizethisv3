# Logic package: validator unitsById parameter threading (repo lint)

**SPEC/program** — Enforces Refs [#2836](https://github.com/waigore/colonizethisv3/issues/2836) AC 3 guidance: order-suggestion and validation helpers under `packages/colonizethis_logic/lib/src/orders/` thread the canonical `OrderResolutionContext` record (`view` + `unitsById` + `provinceById`) instead of accepting `Map<String, Unit> unitsById` as a free-standing function parameter. The cached per-pass snapshots flow through one shared record so probe loops do not rebuild equivalent maps and so candidate validation reuses the validated context already built by the engine entry point.

## Policy

- **Canonical typedef:** `packages/colonizethis_logic/lib/src/orders/order_resolution_context.dart` defines the `OrderResolutionContext` record and the two builders (`buildOrderResolutionContext`, `orderResolutionContextFromView`). The record itself ships a `Map<String, Unit> unitsById` field; that single declaration is intentionally exempt from the budget below.
- **Elsewhere under** `packages/colonizethis_logic/lib/src/orders/`: helpers and validators should accept `OrderResolutionContext` (or an internal context object built from it) rather than taking `Map<String, Unit> unitsById` as a function parameter.
- **Class fields not counted:** `final Map<String, Unit> unitsById;` declarations on internal classes such as `IncrementalCandidateValidator` and `WorkOrderValidator` represent constructor-bound state, not parameter threading. They are not counted by this checker; their migration is orthogonal and tracked separately.
- **Out of scope:** Test files and Dart code outside `packages/colonizethis_logic/lib/src/orders/`. Order-application phase helpers under `lib/src/turn/phases/` still build `OrderResolutionContext` inline via `orderResolutionContextFromView` when calling into `orders/` helpers.

## CI rule

| Field | Value |
|-------|--------|
| `rule_id` | `repo.logic_validator_units_params` |
| Checker | `tool/check_logic_validator_units_params.dart` |
| Scan root | `packages/colonizethis_logic/lib/src/orders/` (non-generated `.dart` only) |
| Excluded file | `packages/colonizethis_logic/lib/src/orders/order_resolution_context.dart` |
| Pattern | `Map<String, Unit> unitsById` followed by `,` or `)` (function-parameter declaration). Lines starting with `final ` (class field) or `//` / `///` (comment) are skipped. |
| Budget | At most **10** physical source lines (total) outside the excluded file may contain a matching `Map<String, Unit> unitsById` function-parameter declaration. |

Raising the budget requires a SPEC update in this file and a maintainer-reviewed PR (same PR as the checker constant change). Lowering the budget tracks the smallest value the latest audit confirms is achievable; future migration of more helpers to `OrderResolutionContext` should drop the budget further in the same PR.

## Audit history

- Refs #2836 AC 3 (this PR): migrated `firstLegalBundledEntryTileKeyInProvince` and `validateCivilianBundledWorkMoveLeg` in `orders/bundled_civilian_work_order.dart` to accept `OrderResolutionContext`, lowering the budget from **12 → 10**. Remaining 10 hits live in `validator_bundle.dart` (3), `order_engine.dart` (4 including the public `OrderValidatorFactory` typedef), `orders_application.dart` (2), and `validators/move_validator.dart` (1) — the engine entry-point and the per-validator probe layer that still accept the unit map directly. Threading the record deeper is tracked as follow-up.

## Acceptance criteria

- Given the repository at `dev` with `packages/colonizethis_logic/lib/src/orders/**` sources, when CI runs `dart run tool/ct_repo_lint.dart` including rule `repo.logic_validator_units_params`, then the checker counts matching `Map<String, Unit> unitsById` function-parameter declarations outside `order_resolution_context.dart` and the run passes when the count is at most 10.
- Given a contributor adds an 11th matching line outside `order_resolution_context.dart` without updating the budget in this SPEC and the checker constant, when repo lint runs, then the run fails and lists each `path:line` hit.
- Given a contributor declares `final Map<String, Unit> unitsById;` as a class field inside `lib/src/orders/`, when repo lint runs, then the checker does **not** count the field and the rule passes if the function-parameter total is within budget.
