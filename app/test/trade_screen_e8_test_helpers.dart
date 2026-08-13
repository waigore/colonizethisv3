// TradeScreen E8 issue-AC harness helpers (Refs #2993, #4117).
//
// Owns the private pump/assert helpers and commodity fixtures previously
// duplicated inline in `trade_screen_issue_acceptance_criteria_e8_test.dart`
// so the near-cap contract file keeps only AC groups and assertions.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/route_paths.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/widgets/panels/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'trade_screen_test_support.dart';
import 'widget_test_pumps.dart';

const String kTradeE8HumanPlayerId = kTradeTestHumanPlayerId;

late Game _tradeE8RouteHostGame;
late Player _tradeE8RouteHostPlayer;
late Box<dynamic> _tradeE8GamesBox;

Future<void> tradeE8InitRouteHostHive() async {
  _tradeE8RouteHostGame = buildTradeScaffoldTestGame();
  _tradeE8RouteHostPlayer = _tradeE8RouteHostGame.players.firstWhere(
    (p) => p.isHuman,
    orElse: () => _tradeE8RouteHostGame.players.first,
  );
  Hive.init('./.dart_tool/test_hive_trade_screen_e8');
  _tradeE8GamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
}

List<Override> tradeE8RouteHostOverrides({bool globalObserve = false}) => [
      gamesBoxProvider.overrideWith((ref) => _tradeE8GamesBox),
      gameServiceProvider.overrideWith(
        (ref) => GameService(_tradeE8GamesBox, GameSaveAdapter()),
      ),
      currentGameProvider.overrideWith(
        () => CurrentGameNotifier(_tradeE8RouteHostGame),
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

Widget tradeE8RouteHostShell({
  required Widget child,
  bool globalObserve = false,
}) =>
    buildAppShell(
      overrides: tradeE8RouteHostOverrides(globalObserve: globalObserve),
      navigatorKey: appNavigatorKey,
      onGenerateRoute: Routes.generate,
      shellWrapper: (app) => AppEventHandlerScope(child: app),
      child: child,
    );

Widget tradeE8LeftRailHost({bool globalObserve = false}) => tradeE8RouteHostShell(
      globalObserve: globalObserve,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              left: 20,
              top: 0,
              child: GameMapEmpireLeftRail(
                game: _tradeE8RouteHostGame,
                humanPlayerId: _tradeE8RouteHostPlayer.id,
              ),
            ),
          ],
        ),
      ),
    );

Widget tradeE8TradeRouteHost({bool globalObserve = false}) => tradeE8RouteHostShell(
      globalObserve: globalObserve,
      child: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  RoutePaths.trade,
                  arguments: <String, Object?>{
                    'game': _tradeE8RouteHostGame,
                    'humanPlayerId': _tradeE8RouteHostPlayer.id,
                  },
                );
              },
              child: const Text('open trade'),
            ),
          ),
        ),
      ),
    );

Future<void> tradeE8OpenTradeFromRouteHost(
  WidgetTester tester, {
  bool globalObserve = false,
}) async {
  await tester.pumpWidget(tradeE8TradeRouteHost(globalObserve: globalObserve));
  await pumpSettleCapped(tester);
  await tester.tap(find.text('open trade'));
  await pumpSettleCapped(tester);
}

CommodityId get kTradeE8Timber => CommodityCatalog.timber.id;
CommodityId get kTradeE8Iron => CommodityCatalog.iron.id;
CommodityId get kTradeE8Fabric => CommodityCatalog.fabric.id;
CommodityId get kTradeE8Grain => CommodityCatalog.grain.id;

Orders tradeE8OrdersWith(List<TradeOrder> tradeOrders) => Orders(
      tradeOrdersByPlayerId: <String, List<TradeOrder>>{
        kTradeE8HumanPlayerId: tradeOrders,
      },
    );

TradeOrder tradeE8Bid(CommodityId id, int qty, {int priority = 1}) =>
    TradeOrder(
      commodityId: id,
      type: TradeOrderType.bid,
      quantity: qty,
      priority: priority,
    );

TradeOrder tradeE8Offer(CommodityId id, int qty, {int priority = 1}) =>
    TradeOrder(
      commodityId: id,
      type: TradeOrderType.offer,
      quantity: qty,
      priority: priority,
    );

TradeOrder? tradeE8StagedOrder(
  ProviderContainer container,
  CommodityId commodityId,
) {
  final List<TradeOrder>? list = container
      .read(currentOrdersProvider)
      .tradeOrdersByPlayerId[kTradeE8HumanPlayerId];
  if (list == null) return null;
  for (final TradeOrder o in list) {
    if (o.commodityId == commodityId) return o;
  }
  return null;
}

int tradeE8StagedRowCountForPlayer(ProviderContainer container) =>
    container.read(currentOrdersProvider).tradeOrdersByPlayerId[kTradeE8HumanPlayerId]
        ?.length ??
    0;

String tradeE8CargoIndicatorText(WidgetTester tester) =>
    tester
        .widget<Text>(find.byKey(TradeScreenMarketKeys.marketCargoIndicatorKey))
        .data ??
    '';

Future<void> tradeE8SwitchToDealBook(WidgetTester tester) async {
  final Finder dealBookLabel = find.descendant(
    of: find.byType(CtTabStrip),
    matching: find.text(TradeScreenDealBookKeys.dealBookTabLabel),
  );
  expect(dealBookLabel, findsOneWidget);
  await tester.tap(dealBookLabel);
  await tester.pump();
}

