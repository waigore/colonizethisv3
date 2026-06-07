import 'dart:math' show Random;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../ai/ai_control.dart';
import 'diplomacy_relation_lookup.dart';
import '../combat/conflict_detection.dart';
import '../constants.dart';
import '../dossier/evidence_rules.dart';
import 'diplomacy_phase_result.dart';
import '../world/province_lookup.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_resolver.dart';
import 'overture_resolver.dart';

part 'intervention_resolver_call_to_arms.dart';
part 'intervention_resolver_apply.dart';

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
  final hasInvestment = _gpHasPurchasedLandInFactionProvinces(
    game,
    gpId,
    minorOrTribeId,
  );
  return hasEmbassy || hasInvestment;
}

bool _interventionChoiceRecordedForTurn(
  Game game,
  int turn,
  String interveningGpId,
  String aggressorGpId,
) {
  for (final e in game.diplomaticHistoryEvents) {
    if (e.turn != turn) continue;
    if (e.fromFactionId != interveningGpId || e.toFactionId != aggressorGpId) {
      continue;
    }
    if (e.type == DiplomaticEventType.interventionIntervene ||
        e.type == DiplomaticEventType.interventionDoNothing ||
        e.type == DiplomaticEventType.interventionProtest) {
      return true;
    }
  }
  return false;
}

bool _interventionsOutstanding(
  Game game,
  int turn,
  String aggressorGpId,
  String defenderMinorOrTribeId,
  DiplomacyFactionMembership factionMembership,
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
    if (!_interventionChoiceRecordedForTurn(game, turn, p.id, aggressorGpId)) {
      return true;
    }
  }
  return false;
}

InterventionDecision? _findInterventionDecision(
  List<InterventionDecision>? list,
  String aggressorGpId,
  String defenderMinorOrTribeId,
  String interveningGpId,
) {
  if (list == null) return null;
  for (final d in list) {
    if (d.aggressorGpId == aggressorGpId &&
        d.defenderMinorOrTribeId == defenderMinorOrTribeId &&
        d.interveningGpId == interveningGpId) {
      return d;
    }
  }
  return null;
}

/// Relation score 0–25 → 0%, 26–50 → 25%, 51–75 → 50%, 76–100 → 80%.
double _aiInterventionProbability(int relationScore) {
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

Game _clearOverturesBetweenGpAndMinorTribe(
  Game game,
  String gpId,
  String minorOrTribeId,
) {
  final overtures = game.overtureStates
      .where((o) => !(o.gpId == gpId && o.targetId == minorOrTribeId))
      .toList();
  if (overtures.length == game.overtureStates.length) return game;
  return game.copyWith(overtureStates: overtures);
}

InterventionResolutionResult _processInterventionsForAggressorDefender(
  Game game, {
  required String aggressorGpId,
  required String defenderMinorOrTribeId,
  required int turn,
  required DiplomacyFactionMembership factionMembership,
  List<InterventionDecision>? interventionDecisions,
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
    if (_interventionChoiceRecordedForTurn(
      g,
      turn,
      interveningId,
      aggressorGpId,
    )) {
      continue;
    }
    final player = g.playerById(interveningId);
    if (player == null) continue;
    if (player.isHuman) {
      final d = _findInterventionDecision(
        interventionDecisions,
        aggressorGpId,
        defenderMinorOrTribeId,
        interveningId,
      );
      if (d == null) {
        pending.add(
          InterventionPrompt(
            aggressorGpId: aggressorGpId,
            defenderMinorOrTribeId: defenderMinorOrTribeId,
            interveningGpId: interveningId,
          ),
        );
        continue;
      }
      g = applyInterventionAgainstAggressor(
        g,
        aggressorGpId: aggressorGpId,
        defenderMinorOrTribeId: defenderMinorOrTribeId,
        interveningGpId: interveningId,
        choice: d.choice,
        factionMembership: factionMembership,
      );
      continue;
    }
    final aiChoice = _chooseAiIntervention(
      g,
      interveningId,
      aggressorGpId,
      defenderMinorOrTribeId,
      turn,
    );
    g = applyInterventionAgainstAggressor(
      g,
      aggressorGpId: aggressorGpId,
      defenderMinorOrTribeId: defenderMinorOrTribeId,
      interveningGpId: interveningId,
      choice: aiChoice,
      factionMembership: factionMembership,
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
}) {
  final seen = <String>{};
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
      )) {
        continue;
      }
      final pass = _processInterventionsForAggressorDefender(
        g,
        aggressorGpId: gpId,
        defenderMinorOrTribeId: targetId,
        turn: turn,
        factionMembership: factionMembership,
        interventionDecisions: interventionDecisions,
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
