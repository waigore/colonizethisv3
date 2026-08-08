// Case bodies for `treasury_planner_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Case bodies for `treasury_planner_test.dart` (Refs #3997 Phase 8).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'treasury_planner_main_support.dart';


void registerTreasuryPlannerCoreReserveCases() {
  group('runTreasuryPlanner(TreasuryPlannerInput(Refs #2994))', () {
    test(
      'lock-recovery designated buyer bids liquid food at urgent priority '
      'and does not offer that commodity (Refs #2924 F11/F12)',
      () {
        var stockpile = const Stockpile().applyDelta('grain', 200);
        for (final commodity in CommodityCatalog.all) {
          if (richesCommodityIds.contains(commodity.id)) continue;
          if (commodity.id == 'grain') continue;
          stockpile = stockpile.applyDelta(commodity.id, 4);
        }
        final affluentTreasury = cheapestRegimentBuildTreasuryCost() + 100;
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: stockpile,
          treasury: 0,
          turnNumber: 0,
          extraPlayers: [
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              capitalProvinceId: 'oldWorld|p2',
              stockpile: Stockpile.empty,
              treasury: affluentTreasury,
            ),
          ],
        ).copyWith(
          worldMarketState: WorldMarketState.withDefaultPrices(const {
            'grain': 10,
            'timber': 20,
          }).copyWith(
            lastTurnActivity: {
              'grain': const MarketActivity(
                totalBidQuantity: 0,
                totalOfferQuantity: 100,
                filledQuantity: 0,
              ),
            },
          ),
        );
        expect(
          lockRecoveryDesignatedBuyerId(game),
          'gp2',
          reason: 'gp2 is the affluent GP and gp1 is broke, so the F12 '
              'affluent-only rotation selects gp2 as designated buyer.',
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp2',
          stockpile: Stockpile.empty,
          productionAssignments: const [],
          treasury: affluentTreasury,
        ));
        final grainBids = orders
            .where((o) => o.type == TradeOrderType.bid && o.commodityId == 'grain');
        final grainOffers = orders
            .where((o) => o.type == TradeOrderType.offer && o.commodityId == 'grain');
        expect(grainBids, isNotEmpty);
        expect(grainOffers, isEmpty);
        expect(
          grainBids.first.priority,
          kTreasuryOfferPriorityUrgent,
          reason: 'F12 forces the affluent designated buyer\'s liquidity bid '
              'to the urgent tier even though its own forecast is above the '
              'regiment threshold.',
        );
      },
    );

    test(
      'all-broke campaign: no GP liquidity buyer — phase-13 minor bids (F15)',
      () {
        final stockpile = const Stockpile().applyDelta('grain', 8);
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'gp1',
              displayName: 'GP1',
              isHuman: false,
              stockpile: stockpile,
              treasury: 50,
            ),
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              stockpile: Stockpile.empty,
              treasury: 80,
            ),
          ],
          worldMarketState: WorldMarketState.withDefaultPrices(const {
            'grain': 10,
          }).copyWith(
            lastTurnActivity: {
              'grain': const MarketActivity(
                totalBidQuantity: 0,
                totalOfferQuantity: 100,
                filledQuantity: 0,
              ),
            },
          ),
        );
        expect(
          isLockRecoveryLiquidityBuyer(
            game: game,
            playerId: 'gp2',
            treasuryBudgetForBids: 80,
            treasuryForecast: 80,
          ),
          isFalse,
          reason: 'F15 buy-side is logic-phase minor auto-bids when no GP is '
              'affluent.',
        );
        final gp2Orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp2',
          stockpile: Stockpile.empty,
          productionAssignments: const [],
          treasury: 80,
        ));
        expect(
          gp2Orders.where(
            (o) => o.type == TradeOrderType.bid && o.commodityId == 'grain',
          ),
          isEmpty,
        );
      },
    );

    test(
      'broke non-designated GP emits offers only when forecast is above '
      'regiment threshold (Refs #2924 F13)',
      () {
        final stockpile = const Stockpile().applyDelta('grain', 500);
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: stockpile,
          treasury: 50,
          turnNumber: 1,
          extraPlayers: const [
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              capitalProvinceId: 'oldWorld|p2',
              stockpile: Stockpile.empty,
              treasury: 100,
            ),
          ],
        ).copyWith(
          worldMarketState: WorldMarketState.withDefaultPrices(const {
            'grain': 10,
          }).copyWith(
            lastTurnActivity: {
              'grain': const MarketActivity(
                totalBidQuantity: 0,
                totalOfferQuantity: 100,
                filledQuantity: 100,
              ),
            },
          ),
        );
        expect(lockRecoveryDesignatedBuyerId(game), isEmpty);
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 50,
        ));
        expect(
          orders.where((o) => o.type == TradeOrderType.bid),
          isEmpty,
          reason: 'Actual treasury 50 < 2000 must keep gp1 on offers-only '
              'even when F8 forecast inflow would exceed the threshold.',
        );
        expect(
          orders.where((o) => o.type == TradeOrderType.offer),
          isNotEmpty,
        );
        for (final offer in orders.where((o) => o.type == TradeOrderType.offer)) {
          expect(
            offer.priority,
            kTreasuryOfferPriorityUrgent,
            reason: 'Refs #2924 F16: actual treasury below regiment threshold '
                'must keep offers on the urgent tier even when F8 forecast '
                'exceeds the threshold.',
          );
        }
      },
    );

    test(
      'broke GP keeps urgent offer tier at treasury 1999 when forecast clears '
      'threshold (Refs #2924 F16)',
      () {
        final stockpile = const Stockpile().applyDelta('grain', 500);
        final game = treasuryPlannerTestGameWithStockpile(
          stockpile: stockpile,
          treasury: 1999,
          turnNumber: 1,
        ).copyWith(
          worldMarketState: WorldMarketState.withDefaultPrices(const {
            'grain': 10,
          }).copyWith(
            lastTurnActivity: {
              'grain': const MarketActivity(
                totalBidQuantity: 0,
                totalOfferQuantity: 100,
                filledQuantity: 100,
              ),
            },
          ),
        );
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 1999,
        ));
        final offers = orders.where((o) => o.type == TradeOrderType.offer);
        expect(offers, isNotEmpty);
        for (final offer in offers) {
          expect(offer.priority, kTreasuryOfferPriorityUrgent);
        }
      },
    );

    test('deterministic for identical inputs', () {
      final stockpile = const Stockpile().applyDelta('timber', 60);
      final game = treasuryPlannerTestGameWithStockpile(stockpile: stockpile, treasury: 10);
      final a = runTreasuryPlanner(TreasuryPlannerInput(
        game: game,
        playerId: 'gp1',
        stockpile: stockpile,
        productionAssignments: const [],
        treasury: 10,
      ));
      final b = runTreasuryPlanner(TreasuryPlannerInput(
        game: game,
        playerId: 'gp1',
        stockpile: stockpile,
        productionAssignments: const [],
        treasury: 10,
      ));
      expect(a, b);
    });
  });
}
