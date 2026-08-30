import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_snapshot.dart';
import 'package:colonizethis_orders/src/orders/engineer_work_scoring.dart';

import 'full_ai_civilian_work_selection.dart' show FullAiCivilianWorkIdle;
import 'full_ai_civilian_work_selection_shared.dart';

// Engineer (`build_road` / `build_port` / `build_fort`) candidate scoring / row
// selection and the Engineer path appender. Scoring lives in colonizethis_orders
// (`engineer_work_scoring.dart`) so Development Counsel stays AI-aligned
// without importing colonizethis_ai (Refs #4332 / SPEC/ai/civilian-work-planner.md).

void appendEngineerPathResult({
  required Unit? unit,
  required List<WorkOrder> w,
  required Game game,
  required String playerId,
  required List<WorkOrder> workOrders,
  required List<FullAiCivilianWorkIdle> idleEvents,
  ConnectivityDevSnapshot? connectivityDev,
}) {
  final chosen =
      bestEngineerWorkOrder(
        w,
        game,
        playerId: playerId,
        connectivityDev: connectivityDev,
      ) ??
      pickLexicographic(w);
  if (chosen != null) {
    workOrders.add(chosen);
    return;
  }
  if (unit == null) return;
  idleEvents.add(
    FullAiCivilianWorkIdle(
      unitId: unit.id,
      unitType: unit.type,
      reason: 'no_suggestions',
    ),
  );
}
