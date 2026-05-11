import 'package:colonizethis_models/colonizethis_models.dart';

/// Per-game-state index of which players have any non-`unknown` tile
/// visibility inside each province.
///
/// Precomputed in one pass to avoid re-scanning per-province tile keys
/// inside per-player loops on the turn-resolution hot path.
/// See `SPEC/program/turn-resolution.md` and the turn-resolution budget rule.
///
/// Identity contract: province ids exposed by this index are always
/// `regionId|localId` full ids per `SPEC/game/world-model-identity.md`.
class ProvinceVisibilityIndex {
  final Map<String, Set<String>> _knownByPlayer;
  final Set<String> _knownToAny;

  const ProvinceVisibilityIndex._({
    required Map<String, Set<String>> knownByPlayer,
    required Set<String> knownToAny,
  }) : _knownByPlayer = knownByPlayer,
       _knownToAny = knownToAny;

  /// True when [playerId] has any tile in [fullProvinceId] with
  /// visibility other than `unknown`.
  bool isKnownToPlayer(String playerId, String fullProvinceId) {
    final set = _knownByPlayer[playerId];
    if (set == null) return false;
    return set.contains(fullProvinceId);
  }

  /// True when at least one player has any tile in [fullProvinceId] with
  /// visibility other than `unknown`.
  bool isKnownToAnyPlayer(String fullProvinceId) =>
      _knownToAny.contains(fullProvinceId);
}

/// Builds the per-(player, province) "known" index for [game] in a single
/// pass over provinces and player visibility maps.
///
/// Preserves the existing predicate used by
/// `emitPlayerProvinceDiscoveryEvents` and `_provinceKnownToAnyGp`:
/// a tile is "known" when its raw visibility entry is non-null and not
/// equal to `VisibilityLevel.unknown.name`.
///
/// Tile-key fallback (`localProvinceId` then prefixed) preserves
/// pre-index behavior in `_provinceKnownToPlayer`. Empty tile-key buckets
/// yield no membership for that province.
ProvinceVisibilityIndex buildProvinceVisibilityIndex(Game game) {
  final knownByPlayer = <String, Set<String>>{};
  final knownToAny = <String>{};

  final tileBuckets = game.worldState.tileKeysByRegionAndProvince;
  final visibilityByPlayer = game.worldState.playerVisibilityByTile;
  final playerIds = <String>[for (final p in game.players) p.id];

  for (final region in [game.worldState.oldWorld, game.worldState.newWorld]) {
    for (final province in region.provinces) {
      final regionId = province.regionId;
      final fullProvinceId = province.id.contains('|')
          ? province.id
          : ProvinceId.full(regionId, province.id);
      final localProvinceId = ProvinceId.localIdFrom(fullProvinceId);

      final regionBucket = tileBuckets[regionId];
      final tileKeys =
          regionBucket?[localProvinceId] ??
          regionBucket?[fullProvinceId] ??
          const <String>[];
      if (tileKeys.isEmpty) continue;

      var provinceKnownToAny = false;
      for (final playerId in playerIds) {
        final visibility =
            visibilityByPlayer[playerId] ?? const <String, String>{};
        for (final tileKey in tileKeys) {
          final raw = visibility[tileKey];
          if (raw != null && raw != 'unknown') {
            knownByPlayer
                .putIfAbsent(playerId, () => <String>{})
                .add(fullProvinceId);
            provinceKnownToAny = true;
            break;
          }
        }
      }
      if (provinceKnownToAny) {
        knownToAny.add(fullProvinceId);
      }
    }
  }

  return ProvinceVisibilityIndex._(
    knownByPlayer: knownByPlayer,
    knownToAny: knownToAny,
  );
}
