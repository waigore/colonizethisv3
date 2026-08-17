// Deal Book leftover reason Details affordance widget tests (Refs #4500).
// SPEC/ui/trade-screen.md § Deal Book leftover reasons.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_deal_book_leftover_reasons_widget_support.dart';
import 'trade_screen_deal_book_tab_e6_support.dart';
import 'trade_screen_test_game_builders.dart';
import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen Deal Book leftover Details (Refs #4500)', () {
    testWidgets('Details tap expands next-step line for treasury-short row', (
      tester,
    ) async {
      final game = buildTradeTestGame(
        players: dealBookTestPlayers,
        lastTurnActivity: {
          'timber': dealBookActivityWithNotes(
            commodity: 'timber',
            notes: <MarketActivityNote>[
              MarketActivityNote(
                kind: MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
                factionId: kTradeTestHumanPlayerId,
                commodityId: 'timber',
                quantity: 10,
              ),
            ],
          ),
        },
        carryForwardBids: <String, List<TradeOrder>>{
          kTradeTestHumanPlayerId: <TradeOrder>[
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.bid,
              quantity: 5,
              priority: 1,
            ),
          ],
        },
      );
      await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

      expect(
        find.text(
          'Free treasury by canceling other bids or waiting for income.',
        ),
        findsNothing,
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
      expect(
        find.text(
          'Free treasury by canceling other bids or waiting for income.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('bidPartialFill'), findsNothing);
    });

    testWidgets('Details tap on cargo-drop row expands add-cargo next-step', (
      tester,
    ) async {
      final game = buildTradeTestGame(
        players: dealBookTestPlayers,
        lastTurnActivity: {
          'timber': dealBookActivityWithNotes(
            commodity: 'timber',
            notes: <MarketActivityNote>[
              MarketActivityNote(
                kind:
                    MarketActivityNoteKind.carryForwardDroppedCargoInsufficient,
                factionId: kTradeTestHumanPlayerId,
                commodityId: 'timber',
                quantity: 8,
              ),
            ],
          ),
        },
      );
      await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

      await tester.tap(
        find.byKey(
          TradeScreenDealBookKeys.dealBookDetailsAffordanceKey(
            TradeScreenDealBookKeys.dealBookRowKindDidNotStayOpen,
            'timber',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Add cargo to your home fleet or reduce bid quantity.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('carryForwardDroppedCargoInsufficient'),
        findsNothing,
      );
    });

    testWidgets(
      'Details tap on stockpile-drop row expands keep-stock next-step',
      (tester) async {
        final game = buildTradeTestGame(
          players: dealBookTestPlayers,
          lastTurnActivity: {
            'grain': dealBookActivityWithNotes(
              commodity: 'grain',
              notes: <MarketActivityNote>[
                MarketActivityNote(
                  kind: MarketActivityNoteKind
                      .carryForwardDroppedStockpileInsufficient,
                  factionId: kTradeTestHumanPlayerId,
                  commodityId: 'grain',
                  quantity: 6,
                ),
              ],
            ),
          },
        );
        await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

        await tester.tap(
          find.byKey(
            TradeScreenDealBookKeys.dealBookDetailsAffordanceKey(
              TradeScreenDealBookKeys.dealBookRowKindDidNotStayOpen,
              'grain',
            ),
          ),
        );
        await tester.pumpAndSettle();
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
      },
    );
  });
}
