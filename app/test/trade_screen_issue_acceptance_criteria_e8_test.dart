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
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/features/game/widgets/panels/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/app_shell_harness.dart';
import 'support/trade_screen_test_support.dart';
import 'widget_test_pumps.dart';

// Player ids used by the isolated shared TradeScreen harness
// (AC #2, #3, #4, #5, and observe-variant tests). The route-host
// fixture (AC #1, #6) uses the human player from the shared lightweight
// `buildTradePanelTestGame()` fixture (Refs #3656).
const String _humanPlayerId = kTradeTestHumanPlayerId;

CommodityId get _timber => CommodityCatalog.timber.id;
CommodityId get _iron => CommodityCatalog.iron.id;
CommodityId get _fabric => CommodityCatalog.fabric.id;
CommodityId get _grain => CommodityCatalog.grain.id;

Orders _ordersWith(List<TradeOrder> tradeOrders) {
  return Orders(
    tradeOrdersByPlayerId: <String, List<TradeOrder>>{
      _humanPlayerId: tradeOrders,
    },
  );
}

TradeOrder _bid(CommodityId commodityId, int quantity, {int priority = 1}) {
  return TradeOrder(
    commodityId: commodityId,
    type: TradeOrderType.bid,
    quantity: quantity,
    priority: priority,
  );
}

TradeOrder _offer(CommodityId commodityId, int quantity, {int priority = 1}) {
  return TradeOrder(
    commodityId: commodityId,
    type: TradeOrderType.offer,
    quantity: quantity,
    priority: priority,
  );
}

TradeOrder? _stagedOrder(ProviderContainer container, CommodityId commodityId) {
  final Orders orders = container.read(currentOrdersProvider);
  final List<TradeOrder>? list = orders.tradeOrdersByPlayerId[_humanPlayerId];
  if (list == null) return null;
  for (final TradeOrder o in list) {
    if (o.commodityId == commodityId) return o;
  }
  return null;
}

int _stagedRowCountForPlayer(ProviderContainer container) {
  final Orders orders = container.read(currentOrdersProvider);
  return orders.tradeOrdersByPlayerId[_humanPlayerId]?.length ?? 0;
}

String _cargoIndicatorText(WidgetTester tester) {
  final Text widget = tester.widget<Text>(
    find.byKey(TradeScreen.marketCargoIndicatorKey),
  );
  return widget.data ?? '';
}

Future<void> _switchToDealBook(WidgetTester tester) async {
  final dealBookLabel = find.descendant(
    of: find.byType(CtTabStrip),
    matching: find.text(TradeScreen.dealBookTabLabel),
  );
  expect(dealBookLabel, findsOneWidget);
  await tester.tap(dealBookLabel);
  await tester.pump();
}

Future<ProviderContainer> _pumpMarket(
  WidgetTester tester, {
  WorldMarketState? worldMarketState,
  int? tradeCargoCapacityOverride,
  Orders initialOrders = const Orders(),
  bool canMutateViaUi = true,
  int treasury = 500,
}) {
  return pumpTradeScreenWithContainer(
    tester,
    game: buildTradeTestGame(
      id: 'test_trade_screen_e8',
      treasury: treasury,
      stockpile: tradeableStockpileFilled(99),
      worldMarketState: worldMarketState,
      tradeCargoCapacityOverride: tradeCargoCapacityOverride,
    ),
    initialOrders: initialOrders,
    canMutateViaUi: canMutateViaUi,
  );
}

Future<ProviderContainer> _pumpFilledMarket(WidgetTester tester) {
  return _pumpMarket(tester);
}

Future<void> _incrementCommodity(
  WidgetTester tester,
  CommodityId commodityId,
  int taps,
) async {
  for (int i = 0; i < taps; i++) {
    await tester.tap(
      find.byKey(TradeScreen.marketRowIncrementKey(commodityId)),
    );
    await tester.pump();
  }
}

Future<void> _tapBid(WidgetTester tester, CommodityId commodityId) async {
  await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(commodityId)));
  await tester.pump();
}

Future<void> _tapOffer(WidgetTester tester, CommodityId commodityId) async {
  await tester.tap(find.byKey(TradeScreen.marketRowOfferChipKey(commodityId)));
  await tester.pump();
}

