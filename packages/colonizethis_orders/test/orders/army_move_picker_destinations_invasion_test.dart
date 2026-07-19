// Ported from colonizethis_logic (Refs #4090 Slice D).
// Split from army_move_picker_destinations_test for
// repo.domain_package_test_file_size (≤400 physical lines).
// Table-driven for repo.orders_test_prefer_scenario_tables (Refs #3949).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'support/army_move_picker_destinations_fixtures.dart';
import 'support/scenario_runner.dart';

void main() {
  const ow = kArmyMovePickerOw;

  runLabeledScenarioGroup('armyMovePickerDestinationsInvasion', [
    rs(
      'adjacent enemy province requires declare war on confirm when at peace',
      () {
        const p1 = 'gp1';
        const p2 = 'gp2';
        const loc1 = '$ow|P1';
        const loc2 = '$ow|P2';
        final army = armyMovePickerFieldArmy(ow, p1, 'P1', 'u1');
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(id: loc1, regionId: ow, ownerId: p1),
                Province(id: loc2, regionId: ow, ownerId: p2),
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
              p1: armyMovePickerVis([
                (loc1, '$ow|P1|0|0'),
                (loc2, '$ow|P2|0|0'),
              ]),
            },
            tileKeysByRegionAndProvince: {
              ow: {
                loc1: ['$ow|P1|0|0'],
                loc2: ['$ow|P2|0|0'],
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
          topology: armyMovePickerAdjacencyOw,
          playerId: p1,
          army: army,
          currentOrders: const Orders(),
        );
        final inv = list.firstWhere((e) => e.fullProvinceId == loc2);
        expect(inv.requiresDeclareWarOnConfirm, isTrue);
        expect(inv.ownerFactionId, p2);
      },
    ),
    rs(
      'two reachable enemy provinces of same owner both require declare war (Refs #2394 trial-validator cache keyed by defender)',
      () {
        const p1 = 'gp1';
        const p2 = 'gp2';
        const loc1 = '$ow|P1';
        const loc2 = '$ow|P2';
        const loc3 = '$ow|P3';
        final army = armyMovePickerFieldArmy(ow, p1, 'P1', 'u1');
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'P2',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'P3',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'P1', id2: 'P2'),
            TopologyEdge(id1: 'P1', id2: 'P3'),
          ],
        );
        final game = Game(
          id: 'g_two_enemy_same_owner',
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
              p1: armyMovePickerVis([
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
        final invasions = list
            .where((e) => e.fullProvinceId == loc2 || e.fullProvinceId == loc3)
            .toList();
        expect(invasions, hasLength(2));
        expect(invasions.every((e) => e.requiresDeclareWarOnConfirm), isTrue);
        expect(invasions.every((e) => e.ownerFactionId == p2), isTrue);
      },
    ),
    rs('at war with enemy: invasion confirm not required', () {
      const p1 = 'gp1';
      const p2 = 'gp2';
      const loc1 = '$ow|P1';
      const loc2 = '$ow|P2';
      final army = armyMovePickerFieldArmy(ow, p1, 'P1', 'u1');
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: loc1, regionId: ow, ownerId: p1),
              Province(id: loc2, regionId: ow, ownerId: p2),
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
            p1: armyMovePickerVis([(loc1, '$ow|P1|0|0'), (loc2, '$ow|P2|0|0')]),
          },
          tileKeysByRegionAndProvince: {
            ow: {
              loc1: ['$ow|P1|0|0'],
              loc2: ['$ow|P2|0|0'],
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
        topology: armyMovePickerAdjacencyOw,
        playerId: p1,
        army: army,
        currentOrders: const Orders(),
      );
      final inv = list.firstWhere((e) => e.fullProvinceId == loc2);
      expect(inv.requiresDeclareWarOnConfirm, isFalse);
    }),
    rs('player-owned destinations sort before other factions', () {
      const p1 = 'gp1';
      const p2 = 'gp2';
      const loc1 = '$ow|P1';
      const loc2 = '$ow|P2';
      const loc3 = '$ow|P3';
      final army = armyMovePickerFieldArmy(ow, p1, 'P1', 'u1');
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
              Province(
                id: loc3,
                regionId: ow,
                ownerId: p1,
                displayName: 'Zebra',
              ),
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
            p1: armyMovePickerVis([
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
    }),
  ], runRunnableScenario);
}
