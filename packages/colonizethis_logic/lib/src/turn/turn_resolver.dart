import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../event_bus/game_event_bus.dart';
import '../game_events.dart';
import '../orders/order_engine.dart';
import '../orders/order_merge.dart';
import '../world/army_migration.dart';
export 'economy_preview_pipeline.dart'
    show
        applyEconomyPhasesForPreview,
        economyPreviewStockpilePhaseDeltasForPlayer,
        previewStockpileNetDeltaByCommodityForPlayer,
        previewStockpilePhaseDeltasByCommodityForPlayer;
import 'turn_order_acceptance.dart';
import 'turn_phase_runner.dart';
import 'turn_resolution_result.dart';
import 'turn_resolution_sequence.dart';
import 'trace/turn_trace_contracts.dart';
import 'trace/turn_trace_runtime.dart';
export 'turn_resolution_sequence.dart';
import 'turn_resolver_config.dart';
export 'turn_resolver_config.dart';

/// Turn resolver stub (Phase 1 compatibility). Runs phase sequence; only
/// endOfTurn advances turn number.
WorldState resolveTurn(WorldState current) {
  WorldState state = current;
  for (final phase in turnResolutionSequence) {
    state = _runWorldStatePhase(state, phase);
  }
  return state;
}

WorldState _runWorldStatePhase(WorldState state, TurnPhase phase) {
  switch (phase) {
    case TurnPhase.orders:
    case TurnPhase.extraction:
    case TurnPhase.richesToTreasury:
    case TurnPhase.production:
    case TurnPhase.consumption:
    case TurnPhase.research:
    case TurnPhase.diplomacy:
    case TurnPhase.movement:
    case TurnPhase.minorRegimentUpgrade:
    case TurnPhase.navalInterceptionCombat:
    case TurnPhase.combat:
    case TurnPhase.buildWork:
      return state;
    case TurnPhase.endOfTurn:
      return state.copyWith(
        turnState: state.turnState.copyWith(
          turnNumber: state.turnState.turnNumber + 1,
          phase: TurnPhase.orders,
        ),
      );
  }
}

/// Resolves turn using OrderEngine output. Merges human + AI orders (AI optional).
/// SPEC/program/order-engine.md: merge at turn resolution.
/// Returns [TurnResolutionResult]; may be [TurnResolutionPendingOvertures] when a human must accept/reject an overture.
TurnResolutionResult resolveTurnForGameFromOrderEngine({
  required Game game,
  required MapTopology topology,
  required OrderEngine orderEngine,
  Orders? aiOrders,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  GameEventBus? eventBus,
  void Function(DialogueEvent)? onDialogue,
  void Function(GameEvent)? onGameEvent,
  void Function(TurnTracePhaseTrace phaseTrace)? onTurnTracePhase,
  TurnTraceRuntime? turnTraceRuntime,
}) {
  final merged = mergeOrderLists(
    humanOrders: orderEngine.orders,
    aiOrders: aiOrders,
  );
  return validateOrdersAndResolveTurn(
    game: game,
    topology: topology,
    orders: merged,
    eventBus: eventBus,
    onDialogue: onDialogue,
    onGameEvent: onGameEvent,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
    extractedByPlayerId: extractedByPlayerId,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
    onTurnTracePhase: onTurnTracePhase,
    turnTraceRuntime: turnTraceRuntime,
  );
}

/// Validates orders and resolves the turn. Returns [TurnResolutionResult];
/// may be [TurnResolutionPendingOvertures] when a human must accept/reject an overture.
///
/// **Untrusted entry point.** Runs [filterAcceptedOrdersForAllPlayers] over
/// the supplied [orders] before applying so any rejected orders are stripped
/// from each per-player list. Required for callers whose order sources are not
/// pre-validated (scenario runners, ad-hoc test orders, manual JSON-loaded
/// orders, future external/manual sources).
///
/// Use [validateOrdersAndResolveTurnFromTrustedOrders] when every order has
/// already passed OrderEngine validation (human draft) or the order suggestion
/// API guarantee (AI orders). Both entry points return the same resulting
/// [WorldState] for inputs whose orders all pass validation.
///
/// SPEC: `SPEC/program/order-engine.md` § Turn Resolution Integration §
/// Trusted-source resolution.
TurnResolutionResult validateOrdersAndResolveTurn({
  required Game game,
  required MapTopology topology,
  required Orders orders,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  GameEventBus? eventBus,
  void Function(DialogueEvent)? onDialogue,
  void Function(GameEvent)? onGameEvent,
  void Function(TurnPhase phase, TurnPhaseProgressMarker marker)?
  onPhaseProgress,
  void Function(TurnTracePhaseTrace phaseTrace)? onTurnTracePhase,
  TurnTraceRuntime? turnTraceRuntime,
}) {
  final engine = OrderEngine(initialOrders: orders);
  final filtered = filterAcceptedOrdersForAllPlayers(
    engine: engine,
    game: game,
    topology: topology,
    eventBus: eventBus,
    onGameEvent: onGameEvent,
    tileMapByRegion: tileMapByRegion,
  );
  return resolveTurnForGame(
    game: game,
    eventBus: eventBus,
    onDialogue: onDialogue,
    onGameEvent: onGameEvent,
    topology: topology,
    orders: filtered,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
    extractedByPlayerId: extractedByPlayerId,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
    onPhaseProgress: onPhaseProgress,
    onTurnTracePhase: onTurnTracePhase,
    turnTraceRuntime: turnTraceRuntime,
  );
}

