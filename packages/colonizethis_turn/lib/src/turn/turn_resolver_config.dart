import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'turn_event_sink.dart';
import 'turn_pipeline_state.dart';
import 'turn_resolution_result.dart';

export 'turn_event_sink.dart';

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
    this.eventSink = const TurnEventSink(),
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

  /// Bundles the event transport ([GameEventBus], `onGameEvent`, `onDialogue`)
  /// behind a single [TurnEventSink], replacing the positional
  /// `(eventBus, onGameEvent, onDialogue)` trio that was previously threaded
  /// through this config and every public resolver entry point. Defaults to a
  /// no-op sink (no bus, no callbacks). Refs #3701.
  final TurnEventSink eventSink;
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

  /// Returns a copy with the given overrides applied. A `null` argument leaves
  /// the existing value unchanged.
  ///
  /// Used by the Diplomacy-phase resume entry points so each resume wrapper can
  /// forward a single [TurnResolverConfig] and only override [startFromPhase]
  /// and the one decision list it carries, instead of re-threading every
  /// resolver parameter individually (Refs #3416,
  /// `SPEC/program/turn-resume-config-dispatch.md`).
  TurnResolverConfig copyWith({
    MapTopology? topology,
    Orders? orders,
    Map<String, TileMapResult>? tileMapByRegion,
    Map<String, MapTopology>? topologyByRegion,
    Map<String, Map<CommodityId, int>>? extractedByPlayerId,
    List<AssignedRecipe>? defaultAssignments,
    Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
    TurnEventSink? eventSink,
    void Function(Map<String, Map<String, int>> productionByRecipeByPlayerId)?
    onProductionComplete,
    TurnPhase? startFromPhase,
    List<OvertureDecision>? overtureDecisions,
    List<FtpDecision>? ftpDecisions,
    List<InterventionDecision>? interventionDecisions,
    List<CallToArmsDecision>? callToArmsDecisions,
    Map<TurnPhase, TurnPhaseHandler>? phaseHandlerOverrides,
    void Function(TurnPhase phase, TurnPhaseProgressMarker marker)?
    onPhaseProgress,
    void Function(TurnTracePhaseTrace phaseTrace)? onTurnTracePhase,
    TurnTraceRuntime? turnTraceRuntime,
  }) {
    return TurnResolverConfig(
      topology: topology ?? this.topology,
      orders: orders ?? this.orders,
      tileMapByRegion: tileMapByRegion ?? this.tileMapByRegion,
      topologyByRegion: topologyByRegion ?? this.topologyByRegion,
      extractedByPlayerId: extractedByPlayerId ?? this.extractedByPlayerId,
      defaultAssignments: defaultAssignments ?? this.defaultAssignments,
      defaultAssignmentsByPlayerId:
          defaultAssignmentsByPlayerId ?? this.defaultAssignmentsByPlayerId,
      eventSink: eventSink ?? this.eventSink,
      onProductionComplete: onProductionComplete ?? this.onProductionComplete,
      startFromPhase: startFromPhase ?? this.startFromPhase,
      overtureDecisions: overtureDecisions ?? this.overtureDecisions,
      ftpDecisions: ftpDecisions ?? this.ftpDecisions,
      interventionDecisions:
          interventionDecisions ?? this.interventionDecisions,
      callToArmsDecisions: callToArmsDecisions ?? this.callToArmsDecisions,
      phaseHandlerOverrides:
          phaseHandlerOverrides ?? this.phaseHandlerOverrides,
      onPhaseProgress: onPhaseProgress ?? this.onPhaseProgress,
      onTurnTracePhase: onTurnTracePhase ?? this.onTurnTracePhase,
      turnTraceRuntime: turnTraceRuntime ?? this.turnTraceRuntime,
    );
  }
}
