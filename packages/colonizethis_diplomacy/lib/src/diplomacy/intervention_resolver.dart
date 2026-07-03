import 'dart:math' show Random;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'diplomacy_phase_result.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_shared_helpers.dart';
import 'intervention_resolver_apply.dart';
import 'diplomacy_event_logging.dart';

export 'intervention_resolver_apply.dart';
export 'intervention_resolver_call_to_arms.dart';

class InterventionResolutionResult {
  InterventionResolutionResult(this.game, {this.pendingInterventions});

  final Game game;
  final List<InterventionPrompt>? pendingInterventions;
}

bool _gpHasEmbassyOrPurchasedLandInMinorTribe(
  Game game,
  String gpId,
  String minorOrTribeId,
) {
  final o = getOverture(game, gpId, minorOrTribeId);
  final hasEmbassy = o != null && o.hasEmbassy;
  final hasInvestment = gpHasPurchasedLandInFactionProvinces(
    game,
    gpId,
    minorOrTribeId,
  );
  return hasEmbassy || hasInvestment;
}

/// Lookup key for a recorded intervention choice on [turn] by [interveningGpId]
/// reacting to [aggressorGpId]. Refs #3419 step 6.
String _interventionChoiceKey(
  int turn,
  String interveningGpId,
  String aggressorGpId,
) => '$turn|$interveningGpId|$aggressorGpId';

/// Set of `(turn, interveningGpId, aggressorGpId)` keys for intervention choices
/// already recorded in [game]'s history for [turn], built with a single scan.
///
/// Replaces the per-eligible-GP linear scan of the unbounded
/// `diplomaticHistoryEvents` list (formerly O(history × players) per war
/// declaration) with an O(1) membership test against this set (Refs #3419).
Set<String> _recordedInterventionChoiceKeys(Game game, int turn) {
  final keys = <String>{};
  for (final e in game.diplomaticHistoryEvents) {
    if (e.turn != turn) continue;
    if (e.type != DiplomaticEventType.interventionIntervene &&
        e.type != DiplomaticEventType.interventionDoNothing &&
        e.type != DiplomaticEventType.interventionProtest) {
      continue;
    }
    final from = e.fromFactionId;
    final to = e.toFactionId;
    if (from == null || to == null) continue;
    keys.add(_interventionChoiceKey(turn, from, to));
  }
  return keys;
}

bool _interventionsOutstanding(
  Game game,
  int turn,
  String aggressorGpId,
  String defenderMinorOrTribeId,
  DiplomacyFactionMembership factionMembership,
  Set<String> recordedChoiceKeys,
) {
  for (final p in game.players) {
    if (!factionMembership.isGreatPower(p.id) || p.id == aggressorGpId) {
      continue;
    }
    if (!_gpHasEmbassyOrPurchasedLandInMinorTribe(
      game,
      p.id,
      defenderMinorOrTribeId,
    )) {
      continue;
    }
    if (!recordedChoiceKeys.contains(
      _interventionChoiceKey(turn, p.id, aggressorGpId),
    )) {
      return true;
    }
  }
  return false;
}

/// Relation score 0–25 → 0%, 26–50 → 25%, 51–75 → 50%, 76–100 → 80%.
double _aiInterventionProbability(num relationScore) {
  if (relationScore <= relationScoreLevelHostileMax) return 0;
  if (relationScore <= relationScoreLevelNeutralMax) {
    return kInterventionProbabilityNeutral;
  }
  if (relationScore <= relationScoreLevelFriendlyMax) {
    return kInterventionProbabilityFriendly;
  }
  return kInterventionProbabilityAllied;
}

InterventionChoice _chooseAiIntervention(
  Game game,
  String aiGpId,
  String aggressorGpId,
  String defenderMinorOrTribeId,
  int turn,
) {
  final rel = getRelation(game, aiGpId, defenderMinorOrTribeId);
  final score = rel?.score ?? relationScoreNeutral;
  final p = _aiInterventionProbability(score);
  final seed = Object.hash(turn, aiGpId, aggressorGpId, defenderMinorOrTribeId);
  final roll = Random(seed).nextDouble();
  return roll < p ? InterventionChoice.intervene : InterventionChoice.doNothing;
}

InterventionResolutionResult _processInterventionsForAggressorDefender(
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
    if (!_gpHasEmbassyOrPurchasedLandInMinorTribe(
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
      _interventionChoiceKey(turn, interveningId, aggressorGpId),
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
        final aiChoice = _chooseAiIntervention(
          g,
          interveningId,
          aggressorGpId,
          defenderMinorOrTribeId,
          turn,
        );
        final next = applyInterventionAgainstAggressor(
          g,
          aggressorGpId: aggressorGpId,
          defenderMinorOrTribeId: defenderMinorOrTribeId,
          interveningGpId: interveningId,
          choice: aiChoice,
          factionMembership: factionMembership,
          eventTally: eventTally,
        );
        recordedChoiceKeys.add(
          _interventionChoiceKey(turn, interveningId, aggressorGpId),
        );
        return next;
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
        final next = applyInterventionAgainstAggressor(
          g,
          aggressorGpId: aggressorGpId,
          defenderMinorOrTribeId: defenderMinorOrTribeId,
          interveningGpId: interveningId,
          choice: d.choice,
          factionMembership: factionMembership,
          eventTally: eventTally,
        );
        recordedChoiceKeys.add(
          _interventionChoiceKey(turn, interveningId, aggressorGpId),
        );
        return next;
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
  final recordedChoiceKeys = _recordedInterventionChoiceKeys(game, turn);
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
      if (!_interventionsOutstanding(
        g,
        turn,
        gpId,
        targetId,
        factionMembership,
        recordedChoiceKeys,
      )) {
        continue;
      }
      final pass = _processInterventionsForAggressorDefender(
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
