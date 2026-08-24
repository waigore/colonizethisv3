// Selection helpers / addHumanWorkOrder (Refs #4642 Slice B).

// Concern split under repo.app_test_file_size (Refs #4013, #4352):
// civilian draft projection, selection helpers, addHumanWorkOrder.

import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement, kWorkTargetBuildRoad, kWorkTargetExplore;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'game_map_area_state_logic_test_support.dart';

void main() {
  suppressLogsForTests();

  const humanPlayerId = kStateLogicHumanPlayerId;

  group('GameMapAreaStateLogic helpers', () {
    test('selection / province-id / region-index / translate helpers', () {
      for (final case_ in <({String selected, String assigned, String? out})>[
        (selected: 'oldWorld|p1|0|0', assigned: 'oldWorld|p1|1|0', out: null),
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
      expect(
        GameMapAreaStateLogicShell.regionIndexFromWorldRegionId('newWorld'),
        1,
      );
      expect(
        GameMapAreaStateLogicShell.regionIndexFromWorldRegionId('oldWorld'),
        0,
      );
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
