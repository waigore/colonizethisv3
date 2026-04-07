import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../event_bus/game_event_bus.dart';
import '../game_events.dart';
import '../orders/order_engine.dart';
import '../orders/order_merge.dart';
import '../world/army_migration.dart';
export 'economy_preview_pipeline.dart'
    show
        applyEconomyPhasesForPreview,
        economyPreviewStockpilePhaseDeltasForPlayer;
import 'turn_order_acceptance.dart';
import 'turn_phase_runner.dart';
import 'turn_resolution_result.dart';
import 'turn_resolution_sequence.dart';
export 'turn_resolution_sequence.dart';
import 'turn_resolver_config.dart';
export 'turn_resolver_config.dart';

final _log = logicLogger();

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
  );
}

/// Validates orders and resolves the turn. Returns [TurnResolutionResult];
/// may be [TurnResolutionPendingOvertures] when a human must accept/reject an overture.
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
    ),
  );
}

/// Same as [resolveTurnForGame] but takes a single [TurnResolverConfig].
TurnResolutionResult resolveTurnForGameWithConfig({
  required Game game,
  required TurnResolverConfig config,
}) {
  final turn = game.worldState.turnState.turnNumber;
  _log.i('turn $turn resolve start');
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
  return switch (result) {
    TurnResolutionComplete(:final game) => game,
    TurnResolutionPendingOvertures() => throw StateError(
      'Turn resolution is pending overture decisions; use resumeTurnResolutionWithOvertureDecisions',
    ),
    TurnResolutionPendingIntervention() => throw StateError(
      'Turn resolution is pending intervention decisions; use resumeTurnResolutionWithInterventionDecisions',
    ),
    TurnResolutionPendingCallToArms() => throw StateError(
      'Turn resolution is pending call to arms; use resumeTurnResolutionWithCallToArmsDecisions',
    ),
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
