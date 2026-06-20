// AI behavior, planning, personalities. SPEC/ai/ai-architecture.md, SPEC/program/ai-systems-impl.md.

export 'package:colonizethis_data/colonizethis_data.dart'
    show kPortraitMoodValues;
export 'package:colonizethis_models/colonizethis_models.dart'
    show
        AIConfig,
        AISeedBundle,
        AssignedRecipe,
        CargoPreference,
        EconomyPlan,
        StrategicOrderResult;
export 'src/perception/dossier_builder.dart';
export 'src/perception/dossier_models.dart';
export 'src/perception/perception_snapshot.dart';
export 'src/planning/domain_planner_orchestrator.dart';
export 'src/planning/diplomacy_planner.dart';
export 'src/planning/economy_planner.dart';
export 'src/planning/growth_stage.dart'
    show
        GrowthStage,
        categoryPriorityForOutput,
        kAtWarMilitaryFloor,
        growthStageSuppressesMilitaryBuilds,
        kGrowthStagePlannerEnabled,
        kMilitaryBuildSuppressionThreshold,
        kRecruitmentFloor,
        kReserveTarget,
        kStagePriorityBias,
        kTargetLabourForMaturity,
        peasantRecruitScoreScale,
        prospectedImprovedFeedstockTileCount;
export 'src/planning/recipe_scoring.dart' show stageScaledRecipeScore;
export 'src/planning/full_ai_planner.dart';
export 'src/planning/goal_manager.dart';
export 'src/planning/observer_goal_phase.dart' show ObserverGoalPhase;
export 'src/planning/phase_planner_dispatch.dart'
    show PhasePlanOutcome, runPhasePlanners;
export 'src/planning/phase_priority_weights.dart'
    show
        PhasePriorityWeights,
        computePhasePriorityWeights,
        goalColonialPressureWeightFor,
        kPhasePriorityCurveEarlySprintCeiling,
        kPhasePriorityNwTreasuryRecoveryFloor,
        kPhasePriorityNwZeroRegimentFloor;
export 'src/planning/recruitment_planner.dart'
    show
        RecruitmentPlan,
        RejectedRecruitmentSuggestion,
        kRecruitmentRejectInsufficientWorkers,
        kRecruitmentRejectMilitaryBuildSuppressed,
        kRecruitmentRejectMilitaryFabricReservation,
        kRecruitmentRejectSoftLuxuryCap,
        runRecruitmentPlanner;
export 'src/social/hidden_agenda.dart';
export 'src/util/ai_validation_exception.dart';
export 'src/social/mood_state_machine.dart';
export 'src/planning/strategic_ai.dart';
export 'src/tactical/tactical_ai.dart';
