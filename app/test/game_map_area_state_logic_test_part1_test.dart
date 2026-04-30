import 'package:colonizethis_app/features/game/flame/game_map_area_state_logic.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        PlayerView,
        VisibilityLevel,
        buildPlayerView,
        getValidWorkOrderTileKeysWithVisibility,
        kWorkTargetBuildImprovement,
        kWorkTargetBuildRoad,
        kWorkTargetExplore,
        kWorkTargetProspect;
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
              unitTypes: {unitId: ct_models.kUnitTypeBuilder},
              representativeUnitType: ct_models.kUnitTypeBuilder,
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
                  type: ct_models.kUnitTypeBuilder,
                  ownerId: humanPlayerId,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: sourceTile,
                  status: ct_models.UnitStatus.idle,
                ),
              ],
            ),
            newWorld: ct_models.RegionData(provinces: [], units: []),
            playerVisibilityByTile: const {
              humanPlayerId: {targetTile: 'fogged'},
            },
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
                target: kWorkTargetBuildImprovement,
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
        expect(marker.applyCivilianRevealHalo, isTrue);
      },
    );

    group(
      'projectCivilianMarkersForHumanDraft cross-region draft projection',
      () {
        const humanPlayerId = 'gp1';
        const explorerId = 'u_explorer';

        RegionMapViewData emptyRegion(String regionId) {
          return RegionMapViewData(
            regionId: regionId,
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
            civilianTileMarkers: const [],
          );
        }

        ct_models.Game gameExplorerOldToNew({
          required String sourceTile,
          required String targetTile,
        }) {
          return ct_models.Game(
            id: 'g',
            worldState: ct_models.WorldState(
              turnState: const ct_models.TurnState(
                phase: ct_models.TurnPhase.orders,
                turnNumber: 1,
              ),
              oldWorld: ct_models.RegionData(
                provinces: const [
                  ct_models.Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
                  ct_models.Province(id: 'oldWorld|pA', regionId: 'oldWorld'),
                ],
                units: [
                  ct_models.Unit(
                    id: explorerId,
                    type: ct_models.kUnitTypeExplorer,
                    ownerId: humanPlayerId,
                    locationProvinceId: 'oldWorld|p1',
                    tileKey: sourceTile,
                    status: ct_models.UnitStatus.idle,
                  ),
                ],
              ),
              newWorld: ct_models.RegionData(
                provinces: const [
                  ct_models.Province(id: 'newWorld|p1', regionId: 'newWorld'),
                  ct_models.Province(id: 'newWorld|pA', regionId: 'newWorld'),
                  ct_models.Province(id: 'newWorld|pB', regionId: 'newWorld'),
                ],
                units: const [],
              ),
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
        }

        test('Old World explorer with prospect draft appears in New World '
            'even when New World has no standing civilian markers', () {
          const sourceTile = 'oldWorld|p1|0|0';
          const targetTile = 'newWorld|p1|1|0';
          final game = gameExplorerOldToNew(
            sourceTile: sourceTile,
            targetTile: targetTile,
          );
          final oldRegion = RegionMapViewData(
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
                unitIds: [explorerId],
                unitTypes: {explorerId: ct_models.kUnitTypeExplorer},
                representativeUnitType: ct_models.kUnitTypeExplorer,
                stackCount: 1,
                representativeIsAssigned: false,
              ),
            ],
          );
          final newRegion = emptyRegion('newWorld');
          final orders = ct_models.Orders(
            workOrdersByPlayerId: {
              humanPlayerId: [
                ct_models.WorkOrder(
                  unitId: explorerId,
                  target: kWorkTargetProspect,
                  targetTileKey: targetTile,
                ),
              ],
            },
          );

          final projectedNw =
              GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
                region: newRegion,
                game: game,
                orders: orders,
                humanPlayerId: humanPlayerId,
              );
          expect(projectedNw.civilianTileMarkers, hasLength(1));
          final nwMarker = projectedNw.civilianTileMarkers.single;
          expect(nwMarker.tileKey, targetTile);
          expect(nwMarker.localProvinceId, 'p1');
          expect(nwMarker.unitIds, contains(explorerId));

          final projectedOw =
              GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
                region: oldRegion,
                game: game,
                orders: orders,
                humanPlayerId: humanPlayerId,
              );
          expect(projectedOw.civilianTileMarkers, isEmpty);
        });

        test('New World explorer with prospect draft appears in Old World '
            'and leaves source New World projection', () {
          const sourceTile = 'newWorld|p1|0|0';
          const targetTile = 'oldWorld|p1|1|0';
          final game = ct_models.Game(
            id: 'g',
            worldState: ct_models.WorldState(
              turnState: const ct_models.TurnState(
                phase: ct_models.TurnPhase.orders,
                turnNumber: 1,
              ),
              oldWorld: ct_models.RegionData(
                provinces: const [
                  ct_models.Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
                ],
                units: const [],
              ),
              newWorld: ct_models.RegionData(
                provinces: const [
                  ct_models.Province(id: 'newWorld|p1', regionId: 'newWorld'),
                ],
                units: [
                  ct_models.Unit(
                    id: explorerId,
                    type: ct_models.kUnitTypeExplorer,
                    ownerId: humanPlayerId,
                    locationProvinceId: 'newWorld|p1',
                    tileKey: sourceTile,
                    status: ct_models.UnitStatus.idle,
                  ),
                ],
              ),
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
          final newRegion = RegionMapViewData(
            regionId: 'newWorld',
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
                unitIds: [explorerId],
                unitTypes: {explorerId: ct_models.kUnitTypeExplorer},
                representativeUnitType: ct_models.kUnitTypeExplorer,
                stackCount: 1,
                representativeIsAssigned: false,
              ),
            ],
          );
          final oldRegion = emptyRegion('oldWorld');
          final orders = ct_models.Orders(
            workOrdersByPlayerId: {
              humanPlayerId: [
                ct_models.WorkOrder(
                  unitId: explorerId,
                  target: kWorkTargetProspect,
                  targetTileKey: targetTile,
                ),
              ],
            },
          );

          final projectedOw =
              GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
                region: oldRegion,
                game: game,
                orders: orders,
                humanPlayerId: humanPlayerId,
              );
          expect(projectedOw.civilianTileMarkers, hasLength(1));
          expect(projectedOw.civilianTileMarkers.single.tileKey, targetTile);

          final projectedNw =
              GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
                region: newRegion,
                game: game,
                orders: orders,
                humanPlayerId: humanPlayerId,
              );
          expect(projectedNw.civilianTileMarkers, isEmpty);
        });

        test(
          'overlapping local province id does not alias regions in projection',
          () {
            const sourceTile = 'oldWorld|p1|0|0';
            const targetTile = 'newWorld|p1|1|0';
            final game = gameExplorerOldToNew(
              sourceTile: sourceTile,
              targetTile: targetTile,
            );
            final newRegion = emptyRegion('newWorld');
            final orders = ct_models.Orders(
              workOrdersByPlayerId: {
                humanPlayerId: [
                  ct_models.WorkOrder(
                    unitId: explorerId,
                    target: kWorkTargetProspect,
                    targetTileKey: targetTile,
                  ),
                ],
              },
            );
            final projectedNw =
                GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
                  region: newRegion,
                  game: game,
                  orders: orders,
                  humanPlayerId: humanPlayerId,
                );
            expect(projectedNw.civilianTileMarkers.single.tileKey, targetTile);
            expect(
              projectedNw.civilianTileMarkers.single.tileKey,
              isNot(startsWith('oldWorld|')),
            );
          },
        );

        test('clearing cross-region draft restores source-region marker', () {
          const sourceTile = 'oldWorld|p1|0|0';
          const targetTile = 'newWorld|p1|1|0';
          final game = gameExplorerOldToNew(
            sourceTile: sourceTile,
            targetTile: targetTile,
          );
          final oldRegion = RegionMapViewData(
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
                unitIds: [explorerId],
                unitTypes: {explorerId: ct_models.kUnitTypeExplorer},
                representativeUnitType: ct_models.kUnitTypeExplorer,
                stackCount: 1,
                representativeIsAssigned: false,
              ),
            ],
          );
          final newRegion = emptyRegion('newWorld');
          final ordersDraft = ct_models.Orders(
            workOrdersByPlayerId: {
              humanPlayerId: [
                ct_models.WorkOrder(
                  unitId: explorerId,
                  target: kWorkTargetProspect,
                  targetTileKey: targetTile,
                ),
              ],
            },
          );
          final cleared = const ct_models.Orders();

          expect(
            GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
              region: newRegion,
              game: game,
              orders: ordersDraft,
              humanPlayerId: humanPlayerId,
            ).civilianTileMarkers,
            isNotEmpty,
          );
          final afterCancelNw =
              GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
                region: newRegion,
                game: game,
                orders: cleared,
                humanPlayerId: humanPlayerId,
              );
          expect(afterCancelNw.civilianTileMarkers, isEmpty);

          final afterCancelOw =
              GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
                region: oldRegion,
                game: game,
                orders: cleared,
                humanPlayerId: humanPlayerId,
              );
          expect(afterCancelOw.civilianTileMarkers, hasLength(1));
          expect(afterCancelOw.civilianTileMarkers.single.tileKey, sourceTile);
        });

        test(
          'replacing cross-region prospect target updates destination tile',
          () {
            const sourceTile = 'oldWorld|p1|0|0';
            const targetA = 'newWorld|pA|1|0';
            const targetB = 'newWorld|pB|0|0';
            final game = gameExplorerOldToNew(
              sourceTile: sourceTile,
              targetTile: targetA,
            );
            final newRegion = RegionMapViewData(
              regionId: 'newWorld',
              width: 2,
              height: 1,
              cellSize: 16,
              cells: const [
                CellViewData(x: 0, y: 0, regionCellId: 'pB', isSea: false),
                CellViewData(x: 1, y: 0, regionCellId: 'pA', isSea: false),
              ],
              capitalMarkers: const [],
              portMarkers: const [],
              factionColors: const {},
              greatPowerFactionIds: const {},
              terrainColors: const {},
              unitMarkers: const [],
              civilianTileMarkers: const [],
            );
            final ordersA = ct_models.Orders(
              workOrdersByPlayerId: {
                humanPlayerId: [
                  ct_models.WorkOrder(
                    unitId: explorerId,
                    target: kWorkTargetProspect,
                    targetTileKey: targetA,
                  ),
                ],
              },
            );
            final ordersB = ct_models.Orders(
              workOrdersByPlayerId: {
                humanPlayerId: [
                  ct_models.WorkOrder(
                    unitId: explorerId,
                    target: kWorkTargetProspect,
                    targetTileKey: targetB,
                  ),
                ],
              },
            );

            expect(
              GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
                region: newRegion,
                game: game,
                orders: ordersA,
                humanPlayerId: humanPlayerId,
              ).civilianTileMarkers.single.tileKey,
              targetA,
            );
            final markerB =
                GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
                  region: newRegion,
                  game: game,
                  orders: ordersB,
                  humanPlayerId: humanPlayerId,
                ).civilianTileMarkers.single;
            expect(markerB.tileKey, targetB);
            expect(markerB.localProvinceId, 'pB');
          },
        );

        test('cross-region prospect stacks explorer onto existing destination '
            'civilian marker', () {
          const sourceTile = 'oldWorld|p1|0|0';
          const targetTile = 'newWorld|p1|1|0';
          const merchantId = 'u_merchant';
          final game = ct_models.Game(
            id: 'g',
            worldState: ct_models.WorldState(
              turnState: const ct_models.TurnState(
                phase: ct_models.TurnPhase.orders,
                turnNumber: 1,
              ),
              oldWorld: ct_models.RegionData(
                provinces: const [
                  ct_models.Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
                ],
                units: [
                  ct_models.Unit(
                    id: explorerId,
                    type: ct_models.kUnitTypeExplorer,
                    ownerId: humanPlayerId,
                    locationProvinceId: 'oldWorld|p1',
                    tileKey: sourceTile,
                    status: ct_models.UnitStatus.idle,
                  ),
                ],
              ),
              newWorld: ct_models.RegionData(
                provinces: const [
                  ct_models.Province(id: 'newWorld|p1', regionId: 'newWorld'),
                ],
                units: [
                  ct_models.Unit(
                    id: merchantId,
                    type: ct_models.kUnitTypeMerchant,
                    ownerId: humanPlayerId,
                    locationProvinceId: 'newWorld|p1',
                    tileKey: targetTile,
                    status: ct_models.UnitStatus.idle,
                  ),
                ],
              ),
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
          final newRegion = RegionMapViewData(
            regionId: 'newWorld',
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
                tileKey: targetTile,
                x: 1,
                y: 0,
                localProvinceId: 'p1',
                unitIds: [merchantId],
                unitTypes: {merchantId: ct_models.kUnitTypeMerchant},
                representativeUnitType: ct_models.kUnitTypeMerchant,
                stackCount: 1,
                representativeIsAssigned: false,
              ),
            ],
          );
          final orders = ct_models.Orders(
            workOrdersByPlayerId: {
              humanPlayerId: [
                ct_models.WorkOrder(
                  unitId: explorerId,
                  target: kWorkTargetProspect,
                  targetTileKey: targetTile,
                ),
              ],
            },
          );
          final projected =
              GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
                region: newRegion,
                game: game,
                orders: orders,
                humanPlayerId: humanPlayerId,
              );
          expect(projected.civilianTileMarkers, hasLength(1));
          final m = projected.civilianTileMarkers.single;
          expect(m.tileKey, targetTile);
          expect(m.unitIds, containsAll([explorerId, merchantId]));

          final oldRegion = RegionMapViewData(
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
                unitIds: [explorerId],
                unitTypes: {explorerId: ct_models.kUnitTypeExplorer},
                representativeUnitType: ct_models.kUnitTypeExplorer,
                stackCount: 1,
                representativeIsAssigned: false,
              ),
            ],
          );
          expect(
            GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
              region: oldRegion,
              game: game,
              orders: orders,
              humanPlayerId: humanPlayerId,
            ).civilianTileMarkers,
            isEmpty,
          );
        });
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

    group('translateWorkTargetTileKey', () {
      test('explore preserves exact assigned tile key', () {
        final translated = GameMapAreaStateLogic.translateWorkTargetTileKey(
          tileKey: 'oldWorld|p1|10|20',
          workTarget: kWorkTargetExplore,
        );
        expect(translated, 'oldWorld|p1|10|20');
      });

      test('non-province-based work targets preserve tileKey', () {
        final translated = GameMapAreaStateLogic.translateWorkTargetTileKey(
          tileKey: 'oldWorld|p1|10|20',
          workTarget: 'move',
        );
        expect(translated, 'oldWorld|p1|10|20');
      });

      test('short tile keys are returned unchanged', () {
        final translated = GameMapAreaStateLogic.translateWorkTargetTileKey(
          tileKey: 'oldWorld|p1',
          workTarget: kWorkTargetExplore,
        );
        expect(translated, 'oldWorld|p1');
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
          target: kWorkTargetExplore,
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
                target: kWorkTargetBuildImprovement,
                targetTileKey: 'oldWorld|p1|0|0',
              ),
            ],
          },
        );
        const replacement = ct_models.WorkOrder(
          unitId: unitId,
          target: kWorkTargetBuildRoad,
          targetTileKey: 'oldWorld|p1|1|0',
        );

        final updated = GameMapAreaStateLogic.addHumanWorkOrder(
          orders: orders,
          humanPlayerId: humanPlayerId,
          workOrder: replacement,
        );

        expect(updated.workOrdersByPlayerId[humanPlayerId], [replacement]);
      });

      test('drops pending civilian move for same unit when assigning work', () {
        const humanPlayerId = 'gp1';
        const pendingMove = ct_models.MoveOrder(
          unitId: 'u1',
          destinationTileKey: 'oldWorld|p2|0|0',
        );
        final orders = ct_models.Orders(
          moveOrdersByPlayerId: {
            humanPlayerId: [pendingMove],
          },
        );
        const work = ct_models.WorkOrder(
          unitId: 'u1',
          target: kWorkTargetExplore,
          targetTileKey: 'oldWorld|p2|0|0',
        );

        final updated = GameMapAreaStateLogic.addHumanWorkOrder(
          orders: orders,
          humanPlayerId: humanPlayerId,
          workOrder: work,
        );

        expect(updated.moveOrdersByPlayerId[humanPlayerId], isEmpty);
        expect(updated.workOrdersByPlayerId[humanPlayerId], [work]);
      });
    });
  });
}
