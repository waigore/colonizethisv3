import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Shared tile/province snapshot for work-target pre-filtering and tile-keys
/// probing. Both suggestion prefilter and UI tile-key highlight paths consume
/// this index instead of duplicating ownership/resource scans.
class WorkTileCandidateIndex {
  WorkTileCandidateIndex({
    required this.game,
    required this.playerId,
    required this.tileKeysByRegion,
    required this.resourceByTile,
    required this.purchasedTiles,
    required this.ownedProvinceIds,
    this.tileMapByRegion,
    this.factionMembership,
  });

  final Game game;
  final String playerId;
  final Map<String, Map<String, List<String>>> tileKeysByRegion;
  final Map<String, String> resourceByTile;
  final Map<String, String> purchasedTiles;
  final Set<String> ownedProvinceIds;
  final Map<String, TileMapResult>? tileMapByRegion;
  final DiplomacyFactionMembership? factionMembership;
}

class WorkTilePrefilterSession {
  WorkTilePrefilterSession({
    required this.index,
    required this.exploreProvinceScope,
    required this.result,
  });

  final WorkTileCandidateIndex index;
  final Set<String>? exploreProvinceScope;
  final Set<String> result;

  Game get game => index.game;
  String get playerId => index.playerId;
  Map<String, Map<String, List<String>>> get tileKeysByRegion =>
      index.tileKeysByRegion;
  Map<String, String> get resourceByTile => index.resourceByTile;
  Map<String, String> get purchasedTiles => index.purchasedTiles;
  Set<String> get ownedProvinceIds => index.ownedProvinceIds;
  Map<String, TileMapResult>? get tileMapByRegion => index.tileMapByRegion;
  DiplomacyFactionMembership? get factionMembership => index.factionMembership;
}
