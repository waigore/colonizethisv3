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
  });
}
