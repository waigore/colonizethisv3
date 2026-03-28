/// Industrial labour pool per player.
/// SPEC/game/workers-and-population.md
/// SPEC/program/economy-models.md
class WorkerPool {
  const WorkerPool({
    this.peasants = 0,
    this.apprentices = 0,
    this.journeymen = 0,
    this.masters = 0,
  }) : assert(
          peasants >= 0 &&
              apprentices >= 0 &&
              journeymen >= 0 &&
              masters >= 0,
          'Worker counts must be non-negative',
        );

  final int peasants;
  final int apprentices;
  final int journeymen;
  final int masters;

  static const empty = WorkerPool();

  /// Labour per trained worker per turn (GDD Worker Tiers table).
  static const int labourPerPeasantTurn = 1;
  static const int labourPerApprenticeTurn = 4;
  static const int labourPerJourneymanTurn = 6;
  static const int labourPerMasterTurn = 8;

  /// Raw labour supply per turn from all tiers (sum of tier × count).
  ///
  /// Does not apply food/luxury strike gating; see [WorkerIdleCounts] and
  /// `effectiveLabourForWorkers` / `resolveProduction` in `colonizethis_logic`.
  int get labourSupplyPerTurn =>
      peasants * labourPerPeasantTurn +
      apprentices * labourPerApprenticeTurn +
      journeymen * labourPerJourneymanTurn +
      masters * labourPerMasterTurn;

  WorkerPool copyWith({
    int? peasants,
    int? apprentices,
    int? journeymen,
    int? masters,
  }) {
    return WorkerPool(
      peasants: peasants ?? this.peasants,
      apprentices: apprentices ?? this.apprentices,
      journeymen: journeymen ?? this.journeymen,
      masters: masters ?? this.masters,
    );
  }

  /// Total headcount across all tiers.
  int get totalWorkers => peasants + apprentices + journeymen + masters;

  Map<String, dynamic> toJson() => {
        'peasants': peasants,
        'apprentices': apprentices,
        'journeymen': journeymen,
        'masters': masters,
      };

  static WorkerPool fromJson(Map<String, dynamic> json) {
    int _read(String key) {
      final value = json[key];
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return WorkerPool(
      peasants: _read('peasants'),
      apprentices: _read('apprentices'),
      journeymen: _read('journeymen'),
      masters: _read('masters'),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerPool &&
          runtimeType == other.runtimeType &&
          peasants == other.peasants &&
          apprentices == other.apprentices &&
          journeymen == other.journeymen &&
          masters == other.masters;

  @override
  int get hashCode => Object.hash(
        peasants,
        apprentices,
        journeymen,
        masters,
      );
}

