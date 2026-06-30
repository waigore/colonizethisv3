/// Shared seed-42 Full-AI observer campaign harness (Refs #3749 step 2).
///
/// Single source of truth for the `runInitGame(seed: 42)` ->
/// [applyFaithfulFullAiTestHandoff] -> N-turn
/// `generateOrdersForGameFullAI` -> `mergeOrderLists` ->
/// `validateOrdersAndResolveTurnFromTrustedOrders` resolve loop duplicated
/// across the top-level `seed42_observer_*` integration tests. Each migrated
/// test supplies only its per-turn observation via [onBeforeResolve] /
/// [onAfterResolve] and reads the start / end game from the returned
/// [Seed42ObserverCampaignResult]; the init, handoff, per-turn order
/// generation, merge, trusted-order resolution, and the
/// `expect(result, isA<TurnResolutionComplete>())` assertion live here once.
///
/// Behaviour-preserving against the inline loops it replaces: the same
/// [GameSetupConfig] seed, [InitGameOptions] (`cellSize: 24`, `renderPng:
/// false`, `skipFillLakes: false`), handoff, per-turn call order, and
/// trusted-order resolution path are retained verbatim so a migrated test
/// observes byte-identical turn-by-turn state.
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show GameSetupConfig, MapTopology, TileMapResult;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'faithful_full_ai_test_handoff.dart';

/// Per-turn observation hook invoked immediately after the Full-AI orders for
/// turn [turn] are generated and **before** turn resolution.
///
/// [fullAi] carries the generated orders / economy plans for the turn and
/// [game] is the start-of-turn game state (before resolution advances it), so
/// callbacks can read pre-resolution treasury / ownership and the emitted
/// orders together — matching the inline tests that captured both before
/// resolving. [topology] and [tileMapByRegion] are the same init artifacts the
/// harness uses for order generation and resolution so per-turn phase
/// classification (`buildPlayerView` / `runPhasePlanners`) can run inside the
/// callback without re-inlining the campaign init.
typedef Seed42ObserverBeforeResolve = void Function(
  int turn,
  FullAIResult fullAi,
  Game game,
  MapTopology topology,
  Map<String, TileMapResult> tileMapByRegion,
);

/// Per-turn observation hook invoked immediately **after** turn [turn] is
/// resolved, receiving the resolved [game] for that turn.
typedef Seed42ObserverAfterResolve = void Function(int turn, Game game);

/// Result of [runSeed42ObserverCampaign].
class Seed42ObserverCampaignResult {
  const Seed42ObserverCampaignResult({
    required this.finalGame,
    required this.initialGame,
  });

  /// Game state after the final resolved turn of the campaign.
  final Game finalGame;

  /// Post-handoff game state captured before turn 0 (every player
  /// `isHuman: false`, every Great Power AI-controlled). Use this to read
  /// campaign-start baselines (for example per-GP Old World province counts).
  final Game initialGame;
}

/// Runs a seed-[seed] Full-AI observer campaign for [turns] turns and returns
/// the start / end game state.
///
/// Drives the canonical observer loop once: init the seed game, apply the
/// faithful Full-AI handoff, then for each turn generate Full-AI orders, invoke
/// [onBeforeResolve], merge with empty human orders, resolve from trusted
/// orders, assert the turn completed, advance the game, and invoke
/// [onAfterResolve].
///
/// Pure with respect to its callbacks: identical [seed] / [turns] inputs drive
/// the same deterministic turn sequence (Refs #2509 Must-have #7); the
/// callbacks are the only place a caller accumulates per-turn observations.
Seed42ObserverCampaignResult runSeed42ObserverCampaign({
  int turns = 100,
  int seed = 42,
  bool growthStagePlannerEnabled = kGrowthStagePlannerEnabled,
  Seed42ObserverBeforeResolve? onBeforeResolve,
  Seed42ObserverAfterResolve? onAfterResolve,
}) {
  final init = runInitGame(
    config: GameSetupConfig(seed: seed),
    options: const InitGameOptions(
      cellSize: 24,
      renderPng: false,
      skipFillLakes: false,
    ),
  );
  final initialGame = applyFaithfulFullAiTestHandoff(init.game);
  final topo = init.combinedTopology;
  final tileMap = init.tileMapByRegion;

  var game = initialGame;
  for (var t = 0; t < turns; t++) {
    final fullAi = generateOrdersForGameFullAI(
      game,
      topo,
      tileMapByRegion: tileMap,
      growthStagePlannerEnabled: growthStagePlannerEnabled,
    );
    onBeforeResolve?.call(t, fullAi, game, topo, tileMap);
    final merged = mergeOrderLists(
      humanOrders: const Orders(),
      aiOrders: fullAi.orders,
    );
    final assignments = fullAi.economyPlansByPlayerId.map(
      (pid, plan) => MapEntry(pid, plan.productionAssignments),
    );
    final result = validateOrdersAndResolveTurnFromTrustedOrders(
      game: fullAi.game,
      topology: topo,
      orders: merged,
      tileMapByRegion: tileMap,
      defaultAssignmentsByPlayerId: assignments,
    );
    expect(result, isA<TurnResolutionComplete>());
    game = (result as TurnResolutionComplete).game;
    onAfterResolve?.call(t, game);
  }

  return Seed42ObserverCampaignResult(
    finalGame: game,
    initialGame: initialGame,
  );
}
