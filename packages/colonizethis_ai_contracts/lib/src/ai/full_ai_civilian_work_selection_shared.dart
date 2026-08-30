// Shared helpers for the Full AI civilian work selection family. Extracted from
// the former `full_ai_civilian_work_selection.dart` `part` cluster so each
// selection module can import a single narrow dependency instead of sharing a
// `part of` namespace (Refs #4084 Slice A). Behaviour-preserving: bodies are
// unchanged from the prior library-private helpers, only the leading `_` was
// dropped so sibling libraries can import them.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

bool civilianWorkCapableType(String type) =>
    isExplorerUnit(type) ||
    isCivilianWorkerUnit(type) ||
    isSpyUnit(type) ||
    isMerchantUnit(type);

int compareWorkOrderLex(WorkOrder a, WorkOrder b) {
  final t = a.target.compareTo(b.target);
  if (t != 0) return t;
  return a.targetTileKey.compareTo(b.targetTileKey);
}

void sortWorkOrdersLex(List<WorkOrder> list) {
  list.sort(compareWorkOrderLex);
}

WorkOrder? pickLexicographic(List<WorkOrder> w) {
  if (w.isEmpty) return null;
  final copy = List<WorkOrder>.from(w)..sort(compareWorkOrderLex);
  return copy.first;
}

/// Stable secondary ordering for equally-scored candidates that share a work
/// target: province id first, then full tile key (Refs #3794 AC16, #4368 AC1).
int compareWorkOrderProvinceThenTile(WorkOrder a, WorkOrder b) {
  final pa = Unit.provinceIdFromTileKey(a.targetTileKey) ?? '';
  final pb = Unit.provinceIdFromTileKey(b.targetTileKey) ?? '';
  final p = pa.compareTo(pb);
  if (p != 0) return p;
  return a.targetTileKey.compareTo(b.targetTileKey);
}

/// Picks the highest-scoring [WorkOrder] from [candidates].
///
/// When scores tie, [compareTieBreak] selects the winning row: a negative
/// return means [a] beats [b] (Refs #4368 Slice A).
WorkOrder? bestScoredWorkRow(
  List<WorkOrder> candidates, {
  required int Function(WorkOrder) scoreOf,
  required int Function(WorkOrder a, WorkOrder b) compareTieBreak,
}) {
  if (candidates.isEmpty) return null;
  var best = candidates.first;
  var bestScore = scoreOf(best);
  for (var i = 1; i < candidates.length; i++) {
    final w = candidates[i];
    final s = scoreOf(w);
    if (s > bestScore) {
      bestScore = s;
      best = w;
      continue;
    }
    if (s == bestScore && compareTieBreak(w, best) < 0) {
      best = w;
    }
  }
  return best;
}
