/// Turn-to-calendar-year mapping. SPEC/game/turn-time-mapping.
///
/// Maps turn number to calendar year. Configurable per game (fixed at creation).
/// Default: GDD 01 / Imperialism II (1500 start, 2 years/turn until 1700, 1 year/turn after).
class TurnTimeMapping {
  const TurnTimeMapping({
    required this.startYear,
    required this.cutoffYear,
    required this.yearsPerTurnBeforeCutoff,
    required this.yearsPerTurnAfterCutoff,
  });

  final int startYear;
  final int cutoffYear;
  final int yearsPerTurnBeforeCutoff;
  final int yearsPerTurnAfterCutoff;

  /// Normative campaign stop: calendar year at the **start** of the last playable
  /// full turn for default GDD pacing. SPEC/game/turn-time-mapping.md § Campaign calendar cap.
  static const int campaignCalendarStopStartYear = 1800;

  /// Calendar year at the start of [turn]. SPEC/game/turn-time-mapping.md.
  /// Turn 1 → startYear; after cutoff, 1 year per turn.
  int yearAtTurn(int turn) {
    final turnsBeforeCutoff =
        (cutoffYear - startYear) ~/ yearsPerTurnBeforeCutoff;
    if (turn <= turnsBeforeCutoff) {
      return startYear + (turn - 1) * yearsPerTurnBeforeCutoff;
    }
    return cutoffYear +
        (turn - 1 - turnsBeforeCutoff) * yearsPerTurnAfterCutoff;
  }

  /// Turn number ≥ 1 whose [yearAtTurn] equals [year], or `null` when no turn starts on that year
  /// (gaps between segment pacing) or [year] is before [startYear].
  int? turnNumberForStartCalendarYear(int year) {
    if (year < startYear) return null;
    final turnsBeforeCutoff =
        (cutoffYear - startYear) ~/ yearsPerTurnBeforeCutoff;
    final diff = year - startYear;
    if (diff % yearsPerTurnBeforeCutoff == 0) {
      final turn = 1 + diff ~/ yearsPerTurnBeforeCutoff;
      if (turn >= 1 &&
          turn <= turnsBeforeCutoff &&
          yearAtTurn(turn) == year) {
        return turn;
      }
    }
    final diff2 = year - cutoffYear;
    if (diff2 < 0) return null;
    if (diff2 % yearsPerTurnAfterCutoff != 0) return null;
    final turn = turnsBeforeCutoff + 1 + diff2 ~/ yearsPerTurnAfterCutoff;
    if (turn > turnsBeforeCutoff && yearAtTurn(turn) == year) {
      return turn;
    }
    return null;
  }

  /// GDD 01 / Imperialism II default: 1500 start, 2 years/turn until 1700, 1 year/turn after.
  static const TurnTimeMapping gdd01 = TurnTimeMapping(
    startYear: 1500,
    cutoffYear: 1700,
    yearsPerTurnBeforeCutoff: 2,
    yearsPerTurnAfterCutoff: 1,
  );

  Map<String, dynamic> toJson() => {
        'startYear': startYear,
        'cutoffYear': cutoffYear,
        'yearsPerTurnBeforeCutoff': yearsPerTurnBeforeCutoff,
        'yearsPerTurnAfterCutoff': yearsPerTurnAfterCutoff,
      };

  static TurnTimeMapping fromJson(Map<String, dynamic> json) {
    return TurnTimeMapping(
      startYear: json['startYear'] as int,
      cutoffYear: json['cutoffYear'] as int,
      yearsPerTurnBeforeCutoff: json['yearsPerTurnBeforeCutoff'] as int,
      yearsPerTurnAfterCutoff: json['yearsPerTurnAfterCutoff'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TurnTimeMapping &&
          runtimeType == other.runtimeType &&
          startYear == other.startYear &&
          cutoffYear == other.cutoffYear &&
          yearsPerTurnBeforeCutoff == other.yearsPerTurnBeforeCutoff &&
          yearsPerTurnAfterCutoff == other.yearsPerTurnAfterCutoff;

  @override
  int get hashCode =>
      Object.hash(startYear, cutoffYear, yearsPerTurnBeforeCutoff, yearsPerTurnAfterCutoff);
}
