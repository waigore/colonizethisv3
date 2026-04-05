import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../economy/economy_production.dart';
import '../event_bus/game_event_bus.dart';
import '../game_events.dart' show GameEvent;
import 'turn_resolution_result.dart';

/// Bundles inputs for [resolveTurnForGameWithConfig] / full turn resolution.
class TurnResolverConfig {
  const TurnResolverConfig({
    required this.topology,
    required this.orders,
    this.tileMapByRegion,
    this.topologyByRegion,
    this.extractedByPlayerId = const {},
    this.defaultAssignments = const [],
    this.defaultAssignmentsByPlayerId,
    this.eventBus,
    this.onDialogue,
    this.onGameEvent,
    this.onProductionComplete,
    this.startFromPhase,
    this.overtureDecisions,
    this.interventionDecisions,
    this.callToArmsDecisions,
  });

  final MapTopology topology;
  final Orders orders;
  final Map<String, TileMapResult>? tileMapByRegion;
  final Map<String, MapTopology>? topologyByRegion;
  final Map<String, Map<CommodityId, int>> extractedByPlayerId;
  final List<AssignedRecipe> defaultAssignments;
  final Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId;
  final GameEventBus? eventBus;
  final void Function(DialogueEvent)? onDialogue;
  final void Function(GameEvent)? onGameEvent;
  final void Function(
    Map<String, Map<String, int>> productionByRecipeByPlayerId,
  )?
  onProductionComplete;
  final TurnPhase? startFromPhase;
  final List<OvertureDecision>? overtureDecisions;
  final List<InterventionDecision>? interventionDecisions;
  final List<CallToArmsDecision>? callToArmsDecisions;
}
