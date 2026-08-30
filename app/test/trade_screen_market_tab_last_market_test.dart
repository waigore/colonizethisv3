// Widget tests for Market Last market chip (Refs #4653).
// SPEC/ui/trade-screen.md § Market tab — last market chip.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen_market_tab_catalog_data.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

const String _humanPlayerId = kTradeTestHumanPlayerId;

void main() {
  suppressLogsForTests();

  group('showLastMarketChip helper (#4653)', () {
    test('false when both totals are 0 or activity is empty', () {
      expect(showLastMarketChip(MarketActivity.empty), isFalse);
      expect(
        showLastMarketChip(
          const MarketActivity(totalBidQuantity: 0, totalOfferQuantity: 0),
        ),
        isFalse,
      );
    });

    test('true when either volume total is positive', () {
      expect(
        showLastMarketChip(
          const MarketActivity(totalBidQuantity: 1, totalOfferQuantity: 0),
        ),
        isTrue,
      );
      expect(
        showLastMarketChip(
          const MarketActivity(totalBidQuantity: 0, totalOfferQuantity: 4),
        ),
        isTrue,
      );
    });
  });

  group('TradeScreen Market Last market chip (Refs #4653)', () {
    testWidgets(
      'on-request copy states worldwide bought/sold and is not staged Bid/Offer',
      (tester) async {
        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(
            lastTurnActivity: const <CommodityId, MarketActivity>{
              'timber': MarketActivity(
                totalBidQuantity: 12,
                totalOfferQuantity: 8,
              ),
            },
          ),
          viewport: const Size(400, 4096),
        );

        final Finder chip = find.byKey(
          TradeScreenMarketKeys.marketRowLastMarketChipKey(
            CommodityCatalog.timber.id,
          ),
        );
        expect(chip, findsOneWidget);
        final Tooltip tip = tester.widget<Tooltip>(
          find.ancestor(of: chip, matching: find.byType(Tooltip)).first,
        );
        expect(tip.message, contains('12 bought'));
        expect(tip.message, contains('8 sold worldwide'));
        expect(tip.message, contains('not your staged Bid or Offer'));
        expect(tip.message, isNot(contains('bids')));
        expect(tip.message, isNot(contains('offers')));
      },
    );

    testWidgets('Last market still reflects world volume after staging a Bid', (
      tester,
    ) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          stockpile: tradeableStockpileFilled(10),
          lastTurnActivity: const <CommodityId, MarketActivity>{
            'timber': MarketActivity(
              totalBidQuantity: 12,
              totalOfferQuantity: 8,
            ),
          },
        ),
      );

      await tester.tap(
        find.byKey(
          TradeScreenMarketKeys.marketRowBidChipKey(CommodityCatalog.timber.id),
        ),
      );
      await tester.pump();

      final Orders orders = container.read(currentOrdersProvider);
      expect(orders.tradeOrdersByPlayerId[_humanPlayerId], isNotEmpty);

      final Finder chip = find.byKey(
        TradeScreenMarketKeys.marketRowLastMarketChipKey(
          CommodityCatalog.timber.id,
        ),
      );
      final Tooltip tip = tester.widget<Tooltip>(
        find.ancestor(of: chip, matching: find.byType(Tooltip)).first,
      );
      expect(tip.message, contains('12 bought'));
      expect(tip.message, contains('8 sold'));
    });

    testWidgets(
      'observe mode keeps Last market tooltip reachable and does not stage',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            lastTurnActivity: const <CommodityId, MarketActivity>{
              'timber': MarketActivity(
                totalBidQuantity: 4,
                totalOfferQuantity: 2,
              ),
            },
          ),
          canMutateViaUi: false,
          viewport: const Size(400, 4096),
        );

        final Finder chip = find.byKey(
          TradeScreenMarketKeys.marketRowLastMarketChipKey(
            CommodityCatalog.timber.id,
          ),
        );
        expect(chip, findsOneWidget);
        final Tooltip tip = tester.widget<Tooltip>(
          find.ancestor(of: chip, matching: find.byType(Tooltip)).first,
        );
        expect(tip.message, contains('4 bought'));

        await tester.tap(
          find.byKey(
            TradeScreenMarketKeys.marketRowBidChipKey(
              CommodityCatalog.timber.id,
            ),
          ),
          warnIfMissed: false,
        );
        await tester.pump();
        expect(
          container
              .read(currentOrdersProvider)
              .tradeOrdersByPlayerId[_humanPlayerId],
          isNull,
        );
      },
    );
  });
}
