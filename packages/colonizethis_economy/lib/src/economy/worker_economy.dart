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
  MilitaryNavyFoodCounts foodCounts = const MilitaryNavyFoodCounts(),
}) {
  final idle = previewWorkerIdleLabour(
    stockpile: stockpile,
    workers: workers,
    foodCounts: foodCounts,
  );
  return effectiveLabourFromIdleCounts(idle);
}
