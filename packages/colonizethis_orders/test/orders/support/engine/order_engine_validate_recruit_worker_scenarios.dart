// Table-driven OrderEngine validateRecruitWorker scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_validate_recruit_worker_run_rows.dart';

class OrderEngineValidateRecruitWorkerScenario implements RefsScenario {
  const OrderEngineValidateRecruitWorkerScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runOrderEngineValidateRecruitWorkerScenario(
  OrderEngineValidateRecruitWorkerScenario scenario,
) => scenario.run();

List<OrderEngineValidateRecruitWorkerScenario>
orderEngineValidateRecruitWorkerScenarios() => const [
  // dart format off
          OrderEngineValidateRecruitWorkerScenario(
            label: 'accepts a single peasant recruit when fabric is available',
            run: vrwRunAcceptsSinglePeasantRecruitWhenFabricAvailable,
          ),
          OrderEngineValidateRecruitWorkerScenario(
            label: 'rejects apprentice train when required tech is locked',
            run: vrwRunRejectsApprenticeTrainWhenRequiredTechLocked,
          ),
          OrderEngineValidateRecruitWorkerScenario(
            label: 'recruit consumes last peasant before military build, so subsequent regiment build is rejected with Insufficient workers',
            run: vrwRunRecruitConsumesLastPeasantBeforeMilitaryBuild,
          ),
          OrderEngineValidateRecruitWorkerScenario(
            label: 'civilian build (no peasant consume) is accepted after recruit consumes the only peasant',
            run: vrwRunCivilianBuildAcceptedAfterRecruitConsumesOnlyPeasant,
          ),
          // dart format on
];
