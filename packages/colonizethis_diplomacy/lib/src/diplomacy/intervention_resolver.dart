import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'diplomacy_event_logging.dart';
import 'diplomacy_phase_result.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_shared_helpers.dart';
import 'intervention_resolver_apply.dart';
import 'intervention_resolver_eligibility.dart';

export 'intervention_resolver_apply.dart';
export 'intervention_resolver_call_to_arms.dart';
export 'intervention_resolver_eligibility.dart';

class InterventionResolutionResult {
  InterventionResolutionResult(this.game, {this.pendingInterventions});

  final Game game;
  final List<InterventionPrompt>? pendingInterventions;
}

Game _applyInterventionChoiceAndRecord(
  Game game, {
  required String aggressorGpId,
  required String defenderMinorOrTribeId,
  required String interveningGpId,
  required InterventionChoice choice,
  required int turn,
  required DiplomacyFactionMembership factionMembership,
  required Set<String> recordedChoiceKeys,
  IntraTurnEventTally? eventTally,
}) {
  final next = applyInterventionAgainstAggressor(
    game,
    aggressorGpId: aggressorGpId,
    defenderMinorOrTribeId: defenderMinorOrTribeId,
    interveningGpId: interveningGpId,
    choice: choice,
    factionMembership: factionMembership,
    eventTally: eventTally,
  );
  recordedChoiceKeys.add(
    interventionChoiceKey(turn, interveningGpId, aggressorGpId),
  );
  return next;
}

InterventionResolutionResult processInterventionsForAggressorDefender(
  Game game, {
  required String aggressorGpId,
  required String defenderMinorOrTribeId,
  required int turn,
  required DiplomacyFactionMembership factionMembership,
  required Set<String> recordedChoiceKeys,
  List<InterventionDecision>? interventionDecisions,
  IntraTurnEventTally? eventTally,
}) {
  final eligible = <String>[];
  for (final p in game.players) {
    if (!factionMembership.isGreatPower(p.id) || p.id == aggressorGpId) {
      continue;
    }
    if (!gpHasEmbassyOrPurchasedLandInMinorTribe(
      game,
      p.id,
      defenderMinorOrTribeId,
    )) {
      continue;
    }
    eligible.add(p.id);
  }
  eligible.sort();
  var g = game;
  final pending = <InterventionPrompt>[];
  for (final interveningId in eligible) {
    if (recordedChoiceKeys.contains(
      interventionChoiceKey(turn, interveningId, aggressorGpId),
    )) {
      continue;
    }
    if (g.playerById(interveningId) == null) continue;
    // Canonical pending-human-decision flow (diplomacy_shared_helpers.dart):
    // human intervener applies a supplied decision or suspends pending;
    // otherwise the AI rule resolves immediately.
    g = resolveHumanGatedDecision<InterventionDecision, Game>(
      isHumanControlled: isTargetHumanGp(g, interveningId),
      decisions: interventionDecisions,
      matches: (d) =>
          d.aggressorGpId == aggressorGpId &&
          d.defenderMinorOrTribeId == defenderMinorOrTribeId &&
          d.interveningGpId == interveningId,
      onAiResolve: () {
        final aiChoice = chooseAiIntervention(
          g,
          interveningId,
          aggressorGpId,
          defenderMinorOrTribeId,
          turn,
        );
        return _applyInterventionChoiceAndRecord(
          g,
          aggressorGpId: aggressorGpId,
          defenderMinorOrTribeId: defenderMinorOrTribeId,
          interveningGpId: interveningId,
          choice: aiChoice,
          turn: turn,
          factionMembership: factionMembership,
          recordedChoiceKeys: recordedChoiceKeys,
          eventTally: eventTally,
        );
      },
      onPending: () {
        pending.add(
          InterventionPrompt(
            aggressorGpId: aggressorGpId,
            defenderMinorOrTribeId: defenderMinorOrTribeId,
            interveningGpId: interveningId,
          ),
        );
        return g;
      },
      onHumanDecision: (d) {
        return _applyInterventionChoiceAndRecord(
          g,
          aggressorGpId: aggressorGpId,
          defenderMinorOrTribeId: defenderMinorOrTribeId,
          interveningGpId: interveningId,
          choice: d.choice,
          turn: turn,
          factionMembership: factionMembership,
          recordedChoiceKeys: recordedChoiceKeys,
          eventTally: eventTally,
        );
      },
    );
  }
  if (pending.isNotEmpty) {
    return InterventionResolutionResult(g, pendingInterventions: pending);
  }
  return InterventionResolutionResult(g);
}

InterventionResolutionResult resolveOutstandingInterventionsForMinorTribeWars(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
  List<InterventionDecision>? interventionDecisions,
  IntraTurnEventTally? eventTally,
}) {
  final seen = <String>{};
  // Built once from current-turn history; kept current as choices are applied
  // below, replacing the former per-GP linear scan of diplomaticHistoryEvents
  // (Refs #3419 step 6).
  final recordedChoiceKeys = recordedInterventionChoiceKeys(game, turn);
  var g = game;
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.declareWar) continue;
      final targetId = order.targetFactionId;
      if (!factionMembership.isGreatPower(gpId) ||
          !factionMembership.isMinorOrTribe(targetId)) {
        continue;
      }
      final rel = getRelation(g, gpId, targetId);
      if (rel == null || !rel.atWar) continue;
      final key = '$gpId|$targetId';
      if (seen.contains(key)) continue;
      seen.add(key);
      if (!interventionsOutstanding(
        g,
        turn,
        gpId,
        targetId,
        factionMembership,
        recordedChoiceKeys,
      )) {
        continue;
      }
      final pass = processInterventionsForAggressorDefender(
        g,
        aggressorGpId: gpId,
        defenderMinorOrTribeId: targetId,
        turn: turn,
        factionMembership: factionMembership,
        recordedChoiceKeys: recordedChoiceKeys,
        interventionDecisions: interventionDecisions,
        eventTally: eventTally,
      );
      g = pass.game;
      if (pass.pendingInterventions != null &&
          pass.pendingInterventions!.isNotEmpty) {
        return pass;
      }
    }
  }
  return InterventionResolutionResult(g);
}
