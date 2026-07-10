// Table-driven recruit-worker suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_recruit_worker_expectations.dart';

/// One row in recruit-worker scenario tables.
class OrderSuggestionRecruitWorkerScenario implements RefsScenario {
  const OrderSuggestionRecruitWorkerScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionRecruitWorkerTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionRecruitWorkerScenario(
  OrderSuggestionRecruitWorkerScenario scenario,
) {
  runOrderSuggestionRecruitWorkerExpectation(scenario.target);
}

List<OrderSuggestionRecruitWorkerScenario>
orderSuggestionRecruitWorkerInclusionScenarios() => const [
      OrderSuggestionRecruitWorkerScenario(
        label: 'returns peasant and apprentice when fabric, treasury, paper, and apprentice tech support both rows',
        target: OrderSuggestionRecruitWorkerTarget
            .returnsPeasantAndApprenticeWhenSupported,
        refs: '#2692 S7',
      ),
      OrderSuggestionRecruitWorkerScenario(
        label: 'omits trained tiers when their required techs are locked',
        target:
            OrderSuggestionRecruitWorkerTarget.omitsTrainedTiersWhenTechsLocked,
        refs: '#2692 S7',
      ),
      OrderSuggestionRecruitWorkerScenario(
        label: 'omits peasant recruit when fabric is insufficient',
        target:
            OrderSuggestionRecruitWorkerTarget.omitsPeasantWhenFabricInsufficient,
        refs: '#2692 S7',
      ),
      OrderSuggestionRecruitWorkerScenario(
        label: 'omits apprentice recruit when treasury is below 200 ducats',
        target:
            OrderSuggestionRecruitWorkerTarget.omitsApprenticeWhenTreasuryBelow200,
        refs: '#2692 S7',
      ),
      OrderSuggestionRecruitWorkerScenario(
        label: 'omits apprentice recruit when peasant pool is empty',
        target:
            OrderSuggestionRecruitWorkerTarget.omitsApprenticeWhenPeasantPoolEmpty,
        refs: '#2692 S7',
      ),
    ];

List<OrderSuggestionRecruitWorkerScenario>
orderSuggestionRecruitWorkerParityScenarios() => const [
      OrderSuggestionRecruitWorkerScenario(
        label: 'returns all four tiers when all techs unlocked and resources support every cost row',
        target:
            OrderSuggestionRecruitWorkerTarget.returnsAllFourTiersWhenFullyUnlocked,
        refs: '#2692 S7',
      ),
      OrderSuggestionRecruitWorkerScenario(
        label: 'peasant reservation: pending apprentice recruit drains the only peasant so a candidate apprentice is excluded but candidate peasant remains',
        target: OrderSuggestionRecruitWorkerTarget
            .peasantReservationExcludesApprenticeCandidate,
        refs: '#2692 S7',
      ),
      OrderSuggestionRecruitWorkerScenario(
        label: 'engine round-trip parity: accept/reject decision matches addRecruitWorkerOrderWithContext for every WorkerTier in a partial tech / peasant / treasury fixture',
        target:
            OrderSuggestionRecruitWorkerTarget.engineRoundTripParityPartialFixture,
        refs: '#2692 S7',
      ),
      OrderSuggestionRecruitWorkerScenario(
        label: 'empty stockpile + zero treasury + zero peasants -> empty list',
        target: OrderSuggestionRecruitWorkerTarget.emptyPlayerReturnsEmptyList,
        refs: '#2692 S7',
      ),
    ];
