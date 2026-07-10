// Shared TradeScreen widget-test hosts and Game builders (Refs #3952).
//
// Market-tab / Deal Book / E8 standalone suites previously each re-declared
// private `_buildGame` / `_pumpTradeScreen*` helpers wrapping the same
// `ProviderContainer` + `shellPlayerContextProvider` + `TradeScreen` pump
// sequence. This module owns the parameterized builders and pump hosts;
// trade test files keep only override lists and assertions.
//
// Extends the lightweight panel fixture seam in `panel_fixtures/trade.dart`
// (`buildTradePanelTestGame`) for scaffold/viewport pins that need only
// `game.players` + empty world-market state.

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/production_allocation_provider.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'min_viewport_harness.dart';
import 'panel_fixtures/trade.dart';

/// Canonical human GP id used by Market-tab / Deal Book / E8 standalone hosts.
const String kTradeTestHumanPlayerId = 'gp_h';

/// Tall viewport so the 22-commodity Market list lays out without scrolling.
const Size kTradeMarketTabViewport = Size(1024, 4096);

/// Capital province id used when seeding a synthetic home fleet for cargo-cap
/// pins (`tradeCargoCapacityOverride == 10`).
const String kTradeTestCapitalProvinceId = 'oldWorld|cap1';

/// Stockpile map covering every tradeable commodity at [quantity] (excludes
/// riches and `spices`). Used by Offer-side interactive suites so the sellable
/// clamp does not zero out default Offer taps.
Map<CommodityId, int> tradeableStockpileFilled(int quantity) {
  return <CommodityId, int>{
    for (final Commodity c in CommodityCatalog.all)
      if (c.category != CommodityCategory.riches && c.id != 'spices')
        c.id: quantity,
  };
}

/// Parameterized lightweight [Game] for TradeScreen widget tests.
///
/// Defaults match the Market-tab family (`gp_h`, treasury 500, empty regions).
/// Pass [players] / [worldMarketState] / [fleets] / [oldWorld] when a suite
/// needs foreign GPs, carry-forwards, or a home fleet for cargo capacity.
Game buildTradeTestGame({
  String id = 'test_trade_screen',
  String playerId = kTradeTestHumanPlayerId,
  String displayName = 'England',
  int treasury = 500,
  Map<CommodityId, int>? stockpile,
  Map<CommodityId, int>? prices,
  Map<CommodityId, MarketActivity>? lastTurnActivity,
  Map<String, List<TradeOrder>> carryForwardBids =
      const <String, List<TradeOrder>>{},
  Map<String, List<TradeOrder>> carryForwardOffers =
      const <String, List<TradeOrder>>{},
  List<Player>? players,
  List<Fleet> fleets = const <Fleet>[],
  RegionData oldWorld = const RegionData(),
  RegionData newWorld = const RegionData(),
  WorldMarketState? worldMarketState,
  /// When `10`, seeds a galleon+fluyte home fleet (cargoHold 6+4). Other
  /// values throw — only the E5c / E8 cargo-cap mapping is supported.
  int? tradeCargoCapacityOverride,
}) {
  final List<Fleet> resolvedFleets = List<Fleet>.of(fleets);
  RegionData resolvedOldWorld = oldWorld;
  if (tradeCargoCapacityOverride != null) {
    final int galleonHolds = NavalStatsCatalog.galleon.cargoHold;
    final int fluyteHolds = NavalStatsCatalog.fluyte.cargoHold;
    if (galleonHolds + fluyteHolds != 10) {
      throw StateError(
        'NavalStatsCatalog cargoHold drift: '
        'galleon=$galleonHolds + fluyte=$fluyteHolds != 10. '
        'Update the override mapping in trade_screen_test_support.dart.',
      );
    }
    if (tradeCargoCapacityOverride != 10) {
      throw StateError(
        'Only tradeCargoCapacityOverride == 10 is currently supported '
        'by trade_screen_test_support.',
      );
    }
    resolvedFleets.add(
      Fleet(
        id: homeFleetIdFor(playerId),
        ownerId: playerId,
        regionId: 'oldWorld',
        inPortAtProvinceId: kTradeTestCapitalProvinceId,
        ships: const [
          ShipInstance(id: 'h1', typeId: 'galleon'),
          ShipInstance(id: 'h2', typeId: 'fluyte'),
        ],
      ),
    );
    if (resolvedOldWorld.provinces.isEmpty) {
      resolvedOldWorld = const RegionData(
        provinces: [
          Province(
            id: 'cap1',
            regionId: 'oldWorld',
            // ignore: avoid_hardcoded_strings_in_widgets
            displayName: 'Capital',
          ),
        ],
      );
    }
  }

  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: resolvedOldWorld,
      newWorld: newWorld,
      fleets: resolvedFleets,
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players:
        players ??
        [
          Player(
            id: playerId,
            // ignore: avoid_hardcoded_strings_in_widgets
            displayName: displayName,
            isHuman: true,
            treasury: treasury,
            stockpile: Stockpile(
              quantities: stockpile ?? const <CommodityId, int>{},
            ),
          ),
        ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState:
        worldMarketState ??
        WorldMarketState(
          prices: prices ?? const <CommodityId, int>{},
          lastTurnActivity:
              lastTurnActivity ?? const <CommodityId, MarketActivity>{},
          carryForwardBidsByFactionId: carryForwardBids,
          carryForwardOffersByFactionId: carryForwardOffers,
        ),
  );
}

