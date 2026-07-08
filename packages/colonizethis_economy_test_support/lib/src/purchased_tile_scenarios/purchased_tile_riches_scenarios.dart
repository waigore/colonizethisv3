// Table-driven purchased-tile riches scenarios (Refs #3856, #3939 slice 17).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import '../extraction_fixture_support.dart';
import 'purchased_tile_expectations.dart';
import 'purchased_tile_riches_test_support.dart';

/// One row in [purchasedTileRichesScenarios].
class PurchasedTileRichesScenario {
  const PurchasedTileRichesScenario({
    required this.label,
    required this.buildGame,
    required this.tileMaps,
    required this.verify,
    this.richesCashMultiplier,
    this.refs,
  });

  PurchasedTileRichesScenario.expect({
    required String label,
    required Game Function() buildGame,
    required Map<String, TileMapResult> Function() tileMaps,
    required PurchasedTileRichesExpectation expect,
    double? richesCashMultiplier,
    String? refs,
  }) : this(
          label: label,
          buildGame: buildGame,
          tileMaps: tileMaps,
          richesCashMultiplier: richesCashMultiplier,
          verify: (result, index, game) =>
              assertPurchasedTileRichesExpectation(
            result,
            index,
            game,
            expect,
            tileMapByRegion: tileMaps(),
            richesCashMultiplier: richesCashMultiplier ?? 1.0,
          ),
          refs: refs,
        );

  final String label;
  final Game Function() buildGame;
  final Map<String, TileMapResult> Function() tileMaps;
  final double? richesCashMultiplier;
  final void Function(
    PurchasedTileRichesResult result,
    PurchasedTileIndex index,
    Game game,
  )
  verify;
  final String? refs;
}

