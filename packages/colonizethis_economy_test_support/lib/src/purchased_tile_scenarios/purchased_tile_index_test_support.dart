// dart format off
/// Shared fixtures for [PurchasedTileIndex] unit tests (Refs #3856, #3939).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
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
/// Data-driven expectations for [PurchasedTileIndexFromGameScenario] rows.
class PurchasedTileIndexExpectation {
  const PurchasedTileIndexExpectation({this.length, this.isEmpty, this.isNotEmpty, this.attributionForTileKeyNull, this.attributionForTileKeysNull, this.attributionsEmpty = false, this.singleAttribution, this.multiAttributions, this.attributionsTileKeysContainAll, this.deterministicIndexRerun = false, this.deterministicRerunTileKey});
  final int? length;
  final bool? isEmpty;
  final bool? isNotEmpty;
  final String? attributionForTileKeyNull;
  final Iterable<String>? attributionForTileKeysNull;
  final bool attributionsEmpty;
  final PurchasedTileAttributionExpectation? singleAttribution;
  final Iterable<PurchasedTileAttributionExpectation>? multiAttributions;
  final Iterable<String>? attributionsTileKeysContainAll;
  final bool deterministicIndexRerun;
  final String? deterministicRerunTileKey;
}
class PurchasedTileAttributionExpectation {
  const PurchasedTileAttributionExpectation({required this.tileKey, this.owningGpId, this.sourceFactionId, this.provinceId});
  final String tileKey;
  final String? owningGpId;
  final String? sourceFactionId;
  final String? provinceId;
}
void assertPurchasedTileIndexExpectation(PurchasedTileIndex index, PurchasedTileIndexExpectation expectation, {Game? gameForDeterminismRerun}) {
  if (expectation.length != null) {
    expect(index.length, expectation.length);
  }
  if (expectation.isEmpty != null) {
    expect(index.isEmpty, expectation.isEmpty);
  }
  if (expectation.isNotEmpty != null) {
    expect(index.isNotEmpty, expectation.isNotEmpty);
  }
  if (expectation.attributionForTileKeyNull != null) {
    expect(index.attributionForTileKey(expectation.attributionForTileKeyNull!), isNull);
  }
  if (expectation.attributionForTileKeysNull != null) {
    for (final tileKey in expectation.attributionForTileKeysNull!) {
      expect(index.attributionForTileKey(tileKey), isNull);
    }
  }
  if (expectation.attributionsEmpty) {
    expect(index.attributions, isEmpty);
  }
  if (expectation.singleAttribution != null) {
    final attr = index.attributionForTileKey(expectation.singleAttribution!.tileKey);
    expect(attr, isNotNull);
    if (expectation.singleAttribution!.owningGpId != null) {
      expect(attr!.owningGpId, expectation.singleAttribution!.owningGpId);
    }
    if (expectation.singleAttribution!.sourceFactionId != null) {
      expect(attr!.sourceFactionId, expectation.singleAttribution!.sourceFactionId);
    }
    if (expectation.singleAttribution!.provinceId != null) {
      expect(attr!.provinceId, expectation.singleAttribution!.provinceId);
    }
    expect(attr!.tileKey, expectation.singleAttribution!.tileKey);
  }
  if (expectation.multiAttributions != null) {
    for (final pin in expectation.multiAttributions!) {
      final attr = index.attributionForTileKey(pin.tileKey);
      expect(attr, isNotNull);
      if (pin.owningGpId != null) {
        expect(attr!.owningGpId, pin.owningGpId);
      }
      if (pin.sourceFactionId != null) {
        expect(attr!.sourceFactionId, pin.sourceFactionId);
      }
      if (pin.provinceId != null) {
        expect(attr!.provinceId, pin.provinceId);
      }
    }
  }
  if (expectation.attributionsTileKeysContainAll != null) {
    expect(index.attributions.map((a) => a.tileKey).toSet(), containsAll(expectation.attributionsTileKeysContainAll!));
  }
  if (expectation.deterministicIndexRerun) {
    final game = gameForDeterminismRerun;
    expect(game, isNotNull, reason: 'deterministicIndexRerun requires game');
    final first = PurchasedTileIndex.fromGame(game!);
    final second = PurchasedTileIndex.fromGame(game);
    expect(index.length, first.length);
    expect(first.length, second.length);
    if (expectation.deterministicRerunTileKey != null) {
      expect(first.attributionForTileKey(expectation.deterministicRerunTileKey!), equals(second.attributionForTileKey(expectation.deterministicRerunTileKey!)));
    }
  }
}
// dart format on
