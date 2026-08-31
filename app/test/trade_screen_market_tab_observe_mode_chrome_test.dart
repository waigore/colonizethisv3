// Trade Market observe-mode chrome parity (Refs #3093).

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_market_tab_commodity_table_support.dart';
import 'trade_screen_test_support.dart';

CommodityId get _timber => CommodityCatalog.timber.id;

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab observe-mode chrome parity (Refs #3093)', () {
    testWidgets('sectioned grouping remains mounted when canMutateViaUi == false',
        (tester) async {
      await pumpObserveModeChromeMarket(tester);
      expectObserveModeSectionHeadersMounted(tester);
    });

    testWidgets('row icons remain mounted on every tradeable row when '
        'canMutateViaUi == false', (tester) async {
      await pumpObserveModeChromeMarket(tester);
      expectObserveModeRowIconsMounted(tester);
    });

    testWidgets('sellable readout `(N)` remains mounted on every tradeable row '
        'when canMutateViaUi == false', (tester) async {
      await pumpObserveModeChromeMarket(tester);
      expectObserveModeSellableReadoutsMounted(tester, qty: 99);
    });

    testWidgets('integer price text remains mounted under observe mode', (
      tester,
    ) async {
      await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_market_tab_observe_mode_chrome',
          stockpile: tradeableStockpileFilled(99),
          prices: const <CommodityId, int>{'timber': 30},
        ),
        canMutateViaUi: false,
      );

      final timberRow =
          find.byKey(TradeScreenMarketKeys.marketCommodityRowKey(_timber));
      expect(timberRow, findsOneWidget);
      expect(
        find.descendant(
          of: timberRow,
          // ignore: avoid_hardcoded_strings_in_widgets
          matching: find.text('30'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('catalog default-price fallback resolves under observe mode', (
      tester,
    ) async {
      await pumpObserveModeChromeMarket(tester);

      final ironRow = find.byKey(
        TradeScreenMarketKeys.marketCommodityRowKey(CommodityCatalog.iron.id),
      );
      expect(ironRow, findsOneWidget);
      expect(
        find.descendant(
          of: ironRow,
          // ignore: avoid_hardcoded_strings_in_widgets
          matching: find.text('80'),
        ),
        findsOneWidget,
      );

      final coinRect = tester.getRect(
        find.byKey(
          TradeScreenMarketKeys.marketRowPriceCoinIconKey(
            CommodityCatalog.iron.id,
          ),
        ),
      );
      final priceRect = tester.getRect(
        find.descendant(
          of: ironRow,
          // ignore: avoid_hardcoded_strings_in_widgets
          matching: find.text('80'),
        ),
      );
      expect(coinRect.right, lessThanOrEqualTo(priceRect.left));
    });
  });
}
