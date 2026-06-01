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

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/trade_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Synthetic [Game] with the human player `gp_h` and a foreign GP
/// `gp_a` used to prove player isolation in the ledger filter. The
/// `worldMarketState` is fully caller-controlled so each test pins the
/// scenario it cares about (filled deals, carry-forwards, empties).
Game _buildGame({
  Map<CommodityId, MarketActivity> activity = const <CommodityId, MarketActivity>{},
  Map<String, List<TradeOrder>> carryForwardBids =
      const <String, List<TradeOrder>>{},
  Map<String, List<TradeOrder>> carryForwardOffers =
      const <String, List<TradeOrder>>{},
}) {
  return Game(
    id: 'test_trade_screen_deal_book_e6',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      // ignore: avoid_hardcoded_strings_in_widgets
      Player(id: 'gp_h', displayName: 'England', isHuman: true, treasury: 500),
      // ignore: avoid_hardcoded_strings_in_widgets
      Player(id: 'gp_a', displayName: 'Aragon', isHuman: false, treasury: 500),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: WorldMarketState(
      prices: const <CommodityId, int>{},
      lastTurnActivity: activity,
      carryForwardOffersByFactionId: carryForwardOffers,
      carryForwardBidsByFactionId: carryForwardBids,
    ),
  );
}

Future<void> _pumpDealBookTab(
  WidgetTester tester, {
  required Game game,
}) async {
  final Player player = game.players.firstWhere((p) => p.isHuman);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      ],
      child: MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: TradeScreen(game: game, player: player),
      ),
    ),
  );
  await tester.pump();
  // Tab into the Deal Book tab so the live content is foregrounded.
  final dealBookLabel = find.descendant(
    of: find.byType(CtTabStrip),
    matching: find.text(TradeScreen.dealBookTabLabel),
  );
  expect(dealBookLabel, findsOneWidget);
  await tester.tap(dealBookLabel);
  await tester.pump();
}

