import 'package:colonizethis_ai/src/planning/cast_iron_labour_gate.dart'
    show
        isCastIronLabourPeasantRecruitFabricShort,
        isCastIronLabourPopulationBoundForLockRecoverySeller,
        otherGreatPowerFabricHeld;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _playerId = 'gp5';
const _tileTimber = 'oldWorld|p0|2|0';

Game _lockRecoverySellerGame({
  required WorkerPool workerPool,
  required Stockpile stockpile,
}) {
  return Game(
    id: 'g-castiron-labour',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < 5; i++)
            Province(
              id: 'oldWorld|p$i',
              regionId: kRegionOldWorld,
              ownerId: _playerId,
            ),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {_tileTimber: 'timber'},
      tileKeysByRegionAndProvince: const {
        kRegionOldWorld: {
          'oldWorld|p0': [_tileTimber],
        },
      },
    ),
    players: [
      Player(
        id: _playerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: stockpile,
        workerPool: workerPool,
      ),
    ],
  );
}

void main() {
  group('isCastIronLabourPopulationBoundForLockRecoverySeller (Refs #2847)', () {
    test(
      'positive: material-feasible castIron with fed workers below one run',
      () {
        final game = _lockRecoverySellerGame(
          workerPool: const WorkerPool(peasants: 2),
          stockpile: Stockpile.empty
              .applyDelta(CommodityCatalog.timber.id, 2)
              .applyDelta(CommodityCatalog.iron.id, 2)
              .applyDelta(CommodityCatalog.grain.id, 10),
        );
        expect(
          selfLockRecoverySellerStageableImprovementInputs(game, _playerId),
          contains(CommodityCatalog.castIron.id),
        );
        expect(
          isCastIronLabourPopulationBoundForLockRecoverySeller(
            game: game,
            playerId: _playerId,
          ),
          isTrue,
        );
      },
    );

    test(
      'negative: enough peasants to run castIron when fully fed',
      () {
        final game = _lockRecoverySellerGame(
          workerPool: const WorkerPool(peasants: 5),
          stockpile: Stockpile.empty
              .applyDelta(CommodityCatalog.timber.id, 2)
              .applyDelta(CommodityCatalog.iron.id, 2)
              .applyDelta(CommodityCatalog.grain.id, 10),
        );
        expect(
          isCastIronLabourPopulationBoundForLockRecoverySeller(
            game: game,
            playerId: _playerId,
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
                  ownerId: _playerId,
                ),
              ],
              units: [
                Unit(
                  id: 'r1',
                  type: 'peasant_levies',
                  ownerId: _playerId,
                  locationProvinceId: 'oldWorld|p0',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: _playerId,
              displayName: 'Healthy',
              isHuman: false,
              workerPool: const WorkerPool(peasants: 1),
              stockpile: Stockpile.empty
                  .applyDelta(CommodityCatalog.timber.id, 2)
                  .applyDelta(CommodityCatalog.iron.id, 2),
            ),
          ],
        );
        expect(
          isCastIronLabourPopulationBoundForLockRecoverySeller(
            game: game,
            playerId: _playerId,
          ),
          isFalse,
        );
      },
    );
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
