// Concern split under repo.app_test_file_size (Refs #4013, #4352):
// civilian draft projection (same-region).

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'game_map_area_state_logic_test_support.dart';

void main() {
  suppressLogsForTests();

  const humanPlayerId = kStateLogicHumanPlayerId;

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
  });
}
