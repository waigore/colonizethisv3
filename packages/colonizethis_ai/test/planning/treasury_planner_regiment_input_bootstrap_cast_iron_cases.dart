// Bootstrap / bid-side regiment build-input cases (Refs #3941 consolidation).
//
// Transcribed 1:1 from the former `treasury_planner_regiment_input_{bootstrap,
// improvement_bootstrap,castiron_production}_test.dart` shards.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_planner_regiment_input_support.dart';

void registerTreasuryRegimentInputBootstrapCastIronCases() {
  group('lock-recovery seller improvement-input domestic production '
      '(Refs #2847 H8-extraction castIron residual)', () {
    final threshold = regimentInputThreshold();

    test(
      'seller short of castIron (and missing its production feedstock) bids a '
      'castIron production feedstock commodity, not castIron itself',
      () {
        final orders = runRegimentInputTreasuryPlanner(
          castIronProductionRegimentInputGame(
            sellerTreasury: threshold,
            sellerLumberHeld: 1,
          ),
          playerId: kRegimentInputSellerId,
        );
        final feedstockBids = orders.where(
          (o) =>
              o.type == TradeOrderType.bid &&
              (o.commodityId == kRegimentInputTimberId ||
                  o.commodityId == kRegimentInputIronId),
        );
        expect(
          feedstockBids,
          isNotEmpty,
          reason:
              'The locked seller must bid castIron production feedstock '
              '(timber / iron) because castIron has no world-market supply.',
        );
        expect(
          regimentInputBidsFor(orders, kRegimentInputCastIronId),
          isEmpty,
          reason: 'castIron is never bid directly (the market cannot supply it).',
        );
      },
    );

    test(
      'seller already holding the castIron production feedstock emits no '
      'castIron or feedstock bid, but still bids a missing direct input (lumber)',
      () {
        final orders = runRegimentInputTreasuryPlanner(
          castIronProductionRegimentInputGame(
            sellerTreasury: threshold,
            sellerTimberHeld: 2,
            sellerIronHeld: 2,
          ),
          playerId: kRegimentInputSellerId,
        );
        expect(regimentInputBidsFor(orders, kRegimentInputCastIronId), isEmpty);
        expect(regimentInputBidsFor(orders, kRegimentInputTimberId), isEmpty);
        expect(regimentInputBidsFor(orders, kRegimentInputIronId), isEmpty);
        expect(
          regimentInputBidsFor(orders, kRegimentInputLumberId),
          isNotEmpty,
          reason:
              'lumber keeps its direct market bid; only castIron is produced '
              'domestically.',
        );
      },
    );

    test('seller already holding castIron emits no castIron feedstock bid', () {
      final orders = runRegimentInputTreasuryPlanner(
        castIronProductionRegimentInputGame(
          sellerTreasury: threshold,
          sellerLumberHeld: 1,
          sellerCastIronHeld: 1,
        ),
        playerId: kRegimentInputSellerId,
      );
      expect(regimentInputBidsFor(orders, kRegimentInputCastIronId), isEmpty);
      expect(regimentInputBidsFor(orders, kRegimentInputTimberId), isEmpty);
      expect(regimentInputBidsFor(orders, kRegimentInputIronId), isEmpty);
    });

    test('castIron production feedstock path is deterministic', () {
      final game = castIronProductionRegimentInputGame(
        sellerTreasury: threshold,
        sellerLumberHeld: 1,
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
    });
  });
}
