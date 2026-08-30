// Bootstrap / bid-side regiment build-input cases (Refs #3941 consolidation).
//
// Transcribed 1:1 from the former `treasury_planner_regiment_input_{bootstrap,
// improvement_bootstrap,castiron_production}_test.dart` shards.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_planner_regiment_input_support.dart';

void registerTreasuryRegimentInputBootstrapLockRecoveryCases() {
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
