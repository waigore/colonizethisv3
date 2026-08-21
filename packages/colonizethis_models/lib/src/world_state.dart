import 'army.dart';
import 'fleet.dart';
import 'region_data.dart';
import 'tile_map_state.dart';
import 'turn_state.dart';
import 'world_state/equality_helpers.dart';
import 'world_state_serialization.dart';

export 'world_state/copy_with.dart';
export 'world_state/focused_accessors.dart';

/// Snapshot at a point in time. Turn state + region data + tile state. SPEC/game/world-model.
class WorldState {
  const WorldState({
    required this.turnState,
    required this.oldWorld,
    required this.newWorld,
    this.tileState = const TileMapState(),
    this.portsByProvinceSeaboard = const {},
    this.playerVisibilityByTile = const {},
    this.playerProspectedTiles = const {},
    this.fleets = const [],
    this.tileKeysByRegionAndProvince = const {},
    this.spyRevealTurnsByPlayer = const {},
    this.purchasedTilesByTileKey = const {},
    this.resourceByTileKey = const {},
    this.seaZoneDisplayNameById = const {},
    this.nextShipInstanceSeq = 1,
    this.armies = const [],
    this.nextArmySeq = 1,
    this.newsDigestProvinceRevealDoneIds = const [],
    this.newsDigestSeaZoneFleetDoneIds = const [],
  });

  final TurnState turnState;
  final RegionData oldWorld;
  final RegionData newWorld;

  /// Mutable per-tile improvement and road level. Key: "regionId|provinceId|x|y".
  final TileMapState tileState;

  /// Port present per (province, seaboard). Key: "provinceId|seaZoneId", value: tile key.
  final Map<String, String> portsByProvinceSeaboard;

  /// Per-player tile visibility: playerId -> (tileKey -> visibility level name).
  /// Visibility level names correspond to the enum in SPEC/game/fog-and-exploration.md.
  final Map<String, Map<String, String>> playerVisibilityByTile;

  /// Per-player set of prospected tile keys: playerId -> set of tile keys.
  /// Stored as lists in JSON; converted to sets in logic as needed.
  final Map<String, Set<String>> playerProspectedTiles;

  /// Fleets (naval). SPEC/game/ships-and-naval.md.
  final List<Fleet> fleets;

  /// Tile keys per region and province. regionId -> provinceId -> list of tile keys.
  /// Used for explore resolution (full province reveal). Populated at game setup.
  /// SPEC/program/fog-and-exploration-resolution.md.
  final Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince;

  /// Spy reveal timers: playerId -> (provinceKey -> turns left until fog returns). SPEC/program/fog-and-exploration-resolution.md.
  final Map<String, Map<String, int>> spyRevealTurnsByPlayer;

  /// Purchased tiles (Merchant purchase_land): tileKey -> buyer playerId. Minor/Tribe tiles bought by GP. SPEC/game/civilian-units.md.
  final Map<String, String> purchasedTilesByTileKey;

  /// Resource (commodity id) per tile key. Populated at game setup from tile map. Used for purchase_land validation.
  final Map<String, String> resourceByTileKey;

  /// Sea-zone display name by prefixed sea-zone id ("regionId|localSeaZoneId").
  final Map<String, String> seaZoneDisplayNameById;

  /// Next index for minting `ship_<n>` instance ids. At least [inferNextShipInstanceSeqFromFleets](fleets).
  /// SPEC/game/ships-and-naval.md.
  final int nextShipInstanceSeq;

  /// Land armies (regiment containers). SPEC/game/military-armies.md.
  final List<Army> armies;

  /// Monotonic counter for minting non-home army ids (e.g. split armies).
  final int nextArmySeq;

  /// Prefixed province ids that already generated a news "province discovered" line.
  /// SPEC/program/turn-news-digest.md.
  final List<String> newsDigestProvinceRevealDoneIds;

  /// Prefixed sea zone ids that already generated a news "first fleet" line.
  final List<String> newsDigestSeaZoneFleetDoneIds;

  Map<String, dynamic> toJson() => encodeWorldStateToJson(this);

  static WorldState fromJson(Map<String, dynamic> json) =>
      decodeWorldStateFromJson(json);

  @override
  bool operator ==(Object other) => worldStateEquals(this, other);

  @override
  int get hashCode => worldStateHashCode(this);
}
