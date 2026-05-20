import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_suggestion_context.dart';

/// Max engine validation probes per unit per work target in one pass (Refs #2507).
const int kMaxWorkProbeAttemptsPerUnitPerTarget = 4;

/// Max partially-revealed provinces probed per Explorer explore pass (Refs #2507).
const int kMaxExploreProvinceProbesPerUnit = 4;

/// Max total work validation probes per [suggestWorkOrders] player pass (Refs #2507).
const int kMaxWorkProbeAttemptsPerPlayerPass = 64;

/// Shared decrementing budget for one [suggestWorkOrders] invocation.
class WorkSuggestionProbeBudget {
  WorkSuggestionProbeBudget([int? max])
    : remaining = max ?? kMaxWorkProbeAttemptsPerPlayerPass;

  int remaining;

  bool consume() {
    if (remaining <= 0) return false;
    remaining--;
    return true;
  }
}

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
    WorkSuggestionProbeBudget? probeBudget,
    String engineRejectedReason = 'engine_rejected',
    bool includeAllAccepted = false,

    /// When the provider yields **no** candidates ([sawCandidate] stays false),
    /// call this for the `excluded` log reason instead of a fixed
    /// [noCandidateReason] — for example after a [sync*] generator updated a
    /// mutable `lastReason` while probing provinces (Refs #2391 AC8).
    String Function()? resolveNoCandidateReason,

    /// Optional override for the per-call probe cap; defaults to
    /// [kMaxWorkProbeAttemptsPerUnitPerTarget]. Multi-province sweeps that
    /// pre-validate candidates inside [candidatesProvider] (e.g. Explorer
    /// `prospect`) may raise the cap to honor per-province × per-tile bounds
    /// from `SPEC/program/order-suggestions.md` § Throughput bounds.
    int? maxProbeAttempts,
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

    final probeCap = maxProbeAttempts ?? kMaxWorkProbeAttemptsPerUnitPerTarget;
    var sawCandidate = false;
    var acceptedCount = 0;
    var firstIncludedTile = '-';
    var probeAttempts = 0;
    for (final candidate in candidatesProvider()) {
      probeAttempts++;
      if (probeAttempts > probeCap) {
        break;
      }
      if (probeBudget != null && !probeBudget.consume()) {
        break;
      }
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
      final reason = sawCandidate
          ? engineRejectedReason
          : (resolveNoCandidateReason?.call() ?? noCandidateReason);
      logWorkOrderSuggestion(
        unitId: unit.id,
        unitType: unitType,
        unitRegionId: unitRegionId,
        atProvinceId: atProvinceId,
        workTarget: workTarget,
        outcome: 'excluded',
        reason: reason,
      );
    }
  }
}
