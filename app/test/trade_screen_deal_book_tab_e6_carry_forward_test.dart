// Widget tests for the Deal Book tab live ledger (Refs #2993 E6).
// SPEC/ui/trade-screen.md § Body — Deal Book tab.
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';
import 'trade_screen_deal_book_tab_e6_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen Deal Book tab — live ledger (Refs #2993 E6)', () {
    testWidgets(
      'carry-forward bids render in the bids panel and do NOT contribute '
      'to the total spent (they have not cleared)',
      (tester) async {
        final game = buildTradeTestGame(
          players: dealBookTestPlayers,
          carryForwardBids: <String, List<TradeOrder>>{
            'gp_h': <TradeOrder>[
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.bid,
                quantity: 8,
                priority: 2,
              ),
            ],
          },
        );
        await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

        expect(
          find.byKey(
            TradeScreenDealBookKeys.dealBookUnfilledRowKey(
              TradeScreenDealBookKeys.dealBookSideBids,
              0,
            ),
          ),
          findsOneWidget,
        );
        // ignore: avoid_hardcoded_strings_in_widgets
        expect(find.text('Timber — 8'), findsOneWidget);
        expect(find.textContaining('(priority'), findsNothing);
        expect(find.textContaining('timber — qty'), findsNothing);
        expect(
          find.byKey(
            TradeScreenDealBookKeys.dealBookFilledRowKey(
              TradeScreenDealBookKeys.dealBookSideBids,
              0,
            ),
          ),
          findsNothing,
        );
        expectDealBookTotals(tester, bids: 0);
        expect(
          find.byKey(TradeScreenDealBookKeys.dealBookBidsEmptyKey),
          findsNothing,
        );
        expect(
          find.byKey(TradeScreenDealBookKeys.dealBookOffersEmptyKey),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'carry-forward offers render in the offers panel; per-side filter '
      'isolation: another player\'s carry-forwards never appear',
      (tester) async {
        final game = buildTradeTestGame(
          players: dealBookTestPlayers,
          carryForwardOffers: <String, List<TradeOrder>>{
            'gp_h': <TradeOrder>[
              TradeOrder(
                commodityId: 'fabric',
                type: TradeOrderType.offer,
                quantity: 6,
                priority: 1,
              ),
              TradeOrder(
                commodityId: 'fabric',
                type: TradeOrderType.offer,
                quantity: 4,
                priority: 3,
              ),
            ],
            'gp_a': <TradeOrder>[
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.offer,
                quantity: 99,
                priority: 1,
              ),
            ],
          },
        );
        await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

        expect(
          find.byKey(
            TradeScreenDealBookKeys.dealBookUnfilledRowKey(
              TradeScreenDealBookKeys.dealBookSideOffers,
              0,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            TradeScreenDealBookKeys.dealBookUnfilledRowKey(
              TradeScreenDealBookKeys.dealBookSideOffers,
              1,
            ),
          ),
          findsOneWidget,
        );
        // ignore: avoid_hardcoded_strings_in_widgets
        expect(find.text('Timber — 99'), findsNothing);
        expect(find.textContaining('(priority'), findsNothing);
      },
    );

    testWidgets(
      'FRR / FTP tags render on filled rows when the matcher annotated '
      'the deal so players can audit how a fill cleared',
      (tester) async {
        final game = buildTradeTestGame(
          players: dealBookTestPlayers,
          lastTurnActivity: {
            'timber': dealBookActivity('timber', [
              dealBookFilledDeal(
                seller: 'M1',
                buyer: 'gp_h',
                commodity: 'timber',
                qty: 3,
                price: 30.0,
                frr: true,
                sellerOriginTileKey: 'oldWorld|M1|0|0',
              ),
              dealBookFilledDeal(
                seller: 'gp_a',
                buyer: 'gp_h',
                commodity: 'timber',
                qty: 3,
                price: 30.0,
                ftp: true,
              ),
            ]),
          },
        );
        await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

        expect(
          find.byKey(
            TradeScreenDealBookKeys.dealBookFilledRowKey(
              TradeScreenDealBookKeys.dealBookSideBids,
              0,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            TradeScreenDealBookKeys.dealBookFilledRowKey(
              TradeScreenDealBookKeys.dealBookSideBids,
              1,
            ),
          ),
          findsOneWidget,
        );
        expect(find.text('First right'), findsOneWidget);
        expect(find.text('Favored partner'), findsOneWidget);
        expectDealBookTotals(tester, bids: 180);
      },
    );
  });
}
