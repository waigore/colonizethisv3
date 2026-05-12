import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_suggestion_context.dart';

/// Emits one structured line per work-order suggestion decision (Refs #2277,
/// SPEC/program/order-suggestions.md suggestion observability).
void logWorkOrderSuggestion({
  required String unitId,
  required String unitType,
  required String unitRegionId,
  required String atProvinceId,
  required String workTarget,
  required String outcome,
  String reason = '-',
  String tile = '-',

  /// When [outcome] is `included` and greater than 1 row is accepted in one
  /// pass, emit a single summary line with `includedCount=` (Refs #2277,
  /// SPEC/program/order-suggestions.md suggestion observability).
  int? includedRowCount,
}) {
  final multiIncluded =
      outcome == 'included' && includedRowCount != null && includedRowCount > 1;
  final tileField = multiIncluded ? '-' : tile;
  final countSuffix = multiIncluded ? ' includedCount=$includedRowCount' : '';
  orderSuggestionLog.d(
    'suggest_work unitId=$unitId unitType=$unitType region=$unitRegionId '
    'at=$atProvinceId target=$workTarget outcome=$outcome reason=$reason '
    'tile=$tileField$countSuffix',
  );
}

typedef WorkSuggestionCandidatesProvider = Iterable<WorkOrder> Function();
typedef WorkSuggestionCandidateAcceptor = bool Function(WorkOrder candidate);

/// Shared work-order suggestion pipeline used by explorer, worker, spy, and
/// merchant suggestion paths (Refs #2391 AC8).
class WorkSuggestionPipeline {
  WorkSuggestionPipeline._();

  static void run({
    required Unit unit,
    required String unitType,
    required String unitRegionId,
    required String atProvinceId,
    required String workTarget,
    required Map<String, Set<String>> existingTargetsByUnit,
    required List<WorkOrder> suggestions,
    required WorkSuggestionCandidatesProvider candidatesProvider,
    required WorkSuggestionCandidateAcceptor candidateAcceptor,
    required String noCandidateReason,
    String engineRejectedReason = 'engine_rejected',
    bool includeAllAccepted = false,
  }) {
    final existing = existingTargetsByUnit[unit.id];
    if (existing != null && existing.contains(workTarget)) {
      logWorkOrderSuggestion(
        unitId: unit.id,
        unitType: unitType,
        unitRegionId: unitRegionId,
        atProvinceId: atProvinceId,
        workTarget: workTarget,
        outcome: 'excluded',
        reason: 'duplicate_pending',
      );
      return;
    }

    var sawCandidate = false;
    var acceptedCount = 0;
    var firstIncludedTile = '-';
    for (final candidate in candidatesProvider()) {
      sawCandidate = true;
      if (!candidateAcceptor(candidate)) continue;
      acceptedCount++;
      suggestions.add(candidate);
      existingTargetsByUnit
          .putIfAbsent(unit.id, () => <String>{})
          .add(workTarget);
      if (acceptedCount == 1) {
        firstIncludedTile = candidate.targetTileKey;
      }
      if (!includeAllAccepted) {
        logWorkOrderSuggestion(
          unitId: unit.id,
          unitType: unitType,
          unitRegionId: unitRegionId,
          atProvinceId: atProvinceId,
          workTarget: workTarget,
          outcome: 'included',
          tile: candidate.targetTileKey,
        );
        return;
      }
    }

    if (acceptedCount > 0) {
      logWorkOrderSuggestion(
        unitId: unit.id,
        unitType: unitType,
        unitRegionId: unitRegionId,
        atProvinceId: atProvinceId,
        workTarget: workTarget,
        outcome: 'included',
        tile: firstIncludedTile,
        includedRowCount: acceptedCount,
      );
    } else {
      logWorkOrderSuggestion(
        unitId: unit.id,
        unitType: unitType,
        unitRegionId: unitRegionId,
        atProvinceId: atProvinceId,
        workTarget: workTarget,
        outcome: 'excluded',
        reason: sawCandidate ? engineRejectedReason : noCandidateReason,
      );
    }
  }
}
