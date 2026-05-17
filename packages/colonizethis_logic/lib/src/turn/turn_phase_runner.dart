import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../diplomacy/diplomacy_resolver.dart';
import 'end_of_turn_resolver.dart';
import 'research_resolver.dart';
import 'turn_news_digest.dart';
import 'turn_pipeline_state.dart';
import 'turn_resolution_events.dart';
import 'turn_resolution_result.dart';
import 'turn_resolution_sequence.dart';
import 'turn_resolver_config.dart';
import 'trace/turn_trace_contracts.dart';
import 'phases.dart';

/// Runs full turn phase sequence; may return early for pending diplomacy.
TurnResolutionResult runTurnResolutionPipeline({
  required Game gameAtResolutionStart,
  required TurnResolverConfig config,
}) {
  if (gameAtResolutionStart.calendarCampaignHalted) {
    final turn = gameAtResolutionStart.worldState.turnState.turnNumber;
    logicLog.i('turn $turn resolve skipped (calendar halted)');
    emitPlayerDiscoveryEvents(
      gameAtResolutionStart,
      gameAtResolutionStart,
      turn,
      config.eventBus,
      config.onGameEvent,
    );
    final news = buildTurnNewsDigestForComplete(
      start: gameAtResolutionStart,
      end: gameAtResolutionStart,
    );
    return TurnResolutionComplete(
      news.game,
      turnNewsDigest: news.digest,
    );
  }
  var acc = TurnPipelineState(game: gameAtResolutionStart);
  final turn = acc.game.worldState.turnState.turnNumber;
  final phaseIndex = config.startFromPhase != null
      ? turnResolutionSequence.indexOf(config.startFromPhase!)
      : 0;
  final defaults = _defaultTurnPhaseHandlers();
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
    logicLog.i('phase ${phase.name} start');
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
    logicLog.i('phase ${phase.name} end');
    config.onPhaseProgress?.call(phase, TurnPhaseProgressMarker.end);
  }

  logicLog.i('turn $turn resolve end');
  emitPlayerDiscoveryEvents(
    gameAtResolutionStart,
    acc.game,
    turn,
    config.eventBus,
    config.onGameEvent,
  );
  final news = buildTurnNewsDigestForComplete(
    start: gameAtResolutionStart,
    end: acc.game,
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

Map<TurnPhase, TurnPhaseHandler> _defaultTurnPhaseHandlers() {
  return <TurnPhase, TurnPhaseHandler>{
    TurnPhase.orders: _runOrdersPhase,
    TurnPhase.extraction: _runExtractionPhaseHandler,
    TurnPhase.richesToTreasury: _runRichesToTreasuryPhaseHandler,
    TurnPhase.consumption: _runConsumptionPhaseHandler,
    TurnPhase.production: _runProductionPhaseHandler,
    TurnPhase.research: _runResearchPhaseHandler,
    TurnPhase.diplomacy: _runDiplomacyPhaseHandler,
    TurnPhase.movement: _runMovementPhaseHandler,
    TurnPhase.minorRegimentUpgrade: _runMinorRegimentUpgradePhaseHandler,
    TurnPhase.navalInterceptionCombat: _runNavalInterceptionCombatPhaseHandler,
    TurnPhase.combat: _runCombatPhaseHandler,
    TurnPhase.buildWork: _runBuildWorkPhaseHandler,
    TurnPhase.endOfTurn: _runEndOfTurnPhaseHandler,
  };
}

TurnPhaseStepOutcome _runOrdersPhase(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) => TurnPhaseStepContinue(acc);

TurnPhaseStepOutcome _runExtractionPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  return TurnPhaseStepContinue(
    acc.copyWith(
      game: runExtractionPhase(
        acc.game,
        config.topology,
        config.tileMapByRegion,
        config.extractedByPlayerId,
      ),
    ),
  );
}

TurnPhaseStepOutcome _runRichesToTreasuryPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) => TurnPhaseStepContinue(
  acc.copyWith(game: runRichesToTreasuryPhase(acc.game)),
);

TurnPhaseStepOutcome _runConsumptionPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) => TurnPhaseStepContinue(runConsumptionPipelinePhase(acc));

TurnPhaseStepOutcome _runProductionPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  return TurnPhaseStepContinue(
    runProductionPipelinePhase(
      acc,
      config.defaultAssignments,
      config.defaultAssignmentsByPlayerId,
      config.onProductionComplete,
    ),
  );
}

TurnPhaseStepOutcome _runResearchPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  final stateBeforeResearch = acc.game;
  final afterResearch = resolveResearchPhase(acc.game, config.orders);
  emitResearchCompleteEvents(
    stateBeforeResearch,
    afterResearch,
    turn,
    config.eventBus,
    config.onGameEvent,
    config.onDialogue,
  );
  return TurnPhaseStepContinue(acc.copyWith(game: afterResearch));
}

