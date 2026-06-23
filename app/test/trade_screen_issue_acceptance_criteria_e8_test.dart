// Issue-AC-mapped widget tests for `TradeScreen` (`#2993` E8).
// SPEC/ui/trade-screen.md.
//
// This file consolidates the trade-screen acceptance criteria listed
// at the bottom of issue [#2993](https://github.com/waigore/colonizethisv3/issues/2993)
// into a single E8 contract file. Each `group(...)` below maps 1:1 to
// one issue AC so reviewers (and the `verify-github-issue` workflow)
// can audit AC↔test coverage without cross-referencing slice files.
// The per-slice tests (E1+E2+E3+E4 scaffold, E5a, E5b, E5c, E6, E7)
// continue to exercise the broader SPEC AC table — this file's role
// is to pin the canonical issue-level scenarios that map to the six
// numbered ACs in the issue body.
//
// Issue AC → group mapping
// ------------------------
//  AC #1 — Left rail Trade icon opens TradeScreen full-screen dark
//          feature surface (`E8 (a)` in the issue body subtask list).
//  AC #2 — Bid toggle + quantity stepper stages a `TradeOrder` with
//          the correct `type`, `quantity`, and (default) `priority`
//          in `currentOrdersProvider` (`E8 (b)`). The interactive
//          priority dropdown is deferred (SPEC/ui/trade-screen.md
//          §Body — planned follow-up `#2993` E5b cont.) so the test
//          pins `priority == marketRowDefaultPriority` (1).
//  AC #3 — Per-commodity mutual exclusion: staging `Bid` on X then
//          toggling X to `Offer` (or vice versa) leaves exactly one
//          staged `TradeOrder` per `(player, commodityId)` (`E8 (c)`).
//  AC #4 — Deal Book renders previous-turn filled and carry-forward
//          rows in the correct per-side panel with correct
//          quantities, prices, and treasury totals (`E8 (d)`).
//  AC #5 — Cross-commodity cargo cap: with `tradeCargoCapacity == 10`
//          attempting to stage bids totalling 12 across commodities
//          (i) clamps the cargo indicator to 0, (ii) caps the
//          offending stepper, and (iii) mounts the cargo-limit
//          warning row (`E8 (e)`).
//  AC #6 — Observe mode: when `shellPanelsNotDefined(ref) == true`
//          the body short-circuits to `ObserveModeNotDefinedPanel`
//          (the "Observe mode is indicated" path per
//          SPEC/ui/trade-screen.md § Variant `c`), no bid/offer
//          controls are mounted, and the screen still surfaces the
//          dark `CtTopBar` chrome (`E8 (f)`).
//
// The harness mirrors the per-slice test patterns (`trade_screen_*`
// files) so the tests share their proven `ProviderScope` + tall
// surface layout. The file is intentionally self-contained — no
// helpers are imported from sibling slice test files — so an audit
// can read this single file from top to bottom and verify every
// issue AC against its scenario without chasing imports.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/route_paths.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_map_empire_left_rail.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/trade_screen.dart';
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_app/features/game/widgets/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/panel_test_fixtures.dart';
import 'widget_test_pumps.dart';

// Player ids used by the isolated `_pumpTradeScreenStandalone` harness
// (AC #2, #3, #4, #5, and observe-variant tests). The route-host
// fixture (AC #1, #6) uses the human player from the shared lightweight
// `buildTradePanelTestGame()` fixture (Refs #3656).
const String _humanPlayerId = 'gp_h';
const String _capProvinceId = 'oldWorld|cap1';

CommodityId get _timber => CommodityCatalog.timber.id;
CommodityId get _iron => CommodityCatalog.iron.id;
CommodityId get _fabric => CommodityCatalog.fabric.id;
CommodityId get _grain => CommodityCatalog.grain.id;

