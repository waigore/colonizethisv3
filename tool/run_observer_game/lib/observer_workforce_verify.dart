import 'dart:convert';
import 'dart:io';

import 'observer_conquest_verify.dart';

/// Workforce sustain verifier (Refs #2692 S10a + S10b).
///
/// Reads per-player `workerPool`, `luxuryStockpile`, and
/// `lastTurnLuxuryProduction` from a turn-100 `ObserverSnapshot` v4 and
/// checks the 15-regiment workforce sustain metric for each canonical
/// Great Power (`gp1`–`gp6`):
///
/// 1. **Peasant buffer** — `peasants >= kObserverWorkforceMinPeasants`
///    (default `15`, sufficient for one full 15-regiment build cycle
///    plus reservation headroom per `SPEC/game/workers-and-population.md`
///    § Peasant reservation).
/// 2. **Trained-tier buffer** — `apprentices + journeymen + masters >=
///    kObserverWorkforceMinTrained` (default `8`, effective-labour buffer
///    for production chains per Requirement §21 of issue #2692).
/// 3. **Luxury sustain (§21 bullet 4)** — for each trained tier with a
///    non-zero count, the matched luxury commodity's snapshot
///    `luxuryStockpile + lastTurnLuxuryProduction` must be at least the
///    tier count:
///    - apprentices ↔ `refinedSugar`
///    - journeymen ↔ `cigars`
///    - masters ↔ `furHats`
///    Players with a zero count for a tier always pass that tier's
///    luxury check (no requirement when nobody consumes the luxury).
///
/// **Deferred:** Food production sustain (§21 bullet 3, `grain + meat`)
/// remains out of scope — grain and meat are extracted (not recipe
/// outputs) so a per-turn production snapshot needs a different data
/// channel than the production-phase callback. `kObserverWorkforceFoodProductionDeferred`
/// documents the deferral as a value developers can grep for when the
/// next slice lands.
const int kObserverWorkforceCanonicalTurn = 100;

/// Minimum peasants per Great Power on the turn-100 snapshot.
const int kObserverWorkforceMinPeasants = 15;

/// Minimum combined trained-tier workers (apprentices + journeymen +
/// masters) per Great Power on the turn-100 snapshot.
const int kObserverWorkforceMinTrained = 8;

/// Deferral marker: food production sustain (§21 bullet 3) is NOT
/// enforced by this verifier yet. Luxury sustain (§21 bullet 4) is
/// enforced from `ObserverSnapshot` v4 onward — see
/// `verifyPerGpLuxurySustain`. The flag exists so future work can
/// surface every still-gated check in one search.
const bool kObserverWorkforceFoodProductionDeferred = true;

/// Back-compat alias for the original deferral flag. The narrower
/// `kObserverWorkforceFoodProductionDeferred` is the canonical name
/// going forward; luxury sustain is no longer deferred.
@Deprecated(
  'Use kObserverWorkforceFoodProductionDeferred; luxury sustain is now '
  'enforced by verifyPerGpLuxurySustain (Refs #2692 S10b).',
)
const bool kObserverWorkforceFoodLuxuryDeferred =
    kObserverWorkforceFoodProductionDeferred;

/// Luxury commodity required for the apprentice tier (§21 bullet 4).
const String kObserverWorkforceApprenticeLuxuryCommodityId = 'refinedSugar';

/// Luxury commodity required for the journeyman tier (§21 bullet 4).
const String kObserverWorkforceJourneymanLuxuryCommodityId = 'cigars';

/// Luxury commodity required for the master tier (§21 bullet 4).
const String kObserverWorkforceMasterLuxuryCommodityId = 'furHats';

/// Ordered tier → matched luxury commodity for the §21 bullet 4
/// luxury sustain check. Iteration order is fixed (apprentice →
/// journeyman → master) so failure lines are emitted deterministically.
const List<({String tier, String commodityId})>
    kObserverWorkforceLuxuryTierMapping = <({String tier, String commodityId})>[
  (tier: 'apprentices', commodityId: kObserverWorkforceApprenticeLuxuryCommodityId),
  (tier: 'journeymen', commodityId: kObserverWorkforceJourneymanLuxuryCommodityId),
  (tier: 'masters', commodityId: kObserverWorkforceMasterLuxuryCommodityId),
];

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

int _readCommodityFromBlock(Object? block, String commodityId) {
  if (block is! Map<String, Object?>) return 0;
  return _readInt(block[commodityId]);
}

