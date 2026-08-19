// Observer seed-42 turn-1 TreasuryPlanner trade-order emission pin
// (Refs #2994 F9). SPEC/ai/treasury-planner.md
// § "Observer-game seed-42 trade-order emission (Refs #2994 F9)".
//
// F1–F8 ship the per-planner behaviour for `runTreasuryPlanner`
// (unit-tested in `packages/colonizethis_ai/test/planning/treasury_planner_test.dart`)
// and the orchestrator F7 wiring (unit-tested via the
// `domain_planner_orchestrator_*` suite). F9 closes the missing
// integration gap: the production Full AI entrypoint
// `generateOrdersForGameFullAI` must actually surface
// `TradeOrder` rows on a real seed-42 starting state without any
// hand-built fixtures.
//
// Seed-42 GPs stay in EXPAND for the full observer horizon (the
// 150-turn colonial regression test stays skipped per
// `seed42_observer_colonial_regression_test.dart` § skip rationale),
// so a turn-1 inspection deterministically pins the **EXPAND-phase**
// trade-emission baseline without paying the cost of a 150-turn loop.
// Once the colonial-acquisition gap (Refs #2848 / #2509 S7) closes, a
// follow-up slice can extend the same trace to a phase-varying
// EXPAND → COLONIAL assertion per `SPEC/ai/treasury-planner.md`
// § Out of scope.
//
// The structural pattern mirrors
// `seed42_expand_phase_turn1_pin_test.dart` (init game, no turn
// resolution, per-GP trace table on failure) so the two seed-42
// turn-1 pins stay easy to read together. The single-turn budget
// envelope mirrors `full_ai_first_turn_wall_clock_budget_test.dart`
// (Refs #2507): one `generateOrdersForGameFullAI` invocation per
// assertion.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart'
    show observerGoalPhaseFor;
import 'package:colonizethis_ai/src/planning/treasury_planner.dart'
    show
        kTreasuryBidPriorityEssentialInput,
        kTreasuryBidPriorityLuxury,
        kTreasuryBidPriorityRawMaterial,
        kTreasuryBidPriorityFood,
        kTreasuryOfferPriorityUrgent,
        kTreasuryOfferPriorityModerate;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

/// Great Power factionIds the F9 trace scopes to (`gp1..gp6`). Mirrors
/// `kColonialPhaseEntryGreatPowerIds` in
/// `seed42_observer_colonial_phase_entry_budget_test.dart` so the two
/// observer-tied seed-42 pins agree on the GP cohort.
const Set<String> _kGreatPowerIds = {'gp1', 'gp2', 'gp3', 'gp4', 'gp5', 'gp6'};

/// Allowed priority integers a `TradeOrder` may carry on emission from
/// `runTreasuryPlanner`. Sourced from the planner module constants so a
/// future re-tier of the bid/offer priorities updates the test
/// surface in one place. Constructed from a list (de-duplicated to a
/// set) because the F4 essential-input bid tier currently shares the
/// integer `2` with the F8 urgent offer tier; a set literal with both
/// constants would otherwise trip the `equal_elements_in_set` analyzer
/// warning while remaining semantically correct.
final Set<int> _kAllowedTreasuryPlannerPriorities = <int>[
  kTreasuryBidPriorityEssentialInput,
  kTreasuryBidPriorityLuxury,
  kTreasuryBidPriorityRawMaterial,
  kTreasuryBidPriorityFood,
  kTreasuryOfferPriorityUrgent,
  kTreasuryOfferPriorityModerate,
].toSet();

/// Per-GP turn-1 row recorded for the F9 diagnostic trace. Surfaced on
/// any failing assertion via `reason:` so a regression in the planner
/// chain or the orchestrator F7 append pinpoints which GP / phase /
/// counts diverged.
class _Gp1TradeEmissionTrace {
  const _Gp1TradeEmissionTrace({
    required this.gpId,
    required this.tradeOrders,
    required this.bidCount,
    required this.offerCount,
    required this.treasury,
    required this.phase,
  });

  final String gpId;
  final int tradeOrders;
  final int bidCount;
  final int offerCount;
  final int treasury;
  final ObserverGoalPhase phase;

  String formatRow() =>
      '$gpId  tradeOrders=$tradeOrders  bids=$bidCount  '
      'offers=$offerCount  treasury=$treasury  phase=$phase';
}

