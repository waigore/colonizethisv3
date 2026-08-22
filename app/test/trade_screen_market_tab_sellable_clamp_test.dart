// Widget tests for the Trade Market tab sellable-headroom display and
// industry-allocation reservation (Refs #3093 Slice 2 — sellable clamp).
// SPEC/ui/trade-screen.md § Market tab — Sellable + offer clamp,
// SPEC/game/world-market.md § Trade orders § Validation rules.
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_market_tab_sellable_clamp_support.dart';
import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab sellable clamp readout (Refs #3093)', () {
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
        find.byKey(
          TradeScreenMarketKeys.marketRowSellableReadoutKey(
            kSellableClampTimber,
          ),
        ),
        findsOneWidget,
      );
      expectSellableClampReadout(tester, kSellableClampTimber, '(10)');
      expectSellableClampReadout(tester, kSellableClampIron, '(7)');
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
        initialOrders: sellableClampTradeOrders(
          sellableClampTimberTrade(quantity: 2),
        ),
        // paper_from_timber consumes 2 timber per run, 2 labour per
        // output; desired output 1 → assigned labour 2 → runs 1 →
        // 2 timber reserved.
        initialDesiredOutputByRecipe: const <String, int>{
          'paper_from_timber': 1,
        },
      );

      // Sellable headroom = max(0, 10 - 2) - 2 = 6.
      expectSellableClampReadout(tester, kSellableClampTimber, '(6)');

      // The offer cap (stockpile − reservation) is 8, so 6 +-taps
      // grow the staged offer from 2 to 8 (= cap). Per the issue AC:
      // "offer increment cannot exceed 6" — i.e. the player gains
      // at most +6 units before saturating, which lands the staged
      // quantity at 8 (matching the cap).
      for (int i = 0; i < 6; i++) {
        await tapSellableClampKey(
          tester,
          TradeScreenMarketKeys.marketRowIncrementKey(kSellableClampTimber),
        );
      }
      expect(
        stagedSellableClampOrder(container, kSellableClampTimber)?.quantity,
        8,
        reason:
            'Six +-taps grow the staged offer from 2 to 8 '
            '(= 10 stockpile − 2 industry allocation).',
      );
      expectSellableClampReadout(
        tester,
        kSellableClampTimber,
        '(0)',
        reason: 'At cap, sellable readout drops to (0).',
      );

      // Next + tap is a silent no-op; quantity stays at 8.
      await tapSellableClampKey(
        tester,
        TradeScreenMarketKeys.marketRowIncrementKey(kSellableClampTimber),
      );
      expect(
        stagedSellableClampOrder(container, kSellableClampTimber)?.quantity,
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

      expectSellableClampReadout(tester, kSellableClampTimber, '(0)');
      await tapSellableClampKey(
        tester,
        TradeScreenMarketKeys.marketRowOfferChipKey(kSellableClampTimber),
      );
      expect(
        stagedSellableClampOrder(container, kSellableClampTimber),
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

      expectSellableClampReadout(
        tester,
        kSellableClampTimber,
        '(8)',
        reason: 'Timber sellable = 10 - 2 (paper reservation) = 8.',
      );
      expectSellableClampReadout(
        tester,
        kSellableClampIron,
        '(7)',
        reason:
            'Iron has no production allocation; headroom equals raw '
            'stockpile.',
      );
    });
  });
}
