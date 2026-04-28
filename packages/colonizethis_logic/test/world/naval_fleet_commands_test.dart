import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _gameWithFleets(List<Fleet> fleets) {
  return Game(
    id: 'g_naval_split',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: fleets,
    ),
    players: const [
      Player(id: 'gp_human', displayName: 'Human', isHuman: true),
    ],
  );
}

void main() {
  group('applyNavalSplitFleet', () {
    test('Given empty split set When applied Then returns unchanged game', () {
      final original = _gameWithFleets([
        Fleet(
          id: '1',
          ownerId: 'gp_human',
          regionId: 'oldWorld',
          seaZoneId: 'sea_a',
          ships: [ShipInstance(id: 'ship_1', typeId: 'carrack')],
        ),
      ]);

      final next = applyNavalSplitFleet(
        game: original,
        humanPlayerId: 'gp_human',
        originalFleetId: '1',
        shipInstanceIdsToNewFleet: const [],
      );

      expect(next, same(original));
    });

    test(
      'Given existing fleet and selected ships When applied Then creates split fleet and updates original',
      () {
        final original = _gameWithFleets([
          Fleet(
            id: '1',
            ownerId: 'gp_human',
            regionId: 'oldWorld',
            seaZoneId: 'sea_a',
            ships: [
              ShipInstance(id: 'ship_1', typeId: 'carrack'),
              ShipInstance(id: 'ship_2', typeId: 'fluyte'),
            ],
          ),
          Fleet(
            id: '2',
            ownerId: 'gp_human',
            regionId: 'oldWorld',
            seaZoneId: 'sea_b',
            ships: [ShipInstance(id: 'ship_3', typeId: 'carrack')],
          ),
        ]);

        final next = applyNavalSplitFleet(
          game: original,
          humanPlayerId: 'gp_human',
          originalFleetId: '1',
          shipInstanceIdsToNewFleet: const ['ship_2'],
        );

        expect(next.worldState.fleets, hasLength(3));

        final updatedOriginal = next.worldState.fleets.firstWhere(
          (f) => f.id == '1',
        );
        expect(updatedOriginal.ships.map((s) => s.id), ['ship_1']);

        final splitFleet = next.worldState.fleets.firstWhere(
          (f) => f.id == '3',
        );
        expect(splitFleet.ownerId, 'gp_human');
        expect(splitFleet.seaZoneId, 'sea_a');
        expect(splitFleet.ships.map((s) => s.id), ['ship_2']);
        expect(splitFleet.mission, FleetMission.none);
      },
    );

    test(
      'Given Home Fleet split-all When applied Then Home Fleet remains with zero ships',
      () {
        final homeFleetId = homeFleetIdFor('gp_human');
        final original = _gameWithFleets([
          Fleet(
            id: homeFleetId,
            ownerId: 'gp_human',
            regionId: 'oldWorld',
            inPortAtProvinceId: 'oldWorld|capital',
            ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
          ),
          Fleet(
            id: '2',
            ownerId: 'gp_human',
            regionId: 'oldWorld',
            seaZoneId: 'sea_b',
            ships: const [ShipInstance(id: 'ship_3', typeId: 'carrack')],
          ),
        ]);

        final next = applyNavalSplitFleet(
          game: original,
          humanPlayerId: 'gp_human',
          originalFleetId: homeFleetId,
          shipInstanceIdsToNewFleet: const ['ship_1'],
        );

        final homeFleet = next.worldState.fleets.firstWhere(
          (f) => f.id == homeFleetId,
        );
        expect(homeFleet.ships, isEmpty);

        final splitFleet = next.worldState.fleets.firstWhere(
          (f) => f.id == '3',
        );
        expect(splitFleet.ships.map((s) => s.id), ['ship_1']);
      },
    );
  });

  group('applyNavalTransferShipsBetweenFleets', () {
    test(
      'Given subset selected When transferred Then target gains selected and source remains',
      () {
        final game = _gameWithFleets([
          Fleet(
            id: 'source',
            ownerId: 'gp_human',
            regionId: 'oldWorld',
            seaZoneId: 'sea_a',
            ships: const [
              ShipInstance(id: 'ship_1', typeId: 'carrack'),
              ShipInstance(id: 'ship_2', typeId: 'fluyte'),
            ],
          ),
          Fleet(
            id: homeFleetIdFor('gp_human'),
            ownerId: 'gp_human',
            regionId: 'oldWorld',
            inPortAtProvinceId: 'oldWorld|cap',
            ships: const [ShipInstance(id: 'ship_home', typeId: 'carrack')],
          ),
        ]);

        final next = applyNavalTransferShipsBetweenFleets(
          game: game,
          humanPlayerId: 'gp_human',
          sourceFleetId: 'source',
          targetFleetId: homeFleetIdFor('gp_human'),
          shipInstanceIdsToTransfer: const ['ship_2'],
        );

        final source = next.worldState.fleets.firstWhere(
          (f) => f.id == 'source',
        );
        final target = next.worldState.fleets.firstWhere(
          (f) => f.id == homeFleetIdFor('gp_human'),
        );
        expect(source.ships.map((s) => s.id).toList(), ['ship_1']);
        expect(target.ships.map((s) => s.id).toList(), ['ship_home', 'ship_2']);
      },
    );

    test(
      'Given all source ships selected When transferred Then source is removed',
      () {
        final game = _gameWithFleets([
          Fleet(
            id: 'source',
            ownerId: 'gp_human',
            regionId: 'oldWorld',
            seaZoneId: 'sea_a',
            ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
          ),
          Fleet(
            id: homeFleetIdFor('gp_human'),
            ownerId: 'gp_human',
            regionId: 'oldWorld',
            inPortAtProvinceId: 'oldWorld|cap',
            ships: const [],
          ),
        ]);

        final next = applyNavalTransferShipsBetweenFleets(
          game: game,
          humanPlayerId: 'gp_human',
          sourceFleetId: 'source',
          targetFleetId: homeFleetIdFor('gp_human'),
          shipInstanceIdsToTransfer: const ['ship_1'],
        );

        expect(next.worldState.fleets.any((f) => f.id == 'source'), isFalse);
        final home = next.worldState.fleets.firstWhere(
          (f) => f.id == homeFleetIdFor('gp_human'),
        );
        expect(home.ships.map((s) => s.id).toList(), ['ship_1']);
      },
    );
  });
}
