import '../util/ai_random_utils.dart';

/// Filter → score → weighted pick for planner candidate lists.
///
/// Returns null when [candidates] is empty, [filter] removes all items, scores
/// sum to zero, or [pickWeightedIndex] cannot select.
T? selectWeightedCandidate<T>({
  required List<T> candidates,
  List<T> Function(List<T>)? filter,
  required List<num> Function(List<T>) scorer,
  required int seed,
  bool useIntRoll = false,
}) {
  var working = candidates;
  if (filter != null) {
    working = filter(working);
    if (working.isEmpty) return null;
  }
  if (working.isEmpty) return null;
  final scores = scorer(working);
  final idx = pickWeightedIndex(scores, seed, useIntRoll: useIntRoll);
  if (idx == null) return null;
  return working[idx];
}
