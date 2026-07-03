/// Shared fixtures for `computeNonGreatPowerAutoOffers` purchased-tile
/// parity tests (Refs #2991 C6, #3856).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import 'tile_map_test_support.dart';

/// Builds a minimal [Game] with one Minor `m1` owning province `oldWorld|m1`
/// and a single tile at [tileKey]. The tile is improved to
/// [improvementLevel] with road level [roadLevel].
Game minorTileAutoOfferGame({
  required String tileKey,
  required int improvementLevel,
  required int roadLevel,
  Map<String, String> purchasedTilesByTileKey = const {},
}) {
  const provinceId = 'oldWorld|m1';
  TileMapState tileState = const TileMapState();
  if (improvementLevel > 0) {
    tileState = tileState.setImprovement(tileKey, improvementLevel);
  }
  if (roadLevel > 0) {
    tileState = tileState.setRoadLevel(tileKey, roadLevel);
  }
  return TestFixtures.minimalGame(
    id: 'g_c6',
    players: const [Player(id: 'gpA', displayName: 'GP A', isHuman: true)],
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: provinceId,
          regionId: 'oldWorld',
          ownerId: 'm1',
          townDevelopmentLevel: 1,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: const {
      'oldWorld': {
        provinceId: ['oldWorld|m1|0|0'],
      },
    },
    minorNations: const [
      MinorNation(
        id: 'm1',
        capitalProvinceId: provinceId,
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: provinceId,
          x: 0,
          y: 0,
        ),
      ),
    ],
    tileState: tileState,
    purchasedTilesByTileKey: purchasedTilesByTileKey,
    turnNumber: 1,
  );
}

/// Two timber tiles in the same province — one purchased, one not.
Game twoMinorTimberTilesAutoOfferGame({
  required String purchasedTileKey,
  required String unpurchasedTileKey,
}) {
  const provinceId = 'oldWorld|m1';
  TileMapState tileState = const TileMapState();
  for (final tileKey in [purchasedTileKey, unpurchasedTileKey]) {
    tileState = tileState.setImprovement(tileKey, 1).setRoadLevel(tileKey, 1);
  }
  return TestFixtures.minimalGame(
    id: 'g_c6_parity',
    players: const [Player(id: 'gpA', displayName: 'GP A', isHuman: true)],
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: provinceId,
          regionId: 'oldWorld',
          ownerId: 'm1',
          townDevelopmentLevel: 1,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: {
      'oldWorld': {
        provinceId: [purchasedTileKey, unpurchasedTileKey],
      },
    },
    minorNations: const [
      MinorNation(
        id: 'm1',
        capitalProvinceId: provinceId,
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: provinceId,
          x: 0,
          y: 0,
        ),
      ),
    ],
    tileState: tileState,
    purchasedTilesByTileKey: {purchasedTileKey: 'gpA'},
    turnNumber: 1,
  );
}

/// 2x1 tile map for province `m1` where both tiles carry [resource].
TileMapResult twoTileSameResourceMap(Resource resource) => TileMapResult(
  width: 2,
  height: 1,
  grid: [
    ['m1', 'm1'],
  ],
  resourceGrid: [
    [resource, resource],
  ],
);