Game _buildStandaloneGame({
  int? tradeCargoCapacityOverride,
  WorldMarketState? worldMarketState,
}) {
  final List<Fleet> fleets = <Fleet>[];
  if (tradeCargoCapacityOverride != null) {
    final int galleonHolds = NavalStatsCatalog.galleon.cargoHold;
    final int fluyteHolds = NavalStatsCatalog.fluyte.cargoHold;
    if (galleonHolds + fluyteHolds != 10) {
      throw StateError(
        'NavalStatsCatalog cargoHold drift: '
        'galleon=$galleonHolds + fluyte=$fluyteHolds != 10. '
        'Update the override mapping in this test.',
      );
    }
    if (tradeCargoCapacityOverride != 10) {
      throw StateError(
        'Only tradeCargoCapacityOverride == 10 is currently supported '
        'by this test harness.',
      );
    }
    fleets.add(
      Fleet(
        id: homeFleetIdFor(_humanPlayerId),
        ownerId: _humanPlayerId,
        regionId: 'oldWorld',
        inPortAtProvinceId: _capProvinceId,
        ships: const [
          ShipInstance(id: 'h1', typeId: 'galleon'),
          ShipInstance(id: 'h2', typeId: 'fluyte'),
        ],
      ),
    );
  }
  return Game(
    id: 'test_trade_screen_e8',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: 'cap1',
            regionId: 'oldWorld',
            // ignore: avoid_hardcoded_strings_in_widgets
            displayName: 'Capital',
          ),
        ],
      ),
      newWorld: const RegionData(),
      fleets: fleets,
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      // Refs #3093 — sellable clamp slice. Offer chips + offer-side
      // `+` are now gated by the per-commodity offer cap
      // (`stockpile − industryAllocation`). Seed a baseline stockpile
      // of 99 units for every tradeable commodity so the E8 acceptance
      // criteria tests (which stage Offer orders without specifying
      // stockpile) keep passing under the new contract.
      Player(
        id: _humanPlayerId,
        // ignore: avoid_hardcoded_strings_in_widgets
        displayName: 'England',
        isHuman: true,
        treasury: 500,
        stockpile: Stockpile(
          quantities: <CommodityId, int>{
            for (final Commodity c in CommodityCatalog.all)
              if (c.category != CommodityCategory.riches && c.id != 'spices')
                c.id: 99,
          },
        ),
      ),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: worldMarketState ?? const WorldMarketState(),
  );
}

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

/// Pumps [TradeScreen] in isolation against a [ProviderContainer]
/// that exposes [currentGameProvider], [currentOrdersProvider], and a
/// (mockable) [shellPlayerContextProvider]. Uses a tall (1024 × 4096)
/// surface so every alphabetical row in the 22-commodity Market tab
/// list is laid out at once — `tester.tap` resolves against visible
/// targets without scrolling.
Future<ProviderContainer> _pumpTradeScreenStandalone(
  WidgetTester tester, {
  required Game game,
  Orders initialOrders = const Orders(),
  bool canMutateViaUi = true,
}) async {
  final Player player = game.players.first;
  final ProviderContainer container = ProviderContainer(
    overrides: [
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(initialOrders),
      ),
      shellPlayerContextProvider.overrideWith(
        (ref) => ShellPlayerContext(
          effectiveHumanPlayerId: player.id,
          viewingPlayerId: player.id,
          mapVisibilityMode: CtMapVisibilityMode.full,
          playerView: null,
          omniscientDetail: false,
          showPlayerChrome: true,
          canMutateViaUi: canMutateViaUi,
          debugCommandTargetPlayerId: player.id,
          inObservePhase: !canMutateViaUi,
          // ignore: avoid_hardcoded_strings_in_widgets
          observeBannerLabel: canMutateViaUi ? null : 'Observing',
          treasuryNotDefined: false,
          cargoNotDefined: false,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.binding.setSurfaceSize(const Size(1024, 4096));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: TradeScreen(game: game, player: player),
      ),
    ),
  );
  await tester.pump();
  return container;
}