/// Resolves the turn using [orders] without running the per-player pre-apply
/// validation pass.
///
/// **Trusted entry point.** Skips [filterAcceptedOrdersForAllPlayers] and
/// dispatches straight to [resolveTurnForGame]. Caller contract: every order in
/// [orders] must already have been accepted by either:
///
/// 1. [OrderEngine.addXxxOrderWithContext] (human draft orders), or
/// 2. the order suggestion API guarantee (AI-generated orders) — see
///    `SPEC/program/order-suggestions.md` § Guarantees.
///
/// Use this entry point only when the order sources are auditable as
/// pre-validated. Mixing untrusted orders breaks the contract; for any other
/// source use [validateOrdersAndResolveTurn] instead.
///
/// A separate function name (not a flag on [Orders]) is the chosen mechanism
/// so trust does not propagate silently through copies or future refactors.
///
/// SPEC: `SPEC/program/order-engine.md` § Turn Resolution Integration §
/// Trusted-source resolution.
TurnResolutionResult validateOrdersAndResolveTurnFromTrustedOrders({
  required Game game,
  required MapTopology topology,
  required Orders orders,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  GameEventBus? eventBus,
  void Function(DialogueEvent)? onDialogue,
  void Function(GameEvent)? onGameEvent,
  void Function(Map<String, Map<String, int>> productionByRecipeByPlayerId)?
  onProductionComplete,
  void Function(TurnPhase phase, TurnPhaseProgressMarker marker)?
  onPhaseProgress,
  void Function(TurnTracePhaseTrace phaseTrace)? onTurnTracePhase,
  TurnTraceRuntime? turnTraceRuntime,
}) {
  return resolveTurnForGame(
    game: game,
    eventBus: eventBus,
    onDialogue: onDialogue,
    onGameEvent: onGameEvent,
    onProductionComplete: onProductionComplete,
    topology: topology,
    orders: orders,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
    extractedByPlayerId: extractedByPlayerId,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
    onPhaseProgress: onPhaseProgress,
    onTurnTracePhase: onTurnTracePhase,
    turnTraceRuntime: turnTraceRuntime,
  );
}

/// Resolves one full turn. Returns [TurnResolutionComplete] with the new game state,
/// or [TurnResolutionPendingOvertures] when the Diplomacy phase needs a human target
/// to accept/reject an overture (SPEC/program/turn-resolution-phases.md § Blocking human input).
/// When [startFromPhase] is set (e.g. [TurnPhase.diplomacy] for resume), phases before it are skipped.
/// When [overtureDecisions] is set, those decisions are applied in the Diplomacy phase (resume path).
TurnResolutionResult resolveTurnForGame({
  required Game game,
  required MapTopology topology,
  required Orders orders,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  GameEventBus? eventBus,
  void Function(DialogueEvent)? onDialogue,
  void Function(GameEvent)? onGameEvent,
  void Function(Map<String, Map<String, int>> productionByRecipeByPlayerId)?
  onProductionComplete,
  TurnPhase? startFromPhase,
  List<OvertureDecision>? overtureDecisions,
  List<InterventionDecision>? interventionDecisions,
  List<CallToArmsDecision>? callToArmsDecisions,
  void Function(TurnPhase phase, TurnPhaseProgressMarker marker)?
  onPhaseProgress,
  void Function(TurnTracePhaseTrace phaseTrace)? onTurnTracePhase,
  TurnTraceRuntime? turnTraceRuntime,
}) {
  return resolveTurnForGameWithConfig(
    game: game,
    config: TurnResolverConfig(
      topology: topology,
      orders: orders,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
      extractedByPlayerId: extractedByPlayerId,
      defaultAssignments: defaultAssignments,
      defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
      eventBus: eventBus,
      onDialogue: onDialogue,
      onGameEvent: onGameEvent,
      onProductionComplete: onProductionComplete,
      startFromPhase: startFromPhase,
      overtureDecisions: overtureDecisions,
      interventionDecisions: interventionDecisions,
      callToArmsDecisions: callToArmsDecisions,
      onPhaseProgress: onPhaseProgress,
      onTurnTracePhase: onTurnTracePhase,
      turnTraceRuntime: turnTraceRuntime,
    ),
  );
}

