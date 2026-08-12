// Spec AC4/AC8 case bodies for `treasury_planner_treasury_budget_test.dart`
// (Refs #3997 Phase 8, #4310 Slice D remainder).

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_planner_treasury_budget_support.dart';

void registerTreasuryPlannerTreasuryBudgetDeficitClampSpecAcCases() {
  group('runTreasuryPlanner per-bid treasury clamp — deficit path (Refs #3122)', () {
    // SPEC/ai/treasury-planner.md § Treasury-budget-aware bid sizing —
    // AC4: given two deficit commodities where the first bid (after
    // cargo clamp) would consume the full remaining treasury budget,
    // when `runTreasuryPlanner` runs, then the first bid is emitted and
    // the second commodity is skipped without consuming an extra
    // `bidTypeCap` slot (the planner does not emit a zero-quantity
    // placeholder for the dropped bid). Refs #3122.
    //
    // Fixture: bronze and fabric (both manufactured → priority 1) have
    // positive deficits. Bronze sorts alphabetically first inside the
    // priority-1 tier. Market prices are set equal to the affluent-GP
    // treasury so the per-bid clamp gives `floor(2000 / 2000) = 1` —
    // the first emitted bid (bronze) consumes the entire remaining
    // budget. The subsequent priority-1 commodity (fabric) has
    // `remainingBudget == 0` and `maxAffordable == 0`, so the
    // suggester / `_prioritizedBids` `cappedQty <= 0` branch skips
    // it without incrementing the admitted-bid counter — even though
    // `bidTypeCap == 3` (embassy) and `tradeCargoCapacity == 24`
    // (default home-fleet stub) both leave room.
    //
    // Treasury is set at `treasuryAffluenceThreshold()` so the
    // lock-recovery branch never activates (no GP is below the
    // regiment threshold) and the F3 price gate fires for both
    // commodities because recipe-input prices are set well above the
    // market price.
    test(
      'first deficit bid consumes full remaining treasury budget; '
      'later deficit commodities are skipped without consuming an '
      'extra bidTypeCap slot (AC4)',
      () {
        const bronzePrice = 2000;
        const fabricPrice = 2000;
        final stockpile = const Stockpile()
            .applyDelta(CommodityCatalog.bronze.id, 1)
            .applyDelta(CommodityCatalog.fabric.id, 1);
        final game = treasuryBudgetTestGameFor(
          stockpile: stockpile,
          treasury: 2000,
          prices: const {
            'bronze': bronzePrice,
            'fabric': fabricPrice,
            'copper': 1500,
            'tin': 1500,
            'wool': 1500,
            'cotton': 1500,
            'grain': 5,
            'meat': 5,
          },
          overtures: const [kTreasuryBudgetEmbassyOverture],
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: kTreasuryBudgetGpId,
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 2000,
        ));
        final bids = treasuryBudgetTestBids(orders);
        expect(
          bids.length,
          1,
          reason: 'AC4: with two priority-1 deficits and bidTypeCap == 3 '
              '(embassy), the alphabetical-first deficit (bronze) must '
              'consume the full remaining treasury budget and every '
              'later deficit must be skipped without consuming an extra '
              'bidTypeCap slot. Exactly one bid is emitted.',
        );
        expect(
          bids.first.commodityId,
          CommodityCatalog.bronze.id,
          reason: 'AC4: bronze (alphabetical-first priority-1 manufactured '
              'commodity in `need`) must be the emitted bid.',
        );
        expect(
          bids.first.quantity,
          2000 ~/ bronzePrice,
          reason: 'AC4: bronze quantity must equal floor(budget / price) = '
              'floor(2000 / 2000) = 1 — the per-bid treasury clamp '
              'dominates over the cargo clamp and the nominal deficit.',
        );
        final fabricBids = bids
            .where((b) => b.commodityId == CommodityCatalog.fabric.id)
            .toList();
        expect(
          fabricBids,
          isEmpty,
          reason: 'AC4 negative guard: fabric (priority 1, alphabetical '
              'after bronze) has a positive deficit but the planner must '
              'not emit a fabric bid once the remaining treasury budget '
              'collapses to 0 — `cappedQty <= 0` skips the bid before '
              'the slot counter increments.',
        );
        final totalNotional = bids.fold<int>(
          0,
          (s, b) =>
              s + b.quantity * (game.worldMarketState.prices[b.commodityId] ?? 0),
        );
        expect(
          totalNotional,
          lessThanOrEqualTo(2000),
          reason: 'AC4 holistic: cumulative emitted bid notional must '
              'respect the planner-entry treasury budget; the first bid '
              'eats the budget and no second bid is admitted.',
        );
      },
    );

    // SPEC/ai/treasury-planner.md § Treasury-budget-aware bid sizing —
    // AC8 (holistic invariant): given any `runTreasuryPlanner` output
    // for any fixture, when each emitted bid's `quantity ×
    // effectiveMarketPriceForCommodityId(commodityId)` is summed with
    // `pendingTreasuryCostsForTurn` and `carryForwardBidNotional`,
    // then the total is less than or equal to the player's `treasury`
    // at planner entry. Refs #3122.
    //
    // Fixture combines all three budget-reducing sources at once: a
    // pending `BuildUnitOrder` (peasant_levies, `buildTreasuryCost ==
    // 2000`), a carry-forward `TradeOrderType.bid` for timber
    // (`quantity == 4 × pricePerUnit 20 == notional 80`), and two
    // deficit commodities (bronze, fabric) plus the always-tracked
    // food set. Treasury at planner entry is `4000` so the budget
    // after pending and carry-forward reductions is `4000 - 2000 - 80
    // = 1920`. The per-bid clamp must keep every emitted bid sized
    // so the invariant holds even with speculative / multi-priority
    // bid emission across the `bidTypeCap == 3` slot allowance.
    test(
      'cumulative emitted bid notional plus pending costs plus '
      'carry-forward bid notional never exceeds planner-entry '
      'treasury (AC8 holistic invariant)',
      () {
        const peasantBuildTreasuryCost = 2000;
        const carryForwardTimberQty = 4;
        const timberPrice = 20;
        const carryForwardTimberNotional =
            carryForwardTimberQty * timberPrice;
        final stockpile = const Stockpile()
            .applyDelta(CommodityCatalog.bronze.id, 1)
            .applyDelta(CommodityCatalog.fabric.id, 1);
        final game = treasuryBudgetTestGameFor(
          stockpile: stockpile,
          treasury: 4000,
          prices: const {
            'bronze': 30,
            'fabric': 50,
            'timber': timberPrice,
            'copper': 200,
            'tin': 200,
            'wool': 200,
            'cotton': 200,
            'grain': 5,
            'meat': 5,
          },
          carryForwardBidsByFactionId: {
            kTreasuryBudgetGpId: [
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.bid,
                quantity: carryForwardTimberQty,
                priority: 3,
              ),
            ],
          },
          overtures: const [kTreasuryBudgetEmbassyOverture],
        );
        const peasantBuild = BuildUnitOrder(
          unitType: 'peasant_levies',
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p1',
        );
        const currentOrders = Orders(
          buildUnitOrdersByPlayerId: {
            kTreasuryBudgetGpId: [peasantBuild],
          },
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: kTreasuryBudgetGpId,
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 4000,
          currentOrders: currentOrders,
        ));
        final bids = treasuryBudgetTestBids(orders);
        final totalBidNotional = bids.fold<int>(
          0,
          (s, b) =>
              s + b.quantity * (game.worldMarketState.prices[b.commodityId] ?? 0),
        );
        expect(
          totalBidNotional +
              peasantBuildTreasuryCost +
              carryForwardTimberNotional,
          lessThanOrEqualTo(4000),
          reason: 'AC8 holistic invariant: cumulative emitted bid '
              'notional + pending build cost (peasant_levies: 2000) + '
              'carry-forward timber notional (4 × 20 = 80) must not '
              'exceed the planner-entry treasury (4000). The planner '
              'must never authorise a bid the matcher would have to '
              'truncate against the same treasury at phase 13.',
        );
      },
    );
  });
}
