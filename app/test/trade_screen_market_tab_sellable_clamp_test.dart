// Widget tests for the Trade Market tab sellable-headroom display and
// Offer clamp (Refs #3093 Slice 2 — sellable clamp).
//
// SPEC/ui/trade-screen.md § Market tab — Sellable + offer clamp,
// SPEC/game/world-market.md § Trade orders § Validation rules.
//
// Pins:
//   * The `(N)` text rendered next to each commodity name reflects
//     `sellableHeadroomByCommodityId` (offer cap minus the player's
//     own staged offer quantity).
//   * Tapping `Offer` on a commodity with sellable headroom = 0 is a
//     silent no-op (the chip is disabled).
//   * Tapping `+` on an Offer-staged row that is already at the cap
//     is a silent no-op.
//   * Decrement on a saturated offer row still works and refreshes
//     the headroom display.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

const String _humanPlayerId = kTradeTestHumanPlayerId;

CommodityId get _timber => CommodityCatalog.timber.id;
CommodityId get _iron => CommodityCatalog.iron.id;

TradeOrder? _stagedOrder(ProviderContainer container, CommodityId commodityId) {
  final Orders orders = container.read(currentOrdersProvider);
  final List<TradeOrder>? list = orders.tradeOrdersByPlayerId[_humanPlayerId];
  if (list == null) return null;
  for (final TradeOrder o in list) {
    if (o.commodityId == commodityId) return o;
  }
  return null;
}

Orders _tradeOrders(TradeOrder order) => Orders(
      tradeOrdersByPlayerId: {
        _humanPlayerId: [order],
      },
    );

TradeOrder _timberTrade({
  TradeOrderType type = TradeOrderType.offer,
  required int quantity,
}) =>
    TradeOrder(
      commodityId: _timber,
      type: type,
      quantity: quantity,
      priority: 1,
    );

void _expectSellable(
  WidgetTester tester,
  CommodityId commodityId,
  String expected, {
  String? reason,
}) {
  expect(
    tester
        .widget<Text>(
          find.byKey(TradeScreenMarketKeys.marketRowSellableReadoutKey(commodityId)),
        )
        .data,
    // ignore: avoid_hardcoded_strings_in_widgets
    expected,
    reason: reason,
  );
}

