// dart format off
// Table-driven purchased-tile riches scenarios (Refs #3856, #3939 slice 17+48).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import '../extraction_fixture_support.dart';
import 'purchased_tile_expectations.dart';
import 'purchased_tile_riches_test_support.dart';

/// One row in [purchasedTileRichesScenarios].
typedef PurchasedTileRichesScenario = ({String label, Game Function() buildGame, Map<String, TileMapResult> Function() tileMaps, double? richesCashMultiplier, void Function(PurchasedTileRichesResult result, PurchasedTileIndex index, Game game) verify, String? refs});

/// Compact purchased-tile riches row (Refs #3939 slice 48 / 59).
PurchasedTileRichesScenario purchasedTileRichesRow({required String label, required PurchasedTileRichesExpectation expect, Resource? resource, int improvementLevel = 1, int roadLevel = 1, Game Function()? buildGame, Map<String, TileMapResult> Function()? tileMaps, double? richesCashMultiplier, Map<String, String>? portsByProvinceSeaboard, String? refs}) {
  final resolvedResource = resource ?? Resource.gold;
  final Game Function() resolvedBuild = buildGame ?? () => purchasedTileScenario(resource: resolvedResource, improvementLevel: improvementLevel, roadLevel: roadLevel, portsByProvinceSeaboard: portsByProvinceSeaboard);
  final Map<String, TileMapResult> Function() resolvedMaps = tileMaps ?? () => tileMapByRegionForResource(resolvedResource);
  return (label: label, buildGame: resolvedBuild, tileMaps: resolvedMaps, richesCashMultiplier: richesCashMultiplier, verify: (result, index, game) => assertPurchasedTileRichesExpectation(result, index, game, expect, tileMapByRegion: resolvedMaps(), richesCashMultiplier: richesCashMultiplier ?? 1.0), refs: refs);
}

/// Canonical scenarios for [computePurchasedTileRichesCredits].
List<PurchasedTileRichesScenario> purchasedTileRichesScenarios() => [
  purchasedTileRichesRow(
    label:
        'AC purchased-tile riches handoff — credit: improved gold tile in '
        'minor province credits owning GP at improvementLevel × basePrice × '
        'multiplier',
    resource: Resource.gold,
    expect: PurchasedTileRichesExpectation(
      indexLength: 1,
      creditsLength: 1,
      singleCredit: PurchasedTileRichesCreditExpectation(tileKey: 'oldWorld|M1|0|0', owningGpId: 'gpA', sourceFactionId: 'M1', commodityId: 'gold', units: 1, treasuryDelta: richesBasePrice('gold')),
      treasuryCreditByGpId: {'gpA': richesBasePrice('gold')},
      totalTreasuryCredit: richesBasePrice('gold'),
    ),
    refs: '#2991 C5',
  ),
  purchasedTileRichesRow(
    label: 'multiplier is honoured: richesCashMultiplier=1.5 applies before truncation',
    resource: Resource.spices,
    richesCashMultiplier: 1.5,
    expect: const PurchasedTileRichesExpectation(creditsLength: 1, singleCredit: PurchasedTileRichesCreditExpectation(treasuryDeltaCloseTo: 75), treasuryCreditCloseTo: {'gpA': 75}),
  ),
  purchasedTileRichesRow(
    label:
        'AC purchased-tile riches handoff — non-riches resource: timber tile '
        'produces no credit (commodities flow through world market instead)',
    resource: Resource.timber,
    expect: const PurchasedTileRichesExpectation(creditsEmpty: true, treasuryCreditEmpty: true, equalsEmpty: true),
    refs: '#2991 C5',
  ),
  purchasedTileRichesRow(
    label:
        'AC purchased-tile riches handoff — unimproved tile: improvementLevel=0 '
        'produces no credit even when the resource is in the riches set',
    resource: Resource.silver,
    improvementLevel: 0,
    expect: const PurchasedTileRichesExpectation(creditsEmpty: true, treasuryCreditEmpty: true),
    refs: '#2991 C5',
  ),
  purchasedTileRichesRow(
    label:
        'tile with no road and no port produces no credit (transport level 0 '
        'caps yield to 0)',
    roadLevel: 0,
    expect: const PurchasedTileRichesExpectation(creditsEmpty: true, treasuryCreditEmpty: true),
  ),
  purchasedTileRichesRow(
    label: 'port-flagged tile yields even without road (port = transport 4)',
    resource: Resource.diamonds,
    roadLevel: 0,
    portsByProvinceSeaboard: const {'oldWorld|M1|north': 'oldWorld|M1|0|0'},
    expect: PurchasedTileRichesExpectation(creditsLength: 1, singleCredit: PurchasedTileRichesCreditExpectation(units: 1, treasuryDeltaCloseTo: richesBasePrice('diamonds'))),
  ),
  purchasedTileRichesRow(
    label:
        'AC purchased-tile riches handoff — post-conquest filter: when the '
        'purchased province is now owned by a Great Power, no credit is '
        'emitted (the index filters it out at build time)',
    buildGame: postConquestPurchasedTileRichesGame,
    tileMaps: () => tileMapByRegionForResource(Resource.gold, province: 'P1'),
    expect: const PurchasedTileRichesExpectation(creditsEmpty: true, treasuryCreditEmpty: true),
    refs: '#2991 C5',
  ),
  purchasedTileRichesRow(
    label: 'tribe-owned purchased tile producing spices credits the owning GP',
    buildGame: tribeOwnedPurchasedTileRichesGame,
    tileMaps: () => {'oldWorld': singleTileMap(Resource.spices, province: 'T1')},
    expect: PurchasedTileRichesExpectation(
      creditsLength: 1,
      singleCredit: PurchasedTileRichesCreditExpectation(sourceFactionId: 'T1', owningGpId: 'gpA', commodityId: 'spices', treasuryDeltaCloseTo: richesBasePrice('spices')),
    ),
  ),
  purchasedTileRichesRow(
    label: 'multi-tile aggregation — distinct GPs each accrue their own credits',
    buildGame: multiGpPurchasedTileRichesGame,
    tileMaps: multiGpPurchasedTileRichesTileMaps,
    expect: PurchasedTileRichesExpectation(creditsLength: 2, treasuryCreditByGpId: {'gpA': richesBasePrice('gold'), 'gpB': richesBasePrice('gems')}),
  ),
  purchasedTileRichesRow(label: 'empty index returns empty result (no work done)', buildGame: TestFixtures.minimalGame, expect: const PurchasedTileRichesExpectation(equalsEmpty: true, isEmpty: true)),
  purchasedTileRichesRow(label: 'empty tileMapByRegion returns empty result', tileMaps: () => const <String, TileMapResult>{}, expect: const PurchasedTileRichesExpectation(creditsEmpty: true, treasuryCreditEmpty: true, equalsEmpty: true)),
  purchasedTileRichesRow(label: 'determinism — two calls with the same inputs return equal credits', resource: Resource.gems, expect: const PurchasedTileRichesExpectation(deterministicRichesRerun: true)),
];

/// Runs [scenario] through [computePurchasedTileRichesCredits].
PurchasedTileRichesResult runPurchasedTileRichesScenario(PurchasedTileRichesScenario scenario) {
  final game = scenario.buildGame();
  final index = PurchasedTileIndex.fromGame(game);
  return computePurchasedTileRichesCredits(game: game, tileMapByRegion: scenario.tileMaps(), purchasedTileIndex: index, richesCashMultiplier: scenario.richesCashMultiplier ?? 1.0);
}
// dart format on
