// Tail case bodies for `treasury_planner_core_reserve_cases.dart`.

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'treasury_planner_main_support.dart';

void registerTreasuryPlannerCoreReserveTailCases() {
  group('runTreasuryPlanner(TreasuryPlannerInput(Refs #2994))', () {
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
