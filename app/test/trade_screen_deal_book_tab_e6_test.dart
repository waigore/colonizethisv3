// Widget tests for the Deal Book tab live ledger (Refs #2993 E6).
// SPEC/ui/trade-screen.md § Body — Deal Book tab.
//
// Exercises the durable contract for the Deal Book tab body:
//
//  * the live `_DealBookTabContent` mounts under
//    `tradeScreenDealBookTabBody` with both bids and offers panels and
//    treasury-totals rows always present (so widget tests can pin the
//    totals affordance regardless of activity);
//  * filled rows are sourced from
//    `Game.worldMarketState.lastTurnActivity[*].deals`, scoped per
//    panel by `buyerFactionId` (bids panel) and `sellerFactionId`
//    (offers panel), with `quantity × pricePerUnit` summed into the
//    totals row;
//  * unfilled rows are sourced from
//    `WorldMarketState.carryForward{Bids,Offers}ByFactionId[playerId]`
//    so the previous turn's carry-forward orders are visible;
//  * empty-state copy renders when the player has neither filled rows
//    nor carry-forward orders on a side;
//  * FRR / FTP tags render on filled rows that the matcher annotated
//    so the player can audit why a deal cleared.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/trade_screen_test_support.dart';

const List<Player> _players = <Player>[
  // ignore: avoid_hardcoded_strings_in_widgets
  Player(
    id: kTradeTestHumanPlayerId,
    displayName: 'England',
    isHuman: true,
    treasury: 500,
  ),
  // ignore: avoid_hardcoded_strings_in_widgets
  Player(id: 'gp_a', displayName: 'Aragon', isHuman: false, treasury: 500),
];

FilledDeal _deal({
  required String seller,
  required String buyer,
  required String commodity,
  required int qty,
  required double price,
  bool frr = false,
  bool ftp = false,
  String? sellerOriginTileKey,
}) {
  return FilledDeal(
    sellerFactionId: seller,
    buyerFactionId: buyer,
    commodityId: commodity,
    quantity: qty,
    pricePerUnit: price,
    isFirstRightOfRefusalMatch: frr,
    isFtpMatch: ftp,
    sellerOriginTileKey: sellerOriginTileKey,
  );
}

MarketActivity _activity(String commodity, List<FilledDeal> deals) {
  final qty = deals.fold<int>(0, (sum, d) => sum + d.quantity);
  return MarketActivity(
    totalBidQuantity: qty,
    totalOfferQuantity: qty,
    filledQuantity: qty,
    deals: deals,
  );
}

void _expectTotals(WidgetTester tester, {int? bids, int? offers}) {
  if (bids != null) {
    final bidsTotals = tester.widget<Text>(
      find.byKey(TradeScreen.dealBookBidsTotalsKey),
    );
    expect(bidsTotals.data, '${TradeScreen.dealBookTotalSpentLabel}: $bids');
  }
  if (offers != null) {
    final offersTotals = tester.widget<Text>(
      find.byKey(TradeScreen.dealBookOffersTotalsKey),
    );
    expect(
      offersTotals.data,
      '${TradeScreen.dealBookTotalReceivedLabel}: $offers',
    );
  }
}

