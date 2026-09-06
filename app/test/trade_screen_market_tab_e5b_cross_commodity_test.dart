// Market tab E5b cross-commodity mutual exclusion (Refs #4734 Slice G).
// Primary interactive controls: trade_screen_market_tab_e5b_interactive_controls_test.dart.

import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'trade_screen_market_tab_e5b_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('mutual exclusion across distinct commodities — staging timber '
      'as Bid and fabric as Offer keeps both as a single TradeOrder '
      'each in currentOrdersProvider', (tester) async {
    final ProviderContainer container = await pumpE5bFilledTradeScreen(tester);
    await tapE5bKey(tester, TradeScreenMarketKeys.marketRowBidChipKey(kE5bTimber));
    await tapE5bKey(
      tester,
      TradeScreenMarketKeys.marketRowOfferChipKey(kE5bFabric),
    );

    expect(e5bStagedOrder(container, kE5bTimber)?.type, TradeOrderType.bid);
    expect(e5bStagedOrder(container, kE5bFabric)?.type, TradeOrderType.offer);
    final Orders orders = container.read(currentOrdersProvider);
    expect(
      orders.tradeOrdersByPlayerId[kE5bHumanPlayerId]?.length,
      2,
      reason:
          'Refs #2993 E5b: the player can stage one TradeOrder '
          'per commodity simultaneously; mutual exclusion is '
          'per-commodity, not per-player.',
    );
  });
}
