import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../world_test_support/world_test_support.dart';

void main() {
  group('resolveNavalCombineTargetFleetId', () {
    test(
      'Given empty prefer-order When resolving Then throws LogicValidationException',
      () {
        expect(
          () => resolveNavalCombineTargetFleetId(
            humanPlayerId: 'gp_human',
            fleetIdsInPreferOrder: const [],
          ),
          throwsA(isA<LogicValidationException>()),
        );
      },
    );
  });

  group('applyNavalCombineFleets', () {
    test('merges ships into Home Fleet when Home is included', () {
      final homeId = homeFleetIdFor('gp_human');
      final game = gameWithFleets(
        fleets: [
          Fleet(
            id: '2',
            ownerId: 'gp_human',
            regionId: 'oldWorld',
            inPortAtProvinceId: 'oldWorld|cap',
            ships: const [ShipInstance(id: 's2', typeId: 'carrack')],
          ),
          Fleet(
            id: homeId,
            ownerId: 'gp_human',
            regionId: 'oldWorld',
            inPortAtProvinceId: 'oldWorld|cap',
            ships: const [ShipInstance(id: 's1', typeId: 'fluyte')],
          ),
        ],
      );
      final next = applyNavalCombineFleets(
        game: game,
        humanPlayerId: 'gp_human',
        fleetIds: ['2', homeId],
      );
      expect(next.worldState.fleets, hasLength(1));
      final merged = next.worldState.fleets.single;
      expect(merged.id, homeId);
      expect(merged.ships.map((s) => s.id), ['s1', 's2']);
      expect(merged.mission, FleetMission.none);
    });

    test('merges at-sea fleets into first prefer-order id when no Home', () {
      final game = gameWithFleets(
        fleets: [
          Fleet(
            id: 'b',
            ownerId: 'gp_human',
            regionId: 'oldWorld',
            seaZoneId: 'sea_a',
            ships: const [ShipInstance(id: 'sb', typeId: 'carrack')],
          ),
          Fleet(
            id: 'a',
            ownerId: 'gp_human',
            regionId: 'oldWorld',
            seaZoneId: 'sea_a',
            ships: const [ShipInstance(id: 'sa', typeId: 'fluyte')],
          ),
        ],
      );
      final next = applyNavalCombineFleets(
        game: game,
        humanPlayerId: 'gp_human',
        fleetIds: const ['b', 'a'],
      );
      expect(next.worldState.fleets, hasLength(1));
      expect(next.worldState.fleets.single.id, 'b');
      expect(
        next.worldState.fleets.single.ships.map((s) => s.id),
        ['sb', 'sa'],
      );
    });

    test('rejects mixed port and sea locality', () {
      final game = gameWithFleets(
        fleets: [
          Fleet(
            id: '1',
            ownerId: 'gp_human',
            regionId: 'oldWorld',
            inPortAtProvinceId: 'oldWorld|cap',
            ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
          ),
          Fleet(
            id: '2',
            ownerId: 'gp_human',
            regionId: 'oldWorld',
            seaZoneId: 'sea_a',
            ships: const [ShipInstance(id: 's2', typeId: 'carrack')],
          ),
        ],
      );
      final next = applyNavalCombineFleets(
        game: game,
        humanPlayerId: 'gp_human',
        fleetIds: const ['1', '2'],
      );
      expect(next, same(game));
    });
  });
}
