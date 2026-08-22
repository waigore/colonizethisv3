// Shared TradeScreen widget-test hosts and Game builders (Refs #3952).
//
// Market-tab / Deal Book / E8 standalone suites previously each re-declared
// private `_buildGame` / `_pumpTradeScreen*` helpers wrapping the same
// `ProviderContainer` + `shellPlayerContextProvider` + `TradeScreen` pump
// sequence. This module owns the parameterized builders and pump hosts;
// trade test files keep only override lists and assertions.
//
// Game factories live in `trade_screen_test_game_builders.dart`; this file
// re-exports them for stable `import 'trade_screen_test_support.dart'`.
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
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'min_viewport_harness.dart';

export 'trade_screen_test_game_builders.dart';

/// Tall viewport so the 22-commodity Market list lays out without scrolling.
const Size kTradeMarketTabViewport = Size(1024, 4096);

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
  String? highlightCommodityId,
  bool selectDealBookTab = false,
  bool globalObserve = false,
  bool canMutateViaUi = true,
  List<Override> extraOverrides = const <Override>[],
}) async {
  final Player resolved = player ?? _humanOrFirst(game);
  final TradeScreen screen = TradeScreen(
    game: game,
    player: resolved,
    initialTabIndex: initialTabIndex ?? 0,
    highlightCommodityId: highlightCommodityId,
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
      matching: find.text(TradeScreenDealBookKeys.dealBookTabLabel),
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
  String? highlightCommodityId,
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
  final TradeScreen screen = TradeScreen(
    game: game,
    player: resolved,
    initialTabIndex: initialTabIndex ?? 0,
    highlightCommodityId: highlightCommodityId,
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
