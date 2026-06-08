import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/event_bus/game_event_bus.dart';
import 'package:colonizethis_world/src/game_events.dart' show GameEvent;
import 'package:colonizethis_world/src/trace/turn_trace_contracts.dart';
import 'package:colonizethis_world/src/trace/turn_trace_runtime.dart';
import 'turn_pipeline_state.dart';
import 'turn_resolution_result.dart';

/// One turn-resolution phase: advance or exit the pipeline with a result.
typedef TurnPhaseHandler =
    TurnPhaseStepOutcome Function(
      TurnPipelineState pipeline,
      TurnResolverConfig config,
      int turn,
    );

enum TurnPhaseProgressMarker { start, end }

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
    this.ftpDecisions,
    this.interventionDecisions,
    this.callToArmsDecisions,
    this.phaseHandlerOverrides,
    this.onPhaseProgress,
    this.onTurnTracePhase,
    this.turnTraceRuntime = null,
  }) : assert(
          turnTraceRuntime == null || onTurnTracePhase != null,
          'turnTraceRuntime requires onTurnTracePhase so phase buffers flush',
        );

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
  final List<FtpDecision>? ftpDecisions;
  final List<InterventionDecision>? interventionDecisions;
  final List<CallToArmsDecision>? callToArmsDecisions;

  /// Optional handlers merged over the default phase registry (same [TurnPhase]
  /// key replaces the default). Used for tests and narrow customization; the
  /// default sequence and semantics remain authoritative. Refs #1958.
  final Map<TurnPhase, TurnPhaseHandler>? phaseHandlerOverrides;

  /// Optional callback invoked at each phase start/end during pipeline execution.
  final void Function(TurnPhase phase, TurnPhaseProgressMarker marker)?
  onPhaseProgress;

  /// Optional debug trace callback for per-phase snapshots captured during
  /// turn resolution. This hook is observational and must not mutate state.
  final void Function(TurnTracePhaseTrace phaseTrace)? onTurnTracePhase;

  /// When non-null with [onTurnTracePhase], collects order-level events (for
  /// example civilian move apply/ignore) for the active phase.
  final TurnTraceRuntime? turnTraceRuntime;
}
