// Table-driven non-GP auto-offer scenarios (Refs #3856).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'extraction_fixture_support.dart';
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
  NonGpAutoOffersScenario(
    label: 'empty when no minors and no tribes are configured',
    game: gameForNonGpExtractionTest(provinces: const []),
    tileMapByRegion: const {},
    connectivityByFactionId: const {},
    verify: (result) => expect(result, isEmpty),
    refs: '#2991 C4',
  ),
  NonGpAutoOffersScenario(
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
    verify: (result) => expect(result, isEmpty),
    refs: '#2991 C4',
  ),
  NonGpAutoOffersScenario(
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
    verify: (result) => expect(result, isEmpty),
    refs: '#2991 C4',
  ),
];

List<NonGpAutoOffersScenario> _nonGpAutoOffersOfferScenarios() => [
  NonGpAutoOffersScenario(
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
    verify: (result) {
      expect(result.keys, equals(<String>{'m1'}));
      final orders = result['m1']!;
      expect(orders, hasLength(2));
      for (final order in orders) {
        expect(order.type, equals(TradeOrderType.offer));
        expect(order.priority, equals(1));
        expect(order.quantity, equals(1));
        expect(order.originTileKey, isNotNull);
        expect(order.isFtp, isFalse);
      }
      expect(
        orders.map((o) => o.originTileKey).toList(),
        equals(<String>['oldWorld|m1|0|0', 'oldWorld|m1|1|0']),
      );
      expect(
        orders.map((o) => o.commodityId).toList(),
        equals(<CommodityId>['timber', 'grain']),
      );
    },
    refs: '#2991 C4',
  ),
  NonGpAutoOffersScenario(
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
    verify: (result) {
      expect(result.keys, unorderedEquals(<String>['m1', 't1']));
      expect(result['m1'], hasLength(1));
      expect(result['t1'], hasLength(1));
      expect(result['m1']!.first.commodityId, equals('timber'));
      expect(result['t1']!.first.commodityId, equals('furs'));
    },
    refs: '#2991 C4',
  ),
  NonGpAutoOffersScenario(
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
    verify: (result) {
      expect(result.keys, equals(<String>{'m1'}));
      final orders = result['m1']!;
      expect(orders, hasLength(1));
      expect(orders.first.commodityId, equals('grain'));
      expect(orders.first.originTileKey, equals('oldWorld|m1|1|0'));
      for (final order in orders) {
        expect(order.commodityId, isNot(equals('spices')));
      }
    },
    refs: '#2991 C4',
  ),
  NonGpAutoOffersScenario(
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
    verify: (result) {
      expect(result['m1'], hasLength(1));
      expect(result['m1']!.first.commodityId, equals('grain'));
    },
    refs: '#2991 C4',
  ),
];

/// Purchased-tile parity scenarios (Refs #2991 C6, #3939).
List<NonGpAutoOffersScenario> _nonGpAutoOffersPurchasedTileScenarios() {
  const purchasedTileKey = 'oldWorld|m1|0|0';
  const unpurchasedTileKey = 'oldWorld|m1|1|0';

  return [
    NonGpAutoOffersScenario(
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
      verify: (result) {
        expect(result.keys, equals(<String>{'m1'}));
        final orders = result['m1']!;
        expect(orders, hasLength(1));
        final order = orders.single;
        expect(order.commodityId, equals('timber'));
        expect(order.type, equals(TradeOrderType.offer));
        expect(order.priority, equals(1));
        expect(order.quantity, equals(1));
        expect(order.originTileKey, equals(purchasedTileKey));
      },
      refs: '#2991 C6',
    ),
    NonGpAutoOffersScenario(
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
      verify: (result) {
        final orders = result['m1']!;
        expect(orders, hasLength(2));
        for (final order in orders) {
          expect(order.commodityId, equals('timber'));
          expect(order.type, equals(TradeOrderType.offer));
          expect(order.priority, equals(1));
          expect(order.quantity, equals(1));
        }
        expect(
          orders.map((o) => o.originTileKey).toList(),
          equals(<String>[purchasedTileKey, unpurchasedTileKey]),
          reason:
              'tiles are emitted in ascending tileKey order; purchased '
              'status does not affect ordering or eligibility',
        );
      },
      refs: '#2991 C6',
    ),
    () {
      final game = minorTileAutoOfferGame(
        tileKey: purchasedTileKey,
        improvementLevel: 1,
        roadLevel: 1,
        purchasedTilesByTileKey: const {purchasedTileKey: 'gpA'},
      );
      return NonGpAutoOffersScenario(
        label: 'PurchasedTileIndex.fromGame is built independently of auto-offer '
            "emission — the minor's auto-offer for a purchased timber tile "
            'carries the originTileKey that the index can map back to the '
            'owning GP for FRR routing',
        game: game,
        tileMapByRegion: {
          'oldWorld': singleResourceTileMap(Resource.timber, province: 'm1'),
        },
        connectivityByFactionId: const {
          'm1': ConnectivityResult(connected: <String>{purchasedTileKey}),
        },
        verify: (result) {
          final index = PurchasedTileIndex.fromGame(game);

          final order = result['m1']!.single;
          expect(order.originTileKey, equals(purchasedTileKey));
          final attribution = index.attributionForTileKey(order.originTileKey!);
          expect(attribution, isNotNull);
          expect(attribution!.owningGpId, equals('gpA'));
          expect(attribution.sourceFactionId, equals('m1'));
        },
        refs: '#2991 C6',
      );
    }(),
    NonGpAutoOffersScenario(
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
      verify: (result) {
        expect(
          result,
          isEmpty,
          reason:
              'mineral riches are excluded from non-GP auto-offers '
              'regardless of purchased-tile status',
        );
      },
      refs: '#2991 C6',
    ),
    NonGpAutoOffersScenario(
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
      verify: (result) {
        expect(
          result,
          isEmpty,
          reason:
              'spices is in richesCommodityIds and is filtered from '
              'non-GP auto-offers regardless of purchased-tile status',
        );
      },
      refs: '#2991 C6',
    ),
  ];
}

/// Back-compat alias for purchased-tile C6 rows (Refs #3939).
List<NonGpAutoOffersScenario> nonGpAutoOffersPurchasedTileScenarios() =>
    _nonGpAutoOffersPurchasedTileScenarios();
