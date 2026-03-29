import 'worker_pool.dart';

/// Workers that are **idle** for labour this turn after Consumption: food-fed,
/// and for trained tiers, assigned one unit of tier luxury. On-strike workers
/// are not counted here. SPEC/game/workers-and-population.md.
class WorkerIdleCounts {
  const WorkerIdleCounts({
    this.peasants = 0,
    this.apprentices = 0,
    this.journeymen = 0,
    this.masters = 0,
  }) : assert(
          peasants >= 0 &&
              apprentices >= 0 &&
              journeymen >= 0 &&
              masters >= 0,
          'Idle counts must be non-negative',
        );

  /// No idle workers (all on strike or empty pool).
  static const zero = WorkerIdleCounts();

  final int peasants;
  final int apprentices;
  final int journeymen;
  final int masters;

  /// Labour contribution from idle workers only (same multipliers as [WorkerPool]).
  int get effectiveLabour =>
      peasants * WorkerPool.labourPerPeasantTurn +
      apprentices * WorkerPool.labourPerApprenticeTurn +
      journeymen * WorkerPool.labourPerJourneymanTurn +
      masters * WorkerPool.labourPerMasterTurn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerIdleCounts &&
          peasants == other.peasants &&
          apprentices == other.apprentices &&
          journeymen == other.journeymen &&
          masters == other.masters;

  @override
  int get hashCode => Object.hash(peasants, apprentices, journeymen, masters);
}
