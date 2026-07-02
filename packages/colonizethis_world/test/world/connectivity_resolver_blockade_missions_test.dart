import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_world/src/world/connectivity_blockade_target.dart';

import '../world_test_support/world_test_support.dart';

void main() {
group('ConnectivityResolver', () {
    group('blockade', () {
      test(
        'computeBlockadedPortProvincesByPlayer ignores non-blockade missions',
        () {
          const ow = 'oldWorld';
          final topology = MapTopology(
            nodes: [
              TopologyNode(
                id: 'p1',
                regionId: ow,
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: 'p2',
                regionId: ow,
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: 'sea1',
                regionId: ow,
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: [TopologyEdge(id1: 'sea1', id2: 'p2')],
          );
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
                  Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
                ],
              ),
              newWorld: const RegionData(),
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
            ),
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
          final topology = MapTopology(
            nodes: [
              TopologyNode(
                id: 'p1',
                regionId: ow,
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: 'p2',
                regionId: ow,
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: 'n1',
                regionId: nw,
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: 'sea1',
                regionId: ow,
                type: TopologyNodeType.seaZone,
              ),
              TopologyNode(
                id: 'sea2',
                regionId: nw,
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: [
              TopologyEdge(id1: 'sea1', id2: 'p2'),
              TopologyEdge(id1: 'sea2', id2: 'n1'),
            ],
          );
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
                  Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
                ],
              ),
              newWorld: RegionData(
                provinces: [
                  Province(id: '$nw|n1', regionId: nw, ownerId: 'pl1'),
                ],
              ),
              fleets: [
                Fleet(
                  id: 'fleet_p2',
                  ownerId: 'p2',
                  seaZoneId: 'sea1',
                  inPortAtProvinceId: null,
                  regionId: ow,
                  mission: FleetMission.blockade,
                  targetProvinceId: '$ow|p2',
                ),
                Fleet(
                  id: 'fleet_p3',
                  ownerId: 'p3',
                  seaZoneId: 'sea2',
                  inPortAtProvinceId: null,
                  regionId: nw,
                  mission: FleetMission.blockade,
                  targetProvinceId: '$nw|n1',
                ),
              ],
            ),
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
