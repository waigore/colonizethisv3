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

  ct_models.Province prov(String regionId, String localId) =>
      ct_models.Province(id: '$regionId|$localId', regionId: regionId);

  ct_models.Unit unit({
    required String id,
    required String type,
    required String provinceId,
    required String tileKey,
  }) => ct_models.Unit(
    id: id,
    type: type,
    ownerId: humanPlayerId,
    locationProvinceId: provinceId,
    tileKey: tileKey,
    status: ct_models.UnitStatus.idle,
  );

  ct_models.WorkOrder workOrder({
    required String unitId,
    required String target,
    required String targetTileKey,
  }) => ct_models.WorkOrder(
    unitId: unitId,
    target: target,
    targetTileKey: targetTileKey,
  );

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
        provinces: [prov('oldWorld', 'p1'), prov('oldWorld', 'pA')],
        units: [
          unit(
            id: explorerId,
            type: ct_models.kUnitTypeExplorer,
            provinceId: 'oldWorld|p1',
            tileKey: sourceTile,
          ),
        ],
      ),
      newWorld: ct_models.RegionData(
        provinces: [
          prov('newWorld', 'p1'),
          prov('newWorld', 'pA'),
          prov('newWorld', 'pB'),
        ],
        units: const [],
      ),
    );
  }

  ct_models.Orders prospectOrder(String targetTile) => ct_models.Orders(
    workOrdersByPlayerId: {
      humanPlayerId: [
        workOrder(
          unitId: explorerId,
          target: kWorkTargetProspect,
          targetTileKey: targetTile,
        ),
      ],
    },
  );

  RegionMapViewData projectDraft({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
  }) => GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
    region: region,
    game: game,
    orders: orders,
    humanPlayerId: humanPlayerId,
  );

  RegionMapViewData regionWithExplorerMarker(
    String regionId,
    String sourceTile,
  ) => baseRegion(
    regionId,
    markers: [
      civilianMarker(
        tileKey: sourceTile,
        unitId: explorerId,
        unitType: ct_models.kUnitTypeExplorer,
      ),
    ],
  );

  void expectSingleProjectedTile({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String tileKey,
  }) {
    final projected = projectDraft(region: region, game: game, orders: orders);
    expect(projected.civilianTileMarkers, hasLength(1));
    expect(projected.civilianTileMarkers.single.tileKey, tileKey);
  }

  void expectEmptyProjection({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
  }) {
    expect(
      projectDraft(region: region, game: game, orders: orders)
          .civilianTileMarkers,
      isEmpty,
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
            provinces: [prov('oldWorld', 'p1')],
            units: [
              unit(
                id: unitId,
                type: ct_models.kUnitTypeBuilder,
                provinceId: 'oldWorld|p1',
                tileKey: sourceTile,
              ),
            ],
          ),
          playerVisibilityByTile: const {
            humanPlayerId: {targetTile: 'fogged'},
          },
        );
        final orders = ct_models.Orders(
          workOrdersByPlayerId: {
            humanPlayerId: [
              workOrder(
                unitId: unitId,
                target: kWorkTargetBuildImprovement,
                targetTileKey: targetTile,
              ),
            ],
          },
        );

        final projected = projectDraft(
          region: region,
          game: game,
          orders: orders,
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
          final oldRegion = regionWithExplorerMarker('oldWorld', sourceTile);
          final newRegion = baseRegion('newWorld');
          final orders = prospectOrder(targetTile);

          expectSingleProjectedTile(
            region: newRegion,
            game: game,
            orders: orders,
            tileKey: targetTile,
          );
          final nwMarker = projectDraft(
            region: newRegion,
            game: game,
            orders: orders,
          ).civilianTileMarkers.single;
          expect(nwMarker.localProvinceId, 'p1');
          expect(nwMarker.unitIds, contains(explorerId));
          expectEmptyProjection(
            region: oldRegion,
            game: game,
            orders: orders,
          );
        });

        test('New World explorer with prospect draft appears in Old World '
            'and leaves source New World projection', () {
          const sourceTile = 'newWorld|p1|0|0';
          const targetTile = 'oldWorld|p1|1|0';
          final game = humanGame(
            oldWorld: ct_models.RegionData(
              provinces: [prov('oldWorld', 'p1')],
              units: const [],
            ),
            newWorld: ct_models.RegionData(
              provinces: [prov('newWorld', 'p1')],
              units: [
                unit(
                  id: explorerId,
                  type: ct_models.kUnitTypeExplorer,
                  provinceId: 'newWorld|p1',
                  tileKey: sourceTile,
                ),
              ],
            ),
          );
          final newRegion = regionWithExplorerMarker('newWorld', sourceTile);
          final oldRegion = baseRegion('oldWorld');
          final orders = prospectOrder(targetTile);

          expectSingleProjectedTile(
            region: oldRegion,
            game: game,
            orders: orders,
            tileKey: targetTile,
          );
          expectEmptyProjection(
            region: newRegion,
            game: game,
            orders: orders,
          );
        });

        test(
          'overlapping local province id does not alias regions in projection',
          () {
            const sourceTile = 'oldWorld|p1|0|0';
            const targetTile = 'newWorld|p1|1|0';
            final game = gameExplorerOldToNew(sourceTile: sourceTile);
            final projectedNw = projectDraft(
              region: baseRegion('newWorld'),
              game: game,
              orders: prospectOrder(targetTile),
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
          final oldRegion = regionWithExplorerMarker('oldWorld', sourceTile);
          final newRegion = baseRegion('newWorld');
          final ordersDraft = prospectOrder(targetTile);
          const cleared = ct_models.Orders();

          expect(
            projectDraft(
              region: newRegion,
              game: game,
              orders: ordersDraft,
            ).civilianTileMarkers,
            isNotEmpty,
          );
          expectEmptyProjection(
            region: newRegion,
            game: game,
            orders: cleared,
          );
          expectSingleProjectedTile(
            region: oldRegion,
            game: game,
            orders: cleared,
            tileKey: sourceTile,
          );
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

            expectSingleProjectedTile(
              region: newRegion,
              game: game,
              orders: ordersA,
              tileKey: targetA,
            );
            final markerB = projectDraft(
              region: newRegion,
              game: game,
              orders: ordersB,
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
              provinces: [prov('oldWorld', 'p1')],
              units: [
                unit(
                  id: explorerId,
                  type: ct_models.kUnitTypeExplorer,
                  provinceId: 'oldWorld|p1',
                  tileKey: sourceTile,
                ),
              ],
            ),
            newWorld: ct_models.RegionData(
              provinces: [prov('newWorld', 'p1')],
              units: [
                unit(
                  id: merchantId,
                  type: ct_models.kUnitTypeMerchant,
                  provinceId: 'newWorld|p1',
                  tileKey: targetTile,
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
          final projected = projectDraft(
            region: newRegion,
            game: game,
            orders: orders,
          );
          expect(projected.civilianTileMarkers, hasLength(1));
          final m = projected.civilianTileMarkers.single;
          expect(m.tileKey, targetTile);
          expect(m.unitIds, containsAll([explorerId, merchantId]));
          expectEmptyProjection(
            region: regionWithExplorerMarker('oldWorld', sourceTile),
            game: game,
            orders: orders,
          );
        });
      },
    );

    test('selectionAfterWorkAssignment clears stale selected marker tile', () {
      expect(
        GameMapAreaStateLogic.selectionAfterWorkAssignment(
          currentSelectedCivilianTileKey: 'oldWorld|p1|0|0',
          assignedTileKey: 'oldWorld|p1|1|0',
        ),
        isNull,
      );
    });

    test(
      'selectionAfterWorkAssignment preserves selection on assigned tile',
      () {
        expect(
          GameMapAreaStateLogic.selectionAfterWorkAssignment(
            currentSelectedCivilianTileKey: 'oldWorld|p1|1|0',
            assignedTileKey: 'oldWorld|p1|1|0',
          ),
          'oldWorld|p1|1|0',
        );
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
      test('maps newWorld to 1 and other regions to 0', () {
        expect(
          GameMapAreaStateLogic.regionIndexFromWorldRegionId('newWorld'),
          1,
        );
        expect(
          GameMapAreaStateLogic.regionIndexFromWorldRegionId('oldWorld'),
          0,
        );
      });
    });

    group('translateWorkTargetTileKey', () {
      test('preserves tile keys for explore, move, and short keys', () {
        const tile = 'oldWorld|p1|10|20';
        expect(
          GameMapAreaStateLogic.translateWorkTargetTileKey(
            tileKey: tile,
            workTarget: kWorkTargetExplore,
          ),
          tile,
        );
        expect(
          GameMapAreaStateLogic.translateWorkTargetTileKey(
            tileKey: tile,
            workTarget: 'move',
          ),
          tile,
        );
        expect(
          GameMapAreaStateLogic.translateWorkTargetTileKey(
            tileKey: 'oldWorld|p1',
            workTarget: kWorkTargetExplore,
          ),
          'oldWorld|p1',
        );
      });
    });

    group('addHumanWorkOrder', () {
      test('appends work order under given humanPlayerId', () {
        const work = ct_models.WorkOrder(
          unitId: 'u1',
          target: kWorkTargetExplore,
          targetTileKey: 'oldWorld|p1|0|0',
        );
        final updated = GameMapAreaStateLogic.addHumanWorkOrder(
          orders: const ct_models.Orders(
            workOrdersByPlayerId: {humanPlayerId: []},
          ),
          humanPlayerId: humanPlayerId,
          workOrder: work,
        );
        expect(updated.workOrdersByPlayerId[humanPlayerId], [work]);
      });

      test('replaces existing pending work order for same unit', () {
        const unitId = 'u1';
        const replacement = ct_models.WorkOrder(
          unitId: unitId,
          target: kWorkTargetBuildRoad,
          targetTileKey: 'oldWorld|p1|1|0',
        );
        final updated = GameMapAreaStateLogic.addHumanWorkOrder(
          orders: const ct_models.Orders(
            workOrdersByPlayerId: {
              humanPlayerId: [
                ct_models.WorkOrder(
                  unitId: unitId,
                  target: kWorkTargetBuildImprovement,
                  targetTileKey: 'oldWorld|p1|0|0',
                ),
              ],
            },
          ),
          humanPlayerId: humanPlayerId,
          workOrder: replacement,
        );
        expect(updated.workOrdersByPlayerId[humanPlayerId], [replacement]);
      });

      test('drops pending civilian move for same unit when assigning work', () {
        const work = ct_models.WorkOrder(
          unitId: 'u1',
          target: kWorkTargetExplore,
          targetTileKey: 'oldWorld|p2|0|0',
        );
        final updated = GameMapAreaStateLogic.addHumanWorkOrder(
          orders: ct_models.Orders(
            moveOrdersByPlayerId: {
              humanPlayerId: const [
                ct_models.MoveOrder(
                  unitId: 'u1',
                  destinationTileKey: 'oldWorld|p2|0|0',
                ),
              ],
            },
          ),
          humanPlayerId: humanPlayerId,
          workOrder: work,
        );
        expect(updated.moveOrdersByPlayerId[humanPlayerId], isEmpty);
        expect(updated.workOrdersByPlayerId[humanPlayerId], [work]);
      });
    });
  });
}
