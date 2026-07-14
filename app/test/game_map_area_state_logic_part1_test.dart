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

  ct_models.Game gameExplorerNewToOld({required String sourceTile}) {
    return humanGame(
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
              gameAt: (s) => gameExplorerOldToNew(sourceTile: s),
            ),
            (
              source: 'newWorld|p1|0|0',
              target: 'oldWorld|p1|1|0',
              sourceRegion: 'newWorld',
              destRegion: 'oldWorld',
              gameAt: (s) => gameExplorerNewToOld(sourceTile: s),
            ),
          ]) {
            final game = case_.gameAt(case_.source);
            final orders = prospectOrder(case_.target);
            expectSingleProjectedTile(
              region: baseRegion(case_.destRegion),
              game: game,
              orders: orders,
              tileKey: case_.target,
            );
            expectEmptyProjection(
              region: regionWithExplorerMarker(
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
          final owGame = gameExplorerOldToNew(sourceTile: owSource);
          final nwMarker = projectDraft(
            region: baseRegion('newWorld'),
            game: owGame,
            orders: prospectOrder(nwTarget),
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
          final game = gameExplorerOldToNew(sourceTile: sourceTile);
          final oldRegion = regionWithExplorerMarker('oldWorld', sourceTile);
          final newRegion = baseRegion('newWorld');
          final ordersDraft = prospectOrder(targetTile);

          final projectedNw = projectDraft(
            region: newRegion,
            game: game,
            orders: ordersDraft,
          );
          expect(projectedNw.civilianTileMarkers.single.tileKey, targetTile);
          expect(
            projectedNw.civilianTileMarkers.single.tileKey,
            isNot(startsWith('oldWorld|')),
          );

          expectEmptyProjection(
            region: newRegion,
            game: game,
            orders: const ct_models.Orders(),
          );
          expectSingleProjectedTile(
            region: oldRegion,
            game: game,
            orders: const ct_models.Orders(),
            tileKey: sourceTile,
          );

          final retargetRegion = baseRegion(
            'newWorld',
            cells: const [
              CellViewData(x: 0, y: 0, regionCellId: 'pB', isSea: false),
              CellViewData(x: 1, y: 0, regionCellId: 'pA', isSea: false),
            ],
          );
          expectSingleProjectedTile(
            region: retargetRegion,
            game: game,
            orders: prospectOrder(targetA),
            tileKey: targetA,
          );
          final markerB = projectDraft(
            region: retargetRegion,
            game: game,
            orders: prospectOrder(targetB),
          ).civilianTileMarkers.single;
          expect(markerB.tileKey, targetB);
          expect(markerB.localProvinceId, 'pB');

          final stackGame = humanGame(
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
          final stackRegion = baseRegion(
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
          final stackOrders = prospectOrder(targetTile);
          final stacked = projectDraft(
            region: stackRegion,
            game: stackGame,
            orders: stackOrders,
          ).civilianTileMarkers.single;
          expect(stacked.tileKey, targetTile);
          expect(stacked.unitIds, containsAll([explorerId, merchantId]));
          expectEmptyProjection(
            region: regionWithExplorerMarker('oldWorld', sourceTile),
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
          GameMapAreaStateLogic.selectionAfterWorkAssignment(
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
      expect(GameMapAreaStateLogic.regionIndexFromWorldRegionId('newWorld'), 1);
      expect(GameMapAreaStateLogic.regionIndexFromWorldRegionId('oldWorld'), 0);
      const tile = 'oldWorld|p1|10|20';
      for (final case_ in <({String tileKey, String workTarget})>[
        (tileKey: tile, workTarget: kWorkTargetExplore),
        (tileKey: tile, workTarget: 'move'),
        (tileKey: 'oldWorld|p1', workTarget: kWorkTargetExplore),
      ]) {
        expect(
          GameMapAreaStateLogic.translateWorkTargetTileKey(
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
        GameMapAreaStateLogic.addHumanWorkOrder(
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
        GameMapAreaStateLogic.addHumanWorkOrder(
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
}