List<_Gp1TradeEmissionTrace> _buildTradeEmissionTrace({
  required Game game,
  required FullAIResult result,
  required MapTopology topology,
}) {
  final rows = <_Gp1TradeEmissionTrace>[];
  for (var i = 1; i <= 6; i++) {
    final gpId = 'gp$i';
    final orders =
        result.orders.tradeOrdersByPlayerId[gpId] ?? const <TradeOrder>[];
    final bids = orders.where((o) => o.type == TradeOrderType.bid).length;
    final offers = orders.where((o) => o.type == TradeOrderType.offer).length;
    final view = buildPlayerView(game, topology, gpId);
    final snapshot = AIWorldSnapshot.fromPlayerView(view, topology: topology);
    rows.add(
      _Gp1TradeEmissionTrace(
        gpId: gpId,
        tradeOrders: orders.length,
        bidCount: bids,
        offerCount: offers,
        treasury: game.playerById(gpId)?.treasury ?? -1,
        phase: observerGoalPhaseFor(snapshot: snapshot, game: game),
      ),
    );
  }
  return rows;
}

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  suppressLogsForTests();

  group('seed 42 turn 1 TreasuryPlanner trade-order emission (Refs #2994 F9)', () {
    test(
      'generateOrdersForGameFullAI emits TradeOrders for at least one Great '
      'Power and every emitted order satisfies the F1–F5 invariants',
      () {
        final init = runInitGame(
          config: GameSetupConfig(seed: 42),
          options: const InitGameOptions(
            cellSize: 24,
            renderPng: false,
            skipFillLakes: false,
          ),
        );
        final game = init.game.copyWith(
          aiControlByGpId: {for (final p in init.game.players) p.id: true},
        );
        final topology = init.combinedTopology;
        final tileMapByRegion = init.tileMapByRegion;

        final result = generateOrdersForGameFullAI(
          game,
          topology,
          tileMapByRegion: tileMapByRegion,
        );

        final rows = _buildTradeEmissionTrace(
          game: game,
          result: result,
          topology: topology,
        );
        final traceTable = rows.map((r) => r.formatRow()).join('\n');
        final reason = 'seed-42 turn-1 per-GP trade-emission trace:\n'
            '$traceTable';

        // AC F9.1: at least one Great Power emits at least one TradeOrder.
        final aggregatedCount = result.orders.tradeOrdersByPlayerId.values
            .fold<int>(0, (sum, list) => sum + list.length);
        expect(
          aggregatedCount,
          greaterThan(0),
          reason:
              'Refs #2994 F9 AC-1: generateOrdersForGameFullAI must surface '
              'at least one trade order across all AI Great Powers on the '
              'seed-42 turn-1 starting state. $reason',
        );

        // AC F9.2: every emitted TradeOrder satisfies the F1–F5 invariants.
        for (final gpId in _kGreatPowerIds) {
          final orders =
              result.orders.tradeOrdersByPlayerId[gpId] ?? const <TradeOrder>[];
          for (var i = 0; i < orders.length; i++) {
            final order = orders[i];
            expect(
              order.quantity,
              greaterThan(0),
              reason:
                  'Refs #2994 F9 AC-2 (quantity > 0): $gpId trade order #$i '
                  'has non-positive quantity ${order.quantity}. $reason',
            );
            expect(
              _kAllowedTreasuryPlannerPriorities.contains(order.priority),
              isTrue,
              reason:
                  'Refs #2994 F9 AC-2 (priority tier): $gpId trade order #$i '
                  'has priority ${order.priority} outside the planner-allowed '
                  'set $_kAllowedTreasuryPlannerPriorities. $reason',
            );
            expect(
              richesCommodityIds.contains(order.commodityId),
              isFalse,
              reason:
                  'Refs #2994 F9 AC-2 (riches exclusion): $gpId trade order '
                  '#$i targets riches commodity ${order.commodityId}, but the '
                  'TreasuryPlanner skips ids in richesCommodityIds. $reason',
            );
            expect(
              order.type == TradeOrderType.bid ||
                  order.type == TradeOrderType.offer,
              isTrue,
              reason:
                  'Refs #2994 F9 AC-2 (type domain): $gpId trade order #$i '
                  'has type ${order.type} outside '
                  '{TradeOrderType.bid, TradeOrderType.offer}. $reason',
            );
          }
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'generateOrdersForGameFullAI is deterministic on seed-42 turn 1: two '
      'runs produce identical tradeOrdersByPlayerId',
      () {
        final init = runInitGame(
          config: GameSetupConfig(seed: 42),
          options: const InitGameOptions(
            cellSize: 24,
            renderPng: false,
            skipFillLakes: false,
          ),
        );
        final game = init.game.copyWith(
          aiControlByGpId: {for (final p in init.game.players) p.id: true},
        );
        final topology = init.combinedTopology;
        final tileMapByRegion = init.tileMapByRegion;

        final r1 = generateOrdersForGameFullAI(
          game,
          topology,
          tileMapByRegion: tileMapByRegion,
        );
        final r2 = generateOrdersForGameFullAI(
          game,
          topology,
          tileMapByRegion: tileMapByRegion,
        );

        // Compare per-player to surface which GP diverged on failure.
        final allGpIds = <String>{
          ...r1.orders.tradeOrdersByPlayerId.keys,
          ...r2.orders.tradeOrdersByPlayerId.keys,
        };
        for (final gpId in allGpIds) {
          final a = r1.orders.tradeOrdersByPlayerId[gpId] ??
              const <TradeOrder>[];
          final b = r2.orders.tradeOrdersByPlayerId[gpId] ??
              const <TradeOrder>[];
          expect(
            a,
            b,
            reason:
                'Refs #2994 F9 AC-3 (determinism): seed-42 turn-1 trade '
                'orders for $gpId differ between two consecutive '
                'generateOrdersForGameFullAI invocations. '
                'run1=$a run2=$b',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
