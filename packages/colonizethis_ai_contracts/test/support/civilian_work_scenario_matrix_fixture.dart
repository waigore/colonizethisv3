/// Shared OW explorer Game / PlayerView scaffolds for Full AI civilian-work
/// scenario matrix pins SC-01–SC-09 (Refs #2082 / #4084).
library;

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Acting GP id for scenario-matrix civilian-work pins.
const String matrixPlayerId = 'gp1';

/// Old-World region id used by scenario-matrix fixtures.
const String matrixOw = kRegionOldWorld;

/// Tile keys `$matrixOw|$localSuffix|i|0` for [count] columns.
List<String> matrixProvinceTiles(String localSuffix, int count) =>
    List.generate(count, (i) => '$matrixOw|$localSuffix|$i|0');

/// Prefixed province id `$matrixOw|$localSuffix`.
String matrixProvinceId(String localSuffix) => '$matrixOw|$localSuffix';

/// Single-tile key `$matrixOw|$localSuffix|x|0` (default column 0).
String matrixTileKey(String localSuffix, [int x = 0]) =>
    '$matrixOw|$localSuffix|$x|0';

/// Tribe-owned province used by explore-score matrix rows.
Province matrixTribeProvince(String localSuffix) => Province(
      id: matrixProvinceId(localSuffix),
      regionId: matrixOw,
      ownerId: 'tribe1',
    );

/// GP-owned province used by prospect-score matrix rows.
Province matrixOwnedProvince(String localSuffix) => Province(
      id: matrixProvinceId(localSuffix),
      regionId: matrixOw,
      ownerId: matrixPlayerId,
    );

/// Minor-owned province (purchased-tile prospect rows).
Province matrixMinorProvince(String localSuffix, {String ownerId = 'minor1'}) =>
    Province(
      id: matrixProvinceId(localSuffix),
      regionId: matrixOw,
      ownerId: ownerId,
    );

/// OW Game shell with tile-key index and optional purchased tiles / factions.
Game matrixOwGame({
  required List<Province> provinces,
  required Map<String, List<String>> tilesByProvince,
  Map<String, String> purchasedTilesByTileKey = const {},
  List<Tribe> tribes = const [Tribe(id: 'tribe1', displayName: 'T')],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: provinces, units: const []),
      newWorld: const RegionData(),
      purchasedTilesByTileKey: purchasedTilesByTileKey,
      tileKeysByRegionAndProvince: {matrixOw: tilesByProvince},
    ),
    players: const [
      Player(id: matrixPlayerId, displayName: 'GP', isHuman: false),
    ],
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Explorer [PlayerView] for matrix selection pins.
PlayerView matrixExplorerView({
  required Game game,
  required String locationProvinceId,
  required String tileKey,
  required Map<String, VisibilityLevel> visibilityByTile,
  String unitId = 'e1',
}) {
  return PlayerView(
    playerId: matrixPlayerId,
    player: game.players.single,
    ownUnitsById: {
      unitId: Unit(
        id: unitId,
        type: kUnitTypeExplorer,
        ownerId: matrixPlayerId,
        locationProvinceId: locationProvinceId,
        tileKey: tileKey,
      ),
    },
    provincesById: const {},
    visibilityByTile: visibilityByTile,
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

/// Explore work suggestion for [unitId] on [tileKey].
WorkOrder matrixExploreWork(String tileKey, {String unitId = 'e1'}) =>
    WorkOrder(
      unitId: unitId,
      target: kWorkTargetExplore,
      targetTileKey: tileKey,
    );

/// Prospect work suggestion for [unitId] on [tileKey].
WorkOrder matrixProspectWork(String tileKey, {String unitId = 'e1'}) =>
    WorkOrder(
      unitId: unitId,
      target: kWorkTargetProspect,
      targetTileKey: tileKey,
    );

/// Visibility map: first [unknownCount] explore tiles unknown, remainder fogged.
Map<String, VisibilityLevel> matrixExploreVisibility(
  List<String> exploreTiles, {
  int unknownCount = 6,
  Map<String, VisibilityLevel> extra = const {},
}) {
  return <String, VisibilityLevel>{
    for (var i = 0; i < exploreTiles.length; i++)
      exploreTiles[i]: i < unknownCount
          ? VisibilityLevel.unknown
          : VisibilityLevel.fogged,
    ...extra,
  };
}