/// Scaffold / 320 dp pin fixture — delegates to [buildTradePanelTestGame].
Game buildTradeScaffoldTestGame() => buildTradePanelTestGame();

/// Global-observe [ShellPlayerContext] matching `shellPlayerContextProvider`'s
/// observe branch (hides player chrome → `ObserveModeNotDefinedPanel`).
ShellPlayerContext tradeTestGlobalObserveShellContext() {
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

/// Per-player shell context for isolated TradeScreen pumps.
ShellPlayerContext tradeTestShellPlayerContext({
  required Player player,
  bool canMutateViaUi = true,
}) {
  return ShellPlayerContext(
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
  );
}

Player _humanOrFirst(Game game) {
  return game.players.firstWhere(
    (Player p) => p.isHuman,
    orElse: () => game.players.first,
  );
}

/// One-way pump (no container read-back). Optional [initialTabIndex] and
/// [selectDealBookTab] cover E6/E7 Deal Book foregrounding.
Future<void> pumpTradeScreen(
  WidgetTester tester, {
  required Game game,
  Player? player,
  Size? viewport,
  int? initialTabIndex,
  bool selectDealBookTab = false,
  bool globalObserve = false,
  bool canMutateViaUi = true,
  List<Override> extraOverrides = const <Override>[],
}) async {
  final Player resolved = player ?? _humanOrFirst(game);
  final TradeScreen screen = initialTabIndex == null
      ? TradeScreen(game: game, player: resolved)
      : TradeScreen(
          game: game,
          player: resolved,
          initialTabIndex: initialTabIndex,
        );
  await pumpAppShell(
    tester,
    viewport: viewport,
    overrides: [
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      if (globalObserve)
        shellPlayerContextProvider.overrideWithValue(
          tradeTestGlobalObserveShellContext(),
        )
      else if (!canMutateViaUi)
        shellPlayerContextProvider.overrideWith(
          (ref) => tradeTestShellPlayerContext(
            player: resolved,
            canMutateViaUi: false,
          ),
        ),
      ...extraOverrides,
    ],
    child: screen,
  );
  if (selectDealBookTab) {
    final Finder dealBookLabel = find.descendant(
      of: find.byType(CtTabStrip),
      matching: find.text(TradeScreen.dealBookTabLabel),
    );
    expect(dealBookLabel, findsOneWidget);
    await tester.tap(dealBookLabel);
    await tester.pump();
  }
}

/// Container-backed pump for suites that read `currentOrdersProvider` after
/// taps. Registers `addTearDown(container.dispose)`.
Future<ProviderContainer> pumpTradeScreenWithContainer(
  WidgetTester tester, {
  required Game game,
  Player? player,
  Orders initialOrders = const Orders(),
  Size viewport = kTradeMarketTabViewport,
  bool canMutateViaUi = true,
  bool globalObserve = false,
  List<Override> extraOverrides = const <Override>[],
  Map<String, int> initialDesiredOutputByRecipe = const <String, int>{},
  int? initialTabIndex,
}) async {
  final Player resolved = player ?? _humanOrFirst(game);
  final ProviderContainer container = ProviderContainer(
    overrides: [
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(initialOrders),
      ),
      if (globalObserve)
        shellPlayerContextProvider.overrideWithValue(
          tradeTestGlobalObserveShellContext(),
        )
      else
        shellPlayerContextProvider.overrideWith(
          (ref) => tradeTestShellPlayerContext(
            player: resolved,
            canMutateViaUi: canMutateViaUi,
          ),
        ),
      ...extraOverrides,
    ],
  );
  addTearDown(container.dispose);
  if (initialDesiredOutputByRecipe.isNotEmpty) {
    container
        .read(productionDesiredOutputProvider.notifier)
        .replaceAll(initialDesiredOutputByRecipe);
  }
  final TradeScreen screen = initialTabIndex == null
      ? TradeScreen(game: game, player: resolved)
      : TradeScreen(
          game: game,
          player: resolved,
          initialTabIndex: initialTabIndex,
        );
  await pumpAppShellWithContainer(
    tester,
    container: container,
    viewport: viewport,
    child: screen,
  );
  return container;
}

/// 320 dp / wide-viewport pin via [pumpAtMinViewport].
Future<void> pumpTradeScreenAtMinViewport(
  WidgetTester tester, {
  required Size size,
  required Game game,
  Player? player,
  bool globalObserve = false,
}) async {
  final Player resolved = player ?? _humanOrFirst(game);
  await pumpAtMinViewport(
    tester,
    size: size,
    overrides: [
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      if (globalObserve)
        shellPlayerContextProvider.overrideWithValue(
          tradeTestGlobalObserveShellContext(),
        ),
    ],
    child: TradeScreen(game: game, player: resolved),
  );
}
