import 'dart:math' as math;

/// Selects a weighted index from [weights] using [seed].
///
/// Returns `null` when no positive total weight exists.
int? pickWeightedIndex(List<num> weights, int seed, {bool useIntRoll = false}) {
  if (weights.isEmpty) return null;
  final total = weights.fold<double>(0, (sum, value) => sum + value.toDouble());
  if (total <= 0) return null;
  final rng = math.Random(seed);
  var roll = useIntRoll
      ? rng.nextInt(total.toInt()).toDouble()
      : rng.nextDouble() * total;
  for (var i = 0; i < weights.length; i++) {
    final weight = weights[i].toDouble();
    if (weight <= 0) continue;
    if (useIntRoll) {
      roll -= weight;
      if (roll < 0) return i;
      continue;
    }
    if (roll < weight) return i;
    roll -= weight;
  }
  return weights.length - 1;
}
