/// Shared fixtures for `computeNonGreatPowerAutoOffers` purchased-tile
/// parity tests (Refs #2991 C6, #3856, #3939).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'extraction_fixture_support.dart';
import 'purchased_tile_fixture_support.dart';

export 'purchased_tile_fixture_support.dart' show minorTileAutoOfferGame;

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

/// Two timber tiles in the same province — one purchased, one not.
Game twoMinorTimberTilesAutoOfferGame({
  required String purchasedTileKey,
  required String unpurchasedTileKey,
}) {
  const provinceId = 'oldWorld|m1';
  return purchasedTileFixtureGame(
    gameId: 'g_c6_parity',
    provinces: [capitalProvinceForNonGpExtractionTest(provinceId: provinceId)],
    tileKeysByRegionAndProvince: {
      'oldWorld': {
        provinceId: [purchasedTileKey, unpurchasedTileKey],
      },
    },
    minorNations: [testMinor()],
    purchasedTilesByTileKey: {purchasedTileKey: 'gpA'},
    tileState: tileStateFromSpecs(
      tileImps([purchasedTileKey, unpurchasedTileKey]),
    ),
  );
}
