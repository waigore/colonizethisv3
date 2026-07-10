// Scenario run tear-offs for order_suggestion_move_excludes_unit_with_draft_work (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_move_excludes_unit_with_draft_work_fixtures.dart';

void osmeudwRunNoMoveWhenDraftWorkExists() {
  final game = moveExcludesDraftWorkGame();
  final view = buildPlayerView(
    game,
    moveExcludesDraftWorkTopology,
    moveExcludesDraftWorkPlayerId,
  );
  final suggestions = suggestMoveOrders(
    view,
    game,
    moveExcludesDraftWorkTopology,
    moveExcludesDraftWorkOrders(),
  );
  expect(
    suggestions.where((m) => m.unitId == 'u1'),
    isEmpty,
    reason: 'civilian_move_xor_work_order: no move for same unit as work',
  );
}
