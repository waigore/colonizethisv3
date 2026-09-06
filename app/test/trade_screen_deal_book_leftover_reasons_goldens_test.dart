// Widget goldens for Deal Book leftover reason rows (Refs #4500).
// Fallback goldens: trade_screen_deal_book_leftover_reasons_fallback_goldens_test.dart.
// SPEC: SPEC/ui/trade-screen.md § Deal Book tab — leftover reasons.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_deal_book_leftover_reasons_goldens_support.dart';
import 'trade_screen_deal_book_leftover_reasons_widget_support.dart'
    show dealBookActivityWithNotes;
import 'trade_screen_deal_book_tab_e6_support.dart';
import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen #4500 Deal Book leftover reason goldens', () {
    testWidgets('golden: Still open treasury-short reason line (AC-1)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>(
        'tradeDealBookTreasuryShortReasonGolden',
      );

      await pumpDealBookLeftoverReasonGolden(
        tester,
        boundaryKey: boundaryKey,
        game: buildTradeTestGame(
          players: dealBookTestPlayers,
          lastTurnActivity: {
            'timber': dealBookActivityWithNotes(
              commodity: 'timber',
              notes: <MarketActivityNote>[
                MarketActivityNote(
                  kind:
                      MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
                  factionId: kDealBookLeftoverGoldensHumanPlayerId,
                  commodityId: 'timber',
                  quantity: 10,
                ),
              ],
            ),
          },
          carryForwardBids: <String, List<TradeOrder>>{
            kDealBookLeftoverGoldensHumanPlayerId: <TradeOrder>[
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.bid,
                quantity: 5,
                priority: 1,
              ),
            ],
          },
        ),
        viewport: kDealBookLeftoverGoldensPanelViewport,
      );

      final Finder stillOpenRow = find.byKey(
        TradeScreenDealBookKeys.dealBookUnfilledRowKey(
          TradeScreenDealBookKeys.dealBookSideBids,
          0,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(stillOpenRow, findsOneWidget);
      expect(find.text('Timber — 5'), findsOneWidget);
      expect(
        find.text('Treasury ran short — leftover stays open'),
        findsOneWidget,
      );
      expect(find.textContaining('bidPartialFill'), findsNothing);

      await expectLater(
        stillOpenRow,
        matchesGoldenFile(
          'goldens/trade_deal_book_still_open_treasury_short_reason.png',
        ),
      );
    });

    testWidgets('golden: bids panel Did not stay open cargo-drop row (AC-2)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>(
        'tradeDealBookDidNotStayOpenCargoDropGolden',
      );

      await pumpDealBookLeftoverReasonGolden(
        tester,
        boundaryKey: boundaryKey,
        game: buildTradeTestGame(
          players: dealBookTestPlayers,
          lastTurnActivity: {
            'timber': dealBookActivityWithNotes(
              commodity: 'timber',
              notes: <MarketActivityNote>[
                MarketActivityNote(
                  kind: MarketActivityNoteKind
                      .carryForwardDroppedCargoInsufficient,
                  factionId: kDealBookLeftoverGoldensHumanPlayerId,
                  commodityId: 'timber',
                  quantity: 8,
                ),
              ],
            ),
          },
        ),
        viewport: kDealBookLeftoverGoldensPanelViewport,
      );

      final Finder bidsPanel = find.byKey(
        TradeScreenDealBookKeys.dealBookBidsPanelKey,
      );

      expect(tester.takeException(), isNull);
      expect(bidsPanel, findsOneWidget);
      expect(
        find.text(TradeScreenDealBookKeys.dealBookDidNotStayOpenHeading),
        findsOneWidget,
      );
      expect(
        find.text('Timber — 8 — leftover cargo no longer covered this bid'),
        findsOneWidget,
      );
      expect(find.text('Timber — 8'), findsNothing);

      await expectLater(
        bidsPanel,
        matchesGoldenFile(
          'goldens/trade_deal_book_did_not_stay_open_cargo_drop_bids.png',
        ),
      );
    });

    testWidgets(
      'golden: offers panel Did not stay open stockpile-drop row (AC-3)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeDealBookDidNotStayOpenStockpileDropGolden',
        );

        await pumpDealBookLeftoverReasonGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(
            players: dealBookTestPlayers,
            lastTurnActivity: {
              'grain': dealBookActivityWithNotes(
                commodity: 'grain',
                notes: <MarketActivityNote>[
                  MarketActivityNote(
                    kind: MarketActivityNoteKind
                        .carryForwardDroppedStockpileInsufficient,
                    factionId: kDealBookLeftoverGoldensHumanPlayerId,
                    commodityId: 'grain',
                    quantity: 6,
                  ),
                ],
              ),
            },
          ),
          viewport: kDealBookLeftoverGoldensPanelViewport,
        );

        final Finder offersPanel = find.byKey(
          TradeScreenDealBookKeys.dealBookOffersPanelKey,
        );

        expect(tester.takeException(), isNull);
        expect(offersPanel, findsOneWidget);
        expect(
          find.text('Grain — 6 — stores no longer covered this sale'),
          findsOneWidget,
        );

        await expectLater(
          offersPanel,
          matchesGoldenFile(
            'goldens/trade_deal_book_did_not_stay_open_stockpile_drop_offers.png',
          ),
        );
      },
    );
  });
}
