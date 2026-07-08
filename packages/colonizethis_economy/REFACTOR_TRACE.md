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

## Phase 2 — Slice 1 (Refs #3856)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| matcher-treasury-floor | floor(treasury / price) when price is positive | `world_market_matcher_treasury_budget_test.dart` | #3115 |
| matcher-treasury-zero | zero treasury budget yields zero | `world_market_matcher_treasury_budget_test.dart` | #3115 |
| matcher-treasury-free-fill | missing-price free-fill returns bid remaining | `world_market_matcher_treasury_budget_test.dart` | #3115 |
| matcher-treasury-decrement | decrements running treasury tally after a priced fill | `world_market_matcher_treasury_budget_test.dart` | #3856 |
| bid-spend-parity-* | four staged vs carry-forward parity rows | `world_market_bid_spend_shared_helper_test.dart` | #3427 |
| lock-recovery-* | three lock-recovery minor auto-bid rows | `lock_recovery_minor_bids_test.dart` | #2924 |

Modules:
- `colonizethis_economy_test_support/lib/src/matcher_treasury_budget_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/bid_spend_parity_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/lock_recovery_minor_bids_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/lock_recovery_minor_bids_test_support.dart`
- `colonizethis_economy_test_support/lib/src/non_gp_auto_offers_test_support.dart`

Lib: `maxAffordableBidQuantity` + `decrementTreasuryForFill` extracted to `treasury_bid_budget.dart`; `deal_matcher_matching.dart` delegates (lint `repo.economy_deal_matcher_treasury_budget_shared`).

Lint: `repo.economy_test_core_fixtures_shared` scope extended to all `packages/colonizethis_economy/test/**`; zero inline `Game(`.

## Phase 2 — Slice 2 (Refs #3856)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| offer-cap-* | four offerCapByCommodityId rows | `world_market_sellable_quantity_test.dart` | #3093 |
| staged-offer-* | four stagedOfferQuantitiesByCommodityId rows | `world_market_sellable_quantity_test.dart` | #3093 |
| sellable-headroom-* | ten sellableHeadroomByCommodityId rows | `world_market_sellable_quantity_test.dart` | #3093 |

Module: `colonizethis_economy_test_support/lib/src/sellable_quantity_scenarios.dart`

## Phase 2 — Slice 3 (Refs #3856)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| pti-attrib-equality | equality holds across all four fields | `purchased_tile_index_test.dart` | — |
| pti-attrib-inequality | inequality on any differing field | `purchased_tile_index_test.dart` | — |
| pti-attrib-tostring | toString surfaces every field for trace logs | `purchased_tile_index_test.dart` | — |
| pti-d1-1 | AC-D1-1 — empty world yields empty index | `purchased_tile_index_test.dart` | D1-1 |
| pti-d1-2 | AC-D1-2 — minor-owned purchased tile resolves attribution | `purchased_tile_index_test.dart` | D1-2 |
| pti-d1-3 | AC-D1-3 — tribe-owned purchased tile resolves attribution | `purchased_tile_index_test.dart` | D1-3 |
| pti-d1-4 | AC-D1-4 — GP-owned province excludes attribution (post-conquest) | `purchased_tile_index_test.dart` | D1-4 |
| pti-d1-5 | AC-D1-5 — unowned province excludes attribution | `purchased_tile_index_test.dart` | D1-5 |
| pti-d1-6 | AC-D1-6 — unmapped tile key excludes attribution | `purchased_tile_index_test.dart` | D1-6 |
| pti-d1-7 | AC-D1-7 — determinism: repeated builds return equal attributions | `purchased_tile_index_test.dart` | D1-7 |
| pti-mixed-minor-tribe | mixed minor + tribe purchases coexist in the same index | `purchased_tile_index_test.dart` | — |
| pti-empty-owning-gp | empty owningGpId entry is dropped defensively | `purchased_tile_index_test.dart` | — |

Modules:
- `colonizethis_economy_test_support/lib/src/purchased_tile_index_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/purchased_tile_index_test_support.dart`

