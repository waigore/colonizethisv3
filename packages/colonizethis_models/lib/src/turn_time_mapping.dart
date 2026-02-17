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
