part of '../world_state.dart';

/// Read-only focused accessors over [WorldState]'s internal maps so callers
/// avoid drilling the raw collections directly (#3543 §4). Extracted into a
/// part file to keep `world_state.dart` under the models 500 non-comment-line
/// cap (`repo.models_file_size`).
extension WorldStateFocusedAccessors on WorldState {
  /// Resource (commodity id) mapped to [tileKey], or `null` when the tile has
  /// no mapped resource. Read-only accessor over [WorldState.resourceByTileKey]
  /// so callers avoid drilling the internal map directly (#3543 §4).
  String? resourceAtTile(String tileKey) => resourceByTileKey[tileKey];

  /// Tile keys recorded for the ([regionId], [provinceId]) bucket, or `null`
  /// when the region or province bucket is absent. [provinceId] uses the same
  /// key form stored in [WorldState.tileKeysByRegionAndProvince] (prefixed for
  /// sea zones, local id for land provinces). Read-only accessor (#3543 §4).
  List<String>? tileKeysForProvince(String regionId, String provinceId) =>
      tileKeysByRegionAndProvince[regionId]?[provinceId];

  /// Port tile key for [provinceSeaboardKey] ("provinceId|seaZoneId"), or `null`
  /// when no port exists for that seaboard. Read-only accessor over
  /// [WorldState.portsByProvinceSeaboard] (#3543 §4).
  String? portTileForSeaboard(String provinceSeaboardKey) =>
      portsByProvinceSeaboard[provinceSeaboardKey];

  /// Buyer player id that purchased [tileKey] (Merchant purchase_land), or
  /// `null` when the tile is unpurchased. Read-only accessor over
  /// [WorldState.purchasedTilesByTileKey] so callers avoid drilling the
  /// internal map directly (#3543 §4).
  String? purchaserOfTile(String tileKey) => purchasedTilesByTileKey[tileKey];

  /// Prospected tile keys for [playerId], or an empty set when the player has
  /// prospected no tiles. Read-only accessor over
  /// [WorldState.playerProspectedTiles] that folds the common
  /// `?? const <String>{}` fallback in one place (#3543 §4).
  Set<String> prospectedTilesForPlayer(String playerId) =>
      playerProspectedTiles[playerId] ?? const <String>{};

  /// Tile-key buckets recorded for [regionId] (province id -> tile keys), or
  /// `null` when the region bucket is absent. Read-only accessor over
  /// [WorldState.tileKeysByRegionAndProvince] for per-region lookups
  /// (#3543 §4).
  Map<String, List<String>>? tileKeysForRegion(String regionId) =>
      tileKeysByRegionAndProvince[regionId];

  /// Improvement level (0-4) for [tileKey], or `0` when the tile has no
  /// recorded level. Read-only accessor that folds the
  /// `tileState.improvementLevel(...)` two-hop drill into one call so callers
  /// avoid reaching through [WorldState.tileState] directly (#3543 §4).
  int improvementLevelAtTile(String tileKey) =>
      tileState.improvementLevel(tileKey);

  /// Road level (0/1/2/4) for [tileKey], or `0` when the tile has no recorded
  /// level. Read-only accessor that folds the `tileState.roadLevel(...)`
  /// two-hop drill into one call so callers avoid reaching through
  /// [WorldState.tileState] directly (#3543 §4).
  int roadLevelAtTile(String tileKey) => tileState.roadLevel(tileKey);
}
