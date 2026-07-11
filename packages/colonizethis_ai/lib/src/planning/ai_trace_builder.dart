import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart' show TurnTraceAiSection;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'colonial_phase_planner.dart';
import 'domain_gate_data.dart';
import 'goal_manager.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';
import '../perception/perception_snapshot.dart';

/// Bundles inputs for [buildAiTraceSection] (Refs #3972 AC5).
final class AiTraceBuildInput {
  const AiTraceBuildInput({
    required this.nationId,
    required this.turn,
    required this.config,
    required this.seeds,
    required this.snapshot,
    required this.primaryGoal,
    required this.goalScores,
    required this.economyPlan,
    required this.orders,
    required this.ordersByDomain,
    required this.finalOrders,
    this.declaredWarTargetFactionId,
    this.conquestArmyMoveCount = 0,
    this.observerGoalPhase,
    this.phasePlan,
    this.domainGateData,
  });

  final String nationId;
  final int turn;
  final AIConfig config;
  final AISeedBundle seeds;
  final AIWorldSnapshot snapshot;
  final StrategicGoal primaryGoal;
  final Map<StrategicGoal, int> goalScores;
  final EconomyPlan economyPlan;
  final Orders orders;
  final Map<String, Object?> ordersByDomain;
  final List<Map<String, Object?>> finalOrders;
  final String? declaredWarTargetFactionId;
  final int conquestArmyMoveCount;
  final ObserverGoalPhase? observerGoalPhase;
  final PhasePlanOutcome? phasePlan;
  final DomainGateData? domainGateData;
}

