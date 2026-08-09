// Issue-AC-mapped widget tests for `TradeScreen` (`#2993` E8).
// SPEC/ui/trade-screen.md.
//
// Pins the six issue-body ACs (E8 a–f) in one contract file; per-slice
// trade_screen_* suites cover the broader SPEC table. Groups map 1:1:
// AC1 open TradeScreen; AC2 bid+qty (default priority); AC3 mutual
// exclusion; AC4 Deal Book; AC5 cargo cap; AC6 observe variant.
// Harness matches sibling trade_screen_* ProviderScope patterns.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/route_paths.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'trade_screen_test_support.dart';
import 'trade_screen_e8_test_helpers.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Game routeHostGame;
  late Player routeHostPlayer;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    // Lightweight fixture (Refs #3656): route-host + left-rail tests
    // (AC #1, #6) only need a Game with a human player.
    routeHostGame = buildTradeScaffoldTestGame();
    routeHostPlayer = routeHostGame.players.firstWhere(
      (p) => p.isHuman,
      orElse: () => routeHostGame.players.first,
    );
    Hive.init('./.dart_tool/test_hive_trade_screen_e8');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  routeHostOverrides({bool globalObserve = false}) => [
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => GameService(gamesBox, GameSaveAdapter()),
        ),
        currentGameProvider.overrideWith(
          () => CurrentGameNotifier(routeHostGame),
        ),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
        appEventBusProvider.overrideWith((ref) {
          final bus = AppEventBus.create();
          ref.onDispose(bus.dispose);
          return bus;
        }),
        if (globalObserve)
          shellPlayerContextProvider.overrideWithValue(
            tradeTestGlobalObserveShellContext(),
          ),
      ];

  Widget routeHostShell({required Widget child, bool globalObserve = false}) =>
      buildAppShell(
        overrides: routeHostOverrides(globalObserve: globalObserve),
        navigatorKey: appNavigatorKey,
        onGenerateRoute: Routes.generate,
        shellWrapper: (app) => AppEventHandlerScope(child: app),
        child: child,
      );

  Widget buildLeftRailHost({bool globalObserve = false}) => routeHostShell(
        globalObserve: globalObserve,
        child: Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 20,
                top: 0,
                child: GameMapEmpireLeftRail(
                  game: routeHostGame,
                  humanPlayerId: routeHostPlayer.id,
                ),
              ),
            ],
          ),
        ),
      );

  Widget buildTradeRouteHost({bool globalObserve = false}) => routeHostShell(
        globalObserve: globalObserve,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    RoutePaths.trade,
                    arguments: <String, Object?>{
                      'game': routeHostGame,
                      'humanPlayerId': routeHostPlayer.id,
                    },
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('open trade'),
              ),
            ),
          ),
        ),
      );

  Future<void> openTradeFromRouteHost(
    WidgetTester tester, {
    bool globalObserve = false,
  }) async {
    await tester.pumpWidget(buildTradeRouteHost(globalObserve: globalObserve));
    await pumpSettleCapped(tester);
    await tester.tap(find.text('open trade'));
    await pumpSettleCapped(tester);
  }

  group('AC #1 — Left rail Trade icon opens TradeScreen full-screen dark '
      'editorial-monocle surface (#2993 E8 (a))', () {
    testWidgets(
      'tapping kEmpireTradeButtonKey pushes TradeScreen with the dark '
      'CtTopBar (Trade title, Map back affordance, 18 px trade icon) '
      'and the two-tab Market + Deal Book body',
      (tester) async {
        await tester.pumpWidget(buildLeftRailHost());
        await pumpSettleCapped(tester);

        final trade = find.byKey(kEmpireTradeButtonKey);
        expect(trade, findsOneWidget);
        final productionY = tester
            .getTopLeft(find.byKey(kEmpireProductionButtonKey))
            .dy;
        final tradeY = tester.getTopLeft(trade).dy;
        final civilianY = tester
            .getTopLeft(find.byKey(kEmpireCivilianUnitsButtonKey))
            .dy;
        expect(tradeY, greaterThan(productionY));
        expect(civilianY, greaterThan(tradeY));

        await tester.tap(trade);
        await pumpSettleCapped(tester);

        expect(find.byType(TradeScreen), findsOneWidget);
        expect(find.byType(AppBar), findsNothing);
        expectTradeE8Chrome(tester);
      },
    );

    testWidgets(
      'CtTopBar back affordance returns to the host route (TradeScreen '
      'is dismissed) — confirms the full-screen feature contract pops '
      'cleanly without leaking chrome',
      (tester) async {
        await openTradeFromRouteHost(tester);
        expect(find.byType(TradeScreen), findsOneWidget);

        final back = find.descendant(
          of: find.byType(CtTopBar),
          matching: find.byType(CtBackButton),
        );
        expect(back, findsOneWidget);
        await tester.tap(back);
        await pumpSettleCapped(tester);
        expect(find.byType(TradeScreen), findsNothing);
      },
    );
  });

  group('AC #2 / #3 — stage bid+qty, offer default, mutual exclusion '
      '(#2993 E8 (b)(c))', () {
    testWidgets('bid timber to qty 5; offer fabric defaults to qty 1', (
      tester,
    ) async {
      final ProviderContainer container = await tradeE8PumpMarket(tester);
      expect(tradeE8StagedOrder(container, kTradeE8Timber), isNull);

      await tradeE8TapBid(tester, kTradeE8Timber);
      await tradeE8IncrementCommodity(tester, kTradeE8Timber, 4);
      final TradeOrder? bid = tradeE8StagedOrder(container, kTradeE8Timber);
      expect(bid, isNotNull);
      expect(bid!.commodityId, kTradeE8Timber);
      expect(bid.type, TradeOrderType.bid);
      expect(bid.quantity, 5);
      expect(bid.priority, TradeScreenMarketKeys.marketRowDefaultPriority);
      expect(tradeE8StagedRowCountForPlayer(container), 1);

      await tradeE8TapOffer(tester, kTradeE8Fabric);
      final TradeOrder? offer = tradeE8StagedOrder(container, kTradeE8Fabric);
      expect(offer?.type, TradeOrderType.offer);
      expect(offer?.quantity, TradeScreenMarketKeys.marketRowQuantityDefault);
      expect(offer?.priority, TradeScreenMarketKeys.marketRowDefaultPriority);
    });

    testWidgets('per-commodity mutual exclusion + cross-commodity coexistence', (
      tester,
    ) async {
      final ProviderContainer container = await tradeE8PumpMarket(tester);

      await tradeE8TapBid(tester, kTradeE8Timber);
      await tradeE8IncrementCommodity(tester, kTradeE8Timber, 2);
      expect(
        tradeE8StagedOrder(container, kTradeE8Timber)?.type,
        TradeOrderType.bid,
      );
      expect(tradeE8StagedOrder(container, kTradeE8Timber)?.quantity, 3);

      await tradeE8TapOffer(tester, kTradeE8Timber);
      final TradeOrder? flipped = tradeE8StagedOrder(container, kTradeE8Timber);
      expect(flipped?.type, TradeOrderType.offer);
      expect(flipped?.quantity, 3);
      expect(
        container
            .read(currentOrdersProvider)
            .tradeOrdersByPlayerId[kTradeE8HumanPlayerId]!
            .where((TradeOrder o) => o.commodityId == kTradeE8Timber)
            .length,
        1,
      );

      await tradeE8TapBid(tester, kTradeE8Timber);
      await tradeE8TapOffer(tester, kTradeE8Fabric);
      expect(
        tradeE8StagedOrder(container, kTradeE8Timber)?.type,
        TradeOrderType.bid,
      );
      expect(
        tradeE8StagedOrder(container, kTradeE8Fabric)?.type,
        TradeOrderType.offer,
      );
      expect(tradeE8StagedRowCountForPlayer(container), 2);
    });
  });

  group('AC #4 — Deal Book renders previous-turn filled + carry-forward rows '
      'with correct quantities, prices, and treasury totals (#2993 E8 (d))', () {
    testWidgets('Given a partial timber bid (filled 5 of 10 at price 8.4, '
        'displayed as floor=8) plus a carry-forward fabric offer of qty '
        '3 (no fills), when the player opens the Deal Book tab, then '
        'the bids panel shows the timber filled row + timber '
        'carry-forward row + total spent of 40 (= 5 × floor(8.4)), and '
        'the offers panel shows the fabric carry-forward row with total '
        'received of 0', (tester) async {
      await tradeE8PumpMarket(
        tester,
        worldMarketState: tradeE8PartialTimberDealBookMarket(),
      );
      await tradeE8SwitchToDealBook(tester);
      for (final finder in <Finder>[
        find.byKey(
          TradeScreenDealBookKeys.dealBookFilledRowKey(TradeScreenDealBookKeys.dealBookSideBids, 0),
        ),
        // ignore: avoid_hardcoded_strings_in_widgets
        find.text('timber — qty 5 × 8 = 40'),
        find.byKey(
          TradeScreenDealBookKeys.dealBookUnfilledRowKey(TradeScreenDealBookKeys.dealBookSideBids, 0),
        ),
        // ignore: avoid_hardcoded_strings_in_widgets
        find.text('timber — qty 5 (priority 1)'),
        find.byKey(
          TradeScreenDealBookKeys.dealBookUnfilledRowKey(TradeScreenDealBookKeys.dealBookSideOffers, 0),
        ),
        // ignore: avoid_hardcoded_strings_in_widgets
        find.text('fabric — qty 3 (priority 1)'),
      ]) {
        expect(finder, findsOneWidget);
      }
      expectTradeE8DealBookTotals(
        tester,
        bidsTotal: '${TradeScreenDealBookKeys.dealBookTotalSpentLabel}: 40',
        offersTotal: '${TradeScreenDealBookKeys.dealBookTotalReceivedLabel}: 0',
      );
      expect(
        find.byKey(
          TradeScreenDealBookKeys.dealBookFilledRowKey(TradeScreenDealBookKeys.dealBookSideOffers, 0),
        ),
        findsNothing,
      );
      expect(find.byKey(TradeScreenDealBookKeys.dealBookBidsEmptyKey), findsNothing);
      expect(find.byKey(TradeScreenDealBookKeys.dealBookOffersEmptyKey), findsNothing);
    });
  });

  group('AC #5 — Cross-commodity cargo cap: capacity 10 with attempted bids '
      'totalling 12 across commodities clamps the indicator to 0, caps the '
      'offending stepper, and mounts the warning (#2993 E8 (e))', () {
    testWidgets('Given tradeCargoCapacity == 10, staging Bid timber qty 6 then '
        'staging Bid iron qty 4 saturates the cargo (indicator: '
        '"Cargo remaining: 0", warning mounted). A subsequent attempt to '
        'add 2 more units (the 12th unit of cross-commodity bids) by '
        'either toggling a third commodity to Bid or incrementing an '
        'existing bid is rejected — the staged bid total never exceeds '
        '10 and the warning row stays mounted.', (tester) async {
      final ProviderContainer container = await tradeE8PumpMarket(
        tester,
        treasury: 100000,
        tradeCargoCapacityOverride: 10,
        initialOrders: tradeE8OrdersWith(<TradeOrder>[
          tradeE8Bid(kTradeE8Timber, 6),
          tradeE8Bid(kTradeE8Iron, 4),
        ]),
      );

      expectTradeE8CargoSaturated(tester);

      await tester.tap(find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(kTradeE8Timber)));
      await tester.pump();
      expect(
        tradeE8StagedOrder(container, kTradeE8Timber)?.quantity,
        6,
        reason:
            'Refs #2993 E5c: bid increment blocked when cargo saturated.',
      );

      await tradeE8TapBid(tester, kTradeE8Grain);
      expect(tradeE8StagedOrder(container, kTradeE8Grain), isNull);

      final Orders orders = container.read(currentOrdersProvider);
      final int totalBidUnits =
          orders.tradeOrdersByPlayerId[kTradeE8HumanPlayerId]
              ?.where((TradeOrder o) => o.type == TradeOrderType.bid)
              .fold<int>(0, (sum, o) => sum + o.quantity) ??
          0;
      expect(totalBidUnits, 10);
      expectTradeE8CargoSaturated(tester);
    });

    testWidgets(
      'Toggle clamp: with timber 9 + offer fabric 5 (cargo remaining 1), '
      'tapping `Bid` on fabric clamps the new staged quantity to the '
      'remaining cargo (1, not the prior offer\'s 5)',
      (tester) async {
        final ProviderContainer container = await tradeE8PumpMarket(
          tester,
          treasury: 100000,
          tradeCargoCapacityOverride: 10,
          overtureStates: const <OvertureState>[
            OvertureState(
              gpId: kTradeE8HumanPlayerId,
              targetId: 'minor1',
              stage: OvertureStage.embassy,
            ),
          ],
          initialOrders: tradeE8OrdersWith(<TradeOrder>[
            tradeE8Bid(kTradeE8Timber, 9),
            tradeE8Offer(kTradeE8Fabric, 5),
          ]),
        );

        await tradeE8TapBid(tester, kTradeE8Fabric);

        final TradeOrder? fabric = tradeE8StagedOrder(container, kTradeE8Fabric);
        expect(fabric?.type, TradeOrderType.bid);
        expect(
          fabric?.quantity,
          1,
          reason:
              'Refs #2993 E5c: bid toggle clamps to remaining cargo.',
        );
        expectTradeE8CargoSaturated(tester);
      },
    );
  });

  group('AC #6 — Observe mode disables bid/offer controls and surfaces the '
      'Observe-mode indicator (#2993 E8 (f))', () {
    testWidgets('Global observe mode (shellPanelsNotDefined == true): the body '
        'short-circuits to ObserveModeNotDefinedPanel(title: "Trade"); '
        'no Market or Deal Book tab bodies and no bid/offer chips or '
        'stepper buttons are mounted, but the dark CtTopBar chrome '
        'still paints', (tester) async {
      await openTradeFromRouteHost(tester, globalObserve: true);
      expectTradeE8ObserveModeBlocksMarket(tester);
    });

    testWidgets('Per-GP observe variant (canMutateViaUi == false, not global '
        'observe): the Market tab body remains mounted (read-only data '
        'still renders) but the IgnorePointer wrapper blocks taps; '
        'currentOrdersProvider is not mutated when the player tries '
        'to stage a Bid', (tester) async {
      final ProviderContainer container = await tradeE8PumpMarket(
        tester,
        canMutateViaUi: false,
      );

      expect(find.byKey(TradeScreenMarketKeys.marketTabBodyKey), findsOneWidget);

      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(kTradeE8Timber)),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(kTradeE8Timber)),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(
        tradeE8StagedOrder(container, kTradeE8Timber),
        isNull,
        reason:
            'Per-GP observe must not mutate currentOrdersProvider.',
      );
    });
  });
}
