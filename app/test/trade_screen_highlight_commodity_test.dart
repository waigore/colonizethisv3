// TradeScreen highlightCommodityId from Production. SPEC/ui/trade-screen.md Refs #4581.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen_market_row_highlight.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('highlightCommodityId paints inbound chrome on that Market row', (
    WidgetTester tester,
  ) async {
    final game = buildTradeTestGame(stockpile: tradeableStockpileFilled(10));
    await pumpTradeScreen(tester, game: game, highlightCommodityId: 'timber');

    expect(find.byType(TradeScreen), findsOneWidget);
    expect(
      find.byKey(MarketCommodityRowHighlight.highlightKey('timber')),
      findsOneWidget,
    );
    expect(
      find.byKey(MarketCommodityRowHighlight.highlightKey('iron')),
      findsNothing,
    );
  });

  testWidgets('highlight does not auto-stage a TradeOrder', (
    WidgetTester tester,
  ) async {
    final game = buildTradeTestGame(stockpile: tradeableStockpileFilled(10));
    final container = await pumpTradeScreenWithContainer(
      tester,
      game: game,
      highlightCommodityId: 'fabric',
    );
    final orders = container.read(currentOrdersProvider);
    expect(orders.tradeOrdersByPlayerId, isEmpty);
  });
}