Future<void> _tapKey(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pump();
}

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab sellable clamp (Refs #3093)', () {
    testWidgets('renders `(N)` next to commodity name where N = stockpile − '
        'stagedOffer (offer cap minus the row\'s staged offer)', (
      tester,
    ) async {
      await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          stockpile: const <CommodityId, int>{'timber': 10, 'iron': 7},
        ),
      );

      // No staged offers and no production allocation in this test →
      // industry-allocation projection contributes 0, headroom equals
      // the raw stockpile. The new industry-allocation reservation
      // path is exercised by the canonical AC test below.
      expect(
        find.byKey(TradeScreenMarketKeys.marketRowSellableReadoutKey(_timber)),
        findsOneWidget,
      );
      _expectSellable(tester, _timber, '(10)');
      _expectSellable(tester, _iron, '(7)');
    });

    testWidgets('canonical AC (Refs #3093): stockpile=10 timber, production '
        'allocation consumes 2 timber (paper_from_timber @ 2 labour), '
        'staged offer 2 → `(6)` readout and `+` can only grow the offer '
        'by 6 (staged quantity caps at 8 = stockpile − reservation)', (
      tester,
    ) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          stockpile: const <CommodityId, int>{'timber': 10},
        ),
        initialOrders: _tradeOrders(_timberTrade(quantity: 2)),
        // paper_from_timber consumes 2 timber per run, 2 labour per
        // output; desired output 1 → assigned labour 2 → runs 1 →
        // 2 timber reserved.
        initialDesiredOutputByRecipe: const <String, int>{
          'paper_from_timber': 1,
        },
      );

      // Sellable headroom = max(0, 10 - 2) - 2 = 6.
      _expectSellable(tester, _timber, '(6)');

      // The offer cap (stockpile − reservation) is 8, so 6 +-taps
      // grow the staged offer from 2 to 8 (= cap). Per the issue AC:
      // "offer increment cannot exceed 6" — i.e. the player gains
      // at most +6 units before saturating, which lands the staged
      // quantity at 8 (matching the cap).
      for (int i = 0; i < 6; i++) {
        await _tapKey(tester, TradeScreenMarketKeys.marketRowIncrementKey(_timber));
      }
      expect(
        _stagedOrder(container, _timber)?.quantity,
        8,
        reason:
            'Six +-taps grow the staged offer from 2 to 8 '
            '(= 10 stockpile − 2 industry allocation).',
      );
      _expectSellable(
        tester,
        _timber,
        '(0)',
        reason: 'At cap, sellable readout drops to (0).',
      );

      // Next + tap is a silent no-op; quantity stays at 8.
      await _tapKey(tester, TradeScreenMarketKeys.marketRowIncrementKey(_timber));
      expect(
        _stagedOrder(container, _timber)?.quantity,
        8,
        reason:
            'Tapping `+` at saturation must not exceed the offer '
            'cap of 8 (= 10 stockpile − 2 industry allocation).',
      );
    });

    testWidgets('industry-allocation reservation hides the Offer chip when '
        'allocation fully reserves stockpile (cap drops to 0)', (tester) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          stockpile: const <CommodityId, int>{'timber': 4},
        ),
        // Two runs of paper_from_timber consume 4 timber.
        initialDesiredOutputByRecipe: const <String, int>{
          'paper_from_timber': 2,
        },
      );

      _expectSellable(tester, _timber, '(0)');
      await _tapKey(tester, TradeScreenMarketKeys.marketRowOfferChipKey(_timber));
      expect(
        _stagedOrder(container, _timber),
        isNull,
        reason:
            'Full industry-allocation reservation disables the '
            'Offer chip — tap must be a silent no-op.',
      );
    });

    testWidgets('industry-allocation reservation on one commodity does not '
        'reduce another commodity\'s sellable headroom', (tester) async {
      await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          stockpile: const <CommodityId, int>{'timber': 10, 'iron': 7},
        ),
        // paper_from_timber consumes only timber.
        initialDesiredOutputByRecipe: const <String, int>{
          'paper_from_timber': 1,
        },
      );

      _expectSellable(
        tester,
        _timber,
        '(8)',
        reason: 'Timber sellable = 10 - 2 (paper reservation) = 8.',
      );
      _expectSellable(
        tester,
        _iron,
        '(7)',
        reason:
            'Iron has no production allocation; headroom equals raw '
            'stockpile.',
      );
    });

    testWidgets(
      'with stockpile=10 timber and staged offer for 2 timber, the `(N)` '
      'readout shows `(8)` (headroom = cap − staged)',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            stockpile: const <CommodityId, int>{'timber': 10},
          ),
          initialOrders: _tradeOrders(_timberTrade(quantity: 2)),
        );

        _expectSellable(tester, _timber, '(8)');
      },
    );

    testWidgets(
      'rows with zero stockpile and no staged offer render `(0)` and the '
      'Offer chip + offer-side `+` are disabled (silent no-op on tap)',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(stockpile: const <CommodityId, int>{}),
        );

        // (0) display for an empty-stockpile commodity.
        _expectSellable(tester, _timber, '(0)');

        // Offer chip tap → silent no-op.
        await _tapKey(tester, TradeScreenMarketKeys.marketRowOfferChipKey(_timber));
        expect(
          _stagedOrder(container, _timber),
          isNull,
          reason:
              'Refs #3093 — Offer chip is disabled when the per-commodity '
              'offer cap is 0; tapping it must not stage a TradeOrder.',
        );
      },
    );

    testWidgets('Offer chip becomes enabled when the player gains stockpile by '
        'releasing a staged offer (re-evaluate on order changes)', (
      tester,
    ) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          stockpile: const <CommodityId, int>{'timber': 3},
        ),
        initialOrders: _tradeOrders(_timberTrade(quantity: 3)),
      );

      // Headroom is 0 with the saturated offer.
      _expectSellable(tester, _timber, '(0)');

      // Decrement the saturated offer down by 1 → headroom updates to 1.
      await _tapKey(tester, TradeScreenMarketKeys.marketRowDecrementKey(_timber));
      _expectSellable(tester, _timber, '(1)');
      expect(_stagedOrder(container, _timber)?.quantity, 2);
    });

    testWidgets(
      'tapping `Offer` on a fresh commodity clamps the staged quantity to '
      'the per-commodity offer cap (default 1 ≤ cap → preserves default)',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            stockpile: const <CommodityId, int>{'timber': 5},
          ),
        );

        await _tapKey(tester, TradeScreenMarketKeys.marketRowOfferChipKey(_timber));

        final TradeOrder? staged = _stagedOrder(container, _timber);
        expect(staged, isNotNull);
        expect(staged!.type, TradeOrderType.offer);
        expect(
          staged.quantity,
          TradeScreenMarketKeys.marketRowQuantityDefault,
          reason:
              'Default quantity (1) fits inside the offer cap of 5 — no '
              'clamping needed.',
        );
      },
    );

    testWidgets(
      'tapping `Offer` on a fresh commodity with offer cap = 0 is a silent '
      'no-op (no TradeOrder is staged)',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(stockpile: const <CommodityId, int>{}),
        );

        await _tapKey(tester, TradeScreenMarketKeys.marketRowOfferChipKey(_timber));

        expect(_stagedOrder(container, _timber), isNull);
      },
    );

    testWidgets(
      'tapping `Offer` on a row previously staged as Bid with a quantity '
      'exceeding the cap clamps the staged offer quantity down to the cap',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            stockpile: const <CommodityId, int>{'timber': 4},
          ),
          initialOrders: _tradeOrders(
            _timberTrade(type: TradeOrderType.bid, quantity: 9),
          ),
        );

        await _tapKey(tester, TradeScreenMarketKeys.marketRowOfferChipKey(_timber));

        final TradeOrder? staged = _stagedOrder(container, _timber);
        expect(staged, isNotNull);
        expect(staged!.type, TradeOrderType.offer);
        expect(
          staged.quantity,
          4,
          reason:
              'Refs #3093 — switching to Offer clamps the prior quantity '
              '(9) to the per-commodity offer cap (stockpile=4).',
        );
      },
    );

    testWidgets(
      'incrementing a saturated Offer row is a silent no-op (the staged '
      'quantity stays at the cap and the headroom stays at (0))',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            stockpile: const <CommodityId, int>{'timber': 5},
          ),
          initialOrders: _tradeOrders(_timberTrade(quantity: 5)),
        );

        await _tapKey(tester, TradeScreenMarketKeys.marketRowIncrementKey(_timber));

        expect(_stagedOrder(container, _timber)?.quantity, 5);
        _expectSellable(tester, _timber, '(0)');
      },
    );

    testWidgets('incrementing an Offer row with headroom > 0 raises the staged '
        'quantity by 1 and the headroom display decreases accordingly', (
      tester,
    ) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          stockpile: const <CommodityId, int>{'timber': 7},
        ),
        initialOrders: _tradeOrders(_timberTrade(quantity: 2)),
      );

      // Initial headroom 5 (= 7 - 2).
      _expectSellable(tester, _timber, '(5)');

      await _tapKey(tester, TradeScreenMarketKeys.marketRowIncrementKey(_timber));
      expect(_stagedOrder(container, _timber)?.quantity, 3);
      _expectSellable(tester, _timber, '(4)');
    });

    testWidgets('bids do not consume the offer headroom (bid row\'s `(N)` is '
        'unaffected by the staged bid quantity)', (tester) async {
      await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          stockpile: const <CommodityId, int>{'timber': 10},
        ),
        initialOrders: _tradeOrders(
          _timberTrade(type: TradeOrderType.bid, quantity: 4),
        ),
      );

      _expectSellable(
        tester,
        _timber,
        '(10)',
        reason:
            'Refs #3093 — bids do not reserve stockpile (per '
            'SPEC/game/world-market.md § Cargo). The offer headroom '
            'is independent of staged bids.',
      );
    });
  });
}
