part of 'connectivity_resolver_test.dart';

void _connectivity_resolver_blockade_cross_region_testTests() {
group('ConnectivityResolver', () {
    group('blockade', () {
      test(
        'computeBlockadedPortProvincesByPlayer cross-region: fleet in OW blockades NW port when at war',
        () {
          const ow = 'oldWorld';
          const nw = 'newWorld';
          final topology = crossRegionOwSeaToNwProvinceTopology();
          final game = ordersPhaseGame(
            oldWorldProvinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
            ],
            newWorldProvinces: [
              Province(id: '$nw|n1', regionId: nw, ownerId: 'pl1'),
            ],
            fleets: [
              blockadeFleet(
                fleetId: 'fleet_p2',
                ownerId: 'p2',
                regionId: ow,
                seaZoneId: 'sea_ow',
                targetProvinceId: '$nw|n1',
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
          expect(blockaded['pl1'], contains('newWorld|n1'));
          expect(blockaded['p2'], isEmpty);
        },
      );

      test(
        'computeBlockadedPortProvincesByPlayer cross-region: fleet in NW blockades OW port when at war',
        () {
          const ow = 'oldWorld';
          final topology = crossRegionNwSeaToOwProvinceTopology();
          final game = ordersPhaseGame(
            oldWorldProvinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
            ],
            fleets: [
              blockadeFleet(
                fleetId: 'fleet_p2',
                ownerId: 'p2',
                regionId: 'newWorld',
                seaZoneId: 'sea_nw',
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
        },
      );

      test(
        'computeBlockadedPortProvincesByPlayer only at-war blockader counts: peace fleet does not add province',
        () {
          const ow = 'oldWorld';
          final topology = dualSeaZonesTargetProvinceTopology(regionId: ow);
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
              blockadeFleet(
                fleetId: 'fleet_p3',
                ownerId: 'p3',
                regionId: ow,
                seaZoneId: 'sea2',
                targetProvinceId: '$ow|p2',
              ),
            ],
            players: [
              Player(id: 'pl1', displayName: 'Spain', isHuman: true),
              Player(id: 'p2', displayName: 'France', isHuman: true),
              Player(id: 'p3', displayName: 'England', isHuman: true),
            ],
            diplomacyRelations: [
              DiplomacyRelation(
                factionId1: 'pl1',
                factionId2: 'p2',
                state: RelationState.atWar,
              ),
              DiplomacyRelation(
                factionId1: 'pl1',
                factionId2: 'p3',
                state: RelationState.atPeace,
              ),
            ],
          );
          final blockaded = computeBlockadedPortProvincesByPlayer(
            game,
            topology,
          );
          expect(blockaded['pl1'], contains('oldWorld|p2'));
          expect(blockaded['pl1']!.length, 1);
        },
      );

      test(
        'computeBlockadedPortProvincesByPlayer returns empty when at peace',
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
                state: RelationState.atPeace,
              ),
            ],
          );
          final blockaded = computeBlockadedPortProvincesByPlayer(
            game,
            topology,
          );
          expect(blockaded['pl1'], isEmpty);
          expect(blockaded['p2'], isEmpty);
        },
      );

      test(
        'computeBlockadedPortProvincesByPlayer ignores fleet without targetProvinceId',
        () {
          const ow = 'oldWorld';
          final topology = blockadeTargetProvinceTopology(regionId: ow);
          final game = ordersPhaseGame(
            oldWorldProvinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
            ],
            fleets: [
              Fleet(
                id: 'fleet_p2',
                ownerId: 'p2',
                seaZoneId: 'sea1',
                inPortAtProvinceId: null,
                regionId: ow,
                mission: FleetMission.blockade,
                targetProvinceId: null,
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
          expect(blockaded['pl1'], isEmpty);
        },
      );
    });
  });

}
