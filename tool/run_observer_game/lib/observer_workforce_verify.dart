import 'dart:convert';
import 'dart:io';

import 'observer_conquest_verify.dart';

/// Workforce sustain verifier (Refs #2692 S10a).
///
/// Reads per-player `workerPool` from a turn-100 `ObserverSnapshot` v3 and
/// checks the provisional 15-regiment workforce sustain metric for each
/// canonical Great Power (`gp1`–`gp6`):
///
/// 1. **Peasant buffer** — `peasants >= kObserverWorkforceMinPeasants`
///    (default `15`, sufficient for one full 15-regiment build cycle
///    plus reservation headroom per `SPEC/game/workers-and-population.md`
///    § Peasant reservation).
/// 2. **Trained-tier buffer** — `apprentices + journeymen + masters >=
///    kObserverWorkforceMinTrained` (default `8`, effective-labour buffer
///    for production chains per Requirement §21 of issue #2692).
///
/// The food/luxury sustain checks listed in Requirement §21 are deferred
/// to a follow-up slice: `ObserverSnapshot` v3 exposes worker counts only
/// — `stockpile`, `food production`, and per-tier luxury production
/// summaries are not in scope here. `kObserverWorkforceFoodLuxuryDeferred`
/// documents the deferral as a value developers can grep for when the
/// next slice lands.
const int kObserverWorkforceCanonicalTurn = 100;

/// Minimum peasants per Great Power on the turn-100 snapshot.
const int kObserverWorkforceMinPeasants = 15;

/// Minimum combined trained-tier workers (apprentices + journeymen +
/// masters) per Great Power on the turn-100 snapshot.
const int kObserverWorkforceMinTrained = 8;

/// Deferral marker: food and luxury sustain checks (§21 bullets 3 and 4)
/// are NOT enforced by this verifier yet. The marker exists so future
/// work can surface every gated check in one search.
const bool kObserverWorkforceFoodLuxuryDeferred = true;

/// Per-Great-Power worker pool counts parsed from an
/// `ObserverSnapshot` v3 player rollup.
class WorkerPoolCounts {
  const WorkerPoolCounts({
    required this.peasants,
    required this.apprentices,
    required this.journeymen,
    required this.masters,
  });

  final int peasants;
  final int apprentices;
  final int journeymen;
  final int masters;

  int get trained => apprentices + journeymen + masters;

  static const WorkerPoolCounts zero = WorkerPoolCounts(
    peasants: 0,
    apprentices: 0,
    journeymen: 0,
    masters: 0,
  );
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// Returns the `WorkerPoolCounts` for [playerId] in [snapshotJson], or
/// [WorkerPoolCounts.zero] when the player row is missing or has no
/// `workerPool` block (older v2 snapshots).
WorkerPoolCounts workerPoolCountsForPlayer(
  Map<String, Object?> snapshotJson,
  String playerId,
) {
  final players = snapshotJson['players'];
  if (players is! List<Object?>) {
    return WorkerPoolCounts.zero;
  }
  for (final row in players) {
    if (row is! Map<String, Object?>) continue;
    if (row['playerId']?.toString() != playerId) continue;
    final pool = row['workerPool'];
    if (pool is! Map<String, Object?>) {
      return WorkerPoolCounts.zero;
    }
    return WorkerPoolCounts(
      peasants: _readInt(pool['peasants']),
      apprentices: _readInt(pool['apprentices']),
      journeymen: _readInt(pool['journeymen']),
      masters: _readInt(pool['masters']),
    );
  }
  return WorkerPoolCounts.zero;
}

/// Returns human-readable failure lines; empty when every Great Power
/// in [kObserverGreatPowerIds] meets both thresholds.
List<String> verifyPerGpWorkforceSustain({
  required Map<String, Object?> turnEndSnapshot,
  int minPeasants = kObserverWorkforceMinPeasants,
  int minTrained = kObserverWorkforceMinTrained,
}) {
  final failures = <String>[];
  for (final gpId in kObserverGreatPowerIds) {
    final counts = workerPoolCountsForPlayer(turnEndSnapshot, gpId);
    if (counts.peasants < minPeasants) {
      failures.add(
        '$gpId peasants=${counts.peasants} (need >= $minPeasants)',
      );
    }
    if (counts.trained < minTrained) {
      failures.add(
        '$gpId trained=${counts.trained} '
        '(apprentices=${counts.apprentices} journeymen=${counts.journeymen} '
        'masters=${counts.masters}; need apprentices+journeymen+masters '
        '>= $minTrained)',
      );
    }
  }
  return failures;
}

Map<String, Object?> _loadSnapshot(String path) {
  final text = File(path).readAsStringSync();
  final decoded = jsonDecode(text);
  if (decoded is! Map<String, Object?>) {
    throw FormatException('Observer snapshot root must be a JSON object: $path');
  }
  return decoded;
}

/// Verifies the turn-[endTurn] snapshot under [tracesGameDir] meets the
/// workforce sustain thresholds for every Great Power.
List<String> verifyObserverWorkforceFromTraceDir(
  String tracesGameDir, {
  int endTurn = kObserverWorkforceCanonicalTurn,
  int minPeasants = kObserverWorkforceMinPeasants,
  int minTrained = kObserverWorkforceMinTrained,
}) {
  final endPath = observerTurnSnapshotPath(
    tracesGameDir: tracesGameDir,
    turnNumber: endTurn,
  );
  if (!File(endPath).existsSync()) {
    return ['missing end snapshot: $endPath'];
  }
  return verifyPerGpWorkforceSustain(
    turnEndSnapshot: _loadSnapshot(endPath),
    minPeasants: minPeasants,
    minTrained: minTrained,
  );
}
