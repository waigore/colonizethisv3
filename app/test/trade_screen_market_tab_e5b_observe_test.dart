// Observe-mode Market tab E5b pins (Refs #4606 Slice D).
// SPEC/ui/trade-screen.md § Body — Market

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

const String _humanPlayerId = kTradeTestHumanPlayerId;

CommodityId get _timber => CommodityCatalog.timber.id;

TradeOrder? _stagedOrder(ProviderContainer container, CommodityId commodityId) {
  final Orders orders = container.read(currentOrdersProvider);
  final List<TradeOrder>? list = orders.tradeOrdersByPlayerId[_humanPlayerId];
  if (list == null) return null;
  for (final TradeOrder o in list) {
    if (o.commodityId == commodityId) return o;
  }
  return null;
}

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab observe variant (Refs #2993 E5b)', () {
    testWidgets(
      'observe variant (canMutateViaUi == false): direction chips and '
      'stepper taps do NOT mutate currentOrdersProvider — the table '
      'reads as read-only',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            id: 'test_trade_screen_e5b',
            stockpile: tradeableStockpileFilled(99),
          ),
          canMutateViaUi: false,
        );

        await tester.tap(
          find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(_timber)),
          warnIfMissed: false,
        );
        await tester.pump();
        await tester.tap(
          find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(_timber)),
          warnIfMissed: false,
        );
        await tester.pump();

        expect(
          _stagedOrder(container, _timber),
          isNull,
          reason:
              'Refs #2993 E5b observe variant: when '
              'canMutateViaUi == false, Bid/Offer/stepper wrap in '
              'IgnorePointer so taps do not stage trade orders.',
        );
      },
    );

    testWidgets('observe variant still mounts the row controls and quantity '
        'readout (the chrome remains visible — only interaction is '
        'blocked, matching the Production screen pattern)', (tester) async {
      await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_e5b',
          stockpile: tradeableStockpileFilled(99),
        ),
        canMutateViaUi: false,
      );

      final timberRow = find.byKey(
        TradeScreenMarketKeys.marketCommodityRowKey(_timber),
      );
      expect(
        find.descendant(
          of: timberRow,
          matching: find.byKey(
            TradeScreenMarketKeys.marketRowNoneChipKey(_timber),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: timberRow,
          matching: find.byKey(
            TradeScreenMarketKeys.marketRowQuantityTextKey(_timber),
          ),
        ),
        findsOneWidget,
      );
    });
  });
}
