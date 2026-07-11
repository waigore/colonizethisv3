part of 'connectivity_resolver_test.dart';

void _connectivity_resolver_blockade_missions_testTests() {
group('ConnectivityResolver', () {
    group('blockade', () {
      test(
        'computeBlockadedPortProvincesByPlayer ignores non-blockade missions',
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
                mission: FleetMission.patrol,
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
          expect(blockaded['pl1'], isEmpty);
        },
      );

      test(
        'computeBlockadedPortProvincesByPlayer returns multiple provinces when two enemies blockade',
        () {
          const ow = 'oldWorld';
          const nw = 'newWorld';
          final topology = dualRegionBlockadeTargetsTopology();
          final game = ordersPhaseGame(
            oldWorldProvinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
            ],
            newWorldProvinces: [
              Province(id: '$nw|n1', regionId: nw, ownerId: 'pl1'),
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
                regionId: nw,
                seaZoneId: 'sea2',
                targetProvinceId: '$nw|n1',
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
                state: RelationState.atWar,
              ),
            ],
          );
          final blockaded = computeBlockadedPortProvincesByPlayer(
            game,
            topology,
          );
          expect(blockaded['pl1'], containsAll(['oldWorld|p2', 'newWorld|n1']));
          expect(blockaded['pl1']!.length, 2);
        },
      );
    });
  });

}