TradeOrder? _stagedOrder(
  ProviderContainer container,
  CommodityId commodityId,
) {
  final Orders orders = container.read(currentOrdersProvider);
  final List<TradeOrder>? list =
      orders.tradeOrdersByPlayerId[_humanPlayerId];
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

void main() {
  suppressLogsForTests();

  late Game routeHostGame;
  late Player routeHostPlayer;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    // Lightweight fixture (Refs #3656): the route-host + left-rail tests
    // (AC #1, #6) only need a Game with a human player for navigation and the
    // TradeScreen chrome — no generated map/topology data — so the ~7-11s
    // procedural map generator is avoided.
    routeHostGame = buildTradePanelTestGame();
    routeHostPlayer = routeHostGame.players.firstWhere(
      (p) => p.isHuman,
      orElse: () => routeHostGame.players.first,
    );
    Hive.init('./.dart_tool/test_hive_trade_screen_e8');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  ShellPlayerContext globalObserveShellContext() {
    return const ShellPlayerContext(
      effectiveHumanPlayerId: null,
      viewingPlayerId: null,
      mapVisibilityMode: CtMapVisibilityMode.full,
      playerView: null,
      omniscientDetail: true,
      showPlayerChrome: false,
      canMutateViaUi: false,
      debugCommandTargetPlayerId: null,
      inObservePhase: true,
      // ignore: avoid_hardcoded_strings_in_widgets
      observeBannerLabel: 'Observing: global',
      treasuryNotDefined: true,
      cargoNotDefined: true,
    );
  }

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
          globalObserveShellContext(),
        ),
    ];

  Widget buildLeftRailHost({bool globalObserve = false}) {
    return ProviderScope(
      overrides: routeHostOverrides(globalObserve: globalObserve),
      child: AppEventHandlerScope(
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          theme: AppThemes.editorialMonocle,
          onGenerateRoute: Routes.generate,
          home: Scaffold(
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
        ),
      ),
    );
  }

  Widget buildTradeRouteHost({bool globalObserve = false}) {
    return ProviderScope(
      overrides: routeHostOverrides(globalObserve: globalObserve),
      child: AppEventHandlerScope(
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          theme: AppThemes.editorialMonocle,
          onGenerateRoute: Routes.generate,
          home: Builder(
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
        ),
      ),
    );
  }

  group(
    'AC #1 — Left rail Trade icon opens TradeScreen full-screen dark '
    'editorial-monocle surface (#2993 E8 (a))',
    () {
      testWidgets(
        'tapping kEmpireTradeButtonKey pushes TradeScreen with the dark '
        'CtTopBar (Trade title, Map back affordance, 18 px trade icon) '
        'and the two-tab Market + Deal Book body',
        (tester) async {
          await tester.pumpWidget(buildLeftRailHost());
          await pumpSettleCapped(tester);

          // Given the left rail is visible, the Trade button sits below
          // Production and above Civilian Units per SPEC § Trigger
          // conditions (Refs `#2993` R4).
          final trade = find.byKey(kEmpireTradeButtonKey);
          expect(trade, findsOneWidget);
          final productionY = tester
              .getTopLeft(find.byKey(kEmpireProductionButtonKey)).dy;
          final tradeY = tester.getTopLeft(trade).dy;
          final civilianY = tester
              .getTopLeft(find.byKey(kEmpireCivilianUnitsButtonKey)).dy;
          expect(tradeY, greaterThan(productionY));
          expect(civilianY, greaterThan(tradeY));

          await tester.tap(trade);
          await pumpSettleCapped(tester);

          // Then the Trade Screen mounts with the editorial-monocle
          // dark chrome (no light Material AppBar).
          expect(find.byType(TradeScreen), findsOneWidget);
          expect(find.byType(AppBar), findsNothing);

          final topBarFinder = find.byKey(TradeScreen.topBarKey);
          expect(topBarFinder, findsOneWidget);
          final CtTopBar topBar = tester.widget<CtTopBar>(topBarFinder);
          expect(topBar.title, TradeScreen.topBarTitle);
          expect(topBar.backButtonLabel, TradeScreen.topBarBackLabel);

          // And the body hosts the two-tab Market + Deal Book strip.
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

          // The dark editorial-monocle CtPanel surface wraps the strip
          // (no hardcoded light-theme parchment).
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
          await tester.pumpWidget(buildTradeRouteHost());
          await pumpSettleCapped(tester);

          await tester.tap(find.text('open trade'));
          await pumpSettleCapped(tester);
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
    },
  );

  group(
    'AC #2 — Bid toggle + quantity stepper stages a TradeOrder with the '
    'correct type, quantity, and (default) priority in '
    'currentOrdersProvider (#2993 E8 (b))',
    () {
      testWidgets(
        'Given no staged TradeOrder, when the player taps `Bid` on '
        'timber and increments the stepper to 5, then '
        'tradeOrdersByPlayerId[player.id] contains exactly one '
        'TradeOrder(type=bid, quantity=5, priority=1) for timber',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreenStandalone(
            tester,
            game: _buildStandaloneGame(),
          );
          expect(_stagedOrder(container, _timber), isNull);

          await tester.tap(
            find.byKey(TradeScreen.marketRowBidChipKey(_timber)),
          );
          await tester.pump();
          // Increment from 1 → 5 (4 taps).
          for (int i = 0; i < 4; i++) {
            await tester.tap(
              find.byKey(TradeScreen.marketRowIncrementKey(_timber)),
            );
            await tester.pump();
          }

          final TradeOrder? staged = _stagedOrder(container, _timber);
          expect(staged, isNotNull);
          expect(staged!.commodityId, _timber);
          expect(staged.type, TradeOrderType.bid);
          expect(staged.quantity, 5);
          // SPEC/ui/trade-screen.md § Body — planned follow-up `#2993`
          // E5b cont.: the interactive priority dropdown is deferred
          // until `kMaxTradePriority` is exposed by `#2989`. Until then
          // staged orders use `marketRowDefaultPriority` (1). The
          // priority-2 leg of issue AC #2 is therefore covered by the
          // deferred slice and tracked in SPEC.
          expect(staged.priority, TradeScreen.marketRowDefaultPriority);
          // Exactly one staged TradeOrder for the player on timber.
          expect(_stagedRowCountForPlayer(container), 1);
        },
      );

      testWidgets(
        'Offer toggle stages a TradeOrder(type=offer, quantity=1, '
        'priority=1) with no quantity carry-over from an unstaged row',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreenStandalone(
            tester,
            game: _buildStandaloneGame(),
          );

          await tester.tap(
            find.byKey(TradeScreen.marketRowOfferChipKey(_fabric)),
          );
          await tester.pump();

          final TradeOrder? staged = _stagedOrder(container, _fabric);
          expect(staged, isNotNull);
          expect(staged!.type, TradeOrderType.offer);
          expect(staged.quantity, TradeScreen.marketRowQuantityDefault);
          expect(staged.priority, TradeScreen.marketRowDefaultPriority);
        },
      );
    },
  );

  group(
    'AC #3 — Per-commodity mutual exclusion: bid on X and offer on X '
    'cannot coexist (#2993 E8 (c))',
    () {
      testWidgets(
        'Given a staged Bid for timber (qty 3), when the player taps the '
        '`Offer` chip on timber, then the prior bid is replaced by a '
        'single TradeOrder(type=offer, quantity=3) — at most one staged '
        'TradeOrder per (player, commodityId)',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreenStandalone(
            tester,
            game: _buildStandaloneGame(),
          );

          // Stage Bid + increment to qty 3.
          await tester.tap(
            find.byKey(TradeScreen.marketRowBidChipKey(_timber)),
          );
          await tester.pump();
          await tester.tap(
            find.byKey(TradeScreen.marketRowIncrementKey(_timber)),
          );
          await tester.pump();
          await tester.tap(
            find.byKey(TradeScreen.marketRowIncrementKey(_timber)),
          );
          await tester.pump();
          TradeOrder? staged = _stagedOrder(container, _timber);
          expect(staged?.type, TradeOrderType.bid);
          expect(staged?.quantity, 3);

          // Toggle to Offer: prior quantity is preserved across the
          // direction change (SPEC § Behavior — User actions table).
          await tester.tap(
            find.byKey(TradeScreen.marketRowOfferChipKey(_timber)),
          );
          await tester.pump();

          staged = _stagedOrder(container, _timber);
          expect(staged?.type, TradeOrderType.offer);
          expect(staged?.quantity, 3);

          // Mutual exclusion guarantee — exactly one TradeOrder for the
          // commodity in the player's staged trade orders list.
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
                'Mutual exclusion contract: tradeOrdersByPlayerId must '
                'contain at most one TradeOrder per (player, commodityId).',
          );
        },
      );

      testWidgets(
        'Cross-commodity mutual exclusion is per-commodity, not per-player: '
        'staging Bid on timber AND Offer on fabric keeps both staged '
        '(tradeOrdersByPlayerId[player.id].length == 2)',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreenStandalone(
            tester,
            game: _buildStandaloneGame(),
          );

          await tester.tap(
            find.byKey(TradeScreen.marketRowBidChipKey(_timber)),
          );
          await tester.pump();
          await tester.tap(
            find.byKey(TradeScreen.marketRowOfferChipKey(_fabric)),
          );
          await tester.pump();

          expect(_stagedOrder(container, _timber)?.type, TradeOrderType.bid);
          expect(
            _stagedOrder(container, _fabric)?.type,
            TradeOrderType.offer,
          );
          expect(_stagedRowCountForPlayer(container), 2);
        },
      );
    },
  );

  group(
    'AC #4 — Deal Book renders previous-turn filled + carry-forward rows '
    'with correct quantities, prices, and treasury totals (#2993 E8 (d))',
    () {
      testWidgets(
        'Given a partial timber bid (filled 5 of 10 at price 8.4, '
        'displayed as floor=8) plus a carry-forward fabric offer of qty '
        '3 (no fills), when the player opens the Deal Book tab, then '
        'the bids panel shows the timber filled row + timber '
        'carry-forward row + total spent of 40 (= 5 × floor(8.4)), and '
        'the offers panel shows the fabric carry-forward row with total '
        'received of 0',
        (tester) async {
          final WorldMarketState worldMarket = WorldMarketState(
            prices: const <CommodityId, int>{},
            lastTurnActivity: const <CommodityId, MarketActivity>{
              // Filled portion of the timber bid (5 of 10 at 8.4).
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
              _humanPlayerId: <TradeOrder>[
                // Unfilled remainder of the timber bid (5 of 10).
                TradeOrder(
                  commodityId: 'timber',
                  type: TradeOrderType.bid,
                  quantity: 5,
                  priority: 1,
                ),
              ],
            },
            carryForwardOffersByFactionId: <String, List<TradeOrder>>{
              _humanPlayerId: <TradeOrder>[
                // Fully unfilled fabric offer (3 of 3).
                TradeOrder(
                  commodityId: 'fabric',
                  type: TradeOrderType.offer,
                  quantity: 3,
                  priority: 1,
                ),
              ],
            },
          );

          await _pumpTradeScreenStandalone(
            tester,
            game: _buildStandaloneGame(worldMarketState: worldMarket),
          );
          await _switchToDealBook(tester);

          // Filled timber row in the bids panel: qty 5 × floor(8.4) = 5 × 8 = 40
          // per `SPEC/ui/trade-screen.md` § Deal Book (integer filled-row prices).
          expect(
            find.byKey(
              TradeScreen.dealBookFilledRowKey(
                TradeScreen.dealBookSideBids,
                0,
              ),
            ),
            findsOneWidget,
          );
          // ignore: avoid_hardcoded_strings_in_widgets
          expect(find.text('timber — qty 5 × 8 = 40'), findsOneWidget);

          // Unfilled timber carry-forward row in the bids panel.
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
            find.text('timber — qty 5 (priority 1)'),
            findsOneWidget,
          );

          // Bids panel total spent = filled notional only with integer
          // unit prices: quantity × floor(pricePerUnit) = 5 × 8 = 40
          // (carry-forwards do not contribute to treasury totals per
          // `SPEC/ui/trade-screen.md` § Deal Book).
          final Text bidsTotals = tester.widget<Text>(
            find.byKey(TradeScreen.dealBookBidsTotalsKey),
          );
          expect(
            bidsTotals.data,
            '${TradeScreen.dealBookTotalSpentLabel}: 40',
          );

          // Offers panel: no filled deal, one carry-forward fabric offer.
          expect(
            find.byKey(
              TradeScreen.dealBookFilledRowKey(
                TradeScreen.dealBookSideOffers,
                0,
              ),
            ),
            findsNothing,
          );
          expect(
            find.byKey(
              TradeScreen.dealBookUnfilledRowKey(
                TradeScreen.dealBookSideOffers,
                0,
              ),
            ),
            findsOneWidget,
          );
          // ignore: avoid_hardcoded_strings_in_widgets
          expect(
            find.text('fabric — qty 3 (priority 1)'),
            findsOneWidget,
          );

          final Text offersTotals = tester.widget<Text>(
            find.byKey(TradeScreen.dealBookOffersTotalsKey),
          );
          expect(
            offersTotals.data,
            '${TradeScreen.dealBookTotalReceivedLabel}: 0',
          );

          // Per-side empty-state copy must NOT render — both sides are
          // non-empty (bids has filled+unfilled, offers has unfilled).
          expect(
            find.byKey(TradeScreen.dealBookBidsEmptyKey),
            findsNothing,
          );
          expect(
            find.byKey(TradeScreen.dealBookOffersEmptyKey),
            findsNothing,
          );
        },
      );
    },
  );

  group(
    'AC #5 — Cross-commodity cargo cap: capacity 10 with attempted bids '
    'totalling 12 across commodities clamps the indicator to 0, caps the '
    'offending stepper, and mounts the warning (#2993 E8 (e))',
    () {
      testWidgets(
        'Given tradeCargoCapacity == 10, staging Bid timber qty 6 then '
        'staging Bid iron qty 4 saturates the cargo (indicator: '
        '"Cargo remaining: 0", warning mounted). A subsequent attempt to '
        'add 2 more units (the 12th unit of cross-commodity bids) by '
        'either toggling a third commodity to Bid or incrementing an '
        'existing bid is rejected — the staged bid total never exceeds '
        '10 and the warning row stays mounted.',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreenStandalone(
            tester,
            game: _buildStandaloneGame(tradeCargoCapacityOverride: 10),
            initialOrders: _ordersWith(<TradeOrder>[
              _bid(_timber, 6),
              _bid(_iron, 4),
            ]),
          );

          // (i) Cargo indicator clamps at 0 once total bids == capacity.
          expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
          // (iii) Warning row is mounted.
          expect(
            find.byKey(TradeScreen.marketCargoWarningKey),
            findsOneWidget,
          );
          expect(
            find.text(TradeScreen.cargoLimitWarningText),
            findsOneWidget,
          );

          // (ii) Offending stepper is capped — increment on timber is
          // a silent no-op because cross-commodity bid total already
          // saturates the cargo budget.
          await tester.tap(
            find.byKey(TradeScreen.marketRowIncrementKey(_timber)),
          );
          await tester.pump();
          expect(
            _stagedOrder(container, _timber)?.quantity,
            6,
            reason:
                'Refs #2993 E5c: bid increment blocked when cross-'
                'commodity bid total saturates tradeCargoCapacity.',
          );

          // Toggle Bid on a fresh commodity (grain) is also a no-op
          // because maxAllowedBidQuantity == 0 at saturation.
          await tester.tap(
            find.byKey(TradeScreen.marketRowBidChipKey(_grain)),
          );
          await tester.pump();
          expect(_stagedOrder(container, _grain), isNull);

          // Cross-commodity total never exceeds the capacity.
          final Orders orders = container.read(currentOrdersProvider);
          final int totalBidUnits = orders
                  .tradeOrdersByPlayerId[_humanPlayerId]
                  ?.where((TradeOrder o) => o.type == TradeOrderType.bid)
                  .fold<int>(0, (sum, o) => sum + o.quantity) ??
              0;
          expect(totalBidUnits, 10);
          expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
          expect(
            find.byKey(TradeScreen.marketCargoWarningKey),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Toggle clamp: with timber 9 + offer fabric 5 (cargo remaining 1), '
        'tapping `Bid` on fabric clamps the new staged quantity to the '
        'remaining cargo (1, not the prior offer\'s 5)',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreenStandalone(
            tester,
            game: _buildStandaloneGame(tradeCargoCapacityOverride: 10),
            initialOrders: _ordersWith(<TradeOrder>[
              _bid(_timber, 9),
              _offer(_fabric, 5),
            ]),
          );

          await tester.tap(
            find.byKey(TradeScreen.marketRowBidChipKey(_fabric)),
          );
          await tester.pump();

          final TradeOrder? fabric = _stagedOrder(container, _fabric);
          expect(fabric?.type, TradeOrderType.bid);
          expect(
            fabric?.quantity,
            1,
            reason:
                'Refs #2993 E5c: bid toggle clamps quantity to '
                'maxAllowedBidQuantity (remainingCargo + '
                'priorBidContribution).',
          );
          expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
          expect(
            find.byKey(TradeScreen.marketCargoWarningKey),
            findsOneWidget,
          );
        },
      );
    },
  );

  group(
    'AC #6 — Observe mode disables bid/offer controls and surfaces the '
    'Observe-mode indicator (#2993 E8 (f))',
    () {
      testWidgets(
        'Global observe mode (shellPanelsNotDefined == true): the body '
        'short-circuits to ObserveModeNotDefinedPanel(title: "Trade"); '
        'no Market or Deal Book tab bodies and no bid/offer chips or '
        'stepper buttons are mounted, but the dark CtTopBar chrome '
        'still paints',
        (tester) async {
          await tester.pumpWidget(
            buildTradeRouteHost(globalObserve: true),
          );
          await pumpSettleCapped(tester);

          await tester.tap(find.text('open trade'));
          await pumpSettleCapped(tester);

          // TradeScreen mounted with dark chrome still present.
          expect(find.byType(TradeScreen), findsOneWidget);
          expect(find.byKey(TradeScreen.topBarKey), findsOneWidget);

          // Observe-mode indicator: the ObserveModeNotDefinedPanel
          // titled "Trade" is the SPEC-canonical surface that signals
          // observe mode is active (variant `c`).
          final observePanelFinder = find.byType(ObserveModeNotDefinedPanel);
          expect(observePanelFinder, findsOneWidget);
          final ObserveModeNotDefinedPanel observePanel =
              tester.widget<ObserveModeNotDefinedPanel>(observePanelFinder);
          // ignore: avoid_hardcoded_strings_in_widgets
          expect(observePanel.title, 'Trade');

          // No Market / Deal Book tab bodies → no bid/offer chips and
          // no stepper buttons can be mounted in the tree (controls
          // are scoped under the tab strip which itself is absent).
          expect(find.byKey(TradeScreen.tabsBodyKey), findsNothing);
          expect(find.byKey(TradeScreen.marketTabBodyKey), findsNothing);
          expect(find.byKey(TradeScreen.dealBookTabBodyKey), findsNothing);
          expect(find.byType(CtTabStrip), findsNothing);
          // Per-row chip and stepper keys for the canonical timber row
          // must not exist anywhere in the widget tree under observe.
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
        },
      );

      testWidgets(
        'Per-GP observe variant (canMutateViaUi == false, not global '
        'observe): the Market tab body remains mounted (read-only data '
        'still renders) but the IgnorePointer wrapper blocks taps; '
        'currentOrdersProvider is not mutated when the player tries '
        'to stage a Bid',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreenStandalone(
            tester,
            game: _buildStandaloneGame(),
            canMutateViaUi: false,
          );

          // Market tab body is mounted (chrome stays read-only, not
          // hidden behind the global-observe sentinel).
          expect(
            find.byKey(TradeScreen.marketTabBodyKey),
            findsOneWidget,
          );

          // Attempting to tap Bid / increment is absorbed by the
          // IgnorePointer; `warnIfMissed: false` silences the expected
          // hit-test warning that the wrapper surfaces when it
          // swallows pointer events.
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
                'Per-GP observe variant must not mutate '
                'currentOrdersProvider even when the player attempts '
                'to drive the chip / stepper controls.',
          );
        },
      );
    },
  );
}