## Phase 2 — Slice 4 (Refs #3856)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| ptr-c5-credit | AC purchased-tile riches handoff — credit: improved gold tile in minor province credits owning GP at improvementLevel × basePrice × multiplier | `purchased_tile_riches_test.dart` | #2991 C5 |
| ptr-multiplier | multiplier is honoured: richesCashMultiplier=1.5 applies before truncation | `purchased_tile_riches_test.dart` | — |
| ptr-non-riches | AC purchased-tile riches handoff — non-riches resource: timber tile produces no credit (commodities flow through world market instead) | `purchased_tile_riches_test.dart` | #2991 C5 |
| ptr-unimproved | AC purchased-tile riches handoff — unimproved tile: improvementLevel=0 produces no credit even when the resource is in the riches set | `purchased_tile_riches_test.dart` | #2991 C5 |
| ptr-no-transport | tile with no road and no port produces no credit (transport level 0 caps yield to 0) | `purchased_tile_riches_test.dart` | — |
| ptr-port-yield | port-flagged tile yields even without road (port = transport 4) | `purchased_tile_riches_test.dart` | — |
| ptr-post-conquest | AC purchased-tile riches handoff — post-conquest filter: when the purchased province is now owned by a Great Power, no credit is emitted (the index filters it out at build time) | `purchased_tile_riches_test.dart` | #2991 C5 |
| ptr-tribe-spices | tribe-owned purchased tile producing spices credits the owning GP | `purchased_tile_riches_test.dart` | — |
| ptr-multi-gp | multi-tile aggregation — distinct GPs each accrue their own credits | `purchased_tile_riches_test.dart` | — |
| ptr-empty-index | empty index returns empty result (no work done) | `purchased_tile_riches_test.dart` | — |
| ptr-empty-tilemaps | empty tileMapByRegion returns empty result | `purchased_tile_riches_test.dart` | — |
| ptr-determinism | determinism — two calls with the same inputs return equal credits | `purchased_tile_riches_test.dart` | — |

Modules:
- `colonizethis_economy_test_support/lib/src/purchased_tile_riches_scenarios.dart`
- Extended `colonizethis_economy_test_support/lib/src/purchased_tile_riches_test_support.dart` (post-conquest, tribe, multi-GP builders)

## Phase 2 — Slice 5 (Refs #3856)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| suggester-empty-* | three empty / defensive-path rows | `world_market_trade_order_suggester_test.dart` | #2989 |
| suggester-offer-* | four surplus-offer detection rows | `world_market_trade_order_suggester_test.dart` | #2989 |
| suggester-bid-* | three deficit-bid detection rows | `world_market_trade_order_suggester_test.dart` | #2989 |
| suggester-bid-cap-* | three bid type cap (rule 4) rows | `world_market_trade_order_suggester_test.dart` | #2989 |
| suggester-cargo-* | three cumulative cargo cap (rule 5) rows | `world_market_trade_order_suggester_test.dart` | #2989 |
| suggester-validator-* | two validator-clean-by-construction rows | `world_market_trade_order_suggester_test.dart` | #2989 |

Module: `colonizethis_economy_test_support/lib/src/trade_order_suggester_scenarios.dart`

## Phase 2 — Slice 6 (Refs #3856)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| suggester-treasury-* | three cumulative treasury cap (rule 5) rows | `world_market_trade_order_suggester_treasury_test.dart` | #3123 |
| player-ctx-snapshot-* | four `worldMarketPlayerContextFromGame` snapshot rows | `world_market_player_context_test.dart` | #3615 |
| player-ctx-factory-* | two factory parity rows over the shared snapshot | `world_market_player_context_test.dart` | #3615 |
| player-ctx-suggestion-* | three `tradeSuggestionContextFromGame` behavior rows | `world_market_player_context_test.dart` | #3615 |

Modules:
- Extended `colonizethis_economy_test_support/lib/src/trade_order_suggester_scenarios.dart` (`tradeOrderSuggesterTreasuryCapScenarios`)
- `colonizethis_economy_test_support/lib/src/player_context_scenarios.dart`

## Phase 2 — Slice 7 (Refs #3856)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| pd-next-* | nine `PriceDiscovery.computeNextPrice` rows | `world_market_price_discovery_test.dart` | — |
| pd-activity-* | four `PriceDiscovery.computeMarketActivity` rows | `world_market_price_discovery_test.dart` | — |
| admission-rule3-* | four `commoditiesWithBidAndOffer` rows | `trade_order_admission_test.dart` | #3615 |
| admission-rule4-* | five `admittedBidCommodityIdsInSubmissionOrder` rows | `trade_order_admission_test.dart` | #3615 |
| ctx-base-* | two `WorldMarketContextBase` field-carrying rows | `world_market_context_base_test.dart` | #3396 |
| gp-treasury-int-* | five int accumulator rows | `gp_treasury_credit_accumulator_test.dart` | — |
| gp-treasury-double-* | three double accumulator rows | `gp_treasury_credit_accumulator_test.dart` | — |
| boycott-blocked-* | seven `boycottedColonySellableCommodityIds` rows | `world_market_boycott_blocked_commodities_test.dart` | #3758 |

