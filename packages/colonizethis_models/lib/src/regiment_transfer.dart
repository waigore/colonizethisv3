import 'unit.dart';

/// Bucket key for split-army transfer rows: [Unit.type] when known and non-empty,
/// otherwise the unit id (missing unit data).
String regimentTransferBucketKey(Unit? unit, String unitId) {
  if (unit != null && unit.type.isNotEmpty) return unit.type;
  return unitId;
}

/// Picks regiment unit ids in [regimentUnitIdsInOrder] for [countsByBucketToMove],
/// taking the first matches per bucket (same order semantics as [shipInstancesForTransferCounts]).
List<String> regimentUnitIdsForTransferCounts(
  List<String> regimentUnitIdsInOrder,
  Unit? Function(String unitId) tryUnit,
  Map<String, int> countsByBucketToMove,
) {
  final need = <String, int>{
    for (final e in countsByBucketToMove.entries)
      if (e.value > 0) e.key: e.value,
  };
  if (need.isEmpty) return const [];

  final out = <String>[];
  for (final unitId in regimentUnitIdsInOrder) {
    final u = tryUnit(unitId);
    final bucket = regimentTransferBucketKey(u, unitId);
    final left = need[bucket] ?? 0;
    if (left > 0) {
      out.add(unitId);
      need[bucket] = left - 1;
    }
  }
  return out;
}
