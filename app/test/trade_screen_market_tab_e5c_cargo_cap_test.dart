// Widget tests for the Market tab cross-commodity cargo-remaining
// indicator + per-stepper cap + warning row (Refs #2993 E5c).
// SPEC/ui/trade-screen.md § Cargo indicator + per-stepper cap +
// warning.
//
// Exercises the durable contract for the E5c cargo telemetry and cap:
//
//  * The cargo indicator (`marketCargoIndicatorKey`) is always
//    mounted in the Market tab body and renders `Cargo remaining: X`
//    where `X = max(0, tradeCargoCapacity − totalStagedBidQuantity)`.
//  * `tradeCargoCapacity` comes from `cargoHoldsForHomeFleet` and
//    falls back to `defaultCargoHoldsStub = 24` when the player has
//    no home fleet.
//  * Offers do not consume cargo (per #2988 § Cargo Constraint Model).
//  * The warning row (`marketCargoWarningKey`) is only mounted when
//    `remainingCargo == 0` AND `totalStagedBidQuantity > 0`; absent
//    otherwise.
//  * Bid increments are blocked when the cross-commodity bid total
//    would exceed `tradeCargoCapacity`; the staged TradeOrder.quantity
//    stays at its prior value and the indicator + warning state stays
//    consistent.
//  * Toggling a row to `Bid` is clamped: the staged quantity =
//    min(desiredQuantity, maxAllowedBidQuantity); the cross-commodity
//    bid total never exceeds `tradeCargoCapacity`.
//  * Toggling a row to `Bid` is a silent no-op when
//    `maxAllowedBidQuantity <= 0` (cargo budget already saturated by
//    other commodities).
//  * Decrement and `None` free cargo: the indicator updates and the
//    warning row is removed when the cap is no longer saturated.
//  * Observe-mode (`canMutateViaUi == false`): the cargo indicator and
//    warning still mount with live text values; the chip / stepper
//    taps are blocked by the existing `IgnorePointer` wrapper.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/trade_screen.dart';
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const String _humanPlayerId = 'gp_h';
const String _capProvinceId = 'oldWorld|cap1';