Modules:
- `colonizethis_economy_test_support/lib/src/price_discovery_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/trade_order_admission_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/world_market_context_base_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/gp_treasury_credit_accumulator_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/boycott_blocked_commodities_scenarios.dart`

## Phase 2 — Slice 8 (Refs #3856)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| d5-ac1-* | three AC #1 owning-GP FRR matcher rows | `first_right_of_refusal_issue_acceptance_criteria_d5_test.dart` | #2992 D5 |
| d5-ac2-* | AC #2 relation-75 credit row | `first_right_of_refusal_issue_acceptance_criteria_d5_test.dart` | #2992 D5 |
| d5-ac3-* | AC #3 relation-100 full-share row | `first_right_of_refusal_issue_acceptance_criteria_d5_test.dart` | #2992 D5 |
| d5-ac4-* | two AC #4 zero-credit / FRR-exclusion rows | `first_right_of_refusal_issue_acceptance_criteria_d5_test.dart` | #2992 D5 |
| d5-ac5-* | two AC #5 multi-GP attribution rows | `first_right_of_refusal_issue_acceptance_criteria_d5_test.dart` | #2992 D5 |
| validator-rules-* | sixteen rules 1–3 + empty/accept rows | `world_market_trade_order_validator_test.dart` | #2989 |

Modules:
- `colonizethis_economy_test_support/lib/src/frr_issue_ac_d5_scenarios.dart`
- Extended `colonizethis_economy_test_support/lib/src/trade_order_validator_scenarios.dart` (`tradeOrderValidatorRulesScenarios`)

D5 test now imports `DealMatcher` from `package:colonizethis_economy/colonizethis_economy.dart` (no `colonizethis_logic` test import).

## Phase 2 — Slice 9 (Refs #3856)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| frr-rate-* | five `computeFirstRightProfitRate` rows | `first_right_profit_test.dart` | #3753 R8.2 |
| frr-profit-* | eight `computeFirstRightProfit` rows | `first_right_profit_test.dart` | #2992 D3 |
| embassy-kickback-* | seven `computeEmbassyKickback` rows | `first_right_profit_test.dart` | #3753 R8.3 |

Module: `colonizethis_economy_test_support/lib/src/first_right_profit_scenarios.dart`

## Phase 2 — Slice 10 (Refs #3856)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| consumption-* | twelve `resolveConsumption` rows | `economy_consumption_test.dart` | — |
| military-food-* | five `consumeMilitaryFood` rows | `economy_consumption_phases_test.dart` | — |
| navy-food-* | four `consumeNavyFood` rows | `economy_consumption_phases_test.dart` | — |
| worker-food-* | four `consumeWorkerFood` rows | `economy_consumption_phases_test.dart` | — |
| assign-luxury-* | four `assignWorkerLuxury` rows | `economy_consumption_phases_test.dart` | — |
| food-units-* | two `consumeFoodUnits` rows | `economy_consumption_phases_test.dart` | — |

Modules:
- `colonizethis_economy_test_support/lib/src/consumption_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/consumption_phases_scenarios.dart`

## Phase 2 — Slice 11 (Refs #3856)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| build-cost-* | nine `canAffordBuild` / `applyBuildCostDeduction` rows | `build_cost_test.dart` | — |

Module: `colonizethis_economy_test_support/lib/src/build_cost_scenarios.dart`

## Phase 2 — Slice 12 (Refs #3856)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| production-recipe-* | five `resolveProduction` recipe/labour rows | `economy_production_test.dart` | — |
| production-edge-* | three `resolveProduction` edge-case rows | `economy_production_test.dart` | — |
| effective-labour-* | three `effectiveLabourForWorkers` rows | `economy_production_test.dart` | — |

Module: `colonizethis_economy_test_support/lib/src/economy_production_scenarios.dart`

## Phase 2 — Slice 13 (Refs #3856)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| recruit-afford-* | eight `canAffordRecruitWorker` rows | `worker_action_cost_test.dart` | — |
| recruit-apply-* | five `applyRecruitWorkerCostDeduction` rows | `worker_action_cost_test.dart` | — |

Module: `colonizethis_economy_test_support/lib/src/worker_action_cost_scenarios.dart`

