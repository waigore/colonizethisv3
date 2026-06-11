import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/src/turn/phases/world_market_phase_carry_forward.dart';
import 'package:colonizethis_test/test.dart';

/// Guards the turn-package defensive-copy audit (#3416,
/// SPEC/program/turn-defensive-copy-audit.md). The pass-through branches of
/// [validateCarryForwards] must NOT re-introduce a `List.from` clone, while the
/// constraint-filtering branches must still allocate a fresh kept list.
void main() {
  group('validateCarryForwards defensive-copy audit (#3416)', () {
    TradeOrder offer(String commodity, int qty, int priority) => TradeOrder(
      commodityId: commodity,
      type: TradeOrderType.offer,
      quantity: qty,
      priority: priority,
    );

    TradeOrder bid(String commodity, int qty, int priority) => TradeOrder(
      commodityId: commodity,
      type: TradeOrderType.bid,
      quantity: qty,
      priority: priority,
    );

    test(
      'offers pass through the same list instance when the faction has no '
      'stockpile entry (SPEC AC: no List.from in pass-through branch)',
      () {
        final orders = <TradeOrder>[offer('grain', 5, 1), offer('iron', 3, 2)];
        final result = validateCarryForwards(
          carryForwardOffersByFactionId: {'f1': orders},
          carryForwardBidsByFactionId: const {},
          stockpileByFactionId: const {},
          tradeCapacityByFactionId: const {},
        );

        expect(
          identical(result.validOffersByFactionId['f1'], orders),
          isTrue,
          reason: 'pass-through must reference the input list, not a copy',
        );
        expect(result.dropNotesByCommodity, isEmpty);
      },
    );

    test(
      'bids pass through the same list instance when the faction has no trade '
      'capacity entry (SPEC AC: no List.from in pass-through branch)',
      () {
        final orders = <TradeOrder>[bid('grain', 5, 1)];
        final result = validateCarryForwards(
          carryForwardOffersByFactionId: const {},
          carryForwardBidsByFactionId: {'f1': orders},
          stockpileByFactionId: const {},
          tradeCapacityByFactionId: const {},
        );

        expect(
          identical(result.validBidsByFactionId['f1'], orders),
          isTrue,
          reason: 'pass-through must reference the input list, not a copy',
        );
        expect(result.dropNotesByCommodity, isEmpty);
      },
    );

    test(
      'offers filtered against a stockpile produce a fresh kept list (not the '
      'input) and record drop notes for the dropped order',
      () {
        final orders = <TradeOrder>[offer('grain', 8, 1), offer('grain', 5, 2)];
        final result = validateCarryForwards(
          carryForwardOffersByFactionId: {'f1': orders},
          carryForwardBidsByFactionId: const {},
          stockpileByFactionId: const {
            'f1': Stockpile(quantities: {'grain': 10}),
          },
          tradeCapacityByFactionId: const {},
        );

        final kept = result.validOffersByFactionId['f1'];
        expect(kept, isNotNull);
        expect(
          identical(kept, orders),
          isFalse,
          reason: 'filtering branch must build a new kept list',
        );
        expect(kept, hasLength(1));
        expect(kept!.single.quantity, 8);
        expect(result.dropNotesByCommodity['grain'], hasLength(1));
      },
    );

    test(
      'bids filtered against trade capacity produce a fresh kept list (not the '
      'input) and record drop notes for the dropped order',
      () {
        final orders = <TradeOrder>[bid('grain', 6, 1), bid('iron', 6, 2)];
        final result = validateCarryForwards(
          carryForwardOffersByFactionId: const {},
          carryForwardBidsByFactionId: {'f1': orders},
          stockpileByFactionId: const {},
          tradeCapacityByFactionId: const {'f1': 6},
        );

        final kept = result.validBidsByFactionId['f1'];
        expect(kept, isNotNull);
        expect(
          identical(kept, orders),
          isFalse,
          reason: 'filtering branch must build a new kept list',
        );
        expect(kept, hasLength(1));
        expect(kept!.single.commodityId, 'grain');
        expect(result.dropNotesByCommodity['iron'], hasLength(1));
      },
    );
  });
}
