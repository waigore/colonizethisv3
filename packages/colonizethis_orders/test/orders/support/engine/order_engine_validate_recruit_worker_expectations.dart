// Compact OrderEngine validateRecruitWorker assertions (Refs #3949 wave 3).

import 'order_engine_validate_recruit_worker_expectation_shorthand.dart';

/// Pins for [orderEngineValidateRecruitWorkerScenarios] rows.
enum OrderEngineValidateRecruitWorkerTarget {
  acceptsASinglePeasantRecruitWhenFabricIsAvailable,
  rejectsApprenticeTrainWhenRequiredTechIsLocked,
  recruitConsumesLastPeasantBeforeMilitaryBuild,
  civilianBuildAcceptedAfterRecruitConsumesOnlyPeasant,
}

void runOrderEngineValidateRecruitWorkerExpectation(
  OrderEngineValidateRecruitWorkerTarget target,
) {
  switch (target) {
    case OrderEngineValidateRecruitWorkerTarget
        .acceptsASinglePeasantRecruitWhenFabricIsAvailable:
      _acceptsASinglePeasantRecruitWhenFabricIsAvailable();
    case OrderEngineValidateRecruitWorkerTarget
        .rejectsApprenticeTrainWhenRequiredTechIsLocked:
      _rejectsApprenticeTrainWhenRequiredTechIsLocked();
    case OrderEngineValidateRecruitWorkerTarget
        .recruitConsumesLastPeasantBeforeMilitaryBuild:
      _recruitConsumesLastPeasantBeforeMilitaryBuild();
    case OrderEngineValidateRecruitWorkerTarget
        .civilianBuildAcceptedAfterRecruitConsumesOnlyPeasant:
      _civilianBuildAcceptedAfterRecruitConsumesOnlyPeasant();
  }
}

void _acceptsASinglePeasantRecruitWhenFabricIsAvailable() {
  vrwExpectPeasantRecruitAccepted();
}

void _rejectsApprenticeTrainWhenRequiredTechIsLocked() {
  vrwExpectApprenticeTrainRejectedTechLocked();
}

void _recruitConsumesLastPeasantBeforeMilitaryBuild() {
  vrwExpectRecruitConsumesPeasantBeforeMilitaryBuild();
}

void _civilianBuildAcceptedAfterRecruitConsumesOnlyPeasant() {
  vrwExpectRecruitThenCivilianBuildAccepted();
}
