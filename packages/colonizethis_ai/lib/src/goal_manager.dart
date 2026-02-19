import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';

import 'ai_config.dart';
import 'hidden_agenda.dart';
import 'perception.dart';

// Goal selection (behavior tree). SPEC/ai/ai-architecture.md, ai-personalities.md.

/// Top-level strategy goals for the AI.
enum StrategicGoal {
  defend,
  expand,
  conquer,
  trade,
  tech,
  diplomacy,
}

/// Selects primary strategic goal from snapshot, personality, and agenda modifiers.
/// Deterministic given [snapshot], [config], and [goalSeed].
StrategicGoal selectPrimaryGoal(
  AIWorldSnapshot snapshot,
  AIConfig config,
  int goalSeed,
) {
  final weights = getGoalWeightsForLeader(config.leaderId);

  // Situational modifiers from snapshot.
  int defend = weights.defend;
  int expand = weights.expand;
  int conquer = weights.conquer;
  int trade = weights.trade;
  int tech = weights.tech;
  int diplomacy = weights.diplomacy;

  conquer += agendaConquerModifier(config.hiddenAgendaId);
  diplomacy += agendaDiplomacyModifier(config.hiddenAgendaId);

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

  // Weighted random choice using goalSeed.
  final total = candidates.values.fold<int>(0, (a, b) => a + b);
  if (total <= 0) return StrategicGoal.expand;
  var r = math.Random(goalSeed).nextInt(total);
  for (final e in candidates.entries) {
    r -= e.value;
    if (r < 0) return e.key;
  }
  return StrategicGoal.expand;
}
