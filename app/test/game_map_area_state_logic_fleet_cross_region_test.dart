import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'game_map_area_state_logic_test_support.dart';

void main() {
  suppressLogsForTests();
  group('GameMapAreaStateLogic', () {
    group('projectFleetMarkersForHumanDraft cross-region draft projection', () {
      const humanId = 'gp1';

      ct_models.Game gameForCrossRegionDraft() {
        return ct_models.Game(
          id: 'g',
          worldState: ct_models.WorldState(
            turnState: const ct_models.TurnState(
              phase: ct_models.TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: ct_models.RegionData(
              provinces: const [
                ct_models.Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                ),
              ],
              units: const [],
            ),
            newWorld: ct_models.RegionData(
              provinces: const [
                ct_models.Province(
                  id: 'newWorld|p1',
                  regionId: 'newWorld',
                  ownerId: humanId,
                ),
              ],
              units: const [],
            ),
            fleets: [
              ct_models.Fleet(
                id: 'f1',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 's1',
                ships: const [
                  ct_models.ShipInstance(id: 'ship_1', typeId: 'frigate'),
                ],
              ),
            ],
          ),
          players: const [
            ct_models.Player(id: humanId, displayName: 'Human', isHuman: true),
          ],
          minorNations: const [],
          tribes: const [],
        );
      }

      final oldWorldMap = TileMapResult(
        width: 2,
        height: 1,
        grid: [
          ['s1', 'p1'],
        ],
      );
      final newWorldMap = TileMapResult(
        width: 2,
        height: 1,
        grid: [
          ['s2', 'p1'],
        ],
      );
      const oldWorldTopology = MapTopology(
        nodes: [
          TopologyNode(
            id: 's1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [TopologyEdge(id1: 's1', id2: 'p1')],
      );
      const newWorldTopology = MapTopology(
        nodes: [
          TopologyNode(
            id: 's2',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'p1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [TopologyEdge(id1: 's2', id2: 'p1')],
      );
      const combinedTopology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|s1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'newWorld|s2',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'oldWorld|s1', id2: 'newWorld|s2')],
      );

      ({
        ct_models.Game game,
        Map<String, TileMapResult> tiles,
        Map<String, MapTopology> topologies,
        InitGameMapViewData mapView,
      })
      crossRegionDraftContext() {
        final game = gameForCrossRegionDraft();
        final tiles = {'oldWorld': oldWorldMap, 'newWorld': newWorldMap};
        final topologies = {
          'oldWorld': oldWorldTopology,
          'newWorld': newWorldTopology,
        };
        return (
          game: game,
          tiles: tiles,
          topologies: topologies,
          mapView: buildInitGameMapViewData(
            game: game,
            tileMapByRegion: tiles,
            topologyByRegion: topologies,
            cellSize: 8,
          ),
        );
      }

      RegionMapViewData projectCrossRegion({
        required RegionMapViewData region,
        required ct_models.Game game,
        required ct_models.Orders orders,
        required Map<String, TileMapResult> tiles,
        required Map<String, MapTopology> topologies,
      }) {
        return GameMapAreaStateLogicDraftProjection.projectFleetMarkersForHumanDraft(
          region: region,
          game: game,
          orders: orders,
          humanPlayerId: humanId,
          tileMapByRegion: tiles,
          topologyByRegion: topologies,
          combinedTopology: combinedTopology,
        );
      }

      test(
        'projects marker in destination region with halo + destination scope',
        () {
          final ctx = crossRegionDraftContext();
          final projected = projectCrossRegion(
            region: ctx.mapView.newWorld,
            game: ctx.game,
            orders: const ct_models.Orders(
              navalMoveOrdersByPlayerId: {
                humanId: [
                  ct_models.NavalMoveOrder(
                    fleetId: 'f1',
                    destinationSeaZoneId: 'newWorld|s2',
                  ),
                ],
              },
            ),
            tiles: ctx.tiles,
            topologies: ctx.topologies,
          );

          expect(projected.fleetTileMarkers, hasLength(1));
          final marker = projected.fleetTileMarkers.single;
          expect(marker.tileKey, 'newWorld|s2|0|0');
          expect(marker.locationScopeKey, 'sea:newWorld|s2');
          expect(marker.applyFleetRevealHalo, isTrue);
          expect(marker.renderGrayscale, isTrue);
        },
      );

      test('does not render cross-region drafted fleet in source region', () {
        final ctx = crossRegionDraftContext();
        final projected = projectCrossRegion(
          region: ctx.mapView.oldWorld,
          game: ctx.game,
          orders: const ct_models.Orders(
            navalMoveOrdersByPlayerId: {
              humanId: [
                ct_models.NavalMoveOrder(
                  fleetId: 'f1',
                  destinationSeaZoneId: 'newWorld|s2',
                ),
              ],
            },
          ),
          tiles: ctx.tiles,
          topologies: ctx.topologies,
        );
        expect(projected.fleetTileMarkers, isEmpty);
      });

      test('canceling draft restores source-region marker', () {
        final ctx = crossRegionDraftContext();
        final projected = projectCrossRegion(
          region: ctx.mapView.oldWorld,
          game: ctx.game,
          orders: const ct_models.Orders(),
          tiles: ctx.tiles,
          topologies: ctx.topologies,
        );

        expect(projected.fleetTileMarkers, hasLength(1));
        final marker = projected.fleetTileMarkers.single;
        expect(marker.tileKey, 'oldWorld|s1|0|0');
        expect(marker.locationScopeKey, 'sea:oldWorld|s1');
        expect(marker.applyFleetRevealHalo, isFalse);
      });
    });
  });
}
