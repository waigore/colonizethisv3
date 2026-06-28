import 'package:colonizethis_app/features/game/flame/game_map_area_state_logic.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        PlayerView,
        VisibilityLevel,
        buildPlayerView,
        getValidWorkOrderTileKeysWithVisibility,
        kWorkTargetBuildImprovement;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

/// Expected `provinceBuildImprovementActionState(...).enabled` per **pipeline contract A**
/// ([SPEC/program/order-suggestions.md](../../SPEC/program/order-suggestions.md) § Province Tile
/// `Build improvement` shortcut enablement): same predicate as
/// [GameMapAreaStateLogic.provinceBuildImprovementActionState] — any human Builder whose allowed
/// targets include `build_improvement` has `selectedTileKey` in
/// `getValidWorkOrderTileKeysWithVisibility` for the same `(game, topology, view, orders, tileMap)`.
bool _expectedBuildImprovementEnabledFromPipeline({
  required ct_models.Game game,
  required String humanPlayerId,
  required String selectedTileKey,
  required PlayerView playerView,
  required MapTopology? topology,
  required ct_models.Orders currentOrders,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (topology == null) return false;
  final allUnits = <ct_models.Unit>[
    ...game.worldState.oldWorld.units,
    ...game.worldState.newWorld.units,
  ];
  final builderUnits = allUnits
      .where((unit) => unit.ownerId == humanPlayerId)
      .where(
        (unit) =>
            workOrderTargetsByUnitType[unit.type]?.contains(
              kWorkTargetBuildImprovement,
            ) ??
            false,
      )
      .toList();
  if (builderUnits.isEmpty) return false;
  return builderUnits.any((builder) {
    final valid = getValidWorkOrderTileKeysWithVisibility(
      game: game,
      topology: topology,
      view: playerView,
      unitId: builder.id,
      workTarget: kWorkTargetBuildImprovement,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
    );
    return valid.contains(selectedTileKey);
  });
}

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
          final nwMap = TileMapResult(
            width: 1,
            height: 1,
            grid: [
              ['p1'],
            ],
          );
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
        final nwMap = TileMapResult(
          width: 1,
          height: 1,
          grid: [
            ['p1'],
          ],
        );
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
            ct_models.Player(id: humanId, displayName: 'Human', isHuman: true),
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

      test('non-capital port fleet matches port drawable after projection', () {
        final owMap = TileMapResult(
          width: 3,
          height: 2,
          grid: [
            ['p2', 'p2', 'p2'],
            ['p2', 'p2', 's1'],
          ],
        );
        final nwMap = TileMapResult(
          width: 1,
          height: 1,
          grid: [
            ['p1'],
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
      });
    });

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
      final oldWorldTopology = const MapTopology(
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
      final newWorldTopology = const MapTopology(
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
      final combinedTopology = const MapTopology(
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

      test(
        'projects marker in destination region with halo + destination scope',
        () {
          final game = gameForCrossRegionDraft();
          final tileByReg = {'oldWorld': oldWorldMap, 'newWorld': newWorldMap};
          final topoByReg = {
            'oldWorld': oldWorldTopology,
            'newWorld': newWorldTopology,
          };
          final mapView = buildInitGameMapViewData(
            game: game,
            tileMapByRegion: tileByReg,
            topologyByRegion: topoByReg,
            cellSize: 8,
          );
          final projected =
              GameMapAreaStateLogic.projectFleetMarkersForHumanDraft(
                region: mapView.newWorld,
                game: game,
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
                humanPlayerId: humanId,
                tileMapByRegion: tileByReg,
                topologyByRegion: topoByReg,
                combinedTopology: combinedTopology,
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
        final game = gameForCrossRegionDraft();
        final tileByReg = {'oldWorld': oldWorldMap, 'newWorld': newWorldMap};
        final topoByReg = {
          'oldWorld': oldWorldTopology,
          'newWorld': newWorldTopology,
        };
        final mapView = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: tileByReg,
          topologyByRegion: topoByReg,
          cellSize: 8,
        );
        final projected =
            GameMapAreaStateLogic.projectFleetMarkersForHumanDraft(
              region: mapView.oldWorld,
              game: game,
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
              humanPlayerId: humanId,
              tileMapByRegion: tileByReg,
              topologyByRegion: topoByReg,
              combinedTopology: combinedTopology,
            );
        expect(projected.fleetTileMarkers, isEmpty);
      });

      test('canceling draft restores source-region marker', () {
        final game = gameForCrossRegionDraft();
        final tileByReg = {'oldWorld': oldWorldMap, 'newWorld': newWorldMap};
        final topoByReg = {
          'oldWorld': oldWorldTopology,
          'newWorld': newWorldTopology,
        };
        final mapView = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: tileByReg,
          topologyByRegion: topoByReg,
          cellSize: 8,
        );
        final projected =
            GameMapAreaStateLogic.projectFleetMarkersForHumanDraft(
              region: mapView.oldWorld,
              game: game,
              orders: const ct_models.Orders(),
              humanPlayerId: humanId,
              tileMapByRegion: tileByReg,
              topologyByRegion: topoByReg,
              combinedTopology: combinedTopology,
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
