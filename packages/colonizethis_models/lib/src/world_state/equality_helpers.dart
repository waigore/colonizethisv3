part of '../world_state.dart';

/// Equality and JSON-load helpers for [WorldState]. Extracted into a part file
/// to keep `world_state.dart` under the models 500 non-comment-line cap
/// (`repo.models_file_size`). Refs #4002.

List<String> _sortedCopy(List<String> xs) => List<String>.from(xs)..sort();

bool _tileKeysByRegionEquals(
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
      if (otherList == null ||
          otherList.length != innerEntry.value.length ||
          !_listEqualsString(innerEntry.value, otherList)) {
        return false;
      }
    }
  }
  return true;
}

bool _listEqualsString(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _listEqualsArmy(List<Army> a, List<Army> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _listEqualsFleet(List<Fleet> a, List<Fleet> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}


bool _mapEquals(Map<String, String> a, Map<String, String> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}

bool _nestedStringMapEquals(
  Map<String, Map<String, String>> a,
  Map<String, Map<String, String>> b,
) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    final otherInner = b[entry.key];
    if (otherInner == null || !_mapEquals(entry.value, otherInner)) {
      return false;
    }
  }
  return true;
}

bool _spyRevealEquals(
  Map<String, Map<String, int>> a,
  Map<String, Map<String, int>> b,
) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    final otherInner = b[entry.key];
    if (otherInner == null || otherInner.length != entry.value.length) {
      return false;
    }
    for (final innerEntry in entry.value.entries) {
      if (otherInner[innerEntry.key] != innerEntry.value) return false;
    }
  }
  return true;
}

bool _mapOfSetEquals(Map<String, Set<String>> a, Map<String, Set<String>> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    final otherSet = b[entry.key];
    if (otherSet == null || entry.value.length != otherSet.length) {
      return false;
    }
    for (final v in entry.value) {
      if (!otherSet.contains(v)) return false;
    }
  }
  return true;
}

String _canonicalTileBucketKeyForLoad({
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
