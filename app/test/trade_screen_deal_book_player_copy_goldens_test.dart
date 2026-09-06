// Widget goldens for Deal Book player-language ledger copy (Refs #4414).
// Still-open / tag goldens: trade_screen_deal_book_player_copy_still_open_goldens_test.dart.
// SPEC: SPEC/ui/trade-screen.md § Deal Book tab — player-language ledger.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_deal_book_player_copy_goldens_support.dart';
import 'trade_screen_deal_book_tab_e6_support.dart';
import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen #4414 Deal Book player-language goldens', () {
    testWidgets('golden: filled bid row Timber — 5 at £30 = £150 (AC-1)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('tradeDealBookFilledBidRowGolden');

      await pumpDealBookPlayerCopyGolden(
        tester,
        boundaryKey: boundaryKey,
        game: buildTradeTestGame(
          players: dealBookTestPlayers,
          lastTurnActivity: {
            'timber': dealBookActivity('timber', [
              dealBookFilledDeal(
                seller: 'gp_a',
                buyer: kDealBookPlayerCopyHumanPlayerId,
                commodity: 'timber',
                qty: 5,
                price: 30,
              ),
            ]),
          },
        ),
        viewport: kDealBookPlayerCopyRowViewport,
      );

      final Finder filledRow = find.byKey(
        TradeScreenDealBookKeys.dealBookFilledRowKey(
          TradeScreenDealBookKeys.dealBookSideBids,
          0,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(filledRow, findsOneWidget);
      expect(find.text('Timber — 5 at £30 = £150'), findsOneWidget);
      expect(find.textContaining('timber — qty'), findsNothing);

      await expectLater(
        filledRow,
        matchesGoldenFile('goldens/trade_deal_book_filled_bid_row.png'),
      );
    });

    testWidgets(
      'golden: filled offer row uses Refined sugar display name (AC-2)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeDealBookFilledOfferRowGolden',
        );

        await pumpDealBookPlayerCopyGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(
            players: dealBookTestPlayers,
            lastTurnActivity: {
              'refinedSugar': dealBookActivity('refinedSugar', [
                dealBookFilledDeal(
                  seller: kDealBookPlayerCopyHumanPlayerId,
                  buyer: 'gp_a',
                  commodity: 'refinedSugar',
                  qty: 2,
                  price: 70,
                ),
              ]),
            },
          ),
          viewport: kDealBookPlayerCopyRowViewport,
        );

        final Finder filledRow = find.byKey(
          TradeScreenDealBookKeys.dealBookFilledRowKey(
            TradeScreenDealBookKeys.dealBookSideOffers,
            0,
          ),
        );

        expect(tester.takeException(), isNull);
        expect(filledRow, findsOneWidget);
        expect(find.text('Refined sugar — 2 at £70 = £140'), findsOneWidget);
        expect(find.textContaining('refinedSugar'), findsNothing);

        await expectLater(
          filledRow,
          matchesGoldenFile('goldens/trade_deal_book_filled_offer_row.png'),
        );
      },
    );
  });
}
