// Table-driven RecruitWorkerOrderValidator scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'recruit_worker_order_validator_run_rows.dart';

/// One row in [recruitWorkerOrderValidatorScenarios].
class RecruitWorkerOrderValidatorScenario implements RefsScenario {
  const RecruitWorkerOrderValidatorScenario({
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

void runRecruitWorkerOrderValidatorScenario(
  RecruitWorkerOrderValidatorScenario scenario,
) =>
    scenario.run();

/// Canonical scenarios for RecruitWorkerOrderValidator (#2692 S4).
List<RecruitWorkerOrderValidatorScenario> recruitWorkerOrderValidatorScenarios() =>
    const [
      RecruitWorkerOrderValidatorScenario(
        label: 'accepts peasant recruit and deducts 2 fabric, adds peasant',
        run: rwovRunAcceptsPeasantRecruit,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'rejects peasant recruit when fabric is insufficient',
        run: rwovRunRejectsPeasantInsufficientFabric,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'accepts apprentice train when tech unlocked, deducts 200 ducats, 2 paper, 1 peasant; increments apprentices',
        run: rwovRunAcceptsApprenticeTrain,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'rejects apprentice train when required tech is locked',
        run: rwovRunRejectsApprenticeTechLocked,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'rejects apprentice train when no peasant is available',
        run: rwovRunRejectsApprenticeNoPeasant,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'rejects apprentice train when treasury is insufficient',
        run: rwovRunRejectsApprenticeInsufficientTreasury,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'accepts journeyman train and applies 500 ducat + 5 paper cost',
        run: rwovRunAcceptsJourneymanTrain,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'accepts master train and applies 1000 ducat + 10 paper cost',
        run: rwovRunAcceptsMasterTrain,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'short-circuits to "Previous invalid" when previousRejected is true',
        run: rwovRunShortCircuitsPreviousRejected,
        refs: '#2692 S4',
      ),
      RecruitWorkerOrderValidatorScenario(
        label: 'sequential apprentice trains drain peasants in submission order',
        run: rwovRunSequentialApprenticeTrainsDrainPeasants,
        refs: '#2692 S4',
      ),
    ];
