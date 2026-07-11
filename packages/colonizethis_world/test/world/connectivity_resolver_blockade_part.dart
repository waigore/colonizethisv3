part of 'connectivity_resolver_test.dart';

void _connectivity_resolver_blockade_testTests() {
group('ConnectivityResolver', () {
    group('blockade', () {
      test(
        'blockadedProvinceOwnerIdForFleet returns owner for valid at-war blockade',
        () {
          const ow = 'oldWorld';
          final topology = provinceSeaZoneTopology(
            regionId: ow,
            provinceLocalId: 'p2',
            seaZoneId: 'sea1',
          );
          final worldState = ordersPhaseWorldState(
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1')],
            ),
          );
          final fleet = blockadeFleet(
            fleetId: 'fleet_attacker',
            ownerId: 'p2',
            regionId: ow,
            seaZoneId: 'sea1',
            targetProvinceId: '$ow|p2',
          );

          final ownerId = blockadedProvinceOwnerIdForFleet(
            fleet: fleet,
            worldState: worldState,
            topology: topology,
            areFactionsAtWar: (attacker, defender) =>
                attacker == 'p2' && defender == 'pl1',
          );

          expect(ownerId, 'pl1');
        },
      );

      test('blockadedProvinceOwnerIdForFleet returns null when not at war', () {
        const ow = 'oldWorld';
        final topology = provinceSeaZoneTopology(
          regionId: ow,
          provinceLocalId: 'p2',
          seaZoneId: 'sea1',
        );
        final worldState = ordersPhaseWorldState(
          oldWorld: RegionData(
            provinces: [Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1')],
          ),
        );
        final fleet = Fleet(
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
          areFactionsAtWar: (_, __) => false,
        );

        expect(ownerId, isNull);
      });

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
