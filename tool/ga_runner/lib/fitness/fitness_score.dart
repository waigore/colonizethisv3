/// Per-player fitness result produced by the GA fitness function.
///
/// `economic`, `military`, and `diplomatic` are the equal-weight, game-relative
/// normalized category scores in `[0, 1]`. `total` is the final fitness:
/// `(0.4·economic + 0.4·military + 0.2·diplomatic) × winMultiplier +
/// shapingPenalties`. SPEC/program/ga-fitness.md. Refs #3438.
class FitnessScore {
  const FitnessScore({
    required this.economic,
    required this.military,
    required this.diplomatic,
    required this.total,
  });

  /// Normalized economic category score, `[0, 1]`.
  final double economic;

  /// Normalized military category score, `[0, 1]`.
  final double military;

  /// Normalized diplomatic category score, `[0, 1]`.
  final double diplomatic;

  /// Final fitness after the win multiplier and additive shaping penalties.
  final double total;

  @override
  String toString() =>
      'FitnessScore(economic: $economic, military: $military, '
      'diplomatic: $diplomatic, total: $total)';
}
