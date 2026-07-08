// SPEC-AC tests for `computeNonGreatPowerAutoOffers` purchased-tile parity —
// Issue #2991 C6.
//
// Anchors:
//   - `SPEC/game/world-market.md` § Minor and tribe auto-sell — acceptance
//     criteria *Purchased-tile non-riches auto-offer — emission* and
//     *Purchased-tile non-riches auto-offer — parity with unpurchased tiles*.
//   - `SPEC/game/world-market.md` § First right of refusal — *Riches handoff*
//     (purchased riches tiles route via `computePurchasedTileRichesCredits`
//     in phase 3, not the world market).
//
// C6 invariant: the minor/tribe auto-offer iteration treats purchased and
// unpurchased tiles identically. Purchased-tile attribution flows separately
// through `PurchasedTileIndex.fromGame` into the deal matcher's FRR routing
// (Refs #2992 D2/D4); the auto-offer emission contract is independent of
// purchased status.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group(
    'computeNonGreatPowerAutoOffers — purchased-tile parity (Refs #2991 C6)',
    () {
      test('purchased non-riches tile (timber) emits a priority-1 auto-offer '
          'keyed under the minor with originTileKey equal to the purchased '
          'tile key', () {
        const purchasedTileKey = 'oldWorld|m1|0|0';
        final game = minorTileAutoOfferGame(
          tileKey: purchasedTileKey,
          improvementLevel: 1,
          roadLevel: 1,
          purchasedTilesByTileKey: const {purchasedTileKey: 'gpA'},
        );

        final result = computeNonGreatPowerAutoOffers(
          game: game,
          tileMapByRegion: {
            'oldWorld': singleResourceTileMap(Resource.timber, province: 'm1'),
          },
          connectivityByFactionId: const {
            'm1': ConnectivityResult(connected: <String>{purchasedTileKey}),
          },
        );

        expect(result.keys, equals(<String>{'m1'}));
        final orders = result['m1']!;
        expect(orders, hasLength(1));
        final order = orders.single;
        expect(order.commodityId, equals('timber'));
        expect(order.type, equals(TradeOrderType.offer));
        expect(order.priority, equals(1));
        expect(order.quantity, equals(1));
        expect(order.originTileKey, equals(purchasedTileKey));
      });

      test(
        'purchased non-riches tile parity with unpurchased tile — both tiles '
        'emit auto-offers with identical quantity and priority; only '
        'originTileKey differs',
        () {
          const purchasedTileKey = 'oldWorld|m1|0|0';
          const unpurchasedTileKey = 'oldWorld|m1|1|0';
          final game = twoMinorTimberTilesAutoOfferGame(
            purchasedTileKey: purchasedTileKey,
            unpurchasedTileKey: unpurchasedTileKey,
          );

          final result = computeNonGreatPowerAutoOffers(
            game: game,
            tileMapByRegion: {
              'oldWorld': twoTileSameResourceMap(Resource.timber),
            },
            connectivityByFactionId: const {
              'm1': ConnectivityResult(
                connected: <String>{purchasedTileKey, unpurchasedTileKey},
              ),
            },
          );

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
      );

      test('PurchasedTileIndex.fromGame is built independently of auto-offer '
          "emission — the minor's auto-offer for a purchased timber tile "
          'carries the originTileKey that the index can map back to the '
          'owning GP for FRR routing', () {
        const purchasedTileKey = 'oldWorld|m1|0|0';
        final game = minorTileAutoOfferGame(
          tileKey: purchasedTileKey,
          improvementLevel: 1,
          roadLevel: 1,
          purchasedTilesByTileKey: const {purchasedTileKey: 'gpA'},
        );

        final autoOffers = computeNonGreatPowerAutoOffers(
          game: game,
          tileMapByRegion: {
            'oldWorld': singleResourceTileMap(Resource.timber, province: 'm1'),
          },
          connectivityByFactionId: const {
            'm1': ConnectivityResult(connected: <String>{purchasedTileKey}),
          },
        );
        final index = PurchasedTileIndex.fromGame(game);

        final order = autoOffers['m1']!.single;
        expect(order.originTileKey, equals(purchasedTileKey));
        final attribution = index.attributionForTileKey(order.originTileKey!);
        expect(attribution, isNotNull);
        expect(attribution!.owningGpId, equals('gpA'));
        expect(attribution.sourceFactionId, equals('m1'));
      });

      test('purchased gold tile (mineral riches) emits no auto-offer — riches '
          'handoff (C5) routes the yield to the owning GP treasury in '
          'phase 3 instead', () {
        const purchasedTileKey = 'oldWorld|m1|0|0';
        final game = minorTileAutoOfferGame(
          tileKey: purchasedTileKey,
          improvementLevel: 1,
          roadLevel: 1,
          purchasedTilesByTileKey: const {purchasedTileKey: 'gpA'},
        );

        final result = computeNonGreatPowerAutoOffers(
          game: game,
          tileMapByRegion: {'oldWorld': singleResourceTileMap(Resource.gold, province: 'm1')},
          connectivityByFactionId: const {
            'm1': ConnectivityResult(connected: <String>{purchasedTileKey}),
          },
        );

        expect(
          result,
          isEmpty,
          reason:
              'mineral riches are excluded from non-GP auto-offers '
              'regardless of purchased-tile status',
        );
      });

      test('purchased spices tile (non-mineral riches) emits no auto-offer — '
          'spices route through the riches handoff (C5) instead of the '
          'world market', () {
        const purchasedTileKey = 'oldWorld|m1|0|0';
        final game = minorTileAutoOfferGame(
          tileKey: purchasedTileKey,
          improvementLevel: 1,
          roadLevel: 1,
          purchasedTilesByTileKey: const {purchasedTileKey: 'gpA'},
        );

        final result = computeNonGreatPowerAutoOffers(
          game: game,
          tileMapByRegion: {
            'oldWorld': singleResourceTileMap(Resource.spices, province: 'm1'),
          },
          connectivityByFactionId: const {
            'm1': ConnectivityResult(connected: <String>{purchasedTileKey}),
          },
        );

        expect(
          result,
          isEmpty,
          reason:
              'spices is in richesCommodityIds and is filtered from '
              'non-GP auto-offers regardless of purchased-tile status',
        );
      });
    },
  );
}