TurnPhaseStepOutcome _runDiplomacyPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  final stateBeforeDiplomacy = acc.game;
  final previousRelations = <String, Map<String, RelationState>>{};
  for (final rel in acc.game.diplomacyRelations) {
    previousRelations.putIfAbsent(rel.factionId1, () => {});
    previousRelations.putIfAbsent(rel.factionId2, () => {});
    previousRelations[rel.factionId1]![rel.factionId2] = rel.state;
    previousRelations[rel.factionId2]![rel.factionId1] = rel.state;
  }
  final diploResult = resolveDiplomacyPhase(
    acc.game,
    config.orders,
    onDialogue: config.onDialogue,
    overtureDecisions: config.overtureDecisions,
    interventionDecisions: config.interventionDecisions,
    callToArmsDecisions: config.callToArmsDecisions,
  );
  if (diploResult.isPending) {
    final po = diploResult.pendingOvertures;
    if (po != null && po.isNotEmpty) {
      return TurnPhaseStepExit(
        TurnResolutionPendingOvertures(
          game: diploResult.game,
          pendingOvertures: po,
        ),
      );
    }
    final pi = diploResult.pendingInterventions;
    if (pi != null && pi.isNotEmpty) {
      return TurnPhaseStepExit(
        TurnResolutionPendingIntervention(
          game: diploResult.game,
          pendingInterventions: pi,
        ),
      );
    }
    final cta = diploResult.pendingCallToArms;
    if (cta != null && cta.isNotEmpty) {
      return TurnPhaseStepExit(
        TurnResolutionPendingCallToArms(
          game: diploResult.game,
          pendingCallToArms: cta,
        ),
      );
    }
    throw StateError('diplomacy pending but no pending lists populated');
  }
  emitDiplomacyChangeEvents(
    previousRelations,
    diploResult.game,
    turn,
    config.eventBus,
    config.onGameEvent,
  );
  emitOvertureAdvancedEvents(
    stateBeforeDiplomacy,
    diploResult.game,
    turn,
    config.eventBus,
    config.onGameEvent,
  );
  return TurnPhaseStepContinue(acc.copyWith(game: diploResult.game));
}

TurnPhaseStepOutcome _runMovementPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  return TurnPhaseStepContinue(
    acc.copyWith(
      game: runMovementPhase(
        acc.game,
        config.topology,
        config.orders,
        onCivilianMoveOrderTrace:
            config.turnTraceRuntime?.handleCivilianMoveOrderTrace,
        onBundledWorkMoveTrace:
            config.turnTraceRuntime?.handleBundledWorkMoveTrace,
        onArmyMoveOrderTrace: config.turnTraceRuntime?.handleArmyMoveOrderTrace,
      ),
    ),
  );
}

TurnPhaseStepOutcome _runMinorRegimentUpgradePhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) => TurnPhaseStepContinue(
  acc.copyWith(game: runMinorRegimentUpgradePhase(acc.game)),
);

TurnPhaseStepOutcome _runNavalInterceptionCombatPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  return TurnPhaseStepContinue(
    runNavalInterceptionTurnPhase(
      acc,
      config.topology,
      config.orders.navalMoveOrdersByPlayerId,
      config.eventBus,
      config.onDialogue,
      config.onGameEvent,
    ),
  );
}

TurnPhaseStepOutcome _runCombatPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  final previousOwnership = <String, String?>{};
  for (final region in [
    acc.game.worldState.oldWorld,
    acc.game.worldState.newWorld,
  ]) {
    for (final prov in region.provinces) {
      previousOwnership[prov.id] = prov.ownerId;
    }
  }
  final afterCombat = runCombatPhase(
    acc.game,
    config.orders,
    acc.landFeedingCoverageByPlayerId,
    config.topology,
    config.tileMapByRegion,
    topologyByRegion: config.topologyByRegion,
    onDialogue: config.onDialogue,
    onGameEvent: config.onGameEvent,
  );
  emitProvinceCapturedEvents(
    previousOwnership,
    afterCombat,
    turn,
    config.eventBus,
    config.onGameEvent,
    config.onDialogue,
  );
  return TurnPhaseStepContinue(acc.copyWith(game: afterCombat));
}

TurnPhaseStepOutcome _runBuildWorkPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  final stateBeforeBuildWork = acc.game;
  final afterBuildWork = runBuildWorkPhase(
    acc.game,
    config.orders,
    config.topology,
    config.tileMapByRegion,
    onDialogue: config.onDialogue,
    onWorkOrderTrace: config.turnTraceRuntime?.handleWorkOrderTrace,
  );
  emitWorkOrderCompletedEvents(
    stateBeforeBuildWork,
    afterBuildWork,
    turn,
    config.eventBus,
    config.onGameEvent,
  );
  return TurnPhaseStepContinue(acc.copyWith(game: afterBuildWork));
}

TurnPhaseStepOutcome _runEndOfTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  final after = runEndOfTurnPhase(
    acc.game,
    topology: config.topology,
    topologyByRegion: config.topologyByRegion,
    onDialogue: config.onDialogue,
  );
  emitVictorySetEvent(after, turn, config.eventBus, config.onGameEvent);
  return TurnPhaseStepContinue(acc.copyWith(game: after));
}
