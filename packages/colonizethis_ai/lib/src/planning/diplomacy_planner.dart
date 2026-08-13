/// Diplomacy planner public surface (Refs #2509; #4365 Slice A).
///
/// Re-exports peace-target / declare-war helpers and the run entrypoints.
library;

export 'expand_phase_planner.dart'
    show
        // Previously re-exported via `colonial_pressure.dart`.
        consolidateGainsSoleGpPeaceTarget,
        criticalOwHoldPeaceTargets,
        hasUninvadedOldWorldMinor,
        isOldWorldGpOnlyInvadableFrontier,
        isStalledOldWorldGpBlockerFocus,
        primaryInvadableOldWorldGpBlocker,
        quotaMetBelowQuotaAtWarPeaceTargets,
        quotaMetFutileBelowQuotaGpPeaceTargets,
        stalledBelowQuotaGpLeadPeaceTargets,
        belowQuotaPeerGpPeaceTargets,
        defaultStartGpPeaceTargets,
        defaultStartFutileMinorPeaceTargets,
        nearQuotaHoldPeaceTargets,
        unwinnableSoleGpFrontierPeaceTarget,
        // Previously re-exported via `diplomacy_planner_peace_targets.dart`.
        stalledStrongerGpBlockerPeaceTarget,
        stalledGpBlockerFocusPeaceTargets,
        stalledFutileGpPeaceTargets,
        stalledFocusMinorTarget,
        belowQuotaActiveMinorWarTarget,
        atWarGpDistractionTribePeaceTargets,
        belowQuotaRegimentThinTribeDistractionPeaceTargets,
        stalledExpansionDistractionPeaceTargets,
        criticalWeakGpSurvivalPeaceTargets,
        weakHoldingsInvadableBlockerPeaceTargets,
        criticalMultiFrontGpPeaceTargets,
        belowQuotaMultiMinorDistractionPeaceTargets,
        stalledZeroRegimentAllFactionPeaceTargets,
        stalledZeroRegimentGpPeaceTargets,
        mutualZeroRegimentGpStalematePeaceTargets,
        mutualExhaustedBelowQuotaGpStalematePeaceTargets,
        stalledOwExpansionNeedsPeacePass,
        multiFrontNonBlockerGpPeaceTargets;
export 'observer_goal_phase.dart'
    show
        collectStalledGreatPowerPeaceTargets,
        supplementMutualStalledGreatPowerPeaceOrders;
export 'diplomacy_planner_declare_war_targets.dart';
export 'diplomatic_candidate_scoring.dart'
    show computeDiplomaticCandidateScores, DiplomaticCandidateScoringInput;
export 'war_desire_calculator.dart' show computeWarDesireScore;
export 'diplomacy_planner_result.dart'
    show DiplomacyPlannerPass, DiplomacyPlannerResult;
export 'diplomacy_planner_run.dart'
    show runDiplomacyPlanner, runDiplomacyPlannerWithResult;
