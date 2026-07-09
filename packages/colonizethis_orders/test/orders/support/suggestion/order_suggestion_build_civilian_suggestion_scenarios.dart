// Table-driven civilian build suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_build_civilian_suggestion_expectations.dart';

/// One row in civilian build suggestion scenario tables.
class OrderSuggestionBuildCivilianSuggestionScenario implements RefsScenario {
  const OrderSuggestionBuildCivilianSuggestionScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionBuildCivilianSuggestionTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionBuildCivilianSuggestionScenario(
  OrderSuggestionBuildCivilianSuggestionScenario scenario,
) {
  runOrderSuggestionBuildCivilianSuggestionExpectation(scenario.target);
}

/// Scenarios for suggestBuildOrders civilian enumeration (Refs #3793).
List<OrderSuggestionBuildCivilianSuggestionScenario>
    suggestBuildOrdersCivilianEnumerationScenarios() => const [
          OrderSuggestionBuildCivilianSuggestionScenario(
            label: 'AC1: includes affordable civilian candidates when includeCivilianBuilds is true',
            target: OrderSuggestionBuildCivilianSuggestionTarget.includesAffordableWhenFlagTrue,
            refs: '#3793',
          ),
          OrderSuggestionBuildCivilianSuggestionScenario(
            label: 'AC1: emitted civilian candidates are deterministically sorted by unitType',
            target: OrderSuggestionBuildCivilianSuggestionTarget.deterministicallySortedByUnitType,
            refs: '#3793',
          ),
          OrderSuggestionBuildCivilianSuggestionScenario(
            label: 'AC1b: default (flag omitted) emits no civilian candidates and equals the explicit false call',
            target: OrderSuggestionBuildCivilianSuggestionTarget.defaultOmitsCivilianCandidates,
            refs: '#3793',
          ),
          OrderSuggestionBuildCivilianSuggestionScenario(
            label: 'AC5: Merchant excluded when merchant_companies is not unlocked',
            target: OrderSuggestionBuildCivilianSuggestionTarget.merchantExcludedWithoutTech,
            refs: '#3793',
          ),
          OrderSuggestionBuildCivilianSuggestionScenario(
            label: 'AC5: Merchant included when merchant_companies is unlocked and affordable',
            target: OrderSuggestionBuildCivilianSuggestionTarget.merchantIncludedWhenUnlocked,
            refs: '#3793',
          ),
          OrderSuggestionBuildCivilianSuggestionScenario(
            label: 'AC9: identical inputs produce identical civilian enumeration',
            target: OrderSuggestionBuildCivilianSuggestionTarget.identicalInputsIdenticalEnumeration,
            refs: '#3793',
          ),
          OrderSuggestionBuildCivilianSuggestionScenario(
            label: 'AC12: no civilian candidates when treasury is zero',
            target: OrderSuggestionBuildCivilianSuggestionTarget.noCandidatesWhenTreasuryZero,
            refs: '#3793',
          ),
          OrderSuggestionBuildCivilianSuggestionScenario(
            label: 'AC12: no civilian candidates when paper is below the minimum cost',
            target: OrderSuggestionBuildCivilianSuggestionTarget.noCandidatesWhenPaperBelowMinimum,
            refs: '#3793',
          ),
        ];
