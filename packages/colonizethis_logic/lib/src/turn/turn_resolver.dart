import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../event_bus/game_event_bus.dart';
import '../game_events.dart';
import '../combat/battle_general_assignment.dart';
import '../combat/combat_mode_selection.dart';
import '../orders/order_engine.dart';
import '../orders/order_merge.dart';
import '../constants.dart';
import '../combat/conflict_detection.dart';
import '../setup/capital_choice.dart';
import '../world/connectivity_resolver.dart';
import '../economy/economy_consumption.dart';
import '../economy/economy_extraction.dart';
import '../economy/economy_production.dart';
import '../economy/economy_riches_to_treasury.dart';
import '../diplomacy/diplomacy_resolver.dart';
import '../world/minor_military_parity.dart';
import '../world/army_migration.dart';
import '../world/army_movement.dart';
import '../world/movement.dart';
import '../orders/draft_orders_mutations.dart';
import '../orders/orders_application.dart';
import '../economy/resource_extractor.dart';
import '../economy/sea_transport.dart';
import 'research_resolver.dart';
import '../world/naval.dart';
import '../world/naval_resolution.dart';
import '../dossier/evidence_rules.dart';
import '../dossier/event_dialogue.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';
import '../world/unit_lookup.dart';
import '../world/capital_and_gp_fall.dart';
import 'combat_phase_helpers.dart';
import 'end_of_turn_resolver.dart';
import 'turn_resolution_events.dart';
import 'turn_resolution_result.dart';

final _log = logicLogger();

/// Resolution sequence. SPEC/program/turn-resolution-phases.md
const List<TurnPhase> turnResolutionSequence = [
  TurnPhase.orders,
  TurnPhase.extraction,
  TurnPhase.richesToTreasury,
  TurnPhase.consumption,
  TurnPhase.production,
  TurnPhase.research,
  TurnPhase.diplomacy,
  TurnPhase.movement,
  TurnPhase.minorRegimentUpgrade,
  TurnPhase.navalInterceptionCombat,
  TurnPhase.combat,
  TurnPhase.buildWork,
  TurnPhase.endOfTurn,
];

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

