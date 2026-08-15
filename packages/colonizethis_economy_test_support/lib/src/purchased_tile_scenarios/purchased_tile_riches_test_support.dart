// dart format off
/// Shared fixtures for the `computePurchasedTileRichesCredits` unit tests
/// (Refs #2991 C5, #3823, #3856, #3939).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../purchased_tile_fixture_support.dart';
/// Post-conquest: province owned by `gpB`; purchased entry still maps to `gpA`.
Game postConquestPurchasedTileRichesGame() {
  const tileKey = 'oldWorld|P1|0|0';
  return gpProvincePurchasedTileGame(ownerGpId: 'gpB', tileState: improvedRoadedTileState(tileKey));
}
/// Tribe-owned purchased tile in `oldWorld|T1` purchased by `gpA`, improved
/// and roaded for riches yield.
Game tribeOwnedPurchasedTileRichesGame() {
  const tileKey = 'oldWorld|T1|0|0';
  return tribePurchasedTileGame(tribeDisplayName: 'Tribe 1', tileState: improvedRoadedTileState(tileKey));
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
    tileState: improvedRoadedTileState(tileA).setImprovement(tileB, 1).setRoadLevel(tileB, 1),
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
Game purchasedTileScenario({required Resource resource, required int improvementLevel, required int roadLevel, Map<String, String>? portsByProvinceSeaboard}) {
  const tileKey = 'oldWorld|M1|0|0';
  var tileState = const TileMapState();
  if (improvementLevel > 0) {
    tileState = tileState.setImprovement(tileKey, improvementLevel);
  }
  if (roadLevel > 0) {
    tileState = tileState.setRoadLevel(tileKey, roadLevel);
  }
  return minorPurchasedTileGame(minorDisplayName: 'Minor 1', tileState: tileState, portsByProvinceSeaboard: portsByProvinceSeaboard);
}
/// Data-driven expectations for [PurchasedTileRichesScenario] rows.
class PurchasedTileRichesExpectation {
  const PurchasedTileRichesExpectation({this.indexLength, this.creditsLength, this.creditsEmpty = false, this.treasuryCreditEmpty = false, this.equalsEmpty = false, this.isEmpty, this.singleCredit, this.treasuryCreditByGpId, this.treasuryCreditCloseTo, this.totalTreasuryCredit, this.totalTreasuryCreditCloseTo, this.deterministicRichesRerun = false});
  final int? indexLength;
  final int? creditsLength;
  final bool creditsEmpty;
  final bool treasuryCreditEmpty;
  final bool equalsEmpty;
  final bool? isEmpty;
  final PurchasedTileRichesCreditExpectation? singleCredit;
  final Map<String, int>? treasuryCreditByGpId;
  final Map<String, int>? treasuryCreditCloseTo;
  final int? totalTreasuryCredit;
  final int? totalTreasuryCreditCloseTo;
  final bool deterministicRichesRerun;
}
class PurchasedTileRichesCreditExpectation {
  const PurchasedTileRichesCreditExpectation({this.tileKey, this.owningGpId, this.sourceFactionId, this.commodityId, this.units, this.treasuryDelta, this.treasuryDeltaCloseTo});
  final String? tileKey;
  final String? owningGpId;
  final String? sourceFactionId;
  final String? commodityId;
  final int? units;
  final int? treasuryDelta;
  final int? treasuryDeltaCloseTo;
}
void assertPurchasedTileRichesExpectation(PurchasedTileRichesResult result, PurchasedTileIndex index, Game game, PurchasedTileRichesExpectation expectation, {Map<String, TileMapResult> tileMapByRegion = const {}, double richesCashMultiplier = 1.0}) {
  if (expectation.indexLength != null) {
    expect(index.length, expectation.indexLength);
  }
  if (expectation.creditsEmpty) {
    expect(result.credits, isEmpty);
  }
  if (expectation.treasuryCreditEmpty) {
    expect(result.treasuryCreditByGpId, isEmpty);
  }
  if (expectation.creditsLength != null) {
    expect(result.credits, hasLength(expectation.creditsLength));
  }
  if (expectation.equalsEmpty) {
    expect(result, equals(PurchasedTileRichesResult.empty));
  }
  if (expectation.isEmpty != null) {
    expect(result.isEmpty, expectation.isEmpty);
  }
  if (expectation.singleCredit != null) {
    final credit = result.credits.single;
    final pin = expectation.singleCredit!;
    if (pin.tileKey != null) {
      expect(credit.tileKey, equals(pin.tileKey));
    }
    if (pin.owningGpId != null) {
      expect(credit.owningGpId, equals(pin.owningGpId));
    }
    if (pin.sourceFactionId != null) {
      expect(credit.sourceFactionId, equals(pin.sourceFactionId));
    }
    if (pin.commodityId != null) {
      expect(credit.commodityId, equals(pin.commodityId));
    }
    if (pin.units != null) {
      expect(credit.units, equals(pin.units));
    }
    if (pin.treasuryDelta != null) {
      expect(credit.treasuryDelta, equals(pin.treasuryDelta));
    }
    if (pin.treasuryDeltaCloseTo != null) {
      expect(credit.treasuryDelta, equals(pin.treasuryDeltaCloseTo));
    }
  }
  if (expectation.treasuryCreditByGpId != null) {
    expect(result.treasuryCreditByGpId, equals(expectation.treasuryCreditByGpId));
  }
  if (expectation.treasuryCreditCloseTo != null) {
    for (final entry in expectation.treasuryCreditCloseTo!.entries) {
      expect(result.treasuryCreditByGpId[entry.key], equals(entry.value));
    }
  }
  if (expectation.totalTreasuryCredit != null) {
    expect(result.totalTreasuryCredit, equals(expectation.totalTreasuryCredit));
  }
  if (expectation.totalTreasuryCreditCloseTo != null) {
    expect(result.totalTreasuryCredit, equals(expectation.totalTreasuryCreditCloseTo));
  }
  if (expectation.deterministicRichesRerun) {
    final r2 = computePurchasedTileRichesCredits(game: game, tileMapByRegion: tileMapByRegion, purchasedTileIndex: index, richesCashMultiplier: richesCashMultiplier);
    expect(result.credits.length, equals(r2.credits.length));
    expect(result.totalTreasuryCredit, equals(r2.totalTreasuryCredit));
    expect(result.treasuryCreditByGpId, equals(r2.treasuryCreditByGpId));
  }
}
// dart format on