## Phase 2 — Slice 14 (Refs #3856)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| auto-offer-empty-* | two empty-fixture rows | `non_gp_auto_offers_test.dart` | #2991 C4 |
| auto-offer-per-tile | emits one priority-1 offer per non-riches tile with originTileKey set | `non_gp_auto_offers_test.dart` | #2991 C4 |
| auto-offer-minor-tribe | aggregates minor and tribe offers in the same result map | `non_gp_auto_offers_test.dart` | #2991 C4 |
| auto-offer-riches | excludes riches commodities (spices) per Requirement 11 | `non_gp_auto_offers_test.dart` | #2991 C4 |
| auto-offer-minerals | minerals stay excluded — no offer for iron tile | `non_gp_auto_offers_test.dart` | #2991 C4 |
| auto-offer-no-connectivity | factions with no connectivity entry omitted | `non_gp_auto_offers_test.dart` | #2991 C4 |

Module: `colonizethis_economy_test_support/lib/src/non_gp_auto_offers_scenarios.dart`

## Deferred (phase 2 follow-up slices)

- Deal-matcher treasury dedup — done (shared helpers + `repo.economy_deal_matcher_treasury_budget_shared`)
- Extended inline-`Game(` guard — done (`repo.economy_test_no_inline_game` on all `test/**`)
- ≥15% test LOC reduction target (≤6,500 LOC) — met; maintain on follow-up migrations

## Phase 3 — Slice 1 (Refs #3939)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| harness-run-labeled | `runLabeledScenario` / `runLabeledScenarios` / `runLabeledScenarioGroup` exported from `scenario_runner.dart` | `colonizethis_economy_test_support/lib/src/scenario_runner.dart` | #3939 |
| dm-consolidated | all non-FRR DealMatcher table rows | `world_market_deal_matcher_test.dart` (merged from boycott, priority, sell-priority, treasury micro-runners) | #3939 |
| dm-frr-consolidated | FRR matcher + FRR activity + PurchasedTileIndex.forTesting helper rows | `world_market_deal_matcher_frr_test.dart` (merged from first_right + first_right_supplement) | #2992 D2, #3939 |
| description-baseline | 115 preserved single-line test descriptions | `test/DESCRIPTION_BASELINE.txt` + `repo.economy_test_preserved_descriptions` | #3939 |
| import-hygiene | zero `package:*/src/` imports under economy test/ | `repo.economy_test_no_cross_package_src_imports` | #3939 |

Deleted micro-runners: `world_market_deal_matcher_boycott_test.dart`, `world_market_deal_matcher_priority_test.dart`, `world_market_deal_matcher_sell_priority_test.dart`, `world_market_deal_matcher_treasury_test.dart`, `world_market_deal_matcher_first_right_test.dart`, `world_market_deal_matcher_first_right_supplement_test.dart`.

World-market file count: 35 → 30 (target ≤12 deferred to slice 2+).

Wall-clock (advisory, 3-run median): **28.30 s** — above `ECONOMY_TEST_TIMING_CEILING_SECONDS` (25 s); documented per `SPEC/program/economy-test-wall-clock.md`; not a merge blocker.

## Phase 3 — Slice 2 (Refs #3939)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| treasury-consolidated | all treasury bid-budget, staged spend, carry-forward, parity, GP credit, effective price, cap-bid rows | `world_market_treasury_test.dart` (merged from 11 micro-runners) | #3939 |
| validator-consolidated | rules 1–7, precedence, treasury cap, context-from-game, catalog-default pin | `world_market_trade_order_validator_test.dart` (merged caps + treasury runners) | #3939 |
| suggester-consolidated | suggester, admission, sellable-headroom rows | `world_market_trade_order_suggester_test.dart` (merged treasury + admission + sellable) | #3939 |
| frr-credits-consolidated | defensive, aggregation, embassy kickback rows | `first_right_credits_test.dart` (merged aggregation + kickback) | #3939 |
| context-consolidated | WorldMarketContextBase, player context, PriceDiscovery rows | `world_market_context_test.dart` (merged context_base + player_context + price_discovery) | #3939 |
| purchased-tile-consolidated | PurchasedTileIndex + riches handoff rows | `purchased_tile_test.dart` (merged index + riches) | #3939 |
| misc-consolidated | boycott blocked commodities + lock-recovery minor bids | `world_market_misc_test.dart` (merged boycott + lock_recovery) | #3939 |

