// Widget goldens for Deal Book player-language ledger copy (Refs #4414).
// Pixel baselines under `app/test/goldens/` close the verify-github-issue
// UI proof gap flagged on issue #4414.
//
// Golden mapping:
//  - AC-1  filled bid row `Timber — 5 at £30 = £150`
//  - AC-2  filled offer row uses `Refined sugar` display name
//  - AC-3  **Still open** heading + leftover `{displayName} — {quantity}`
//  - AC-4  **None still open.** inside a filled-only bids panel
//  - AC-5  **First right** / **Favored partner** tags on filled rows
//
// SPEC: SPEC/ui/trade-screen.md § Deal Book tab — player-language ledger.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen_deal_book.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'trade_screen_deal_book_tab_e6_support.dart';
import 'trade_screen_test_support.dart';

const String _humanPlayerId = kTradeTestHumanPlayerId;
const Size _dealBookPanelViewport = Size(400, 320);
const Size _dealBookRowViewport = Size(520, 120);

Future<void> _pumpDealBookGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  required Size viewport,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: viewport,
    center: false,
    includeLocalizations: true,
    child: SizedBox(
      width: viewport.width,
      height: viewport.height,
      child: SingleChildScrollView(
        child: DealBookTabContent(game: game, playerId: _humanPlayerId),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('TradeScreen #4414 Deal Book player-language goldens', () {
    testWidgets('golden: filled bid row Timber — 5 at £30 = £150 (AC-1)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('tradeDealBookFilledBidRowGolden');

      await _pumpDealBookGolden(
        tester,
        boundaryKey: boundaryKey,
        game: buildTradeTestGame(
          players: dealBookTestPlayers,
          lastTurnActivity: {
            'timber': dealBookActivity('timber', [
              dealBookFilledDeal(
                seller: 'gp_a',
                buyer: _humanPlayerId,
                commodity: 'timber',
                qty: 5,
                price: 30,
              ),
            ]),
          },
        ),
        viewport: _dealBookRowViewport,
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

        await _pumpDealBookGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(
            players: dealBookTestPlayers,
            lastTurnActivity: {
              'refinedSugar': dealBookActivity('refinedSugar', [
                dealBookFilledDeal(
                  seller: _humanPlayerId,
                  buyer: 'gp_a',
                  commodity: 'refinedSugar',
                  qty: 2,
                  price: 70,
                ),
              ]),
            },
          ),
          viewport: _dealBookRowViewport,
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

    testWidgets('golden: Still open heading + leftover Grain — 8 (AC-3)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>(
        'tradeDealBookStillOpenLeftoverGolden',
      );

      await _pumpDealBookGolden(
        tester,
        boundaryKey: boundaryKey,
        game: buildTradeTestGame(
          players: dealBookTestPlayers,
          carryForwardBids: <String, List<TradeOrder>>{
            _humanPlayerId: <TradeOrder>[
              TradeOrder(
                commodityId: 'grain',
                type: TradeOrderType.bid,
                quantity: 8,
                priority: 2,
              ),
            ],
          },
        ),
        viewport: _dealBookPanelViewport,
      );

      final Finder bidsPanel = find.byKey(
        TradeScreenDealBookKeys.dealBookBidsPanelKey,
      );

      expect(tester.takeException(), isNull);
      expect(bidsPanel, findsOneWidget);
      expect(find.text('Still open'), findsWidgets);
      expect(find.text('Grain — 8'), findsOneWidget);
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

      await _pumpDealBookGolden(
        tester,
        boundaryKey: boundaryKey,
        game: buildTradeTestGame(
          players: dealBookTestPlayers,
          lastTurnActivity: {
            'timber': dealBookActivity('timber', [
              dealBookFilledDeal(
                seller: 'gp_a',
                buyer: _humanPlayerId,
                commodity: 'timber',
                qty: 5,
                price: 30,
              ),
            ]),
          },
        ),
        viewport: _dealBookPanelViewport,
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

        await _pumpDealBookGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(
            players: dealBookTestPlayers,
            lastTurnActivity: {
              'timber': dealBookActivity('timber', [
                dealBookFilledDeal(
                  seller: 'M1',
                  buyer: _humanPlayerId,
                  commodity: 'timber',
                  qty: 3,
                  price: 30,
                  frr: true,
                ),
                dealBookFilledDeal(
                  seller: 'gp_a',
                  buyer: _humanPlayerId,
                  commodity: 'timber',
                  qty: 3,
                  price: 30,
                  ftp: true,
                ),
              ]),
            },
          ),
          viewport: _dealBookPanelViewport,
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
