import 'package:colonizethis_app/features/game/flame/game_map_area_state_logic.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        kWorkTargetBuildImprovement,
        kWorkTargetBuildFort,
        kWorkTargetBuildPort,
        kWorkTargetBuildRail,
        kWorkTargetBuildRoad,
        kWorkTargetCounterSpy,
        kWorkTargetExplore,
        kWorkTargetProspect,
        kWorkTargetPurchaseLand,
        kWorkTargetUpgradeTown;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('GameMapAreaStateLogic cache stale-tile filtering', () {
    test(
      'cache-first target set includes explore, spy, merchant, prospect, and '
      'worker targets',
      () {
        expect(
          GameMapAreaStateLogic.kCacheFirstWorkTargets,
          containsAll(<String>{
            kWorkTargetExplore,
            kWorkTargetCounterSpy,
            kWorkTargetPurchaseLand,
            kWorkTargetProspect,
            kWorkTargetBuildImprovement,
            kWorkTargetUpgradeTown,
            kWorkTargetBuildRoad,
            kWorkTargetBuildPort,
            kWorkTargetBuildFort,
            kWorkTargetBuildRail,
          }),
        );
      },
    );

    test(
      'runtime stale-tile filter subtracts pending conflicts for cache-first targets',
      () {
        const humanPlayerId = 'gp1';
        const selectedUnitId = 'u_selected';
        final game = ct_models.Game(
          id: 'g_filter_pending',
          worldState: const ct_models.WorldState(
            turnState: ct_models.TurnState(
              phase: ct_models.TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: ct_models.RegionData(provinces: [], units: []),
            newWorld: ct_models.RegionData(provinces: [], units: []),
          ),
          players: const [
            ct_models.Player(
              id: humanPlayerId,
              displayName: 'Human',
              isHuman: true,
            ),
          ],
        );

        for (final workTarget in <String>[
          kWorkTargetExplore,
          kWorkTargetCounterSpy,
          kWorkTargetPurchaseLand,
          kWorkTargetProspect,
          kWorkTargetBuildImprovement,
          kWorkTargetUpgradeTown,
          kWorkTargetBuildRoad,
          kWorkTargetBuildPort,
          kWorkTargetBuildFort,
          kWorkTargetBuildRail,
        ]) {
          final filtered =
              GameMapAreaStateLogic.filterCacheSelectionForRuntimeStaleTileConflicts(
                cachedTileKeys: const {'oldWorld|p1|0|0', 'oldWorld|p1|1|0'},
                game: game,
                currentOrders: ct_models.Orders(
                  workOrdersByPlayerId: {
                    humanPlayerId: const [
                      ct_models.WorkOrder(
                        unitId: 'u_other',
                        target: kWorkTargetBuildRoad,
                        targetTileKey: 'oldWorld|p1|1|0',
                      ),
                    ],
                  },
                ),
                playerId: humanPlayerId,
                selectedUnitId: selectedUnitId,
                workTarget: workTarget,
              );

          expect(
            filtered,
            const {'oldWorld|p1|0|0'},
            reason: 'Expected stale conflict subtraction for $workTarget',
          );
        }
      },
    );

    test(
      'runtime stale-tile filter subtracts in-progress build_rail conflicts',
      () {
        const humanPlayerId = 'gp1';
        final game = ct_models.Game(
          id: 'g_filter_in_progress',
          worldState: ct_models.WorldState(
            turnState: ct_models.TurnState(
              phase: ct_models.TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: ct_models.RegionData(
              provinces: [],
              units: [
                ct_models.Unit(
                  id: 'u_other',
                  type: ct_models.kUnitTypeRailBuilder,
                  ownerId: humanPlayerId,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: 'oldWorld|p1|0|0',
                  status: ct_models.UnitStatus.working,
                  currentWork: ct_models.CurrentWork(
                    workTarget: kWorkTargetBuildRail,
                    tileKey: 'oldWorld|p1|1|0',
                    totalTurns: 1,
                    remainingTurns: 1,
                  ),
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
        );

        final filtered =
            GameMapAreaStateLogic.filterCacheSelectionForRuntimeStaleTileConflicts(
              cachedTileKeys: const {'oldWorld|p1|0|0', 'oldWorld|p1|1|0'},
              game: game,
              currentOrders: const ct_models.Orders(),
              playerId: humanPlayerId,
              selectedUnitId: 'u_selected',
              workTarget: kWorkTargetBuildRail,
            );
        expect(filtered, const {'oldWorld|p1|0|0'});
      },
    );
  });
}
