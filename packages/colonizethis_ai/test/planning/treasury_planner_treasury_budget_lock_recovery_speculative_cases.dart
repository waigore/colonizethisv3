// Case bodies for `treasury_planner_treasury_budget_test.dart`
// (Refs #3997 Phase 8). Registered from the thin contract; pin coverage
// preserved 1:1 from the former inline suite.

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_planner_treasury_budget_support.dart';
import 'treasury_planner_treasury_budget_lock_recovery_speculative_cases_tail_cases.dart';

void registerTreasuryPlannerTreasuryBudgetLockRecoverySpeculativeCases() {
  group('runTreasuryPlanner per-bid treasury clamp — lock-recovery & speculative (Refs #3122)', () {
    test(
      'lock-recovery designated buyer respects treasury budget: liquidity '
      'bid notional + pending costs <= original treasury',
      () {
        const grain = 'grain';
        // gp1 broke (forces lock recovery), gp2 affluent designated buyer.
        var stockpile = const Stockpile().applyDelta(grain, 200);
        for (final commodity in CommodityCatalog.all) {
          if (richesCommodityIds.contains(commodity.id)) continue;
          if (commodity.id == grain) continue;
          stockpile = stockpile.applyDelta(commodity.id, 4);
        }
        const grainPrice = 10;
        final affluentTreasury =
            cheapestRegimentBuildTreasuryCost() + 100;
        final game = treasuryBudgetTestGameFor(
          stockpile: stockpile,
          treasury: 0,
          prices: {grain: grainPrice, 'timber': 20},
          lastTurnActivity: {
            grain: const MarketActivity(
              totalBidQuantity: 0,
              totalOfferQuantity: 100,
              filledQuantity: 0,
            ),
          },
        );
        final game2 = game.copyWith(
          players: [
            ...game.players,
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              capitalProvinceId: 'oldWorld|p2',
              stockpile: const Stockpile()
                  .applyDelta(CommodityCatalog.fabric.id, 4),
              workerPool: const WorkerPool(peasants: 5),
              treasury: affluentTreasury,
            ),
          ],
        );
        expect(lockRecoveryDesignatedBuyerId(game2), 'gp2');
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
          game: game2,
          playerId: 'gp2',
          stockpile: game2.players[1].stockpile,
          productionAssignments: const [],
          treasury: affluentTreasury,
          currentOrders: currentOrders,
        ));
        final grainBids = treasuryBudgetTestBids(orders).where((b) => b.commodityId == grain);
        final grainOffers = orders.where(
          (o) =>
              o.type == TradeOrderType.offer && o.commodityId == grain,
        );
        // Mutual exclusion must always hold for the designated buyer's
        // liquidity commodity (Refs #2924 F11 / F12).
        expect(grainOffers, isEmpty,
            reason: 'Mutual exclusion: designated buyer must not offer the '
                'liquidity food commodity.');
        // Budget invariant: cumulative bid notional must fit within the
        // remaining treasury after one pending peasant_levies build (2000).
        const peasantCost = 2000;
        final totalNotional = grainBids.fold<int>(
          0,
          (s, b) => s + b.quantity * grainPrice,
        );
        expect(
          totalNotional + peasantCost,
          lessThanOrEqualTo(affluentTreasury),
          reason: 'Liquidity bid notional + pending build cost must not '
              'exceed gp2 starting treasury (the matcher would clamp).',
        );
      },
    );

    test(
      'lock-recovery liquidity bid uses full treasury budget not F10 '
      'stockpile-target cap (Refs #2924 F14)',
      () {
        const grain = 'grain';
        const grainPrice = 10;
        final affluentTreasury =
            cheapestRegimentBuildTreasuryCost() + 100;
        final baseGame = treasuryBudgetTestGameFor(
          stockpile: const Stockpile().applyDelta(grain, 200),
          treasury: 0,
          prices: {grain: grainPrice},
          lastTurnActivity: {
            grain: const MarketActivity(
              totalBidQuantity: 0,
              totalOfferQuantity: 50,
              filledQuantity: 0,
            ),
          },
        );
        final game = baseGame.copyWith(
          players: [
            ...baseGame.players,
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              capitalProvinceId: 'oldWorld|p2',
              stockpile: Stockpile.empty,
              treasury: affluentTreasury,
            ),
          ],
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp2',
          stockpile: Stockpile.empty,
          productionAssignments: const [],
          treasury: affluentTreasury,
        ));
        final grainBid = treasuryBudgetTestBids(orders).firstWhere(
          (b) => b.commodityId == grain,
        );
        expect(
          grainBid.quantity,
          greaterThan(kSpeculativeBidStockpileTarget),
          reason: 'F14 removes the kSpeculativeBidStockpileTarget (= 8) '
              'ceiling; quantity may still be cargo-capped below '
              'treasuryBudgetForBids ~/ price.',
        );
        expect(
          grainBid.quantity * grainPrice,
          lessThanOrEqualTo(affluentTreasury),
        );
      },
    );
  });

  registerTreasuryPlannerTreasuryBudgetLockRecoverySpeculativeCasesTail();
}
