/// Equality and JSON-load helpers for [WorldState].
///
/// First-class library (Refs #4068 Slice C). Full [WorldState] == / hashCode
/// live here so the host stays thin (Refs #4571).

import '../model_collection_equality.dart';
import '../province_id.dart';
import '../world_state.dart';

/// Equality and JSON-load helpers for [WorldState]. Collection comparisons use
/// [modelListEquals] / [modelMapEquals] / [modelSetEquals] (Refs #4068).
///
/// `lastTurnProvinceExtractionByProvinceId` comparison removed with the field
/// (Refs #4064).

List<String> worldStateSortedCopy(List<String> xs) => List<String>.from(xs)..sort();

bool worldStateEquals(WorldState state, Object other) =>
    identical(state, other) ||
    other is WorldState &&
        state.runtimeType == other.runtimeType &&
        state.turnState == other.turnState &&
        state.oldWorld == other.oldWorld &&
        state.newWorld == other.newWorld &&
        state.tileState == other.tileState &&
        modelMapEquals(
          state.portsByProvinceSeaboard,
          other.portsByProvinceSeaboard,
        ) &&
        worldStateNestedStringMapEquals(
          state.playerVisibilityByTile,
          other.playerVisibilityByTile,
        ) &&
        worldStateMapOfSetEquals(
          state.playerProspectedTiles,
          other.playerProspectedTiles,
        ) &&
        modelListEquals(state.fleets, other.fleets) &&
        worldStateTileKeysByRegionEquals(
          state.tileKeysByRegionAndProvince,
          other.tileKeysByRegionAndProvince,
        ) &&
        worldStateSpyRevealEquals(
          state.spyRevealTurnsByPlayer,
          other.spyRevealTurnsByPlayer,
        ) &&
        modelMapEquals(
          state.purchasedTilesByTileKey,
          other.purchasedTilesByTileKey,
        ) &&
        modelMapEquals(state.resourceByTileKey, other.resourceByTileKey) &&
        modelMapEquals(
          state.seaZoneDisplayNameById,
          other.seaZoneDisplayNameById,
        ) &&
        state.nextShipInstanceSeq == other.nextShipInstanceSeq &&
        modelListEquals(state.armies, other.armies) &&
        state.nextArmySeq == other.nextArmySeq &&
        modelListEquals(
          worldStateSortedCopy(state.newsDigestProvinceRevealDoneIds),
          worldStateSortedCopy(other.newsDigestProvinceRevealDoneIds),
        ) &&
        modelListEquals(
          worldStateSortedCopy(state.newsDigestSeaZoneFleetDoneIds),
          worldStateSortedCopy(other.newsDigestSeaZoneFleetDoneIds),
        );

int worldStateHashCode(WorldState state) => Object.hash(
  state.turnState,
  state.oldWorld,
  state.newWorld,
  state.tileState,
  Object.hashAll(state.portsByProvinceSeaboard.entries),
  Object.hashAll(
    state.playerVisibilityByTile.entries.map(
      (e) => Object.hash(e.key, Object.hashAll(e.value.entries)),
    ),
  ),
  Object.hashAll(
    state.playerProspectedTiles.entries.map(
      (e) => Object.hash(e.key, Object.hashAll(e.value)),
    ),
  ),
  Object.hashAll(state.fleets),
  Object.hashAll(
    state.tileKeysByRegionAndProvince.entries.map(
      (e) => Object.hash(
        e.key,
        Object.hashAll(
          e.value.entries.map(
            (e2) => Object.hash(e2.key, Object.hashAll(e2.value)),
          ),
        ),
      ),
    ),
  ),
  Object.hashAll(
    state.spyRevealTurnsByPlayer.entries.map(
      (e) => Object.hash(e.key, Object.hashAll(e.value.entries)),
    ),
  ),
  Object.hashAll(state.purchasedTilesByTileKey.entries),
  Object.hashAll(state.resourceByTileKey.entries),
  Object.hashAll(state.seaZoneDisplayNameById.entries),
  state.nextShipInstanceSeq,
  Object.hashAll(state.armies),
  state.nextArmySeq,
  Object.hashAll(worldStateSortedCopy(state.newsDigestProvinceRevealDoneIds)),
  Object.hashAll(worldStateSortedCopy(state.newsDigestSeaZoneFleetDoneIds)),
);

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
