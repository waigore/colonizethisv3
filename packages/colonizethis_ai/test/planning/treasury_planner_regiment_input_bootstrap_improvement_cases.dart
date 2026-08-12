// Bootstrap / bid-side regiment build-input cases (Refs #3941 consolidation).
//
// Transcribed 1:1 from the former `treasury_planner_regiment_input_{bootstrap,
// improvement_bootstrap,castiron_production}_test.dart` shards.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_planner_regiment_input_support.dart';

void registerTreasuryRegimentInputBootstrapImprovementCases() {
  group('lock-recovery seller feedstock-improvement input bootstrap '
      '(Refs #2847 H8-extraction)', () {
    final threshold = regimentInputThreshold();

    test(
      'recovered seller with owned unimproved feedstock tile but no lumber / '
      'cast iron bids an improvement input before fabric or feedstock',
      () {
        final orders = runRegimentInputTreasuryPlanner(
          improvementBootstrapRegimentInputGame(
            sellerTreasury: threshold,
            supplierTreasury: threshold,
          ),
          playerId: kRegimentInputSellerId,
        );
        final improvementBids = orders.where(
          (o) =>
              o.type == TradeOrderType.bid &&
              (o.commodityId == kRegimentInputLumberId ||
                  o.commodityId == kRegimentInputCastIronId),
        );
        expect(
          improvementBids,
          isNotEmpty,
          reason:
              'The locked seller must bid for the level-0 build_improvement '
              'inputs (lumber / cast iron) it cannot afford.',
        );
        expect(
          regimentInputBidsFor(orders, kRegimentInputFabricId),
          isEmpty,
        );
        expect(regimentInputBidsFor(orders, kRegimentInputWoolId), isEmpty);
      },
    );

    test('seller already holding lumber + cast iron emits no improvement-input '
        'bid and resumes the feedstock / fabric bootstrap', () {
      final orders = runRegimentInputTreasuryPlanner(
        improvementBootstrapRegimentInputGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          sellerHoldsImprovementInputs: true,
        ),
        playerId: kRegimentInputSellerId,
      );
      expect(regimentInputBidsFor(orders, kRegimentInputLumberId), isEmpty);
      expect(regimentInputBidsFor(orders, kRegimentInputCastIronId), isEmpty);
      expect(
        orders.where((o) => o.type == TradeOrderType.bid),
        isNotEmpty,
        reason:
            'With the improvement inputs on hand the seller resumes the '
            'feedstock / fabric bootstrap bid.',
      );
    });

    test('seller owning no feedstock tile emits no improvement-input bid', () {
      final orders = runRegimentInputTreasuryPlanner(
        improvementBootstrapRegimentInputGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          sellerOwnsFeedstockTile: false,
        ),
        playerId: kRegimentInputSellerId,
      );
      expect(regimentInputBidsFor(orders, kRegimentInputLumberId), isEmpty);
      expect(regimentInputBidsFor(orders, kRegimentInputCastIronId), isEmpty);
    });

    test('seller whose feedstock tile is already improved emits no '
        'improvement-input bid', () {
      final orders = runRegimentInputTreasuryPlanner(
        improvementBootstrapRegimentInputGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          sellerWoolTileImproved: true,
        ),
        playerId: kRegimentInputSellerId,
      );
      expect(regimentInputBidsFor(orders, kRegimentInputLumberId), isEmpty);
      expect(regimentInputBidsFor(orders, kRegimentInputCastIronId), isEmpty);
    });

    test(
      'seller that already owns a regiment emits no improvement-input bid',
      () {
        final orders = runRegimentInputTreasuryPlanner(
          improvementBootstrapRegimentInputGame(
            sellerTreasury: threshold,
            supplierTreasury: threshold,
            sellerUnits: [
              Unit(
                id: 'r1',
                type: 'peasant_levies',
                ownerId: kRegimentInputSellerId,
                locationProvinceId: 'oldWorld|seller_0',
              ),
            ],
          ),
          playerId: kRegimentInputSellerId,
        );
        expect(regimentInputBidsFor(orders, kRegimentInputLumberId), isEmpty);
        expect(regimentInputBidsFor(orders, kRegimentInputCastIronId), isEmpty);
      },
    );

    test(
      'seller below the regiment threshold emits no improvement-input bid',
      () {
        final orders = runRegimentInputTreasuryPlanner(
          improvementBootstrapRegimentInputGame(
            sellerTreasury: threshold - 1,
            supplierTreasury: threshold,
          ),
          playerId: kRegimentInputSellerId,
        );
        expect(regimentInputBidsFor(orders, kRegimentInputLumberId), isEmpty);
        expect(regimentInputBidsFor(orders, kRegimentInputCastIronId), isEmpty);
      },
    );

    test('affluent non-seller releases surplus lumber while a lock-recovery '
        'seller needs the improvement-input bootstrap', () {
      final lumberOffers = runRegimentInputTreasuryPlanner(
        improvementBootstrapRegimentInputGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
        ),
        playerId: kRegimentInputSupplierId,
      ).where(
        (o) =>
            o.type == TradeOrderType.offer &&
            o.commodityId == kRegimentInputLumberId,
      );
      expect(
        lumberOffers,
        isNotEmpty,
        reason:
            'An affluent GP must release lumber so the locked seller\'s '
            'improvement-input bid can clear.',
      );
    });

    test('below-affordable non-seller still releases surplus lumber while a '
        'lock-recovery seller needs the improvement-input bootstrap', () {
      final lumberOffers = runRegimentInputTreasuryPlanner(
        improvementBootstrapRegimentInputGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold - 100,
          supplierLumberHeld: 6,
        ),
        playerId: kRegimentInputSupplierId,
      ).where(
        (o) =>
            o.type == TradeOrderType.offer &&
            o.commodityId == kRegimentInputLumberId,
      );
      expect(
        lumberOffers,
        isNotEmpty,
        reason:
            'A non-seller GP holding surplus lumber must release it regardless '
            'of its own treasury so the locked seller\'s improvement-input bid '
            'can clear.',
      );
    });

    test('improvement-input bootstrap path is deterministic', () {
      final game = improvementBootstrapRegimentInputGame(
        sellerTreasury: threshold,
        supplierTreasury: threshold,
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
