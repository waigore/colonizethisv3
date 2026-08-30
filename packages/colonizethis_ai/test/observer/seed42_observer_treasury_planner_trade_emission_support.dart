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
const Set<String> kSeed42TreasuryTradeEmissionGreatPowerIds = {
  'gp1',
  'gp2',
  'gp3',
  'gp4',
  'gp5',
  'gp6',
};

final Set<int> kSeed42TreasuryTradeEmissionAllowedPriorities = <int>[
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
class Seed42TreasuryTradeEmissionTraceRow {
  const Seed42TreasuryTradeEmissionTraceRow({
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

List<Seed42TreasuryTradeEmissionTraceRow> buildSeed42TreasuryTradeEmissionTrace({
  required Game game,
  required FullAIResult result,
  required MapTopology topology,
}) {
  final rows = <Seed42TreasuryTradeEmissionTraceRow>[];
  for (var i = 1; i <= 6; i++) {
    final gpId = 'gp$i';
    final orders =
        result.orders.tradeOrdersByPlayerId[gpId] ?? const <TradeOrder>[];
    final bids = orders.where((o) => o.type == TradeOrderType.bid).length;
    final offers = orders.where((o) => o.type == TradeOrderType.offer).length;
    final view = buildPlayerView(game, topology, gpId);
    final snapshot = AIWorldSnapshot.fromPlayerView(view, topology: topology);
    rows.add(
      Seed42TreasuryTradeEmissionTraceRow(
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

