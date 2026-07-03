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

## Slice 3 — deal matcher, treasury available, validator cap scenario tables

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| dm-empty | no offers and no bids returns DealMatchResult.empty | `world_market_deal_matcher_test.dart` | — |
| dm-offers-only | offers only (no bids) carries every offer forward, no deals | `world_market_deal_matcher_test.dart` | — |
| dm-bids-only | bids only (no offers) carries every bid forward, no deals | `world_market_deal_matcher_test.dart` | — |
| dm-basic-fill | single offer 10 vs single bid 5 fills 5, offer carries 5 forward | `world_market_deal_matcher_test.dart` | — |
| dm-missing-price | missing price for commodity records pricePerUnit = 0.0 | `world_market_deal_matcher_test.dart` | — |
| dm-zero-offer | zero-quantity offer emits no deal and no carry-forward | `world_market_deal_matcher_test.dart` | — |
| dm-no-cargo | buyer with no tradeCapacity entry treated as zero cargo | `world_market_deal_matcher_test.dart` | — |
| dm-cross-cargo | cross-commodity cargo partial fill + carry-forward | `world_market_deal_matcher_test.dart` | — |
| dm-negative-cargo | negative tradeCapacity is clamped to zero | `world_market_deal_matcher_test.dart` | — |
| dm-boycott-* | four boycott exclusion cases | `world_market_deal_matcher_boycott_test.dart` | #3753 |
| treasury-available-* | ten treasuryAvailableForBidsByPlayer cases | `world_market_treasury_bid_budget_test.dart` | #3093 |
| treasury-ui-* | five UI composition clamp cases | `world_market_treasury_bid_budget_test.dart` | #3093 |
| validator-cap-* | thirteen validator rules 4–7 + precedence cases | `world_market_trade_order_validator_caps_test.dart` | #2989 |

Modules:
- `colonizethis_economy_test_support/lib/src/deal_matcher_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/treasury_available_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/trade_order_validator_scenarios.dart`

## Slice 4 — deal matcher priority/treasury/FRR/sell-priority scenario tables

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| dm-priority-* | five FTP/priority precedence cases | `world_market_deal_matcher_priority_test.dart` | #2989 |
| dm-multi-* | two multi-commodity / carry-forward cases | `world_market_deal_matcher_priority_test.dart` | — |
| dm-lock-recovery | lock-recovery seller priority | `world_market_deal_matcher_priority_test.dart` | #2924 |
| dm-activity-* | two activity bookkeeping cases | `world_market_deal_matcher_priority_test.dart` | — |
| dm-treasury-* | ten treasury-clamp cases | `world_market_deal_matcher_treasury_test.dart` | #3115 |
| dm-frr-* | seven FRR matcher integration cases | `world_market_deal_matcher_first_right_test.dart` | #2992 |
| dm-frr-activity | FRR filledQuantity activity case | `world_market_deal_matcher_first_right_supplement_test.dart` | #2992 |
| dm-sell-priority-* | seven sell-priority relation cases | `world_market_deal_matcher_sell_priority_test.dart` | #3753 |

Modules:
- `colonizethis_economy_test_support/lib/src/deal_matcher_priority_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/deal_matcher_treasury_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/deal_matcher_frr_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/deal_matcher_sell_priority_scenarios.dart`

## Slice 5 — FRR credits and validator treasury scenario tables

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| frr-defensive-* | six defensive/skip branches | `first_right_credits_test.dart` | #2992 |
| frr-aggregation-* | three multi-tile / precedence / determinism cases | `first_right_credits_aggregation_test.dart` | #3753 |
| frr-kickback-* | five embassy kickback cases | `first_right_credits_kickback_test.dart` | #3753 |
| validator-treasury-* | ten rule-5 treasury cap cases | `world_market_trade_order_validator_treasury_test.dart` | #3093, #3123 |
| validator-context-treasury-* | six context-from-game treasury cases | `world_market_trade_order_validator_context_treasury_test.dart` | #3123, #3290 |

Modules:
- `colonizethis_economy_test_support/lib/src/frr_credits_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/trade_order_validator_treasury_scenarios.dart`

## Slice 6 — extraction scenario DSL and carry-forward bid notional

| scenario_id | test description | source test file(s) | refs |
|-------------|------------------|----------------|------|
| re-connectivity-* | four connectivity/cap cases from part1 segment1 | `resource_extractor_part1_segment1_test.dart` | #3661 |
| re-mineral-* | four mineral/town-dev cases from part1 segment2 | `resource_extractor_part1_segment2_test.dart` | — |
| re-empty-connected | returns empty ExtractionTotals when player has no connected tiles | `resource_extractor_part2_part2_test.dart` | — |
| re-overseas | overseas totals when connected tile in different region | `resource_extractor_part2_part1_test.dart` | — |
| re-path-transport | effective yield capped by min transport level along path to capital | `resource_extractor_part2_part1_test.dart` | — |
| non-gp-spec-* | five SPEC-AC cases | `non_gp_extraction_part1_test.dart` | #2991 |
| non-gp-boundary-* | eight boundary/multi-faction cases | `non_gp_extraction_part2_test.dart` | #2991 |
| carry-fwd-catalog | falls back to catalog default price when world price is missing | `world_market_carry_forward_bid_notional_test.dart` | #3122 |

Modules:
- `colonizethis_economy_test_support/lib/src/resource_extractor_scenarios.dart` (`extractionScenario` DSL)
- `colonizethis_economy_test_support/lib/src/non_gp_extraction_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/carry_forward_bid_notional_scenarios.dart`

Helpers extended in `resource_extractor_test_support.dart`: `TileImprovementSpec`, `tileStateFromSpecs`, `tileMapFromGrids`, `overseasResourceExtractorGame`.

Bespoke tests retained (topology/logging/town-rule/tile-contribution): `resource_extractor_part1_segment1_test.dart` (dual tech cap), `resource_extractor_part1_segment2_test.dart` (town-rule non-port), `resource_extractor_part2_part1_test.dart` (town-rule port, blockaded overseas), `resource_extractor_part2_part2_test.dart` (province-missing log, capital bonus, tile contribution).

## Deferred (follow-up slices)

- None — #3836 ACs satisfied pending PR merge and verification
