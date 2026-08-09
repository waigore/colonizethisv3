import 'army.dart';
import 'fleet.dart';
import 'model_collection_equality.dart';
import 'region_data.dart';
import 'tile_map_state.dart';
import 'turn_state.dart';
import 'world_state/equality_helpers.dart';
import 'world_state_serialization.dart';

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

  WorldState copyWith({
    TurnState? turnState,
    RegionData? oldWorld,
    RegionData? newWorld,
    TileMapState? tileState,
    Map<String, String>? portsByProvinceSeaboard,
    Map<String, Map<String, String>>? playerVisibilityByTile,
    Map<String, Set<String>>? playerProspectedTiles,
    List<Fleet>? fleets,
    Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
    Map<String, Map<String, int>>? spyRevealTurnsByPlayer,
    Map<String, String>? purchasedTilesByTileKey,
    Map<String, String>? resourceByTileKey,
    Map<String, String>? seaZoneDisplayNameById,
    int? nextShipInstanceSeq,
    List<Army>? armies,
    int? nextArmySeq,
    List<String>? newsDigestProvinceRevealDoneIds,
    List<String>? newsDigestSeaZoneFleetDoneIds,
  }) {
    return WorldState(
      turnState: turnState ?? this.turnState,
      oldWorld: oldWorld ?? this.oldWorld,
      newWorld: newWorld ?? this.newWorld,
      tileState: tileState ?? this.tileState,
      portsByProvinceSeaboard:
          portsByProvinceSeaboard ?? this.portsByProvinceSeaboard,
      playerVisibilityByTile:
          playerVisibilityByTile ?? this.playerVisibilityByTile,
      playerProspectedTiles:
          playerProspectedTiles ?? this.playerProspectedTiles,
      fleets: fleets ?? this.fleets,
      tileKeysByRegionAndProvince:
          tileKeysByRegionAndProvince ?? this.tileKeysByRegionAndProvince,
      spyRevealTurnsByPlayer:
          spyRevealTurnsByPlayer ?? this.spyRevealTurnsByPlayer,
      purchasedTilesByTileKey:
          purchasedTilesByTileKey ?? this.purchasedTilesByTileKey,
      resourceByTileKey: resourceByTileKey ?? this.resourceByTileKey,
      seaZoneDisplayNameById:
          seaZoneDisplayNameById ?? this.seaZoneDisplayNameById,
      nextShipInstanceSeq: nextShipInstanceSeq ?? this.nextShipInstanceSeq,
      armies: armies ?? this.armies,
      nextArmySeq: nextArmySeq ?? this.nextArmySeq,
      newsDigestProvinceRevealDoneIds:
          newsDigestProvinceRevealDoneIds ??
          this.newsDigestProvinceRevealDoneIds,
      newsDigestSeaZoneFleetDoneIds:
          newsDigestSeaZoneFleetDoneIds ?? this.newsDigestSeaZoneFleetDoneIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldState &&
          runtimeType == other.runtimeType &&
          turnState == other.turnState &&
          oldWorld == other.oldWorld &&
          newWorld == other.newWorld &&
          tileState == other.tileState &&
          modelMapEquals(
            portsByProvinceSeaboard,
            other.portsByProvinceSeaboard,
          ) &&
          worldStateNestedStringMapEquals(
            playerVisibilityByTile,
            other.playerVisibilityByTile,
          ) &&
          worldStateMapOfSetEquals(playerProspectedTiles, other.playerProspectedTiles) &&
          modelListEquals(fleets, other.fleets) &&
          worldStateTileKeysByRegionEquals(
            tileKeysByRegionAndProvince,
            other.tileKeysByRegionAndProvince,
          ) &&
          worldStateSpyRevealEquals(
            spyRevealTurnsByPlayer,
            other.spyRevealTurnsByPlayer,
          ) &&
          modelMapEquals(
            purchasedTilesByTileKey,
            other.purchasedTilesByTileKey,
          ) &&
          modelMapEquals(resourceByTileKey, other.resourceByTileKey) &&
          modelMapEquals(
            seaZoneDisplayNameById,
            other.seaZoneDisplayNameById,
          ) &&
          nextShipInstanceSeq == other.nextShipInstanceSeq &&
          modelListEquals(armies, other.armies) &&
          nextArmySeq == other.nextArmySeq &&
          modelListEquals(
            worldStateSortedCopy(newsDigestProvinceRevealDoneIds),
            worldStateSortedCopy(other.newsDigestProvinceRevealDoneIds),
          ) &&
          modelListEquals(
            worldStateSortedCopy(newsDigestSeaZoneFleetDoneIds),
            worldStateSortedCopy(other.newsDigestSeaZoneFleetDoneIds),
          );

  @override
  int get hashCode => Object.hash(
    turnState,
    oldWorld,
    newWorld,
    tileState,
    Object.hashAll(portsByProvinceSeaboard.entries),
    Object.hashAll(
      playerVisibilityByTile.entries.map(
        (e) => Object.hash(e.key, Object.hashAll(e.value.entries)),
      ),
    ),
    Object.hashAll(
      playerProspectedTiles.entries.map(
        (e) => Object.hash(e.key, Object.hashAll(e.value)),
      ),
    ),
    Object.hashAll(fleets),
    Object.hashAll(
      tileKeysByRegionAndProvince.entries.map(
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
      spyRevealTurnsByPlayer.entries.map(
        (e) => Object.hash(e.key, Object.hashAll(e.value.entries)),
      ),
    ),
    Object.hashAll(purchasedTilesByTileKey.entries),
    Object.hashAll(resourceByTileKey.entries),
    Object.hashAll(seaZoneDisplayNameById.entries),
    nextShipInstanceSeq,
    Object.hashAll(armies),
    nextArmySeq,
    Object.hashAll(worldStateSortedCopy(newsDigestProvinceRevealDoneIds)),
    Object.hashAll(worldStateSortedCopy(newsDigestSeaZoneFleetDoneIds)),
  );
}
