import 'dart:math' as math;

int? pickWeightedIndex(List<num> weights, int seed, {bool useIntRoll = false}) {
  if (weights.isEmpty) return null;
  final normalized = weights
      .map((weight) => weight < 0 ? 0.0 : weight.toDouble())
      .toList();
  final total = normalized.fold<double>(0, (sum, value) => sum + value);
  if (total <= 0) return null;

  if (useIntRoll) {
    final intWeights = normalized.map((weight) => weight.round()).toList();
    final intTotal = intWeights.fold<int>(0, (a, b) => a + b);
    if (intTotal <= 0) return null;
    var remaining = math.Random(seed).nextInt(intTotal);
    for (var idx = 0; idx < intWeights.length; idx++) {
      remaining -= intWeights[idx];
      if (remaining < 0) return idx;
    }
    return intWeights.length - 1;
  }

  var remaining = math.Random(seed).nextDouble() * total;
  for (var idx = 0; idx < normalized.length; idx++) {
    if (remaining < normalized[idx]) return idx;
    remaining -= normalized[idx];
  }
  return normalized.length - 1;
}

/// Picks one [candidates] entry by weighted score, using [seed] (Refs #2521 AC6).
///
/// Provide either [score] per candidate or a parallel [scores] list.
T? selectWeightedCandidate<T>({
  required List<T> candidates,
  required int seed,
  num Function(T)? score,
  List<num>? scores,
  bool useIntRoll = false,
}) {
  if (candidates.isEmpty) return null;
  final resolvedScores =
      scores ?? candidates.map(score!).toList(growable: false);
  if (resolvedScores.length != candidates.length) return null;
  final idx = pickWeightedIndex(resolvedScores, seed, useIntRoll: useIntRoll);
  if (idx == null) return null;
  return candidates[idx];
}