void main() {
  suppressLogsForTests();

  group('TradeScreen Deal Book tab — live ledger (Refs #2993 E6)', () {
    testWidgets(
      'empty state: panels show empty copy and totals read 0 when the '
      'player has no filled deals and no carry-forwards',
      (tester) async {
        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(players: _players),
          selectDealBookTab: true,
        );

        expect(find.byKey(TradeScreen.dealBookBidsEmptyKey), findsOneWidget);
        expect(find.byKey(TradeScreen.dealBookOffersEmptyKey), findsOneWidget);
        expect(find.text(TradeScreen.dealBookBidsEmptyText), findsOneWidget);
        expect(find.text(TradeScreen.dealBookOffersEmptyText), findsOneWidget);
        _expectTotals(tester, bids: 0, offers: 0);
      },
    );

    testWidgets(
      'filled bid row floors legacy fractional pricePerUnit to integer '
      'display (Refs #3093)',
      (tester) async {
        final game = buildTradeTestGame(
          players: _players,
          lastTurnActivity: {
            'timber': _activity('timber', [
              _deal(
                seller: 'gp_a',
                buyer: 'gp_h',
                commodity: 'timber',
                qty: 5,
                price: 30.9,
              ),
            ]),
          },
        );
        await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

        // ignore: avoid_hardcoded_strings_in_widgets
        expect(find.text('timber — qty 5 × 30 = 150'), findsOneWidget);
        _expectTotals(tester, bids: 150);
      },
    );

    testWidgets(
      'filled bid (player == buyer) renders with notional and contributes '
      'to the bids panel total spent; unrelated deal is excluded',
      (tester) async {
        final game = buildTradeTestGame(
          players: _players,
          lastTurnActivity: {
            'timber': _activity('timber', [
              _deal(
                seller: 'gp_a',
                buyer: 'gp_h',
                commodity: 'timber',
                qty: 5,
                price: 30.0,
              ),
            ]),
            'iron': _activity('iron', [
              _deal(
                seller: 'gp_a',
                buyer: 'gp_b',
                commodity: 'iron',
                qty: 4,
                price: 50.0,
              ),
            ]),
          },
        );
        await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

        expect(
          find.byKey(
            TradeScreen.dealBookFilledRowKey(TradeScreen.dealBookSideBids, 0),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            TradeScreen.dealBookFilledRowKey(TradeScreen.dealBookSideBids, 1),
          ),
          findsNothing,
        );
        expect(find.byKey(TradeScreen.dealBookBidsEmptyKey), findsNothing);

        // ignore: avoid_hardcoded_strings_in_widgets
        expect(find.text('timber — qty 5 × 30 = 150'), findsOneWidget);
        _expectTotals(tester, bids: 150, offers: 0);
        expect(find.byKey(TradeScreen.dealBookOffersEmptyKey), findsOneWidget);
      },
    );

    testWidgets(
      'filled offer (player == seller) renders in offers panel and sums '
      'into the total received; multiple deals across commodities tally '
      'a combined total',
      (tester) async {
        final game = buildTradeTestGame(
          players: _players,
          lastTurnActivity: {
            'timber': _activity('timber', [
              _deal(
                seller: 'gp_h',
                buyer: 'gp_a',
                commodity: 'timber',
                qty: 7,
                price: 30.0,
              ),
            ]),
            'iron': _activity('iron', [
              _deal(
                seller: 'gp_h',
                buyer: 'gp_a',
                commodity: 'iron',
                qty: 3,
                price: 60.0,
              ),
            ]),
          },
        );
        await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

        expect(
          find.byKey(
            TradeScreen.dealBookFilledRowKey(TradeScreen.dealBookSideOffers, 0),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            TradeScreen.dealBookFilledRowKey(TradeScreen.dealBookSideOffers, 1),
          ),
          findsOneWidget,
        );

        _expectTotals(tester, offers: 390);
        expect(find.byKey(TradeScreen.dealBookBidsEmptyKey), findsOneWidget);
      },
    );

    testWidgets(
      'carry-forward bids render in the bids panel and do NOT contribute '
      'to the total spent (they have not cleared)',
      (tester) async {
        final game = buildTradeTestGame(
          players: _players,
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
            TradeScreen.dealBookUnfilledRowKey(TradeScreen.dealBookSideBids, 0),
          ),
          findsOneWidget,
        );
        // ignore: avoid_hardcoded_strings_in_widgets
        expect(find.text('timber — qty 8 (priority 2)'), findsOneWidget);
        expect(
          find.byKey(
            TradeScreen.dealBookFilledRowKey(TradeScreen.dealBookSideBids, 0),
          ),
          findsNothing,
        );
        _expectTotals(tester, bids: 0);
        expect(find.byKey(TradeScreen.dealBookBidsEmptyKey), findsNothing);
        expect(find.byKey(TradeScreen.dealBookOffersEmptyKey), findsOneWidget);
      },
    );

    testWidgets(
      'carry-forward offers render in the offers panel; per-side filter '
      'isolation: another player\'s carry-forwards never appear',
      (tester) async {
        final game = buildTradeTestGame(
          players: _players,
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
            TradeScreen.dealBookUnfilledRowKey(
              TradeScreen.dealBookSideOffers,
              0,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            TradeScreen.dealBookUnfilledRowKey(
              TradeScreen.dealBookSideOffers,
              1,
            ),
          ),
          findsOneWidget,
        );
        // ignore: avoid_hardcoded_strings_in_widgets
        expect(find.text('timber — qty 99 (priority 1)'), findsNothing);
      },
    );

    testWidgets(
      'FRR / FTP tags render on filled rows when the matcher annotated '
      'the deal so players can audit how a fill cleared',
      (tester) async {
        final game = buildTradeTestGame(
          players: _players,
          lastTurnActivity: {
            'timber': _activity('timber', [
              _deal(
                seller: 'M1',
                buyer: 'gp_h',
                commodity: 'timber',
                qty: 3,
                price: 30.0,
                frr: true,
                sellerOriginTileKey: 'oldWorld|M1|0|0',
              ),
              _deal(
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
            TradeScreen.dealBookFilledRowKey(TradeScreen.dealBookSideBids, 0),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            TradeScreen.dealBookFilledRowKey(TradeScreen.dealBookSideBids, 1),
          ),
          findsOneWidget,
        );
        // ignore: avoid_hardcoded_strings_in_widgets
        expect(find.text('FRR'), findsOneWidget);
        // ignore: avoid_hardcoded_strings_in_widgets
        expect(find.text('FTP'), findsOneWidget);
        _expectTotals(tester, bids: 180);
      },
    );

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
        game: buildTradeTestGame(players: _players),
        selectDealBookTab: true,
      );

      final Offset bidsTopLeft = tester.getTopLeft(
        find.byKey(TradeScreen.dealBookBidsPanelKey),
      );
      final Offset offersTopLeft = tester.getTopLeft(
        find.byKey(TradeScreen.dealBookOffersPanelKey),
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
          game: buildTradeTestGame(players: _players),
          selectDealBookTab: true,
        );

        expect(tester.takeException(), isNull);

        final Offset bidsTopLeft = tester.getTopLeft(
          find.byKey(TradeScreen.dealBookBidsPanelKey),
        );
        final Offset offersTopLeft = tester.getTopLeft(
          find.byKey(TradeScreen.dealBookOffersPanelKey),
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
