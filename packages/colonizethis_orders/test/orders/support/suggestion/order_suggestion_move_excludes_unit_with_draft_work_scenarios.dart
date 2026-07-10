// Table-driven draft-work move exclusion scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_move_excludes_unit_with_draft_work_fixtures.dart';
// dart format off

void osmeudwRunNoMoveWhenDraftWorkExists() {final game = moveExcludesDraftWorkGame(); final view = buildPlayerView(game,moveExcludesDraftWorkTopology,moveExcludesDraftWorkPlayerId,); final suggestions = suggestMoveOrders(view,game,moveExcludesDraftWorkTopology,moveExcludesDraftWorkOrders(),); expect(suggestions.where((m) => m.unitId == 'u1'),isEmpty,reason: 'civilian_move_xor_work_order: no move for same unit as work',);}

List<RunnableScenario>
orderSuggestionMoveExcludesUnitWithDraftWorkScenarios() => [
  rs('suggestMoveOrders emits no MoveOrder for a unit that already has a draft WorkOrder', osmeudwRunNoMoveWhenDraftWorkExists),
];
