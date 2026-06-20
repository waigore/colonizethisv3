import 'dart:math' as math;

import 'planning_imports.dart';

import '../util/ai_random_utils.dart';
import '../perception/perception_snapshot.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_goal_filter.dart';

final _log = packageLogger();

// Goal selection (behavior tree). SPEC/ai/ai-architecture.md, ai-personalities.md.

/// Top-level strategy goals for the AI.
enum StrategicGoal { defend, expand, conquer, trade, tech, diplomacy }

/// Computes the effective strategic-goal candidate scores before weighted
/// random selection. Used by both the planner and trace export.
///
/// Soft-phase NW acquisition wiring (Refs #2847 Phase 3): when
/// [colonialPressureWeight] is non-null, the goal-score colonial-pressure
/// penalty/floor pass derives its activation gate from
/// `colonialPressureWeight > 0.0` (legacy hard-suppress preserved when
/// `colonialPressureWeight <= 0.0`) and scales the penalty magnitudes and
/// score floors by `colonialPressureWeight` clamped to `[0.0, 1.0]`. The
/// soft path is identity-equal to the legacy hard-phase
/// `phaseColonialPressureActive == true` behaviour when
/// `colonialPressureWeight == 1.0`, preserving the production goal-score
/// contract at the EXPAND→COLONIAL boundary while allowing the curve
/// values from `phase_priority_weights.dart` to ramp colonial pressure
/// continuously across OW counts on the dispatch path.
///
/// When [colonialPressureWeight] is null, the legacy boolean resolution
/// runs unchanged: callers passing [observerGoalPhase] route off
/// [resolvePhaseGoalColonialPressureActive], and tests/legacy callers
/// without either parameter fall through to the
/// `!suppressColonialPressure && hasColonialAcquisitionTargets &&
/// !shouldSuppressNewWorldColonialOrders` compose.
Map<StrategicGoal, int> evaluateStrategicGoalScores(
  AIWorldSnapshot snapshot,
  AIConfig config, {
  ObserverGoalPhase? observerGoalPhase,
  bool suppressColonialPressure = false,
  double? colonialPressureWeight,
}) {
  final effectiveColonialPressureWeight = colonialPressureWeight == null
      ? null
      : colonialPressureWeight.clamp(0.0, 1.0).toDouble();
  final phaseColonialPressureActive = effectiveColonialPressureWeight != null
      ? effectiveColonialPressureWeight > 0.0
      : observerGoalPhase != null
      ? resolvePhaseGoalColonialPressureActive(observerGoalPhase)
      : !suppressColonialPressure &&
            hasColonialAcquisitionTargets(snapshot.colonial) &&
            !shouldSuppressNewWorldColonialOrders(snapshot: snapshot);
  final colonialPressureScale = effectiveColonialPressureWeight ?? 1.0;
  final weights = resolveGoalWeights(
    config.personalityId,
    overrides: config.parameterOverrides,
  );
  final thresholds = resolveThresholds(
    config.personalityId,
    overrides: config.parameterOverrides,
  );

  var defend = weights.defend;
  var expand = weights.expand;
  var conquer = weights.conquer;
  var trade = weights.trade;
  var tech = weights.tech;
  var diplomacy = weights.diplomacy;

  conquer += getAgendaConquerModifier(config.hiddenAgendaId);
  diplomacy += getAgendaDiplomacyModifier(config.hiddenAgendaId);
  conquer += thresholds.warLikelihood - 50;
  diplomacy +=
      ((thresholds.peaceTendency + thresholds.allianceTendency) ~/ 2) - 50;

  if (snapshot.threats.atWarWith.isNotEmpty) {
    defend += 30;
    if (snapshot.conquest.oldWorldProvincesOwned <=
            kFewOldWorldProvincesDefendThreshold &&
        snapshot.conquest.provincesToVictory >
            kConquerScoreFloorProvincesToVictoryThreshold) {
      defend += kDefendBonusWhenAtWarAndFewHoldings;
    }
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

  final provincesToVictory = snapshot.conquest.provincesToVictory;
  if (snapshot.conquest.oldWorldProvincesOwned <=
          kFewOldWorldProvincesDefendThreshold &&
      provincesToVictory > kConquerScoreFloorProvincesToVictoryThreshold) {
    defend += kDefendBonusWhenFewOldWorldProvinces;
    if (snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty) {
      conquer += kWeakGpRecoveryConquerBonus;
      defend -= kWeakGpRecoveryDefendPenalty;
    }
  }
  conquer += conquerScoreBonusForProvincesToVictory(provincesToVictory);
  conquer += endgameConquerScoreBonus(provincesToVictory);
  if (snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty) {
    expand += kExpandBonusWhenInvadableProvinces;
  }
  if (snapshot.colonial.invadableNewWorldProvinceIdsSorted.isNotEmpty) {
    expand += kColonialExpandBonusWhenInvadableNw;
    conquer += kColonialConquerBonusWhenInvadableNw;
  }
  if (isEarlyColonialExpansion(snapshot.colonial)) {
    conquer += kColonialConquerBonusWhenFewNwProvinces;
  }
  if (isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    diplomacy -= kStalledDiplomacyGoalPenalty;
    trade -= kStalledTradeGoalPenalty;
    conquer += kStalledConquerGoalBonus;
    if (snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty) {
      conquer += kDeclareWarStalledExpansionMinorBonus;
      conquer = math.max(conquer, 120);
      diplomacy = math.min(diplomacy, 35);
      trade = math.min(trade, 35);
      tech = math.min(tech, 45);
    }
  }
  if (phaseColonialPressureActive) {
    final scaledDiplomacyPenalty =
        (kColonialDiplomacyGoalPenaltyWhenPressure * colonialPressureScale)
            .round();
    final scaledTradePenalty =
        (kColonialTradeGoalPenaltyWhenPressure * colonialPressureScale).round();
    final scaledExpandFloor =
        (kMinimumColonialExpandScoreWhenPressure * colonialPressureScale)
            .round();
    final scaledConquerFloor =
        (kMinimumColonialConquerScoreWhenPressure * colonialPressureScale)
            .round();
    diplomacy -= scaledDiplomacyPenalty;
    trade -= scaledTradePenalty;
    if (expand < scaledExpandFloor) {
      expand = scaledExpandFloor;
    }
    if (conquer < scaledConquerFloor) {
      conquer = scaledConquerFloor;
    }
  }
  if (provincesToVictory > kConquerScoreFloorProvincesToVictoryThreshold &&
      conquer < kMinimumConquerScoreWhenFarFromVictory) {
    conquer = kMinimumConquerScoreWhenFarFromVictory;
  }
  if (provincesToVictory > kConquerScoreFloorProvincesToVictoryThreshold) {
    final tradePenalty = math.min(
      kTradeGoalPenaltyCapWhenFarFromVictory,
      trade - 40,
    );
    if (tradePenalty > 0) {
      trade -= tradePenalty;
    }
    if (snapshot.conquest.adjacentOwnerFactionIdsSorted.isNotEmpty &&
        expand < kMinimumConquerScoreWhenFarFromVictory) {
      expand = kMinimumConquerScoreWhenFarFromVictory;
    }
  }

  // Treasury-acquisition trade bias (Refs #2994 F6). Applied last so that a
  // broke AI ( `treasury <= 0` ) escapes the stalled-OW `trade <= 35` clamp
  // and the colonial-pressure / far-from-victory trade penalties before the
  // score map is returned. See `SPEC/ai/treasury-planner.md`.
  final treasury = snapshot.economy.treasury;
  final cheapestRegimentTreasuryCost = cheapestRegimentBuildTreasuryCost();
  if (treasury <= 0) {
    if (trade < kEmergencyTradeGoalDominantFloor) {
      trade = kEmergencyTradeGoalDominantFloor;
    }
  } else if (treasury < cheapestRegimentTreasuryCost) {
    final ratio = treasury / cheapestRegimentTreasuryCost;
    final boost =
        ((1.0 - ratio) * kTreasuryAcquisitionTradeBoostMax).round();
    if (boost > 0) {
      trade += boost;
    }
  }

  return <StrategicGoal, int>{
    StrategicGoal.defend: defend,
    StrategicGoal.expand: expand,
    StrategicGoal.conquer: conquer,
    StrategicGoal.trade: trade,
    StrategicGoal.tech: tech,
    StrategicGoal.diplomacy: diplomacy,
  };
}

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
