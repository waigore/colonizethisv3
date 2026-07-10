// Table-driven recruit-worker suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_recruit_worker_run_rows.dart';

/// One row in recruit-worker scenario tables.
class OrderSuggestionRecruitWorkerScenario implements RefsScenario {
  const OrderSuggestionRecruitWorkerScenario({
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

void runOrderSuggestionRecruitWorkerScenario(
  OrderSuggestionRecruitWorkerScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionRecruitWorkerScenario>
orderSuggestionRecruitWorkerInclusionScenarios() => const [
  OrderSuggestionRecruitWorkerScenario(
    label:
        'returns peasant and apprentice when fabric, treasury, paper, and apprentice tech support both rows',
    run: osrwRunReturnsPeasantAndApprenticeWhenSupported,
    refs: '#2692 S7',
  ),
  OrderSuggestionRecruitWorkerScenario(
    label: 'omits trained tiers when their required techs are locked',
    run: osrwRunOmitsTrainedTiersWhenTechsLocked,
    refs: '#2692 S7',
  ),
  OrderSuggestionRecruitWorkerScenario(
    label: 'omits peasant recruit when fabric is insufficient',
    run: osrwRunOmitsPeasantWhenFabricInsufficient,
    refs: '#2692 S7',
  ),
  OrderSuggestionRecruitWorkerScenario(
    label: 'omits apprentice recruit when treasury is below 200 ducats',
    run: osrwRunOmitsApprenticeWhenTreasuryBelow200,
    refs: '#2692 S7',
  ),
  OrderSuggestionRecruitWorkerScenario(
    label: 'omits apprentice recruit when peasant pool is empty',
    run: osrwRunOmitsApprenticeWhenPeasantPoolEmpty,
    refs: '#2692 S7',
  ),
];

List<OrderSuggestionRecruitWorkerScenario>
orderSuggestionRecruitWorkerParityScenarios() => const [
  OrderSuggestionRecruitWorkerScenario(
    label:
        'returns all four tiers when all techs unlocked and resources support every cost row',
    run: osrwRunReturnsAllFourTiersWhenFullyUnlocked,
    refs: '#2692 S7',
  ),
  OrderSuggestionRecruitWorkerScenario(
    label:
        'peasant reservation: pending apprentice recruit drains the only peasant so a candidate apprentice is excluded but candidate peasant remains',
    run: osrwRunPeasantReservationExcludesApprenticeCandidate,
    refs: '#2692 S7',
  ),
  OrderSuggestionRecruitWorkerScenario(
    label:
        'engine round-trip parity: accept/reject decision matches addRecruitWorkerOrderWithContext for every WorkerTier in a partial tech / peasant / treasury fixture',
    run: osrwRunEngineRoundTripParityPartialFixture,
    refs: '#2692 S7',
  ),
  OrderSuggestionRecruitWorkerScenario(
    label: 'empty stockpile + zero treasury + zero peasants -> empty list',
    run: osrwRunEmptyPlayerReturnsEmptyList,
    refs: '#2692 S7',
  ),
];
