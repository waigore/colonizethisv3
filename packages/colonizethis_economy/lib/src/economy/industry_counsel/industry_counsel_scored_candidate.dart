/// Score-ranked candidates for industry counsel sorting.
library;

class IndustryCounselScoredCandidate<T> {
  const IndustryCounselScoredCandidate({required this.item, required this.score});

  final T item;
  final double score;
}

List<T> sortIndustryCounselByScore<T>(
  Iterable<IndustryCounselScoredCandidate<T>> scored,
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
