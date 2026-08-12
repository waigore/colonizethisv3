import 'planning_imports.dart';
import 'recruitment_planner_types.dart';
import 'recruitment_planner_candidates.dart';
import 'recruitment_planner_candidates_ledger.dart';

// Candidate evaluate / emit for the recruitment planner (Refs #3997 AC5;
// #4310 Slice B process split).

void processRecruitCandidates({
  required PreparedRecruitmentPlan prepared,
  required List<RecruitWorkerOrder> recruitOrders,
  required List<RejectedRecruitmentSuggestion> rejected,
}) {
  for (final candidate in prepared.recruitCandidates) {
    if (prepared.reserveFabricForMilitary && recruitConsumesFabric(candidate)) {
      rejected.add(
        RejectedRecruitmentSuggestion(
          reason: kRecruitmentRejectMilitaryFabricReservation,
          targetTier: candidate.targetTier.name,
        ),
      );
      continue;
    }
    final outcome = _evaluateRecruitCandidate(candidate, prepared.state);
    switch (outcome) {
      case _CandidateOutcome.accepted:
        recruitOrders.add(candidate);
        prepared.state.applyRecruit(candidate);
      case _CandidateOutcome.rejectedInsufficientWorkers:
        rejected.add(
          RejectedRecruitmentSuggestion(
            reason: kRecruitmentRejectInsufficientWorkers,
            targetTier: candidate.targetTier.name,
          ),
        );
      case _CandidateOutcome.rejectedSoftCap:
        rejected.add(
          RejectedRecruitmentSuggestion(
            reason: kRecruitmentRejectSoftLuxuryCap,
            targetTier: candidate.targetTier.name,
          ),
        );
      case _CandidateOutcome.rejectedPaperBudget:
        rejected.add(
          RejectedRecruitmentSuggestion(
            reason: kRecruitmentRejectPaperBudget,
            targetTier: candidate.targetTier.name,
          ),
        );
    }
  }
}

void processBuildCandidates({
  required PreparedRecruitmentPlan prepared,
  required List<BuildUnitOrder> buildUnitOrders,
  required List<RejectedRecruitmentSuggestion> rejected,
}) {
  for (final candidate in prepared.buildCandidates) {
    if (prepared.suppressMilitaryBuilds && buildConsumesPeasant(candidate)) {
      rejected.add(
        RejectedRecruitmentSuggestion(
          reason: kRecruitmentRejectMilitaryBuildSuppressed,
          targetTier: candidate.unitType,
        ),
      );
      continue;
    }
    final outcome = _evaluateBuildCandidate(candidate, prepared.state);
    switch (outcome) {
      case _CandidateOutcome.accepted:
        buildUnitOrders.add(candidate);
        prepared.state.applyBuild(candidate);
      case _CandidateOutcome.rejectedInsufficientWorkers:
        rejected.add(
          RejectedRecruitmentSuggestion(
            reason: kRecruitmentRejectInsufficientWorkers,
            targetTier: candidate.unitType,
          ),
        );
      case _CandidateOutcome.rejectedSoftCap:
        // Builds are not gated by the soft luxury cap; defensive only.
        rejected.add(
          RejectedRecruitmentSuggestion(
            reason: kRecruitmentRejectSoftLuxuryCap,
            targetTier: candidate.unitType,
          ),
        );
      case _CandidateOutcome.rejectedPaperBudget:
        rejected.add(
          RejectedRecruitmentSuggestion(
            reason: kRecruitmentRejectPaperBudget,
            targetTier: candidate.unitType,
          ),
        );
    }
  }
}

enum _CandidateOutcome {
  accepted,
  rejectedInsufficientWorkers,
  rejectedSoftCap,
  rejectedPaperBudget,
}

_CandidateOutcome _evaluateRecruitCandidate(
  RecruitWorkerOrder candidate,
  RecruitmentCandidatePlanState state,
) {
  // Refs #3793 AC7: the shared paper budget is the dominant gate — a
  // paper-costing trained-worker recruit that would overrun the remaining
  // budget is dropped before the peasant / soft-cap checks.
  if (state.paperOverBudget(recruitPaperCost(candidate))) {
    return _CandidateOutcome.rejectedPaperBudget;
  }
  final row = WorkerActionEconomyCatalog.forTier(candidate.targetTier);
  if (row.consumesPeasant && state.availablePeasants() < 1) {
    return _CandidateOutcome.rejectedInsufficientWorkers;
  }
  if (candidate.targetTier != WorkerTier.peasant) {
    final projected = state.projectedTrainedCount(candidate.targetTier) + 1;
    final sustainable = state.sustainable[candidate.targetTier] ?? 0;
    final cap = state.inDeficit
        ? softLuxuryCapDeficitLimit(sustainable)
        : sustainable;
    if (projected > cap) {
      return _CandidateOutcome.rejectedSoftCap;
    }
  }
  return _CandidateOutcome.accepted;
}

_CandidateOutcome _evaluateBuildCandidate(
  BuildUnitOrder candidate,
  RecruitmentCandidatePlanState state,
) {
  // Refs #3793 AC7: civilian builds consume paper; drop one whose paper cost
  // would overrun the remaining shared budget before the peasant check.
  if (state.paperOverBudget(buildPaperCost(candidate))) {
    return _CandidateOutcome.rejectedPaperBudget;
  }
  if (buildConsumesPeasant(candidate) && state.availablePeasants() < 1) {
    return _CandidateOutcome.rejectedInsufficientWorkers;
  }
  return _CandidateOutcome.accepted;
}
