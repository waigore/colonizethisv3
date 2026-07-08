/// Shared fixtures for the `computePurchasedTileRichesCredits` unit tests
/// (Refs #2991 C5, #3823, #3856).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Post-conquest: province owned by `gpB`; purchased entry still maps to `gpA`.
/// Tile is improved and roaded so the index filters it at build time.
Game postConquestPurchasedTileRichesGame() {
  const ow = 'oldWorld';
  const provinceId = '$ow|P1';
  const tileKey = '$ow|P1|0|0';
  return TestFixtures.minimalGame(
    players: const [
      Player(id: 'gpA', displayName: 'GP A', isHuman: true),
      Player(id: 'gpB', displayName: 'GP B', isHuman: false),
    ],
    oldWorld: const RegionData(
      provinces: [Province(id: provinceId, regionId: ow, ownerId: 'gpB')],
    ),
    tileKeysByRegionAndProvince: const {
      ow: {
        provinceId: [tileKey],
      },
    },
    purchasedTilesByTileKey: const {tileKey: 'gpA'},
    tileState: TileMapState()
        .setImprovement(tileKey, 1)
        .setRoadLevel(tileKey, 1),
  );
}

/// Tribe-owned purchased tile in `oldWorld|T1` purchased by `gpA`, improved
/// and roaded for riches yield.
Game tribeOwnedPurchasedTileRichesGame() {
  const ow = 'oldWorld';
  const tribeProvinceId = '$ow|T1';
  const tileKey = '$ow|T1|0|0';
  return TestFixtures.minimalGame(
    players: const [Player(id: 'gpA', displayName: 'GP A', isHuman: true)],
    oldWorld: const RegionData(
      provinces: [
        Province(id: tribeProvinceId, regionId: ow, ownerId: 'T1'),
      ],
    ),
    tileKeysByRegionAndProvince: const {
      ow: {
        tribeProvinceId: [tileKey],
      },
    },
    tribes: const [Tribe(id: 'T1', displayName: 'Tribe 1')],
    purchasedTilesByTileKey: const {tileKey: 'gpA'},
    tileState: TileMapState()
        .setImprovement(tileKey, 1)
        .setRoadLevel(tileKey, 1),
  );
}

/// Two minor-owned purchased tiles (`gpA` / `gpB`) with gold and gems yields.
Game multiGpPurchasedTileRichesGame() {
  const ow = 'oldWorld';
  const province1 = '$ow|M1';
  const province2 = '$ow|M2';
  const tileA = '$ow|M1|0|0';
  const tileB = '$ow|M2|0|1';
  return TestFixtures.minimalGame(
    players: const [
      Player(id: 'gpA', displayName: 'GP A', isHuman: true),
      Player(id: 'gpB', displayName: 'GP B', isHuman: false),
    ],
    oldWorld: const RegionData(
      provinces: [
        Province(id: province1, regionId: ow, ownerId: 'M1'),
        Province(id: province2, regionId: ow, ownerId: 'M2'),
      ],
    ),
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
    tileState: TileMapState()
        .setImprovement(tileA, 1)
        .setRoadLevel(tileA, 1)
        .setImprovement(tileB, 1)
        .setRoadLevel(tileB, 1),
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
