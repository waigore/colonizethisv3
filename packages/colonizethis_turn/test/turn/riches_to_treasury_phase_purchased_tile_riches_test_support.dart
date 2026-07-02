/// Shared fixtures for the `richesToTreasuryTurnPhaseHandler` purchased-tile
/// riches handoff integration tests (Refs #2991 C5). Extracted so
/// `riches_to_treasury_phase_purchased_tile_riches_test.dart` stays within the
/// `repo.logic_test_file_size` 400-line limit.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

Game gameWithPurchasedGoldTile({
  required int gpATreasury,
  int gpAStockpileGold = 0,
}) =>
    gameWithPurchasedTileResource(
      resource: Resource.gold,
      improvementLevel: 1,
      roadLevel: 1,
      gpATreasury: gpATreasury,
      gpAStockpileGold: gpAStockpileGold,
    );

Game gameWithPurchasedTileResource({
  required Resource resource,
  required int improvementLevel,
  required int roadLevel,
  required int gpATreasury,
  required int gpAStockpileGold,
  double richesCashMultiplier = 1.0,
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
    players: [
      Player(
        id: 'gpA',
        displayName: 'GP A',
        isHuman: true,
        treasury: gpATreasury,
        stockpile: gpAStockpileGold > 0
            ? Stockpile(quantities: {'gold': gpAStockpileGold})
            : Stockpile.empty,
      ),
    ],
    oldWorld: const RegionData(
      provinces: [
        Province(id: minorProvinceId, regionId: ow, ownerId: 'M1'),
      ],
    ),
    tileKeysByRegionAndProvince: const {
      ow: {
        minorProvinceId: [tileKey],
      },
    },
    minorNations: const [MinorNation(id: 'M1', displayName: 'Minor 1')],
    purchasedTilesByTileKey: const {tileKey: 'gpA'},
    tileState: tileState,
    richesCashMultiplier: richesCashMultiplier,
  );
}

Map<String, TileMapResult> tileMapByRegionForResource(Resource resource) {
  return {
    'oldWorld': TileMapResult(
      width: 1,
      height: 1,
      grid: [
        ['M1'],
      ],
      resourceGrid: [
        [resource],
      ],
    ),
  };
}
