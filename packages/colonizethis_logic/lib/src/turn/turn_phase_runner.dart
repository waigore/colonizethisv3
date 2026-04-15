import 'package:colonizethis_logic/package_logger.dart';
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
import 'phases.dart';

final _log = packageLogger();

/// Runs full turn phase sequence; may return early for pending diplomacy.
TurnResolutionResult runTurnResolutionPipeline({
  required Game gameAtResolutionStart,
  required TurnResolverConfig config,
}) {
  var acc = TurnPipelineState(game: gameAtResolutionStart);
  final turn = acc.game.worldState.turnState.turnNumber;
  final phaseIndex = config.startFromPhase != null
      ? turnResolutionSequence.indexOf(config.startFromPhase!)
      : 0;

  for (var i = 0; i < turnResolutionSequence.length; i++) {
    final phase = turnResolutionSequence[i];
    if (i < phaseIndex) continue;
    _log.i('phase ${phase.name} start');
    final outcome = _applyTurnPhase(phase, acc, config, turn);
    switch (outcome) {
      case TurnPhaseStepExit(:final result):
        return result;
      case TurnPhaseStepContinue(:final pipeline):
        acc = pipeline;
    }
    _log.i('phase ${phase.name} end');
  }

  _log.i('turn $turn resolve end');
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

TurnPhaseStepOutcome _applyTurnPhase(
  TurnPhase phase,
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  switch (phase) {
    case TurnPhase.orders:
      return TurnPhaseStepContinue(acc);
    case TurnPhase.extraction:
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
    case TurnPhase.richesToTreasury:
      return TurnPhaseStepContinue(
        acc.copyWith(game: runRichesToTreasuryPhase(acc.game)),
      );
    case TurnPhase.consumption:
      return TurnPhaseStepContinue(runConsumptionPipelinePhase(acc));
    case TurnPhase.production:
      return TurnPhaseStepContinue(
        runProductionPipelinePhase(
          acc,
          config.defaultAssignments,
          config.defaultAssignmentsByPlayerId,
          config.onProductionComplete,
        ),
      );
    case TurnPhase.research:
      {
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
    case TurnPhase.diplomacy:
      {
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
    case TurnPhase.movement:
      return TurnPhaseStepContinue(
        acc.copyWith(
          game: runMovementPhase(acc.game, config.topology, config.orders),
        ),
      );
    case TurnPhase.minorRegimentUpgrade:
      return TurnPhaseStepContinue(
        acc.copyWith(game: runMinorRegimentUpgradePhase(acc.game)),
      );
    case TurnPhase.navalInterceptionCombat:
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
    case TurnPhase.combat:
      {
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
    case TurnPhase.buildWork:
      {
        final stateBeforeBuildWork = acc.game;
        final afterBuildWork = runBuildWorkPhase(
          acc.game,
          config.orders,
          config.topology,
          config.tileMapByRegion,
          onDialogue: config.onDialogue,
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
    case TurnPhase.endOfTurn:
      {
        final after = runEndOfTurnPhase(
          acc.game,
          topology: config.topology,
          topologyByRegion: config.topologyByRegion,
          onDialogue: config.onDialogue,
        );
        emitVictorySetEvent(after, turn, config.eventBus, config.onGameEvent);
        return TurnPhaseStepContinue(acc.copyWith(game: after));
      }
  }
}
