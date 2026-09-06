// Deal Book player-language goldens — still-open / match-tag rows (Refs #4734 Slice G).
// Filled-row goldens: trade_screen_deal_book_player_copy_goldens_test.dart.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_deal_book_player_copy_goldens_support.dart';
import 'trade_screen_deal_book_tab_e6_support.dart';
import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen #4414 Deal Book still-open / tag goldens', () {
    testWidgets('golden: Still open heading + leftover Grain — 8 (AC-3)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>(
        'tradeDealBookStillOpenLeftoverGolden',
      );

      await pumpDealBookPlayerCopyGolden(
        tester,
        boundaryKey: boundaryKey,
        game: buildTradeTestGame(
          players: dealBookTestPlayers,
          carryForwardBids: <String, List<TradeOrder>>{
            kDealBookPlayerCopyHumanPlayerId: <TradeOrder>[
              TradeOrder(
                commodityId: 'grain',
                type: TradeOrderType.bid,
                quantity: 8,
                priority: 2,
              ),
            ],
          },
        ),
        viewport: kDealBookPlayerCopyPanelViewport,
      );

      final Finder bidsPanel = find.byKey(
        TradeScreenDealBookKeys.dealBookBidsPanelKey,
      );

      expect(tester.takeException(), isNull);
      expect(bidsPanel, findsOneWidget);
      expect(find.text('Still open'), findsWidgets);
      expect(find.text('Grain — 8'), findsOneWidget);
      expect(find.text('No matching sales last turn'), findsOneWidget);
      expect(find.text('Unfilled (carry-forward)'), findsNothing);
      expect(find.textContaining('(priority'), findsNothing);

      await expectLater(
        bidsPanel,
        matchesGoldenFile('goldens/trade_deal_book_still_open_leftover.png'),
      );
    });

    testWidgets('golden: None still open in filled-only bids panel (AC-4)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('tradeDealBookNoneStillOpenGolden');

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
        viewport: kDealBookPlayerCopyPanelViewport,
      );

      final Finder bidsPanel = find.byKey(
        TradeScreenDealBookKeys.dealBookBidsPanelKey,
      );

      expect(tester.takeException(), isNull);
      expect(bidsPanel, findsOneWidget);
      expect(find.text('Timber — 5 at £30 = £150'), findsOneWidget);
      expect(find.text('None still open.'), findsOneWidget);
      expect(find.text('No orders carrying forward.'), findsNothing);
      expect(
        find.text(TradeScreenDealBookKeys.dealBookBidsEmptyText),
        findsNothing,
      );

      await expectLater(
        bidsPanel,
        matchesGoldenFile('goldens/trade_deal_book_none_still_open.png'),
      );
    });

    testWidgets(
      'golden: First right and Favored partner tags on filled rows (AC-5)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeDealBookFilledRowMatchTagsGolden',
        );

        await pumpDealBookPlayerCopyGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(
            players: dealBookTestPlayers,
            lastTurnActivity: {
              'timber': dealBookActivity('timber', [
                dealBookFilledDeal(
                  seller: 'M1',
                  buyer: kDealBookPlayerCopyHumanPlayerId,
                  commodity: 'timber',
                  qty: 3,
                  price: 30,
                  frr: true,
                ),
                dealBookFilledDeal(
                  seller: 'gp_a',
                  buyer: kDealBookPlayerCopyHumanPlayerId,
                  commodity: 'timber',
                  qty: 3,
                  price: 30,
                  ftp: true,
                ),
              ]),
            },
          ),
          viewport: kDealBookPlayerCopyPanelViewport,
        );

        final Finder bidsPanel = find.byKey(
          TradeScreenDealBookKeys.dealBookBidsPanelKey,
        );

        expect(tester.takeException(), isNull);
        expect(bidsPanel, findsOneWidget);
        expect(find.text('First right'), findsOneWidget);
        expect(find.text('Favored partner'), findsOneWidget);
        expect(find.text('Timber — 3 at £30 = £90'), findsNWidgets(2));

        await expectLater(
          bidsPanel,
          matchesGoldenFile(
            'goldens/trade_deal_book_filled_row_match_tags.png',
          ),
        );
      },
    );
  });
}