Deleted micro-runners (22): `first_right_credits_aggregation_test.dart`, `first_right_credits_kickback_test.dart`, `world_market_treasury_bid_budget_test.dart`, `world_market_matcher_treasury_budget_test.dart`, `world_market_staged_bid_spend_test.dart`, `world_market_carry_forward_bid_notional_test.dart`, `world_market_bid_spend_shared_helper_test.dart`, `gp_treasury_credit_accumulator_test.dart`, `world_market_effective_price_test.dart`, `world_market_cap_bid_quantity_test.dart`, `world_market_trade_order_validator_treasury_test.dart`, `world_market_trade_order_validator_context_treasury_test.dart`, `world_market_trade_order_validator_caps_test.dart`, `world_market_trade_order_suggester_treasury_test.dart`, `trade_order_admission_test.dart`, `world_market_sellable_quantity_test.dart`, `world_market_context_base_test.dart`, `world_market_player_context_test.dart`, `world_market_price_discovery_test.dart`, `purchased_tile_index_test.dart`, `purchased_tile_riches_test.dart`, `world_market_boycott_blocked_commodities_test.dart`, `lock_recovery_minor_bids_test.dart`.

World-market file count: 30 → **11** (meets ≤12 AC).

Wall-clock (advisory, 3-run median): **21.19 s** — within `ECONOMY_TEST_TIMING_CEILING_SECONDS` (25 s); improved from slice 1 median 28.30 s.

## Phase 3 — Slice 3 (Refs #3939)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| trade-interception-apply | nine `applyTradeInterception` rows | `trade_interception_test.dart` → `trade_interception_scenarios.dart` | #3939, #3470 |
| trade-interception-scan | four `scanTradeInterceptionInputs` rows | `trade_interception_scan_test.dart` → `trade_interception_scenarios.dart` | #3615, #3939 |
| town-bonus-province | five `computeTownManufacturingBonusForProvince` rows | `town_manufacturing_bonus_test.dart` → `town_manufacturing_bonus_scenarios.dart` | #3872, #3939 |
| town-bonus-game | five fixture-backed `computeTownManufacturingBonusForGame` rows | `town_manufacturing_bonus_test.dart` → `town_manufacturing_bonus_scenarios.dart` | #3872, #3939 |
| description-baseline-ext | preserved-description lint scans test_support `*_scenarios.dart` `label:` fields | `tool/check_economy_test_preserved_descriptions.dart` | #3939 |

Modules:
- `colonizethis_economy_test_support/lib/src/trade_interception_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/town_manufacturing_bonus_scenarios.dart`

Core scenario migration progress: `trade_interception_test.dart`, `trade_interception_scan_test.dart`, `town_manufacturing_bonus_test.dart` (10 table rows + 4 documented pure-helper exceptions).

## Phase 3 — Slice 4 (Refs #3939)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| game-lookup-province | two `buildProvinceIndex` rows | `game_lookup_helpers_test.dart` → `game_lookup_helpers_scenarios.dart` | #3939 |
| game-lookup-ports | three `collectPortTileKeys` rows | `game_lookup_helpers_test.dart` → `game_lookup_helpers_scenarios.dart` | #3939 |
| cost-check-precond | five `checkPreconditionsInOrder` rows | `cost_check_test.dart` → `cost_check_scenarios.dart` | #3517, #3939 |
| extraction-stockpile | six `applyExtractionToStockpile` rows | `economy_extraction_test.dart` → `economy_extraction_scenarios.dart` | #3939 |
| extraction-players | three `applyExtractionForPlayers` rows | `economy_extraction_test.dart` → `economy_extraction_scenarios.dart` | #3939 |
| sea-transport-holds | four `cargoHoldsForHomeFleet` rows | `sea_transport_test.dart` → `sea_transport_scenarios.dart` | #3939 |
| sea-transport-allocate | four `allocateOverseasToStockpile` rows | `sea_transport_test.dart` → `sea_transport_scenarios.dart` | #3939 |
| tile-resource-ctx | three `resolveTileKeyResourceContext` rows | `tile_extraction_pipeline_test.dart` → `tile_extraction_pipeline_scenarios.dart` | #3939 |
| tile-extraction-ctx | three `resolveTileKeyExtractionContext` rows | `tile_extraction_pipeline_test.dart` → `tile_extraction_pipeline_scenarios.dart` | #3939 |
| trade-cargo-tonnage | two `overseasShippedTonnageFromExtractionTotals` rows | `economy/trade_cargo_capacity_test.dart` → `trade_cargo_capacity_scenarios.dart` | #3939 |
| trade-cargo-capacity | one empty-tile-map capacity row | `economy/trade_cargo_capacity_test.dart` → `trade_cargo_capacity_scenarios.dart` | #3939 |
| trade-cargo-bypass | four extractionById bypass rows | `economy/trade_cargo_capacity_test.dart` → `trade_cargo_capacity_scenarios.dart` | #3517, #3939 |
| projected-cost-work | two work-material rows | `economy/projected_cost_engine_test.dart` → `projected_cost_engine_scenarios.dart` | #3939 |
| projected-cost-build | two build-delegation rows | `economy/projected_cost_engine_test.dart` → `projected_cost_engine_scenarios.dart` | #3939 |

