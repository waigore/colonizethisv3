// Table-driven RecruitWorkerOrderValidator scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'recruit_worker_order_validator_expectations.dart';

/// One row in [recruitWorkerOrderValidatorScenarios].
class RecruitWorkerOrderValidatorScenario implements RefsScenario {
  const RecruitWorkerOrderValidatorScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final RecruitWorkerOrderValidatorTarget target;
  @override
  final String? refs;
}

void runRecruitWorkerOrderValidatorScenario(
  RecruitWorkerOrderValidatorScenario scenario,
) {
  runRecruitWorkerOrderValidatorExpectation(scenario.target);
}

/// Canonical scenarios for RecruitWorkerOrderValidator (#2692 S4).
List<RecruitWorkerOrderValidatorScenario> recruitWorkerOrderValidatorScenarios() =>
    const [
      RecruitWorkerOrderValidatorScenario(
        label: 'accepts peasant recruit and deducts 2 fabric, adds peasant',
        target: RecruitWorkerOrderValidatorTarget.acceptsPeasantRecruit,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'rejects peasant recruit when fabric is insufficient',
        target: RecruitWorkerOrderValidatorTarget.rejectsPeasantInsufficientFabric,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'accepts apprentice train when tech unlocked, deducts 200 ducats, 2 paper, 1 peasant; increments apprentices',
        target: RecruitWorkerOrderValidatorTarget.acceptsApprenticeTrain,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'rejects apprentice train when required tech is locked',
        target: RecruitWorkerOrderValidatorTarget.rejectsApprenticeTechLocked,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'rejects apprentice train when no peasant is available',
        target: RecruitWorkerOrderValidatorTarget.rejectsApprenticeNoPeasant,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'rejects apprentice train when treasury is insufficient',
        target:
            RecruitWorkerOrderValidatorTarget.rejectsApprenticeInsufficientTreasury,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'accepts journeyman train and applies 500 ducat + 5 paper cost',
        target: RecruitWorkerOrderValidatorTarget.acceptsJourneymanTrain,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'accepts master train and applies 1000 ducat + 10 paper cost',
        target: RecruitWorkerOrderValidatorTarget.acceptsMasterTrain,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'short-circuits to "Previous invalid" when previousRejected is true',
        target: RecruitWorkerOrderValidatorTarget.shortCircuitsPreviousRejected,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'sequential apprentice trains drain peasants in submission order',
        target:
            RecruitWorkerOrderValidatorTarget.sequentialApprenticeTrainsDrainPeasants,
        refs: '#2692 S4',
      ),
    ];
