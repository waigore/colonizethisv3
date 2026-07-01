/// Generic score-ranked candidate used by naval and recipe planners (Refs #3822).
class ScoredCandidate<T> {
  const ScoredCandidate({required this.item, required this.score});

  final T item;
  final num score;
}

/// Sorts [scored] by descending [ScoredCandidate.score], then by [compareTieBreak].
List<T> sortByScore<T>(
  Iterable<ScoredCandidate<T>> scored,
  int Function(T a, T b) compareTieBreak,
) {
  final list = scored.toList();
  list.sort((a, b) {
    final scoreCmp = b.score.compareTo(a.score);
    if (scoreCmp != 0) return scoreCmp;
    return compareTieBreak(a.item, b.item);
  });
  return list.map((e) => e.item).toList();
}
