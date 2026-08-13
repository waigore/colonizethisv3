import 'planning_imports.dart';

import '../util/ai_random_utils.dart';
import '../perception/perception_snapshot.dart';
import 'observer_goal_phase.dart';
import 'goal_manager_scores.dart';

export 'goal_manager_scores.dart' show StrategicGoal, evaluateStrategicGoalScores;

final _log = packageLogger();

// Goal selection (behavior tree). SPEC/ai/ai-architecture.md, ai-personalities.md.

String majorConstraintForStrategicGoal(
  StrategicGoal selected,
  AIWorldSnapshot snapshot,
  AIConfig config,
) {
  final thresholds = resolveThresholds(
    config.personalityId,
    overrides: config.parameterOverrides,
  );
  return switch (selected) {
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
      snapshot.conquest.provincesToVictory > 0
          ? 'provincesToVictory'
          : getAgendaConquerModifier(config.hiddenAgendaId) != 0
          ? 'hiddenAgendaConquerModifier'
          : (thresholds.warLikelihood - 50) != 0
          ? 'warLikelihoodThreshold'
          : 'none',
    StrategicGoal.diplomacy =>
      getAgendaDiplomacyModifier(config.hiddenAgendaId) != 0
          ? 'hiddenAgendaDiplomacyModifier'
          : ((thresholds.peaceTendency + thresholds.allianceTendency) ~/ 2) !=
                50
          ? 'peaceAllianceTendency'
          : 'none',
    _ => 'none',
  };
}

/// Selects primary strategic goal from snapshot, personality, and agenda modifiers.
/// Deterministic given [snapshot], [config], and [goalSeed].
///
/// When [colonialPressureWeight] is non-null, the underlying
/// [evaluateStrategicGoalScores] call routes its colonial-pressure
/// penalty/floor pass through the soft-phase NW acquisition weight (Refs
/// #2847 Phase 3 goal-score wiring); identity-equal to the legacy
/// hard-phase behaviour at `colonialPressureWeight == 1.0`. Otherwise
/// the legacy boolean resolution from [observerGoalPhase] /
/// [suppressColonialPressure] is preserved exactly.
StrategicGoal selectPrimaryGoal(
  AIWorldSnapshot snapshot,
  AIConfig config,
  int goalSeed, {
  required String nationId,
  required int turn,
  ObserverGoalPhase? observerGoalPhase,
  bool suppressColonialPressure = false,
  double? colonialPressureWeight,
}) {
  final candidates = evaluateStrategicGoalScores(
    snapshot,
    config,
    observerGoalPhase: observerGoalPhase,
    suppressColonialPressure: suppressColonialPressure,
    colonialPressureWeight: colonialPressureWeight,
  );

  _log.d(
    'eval leaderId=${config.leaderId} hiddenAgendaId=${config.hiddenAgendaId} goalSeed=$goalSeed '
    'weights defend=${candidates[StrategicGoal.defend]} '
    'expand=${candidates[StrategicGoal.expand]} '
    'conquer=${candidates[StrategicGoal.conquer]} '
    'trade=${candidates[StrategicGoal.trade]} '
    'tech=${candidates[StrategicGoal.tech]} '
    'diplomacy=${candidates[StrategicGoal.diplomacy]}',
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
  final majorConstraint = majorConstraintForStrategicGoal(
    selected,
    snapshot,
    config,
  );
  _log.i(
    'selected primaryGoal=$selected nationId=$nationId turn=$turn majorConstraint=$majorConstraint',
  );
  return selected;
}
