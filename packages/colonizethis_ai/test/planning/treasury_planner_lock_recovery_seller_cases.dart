// Case bodies for `treasury_planner_test.dart` (Refs #3997 Phase 8).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'treasury_planner_main_support.dart';

void registerTreasuryPlannerLockRecoverySellerCases() {
group('lock-recovery seller food-surplus release (Refs #2924 F17)', () {
    test(
      'below-quota zero-NW seller releases food above one consumption cycle',
      () {
        // grain reserve for the seller is consumption (8) with the 2x safety
        // buffer dropped, so grain 16 yields surplus 8 -> an urgent offer.
        final stockpile = const Stockpile().applyDelta('grain', 16);
        final game = treasuryPlannerTestLockRecoverySellerGame(stockpile: stockpile, treasury: 0);
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        ));
        final grainOffers = orders
            .where(
              (o) => o.type == TradeOrderType.offer && o.commodityId == 'grain',
            )
            .toList();
        expect(
          grainOffers,
          isNotEmpty,
          reason: 'F17: a broke lock-recovery seller drops the 2x food safety '
              'buffer so grain above one consumption cycle is offered.',
        );
        expect(grainOffers.first.priority, kTreasuryOfferPriorityUrgent);
        expect(grainOffers.first.quantity, greaterThan(0));
      },
    );

    test(
      'seller food reserve floor equals one consumption cycle (no offer at 8)',
      () {
        // grain 8 == consumption: surplus 0, so no offer. This pins the food
        // reserve at exactly `consumption` (safety buffer == 0) for sellers,
        // distinguishing F17 from the 1x (reserve 16) and 2x (reserve 24)
        // buffers.
        final stockpile = const Stockpile().applyDelta('grain', 8);
        final game = treasuryPlannerTestLockRecoverySellerGame(stockpile: stockpile, treasury: 0);
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        ));
        expect(
          orders.where(
            (o) => o.type == TradeOrderType.offer && o.commodityId == 'grain',
          ),
          isEmpty,
        );
      },
    );

    test(
      'non-seller GP keeps the 2x food safety buffer (negative control)',
      () {
        // gp1 owns a single OW province -> not a lock-recovery seller. grain 16
        // is below the 2x reserve (24), so no offer is emitted.
        final stockpile = const Stockpile().applyDelta('grain', 16);
        final game = treasuryPlannerTestGameWithStockpile(stockpile: stockpile, treasury: 0);
        final orders = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        ));
        expect(
          orders.where(
            (o) => o.type == TradeOrderType.offer && o.commodityId == 'grain',
          ),
          isEmpty,
          reason: 'A non-seller GP retains the 2x food safety buffer, so grain '
              '16 < reserve 24 yields no surplus offer.',
        );
      },
    );

    test('seller food-release path is deterministic', () {
      final stockpile = const Stockpile().applyDelta('grain', 20);
      final game = treasuryPlannerTestLockRecoverySellerGame(stockpile: stockpile, treasury: 0);
      final a = runTreasuryPlanner(TreasuryPlannerInput(
        game: game,
        playerId: 'gp1',
        stockpile: stockpile,
        productionAssignments: const [],
        treasury: 0,
      ));
      final b = runTreasuryPlanner(TreasuryPlannerInput(
        game: game,
        playerId: 'gp1',
        stockpile: stockpile,
        productionAssignments: const [],
        treasury: 0,
      ));
      expect(a, b);
    });

    test(
      'snapshot province counts match world-state scans (Refs #3288)',
      () {
        final stockpile = const Stockpile().applyDelta('grain', 20);
        final game = treasuryPlannerTestLockRecoverySellerGame(stockpile: stockpile, treasury: 0);
        const snapshot = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(oldWorldProvincesOwned: 3),
          colonial: ColonialSummary(newWorldProvincesOwned: 0),
          economy: EconomySummary(treasury: 0),
          relations: {},
        );
        final withoutSnapshot = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
        ));
        final withSnapshot = runTreasuryPlanner(TreasuryPlannerInput(
          game: game,
          playerId: 'gp1',
          stockpile: stockpile,
          productionAssignments: const [],
          treasury: 0,
          snapshot: snapshot,
        ));
        expect(withSnapshot, withoutSnapshot);
      },
    );
  });
}
