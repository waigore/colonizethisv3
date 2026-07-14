// Shared apply path for diplomacy dialogue resume closures. Refs #4018.
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show TurnResolutionResult;
import 'package:colonizethis_models/colonizethis_models.dart' show Orders;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/game_service/game_service.dart';
import '../../../../core/services/turn_resolution/turn_resolution_result_applier.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';

/// Loads [GameService] + draft [Orders], runs [resume], applies the result.
void applyDiplomacyResumeDecisions({
  required WidgetRef ref,
  required TurnResolutionResult Function(GameService service, Orders orders)
      resume,
}) {
  final service = ref.read(gameServiceProvider);
  final orders = ref.read(currentOrdersProvider);
  final result = resume(service, orders);
  ref.read(turnResolutionResultApplierProvider).apply(result);
}
