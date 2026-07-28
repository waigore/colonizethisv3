import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_snapshot.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_targets.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';
import 'package:colonizethis_orders/src/orders/work_suggestion_pipeline.dart';
import 'package:colonizethis_test/test.dart';

/// ConnectivityDevSnapshot builder pins (Refs #4176 AC-A5, AC-A7).
void main() {
  group('buildConnectivityDevSnapshot', () {
    test('AC-A5 owned-land traversal only for extension distances', () {
      const ow = 'oldWorld';
      const pCapital = '$ow|pCap';
      const pForeign = '$ow|pFor';
      const pResource = '$ow|pRes';
      const capTile = '$pCapital|2|0';
      const resourceTile = '$pResource|0|2';
      const grid = [
        ['pCap', 'pCap', 'pCap'],
        ['pFor', 'pFor', 'pFor'],
        ['pRes', 'pRes', 'pRes'],
      ];
      final tileMap = TileMapResult(
        width: grid.first.length,
        height: grid.length,
        grid: grid,
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: pCapital,
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: pForeign,
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: pResource,
            regionId: ow,
            type: TopologyNodeType.province,
          ),
        ],
        edges: [
          TopologyEdge(id1: pCapital, id2: pForeign),
          TopologyEdge(id1: pForeign, id2: pResource),
        ],
      );
      final capTiles = [
        for (var x = 0; x < 3; x++) '$pCapital|$x|0',
      ];
      final resTiles = [
        for (var x = 0; x < 3; x++) '$pResource|$x|2',
      ];
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: pCapital, regionId: ow, ownerId: 'gp1'),
              Province(id: pForeign, regionId: ow, ownerId: 'minor1'),
              Province(id: pResource, regionId: ow, ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              'pCap': capTiles,
              'pRes': resTiles,
            },
          },
          resourceByTileKey: {resourceTile: 'iron'},
          tileState: const TileMapState(
            improvementByTile: {resourceTile: 1},
          ),
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: false,
            capitalProvinceId: pCapital,
            capitalTile: CapitalTile(
              regionId: ow,
              provinceId: pCapital,
              x: 2,
              y: 0,
            ),
          ),
        ],
      );
      final snapshot = buildConnectivityDevSnapshot(
        game: game,
        playerId: 'gp1',
        topology: topology,
        tileMapByRegion: {ow: tileMap},
      );
      expect(snapshot, isNotNull);
      expect(snapshot!.hasUnconnectedDevTargets, isTrue);
      expect(
        snapshot.extensionDistanceByTile[capTile],
        isNull,
        reason: 'foreign-province barrier must block owned-land extension '
            'distance toward the isolated resource province',
      );
    });
  });

  group('build_road connectivity ordering with probe cap', () {
    test('AC-A7 frontier tile is first accepted despite lex-smaller non-frontier', () {
      const frontierTile = 'oldWorld|p1|2|4';
      final lexSorted = <String>[
        for (var y = 0; y < 5; y++)
          for (var x = 0; x < 5; x++) 'oldWorld|p1|$x|$y',
      ];
      final snapshot = ConnectivityDevSnapshot(
        connected: {'oldWorld|p1|4|4', 'oldWorld|p1|3|4', 'oldWorld|p1|4|3'},
        pathTransportCap: const {},
        extensionDistanceByTile: {
          frontierTile: 6,
          'oldWorld|p1|3|3': 6,
          'oldWorld|p1|4|2': 6,
        },
        seaZonesReachableFromCapital: const {},
        provincesWithUnconnectedDevTargets: {'oldWorld|p1'},
        hasUnconnectedDevTargets: true,
        frontierExtensionTiles: {
          frontierTile,
          'oldWorld|p1|3|3',
          'oldWorld|p1|4|2',
        },
        bottleneckRailTiles: const {},
        adjacentToConnectedTiles: {
          frontierTile,
          'oldWorld|p1|3|3',
          'oldWorld|p1|4|2',
        },
      );
      final ordered = prioritizeBuildRoadCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: lexSorted,
      );
      expect(ordered.first, frontierTile);

      final unit = Unit(
        id: 'e1',
        type: kUnitTypeEngineer,
        ownerId: 'gp1',
        locationProvinceId: 'oldWorld|p1',
      );
      final suggestions = <WorkOrder>[];
      WorkSuggestionPipeline.run(
        unit: unit,
        unitType: unit.type,
        unitRegionId: 'oldWorld',
        atProvinceId: 'oldWorld|p1',
        workTarget: kWorkTargetBuildRoad,
        existingTargetsByUnit: {},
        suggestions: suggestions,
        candidatesProvider: () sync* {
          for (final tileKey in ordered) {
            yield WorkOrder(
              unitId: unit.id,
              target: kWorkTargetBuildRoad,
              targetTileKey: tileKey,
            );
          }
        },
        candidateAcceptor: (_) => true,
        noCandidateReason: 'no_valid_tile',
      );
      expect(suggestions.single.targetTileKey, frontierTile);
    });
  });
}