/// Game-level resolver that runs the full Phase 2 sequence over [game],
/// using shared economy and movement helpers.
///
/// [topology] is the static map topology; [orders] holds per-player orders
/// for this turn. When [tileMapByRegion] is provided, extraction runs from
/// connectivity + resource extractor + sea allocation. When null and
/// [extractedByPlayerId] is empty, extraction phase leaves stockpiles unchanged.
/// [extractedByPlayerId] override (non-empty) is used for tests/sim_economy.

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
  final filtered = _filterAcceptedOrdersForAllPlayers(
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

  /// Per-region topology for capital reassignment sea-bound checks (SPEC/game/world-model-identity). When set, reassignment uses [topologyByRegion][regionId] for each player's region instead of combined [topology]. Callers with multi-region (e.g. app, ctdev) should pass this. When [tileMapByRegion] is non-null, combat capital reassignment also clears terrain resources and extraction improvements on the new capital tile per SPEC/game/tile-map-and-generation.md § Town and capital tile occupancy.
  Map<String, MapTopology>? topologyByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],

  /// Per-player production assignments; when set, used for that player instead of [defaultAssignments]. SPEC/ai/economy-planner.md.
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,

  /// Event bus for game events (combat, diplomacy, research, victory, etc.). When set, events are published via bus. SPEC/program/event-bus.md.
  GameEventBus? eventBus,

  void Function(DialogueEvent)? onDialogue,

  /// Callback for game events (combat, diplomacy, research, victory, etc.). For backward compat; prefer [eventBus]. SPEC/program/game-events.md.
  void Function(GameEvent)? onGameEvent,

  /// Called after production phase with playerId → (recipeId → quantity produced). For projection API. SPEC/program/order-projections.md.
  void Function(Map<String, Map<String, int>> productionByRecipeByPlayerId)?
  onProductionComplete,

  /// When non-null, skip phases before this (used when resuming after pending overture or intervention).
  TurnPhase? startFromPhase,

  /// Overture accept/reject decisions from human target(s); when set, Diplomacy phase uses these and does not suspend.
  List<OvertureDecision>? overtureDecisions,

  /// Intervention choices after a GP declares war on a Minor/Tribe; Diplomacy phase resume path.
  List<InterventionDecision>? interventionDecisions,

  /// Call to arms accept/refuse from human ally(ies); when set, Diplomacy phase applies and does not suspend on CTA.
  List<CallToArmsDecision>? callToArmsDecisions,
}) {
  final turn = game.worldState.turnState.turnNumber;
  _log.i('turn $turn resolve start');
  Game state = ensureMilitaryArmiesForGame(game);
  final landFeedingCoverageByPlayerId = <String, double>{};
  final navalFeedingCoverageByPlayerId = <String, double>{};
  final idleLabourByPlayerId = <String, WorkerIdleCounts>{};
  final phaseIndex = startFromPhase != null
      ? turnResolutionSequence.indexOf(startFromPhase)
      : 0;

  for (var i = 0; i < turnResolutionSequence.length; i++) {
    final phase = turnResolutionSequence[i];
    if (i < phaseIndex) continue;
    _log.i('phase ${phase.name} start');
    switch (phase) {
      case TurnPhase.orders:
        // Orders are assumed to already be attached to the Game or passed in.
        break;
      case TurnPhase.extraction:
        state = _runExtractionPhase(
          state,
          topology,
          tileMapByRegion,
          extractedByPlayerId,
        );
        break;
      case TurnPhase.richesToTreasury:
        state = _runRichesToTreasuryPhase(state);
        break;
      case TurnPhase.consumption:
        state = _runConsumptionPhase(
          state,
          landFeedingCoverageByPlayerId,
          navalFeedingCoverageByPlayerId,
          idleLabourByPlayerId,
        );
        break;
      case TurnPhase.production:
        state = _runProductionPhase(
          state,
          defaultAssignments,
          defaultAssignmentsByPlayerId,
          idleLabourByPlayerId,
          onProductionComplete,
        );
        break;
      case TurnPhase.research:
        {
          final stateBeforeResearch = state;
          state = resolveResearchPhase(state, orders);
          emitResearchCompleteEvents(
            stateBeforeResearch,
            state,
            turn,
            eventBus,
            onGameEvent,
            onDialogue,
          );
          break;
        }
      case TurnPhase.diplomacy:
        {
          // Track previous diplomatic relations from game state
          final previousRelations = <String, Map<String, RelationState>>{};
          for (final rel in state.diplomacyRelations) {
            // Store both directions
            previousRelations.putIfAbsent(rel.factionId1, () => {});
            previousRelations.putIfAbsent(rel.factionId2, () => {});
            previousRelations[rel.factionId1]![rel.factionId2] = rel.state;
            previousRelations[rel.factionId2]![rel.factionId1] = rel.state;
          }
          final diploResult = resolveDiplomacyPhase(
            state,
            orders,
            onDialogue: onDialogue,
            overtureDecisions: overtureDecisions,
            interventionDecisions: interventionDecisions,
            callToArmsDecisions: callToArmsDecisions,
          );
          if (diploResult.isPending) {
            final po = diploResult.pendingOvertures;
            if (po != null && po.isNotEmpty) {
              return TurnResolutionPendingOvertures(
                game: diploResult.game,
                pendingOvertures: po,
              );
            }
            final pi = diploResult.pendingInterventions;
            if (pi != null && pi.isNotEmpty) {
              return TurnResolutionPendingIntervention(
                game: diploResult.game,
                pendingInterventions: pi,
              );
            }
            final cta = diploResult.pendingCallToArms;
            if (cta != null && cta.isNotEmpty) {
              return TurnResolutionPendingCallToArms(
                game: diploResult.game,
                pendingCallToArms: cta,
              );
            }
            throw StateError(
              'diplomacy pending but no pending lists populated',
            );
          }
          state = diploResult.game;
          emitDiplomacyChangeEvents(
            previousRelations,
            state,
            turn,
            eventBus,
            onGameEvent,
          );
          break;
        }
      case TurnPhase.movement:
        state = _runMovementPhase(state, topology, orders);
        break;
      case TurnPhase.minorRegimentUpgrade:
        state = _runMinorRegimentUpgradePhase(state);
        break;
      case TurnPhase.navalInterceptionCombat:
        state = runNavalInterceptionCombatPhase(
          state,
          topology,
          orders.navalMoveOrdersByPlayerId,
          navalFeedingCoverageByPlayerId: navalFeedingCoverageByPlayerId,
          onDialogue: onDialogue,
          onGameEvent: onGameEvent,
          eventBus: eventBus,
        );
        break;
      case TurnPhase.combat:
        {
          // Track province ownership before combat for province_captured events
          final previousOwnership = <String, String?>{};
          for (final region in [
            state.worldState.oldWorld,
            state.worldState.newWorld,
          ]) {
            for (final prov in region.provinces) {
              previousOwnership[prov.id] = prov.ownerId;
            }
          }
          state = _runCombatPhase(
            state,
            orders,
            landFeedingCoverageByPlayerId,
            topology,
            tileMapByRegion,
            topologyByRegion: topologyByRegion,
            onDialogue: onDialogue,
            onGameEvent: onGameEvent,
          );
          emitProvinceCapturedEvents(
            previousOwnership,
            state,
            turn,
            eventBus,
            onGameEvent,
            onDialogue,
          );
          break;
        }
      case TurnPhase.buildWork:
        state = applyBuildAndWorkOrders(
          state,
          orders,
          topology: topology,
          tileMapByRegion: tileMapByRegion,
          onDialogue: onDialogue,
        );
        break;
      case TurnPhase.endOfTurn:
        {
          state = runEndOfTurnPhase(
            state,
            topology: topology,
            topologyByRegion: topologyByRegion,
            onDialogue: onDialogue,
          );
          emitVictorySetEvent(state, turn, eventBus, onGameEvent);
          break;
        }
    }
    _log.i('phase ${phase.name} end');
  }

  _log.i('turn $turn resolve end');
  return TurnResolutionComplete(state);
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

/// Filters [orders] by validation [results] (consuming via [idxBox]).
/// Accepted orders are added via [addAccepted]; rejected emit [OrderRejectedEvent] when [onGameEvent] is set.
void _filterOrderList<T>(
  String playerId,
  List<T> orders,
  List<OrderValidationResult> results,
  List<int> idxBox,
  void Function(String playerId, T order) addAccepted,
  String Function(T order) orderSummary,
  GameEventBus? eventBus,
  void Function(GameEvent)? onGameEvent,
) {
  for (final order in orders) {
    final r = idxBox[0] >= results.length
        ? OrderValidationResult.accepted()
        : results[idxBox[0]++];
    if (r.isAccepted) {
      addAccepted(playerId, order);
    } else if (r.reason != null) {
      final event = OrderRejectedEvent(
        playerId: playerId,
        orderSummary: orderSummary(order),
        reasonCode: r.reason!,
      );
      deliverGameEvent(event, eventBus: eventBus, onGameEvent: onGameEvent);
    }
  }
}

Orders _filterAcceptedOrdersForAllPlayers({
  required OrderEngine engine,
  required Game game,
  required MapTopology topology,
  GameEventBus? eventBus,
  void Function(GameEvent)? onGameEvent,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final original = engine.orders;
  final moveByPlayer = <String, List<MoveOrder>>{};
  final armyMoveByPlayer = <String, List<ArmyMoveOrder>>{};
  final buildByPlayer = <String, List<BuildUnitOrder>>{};
  final workByPlayer = <String, List<WorkOrder>>{};
  final diploByPlayer = <String, List<DiplomaticOrder>>{};

  final playerIds = <String>{
    ...original.moveOrdersByPlayerId.keys,
    ...original.armyMoveOrdersByPlayerId.keys,
    ...original.buildUnitOrdersByPlayerId.keys,
    ...original.workOrdersByPlayerId.keys,
    ...original.diplomaticOrdersByPlayerId.keys,
  };

  for (final playerId in playerIds) {
    final moves = original.moveOrdersByPlayerId[playerId] ?? const [];
    final armyMoves = original.armyMoveOrdersByPlayerId[playerId] ?? const [];
    final builds = original.buildUnitOrdersByPlayerId[playerId] ?? const [];
    final works = original.workOrdersByPlayerId[playerId] ?? const [];
    final diplo =
        original.diplomaticOrdersByPlayerId[playerId] ??
        const <DiplomaticOrder>[];

    if (moves.isEmpty &&
        armyMoves.isEmpty &&
        builds.isEmpty &&
        works.isEmpty &&
        diplo.isEmpty) {
      continue;
    }

    final results = engine.validatePlayerOrdersWithContext(
      game,
      topology,
      playerId,
      tileMapByRegion: tileMapByRegion,
    );
    final idxBox = [0];

    _filterOrderList<MoveOrder>(
      playerId,
      moves,
      results,
      idxBox,
      (pid, m) => moveByPlayer.putIfAbsent(pid, () => <MoveOrder>[]).add(m),
      (m) => 'Move order: ${m.unitId} -> ${m.destinationProvinceId}',
      eventBus,
      onGameEvent,
    );
    _filterOrderList<ArmyMoveOrder>(
      playerId,
      armyMoves,
      results,
      idxBox,
      (pid, m) =>
          armyMoveByPlayer.putIfAbsent(pid, () => <ArmyMoveOrder>[]).add(m),
      (m) => 'Army move: ${m.armyId} -> ${m.destinationProvinceId}',
      eventBus,
      onGameEvent,
    );
    _filterOrderList<BuildUnitOrder>(
      playerId,
      builds,
      results,
      idxBox,
      (pid, b) =>
          buildByPlayer.putIfAbsent(pid, () => <BuildUnitOrder>[]).add(b),
      (b) => 'Build unit: ${b.unitType}',
      eventBus,
      onGameEvent,
    );
    _filterOrderList<WorkOrder>(
      playerId,
      works,
      results,
      idxBox,
      (pid, w) => workByPlayer.putIfAbsent(pid, () => <WorkOrder>[]).add(w),
      (w) => 'Work order: ${w.target}',
      eventBus,
      onGameEvent,
    );

    if (diplo.isNotEmpty) {
      diploByPlayer[playerId] = List<DiplomaticOrder>.from(diplo);
    }
  }

  // Research orders are validated in the research phase; pass through from original.
  final researchByPlayer = Map<String, List<ResearchOrder>>.from(
    original.researchOrdersByPlayerId,
  );

  // Naval move orders pass through; validated when applied in movement phase.
  final navalByPlayer = Map<String, List<NavalMoveOrder>>.from(
    original.navalMoveOrdersByPlayerId,
  );

  final missionByPlayer = Map<String, List<NavalMissionOrder>>.from(
    original.navalMissionOrdersByPlayerId,
  );

  return Orders(
    moveOrdersByPlayerId: moveByPlayer,
    armyMoveOrdersByPlayerId: armyMoveByPlayer,
    buildUnitOrdersByPlayerId: buildByPlayer,
    workOrdersByPlayerId: workByPlayer,
    diplomaticOrdersByPlayerId: diploByPlayer,
    researchOrdersByPlayerId: researchByPlayer,
    navalMoveOrdersByPlayerId: navalByPlayer,
    navalMissionOrdersByPlayerId: missionByPlayer,
  );
}

Game _runExtractionPhase(
  Game state,
  MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId,
) {
  if (extractedByPlayerId.isNotEmpty) {
    return applyExtractionForPlayers(state, extractedByPlayerId);
  }
  if (tileMapByRegion == null || tileMapByRegion.isEmpty) {
    return state;
  }
  final connectivity = resolveConnectivity(
    game: state,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  final extraction = computeExtraction(
    game: state,
    tileMapByRegion: tileMapByRegion,
    connectivityResult: connectivity,
    techCapForPlayer: (playerId) {
      final player = state.playerById(playerId);
      return extractionCapForUnlocked(player?.techUnlocked);
    },
  );
  var currentState = state;
  final updatedPlayers = <Player>[];
  var extractionSeed =
      (state.globalGameSeed ?? 0) ^
      (state.worldState.turnState.turnNumber * 0x9E3779B1);
  for (final player in state.players) {
    var stockpile = player.stockpile;
    final tot = extraction[player.id];
    if (tot != null) {
      stockpile = applyExtractionToStockpile(stockpile, tot.land);
      var overseasDelivered = allocateOverseasToStockpile(
        tot.overseas,
        cargoHolds: cargoHoldsForHomeFleet(state, player.id),
      );
      if (overseasDelivered.isNotEmpty) {
        extractionSeed = (extractionSeed * 1103515245 + 12345) & 0x7fffffff;
        final interception = applyTradeInterception(
          currentState,
          player.id,
          overseasDelivered,
          seed: extractionSeed ^ player.id.hashCode,
        );
        overseasDelivered = interception.reducedDelivered;
        currentState = currentState.copyWith(
          worldState: currentState.worldState.copyWith(
            fleets: interception.updatedFleets,
          ),
        );
      }
      stockpile = applyExtractionToStockpile(stockpile, overseasDelivered);
    }
    updatedPlayers.add(player.copyWith(stockpile: stockpile));
  }
  return currentState.copyWith(players: updatedPlayers);
}

Game _runProductionPhase(
  Game game,
  List<AssignedRecipe> defaultAssignments,
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  Map<String, WorkerIdleCounts> idleLabourByPlayerId,
  void Function(Map<String, Map<String, int>> productionByRecipeByPlayerId)?
  onProductionComplete,
) {
  final updatedPlayers = <Player>[];
  final productionByRecipeByPlayerId = <String, Map<String, int>>{};

  for (final player in game.players) {
    final assignments =
        defaultAssignmentsByPlayerId?[player.id] ?? defaultAssignments;
    final idleLabour = idleLabourByPlayerId[player.id] ?? WorkerIdleCounts.zero;
    final result = resolveProduction(
      stockpile: player.stockpile,
      workers: player.workerPool,
      idleLabour: idleLabour,
      assignments: assignments,
    );
    if (result.productionByRecipe.isNotEmpty) {
      productionByRecipeByPlayerId[player.id] = Map<String, int>.from(
        result.productionByRecipe,
      );
    }
    updatedPlayers.add(
      player.copyWith(
        stockpile: result.stockpile,
        workerPool: result.workerPool,
      ),
    );
  }

  onProductionComplete?.call(productionByRecipeByPlayerId);
  return game.copyWith(players: updatedPlayers);
}

Game _runConsumptionPhase(
  Game game,
  Map<String, double> landFeedingCoverageByPlayerId,
  Map<String, double> navalFeedingCoverageByPlayerId,
  Map<String, WorkerIdleCounts> idleLabourByPlayerId,
) {
  final updatedPlayers = <Player>[];

  for (final player in game.players) {
    final regimentCounts = regimentTypeCountsForPlayer(
      game.worldState,
      player.id,
    );
    final shipCounts = shipTypeCountsForPlayer(game.worldState, player.id);

    final result = resolveConsumption(
      stockpile: player.stockpile,
      workers: player.workerPool,
      regimentCountsById: regimentCounts,
      shipCountsById: shipCounts,
    );

    double landCoverage;
    if (result.totalRegiments <= 0) {
      landCoverage = 1.0;
    } else {
      landCoverage = result.fullyFedRegiments / result.totalRegiments;
      if (landCoverage < 0) landCoverage = 0;
      if (landCoverage > 1) landCoverage = 1;
    }
    landFeedingCoverageByPlayerId[player.id] = landCoverage;

    double navalCoverage;
    if (result.totalShips <= 0) {
      navalCoverage = 1.0;
    } else {
      navalCoverage = result.fullyFedShips / result.totalShips;
      if (navalCoverage < 0) navalCoverage = 0;
      if (navalCoverage > 1) navalCoverage = 1;
    }
    navalFeedingCoverageByPlayerId[player.id] = navalCoverage;
    idleLabourByPlayerId[player.id] = result.idleLabour;
    updatedPlayers.add(
      player.copyWith(
        stockpile: result.stockpile,
        workerPool: result.workerPool,
      ),
    );
  }

  return game.copyWith(players: updatedPlayers);
}

Game _runRichesToTreasuryPhase(Game game) {
  final updatedPlayers = <Player>[];
  final multiplier = game.richesCashMultiplier;

  for (final player in game.players) {
    final result = resolveRichesToTreasury(
      stockpile: player.stockpile,
      richesCashMultiplier: multiplier,
    );
    updatedPlayers.add(
      player.copyWith(
        stockpile: result.stockpile,
        treasury: player.treasury + result.treasuryDelta,
      ),
    );
  }

  return game.copyWith(players: updatedPlayers);
}

/// Runs Extraction → Riches-to-treasury → Consumption → Production only, in
/// SPEC/program/turn-resolution-phases.md order.
///
/// Does not mutate [game]. Does not advance the turn or run other phases.
/// Used for UI stockpile previews (e.g. production panel). Player order and
/// extraction seeding match [_runExtractionPhase] so overseas interception
/// matches a full turn for the same starting state.
///
/// When [extractedByPlayerId] is non-empty, extraction uses
/// [applyExtractionForPlayers] only (same override path as full resolution).
Game applyEconomyPhasesForPreview({
  required Game game,
  required MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
}) {
  var state = game;
  final landFeedingCoverageByPlayerId = <String, double>{};
  final navalFeedingCoverageByPlayerId = <String, double>{};
  final idleLabourByPlayerId = <String, WorkerIdleCounts>{};
  state = _runExtractionPhase(
    state,
    topology,
    tileMapByRegion,
    extractedByPlayerId,
  );
  state = _runRichesToTreasuryPhase(state);
  state = _runConsumptionPhase(
    state,
    landFeedingCoverageByPlayerId,
    navalFeedingCoverageByPlayerId,
    idleLabourByPlayerId,
  );
  state = _runProductionPhase(
    state,
    defaultAssignments,
    defaultAssignmentsByPlayerId,
    idleLabourByPlayerId,
    null,
  );
  return state;
}

Game _runMovementPhase(Game game, MapTopology topology, Orders orders) {
  var state = game;

  final moveOrders = orders.moveOrdersByPlayerId;
  final tileKeysByRegion = state.worldState.tileKeysByRegionAndProvince;
  if (moveOrders.isNotEmpty) {
    // Province ownership lookup for Spy timers (other-faction only).
    final ownerByProvinceId = <String, String?>{
      for (final p in allProvinces(state.worldState)) p.id: p.ownerId,
    };
    // Movement within own provinces: no adjacency and no region restriction. SPEC/program/movement.md.
    bool isDestinationOwnedByPlayer(
      String playerId,
      String destFullProvinceId,
    ) =>
        tryGetProvince(state.worldState, destFullProvinceId)?.ownerId ==
        playerId;

    final originalOldWorld = state.worldState.oldWorld;
    final originalNewWorld = state.worldState.newWorld;

    // First apply cross-region moves within the player's own provinces (OldWorld ↔ NewWorld).
    final crossRegionResult = _applyCrossRegionOwnProvinceMoves(
      state,
      moveOrders,
      tileKeysByRegion,
    );

    // Then apply remaining land moves within each region using adjacency.
    final oldWorld = applyMoveOrdersToRegion(
      crossRegionResult.oldWorld,
      topology,
      crossRegionResult.remainingMoveOrdersByPlayerId,
      regionId: kRegionOldWorld,
      tileKeysByRegionAndProvince: tileKeysByRegion,
      isDestinationOwnedByPlayer: isDestinationOwnedByPlayer,
    );
    final newWorld = applyMoveOrdersToRegion(
      crossRegionResult.newWorld,
      topology,
      crossRegionResult.remainingMoveOrdersByPlayerId,
      regionId: kRegionNewWorld,
      tileKeysByRegionAndProvince: tileKeysByRegion,
      isDestinationOwnedByPlayer: isDestinationOwnedByPlayer,
    );
    // Spy leave province: set 5-turn reveal timer for (owner, left province). SPEC/program/fog-and-exploration-resolution.md.
    final spyTimers = Map<String, Map<String, int>>.from(
      state.worldState.spyRevealTurnsByPlayer.map(
        (k, v) => MapEntry(k, Map<String, int>.from(v)),
      ),
    );
    void recordSpyLeft(String ownerId, String provinceId) {
      // Only start timers for provinces owned by another faction; own provinces never decay.
      final provinceOwner = ownerByProvinceId[provinceId];
      if (provinceOwner == null || provinceOwner == ownerId) {
        return;
      }
      spyTimers.putIfAbsent(ownerId, () => {})[provinceId] = 5;
    }

    for (final u in originalOldWorld.units) {
      if (!isSpyUnit(u.type)) continue;
      final after = oldWorld.units.where((x) => x.id == u.id).firstOrNull;
      if (after != null && after.locationProvinceId != u.locationProvinceId) {
        recordSpyLeft(u.ownerId, u.locationProvinceId);
      }
    }
    for (final u in originalNewWorld.units) {
      if (!isSpyUnit(u.type)) continue;
      final after = newWorld.units.where((x) => x.id == u.id).firstOrNull;
      if (after != null && after.locationProvinceId != u.locationProvinceId) {
        recordSpyLeft(u.ownerId, u.locationProvinceId);
      }
    }
    state = state.copyWith(
      worldState: state.worldState.copyWith(
        oldWorld: oldWorld,
        newWorld: newWorld,
        spyRevealTurnsByPlayer: spyTimers,
      ),
    );
  }

  // Land army movement (after civilian moves). SPEC/game/military-armies.md.
  final armyMoveOrders = orders.armyMoveOrdersByPlayerId;
  if (armyMoveOrders.isNotEmpty) {
    bool isDestinationOwnedByPlayer(
      String playerId,
      String destFullProvinceId,
    ) =>
        tryGetProvince(state.worldState, destFullProvinceId)?.ownerId ==
        playerId;

    final cross = applyCrossRegionArmyMovesWithinOwnedProvinces(
      game: state,
      worldState: state.worldState,
      armyMoveOrdersByPlayerId: armyMoveOrders,
    );
    var ws = cross.worldState;
    final remaining = cross.remainingArmyMoveOrdersByPlayerId;
    ws = applyArmyMoveOrdersToRegion(
      ws,
      topology,
      remaining,
      regionId: kRegionOldWorld,
      isDestinationOwnedByPlayer: isDestinationOwnedByPlayer,
    );
    ws = applyArmyMoveOrdersToRegion(
      ws,
      topology,
      remaining,
      regionId: kRegionNewWorld,
      isDestinationOwnedByPlayer: isDestinationOwnedByPlayer,
    );
    state = state.copyWith(worldState: ws);
  }

  // Naval movement and ship reveal. SPEC/program/naval-movement-resolution.md.
  final navalOrders = orders.navalMoveOrdersByPlayerId;
  if (navalOrders.isNotEmpty) {
    state = applyNavalMovesAndShipReveal(state, topology, navalOrders);
  }

  // Naval mission assignment. Phase 6. Apply after moves so fleet position is final.
  // Fleets with a naval move this turn do not apply a naval mission order.
  final missionOrders = navalMissionOrdersRespectingNavalMoves(
    orders.navalMissionOrdersByPlayerId,
    orders.navalMoveOrdersByPlayerId,
  );
  // Always apply so we run the clearing pass for blockades when not at war.
  state = applyNavalMissionOrders(state, missionOrders);

  return state;
}

/// Apply cross-region land moves within a player's own provinces (OldWorld ↔ NewWorld).
/// These moves ignore adjacency and complete in a single Movement phase. SPEC/program/movement.md.
({
  RegionData oldWorld,
  RegionData newWorld,
  Map<String, List<MoveOrder>> remainingMoveOrdersByPlayerId,
})
_applyCrossRegionOwnProvinceMoves(
  Game game,
  Map<String, List<MoveOrder>> moveOrdersByPlayerId,
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince,
) {
  var oldUnits = List<Unit>.from(game.worldState.oldWorld.units);
  var newUnits = List<Unit>.from(game.worldState.newWorld.units);

  final unitRegionById = <String, String>{
    for (final u in oldUnits) u.id: kRegionOldWorld,
    for (final u in newUnits) u.id: kRegionNewWorld,
  };
  final unitsById = Map<String, Unit>.from(unitsByIdFromWorld(game.worldState));

  String? _firstTileFor(String regionId, String fullProvinceId) {
    final byProvince = tileKeysByRegionAndProvince[regionId];
    if (byProvince == null) return null;
    final tiles = byProvince[fullProvinceId];
    if (tiles == null || tiles.isEmpty) return null;
    return tiles.first;
  }

  final remaining = <String, List<MoveOrder>>{};

  moveOrdersByPlayerId.forEach((playerId, orders) {
    final remainingForPlayer = <MoveOrder>[];
    for (final o in orders) {
      final unit = unitsById[o.unitId];
      if (unit == null || unit.ownerId != playerId) {
        remainingForPlayer.add(o);
        continue;
      }
      final currentRegion = unitRegionById[unit.id];
      if (currentRegion == null) {
        remainingForPlayer.add(o);
        continue;
      }
      final destFullId = resolveToFullProvinceId(
        game.worldState,
        o.destinationProvinceId,
      );
      final destRegion = ProvinceId.regionIdFrom(destFullId);
      if (destRegion == currentRegion) {
        remainingForPlayer.add(o);
        continue;
      }
      final destProvince = tryGetProvince(game.worldState, destFullId);
      if (destProvince == null || destProvince.ownerId != playerId) {
        remainingForPlayer.add(o);
        continue;
      }

      // Cross-region own-province move: apply immediately.
      final isCivilian = unit.tileKey != null && unit.tileKey!.isNotEmpty;
      final firstTile = isCivilian
          ? _firstTileFor(destRegion, destFullId)
          : null;
      final movedUnit = isCivilian && firstTile != null
          ? unit.copyWith(locationProvinceId: destFullId, tileKey: firstTile)
          : unit.copyWith(locationProvinceId: destFullId);

      unitsById[unit.id] = movedUnit;
      unitRegionById[unit.id] = destRegion;

      if (currentRegion == kRegionOldWorld) {
        oldUnits = oldUnits.where((u) => u.id != unit.id).toList();
      } else if (currentRegion == kRegionNewWorld) {
        newUnits = newUnits.where((u) => u.id != unit.id).toList();
      }

      if (destRegion == kRegionOldWorld) {
        oldUnits = [...oldUnits, movedUnit];
      } else if (destRegion == kRegionNewWorld) {
        newUnits = [...newUnits, movedUnit];
      }
    }
    if (remainingForPlayer.isNotEmpty) {
      remaining[playerId] = remainingForPlayer;
    }
  });

  return (
    oldWorld: RegionData(
      provinces: game.worldState.oldWorld.provinces,
      units: oldUnits,
    ),
    newWorld: RegionData(
      provinces: game.worldState.newWorld.provinces,
      units: newUnits,
    ),
    remainingMoveOrdersByPlayerId: remaining,
  );
}

Game _runCombatPhase(
  Game game,
  Orders orders,
  Map<String, double> feedingCoverageByPlayerId,
  MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion, {
  Map<String, MapTopology>? topologyByRegion,
  void Function(DialogueEvent)? onDialogue,
  void Function(GameEvent)? onGameEvent,
}) {
  final previousCapitalByPlayer = {
    for (final p in game.players) p.id: p.capitalProvinceId,
  };
  Game state = game;
  final turn = state.worldState.turnState.turnNumber;
  final preBattleDialogueSeed =
      (game.globalGameSeed ?? 0) ^ (turn * 0x9E3779B1);
  _log.i('combat conflict_detection start turn=$turn');
  final battles = detectConflicts(state, orders);
  if (onDialogue != null && battles.isNotEmpty) {
    for (final ctx in battles) {
      final attackerIds = ctx.attackers.map((a) => a.factionId).toList()
        ..sort();
      final capitalThreatened = dialogueEventsForCapitalThreatened(
        state,
        capitalOwnerId: ctx.defenderFactionId,
        provinceId: ctx.provinceId,
        attackerFactionIds: attackerIds,
        turnNumber: turn,
        seed: preBattleDialogueSeed,
      );
      for (final e in capitalThreatened) {
        onDialogue(e);
      }
      for (final attackerId in attackerIds) {
        final reactive = dialogueEventsForReactiveHumanAttack(
          state,
          attackerFactionId: attackerId,
          defenderFactionId: ctx.defenderFactionId,
          provinceId: ctx.provinceId,
          turnNumber: turn,
          seed: preBattleDialogueSeed,
        );
        for (final e in reactive) {
          onDialogue(e);
        }
      }
    }
  }
  _log.i(
    'combat conflict_detection end turn=$turn battleContexts=${battles.length}',
  );
  final combatGeneralLedger = CombatPhaseGeneralLedger();
  final defaultMode = game.defaultCombatMode ?? CombatMode.autoResolve;
  var seed = (game.globalGameSeed ?? 0) ^ (turn * 0x9E3779B1);
  var battleIndex = 0;
  for (final ctx in battles) {
    final mode = resolveCombatModeForBattle(
      state,
      ctx,
      defaultMode: defaultMode,
      perBattleOverrides: game.combatModeByProvinceId.isNotEmpty
          ? game.combatModeByProvinceId
          : null,
    );
    state = runOneLandBattle(
      state,
      ctx,
      mode,
      feedingCoverageByPlayerId,
      turn,
      battleIndex,
      seed,
      combatGeneralLedger,
      onDialogue: onDialogue,
      onGameEvent: onGameEvent,
    );
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    battleIndex++;
  }
  // Capital reassignment: any player with capital set who no longer owns that province. SPEC/game/capital-and-connectivity § Capital loss and reassignment.
  state = applyCapitalReassignmentAfterCombat(
    state,
    topology,
    topologyByRegion: topologyByRegion,
    tileMapByRegion: tileMapByRegion,
  );
  // Great Power fall: any GP that lost its original capital and has no port provinces left forfeits.
  state = applyGreatPowerFall(state, previousCapitalByPlayer);
  return state;
}

Game _runMinorRegimentUpgradePhase(Game game) => applyMinorMilitaryParity(game);
