// Case bodies for `treasury_planner_treasury_budget_test.dart`
// (Refs #3997 Phase 8). Registered from the thin contract; pin coverage
// preserved 1:1 from the former inline suite.

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_planner_treasury_budget_support.dart';

void registerTreasuryPlannerTreasuryBudgetLockRecoverySpeculativeCasesTail() {
  group('runTreasuryPlanner per-bid treasury clamp — lock-recovery & speculative (Refs #3122)', () {
    test(
      'speculative pass: budget/price < kSpeculativeBidStockpileTarget '
      'emits bid at quantity == floor(budget/price), not target 8',
      () {
        // Treasury == affluence threshold (= cheapestRegimentBuildTreasuryCost
        // = 2000) so the affluent speculative pass is active. Stockpile
        // covers grain/meat so the food deficit path stays out of `need`;
        // every other non-riches commodity has `projected == 0 < 8` and
        // is therefore speculative-eligible. lastTurnActivity routes the
        // speculative selection to castIron (the liquid pick branch
        // outranks both food and alphabetical fallback per
        // _addSpeculativeBidNeeds, so the selected commodity is
        // deterministic for this fixture).
        const castIron = 'castIron';
        const castIronPrice = 400;
        final affluentTreasury = treasuryAffluenceThreshold();
        // floor(2000 / 400) == 5, strictly less than kSpeculativeBidStockpileTarget (8).
        final expectedAffordableFloor = affluentTreasury ~/ castIronPrice;
        expect(
          expectedAffordableFloor < kSpeculativeBidStockpileTarget,
          isTrue,
          reason: 'Fixture invariant: affordable floor must be below the '
              'speculative stockpile target so the per-bid clamp dominates.',
        );
        final stockpile = const Stockpile()
            .applyDelta('grain', 100)
            .applyDelta('meat', 100);
        final game = treasuryBudgetTestGameFor(
          stockpile: stockpile,
          treasury: affluentTreasury,
          prices: const {
            castIron: castIronPrice,
            'grain': 5,
            'meat': 5,
          },
          lastTurnActivity: const {
            castIron: MarketActivity(
              totalBidQuantity: 0,
              totalOfferQuantity: 100,
              filledQuantity: 0,
            ),
          },
          overtures: const [kTreasuryBudgetEmbassyOverture],
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: kTreasuryBudgetGpId,
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: affluentTreasury,
        ));
        final castIronBids = treasuryBudgetTestBids(orders)
            .where((b) => b.commodityId == castIron)
            .toList();
        expect(
          castIronBids,
          hasLength(1),
          reason: 'A non-zero affordable floor must not drop the '
              'speculative bid; the planner emits exactly one castIron bid '
              'after the per-bid treasury clamp.',
        );
        expect(
          castIronBids.single.quantity,
          expectedAffordableFloor,
          reason: 'Speculative bid quantity must equal '
              'floor(budget / price) = floor(2000 / 400) = 5, not the '
              'kSpeculativeBidStockpileTarget (= 8) gap.',
        );
        // Budget invariant for the speculative path: cumulative notional
        // never exceeds the affluent treasury at planner entry.
        final totalNotional = treasuryBudgetTestBids(orders).fold<int>(
          0,
          (s, b) =>
              s + b.quantity * (game.worldMarketState.prices[b.commodityId] ?? 0),
        );
        expect(totalNotional, lessThanOrEqualTo(affluentTreasury));
      },
    );

    // SPEC/ai/treasury-planner.md § Treasury-budget-aware bid sizing —
    // AC6: when the lock-recovery designated buyer's per-bid budget is
    // below the liquidity commodity's per-unit price the synthetic grain
    // bid drops (affordableQty == 0). Mutual exclusion against the
    // liquidity commodity's offer side is preserved by the unconditional
    // `available.remove(commodityId)` at the head of
    // `_applyLockRecoveryLiquidityBid` (Refs #2924 F11 / F12 + #3122).
    test(
      'lock-recovery designated buyer with budget < pricePerUnit emits no '
      'liquidity bid and still preserves mutual exclusion on offers',
      () {
        const grain = 'grain';
        const grainPrice = 10;
        // gp1 is broke (treasury 0 < cheapestRegimentBuildTreasuryCost)
        // so `_anyBrokeGreatPower(game)` is true and lock-recovery rotation
        // selects from the affluent pool that includes gp2.
        var stockpile = const Stockpile().applyDelta(grain, 200);
        for (final commodity in CommodityCatalog.all) {
          if (richesCommodityIds.contains(commodity.id)) continue;
          if (commodity.id == grain) continue;
          stockpile = stockpile.applyDelta(commodity.id, 4);
        }
        final affluentTreasury = treasuryAffluenceThreshold();
        // One pending peasant_levies build consumes the entire affluent
        // treasury (buildTreasuryCost == 2000 == affluentTreasury), so
        // `treasuryBudgetForBids` collapses to 0 and the synthetic grain
        // bid's affordable quantity drops to floor(0 / 10) = 0.
        final base = treasuryBudgetTestGameFor(
          stockpile: stockpile,
          treasury: 0,
          prices: const {grain: grainPrice, 'fabric': 40},
          lastTurnActivity: const {
            grain: MarketActivity(
              totalBidQuantity: 0,
              totalOfferQuantity: 100,
              filledQuantity: 0,
            ),
          },
        );
        final gp2Stockpile = const Stockpile()
            .applyDelta(grain, 100)
            .applyDelta(CommodityCatalog.fabric.id, 4);
        final game = base.copyWith(
          players: [
            ...base.players,
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              capitalProvinceId: 'oldWorld|p2',
              stockpile: gp2Stockpile,
              workerPool: const WorkerPool(peasants: 5),
              treasury: affluentTreasury,
            ),
          ],
        );
        expect(
          lockRecoveryDesignatedBuyerId(game),
          'gp2',
          reason: 'Fixture invariant: gp1 is broke and gp2 is the only '
              'affluent GP, so the rotation must pick gp2.',
        );
        const pendingBuild = BuildUnitOrder(
          unitType: 'peasant_levies',
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p2',
        );
        final currentOrders = const Orders(
          buildUnitOrdersByPlayerId: {
            'gp2': [pendingBuild],
          },
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp2',
          stockpile: gp2Stockpile,
          productionAssignments: const [],
          treasury: affluentTreasury,
          currentOrders: currentOrders,
        ));
        final grainBids = treasuryBudgetTestBids(orders).where((b) => b.commodityId == grain);
        final grainOffers = orders.where(
          (o) => o.type == TradeOrderType.offer && o.commodityId == grain,
        );
        expect(
          grainBids,
          isEmpty,
          reason: 'Lock-recovery designated buyer with '
              'treasuryBudgetForBids == 0 < grainPrice must not emit a '
              'grain bid (affordableQty == 0).',
        );
        expect(
          grainOffers,
          isEmpty,
          reason: 'Mutual exclusion: even when the synthetic liquidity '
              'bid drops, the designated buyer must not offer the '
              'liquidity commodity — `_applyLockRecoveryLiquidityBid` '
              'removes it from `available` before the affordability '
              'check.',
        );
      },
    );
  });
}
