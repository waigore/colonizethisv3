// Deal Book player-language ledger copy (Refs #4414).
// SPEC/ui/trade-screen.md § Deal Book tab — player-language ledger.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_deal_book_tab_e6_support.dart';
import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen Deal Book player-language copy (Refs #4414)', () {
    testWidgets(
      'filled offer uses commodity display name, not the raw catalog id',
      (tester) async {
        final game = buildTradeTestGame(
          players: dealBookTestPlayers,
          lastTurnActivity: {
            'refinedSugar': dealBookActivity('refinedSugar', [
              dealBookFilledDeal(
                seller: 'gp_h',
                buyer: 'gp_a',
                commodity: 'refinedSugar',
                qty: 2,
                price: 70,
              ),
            ]),
          },
        );
        await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

        expect(find.text('Refined sugar — 2 at £70 = £140'), findsOneWidget);
        expect(find.textContaining('refinedSugar'), findsNothing);
      },
    );

    testWidgets('leftover section heading is Still open and omits priority', (
      tester,
    ) async {
      final game = buildTradeTestGame(
        players: dealBookTestPlayers,
        carryForwardBids: <String, List<TradeOrder>>{
          'gp_h': <TradeOrder>[
            TradeOrder(
              commodityId: 'grain',
              type: TradeOrderType.bid,
              quantity: 8,
              priority: 2,
            ),
          ],
        },
      );
      await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

      expect(
        find.text(TradeScreenDealBookKeys.dealBookUnfilledHeading),
        findsWidgets,
      );
      expect(find.text('Unfilled (carry-forward)'), findsNothing);
      expect(find.text('Grain — 8'), findsOneWidget);
      expect(find.textContaining('(priority'), findsNothing);
    });

    testWidgets(
      'filled-only panel shows None still open, not the panel-level empty copy',
      (tester) async {
        final game = buildTradeTestGame(
          players: dealBookTestPlayers,
          lastTurnActivity: {
            'timber': dealBookActivity('timber', [
              dealBookFilledDeal(
                seller: 'gp_a',
                buyer: 'gp_h',
                commodity: 'timber',
                qty: 5,
                price: 30,
              ),
            ]),
          },
        );
        await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

        expect(
          find.text(TradeScreenDealBookKeys.dealBookUnfilledEmptyText),
          findsOneWidget,
        );
        expect(find.text('No orders carrying forward.'), findsNothing);
        expect(
          find.text(TradeScreenDealBookKeys.dealBookBidsEmptyText),
          findsNothing,
        );
      },
    );

    testWidgets(
      'First right and Favored partner tags still render on filled rows',
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
                price: 30,
                frr: true,
              ),
              dealBookFilledDeal(
                seller: 'gp_a',
                buyer: 'gp_h',
                commodity: 'timber',
                qty: 3,
                price: 30,
                ftp: true,
              ),
            ]),
          },
        );
        await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

        expect(find.text('First right'), findsOneWidget);
        expect(find.text('Favored partner'), findsOneWidget);
        expect(find.text('Timber — 3 at £30 = £90'), findsNWidgets(2));
      },
    );

    testWidgets(
      '320 dp leftover row with a long display name does not overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final game = buildTradeTestGame(
          players: dealBookTestPlayers,
          carryForwardOffers: <String, List<TradeOrder>>{
            'gp_h': <TradeOrder>[
              TradeOrder(
                commodityId: 'refinedSugar',
                type: TradeOrderType.offer,
                quantity: 4,
                priority: 1,
              ),
            ],
          },
        );
        await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

        expect(tester.takeException(), isNull);
        expect(find.text('Refined sugar — 4'), findsOneWidget);
      },
    );
  });
}
