// Shared apply path for diplomacy dialogue resume closures. Refs #4018.

import 'package:colonizethis_models/colonizethis_models.dart' show Orders;

import '../../../../core/services/game_service/game_service.dart';
import '../../../../core/services/turn_resolution/turn_resolution_result_applier.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart' show TurnResolutionResult;

/// Loads draft [orders], runs [resume] with [service], applies the result.
void applyDiplomacyResumeDecisions({
  required GameService service,
  required Orders orders,
  required TurnResolutionResultApplier applier,
  required TurnResolutionResult Function(GameService service, Orders orders)
      resume,
}) {
  final result = resume(service, orders);
  applier.apply(result);
}