/// Builds a game whose human player has either:
///   * no home fleet (so `cargoHoldsForHomeFleet` falls back to the
///     `defaultCargoHoldsStub = 24`), or
///   * a synthetic home fleet whose ship-type ids sum to
///     [tradeCargoCapacityOverride] cargo holds (used to pin the
///     capacity at 10 for the saturation / clamp ACs).
///
/// Cargo-hold totals chosen so `tradeCargoCapacity == 10`:
///   * `galleon` (cargoHold 6) + `fluyte` (cargoHold 4) = 10.
Game _buildGame({int? tradeCargoCapacityOverride}) {
  final List<Fleet> fleets = <Fleet>[];
  if (tradeCargoCapacityOverride != null) {
    // Validate the override mapping at call-site so a stale catalog
    // change is caught by the test runner instead of producing a
    // mis-sized fleet.
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
        'Only tradeCargoCapacityOverride == 10 is currently '
        'supported by this test harness.',
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
    id: 'test_trade_screen_e5c',
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
    players: const [
      // ignore: avoid_hardcoded_strings_in_widgets
      Player(id: _humanPlayerId, displayName: 'England', isHuman: true,
          treasury: 500),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: const WorldMarketState(),
  );
}

Orders _orders(List<TradeOrder> tradeOrders) {
  return Orders(
    tradeOrdersByPlayerId: <String, List<TradeOrder>>{
      _humanPlayerId: tradeOrders,
    },
  );
}

TradeOrder _bid(CommodityId commodityId, int quantity) {
  return TradeOrder(
    commodityId: commodityId,
    type: TradeOrderType.bid,
    quantity: quantity,
    priority: 1,
  );
}

TradeOrder _offer(CommodityId commodityId, int quantity) {
  return TradeOrder(
    commodityId: commodityId,
    type: TradeOrderType.offer,
    quantity: quantity,
    priority: 1,
  );
}

/// Mirrors the E5b harness — pumps [TradeScreen] in isolation under a
/// [ProviderScope] that exposes [currentGameProvider],
/// [currentOrdersProvider], and a (mockable) [shellPlayerContextProvider].
/// Uses a tall (1024 × 4096) test viewport so every alphabetical row
/// in the 22-commodity list lays out inside the scroll view at once.
Future<ProviderContainer> _pumpTradeScreen(
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
          // ignore: avoid_hardcoded_strings_in_widgets
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

CommodityId get _timber => CommodityCatalog.timber.id;
CommodityId get _iron => CommodityCatalog.iron.id;
CommodityId get _fabric => CommodityCatalog.fabric.id;
CommodityId get _grain => CommodityCatalog.grain.id;

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

int _totalStagedBid(ProviderContainer container) {
  final Orders orders = container.read(currentOrdersProvider);
  final List<TradeOrder>? list =
      orders.tradeOrdersByPlayerId[_humanPlayerId];
  if (list == null || list.isEmpty) return 0;
  int total = 0;
  for (final TradeOrder o in list) {
    if (o.type == TradeOrderType.bid) total += o.quantity;
  }
  return total;
}

String _cargoIndicatorText(WidgetTester tester) {
  final Text widget = tester.widget<Text>(
    find.byKey(TradeScreen.marketCargoIndicatorKey),
  );
  return widget.data ?? '';
}

void main() {
  suppressLogsForTests();

  group(
    'TradeScreen Market tab cargo indicator + cap + warning '
    '(Refs #2993 E5c)',
    () {
      testWidgets(
        'no home fleet and no staged orders → indicator reads '
        '"Cargo remaining: 24" (defaultCargoHoldsStub) and the '
        'warning row is absent',
        (tester) async {
          await _pumpTradeScreen(tester, game: _buildGame());

          expect(
            find.byKey(TradeScreen.marketCargoIndicatorKey),
            findsOneWidget,
          );
          expect(_cargoIndicatorText(tester), 'Cargo remaining: 24');
          expect(
            find.byKey(TradeScreen.marketCargoWarningKey),
            findsNothing,
          );
        },
      );

      testWidgets(
        'staged offers do not consume cargo → indicator stays at the '
        'full capacity and the warning row is absent',
        (tester) async {
          await _pumpTradeScreen(
            tester,
            game: _buildGame(),
            initialOrders: _orders(<TradeOrder>[
              _offer(_fabric, 7),
              _offer(_timber, 3),
            ]),
          );

          expect(_cargoIndicatorText(tester), 'Cargo remaining: 24');
          expect(
            find.byKey(TradeScreen.marketCargoWarningKey),
            findsNothing,
          );
        },
      );

      testWidgets(
        'staged bids totalling 7 (timber 4 + iron 3) under capacity 24 → '
        'indicator reads "Cargo remaining: 17" and no warning is shown',
        (tester) async {
          await _pumpTradeScreen(
            tester,
            game: _buildGame(),
            initialOrders: _orders(<TradeOrder>[
              _bid(_timber, 4),
              _bid(_iron, 3),
            ]),
          );

          expect(_cargoIndicatorText(tester), 'Cargo remaining: 17');
          expect(
            find.byKey(TradeScreen.marketCargoWarningKey),
            findsNothing,
          );
        },
      );

      testWidgets(
        'capacity 10 with bids totalling 10 → indicator reads '
        '"Cargo remaining: 0" AND the warning row is mounted with '
        'the canonical copy',
        (tester) async {
          await _pumpTradeScreen(
            tester,
            game: _buildGame(tradeCargoCapacityOverride: 10),
            initialOrders: _orders(<TradeOrder>[
              _bid(_timber, 6),
              _bid(_iron, 4),
            ]),
          );

          expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
          expect(
            find.byKey(TradeScreen.marketCargoWarningKey),
            findsOneWidget,
          );
          expect(
            find.text(TradeScreen.cargoLimitWarningText),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'capacity 10 with bid timber 6 (cargo remaining 4): incrementing '
        'timber `+` four times brings staged quantity to 10 then the '
        'fifth `+` tap is a silent no-op (cross-commodity total clamped '
        'at 10) and the warning row mounts at saturation',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreen(
            tester,
            game: _buildGame(tradeCargoCapacityOverride: 10),
            initialOrders: _orders(<TradeOrder>[_bid(_timber, 6)]),
          );

          expect(_cargoIndicatorText(tester), 'Cargo remaining: 4');
          expect(
            find.byKey(TradeScreen.marketCargoWarningKey),
            findsNothing,
          );

          for (int i = 0; i < 4; i++) {
            await tester
                .tap(find.byKey(TradeScreen.marketRowIncrementKey(_timber)));
            await tester.pump();
          }
          expect(_stagedOrder(container, _timber)?.quantity, 10);
          expect(_totalStagedBid(container), 10);
          expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
          expect(
            find.byKey(TradeScreen.marketCargoWarningKey),
            findsOneWidget,
          );

          // 5th increment is blocked by the cross-commodity cap.
          await tester
              .tap(find.byKey(TradeScreen.marketRowIncrementKey(_timber)));
          await tester.pump();
          expect(
            _stagedOrder(container, _timber)?.quantity,
            10,
            reason: 'Refs #2993 E5c: bid increment blocked when '
                'cross-commodity bid total saturates tradeCargoCapacity.',
          );
          expect(_totalStagedBid(container), 10);
        },
      );

      testWidgets(
        'capacity 10 with cargo saturated (timber 6 + iron 4): tapping '
        '`Bid` on a fresh commodity (grain) is a silent no-op — no '
        'TradeOrder for grain is staged and the cross-commodity bid '
        'total stays at 10',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreen(
            tester,
            game: _buildGame(tradeCargoCapacityOverride: 10),
            initialOrders: _orders(<TradeOrder>[
              _bid(_timber, 6),
              _bid(_iron, 4),
            ]),
          );

          expect(_stagedOrder(container, _grain), isNull);

          await tester
              .tap(find.byKey(TradeScreen.marketRowBidChipKey(_grain)));
          await tester.pump();

          expect(
            _stagedOrder(container, _grain),
            isNull,
            reason: 'Refs #2993 E5c: Bid toggle is a no-op when '
                'maxAllowedBidQuantity <= 0.',
          );
          expect(_totalStagedBid(container), 10);
          expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
          expect(
            find.byKey(TradeScreen.marketCargoWarningKey),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'capacity 10 with cargo saturated and a staged offer: tapping '
        '`Bid` on the offer row is also blocked (the prior offer '
        'survives because the toggle is rejected)',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreen(
            tester,
            game: _buildGame(tradeCargoCapacityOverride: 10),
            initialOrders: _orders(<TradeOrder>[
              _bid(_timber, 6),
              _bid(_iron, 4),
              _offer(_fabric, 5),
            ]),
          );

          await tester
              .tap(find.byKey(TradeScreen.marketRowBidChipKey(_fabric)));
          await tester.pump();

          final TradeOrder? fabric = _stagedOrder(container, _fabric);
          expect(
            fabric?.type,
            TradeOrderType.offer,
            reason: 'Refs #2993 E5c: bid toggle is rejected when '
                'maxAllowedBidQuantity <= 0; the prior offer stays.',
          );
          expect(fabric?.quantity, 5);
          expect(_totalStagedBid(container), 10);
        },
      );

      testWidgets(
        'capacity 10 with offer fabric 8 (cargo remaining 10): tapping '
        '`Bid` on fabric preserves the prior quantity (8 ≤ 10) and '
        'reduces cargo remaining to 2',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreen(
            tester,
            game: _buildGame(tradeCargoCapacityOverride: 10),
            initialOrders: _orders(<TradeOrder>[_offer(_fabric, 8)]),
          );

          expect(_cargoIndicatorText(tester), 'Cargo remaining: 10');

          await tester
              .tap(find.byKey(TradeScreen.marketRowBidChipKey(_fabric)));
          await tester.pump();

          final TradeOrder? fabric = _stagedOrder(container, _fabric);
          expect(fabric?.type, TradeOrderType.bid);
          expect(fabric?.quantity, 8);
          expect(_totalStagedBid(container), 8);
          expect(_cargoIndicatorText(tester), 'Cargo remaining: 2');
          expect(
            find.byKey(TradeScreen.marketCargoWarningKey),
            findsNothing,
          );
        },
      );

      testWidgets(
        'capacity 10 with bid timber 9 (cargo remaining 1) AND offer '
        'fabric 5: tapping `Bid` on fabric clamps the new staged '
        'quantity to the remaining cargo (1, not the prior 5)',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreen(
            tester,
            game: _buildGame(tradeCargoCapacityOverride: 10),
            initialOrders: _orders(<TradeOrder>[
              _bid(_timber, 9),
              _offer(_fabric, 5),
            ]),
          );

          expect(_cargoIndicatorText(tester), 'Cargo remaining: 1');

          await tester
              .tap(find.byKey(TradeScreen.marketRowBidChipKey(_fabric)));
          await tester.pump();

          final TradeOrder? fabric = _stagedOrder(container, _fabric);
          expect(fabric?.type, TradeOrderType.bid);
          expect(
            fabric?.quantity,
            1,
            reason: 'Refs #2993 E5c: bid toggle clamps quantity to '
                'maxAllowedBidQuantity (remainingCargo + priorBidContribution).',
          );
          expect(_totalStagedBid(container), 10);
          expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
          expect(
            find.byKey(TradeScreen.marketCargoWarningKey),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'capacity 10 saturated with bid timber 10: tapping `−` on '
        'timber frees one unit of cargo, removes the warning row, and '
        'updates the indicator to "Cargo remaining: 1"',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreen(
            tester,
            game: _buildGame(tradeCargoCapacityOverride: 10),
            initialOrders: _orders(<TradeOrder>[_bid(_timber, 10)]),
          );

          expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
          expect(
            find.byKey(TradeScreen.marketCargoWarningKey),
            findsOneWidget,
          );

          await tester
              .tap(find.byKey(TradeScreen.marketRowDecrementKey(_timber)));
          await tester.pump();

          expect(_stagedOrder(container, _timber)?.quantity, 9);
          expect(_cargoIndicatorText(tester), 'Cargo remaining: 1');
          expect(
            find.byKey(TradeScreen.marketCargoWarningKey),
            findsNothing,
          );
        },
      );

      testWidgets(
        'capacity 10 saturated with bid timber 10: tapping `None` on '
        'timber removes the staged TradeOrder, frees the entire cargo '
        'budget, and removes the warning row',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreen(
            tester,
            game: _buildGame(tradeCargoCapacityOverride: 10),
            initialOrders: _orders(<TradeOrder>[_bid(_timber, 10)]),
          );

          await tester
              .tap(find.byKey(TradeScreen.marketRowNoneChipKey(_timber)));
          await tester.pump();

          expect(_stagedOrder(container, _timber), isNull);
          expect(_totalStagedBid(container), 0);
          expect(_cargoIndicatorText(tester), 'Cargo remaining: 10');
          expect(
            find.byKey(TradeScreen.marketCargoWarningKey),
            findsNothing,
          );
        },
      );

      testWidgets(
        'observe mode (canMutateViaUi == false): the cargo indicator '
        'and warning row stay mounted with live text values; the chip '
        'taps are blocked by the existing IgnorePointer wrapper so '
        'currentOrdersProvider is not mutated',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreen(
            tester,
            game: _buildGame(tradeCargoCapacityOverride: 10),
            initialOrders: _orders(<TradeOrder>[
              _bid(_timber, 6),
              _bid(_iron, 4),
            ]),
            canMutateViaUi: false,
          );

          expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
          expect(
            find.byKey(TradeScreen.marketCargoWarningKey),
            findsOneWidget,
          );

          // Attempting to tap the increment / None chip is swallowed by
          // IgnorePointer (`warnIfMissed: false` silences the expected
          // hit-test warning that surfaces when the wrapper absorbs
          // the pointer event).
          await tester.tap(
            find.byKey(TradeScreen.marketRowNoneChipKey(_timber)),
            warnIfMissed: false,
          );
          await tester.pump();

          expect(
            _stagedOrder(container, _timber)?.quantity,
            6,
            reason: 'Observe mode must not mutate currentOrdersProvider.',
          );
          expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
        },
      );
    },
  );
}
