import 'dart:convert';
import 'dart:io';

/// Canonical Full-AI observer seed for conquest regression (Refs #2504).
const int kObserverConquestCanonicalSeed = 42;

/// Minimum resolved turns for per-GP Old World conquest AC.
const int kObserverConquestCanonicalTurns = 100;

/// Minimum net Old World provinces gained per Great Power vs turn 1.
const int kObserverConquestMinOwGainPerGp = 3;

const List<String> kObserverGreatPowerIds = [
  'gp1',
  'gp2',
  'gp3',
  'gp4',
  'gp5',
  'gp6',
];

const String kOldWorldProvinceIdPrefix = 'oldWorld|';

/// Counts provinces in [snapshotJson] owned by [ownerId] whose id starts with
/// [kOldWorldProvinceIdPrefix].
int countOldWorldProvincesOwned(
  Map<String, Object?> snapshotJson,
  String ownerId,
) {
  final rows = snapshotJson['provinceOwnershipSorted'];
  if (rows is! List<Object?>) {
    return 0;
  }
  var count = 0;
  for (final row in rows) {
    if (row is! Map) {
      continue;
    }
    final id = row['id']?.toString() ?? '';
    final rowOwner = row['ownerId']?.toString();
    if (rowOwner == ownerId && id.startsWith(kOldWorldProvinceIdPrefix)) {
      count++;
    }
  }
  return count;
}

Map<String, int> oldWorldProvinceCountsByGp(Map<String, Object?> snapshotJson) {
  return <String, int>{
    for (final gpId in kObserverGreatPowerIds)
      gpId: countOldWorldProvincesOwned(snapshotJson, gpId),
  };
}

/// Returns human-readable failure lines; empty when every GP meets [minGainPerGp].
List<String> verifyPerGpOldWorldConquestGains({
  required Map<String, Object?> turnStartSnapshot,
  required Map<String, Object?> turnEndSnapshot,
  int minGainPerGp = kObserverConquestMinOwGainPerGp,
}) {
  final failures = <String>[];
  for (final gpId in kObserverGreatPowerIds) {
    final start = countOldWorldProvincesOwned(turnStartSnapshot, gpId);
    final end = countOldWorldProvincesOwned(turnEndSnapshot, gpId);
    final gain = end - start;
    if (gain < minGainPerGp) {
      failures.add(
        '$gpId gained $gain Old World provinces (need >= $minGainPerGp; '
        'start=$start end=$end)',
      );
    }
  }
  return failures;
}

Map<String, Object?> loadObserverSnapshotJsonFile(String path) {
  final text = File(path).readAsStringSync();
  final decoded = jsonDecode(text);
  if (decoded is! Map<String, Object?>) {
    throw FormatException('Observer snapshot root must be a JSON object: $path');
  }
  return decoded;
}

String observerTurnSnapshotPath({
  required String tracesGameDir,
  required int turnNumber,
}) {
  final label = turnNumber.toString().padLeft(6, '0');
  return '$tracesGameDir/turn-$label.snapshot.json';
}

/// Verifies turn-1 vs turn-[endTurn] snapshots under [tracesGameDir].
List<String> verifyObserverConquestFromTraceDir(
  String tracesGameDir, {
  int endTurn = kObserverConquestCanonicalTurns,
  int startTurn = 1,
  int minGainPerGp = kObserverConquestMinOwGainPerGp,
}) {
  final startPath = observerTurnSnapshotPath(
    tracesGameDir: tracesGameDir,
    turnNumber: startTurn,
  );
  final endPath = observerTurnSnapshotPath(
    tracesGameDir: tracesGameDir,
    turnNumber: endTurn,
  );
  if (!File(startPath).existsSync()) {
    return ['missing start snapshot: $startPath'];
  }
  if (!File(endPath).existsSync()) {
    return ['missing end snapshot: $endPath'];
  }
  return verifyPerGpOldWorldConquestGains(
    turnStartSnapshot: loadObserverSnapshotJsonFile(startPath),
    turnEndSnapshot: loadObserverSnapshotJsonFile(endPath),
    minGainPerGp: minGainPerGp,
  );
}
