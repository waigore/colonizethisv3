// Topic-split case module (Refs #3997 Phase 8).
// Pin/row coverage preserved 1:1 from the former combined cases file.

// Supply / retention / offer-side regiment build-input cases (Refs #3941).
//
// Transcribed 1:1 from the former `treasury_planner_regiment_input_{market_
// supply,retention,feedstock}_test.dart` shards.

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_planner_regiment_input_support.dart';


void registerTreasuryRegimentInputMarketSupplyCases() {
  group('lock-recovery regiment build-input market supply (Refs #2847 H8-supply market)',
      () {
    final threshold = regimentInputThreshold();

    test(
      'recovered lock-recovery seller missing wool bids wool before fabric',
      () {
        final game = twoGpRegimentInputGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          sellerFabricHeld: 0,
          sellerWoolHeld: 0,
          supplierWoolHeld: 20,
        );
        final orders = runRegimentInputTreasuryPlanner(
          game,
          playerId: kRegimentInputSellerId,
        );
        expect(
          regimentInputBidsFor(orders, kRegimentInputWoolId),
          isNotEmpty,
        );
        expect(
          regimentInputBidsFor(orders, kRegimentInputFabricId),
          isEmpty,
        );
      },
    );

    test(
      'affluent non-seller offers surplus wool while a lock-recovery seller '
      'still needs the bootstrap path',
      () {
        final game = twoGpRegimentInputGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          sellerFabricHeld: 0,
          sellerWoolHeld: 0,
          supplierWoolHeld: 20,
        );
        expect(
          regimentInputOffersFor(
            runRegimentInputTreasuryPlanner(
              game,
              playerId: kRegimentInputSupplierId,
            ),
            kRegimentInputWoolId,
          ),
          isNotEmpty,
          reason:
              'An affluent GP must release wool offers so the seller feedstock '
              'bid can clear.',
        );
      },
    );

    test(
      'affluent non-seller keeps normal wool buffer when no lock-recovery seller '
      'needs the bootstrap path',
      () {
        final game = twoGpRegimentInputGame(
          sellerTreasury: threshold - 1,
          supplierTreasury: threshold,
          sellerFabricHeld: 0,
          sellerWoolHeld: 0,
          supplierWoolHeld: 4,
        );
        expect(
          regimentInputOffersFor(
            runRegimentInputTreasuryPlanner(
              game,
              playerId: kRegimentInputSupplierId,
            ),
            kRegimentInputWoolId,
          ),
          isEmpty,
        );
      },
    );

    test('seller with sufficient wool bids fabric not wool', () {
      final game = twoGpRegimentInputGame(
        sellerTreasury: threshold,
        supplierTreasury: threshold,
        sellerFabricHeld: 0,
        sellerWoolHeld: 2,
        supplierWoolHeld: 20,
      );
      final orders = runRegimentInputTreasuryPlanner(
        game,
        playerId: kRegimentInputSellerId,
      );
      expect(regimentInputBidsFor(orders, kRegimentInputWoolId), isEmpty);
      expect(regimentInputBidsFor(orders, kRegimentInputFabricId), isNotEmpty);
    });

    test(
      'supplier build-input offer lands in the same priority tier the buyer '
      'bids at so the DealMatcher can cross them (Refs #2847 H8-supply market '
      'order matching)',
      () {
        final game = twoGpRegimentInputGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          sellerFabricHeld: 0,
          sellerWoolHeld: 0,
          supplierWoolHeld: 20,
        );
        final supplierWoolOffer = runRegimentInputTreasuryPlanner(
          game,
          playerId: kRegimentInputSupplierId,
        ).firstWhere(
          (o) =>
              o.type == TradeOrderType.offer &&
              o.commodityId == kRegimentInputWoolId,
        );
        final sellerWoolBid = runRegimentInputTreasuryPlanner(
          game,
          playerId: kRegimentInputSellerId,
        ).firstWhere(
          (o) =>
              o.type == TradeOrderType.bid && o.commodityId == kRegimentInputWoolId,
        );
        expect(
          supplierWoolOffer.priority,
          sellerWoolBid.priority,
          reason:
              'The build-input supply offer and the buyer build-input bid '
              'must share an integer priority tier; the DealMatcher only '
              'crosses orders within the same tier.',
        );
        expect(
          supplierWoolOffer.priority,
          kTreasuryBidPriorityRawMaterial,
          reason:
              'wool is a raw material; the supply offer is re-tagged to the '
              'raw bid tier rather than the moderate offer tier.',
        );
      },
    );

    test(
      'only build-input supply commodities are re-tagged; a non-build-input '
      'surplus offer keeps the moderate offer tier (Refs #2847 H8-supply '
      'market order matching)',
      () {
        final game = twoGpRegimentInputGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          sellerFabricHeld: 0,
          sellerWoolHeld: 0,
          supplierWoolHeld: 20,
          supplierTimberHeld: 200,
        );
        final supplierOrders = runRegimentInputTreasuryPlanner(
          game,
          playerId: kRegimentInputSupplierId,
        );
        final timberOffer = supplierOrders.firstWhere(
          (o) =>
              o.type == TradeOrderType.offer &&
              o.commodityId == kRegimentInputTimberId,
        );
        expect(
          timberOffer.priority,
          kTreasuryOfferPriorityModerate,
          reason:
              'timber is not a regiment build-input supply commodity, so its '
              'surplus offer keeps the general moderate offer priority and is '
              'not re-tagged.',
        );
        final woolOffer = supplierOrders.firstWhere(
          (o) =>
              o.type == TradeOrderType.offer &&
              o.commodityId == kRegimentInputWoolId,
        );
        expect(
          woolOffer.priority,
          kTreasuryBidPriorityRawMaterial,
          reason:
              'wool is a build-input supply commodity, so it is re-tagged to '
              'the buyer bid tier even while timber is not.',
        );
      },
    );

    test('H8-supply market path is deterministic', () {
      final game = twoGpRegimentInputGame(
        sellerTreasury: threshold,
        supplierTreasury: threshold,
        sellerFabricHeld: 0,
        sellerWoolHeld: 0,
        supplierWoolHeld: 20,
      );
      expect(
        runRegimentInputTreasuryPlanner(game, playerId: kRegimentInputSellerId),
        equals(
          runRegimentInputTreasuryPlanner(
            game,
            playerId: kRegimentInputSellerId,
          ),
        ),
      );
      expect(
        runRegimentInputTreasuryPlanner(
          game,
          playerId: kRegimentInputSupplierId,
        ),
        equals(
          runRegimentInputTreasuryPlanner(
            game,
            playerId: kRegimentInputSupplierId,
          ),
        ),
      );
    });
  });
}