Modules:
- `colonizethis_economy_test_support/lib/src/game_lookup_helpers_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/cost_check_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/economy_extraction_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/sea_transport_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/tile_extraction_pipeline_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/trade_cargo_capacity_scenarios.dart`
- `colonizethis_economy_test_support/lib/src/projected_cost_engine_scenarios.dart`

Core scenario migration progress: seven additional imperative suites migrated (39 table rows); `non_gp_auto_offers_purchased_tile_test.dart` and lib DRY deferred to slice 5+.

Economy `test/` LOC: **2,415** (down from 3,093 slice 3). test_support: **12,184** (treasury/deal-matcher consolidation still deferred for ≤8,200 target).

Wall-clock (advisory, 3-run median): **32.49 s** — above `ECONOMY_TEST_TIMING_CEILING_SECONDS` (25 s); documented per `SPEC/program/economy-test-wall-clock.md`; not a merge blocker.

## Phase 3 — documented exceptions (partial; extended in later slices)

| file | retained test description(s) | rationale | refs |
|------|------------------------------|-----------|------|
| `world_market_deal_matcher_test.dart` | `returns canonical key regardless of argument order`; `handles equal ids (degenerate self-pair) deterministically` | pure `DealMatcher.pairKey` helper unit tests | #3939 |
| `world_market_deal_matcher_frr_test.dart` | `first attribution per tileKey wins on duplicates`; `empty input yields empty index` | pure `PurchasedTileIndex.forTesting` helper unit tests | #2992 D2, #3939 |
| `town_manufacturing_bonus_test.dart` | `level 2 → 1, level 4 → 2, others → 0`; three `isTownManufacturingRecipeEligible` rows | pure multiplier / recipe-eligibility helper unit tests | #3872, #3939 |

## Phase 3 — Slice 5 (Refs #3939)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| purchased-tile-timber | purchased non-riches tile (timber) emits priority-1 auto-offer | `non_gp_auto_offers_purchased_tile_test.dart` → `non_gp_auto_offers_purchased_tile_scenarios.dart` | #2991 C6, #3939 |
| purchased-tile-parity | purchased vs unpurchased tile parity | `non_gp_auto_offers_purchased_tile_test.dart` → `non_gp_auto_offers_purchased_tile_scenarios.dart` | #2991 C6, #3939 |
| purchased-tile-frr-index | PurchasedTileIndex.fromGame independent of auto-offer emission | `non_gp_auto_offers_purchased_tile_test.dart` → `non_gp_auto_offers_purchased_tile_scenarios.dart` | #2991 C6, #3939 |
| purchased-tile-gold | purchased gold tile emits no auto-offer | `non_gp_auto_offers_purchased_tile_test.dart` → `non_gp_auto_offers_purchased_tile_scenarios.dart` | #2991 C6, #3939 |
| purchased-tile-spices | purchased spices tile emits no auto-offer | `non_gp_auto_offers_purchased_tile_test.dart` → `non_gp_auto_offers_purchased_tile_scenarios.dart` | #2991 C6, #3939 |

Module: `colonizethis_economy_test_support/lib/src/non_gp_auto_offers_purchased_tile_scenarios.dart`

Core scenario migration: complete — all imperative core suites migrated except documented extractor exceptions. Treasury test_support cluster consolidation and town-bonus lib DRY continued in slice 6; further test_support LOC reduction deferred to slice 7+.

Economy `test/` LOC: **2,248** (down from 2,415 slice 4). test_support: **12,355** (treasury/deal-matcher consolidation still deferred for ≤8,200 target).

## Phase 3 — Slice 6 (Refs #3939)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| treasury-cluster | consolidated treasury pure-helper + bid-spend + available scenario modules under `treasury_scenarios/` | `treasury_scenarios/treasury_pure_helper_scenarios.dart`, `treasury_bid_spend_scenarios.dart`, `treasury_available_scenarios.dart`, `treasury_test_support.dart` | #3939 |
| town-tile-walk | shared `forEachTownConnectedTileInProvince` + `fullProvinceIdFromTileKey` | `lib/src/economy/town_connected_tile_walk.dart`; `town_manufacturing_bonus.dart` delegates GP/non-GP province tile loops | #3872, #3939 |