Future<ProviderContainer> tradeE8PumpMarket(
  WidgetTester tester, {
  WorldMarketState? worldMarketState,
  int? tradeCargoCapacityOverride,
  Orders initialOrders = const Orders(),
  bool canMutateViaUi = true,
  int treasury = 500,
  List<OvertureState> overtureStates = const <OvertureState>[],
}) =>
    pumpTradeScreenWithContainer(
      tester,
      game: buildTradeTestGame(
        id: 'test_trade_screen_e8',
        treasury: treasury,
        stockpile: tradeableStockpileFilled(99),
        worldMarketState: worldMarketState,
        tradeCargoCapacityOverride: tradeCargoCapacityOverride,
        overtureStates: overtureStates,
      ),
      initialOrders: initialOrders,
      canMutateViaUi: canMutateViaUi,
    );

Future<void> tradeE8IncrementCommodity(
  WidgetTester tester,
  CommodityId commodityId,
  int taps,
) async {
  for (int i = 0; i < taps; i++) {
    await tester.tap(
      find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(commodityId)),
    );
    await tester.pump();
  }
}

Future<void> tradeE8TapBid(WidgetTester tester, CommodityId commodityId) async {
  await tester.tap(
    find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(commodityId)),
  );
  await tester.pump();
}

Future<void> tradeE8TapOffer(
  WidgetTester tester,
  CommodityId commodityId,
) async {
  await tester.tap(
    find.byKey(TradeScreenMarketKeys.marketRowOfferChipKey(commodityId)),
  );
  await tester.pump();
}

void expectTradeE8CargoSaturated(WidgetTester tester) {
  expect(tradeE8CargoIndicatorText(tester), 'Cargo remaining: 0');
  expect(find.byKey(TradeScreenMarketKeys.marketCargoWarningKey), findsOneWidget);
  expect(find.text(TradeScreenMarketKeys.cargoLimitWarningText), findsOneWidget);
}

void expectTradeE8Chrome(WidgetTester tester) {
  final CtTopBar topBar =
      tester.widget<CtTopBar>(find.byKey(TradeScreenMarketKeys.topBarKey));
  expect(topBar.title, TradeScreenMarketKeys.topBarTitle);
  expect(topBar.backButtonLabel, TradeScreenMarketKeys.topBarBackLabel);
  expect(find.byKey(TradeScreenMarketKeys.tabsBodyKey), findsOneWidget);
  final CtTabStrip strip = tester.widget<CtTabStrip>(
    find.descendant(
      of: find.byKey(TradeScreenMarketKeys.tabsBodyKey),
      matching: find.byType(CtTabStrip),
    ),
  );
  expect(strip.tabLabels, <String>[
    TradeScreenMarketKeys.marketTabLabel,
    TradeScreenDealBookKeys.dealBookTabLabel,
  ]);
  expect(
    find.descendant(
      of: find.byKey(TradeScreenMarketKeys.tabsBodyKey),
      matching: find.byType(CtPanel),
    ),
    findsOneWidget,
  );
}

void expectTradeE8DealBookTotals(
  WidgetTester tester, {
  required String bidsTotal,
  required String offersTotal,
}) {
  expect(
    tester
        .widget<Text>(find.byKey(TradeScreenDealBookKeys.dealBookBidsTotalsKey))
        .data,
    bidsTotal,
  );
  expect(
    tester
        .widget<Text>(
          find.byKey(TradeScreenDealBookKeys.dealBookOffersTotalsKey),
        )
        .data,
    offersTotal,
  );
}

void expectTradeE8ObserveModeBlocksMarket(WidgetTester tester) {
  expect(find.byType(TradeScreen), findsOneWidget);
  expect(find.byKey(TradeScreenMarketKeys.topBarKey), findsOneWidget);
  final Finder observePanelFinder = find.byType(ObserveModeNotDefinedPanel);
  expect(observePanelFinder, findsOneWidget);
  // ignore: avoid_hardcoded_strings_in_widgets
  expect(
    tester.widget<ObserveModeNotDefinedPanel>(observePanelFinder).title,
    'Trade',
  );
  for (final Finder finder in <Finder>[
    find.byKey(TradeScreenMarketKeys.tabsBodyKey),
    find.byKey(TradeScreenMarketKeys.marketTabBodyKey),
    find.byKey(TradeScreenDealBookKeys.dealBookTabBodyKey),
    find.byType(CtTabStrip),
    find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(kTradeE8Timber)),
    find.byKey(TradeScreenMarketKeys.marketRowOfferChipKey(kTradeE8Timber)),
    find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(kTradeE8Timber)),
  ]) {
    expect(finder, findsNothing);
  }
}

WorldMarketState tradeE8PartialTimberDealBookMarket() => WorldMarketState(
      prices: const <CommodityId, int>{},
      lastTurnActivity: const <CommodityId, MarketActivity>{
        'timber': MarketActivity(
          totalBidQuantity: 10,
          totalOfferQuantity: 5,
          filledQuantity: 5,
          deals: <FilledDeal>[
            FilledDeal(
              sellerFactionId: 'gp_a',
              buyerFactionId: kTradeE8HumanPlayerId,
              commodityId: 'timber',
              quantity: 5,
              pricePerUnit: 8.4,
            ),
          ],
        ),
      },
      carryForwardBidsByFactionId: <String, List<TradeOrder>>{
        kTradeE8HumanPlayerId: <TradeOrder>[tradeE8Bid('timber', 5)],
      },
      carryForwardOffersByFactionId: <String, List<TradeOrder>>{
        kTradeE8HumanPlayerId: <TradeOrder>[tradeE8Offer('fabric', 3)],
      },
    );
