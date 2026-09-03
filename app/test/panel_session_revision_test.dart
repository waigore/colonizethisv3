import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/providers/development_panel_projection_provider.dart';
import 'package:colonizethis_app/providers/panel_session_revision.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'panel_fixtures/core.dart';

void main() {
  suppressLogsForTests();
  test(
    'panelWorldRevision matches developmentPanelWorldRevision (Refs #4720 AC2)',
    () {
      final game = buildPanelTestGame(
        players: [panelTestHumanPlayer()],
        tileKeysByRegionAndProvince: {
          'oldWorld': {'p1': ['oldWorld|p1|0|0']},
        },
      );

      expect(panelWorldRevision(game), developmentPanelWorldRevision(game));
    },
  );

  test(
    'panelOrdersRevision matches developmentPanelOrdersRevision (Refs #4720 AC2)',
    () {
      const orders = Orders(
        workOrdersByPlayerId: {
          kPanelTestHumanPlayerId: [
            WorkOrder(
              unitId: 'u1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: 'oldWorld|p1|0|0',
            ),
            WorkOrder(
              unitId: 'u2',
              target: kWorkTargetBuildImprovement,
              targetTileKey: 'oldWorld|p1|1|0',
            ),
          ],
        },
      );

      expect(panelOrdersRevision(orders), developmentPanelOrdersRevision(orders));
    },
  );
}
