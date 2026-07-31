import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _twoProvinceSpyGame() {
  return Game(
    id: 'g1',
    players: const [
      Player(id: 'h1', displayName: 'Human', isHuman: true),
      Player(id: 'gp2', displayName: 'Rival', isHuman: false),
    ],
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            displayName: 'Home',
            ownerId: 'h1',
          ),
          Province(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            displayName: 'Rival Land',
            ownerId: 'gp2',
          ),
        ],
        units: [
          Unit(
            id: 'spy1',
            type: kUnitTypeSpy,
            ownerId: 'h1',
            locationProvinceId: 'oldWorld|p2',
            tileKey: 'oldWorld|p2|0|0',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
  );
}

void main() {
  group('spyLeaveIntelWarningNeeded', () {
    const humanId = 'h1';

    test('warns when last Spy would leave foreign province', () {
      final game = _twoProvinceSpyGame();
      expect(
        spyLeaveIntelWarningNeeded(
          game: game,
          orders: const Orders(),
          humanPlayerId: humanId,
          spyUnitId: 'spy1',
          newDestinationTileKey: 'oldWorld|p1|0|0',
        ),
        isTrue,
      );
    });

    test('no warning when another Spy remains in foreign province', () {
      final game = Game(
        id: 'g1',
        players: const [
          Player(id: 'h1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'Rival', isHuman: false),
        ],
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                displayName: 'Home',
                ownerId: 'h1',
              ),
              Province(
                id: 'oldWorld|p2',
                regionId: 'oldWorld',
                displayName: 'Rival Land',
                ownerId: 'gp2',
              ),
            ],
            units: [
              Unit(
                id: 'spy1',
                type: kUnitTypeSpy,
                ownerId: 'h1',
                locationProvinceId: 'oldWorld|p2',
                tileKey: 'oldWorld|p2|0|0',
              ),
              Unit(
                id: 'spy2',
                type: kUnitTypeSpy,
                ownerId: 'h1',
                locationProvinceId: 'oldWorld|p2',
                tileKey: 'oldWorld|p2|1|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
      );
      expect(
        spyLeaveIntelWarningNeeded(
          game: game,
          orders: const Orders(),
          humanPlayerId: humanId,
          spyUnitId: 'spy1',
          newDestinationTileKey: 'oldWorld|p1|0|0',
        ),
        isFalse,
      );
    });
  });
}
