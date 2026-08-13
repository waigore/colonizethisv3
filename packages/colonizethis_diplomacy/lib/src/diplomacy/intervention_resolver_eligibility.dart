import 'dart:math' show Random;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'diplomacy_relation_constants.dart';
import 'diplomacy_relation_lookup.dart';
import 'intervention_resolver_apply.dart'
    show gpHasPurchasedLandInFactionProvinces;

bool gpHasEmbassyOrPurchasedLandInMinorTribe(
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
String interventionChoiceKey(
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
Set<String> recordedInterventionChoiceKeys(Game game, int turn) {
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
    keys.add(interventionChoiceKey(turn, from, to));
  }
  return keys;
}

bool interventionsOutstanding(
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
    if (!gpHasEmbassyOrPurchasedLandInMinorTribe(
      game,
      p.id,
      defenderMinorOrTribeId,
    )) {
      continue;
    }
    if (!recordedChoiceKeys.contains(
      interventionChoiceKey(turn, p.id, aggressorGpId),
    )) {
      return true;
    }
  }
  return false;
}

/// Relation score 0–25 → 0%, 26–50 → 25%, 51–75 → 50%, 76–100 → 80%.
double aiInterventionProbability(num relationScore) {
  if (relationScore <= relationScoreLevelHostileMax) return 0;
  if (relationScore <= relationScoreLevelNeutralMax) {
    return kInterventionProbabilityNeutral;
  }
  if (relationScore <= relationScoreLevelFriendlyMax) {
    return kInterventionProbabilityFriendly;
  }
  return kInterventionProbabilityAllied;
}

InterventionChoice chooseAiIntervention(
  Game game,
  String aiGpId,
  String aggressorGpId,
  String defenderMinorOrTribeId,
  int turn,
) {
  final rel = getRelation(game, aiGpId, defenderMinorOrTribeId);
  final score = rel?.score ?? relationScoreNeutral;
  final p = aiInterventionProbability(score);
  final seed = Object.hash(turn, aiGpId, aggressorGpId, defenderMinorOrTribeId);
  final roll = Random(seed).nextDouble();
  return roll < p ? InterventionChoice.intervene : InterventionChoice.doNothing;
}
