import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        kWorkTargetBuildImprovement,
        kWorkTargetBuildRoad,
        kWorkTargetExplore,
        kWorkTargetProspect;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  const humanPlayerId = 'gp1';
  const explorerId = 'u_explorer';

  RegionMapViewData baseRegion(
    String regionId, {
    List<CivilianTileMarkerView> markers = const [],
    List<CellViewData>? cells,
  }) {
    return RegionMapViewData(
      regionId: regionId,
      width: 2,
      height: 1,
      cellSize: 16,
      cells:
          cells ??
          const [
            CellViewData(x: 0, y: 0, regionCellId: 'p1', isSea: false),
            CellViewData(x: 1, y: 0, regionCellId: 'p1', isSea: false),
          ],
      capitalMarkers: const [],
      portMarkers: const [],
      factionColors: const {},
      greatPowerFactionIds: const {},
      terrainColors: const {},
      unitMarkers: const [],
      civilianTileMarkers: markers,
    );
  }

  CivilianTileMarkerView civilianMarker({
    required String tileKey,
    required String unitId,
    required String unitType,
    int x = 0,
    int y = 0,
    String localProvinceId = 'p1',
  }) {
    return CivilianTileMarkerView(
      tileKey: tileKey,
      x: x,
      y: y,
      localProvinceId: localProvinceId,
      unitIds: [unitId],
      unitTypes: {unitId: unitType},
      representativeUnitType: unitType,
      stackCount: 1,
      representativeIsAssigned: false,
    );
  }

  ct_models.Game humanGame({
    ct_models.RegionData? oldWorld,
    ct_models.RegionData? newWorld,
    Map<String, Map<String, String>>? playerVisibilityByTile,
  }) {
    return ct_models.Game(
      id: 'g',
      worldState: ct_models.WorldState(
        turnState: const ct_models.TurnState(
          phase: ct_models.TurnPhase.orders,
          turnNumber: 1,
        ),
        oldWorld:
            oldWorld ?? const ct_models.RegionData(provinces: [], units: []),
        newWorld:
            newWorld ?? const ct_models.RegionData(provinces: [], units: []),
        playerVisibilityByTile: playerVisibilityByTile ?? const {},
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

  ct_models.Game gameExplorerOldToNew({required String sourceTile}) {
    return humanGame(
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
      newWorld: const ct_models.RegionData(
        provinces: [
          ct_models.Province(id: 'newWorld|p1', regionId: 'newWorld'),
          ct_models.Province(id: 'newWorld|pA', regionId: 'newWorld'),
          ct_models.Province(id: 'newWorld|pB', regionId: 'newWorld'),
        ],
        units: [],
      ),
    );
  }

  ct_models.Orders prospectOrder(String targetTile) {
    return ct_models.Orders(
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
  }

  group('GameMapAreaStateLogic', () {
    test(
      'projectCivilianMarkersForHumanDraft projects pending assignment tile in same turn',
      () {
        const sourceTile = 'oldWorld|p1|0|0';
        const targetTile = 'oldWorld|p1|1|0';
        const unitId = 'u_builder';

        final region = baseRegion(
          'oldWorld',
          markers: [
            civilianMarker(
              tileKey: sourceTile,
              unitId: unitId,
              unitType: ct_models.kUnitTypeBuilder,
            ),
          ],
        );
        final game = humanGame(
          oldWorld: ct_models.RegionData(
            provinces: const [
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
          playerVisibilityByTile: const {
            humanPlayerId: {targetTile: 'fogged'},
          },
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
        test('Old World explorer with prospect draft appears in New World '
            'even when New World has no standing civilian markers', () {
          const sourceTile = 'oldWorld|p1|0|0';
          const targetTile = 'newWorld|p1|1|0';
          final game = gameExplorerOldToNew(sourceTile: sourceTile);
          final oldRegion = baseRegion(
            'oldWorld',
            markers: [
              civilianMarker(
                tileKey: sourceTile,
                unitId: explorerId,
                unitType: ct_models.kUnitTypeExplorer,
              ),
            ],
          );
          final newRegion = baseRegion('newWorld');
          final orders = prospectOrder(targetTile);

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
          final game = humanGame(
            oldWorld: const ct_models.RegionData(
              provinces: [
                ct_models.Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
              ],
              units: [],
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
          );
          final newRegion = baseRegion(
            'newWorld',
            markers: [
              civilianMarker(
                tileKey: sourceTile,
                unitId: explorerId,
                unitType: ct_models.kUnitTypeExplorer,
              ),
            ],
          );
          final oldRegion = baseRegion('oldWorld');
          final orders = prospectOrder(targetTile);

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
            final game = gameExplorerOldToNew(sourceTile: sourceTile);
            final newRegion = baseRegion('newWorld');
            final orders = prospectOrder(targetTile);
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
          final game = gameExplorerOldToNew(sourceTile: sourceTile);
          final oldRegion = baseRegion(
            'oldWorld',
            markers: [
              civilianMarker(
                tileKey: sourceTile,
                unitId: explorerId,
                unitType: ct_models.kUnitTypeExplorer,
              ),
            ],
          );
          final newRegion = baseRegion('newWorld');
          final ordersDraft = prospectOrder(targetTile);
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
            final game = gameExplorerOldToNew(sourceTile: sourceTile);
            final newRegion = baseRegion(
              'newWorld',
              cells: const [
                CellViewData(x: 0, y: 0, regionCellId: 'pB', isSea: false),
                CellViewData(x: 1, y: 0, regionCellId: 'pA', isSea: false),
              ],
            );
            final ordersA = prospectOrder(targetA);
            final ordersB = prospectOrder(targetB);

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
          final game = humanGame(
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
          );
          final newRegion = baseRegion(
            'newWorld',
            markers: [
              civilianMarker(
                tileKey: targetTile,
                unitId: merchantId,
                unitType: ct_models.kUnitTypeMerchant,
                x: 1,
              ),
            ],
          );
          final orders = prospectOrder(targetTile);
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

          final oldRegion = baseRegion(
            'oldWorld',
            markers: [
              civilianMarker(
                tileKey: sourceTile,
                unitId: explorerId,
                unitType: ct_models.kUnitTypeExplorer,
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
