// Table-driven purchased-tile riches scenarios (Refs #3856).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import 'purchased_tile_riches_test_support.dart';
import 'tile_map_test_support.dart';

/// One row in [purchasedTileRichesScenarios].
typedef PurchasedTileRichesScenario = ({
  String label,
  Game Function() buildGame,
  Map<String, TileMapResult> Function() tileMaps,
  double? richesCashMultiplier,
  void Function(
    PurchasedTileRichesResult result,
    PurchasedTileIndex index,
    Game game,
  )
  verify,
  String? refs,
});

/// Canonical scenarios for [computePurchasedTileRichesCredits].
List<PurchasedTileRichesScenario> purchasedTileRichesScenarios() => [
  (
    label:
        'AC purchased-tile riches handoff — credit: improved gold tile in '
        'minor province credits owning GP at improvementLevel × basePrice × '
        'multiplier',
    buildGame: () => purchasedTileScenario(
      resource: Resource.gold,
      improvementLevel: 1,
      roadLevel: 1,
    ),
    tileMaps: () => tileMapByRegionForResource(Resource.gold),
    richesCashMultiplier: null,
    verify: _verifyGoldCreditAc,
    refs: '#2991 C5',
  ),
  (
    label:
        'multiplier is honoured: richesCashMultiplier=1.5 applies before truncation',
    buildGame: () => purchasedTileScenario(
      resource: Resource.spices,
      improvementLevel: 1,
      roadLevel: 1,
    ),
    tileMaps: () => tileMapByRegionForResource(Resource.spices),
    richesCashMultiplier: 1.5,
    verify: _verifyMultiplierHonoured,
    refs: null,
  ),
  (
    label:
        'AC purchased-tile riches handoff — non-riches resource: timber tile '
        'produces no credit (commodities flow through world market instead)',
    buildGame: () => purchasedTileScenario(
      resource: Resource.timber,
      improvementLevel: 1,
      roadLevel: 1,
    ),
    tileMaps: () => tileMapByRegionForResource(Resource.timber),
    richesCashMultiplier: null,
    verify: _verifyEmptyResult,
    refs: '#2991 C5',
  ),
  (
    label:
        'AC purchased-tile riches handoff — unimproved tile: improvementLevel=0 '
        'produces no credit even when the resource is in the riches set',
    buildGame: () => purchasedTileScenario(
      resource: Resource.silver,
      improvementLevel: 0,
      roadLevel: 1,
    ),
    tileMaps: () => tileMapByRegionForResource(Resource.silver),
    richesCashMultiplier: null,
    verify: _verifyUnimprovedEmpty,
    refs: '#2991 C5',
  ),
  (
    label: 'tile with no road and no port produces no credit (transport level 0 '
        'caps yield to 0)',
    buildGame: () => purchasedTileScenario(
      resource: Resource.gold,
      improvementLevel: 1,
      roadLevel: 0,
    ),
    tileMaps: () => tileMapByRegionForResource(Resource.gold),
    richesCashMultiplier: null,
    verify: _verifyUnimprovedEmpty,
    refs: null,
  ),
  (
    label: 'port-flagged tile yields even without road (port = transport 4)',
    buildGame: () {
      const tileKey = 'oldWorld|M1|0|0';
      return purchasedTileScenario(
        resource: Resource.diamonds,
        improvementLevel: 1,
        roadLevel: 0,
        portsByProvinceSeaboard: const {'oldWorld|M1|north': tileKey},
      );
    },
    tileMaps: () => tileMapByRegionForResource(Resource.diamonds),
    richesCashMultiplier: null,
    verify: _verifyPortFlaggedYield,
    refs: null,
  ),
  (
    label:
        'AC purchased-tile riches handoff — post-conquest filter: when the '
        'purchased province is now owned by a Great Power, no credit is '
        'emitted (the index filters it out at build time)',
    buildGame: postConquestPurchasedTileRichesGame,
    tileMaps: () => tileMapByRegionForResource(Resource.gold, province: 'P1'),
    richesCashMultiplier: null,
    verify: _verifyUnimprovedEmpty,
    refs: '#2991 C5',
  ),
  (
    label: 'tribe-owned purchased tile producing spices credits the owning GP',
    buildGame: tribeOwnedPurchasedTileRichesGame,
    tileMaps: () => {
      'oldWorld': singleResourceTileMap(Resource.spices, province: 'T1'),
    },
    richesCashMultiplier: null,
    verify: _verifyTribeSpicesCredit,
    refs: null,
  ),
  (
    label: 'multi-tile aggregation — distinct GPs each accrue their own credits',
    buildGame: multiGpPurchasedTileRichesGame,
    tileMaps: multiGpPurchasedTileRichesTileMaps,
    richesCashMultiplier: null,
    verify: _verifyMultiGpAggregation,
    refs: null,
  ),
  (
    label: 'empty index returns empty result (no work done)',
    buildGame: TestFixtures.minimalGame,
    tileMaps: () => tileMapByRegionForResource(Resource.gold),
    richesCashMultiplier: null,
    verify: _verifyEmptyIndex,
    refs: null,
  ),
  (
    label: 'empty tileMapByRegion returns empty result',
    buildGame: () => purchasedTileScenario(
      resource: Resource.gold,
      improvementLevel: 1,
      roadLevel: 1,
    ),
    tileMaps: () => const <String, TileMapResult>{},
    richesCashMultiplier: null,
    verify: _verifyEmptyResult,
    refs: null,
  ),
  (
    label: 'determinism — two calls with the same inputs return equal credits',
    buildGame: () => purchasedTileScenario(
      resource: Resource.gems,
      improvementLevel: 1,
      roadLevel: 1,
    ),
    tileMaps: () => tileMapByRegionForResource(Resource.gems),
    richesCashMultiplier: null,
    verify: _verifyDeterminism,
    refs: null,
  ),
];

