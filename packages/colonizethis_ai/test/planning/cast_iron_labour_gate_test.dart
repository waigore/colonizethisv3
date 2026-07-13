import 'package:colonizethis_ai/src/planning/cast_iron_labour_gate.dart'
    show
        isCastIronLabourPeasantRecruitFabricMarketPathActive,
        isCastIronLabourPeasantRecruitFabricShort,
        isCastIronLabourPopulationBoundForLockRecoverySeller,
        isDomesticFabricProductionLabourInfeasible,
        otherGreatPowerFabricHeld;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/lock_recovery_seller_test_support.dart';

void main() {
  group('isCastIronLabourPopulationBoundForLockRecoverySeller (Refs #2847)', () {
    test(
      'positive: material-feasible castIron with fed workers below one run',
      () {
        final game = buildCastIronLabourLockRecoverySellerGame(
          workerPool: const WorkerPool(peasants: 1),
          stockpile: Stockpile.empty
              .applyDelta(CommodityCatalog.iron.id, 4)
              .applyDelta(CommodityCatalog.grain.id, 10),
        );
        expect(
          isCastIronLabourPopulationBoundForLockRecoverySeller(
            game: game,
            playerId: kCastIronLabourLockRecoverySellerId,
          ),
          isTrue,
        );
      },
    );

    test(
      'negative: enough peasants to run castIron when fully fed',
      () {
        final game = buildCastIronLabourLockRecoverySellerGame(
          workerPool: const WorkerPool(peasants: 2),
          stockpile: Stockpile.empty
              .applyDelta(CommodityCatalog.iron.id, 4)
              .applyDelta(CommodityCatalog.grain.id, 10),
        );
        expect(
          isCastIronLabourPopulationBoundForLockRecoverySeller(
            game: game,
            playerId: kCastIronLabourLockRecoverySellerId,
          ),
          isFalse,
        );
      },
    );

    test(
      'negative: healthy GP holding a regiment is out of scope',
      () {
        final game = Game(
          id: 'g-healthy',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p0',
                  regionId: kRegionOldWorld,
                  ownerId: kCastIronLabourLockRecoverySellerId,
                ),
              ],
              units: [
                Unit(
                  id: 'r1',
                  type: 'peasant_levies',
                  ownerId: kCastIronLabourLockRecoverySellerId,
                  locationProvinceId: 'oldWorld|p0',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: kCastIronLabourLockRecoverySellerId,
              displayName: 'Healthy',
              isHuman: false,
              workerPool: const WorkerPool(peasants: 1),
              stockpile: Stockpile.empty
                  .applyDelta(CommodityCatalog.iron.id, 4),
            ),
          ],
        );
        expect(
          isCastIronLabourPopulationBoundForLockRecoverySeller(
            game: game,
            playerId: kCastIronLabourLockRecoverySellerId,
          ),
          isFalse,
        );
      },
    );
  });

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

  group('otherGreatPowerFabricHeld (Refs #2847)', () {
    Game gameWithFabric(Map<String, int> fabricByPlayerId) {
      return Game(
        id: 'g-market-fabric',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          for (final entry in fabricByPlayerId.entries)
            Player(
              id: entry.key,
              displayName: entry.key,
              isHuman: false,
              stockpile: Stockpile.empty.applyDelta(
                CommodityCatalog.fabric.id,
                entry.value,
              ),
            ),
        ],
      );
    }

    test('positive: sums fabric across all other great powers', () {
      final game = gameWithFabric({'gp5': 0, 'gp1': 3, 'gp2': 4});
      expect(otherGreatPowerFabricHeld(game, 'gp5'), 7);
    });

    test('negative: zero when no other great power holds any fabric', () {
      final game = gameWithFabric({'gp5': 0, 'gp1': 0, 'gp2': 0});
      expect(otherGreatPowerFabricHeld(game, 'gp5'), 0);
    });

    test('excludes the queried seller\'s own fabric holdings', () {
      final game = gameWithFabric({'gp5': 9, 'gp1': 0});
      expect(otherGreatPowerFabricHeld(game, 'gp5'), 0);
    });
  });
}