/// Returns the v4 `luxuryStockpile + lastTurnLuxuryProduction` total for
/// [playerId] and [commodityId] in [snapshotJson], or `0` when either
/// block is missing (older v3 snapshots or absent player row).
///
/// Per Requirement §21 bullet 4 of issue #2692, the luxury sustain check
/// compares this **stockpile + production** sum against the matched
/// trained-tier count: a player with zero stockpile but enough per-turn
/// production must still pass.
int luxuryAvailableForPlayer(
  Map<String, Object?> snapshotJson,
  String playerId,
  String commodityId,
) {
  final players = snapshotJson['players'];
  if (players is! List<Object?>) return 0;
  for (final row in players) {
    if (row is! Map<String, Object?>) continue;
    if (row['playerId']?.toString() != playerId) continue;
    final stockpile = _readCommodityFromBlock(
      row['luxuryStockpile'],
      commodityId,
    );
    final production = _readCommodityFromBlock(
      row['lastTurnLuxuryProduction'],
      commodityId,
    );
    return stockpile + production;
  }
  return 0;
}

/// Returns human-readable failure lines; empty when every Great Power
/// in [kObserverGreatPowerIds] meets both thresholds.
///
/// When [checkLuxurySustain] is `true` (default), each GP also passes
/// the §21 bullet 4 luxury sustain check via [verifyPerGpLuxurySustain]
/// — `luxuryStockpile + lastTurnLuxuryProduction >= tier count` for
/// every trained tier with a non-zero count. Pass `false` to limit the
/// verifier to the S10a thresholds (used by callers that read older v3
/// snapshots without luxury fields).
List<String> verifyPerGpWorkforceSustain({
  required Map<String, Object?> turnEndSnapshot,
  int minPeasants = kObserverWorkforceMinPeasants,
  int minTrained = kObserverWorkforceMinTrained,
  bool checkLuxurySustain = true,
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
  if (checkLuxurySustain) {
    failures.addAll(
      verifyPerGpLuxurySustain(turnEndSnapshot: turnEndSnapshot),
    );
  }
  return failures;
}

/// Returns one failure line per `(GP, tier)` whose
/// `luxuryStockpile + lastTurnLuxuryProduction` is below the tier
/// count for the matched luxury commodity (§21 bullet 4). Tiers with
/// a zero count for a given GP are skipped (no requirement when no
/// worker consumes the luxury).
///
/// Failure line format:
///
///     <gpId> <tier>=<count> <commodityId>_available=<available>
///         stockpile=<stockpile> lastTurnProduction=<production>
///
/// `available = stockpile + lastTurnProduction`. Both summands are
/// reported so the operator can quickly see whether the buffer or
/// the production rate is the bottleneck.
List<String> verifyPerGpLuxurySustain({
  required Map<String, Object?> turnEndSnapshot,
}) {
  final failures = <String>[];
  for (final gpId in kObserverGreatPowerIds) {
    final counts = workerPoolCountsForPlayer(turnEndSnapshot, gpId);
    final byTier = <String, int>{
      'apprentices': counts.apprentices,
      'journeymen': counts.journeymen,
      'masters': counts.masters,
    };
    for (final entry in kObserverWorkforceLuxuryTierMapping) {
      final tierCount = byTier[entry.tier] ?? 0;
      if (tierCount <= 0) continue;
      final stockpile = _readCommodityFromBlock(
        _luxuryStockpileBlockFor(turnEndSnapshot, gpId),
        entry.commodityId,
      );
      final production = _readCommodityFromBlock(
        _lastTurnLuxuryProductionBlockFor(turnEndSnapshot, gpId),
        entry.commodityId,
      );
      final available = stockpile + production;
      if (available < tierCount) {
        failures.add(
          '$gpId ${entry.tier}=$tierCount '
          '${entry.commodityId}_available=$available '
          'stockpile=$stockpile lastTurnProduction=$production '
          '(need ${entry.commodityId}_available >= $tierCount)',
        );
      }
    }
  }
  return failures;
}

Object? _luxuryStockpileBlockFor(
  Map<String, Object?> snapshotJson,
  String playerId,
) {
  final players = snapshotJson['players'];
  if (players is! List<Object?>) return null;
  for (final row in players) {
    if (row is! Map<String, Object?>) continue;
    if (row['playerId']?.toString() != playerId) continue;
    return row['luxuryStockpile'];
  }
  return null;
}

Object? _lastTurnLuxuryProductionBlockFor(
  Map<String, Object?> snapshotJson,
  String playerId,
) {
  final players = snapshotJson['players'];
  if (players is! List<Object?>) return null;
  for (final row in players) {
    if (row is! Map<String, Object?>) continue;
    if (row['playerId']?.toString() != playerId) continue;
    return row['lastTurnLuxuryProduction'];
  }
  return null;
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
  bool checkLuxurySustain = true,
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
    checkLuxurySustain: checkLuxurySustain,
  );
}
