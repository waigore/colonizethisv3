// Deal Book leftover reason widget tests (Refs #4500).
// SPEC/ui/trade-screen.md § Deal Book leftover reasons.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_deal_book_tab_e6_support.dart';
import 'trade_screen_test_game_builders.dart';
import 'trade_screen_test_support.dart';

MarketActivity dealBookActivityWithNotes({
  required String commodity,
  List<FilledDeal> deals = const <FilledDeal>[],
  List<MarketActivityNote> notes = const <MarketActivityNote>[],
  int totalBidQuantity = 0,
  int totalOfferQuantity = 0,
}) {
  return MarketActivity(
    totalBidQuantity: totalBidQuantity,
    totalOfferQuantity: totalOfferQuantity,
    filledQuantity: deals.fold<int>(0, (sum, d) => sum + d.quantity),
    deals: deals,
    notes: notes,
  );
}

void main() {
  suppressLogsForTests();

  group('TradeScreen Deal Book leftover reasons (Refs #4500)', () {
    testWidgets(
      'treasury-short leftover bid shows reason line without enum names',
      (tester) async {
        final game = buildTradeTestGame(
          players: dealBookTestPlayers,
          lastTurnActivity: {
            'timber': dealBookActivityWithNotes(
              commodity: 'timber',
              notes: <MarketActivityNote>[
                MarketActivityNote(
                  kind:
                      MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
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

        expect(find.text('Timber — 5'), findsOneWidget);
        expect(
          find.text('Treasury ran short — leftover stays open'),
          findsOneWidget,
        );
        expect(find.textContaining('bidPartialFill'), findsNothing);
      },
    );

    testWidgets(
      'cargo drop shows Did not stay open row and not under Still open',
      (tester) async {
        final game = buildTradeTestGame(
          players: dealBookTestPlayers,
          lastTurnActivity: {
            'timber': dealBookActivityWithNotes(
              commodity: 'timber',
              notes: <MarketActivityNote>[
                MarketActivityNote(
                  kind: MarketActivityNoteKind
                      .carryForwardDroppedCargoInsufficient,
                  factionId: kTradeTestHumanPlayerId,
                  commodityId: 'timber',
                  quantity: 8,
                ),
              ],
            ),
          },
        );
        await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

        expect(
          find.text('Timber — 8 — leftover cargo no longer covered this bid'),
          findsOneWidget,
        );
        expect(
          find.text(TradeScreenDealBookKeys.dealBookDidNotStayOpenHeading),
          findsOneWidget,
        );
        expect(
          find.byKey(
            TradeScreenDealBookKeys.dealBookDidNotStayOpenRowKey(
              TradeScreenDealBookKeys.dealBookSideBids,
              0,
            ),
          ),
          findsOneWidget,
        );
        expect(find.text('Timber — 8'), findsNothing);
      },
    );

    testWidgets('stockpile drop shows Did not stay open on offers panel', (
      tester,
    ) async {
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

      expect(
        find.text('Grain — 6 — stores no longer covered this sale'),
        findsOneWidget,
      );
    });

    testWidgets(
      'leftover bid with zero last-turn offers shows volume fallback',
      (tester) async {
        final game = buildTradeTestGame(
          players: dealBookTestPlayers,
          lastTurnActivity: {
            'timber': dealBookActivityWithNotes(
              commodity: 'timber',
              totalOfferQuantity: 0,
            ),
          },
          carryForwardBids: <String, List<TradeOrder>>{
            kTradeTestHumanPlayerId: <TradeOrder>[
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.bid,
                quantity: 3,
                priority: 1,
              ),
            ],
          },
        );
        await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

        expect(find.text('Timber — 3'), findsOneWidget);
        expect(find.text('No matching sales last turn'), findsOneWidget);
      },
    );

    testWidgets(
      'leftover offer with zero last-turn bids shows volume fallback',
      (tester) async {
        final game = buildTradeTestGame(
          players: dealBookTestPlayers,
          lastTurnActivity: {
            'grain': dealBookActivityWithNotes(
              commodity: 'grain',
              totalBidQuantity: 0,
            ),
          },
          carryForwardOffers: <String, List<TradeOrder>>{
            kTradeTestHumanPlayerId: <TradeOrder>[
              TradeOrder(
                commodityId: 'grain',
                type: TradeOrderType.offer,
                quantity: 4,
                priority: 1,
              ),
            ],
          },
        );
        await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

        expect(find.text('Grain — 4'), findsOneWidget);
        expect(find.text('No matching buys last turn'), findsOneWidget);
      },
    );

    testWidgets('no fallback when last-turn volume was non-zero', (
      tester,
    ) async {
      final game = buildTradeTestGame(
        players: dealBookTestPlayers,
        lastTurnActivity: {
          'timber': dealBookActivityWithNotes(
            commodity: 'timber',
            totalOfferQuantity: 5,
          ),
        },
        carryForwardBids: <String, List<TradeOrder>>{
          kTradeTestHumanPlayerId: <TradeOrder>[
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.bid,
              quantity: 3,
              priority: 1,
            ),
          ],
        },
      );
      await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

      expect(find.text('No matching sales last turn'), findsNothing);
    });

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

    testWidgets('no offer fallback when last-turn bid volume was non-zero', (
      tester,
    ) async {
      final game = buildTradeTestGame(
        players: dealBookTestPlayers,
        lastTurnActivity: {
          'grain': dealBookActivityWithNotes(
            commodity: 'grain',
            totalBidQuantity: 5,
          ),
        },
        carryForwardOffers: <String, List<TradeOrder>>{
          kTradeTestHumanPlayerId: <TradeOrder>[
            TradeOrder(
              commodityId: 'grain',
              type: TradeOrderType.offer,
              quantity: 4,
              priority: 1,
            ),
          ],
        },
      );
      await pumpTradeScreen(tester, game: game, selectDealBookTab: true);

      expect(find.text('No matching buys last turn'), findsNothing);
    });

    testWidgets(
      '320 dp reason line and Did not stay open rows do not overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 3, 900 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final game = buildTradeTestGame(
          players: dealBookTestPlayers,
          lastTurnActivity: {
            'timber': dealBookActivityWithNotes(
              commodity: 'timber',
              notes: <MarketActivityNote>[
                MarketActivityNote(
                  kind:
                      MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
                  factionId: kTradeTestHumanPlayerId,
                  commodityId: 'timber',
                  quantity: 10,
                ),
              ],
            ),
            'iron': dealBookActivityWithNotes(
              commodity: 'iron',
              notes: <MarketActivityNote>[
                MarketActivityNote(
                  kind: MarketActivityNoteKind
                      .carryForwardDroppedCargoInsufficient,
                  factionId: kTradeTestHumanPlayerId,
                  commodityId: 'iron',
                  quantity: 8,
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

        expect(tester.takeException(), isNull);
        expect(
          find.text('Treasury ran short — leftover stays open'),
          findsOneWidget,
        );
        expect(
          find.text('Iron — 8 — leftover cargo no longer covered this bid'),
          findsOneWidget,
        );
      },
    );

    testWidgets('empty state unchanged when no notes and no leftovers', (
      tester,
    ) async {
      await pumpTradeScreen(
        tester,
        game: buildTradeTestGame(players: dealBookTestPlayers),
        selectDealBookTab: true,
      );

      expect(
        find.text(TradeScreenDealBookKeys.dealBookDidNotStayOpenHeading),
        findsNothing,
      );
      expect(
        find.text(TradeScreenDealBookKeys.dealBookBidsEmptyText),
        findsOneWidget,
      );
    });
  });
}
