import '../config/ga_config.dart';

/// Mean stage fitness from successfully scored per-game totals.
///
/// Returns `0.0` when [scores] is empty (all games failed). Refs #3488.
double meanStageFitness(List<double> scores) {
  if (scores.isEmpty) return 0.0;
  return scores.reduce((a, b) => a + b) / scores.length;
}

/// Combines 2-player and 7-GP stage fitness per SPEC/program/ga-runner.md.
///
/// When [sevenGpSkipped] is true (2-player stage had zero successfully scored
/// games), returns [twoPlayerFitness] only — typically `0.0`.
double combineStageFitness({
  required double twoPlayerFitness,
  required double? sevenGpFitness,
  required StageFitnessWeights weights,
  required bool sevenGpSkipped,
}) {
  if (sevenGpSkipped || sevenGpFitness == null) {
    return twoPlayerFitness;
  }
  final w2p = weights.twoPlayer;
  final w7gp = weights.sevenGp;
  return (w2p * twoPlayerFitness + w7gp * sevenGpFitness) / (w2p + w7gp);
}
