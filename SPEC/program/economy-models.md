# Economy Data Models

## Responsibility

Defines core data structures for the player economy: stockpiles, worker pools, and the turn-level economic flow. Game rules: [stockpiles-and-production.md](../game/stockpiles-and-production.md), [workers-and-population.md](../game/workers-and-population.md).

---

## Data Model

### Stockpile

Per-player map of commodity id → quantity. No per-province storage. Extraction, production, and consumption all operate on this structure. The type models a **strategic national resource pool**; **warehouse logistics** are not simulated ([stockpiles-and-production.md](../game/stockpiles-and-production.md) § Strategic abstraction). Quantities are unbounded aside from integer limits.

### WorkerPool

Per-player population for production, distinct from military/civilian units. Tier definitions and labour values are specified in game/workers-and-population.md.

---

## Algorithm / Flow

Turn economic phases (in order):

1. **Extraction:** Province tiles produce; resources flow to player stockpile via auto-transport. Per game/extraction-and-improvements.md.
2. **Riches-to-treasury:** Riches in stockpile convert to treasury at base price; removed from stockpile. The list of riches commodity ids and base price per commodity is defined at program level in package **colonizethis_data** (riches catalog). Scenario overrides may apply a **richesCashMultiplier** (e.g. 1.5) to the treasury conversion; see [turn-resolution-phase-details.md](turn-resolution-phase-details.md) (Riches to treasury) and resolution API. In the **default ColonizeThis ruleset**, `game.richesCashMultiplier` is 1.0 unless a scenario or ruleset explicitly overrides it; tests and sim_economy may pass higher multipliers (such as 1.5) to explore variant economies without changing the default balance.
3. **Consumption:** Land military regiments consume food upkeep first, then **navy** (ships in the player's fleets; per-ship food from `ShipEconomyCatalog`), then **workers** (food priority Masters→Journeymen→Apprentices→Peasants; strike for missing food/luxury, **not removed**; luxury only for food-fed trained workers who receive a unit). Military and navy food shortfalls do not remove units; **land** feeding coverage drives land combat morale multipliers; **naval** feeding coverage (`fullyFedShips / totalShips`, or 1.0 when there are no ships) drives the **same** morale multipliers for **naval** strength in sea battles per [turn-resolution-phase-details.md](turn-resolution-phase-details.md) and [naval-combat-resolution.md](naval-combat-resolution.md). `WorkerIdleCounts` / `ConsumptionResult.idleLabour` capture post-consumption labour. Unknown `ship_type_id` in fleets fails turn resolution.
4. **Production:** Runs **after** Consumption. Consume commodities and **idle labour** from post-Consumption `WorkerIdleCounts`; produce outputs to stockpile. `resolveProduction` takes `idleLabour` from the consumption pass. Per game/stockpiles-and-production.md and workers-and-population.md.

---

## Research treasury debt (labour techs)

**Scope:** Negative treasury allowed **only** as a result of **research funding** in the Research phase, and only within the cap below. Other phases keep their existing treasury rules unless a future spec extends debt.

| Condition | Max debt (ducats) | Treasury floor |
|-----------|-------------------|----------------|
| `money_lending` not unlocked | 0 | 0 |
| `money_lending` unlocked | 500 | −500 |

**Implementation:** `maxDebtForPlayer(Player)` in `packages/colonizethis_logic/lib/src/turn/economy_debt_rules.dart`. The research resolver rejects a slot’s spend if `treasury - spend < -maxDebt`. **`banking`:** prerequisite-only for other techs in current product; does not change `maxDebtForPlayer` until specified in GDD/TDD.

**Game source of truth:** [tech-tree-labour-economy.md](../game/tech-tree-labour-economy.md) § Effect implementation status. **Resolution:** [research-resolution.md](research-resolution.md).

---

## Integration

| Aspect | Detail |
|---|---|
| Phase | Spans extraction through production (consumption before production) |
| Upstream | Extraction pipeline, game rules (stockpiles-and-production, workers-and-population) |
| Downstream | Player treasury, military morale, production output |

**Package locations:**

- Models (Stockpile, WorkerPool, Player fields): colonizethis_models.
- Resolution logic (extraction, production, transport, consumption): colonizethis_logic.
- Trade-cargo forecasting: `colonizethis_economy` publishes `computeExtractionTotalsForTradeForecast` (per-player `ExtractionTotals` map) so callers driving multiple overseas-tonnage forecasts in one pass build the extraction map once; `forecastOverseasShippedTonnageForPlayer` / `tradeCargoCapacityForGreatPower` accept an optional pre-computed `extractionById` map and fall back to an on-demand `computeExtraction` scan when it is absent (Refs #3517 Cluster 4; avoids duplicate global scans per `colonizethis-turn-resolution-budget.mdc`).
- World-market admission helpers: `colonizethis_economy` owns the rule-2/3/4 admission contracts in `src/economy/world_market/trade_order_admission.dart` (`isWorldMarketTradeableCommodity`, `commoditiesWithBidAndOffer`, `admittedBidCommodityIdsInSubmissionOrder`). `TradeOrderValidator` and `TradeOrderSuggester` delegate to it (validator uses submission-order bid admission; the suggester keeps its alphabetical net-deficit bid pass and only shares the tradeability predicate), and `sellable_quantity.dart` / `treasury_bid_budget.dart` route their riches skip through the same predicate. The `collectPortTileKeys` port-seaboard key builder in `src/economy/game_lookup_helpers.dart` is the single source for `portsByProvinceSeaboard.values.toSet()`. CI gates `repo.economy_world_market_admission_shared` and `repo.economy_dedup_port_tile_keys` keep these deduplicated (Refs #3615 Clusters 1 / 3).
- World-market player context facade: `colonizethis_economy` owns the single `Game`→player numeric-snapshot build path in `src/economy/world_market/world_market_player_context.dart`. `worldMarketPlayerContextFromGame` builds the shared scalars once (bid-type cap, cargo capacity, treasury bid budget with optional staged composition, market prices/rules); `tradeOrderValidationContextFromGame` and `tradeSuggestionContextFromGame` are thin wrappers over it that add their concern-specific availability source (validator offer caps via `offerCapByCommodityId`; suggester raw post-production stockpile supplied by the caller). AI/order layers consume `tradeSuggestionContextFromGame` instead of hand-wiring fields. The Game-scoped build path stays in `colonizethis_economy` so the package remains free of any `orders`/`turn` dependency (Refs #3615 Cluster 2).
- World-market test fixtures: the shared `colonizethis_economy_test_support` package (`lib/`, dev-dependency only) is the single canonical home for the world-market `TradeOrder` factory (`testBid`/`testOffer`), `TradeOrderValidator` helpers (`validatorBid`/`validatorOffer`/`validatorCtx`), `DealMatcher` helpers (`matcherBid`/`matcherOffer`/`matcherInputs`/`frrMatcherTestIndex`), treasury-bid-budget game builders (`buildTreasuryBidBudgetGame`, `buildStockpilePlayerGame`, `humanOrdersWith`, `humanPlayerId`), extraction fixtures (`resourceExtractorGame`, `connectivityFor`, `gameForNonGpExtractionTest`, `testMinor`, `testTribe`, `tileMapAllInProvinceForNonGpExtractionTest`), tile-map builders (`singleTileMap`, `singleResourceTileMap`, `tileMapByRegionForResource`), FRR credit test helpers (`idx`/`attr`/`deal`), and purchased-tile riches scenario builder (`purchasedTileScenario`). Lib code exposes `bidTreasurySpendForOrder` in `treasury_bid_budget.dart` as the single bid-spend contract for validator, suggester, and staged/carry-forward summation, and `GpTreasuryCreditRollup` beside `GpTreasuryCreditAccumulator` as the internal GP-treasury roll-up seam for FRR and purchased-tile riches results (Refs #3831). It depends only on the `colonizethis_economy` public barrel plus `colonizethis_models`, `colonizethis_data`, `colonizethis_test`, and `colonizethis_world` (connectivity fixtures only), so `colonizethis_economy`, `colonizethis_orders`, `colonizethis_logic`, and `colonizethis_diplomacy` test suites import the fixtures from one place instead of maintaining package-local copies. Economy tests import shared `TestFixtures` from `package:colonizethis_test/game_test_fixtures.dart` (including `capitalTileGrainBonusPerTurn` on `minimalGame`). World-market economy tests live under `packages/colonizethis_economy/test/economy/world_market/` (not the `test/` package root). CI gates `repo.economy_test_no_duplicate_fixtures`, `repo.economy_test_no_local_world_market_support`, `repo.economy_test_no_local_stockpile_game_builder`, `repo.economy_gp_treasury_rollup_shared`, `repo.economy_bid_treasury_spend_shared`, and `repo.economy_test_file_size` keep these deduplicated (Refs #3615 Cluster 6, #3823, #3831). A dedicated package (rather than the issue's loosely-suggested `colonizethis_test`) is required because `colonizethis_test` is dev-depended by nearly every package and must not take on `colonizethis_economy`/`colonizethis_logic` dependencies (Refs #3615 Cluster 6).
- Sibling barrel consumption: sibling packages consume `colonizethis_economy` world-market symbols (`bid_type_cap`, `trade_order_suggester`, `validation/order_validation_result`, `deal_matcher`, `purchased_tile_index`, `sea_transport`, `worker_action_cost`) through the public barrel `package:colonizethis_economy/colonizethis_economy.dart` (narrow `show`), not deep `src/` paths. `colonizethis_diplomacy`, `colonizethis_logic`, and `colonizethis_orders` re-export the symbols they republish from the barrel; CI gate `repo.domain_package_barrel_import` enforces `diplomacy → {economy, world}` and `logic → {economy, orders, world}` (alongside the existing `orders → economy`) so no consumer `lib/**` deep-imports a barrel-published economy file (Refs #3615 Cluster 5; `SPEC/program/logic-package-barrel-contracts.md`).

---

## Acceptance criteria and testing

- **Phase order:** Extraction → Riches → Consumption → Production is fixed and tested (e.g. turn resolver and integration tests).
- **Serialization:** Stockpile and WorkerPool are serializable for save/load; tests cover round-trip or snapshot behaviour.
- **Riches:** Conversion uses base price from colonizethis_data; riches are removed from stockpile; optional richesCashMultiplier scales treasury delta when provided. When no scenario override is active, the main game uses a multiplier of exactly 1.0.
- **Consumption:** Land military fed first, then navy (per catalog food upkeep per ship), then workers (food priority Masters→Peasants; luxury for food-fed trained only). Workers are not removed for missing food (strike). Land and naval feeding coverage from `ConsumptionResult` feed land and sea combat (same multiplier tiers). `resolveConsumption` throws if a fleet references an unknown ship type id.
- **Production:** Effective labour from `WorkerIdleCounts` after Consumption (workers-and-population.md). Inputs and labour consumed; outputs added to stockpile; insufficient input skips or partial per recipe spec.
- **Research treasury debt:** `maxDebtForPlayer` returns 0 without `money_lending`, 500 with it; research resolver enforces treasury ≥ −`maxDebt` for research spending only (see [research-resolution.md](research-resolution.md)).

Unit tests: Stockpile/WorkerPool serialization; resolveRichesToTreasury; resolveConsumption (military-first, navy-before-workers, worker food priority, strike / idle counts, unknown ship id error); resolveProduction (with `idleLabour`); `maxDebtForPlayer` (economy debt rules). Integration: turn resolver runs phases in order; consumption coverage flows to land and naval combat morale and production labour where applicable.

---

## Constraints

- Stockpile and WorkerPool types must be serializable for save/load.
- Worker tier definitions, labour values, recruiting/training rules are defined in game/workers-and-population.md; this module references them.
- **Config:** Program-level in current product (no JSON rulesets for economy in current product). Economy-related config (worker tiers, riches list/prices) may move to ruleset per [ruleset-config.md](ruleset-config.md) in a later phase.
