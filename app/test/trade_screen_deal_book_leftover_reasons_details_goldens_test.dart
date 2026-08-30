// Widget goldens for Deal Book leftover Details next-step lines (Refs #4500).
// Pixel baselines under `app/test/goldens/` close the verify-github-issue
// UI proof gap flagged on issue #4500 AC-7.
//
// Golden mapping:
//  - AC-7  Details expanded next-step line (treasury-short, cargo-drop,
//          and stockpile-drop rows)
//
// SPEC: SPEC/ui/trade-screen.md § Deal Book tab — leftover reasons.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_deal_book_leftover_reasons_goldens_support.dart';
import 'trade_screen_deal_book_leftover_reasons_widget_support.dart';
import 'trade_screen_deal_book_tab_e6_support.dart';
import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen #4500 Deal Book leftover Details goldens', () {
    testWidgets('golden: Details expanded next-step line (AC-7)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>(
        'tradeDealBookDetailsExpandedGolden',
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
        viewport: kDealBookLeftoverGoldensRowViewport,
      );

      await tester.tap(
        find.byKey(
          TradeScreenDealBookKeys.dealBookDetailsAffordanceKey(
            TradeScreenDealBookKeys.dealBookRowKindStillOpen,
            'timber',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder stillOpenRow = find.byKey(
        TradeScreenDealBookKeys.dealBookUnfilledRowKey(
          TradeScreenDealBookKeys.dealBookSideBids,
          0,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(stillOpenRow, findsOneWidget);
      expect(
        find.text(
          'Free treasury by canceling other bids or waiting for income.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('bidPartialFill'), findsNothing);

      await expectLater(
        stillOpenRow,
        matchesGoldenFile(
          'goldens/trade_deal_book_details_expanded_treasury_short.png',
        ),
      );
    });

    testWidgets('golden: Details expanded cargo-drop next-step (AC-7)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>(
        'tradeDealBookDetailsExpandedCargoDropGolden',
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

      final Finder cargoDetails = find.byKey(
        TradeScreenDealBookKeys.dealBookDetailsAffordanceKey(
          TradeScreenDealBookKeys.dealBookRowKindDidNotStayOpen,
          'timber',
        ),
      );
      await tester.ensureVisible(cargoDetails);
      await tester.tap(cargoDetails);
      await tester.pumpAndSettle();

      final Finder dropRow = find.byKey(
        TradeScreenDealBookKeys.dealBookDidNotStayOpenRowKey(
          TradeScreenDealBookKeys.dealBookSideBids,
          0,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(dropRow, findsOneWidget);
      await tester.ensureVisible(dropRow);
      await tester.pump();
      expect(
        find.text('Add cargo to your home fleet or reduce bid quantity.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('carryForwardDroppedCargoInsufficient'),
        findsNothing,
      );

      await expectLater(
        dropRow,
        matchesGoldenFile(
          'goldens/trade_deal_book_details_expanded_cargo_drop.png',
        ),
      );
    });

    testWidgets('golden: Details expanded stockpile-drop next-step (AC-7)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>(
        'tradeDealBookDetailsExpandedStockpileDropGolden',
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

      final Finder stockpileDetails = find.byKey(
        TradeScreenDealBookKeys.dealBookDetailsAffordanceKey(
          TradeScreenDealBookKeys.dealBookRowKindDidNotStayOpen,
          'grain',
        ),
      );
      await tester.ensureVisible(stockpileDetails);
      await tester.tap(stockpileDetails);
      await tester.pumpAndSettle();

      final Finder dropRow = find.byKey(
        TradeScreenDealBookKeys.dealBookDidNotStayOpenRowKey(
          TradeScreenDealBookKeys.dealBookSideOffers,
          0,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(dropRow, findsOneWidget);
      await tester.ensureVisible(dropRow);
      await tester.pump();
      expect(
        find.text(
          'Keep enough stock in your warehouses to cover leftover sales.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('carryForwardDroppedStockpileInsufficient'),
        findsNothing,
      );

      await expectLater(
        dropRow,
        matchesGoldenFile(
          'goldens/trade_deal_book_details_expanded_stockpile_drop.png',
        ),
      );
    });
  });
}
