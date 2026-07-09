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
      vrwExpectPeasantRecruitAccepted();
    case OrderEngineValidateRecruitWorkerTarget
        .rejectsApprenticeTrainWhenRequiredTechIsLocked:
      vrwExpectApprenticeTrainRejectedTechLocked();
    case OrderEngineValidateRecruitWorkerTarget
        .recruitConsumesLastPeasantBeforeMilitaryBuild:
      vrwExpectRecruitConsumesPeasantBeforeMilitaryBuild();
    case OrderEngineValidateRecruitWorkerTarget
        .civilianBuildAcceptedAfterRecruitConsumesOnlyPeasant:
      vrwExpectRecruitThenCivilianBuildAccepted();
  }
}
