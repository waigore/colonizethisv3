// Case bodies for `treasury_planner_treasury_budget_test.dart`
// (Refs #3997 Phase 8). Registered from the thin contract; pin coverage
// preserved 1:1 from the former inline suite.

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_planner_treasury_budget_support.dart';

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

    // SPEC/ai/treasury-planner.md § Treasury-budget-aware bid sizing —
    // AC5: when the affluent-speculative pass picks commodity C but the
    // running treasury budget cannot fund the full
    // `kSpeculativeBidStockpileTarget` (= 8) units, the emitted bid
    // quantity equals the affordable floor `budget ~/ price`, not the
    // stockpile target. The bid is only dropped when that floor is `0`
    // (Refs #3122).
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
