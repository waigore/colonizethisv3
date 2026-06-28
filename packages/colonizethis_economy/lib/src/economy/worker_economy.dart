import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_consumption.dart';

/// Worker economy primitives (labour, food, and luxuries).
/// SPEC/program/economy-models.md, SPEC/game/workers-and-population.md.
///
/// Public for use by AI economy planner and production/consumption pipelines.

/// Effective labour from post-consumption [idle] counts only.
int effectiveLabourFromIdleCounts(WorkerIdleCounts idle) =>
    idle.effectiveLabour;

/// Preview effective labour if [resolveConsumption] ran with the same inputs
/// (land military → navy → workers, worker food priority Masters→Peasants,
/// luxury for food-fed trained).
int effectiveLabourForWorkers({
  required WorkerPool workers,
  required Stockpile stockpile,
  int militaryUnits = 0,
  Map<String, int> regimentCountsById = const {},
  Map<String, int> shipCountsById = const {},
}) {
  final idle = previewWorkerIdleLabour(
    stockpile: stockpile,
    workers: workers,
    militaryUnits: militaryUnits,
    regimentCountsById: regimentCountsById,
    shipCountsById: shipCountsById,
  );
  return effectiveLabourFromIdleCounts(idle);
}
