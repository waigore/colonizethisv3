// Shared purchased-tile game builders (Refs #2991, #3939 phase 3 slice 9).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import 'extraction_fixture_support.dart';

/// Canonical parameterized purchased-tile [Game] builder.
Game purchasedTileFixtureGame({
  required List<Province> provinces,
  required Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince,
  Map<String, String> purchasedTilesByTileKey = const {},
  List<Player> players = const [
    Player(id: 'gpA', displayName: 'GP A', isHuman: true),
  ],
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  TileMapState? tileState,
  String gameId = 'g_pt',
  Map<String, String>? portsByProvinceSeaboard,
}) {
  return TestFixtures.minimalGame(
    id: gameId,
    players: players,
    oldWorld: RegionData(
      provinces: provinces.where((p) => p.regionId == 'oldWorld').toList(),
    ),
    newWorld: RegionData(
      provinces: provinces.where((p) => p.regionId == 'newWorld').toList(),
    ),
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    minorNations: minorNations,
    tribes: tribes,
    purchasedTilesByTileKey: purchasedTilesByTileKey,
    tileState: tileState ?? const TileMapState(),
    portsByProvinceSeaboard: portsByProvinceSeaboard,
  );
}

/// Minor-owned province with a single purchased tile at [tileKey].
Game minorPurchasedTileGame({
  String regionId = 'oldWorld',
  String localProvinceId = 'M1',
  String minorId = 'M1',
  String tileKey = 'oldWorld|M1|0|0',
  String owningGpId = 'gpA',
  List<Player> players = const [
    Player(id: 'gpA', displayName: 'GP A', isHuman: true),
  ],
  TileMapState? tileState,
  Map<String, String>? purchasedTilesByTileKey,
  int townDevelopmentLevel = 1,
  String gameId = 'g_pt',
  String? minorDisplayName,
  Map<String, String>? portsByProvinceSeaboard,
}) {
  final provinceId = '$regionId|$localProvinceId';
  return purchasedTileFixtureGame(
    gameId: gameId,
    players: players,
    provinces: [
      Province(
        id: provinceId,
        regionId: regionId,
        ownerId: minorId,
        townDevelopmentLevel: townDevelopmentLevel,
      ),
    ],
    tileKeysByRegionAndProvince: {
      regionId: {
        provinceId: [tileKey],
      },
    },
    minorNations: [
      MinorNation(
        id: minorId,
        displayName: minorDisplayName,
        capitalProvinceId: provinceId,
        capitalTile: CapitalTile(
          regionId: regionId,
          provinceId: provinceId,
          x: 0,
          y: 0,
        ),
      ),
    ],
    purchasedTilesByTileKey: purchasedTilesByTileKey ?? {tileKey: owningGpId},
    tileState: tileState,
    portsByProvinceSeaboard: portsByProvinceSeaboard,
  );
}

/// Tribe-owned province with a single purchased tile at [tileKey].
Game tribePurchasedTileGame({
  String regionId = 'oldWorld',
  String localProvinceId = 'T1',
  String tribeId = 'T1',
  String tileKey = 'oldWorld|T1|0|0',
  String owningGpId = 'gpA',
  List<Player> players = const [
    Player(id: 'gpA', displayName: 'GP A', isHuman: true),
  ],
  TileMapState? tileState,
  String gameId = 'g_pt',
  String? tribeDisplayName,
}) {
  final provinceId = '$regionId|$localProvinceId';
  return purchasedTileFixtureGame(
    gameId: gameId,
    players: players,
    provinces: [Province(id: provinceId, regionId: regionId, ownerId: tribeId)],
    tileKeysByRegionAndProvince: {
      regionId: {
        provinceId: [tileKey],
      },
    },
    tribes: [
      Tribe(
        id: tribeId,
        displayName: tribeDisplayName,
        capitalProvinceId: provinceId,
        capitalTile: CapitalTile(
          regionId: regionId,
          provinceId: provinceId,
          x: 0,
          y: 0,
        ),
      ),
    ],
    purchasedTilesByTileKey: {tileKey: owningGpId},
    tileState: tileState,
  );
}

/// GP-owned province with a purchased tile previously owned by [owningGpId].
Game gpProvincePurchasedTileGame({
  String regionId = 'oldWorld',
  String localProvinceId = 'P1',
  required String ownerGpId,
  String tileKey = 'oldWorld|P1|0|0',
  String owningGpId = 'gpA',
  List<Player> players = const [
    Player(id: 'gpA', displayName: 'GP A', isHuman: true),
    Player(id: 'gpB', displayName: 'GP B', isHuman: false),
  ],
  TileMapState? tileState,
  String gameId = 'g_pt',
}) {
  final provinceId = '$regionId|$localProvinceId';
  return purchasedTileFixtureGame(
    gameId: gameId,
    players: players,
    provinces: [
      Province(id: provinceId, regionId: regionId, ownerId: ownerGpId),
    ],
    tileKeysByRegionAndProvince: {
      regionId: {
        provinceId: [tileKey],
      },
    },
    purchasedTilesByTileKey: {tileKey: owningGpId},
    tileState: tileState,
  );
}

/// Minor-owned tile with configurable improvement/road for auto-offer suites.
Game minorTileAutoOfferGame({
  required String tileKey,
  required int improvementLevel,
  required int roadLevel,
  Map<String, String> purchasedTilesByTileKey = const {},
}) {
  const provinceId = 'oldWorld|m1';
  var tileState = const TileMapState();
  if (improvementLevel > 0) {
    tileState = tileState.setImprovement(tileKey, improvementLevel);
  }
  if (roadLevel > 0) {
    tileState = tileState.setRoadLevel(tileKey, roadLevel);
  }
  return minorPurchasedTileGame(
    localProvinceId: 'm1',
    minorId: 'm1',
    tileKey: tileKey,
    townDevelopmentLevel: 1,
    gameId: 'g_c6',
    purchasedTilesByTileKey: purchasedTilesByTileKey,
    tileState: tileState,
  );
}

/// Improved + roaded tile state for riches-yield purchased-tile tests.
TileMapState improvedRoadedTileState(String tileKey) =>
    TileMapState().setImprovement(tileKey, 1).setRoadLevel(tileKey, 1);
