import 'package:colonizethis_logic/src/world/unit_lookup.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

void main() {
  group('militaryTypeCountsByPlayer', () {
    test('matches per-player regiment and ship counters', () {
      final game = TestFixtures.minimalGame(
        oldWorld: RegionData(
          provinces: const [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'p1'),
            Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'p2'),
          ],
          units: [
            Unit(
              id: 'u1',
              ownerId: 'p1',
              type: 'grenadiers',
              locationProvinceId: 'oldWorld|p1',
            ),
            Unit(
              id: 'u2',
              ownerId: 'p1',
              type: 'grenadiers',
              locationProvinceId: 'oldWorld|p1',
            ),
            Unit(
              id: 'u3',
              ownerId: 'p2',
              type: 'cavalry',
              locationProvinceId: 'oldWorld|p2',
            ),
          ],
        ),
        newWorld: RegionData(
          provinces: const [
            Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'p1'),
          ],
          units: [
            Unit(
              id: 'u4',
              ownerId: 'p1',
              type: 'artillery',
              locationProvinceId: 'newWorld|n1',
            ),
          ],
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
          Player(id: 'p3', displayName: 'P3', isHuman: false),
        ],
      );
      final world = game.worldState.copyWith(
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p1',
            regionId: 'oldWorld',
            seaZoneId: 'oldWorld|sea1',
            ships: [
              ShipInstance(id: 's1', typeId: 'carrack'),
              ShipInstance(id: 's2', typeId: 'carrack'),
              ShipInstance(id: 's3', typeId: 'fluyte'),
            ],
          ),
          Fleet(
            id: 'f2',
            ownerId: 'p2',
            regionId: 'oldWorld',
            seaZoneId: 'oldWorld|sea2',
            ships: [ShipInstance(id: 's4', typeId: 'brig')],
          ),
        ],
      );

      final aggregated = militaryTypeCountsByPlayer(world);

      for (final playerId in const ['p1', 'p2', 'p3']) {
        expect(
          aggregated.regimentCountsByPlayerId[playerId] ??
              const <String, int>{},
          regimentTypeCountsForPlayer(world, playerId),
        );
        expect(
          aggregated.shipCountsByPlayerId[playerId] ?? const <String, int>{},
          shipTypeCountsForPlayer(world, playerId),
        );
      }
    });
  });
}
