/// Shared fixtures for the `computePurchasedTileRichesCredits` unit tests
/// (Refs #2991 C5, #3823, #3856, #3939).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../purchased_tile_fixture_support.dart';

/// Post-conquest: province owned by `gpB`; purchased entry still maps to `gpA`.
Game postConquestPurchasedTileRichesGame() {
  const tileKey = 'oldWorld|P1|0|0';
  return gpProvincePurchasedTileGame(
    ownerGpId: 'gpB',
    tileState: improvedRoadedTileState(tileKey),
  );
}

/// Tribe-owned purchased tile in `oldWorld|T1` purchased by `gpA`, improved
/// and roaded for riches yield.
Game tribeOwnedPurchasedTileRichesGame() {
  const tileKey = 'oldWorld|T1|0|0';
  return tribePurchasedTileGame(
    tribeDisplayName: 'Tribe 1',
    tileState: improvedRoadedTileState(tileKey),
  );
}

/// Two minor-owned purchased tiles (`gpA` / `gpB`) with gold and gems yields.
Game multiGpPurchasedTileRichesGame() {
  const ow = 'oldWorld';
  const province1 = '$ow|M1';
  const province2 = '$ow|M2';
  const tileA = '$ow|M1|0|0';
  const tileB = '$ow|M2|0|1';
  return purchasedTileFixtureGame(
    players: const [
      Player(id: 'gpA', displayName: 'GP A', isHuman: true),
      Player(id: 'gpB', displayName: 'GP B', isHuman: false),
    ],
    provinces: [
      Province(id: province1, regionId: ow, ownerId: 'M1'),
      Province(id: province2, regionId: ow, ownerId: 'M2'),
    ],
    tileKeysByRegionAndProvince: const {
      ow: {
        province1: [tileA],
        province2: [tileB],
      },
    },
    minorNations: const [
      MinorNation(id: 'M1', displayName: 'Minor 1'),
      MinorNation(id: 'M2', displayName: 'Minor 2'),
    ],
    purchasedTilesByTileKey: const {tileA: 'gpA', tileB: 'gpB'},
    tileState: improvedRoadedTileState(
      tileA,
    ).setImprovement(tileB, 1).setRoadLevel(tileB, 1),
  );
}

/// 1×2 region grid: row 0 → M1 with gold; row 1 → M2 with gems.
Map<String, TileMapResult> multiGpPurchasedTileRichesTileMaps() {
  const ow = 'oldWorld';
  return {
    ow: TileMapResult(
      width: 1,
      height: 2,
      grid: [
        ['M1'],
        ['M2'],
      ],
      resourceGrid: [
        [Resource.gold],
        [Resource.gems],
      ],
    ),
  };
}

/// Canonical scenario: minor `M1` owns province `oldWorld|M1`; tile
/// `oldWorld|M1|0|0` was previously purchased by `gpA`.
Game purchasedTileScenario({
  required Resource resource,
  required int improvementLevel,
  required int roadLevel,
  Map<String, String>? portsByProvinceSeaboard,
}) {
  const tileKey = 'oldWorld|M1|0|0';
  var tileState = const TileMapState();
  if (improvementLevel > 0) {
    tileState = tileState.setImprovement(tileKey, improvementLevel);
  }
  if (roadLevel > 0) {
    tileState = tileState.setRoadLevel(tileKey, roadLevel);
  }
  return minorPurchasedTileGame(
    minorDisplayName: 'Minor 1',
    tileState: tileState,
    portsByProvinceSeaboard: portsByProvinceSeaboard,
  );
}
