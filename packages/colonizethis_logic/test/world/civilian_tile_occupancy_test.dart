import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/src/world/civilian_tile_occupancy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('civilianMayOccupyLandTileKey', () {
    const ow = 'oldWorld';
    const tileP2 = '$ow|p2|0|0';

    Game gameWithProvinces(List<Province> provinces) => Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(provinces: provinces, units: const []),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
          ],
        );

    test('Spy may occupy another Great Power province tile', () {
      final game = gameWithProvinces([
        Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
        Province(id: '$ow|p2', regionId: ow, ownerId: 'gp2'),
      ]);
      expect(
        civilianMayOccupyLandTileKey(
          game: game,
          playerId: 'gp1',
          unitType: 'Spy',
          destinationTileKey: tileP2,
        ),
        isTrue,
      );
    });

    test('Builder may not occupy another Great Power province without purchase', () {
      final game = gameWithProvinces([
        Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
        Province(id: '$ow|p2', regionId: ow, ownerId: 'gp2'),
      ]);
      expect(
        civilianMayOccupyLandTileKey(
          game: game,
          playerId: 'gp1',
          unitType: 'Builder',
          destinationTileKey: tileP2,
        ),
        isFalse,
      );
    });

    test('purchased tile allows Builder on tile inside other GP province', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'gp2'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          purchasedTilesByTileKey: {tileP2: 'gp1'},
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
      );
      expect(
        civilianMayOccupyLandTileKey(
          game: game,
          playerId: 'gp1',
          unitType: 'Builder',
          destinationTileKey: tileP2,
        ),
        isTrue,
      );
    });
  });
}
