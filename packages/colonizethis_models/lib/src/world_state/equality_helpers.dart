/// Equality and JSON-load helpers for [WorldState].
///
/// First-class library (Refs #4068 Slice C).

import '../model_collection_equality.dart';
import '../province_id.dart';

/// Equality and JSON-load helpers for [WorldState]. Extracted into a part file
/// to keep `world_state.dart` under the models 500 non-comment-line cap
/// (`repo.models_file_size`). Collection comparisons use
/// [modelListEquals] / [modelMapEquals] / [modelSetEquals] (Refs #4068).
///
/// `lastTurnProvinceExtractionByProvinceId` comparison removed with the field
/// (Refs #4064).

List<String> worldStateSortedCopy(List<String> xs) => List<String>.from(xs)..sort();

bool worldStateTileKeysByRegionEquals(
  Map<String, Map<String, List<String>>> a,
  Map<String, Map<String, List<String>>> b,
) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    final otherInner = b[entry.key];
    if (otherInner == null) return false;
    if (otherInner.length != entry.value.length) return false;
    for (final innerEntry in entry.value.entries) {
      final otherList = otherInner[innerEntry.key];
      if (otherList == null || !modelListEquals(innerEntry.value, otherList)) {
        return false;
      }
    }
  }
  return true;
}

bool worldStateNestedStringMapEquals(
  Map<String, Map<String, String>> a,
  Map<String, Map<String, String>> b,
) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    final otherInner = b[entry.key];
    if (otherInner == null || !modelMapEquals(entry.value, otherInner)) {
      return false;
    }
  }
  return true;
}

bool worldStateSpyRevealEquals(
  Map<String, Map<String, int>> a,
  Map<String, Map<String, int>> b,
) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    final otherInner = b[entry.key];
    if (otherInner == null || !modelMapEquals(entry.value, otherInner)) {
      return false;
    }
  }
  return true;
}

bool worldStateMapOfSetEquals(Map<String, Set<String>> a, Map<String, Set<String>> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    final otherSet = b[entry.key];
    if (otherSet == null || !modelSetEquals(entry.value, otherSet)) {
      return false;
    }
  }
  return true;
}

String worldStateCanonicalTileBucketKeyForLoad({
  required String regionId,
  required String bucketKey,
  required List<String> tileKeys,
  required Set<String> localProvinceIds,
}) {
  if (ProvinceId.isPrefixed(bucketKey)) return bucketKey;
  if (localProvinceIds.contains(bucketKey)) return bucketKey;
  if (tileKeys.isEmpty) return bucketKey;
  final isSeaZoneBucket = tileKeys.every((tileKey) {
    final parts = tileKey.split('|');
    if (parts.length != 4) return false;
    return parts[0] == regionId && parts[1] == bucketKey;
  });
  if (!isSeaZoneBucket) return bucketKey;
  throw StateError(
    'models: legacy local sea-zone bucket key "$bucketKey" is not supported; '
    'expected canonical prefixed id "${ProvinceId.full(regionId, bucketKey)}".',
  );
}