/// Runs [scenario] through [computePurchasedTileRichesCredits].
PurchasedTileRichesResult runPurchasedTileRichesScenario(
  PurchasedTileRichesScenario scenario,
) {
  final game = scenario.buildGame();
  final index = PurchasedTileIndex.fromGame(game);
  return computePurchasedTileRichesCredits(
    game: game,
    tileMapByRegion: scenario.tileMaps(),
    purchasedTileIndex: index,
    richesCashMultiplier: scenario.richesCashMultiplier ?? 1.0,
  );
}

void _verifyGoldCreditAc(
  PurchasedTileRichesResult result,
  PurchasedTileIndex index,
  Game game,
) {
  expect(index.length, 1);
  expect(result.credits, hasLength(1));
  final credit = result.credits.single;
  expect(credit.tileKey, equals('oldWorld|M1|0|0'));
  expect(credit.owningGpId, equals('gpA'));
  expect(credit.sourceFactionId, equals('M1'));
  expect(credit.commodityId, equals('gold'));
  expect(credit.units, equals(1));
  expect(
    credit.treasuryDelta,
    equals(richesBasePrice('gold')),
    reason: 'units=1 × basePrice × multiplier=1.0 truncates to basePrice',
  );
  expect(
    result.treasuryCreditByGpId,
    equals({'gpA': richesBasePrice('gold')}),
  );
  expect(result.totalTreasuryCredit, equals(richesBasePrice('gold')));
}

void _verifyMultiplierHonoured(
  PurchasedTileRichesResult result,
  PurchasedTileIndex index,
  Game game,
) {
  expect(result.credits, hasLength(1));
  expect(result.credits.single.treasuryDelta, equals(75));
  expect(result.treasuryCreditByGpId['gpA'], equals(75));
}

void _verifyEmptyResult(
  PurchasedTileRichesResult result,
  PurchasedTileIndex index,
  Game game,
) {
  expect(result.credits, isEmpty);
  expect(result.treasuryCreditByGpId, isEmpty);
  expect(result, equals(PurchasedTileRichesResult.empty));
}

void _verifyUnimprovedEmpty(
  PurchasedTileRichesResult result,
  PurchasedTileIndex index,
  Game game,
) {
  expect(result.credits, isEmpty);
  expect(result.treasuryCreditByGpId, isEmpty);
}

void _verifyPortFlaggedYield(
  PurchasedTileRichesResult result,
  PurchasedTileIndex index,
  Game game,
) {
  expect(result.credits, hasLength(1));
  expect(result.credits.single.units, equals(1));
  expect(
    result.credits.single.treasuryDelta,
    equals(richesBasePrice('diamonds')),
  );
}

void _verifyTribeSpicesCredit(
  PurchasedTileRichesResult result,
  PurchasedTileIndex index,
  Game game,
) {
  expect(result.credits, hasLength(1));
  final credit = result.credits.single;
  expect(credit.sourceFactionId, equals('T1'));
  expect(credit.owningGpId, equals('gpA'));
  expect(credit.commodityId, equals('spices'));
  expect(credit.treasuryDelta, equals(richesBasePrice('spices')));
}

void _verifyMultiGpAggregation(
  PurchasedTileRichesResult result,
  PurchasedTileIndex index,
  Game game,
) {
  expect(result.credits, hasLength(2));
  expect(
    result.treasuryCreditByGpId.keys.toSet(),
    equals({'gpA', 'gpB'}),
  );
  expect(
    result.treasuryCreditByGpId['gpA'],
    equals(richesBasePrice('gold')),
  );
  expect(
    result.treasuryCreditByGpId['gpB'],
    equals(richesBasePrice('gems')),
  );
}

void _verifyEmptyIndex(
  PurchasedTileRichesResult result,
  PurchasedTileIndex index,
  Game game,
) {
  expect(result, equals(PurchasedTileRichesResult.empty));
  expect(result.isEmpty, isTrue);
}

void _verifyDeterminism(
  PurchasedTileRichesResult result,
  PurchasedTileIndex index,
  Game game,
) {
  final tileMaps = tileMapByRegionForResource(Resource.gems);
  final r2 = computePurchasedTileRichesCredits(
    game: game,
    tileMapByRegion: tileMaps,
    purchasedTileIndex: index,
  );
  expect(result.credits.length, equals(r2.credits.length));
  expect(result.totalTreasuryCredit, equals(r2.totalTreasuryCredit));
  expect(result.treasuryCreditByGpId, equals(r2.treasuryCreditByGpId));
}
