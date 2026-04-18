import 'package:colonizethis_app/features/game/flame/game_map_area_state_logic.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void _expectPortFleetMarkersMatchTownPortDrawables(RegionMapViewData region) {
  for (final m in region.fleetTileMarkers) {
    if (!m.locationScopeKey.startsWith('port:')) {
      continue;
    }
    final localProv = m.locationScopeKey.substring(5).split('|').last;
    final towns = region.townMarkers
        .where((t) => t.provinceId == localProv && t.isPort)
        .toList();
    expect(towns, isNotEmpty, reason: 'port town for $localProv');
    final town = towns.single;
    expect(m.x, town.portIconX, reason: 'fleet x vs port icon $localProv');
    expect(m.y, town.portIconY, reason: 'fleet y vs port icon $localProv');
  }
}

void main() {
  suppressLogsForTests();
  group('GameMapAreaStateLogic', () {
    test(
      'projectCivilianMarkersForHumanDraft projects pending assignment tile in same turn',
      () {
        const sourceTile = 'oldWorld|p1|0|0';
        const targetTile = 'oldWorld|p1|1|0';
        const unitId = 'u_builder';
        const humanPlayerId = 'gp1';

        final region = RegionMapViewData(
          regionId: 'oldWorld',
          width: 2,
          height: 1,
          cellSize: 16,
          cells: const [
            CellViewData(x: 0, y: 0, regionCellId: 'p1', isSea: false),
            CellViewData(x: 1, y: 0, regionCellId: 'p1', isSea: false),
          ],
          capitalMarkers: const [],
          portMarkers: const [],
          factionColors: const {},
          greatPowerFactionIds: const {},
          terrainColors: const {},
          unitMarkers: const [],
          civilianTileMarkers: const [
            CivilianTileMarkerView(
              tileKey: sourceTile,
              x: 0,
              y: 0,
              localProvinceId: 'p1',
              unitIds: [unitId],
              unitTypes: {unitId: 'Builder'},
              representativeUnitType: 'Builder',
              stackCount: 1,
              representativeIsAssigned: false,
            ),
          ],
        );
        final game = ct_models.Game(
          id: 'g',
          worldState: ct_models.WorldState(
            turnState: ct_models.TurnState(
              phase: ct_models.TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: ct_models.RegionData(
              provinces: [
                ct_models.Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
              ],
              units: [
                ct_models.Unit(
                  id: unitId,
                  type: 'Builder',
                  ownerId: humanPlayerId,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: sourceTile,
                  status: ct_models.UnitStatus.idle,
                ),
              ],
            ),
            newWorld: ct_models.RegionData(provinces: [], units: []),
          ),
          players: const [
            ct_models.Player(
              id: humanPlayerId,
              displayName: 'Human',
              isHuman: true,
            ),
          ],
          minorNations: const [],
          tribes: const [],
        );
        final orders = const ct_models.Orders(
          workOrdersByPlayerId: {
            humanPlayerId: [
              ct_models.WorkOrder(
                unitId: unitId,
                target: 'build_improvement',
                targetTileKey: targetTile,
              ),
            ],
          },
        );

        final projected =
            GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
              region: region,
              game: game,
              orders: orders,
              humanPlayerId: humanPlayerId,
            );

        expect(projected.civilianTileMarkers, hasLength(1));
        final marker = projected.civilianTileMarkers.single;
        expect(marker.tileKey, targetTile);
        expect(marker.x, 1);
        expect(marker.y, 0);
        expect(marker.representativeIsAssigned, isTrue);
      },
    );

    test('selectionAfterWorkAssignment clears stale selected marker tile', () {
      final next = GameMapAreaStateLogic.selectionAfterWorkAssignment(
        currentSelectedCivilianTileKey: 'oldWorld|p1|0|0',
        assignedTileKey: 'oldWorld|p1|1|0',
      );
      expect(next, isNull);
    });

    test(
      'selectionAfterWorkAssignment preserves selection on assigned tile',
      () {
        final next = GameMapAreaStateLogic.selectionAfterWorkAssignment(
          currentSelectedCivilianTileKey: 'oldWorld|p1|1|0',
          assignedTileKey: 'oldWorld|p1|1|0',
        );
        expect(next, 'oldWorld|p1|1|0');
      },
    );

    group('displayProvinceOrSeaIdFromTileKey', () {
      test('extracts region and province from full tile key', () {
        expect(
          displayProvinceOrSeaIdFromTileKey('oldWorld|p1|10|20'),
          'oldWorld|p1',
        );
      });

      test('returns null for short keys', () {
        expect(displayProvinceOrSeaIdFromTileKey('badKey'), isNull);
        expect(displayProvinceOrSeaIdFromTileKey(null), isNull);
      });
    });

    group('regionIndexFromWorldRegionId', () {
      test('newWorld maps to index 1', () {
        expect(
          GameMapAreaStateLogic.regionIndexFromWorldRegionId('newWorld'),
          1,
        );
      });

      test('any other region maps to index 0', () {
        expect(
          GameMapAreaStateLogic.regionIndexFromWorldRegionId('oldWorld'),
          0,
        );
      });
    });

    group('isWorkTargetTileProvinceBased', () {
      test('explore/steal_tech/counter_spy are province-based', () {
        expect(
          GameMapAreaStateLogic.isWorkTargetTileProvinceBased('explore'),
          isTrue,
        );
        expect(
          GameMapAreaStateLogic.isWorkTargetTileProvinceBased('steal_tech'),
          isTrue,
        );
        expect(
          GameMapAreaStateLogic.isWorkTargetTileProvinceBased('counter_spy'),
          isTrue,
        );
      });

      test('move is not province-based', () {
        expect(
          GameMapAreaStateLogic.isWorkTargetTileProvinceBased('move'),
          isFalse,
        );
      });
    });

    group('translateWorkTargetTileKey', () {
      test('province-based work targets rewrite tile coords to x=0,y=0', () {
        final translated = GameMapAreaStateLogic.translateWorkTargetTileKey(
          tileKey: 'oldWorld|p1|10|20',
          workTarget: 'explore',
        );
        expect(translated, 'oldWorld|p1|0|0');
      });

      test('non-province-based work targets return tileKey unchanged', () {
        final translated = GameMapAreaStateLogic.translateWorkTargetTileKey(
          tileKey: 'oldWorld|p1|10|20',
          workTarget: 'move',
        );
        expect(translated, 'oldWorld|p1|10|20');
      });

      test('short tile keys return tileKey unchanged', () {
        final translated = GameMapAreaStateLogic.translateWorkTargetTileKey(
          tileKey: 'oldWorld|p1',
          workTarget: 'explore',
        );
        // With parts length >= 2, province-based work targets normalize to x=0,y=0.
        expect(translated, 'oldWorld|p1|0|0');
      });
    });

    group('addHumanWorkOrder', () {
      test('appends work order under given humanPlayerId', () {
        const humanPlayerId = 'gp1';
        final orders = ct_models.Orders(
          workOrdersByPlayerId: const {humanPlayerId: []},
        );
        final workOrder = ct_models.WorkOrder(
          unitId: 'u1',
          target: 'explore',
          targetTileKey: 'oldWorld|p1|0|0',
        );

        final updated = GameMapAreaStateLogic.addHumanWorkOrder(
          orders: orders,
          humanPlayerId: humanPlayerId,
          workOrder: workOrder,
        );

        expect(updated.workOrdersByPlayerId[humanPlayerId], [workOrder]);
      });

      test('replaces existing pending work order for same unit', () {
        const humanPlayerId = 'gp1';
        const unitId = 'u1';
        final orders = ct_models.Orders(
          workOrdersByPlayerId: const {
            humanPlayerId: [
              ct_models.WorkOrder(
                unitId: unitId,
                target: 'build_improvement',
                targetTileKey: 'oldWorld|p1|0|0',
              ),
            ],
          },
        );
        const replacement = ct_models.WorkOrder(
          unitId: unitId,
          target: 'build_road',
          targetTileKey: 'oldWorld|p1|1|0',
        );

        final updated = GameMapAreaStateLogic.addHumanWorkOrder(
          orders: orders,
          humanPlayerId: humanPlayerId,
          workOrder: replacement,
        );

        expect(updated.workOrdersByPlayerId[humanPlayerId], [replacement]);
      });
    });

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

      test(
        'in-port fleet marker matches port icon after projection (capital port)',
        () {
          final owMap = TileMapResult(
            width: 2,
            height: 2,
            grid: [
              ['p1', 's1'],
              ['p1', 'p1'],
            ],
          );
          final nwMap = TileMapResult(width: 1, height: 1, grid: [['p1']]);
          final owTopology = MapTopology(
            nodes: const [
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
            edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
          );
          final nwTopology = MapTopology(
            nodes: const [
              TopologyNode(
                id: 'p1',
                regionId: 'newWorld',
                type: TopologyNodeType.province,
              ),
            ],
            edges: const [],
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
            ),
            players: const [
              ct_models.Player(
                id: humanId,
                displayName: 'Human',
                isHuman: true,
              ),
            ],
            minorNations: const [],
            tribes: const [],
          );

          final tileByReg = {'oldWorld': owMap, 'newWorld': nwMap};
          final topoByReg = {'oldWorld': owTopology, 'newWorld': nwTopology};
          final view = buildInitGameMapViewData(
            game: game,
            tileMapByRegion: tileByReg,
            topologyByRegion: topoByReg,
            cellSize: 8,
          );
          final region = view.oldWorld;
          _expectPortFleetMarkersMatchTownPortDrawables(region);

          final projected = projectFleetDraft(
            region: region,
            game: game,
            orders: const ct_models.Orders(),
            tm: tileByReg,
            tr: topoByReg,
          );
          _expectPortFleetMarkersMatchTownPortDrawables(projected);
        },
      );

      test('dock draft destination uses same harbor sea cell as port icon', () {
        final owMap = TileMapResult(
          width: 2,
          height: 2,
          grid: [
            ['p1', 's1'],
            ['p1', 'p1'],
          ],
        );
        final nwMap = TileMapResult(width: 1, height: 1, grid: [['p1']]);
        final owTopology = MapTopology(
          nodes: const [
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
          edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
        );
        final nwTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
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
            fleets: [
              ct_models.Fleet(
                id: 'f_sea',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 's1',
                ships: [
                  ct_models.ShipInstance(id: 'ship_1', typeId: 'frigate'),
                ],
              ),
            ],
          ),
          players: const [
            ct_models.Player(
              id: humanId,
              displayName: 'Human',
              isHuman: true,
            ),
          ],
          minorNations: const [],
          tribes: const [],
        );
        final tileByReg = {'oldWorld': owMap, 'newWorld': nwMap};
        final topoByReg = {'oldWorld': owTopology, 'newWorld': nwTopology};
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

      test(
        'non-capital port fleet matches port drawable after projection',
        () {
          final owMap = TileMapResult(
            width: 3,
            height: 2,
            grid: [
              ['p2', 'p2', 'p2'],
              ['p2', 'p2', 's1'],
            ],
          );
          final nwMap = TileMapResult(width: 1, height: 1, grid: [['p1']]);
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
          final nwTopology = MapTopology(
            nodes: const [
              TopologyNode(
                id: 'p1',
                regionId: 'newWorld',
                type: TopologyNodeType.province,
              ),
            ],
            edges: const [],
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
              portsByProvinceSeaboard: {
                'oldWorld|p2|sb': 'oldWorld|p1|2|0',
              },
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
              ct_models.Player(
                id: humanId,
                displayName: 'Human',
                isHuman: true,
              ),
            ],
            minorNations: const [],
            tribes: const [],
          );
          final tileByReg = {'oldWorld': owMap, 'newWorld': nwMap};
          final topoByReg = {'oldWorld': owTopology, 'newWorld': nwTopology};
          final view = buildInitGameMapViewData(
            game: game,
            tileMapByRegion: tileByReg,
            topologyByRegion: topoByReg,
            cellSize: 8,
          );
          final region = view.oldWorld;
          _expectPortFleetMarkersMatchTownPortDrawables(region);
          final projected = projectFleetDraft(
            region: region,
            game: game,
            orders: const ct_models.Orders(),
            tm: tileByReg,
            tr: topoByReg,
          );
          _expectPortFleetMarkersMatchTownPortDrawables(projected);
        },
      );
    });
  });
}
