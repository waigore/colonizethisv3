/// Shared fixtures for [PurchasedTileIndex] unit tests (Refs #3856).
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Canonical minor-owned purchased-tile scenario used by AC-D1-2 and
/// AC-D1-7. A single tile in `oldWorld|M1` was previously purchased by
/// `gpA` and the province is still owned by minor `M1`.
Game minorOwnedPurchasedTileIndexGame() {
  const ow = 'oldWorld';
  const minorProvinceId = '$ow|M1';
  const tileKey = '$ow|M1|0|0';
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
  );
}

/// Tribe-owned purchased tile in `oldWorld|T1` purchased by `gpA`.
Game tribeOwnedPurchasedTileIndexGame() {
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
  );
}

/// Purchased tile whose containing province is now GP-owned (post-conquest).
Game gpOwnedProvinceExcludesPurchasedTileGame() {
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
  );
}

/// Purchased tile in an unowned province.
Game unownedProvincePurchasedTileGame() {
  const ow = 'oldWorld';
  const provinceId = '$ow|P1';
  const tileKey = '$ow|P1|0|0';
  return TestFixtures.minimalGame(
    players: const [Player(id: 'gpA', displayName: 'GP A', isHuman: true)],
    oldWorld: const RegionData(
      provinces: [Province(id: provinceId, regionId: ow)],
    ),
    tileKeysByRegionAndProvince: const {
      ow: {
        provinceId: [tileKey],
      },
    },
    purchasedTilesByTileKey: const {tileKey: 'gpA'},
  );
}

/// Orphan purchased tile key with no tile-map entry.
Game unmappedTileKeyPurchasedTileGame() {
  const ow = 'oldWorld';
  const provinceId = '$ow|M1';
  const realTileKey = '$ow|M1|0|0';
  const orphanTileKey = '$ow|M1|9|9';
  return TestFixtures.minimalGame(
    players: const [Player(id: 'gpA', displayName: 'GP A', isHuman: true)],
    oldWorld: const RegionData(
      provinces: [Province(id: provinceId, regionId: ow, ownerId: 'M1')],
    ),
    tileKeysByRegionAndProvince: const {
      ow: {
        provinceId: [realTileKey],
      },
    },
    minorNations: const [MinorNation(id: 'M1', displayName: 'Minor 1')],
    purchasedTilesByTileKey: const {orphanTileKey: 'gpA'},
  );
}

/// Mixed minor + tribe purchases across old and new world.
Game mixedMinorTribePurchasedTileGame() {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  const minorProvinceId = '$ow|M1';
  const tribeProvinceId = '$nw|T1';
  const minorTileKey = '$ow|M1|0|0';
  const tribeTileKey = '$nw|T1|0|0';
  return TestFixtures.minimalGame(
    players: const [
      Player(id: 'gpA', displayName: 'GP A', isHuman: true),
      Player(id: 'gpB', displayName: 'GP B', isHuman: false),
    ],
    oldWorld: const RegionData(
      provinces: [
        Province(id: minorProvinceId, regionId: ow, ownerId: 'M1'),
      ],
    ),
    newWorld: const RegionData(
      provinces: [
        Province(id: tribeProvinceId, regionId: nw, ownerId: 'T1'),
      ],
    ),
    tileKeysByRegionAndProvince: const {
      ow: {
        minorProvinceId: [minorTileKey],
      },
      nw: {
        tribeProvinceId: [tribeTileKey],
      },
    },
    minorNations: const [MinorNation(id: 'M1', displayName: 'Minor 1')],
    tribes: const [Tribe(id: 'T1', displayName: 'Tribe 1')],
    purchasedTilesByTileKey: const {
      minorTileKey: 'gpA',
      tribeTileKey: 'gpB',
    },
  );
}

/// Minor-owned tile with empty owningGpId in purchasedTilesByTileKey.
Game emptyOwningGpPurchasedTileGame() {
  const ow = 'oldWorld';
  const provinceId = '$ow|M1';
  const tileKey = '$ow|M1|0|0';
  return TestFixtures.minimalGame(
    players: const [Player(id: 'gpA', displayName: 'GP A', isHuman: true)],
    oldWorld: const RegionData(
      provinces: [Province(id: provinceId, regionId: ow, ownerId: 'M1')],
    ),
    tileKeysByRegionAndProvince: const {
      ow: {
        provinceId: [tileKey],
      },
    },
    minorNations: const [MinorNation(id: 'M1', displayName: 'Minor 1')],
    purchasedTilesByTileKey: const {tileKey: ''},
  );
}
