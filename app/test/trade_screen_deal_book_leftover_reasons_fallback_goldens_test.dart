// Deal Book leftover-reason goldens — no-matching fallback rows (Refs #4734 Slice G).
// Primary leftover goldens: trade_screen_deal_book_leftover_reasons_goldens_test.dart.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_deal_book_leftover_reasons_goldens_support.dart';
import 'trade_screen_deal_book_tab_e6_support.dart';
import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen #4500 Deal Book fallback reason goldens', () {
    testWidgets(
      'golden: bids panel No matching sales last turn fallback (AC-4)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeDealBookStillOpenBidFallbackGolden',
        );

        await pumpDealBookLeftoverReasonGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(
            players: dealBookTestPlayers,
            lastTurnActivity: {
              'timber': dealBookActivityWithNotes(
                commodity: 'timber',
                totalOfferQuantity: 0,
              ),
            },
            carryForwardBids: <String, List<TradeOrder>>{
              kDealBookLeftoverGoldensHumanPlayerId: <TradeOrder>[
                TradeOrder(
                  commodityId: 'timber',
                  type: TradeOrderType.bid,
                  quantity: 3,
                  priority: 1,
                ),
              ],
            },
          ),
          viewport: kDealBookLeftoverGoldensPanelViewport,
        );

        final Finder bidsPanel = find.byKey(
          TradeScreenDealBookKeys.dealBookBidsPanelKey,
        );

        expect(tester.takeException(), isNull);
        expect(bidsPanel, findsOneWidget);
        expect(find.text('Timber — 3'), findsOneWidget);
        expect(find.text('No matching sales last turn'), findsOneWidget);

        await expectLater(
          bidsPanel,
          matchesGoldenFile(
            'goldens/trade_deal_book_still_open_bid_no_matching_sales.png',
          ),
        );
      },
    );

    testWidgets(
      'golden: offers panel No matching buys last turn fallback (AC-5)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeDealBookStillOpenOfferFallbackGolden',
        );

        await pumpDealBookLeftoverReasonGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(
            players: dealBookTestPlayers,
            lastTurnActivity: {
              'grain': dealBookActivityWithNotes(
                commodity: 'grain',
                totalBidQuantity: 0,
              ),
            },
            carryForwardOffers: <String, List<TradeOrder>>{
              kDealBookLeftoverGoldensHumanPlayerId: <TradeOrder>[
                TradeOrder(
                  commodityId: 'grain',
                  type: TradeOrderType.offer,
                  quantity: 4,
                  priority: 1,
                ),
              ],
            },
          ),
          viewport: kDealBookLeftoverGoldensPanelViewport,
        );

        final Finder offersPanel = find.byKey(
          TradeScreenDealBookKeys.dealBookOffersPanelKey,
        );

        expect(tester.takeException(), isNull);
        expect(offersPanel, findsOneWidget);
        expect(find.text('Grain — 4'), findsOneWidget);
        expect(find.text('No matching buys last turn'), findsOneWidget);

        await expectLater(
          offersPanel,
          matchesGoldenFile(
            'goldens/trade_deal_book_still_open_offer_no_matching_buys.png',
          ),
        );
      },
    );
  });
}
