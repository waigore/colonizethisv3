# Economy dedup refactor trace (Refs #3836)

Maps consolidated scenario modules to preserved test descriptions, source files, and originating issue AC references.

Baseline: `dev` @ `decff0ac` (world_market test LOC ~6227 before slice 1).

## Slice 1 — bid cap helper, core builders, import hygiene

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| cap-bid-cargo-only | cargo-only cap when treasury is ample | `world_market_cap_bid_quantity_test.dart` (new table) | #3093 |
| cap-bid-treasury-only | treasury-only cap when cargo is ample | `world_market_cap_bid_quantity_test.dart` | #3123 |
| cap-bid-zero-treasury | zero treasury budget yields zero | `world_market_cap_bid_quantity_test.dart` | #3123 |
| cap-bid-zero-cargo | zero cargo budget yields zero | `world_market_cap_bid_quantity_test.dart` | — |
| cap-bid-null-price | null unit price applies cargo cap only | `world_market_cap_bid_quantity_test.dart` | — |
| cap-bid-nonpositive-price | non-positive unit price applies cargo cap only | `world_market_cap_bid_quantity_test.dart` | — |
| cap-bid-below-caps | bid quantity below both caps passes through | `world_market_cap_bid_quantity_test.dart` | — |
| cap-bid-nonpositive-qty | non-positive bid quantity yields zero | `world_market_cap_bid_quantity_test.dart` | — |

Module: `colonizethis_economy_test_support/lib/src/treasury_bid_budget_scenarios.dart`

Lib: `capBidQuantityForBudgets` extracted to `treasury_bid_budget.dart`; `trade_order_suggester.dart` delegates (lint `repo.economy_bid_quantity_cap_shared`).

Core builder module: `colonizethis_economy_test_support/lib/src/core_economy_test_support.dart` — migrated 13/18 core suites in slice 1.

Import hygiene: zero `package:colonizethis_economy/src/` imports (lint `repo.economy_test_no_src_imports`).

## Slice 2 — treasury scenario tables, remaining core migrations

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| eff-price-stored | returns the integer price from worldMarketState.prices when present | `world_market_effective_price_test.dart` | #3093 |
| eff-price-catalog-fallback | falls back to ResourceRules.defaultMarketPriceForCommodityId when the prices map omits the commodity | `world_market_effective_price_test.dart` | #3093 |
| eff-price-manufactured-default | falls back to the catalog manufactured base price when the prices map omits the commodity (Refs #3093 manufactured-default-prices) | `world_market_effective_price_test.dart` | #3093 |
| eff-price-unknown-null | returns null only when neither prices nor catalog has a value (defensive fallback for unknown / future commodity ids) | `world_market_effective_price_test.dart` | — |
| eff-price-riches-null | returns null for riches commodities regardless of stored prices | `world_market_effective_price_test.dart` | — |
| eff-price-negative-fallback | treats negative stored prices as missing and falls back to catalog | `world_market_effective_price_test.dart` | — |
| staged-spend-empty | returns 0 when the player has no staged trade orders | `world_market_staged_bid_spend_test.dart` | #3093 |
| staged-spend-offers-only | returns 0 when the player has only staged offers (no bids) | `world_market_staged_bid_spend_test.dart` | #3093 |
| staged-spend-sum-bids | sums quantity × effectiveMarketPrice across all staged bids | `world_market_staged_bid_spend_test.dart` | #3093 |
| staged-spend-catalog-default | uses catalog defaults when a bid commodity is missing from prices | `world_market_staged_bid_spend_test.dart` | #3093 |
| staged-spend-mixed-defaults | sums spend across raw + manufactured bids using catalog defaults (Refs #3093 manufactured-default-prices) | `world_market_staged_bid_spend_test.dart` | #3093 |
| staged-spend-unpriced-skip | skips bids on commodities with no effective price (defensive guard against unknown / future ids) | `world_market_staged_bid_spend_test.dart` | — |
| staged-spend-zero-qty | ignores bids with non-positive quantity (defensive guard) | `world_market_staged_bid_spend_test.dart` | — |
| staged-spend-player-isolation | isolates spend per player (unknown playerId returns 0) | `world_market_staged_bid_spend_test.dart` | — |

Modules:
- `colonizethis_economy_test_support/lib/src/effective_market_price_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/staged_bid_spend_scenarios.dart`

Core builder extensions: `minimalEconomyGame`, `minimalTwoPlayerGame`, `minimalGpGame` in `core_economy_test_support.dart`.

Core migrations (slice 2): `worker_action_cost_test.dart`, `sea_transport_test.dart`, `projected_cost_engine_test.dart`, `economy_riches_to_treasury_test.dart`, `economy_tech_effects_test.dart`, `economy_extraction_test.dart`, `trade_cargo_capacity_test.dart`.

Lint: `repo.economy_test_core_fixtures_shared` — blocks inline `Game(` in 17 guarded core test files.

## Documented exceptions (≤2)

| file | rationale |
|------|-----------|
| `resource_commodity_id_mapping_test.dart` | Enum→catalog guard only; no Player/Stockpile/Game fixtures |

## Deferred (follow-up slices)

- `deal_matcher_scenarios.dart`, `trade_order_validator_scenarios.dart`, `frr_credits_scenarios.dart`
- Extraction scenario DSL for `resource_extractor_part*` / `non_gp_extraction_part*`
- World-market test LOC ≥25% reduction vs baseline (carry-forward, validator, matcher, FRR clusters)
