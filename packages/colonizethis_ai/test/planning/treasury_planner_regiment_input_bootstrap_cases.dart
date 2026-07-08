// Bootstrap / bid-side regiment build-input cases (Refs #3941 consolidation).
//
// Transcribed 1:1 from the former `treasury_planner_regiment_input_{bootstrap,
// improvement_bootstrap,castiron_production}_test.dart` shards.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_planner_regiment_input_support.dart';

void registerTreasuryRegimentInputBootstrapCases() {
  _registerLockRecoveryBootstrapCases();
  _registerImprovementBootstrapCases();
  _registerCastIronProductionCases();
}

void _registerLockRecoveryBootstrapCases() {
  group('lock-recovery seller regiment build-input bootstrap (Refs #2847 H8)',
      () {
    final threshold = regimentInputThreshold();
    final fabricInput =
        RegimentEconomyCatalog.peasantLevies.buildInputs[kRegimentInputFabricId];

    test('peasant_levies requires fabric (guards the fixture assumption)', () {
      expect(
        fabricInput,
        isNotNull,
        reason:
            'This slice assumes the cheapest regiment consumes fabric; if the '
            'catalog changes, the carve-out and these tests must follow.',
      );
      expect(fabricInput, greaterThan(0));
    });

    test(
      'recovered-treasury seller holding zero fabric and zero wool emits a '
      'wool feedstock bid before fabric',
      () {
        final game = lockRecoverySellerRegimentInputGame(
          treasury: threshold,
          fabricHeld: 0,
          woolHeld: 0,
        );
        final bids = runRegimentInputTreasuryPlanner(game)
            .where((o) => o.type == TradeOrderType.bid)
            .toList();
        final woolBids =
            bids.where((o) => o.commodityId == kRegimentInputWoolId).toList();
        final fabricBids =
            bids.where((o) => o.commodityId == kRegimentInputFabricId).toList();
        expect(
          woolBids,
          isNotEmpty,
          reason:
              'A seller above the regiment threshold with no regiment and no '
              'fabric must bid for missing wool feedstock first.',
        );
        expect(fabricBids, isEmpty);
      },
    );

    test('seller with sufficient wool feedstock emits a fabric bid', () {
      final game = lockRecoverySellerRegimentInputGame(
        treasury: threshold,
        fabricHeld: 0,
        woolHeld: 2,
      );
      final fabricBids = runRegimentInputTreasuryPlanner(game)
          .where(
            (o) =>
                o.type == TradeOrderType.bid &&
                o.commodityId == kRegimentInputFabricId,
          )
          .toList();
      expect(fabricBids, isNotEmpty);
      expect(
        runRegimentInputTreasuryPlanner(game).where(
          (o) =>
              o.type == TradeOrderType.bid &&
              o.commodityId == kRegimentInputWoolId,
        ),
        isEmpty,
      );
    });

    test('seller still below the regiment threshold emits no fabric bid', () {
      final game = lockRecoverySellerRegimentInputGame(
        treasury: threshold - 1,
        fabricHeld: 0,
        woolHeld: 0,
      );
      final fabricBids = runRegimentInputTreasuryPlanner(game)
          .where(
            (o) =>
                o.type == TradeOrderType.bid &&
                o.commodityId == kRegimentInputFabricId,
          )
          .toList();
      expect(
        fabricBids,
        isEmpty,
        reason:
            'A broke seller must keep accumulating credits, not spend them on '
            'the build input before it can afford the regiment itself.',
      );
    });

    test('seller already holding the fabric input emits no fabric bid', () {
      final game = lockRecoverySellerRegimentInputGame(
        treasury: threshold,
        fabricHeld: fabricInput!,
      );
      final fabricBids = runRegimentInputTreasuryPlanner(game)
          .where(
            (o) =>
                o.type == TradeOrderType.bid &&
                o.commodityId == kRegimentInputFabricId,
          )
          .toList();
      expect(
        fabricBids,
        isEmpty,
        reason:
            'Once the build input is on hand the carve-out clears; the build '
            'pipeline can emit the regiment without a redundant bid.',
      );
    });

    test('seller that already holds a regiment emits no fabric bid', () {
      final game = lockRecoverySellerRegimentInputGame(
        treasury: threshold,
        fabricHeld: 0,
        woolHeld: 0,
        hasRegiment: true,
      );
      final fabricBids = runRegimentInputTreasuryPlanner(game)
          .where(
            (o) =>
                o.type == TradeOrderType.bid &&
                o.commodityId == kRegimentInputFabricId,
          )
          .toList();
      expect(
        fabricBids,
        isEmpty,
        reason: 'The bootstrap targets the zero-regiment rebuild gap only.',
      );
    });

    test('quota-met (non-seller) GP above threshold emits no bootstrap bid', () {
      final game = lockRecoverySellerRegimentInputGame(
        treasury: threshold,
        fabricHeld: 0,
        woolHeld: 0,
        owProvinces: 12,
      );
      final fabricBids = runRegimentInputTreasuryPlanner(game)
          .where(
            (o) =>
                o.type == TradeOrderType.bid &&
                o.commodityId == kRegimentInputFabricId,
          )
          .toList();
      expect(fabricBids, isEmpty);
    });
  });
}

void _registerImprovementBootstrapCases() {
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

void _registerCastIronProductionCases() {
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
