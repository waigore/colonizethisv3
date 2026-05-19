import 'package:colonizethis_models/colonizethis_models.dart';

import '../diplomacy/diplomacy_resolver.dart';
import 'end_of_turn_resolver.dart';
import 'phases.dart';
import 'research_resolver.dart';
import 'turn_pipeline_state.dart';
import 'turn_resolution_events.dart';
import 'turn_resolution_result.dart';
import 'turn_resolution_sequence.dart';
import 'turn_resolver_config.dart';

/// Canonical turn-phase handler registry. SPEC/program/turn-resolution-phase-details.md § Phase handler registry.
final class TurnPhaseHandlerRegistry {
  TurnPhaseHandlerRegistry._();

  static Map<TurnPhase, TurnPhaseHandler> get defaults =>
      Map<TurnPhase, TurnPhaseHandler>.unmodifiable(_handlers);

  static TurnPhaseHandler? handlerFor(TurnPhase phase) => _handlers[phase];

  static const Map<TurnPhase, TurnPhaseHandler> _handlers =
      <TurnPhase, TurnPhaseHandler>{
        TurnPhase.orders: ordersTurnPhaseHandler,
        TurnPhase.extraction: extractionTurnPhaseHandler,
        TurnPhase.richesToTreasury: richesToTreasuryTurnPhaseHandler,
        TurnPhase.consumption: consumptionTurnPhaseHandler,
        TurnPhase.production: productionTurnPhaseHandler,
        TurnPhase.diplomacy: diplomacyTurnPhaseHandler,
        TurnPhase.research: researchTurnPhaseHandler,
        TurnPhase.movement: movementTurnPhaseHandler,
        TurnPhase.minorRegimentUpgrade: minorRegimentUpgradeTurnPhaseHandler,
        TurnPhase.navalInterceptionCombat: navalInterceptionCombatTurnPhaseHandler,
        TurnPhase.combat: combatTurnPhaseHandler,
        TurnPhase.buildWork: buildWorkTurnPhaseHandler,
        TurnPhase.endOfTurn: endOfTurnTurnPhaseHandler,
      };
}

/// Validates that [defaults] covers every phase in [turnResolutionSequence].
void assertTurnPhaseHandlerRegistryComplete() {
  for (final phase in turnResolutionSequence) {
    if (TurnPhaseHandlerRegistry.handlerFor(phase) == null) {
      throw StateError(
        'TurnPhaseHandlerRegistry missing handler for ${phase.name}',
      );
    }
  }
}

TurnPhaseStepOutcome ordersTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) => TurnPhaseStepContinue(acc);

TurnPhaseStepOutcome researchTurnPhaseHandler(
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

TurnPhaseStepOutcome diplomacyTurnPhaseHandler(
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

TurnPhaseStepOutcome combatTurnPhaseHandler(
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

TurnPhaseStepOutcome buildWorkTurnPhaseHandler(
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

TurnPhaseStepOutcome endOfTurnTurnPhaseHandler(
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
