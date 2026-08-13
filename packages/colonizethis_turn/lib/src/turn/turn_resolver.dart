import 'package:colonizethis_data/colonizethis_data.dart';
import 'turn_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
export 'economy_preview_pipeline.dart'
    show
        EconomyPreviewInputs,
        applyEconomyPhasesForPreview,
        applyEconomyPhasesThroughRichesForPreview,
        economyPreviewInputs,
        economyPreviewStockpilePhaseDeltasForPlayer,
        emptyEconomyPreviewInputs,
        forcesFeedingForPlayer,
        labourReadinessForPlayer,
        previewStockpileNetDeltaByCommodityForPlayer,
        previewStockpilePhaseDeltasByCommodityForPlayer;
export 'package:colonizethis_economy/colonizethis_economy.dart'
    show previewTownManufacturingBonusByProvince;
import 'turn_phase_runner.dart';
import 'turn_resolution_result.dart';
export 'turn_resolution_sequence.dart';
import 'turn_resolver_config.dart';
export 'turn_resolver_config.dart';
export 'turn_resolver_order_entry.dart';
export 'turn_resolver_resume.dart';
export 'turn_resolver_world_state_stub.dart';

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
  TurnEventSink? eventSink,
  void Function(Map<String, Map<String, int>> productionByRecipeByPlayerId)?
  onProductionComplete,
  TurnPhase? startFromPhase,
  List<OvertureDecision>? overtureDecisions,
  List<FtpDecision>? ftpDecisions,
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
      eventSink: eventSink ?? const TurnEventSink(),
      onProductionComplete: onProductionComplete,
      startFromPhase: startFromPhase,
      overtureDecisions: overtureDecisions,
      ftpDecisions: ftpDecisions,
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
  turnLog.i('turn $turn resolve start');
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
    TurnResolutionPendingFtp() =>
      'Turn resolution is pending FTP decisions; use resumeTurnResolutionWithFtpDecisions',
    TurnResolutionPendingIntervention() =>
      'Turn resolution is pending intervention decisions; use resumeTurnResolutionWithInterventionDecisions',
    TurnResolutionPendingCallToArms() =>
      'Turn resolution is pending call to arms; use resumeTurnResolutionWithCallToArmsDecisions',
  };
}
