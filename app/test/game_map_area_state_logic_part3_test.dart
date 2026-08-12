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
    group('projectFleetMarkersForHumanDraft in-port harbor anchoring', () {
      const humanId = 'gp1';

      RegionMapViewData projectFleetDraft({
        required RegionMapViewData region,
        required ct_models.Game game,
        required ct_models.Orders orders,
        required Map<String, TileMapResult> tm,
        required Map<String, MapTopology> tr,
      }) {
        return GameMapAreaStateLogic.projectFleetMarkersForHumanDraft(
          region: region,
          game: game,
          orders: orders,
          humanPlayerId: humanId,
          tileMapByRegion: tm,
          topologyByRegion: tr,
          combinedTopology: const MapTopology(nodes: [], edges: []),
        );
      }

      final capitalPortOwMap = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 's1'],
          ['p1', 'p1'],
        ],
      );
      final stubNwMap = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['p1'],
        ],
      );
      const capitalPortOwTopology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 's1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 's1')],
      );
      const stubNwTopology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [],
      );

      Map<String, TileMapResult> capitalPortTiles() => {
        'oldWorld': capitalPortOwMap,
        'newWorld': stubNwMap,
      };
      Map<String, MapTopology> capitalPortTopologies() => {
        'oldWorld': capitalPortOwTopology,
        'newWorld': stubNwTopology,
      };

      ct_models.Game capitalPortGame({required List<ct_models.Fleet> fleets}) {
        return ct_models.Game(
          id: 'g',
          worldState: ct_models.WorldState(
            turnState: const ct_models.TurnState(
              phase: ct_models.TurnPhase.orders,
              turnNumber: 0,
            ),
            oldWorld: ct_models.RegionData(
              provinces: [
                ct_models.Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  townTileKey: 'oldWorld|p1|1|1',
                ),
              ],
              units: const [],
            ),
            newWorld: const ct_models.RegionData(provinces: [], units: []),
            portsByProvinceSeaboard: {'oldWorld|p1|sb': 'oldWorld|p1|0|0'},
            fleets: fleets,
          ),
          players: const [
            ct_models.Player(id: humanId, displayName: 'Human', isHuman: true),
          ],
          minorNations: const [],
          tribes: const [],
        );
      }

      test(
        'in-port fleet marker matches port icon after projection (capital port)',
        () {
          final game = capitalPortGame(
            fleets: [
              ct_models.Fleet(
                id: 'f1',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: 'oldWorld|p1',
                ships: [
                  ct_models.ShipInstance(id: 'ship_1', typeId: 'frigate'),
                ],
              ),
            ],
          );
          final tileByReg = capitalPortTiles();
          final topoByReg = capitalPortTopologies();
          final view = buildInitGameMapViewData(
            game: game,
            tileMapByRegion: tileByReg,
            topologyByRegion: topoByReg,
            cellSize: 8,
          );
          final region = view.oldWorld;
          expectPortFleetMarkersMatchTownPortDrawables(region);

          final projected = projectFleetDraft(
            region: region,
            game: game,
            orders: const ct_models.Orders(),
            tm: tileByReg,
            tr: topoByReg,
          );
          expectPortFleetMarkersMatchTownPortDrawables(projected);
        },
      );

      test('dock draft destination uses same harbor sea cell as port icon', () {
        final game = capitalPortGame(
          fleets: [
            ct_models.Fleet(
              id: 'f_sea',
              ownerId: humanId,
              regionId: 'oldWorld',
              seaZoneId: 's1',
              ships: [ct_models.ShipInstance(id: 'ship_1', typeId: 'frigate')],
            ),
          ],
        );
        final tileByReg = capitalPortTiles();
        final topoByReg = capitalPortTopologies();
        final view = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: tileByReg,
          topologyByRegion: topoByReg,
          cellSize: 8,
        );
        final region = view.oldWorld;
        final town = region.townMarkers.singleWhere((t) => t.isPort);
        final orders = ct_models.Orders(
          navalMoveOrdersByPlayerId: {
            humanId: [
              ct_models.NavalMoveOrder(
                fleetId: 'f_sea',
                destinationPortProvinceId: 'oldWorld|p1',
              ),
            ],
          },
        );
        final projected = projectFleetDraft(
          region: region,
          game: game,
          orders: orders,
          tm: tileByReg,
          tr: topoByReg,
        );
        final fleetMarker = projected.fleetTileMarkers.single;
        expect(fleetMarker.x, town.portIconX);
        expect(fleetMarker.y, town.portIconY);
      });

      test('non-capital port fleet matches port drawable after projection', () {
        final owMap = TileMapResult(
          width: 3,
          height: 2,
          grid: [
            ['p2', 'p2', 'p2'],
            ['p2', 'p2', 's1'],
          ],
        );
        final owTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 's1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'p2', id2: 's1')],
        );
        final game = ct_models.Game(
          id: 'g',
          worldState: ct_models.WorldState(
            turnState: const ct_models.TurnState(
              phase: ct_models.TurnPhase.orders,
              turnNumber: 0,
            ),
            oldWorld: ct_models.RegionData(
              provinces: [
                const ct_models.Province(
                  id: 'oldWorld|p2',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  townTileKey: 'oldWorld|p2|0|0',
                ),
              ],
              units: const [],
            ),
            newWorld: const ct_models.RegionData(provinces: [], units: []),
            portsByProvinceSeaboard: {'oldWorld|p2|sb': 'oldWorld|p1|2|0'},
            fleets: [
              ct_models.Fleet(
                id: 'f_p2',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: 'oldWorld|p2',
                ships: [
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
        final tileByReg = {'oldWorld': owMap, 'newWorld': stubNwMap};
        final topoByReg = {'oldWorld': owTopology, 'newWorld': stubNwTopology};
        final view = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: tileByReg,
          topologyByRegion: topoByReg,
          cellSize: 8,
        );
        final region = view.oldWorld;
        expectPortFleetMarkersMatchTownPortDrawables(region);
        final projected = projectFleetDraft(
          region: region,
          game: game,
          orders: const ct_models.Orders(),
          tm: tileByReg,
          tr: topoByReg,
        );
        expectPortFleetMarkersMatchTownPortDrawables(projected);
      });
    });
  });
}
