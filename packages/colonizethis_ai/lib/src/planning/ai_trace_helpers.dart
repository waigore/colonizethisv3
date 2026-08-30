import 'colonial_phase_planner.dart';
import 'goal_manager.dart';
import 'phase_planner_dispatch.dart';

/// Compact decision-provenance projection of [PhasePlanOutcome] for AI
/// trace emission under `state.phasePlan` (Refs #2832).
///
/// Returns only the provenance-relevant fields for the active phase and
/// omits null / empty values to keep the payload compact. The verbose
/// nested plan objects (economy, military, naval, civilian work orders)
/// are intentionally excluded because the trace already captures their
/// emitted output under `outcome.domainOutputs` and
/// `outcome.finalAggregatedOrders`.
Map<String, Object?> compactPhasePlanJson(PhasePlanOutcome phasePlan) {
  final acquisition = phasePlan.colonialAcquisitionTarget;
  return <String, Object?>{
    if (acquisition != null)
      'colonialAcquisition': <String, Object?>{
        'targetFactionId': acquisition.targetFactionId,
        'method': acquisition.method.traceJsonName,
      },
    if (phasePlan.expandDeclareWarTargetFactionId != null)
      'expandDeclareWarTarget': phasePlan.expandDeclareWarTargetFactionId,
    if (phasePlan.expandPeaceTargetFactionIdsSorted.isNotEmpty)
      'expandPeaceTargets': phasePlan.expandPeaceTargetFactionIdsSorted,
    if (phasePlan.colonialPeaceTargetFactionIdsSorted.isNotEmpty)
      'colonialPeaceTargets': phasePlan.colonialPeaceTargetFactionIdsSorted,
    if (phasePlan.colonialLiteOverturesSorted.isNotEmpty)
      'colonialLiteOvertures': phasePlan.colonialLiteOverturesSorted,
    if (phasePlan.developPeaceTargetFactionIdsSorted.isNotEmpty)
      'developPeaceTargets': phasePlan.developPeaceTargetFactionIdsSorted,
  };
}

extension _AcquisitionMethodTraceJsonName on AcquisitionMethod {
  /// Stable lowerCamelCase string used in the trace under
  /// `state.phasePlan.colonialAcquisition.method` (Refs #2832).
  String get traceJsonName {
    switch (this) {
      case AcquisitionMethod.joinEmpire:
        return 'joinEmpire';
      case AcquisitionMethod.purchaseLand:
        return 'purchaseLand';
      case AcquisitionMethod.declareWar:
        return 'declareWar';
    }
  }
}

List<Map<String, Object?>> goalSelectionGates(
  Map<StrategicGoal, int> goalScores,
  StrategicGoal selectedGoal,
) {
  final entries = goalScores.entries.toList(growable: false)
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries
      .map(
        (entry) => <String, Object?>{
          'gate': 'strategic_goal_selection',
          'method': 'weighted_random',
          'candidateGoal': entry.key.name,
          'candidateScore': entry.value,
          'selected': entry.key == selectedGoal,
        },
      )
      .toList(growable: false);
}

Map<String, Object?> goalScoresJson(Map<StrategicGoal, int> goalScores) {
  return <String, Object?>{
    for (final entry in goalScores.entries) entry.key.name: entry.value,
  };
}

List<Map<String, Object?>> rankedGoalCandidates(
  Map<StrategicGoal, int> goalScores, {
  required StrategicGoal exclude,
}) {
  final entries =
      goalScores.entries
          .where((entry) => entry.key != exclude)
          .toList(growable: false)
        ..sort((a, b) => b.value.compareTo(a.value));
  return entries
      .take(3)
      .map(
        (entry) => <String, Object?>{
          'type': 'strategicGoal',
          'goal': entry.key.name,
          'score': entry.value,
        },
      )
      .toList(growable: false);
}
