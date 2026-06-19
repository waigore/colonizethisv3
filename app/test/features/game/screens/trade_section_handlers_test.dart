// Tests for trade_section_handlers.dart (Refs #3546 — trade-screen section
// callback factory slice).
//
// `buildTradeSectionHandlers` replaced the three verbatim
// `onDirectionChanged` / `onQuantityDelta` closure pairs inlined under each
// Market-tab commodity section. These tests pin the contract that mattered for
// behaviour preservation:
//
// - The row's own arguments (commodityId + direction/delta) are forwarded to
//   the supplied base handlers unchanged.
// - The projected treasury delta is read **lazily** at invocation time, so a
//   value that changes between building the handlers and firing a row is read
//   afresh on each call (the original inlined closures called
//   `readProjectedTreasuryDelta()` per interaction).

import 'package:colonizethis_app/features/game/screens/trade_section_handlers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(suppressLogsForTests);

  group('buildTradeSectionHandlers', () {
    test('onDirectionChanged forwards row args plus the lazily-read delta', () {
      final List<({CommodityId id, TradeOrderType? next, int? delta})> calls =
          <({CommodityId id, TradeOrderType? next, int? delta})>[];
      int treasuryDelta = 10;

      final handlers = buildTradeSectionHandlers(
        readProjectedTreasuryDelta: () => treasuryDelta,
        handleDirectionChanged: ({
          required CommodityId commodityId,
          required TradeOrderType? next,
          required int? projectedTreasuryDelta,
        }) =>
            calls.add((id: commodityId, next: next, delta: projectedTreasuryDelta)),
        handleQuantityDelta: ({
          required CommodityId commodityId,
          required int delta,
          required int? projectedTreasuryDelta,
        }) {},
      );

      handlers.onDirectionChanged('grain', TradeOrderType.bid);

      expect(calls, hasLength(1));
      expect(calls.single.id, 'grain');
      expect(calls.single.next, TradeOrderType.bid);
      expect(calls.single.delta, 10);
    });

    test('onQuantityDelta forwards row args plus the lazily-read delta', () {
      final List<({CommodityId id, int delta, int? treasury})> calls =
          <({CommodityId id, int delta, int? treasury})>[];
      int treasuryDelta = -5;

      final handlers = buildTradeSectionHandlers(
        readProjectedTreasuryDelta: () => treasuryDelta,
        handleDirectionChanged: ({
          required CommodityId commodityId,
          required TradeOrderType? next,
          required int? projectedTreasuryDelta,
        }) {},
        handleQuantityDelta: ({
          required CommodityId commodityId,
          required int delta,
          required int? projectedTreasuryDelta,
        }) =>
            calls.add((id: commodityId, delta: delta, treasury: projectedTreasuryDelta)),
      );

      handlers.onQuantityDelta('iron', -1);

      expect(calls, hasLength(1));
      expect(calls.single.id, 'iron');
      expect(calls.single.delta, -1);
      expect(calls.single.treasury, -5);
    });

    test('reads the projected treasury delta afresh on each invocation', () {
      final List<int?> seenDeltas = <int?>[];
      int treasuryDelta = 1;

      final handlers = buildTradeSectionHandlers(
        readProjectedTreasuryDelta: () => treasuryDelta,
        handleDirectionChanged: ({
          required CommodityId commodityId,
          required TradeOrderType? next,
          required int? projectedTreasuryDelta,
        }) =>
            seenDeltas.add(projectedTreasuryDelta),
        handleQuantityDelta: ({
          required CommodityId commodityId,
          required int delta,
          required int? projectedTreasuryDelta,
        }) =>
            seenDeltas.add(projectedTreasuryDelta),
      );

      handlers.onDirectionChanged('grain', TradeOrderType.offer);
      treasuryDelta = 2;
      handlers.onQuantityDelta('grain', 1);
      treasuryDelta = 3;
      handlers.onDirectionChanged('grain', null);

      // Each call read the value current at invocation time, not at build time.
      expect(seenDeltas, <int?>[1, 2, 3]);
    });

    test('forwards a null projected treasury delta unchanged', () {
      int? captured = 0;

      final handlers = buildTradeSectionHandlers(
        readProjectedTreasuryDelta: () => null,
        handleDirectionChanged: ({
          required CommodityId commodityId,
          required TradeOrderType? next,
          required int? projectedTreasuryDelta,
        }) =>
            captured = projectedTreasuryDelta,
        handleQuantityDelta: ({
          required CommodityId commodityId,
          required int delta,
          required int? projectedTreasuryDelta,
        }) {},
      );

      handlers.onDirectionChanged('grain', TradeOrderType.bid);

      expect(captured, isNull);
    });
  });
}