TurnTraceAiSection buildAiTraceSection(AiTraceBuildInput input) {
  final config = input.config;
  final snapshot = input.snapshot;
  final primaryGoal = input.primaryGoal;
  final goalScores = input.goalScores;
  final economyPlan = input.economyPlan;
  final ordersByDomain = input.ordersByDomain;
  final finalOrders = input.finalOrders;
  final declaredWarTargetFactionId = input.declaredWarTargetFactionId;
  final conquestArmyMoveCount = input.conquestArmyMoveCount;
  final observerGoalPhase = input.observerGoalPhase;
  final phasePlan = input.phasePlan;
  final domainGateData = input.domainGateData;
  final domainWeights = resolveDomainWeights(
    config.personalityId,
    overrides: config.parameterOverrides,
  );
  final goalWeights = resolveGoalWeights(
    config.personalityId,
    overrides: config.parameterOverrides,
  );
  final thresholds = resolveThresholds(
    config.personalityId,
    overrides: config.parameterOverrides,
  );
  final selectedScore = goalScores[primaryGoal] ?? 0;
  final agendaConquerModifier = getAgendaConquerModifier(config.hiddenAgendaId);
  final agendaDiplomacyModifier = getAgendaDiplomacyModifier(
    config.hiddenAgendaId,
  );
  final agendaSpyOrderModifier = getAgendaSpyOrderModifier(
    config.hiddenAgendaId,
  );
  final agendaBuildOrderModifier = getAgendaBuildOrderModifier(
    config.hiddenAgendaId,
  );
  final agendaResearchModifier = getAgendaResearchModifier(
    config.hiddenAgendaId,
  );
  final phasePlanJson = phasePlan == null
      ? null
      : compactPhasePlanJson(phasePlan);
  return TurnTraceAiSection(
    factionId: input.nationId,
    state: <String, Object?>{
      'winningCandidate': <String, Object?>{
        'type': 'strategicGoal',
        'goal': primaryGoal.name,
        'score': selectedScore,
        'selectionMethod': 'weighted_random',
        'majorConstraint': majorConstraintForStrategicGoal(
          primaryGoal,
          snapshot,
          config,
        ),
      },
      'topAlternates': rankedGoalCandidates(goalScores, exclude: primaryGoal),
      'aggregates': <String, Object?>{
        'totalOrders': finalOrders.length,
        'ordersByDomain': ordersByDomain,
        'economyPlan': <String, Object?>{
          'productionAssignmentCount': economyPlan.productionAssignments.length,
          'cargoPreference': economyPlan.cargoPreference.name,
        },
        'snapshot': <String, Object?>{
          'atWarWith': snapshot.threats.atWarWith,
          'neighborProvincesHostile': snapshot.threats.neighborProvincesHostile,
          'capitalThreatened': snapshot.threats.capitalThreatened,
          'weakNeighbors': snapshot.opportunities.weakNeighbors,
          'richUnexploitedProvinces':
              snapshot.opportunities.richUnexploitedProvinces,
          'unclaimedProvinces': snapshot.opportunities.unclaimedProvinces,
          'workerCount': snapshot.economy.workerCount,
          'treasury': snapshot.economy.treasury,
          'ownProvinceCount': snapshot.economy.ownProvinceCount,
          'provincesToVictory': snapshot.conquest.provincesToVictory,
          'invadableCount':
              snapshot.conquest.invadableProvinceIdsSorted.length,
          'declaredWarTarget': declaredWarTargetFactionId,
          'conquestArmyMoveCount': conquestArmyMoveCount,
        },
      },
      if (observerGoalPhase != null) 'observerGoalPhase': observerGoalPhase.name,
      if (phasePlanJson != null && phasePlanJson.isNotEmpty)
        'phasePlan': phasePlanJson,
      'decisionContext': <String, Object?>{
        'turnNumber': input.turn,
        'leaderId': config.leaderId,
        'personalityId': config.personalityId,
        'hiddenAgendaId': config.hiddenAgendaId,
        'profileId': config.profileId,
      },
    },
    thresholds: <String, Object?>{
      'constants': <String, Object?>{
        'seeds': <String, Object?>{
          'perception': input.seeds.perceptionSeed,
          'goal': input.seeds.goalSeed,
          'economy': input.seeds.economySeed,
          'military': input.seeds.militarySeed,
          'diplomacy': input.seeds.diplomacySeed,
          'research': input.seeds.researchSeed,
          'tactical': input.seeds.tacticalSeed,
          'dialogue': input.seeds.dialogueSeed,
          'agenda': input.seeds.agendaSeed,
        },
        'goalWeights': <String, Object?>{
          'defend': goalWeights.defend,
          'expand': goalWeights.expand,
          'conquer': goalWeights.conquer,
          'trade': goalWeights.trade,
          'tech': goalWeights.tech,
          'diplomacy': goalWeights.diplomacy,
        },
        'agendaModifiers': <String, Object?>{
          'conquer': agendaConquerModifier,
          'diplomacy': agendaDiplomacyModifier,
          'spyOrder': agendaSpyOrderModifier,
          'buildOrder': agendaBuildOrderModifier,
          'research': agendaResearchModifier,
        },
      },
      'derived': <String, Object?>{
        'goalCandidateScores': goalScoresJson(goalScores),
        'domainWeights': <String, Object?>{
          'economy': domainWeights.economy,
          'military': domainWeights.military,
          'diplomacy': domainWeights.diplomacy,
          'research': domainWeights.research,
        },
      },
      'effective': <String, Object?>{
        'selectedGoal': primaryGoal.name,
        'selectedGoalScore': selectedScore,
        'adjustedGoalScores': goalScoresJson(goalScores),
        'personalityThresholds': <String, Object?>{
          'warLikelihood': thresholds.warLikelihood,
          'peaceTendency': thresholds.peaceTendency,
          'allianceTendency': thresholds.allianceTendency,
          'researchNaval': thresholds.researchNaval,
          'researchMilitary': thresholds.researchMilitary,
          'researchEconomic': thresholds.researchEconomic,
          'researchExploration': thresholds.researchExploration,
        },
      },
      'gates': <Object?>[...goalSelectionGates(goalScores, primaryGoal)],
      if (domainGateData != null) 'domainGates': domainGateData.toJson(),
    },
    outcome: <String, Object?>{
      'domainOutputs': <String, Object?>{
        ...ordersByDomain,
        'conquestArmyMove': conquestArmyMoveCount,
      },
      'finalAggregatedOrders': finalOrders,
      'emittedOrderCount': finalOrders.length,
    },
  );
}

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
