import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_world/src/world/connectivity_blockade_target.dart';
import '../world_test_support/world_test_support.dart';

void main() {
  _connectivity_resolver_blockade_testTests();
}

void _connectivity_resolver_blockade_testTests() {
  group('ConnectivityResolver', () {
    group('blockade', () {
      for (final case_ in _blockadedOwnerCases) {
        test(case_.description, () {
          const ow = 'oldWorld';
          final topology = provinceSeaZoneTopology(
            regionId: ow,
            provinceLocalId: 'p2',
            seaZoneId: 'sea1',
          );
          final worldState = ordersPhaseWorldState(
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
              ],
            ),
          );
          final fleet = case_.useBlockadeFleetHelper
              ? blockadeFleet(
                  fleetId: 'fleet_attacker',
                  ownerId: 'p2',
                  regionId: ow,
                  seaZoneId: 'sea1',
                  targetProvinceId: '$ow|p2',
                )
              : Fleet(
                  id: 'fleet_attacker',
                  ownerId: 'p2',
                  seaZoneId: 'sea1',
                  inPortAtProvinceId: null,
                  regionId: ow,
                  mission: FleetMission.blockade,
                  targetProvinceId: '$ow|p2',
                );

          final ownerId = blockadedProvinceOwnerIdForFleet(
            fleet: fleet,
            worldState: worldState,
            topology: topology,
            areFactionsAtWar: case_.areFactionsAtWar,
          );

          expect(ownerId, case_.expectedOwnerId);
        });
      }

      test('blockaded port province excluded from connectivity', () {
        final scenario = dualRegionPortConnectivityScenario();
        final result = resolveConnectivity(
          game: scenario.game,
          tileMapByRegion: scenario.tileMapByRegion,
          topology: scenario.topology,
          blockadedPortProvincesByPlayerId: {
            'pl1': {'newWorld|p2'},
          },
        );
        final connected = result['pl1']!.connected;
        expect(connected.contains('oldWorld|p1|0|0'), true);
        expect(connected.contains('newWorld|p2|0|0'), false);
      });

      test('capital province blockaded: no sea connectivity', () {
        final scenario = dualRegionPortConnectivityScenario();
        final result = resolveConnectivity(
          game: scenario.game,
          tileMapByRegion: scenario.tileMapByRegion,
          topology: scenario.topology,
          blockadedPortProvincesByPlayerId: {
            'pl1': {'oldWorld|p1'},
          },
        );
        final connected = result['pl1']!.connected;
        expect(connected.contains('oldWorld|p1|0|0'), true);
        expect(connected.contains('newWorld|p2|0|0'), false);
      });

      test(
        'computeBlockadedPortProvincesByPlayer same-region: fleet in OW blockades OW port when at war',
        () {
          const ow = 'oldWorld';
          final topology = blockadeTargetProvinceTopology(regionId: ow);
          final game = ordersPhaseGame(
            oldWorldProvinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
            ],
            fleets: [
              blockadeFleet(
                fleetId: 'fleet_p2',
                ownerId: 'p2',
                regionId: ow,
                seaZoneId: 'sea1',
                targetProvinceId: '$ow|p2',
              ),
            ],
            players: [
              Player(id: 'pl1', displayName: 'Spain', isHuman: true),
              Player(id: 'p2', displayName: 'France', isHuman: true),
            ],
            diplomacyRelations: [
              DiplomacyRelation(
                factionId1: 'pl1',
                factionId2: 'p2',
                state: RelationState.atWar,
              ),
            ],
          );
          final blockaded = computeBlockadedPortProvincesByPlayer(
            game,
            topology,
          );
          expect(blockaded['pl1'], contains('oldWorld|p2'));
          expect(blockaded['p2'], isEmpty);
        },
      );
    });
  });
}

typedef _BlockadedOwnerCase = ({
  String description,
  bool useBlockadeFleetHelper,
  bool Function(String attacker, String defender) areFactionsAtWar,
  String? expectedOwnerId,
});

final List<_BlockadedOwnerCase> _blockadedOwnerCases = [
  (
    description:
        'blockadedProvinceOwnerIdForFleet returns owner for valid at-war blockade',
    useBlockadeFleetHelper: true,
    areFactionsAtWar: (attacker, defender) =>
        attacker == 'p2' && defender == 'pl1',
    expectedOwnerId: 'pl1',
  ),
  (
    description: 'blockadedProvinceOwnerIdForFleet returns null when not at war',
    useBlockadeFleetHelper: false,
    areFactionsAtWar: (_, __) => false,
    expectedOwnerId: null,
  ),
];