void main() {
  suppressLogsForTests();

  group('TradeScreen Deal Book tab — live ledger (Refs #2993 E6)', () {
    testWidgets(
      'empty state: panels show empty copy and totals read 0 when the '
      'player has no filled deals and no carry-forwards',
      (tester) async {
        await _pumpDealBookTab(tester, game: _buildGame());

        // Both empty-state keys are mounted because both filled and
        // unfilled lists are empty per side.
        expect(
          find.byKey(TradeScreen.dealBookBidsEmptyKey),
          findsOneWidget,
        );
        expect(
          find.byKey(TradeScreen.dealBookOffersEmptyKey),
          findsOneWidget,
        );
        // Empty-state copy renders the per-side literal.
        expect(
          find.text(TradeScreen.dealBookBidsEmptyText),
          findsOneWidget,
        );
        expect(
          find.text(TradeScreen.dealBookOffersEmptyText),
          findsOneWidget,
        );
        // Totals rows are always mounted and render 0 in the empty case.
        final bidsTotals = tester.widget<Text>(
          find.byKey(TradeScreen.dealBookBidsTotalsKey),
        );
        expect(
          bidsTotals.data,
          '${TradeScreen.dealBookTotalSpentLabel}: 0',
        );
        final offersTotals = tester.widget<Text>(
          find.byKey(TradeScreen.dealBookOffersTotalsKey),
        );
        expect(
          offersTotals.data,
          '${TradeScreen.dealBookTotalReceivedLabel}: 0',
        );
      },
    );

    testWidgets(
      'filled bid (player == buyer) renders with notional and contributes '
      'to the bids panel total spent; unrelated deal is excluded',
      (tester) async {
        final game = _buildGame(
          activity: const <CommodityId, MarketActivity>{
            'timber': MarketActivity(
              totalBidQuantity: 5,
              totalOfferQuantity: 5,
              filledQuantity: 5,
              deals: <FilledDeal>[
                // Player gp_h buys 5 timber from gp_a at price 30.
                FilledDeal(
                  sellerFactionId: 'gp_a',
                  buyerFactionId: 'gp_h',
                  commodityId: 'timber',
                  quantity: 5,
                  pricePerUnit: 30.0,
                ),
              ],
            ),
            // Unrelated deal between two foreign factions; must NOT
            // appear in the human player's ledger.
            'iron': MarketActivity(
              totalBidQuantity: 4,
              totalOfferQuantity: 4,
              filledQuantity: 4,
              deals: <FilledDeal>[
                FilledDeal(
                  sellerFactionId: 'gp_a',
                  buyerFactionId: 'gp_b',
                  commodityId: 'iron',
                  quantity: 4,
                  pricePerUnit: 50.0,
                ),
              ],
            ),
          },
        );
        await _pumpDealBookTab(tester, game: game);

        // The bids panel has exactly one filled row keyed at index 0
        // (the timber buy), and the empty-state key is absent because
        // the panel is no longer empty.
        expect(
          find.byKey(
            TradeScreen.dealBookFilledRowKey(
              TradeScreen.dealBookSideBids,
              0,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            TradeScreen.dealBookFilledRowKey(
              TradeScreen.dealBookSideBids,
              1,
            ),
          ),
          findsNothing,
        );
        expect(
          find.byKey(TradeScreen.dealBookBidsEmptyKey),
          findsNothing,
        );

        // Row text encodes quantity × price = notional and uses the
        // commodity id as the leading label per the SPEC E6 contract.
        // ignore: avoid_hardcoded_strings_in_widgets
        expect(find.text('timber — qty 5 × 30.0 = 150'), findsOneWidget);

        // Treasury totals reflect the single filled buy notional only;
        // the unrelated iron deal is excluded by the buyer filter.
        final bidsTotals = tester.widget<Text>(
          find.byKey(TradeScreen.dealBookBidsTotalsKey),
        );
        expect(
          bidsTotals.data,
          '${TradeScreen.dealBookTotalSpentLabel}: 150',
        );

        // The offers panel stays empty (the player did not sell
        // anything this turn).
        expect(
          find.byKey(TradeScreen.dealBookOffersEmptyKey),
          findsOneWidget,
        );
        final offersTotals = tester.widget<Text>(
          find.byKey(TradeScreen.dealBookOffersTotalsKey),
        );
        expect(
          offersTotals.data,
          '${TradeScreen.dealBookTotalReceivedLabel}: 0',
        );
      },
    );

    testWidgets(
      'filled offer (player == seller) renders in offers panel and sums '
      'into the total received; multiple deals across commodities tally '
      'a combined total',
      (tester) async {
        final game = _buildGame(
          activity: const <CommodityId, MarketActivity>{
            'timber': MarketActivity(
              totalBidQuantity: 7,
              totalOfferQuantity: 7,
              filledQuantity: 7,
              deals: <FilledDeal>[
                FilledDeal(
                  sellerFactionId: 'gp_h',
                  buyerFactionId: 'gp_a',
                  commodityId: 'timber',
                  quantity: 7,
                  pricePerUnit: 30.0,
                ),
              ],
            ),
            'iron': MarketActivity(
              totalBidQuantity: 3,
              totalOfferQuantity: 3,
              filledQuantity: 3,
              deals: <FilledDeal>[
                FilledDeal(
                  sellerFactionId: 'gp_h',
                  buyerFactionId: 'gp_a',
                  commodityId: 'iron',
                  quantity: 3,
                  pricePerUnit: 60.0,
                ),
              ],
            ),
          },
        );
        await _pumpDealBookTab(tester, game: game);

        // Both filled rows render in the offers panel (indices 0 and 1
        // in encounter order — ordered by lastTurnActivity map iteration).
        expect(
          find.byKey(
            TradeScreen.dealBookFilledRowKey(
              TradeScreen.dealBookSideOffers,
              0,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            TradeScreen.dealBookFilledRowKey(
              TradeScreen.dealBookSideOffers,
              1,
            ),
          ),
          findsOneWidget,
        );

        // Total received = 7*30 + 3*60 = 210 + 180 = 390.
        final offersTotals = tester.widget<Text>(
          find.byKey(TradeScreen.dealBookOffersTotalsKey),
        );
        expect(
          offersTotals.data,
          '${TradeScreen.dealBookTotalReceivedLabel}: 390',
        );

        // The bids panel stays empty because the player did not buy.
        expect(
          find.byKey(TradeScreen.dealBookBidsEmptyKey),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'carry-forward bids render in the bids panel and do NOT contribute '
      'to the total spent (they have not cleared)',
      (tester) async {
        final game = _buildGame(
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
        await _pumpDealBookTab(tester, game: game);

        // Unfilled row keyed under the bids side.
        expect(
          find.byKey(
            TradeScreen.dealBookUnfilledRowKey(
              TradeScreen.dealBookSideBids,
              0,
            ),
          ),
          findsOneWidget,
        );
        // ignore: avoid_hardcoded_strings_in_widgets
        expect(
          find.text('timber — qty 8 (priority 2)'),
          findsOneWidget,
        );
        // No filled row pinned for the bids side.
        expect(
          find.byKey(
            TradeScreen.dealBookFilledRowKey(
              TradeScreen.dealBookSideBids,
              0,
            ),
          ),
          findsNothing,
        );
        // Carry-forwards do not clear so total spent stays at 0.
        final bidsTotals = tester.widget<Text>(
          find.byKey(TradeScreen.dealBookBidsTotalsKey),
        );
        expect(
          bidsTotals.data,
          '${TradeScreen.dealBookTotalSpentLabel}: 0',
        );
        // Bids panel is no longer empty (carry-forward populates it).
        expect(
          find.byKey(TradeScreen.dealBookBidsEmptyKey),
          findsNothing,
        );
        // Offers panel still empty.
        expect(
          find.byKey(TradeScreen.dealBookOffersEmptyKey),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'carry-forward offers render in the offers panel; per-side filter '
      'isolation: another player\'s carry-forwards never appear',
      (tester) async {
        final game = _buildGame(
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
            // Foreign GP's carry-forward must never appear in the human
            // player's Deal Book.
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
        await _pumpDealBookTab(tester, game: game);

        // Two carry-forward rows from gp_h scoped to the offers side.
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
        // gp_a's carry-forward must NOT render anywhere on the page.
        // ignore: avoid_hardcoded_strings_in_widgets
        expect(find.text('timber — qty 99 (priority 1)'), findsNothing);
      },
    );

    testWidgets(
      'FRR / FTP tags render on filled rows when the matcher annotated '
      'the deal so players can audit how a fill cleared',
      (tester) async {
        final game = _buildGame(
          activity: const <CommodityId, MarketActivity>{
            'timber': MarketActivity(
              totalBidQuantity: 6,
              totalOfferQuantity: 6,
              filledQuantity: 6,
              deals: <FilledDeal>[
                FilledDeal(
                  sellerFactionId: 'M1',
                  buyerFactionId: 'gp_h',
                  commodityId: 'timber',
                  quantity: 3,
                  pricePerUnit: 30.0,
                  isFirstRightOfRefusalMatch: true,
                  sellerOriginTileKey: 'oldWorld|M1|0|0',
                ),
                FilledDeal(
                  sellerFactionId: 'gp_a',
                  buyerFactionId: 'gp_h',
                  commodityId: 'timber',
                  quantity: 3,
                  pricePerUnit: 30.0,
                  isFtpMatch: true,
                ),
              ],
            ),
          },
        );
        await _pumpDealBookTab(tester, game: game);

        // Both deals appear as filled bid rows for the human player.
        expect(
          find.byKey(
            TradeScreen.dealBookFilledRowKey(
              TradeScreen.dealBookSideBids,
              0,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            TradeScreen.dealBookFilledRowKey(
              TradeScreen.dealBookSideBids,
              1,
            ),
          ),
          findsOneWidget,
        );
        // FRR tag is rendered on the first row.
        // ignore: avoid_hardcoded_strings_in_widgets
        expect(find.text('FRR'), findsOneWidget);
        // FTP tag is rendered on the second row.
        // ignore: avoid_hardcoded_strings_in_widgets
        expect(find.text('FTP'), findsOneWidget);
        // Treasury spent on filled buys: 3*30 + 3*30 = 180.
        final bidsTotals = tester.widget<Text>(
          find.byKey(TradeScreen.dealBookBidsTotalsKey),
        );
        expect(
          bidsTotals.data,
          '${TradeScreen.dealBookTotalSpentLabel}: 180',
        );
      },
    );

    testWidgets(
      'side-by-side layout: when the viewport is at least '
      'dealBookTwoPanelMinWidth (600 dp) wide, the bids panel sits to '
      'the left of the offers panel',
      (tester) async {
        // 700 dp wide × 800 dp tall — wider than the 600 dp threshold.
        tester.view.physicalSize = const Size(700 * 3, 800 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpDealBookTab(tester, game: _buildGame());

        final Offset bidsTopLeft =
            tester.getTopLeft(find.byKey(TradeScreen.dealBookBidsPanelKey));
        final Offset offersTopLeft =
            tester.getTopLeft(find.byKey(TradeScreen.dealBookOffersPanelKey));

        expect(
          offersTopLeft.dx,
          greaterThan(bidsTopLeft.dx),
          reason:
              'SPEC/ui/trade-screen.md § Body — Deal Book tab pins the '
              'bids panel to the left of the offers panel when the '
              'viewport meets the dealBookTwoPanelMinWidth threshold.',
        );
        // Same baseline Y so the panels read as a single row.
        expect(
          offersTopLeft.dy,
          equals(bidsTopLeft.dy),
          reason:
              'Two-panel mode aligns the bids and offers panels at the '
              'same top so the ledger reads as one row.',
        );
      },
    );

    testWidgets(
      'stacked layout: at the 320 dp minimum viewport the offers panel '
      'sits below the bids panel (no overflow)',
      (tester) async {
        // 320 dp wide × 640 dp tall — below the 600 dp threshold so the
        // panels stack vertically to keep the 320 dp viewport overflow-safe.
        tester.view.physicalSize = const Size(320 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpDealBookTab(tester, game: _buildGame());

        expect(tester.takeException(), isNull);

        final Offset bidsTopLeft =
            tester.getTopLeft(find.byKey(TradeScreen.dealBookBidsPanelKey));
        final Offset offersTopLeft =
            tester.getTopLeft(find.byKey(TradeScreen.dealBookOffersPanelKey));
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
