import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('clearUnitCurrentWork', () {
    test('returns game unchanged when unit has no currentWork', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: playerId),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
      );
      final result = clearUnitCurrentWork(game, 'u1');
      expect(identical(result, game), isTrue);
    });

    test('clears currentWork, restores origin tile, and sets status idle', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: 'oldWorld|p1|0|0',
        originTileKey: 'oldWorld|p1|0|0',
        assignedTileKey: 'oldWorld|p1|1|0',
        status: UnitStatus.working,
        currentWork: CurrentWork(
          workTarget: kWorkTargetBuildImprovement,
          tileKey: 'oldWorld|p1|1|0',
          totalTurns: 2,
          remainingTurns: 1,
        ),
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: playerId),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
      );
      final result = clearUnitCurrentWork(game, 'u1');
      expect(result.worldState.oldWorld.units.length, 1);
      expect(result.worldState.oldWorld.units.single.currentWork, isNull);
      expect(result.worldState.oldWorld.units.single.status, UnitStatus.idle);
      expect(
        result.worldState.oldWorld.units.single.tileKey,
        'oldWorld|p1|0|0',
      );
      expect(result.worldState.oldWorld.units.single.originTileKey, isNull);
      expect(result.worldState.oldWorld.units.single.assignedTileKey, isNull);
    });
  });
}
