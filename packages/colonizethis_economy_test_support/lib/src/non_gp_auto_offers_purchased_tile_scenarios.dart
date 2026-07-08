// Table-driven purchased-tile auto-offer parity scenarios (Refs #2991 C6, #3939).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'non_gp_auto_offers_scenarios.dart';
import 'non_gp_auto_offers_test_support.dart';
import 'tile_map_test_support.dart';

/// Canonical scenarios from `non_gp_auto_offers_purchased_tile_test.dart`.
List<NonGpAutoOffersScenario> nonGpAutoOffersPurchasedTileScenarios() {
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
