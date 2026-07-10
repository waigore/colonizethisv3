// Table-driven civilian build suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_build_civilian_suggestion_run_rows.dart';

/// One row in civilian build suggestion scenario tables.
class OrderSuggestionBuildCivilianSuggestionScenario implements RefsScenario {
  const OrderSuggestionBuildCivilianSuggestionScenario({
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

void runOrderSuggestionBuildCivilianSuggestionScenario(
  OrderSuggestionBuildCivilianSuggestionScenario scenario,
) {
  scenario.run();
}

/// Scenarios for suggestBuildOrders civilian enumeration (Refs #3793).
List<OrderSuggestionBuildCivilianSuggestionScenario>
suggestBuildOrdersCivilianEnumerationScenarios() => const [
  OrderSuggestionBuildCivilianSuggestionScenario(
    label:
        'AC1: includes affordable civilian candidates when includeCivilianBuilds is true',
    run: osbcsRunIncludesAffordableWhenFlagTrue,
    refs: '#3793',
  ),
  OrderSuggestionBuildCivilianSuggestionScenario(
    label:
        'AC1: emitted civilian candidates are deterministically sorted by unitType',
    run: osbcsRunDeterministicallySortedByUnitType,
    refs: '#3793',
  ),
  OrderSuggestionBuildCivilianSuggestionScenario(
    label:
        'AC1b: default (flag omitted) emits no civilian candidates and equals the explicit false call',
    run: osbcsRunDefaultOmitsCivilianCandidates,
    refs: '#3793',
  ),
  OrderSuggestionBuildCivilianSuggestionScenario(
    label: 'AC5: Merchant excluded when merchant_companies is not unlocked',
    run: osbcsRunMerchantExcludedWithoutTech,
    refs: '#3793',
  ),
  OrderSuggestionBuildCivilianSuggestionScenario(
    label:
        'AC5: Merchant included when merchant_companies is unlocked and affordable',
    run: osbcsRunMerchantIncludedWhenUnlocked,
    refs: '#3793',
  ),
  OrderSuggestionBuildCivilianSuggestionScenario(
    label: 'AC9: identical inputs produce identical civilian enumeration',
    run: osbcsRunIdenticalInputsIdenticalEnumeration,
    refs: '#3793',
  ),
  OrderSuggestionBuildCivilianSuggestionScenario(
    label: 'AC12: no civilian candidates when treasury is zero',
    run: osbcsRunNoCandidatesWhenTreasuryZero,
    refs: '#3793',
  ),
  OrderSuggestionBuildCivilianSuggestionScenario(
    label: 'AC12: no civilian candidates when paper is below the minimum cost',
    run: osbcsRunNoCandidatesWhenPaperBelowMinimum,
    refs: '#3793',
  ),
];
