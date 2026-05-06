import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'ai_random_utils.dart';
import 'hidden_agenda.dart';
import 'perception.dart';

final _log = packageLogger();

// Goal selection (behavior tree). SPEC/ai/ai-architecture.md, ai-personalities.md.

/// Top-level strategy goals for the AI.
enum StrategicGoal { defend, expand, conquer, trade, tech, diplomacy }

/// Selects primary strategic goal from snapshot, personality, and agenda modifiers.
/// Deterministic given [snapshot], [config], and [goalSeed].
StrategicGoal selectPrimaryGoal(
  AIWorldSnapshot snapshot,
  AIConfig config,
  int goalSeed, {
  required String nationId,
  required int turn,
}) {
  final weights = getGoalWeightsForLeader(config.personalityId);
  final thresholds = getThresholdsForLeader(config.personalityId);

  // Situational modifiers from snapshot.
  int defend = weights.defend;
  int expand = weights.expand;
  int conquer = weights.conquer;
  int trade = weights.trade;
  int tech = weights.tech;
  int diplomacy = weights.diplomacy;

  conquer += agendaConquerModifier(config.hiddenAgendaId);
  diplomacy += agendaDiplomacyModifier(config.hiddenAgendaId);
  // Personality thresholds: war likelihood boosts conquer; peace/alliance boost diplomacy goal.
  conquer += (thresholds.warLikelihood - 50);
  diplomacy +=
      ((thresholds.peaceTendency + thresholds.allianceTendency) ~/ 2) - 50;

  if (snapshot.threats.atWarWith.isNotEmpty) {
    defend += 30;
  }
  if (snapshot.threats.capitalThreatened) {
    defend += 50;
  }
  if (snapshot.opportunities.unclaimedProvinces > 0) {
    expand += 20;
  }
  if (snapshot.economy.workerCount < 3) {
    expand += 15;
  }

  final candidates = <StrategicGoal, int>{
    StrategicGoal.defend: defend,
    StrategicGoal.expand: expand,
    StrategicGoal.conquer: conquer,
    StrategicGoal.trade: trade,
    StrategicGoal.tech: tech,
    StrategicGoal.diplomacy: diplomacy,
  };

  _log.d(
    'eval leaderId=${config.leaderId} hiddenAgendaId=${config.hiddenAgendaId} goalSeed=$goalSeed '
    'weights defend=$defend expand=$expand conquer=$conquer trade=$trade tech=$tech diplomacy=$diplomacy',
  );

  // Weighted random choice using goalSeed.
  final candidateEntries = candidates.entries.toList();
  final selectedIndex = pickWeightedIndex(
    candidateEntries.map((e) => e.value).toList(),
    goalSeed,
    useIntRoll: true,
  );
  final selected = selectedIndex == null
      ? StrategicGoal.expand
      : candidateEntries[selectedIndex].key;
  final majorConstraint = switch (selected) {
    StrategicGoal.defend =>
      snapshot.threats.capitalThreatened
          ? 'capitalThreatened'
          : snapshot.threats.atWarWith.isNotEmpty
          ? 'atWarWith'
          : 'none',
    StrategicGoal.expand =>
      snapshot.opportunities.unclaimedProvinces > 0
          ? 'unclaimedProvinces'
          : snapshot.economy.workerCount < 3
          ? 'lowWorkerCount'
          : 'none',
    StrategicGoal.conquer =>
      agendaConquerModifier(config.hiddenAgendaId) != 0
          ? 'hiddenAgendaConquerModifier'
          : (thresholds.warLikelihood - 50) != 0
          ? 'warLikelihoodThreshold'
          : 'none',
    StrategicGoal.diplomacy =>
      agendaDiplomacyModifier(config.hiddenAgendaId) != 0
          ? 'hiddenAgendaDiplomacyModifier'
          : ((thresholds.peaceTendency + thresholds.allianceTendency) ~/ 2) !=
                50
          ? 'peaceAllianceTendency'
          : 'none',
    _ => 'none',
  };
  _log.i(
    'selected primaryGoal=$selected nationId=$nationId turn=$turn majorConstraint=$majorConstraint',
  );
  return selected;
}
