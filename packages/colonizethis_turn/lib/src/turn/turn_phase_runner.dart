import 'turn_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_turn_summary_events.dart';
import 'last_turn_intelligence_digest.dart';
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
  final collectedEvents = <GameEvent>[];
  final runConfig = config.copyWith(
    eventSink: _CollectingTurnEventSink(config.eventSink, collectedEvents),
  );
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
      runConfig.eventSink,
      beforeIndex: haltedIndex,
      afterIndex: haltedIndex,
    );
    emitEconomyTurnSummaryEvents(
      start: gameAtResolutionStart,
      end: gameAtResolutionStart,
      turn: turn,
      sink: runConfig.eventSink,
    );
    final news = buildTurnNewsDigestForComplete(
      start: gameAtResolutionStart,
      end: gameAtResolutionStart,
      startIndex: haltedIndex,
      endIndex: haltedIndex,
    );
    return _completeWithIntel(
      start: gameAtResolutionStart,
      news: news,
      turnEvents: collectedEvents,
    );
  }
  var acc = TurnPipelineState(game: gameAtResolutionStart);
  final turn = acc.game.worldState.turnState.turnNumber;
  final phaseIndex = runConfig.startFromPhase != null
      ? turnResolutionSequence.indexOf(runConfig.startFromPhase!)
      : 0;
  final defaults = TurnPhaseHandlerRegistry.defaults;
  final handlers = runConfig.phaseHandlerOverrides == null
      ? defaults
      : <TurnPhase, TurnPhaseHandler>{
          ...defaults,
          ...runConfig.phaseHandlerOverrides!,
        };

  for (var i = 0; i < turnResolutionSequence.length; i++) {
    final phase = turnResolutionSequence[i];
    if (i < phaseIndex) continue;
    runConfig.turnTraceRuntime?.clearPhaseOrderEvents();
    runConfig.onPhaseProgress?.call(phase, TurnPhaseProgressMarker.start);
    turnLog.i('phase ${phase.name} start');
    final beforeState = runConfig.onTurnTracePhase == null
        ? null
        : acc.game.toJson();
    final handler = handlers[phase];
    if (handler == null) {
      throw StateError('No turn phase handler registered for ${phase.name}');
    }
    final outcome = handler(acc, runConfig, turn);
    switch (outcome) {
      case TurnPhaseStepExit(:final result):
        _emitPhaseTrace(
          config: runConfig,
          phase: phase,
          beforeState: beforeState,
          afterState: _phaseExitStateSnapshot(runConfig, result),
        );
        return result;
      case TurnPhaseStepContinue(:final pipeline):
        _emitPhaseTrace(
          config: runConfig,
          phase: phase,
          beforeState: beforeState,
          afterState: runConfig.onTurnTracePhase == null
              ? null
              : pipeline.game.toJson(),
        );
        acc = pipeline;
    }
    turnLog.i('phase ${phase.name} end');
    runConfig.onPhaseProgress?.call(phase, TurnPhaseProgressMarker.end);
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
    runConfig.eventSink,
    beforeIndex: beforeIndex,
    afterIndex: afterIndex,
  );
  emitEconomyTurnSummaryEvents(
    start: gameAtResolutionStart,
    end: acc.game,
    turn: turn,
    sink: runConfig.eventSink,
  );
  final news = buildTurnNewsDigestForComplete(
    start: gameAtResolutionStart,
    end: acc.game,
    startIndex: beforeIndex,
    endIndex: afterIndex,
  );
  return _completeWithIntel(
    start: gameAtResolutionStart,
    news: news,
    turnEvents: collectedEvents,
  );
}

TurnResolutionComplete _completeWithIntel({
  required Game start,
  required ({TurnNewsDigest? digest, Game game}) news,
  required List<GameEvent> turnEvents,
}) {
  final game = persistLastTurnIntelligenceDigest(
    start: start,
    end: news.game,
    worldNews: news.digest,
    turnEvents: turnEvents,
  );
  return TurnResolutionComplete(game, turnNewsDigest: news.digest);
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

/// Collects [emit] payloads without forcing [TurnEventSink.hasGameEvent].
class _CollectingTurnEventSink extends TurnEventSink {
  _CollectingTurnEventSink(this._inner, this.collected)
    : super(
        eventBus: _inner.eventBus,
        onGameEvent: _inner.onGameEvent,
        onDialogue: _inner.onDialogue,
      );

  final TurnEventSink _inner;
  final List<GameEvent> collected;

  @override
  void emit(GameEvent event) {
    collected.add(event);
    _inner.emit(event);
  }
}
