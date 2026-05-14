import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'army_move_picker_destinations_test_support.dart';

void main() {
  test('player-owned destinations sort before other factions', () {
    const p1 = 'gp1';
    const p2 = 'gp2';
    const loc1 = '$ow|P1';
    const loc2 = '$ow|P2';
    const loc3 = '$ow|P3';
    final army = fieldArmy(ow, p1, 'P1', 'u1');
    final topology = MapTopology(
      nodes: const [
        TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        TopologyNode(id: 'P2', regionId: ow, type: TopologyNodeType.province),
        TopologyNode(id: 'P3', regionId: ow, type: TopologyNodeType.province),
      ],
      edges: const [
        TopologyEdge(id1: 'P1', id2: 'P2'),
        TopologyEdge(id1: 'P1', id2: 'P3'),
      ],
    );
    final game = Game(
      id: 'g',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            Province(id: loc1, regionId: ow, ownerId: p1),
            Province(id: loc2, regionId: ow, ownerId: p2),
            Province(id: loc3, regionId: ow, ownerId: p1, displayName: 'Zebra'),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'musketeers',
              ownerId: p1,
              locationProvinceId: loc1,
            ),
          ],
        ),
        newWorld: const RegionData(),
        armies: [army],
        playerVisibilityByTile: {
          p1: vis([
            (loc1, '$ow|P1|0|0'),
            (loc2, '$ow|P2|0|0'),
            (loc3, '$ow|P3|0|0'),
          ]),
        },
        tileKeysByRegionAndProvince: {
          ow: {
            loc1: ['$ow|P1|0|0'],
            loc2: ['$ow|P2|0|0'],
            loc3: ['$ow|P3|0|0'],
          },
        },
      ),
      players: const [
        Player(id: p1, displayName: 'A', isHuman: true),
        Player(id: p2, displayName: 'B', isHuman: true),
      ],
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: p1,
          factionId2: p2,
          state: RelationState.atWar,
        ),
      ],
    );
    final list = armyMovePickerDestinations(
      game: game,
      topology: topology,
      playerId: p1,
      army: army,
      currentOrders: const Orders(),
    );
    final firstEnemyIndex = list.indexWhere((e) => e.ownerFactionId == p2);
    final lastOwnIndex = list.lastIndexWhere((e) => e.isPlayerOwned);
    expect(lastOwnIndex < firstEnemyIndex, isTrue);
  });

  test(
    'multiple adjacent enemy provinces same owner each require declare war',
    () {
      const p1 = 'gp1';
      const p2 = 'gp2';
      const loc1 = '$ow|P1';
      const loc2 = '$ow|P2';
      const loc3 = '$ow|P3';
      final army = fieldArmy(ow, p1, 'P1', 'u1');
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'P3', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'P2'),
          TopologyEdge(id1: 'P1', id2: 'P3'),
        ],
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: loc1, regionId: ow, ownerId: p1),
              Province(id: loc2, regionId: ow, ownerId: p2),
              Province(id: loc3, regionId: ow, ownerId: p2),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: p1,
                locationProvinceId: loc1,
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [army],
          playerVisibilityByTile: {
            p1: vis([
              (loc1, '$ow|P1|0|0'),
              (loc2, '$ow|P2|0|0'),
              (loc3, '$ow|P3|0|0'),
            ]),
          },
          tileKeysByRegionAndProvince: {
            ow: {
              loc1: ['$ow|P1|0|0'],
              loc2: ['$ow|P2|0|0'],
              loc3: ['$ow|P3|0|0'],
            },
          },
        ),
        players: const [
          Player(id: p1, displayName: 'A', isHuman: true),
          Player(id: p2, displayName: 'B', isHuman: true),
        ],
        diplomacyRelations: const [],
      );
      final list = armyMovePickerDestinations(
        game: game,
        topology: topology,
        playerId: p1,
        army: army,
        currentOrders: const Orders(),
      );
      final p2Dests = list
          .where((e) => e.ownerFactionId == p2)
          .map((e) => e.fullProvinceId)
          .toSet();
      expect(p2Dests, containsAll([loc2, loc3]));
      expect(
        list
            .where((e) => e.fullProvinceId == loc2 || e.fullProvinceId == loc3)
            .every((e) => e.requiresDeclareWarOnConfirm),
        isTrue,
      );
    },
  );
}
