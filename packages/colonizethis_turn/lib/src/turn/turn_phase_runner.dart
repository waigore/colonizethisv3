import 'turn_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'turn_news_digest.dart';
import 'turn_phase_handler_registry.dart';
import 'turn_pipeline_state.dart';
import 'turn_resolution_events.dart';
import 'turn_resolution_result.dart';
import 'turn_resolution_sequence.dart';
import 'turn_resolver_config.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Runs full turn phase sequence; may return early for pending diplomacy.
TurnResolutionResult runTurnResolutionPipeline({
  required Game gameAtResolutionStart,
  required TurnResolverConfig config,
}) {
  if (gameAtResolutionStart.calendarCampaignHalted) {
    final turn = gameAtResolutionStart.worldState.turnState.turnNumber;
    turnLog.i('turn $turn resolve skipped (calendar halted)');
    // Halted: start and end are the same state, so a single visibility index
    // serves both discovery events and the news digest (4 builds -> 1).
    final haltedIndex = buildProvinceVisibilityIndex(gameAtResolutionStart);
    emitPlayerDiscoveryEvents(
      gameAtResolutionStart,
      gameAtResolutionStart,
      turn,
      config.eventSink,
      beforeIndex: haltedIndex,
      afterIndex: haltedIndex,
    );
    final news = buildTurnNewsDigestForComplete(
      start: gameAtResolutionStart,
      end: gameAtResolutionStart,
      startIndex: haltedIndex,
      endIndex: haltedIndex,
    );
    return TurnResolutionComplete(news.game, turnNewsDigest: news.digest);
  }
  var acc = TurnPipelineState(game: gameAtResolutionStart);
  final turn = acc.game.worldState.turnState.turnNumber;
  final phaseIndex = config.startFromPhase != null
      ? turnResolutionSequence.indexOf(config.startFromPhase!)
      : 0;
  final defaults = TurnPhaseHandlerRegistry.defaults;
  final handlers = config.phaseHandlerOverrides == null
      ? defaults
      : <TurnPhase, TurnPhaseHandler>{
          ...defaults,
          ...config.phaseHandlerOverrides!,
        };

  for (var i = 0; i < turnResolutionSequence.length; i++) {
    final phase = turnResolutionSequence[i];
    if (i < phaseIndex) continue;
    config.turnTraceRuntime?.clearPhaseOrderEvents();
    config.onPhaseProgress?.call(phase, TurnPhaseProgressMarker.start);
    turnLog.i('phase ${phase.name} start');
    final beforeState = config.onTurnTracePhase == null
        ? null
        : acc.game.toJson();
    final handler = handlers[phase];
    if (handler == null) {
      throw StateError('No turn phase handler registered for ${phase.name}');
    }
    final outcome = handler(acc, config, turn);
    switch (outcome) {
      case TurnPhaseStepExit(:final result):
        _emitPhaseTrace(
          config: config,
          phase: phase,
          beforeState: beforeState,
          afterState: _phaseExitStateSnapshot(config, result),
        );
        return result;
      case TurnPhaseStepContinue(:final pipeline):
        _emitPhaseTrace(
          config: config,
          phase: phase,
          beforeState: beforeState,
          afterState: config.onTurnTracePhase == null
              ? null
              : pipeline.game.toJson(),
        );
        acc = pipeline;
    }
    turnLog.i('phase ${phase.name} end');
    config.onPhaseProgress?.call(phase, TurnPhaseProgressMarker.end);
  }

  turnLog.i('turn $turn resolve end');
  // Build each per-state visibility index once and reuse it across discovery
  // events and the news digest instead of recomputing both (4 builds -> 2).
  final beforeIndex = buildProvinceVisibilityIndex(gameAtResolutionStart);
  final afterIndex = buildProvinceVisibilityIndex(acc.game);
  emitPlayerDiscoveryEvents(
    gameAtResolutionStart,
    acc.game,
    turn,
    config.eventSink,
    beforeIndex: beforeIndex,
    afterIndex: afterIndex,
  );
  final news = buildTurnNewsDigestForComplete(
    start: gameAtResolutionStart,
    end: acc.game,
    startIndex: beforeIndex,
    endIndex: afterIndex,
  );
  return TurnResolutionComplete(news.game, turnNewsDigest: news.digest);
}

void _emitPhaseTrace({
  required TurnResolverConfig config,
  required TurnPhase phase,
  required Map<String, Object?>? beforeState,
  required Map<String, Object?>? afterState,
}) {
  final onTurnTracePhase = config.onTurnTracePhase;
  if (onTurnTracePhase == null) {
    return;
  }
  final orderEvents =
      config.turnTraceRuntime?.snapshotPhaseOrderEvents() ??
      const <TurnTraceOrderEvent>[];
  onTurnTracePhase(
    TurnTracePhaseTrace(
      phaseId: phase.name,
      beforeState: beforeState ?? const <String, Object?>{},
      afterState: afterState ?? const <String, Object?>{},
      orderEvents: orderEvents,
    ),
  );
}

Map<String, Object?>? _phaseExitStateSnapshot(
  TurnResolverConfig config,
  TurnResolutionResult result,
) {
  if (config.onTurnTracePhase == null) {
    return null;
  }
  return gameFromTurnResolutionResult(result).toJson();
}
