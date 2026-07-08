// Table-driven non-GP auto-offer scenarios (Refs #3856).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'extraction_fixture_support.dart';
import 'non_gp_auto_offers_expectations.dart';
import 'non_gp_auto_offers_test_support.dart';
import 'scenario_runner.dart';

/// One row for `computeNonGreatPowerAutoOffers` scenario tables.
class NonGpAutoOffersScenario implements RefsScenario {
  const NonGpAutoOffersScenario({
    required this.label,
    required this.game,
    required this.tileMapByRegion,
    required this.connectivityByFactionId,
    required this.verify,
    this.refs,
  });

  NonGpAutoOffersScenario.expect({
    required String label,
    required Game game,
    required Map<String, TileMapResult> tileMapByRegion,
    required Map<String, ConnectivityResult> connectivityByFactionId,
    required NonGpAutoOffersExpectation expect,
    String? refs,
  }) : this(
          label: label,
          game: game,
          tileMapByRegion: tileMapByRegion,
          connectivityByFactionId: connectivityByFactionId,
          verify: (result) =>
              assertNonGpAutoOffersExpectation(result, expect, game: game),
          refs: refs,
        );

  final String label;
  final Game game;
  final Map<String, TileMapResult> tileMapByRegion;
  final Map<String, ConnectivityResult> connectivityByFactionId;
  final void Function(Map<String, List<TradeOrder>> result) verify;
  @override
  final String? refs;
}

void runNonGpAutoOffersScenario(NonGpAutoOffersScenario scenario) {
  final result = computeNonGreatPowerAutoOffers(
    game: scenario.game,
    tileMapByRegion: scenario.tileMapByRegion,
    connectivityByFactionId: scenario.connectivityByFactionId,
  );
  scenario.verify(result);
}

/// Canonical scenarios from `non_gp_auto_offers_test.dart` (Issue #2991 C4).
List<NonGpAutoOffersScenario> nonGpAutoOffersScenarios() => [
  ..._nonGpAutoOffersEmptyScenarios(),
  ..._nonGpAutoOffersOfferScenarios(),
  ..._nonGpAutoOffersPurchasedTileScenarios(),
];

List<NonGpAutoOffersScenario> _nonGpAutoOffersEmptyScenarios() => [
  NonGpAutoOffersScenario.expect(
    label: 'empty when no minors and no tribes are configured',
    game: gameForNonGpExtractionTest(provinces: const []),
    tileMapByRegion: const {},
    connectivityByFactionId: const {},
    expect: const NonGpAutoOffersExpectation(empty: true),
    refs: '#2991 C4',
  ),
  NonGpAutoOffersScenario.expect(
    label: 'empty when tileMapByRegion is empty',
    game: gameForNonGpExtractionTest(
      provinces: [
        capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1'),
      ],
      minorNations: [testMinor()],
    ),
    tileMapByRegion: const {},
    connectivityByFactionId: const {
      'm1': ConnectivityResult(connected: <String>{'oldWorld|m1|0|0'}),
    },
    expect: const NonGpAutoOffersExpectation(empty: true),
    refs: '#2991 C4',
  ),
  NonGpAutoOffersScenario.expect(
    label: 'factions with no connectivity entry do not appear in the auto-offer map',
    game: gameForNonGpExtractionTest(
      provinces: [
        capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1'),
      ],
      tileState: tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|m1|0|0', improvement: 1),
      ]),
      minorNations: [testMinor()],
    ),
    tileMapByRegion: {
      'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'oldWorld|m1',
        width: 1,
        height: 1,
        resources: const [
          [Resource.timber],
        ],
      ),
    },
    connectivityByFactionId: const {},
    expect: const NonGpAutoOffersExpectation(empty: true),
    refs: '#2991 C4',
  ),
];

