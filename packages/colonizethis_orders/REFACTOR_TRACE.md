# Orders refactor trace (wave 3)

Wave-3 maintenance for `packages/colonizethis_orders` (Refs #3949). Pattern mirrors
economy phase 3 (#3939): support consolidation, scenario harness, description
baseline, prefer-scenario-tables advisory.

## Wave 3 — Slice 1 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| support-tree | relocate non-`*_test.dart` fixtures/helpers under `test/orders/support/` | former `test/orders/*_test_support.dart`, `*fixtures*`, `*helpers*`, `validators/**/*_test_support.dart` | `test/orders/support/{diplomatic,incremental,engine,application,suggestion,validators/**}` | #3949 |
| scenario-harness | add `runLabeledScenario` / `runLabeledScenarios` | — | `test/orders/support/scenario_runner.dart` | #3949 |
| description-baseline | commit 475 single-line `test`/`testWidgets` descriptions | `test/**/*_test.dart` | `test/DESCRIPTION_BASELINE.txt` + `repo.orders_test_preserved_descriptions` | #3949 |
| support-layout-gate | CI forbids new non-test Dart at `test/orders/` root | — | `tool/check_orders_test_support_layout.dart` | #3949 |
| prefer-scenario-tables-gate | advisory prefer-scenario-tables (baseline allow-all on at kickoff) | — | `tool/check_orders_scenario_table_runner.dart` | #3949 |
| gp-minor-path | update GP–Minor fixture canonical path | `tool/check_orders_test_dedup_gp_minor_game.dart` | `support/diplomatic/diplomatic_orders_test_fixtures.dart` | #3877, #3949 |

test/ LOC: **33,048** baseline (unchanged this slice — support moves only). Family scenario migrations and ≥20% LOC reduction deferred to later slices.

## Wave 3 — documented exceptions (kickoff)

| file | retained test description(s) | rationale | refs |
|------|------------------------------|-----------|------|
| (all pre-wave `*_test.dart`) | see `DESCRIPTION_BASELINE.txt` | Imperative suites allowlisted via `ordersPreferScenarioTablesBaselineAllowAll` until table migration; tighten allowlist as families migrate | #3949 |
