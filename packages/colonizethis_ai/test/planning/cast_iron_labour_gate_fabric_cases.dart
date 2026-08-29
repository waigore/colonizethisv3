import 'package:colonizethis_ai/src/planning/cast_iron_labour_gate.dart'
    show
        isCastIronLabourPeasantRecruitFabricMarketPathActive,
        isCastIronLabourPeasantRecruitFabricShort,
        isDomesticFabricProductionLabourInfeasible;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/lock_recovery_seller_test_support.dart';

void registerCastIronLabourGateFabricCases() {
  group('isDomesticFabricProductionLabourInfeasible (Refs #2847)', () {
    test('positive: material-feasible fabric recipe with labour below one run', () {
      final game = buildCastIronLabourLockRecoverySellerGame(
        workerPool: const WorkerPool(peasants: 1),
        stockpile: Stockpile.empty
            .applyDelta('iron', 4)
            .applyDelta('coal', 1)
            .applyDelta('wool', 5)
            .applyDelta('grain', 10),
      );
      expect(
        isDomesticFabricProductionLabourInfeasible(
          game: game,
          playerId: kCastIronLabourLockRecoverySellerId,
        ),
        isTrue,
      );
    });

    test('negative: enough labour to run at least one fabric recipe', () {
      final game = buildCastIronLabourLockRecoverySellerGame(
        workerPool: const WorkerPool(peasants: 2),
        stockpile: Stockpile.empty
            .applyDelta('iron', 4)
            .applyDelta('coal', 1)
            .applyDelta('wool', 5)
            .applyDelta('grain', 20),
      );
      expect(
        isDomesticFabricProductionLabourInfeasible(
          game: game,
          playerId: kCastIronLabourLockRecoverySellerId,
        ),
        isFalse,
      );
    });

    test('negative: no material-feasible fabric recipe', () {
      final game = buildCastIronLabourLockRecoverySellerGame(
        workerPool: const WorkerPool(peasants: 1),
        stockpile: Stockpile.empty
            .applyDelta('iron', 4)
            .applyDelta('coal', 1)
            .applyDelta('grain', 10),
      );
      expect(
        isDomesticFabricProductionLabourInfeasible(
          game: game,
          playerId: kCastIronLabourLockRecoverySellerId,
        ),
        isFalse,
      );
    });
  });

  group('isCastIronLabourPeasantRecruitFabricMarketPathActive (Refs #2847)', () {
    test('true for population-bound seller short peasant fabric cost', () {
      final game = buildCastIronLabourLockRecoverySellerGame(
        workerPool: const WorkerPool(peasants: 1),
        stockpile: Stockpile.empty
            .applyDelta('iron', 4)
            .applyDelta('coal', 1)
            .applyDelta('fabric', 1)
            .applyDelta('grain', 10),
      );
      expect(
        isCastIronLabourPeasantRecruitFabricMarketPathActive(
          game: game,
          playerId: kCastIronLabourLockRecoverySellerId,
          projected: game.players.first.stockpile,
        ),
        isTrue,
      );
    });

    test('false when fabric meets peasant recruit cost', () {
      final game = buildCastIronLabourLockRecoverySellerGame(
        workerPool: const WorkerPool(peasants: 1),
        stockpile: Stockpile.empty
            .applyDelta('iron', 4)
            .applyDelta('coal', 1)
            .applyDelta('fabric', 2)
            .applyDelta('grain', 10),
      );
      expect(
        isCastIronLabourPeasantRecruitFabricMarketPathActive(
          game: game,
          playerId: kCastIronLabourLockRecoverySellerId,
          projected: game.players.first.stockpile,
        ),
        isFalse,
      );
    });
  });

  group('isCastIronLabourPeasantRecruitFabricShort (Refs #2847)', () {
    test('true when fabric is below the peasant recruit cost of 2', () {
      expect(
        isCastIronLabourPeasantRecruitFabricShort(
          const Stockpile(quantities: {'fabric': 1}),
        ),
        isTrue,
      );
      expect(
        isCastIronLabourPeasantRecruitFabricShort(Stockpile.empty),
        isTrue,
      );
    });

    test('false when fabric meets the peasant recruit cost of 2', () {
      expect(
        isCastIronLabourPeasantRecruitFabricShort(
          const Stockpile(quantities: {'fabric': 2}),
        ),
        isFalse,
      );
    });
  });
}