Deleted modules (merged): `effective_market_price_scenarios.dart`, `staged_bid_spend_scenarios.dart`, `carry_forward_bid_notional_scenarios.dart`, `bid_spend_parity_scenarios.dart`, `treasury_bid_budget_scenarios.dart`, `matcher_treasury_budget_scenarios.dart`, `gp_treasury_credit_accumulator_scenarios.dart`, `treasury_bid_budget_test_support.dart`, `bid_spend_game_factory.dart`, `treasury_available_scenarios.dart` (root).

test_support LOC: **12,287** (down from 12,355 slice 5). Treasury/deal-matcher validator scenario merge and ≥20% test_support reduction (≤8,200) still deferred to slice 7+.

## Phase 3 — Slice 7 (Refs #3939)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| deal-matcher-cluster | consolidated DealMatcher scenario modules under `deal_matcher_scenarios/` barrel | `deal_matcher_scenarios/deal_matcher_core_scenarios.dart`, `deal_matcher_frr_scenarios.dart`, `deal_matcher_priority_scenarios.dart`, `deal_matcher_sell_priority_scenarios.dart`, `deal_matcher_treasury_scenarios.dart`, `deal_matcher_test_support.dart` | #3939 |
| validator-cluster | consolidated TradeOrderValidator scenario modules under `validator_scenarios/` barrel | `validator_scenarios/trade_order_validator_scenarios.dart`, `trade_order_validator_treasury_scenarios.dart`, `trade_order_validator_test_support.dart` | #3939 |
| purchased-tile-cluster | consolidated purchased-tile scenario + fixture modules under `purchased_tile_scenarios/` barrel | `purchased_tile_scenarios/purchased_tile_index_scenarios.dart`, `purchased_tile_riches_scenarios.dart`, `purchased_tile_index_test_support.dart`, `purchased_tile_riches_test_support.dart` | #3939 |
| frr-cluster | consolidated FRR scenario modules under `frr_scenarios/` barrel; D5 helpers delegate to `frr_credits_test_support` | `frr_scenarios/frr_credits_scenarios.dart`, `frr_issue_ac_d5_scenarios.dart`, `first_right_profit_scenarios.dart`, `frr_credits_test_support.dart` | #2992 D5, #3939 |
| consumption-dry | `consumption_phases_scenarios.dart` reuses `ConsumptionScenario` type from `consumption_scenarios.dart` | `consumption_phases_scenarios.dart` | #3939 |

test_support LOC: **12,287** (organizational consolidation; further scenario-data dedup for ≤8,200 target deferred to slice 8+).

## Phase 3 — Slice 8 (Refs #3939)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| extraction-fixtures | merged `tile_map_test_support`, `non_gp_extraction_test_support`, `resource_extractor_test_support` into `extraction_fixture_support.dart` | `extraction_fixture_support.dart` | #3939 |
| treasury-quantity-cluster | sellable/offer-cap scenarios under `treasury_scenarios/` with data-driven `assertCommodityQuantityMap` | `treasury_scenarios/treasury_sellable_quantity_scenarios.dart` | #3093, #3939 |
| treasury-context-cluster | player-context + context-base scenarios under `treasury_scenarios/` barrel | `treasury_scenarios/treasury_player_context_scenarios.dart`, `world_market_context_base_scenarios.dart` | #3615, #3396, #3939 |
| auto-offers-merge | purchased-tile C6 rows merged into `non_gp_auto_offers_scenarios.dart` | `non_gp_auto_offers_scenarios.dart` | #2991 C6, #3939 |

Deleted modules (merged): `tile_map_test_support.dart`, `non_gp_extraction_test_support.dart`, `resource_extractor_test_support.dart`, `sellable_quantity_scenarios.dart`, `player_context_scenarios.dart`, `world_market_context_base_scenarios.dart`, `non_gp_auto_offers_purchased_tile_scenarios.dart`.

test_support LOC: **12,207** (down from 12,287 slice 7). Further scenario-data compaction for ≤8,200 target deferred to slice 9+.

## Phase 3 — Slice 9 (Refs #3939)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| purchased-tile-fixtures | shared `purchased_tile_fixture_support.dart` builders (`purchasedTileFixtureGame`, `minorPurchasedTileGame`, `tribePurchasedTileGame`, `gpProvincePurchasedTileGame`, `minorTileAutoOfferGame`) | `purchased_tile_index_test_support.dart`, `purchased_tile_riches_test_support.dart`, `non_gp_auto_offers_test_support.dart` | #2991, #3939 |
| riches-to-treasury | `economy_riches_to_treasury_test.dart` → `economy_riches_to_treasury_scenarios.dart` (8 rows) | `economy_riches_to_treasury_scenarios.dart` | #3939 |

