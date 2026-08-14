// Deal Book tab two-panel layout pins (Refs #4352).
// SPEC/ui/trade-screen.md § Body — Deal Book tab.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_deal_book_tab_e6_support.dart';
import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen Deal Book tab layout (Refs #2993 E6)', () {
    testWidgets('side-by-side layout: when the viewport is at least '
        'dealBookTwoPanelMinWidth (600 dp) wide, the bids panel sits to '
        'the left of the offers panel', (tester) async {
      tester.view.physicalSize = const Size(700 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpTradeScreen(
        tester,
        game: buildTradeTestGame(players: dealBookTestPlayers),
        selectDealBookTab: true,
      );

      final Offset bidsTopLeft = tester.getTopLeft(
        find.byKey(TradeScreenDealBookKeys.dealBookBidsPanelKey),
      );
      final Offset offersTopLeft = tester.getTopLeft(
        find.byKey(TradeScreenDealBookKeys.dealBookOffersPanelKey),
      );

      expect(
        offersTopLeft.dx,
        greaterThan(bidsTopLeft.dx),
        reason:
            'SPEC/ui/trade-screen.md § Body — Deal Book tab pins the '
            'bids panel to the left of the offers panel when the '
            'viewport meets the dealBookTwoPanelMinWidth threshold.',
      );
      expect(
        offersTopLeft.dy,
        equals(bidsTopLeft.dy),
        reason:
            'Two-panel mode aligns the bids and offers panels at the '
            'same top so the ledger reads as one row.',
      );
    });

    testWidgets(
      'stacked layout: at the 320 dp minimum viewport the offers panel '
      'sits below the bids panel (no overflow)',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(players: dealBookTestPlayers),
          selectDealBookTab: true,
        );

        expect(tester.takeException(), isNull);

        final Offset bidsTopLeft = tester.getTopLeft(
          find.byKey(TradeScreenDealBookKeys.dealBookBidsPanelKey),
        );
        final Offset offersTopLeft = tester.getTopLeft(
          find.byKey(TradeScreenDealBookKeys.dealBookOffersPanelKey),
        );
        expect(
          offersTopLeft.dy,
          greaterThan(bidsTopLeft.dy),
          reason:
              'Below dealBookTwoPanelMinWidth the panels stack so the '
              'Deal Book stays overflow-safe at the 320 dp pin.',
        );
      },
    );
  });
}
