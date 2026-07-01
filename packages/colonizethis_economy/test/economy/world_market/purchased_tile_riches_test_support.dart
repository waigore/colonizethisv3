/// Shared fixtures for the `computePurchasedTileRichesCredits` unit tests
/// (Refs #2991 C5). Extracted so `purchased_tile_riches_test.dart` stays
/// within the `repo.logic_test_file_size` 400-line limit.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

export 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart'
    show singleResourceTileMap, tileMapByRegionForResource;

/// Canonical scenario: minor `M1` owns province `oldWorld|M1`; tile
/// `oldWorld|M1|0|0` was previously purchased by `gpA`.
Game purchasedTileScenario({
  required Resource resource,
  required int improvementLevel,
  required int roadLevel,
  Map<String, String>? portsByProvinceSeaboard,
}) {
  const ow = 'oldWorld';
  const minorProvinceId = '$ow|M1';
  const tileKey = '$ow|M1|0|0';
  TileMapState tileState = const TileMapState();
  if (improvementLevel > 0) {
    tileState = tileState.setImprovement(tileKey, improvementLevel);
  }
  if (roadLevel > 0) {
    tileState = tileState.setRoadLevel(tileKey, roadLevel);
  }
  return TestFixtures.minimalGame(
    players: const [Player(id: 'gpA', displayName: 'GP A', isHuman: true)],
    oldWorld: const RegionData(
      provinces: [Province(id: minorProvinceId, regionId: ow, ownerId: 'M1')],
    ),
    tileKeysByRegionAndProvince: const {
      ow: {
        minorProvinceId: [tileKey],
      },
    },
    minorNations: const [MinorNation(id: 'M1', displayName: 'Minor 1')],
    purchasedTilesByTileKey: const {tileKey: 'gpA'},
    tileState: tileState,
    portsByProvinceSeaboard: portsByProvinceSeaboard,
  );
}