Economy `test/` LOC: **2,153** (down from 2,238 slice 8). test_support: **12,356** (fixture module + riches scenarios added; net +149 — DealMatcher/validator record compaction and further scenario-data dedup deferred to slice 10+ for ≤8,200 target).

## Phase 3 — Slice 10 (Refs #3939)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| dm-expectations | `DealMatchExpectation` + `DealMatcherScenario.expect` data-driven assertions | `deal_matcher_scenarios/deal_matcher_expectations.dart` | #3939 |
| validator-expectations | `ValidatorExpectation` + `TradeOrderValidatorScenario.expect` | `validator_scenarios/validator_expectations.dart` | #3939 |
| dm-record-compaction | migrated DealMatcher empty/basic/cargo/boycott/activity/sell-priority/treasury/FRR-activity rows to `.expect` | `deal_matcher_core_scenarios.dart`, `deal_matcher_priority_scenarios.dart`, `deal_matcher_sell_priority_scenarios.dart`, `deal_matcher_treasury_scenarios.dart`, `deal_matcher_frr_scenarios.dart` | #3939 |
| validator-record-compaction | migrated validator cap rows (bidTypeCap 0/3) to `.expect` | `validator_scenarios/trade_order_validator_scenarios.dart` | #3939 |

## Phase 3 — Slice 11 (Refs #3939)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| dm-expectations-v2 | `FilledDealExpectation`, `frrFilledDeal`/`nonFrrFilledDeal`, `filledDealCommodityIds` on `DealMatchExpectation` | `deal_matcher_expectations.dart` | #3939 |
| validator-expectations-v2 | `singleAccepted`, `singleRejectedWithReason`, `allSameReason`, `firstNAccepted`/`thenRejectedWithReason`, `resultsEmpty` on `ValidatorExpectation` | `validator_expectations.dart` | #3939 |
| dm-priority-compaction | migrated remaining priority/FTP/multi-commodity rows to `.expect` | `deal_matcher_priority_scenarios.dart` | #3939 |
| dm-frr-compaction | migrated remaining FRR routing/multi-bid rows to `.expect` | `deal_matcher_frr_scenarios.dart` | #3939 |
| dm-treasury-compaction | migrated remaining treasury clamp/edge rows to `.expect` | `deal_matcher_treasury_scenarios.dart` | #3939 |
| dm-sell-priority-compaction | migrated relation tiebreaker row to `.expect` | `deal_matcher_sell_priority_scenarios.dart` | #3939 |
| validator-compaction | migrated cap/rules/treasury validator rows to `.expect` | `trade_order_validator_scenarios.dart`, `trade_order_validator_treasury_scenarios.dart` | #3939 |

test_support LOC: **12,624** (net +106 vs slice 10 — `FilledDealExpectation` class + validator helpers; DealMatcher/validator inline-verify compaction; FRR credits / non-GP extraction / auto-offers scenario compaction and ≥20% test_support reduction (≤8,200) deferred to slice 12+).

## Phase 3 — Slice 12 (Refs #3939)

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| frr-credits-expectations | `FrrCreditsExpectation` + `FrrCreditsScenario.expect` data-driven assertions | `frr_scenarios/frr_credits_expectations.dart` | #3939 |
| non-gp-extraction-expectations | `NonGpExtractionExpectation` + `NonGpExtractionScenario.expect` | `non_gp_extraction_expectations.dart` | #3939 |
| non-gp-auto-offers-expectations | `NonGpAutoOffersExpectation` + `FactionAutoOffersExpectation` + `NonGpAutoOffersScenario.expect` | `non_gp_auto_offers_expectations.dart` | #3939 |
| frr-credits-compaction | migrated defensive/aggregation/kickback FRR credits rows to `.expect` | `frr_scenarios/frr_credits_scenarios.dart` | #3939 |
| non-gp-extraction-compaction | migrated all non-GP extraction scenario rows to `.expect` | `non_gp_extraction_scenarios.dart` | #3939 |
| non-gp-auto-offers-compaction | migrated C4/C6 auto-offer rows to `.expect` (FRR index row retains inline verify) | `non_gp_auto_offers_scenarios.dart` | #3939 |

test_support LOC: **12,927** (net +303 vs slice 11 — three expectation helper modules added; scenario inline-verify bodies reduced; further treasury/validator/FRR-profit scenario-data dedup for ≥20% reduction (≤8,200) deferred to slice 13+).