/// Canonical scenarios for [computePurchasedTileRichesCredits].
List<PurchasedTileRichesScenario> purchasedTileRichesScenarios() => [
  PurchasedTileRichesScenario.expect(
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
    expect: PurchasedTileRichesExpectation(
      indexLength: 1,
      creditsLength: 1,
      singleCredit: PurchasedTileRichesCreditExpectation(
        tileKey: 'oldWorld|M1|0|0',
        owningGpId: 'gpA',
        sourceFactionId: 'M1',
        commodityId: 'gold',
        units: 1,
        treasuryDelta: richesBasePrice('gold'),
      ),
      treasuryCreditByGpId: {'gpA': richesBasePrice('gold')},
      totalTreasuryCredit: richesBasePrice('gold'),
    ),
    refs: '#2991 C5',
  ),
  PurchasedTileRichesScenario.expect(
    label:
        'multiplier is honoured: richesCashMultiplier=1.5 applies before truncation',
    buildGame: () => purchasedTileScenario(
      resource: Resource.spices,
      improvementLevel: 1,
      roadLevel: 1,
    ),
    tileMaps: () => tileMapByRegionForResource(Resource.spices),
    richesCashMultiplier: 1.5,
    expect: const PurchasedTileRichesExpectation(
      creditsLength: 1,
      singleCredit: PurchasedTileRichesCreditExpectation(
        treasuryDeltaCloseTo: 75,
      ),
      treasuryCreditCloseTo: {'gpA': 75},
    ),
    refs: null,
  ),
  PurchasedTileRichesScenario.expect(
    label:
        'AC purchased-tile riches handoff — non-riches resource: timber tile '
        'produces no credit (commodities flow through world market instead)',
    buildGame: () => purchasedTileScenario(
      resource: Resource.timber,
      improvementLevel: 1,
      roadLevel: 1,
    ),
    tileMaps: () => tileMapByRegionForResource(Resource.timber),
    expect: const PurchasedTileRichesExpectation(
      creditsEmpty: true,
      treasuryCreditEmpty: true,
      equalsEmpty: true,
    ),
    refs: '#2991 C5',
  ),
  PurchasedTileRichesScenario.expect(
    label:
        'AC purchased-tile riches handoff — unimproved tile: improvementLevel=0 '
        'produces no credit even when the resource is in the riches set',
    buildGame: () => purchasedTileScenario(
      resource: Resource.silver,
      improvementLevel: 0,
      roadLevel: 1,
    ),
    tileMaps: () => tileMapByRegionForResource(Resource.silver),
    expect: const PurchasedTileRichesExpectation(
      creditsEmpty: true,
      treasuryCreditEmpty: true,
    ),
    refs: '#2991 C5',
  ),
  PurchasedTileRichesScenario.expect(
    label: 'tile with no road and no port produces no credit (transport level 0 '
        'caps yield to 0)',
    buildGame: () => purchasedTileScenario(
      resource: Resource.gold,
      improvementLevel: 1,
      roadLevel: 0,
    ),
    tileMaps: () => tileMapByRegionForResource(Resource.gold),
    expect: const PurchasedTileRichesExpectation(
      creditsEmpty: true,
      treasuryCreditEmpty: true,
    ),
  ),
  PurchasedTileRichesScenario.expect(
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
    expect: PurchasedTileRichesExpectation(
      creditsLength: 1,
      singleCredit: PurchasedTileRichesCreditExpectation(
        units: 1,
        treasuryDeltaCloseTo: richesBasePrice('diamonds'),
      ),
    ),
  ),
  PurchasedTileRichesScenario.expect(
    label:
        'AC purchased-tile riches handoff — post-conquest filter: when the '
        'purchased province is now owned by a Great Power, no credit is '
        'emitted (the index filters it out at build time)',
    buildGame: postConquestPurchasedTileRichesGame,
    tileMaps: () => tileMapByRegionForResource(Resource.gold, province: 'P1'),
    expect: const PurchasedTileRichesExpectation(
      creditsEmpty: true,
      treasuryCreditEmpty: true,
    ),
    refs: '#2991 C5',
  ),
  PurchasedTileRichesScenario.expect(
    label: 'tribe-owned purchased tile producing spices credits the owning GP',
    buildGame: tribeOwnedPurchasedTileRichesGame,
    tileMaps: () => {
      'oldWorld': singleResourceTileMap(Resource.spices, province: 'T1'),
    },
    expect: PurchasedTileRichesExpectation(
      creditsLength: 1,
      singleCredit: PurchasedTileRichesCreditExpectation(
        sourceFactionId: 'T1',
        owningGpId: 'gpA',
        commodityId: 'spices',
        treasuryDeltaCloseTo: richesBasePrice('spices'),
      ),
    ),
  ),
  PurchasedTileRichesScenario.expect(
    label: 'multi-tile aggregation — distinct GPs each accrue their own credits',
    buildGame: multiGpPurchasedTileRichesGame,
    tileMaps: multiGpPurchasedTileRichesTileMaps,
    expect: PurchasedTileRichesExpectation(
      creditsLength: 2,
      treasuryCreditByGpId: {
        'gpA': richesBasePrice('gold'),
        'gpB': richesBasePrice('gems'),
      },
    ),
  ),
  PurchasedTileRichesScenario.expect(
    label: 'empty index returns empty result (no work done)',
    buildGame: TestFixtures.minimalGame,
    tileMaps: () => tileMapByRegionForResource(Resource.gold),
    expect: const PurchasedTileRichesExpectation(
      equalsEmpty: true,
      isEmpty: true,
    ),
  ),
  PurchasedTileRichesScenario.expect(
    label: 'empty tileMapByRegion returns empty result',
    buildGame: () => purchasedTileScenario(
      resource: Resource.gold,
      improvementLevel: 1,
      roadLevel: 1,
    ),
    tileMaps: () => const <String, TileMapResult>{},
    expect: const PurchasedTileRichesExpectation(
      creditsEmpty: true,
      treasuryCreditEmpty: true,
      equalsEmpty: true,
    ),
  ),
  PurchasedTileRichesScenario.expect(
    label: 'determinism — two calls with the same inputs return equal credits',
    buildGame: () => purchasedTileScenario(
      resource: Resource.gems,
      improvementLevel: 1,
      roadLevel: 1,
    ),
    tileMaps: () => tileMapByRegionForResource(Resource.gems),
    expect: const PurchasedTileRichesExpectation(
      deterministicRichesRerun: true,
    ),
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
