import 'dart:io';

import 'observer_conquest_verify.dart';
import 'observer_extractable_rollup.dart';

/// Canonical turn for colonial expansion regression (Refs #2509).
const int kObserverColonialCanonicalTurn = 150;

/// Minimum fraction of extractable GP resource tiles improved (level ≥ 1).
const double kObserverColonialMinImprovementRatio = 0.70;

const String kNewWorldProvinceIdPrefix = 'newWorld|';

/// Every `newWorld|` province row must be owned by a Great Power.
List<String> verifyGlobalNewWorldGpOwnership(
  Map<String, Object?> snapshotJson,
) {
  final rows = snapshotJson['provinceOwnershipSorted'];
  if (rows is! List<Object?>) {
    return ['provinceOwnershipSorted missing or not a list'];
  }
  final gpIds = kObserverGreatPowerIds.toSet();
  final failures = <String>[];
  for (final row in rows) {
    if (row is! Map<String, Object?>) continue;
    final id = row['id']?.toString() ?? '';
    if (!id.startsWith(kNewWorldProvinceIdPrefix)) continue;
    final owner = row['ownerId']?.toString();
    if (owner == null || owner.isEmpty || !gpIds.contains(owner)) {
      failures.add(
        'newWorld province $id owned by ${owner ?? "null"} (expected gp1–gp6)',
      );
    }
  }
  return failures;
}

/// Improvement ratio gate using snapshot rollup fields.
List<String> verifyExtractableImprovementRatio(
  Map<String, Object?> snapshotJson, {
  double minRatio = kObserverColonialMinImprovementRatio,
}) {
  final rollup = extractableRollupFromSnapshotJson(snapshotJson);
  if (rollup == null) {
    return [
      'snapshot missing extractableResourceTileCount / '
      'improvedExtractableResourceTileCount',
    ];
  }
  if (rollup.extractableResourceTileCount == 0) {
    return const [];
  }
  final ratio = rollup.improvementRatio;
  if (ratio + 1e-12 >= minRatio) {
    return const [];
  }
  return [
    'extractable improvement ratio ${ratio.toStringAsFixed(3)} '
    '(${rollup.improvedExtractableResourceTileCount}/'
    '${rollup.extractableResourceTileCount}) below minimum '
    '${minRatio.toStringAsFixed(2)}',
  ];
}

/// Turn-[endTurn] snapshot checks for NW ownership and improvement ratio.
List<String> verifyObserverColonialExpansionFromTraceDir(
  String tracesGameDir, {
  int endTurn = kObserverColonialCanonicalTurn,
  double minImprovementRatio = kObserverColonialMinImprovementRatio,
}) {
  final endPath = observerTurnSnapshotPath(
    tracesGameDir: tracesGameDir,
    turnNumber: endTurn,
  );
  if (!File(endPath).existsSync()) {
    return ['missing end snapshot: $endPath'];
  }
  final snapshot = loadObserverSnapshotJsonFile(endPath);
  final failures = <String>[
    ...verifyGlobalNewWorldGpOwnership(snapshot),
    ...verifyExtractableImprovementRatio(
      snapshot,
      minRatio: minImprovementRatio,
    ),
  ];
  return failures;
}
