// Widget tests for the Trade Market tab treasury bid cap (Refs #3093 —
// treasury bid budget slice).
//
// SPEC/ui/trade-screen.md § Market tab — treasury bid cap,
// SPEC/game/world-market.md § Treasury budget for bids.
//
// Pins:
//   * Toggling `Bid` on a row clamps the staged quantity to
//     `min(marketRowQuantityDefault, treasuryQuantityCap)`.
//   * Incrementing a staged Bid past the treasury budget is a silent
//     no-op (no mutation of `currentOrdersProvider`).
//   * Toggling `Bid` on a fresh row whose `treasuryHeadroom < rowPrice`
//     is a silent no-op.
//   * Toggling `Bid` on a row whose effective market price is null
//     (manufactured commodity without catalog default) is a silent
//     no-op.
//   * Projected non-bid pending costs (from `treasurySummaryProvider`)
//     reduce the bid budget; net non-bid income leaves it at raw
//     treasury (conservative clamp per SPEC).

import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/trade_screen.dart';
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/treasury_summary_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_shell_harness.dart';

const String _humanPlayerId = 'gp_h';

const CommodityId _timber = 'timber';
const CommodityId _iron = 'iron';
const CommodityId _lumber = 'lumber';

Game _buildGame({
  int treasury = 100,
  Map<CommodityId, int>? prices,
  Map<CommodityId, int>? stockpile,
}) {
  return Game(
    id: 'test_trade_screen_treasury_bid_cap',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      Player(
        id: _humanPlayerId,
        // ignore: avoid_hardcoded_strings_in_widgets
        displayName: 'England',
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
    worldMarketState: WorldMarketState(
      prices: prices ?? const <CommodityId, int>{},
    ),
  );
}

Future<ProviderContainer> _pumpTradeScreen(
  WidgetTester tester, {
  required Game game,
  Orders initialOrders = const Orders(),
  int? nonBidProjectedDelta,
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
          canMutateViaUi: true,
          debugCommandTargetPlayerId: player.id,
          inObservePhase: false,
          observeBannerLabel: null,
          treasuryNotDefined: false,
          cargoNotDefined: false,
        ),
      ),
      if (nonBidProjectedDelta != null)
        // Mirror production `treasurySummaryProvider`: derive
        // `projectedDelta` from the *current* orders so the value updates
        // as bids are staged. The test fixture pins the **non-bid** delta
        // and we subtract the live staged bid spend so the public
        // `projectedDelta` field still represents the full projection
        // (including bids) that `_projectedNonBidTreasuryDelta` will then
        // net back out via `projectedDelta + stagedBidSpend`.
        treasurySummaryProvider.overrideWith((ref) {
          final Orders orders = ref.watch(currentOrdersProvider);
          final int bidSpend = stagedBidTotalSpendByPlayer(
            orders: orders,
            playerId: _humanPlayerId,
            game: game,
            resourceRules: ResourceRules.defaultRules,
          );
          return TreasurySummary(
            treasury: player.treasury,
            projectedDelta: nonBidProjectedDelta - bidSpend,
          );
        }),
    ],
  );
  addTearDown(container.dispose);
  await pumpAppShellWithContainer(
    tester,
    container: container,
    viewport: const Size(1024, 4096),
    child: TradeScreen(game: game, player: player),
  );
  return container;
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

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab treasury bid cap (Refs #3093)', () {
    testWidgets(
      'treasury 100, timber price 30, no staged orders → tapping Bid stages '
      'a TradeOrder with quantity 1 (default fits inside the budget of 3)',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 100,
            prices: const {_timber: 30},
          ),
        );

        await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_timber)));
        await tester.pump();

        final TradeOrder? staged = _stagedOrder(container, _timber);
        expect(staged, isNotNull);
        expect(staged!.type, TradeOrderType.bid);
        expect(
          staged.quantity,
          TradeScreen.marketRowQuantityDefault,
          reason:
              'Treasury 100 / price 30 = 3 units of headroom; default '
              'staged qty 1 fits inside the budget.',
        );
      },
    );

    testWidgets(
      'treasury 100, timber price 30, staged Bid timber qty 3 → '
      'incrementing further is a silent no-op (budget saturated)',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 100,
            prices: const {_timber: 30},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.bid,
                  quantity: 3,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        await tester.tap(find.byKey(TradeScreen.marketRowIncrementKey(_timber)));
        await tester.pump();

        final TradeOrder? staged = _stagedOrder(container, _timber);
        expect(
          staged?.quantity,
          3,
          reason:
              'Refs #3093 — total spend 4×30=120 exceeds treasury 100, so '
              'the `+` tap is a silent no-op.',
        );
      },
    );

    testWidgets(
      'treasury 100, staged Bid timber qty 3 (spend 90), iron price 80 → '
      'tapping the Bid chip on a fresh iron row is a silent no-op '
      '(headroom 10 < rowPrice 80)',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 100,
            prices: const {_timber: 30, _iron: 80},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.bid,
                  quantity: 3,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_iron)));
        await tester.pump();

        expect(
          _stagedOrder(container, _iron),
          isNull,
          reason:
              'Refs #3093 — treasury headroom 10 cannot cover iron price 80; '
              'toggle must be a silent no-op.',
        );
        expect(_stagedOrder(container, _timber)?.quantity, 3);
      },
    );

    testWidgets(
      'treasury 50, timber price 30, staged Offer timber qty 4 → '
      'tapping Bid clamps the staged bid quantity to treasury budget '
      '(min(4, 50 / 30) = min(4, 1) = 1)',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 50,
            prices: const {_timber: 30},
            stockpile: const {_timber: 10},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.offer,
                  quantity: 4,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_timber)));
        await tester.pump();

        final TradeOrder? staged = _stagedOrder(container, _timber);
        expect(staged, isNotNull);
        expect(staged!.type, TradeOrderType.bid);
        expect(
          staged.quantity,
          1,
          reason:
              'Refs #3093 — prior offer qty 4 is clamped down to treasury '
              'budget 50 / 30 = 1 when toggling Offer → Bid.',
        );
      },
    );

    testWidgets(
      'treasury 100, price map omits commodity and catalog default is also '
      'null (manufactured `lumber`) → Bid toggle stages a TradeOrder under '
      'the cargo cap only (treasury clamp skipped)',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 100,
            prices: const <CommodityId, int>{},
          ),
        );

        await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_lumber)));
        await tester.pump();

        final TradeOrder? staged = _stagedOrder(container, _lumber);
        expect(
          staged,
          isNotNull,
          reason:
              'Refs #3093 — when rowPrice is null (manufactured commodity, '
              'no catalog default), the treasury clamp is skipped so the '
              'cargo cap is the only constraint on the bid toggle; the '
              'validator-side enforcement (follow-up) covers spend cases '
              'for unpriced commodities.',
        );
        expect(staged!.type, TradeOrderType.bid);
        expect(staged.quantity, TradeScreen.marketRowQuantityDefault);
      },
    );

    testWidgets(
      'treasury 100, timber price 30, staged Bid timber qty 2 → '
      'decrementing the staged bid still works (decrement is not gated by '
      'the treasury cap)',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 100,
            prices: const {_timber: 30},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.bid,
                  quantity: 2,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        await tester.tap(find.byKey(TradeScreen.marketRowDecrementKey(_timber)));
        await tester.pump();

        expect(_stagedOrder(container, _timber)?.quantity, 1);
      },
    );

    testWidgets(
      'treasury 100, timber price 30, non-bid pending cost = 40 → tapping '
      'Bid stages qty 1 (budget 60 fits default), incrementing to qty 2 '
      'succeeds (spend 60), next + tap is a silent no-op (spend 90 > '
      'budget 60)',
      (tester) async {
        // Refs #3093 — pending-cost projection wiring. The override
        // mirrors production `treasurySummaryProvider`: it re-derives
        // `projectedDelta` from current orders so the value tracks bid
        // staging like the real app would. The fixture pins the non-bid
        // contribution at -40 (e.g. 40 treasury of build/recruit/civilian
        // commitments).
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 100,
            prices: const {_timber: 30},
          ),
          nonBidProjectedDelta: -40,
        );

        await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_timber)));
        await tester.pump();

        TradeOrder? staged = _stagedOrder(container, _timber);
        expect(staged?.type, TradeOrderType.bid);
        expect(staged?.quantity, 1,
            reason: 'Budget 60 / price 30 = 2 headroom; default qty 1 fits.');

        await tester.tap(find.byKey(TradeScreen.marketRowIncrementKey(_timber)));
        await tester.pump();
        staged = _stagedOrder(container, _timber);
        expect(staged?.quantity, 2,
            reason: 'Spend grows to 60; still inside the 60 budget.');

        await tester.tap(find.byKey(TradeScreen.marketRowIncrementKey(_timber)));
        await tester.pump();
        staged = _stagedOrder(container, _timber);
        expect(staged?.quantity, 2,
            reason:
                'Refs #3093 — qty 3 would cost 90, exceeding the 60 budget; '
                'the + tap must silent-no-op.');
      },
    );

    testWidgets(
      'treasury 50, timber price 30, non-bid pending cost = 60 → bid budget '
      'clamps to 0; tapping Bid on timber is a silent no-op (no TradeOrder '
      'staged)',
      (tester) async {
        // Refs #3093 — projected pending deficit exceeds raw treasury so the
        // helper clamps the bid budget at 0. Even default qty 1 cannot land.
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 50,
            prices: const {_timber: 30},
          ),
          nonBidProjectedDelta: -60,
        );

        await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_timber)));
        await tester.pump();

        expect(
          _stagedOrder(container, _timber),
          isNull,
          reason:
              'Refs #3093 — pending non-bid deficit (60) exceeds raw treasury '
              '(50), so the bid budget is 0 and even default-qty 1 cannot '
              'land. The toggle must be a silent no-op.',
        );
      },
    );

    testWidgets(
      'treasury 100, iron price 80, non-bid projected delta = +25 (net '
      'non-bid income) → bid budget stays at raw treasury 100 (income '
      'does not raise the budget); tapping Bid stages qty 1 normally',
      (tester) async {
        // Refs #3093 — net non-bid income never raises the bid budget
        // (conservative clamp per SPEC § Treasury budget for bids).
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 100,
            prices: const {_iron: 80},
          ),
          nonBidProjectedDelta: 25,
        );

        await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_iron)));
        await tester.pump();

        final TradeOrder? staged = _stagedOrder(container, _iron);
        expect(staged?.type, TradeOrderType.bid);
        expect(staged?.quantity, 1,
            reason:
                'Net non-bid income (+25) is ignored by the bid clamp; '
                'budget stays at raw treasury 100 so the default qty 1 (spend '
                '80) lands.');
      },
    );

    testWidgets(
      'treasury 100, timber price 30, staged Bid timber qty 2 (spend 60), '
      'non-bid projected delta = +10 (net non-bid income) → incrementing '
      'timber lands (budget stays at raw treasury 100, spend grows to 90)',
      (tester) async {
        // Refs #3093 — exercises the UI-side delta reconstruction with a
        // dynamic treasury summary. The non-bid delta is +10 (income), so
        // the helper clamps the deficit to 0 and leaves the budget at raw
        // treasury 100. Spend 60 + 30 = 90 ≤ 100, so the increment lands.
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 100,
            prices: const {_timber: 30},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.bid,
                  quantity: 2,
                  priority: 1,
                ),
              ],
            },
          ),
          nonBidProjectedDelta: 10,
        );

        await tester.tap(find.byKey(TradeScreen.marketRowIncrementKey(_timber)));
        await tester.pump();
        expect(_stagedOrder(container, _timber)?.quantity, 3,
            reason:
                'Reconstructed non-bid delta is +10 (net income); budget '
                'stays at raw treasury 100, allowing the increment to qty 3 '
                '(spend 90).');
      },
    );

    testWidgets(
      'treasury 100, non-bid pending cost = 40, staged Bid timber qty 1 '
      '(spend 30) → tapping Bid on iron (price 80) is refused (budget 60, '
      'headroom 30 < iron price 80)',
      (tester) async {
        // Refs #3093 — cross-commodity bid gate under pending non-bid costs.
        // Bid budget = 100 − 40 = 60; existing timber spend = 30; iron toggle
        // would need 80 of remaining 30 headroom.
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 100,
            prices: const {_timber: 30, _iron: 80},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.bid,
                  quantity: 1,
                  priority: 1,
                ),
              ],
            },
          ),
          nonBidProjectedDelta: -40,
        );

        await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_iron)));
        await tester.pump();

        expect(_stagedOrder(container, _iron), isNull,
            reason:
                'Bid budget 60 − existing timber spend 30 leaves 30 headroom; '
                'iron price 80 > 30 → toggle is silent no-op.');
        expect(_stagedOrder(container, _timber)?.quantity, 1);
      },
    );
  });
}
