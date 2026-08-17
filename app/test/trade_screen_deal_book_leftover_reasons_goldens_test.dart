// Widget goldens for Deal Book leftover reason rows (Refs #4500).
// Pixel baselines under `app/test/goldens/` close the verify-github-issue
// UI proof gap flagged on issue #4500.
//
// Golden mapping:
//  - AC-1  Still open treasury-short reason line
//  - AC-2  Bids panel Did not stay open cargo-drop row
//  - AC-3  Offers panel Did not stay open stockpile-drop row
//  - AC-5  Offers panel No matching buys last turn fallback
//  - AC-7  Details expanded next-step line (treasury-short row)
//
// SPEC: SPEC/ui/trade-screen.md § Deal Book tab — leftover reasons.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen_deal_book.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'trade_screen_deal_book_leftover_reasons_widget_support.dart';
import 'trade_screen_deal_book_tab_e6_support.dart';
import 'trade_screen_test_support.dart';

const String _humanPlayerId = kTradeTestHumanPlayerId;
const Size _dealBookPanelViewport = Size(400, 360);
const Size _dealBookRowViewport = Size(520, 160);

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

  group('TradeScreen #4500 Deal Book leftover reason goldens', () {
    testWidgets('golden: Still open treasury-short reason line (AC-1)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>(
        'tradeDealBookTreasuryShortReasonGolden',
      );

      await _pumpDealBookGolden(
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
                  factionId: _humanPlayerId,
                  commodityId: 'timber',
                  quantity: 10,
                ),
              ],
            ),
          },
          carryForwardBids: <String, List<TradeOrder>>{
            _humanPlayerId: <TradeOrder>[
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.bid,
                quantity: 5,
                priority: 1,
              ),
            ],
          },
        ),
        viewport: _dealBookPanelViewport,
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

    testWidgets(
      'golden: bids panel Did not stay open cargo-drop row (AC-2)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeDealBookDidNotStayOpenCargoDropGolden',
        );

        await _pumpDealBookGolden(
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
                    factionId: _humanPlayerId,
                    commodityId: 'timber',
                    quantity: 8,
                  ),
                ],
              ),
            },
          ),
          viewport: _dealBookPanelViewport,
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
      },
    );

    testWidgets(
      'golden: offers panel Did not stay open stockpile-drop row (AC-3)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeDealBookDidNotStayOpenStockpileDropGolden',
        );

        await _pumpDealBookGolden(
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
                    factionId: _humanPlayerId,
                    commodityId: 'grain',
                    quantity: 6,
                  ),
                ],
              ),
            },
          ),
          viewport: _dealBookPanelViewport,
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

    testWidgets(
      'golden: offers panel No matching buys last turn fallback (AC-5)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeDealBookStillOpenOfferFallbackGolden',
        );

        await _pumpDealBookGolden(
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
              _humanPlayerId: <TradeOrder>[
                TradeOrder(
                  commodityId: 'grain',
                  type: TradeOrderType.offer,
                  quantity: 4,
                  priority: 1,
                ),
              ],
            },
          ),
          viewport: _dealBookPanelViewport,
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

    testWidgets('golden: Details expanded next-step line (AC-7)', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>(
        'tradeDealBookDetailsExpandedGolden',
      );

      await _pumpDealBookGolden(
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
                  factionId: _humanPlayerId,
                  commodityId: 'timber',
                  quantity: 10,
                ),
              ],
            ),
          },
          carryForwardBids: <String, List<TradeOrder>>{
            _humanPlayerId: <TradeOrder>[
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.bid,
                quantity: 5,
                priority: 1,
              ),
            ],
          },
        ),
        viewport: _dealBookRowViewport,
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
  });
}
