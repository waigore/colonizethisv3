// Table-driven OrderEngine validateRecruitWorker scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_validate_recruit_worker_expectations.dart';

class OrderEngineValidateRecruitWorkerScenario implements RefsScenario {
  const OrderEngineValidateRecruitWorkerScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderEngineValidateRecruitWorkerTarget target;
  @override
  final String? refs;
}

void runOrderEngineValidateRecruitWorkerScenario(
  OrderEngineValidateRecruitWorkerScenario scenario,
) {
  runOrderEngineValidateRecruitWorkerExpectation(scenario.target);
}

List<OrderEngineValidateRecruitWorkerScenario>
orderEngineValidateRecruitWorkerScenarios() => const [
  // dart format off
  OrderEngineValidateRecruitWorkerScenario(
    label: 'accepts a single peasant recruit when fabric is available',
    target: OrderEngineValidateRecruitWorkerTarget.acceptsASinglePeasantRecruitWhenFabricIsAvailable,
  ),
  OrderEngineValidateRecruitWorkerScenario(
    label: 'rejects apprentice train when required tech is locked',
    target: OrderEngineValidateRecruitWorkerTarget.rejectsApprenticeTrainWhenRequiredTechIsLocked,
  ),
  OrderEngineValidateRecruitWorkerScenario(
    label: 'recruit consumes last peasant before military build, so subsequent regiment build is rejected with Insufficient workers',
    target: OrderEngineValidateRecruitWorkerTarget.recruitConsumesLastPeasantBeforeMilitaryBuild,
  ),
  OrderEngineValidateRecruitWorkerScenario(
    label: 'civilian build (no peasant consume) is accepted after recruit consumes the only peasant',
    target: OrderEngineValidateRecruitWorkerTarget.civilianBuildAcceptedAfterRecruitConsumesOnlyPeasant,
  ),
  // dart format on
];
