// dart format off
/// Shared fixtures for [PurchasedTileIndex] unit tests (Refs #3856, #3939).
import 'package:colonizethis_models/colonizethis_models.dart';
import '../purchased_tile_fixture_support.dart';
export '../purchased_tile_fixture_support.dart' show purchasedTileFixtureGame, minorPurchasedTileGame;
/// Canonical minor-owned purchased-tile scenario used by AC-D1-2 and AC-D1-7.
Game minorOwnedPurchasedTileIndexGame() => minorPurchasedTileGame(minorDisplayName: 'Minor 1');
/// Tribe-owned purchased tile in `oldWorld|T1` purchased by `gpA`.
Game tribeOwnedPurchasedTileIndexGame() => tribePurchasedTileGame(tribeDisplayName: 'Tribe 1');
/// Purchased tile whose containing province is now GP-owned (post-conquest).
Game gpOwnedProvinceExcludesPurchasedTileGame() => gpProvincePurchasedTileGame(ownerGpId: 'gpB');
/// Purchased tile in an unowned province.
Game unownedProvincePurchasedTileGame() {
  const ow = 'oldWorld';
  const provinceId = '$ow|P1';
  const tileKey = '$ow|P1|0|0';
  return purchasedTileFixtureGame(
    provinces: [Province(id: provinceId, regionId: ow)],
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
  const realTileKey = '$ow|M1|0|0';
  const orphanTileKey = '$ow|M1|9|9';
  return minorPurchasedTileGame(tileKey: realTileKey, minorDisplayName: 'Minor 1', purchasedTilesByTileKey: const {orphanTileKey: 'gpA'});
}
/// Mixed minor + tribe purchases across old and new world.
Game mixedMinorTribePurchasedTileGame() {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  const minorProvinceId = '$ow|M1';
  const tribeProvinceId = '$nw|T1';
  const minorTileKey = '$ow|M1|0|0';
  const tribeTileKey = '$nw|T1|0|0';
  return purchasedTileFixtureGame(
    players: const [
      Player(id: 'gpA', displayName: 'GP A', isHuman: true),
      Player(id: 'gpB', displayName: 'GP B', isHuman: false),
    ],
    provinces: [
      Province(id: minorProvinceId, regionId: ow, ownerId: 'M1'),
      Province(id: tribeProvinceId, regionId: nw, ownerId: 'T1'),
    ],
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
    purchasedTilesByTileKey: const {minorTileKey: 'gpA', tribeTileKey: 'gpB'},
  );
}
/// Minor-owned tile with empty owningGpId in purchasedTilesByTileKey.
Game emptyOwningGpPurchasedTileGame() {
  const tileKey = 'oldWorld|M1|0|0';
  return minorPurchasedTileGame(minorDisplayName: 'Minor 1', purchasedTilesByTileKey: const {tileKey: ''});
}
// dart format on