List<NonGpAutoOffersScenario> _nonGpAutoOffersOfferScenarios() => [
  NonGpAutoOffersScenario.expect(
    label: 'emits one priority-1 offer per non-riches tile with originTileKey set',
    game: gameForNonGpExtractionTest(
      provinces: [
        capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1'),
      ],
      tileState: tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|m1|0|0', improvement: 1, roadLevel: 1),
        TileImprovementSpec('oldWorld|m1|1|0', improvement: 1, roadLevel: 1),
      ]),
      minorNations: [testMinor()],
    ),
    tileMapByRegion: {
      'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'oldWorld|m1',
        width: 2,
        height: 1,
        resources: const [
          [Resource.timber, Resource.grain],
        ],
      ),
    },
    connectivityByFactionId: const {
      'm1': ConnectivityResult(
        connected: <String>{'oldWorld|m1|0|0', 'oldWorld|m1|1|0'},
      ),
    },
    expect: const NonGpAutoOffersExpectation(
      factionKeys: {'m1'},
      offersByFaction: {
        'm1': FactionAutoOffersExpectation(
          length: 2,
          standardPriorityOneOffers: true,
          commodityIds: ['timber', 'grain'],
          originTileKeys: ['oldWorld|m1|0|0', 'oldWorld|m1|1|0'],
        ),
      },
    ),
    refs: '#2991 C4',
  ),
  NonGpAutoOffersScenario.expect(
    label: 'aggregates minor and tribe offers in the same result map',
    game: gameForNonGpExtractionTest(
      provinces: [
        capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1'),
      ],
      newWorldProvinces: [
        capitalProvinceForNonGpExtractionTest(provinceId: 'newWorld|t1'),
      ],
      tileState: tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|m1|0|0', improvement: 1, roadLevel: 1),
        TileImprovementSpec('newWorld|t1|0|0', improvement: 1, roadLevel: 1),
      ]),
      minorNations: [testMinor()],
      tribes: [testTribe()],
    ),
    tileMapByRegion: {
      'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'oldWorld|m1',
        width: 1,
        height: 1,
        resources: const [
          [Resource.timber],
        ],
      ),
      'newWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'newWorld|t1',
        width: 1,
        height: 1,
        resources: const [
          [Resource.furs],
        ],
      ),
    },
    connectivityByFactionId: const {
      'm1': ConnectivityResult(connected: <String>{'oldWorld|m1|0|0'}),
      't1': ConnectivityResult(connected: <String>{'newWorld|t1|0|0'}),
    },
    expect: const NonGpAutoOffersExpectation(
      factionKeysUnordered: ['m1', 't1'],
      offersByFaction: {
        'm1': FactionAutoOffersExpectation(
          length: 1,
          singleCommodityId: 'timber',
        ),
        't1': FactionAutoOffersExpectation(
          length: 1,
          singleCommodityId: 'furs',
        ),
      },
    ),
    refs: '#2991 C4',
  ),
  NonGpAutoOffersScenario.expect(
    label: 'excludes riches commodities (spices) per Requirement 11 — '
        'riches do not trade on the world market',
    game: gameForNonGpExtractionTest(
      provinces: [
        capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1'),
      ],
      tileState: tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|m1|0|0', improvement: 1, roadLevel: 1),
        TileImprovementSpec('oldWorld|m1|1|0', improvement: 1, roadLevel: 1),
      ]),
      minorNations: [testMinor()],
    ),
    tileMapByRegion: {
      'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'oldWorld|m1',
        width: 2,
        height: 1,
        resources: const [
          [Resource.spices, Resource.grain],
        ],
      ),
    },
    connectivityByFactionId: const {
      'm1': ConnectivityResult(
        connected: <String>{'oldWorld|m1|0|0', 'oldWorld|m1|1|0'},
      ),
    },
    expect: const NonGpAutoOffersExpectation(
      factionKeys: {'m1'},
      offersByFaction: {
        'm1': FactionAutoOffersExpectation(
          length: 1,
          singleCommodityId: 'grain',
          singleOriginTileKey: 'oldWorld|m1|1|0',
          excludeCommodity: 'spices',
        ),
      },
    ),
    refs: '#2991 C4',
  ),
  NonGpAutoOffersScenario.expect(
    label: 'minerals stay excluded (covered by computeNonGreatPowerExtraction '
        'mineral filter) — no offer emitted for an iron tile even if developed',
    game: gameForNonGpExtractionTest(
      provinces: [
        capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1'),
      ],
      tileState: tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|m1|0|0', improvement: 1, roadLevel: 1),
        TileImprovementSpec('oldWorld|m1|1|0', improvement: 1, roadLevel: 1),
      ]),
      minorNations: [testMinor()],
    ),
    tileMapByRegion: {
      'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'oldWorld|m1',
        width: 2,
        height: 1,
        resources: const [
          [Resource.iron, Resource.grain],
        ],
      ),
    },
    connectivityByFactionId: const {
      'm1': ConnectivityResult(
        connected: <String>{'oldWorld|m1|0|0', 'oldWorld|m1|1|0'},
      ),
    },
    expect: const NonGpAutoOffersExpectation(
      offersByFaction: {
        'm1': FactionAutoOffersExpectation(
          length: 1,
          singleCommodityId: 'grain',
        ),
      },
    ),
    refs: '#2991 C4',
  ),
];