void _expectCargoSaturated(WidgetTester tester) {
  expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
  expect(find.byKey(TradeScreen.marketCargoWarningKey), findsOneWidget);
  expect(find.text(TradeScreen.cargoLimitWarningText), findsOneWidget);
}

WorldMarketState _partialTimberDealBookMarket() {
  return WorldMarketState(
    prices: const <CommodityId, int>{},
    lastTurnActivity: const <CommodityId, MarketActivity>{
      'timber': MarketActivity(
        totalBidQuantity: 10,
        totalOfferQuantity: 5,
        filledQuantity: 5,
        deals: <FilledDeal>[
          FilledDeal(
            sellerFactionId: 'gp_a',
            buyerFactionId: _humanPlayerId,
            commodityId: 'timber',
            quantity: 5,
            pricePerUnit: 8.4,
          ),
        ],
      ),
    },
    carryForwardBidsByFactionId: <String, List<TradeOrder>>{
      _humanPlayerId: <TradeOrder>[_bid('timber', 5)],
    },
    carryForwardOffersByFactionId: <String, List<TradeOrder>>{
      _humanPlayerId: <TradeOrder>[_offer('fabric', 3)],
    },
  );
}

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
    currentGameProvider.overrideWith(() => CurrentGameNotifier(routeHostGame)),
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

  Widget routeHostShell({required Widget child, bool globalObserve = false}) {
    return buildAppShell(
      overrides: routeHostOverrides(globalObserve: globalObserve),
      navigatorKey: appNavigatorKey,
      onGenerateRoute: Routes.generate,
      shellWrapper: (app) => AppEventHandlerScope(child: app),
      child: child,
    );
  }

  Widget buildLeftRailHost({bool globalObserve = false}) {
    return routeHostShell(
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
  }

  Widget buildTradeRouteHost({bool globalObserve = false}) {
    return routeHostShell(
      globalObserve: globalObserve,
      child: Builder(
        builder: (context) {
          return Scaffold(
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
          );
        },
      ),
    );
  }

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

        final topBarFinder = find.byKey(TradeScreen.topBarKey);
        expect(topBarFinder, findsOneWidget);
        final CtTopBar topBar = tester.widget<CtTopBar>(topBarFinder);
        expect(topBar.title, TradeScreen.topBarTitle);
        expect(topBar.backButtonLabel, TradeScreen.topBarBackLabel);

        expect(find.byKey(TradeScreen.tabsBodyKey), findsOneWidget);
        final stripFinder = find.descendant(
          of: find.byKey(TradeScreen.tabsBodyKey),
          matching: find.byType(CtTabStrip),
        );
        expect(stripFinder, findsOneWidget);
        final CtTabStrip strip = tester.widget<CtTabStrip>(stripFinder);
        expect(strip.tabLabels, <String>[
          TradeScreen.marketTabLabel,
          TradeScreen.dealBookTabLabel,
        ]);
        expect(
          find.descendant(
            of: find.byKey(TradeScreen.tabsBodyKey),
            matching: find.byType(CtPanel),
          ),
          findsOneWidget,
        );
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

  group('AC #2 — Bid toggle + quantity stepper stages a TradeOrder with the '
      'correct type, quantity, and (default) priority in '
      'currentOrdersProvider (#2993 E8 (b))', () {
    testWidgets('Given no staged TradeOrder, when the player taps `Bid` on '
        'timber and increments the stepper to 5, then '
        'tradeOrdersByPlayerId[player.id] contains exactly one '
        'TradeOrder(type=bid, quantity=5, priority=1) for timber', (
      tester,
    ) async {
      final ProviderContainer container = await _pumpFilledMarket(tester);
      expect(_stagedOrder(container, _timber), isNull);

      await _tapBid(tester, _timber);
      await _incrementCommodity(tester, _timber, 4);

      final TradeOrder? staged = _stagedOrder(container, _timber);
      expect(staged, isNotNull);
      expect(staged!.commodityId, _timber);
      expect(staged.type, TradeOrderType.bid);
      expect(staged.quantity, 5);
      expect(staged.priority, TradeScreen.marketRowDefaultPriority);
      expect(_stagedRowCountForPlayer(container), 1);
    });

    testWidgets('Offer toggle stages a TradeOrder(type=offer, quantity=1, '
        'priority=1) with no quantity carry-over from an unstaged row', (
      tester,
    ) async {
      final ProviderContainer container = await _pumpFilledMarket(tester);

      await _tapOffer(tester, _fabric);

      final TradeOrder? staged = _stagedOrder(container, _fabric);
      expect(staged, isNotNull);
      expect(staged!.type, TradeOrderType.offer);
      expect(staged.quantity, TradeScreen.marketRowQuantityDefault);
      expect(staged.priority, TradeScreen.marketRowDefaultPriority);
    });
  });

  group('AC #3 — Per-commodity mutual exclusion: bid on X and offer on X '
      'cannot coexist (#2993 E8 (c))', () {
    testWidgets(
      'Given a staged Bid for timber (qty 3), when the player taps the '
      '`Offer` chip on timber, then the prior bid is replaced by a '
      'single TradeOrder(type=offer, quantity=3) — at most one staged '
      'TradeOrder per (player, commodityId)',
      (tester) async {
        final ProviderContainer container = await _pumpFilledMarket(tester);

        await _tapBid(tester, _timber);
        await _incrementCommodity(tester, _timber, 2);
        TradeOrder? staged = _stagedOrder(container, _timber);
        expect(staged?.type, TradeOrderType.bid);
        expect(staged?.quantity, 3);

        await _tapOffer(tester, _timber);

        staged = _stagedOrder(container, _timber);
        expect(staged?.type, TradeOrderType.offer);
        expect(staged?.quantity, 3);

        final Orders orders = container.read(currentOrdersProvider);
        final List<TradeOrder>? list =
            orders.tradeOrdersByPlayerId[_humanPlayerId];
        expect(list, isNotNull);
        final int timberCount = list!
            .where((TradeOrder o) => o.commodityId == _timber)
            .length;
        expect(
          timberCount,
          1,
          reason:
              'Mutual exclusion: at most one TradeOrder per '
              '(player, commodityId).',
        );
      },
    );

    testWidgets(
      'Cross-commodity mutual exclusion is per-commodity, not per-player: '
      'staging Bid on timber AND Offer on fabric keeps both staged '
      '(tradeOrdersByPlayerId[player.id].length == 2)',
      (tester) async {
        final ProviderContainer container = await _pumpFilledMarket(tester);

        await _tapBid(tester, _timber);
        await _tapOffer(tester, _fabric);

        expect(_stagedOrder(container, _timber)?.type, TradeOrderType.bid);
        expect(_stagedOrder(container, _fabric)?.type, TradeOrderType.offer);
        expect(_stagedRowCountForPlayer(container), 2);
      },
    );
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
      await _pumpMarket(
        tester,
        worldMarketState: _partialTimberDealBookMarket(),
      );
      await _switchToDealBook(tester);

      expect(
        find.byKey(
          TradeScreen.dealBookFilledRowKey(TradeScreen.dealBookSideBids, 0),
        ),
        findsOneWidget,
      );
      // ignore: avoid_hardcoded_strings_in_widgets
      expect(find.text('timber — qty 5 × 8 = 40'), findsOneWidget);
      expect(
        find.byKey(
          TradeScreen.dealBookUnfilledRowKey(TradeScreen.dealBookSideBids, 0),
        ),
        findsOneWidget,
      );
      // ignore: avoid_hardcoded_strings_in_widgets
      expect(find.text('timber — qty 5 (priority 1)'), findsOneWidget);

      final Text bidsTotals = tester.widget<Text>(
        find.byKey(TradeScreen.dealBookBidsTotalsKey),
      );
      expect(bidsTotals.data, '${TradeScreen.dealBookTotalSpentLabel}: 40');

      expect(
        find.byKey(
          TradeScreen.dealBookFilledRowKey(TradeScreen.dealBookSideOffers, 0),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          TradeScreen.dealBookUnfilledRowKey(TradeScreen.dealBookSideOffers, 0),
        ),
        findsOneWidget,
      );
      // ignore: avoid_hardcoded_strings_in_widgets
      expect(find.text('fabric — qty 3 (priority 1)'), findsOneWidget);

      final Text offersTotals = tester.widget<Text>(
        find.byKey(TradeScreen.dealBookOffersTotalsKey),
      );
      expect(offersTotals.data, '${TradeScreen.dealBookTotalReceivedLabel}: 0');
      expect(find.byKey(TradeScreen.dealBookBidsEmptyKey), findsNothing);
      expect(find.byKey(TradeScreen.dealBookOffersEmptyKey), findsNothing);
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
      final ProviderContainer container = await _pumpMarket(
        tester,
        treasury: 100000,
        tradeCargoCapacityOverride: 10,
        initialOrders: _ordersWith(<TradeOrder>[
          _bid(_timber, 6),
          _bid(_iron, 4),
        ]),
      );

      _expectCargoSaturated(tester);

      await tester.tap(find.byKey(TradeScreen.marketRowIncrementKey(_timber)));
      await tester.pump();
      expect(
        _stagedOrder(container, _timber)?.quantity,
        6,
        reason:
            'Refs #2993 E5c: bid increment blocked when cargo saturated.',
      );

      await _tapBid(tester, _grain);
      expect(_stagedOrder(container, _grain), isNull);

      final Orders orders = container.read(currentOrdersProvider);
      final int totalBidUnits =
          orders.tradeOrdersByPlayerId[_humanPlayerId]
              ?.where((TradeOrder o) => o.type == TradeOrderType.bid)
              .fold<int>(0, (sum, o) => sum + o.quantity) ??
          0;
      expect(totalBidUnits, 10);
      _expectCargoSaturated(tester);
    });

    testWidgets(
      'Toggle clamp: with timber 9 + offer fabric 5 (cargo remaining 1), '
      'tapping `Bid` on fabric clamps the new staged quantity to the '
      'remaining cargo (1, not the prior offer\'s 5)',
      (tester) async {
        final ProviderContainer container = await _pumpMarket(
          tester,
          treasury: 100000,
          tradeCargoCapacityOverride: 10,
          initialOrders: _ordersWith(<TradeOrder>[
            _bid(_timber, 9),
            _offer(_fabric, 5),
          ]),
        );

        await _tapBid(tester, _fabric);

        final TradeOrder? fabric = _stagedOrder(container, _fabric);
        expect(fabric?.type, TradeOrderType.bid);
        expect(
          fabric?.quantity,
          1,
          reason:
              'Refs #2993 E5c: bid toggle clamps to remaining cargo.',
        );
        _expectCargoSaturated(tester);
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

      expect(find.byType(TradeScreen), findsOneWidget);
      expect(find.byKey(TradeScreen.topBarKey), findsOneWidget);

      final observePanelFinder = find.byType(ObserveModeNotDefinedPanel);
      expect(observePanelFinder, findsOneWidget);
      final ObserveModeNotDefinedPanel observePanel = tester
          .widget<ObserveModeNotDefinedPanel>(observePanelFinder);
      // ignore: avoid_hardcoded_strings_in_widgets
      expect(observePanel.title, 'Trade');

      expect(find.byKey(TradeScreen.tabsBodyKey), findsNothing);
      expect(find.byKey(TradeScreen.marketTabBodyKey), findsNothing);
      expect(find.byKey(TradeScreen.dealBookTabBodyKey), findsNothing);
      expect(find.byType(CtTabStrip), findsNothing);
      expect(
        find.byKey(TradeScreen.marketRowBidChipKey(_timber)),
        findsNothing,
      );
      expect(
        find.byKey(TradeScreen.marketRowOfferChipKey(_timber)),
        findsNothing,
      );
      expect(
        find.byKey(TradeScreen.marketRowIncrementKey(_timber)),
        findsNothing,
      );
    });

    testWidgets('Per-GP observe variant (canMutateViaUi == false, not global '
        'observe): the Market tab body remains mounted (read-only data '
        'still renders) but the IgnorePointer wrapper blocks taps; '
        'currentOrdersProvider is not mutated when the player tries '
        'to stage a Bid', (tester) async {
      final ProviderContainer container = await _pumpMarket(
        tester,
        canMutateViaUi: false,
      );

      expect(find.byKey(TradeScreen.marketTabBodyKey), findsOneWidget);

      await tester.tap(
        find.byKey(TradeScreen.marketRowBidChipKey(_timber)),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.tap(
        find.byKey(TradeScreen.marketRowIncrementKey(_timber)),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(
        _stagedOrder(container, _timber),
        isNull,
        reason:
            'Per-GP observe must not mutate currentOrdersProvider.',
      );
    });
  });
}