/// Same as [resolveTurnForGame] but takes a single [TurnResolverConfig].
TurnResolutionResult resolveTurnForGameWithConfig({
  required Game game,
  required TurnResolverConfig config,
}) {
  final turn = game.worldState.turnState.turnNumber;
  logicLog.i('turn $turn resolve start');
  final state = ensureMilitaryArmiesForGame(game);
  final gameAtResolutionStart = state;
  return runTurnResolutionPipeline(
    gameAtResolutionStart: gameAtResolutionStart,
    config: config,
  );
}

/// Returns the game when [result] is [TurnResolutionComplete]; throws when pending.
/// Use in tests or callers that do not yet handle [TurnResolutionPendingOvertures].
Game requireTurnResolutionComplete(TurnResolutionResult result) {
  if (result is TurnResolutionComplete) {
    return gameFromTurnResolutionResult(result);
  }
  throw StateError(_pendingTurnResolutionMessage(result));
}

/// Diagnostic message for a non-complete [TurnResolutionResult]. Co-locates the
/// per-variant resume hints so adding a new pending variant requires touching a
/// single switch instead of every caller of [requireTurnResolutionComplete].
String _pendingTurnResolutionMessage(TurnResolutionResult result) {
  return switch (result) {
    TurnResolutionComplete() =>
      'Turn resolution is complete; no pending decisions',
    TurnResolutionPendingOvertures() =>
      'Turn resolution is pending overture decisions; use resumeTurnResolutionWithOvertureDecisions',
    TurnResolutionPendingIntervention() =>
      'Turn resolution is pending intervention decisions; use resumeTurnResolutionWithInterventionDecisions',
    TurnResolutionPendingCallToArms() =>
      'Turn resolution is pending call to arms; use resumeTurnResolutionWithCallToArmsDecisions',
  };
}

/// Resumes turn resolution after the app has collected overture accept/reject decisions
/// from the human target(s). Call with the [game] and [pendingOvertures] from
/// [TurnResolutionPendingOvertures], and the [decisions] from the user. Other parameters
/// must match those used for the original resolveTurnForGame call (orders, topology, etc.).
TurnResolutionResult resumeTurnResolutionWithOvertureDecisions({
  required Game game,
  required List<OvertureOffer> pendingOvertures,
  required List<OvertureDecision> decisions,
  required MapTopology topology,
  required Orders orders,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  GameEventBus? eventBus,
  void Function(DialogueEvent)? onDialogue,
  void Function(GameEvent)? onGameEvent,
  void Function(Map<String, Map<String, int>> productionByRecipeByPlayerId)?
  onProductionComplete,
}) {
  return resolveTurnForGame(
    game: game,
    topology: topology,
    orders: orders,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
    extractedByPlayerId: extractedByPlayerId,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
    eventBus: eventBus,
    onDialogue: onDialogue,
    onGameEvent: onGameEvent,
    onProductionComplete: onProductionComplete,
    startFromPhase: TurnPhase.diplomacy,
    overtureDecisions: decisions,
  );
}

/// Resumes turn resolution after human intervention choices (Diplomacy phase).
TurnResolutionResult resumeTurnResolutionWithInterventionDecisions({
  required Game game,
  required List<InterventionDecision> decisions,
  required MapTopology topology,
  required Orders orders,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  GameEventBus? eventBus,
  void Function(DialogueEvent)? onDialogue,
  void Function(GameEvent)? onGameEvent,
  void Function(Map<String, Map<String, int>> productionByRecipeByPlayerId)?
  onProductionComplete,
}) {
  return resolveTurnForGame(
    game: game,
    topology: topology,
    orders: orders,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
    extractedByPlayerId: extractedByPlayerId,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
    eventBus: eventBus,
    onDialogue: onDialogue,
    onGameEvent: onGameEvent,
    onProductionComplete: onProductionComplete,
    startFromPhase: TurnPhase.diplomacy,
    interventionDecisions: decisions,
  );
}

/// Resumes turn resolution after human ally(ies) responded to call to arms.
TurnResolutionResult resumeTurnResolutionWithCallToArmsDecisions({
  required Game game,
  required List<CallToArmsDecision> decisions,
  required MapTopology topology,
  required Orders orders,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  GameEventBus? eventBus,
  void Function(DialogueEvent)? onDialogue,
  void Function(GameEvent)? onGameEvent,
  void Function(Map<String, Map<String, int>> productionByRecipeByPlayerId)?
  onProductionComplete,
}) {
  return resolveTurnForGame(
    game: game,
    topology: topology,
    orders: orders,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
    extractedByPlayerId: extractedByPlayerId,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
    eventBus: eventBus,
    onDialogue: onDialogue,
    onGameEvent: onGameEvent,
    onProductionComplete: onProductionComplete,
    startFromPhase: TurnPhase.diplomacy,
    callToArmsDecisions: decisions,
  );
}