/// Purchased-tile parity scenarios (Refs #2991 C6, #3939).
List<NonGpAutoOffersScenario> _nonGpAutoOffersPurchasedTileScenarios() {
  const purchasedTileKey = 'oldWorld|m1|0|0';
  const unpurchasedTileKey = 'oldWorld|m1|1|0';

  return [
    NonGpAutoOffersScenario.expect(
      label: 'purchased non-riches tile (timber) emits a priority-1 auto-offer '
          'keyed under the minor with originTileKey equal to the purchased '
          'tile key',
      game: minorTileAutoOfferGame(
        tileKey: purchasedTileKey,
        improvementLevel: 1,
        roadLevel: 1,
        purchasedTilesByTileKey: const {purchasedTileKey: 'gpA'},
      ),
      tileMapByRegion: {
        'oldWorld': singleResourceTileMap(Resource.timber, province: 'm1'),
      },
      connectivityByFactionId: const {
        'm1': ConnectivityResult(connected: <String>{purchasedTileKey}),
      },
      expect: const NonGpAutoOffersExpectation(
        factionKeys: {'m1'},
        offersByFaction: {
          'm1': FactionAutoOffersExpectation(
            length: 1,
            standardPriorityOneOffers: true,
            singleCommodityId: 'timber',
            singleOriginTileKey: purchasedTileKey,
          ),
        },
      ),
      refs: '#2991 C6',
    ),
    NonGpAutoOffersScenario.expect(
      label: 'purchased non-riches tile parity with unpurchased tile — both tiles '
          'emit auto-offers with identical quantity and priority; only '
          'originTileKey differs',
      game: twoMinorTimberTilesAutoOfferGame(
        purchasedTileKey: purchasedTileKey,
        unpurchasedTileKey: unpurchasedTileKey,
      ),
      tileMapByRegion: {
        'oldWorld': twoTileSameResourceMap(Resource.timber),
      },
      connectivityByFactionId: const {
        'm1': ConnectivityResult(
          connected: <String>{purchasedTileKey, unpurchasedTileKey},
        ),
      },
      expect: const NonGpAutoOffersExpectation(
        offersByFaction: {
          'm1': FactionAutoOffersExpectation(
            length: 2,
            standardPriorityOneOffers: true,
            commodityIds: ['timber', 'timber'],
            originTileKeys: [purchasedTileKey, unpurchasedTileKey],
          ),
        },
      ),
      refs: '#2991 C6',
    ),
    NonGpAutoOffersScenario.expect(
      label: 'PurchasedTileIndex.fromGame is built independently of auto-offer '
          "emission — the minor's auto-offer for a purchased timber tile "
          'carries the originTileKey that the index can map back to the '
          'owning GP for FRR routing',
      game: minorTileAutoOfferGame(
        tileKey: purchasedTileKey,
        improvementLevel: 1,
        roadLevel: 1,
        purchasedTilesByTileKey: const {purchasedTileKey: 'gpA'},
      ),
      tileMapByRegion: {
        'oldWorld': singleResourceTileMap(Resource.timber, province: 'm1'),
      },
      connectivityByFactionId: const {
        'm1': ConnectivityResult(connected: <String>{purchasedTileKey}),
      },
      expect: const NonGpAutoOffersExpectation(
        purchasedTileFrrAttribution: PurchasedTileFrrAttributionExpectation(
          factionId: 'm1',
          owningGpId: 'gpA',
          sourceFactionId: 'm1',
        ),
      ),
      refs: '#2991 C6',
    ),
    NonGpAutoOffersScenario.expect(
      label: 'purchased gold tile (mineral riches) emits no auto-offer — riches '
          'handoff (C5) routes the yield to the owning GP treasury in '
          'phase 3 instead',
      game: minorTileAutoOfferGame(
        tileKey: purchasedTileKey,
        improvementLevel: 1,
        roadLevel: 1,
        purchasedTilesByTileKey: const {purchasedTileKey: 'gpA'},
      ),
      tileMapByRegion: {
        'oldWorld': singleResourceTileMap(Resource.gold, province: 'm1'),
      },
      connectivityByFactionId: const {
        'm1': ConnectivityResult(connected: <String>{purchasedTileKey}),
      },
      expect: const NonGpAutoOffersExpectation(empty: true),
      refs: '#2991 C6',
    ),
    NonGpAutoOffersScenario.expect(
      label: 'purchased spices tile (non-mineral riches) emits no auto-offer — '
          'spices route through the riches handoff (C5) instead of the '
          'world market',
      game: minorTileAutoOfferGame(
        tileKey: purchasedTileKey,
        improvementLevel: 1,
        roadLevel: 1,
        purchasedTilesByTileKey: const {purchasedTileKey: 'gpA'},
      ),
      tileMapByRegion: {
        'oldWorld': singleResourceTileMap(Resource.spices, province: 'm1'),
      },
      connectivityByFactionId: const {
        'm1': ConnectivityResult(connected: <String>{purchasedTileKey}),
      },
      expect: const NonGpAutoOffersExpectation(empty: true),
      refs: '#2991 C6',
    ),
  ];
}

/// Back-compat alias for purchased-tile C6 rows (Refs #3939).
List<NonGpAutoOffersScenario> nonGpAutoOffersPurchasedTileScenarios() =>
    _nonGpAutoOffersPurchasedTileScenarios();
