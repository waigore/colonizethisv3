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
