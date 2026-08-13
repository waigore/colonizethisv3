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

import 'game_map_area_state_logic_test_support.dart';

void main() {
  suppressLogsForTests();

  const humanPlayerId = kStateLogicHumanPlayerId;
  const explorerId = kStateLogicExplorerId;

  group('GameMapAreaStateLogic', () {
    test(
      'projectCivilianMarkersForHumanDraft projects pending assignment tile in same turn',
      () {
        const sourceTile = 'oldWorld|p1|0|0';
        const targetTile = 'oldWorld|p1|1|0';
        const unitId = 'u_builder';

        final region = stateLogicBaseRegion(
          'oldWorld',
          markers: [
            stateLogicCivilianMarker(
              tileKey: sourceTile,
              unitId: unitId,
              unitType: ct_models.kUnitTypeBuilder,
            ),
          ],
        );
        final game = stateLogicHumanGame(
          oldWorld: ct_models.RegionData(
            provinces: [stateLogicProv('oldWorld', 'p1')],
            units: [
              stateLogicUnit(
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
              stateLogicWorkOrder(
                unitId: unitId,
                target: kWorkTargetBuildImprovement,
                targetTileKey: targetTile,
              ),
            ],
          },
        );

        final projected = stateLogicProjectDraft(
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
        test('OW↔NW prospect drafts project onto destination and clear source',
            () {
          for (final case_ in <
            ({
              String source,
              String target,
              String sourceRegion,
              String destRegion,
              ct_models.Game Function(String) gameAt,
            })
          >[
            (
              source: 'oldWorld|p1|0|0',
              target: 'newWorld|p1|1|0',
              sourceRegion: 'oldWorld',
              destRegion: 'newWorld',
              gameAt: (s) => stateLogicGameExplorerOldToNew(sourceTile: s),
            ),
            (
              source: 'newWorld|p1|0|0',
              target: 'oldWorld|p1|1|0',
              sourceRegion: 'newWorld',
              destRegion: 'oldWorld',
              gameAt: (s) => stateLogicGameExplorerNewToOld(sourceTile: s),
            ),
          ]) {
            final game = case_.gameAt(case_.source);
            final orders = stateLogicProspectOrder(case_.target);
            expectStateLogicSingleProjectedTile(
              region: stateLogicBaseRegion(case_.destRegion),
              game: game,
              orders: orders,
              tileKey: case_.target,
            );
            expectStateLogicEmptyProjection(
              region: stateLogicRegionWithExplorerMarker(
                case_.sourceRegion,
                case_.source,
              ),
              game: game,
              orders: orders,
            );
          }

          // OW→NW also pins local province + unit id on the destination marker.
          const owSource = 'oldWorld|p1|0|0';
          const nwTarget = 'newWorld|p1|1|0';
          final owGame = stateLogicGameExplorerOldToNew(sourceTile: owSource);
          final nwMarker = stateLogicProjectDraft(
            region: stateLogicBaseRegion('newWorld'),
            game: owGame,
            orders: stateLogicProspectOrder(nwTarget),
          ).civilianTileMarkers.single;
          expect(nwMarker.localProvinceId, 'p1');
          expect(nwMarker.unitIds, contains(explorerId));
        });

        test('aliasing, clear, retarget, and stack onto destination marker',
            () {
          const sourceTile = 'oldWorld|p1|0|0';
          const targetTile = 'newWorld|p1|1|0';
          const targetA = 'newWorld|pA|1|0';
          const targetB = 'newWorld|pB|0|0';
          const merchantId = 'u_merchant';
          final game = stateLogicGameExplorerOldToNew(sourceTile: sourceTile);
          final oldRegion = stateLogicRegionWithExplorerMarker(
            'oldWorld',
            sourceTile,
          );
          final newRegion = stateLogicBaseRegion('newWorld');
          final ordersDraft = stateLogicProspectOrder(targetTile);

          final projectedNw = stateLogicProjectDraft(
            region: newRegion,
            game: game,
            orders: ordersDraft,
          );
          expect(projectedNw.civilianTileMarkers.single.tileKey, targetTile);
          expect(
            projectedNw.civilianTileMarkers.single.tileKey,
            isNot(startsWith('oldWorld|')),
          );

          expectStateLogicEmptyProjection(
            region: newRegion,
            game: game,
            orders: const ct_models.Orders(),
          );
          expectStateLogicSingleProjectedTile(
            region: oldRegion,
            game: game,
            orders: const ct_models.Orders(),
            tileKey: sourceTile,
          );

          final retargetRegion = stateLogicBaseRegion(
            'newWorld',
            cells: const [
              CellViewData(x: 0, y: 0, regionCellId: 'pB', isSea: false),
              CellViewData(x: 1, y: 0, regionCellId: 'pA', isSea: false),
            ],
          );
          expectStateLogicSingleProjectedTile(
            region: retargetRegion,
            game: game,
            orders: stateLogicProspectOrder(targetA),
            tileKey: targetA,
          );
          final markerB = stateLogicProjectDraft(
            region: retargetRegion,
            game: game,
            orders: stateLogicProspectOrder(targetB),
          ).civilianTileMarkers.single;
          expect(markerB.tileKey, targetB);
          expect(markerB.localProvinceId, 'pB');

          final stackGame = stateLogicHumanGame(
            oldWorld: ct_models.RegionData(
              provinces: [stateLogicProv('oldWorld', 'p1')],
              units: [
                stateLogicUnit(
                  id: explorerId,
                  type: ct_models.kUnitTypeExplorer,
                  provinceId: 'oldWorld|p1',
                  tileKey: sourceTile,
                ),
              ],
            ),
            newWorld: ct_models.RegionData(
              provinces: [stateLogicProv('newWorld', 'p1')],
              units: [
                stateLogicUnit(
                  id: merchantId,
                  type: ct_models.kUnitTypeMerchant,
                  provinceId: 'newWorld|p1',
                  tileKey: targetTile,
                ),
              ],
            ),
          );
          final stackRegion = stateLogicBaseRegion(
            'newWorld',
            markers: [
              stateLogicCivilianMarker(
                tileKey: targetTile,
                unitId: merchantId,
                unitType: ct_models.kUnitTypeMerchant,
                x: 1,
              ),
            ],
          );
          final stackOrders = stateLogicProspectOrder(targetTile);
          final stacked = stateLogicProjectDraft(
            region: stackRegion,
            game: stackGame,
            orders: stackOrders,
          ).civilianTileMarkers.single;
          expect(stacked.tileKey, targetTile);
          expect(stacked.unitIds, containsAll([explorerId, merchantId]));
          expectStateLogicEmptyProjection(
            region: stateLogicRegionWithExplorerMarker('oldWorld', sourceTile),
            game: stackGame,
            orders: stackOrders,
          );
        });
      },
    );

    test('selection / province-id / region-index / translate helpers', () {
      for (final case_ in <({String selected, String assigned, String? out})>[
        (
          selected: 'oldWorld|p1|0|0',
          assigned: 'oldWorld|p1|1|0',
          out: null,
        ),
        (
          selected: 'oldWorld|p1|1|0',
          assigned: 'oldWorld|p1|1|0',
          out: 'oldWorld|p1|1|0',
        ),
      ]) {
        expect(
          GameMapAreaStateLogicWorkTargets.selectionAfterWorkAssignment(
            currentSelectedCivilianTileKey: case_.selected,
            assignedTileKey: case_.assigned,
          ),
          case_.out,
        );
      }
      expect(
        displayProvinceOrSeaIdFromTileKey('oldWorld|p1|10|20'),
        'oldWorld|p1',
      );
      expect(displayProvinceOrSeaIdFromTileKey('badKey'), isNull);
      expect(displayProvinceOrSeaIdFromTileKey(null), isNull);
      expect(GameMapAreaStateLogicShell.regionIndexFromWorldRegionId('newWorld'), 1);
      expect(GameMapAreaStateLogicShell.regionIndexFromWorldRegionId('oldWorld'), 0);
      const tile = 'oldWorld|p1|10|20';
      for (final case_ in <({String tileKey, String workTarget})>[
        (tileKey: tile, workTarget: kWorkTargetExplore),
        (tileKey: tile, workTarget: 'move'),
        (tileKey: 'oldWorld|p1', workTarget: kWorkTargetExplore),
      ]) {
        expect(
          GameMapAreaStateLogicShell.translateWorkTargetTileKey(
            tileKey: case_.tileKey,
            workTarget: case_.workTarget,
          ),
          case_.tileKey,
        );
      }
    });

    test('addHumanWorkOrder appends, replaces, and drops pending move', () {
      const explore = ct_models.WorkOrder(
        unitId: 'u1',
        target: kWorkTargetExplore,
        targetTileKey: 'oldWorld|p1|0|0',
      );
      expect(
        GameMapAreaStateLogicWorkTargets.addHumanWorkOrder(
          orders: const ct_models.Orders(
            workOrdersByPlayerId: {humanPlayerId: []},
          ),
          humanPlayerId: humanPlayerId,
          workOrder: explore,
        ).workOrdersByPlayerId[humanPlayerId],
        [explore],
      );

      const replacement = ct_models.WorkOrder(
        unitId: 'u1',
        target: kWorkTargetBuildRoad,
        targetTileKey: 'oldWorld|p1|1|0',
      );
      expect(
        GameMapAreaStateLogicWorkTargets.addHumanWorkOrder(
          orders: const ct_models.Orders(
            workOrdersByPlayerId: {
              humanPlayerId: [
                ct_models.WorkOrder(
                  unitId: 'u1',
                  target: kWorkTargetBuildImprovement,
                  targetTileKey: 'oldWorld|p1|0|0',
                ),
              ],
            },
          ),
          humanPlayerId: humanPlayerId,
          workOrder: replacement,
        ).workOrdersByPlayerId[humanPlayerId],
        [replacement],
      );

      const work = ct_models.WorkOrder(
        unitId: 'u1',
        target: kWorkTargetExplore,
        targetTileKey: 'oldWorld|p2|0|0',
      );
      final updated = GameMapAreaStateLogicWorkTargets.addHumanWorkOrder(
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
}
